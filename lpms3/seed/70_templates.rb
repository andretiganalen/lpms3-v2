require_relative "00_data"
# Template proyek LPMS3 (§5.9): grup per fungsi, 3 template, WP aktivitas BOP-001 + RASCI, Dokumen Rencana, gate, query, wiki.
RASCI = JSON.parse(RASCI_JSON)
admin = User.admin.active.order(:id).first or abort("admin tidak ada")
User.current = admin

# --- Grup per fungsi (dari RASCI) -------------------------------------------------
ROLE_ONLY = ["Pimpro", "Tim Proyek", "Project Sponsor", "Direksi / Project Sponsor", "Seluruh Fungsi Terkait",
             "Fungsi terkait sesuai jenis perubahan"].freeze
names = RASCI.flat_map { |r| %w[A R S C I].flat_map { |k| r[k] } }.uniq - ROLE_ONLY
names.each { |n| Group.find_or_create_by!(lastname: n) }
group = ->(n) { Group.find_by(lastname: n) }

ROLE_MAP = [
  [/Pelaksanaan Proyek/, "Fungsi Pelaksanaan Proyek (Struktural)"], [/Pengawasan Proyek/, "Fungsi Pengawasan Proyek"],
  [/Perencanaan Proyek|Perencanaan Perusahaan/, "Fungsi Perencanaan Proyek"],
  [/Anggaran|Keuangan|Akuntansi/, "Fungsi Pengendali Anggaran/Keuangan/Akuntansi"],
  [/Mutu|Quality/, "Fungsi Penjaminan Mutu"], [/Risiko/, "Fungsi Manajemen Risiko"],
  [/K3|Lingkungan/, "Fungsi K3 & Lingkungan Hidup"], [/Pengadaan|Gudang/, "Fungsi Pengadaan & Pengelola Gudang"],
  [/Pemasaran|Kontrak Bisnis/, "Fungsi Pemasaran"], [/Rekayasa/, "Fungsi Rekayasa Solusi Teknis"],
  [/Rekrutmen|Pembelajaran|Pengembangan Organisasi/, "Fungsi Rekrutmen & Pembelajaran SDM"],
].freeze
role_for = lambda do |n|
  rn = ROLE_MAP.find { |re, _| n =~ re }&.last || "Pembaca (Informed)"
  ProjectRole.find_by!(name: rn)
end

# --- Isi template ------------------------------------------------------------------
DOK_RENCANA = ["Manajemen Ruang Lingkup", "Manajemen Jadwal", "Manajemen Biaya", "Manajemen Mutu", "Manajemen Sumber Daya",
               "Manajemen Komunikasi", "Manajemen Risiko & K3L", "Manajemen Pengadaan", "Manajemen Stakeholder"].freeze
GATES = ["G1 — Project Charter ditetapkan", "G2 — Kick-Off / Baseline 0", "G3 — Serah terima", "G4 — Proyek ditutup"].freeze
MODULES_COMMON = %w[work_package_tracking gantt meetings documents budgets costs news wiki calendar_view].freeze

def rasci_md(r)
  rows = { "A" => "Accountable", "R" => "Responsible", "S" => "Supporting", "C" => "Consulted", "I" => "Informed" }
  "**RASCI BOP-001 #{r['tabel']} no. #{r['no']}** (#{r['fase']})\n\n| Peran | Pihak |\n|---|---|\n" +
    rows.map { |k, l| "| #{l} (#{k}) | #{r[k].join('; ').presence || '—'} |" }.join("\n")
end

def ensure_project(name, ident, parent: nil, desc: nil)
  p = Project.find_by(identifier: ident) || Project.new(identifier: ident)
  p.name = name; p.description = desc if desc; p.workspace_type = "project"; p.templated = true; p.public = false
  p.save!
  p
end

def add_wp(project, type, subject, author, desc: nil, status: nil, assignee: nil, responsible: nil)
  wp = WorkPackage.find_or_initialize_by(project_id: project.id, subject: subject)
  return wp unless wp.new_record?
  wp.type = type
  wp.author = author
  wp.status = status || Status.find_by!(name: Lpms3Data::TYPES.fetch(type.name).first.first)
  wp.priority = IssuePriority.default || IssuePriority.first
  wp.description = desc
  wp.assigned_to = assignee if assignee
  wp.responsible = responsible if responsible
  wp.save!(validate: false) if (wp.errors.any? rescue false)
  wp.save! unless wp.persisted?
  wp
end

