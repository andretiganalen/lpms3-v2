#!/usr/bin/env node
// E2E: registrasi IDS + login -> logout -> login -> logout untuk akun persona LPMS-III (:5000).
//
// Pakai:
//   node ops/e2e_login_ids_5000.js [file-persona.md] [hasil.json]
//
// Default file persona: deploy/akun script persona lpms3 untuk e2e test.md (tidak di-commit, berisi password).
// Default hasil: ops/_e2e_login_result.json (di-ignore git).
// Skrip ini TIDAK menyimpan kredensial; semua dibaca dari file persona saat jalan.
//
// Env opsional:
//   LPMS_BASE   default http://192.168.125.14:5000  (localhost/127.0.0.1 ditolak IDS: redirect_uri tidak terdaftar)
//   IDS_BASE    default https://dev-ids-intern.len.co.id
//   CHROME_PATH default /usr/bin/google-chrome
//   PLAYWRIGHT  path modul playwright (default: require('playwright'), cadangan ~/librechat/node_modules/playwright)
//   SKIP_REGISTER=1  lewati langkah registrasi IDS
//   ONLY=#02,#10     hanya uji akun dengan nomor tersebut
//
// Catatan: login yang gagal tidak diulang, supaya akun Leno asli tidak terkunci.

const fs = require('fs');
const path = require('path');

function loadPlaywright() {
  const cands = [process.env.PLAYWRIGHT, 'playwright', path.join(process.env.HOME || '', 'librechat/node_modules/playwright')].filter(Boolean);
  for (const c of cands) { try { return require(c); } catch (_) {} }
  console.error('Modul playwright tidak ditemukan. Set env PLAYWRIGHT=<path ke node_modules/playwright>.');
  process.exit(2);
}
const { chromium } = loadPlaywright();

const REPO = path.resolve(__dirname, '..');
const PERSONA = process.argv[2] || path.join(REPO, 'deploy', 'akun script persona lpms3 untuk e2e test.md');
const OUT = process.argv[3] || path.join(__dirname, '_e2e_login_result.json');
const BASE = process.env.LPMS_BASE || 'http://192.168.125.14:5000';
const IDS = process.env.IDS_BASE || 'https://dev-ids-intern.len.co.id';
const CHROME = process.env.CHROME_PATH || '/usr/bin/google-chrome';

// Parse blok "#NN" dari file persona.
function parsePersona(file) {
  const s = fs.readFileSync(file, 'utf8');
  return s.trim().split(/\n(?=#\d\d)/).map(blk => {
    const get = k => { const m = blk.match(new RegExp('^' + k + ':[ \\t]*(.*)$', 'm')); return m ? m[1].trim() : ''; };
    const email = get('akun_leno');
    return { id: blk.slice(0, 3), persona: get('persona'), email: /@/.test(email) ? email : '', pw: get('password') };
  });
}

const now = () => new Date().toISOString().replace('T', ' ').slice(0, 19);

