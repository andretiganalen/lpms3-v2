# Tarik proyek :5000 -> :5100 (alur pemicu LenO)
1. `python3 ex.py` — SELECT-only ke MySQL :5000 (kredensial dari ~/lpms3/.env), hasil `proyek5000.json`; kode di luar format XXX-XXXXXXXX dikoreksi (alnum, potong/isi "0" sampai 11 karakter).
2. POST tiap kode ke `/lpms3/api/pemicu-proyek` (header `X-Lpms3-Key`, id_kiriman `tarik5000-<kode>`).
3. `impor.rb` (rails runner, `PROYEK = JSON.parse(...)`) — Admin FPP mengusulkan, Pejabat Eselon 1 FPP menyetujui; job membuat proyek dari template.
Pimpro/VP diambil dari :5000 (cocok lewat email); bila kosong: Pimpro = andre.tigana, VP = Pejabat Eselon 1 FPP.
