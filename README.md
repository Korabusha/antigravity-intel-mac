# Antigravity на Intel Mac

Пошаговый гайд по запуску **Google Antigravity** на Intel-маках (x86_64) с обходом
региональной блокировки, патчем `language_server` и корректной переподписью
приложения под macOS.

> Проверено на: **MacBook Pro 14,1 (2017), Intel Core i5, macOS 13.7.8 (22H730)**,
> Antigravity **2.31.0 (darwin-x64)**, US VPN.

> [!WARNING]
> **Проект бесплатный. Продажа запрещена.**
> Если вы заплатили за это приложение, установку, «настройку под ключ» или
> подписку — вас обманули, а продавец занимается барыжничеством.
> Все бесплатные ссылки: [docs/sources.md](docs/sources.md).
> Подробнее: [NOTICE.md](NOTICE.md) и [docs/anti-resale.md](docs/anti-resale.md).

---

## Содержание

- [Что это](#что-это)
- [Если вы заплатили](#если-вы-заплатили)
- [Дисклеймер](#дисклеймер)
- [Требования](#требования)
- [Как это работает](#как-это-работает)
- [Быстрый старт](#быстрый-старт)
- [Ручная установка по шагам](#ручная-установка-по-шагам)
- [Проверка результата](#проверка-результата)
- [Обновления приложения](#обновления-приложения)
- [Откат](#откат)
- [Диагностика](#диагностика)
- [FAQ](#faq)
- [Структура репозитория](#структура-репозитория)
- [Источники](#источники)
- [Благодарности](#благодарности)
- [Лицензия](#лицензия)

---

## Что это

Google Antigravity — среда разработки с ИИ-агентом. Официально она недоступна
в России: клиент проверяет регион и отказывается работать. Этот репозиторий
содержит:

- инструкцию по установке **официального** дистрибутива Antigravity для Intel Mac;
- патч `language_server`, снимающий три клиентские проверки;
- инструмент корректной переподписи `.app`-бандла, без которого приложение
  падает с `Library not loaded: @rpath/Electron Framework.framework`;
- скрипты повторного патча после автообновления, диагностики и отката.

Репозиторий **не содержит кода Google** и **не перепубликует** сторонний патчер:
он скачивается с upstream-репозитория при установке.

---

## Если вы заплатили

**Стоп. Этот проект бесплатный целиком.**

Если вам продали «сборку», «установку», «настройку под ключ», «доступ» или
«подписку» — вас обманули. Продавец занимается **барыжничеством**: всё, что
здесь лежит, доступно бесплатно и открыто.

Что делать:

1. Не платите больше.
2. Потребуйте возврат.
3. Откройте issue с меткой `license-violation`:
   <https://github.com/Korabusha/antigravity-intel-mac/issues>
4. Сверьтесь с бесплатными источниками: [docs/sources.md](docs/sources.md).

Скрипты при каждом запуске печатают предупреждение, а внутри приложения лежит
`Contents/Resources/FREE_NOTICE.txt` — он уезжает вместе с любой «платной
сборкой». Убрать его без переподписи нельзя: сломается подпись, и приложение
не запустится.

---

## Дисклеймер

Проект носит **технически-образовательный** характер. Патчинг клиента и обход
региональных ограничений могут нарушать условия использования Google.
Используйте на свой риск и, если это возможно, дождитесь официального
одобрения смены региона аккаунта.

Авторы не несут ответственности за блокировки аккаунта, потерю данных или
последствия автообновлений. Все действия выполняются локально, на вашей машине.

---

## Требования

| Компонент | Минимум |
|---|---|
| macOS | 12+ (тестировалось на 13.7.8) |
| Процессор | Intel x64 (для Apple Silicon инструкция не проверялась) |
| Python | 3.9+ (встроенный `python3`) |
| Command Line Tools | `xcode-select --install` |
| VPN | Включённый, с выходом в поддерживаемой стране (например, US) |
| Свободное место | ~2 ГБ |

Проверить архитектуру и Python:

```bash
uname -m          # ожидается x86_64
python3 --version # ожидается 3.9+
xcode-select -p   # путь к CLT; если пусто — установите CLT
```

---

## Как это работает

### 1. Три клиентские проверки

В бинарнике `Contents/Resources/bin/language_server` есть три байтовых гейта:

| Гейт | Что проверяет | Что делает патч |
|---|---|---|
| `auth` | валидность локальной авторизации | принудительно `true` |
| `elig` | экран «регион не поддерживается» | обнуляет переход на экран блокировки |
| `rename` | переименование/подмена полей | патчит вызов |

Патчер ищет **байтовые сигнатуры**, а не фиксированные смещения, поэтому патч
переживает пересборки функций между версиями.

### 2. Почему нельзя просто переподписать всё «как есть»

Оригинальный бандл Google подписан **одним Team ID**. После ad-hoc переподписи
(`codesign --sign -`) Team ID исчезает, и dyld отказывается загружать
`Electron Framework`:

```
mapped file has no Team ID and is not a platform binary
Library not loaded: @rpath/Electron Framework.framework/Electron Framework
```

Решение — добавить **каждому** исполняемому файлу и бандлу entitlement
`com.apple.security.cs.disable-library-validation`, а затем подписать всё
консистентно, изнутри наружу.

### 3. Почему приложение ставится в `~/Applications`

На macOS 13+ действует защита **App Management** (TCC): запись внутрь
`/Applications/Antigravity.app` блокируется даже для `root`:

```
Operation not permitted
```

Поэтому рабочая копия ставится в `~/Applications/Antigravity.app`, где TCC
не мешает патчингу и переподписи.

### 4. Серверная проверка региона

Даже с пропатченным клиентом Google может ответить:

```json
{
  "code": 403,
  "status": "PERMISSION_DENIED",
  "message": "Your location is not eligible for this service at this time. Detected location: RU.",
  "reason": "LOCATION_NOT_ELIGIBLE"
}
```

Это применяется к дополнительному запросу `FetchConfig`. Клиент **не падает**:
он откатывается на старый путь `ListExperiments`, и чат продолжает работать.
Если же отказ приходит и на основные запросы — включите VPN с выходом
в поддерживаемой стране.

---

## Быстрый старт

```bash
git clone https://github.com/Korabusha/antigravity-intel-mac.git
cd antigravity-intel-mac

# 1. Установить официальный Antigravity в ~/Applications
./scripts/setup.sh

# 2. Проверить результат
./scripts/doctor.sh
```

`setup.sh` скачает официальный DMG, распакует приложение в `~/Applications`,
скачает патчер, пропатчит `language_server`, переподпишет бандл и запустит
приложение.

Если приложение уже установлено и нужно только перепатчить:

```bash
./scripts/repatch.sh
```

---

## Ручная установка по шагам

### Шаг 1. Скачать официальный DMG (Intel)

Актуальную ссылку смотрите на <https://antigravity.google/download>.
Для версии 2.31.0 x64:

```bash
mkdir -p ~/Downloads/antigravity
cd ~/Downloads/antigravity

curl -fL -o Antigravity.dmg \
  "https://storage.googleapis.com/antigravity-public/antigravity-hub/2.31.0-6379060755038208/darwin-x64/Antigravity.dmg"
```

### Шаг 2. Установить в `~/Applications`

```bash
hdiutil attach -nobrowse -readonly Antigravity.dmg
mkdir -p ~/Applications
cp -R "/Volumes/Antigravity/Antigravity.app" ~/Applications/
xattr -dr com.apple.quarantine ~/Applications/Antigravity.app
hdiutil detach "/Volumes/Antigravity"
```

Проверить версию и исходную подпись:

```bash
defaults read ~/Applications/Antigravity.app/Contents/Info.plist CFBundleShortVersionString
codesign --verify --deep --strict ~/Applications/Antigravity.app && echo OK
```

### Шаг 3. Скачать патчер

```bash
mkdir -p ~/Applications/agy-tools
curl -fL -o ~/Applications/agy-tools/patcher.py \
  https://raw.githubusercontent.com/trustybird/agy-unlock/main/patcher.py
```

### Шаг 4. Пропатчить `language_server`

```bash
python3 ~/Applications/agy-tools/patcher.py status \
  --path ~/Applications/Antigravity.app/Contents/Resources/bin/language_server

python3 ~/Applications/agy-tools/patcher.py unlock manager \
  --path ~/Applications/Antigravity.app/Contents/Resources/bin/language_server
```

Ожидаемый вывод:

```
[*] manager: .../language_server
    -> patched
```

Проверить, что гейты применены:

```bash
python3 ~/Applications/agy-tools/patcher.py status \
  --path ~/Applications/Antigravity.app/Contents/Resources/bin/language_server
```

Должно быть `статус: patched` и заполнены `gate auth` / `gate elig` / `gate rename`.
Резервная копия оригинала сохраняется рядом как `language_server.agybak`.

### Шаг 5. Переподписать бандл

```bash
./scripts/resign.py ~/Applications/Antigravity.app
```

Скрипт:

1. находит все Mach-O файлы (изнутри наружу);
2. добавляет каждому `com.apple.security.cs.disable-library-validation`,
   сохраняя остальные entitlements;
3. подписывает ad-hoc с `--options runtime`;
4. подписывает вложенные бандлы и главный `.app`;
5. запускает `codesign --verify --deep --strict`.

Успех выглядит так:

```
mach-o files: 18
bundles: 8
main bundle: OK
VERIFY EXIT: 0
FAILURES: 0
```

### Шаг 6. Запустить

```bash
open ~/Applications/Antigravity.app
```

При первом запуске macOS может сказать «разработчик не подтверждён» —
нажмите **«Открыть»** (или `ПКМ → Открыть`).

---

## Проверка результата

```bash
./scripts/doctor.sh
```

Или вручную:

```bash
A=~/Applications/Antigravity.app

# версия
defaults read "$A/Contents/Info.plist" CFBundleShortVersionString

# патч: должно быть 8
grep -a -o "inexigible" "$A/Contents/Resources/bin/language_server" | wc -l

# подпись: exit 0
codesign --verify --deep --strict "$A"; echo "verify_exit=$?"

# процессы
pgrep -fl "Antigravity|language_server"

# VPN
curl -s https://ipinfo.io/json | grep -E '"country"|"region"'
```

Признаки рабочей конфигурации:

- версия отображается;
- `inexigible` встречается **8 раз**;
- `verify_exit=0`;
- процессы `Antigravity` и `language_server` живы;
- VPN показывает страну, где сервис доступен.

---

## Обновления приложения

Antigravity обновляется сама через Squirrel. После переподписи автообновление
**не сможет установиться**: macOS отклонит подпись новой версии, и приложение
останется на текущей. Это безопасно — патч не затрётся.

Если приложение всё же обновилось (например, вы переустановили DMG), запустите:

```bash
./scripts/repatch.sh
```

Скрипт заново патчит `language_server` и переподписывает бандл.

Проверить, не пыталось ли приложение обновиться:

```bash
tail -20 ~/Library/Logs/Antigravity/main.log
```

Ошибка вида `Code signature ... did not pass validation` — ожидаемая.

---

## Откат

Вернуть оригинальный `language_server`:

```bash
cp ~/Applications/Antigravity.app/Contents/Resources/bin/language_server.agybak \
   ~/Applications/Antigravity.app/Contents/Resources/bin/language_server
chmod +x ~/Applications/Antigravity.app/Contents/Resources/bin/language_server
```

Затем переподпишите бандл:

```bash
./scripts/resign.py ~/Applications/Antigravity.app
```

Полностью удалить приложение:

```bash
rm -rf ~/Applications/Antigravity.app
rm -rf ~/.gemini/antigravity
```

---

## Диагностика

Подробный разбор — в [docs/troubleshooting.md](docs/troubleshooting.md).
Короткая таблица:

| Симптом | Причина | Решение |
|---|---|---|
| «Приложение повреждено» | изменён файл внутри `.app`, печать бандла нарушена | `./scripts/resign.py ...` |
| `Library not loaded: Electron Framework` | нет `disable-library-validation` или смешаны Team ID | переподписать через `resign.py` |
| `Operation not permitted` при записи в `/Applications` | TCC App Management | ставить в `~/Applications` |
| `You are not logged into Antigravity` | нет OAuth-токена или истёк | войти в аккаунт заново |
| `LOCATION_NOT_ELIGIBLE: RU` | VPN выключен или регион аккаунта | включить VPN / дождаться смены региона |
| Приложение не открывается после обновления | патч затёрт | `./scripts/repatch.sh` |
| Запросы рвутся, хотя VPN включён | сторонний DNS-фильтр (AdGuard и т.п.) | поставить фильтр на паузу |

Полезные логи:

```bash
tail -50 ~/Library/Logs/Antigravity/language_server.log
tail -50 ~/Library/Logs/Antigravity/main.log
```

---

## FAQ

**Это работает на Apple Silicon (M1/M2/M3)?**
Инструкция проверена только на Intel x64. Патчер умеет ARM64-гейты, но
переподпись и путь установки могут отличаться — тестируйте отдельно.

**Нужен ли VPN постоянно?**
Да, для серверных запросов нужен выход в поддерживаемой стране. Клиентский
патч снимает только локальные проверки.

**Почему приложение лежит в `~/Applications`, а не в `/Applications`?**
Из-за TCC App Management на macOS 13+: запись в системную папку блокируется
даже для root.

**Автообновление всё сломает?**
Нет: новая версия не пройдёт проверку подписи и не установится. Патч останется
на месте. Если вы обновились вручную — запустите `repatch.sh`.

**Можно ли подписать нормальным сертификатом разработчика?**
Можно, но не обязательно. Ad-hoc подписи достаточно, если выставлен
`disable-library-validation`.

**Куда сохраняется бэкап?**
Рядом с бинарником: `language_server.agybak`.

**Где хранится токен входа?**
В связке ключей macOS: сервис `gemini`, аккаунт `antigravity`.

---

## Структура репозитория

```
.
├── README.md                  # этот файл
├── LICENSE                    # PolyForm Noncommercial 1.0.0
├── NOTICE.md                  # манифест «Free Forever»
├── .gitignore
├── docs/
│   ├── how-it-works.md        # технические детали: гейты, подпись, TCC
│   ├── troubleshooting.md     # расширенная диагностика
│   ├── sources.md             # все бесплатные первоисточники
│   └── anti-resale.md         # защита от платных копий
└── scripts/
    ├── setup.sh               # установка с нуля
    ├── repatch.sh             # перепатч после обновления
    ├── resign.py              # консистентная ad-hoc переподпись
    ├── doctor.sh              # проверка состояния
    └── anti-resale.sh         # баннер и FREE_NOTICE.txt
```

---

## Источники

Проект собран из открытых бесплатных репозиториев. Полный список с лицензиями,
датой проверки и пояснением, что именно откуда взято, — в
[docs/sources.md](docs/sources.md).

Все проекты в списке проверены вручную: бесплатные — отдельно, платные и
freemium — отдельно. Ничего с пробным периодом и последующей оплатой в
рекомендациях нет.

Ключевые источники:

- [trustybird/agy-unlock](https://github.com/trustybird/agy-unlock) — патчер
  `language_server`;
- [QNIX-Dev/eligibility-antigravity-patcher](https://github.com/QNIX-Dev/eligibility-antigravity-patcher)
  — сигнатуры и каркас (MIT);
- [vezlin1/antigravity-bypass-russia](https://github.com/vezlin1/antigravity-bypass-russia)
  — IDE JS (MIT);
- [confeden/Antigravity](https://github.com/confeden/Antigravity) — идеи
  rename/asar (бесплатно, но ключ выдаётся в Telegram `@nova_txt`);
- зеркала AvenCores:
  [sara-dev12](https://github.com/sara-dev12/open-antigravity-patcher),
  [top-master](https://github.com/top-master/ai-antigravity-patcher),
  [NoRoute2Koi](https://github.com/NoRoute2Koi/open-antigravity-patcher-nix)
  (GPL-3.0).

Отдельно: [loysger/Antigravity](https://github.com/loysger/Antigravity) в список
**не входит**. Это платный шлюз: тестовый ключ, затем тарифы PRO / X3 / X5 /
ULTRA через Telegram-бота. Мы такие схемы не рекомендуем.

Если кто-то продаёт доступ к этим материалам — он нарушает лицензии и
занимается барыжничеством. См. [docs/anti-resale.md](docs/anti-resale.md).

---

## Благодарности

- [trustybird/agy-unlock](https://github.com/trustybird/agy-unlock) — патчер
  `language_server` (скачивается отдельно, не входит в репозиторий);
- QNIX / vezlin1 / xbox_dns — исследования байтовых гейтов;
- сообществу Antigravity за отчёты о `LOCATION_NOT_ELIGIBLE` и подписях.

---

## Лицензия

Код и документация этого репозитория распространяются по
[PolyForm Noncommercial 1.0.0](LICENSE).

Это значит:

- **можно** бесплатно использовать, изучать, изменять и распространять;
- **нельзя** продавать, ставить за плату, прятать за paywall или включать
  в платный продукт.

При нарушении лицензия прекращается, а к нарушителю применяются меры,
описанные в [NOTICE.md](NOTICE.md) и [docs/anti-resale.md](docs/anti-resale.md).

Сторонний `patcher.py` **не включён** в репозиторий и распространяется на
условиях его авторов. Скрипты скачивают его напрямую из upstream.
