import logging
import os
import sys
import time

import psycopg
import pymysql

from .sync import MAX_ATTEMPTS, Syncer

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")
log = logging.getLogger("lpms3_data")


def sr_connect():
    return pymysql.connect(host=os.environ["STARROCKS_HOST"], port=int(os.environ.get("STARROCKS_PORT", 9030)),
                           user=os.environ["STARROCKS_USER"], password=os.environ["STARROCKS_PASSWORD"],
                           database=os.environ.get("STARROCKS_DATABASE", "medallion_lpms"), autocommit=True, connect_timeout=10)


REPLICATION = os.environ.get("STARROCKS_REPLICATION_NUM", "1")


def refresh(s):
    try:
        s.refresh_registry(REPLICATION)
    except Exception:  # noqa: BLE001  (mis. db/070 belum diterapkan -> tetap jalan dengan pemetaan statis)
        log.exception("refresh registry gagal")
        s._reset_sr()


def main():
    interval = float(os.environ.get("SYNC_INTERVAL", 5))
    recon_every = float(os.environ.get("RECONCILE_INTERVAL", 86400))
    registry_every = float(os.environ.get("REGISTRY_INTERVAL", 300))
    pg = psycopg.connect(os.environ["PG_DSN"], autocommit=True)
    s = Syncer(pg, sr_connect)
    if sys.argv[1:2] == ["ddl"]:  # cetak DDL tabel StarRocks yang belum ada (untuk admin, lihat db/starrocks/120)
        print("\n\n".join(s.missing_ddl(sys.argv[2] if len(sys.argv) > 2 else "${STARROCKS_REPLICATION_NUM}")))
        return
    refresh(s)
    last_recon, last_reg = 0.0, time.time()
    log.info("lpms3-data mulai; interval=%ss", interval)
    while True:
        try:
            n = s.run_once()
            if n == 0:
                time.sleep(interval)
            if time.time() - last_reg > registry_every:
                refresh(s)
                last_reg = time.time()
            if time.time() - last_recon > recon_every:
                s.reconcile()
                last_recon = time.time()
            with pg.cursor() as c:
                c.execute("SELECT count(*) FROM lpms3.sync_outbox WHERE synced_at IS NULL AND attempts >= %s", (MAX_ATTEMPTS,))
                dead = c.fetchone()[0]
            if dead:
                log.error("ALARM: %s entri outbox gagal permanen (attempts>=%s)", dead, MAX_ATTEMPTS)
        except Exception:  # noqa: BLE001
            log.exception("loop error")
            time.sleep(interval * 3)


if __name__ == "__main__":
    main()
