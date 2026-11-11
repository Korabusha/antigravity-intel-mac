# Диагностика

Расширенный разбор проблем. Быстрая проверка — `./scripts/doctor.sh`.

---

## Содержание

- [Приложение «повреждено»](#приложение-повреждено)
- [Library not loaded / no Team ID](#library-not-loaded--no-team-id)
- [Operation not permitted](#operation-not-permitted)
- [Приложение не запускается или висит](#приложение-не-запускается-или-висит)
- [You are not logged into Antigravity](#you-are-not-logged-into-antigravity)
- [LOCATION_NOT_ELIGIBLE](#location_not_eligible)
- [403 на FetchConfig, но чат работает](#403-на-fetchconfig-но-чат-работает)
- [Автообновление и подпись](#автообновление-и-подпись)
- [AdGuard и DNS](#adguard-и-dns)
- [Как собрать диагностику](#как-собрать-диагностику)

---

## Приложение «повреждено»

**Симптом:** macOS пишет «приложение повреждено, переместить в корзину?».

**Причина:** вы изменили файл внутри `.app` (патч), и печать бандла перестала
совпадать. Файлы целы — битая только подпись.

**Решение:**

```bash
~/Applications/agy-tools/resign.py ~/Applications/Antigravity.app
# или, если у вас клон репозитория:
./scripts/resign.py ~/Applications/Antigravity.app
```

В диалоге macOS выбирайте **«Не сейчас»**, а не «Переместить в корзину».

---

## Library not loaded / no Team ID

**Симптом:**

```
Library not loaded: @rpath/Electron Framework.framework/Electron Framework
Reason: mapped file has no Team ID and is not a platform binary
```

**Причина:** бандл переподписан ad-hoc, но главному процессу или хелперам не
добавлен `com.apple.security.cs.disable-library-validation`.

**Решение:** переподписать через `resign.py` (он добавляет entitlement всем
Mach-O и бандлам):

```bash
./scripts/resign.py ~/Applications/Antigravity.app
codesign --verify --deep --strict ~/Applications/Antigravity.app; echo $?
```

Ожидается `0`.

**Чего не делать:** `codesign --deep --force --sign -` — он оставляет
смешанные Team ID и не чинит проблему.

---

## Operation not permitted

**Симптом:** `cp`, `touch` или патчер не могут записать файл в
`/Applications/Antigravity.app`, даже под `sudo`.

**Причина:** TCC App Management на macOS 13+.

**Решение:** работайте с копией в `~/Applications`:

```bash
mkdir -p ~/Applications
cp -R /Applications/Antigravity.app ~/Applications/
xattr -dr com.apple.quarantine ~/Applications/Antigravity.app
```

Дальше все команды выполняйте с `~/Applications/Antigravity.app`.

---

## Приложение не запускается или висит

Проверьте по порядку:

1. **Процесс жив?**

   ```bash
   ps -o pid,stat,rss,command -p "$(pgrep -f 'Antigravity.app/Contents/MacOS/Antigravity' | head -1)"
   ```

   Если `RSS` маленький (единицы КБ) и `%CPU` = 0 — процесс завис на старте.

2. **Есть ли краш-репорт?**

   ```bash
   ls -lt ~/Library/Logs/DiagnosticReports/Antigravity*.ips | head -3
   ```

3. **Что говорит лог?**

   ```bash
   tail -50 ~/Library/Logs/Antigravity/main.log
   tail -50 ~/Library/Logs/Antigravity/language_server.log
   ```

4. **Запустите бинарник вручную** — так видно ошибки dyld:

   ```bash
   ~/Applications/Antigravity.app/Contents/MacOS/Antigravity
   ```

5. **Проверьте подпись:**

   ```bash
   codesign --verify --deep --strict ~/Applications/Antigravity.app; echo $?
   ```

Если не `0` — переподпишите.

---

## You are not logged into Antigravity

**Симптом:** в `language_server.log`:

```
error getting token source: You are not logged into Antigravity
```

**Причина:** нет OAuth-токена, истёк срок, или `language_server` не может
прочитать токен из связки ключей.

**Решение:**

1. Войдите в аккаунт в окне Antigravity.
2. Проверьте, что токен появился:

   ```bash
   security find-generic-password -a antigravity -s gemini -w >/dev/null && echo "токен есть"
   ```

3. Если токен есть, но приложение всё равно «не залогинено», перезапустите
   приложение. При первом обращении macOS может спросить разрешение на доступ
   к ключу — разрешите.

4. Если токен повреждён — удалите его и войдите заново:

   ```bash
   security delete-generic-password -a antigravity -s gemini
   ```

---

## LOCATION_NOT_ELIGIBLE

**Симптом:**

```
403 Forbidden
Your location is not eligible for this service at this time. Detected location: RU.
reason: LOCATION_NOT_ELIGIBLE
```

**Причина:** Google определяет регион. Клиентский патч этого не отменяет.

**Что делать:**

1. Включите VPN с выходом в поддерживаемой стране.
2. Проверьте выход:

   ```bash
   curl -s https://ipinfo.io/json | grep -E '"country"|"region"'
   ```

3. Если страна не та — смените сервер VPN.
4. Если страна `US`, но ошибка остаётся — она может относиться к региону
   **аккаунта Google**, а не к IP. Дождитесь обработки заявки на смену региона
   или используйте аккаунт, созданный в поддерживаемой стране.

---

## 403 на FetchConfig, но чат работает

Это **нормально**. `FetchConfig` — дополнительный запрос конфигурации.
При 403 клиент пишет предупреждение и откатывается на `ListExperiments`:

```
AICode FetchConfig failed, falling back to CCPA ListExperiments
```

Ничего делать не нужно, если основные запросы проходят.

---

## Автообновление и подпись

**Симптом:** в `main.log`:

```
Code signature at URL .../Antigravity.app/ did not pass validation
```

**Причина:** Squirrel пытается установить новую версию, но ad-hoc подпись
не совпадает с ожидаемой.

**Это не ошибка установки** — обновление просто не применяется, патч остаётся.
Если приложение всё же обновилось вручную:

```bash
./scripts/repatch.sh
```

Проверить, не осталось ли pending-обновление:

```bash
ls -lh ~/Library/Caches/com.google.antigravity/pending/
```

Удалить его (необязательно):

```bash
rm -rf ~/Library/Caches/com.google.antigravity/pending
```

---

## AdGuard и DNS

Если VPN включён, но запросы рвутся или не проходят авторизация:

1. Поставьте AdGuard (или другой DNS-фильтр) на паузу.
2. Проверьте DNS-резолверы:

   ```bash
   scutil --dns | grep 'nameserver\['
   ```

3. Проверьте, что Google отвечает:

   ```bash
   curl -s -o /dev/null -w "%{http_code}\n" https://accounts.google.com/generate_204
   ```

   Ожидается `204`.

---

## Как собрать диагностику

Если нужна помощь, приложите вывод:

```bash
./scripts/doctor.sh > /tmp/antigravity-doctor.txt 2>&1

{
  echo "=== version ==="
  defaults read ~/Applications/Antigravity.app/Contents/Info.plist CFBundleShortVersionString
  echo "=== patch ==="
  grep -a -o "inexigible" ~/Applications/Antigravity.app/Contents/Resources/bin/language_server | wc -l
  echo "=== signature ==="
  codesign --verify --deep --strict ~/Applications/Antigravity.app 2>&1; echo "exit=$?"
  echo "=== vpn ==="
  curl -s https://ipinfo.io/json | grep -E '"country"|"region"|"org"'
  echo "=== ls log ==="
  tail -40 ~/Library/Logs/Antigravity/language_server.log
  echo "=== main log ==="
  tail -20 ~/Library/Logs/Antigravity/main.log
} > /tmp/antigravity-report.txt 2>&1
```

Перед публикацией удалите из логов личные данные (email, пути, токены).
