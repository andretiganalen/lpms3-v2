import os,sys,pymysql,json
env={}
for l in open('/home/ubuntu/lpms3/.env'):
    l=l.strip()
    if l.startswith('DB_CONNECTION_STRING='): env=dict(p.split("=",1) for p in l.split("=",1)[1].split(";") if "=" in p)
cn=pymysql.connect(host=env['Server'],port=int(env.get('Port',3306)),user=env['User'],password=env['Password'],database=env['Database'],charset='utf8mb4',connect_timeout=8,read_timeout=30)
cn.autocommit(False)
cur=cn.cursor(pymysql.cursors.DictCursor)
def q(sql,args=None):
    assert sql.strip().lower().startswith(('select','show','describe')), "read-only"
    cur.execute(sql,args); return cur.fetchall()
