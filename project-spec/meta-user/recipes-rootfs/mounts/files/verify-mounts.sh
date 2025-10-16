#!/usr/bin/env bash
# verify-storage-logs.sh
# Verifies SD mounts and that /var/log is bound to /mnt/storage/logs/system with persistent journald.
# No systemctl usage.

set -u

# -------- Config (adjust mount points or labels if yours differ) --------
REQUIRED_MOUNTS=(
  "/mnt/storage/hk"
  "/mnt/storage/logs"
  "/mnt/storage/fsw"
  "/mnt/storage/iris"
  "/mnt/storage/dfgm"
)

LOGS_MOUNT="/mnt/storage/logs"
VARLOG_BIND_SOURCE="/mnt/storage/logs/system"
VARLOG_TARGET="/var/log"
JOURNAL_DIR="${VARLOG_TARGET}/journal"

# -------- Helpers --------
ok()   { printf "\033[1;32m[ OK ]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[FAIL]\033[0m %s\n" "$*"; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }

findmnt_field() {
  # findmnt_field <target> <field>
  # field examples: SOURCE,FSTYPE,OPTIONS
  findmnt -n -o "$2" --target "$1" 2>/dev/null
}

is_bind_mount() {
  local target="$1"
  local opts
  opts="$(findmnt_field "$target" OPTIONS || true)"
  [[ "$opts" == *"bind"* ]]
}

same_underlying_source() {
  # Compare findmnt SOURCE of two targets
  local a="$1" b="$2" sa sb
  sa="$(findmnt_field "$a" SOURCE || true)"
  sb="$(findmnt_field "$b" SOURCE || true)"
  [[ -n "$sa" && -n "$sb" && "$sa" == "$sb" ]]
}

mountpoint_exists() {
  local d="$1"
  [[ -d "$d" ]] || return 1
  mountpoint -q "$d"
}

journal_files_present() {
  compgen -G "${JOURNAL_DIR}"'/*/*.journal' >/dev/null 2>&1
}

fs_for_path() {
  # Return the mount SOURCE backing a path
  findmnt -n -o SOURCE --target "$1" 2>/dev/null
}

mtime_ge_boot() {
  # true if any journal file mtime >= btime
  local btime files mt
  btime="$(awk '/^btime /{print $2}' /proc/stat 2>/dev/null || echo "")"
  [[ -n "$btime" ]] || return 1
  files=$(compgen -G "${JOURNAL_DIR}"'/*/*.journal' || true)
  [[ -n "$files" ]] || return 1
  for f in $files; do
    mt="$(stat -c %Y "$f" 2>/dev/null || echo 0)"
    (( mt >= btime )) && return 0
  done
  return 1
}

# -------- Checks --------
fail_count=0

echo "=== SD Partition Mounts ==="
if ! have_cmd findmnt; then
  err "findmnt not found; please install util-linux."
  exit 2
fi

for m in "${REQUIRED_MOUNTS[@]}"; do
  if mountpoint_exists "$m"; then
    src=$(findmnt_field "$m" SOURCE)
    fstype=$(findmnt_field "$m" FSTYPE)
    ok "$m is mounted (source: ${src:-unknown}, fstype: ${fstype:-unknown})"
  else
    err "$m is NOT mounted"
    ((fail_count++))
  fi
done

echo
echo "=== /var/log Bind Mount ==="
if mountpoint_exists "$LOGS_MOUNT"; then
  :
else
  warn "Logs mount ${LOGS_MOUNT} not mounted; subsequent checks may fail."
fi

if is_bind_mount "$VARLOG_TARGET"; then
  src=$(findmnt_field "$VARLOG_TARGET" SOURCE)
  if [[ "$src" == "$VARLOG_BIND_SOURCE" ]]; then
    ok "/var/log is a bind mount of ${VARLOG_BIND_SOURCE}"
  else
    err "/var/log is a bind mount, but SOURCE='${src}' (expected '${VARLOG_BIND_SOURCE}')"
    ((fail_count++))
  fi
else
  err "/var/log is NOT a bind mount"
  ((fail_count++))
fi

# Verify /var/log and /mnt/storage/logs/system sit on same underlying FS
if same_underlying_source "$VARLOG_TARGET" "$VARLOG_BIND_SOURCE"; then
  ok "/var/log and ${VARLOG_BIND_SOURCE} share the same backing filesystem"
else
  err "/var/log and ${VARLOG_BIND_SOURCE} do NOT share the same backing filesystem"
  ((fail_count++))
fi

echo
echo "=== Persistent Journal on Logs Partition ==="
if [[ -d "$JOURNAL_DIR" ]]; then
  ok "Journal directory exists at ${JOURNAL_DIR}"
else
  err "Journal directory missing at ${JOURNAL_DIR}"
  ((fail_count++))
fi

# Ensure the journal dir resides on the Logs partition
varlog_fs=$(fs_for_path "$VARLOG_TARGET")
logs_fs=$(fs_for_path "$LOGS_MOUNT")
if [[ -n "$varlog_fs" && -n "$logs_fs" ]]; then
  if [[ "$varlog_fs" == "$logs_fs" ]]; then
    ok "Journal lives on same filesystem as ${LOGS_MOUNT} (source: ${varlog_fs})"
  else
    err "Journal filesystem (${varlog_fs}) differs from ${LOGS_MOUNT} (${logs_fs})"
    ((fail_count++))
  fi
else
  warn "Could not resolve filesystem sources for ${VARLOG_TARGET} and/or ${LOGS_MOUNT}"
fi

# Check there are journal files
if journal_files_present; then
  ok "Journal files present in ${JOURNAL_DIR}"
else
  err "No journal files found in ${JOURNAL_DIR}"
  ((fail_count++))
fi

# Check some journal file has mtime >= boot time (i.e., flushed since boot)
if mtime_ge_boot; then
  ok "Persistent journal has entries from this boot (mtime >= kernel btime)"
else
  warn "Could not confirm persistent journal entries since this boot (may still be using runtime journal)"
fi

# Optional: sanity check via journalctl (not using systemctl)
if have_cmd journalctl; then
  echo
  echo "=== journalctl Sanity ==="
  if journalctl -b --no-pager >/dev/null 2>&1; then
    ok "journalctl can read current-boot logs"
  else
    warn "journalctl -b failed; check permissions or journal state"
  fi
  # show disk usage and ensure it points to the Logs filesystem
  du_out=$(journalctl --disk-usage 2>/dev/null || true)
  echo "journalctl --disk-usage: ${du_out:-unavailable}"
else
  warn "journalctl not available; skipping journal content checks"
fi

echo
if (( fail_count == 0 )); then
  ok "All critical checks passed."
  exit 0
else
  err "$fail_count check(s) failed."
  exit 1
fi
