#!/bin/sh

# Run backup function
backup() {
  echo "Starting pg_dump at $(date)"
  export PGPASSWORD="${POSTGRES_PASSWORD}"
  /usr/bin/pg_dump -h "${POSTGRES_ADDR}" -U "${POSTGRES_USER}" "${POSTGRES_DB}" | gzip > /backups/backup_$(date +%Y%m%d_%H%M%S).sql.gz
  echo "Backup completed at $(date)"
}

# Run initial backup at script start (optional)
backup
