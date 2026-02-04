#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

CONFIG_FILE="./config.conf"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Config file not found: $CONFIG_FILE"
  exit 1
fi

# shellcheck disable=SC1090
source "$CONFIG_FILE"

if [[ -z "$BACKUP_DIR" || ${#SOURCE_DIRS[@]} -eq 0 ]]; then
  echo "Invalid configuration"
  exit 1
fi

log() {
  local msg="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') | $msg" | tee -a "$LOG_FILE"
}

log "Backup started"

mkdir -p "$BACKUP_DIR"
log "Backup directory: $BACKUP_DIR"

create_snapshot() {
  if [[ "$ENABLE_SNAPPER" == true ]]; then
    log "Creating snapper snapshot"
    snapper create --description "Automated backup $(date '+%Y-%m-%d %H:%M:%S')"
  else
    log "Snapper disabled"
  fi
}

create_snapshot

TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
ARCHIVE="backup_$TIMESTAMP.tar.gz"
ARCHIVE_PATH="$BACKUP_DIR/$ARCHIVE"

log "Creating archive $ARCHIVE"
tar -czf "$ARCHIVE_PATH" "${SOURCE_DIRS[@]}"

log "Cleaning backups older than $RETENTION_DAYS days"
find "$BACKUP_DIR" -type f -name "backup_*.tar.gz" -mtime +"$RETENTION_DAYS" -exec rm -f {} \;

log "Backup finished"

 
