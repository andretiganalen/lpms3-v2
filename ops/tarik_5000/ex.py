from my5000 import *
import re,json
def fix(c):
    a=re.sub(r'[^A-Z0-9]','',c.upper())
    a=(a+"0"*11)[:11]
    return a[:3]+"-"+a[3:]
ok=re.compile(r'^[A-Z0-9]{3}-[A-Z0-9]{8}$')
rows=q("""select p.ProjectCode code,p.ProjectName nama,p.Status status,p.ContractValue nilai,p.StartDate mulai,p.PlannedEndDate selesai,
 (select u.Email from projectmembers m join users u on u.Id=m.UserId where m.ProjectCode=p.ProjectCode and m.IsPimpro=1 and m.IsActive=1 limit 1) pimpro,
 (select u.Email from projecttriggerrequests t join users u on u.Id=t.ProposedPimproUserId where t.ProjectCode=p.ProjectCode limit 1) pimpro2,
 (select u.Email from projecttriggerrequests t join users u on u.Id=t.ProposedVpUserId where t.ProjectCode=p.ProjectCode limit 1) vp
 from projects p order by p.CreatedAt""")
out=[];seen={}
for r in rows:
    k=r['code'] if ok.match(r['code']) else fix(r['code'])
    if k in seen: raise SystemExit(f"tabrakan {k}: {seen[k]} vs {r['code']}")
    seen[k]=r['code']
    out.append(dict(asal=r['code'],kode=k,dikoreksi=(k!=r['code']),nama=r['nama'],status=r['status'],nilai=str(r['nilai']),mulai=str(r['mulai'])[:10],selesai=str(r['selesai'])[:10],pimpro=r['pimpro'] or r['pimpro2'],vp=r['vp']))
json.dump(out,open('proyek5000.json','w'),ensure_ascii=False,indent=1)
for o in out: print(o['asal'].ljust(17),'->',o['kode'].ljust(13),'*' if o['dikoreksi'] else ' ',o['nama'][:36])
