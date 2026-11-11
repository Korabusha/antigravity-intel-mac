#!/usr/bin/env bash
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
#
# Единый анти-реселл баннер и генератор FREE_NOTICE.txt.
# Подключается через: . "$SCRIPT_DIR/anti-resale.sh"
#
# Идея: любой запуск скриптов и любой экземпляр приложения тащат с собой
# видимое напоминание, что проект бесплатный. Убрать его можно только
# сознательно нарушив лицензию — и это уже доказательство барыжничества.

print_anti_resale_banner() {
    cat <<'EOF'
============================================================
  ЭТОТ ПРОЕКТ БЕСПЛАТНЫЙ. ПРОДАЖА ЗАПРЕЩЕНА.
  Если вы заплатили — вас обманули, а продавец занимается
  барыжничеством. Бесплатные ссылки:

  https://github.com/Korabusha/antigravity-intel-mac
  https://github.com/trustybird/agy-unlock
  https://github.com/QNIX-Dev/eligibility-antigravity-patcher
  https://github.com/vezlin1/antigravity-bypass-russia
  https://github.com/confeden/Antigravity

  Полный список: docs/sources.md
  Все проекты в списке проверены: только бесплатные, без
  пробных периодов и доплат.
  Лицензия: PolyForm Noncommercial 1.0.0
============================================================
EOF
}

write_free_notice() {
    local target="$1"
    mkdir -p "$(dirname "$target")"
    cat > "$target" <<'EOF'
ЭТОТ ПРОЕКТ БЕСПЛАТНЫЙ. ПРОДАЖА ЗАПРЕЩЕНА.

Если вы заплатили за это приложение, установку, «настройку под ключ»,
подписку, доступ по инвайту или «премиум-сборку» — вас обманули.
Продавец занимается барыжничеством: всё это лежит в открытом доступе
бесплатно.

Бесплатные источники:

  Основной репозиторий:
    https://github.com/Korabusha/antigravity-intel-mac

  Патчер language_server:
    https://github.com/trustybird/agy-unlock

  Байтовые сигнатуры и исследования:
    https://github.com/QNIX-Dev/eligibility-antigravity-patcher
    https://github.com/vezlin1/antigravity-bypass-russia
    https://github.com/confeden/Antigravity
    https://github.com/sara-dev12/open-antigravity-patcher
    https://github.com/top-master/ai-antigravity-patcher
    https://github.com/NoRoute2Koi/open-antigravity-patcher-nix

  Другие свободные реализации:
    https://github.com/kakajan/antigravity-patch
    https://github.com/Quenary/antigravity-patcher
    https://github.com/BenSouchet/antigravity-patcher
    https://github.com/RendeRR/antigravity-patcher
    https://github.com/yhan-sun/antigravity-patcher
    https://github.com/mhosseini-dev/antigravity-patch-macos

  Полный список с лицензиями:
    https://github.com/Korabusha/antigravity-intel-mac/blob/main/docs/sources.md

Важно: все источники выше — бесплатные целиком. Среди них нет проектов
с «бесплатным тестом» и последующей оплатой. Если вам продали «тестовый
доступ» или «ключ на 3 дня», а потом попросили денег — это не наш проект
и не наш список. Это freemium-обман.

Отдельно предупреждаем: платные «шлюзы» и «клиенты без VPN», которые
продают ключи через Telegram-ботов (например, тарифы PRO/X3/X5/ULTRA),
к бесплатным источникам не относятся. Их мы не рекомендуем.

Лицензия проекта: PolyForm Noncommercial 1.0.0.
Коммерческое использование и продажа не разрешены.

Если вы нашли платную копию — откройте issue с меткой license-violation:
    https://github.com/Korabusha/antigravity-intel-mac/issues
EOF
}