def build_template(name, ident, modules:, types:, rasci:, doks:, gates:, desc:, admin:, group:, role_for:, rasci_rows:)
  p = ensure_project(name, ident, desc: desc)
  p.enabled_module_names = modules
  p.save!
  Type.where(name: types).each { |t| p.project_types.find_or_create_by!(type_id: t.id, variant_id: t.default_variant.id) }
  # anggota default: grup fungsi dengan perannya
  (rasci ? rasci_rows : []).flat_map { |r| %w[A R S C I].flat_map { |k| r[k] } }.uniq.each do |n|
    g = group.(n) or next
    m = Member.find_or_initialize_by(project: p, principal: g)
    m.roles = [role_for.(n)] if m.new_record?
    m.save!
  end
  Member.where(project_id: p.id).destroy_all unless rasci
  task = Type.find_by!(name: "Task")
  rasci_rows.each do |r|
    subj = "[#{r['tabel']}-#{r['no']}] #{r['aktivitas']}"
    add_wp(p, task, subj, admin, desc: rasci_md(r),
           assignee: group.(r["R"].first), responsible: group.(r["A"].first))
  end if rasci
  if doks
    dt = Type.find_by!(name: "Dokumen Rencana")
    DOK_RENCANA.each { |d| add_wp(p, dt, "Dokumen Rencana — #{d}", admin, desc: "Dokumen PMP (BOP-001 §5.2.1). Status Disahkan diperlukan untuk Gate G2.") }
  end
  if gates
    ms = Type.find_by!(name: "Milestone")
    GATES.each { |g| add_wp(p, ms, g, admin, desc: "Gate penutup fase (Spesifikasi §5.4).") }
  end
  # fase proyek
  begin
    Project::PhaseDefinition.order(:position).each { |d| Project::Phase.find_or_create_by!(project: p, definition: d) }
  rescue => e
    puts "  (fase proyek dilewati: #{e.class}: #{e.message.to_s[0, 120]})"
  end
  p
end

ALLT = Lpms3Data::TYPES.keys + %w[Task Milestone]
common = { admin: admin, group: group, role_for: role_for, rasci_rows: RASCI }
pred = build_template("LPMS3-Prediktif", "lpms3-tpl-prediktif", modules: MODULES_COMMON, types: ALLT, rasci: true, doks: true, gates: true,
  desc: "Template default untuk proyek kontrak (hardware/sistem/konstruksi). BOP-001.", **common)
hib_mod = (MODULES_COMMON + %w[backlogs board_view]) & OpenProject::AccessControl.available_project_modules.map(&:to_s) | %w[wiki]
hib  = build_template("LPMS3-Hibrid", "lpms3-tpl-hibrid", modules: hib_mod, types: ALLT, rasci: true, doks: true, gates: true,
  desc: "Prediktif + Backlogs/Boards untuk komponen perangkat lunak (sprint).", **common)
pj_types = %w[Isu Action\ Item Milestone Lesson\ Learned Task]
puma = build_template("LPMS3-Purnajual", "lpms3-tpl-purnajual", modules: %w[work_package_tracking wiki meetings news], types: pj_types,
  rasci: false, doks: false, gates: false, desc: "Template ringan purnajual: Isu, Action Item, SLA milestone, Lessons Learned.", **common)
add_wp(puma, Type.find_by!(name: "Milestone"), "SLA — batas waktu respons purnajual", admin, desc: "Atur tanggal SLA per kontrak.")

# --- Query tersimpan --------------------------------------------------------------
QUERIES = { "Risk Register" => "Risiko", "Change Log" => "Change Request", "Issue Log" => "Isu",
            "Stakeholder Register" => "Stakeholder", "Lessons Learned" => "Lesson Learned",
            "Pengadaan" => "Item Pengadaan", "Inspeksi Mutu" => "Inspeksi Mutu" }
[pred, hib].each do |proj|
  QUERIES.each do |qn, tn|
    q = Query.find_or_initialize_by(project_id: proj.id, name: qn)
    next unless q.new_record?
    q.user = admin; q.public = true; q.include_subprojects = false
    q.filters = [{ type_id: { operator: "=", values: [Type.find_by!(name: tn).id.to_s] } }]
    q.column_names = %i[id subject status assigned_to updated_at]
    q.save!
  end
end

# --- Wiki -------------------------------------------------------------------------
WIKI = {
  "Project Charter (BOT-001)" => "Gunakan template BOT-001. Isi: tujuan, lingkup, deliverable utama, anggaran, jadwal, stakeholder, risiko awal.",
  "Team Charter" => "Peran, tanggung jawab, aturan kerja, dan jadwal komunikasi tim proyek.",
  "Matriks Komunikasi" => "| Informasi | Pengirim | Penerima | Frekuensi | Media |\n|---|---|---|---|---|\n| | | | | |",
  "Lessons Learned" => "Ringkasan pembelajaran. Rincian ada pada query *Lessons Learned*.",
  "Arsip FFR-710" => "Daftar kelengkapan dokumen proyek (FFR-710): bagian A–E.",
}
[pred, hib, puma].each do |proj|
  wiki = proj.wiki || proj.create_wiki!(start_page: "Wiki")
  WIKI.each do |title, text|
    next if wiki.pages.find_by(title: title)
    pg = wiki.pages.build(title: title); pg.author = admin; pg.text = text; pg.save!
  end
end

puts "templates ok: #{Project.templated.count} template; WP #{WorkPackage.where(project_id: Project.templated.select(:id)).count}; " \
     "grup #{Group.count}; query #{Query.where(project_id: Project.templated.select(:id)).count}; " \
     "anggota #{Member.where(project_id: Project.templated.select(:id)).count}"
