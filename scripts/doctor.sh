#!/usr/bin/env bash
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
#
# Диагностика установки Antigravity.
# Ничего не меняет — только читает состояние и печатает отчёт.

set -uo pipefail

APP="${APP:-$HOME/Applications/Antigravity.app}"
LS="$APP/Contents/Resources/bin/language_server"
LOG="${LOG:-$HOME/Library/Logs/Antigravity/language_server.log}"
MAIN_LOG="${MAIN_LOG:-$HOME/Library/Logs/Antigravity/main.log}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=anti-resale.sh
. "$SCRIPT_DIR/anti-resale.sh"
print_anti_resale_banner

GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
DIM="\033[2m"
RESET="\033[0m"

ok()   { printf "${GREEN}  OK${RESET}   %s\n" "$*"; }
bad()  { printf "${RED}  FAIL${RESET} %s\n" "$*"; }
warn() { printf "${YELLOW}  WARN${RESET} %s\n" "$*"; }
head_() { printf "\n${DIM}%s${RESET}\n" "$*"; }

ERRORS=0

head_ "Приложение"
if [ -d "$APP" ]; then
    ok "найдено: $APP"
    VERSION="$(defaults read "$APP/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "?")"
    ok "версия: $VERSION"
else
    bad "не найдено: $APP"
    echo "       Установите: ./scripts/setup.sh"
    exit 1
fi

head_ "Патч language_server"
if [ -f "$LS" ]; then
    COUNT="$(grep -a -o "inexigible" "$LS" 2>/dev/null | wc -l | tr -d ' ')"
    if [ "$COUNT" -ge 8 ]; then
        ok "гейты применены (inexigible: $COUNT)"
    elif [ "$COUNT" -gt 0 ]; then
        warn "частичный патч (inexigible: $COUNT, ожидается 8)"
        ERRORS=$((ERRORS + 1))
    else
        bad "патч не найден"
        echo "       Запустите: ./scripts/repatch.sh"
        ERRORS=$((ERRORS + 1))
    fi
    if [ -f "$LS.agybak" ]; then
        ok "бэкап оригинала: есть"
    else
        warn "бэкап оригинала отсутствует ($LS.agybak)"
    fi
else
    bad "не найден language_server"
    ERRORS=$((ERRORS + 1))
fi

head_ "Подпись"
if codesign --verify --deep --strict "$APP" >/dev/null 2>&1; then
    ok "codesign --verify --deep --strict: 0"
else
    bad "подпись невалидна"
    echo "       Исправьте: ./scripts/resign.py \"$APP\""
    ERRORS=$((ERRORS + 1))
fi

head_ "Процессы"
if pgrep -f "Antigravity.app/Contents/MacOS/Antigravity" >/dev/null 2>&1; then
    ok "Antigravity запущен"
else
    warn "Antigravity не запущен"
fi
if pgrep -f "Antigravity.app/Contents/Resources/bin/language_server" >/dev/null 2>&1; then
    ok "language_server запущен"
else
    warn "language_server не запущен"
fi

head_ "VPN / регион"
IPINFO="$(curl -s --max-time 10 https://ipinfo.io/json 2>/dev/null || true)"
if [ -n "$IPINFO" ]; then
    COUNTRY="$(printf '%s' "$IPINFO" | tr ',' '\n' | sed -n 's/.*"country": *"\([^"]*\)".*/\1/p' | head -1)"
    REGION="$(printf '%s' "$IPINFO" | tr ',' '\n' | sed -n 's/.*"region": *"\([^"]*\)".*/\1/p' | head -1)"
    if [ "$COUNTRY" = "US" ]; then
        ok "выход: $COUNTRY / $REGION"
    else
        warn "выход: ${COUNTRY:-?} / ${REGION:-?} — проверьте, что страна поддерживается"
    fi
else
    warn "не удалось определить внешний IP"
fi

head_ "Логи"
if [ -f "$LOG" ]; then
    if grep -q "You are not logged into Antigravity" "$LOG" 2>/dev/null; then
        warn "в логе есть «not logged into Antigravity» — войдите в аккаунт"
    else
        ok "ошибок входа не найдено"
    fi
    if grep -q "LOCATION_NOT_ELIGIBLE" "$LOG" 2>/dev/null; then
        warn "в логе есть LOCATION_NOT_ELIGIBLE (обычно не фатально: клиент делает fallback)"
    else
        ok "LOCATION_NOT_ELIGIBLE не найден"
    fi
    if grep -q "Library not loaded" "$LOG" 2>/dev/null; then
        bad "в логе есть ошибка загрузки библиотек — переподпишите бандл"
        ERRORS=$((ERRORS + 1))
    fi
else
    warn "лог не найден: $LOG"
fi

if [ -f "$MAIN_LOG" ] && grep -q "did not pass validation" "$MAIN_LOG" 2>/dev/null; then
    warn "автообновление пыталось установиться и было отклонено (это ожидаемо)"
fi

head_ "Итог"
if [ "$ERRORS" -eq 0 ]; then
    ok "критических проблем не найдено"
else
    bad "проблем: $ERRORS — см. docs/troubleshooting.md"
fi
