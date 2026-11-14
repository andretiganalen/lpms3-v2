import logging
import os
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


def main():
    interval = float(os.environ.get("SYNC_INTERVAL", 5))
    recon_every = float(os.environ.get("RECONCILE_INTERVAL", 86400))
    pg = psycopg.connect(os.environ["PG_DSN"], autocommit=True)
    s = Syncer(pg, sr_connect)
    last_recon = 0.0
    log.info("lpms3-data mulai; interval=%ss", interval)
    while True:
        try:
            n = s.run_once()
            if n == 0:
                time.sleep(interval)
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
