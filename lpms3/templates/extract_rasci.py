#!/usr/bin/env python3
"""Ekstrak Tabel RASCI (1,2,3,5,6) dari BOP-001 ke lpms3/templates/rasci.yml.
Pemakaian: python extract_rasci.py <BOP-001.pdf> <out.yml>  (butuh pdfplumber)"""
import re, sys, json, pdfplumber
pdf_path, out_path = sys.argv[1:3]
pdf = pdfplumber.open(pdf_path)
TABLES = [("T1", "P1 Inisiasi", 12, 13), ("T2", "P2 Perencanaan", 17, 19),
          ("T3", "P3 Eksekusi", 23, 26), ("T5", "P3 Pengawasan & Pengendalian", 31, 34),
          ("T6", "P4 Penutupan", 34, 36)]
NOISE = re.compile(r"\s*(Dokumen tidak terkontrol.*|aplikasi LenO.*|untuk melihat.*|k melihat versi.*|ontrol, silahkan buka.*|(?<=Proyek) (aru|u)|(?<=Pimpro) aru|(?<=Proyek) ontrol, silahkan buka.*)$", re.S)
def clean(s): return re.sub(r"\s+", " ", NOISE.sub("", (s or "").replace("\n", " "))).strip()
def people(s):
    s = clean(s).replace("Pengadan", "Pengadaan").replace("Pengadaaan", "Pengadaan")
    parts = [p.strip() for p in s.split("•")] if "•" in s else [s]
    parts = [p for p in parts if p]
    out = []
    for i, p in enumerate(parts):  # sel yang terpotong di tengah kata "Fungsi" + "X"
        if p == "Fungsi" and i + 1 < len(parts): parts[i + 1] = "Fungsi " + parts[i + 1]; continue
        out.append(re.sub(r"^(Fungsi Pengawasan Proyek) u$", r"\1", p))
    return out
rows = []
for tid, fase, p1, p2 in TABLES:
    seen = set()
    for pn in range(p1, p2 + 1):
        for t in pdf.pages[pn - 1].extract_tables():
            if not t or len(t[0]) != 7: continue
            for r in t:
                m = re.match(r"\s*(\d+)", clean(r[0]))
                if not m or not clean(r[1]): continue
                no = int(m.group(1))
                if (tid, no) in seen: continue
                seen.add((tid, no))
                rows.append({"tabel": tid, "no": no, "fase": fase, "aktivitas": clean(r[1]),
                             "A": people(r[2]), "R": people(r[3]), "S": people(r[4]),
                             "C": people(r[5]), "I": people(r[6])})
with open(out_path, "w") as f:
    json.dump(rows, f, ensure_ascii=False, indent=1)  # JSON adalah subset YAML
print(len(rows), "aktivitas")
