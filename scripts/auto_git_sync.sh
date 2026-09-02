#!/usr/bin/env bash
set -u

REPO_DIR="/home/abhi/Desktop/College/Underbets/SIH/Senvo"
LOG_FILE="/tmp/senvo_git_sync.log"

mkdir -p "$(dirname "$LOG_FILE")"

echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Starting Git sync" >> "$LOG_FILE"

cd "$REPO_DIR" || {
  echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Repository not found: $REPO_DIR" >> "$LOG_FILE"
  exit 1
}

git fetch --all --prune >> "$LOG_FILE" 2>&1 || {
  echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Fetch failed" >> "$LOG_FILE"
  exit 1
}

if ! git diff --quiet || ! git diff --cached --quiet; then
  git add -A
  git commit -m "chore: auto-sync latest local changes" >> "$LOG_FILE" 2>&1 || {
    echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Nothing new to commit" >> "$LOG_FILE"
  }
fi

git pull --rebase origin main >> "$LOG_FILE" 2>&1 || {
  echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Pull/rebase failed; resolve conflicts manually" >> "$LOG_FILE"
  exit 1
}

echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Git sync completed" >> "$LOG_FILE"
