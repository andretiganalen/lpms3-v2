# Fase & gate (§5.4). Gate = gerbang penutup fase (finish_gate). P3 menggabungkan Eksekusi + Pengawasan.
PHASES = [
  ["P1 Inisiasi",    "G1 — Project Charter ditetapkan", "#1D6FA5"],
  ["P2 Perencanaan", "G2 — Kick-Off / Baseline 0",      "#6C4AB6"],
  ["P3 Eksekusi + Pengawasan & Pengendalian", "G3 — Serah terima", "#2E8B57"],
  ["P4 Penutupan",   "G4 — Proyek ditutup",             "#4D5656"],
]
defs = Project::PhaseDefinition.order(:position).to_a
# Gunakan 4 definisi bawaan (urut posisi) agar tidak terjadi duplikasi; tambah bila kurang.
PHASES.each_with_index do |(name, gate, hex), i|
  d = defs[i] || Project::PhaseDefinition.new(position: i + 1)
  d.name = name
  d.start_gate = false
  d.start_gate_name = nil
  d.finish_gate = true
  d.finish_gate_name = gate
  d.color = Color.find_or_create_by!(name: "LPMS3 #{name[0, 2]}") { |c| c.hexcode = hex } if d.respond_to?(:color=)
  d.save!
end
extra = Project::PhaseDefinition.where.not(id: Project::PhaseDefinition.order(:position).limit(4).select(:id))
puts "lifecycle ok: #{Project::PhaseDefinition.count} fase (#{Project::PhaseDefinition.order(:position).pluck(:name).join(' | ')}), definisi lebih: #{extra.count}"
