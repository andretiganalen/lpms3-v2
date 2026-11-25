# Pemeriksaan alur kerja 5 fase BOP-001 (Inisiasi -> Perencanaan -> Eksekusi -> Pengawasan & Pengendalian -> Penutupan)
# pada proyek uji sementara dari template Prediktif. Memeriksa langkah, dokumen, gerbang, halaman fase, progres stepper,
# penutupan/arsip. Data uji dihapus di akhir. Dijalankan lewat lpms3/smoke/run_fase.sh.
# Catatan: halaman fase diambil lewat sesi integrasi dalam proses runner ini (autentikasi disimulasikan hanya di proses ini).
require "action_dispatch/testing/integration"
admin = User.admin.active.where(type: "User").where.not(login: "lpms3-bridge").order(:id).first || User.admin.active.order(:id).first
User.current = admin
RES = []
def chk(id, desc, ok, note = nil)
  RES << ok
  puts format("%-5s %-4s %s%s", ok.nil? ? "N/A" : (ok ? "PASS" : "FAIL"), id, desc, note ? " — #{note}" : "")
end
def safe(id, desc)
  r = yield
  chk(id, desc, r.is_a?(Array) ? r[0] : r, r.is_a?(Array) ? r[1] : nil)
rescue => e
  chk(id, desc, false, "#{e.class}: #{e.message[0, 160]}")
end

