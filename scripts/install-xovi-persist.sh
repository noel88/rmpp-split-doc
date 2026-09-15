#!/bin/sh
# install-xovi-persist.sh — load xovi into xochitl on every boot (Paper Pro family).
#
# WHY: /etc on the Paper Pro is an overlay backed by tmpfs, so a systemd drop-in
# written under /etc/systemd/system/xochitl.service.d/ is WIPED on every reboot,
# and xochitl then starts WITHOUT LD_PRELOAD (xovi/qmldiff never load).
#
# FIX: the rootfs (ext4, mounted ro) can be remounted rw and is PERSISTENT.
# systemd also reads drop-ins from /usr/lib/systemd/system/xochitl.service.d/,
# so the override is written there. The drop-in also enables QML file
# read/write, which the memo feature and last-document storage rely on.
#
# A firmware UPDATE overwrites the rootfs and removes this drop-in. After an
# update, run `xovi/rebuild_hashtable` FIRST, then re-run this script. Enabling
# xovi with a hashtab from another firmware version crash-loops xochitl.
#
# Run this ON THE DEVICE (or via: ssh root@10.11.99.1 'sh -s' < this-file).
set -u
DROPIN_DIR=/usr/lib/systemd/system/xochitl.service.d
DROPIN=$DROPIN_DIR/zz-xovi.conf
XOVI_SO=/home/root/xovi/xovi.so
HASHTAB=/home/root/xovi/exthome/qt-resource-rebuilder/hashtab

log() { echo "[install-xovi-persist] $*"; }

[ -f "$XOVI_SO" ] || { log "ERROR: $XOVI_SO not found — install xovi first"; exit 1; }
[ -f "$HASHTAB" ] || { log "ERROR: $HASHTAB not found — run /home/root/xovi/rebuild_hashtable first"; exit 1; }

log "Remounting / read-write"
mount -o remount,rw / 2>/dev/null || { log "ERROR: cannot remount / rw"; exit 1; }

log "Writing persistent override -> $DROPIN"
mkdir -p "$DROPIN_DIR"
cat > "$DROPIN" <<'EOF'
[Unit]
# /home is an encrypted disk that mounts late; xochitl.service only orders after
# data.mount. Without help it can start before /home is mounted, so xovi.so
# (under /home/root) is not yet accessible and the LD_PRELOAD is ignored for the
# whole boot. RequiresMountsFor orders after home.mount; the ExecStartPre below
# is the real guard (waits until xovi.so is readable). JobTimeoutSec is raised so
# that wait can never trip the stock 60s job timeout (-> OnFailure -> boot loop).
RequiresMountsFor=/home/root/xovi/xovi.so
JobTimeoutSec=300

[Service]
ExecStartPre=/bin/sh -c 'n=0; while [ ! -r /home/root/xovi/xovi.so ] && [ $n -lt 60 ]; do sleep 0.5; n=$((n+1)); done'
Environment="QML_DISABLE_DISK_CACHE=1"
Environment="QML_XHR_ALLOW_FILE_WRITE=1"
Environment="QML_XHR_ALLOW_FILE_READ=1"
Environment="LD_PRELOAD=/home/root/xovi/xovi.so"
EOF
chmod 644 "$DROPIN"
sync

# Remove the volatile /etc copy to avoid confusion (harmless if absent).
rm -f /etc/systemd/system/xochitl.service.d/xovi.conf 2>/dev/null

log "Restoring / read-only"
mount -o remount,ro / 2>/dev/null || true

log "Reloading systemd + restarting xochitl"
systemctl daemon-reload
systemctl restart xochitl || log "xochitl restart returned non-zero (often expected on xovi activation)"

log "Done. Verify with: cat /proc/\$(pidof xochitl)/environ | tr '\\0' '\\n' | grep xovi.so"
