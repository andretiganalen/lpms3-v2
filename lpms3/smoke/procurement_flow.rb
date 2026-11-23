# Uji alur siklus hidup satu Item Pengadaan, dari PR sampai Berita Acara penagihan:
#   Rencana -> PR (gerbang Budget & No. PR) -> PO/Kontrak (gerbang rekanan & kontrak)
#   -> Pengiriman (milestone) -> GR/SES (No. GR) -> Selesai (milestone tertutup & No. BA penagihan)
# Setiap tahap: simpan langkah yang sah (harus lolos gerbang), lalu coba langkah yang tidak sah (harus ditolak).
# Model-level (WorkPackage#save), bukan lewat UI/API; alur workflow status tidak diuji di sini.
# Proyek, Budget, Work Package, dan akun uji dihapus di akhir.
ActionController::Base.allow_forgery_protection = false
def chk(id, desc, ok, note = nil) = puts(format("%-5s %-4s %s%s", ok.nil? ? "N/A" : (ok ? "PASS" : "FAIL"), id, desc, note ? " — #{note}" : ""))
TAG = "smoke-flow"
P = OpenProject::Lpms3::Procurement
proj = nil; user = nil; bud = nil
results = []

begin
  today = Date.current
  author = User.admin.active.where(type: "User").where.not(login: "lpms3-bridge").order(:id).first
  user = User.new(login: "#{TAG}.admin", firstname: "Smoke", lastname: "flow", mail: "#{TAG}@example.com", admin: true,
                  status: User.statuses[:active], language: "id", password: SecureRandom.hex(12) + "Aa1!", force_password_change: false)
  user.save!
  User.current = author

  proj = Project.create!(name: "#{TAG} proyek", identifier: "#{TAG}-#{rand(9999)}", workspace_type: "project", public: false,
                         enabled_module_names: %w[work_package_tracking costs budgets])
  type = Type.find_by!(name: P::TYPE)
  ms_type = Type.where(is_milestone: true).first
  prio = IssuePriority.default || IssuePriority.first
  cf = ->(n) { WorkPackageCustomField.find_by!(name: n) }
  st = ->(n) { Status.find_by!(name: n) }
  closed_st = Status.where(is_closed: true).order(:id).first
  open_st = Status.where(is_closed: false).order(:id).first

  if OpenProject::Lpms3::Fx.rate("USD").nil?
    Lpms3::ExchangeRate.create!(currency_code: "USD", rate: BigDecimal("16000"), valid_on: today - 1, source: "manual", note: TAG, created_by: author)
  end
  bud = Budget.create!(project: proj, author: author, subject: "#{TAG} budget", description: "uji", fixed_date: today, base_amount: 5_000_000)

  # Simpan dengan validasi penuh (gerbang aktif). Mengembalikan [berhasil?, pesan].
  save_wp = lambda do |wp, vals|
    wp.custom_field_values = vals.to_h { |n, v| [cf.(n).id, v.to_s] } if vals
    ok = wp.save
    [ok, wp.errors.full_messages.join("; ")]
  end

  # Unggah dokumen pendukung ke Work Package (lampiran standar OpenProject). Mengembalikan nama berkas tersimpan.
  docs = []
  upload = lambda do |wp, filename, body|
    path = File.join(Dir.tmpdir, "#{TAG}-#{SecureRandom.hex(4)}-#{filename}")
    File.binwrite(path, body)
    up = ActionDispatch::Http::UploadedFile.new(tempfile: File.open(path, "rb"), filename: filename, type: "application/pdf")
    att = Attachment.new(container: wp, author: author, file: up)
    ok = att.save
    docs << att if ok
    File.delete(path) rescue nil
    [ok, att.errors.full_messages.join("; ")]
  end

  item = WorkPackage.new(project: proj, type: type, subject: "Pengadaan uji alur", status: st.("Rencana"), priority: prio, author: author)
  ok, _ = save_wp.(item, nil)
  chk("F0", "item dibuat di status Rencana tanpa Budget", ok, item.errors.full_messages.join("; "))

  # ---- Tahap 1: PR ----
  item.status = st.("PR"); item.budget = nil
  ok, msg = save_wp.(item, { "No. PR" => "PR-FLOW-1", "Nilai pengadaan (IDR)" => "1000000", "Tanggal dibutuhkan" => (today + 20).iso8601 })
  chk("F1", "PR tanpa Budget ditolak", !ok, msg.presence)

  item.reload
  item.status = st.("PR"); item.budget = bud
  ok, msg = save_wp.(item, { "No. PR" => nil, "Nilai pengadaan (IDR)" => "1000000" })
  chk("F2", "PR tanpa No. PR ditolak", !ok, msg.presence)

  item.reload
  item.status = st.("PR"); item.budget = bud
  ok, msg = save_wp.(item, { "No. PR" => "PR-FLOW-1", "Nilai pengadaan (IDR)" => "9000000", "Tanggal dibutuhkan" => (today + 20).iso8601 })
  chk("F3", "PR melampaui sisa Budget (Rp 9 juta > Rp 5 juta) ditolak", !ok, msg.presence)

  item.reload
  item.status = st.("PR"); item.budget = bud
  ok, msg = save_wp.(item, { "No. PR" => "PR-FLOW-1", "Nilai pengadaan (IDR)" => "1000000", "Tanggal dibutuhkan" => (today + 20).iso8601 })
  chk("F4", "PR sah (Rp 1 juta dalam Budget Rp 5 juta) lolos gerbang", ok, msg.presence)
  up_ok, up_msg = upload.(item, "PR-FLOW-1.pdf", "%PDF-1.4 uji PR #{TAG}")
  chk("F4a", "dokumen PR (PR-FLOW-1.pdf) terunggah ke item", up_ok, up_msg.presence)

  # ---- Tahap 2: Buyer -> PO/Kontrak ----
  item.reload
  item.status = st.("PO/Kontrak")
  ok, msg = save_wp.(item, { "Rekanan" => nil, "No. Kontrak" => nil })
  chk("F5", "PO/Kontrak tanpa rekanan dan nomor kontrak ditolak", !ok, msg.presence)

  item.reload
  item.status = st.("PO/Kontrak")
  ok, msg = save_wp.(item, { "Rekanan" => "PT Uji Flow", "No. PO" => "PO-FLOW-1", "No. Kontrak" => "K-FLOW-1",
                             "Nilai kontrak" => "100", "Mata uang kontrak" => "USD",
                             "Tanggal kontrak" => (today - 5).iso8601, "Tanggal berakhir kontrak" => (today + 90).iso8601 })
  chk("F6", "kontrak sah (USD 100) lolos gerbang; nilai dikonversi ke IDR", ok, msg.presence)
  item.reload
  v_base = OpenProject::Lpms3::Procurement.items(WorkPackage.where(id: item.id)).first&.value_base
  chk("F7", "nilai kontrak terkonversi = USD 100 x kurs USD", v_base == BigDecimal("100") * OpenProject::Lpms3::Fx.rate("USD"), v_base.to_s)
  up_ok, up_msg = upload.(item, "Kontrak-K-FLOW-1.pdf", "%PDF-1.4 uji kontrak #{TAG}")
  chk("F7a", "dokumen kontrak (Kontrak-K-FLOW-1.pdf) terunggah ke item", up_ok, up_msg.presence)

  # ---- Tahap 3: Pengiriman (milestone) ----
  item.reload
  item.status = st.("Pengiriman")
  ok, msg = save_wp.(item, nil)
  chk("F8", "Pengiriman tanpa milestone diperbolehkan oleh gerbang (cek temuan no_milestones saja)", ok, msg.presence)
  ms1 = WorkPackage.new(project: proj, type: ms_type, subject: "Milestone 1 flow", status: open_st, priority: prio, author: author, parent_id: item.id)
  ms1.save!(validate: false)
  ms2 = WorkPackage.new(project: proj, type: ms_type, subject: "Milestone 2 flow", status: open_st, priority: prio, author: author, parent_id: item.id)
  ms2.save!(validate: false)
  item.reload
  f_pengiriman = OpenProject::Lpms3::Procurement.items(WorkPackage.where(id: item.id)).first.findings
  chk("F9", "Pengiriman dengan dua milestone terbuka: tanpa temuan no_milestones", !f_pengiriman.include?(:no_milestones), f_pengiriman.inspect)
  u1 = upload.(ms1, "Milestone-1-bukti.pdf", "%PDF-1.4 bukti milestone 1 #{TAG}")
  u2 = upload.(ms2, "Milestone-2-bukti.pdf", "%PDF-1.4 bukti milestone 2 #{TAG}")
  chk("F9a", "dokumen bukti dua milestone terunggah", u1[0] && u2[0], [u1[1], u2[1]].reject(&:blank?).join("; ").presence)

  # ---- Tahap 4: GR/SES ----
  item.reload
  item.status = st.("GR/SES")
  ok, msg = save_wp.(item, { "No. GR/SES" => nil })
  chk("F10", "GR/SES tanpa No. GR (tidak diwajibkan gerbang; temuan missing_gr saja)", ok, msg.presence)
  item.reload
  item.status = st.("GR/SES")
  ok, msg = save_wp.(item, { "No. GR/SES" => "GR-FLOW-1", "Tanggal GR/SES" => today.iso8601 })
  chk("F11", "GR/SES dengan No. GR lolos gerbang", ok, msg.presence)
  up_ok, up_msg = upload.(item, "GR-FLOW-1.pdf", "%PDF-1.4 uji GR #{TAG}")
  chk("F11a", "dokumen GR/SES (GR-FLOW-1.pdf) terunggah ke item", up_ok, up_msg.presence)

  # ---- Tahap 5: Selesai ----
  item.reload
  item.status = st.("Selesai")
  ok, msg = save_wp.(item, { "No. BA penagihan" => nil })
  chk("F12", "Selesai ditolak: milestone terbuka dan BA belum ada", !ok, msg.presence)

  ms1.reload; ms2.reload
  ms1.status = closed_st; ms1.save!(validate: false)
  ms2.status = closed_st; ms2.save!(validate: false)
  item.reload
  item.status = st.("Selesai")
  ok, msg = save_wp.(item, { "No. BA penagihan" => nil })
  chk("F13", "Selesai ditolak: milestone sudah tertutup tapi BA belum ada", !ok, msg.presence)

  item.reload
  item.status = st.("Selesai")
  ok, msg = save_wp.(item, { "No. BA penagihan" => "BA-FLOW-1", "Tanggal BA penagihan" => today.iso8601 })
  chk("F14", "Selesai sah (milestone tertutup + No. BA penagihan) lolos gerbang", ok, msg.presence)
  up_ok, up_msg = upload.(item, "BA-FLOW-1.pdf", "%PDF-1.4 uji BA penagihan #{TAG}")
  chk("F14a", "dokumen Berita Acara penagihan (BA-FLOW-1.pdf) terunggah ke item", up_ok, up_msg.presence)
  chk("F14b", "seluruh dokumen uji (PR, kontrak, bukti milestone, GR, BA) tersimpan dan berukuran > 0",
      docs.size == 6 && docs.all? { _1.reload.filesize.to_i.positive? }, "jumlah dokumen: #{docs.size}")

  item.reload
  final = OpenProject::Lpms3::Procurement.items(WorkPackage.where(id: item.id)).first
  chk("F15", "item selesai tanpa temuan (findings kosong)", final&.findings == [], final&.findings.inspect)
  chk("F16", "ringkasan Budget: komitmen = nilai kontrak terkonversi (PR tidak dihitung ganda)",
      OpenProject::Lpms3::Procurement.committed(OpenProject::Lpms3::Procurement.items(WorkPackage.where(id: item.id))).values.sum == final.value_base)
rescue StandardError => e
  chk("ERR", "pengecualian tak terduga", false, "#{e.class}: #{e.message}".first(300))
  puts e.backtrace.first(5)
ensure
  # Bersihkan data uji
  begin
    Budget.where(project_id: proj.id).delete_all if proj
    proj&.destroy
    user&.destroy
    puts "sisa proyek/akun uji: #{Project.where("identifier LIKE ?", "#{TAG}%").count}/#{User.where("login LIKE ?", "#{TAG}%").count}"
  rescue StandardError => e
    puts "pembersihan gagal: #{e.class}: #{e.message}".first(300)
  end
end
