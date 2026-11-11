#!/usr/bin/env bash
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
#
# Повторный патч Antigravity после обновления.
#
# Использование:
#   ./scripts/repatch.sh
#   APP=/path/to/Antigravity.app ./scripts/repatch.sh
#   LAUNCH=1 ./scripts/repatch.sh     # ещё и запустить приложение

set -euo pipefail

APP="${APP:-$HOME/Applications/Antigravity.app}"
TOOLS_DIR="${TOOLS_DIR:-$HOME/Applications/agy-tools}"
PATCHER="${PATCHER:-$TOOLS_DIR/patcher.py}"
PATCHER_URL="${PATCHER_URL:-https://raw.githubusercontent.com/trustybird/agy-unlock/main/patcher.py}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LS="$APP/Contents/Resources/bin/language_server"

# shellcheck source=anti-resale.sh
. "$SCRIPT_DIR/anti-resale.sh"
print_anti_resale_banner

die() {
    echo "Ошибка: $*" >&2
    exit 1
}

[ -d "$APP" ] || die "приложение не найдено: $APP"
[ -f "$LS" ] || die "не найден language_server: $LS"
command -v python3 >/dev/null || die "нужен python3"
command -v codesign >/dev/null || die "нужен codesign (Command Line Tools)"

mkdir -p "$TOOLS_DIR"
if [ ! -f "$PATCHER" ]; then
    echo "Скачиваю патчер: $PATCHER_URL"
    curl -fL --retry 2 --max-time 180 -o "$PATCHER" "$PATCHER_URL"
fi

# Сохраняем оригинал только один раз — чтобы откат всегда возвращал чистый файл.
if [ ! -f "$LS.agybak" ]; then
    cp "$LS" "$LS.agybak"
    echo "Бэкап оригинала: $LS.agybak"
fi

if python3 "$PATCHER" status --path "$LS" 2>/dev/null | grep -q "статус: patched"; then
    echo "language_server уже пропатчен."
else
    echo "Патчу language_server..."
    python3 "$PATCHER" unlock manager --path "$LS"
fi

echo "Добавляю напоминание о бесплатности..."
write_free_notice "$APP/Contents/Resources/FREE_NOTICE.txt"
write_free_notice "$(dirname "$APP")/FREE_NOTICE.txt"

echo "Переподписываю бандл..."
python3 "$SCRIPT_DIR/resign.py" "$APP"

xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true
echo "Готово: пропатчено и переподписано."

if [ "${LAUNCH:-0}" = "1" ]; then
    open "$APP"
fi
