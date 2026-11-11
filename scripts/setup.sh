#!/usr/bin/env bash
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
#
# Установка Antigravity на Intel Mac «с нуля»:
#   1. скачивает официальный DMG;
#   2. ставит приложение в ~/Applications (в обход TCC App Management);
#   3. скачивает патчер;
#   4. патчит language_server;
#   5. переподписывает бандл;
#   6. проверяет и запускает.
#
# Использование:
#   ./scripts/setup.sh
#   FORCE=1 ./scripts/setup.sh                  # переустановить поверх
#   DMG_URL="https://..." ./scripts/setup.sh    # своя версия
#   ARCH_OK=1 ./scripts/setup.sh                # пропустить проверку Intel

set -euo pipefail

APP_DIR="${APP_DIR:-$HOME/Applications}"
APP="$APP_DIR/Antigravity.app"
TOOLS_DIR="${TOOLS_DIR:-$HOME/Applications/agy-tools}"
PATCHER="${PATCHER:-$TOOLS_DIR/patcher.py}"
PATCHER_URL="${PATCHER_URL:-https://raw.githubusercontent.com/trustybird/agy-unlock/main/patcher.py}"
DMG_URL="${DMG_URL:-https://storage.googleapis.com/antigravity-public/antigravity-hub/2.31.0-6379060755038208/darwin-x64/Antigravity.dmg}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=anti-resale.sh
. "$SCRIPT_DIR/anti-resale.sh"
print_anti_resale_banner

die() {
    echo "Ошибка: $*" >&2
    exit 1
}

info() {
    echo "==> $*"
}

[ "$(uname -s)" = "Darwin" ] || die "скрипт только для macOS"

ARCH="$(uname -m)"
if [ "$ARCH" != "x86_64" ] && [ "${ARCH_OK:-0}" != "1" ]; then
    echo "Внимание: архитектура $ARCH, а гайд проверен на Intel x64." >&2
    echo "Если вы уверены, запустите: ARCH_OK=1 $0" >&2
    exit 1
fi

command -v python3 >/dev/null || die "нужен python3"
command -v codesign >/dev/null || die "нужен codesign (xcode-select --install)"
command -v hdiutil >/dev/null || die "нужен hdiutil"
command -v curl >/dev/null || die "нужен curl"

if [ -d "$APP" ]; then
    if [ "${FORCE:-0}" != "1" ]; then
        die "уже существует $APP. Переустановить: FORCE=1 $0"
    fi
    info "Удаляю старую копию: $APP"
    rm -rf "$APP"
fi

TMP="$(mktemp -d)"
MOUNT=""

cleanup() {
    if [ -n "$MOUNT" ]; then
        hdiutil detach "$MOUNT" -quiet 2>/dev/null || true
    fi
    rm -rf "$TMP"
}
trap cleanup EXIT

info "Скачиваю DMG"
echo "    $DMG_URL"
curl -fL --retry 3 --max-time 900 -o "$TMP/Antigravity.dmg" "$DMG_URL"

info "Монтирую образ"
MOUNT="$(hdiutil attach -nobrowse -readonly "$TMP/Antigravity.dmg" \
    | awk -F'\t' '/\/Volumes\// {print $NF; exit}')"
[ -n "$MOUNT" ] || die "не удалось смонтировать DMG"

SRC_APP="$(find "$MOUNT" -maxdepth 2 -name "Antigravity.app" -print -quit)"
[ -n "$SRC_APP" ] || die "в образе не найден Antigravity.app"

info "Устанавливаю в $APP"
mkdir -p "$APP_DIR"
cp -R "$SRC_APP" "$APP"
xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

hdiutil detach "$MOUNT" -quiet 2>/dev/null || true
MOUNT=""

info "Скачиваю патчер"
mkdir -p "$TOOLS_DIR"
curl -fL --retry 2 --max-time 180 -o "$PATCHER" "$PATCHER_URL"

LS="$APP/Contents/Resources/bin/language_server"
[ -f "$LS" ] || die "в приложении нет language_server"

info "Сохраняю оригинал"
cp "$LS" "$LS.agybak"

info "Патчу language_server"
python3 "$PATCHER" unlock manager --path "$LS"

info "Добавляю напоминание о бесплатности"
write_free_notice "$APP/Contents/Resources/FREE_NOTICE.txt"
write_free_notice "$APP_DIR/FREE_NOTICE.txt"

info "Переподписываю бандл"
python3 "$SCRIPT_DIR/resign.py" "$APP"

info "Проверяю результат"
PATCHED="$(grep -a -o "inexigible" "$LS" | wc -l | tr -d ' ')"
echo "    вхождений inexigible: $PATCHED (ожидается 8)"
codesign --verify --deep --strict "$APP"
echo "    подпись: OK"

info "Запускаю Antigravity"
open "$APP"

cat <<'EOF'

Готово.

Дальше:
  1. Включите VPN со страной, где сервис доступен.
  2. Войдите в свой Google-аккаунт.
  3. Отправьте тестовый запрос в чат.

Если что-то сломалось:
  ./scripts/doctor.sh          — диагностика
  ./scripts/repatch.sh         — перепатч после обновления
EOF
