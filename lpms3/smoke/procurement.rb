# Uji Eksekusi Pengadaan berlandaskan Budget, 3 sub-fase (PR, Buyer sampai kontrak, milestone sampai BA):
# temuan per tahap, komitmen vs Budget, nilai terkonversi, gerbang validasi, hak akses, halaman ID/EN, filter.
# Proyek, Budget, Work Package, dan akun uji dihapus di akhir.
require "action_dispatch/testing/integration"
ActionController::Base.allow_forgery_protection = false
def chk(id, desc, ok, note = nil) = puts(format("%-5s %-4s %s%s", ok.nil? ? "N/A" : (ok ? "PASS" : "FAIL"), id, desc, note ? " — #{note}" : ""))
TAG = "smoke-pgd"
P = OpenProject::Lpms3::Procurement
users = {}; proj = nil; created_rate = nil
begin
  pw = SecureRandom.hex(12) + "Aa1!"
  { member: "id", outsider: "en" }.each do |k, lang|
    u = User.new(login: "#{TAG}.#{k}", firstname: "Smoke", lastname: k.to_s, mail: "#{TAG}.#{k}@example.com", admin: false,
                 status: User.statuses[:active], language: lang, password: pw, password_confirmation: pw, force_password_change: false)
    u.save!; users[k] = u
  end
  proj = Project.create!(name: "#{TAG} proyek", identifier: "#{TAG}-#{rand(9999)}", workspace_type: "project", public: false,
                         enabled_module_names: %w[work_package_tracking costs budgets])
  Member.create!(project: proj, principal: users[:member], roles: [ProjectRole.find_by!(name: "Tim Proyek")])
  type = Type.find_by!(name: P::TYPE)
  ms_type = Type.where(is_milestone: true).first
  prio = IssuePriority.default || IssuePriority.first
  author = User.admin.active.where(type: "User").where.not(login: "lpms3-bridge").order(:id).first
  cf = ->(n) { WorkPackageCustomField.find_by!(name: n) }
  today = Date.current
  if OpenProject::Lpms3::Fx.rate("USD").nil?
    created_rate = Lpms3::ExchangeRate.create!(currency_code: "USD", rate: BigDecimal("16000"), valid_on: today - 1, source: "manual", note: TAG, created_by: author)
  end
  rate = OpenProject::Lpms3::Fx.rate("USD")
  bud = Budget.create!(project: proj, author: author, subject: "#{TAG} budget", description: "uji", fixed_date: today, base_amount: 5_000_000)
  chk("B0", "Budget uji berencana Rp 5.000.000", bud.budget == 5_000_000, bud.budget.to_s)

  mk = lambda do |subject, status, vals, budget: bud, parent: nil, t: type|
    wp = WorkPackage.new(project: proj, type: t, subject: subject, status: Status.find_by!(name: status), priority: prio, author: author, budget: budget, parent_id: parent&.id)
    wp.save!(validate: false)
    vals.each { |n, v| wp.custom_values.create!(custom_field: cf.(n), value: v.to_s) }
    wp
  end
  closed = Status.where(is_closed: true).order(:id).first
  open_st = Status.where(is_closed: false).order(:id).first
  mk_ms = ->(parent, subject, st) { mk.(subject, st.name, {}, budget: nil, parent: parent, t: ms_type) }

  a = mk.("A tanpa budget", "PO/Kontrak", { "Rekanan" => "PT Uji" }, budget: nil)
  b = mk.("B tanpa GR", "GR/SES", { "No. PR" => "PR-1", "No. PO" => "PO-1", "Rekanan" => "PT Uji", "Nilai pengadaan (IDR)" => "1000000",
                                    "No. Kontrak" => "K-1", "Tanggal berakhir kontrak" => (today - 1).iso8601 })
  c = mk.("C lewat butuh", "PR", { "No. PR" => "PR-2", "Nilai pengadaan (IDR)" => "500000", "Tanggal dibutuhkan" => (today - 3).iso8601 })
  d = mk.("D kontrak USD", "PO/Kontrak", { "No. PR" => "PR-3", "No. PO" => "PO-3", "Rekanan" => "PT Uji", "No. Kontrak" => "K-3",
                                           "Nilai kontrak" => "100", "Mata uang kontrak" => "usd", "Tanggal berakhir kontrak" => (today + 10).iso8601,
                                           "Tanggal dibutuhkan" => (today + 60).iso8601 })
  e = mk.("E selesai", "Selesai", { "No. PR" => "PR-4", "No. PO" => "PO-4", "Rekanan" => "PT Uji", "No. GR/SES" => "GR-4", "Nilai pengadaan (IDR)" => "500000",
                                    "No. BA penagihan" => "BA-4", "Tanggal BA penagihan" => today.iso8601 })
  mk_ms.(e, "E milestone 1", closed); mk_ms.(e, "E milestone 2", closed)
  f = mk.("F separuh jalan", "Pengiriman", { "No. PR" => "PR-5", "No. PO" => "PO-5", "Rekanan" => "PT Uji", "No. Kontrak" => "K-5", "Nilai pengadaan (IDR)" => "100" })
  mk_ms.(f, "F milestone 1", closed); mk_ms.(f, "F milestone 2", open_st)

  items = P.items(WorkPackage.where(project_id: proj.id))
  summary = P.summary(items)
  items = items.index_by { _1.wp.id }
  fi = ->(w) { items[w.id].findings }
  chk("P0", "field Kontrak Awal/GR/BA dan tipe Item Pengadaan tersedia", P::F.values.all? { WorkPackageCustomField.exists?(name: _1) })
  chk("P1", "sub-fase 1: PR tanpa Budget, tanpa No. PR dan tanpa nilai ditandai", %i[no_budget missing_pr no_value].all? { fi.(a).include?(_1) } && fi.(a).include?(:missing_po))
  chk("P2", "sub-fase 1: item di Budget lengkap tidak ditandai no_budget", !fi.(b).include?(:no_budget) && !fi.(c).include?(:no_budget))
  chk("P3", "sub-fase 1: lewat tanggal dibutuhkan ditandai", fi.(c).include?(:overdue_need))
  chk("P4", "sub-fase 2: kontrak berakhir ≤ 30 hari ditandai, tanpa temuan lain", fi.(d) == [:contract_expiring] || fi.(d).sort == %i[contract_expiring no_milestones].sort, fi.(d).inspect)
  chk("P5", "sub-fase 2: nilai kontrak USD (kode huruf kecil diterima) dikonversi sesuai kurs", items[d.id].value_base == BigDecimal("100") * rate, items[d.id].value_base.to_s)
  chk("P6", "sub-fase 2: kontrak lewat tanggal ditandai", fi.(b).include?(:contract_expired))
  chk("P7", "sub-fase 3: tahap GR/SES tanpa milestone dan GR ditandai; BA belum wajib sebelum item selesai", %i[no_milestones missing_gr].all? { fi.(b).include?(_1) } && !fi.(b).include?(:missing_ba))
  chk("P8", "sub-fase 3: item selesai dengan milestone tertutup + BA tanpa temuan", fi.(e).empty?, fi.(e).inspect)
  chk("P9", "sub-fase 3: milestone setengah selesai terhitung 1/2; tanpa tanggal berakhir kontrak ditandai", items[f.id].milestones_done == 1 && items[f.id].milestones.size == 2 && fi.(f).include?(:no_end_date))
  chk("P10", "ringkasan: 6 item; nilai total = jumlah nilai terkonversi", summary[:total] == 6 && summary[:value_base] == items.values.sum { _1.value_base || 0 })
  rows = P.budget_rows(items.values, project: proj)
  expect_commit = [1_000_000, 500_000, BigDecimal("100") * rate, 500_000, 100].sum
  chk("P11", "komitmen Budget = jumlah nilai item tahap PR ke atas; sisa = rencana - komitmen", rows.size == 1 && rows[0][:committed] == expect_commit && rows[0][:remaining] == 5_000_000 - expect_commit, rows[0]&.slice(:committed, :remaining).inspect)

  # Gerbang validasi
  newwp = lambda do |status, budget, vals|
    w = WorkPackage.new(project: proj, type: type, subject: "gate", status: Status.find_by!(name: status), priority: prio, author: author, budget: budget)
    w.custom_field_values = vals.to_h { |n, v| [cf.(n).id, v.to_s] }
    w
  end
  g = ->(w) { P.gate(w).map(&:first) }
  chk("G1", "PR tanpa Budget ditolak", g.(newwp.("PR", nil, { "No. PR" => "PR-9", "Nilai pengadaan (IDR)" => "1000" })).include?(:budget_required))
  chk("G2", "PR tanpa No. PR ditolak", g.(newwp.("PR", bud, { "Nilai pengadaan (IDR)" => "1000" })).include?(:pr_required))
  chk("G3", "PR yang melampaui sisa Budget ditolak", g.(newwp.("PR", bud, { "No. PR" => "PR-9", "Nilai pengadaan (IDR)" => "3000000" })).include?(:over_budget))
  chk("G4", "PR dalam sisa Budget lolos", g.(newwp.("PR", bud, { "No. PR" => "PR-9", "Nilai pengadaan (IDR)" => "100000" })).empty?, g.(newwp.("PR", bud, { "No. PR" => "PR-9", "Nilai pengadaan (IDR)" => "100000" })).inspect)
  chk("G5", "status Rencana tidak digerbang", g.(newwp.("Rencana", nil, {})).empty?)
  chk("G6", "PO/Kontrak tanpa rekanan dan nomor kontrak ditolak", (g.(newwp.("PO/Kontrak", bud, { "No. PR" => "P", "Nilai pengadaan (IDR)" => "1" })) & %i[vendor_required contract_required]).size == 2)
  fw = WorkPackage.find(f.id); fw.status = Status.find_by!(name: "Selesai")
  gf = g.(fw)
  chk("G7", "Selesai ditolak bila milestone belum selesai dan BA belum ada", gf.include?(:milestones_open) && gf.include?(:ba_required), gf.inspect)
  ok_wp = newwp.("PR", nil, { "No. PR" => "PR-9", "Nilai pengadaan (IDR)" => "1000" })
  ok_wp.valid?
  chk("G8", "validasi terpasang pada model WorkPackage (pesan tampil di errors)", ok_wp.errors[:base].include?(I18n.t("lpms3.procurement.gate.budget_required")), ok_wp.errors.full_messages.first(3).inspect)

  as = lambda do |user, &blk|
    ApplicationController.class_eval { define_method(:find_current_user) { user || User.anonymous } }
    http = ActionDispatch::Integration::Session.new(Rails.application)
    http.host! (Setting.host_name.presence || "192.168.125.14:5100")
    blk.call(http)
  end
  base = "/projects/#{proj.identifier}/lpms3/pengadaan"
  as.(users[:member]) do |h|
    h.get base
    body = h.response.body
    chk("H1", "anggota: ringkasan 200 (ID) dengan landasan anggaran", h.response.status == 200 && body.include?("Landasan anggaran") && body.include?("#{TAG} budget"), h.response.status.to_s)
    h.get "#{base}/pr"
    chk("H2", "sub-fase 1 (PR): tabel Budget dan item bertahap Rencana/PR", h.response.status == 200 && h.response.body.include?("Sub-fase 1") && h.response.body.include?("C lewat butuh") && !h.response.body.include?("E selesai"))
    h.get "#{base}/buyer"
    chk("H3", "sub-fase 2 (Buyer): item PO/Kontrak tampil, item Selesai tidak", h.response.status == 200 && h.response.body.include?("D kontrak USD") && !h.response.body.include?("E selesai"))
    h.get "#{base}/penyelesaian"
    chk("H4", "sub-fase 3: milestone dan Berita Acara tampil", h.response.status == 200 && h.response.body.include?("F milestone 2") && h.response.body.include?("BA-4") && h.response.body.include?("1/2"))
    h.get "#{base}/penyelesaian", params: { temuan: "no_milestones" }
    chk("H5", "filter temuan pada sub-fase (no_milestones: B ya, E tidak)", h.response.body.include?("B tanpa GR") && !h.response.body.include?("E selesai"))
    h.get base, params: { temuan: "'; drop--" }
    chk("H6", "filter tak dikenal diabaikan (tanpa error)", h.response.status == 200)
    h.get "#{base}/ngawur"
    chk("H7", "sub-fase tak dikenal tidak ditemukan", [404].include?(h.response.status), h.response.status.to_s)
    h.get "/lpms3/pengadaan"
    chk("H8", "halaman lintas proyek menampilkan item proyek yang boleh dilihat", h.response.status == 200 && h.response.body.include?("A tanpa budget"))
    h.get "/projects/#{proj.identifier}/lpms3/fase/eksekusi"
    chk("H9", "sidebar fase Eksekusi memuat tiga sub-fase pengadaan", h.response.status == 200 && %w[pengadaan/pr pengadaan/buyer pengadaan/penyelesaian].all? { h.response.body.include?(_1) })
  end
  as.(users[:outsider]) do |h|
    h.get base
    chk("H10", "bukan anggota ditolak pada proyek", [403, 404].include?(h.response.status), h.response.status.to_s)
    h.get "/lpms3/pengadaan"
    chk("H11", "lintas proyek (EN) tidak membocorkan item proyek lain", h.response.status == 200 && !h.response.body.include?("A tanpa budget") && h.response.body.include?("Procurement"))
  end
  as.(nil) { |h| h.get "/lpms3/pengadaan"; chk("H12", "tamu tidak dapat membuka", [302, 401, 403].include?(h.response.status), h.response.status.to_s) }
rescue => e
  chk("ERR", "uji terhenti", false, "#{e.class}: #{e.message[0, 300]} #{e.backtrace.first(3).join(' | ')}")
ensure
  Lpms3::ExchangeRate.where(note: TAG).delete_all
  if proj
    WorkPackage.where(project_id: proj.id).find_each { |w| w.custom_values.delete_all }
    WorkPackage.where(project_id: proj.id).update_all(parent_id: nil)
    WorkPackage.where(project_id: proj.id).delete_all
    Budget.where(project_id: proj.id).find_each { |b| b.destroy rescue nil }
    Member.where(project_id: proj.id).delete_all
    (proj.reload.destroy rescue (Projects::DeleteProjectService.new(user: User.admin.first, model: proj).call rescue nil))
  end
  users.each_value { |u| (User.find_by(id: u.id)&.then { |x| x.destroy rescue Principals::DeleteJob.perform_now(x) }) }
  puts "sisa proyek/akun uji: #{Project.where('identifier like ?', "#{TAG}%").count}/#{User.where('login like ?', "#{TAG}%").count}"
end
