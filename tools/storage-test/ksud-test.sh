#!/system/bin/sh
set -eu
umask 077
BASE=/data/adb/ace5-ksud-test
LIVE=/data/adb/ksud
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
fail() { echo "$*" >&2; exit 1; }
hash() { sha256sum "$1" | awk '{print $1}'; }
[ "$(id -u)" = 0 ] || fail "Run from a terminal granted root by the official YukiSU manager"
[ -f "$LIVE" ] && [ ! -L "$LIVE" ] || fail "Regular installed ksud required"
case "${1:-status}" in
 status)
  "$LIVE" version
  hash "$LIVE"
  [ ! -f "$BASE/original.sha256" ] || cat "$BASE/original.sha256"
  exit 0
  ;;
 install|restore) ;;
 *) fail "Usage: sh ksud-test.sh status|install|restore" ;;
esac
[ ! -L "$BASE" ] || fail "Unsafe backup directory"
mkdir -p "$BASE"
chmod 700 "$BASE"
mkdir "$BASE/lock" || fail "Another operation is active"
TEMP="$BASE/candidate"
trap 'rm -f "$TEMP"; rmdir "$BASE/lock"' EXIT
if [ "$1" = install ]; then
 [ ! -e "$BASE/original" ] || fail "Backup already exists; restore it first"
 EXPECTED=$(cat "$HERE/ksud.sha256")
 [ "$(hash "$HERE/ksud")" = "$EXPECTED" ] || fail "Package hash mismatch"
 cp "$HERE/ksud" "$TEMP"
 chmod 755 "$TEMP"
 chown 0:0 "$TEMP"
 chcon u:object_r:ksu_file:s0 "$TEMP"
 KERNEL=$("$LIVE" debug info | sed -n 's/^uapi_version: //p')
 BUNDLED=$("$TEMP" version | sed -n 's/.*uapi: \([0-9][0-9]*\)).*/\1/p')
 [ -n "$KERNEL" ] && [ "$KERNEL" != 0 ] && [ "$KERNEL" = "$BUNDLED" ] || fail "Kernel/binary UAPI mismatch"
 cp -p "$LIVE" "$BASE/original"
 hash "$BASE/original" > "$BASE/original.sha256"
 cp "$0" "$BASE/ksud-test.sh"
else
 [ -f "$BASE/original" ] && [ ! -L "$BASE/original" ] || fail "Backup missing"
 [ "$(hash "$BASE/original")" = "$(cat "$BASE/original.sha256")" ] || fail "Backup hash mismatch"
 cp "$BASE/original" "$TEMP"
 chmod 755 "$TEMP"
 chown 0:0 "$TEMP"
 chcon u:object_r:ksu_file:s0 "$TEMP"
fi
EXPECTED=$(hash "$TEMP")
sync
mv -f "$TEMP" "$LIVE"
sync
[ "$(hash "$LIVE")" = "$EXPECTED" ] || fail "Installed hash mismatch"
echo "ksud replaced. Reboot manually; the running daemon has not been replaced."
echo "Restore: su -c 'sh /data/adb/ace5-ksud-test/ksud-test.sh restore'"