TAG = "smoke-fase"
users = {}
proj = nil
begin
  pw = SecureRandom.hex(12) + "Aa1!"
  { pimpro: "Pimpro", pengawas: "Fungsi Pengawasan Proyek" }.each do |k, role|
    u = User.new(login: "#{TAG}.#{k}", firstname: "Smoke", lastname: k.to_s, mail: "#{TAG}.#{k}@example.com", admin: false,
                 status: User.statuses[:active], language: "id", password: pw, password_confirmation: pw, force_password_change: false)
    u.save!
    users[k] = [u, role]
  end
  pimpro = users[:pimpro][0]
  pengawas = users[:pengawas][0]

  tpl = Project.find_by!(identifier: "lpms3-predik")
  res = Projects::CopyService.new(user: admin, source: tpl)
          .call(target_project_params: { name: "SMOKE FASE", identifier: "#{TAG}-proyek" }, only: %i[members work_packages wiki_page_content])
  raise "copy gagal: #{res.errors.full_messages.join('; ')}" unless res.success?
  proj = res.result
  proj.update_columns(templated: false)
  users.each_value { |(u, role)| m = Member.find_or_initialize_by(project: proj, principal: u); m.roles = [ProjectRole.find_by!(name: role)]; m.save! }

  ApplicationController.class_eval { define_method(:find_current_user) { admin } }
  http = ActionDispatch::Integration::Session.new(Rails.application)
  http.host! (Setting.host_name.presence || "192.168.125.14:5100")
  PHASES = OpenProject::Lpms3::Phases::ALL
  def page(http, proj, key)
    http.get "/projects/#{proj.identifier}/lpms3/fase/#{key}"
    [http.response.status, http.response.body]
  end
  def progress_of(body, idx)
    items = body.scan(%r{<li class="lpms3-stepper__item.*?</li>}m)
    m = items[idx].to_s.match(/(\d+)\s+(?:dari|of)\s+(\d+)/)
    m ? [m[1].to_i, m[2].to_i] : nil
  end
  def move(wp, user, status_name)
    st = Status.find_by!(name: status_name)
    WorkPackages::UpdateService.new(user: user, model: wp.reload).call(status_id: st.id).success?
  end
  def steps_of(proj, prefix) = proj.work_packages.where("subject LIKE ?", "[#{prefix}-%").to_a.sort_by { |w| w.subject[/-(\d+)\]/, 1].to_i }

  expected = { "inisiasi" => 3, "perencanaan" => 9, "eksekusi" => 8, "pengawasan" => 11, "penutupan" => 4 }

  safe("F00", "Menu project memuat 5 container fase berurutan setelah Ikhtisar") do
    http.get "/projects/#{proj.identifier}"
    keys = http.response.body.scan(/lpms3-fase-(inisiasi|perencanaan|eksekusi|pengawasan|penutupan)-menu-item/).flatten.uniq
    [keys == PHASES.map(&:key), keys.inspect]
  end
  safe("F00", "Progres awal semua fase 0/total (stepper)") do
    st, body = page(http, proj, "inisiasi")
    got = PHASES.each_index.map { |i| progress_of(body, i) }
    [st == 200 && got == PHASES.map { |ph| [0, expected[ph.key]] }, got.inspect]
  end

  PHASES.each_with_index do |ph, idx|
    n = idx + 1
    steps = steps_of(proj, ph.prefix)
    safe("F#{n}.1", "#{ph.key}: #{expected[ph.key]} langkah BOP-001 ada dan halaman fase terbuka") do
      st, body = page(http, proj, ph.key)
      rows = body.scan(%r{<th scope="row"><a href="[^"]*work_packages/\d+}).size
      [st == 200 && steps.size == expected[ph.key] && rows == expected[ph.key], "wp=#{steps.size} baris=#{rows} http=#{st}"]
    end
    safe("F#{n}.2", "#{ph.key}: setiap langkah Baru→Dikerjakan→Selesai (Pimpro)") do
      bad = steps.reject { |w| move(w, pimpro, "Dikerjakan") && move(w, pimpro, "Selesai") }
      [bad.empty?, bad.empty? ? nil : "gagal: #{bad.map(&:subject).first(2).join(' | ')}"]
    end
    if ph.key == "perencanaan"
      safe("F#{n}.3", "perencanaan: 9 Dokumen Rencana Draft→Reviu→Disahkan") do
        docs = proj.work_packages.joins(:type).where(types: { name: "Dokumen Rencana" }).to_a
        bad = docs.reject { |w| move(w, pimpro, "Reviu") && move(w, pimpro, "Disahkan") }
        [docs.size == 9 && bad.empty?, "dokumen=#{docs.size} gagal=#{bad.size}"]
      end
    end
    safe("F#{n}.4", "#{ph.key}: gerbang #{ph.gates.join(',')} Rencana→Tercapai") do
      gates = proj.work_packages.joins(:type).where(types: { is_milestone: true })
                  .where(ph.gates.map { "work_packages.subject LIKE ?" }.join(" OR "), *ph.gates.map { "#{_1} %" }).to_a
      # G3 menutup Eksekusi sekaligus Pengawasan: hanya ditutup setelah fase Pengawasan selesai
      if ph.key == "eksekusi"
        [nil, "G3 (Serah terima) ditutup setelah Pengawasan & Pengendalian selesai"]
      else
        who = nil
        ok = gates.all? do |g|
          if move(g, pimpro, "Tercapai") then who ||= "Pimpro"; true
          elsif move(g, pengawas, "Tercapai") then who ||= "Pengawas"; true
          else false end
        end
        [gates.any? && ok, "gerbang=#{gates.map { _1.subject[0, 2] }.join(',')} ditutup oleh #{who || 'tidak ada'}"]
      end
    end
    safe("F#{n}.5", "#{ph.key}: progres stepper = total/total setelah fase selesai") do
      _, body = page(http, proj, ph.key)
      got = progress_of(body, idx)
      [got == [expected[ph.key], expected[ph.key]], got.inspect]
    end
    safe("F#{n}.6", "#{ph.key}: halaman fase menampilkan gerbang dan tidak ada langkah berstatus selain Selesai") do
      _, body = page(http, proj, ph.key)
      gate_ok = ph.key == "eksekusi" || body.include?("Tercapai")
      step_status = body.scan(%r{<tbody>.*?</tbody>}m).first.to_s.scan(/lpms3-chip[^>]*>([^<]+)</).flatten.uniq
      [gate_ok && step_status == ["Selesai"], "status langkah=#{step_status.inspect}"]
    end
  end

  safe("F9.1", "G3 Serah terima Rencana→Tercapai setelah Eksekusi dan Pengawasan selesai") do
    g = proj.work_packages.joins(:type).where(types: { is_milestone: true }).where("work_packages.subject LIKE ?", "G3 %").first
    [g && (move(g, pimpro, "Tercapai") || move(g, pengawas, "Tercapai")) || (g&.reload&.status&.name == "Tercapai"), g&.reload&.status&.name]
  end
  safe("F9.2", "Seluruh lima fase 100% pada stepper") do
    _, body = page(http, proj, "penutupan")
    got = PHASES.each_index.map { |i| progress_of(body, i) }
    [got == PHASES.map { |ph| [expected[ph.key], expected[ph.key]] }, got.inspect]
  end
  safe("F9.3", "Penutupan: Jenis Penutupan diisi dan proyek diarsipkan (read-only)") do
    cf = ProjectCustomField.find_by!(name: "Jenis Penutupan")
    proj.custom_field_values = { cf.id => cf.custom_options.order(:id).first.id.to_s }
    proj.save(validate: false)
    Projects::ArchiveService.new(user: admin, model: proj).call
    proj.reload
    r = WorkPackages::UpdateService.new(user: pimpro, model: proj.work_packages.first).call(subject: "setelah arsip")
    [!proj.active? && !r.success?, "active=#{proj.active?}"]
  end
ensure
  begin
    if proj
      proj = Project.find_by(id: proj.id)
      proj&.update_columns(active: true)
      Projects::DeleteService.new(user: admin, model: proj).call if proj
    end
  rescue => e
    puts "cleanup proyek gagal: #{e.class}: #{e.message[0, 200]}"
  end
  users.each_value { |(u, _)| (User.find_by(id: u.id)&.then { |x| x.destroy rescue Principals::DeleteJob.perform_now(x) }) }
  puts "---"
  puts "RINGKASAN: PASS=#{RES.count(true)} FAIL=#{RES.count(false)} N/A=#{RES.count(nil)}"
  puts "sisa proyek uji: #{Project.where('identifier LIKE ?', "#{TAG}%").count}"
end