(async () => {
  const only = (process.env.ONLY || '').split(',').map(x => x.trim()).filter(Boolean);
  const accts = parsePersona(PERSONA).filter(a => !only.length || only.includes(a.id));
  console.log(`${accts.length} akun dibaca dari ${PERSONA}`);
  const b = await chromium.launch({ executablePath: CHROME });
  const out = [];
  for (const a of accts) {
    const r = { id: a.id, persona: a.persona, email: a.email, steps: [] }; out.push(r);
    const log = (step, ok, detail) => { r.steps.push({ step, ok, detail, at: now() }); console.log(a.id, a.persona, step, ok, detail); };
    if (!a.email) {
      log('registrasi', 'SKIP', 'akun_leno kosong di file persona');
      for (const s of ['login-1', 'logout-1', 'login-2', 'logout-2']) log(s, 'SKIP', 'tidak ada akun');
      continue;
    }
    const ctx = await b.newContext({ ignoreHTTPSErrors: true }); const p = await ctx.newPage();
    const txt = async () => (await p.innerText('body').catch(() => '')).replace(/\s+/g, ' ');

    // 1. Registrasi IDS
    if (process.env.SKIP_REGISTER === '1') log('registrasi', 'SKIP', 'SKIP_REGISTER=1');
    else try {
      await p.goto(IDS + '/Account/Register'); await p.fill('#Email', a.email);
      await Promise.all([p.waitForNavigation(), p.click('form[action*=Register] button[type=submit]')]);
      const t = await txt(); const m = ((t.match(/Email kantor (.*?) Daftar/) || [])[1] || t.slice(0, 200)).trim();
      const ok = /berhasil|terkirim|cek email|periksa email|success/i.test(m) ? 'PASS' : /sudah terdaftar|already/i.test(m) ? 'SUDAH ADA' : 'FAIL';
      log('registrasi', ok, m);
    } catch (e) { log('registrasi', 'FAIL', 'error: ' + e.message.split('\n')[0]); }

    const login = async step => {
      await p.goto(BASE + '/');
      if (!p.url().startsWith(IDS)) return log(step, 'PASS', 'sesi IDS masih aktif, langsung masuk: ' + p.url());
      await p.fill('#input-username', a.email); await p.fill('#input-password', a.pw);
      // Form IDS mengenkripsi username/password (CryptoJS) pada event change.
      await p.dispatchEvent('#input-username', 'change'); await p.dispatchEvent('#input-password', 'change');
      if (!(await p.inputValue('#input-passwordencrypted')) || !(await p.inputValue('#input-usernameencrypted')))
        return log(step, 'FAIL', 'field terenkripsi kosong (masalah skrip)');
      await Promise.all([p.waitForNavigation({ timeout: 30000 }).catch(() => {}), p.click('button[value=login]')]);
      await p.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => {});
      const u = p.url(), t = await txt();
      if (u.startsWith(BASE)) return log(step, 'PASS', 'mendarat di ' + u.replace(BASE, '') + ' | ' + t.slice(0, 120));
      const err = ((t.match(/Masuk ke Akun Anda (.*?) Username atau email/) || [])[1] || t.slice(0, 160)).trim();
      log(step, 'FAIL', 'tetap di IDS ' + u.replace(IDS, '').split('?')[0] + ': ' + err);
    };

    const logout = async step => {
      const cand = await p.$$eval('a,form', els => els.map(e => e.getAttribute('href') || e.getAttribute('action') || '').filter(h => /logout|signout|keluar/i.test(h)));
      const target = cand[0] || '/logout';
      await p.goto(target.startsWith('http') ? target : BASE + target).catch(() => {});
      await p.waitForLoadState('networkidle', { timeout: 20000 }).catch(() => {});
      const btn = await p.$('button:has-text("Ya"), button:has-text("Yes"), button:has-text("Keluar"), button:has-text("Logout")');
      if (btn && p.url().startsWith(IDS)) await Promise.all([p.waitForNavigation({ timeout: 15000 }).catch(() => {}), btn.click()]);
      await p.goto(BASE + '/'); const ok = p.url().startsWith(IDS);
      log(step, ok ? 'PASS' : 'FAIL', (ok ? 'akses ulang :5000 diarahkan ke login IDS' : 'masih punya sesi: ' + p.url()) + ' (via ' + target + ')');
    };

    await login('login-1');
    if (r.steps.at(-1).ok !== 'PASS') {
      for (const s of ['logout-1', 'login-2', 'logout-2']) log(s, 'SKIP', 'login-1 gagal; tidak diulang agar akun tidak terkunci');
    } else { await logout('logout-1'); await login('login-2'); await logout('logout-2'); }
    await ctx.close();
  }
  fs.writeFileSync(OUT, JSON.stringify(out, null, 1));
  await b.close();
  const full = out.filter(r => r.steps.slice(1).every(s => s.ok === 'PASS')).length;
  console.log(`\nSelesai: ${full}/${out.length} akun lulus siklus penuh. Hasil: ${OUT}`);
  process.exit(full === out.filter(r => r.email).length ? 0 : 1);
})();
