# Как это работает

Документ для тех, кто хочет понимать, что именно делает патч и почему без
переподписи приложение падает.

---

## 1. Из чего состоит Antigravity

Antigravity — это Electron-приложение:

```
Antigravity.app/
├── Contents/MacOS/Antigravity           # Electron main process
├── Contents/Frameworks/
│   ├── Electron Framework.framework/    # Chromium + Node
│   ├── Antigravity Helper*.app/         # GPU / Renderer / Plugin
│   └── Squirrel.framework/              # автообновление
└── Contents/Resources/
    ├── app.asar                         # UI-шелл
    └── bin/language_server              # Go-бэкенд: модели, авторизация, гейты
```

Все проверки региона и авторизации живут в **`language_server`** — отдельном
процессе. Поэтому патчить нужно именно его, а не весь `.app`.

---

## 2. Три клиентских гейта

`language_server` содержит три проверки:

| Гейт | Смысл | Как обходится |
|---|---|---|
| `auth` | «есть ли валидная авторизация» | байт `cmp` заменяется на безусловный `true` |
| `elig` | «показать экран: регион не поддерживается» | `jne` заменяется на `nop`/`jmp` |
| `rename` | поле, по которому клиент гейтит ответ | `ineligible` → `inexigible` по всему файлу |

### Почему `rename` надёжен

Строка `ineligible` встречается и в protobuf-дескрипторе, и в теге Go-структуры.
Замена на слово той же длины (`inexigible`) ломает имя поля: клиент просто не
находит его в ответе и не включает блокировку. Это не зависит от раскладки
машинного кода и архитектуры, поэтому работает как страховка, когда байтовые
сигнатуры не совпали.

### Почему сигнатуры, а не смещения

Патчер ищет байтовые паттерны функций, а не фиксированные адреса. После
пересборки приложения адреса меняются, а сигнатуры — нет. Поэтому патч
переживает обновления до тех пор, пока Google не перепишет сами функции.

---

## 3. Проблема подписи

### Что ломается

Оригинальный бандл подписан сертификатом Google: у всех файлов один **Team ID**.
macOS проверяет, что загружаемые библиотеки подписаны тем же Team ID или
являются платформенными.

После ad-hoc переподписи (`codesign --sign -`) Team ID исчезает:

```
mapped file has no Team ID and is not a platform binary
Library not loaded: @rpath/Electron Framework.framework/Electron Framework
```

### Как это лечится

Каждому исполняемому файлу и бандлу добавляется entitlement:

```
com.apple.security.cs.disable-library-validation
```

Он говорит загрузчику: «не проверяй Team ID у библиотек». Остальные
entitlements сохраняются:

| Компонент | Entitlements |
|---|---|
| `Antigravity` | `automation.apple-events`, `cs.allow-jit`, `device.audio-input`, `device.camera` |
| Helper / GPU / Renderer | `cs.allow-jit` |
| Plugin | `cs.allow-jit`, `cs.allow-unsigned-executable-memory`, `cs.disable-library-validation` |

### Порядок подписи

1. Все Mach-O файлы — **изнутри наружу** (сначала глубоко вложенные).
2. Все вложенные бандлы (`.app`, `.framework`, `.xpc`, `.bundle`) — тоже
   изнутри наружу.
3. Главный `.app` — последним, с entitlements главного исполняемого файла.

Если подписать в другом порядке, внешняя печать станет невалидной.

### Почему `codesign --deep` не подходит

`codesign --deep --force --sign -` не переписывает вложенные подписи
согласованно и оставляет смешанные Team ID. Именно так появляется ошибка
«подпись невалидна» или «приложение повреждено».

---

## 4. TCC App Management

На macOS 13+ запись внутрь `/Applications/*.app` защищена TCC. Даже `root`
получает:

```
Operation not permitted
```

Поэтому рабочая копия ставится в `~/Applications/Antigravity.app`. Там
патчинг и переподпись проходят без ограничений.

Важно: если приложение уже стоит в `/Applications`, не пытайтесь патчить его
на месте — скопируйте в `~/Applications` и работайте там.

---

## 5. Автообновление

Antigravity использует Squirrel.Mac:

1. приложение скачивает `Antigravity.zip` новой версии;
2. `ShipIt` проверяет подпись;
3. если подпись не совпадает с ожидаемой — установка отменяется.

После ad-hoc переподписи шаг 3 всегда падает:

```
Code signature at URL .../Antigravity.app/ did not pass validation
```

Это **защитный эффект**: патч не затирается. Но если вы переустановили
приложение вручную из свежего DMG — запустите `./scripts/repatch.sh`.

---

## 6. Серверная проверка региона

Клиентский патч снимает только локальные проверки. Google может ответить:

```json
{
  "error": {
    "code": 403,
    "status": "PERMISSION_DENIED",
    "message": "Your location is not eligible for this service at this time. Detected location: RU.",
    "details": [{
      "reason": "LOCATION_NOT_ELIGIBLE",
      "domain": "aicode.googleapis.com"
    }]
  }
}
```

Этот ответ приходит на дополнительный запрос `FetchConfig`. Клиент **не
падает**: он логирует предупреждение и откатывается на `ListExperiments`.
Чат продолжает работать.

Если отказ начинает приходить на основные запросы — нужен VPN с выходом
в поддерживаемой стране. Регион аккаунта Google при этом может оставаться
прежним: смена региона обрабатывается на стороне Google.

---

## 7. Что проверять после установки

```bash
A=~/Applications/Antigravity.app

# 1. Патч: 8 вхождений
grep -a -o "inexigible" "$A/Contents/Resources/bin/language_server" | wc -l

# 2. Подпись: exit 0
codesign --verify --deep --strict "$A"; echo "exit=$?"

# 3. Процессы
pgrep -fl "Antigravity|language_server"

# 4. Регион VPN
curl -s https://ipinfo.io/json | grep -E '"country"|"region"'
```

Все четыре пункта должны быть в норме. Если нет — см.
[troubleshooting.md](troubleshooting.md).
