# Uji pergantian bahasa ID/EN: menu, label, dan panduan HARUS berganti; isian pengguna (nama project, subjek dan
# deskripsi paket-penugasan, komentar) HARUS tetap persis sama. Proyek uji sementara dihapus di akhir.
require "action_dispatch/testing/integration"
admin = User.admin.active.where(type: "User").where.not(login: "lpms3-bridge").order(:id).first || User.admin.active.order(:id).first
User.current = admin
ActionController::Base.allow_forgery_protection = false # sesi integrasi tanpa token CSRF (hanya di proses uji ini)
orig_lang = admin.language
def chk(id, desc, ok, note = nil) = puts(format("%-5s %-4s %s%s", ok ? "PASS" : "FAIL", id, desc, note ? " — #{note}" : ""))

NAME = "Proyek Uji Bahasa — Pelabuhan Cilamaya (jangan diterjemahkan)"
SUBJ = "[T2-99] Review rencana: Risk Register & Change Request sesuai kebutuhan lapangan"
DESC = "Catatan pengguna: Please keep this English text. Jangan ubah teks Indonesia ini. Status: In Progress."
proj = nil
begin
  tpl = Project.find_by!(identifier: "lpms3-tpl-prediktif")
  res = Projects::CopyService.new(user: admin, source: tpl).call(target_project_params: { name: NAME, identifier: "smoke-lang-proyek" }, only: %i[members work_packages])
  raise "copy gagal: #{res.errors.full_messages.join('; ')}" unless res.success?
  proj = res.result
  proj.update_columns(templated: false)
  type = ::Type.where(is_milestone: false).first
  wp = WorkPackage.new(project: proj, type: type, subject: SUBJ, description: DESC, author: admin, status: Status.default, priority: IssuePriority.default)
  wp.save!(validate: false)
  snap = -> { [Project.find(proj.id).name, WorkPackage.find(wp.id).subject, WorkPackage.find(wp.id).description] }
  before = snap.call

  ApplicationController.class_eval { define_method(:find_current_user) { User.find(admin.id) } }
  http = ActionDispatch::Integration::Session.new(Rails.application)
  http.host! (Setting.host_name.presence || "192.168.125.14:5100")
  grab = lambda do |path|
    http.get path
    http.response.body.to_s
  end
  pages = {}
  %w[id en].each do |lang|
    http.post "/lpms3/language", params: { lang: lang, back: "/" }
    chk("L0", "switch ke #{lang.upcase} tersimpan", User.find(admin.id).language == lang)
    pages[lang] = {
      phase: grab.("/projects/#{proj.identifier}/lpms3/fase/perencanaan"),
      overview: grab.("/projects/#{proj.identifier}"),
      wps: grab.("/projects/#{proj.identifier}/work_packages"),
      guide: grab.("/lpms3/panduan"),
      home: grab.("/"),
      admin: grab.("/admin/lpms3/branding")
    }
  end

  # Menu induk-anak: halaman bagian fase menandai anak aktif (selected) dan membuka induk fasenya (li.open).
  %w[ringkasan gerbang langkah register].each do |sec|
    path = sec == "ringkasan" ? "/projects/#{proj.identifier}/lpms3/fase/perencanaan" : "/projects/#{proj.identifier}/lpms3/fase/perencanaan/#{sec}"
    body = grab.(path)
    child_sel = body.match?(/<a class="lpms3-fase-perencanaan-#{sec}-menu-item selected /)
    parent_open = body.match?(/<li class="open" data-name="lpms3_fase_perencanaan"/)
    only_one = body.scan(/menu-item selected /).size == 2 # induk fase + anak aktif (sorotan induk-anak)
    chk("M-#{sec}", "menu: anak '#{sec}' tersorot, induk Perencanaan terbuka dan tersorot (induk + anak)", child_sel && parent_open && only_one, "status=#{http.response.status} child=#{child_sel} open=#{parent_open} sel=#{body.scan(/menu-item selected /).size}")
  end
  chk("M-404", "bagian fase tidak dikenal -> 404", (grab.("/projects/#{proj.identifier}/lpms3/fase/perencanaan/xyz"); http.response.status == 404))
  chk("G-anon", "panduan terbuka tanpa login (tamu)", begin
    ApplicationController.class_eval { define_method(:find_current_user) { User.anonymous } }
    grab.("/lpms3/panduan"); ok = http.response.status == 200
    ApplicationController.class_eval { define_method(:find_current_user) { User.find(admin.id) } }; ok
  end)

  exp = { "id" => { menu: "Perencanaan", title: "Panduan internal LPMS3", stepper: "Fase proyek BOP-001", steps: "Langkah BOP-001", gates: "Gerbang (Gate)", brand: "Tampilan (logo, ikon, warna)" },
          "en" => { menu: "Planning", title: "LPMS3 internal guide", stepper: "BOP-001 project phases", steps: "BOP-001 steps", gates: "Gates", brand: "Appearance (logo, icon, colors)" } }
  %w[id en].each do |l|
    e = exp[l]; p = pages[l]
    chk("L1-#{l}", "label menu fase '#{e[:menu]}' di sidebar", p[:overview].include?(e[:menu]) && p[:phase].include?(e[:menu]))
    chk("L2-#{l}", "halaman fase: stepper/langkah/gerbang berbahasa #{l.upcase}", [e[:stepper], e[:steps]].all? { |s| p[:phase].include?(s) })
    chk("L3-#{l}", "panduan berbahasa #{l.upcase}", p[:guide].include?(e[:title]))
    chk("L4-#{l}", "<html lang> = #{l}", p[:phase] =~ /<html[^>]*lang="#{l}/ ? true : false)
    chk("L5-#{l}", "halaman admin LPMS3 berbahasa #{l.upcase}", p[:admin].include?(e[:brand]))
  end
  other = { "id" => "en", "en" => "id" }
  %w[id en].each do |l|
    chk("L6-#{l}", "teks #{l.upcase} tidak bocor ke #{other[l].upcase} (guide)", !pages[other[l]][:guide].include?(exp[l][:title]))
    chk("L7-#{l}", "teks sidebar #{l.upcase} tidak ada di #{other[l].upcase}", pages[other[l]][:phase].scan(%r{<a[^>]*menu-item[^>]*>.*?</a>}m).none? { |a| a.include?(exp[l][:menu]) && !exp[other[l]][:menu].eql?(exp[l][:menu]) })
  end
  %w[id en].each do |l|
    chk("U1-#{l}", "nama project tidak berubah di halaman (#{l.upcase})", pages[l][:overview].include?(ERB::Util.html_escape(NAME)) || pages[l][:phase].include?(ERB::Util.html_escape(NAME)))
  end
  chk("U2", "isian pengguna di DB identik sebelum dan sesudah ganti bahasa", snap.call == before)
  steps_of = ->(b) { b.scan(%r{<th scope="row"><a [^>]*>(.*?)</a></th>}m).flatten.map(&:strip).sort }
  sid, sen = steps_of.(pages["id"][:phase]), steps_of.(pages["en"][:phase])
  chk("U3", "subjek langkah pada halaman fase identik di ID dan EN (#{sid.size} baris)", sid == sen)
  chk("U4", "subjek isian pengguna tampil apa adanya di ID dan EN", [sid, sen].all? { |l| l.any? { |t| t == "99. " + ERB::Util.html_escape(SUBJ.sub(/\A\[T\d+-\d+\]\s*/, "")) } })
ensure
  admin.update_column(:language, orig_lang)
  if proj
    begin
      Projects::DeleteService.new(user: admin, model: Project.find(proj.id)).call
    rescue StandardError
      Project.find_by(id: proj.id)&.destroy
    end
  end
end
