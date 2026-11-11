# Источники

Полный список **бесплатных GitHub-проектов**, из которых мы брали информацию,
код или идеи. Все ссылки ведут на открытые репозитории; ничего платного здесь
нет.

Обозначения:

- **использовано** — код, сигнатуры или подход вошли в проект;
- **изучено** — рассмотрено как альтернатива, но не использовано;
- **зеркало** — копия удалённого оригинала.

---

## Основные источники

### 1. trustybird/agy-unlock — патчер `language_server`

- Ссылка: <https://github.com/trustybird/agy-unlock>
- Лицензия: не указана (код не перепубликуется, скачивается скриптом напрямую)
- Что взяли: сам патчер `patcher.py` (`unlock manager`, `status`, `doctor`,
  `restore`). Именно им снимаются три гейта в `language_server`.
- Статус: **использовано**

### 2. QNIX-Dev/eligibility-antigravity-patcher — сигнатуры и каркас

- Ссылка: <https://github.com/QNIX-Dev/eligibility-antigravity-patcher>
- Лицензия: MIT
- Что взяли: байтовые сигнатуры гейтов, каркас сканера секций и бэкапов
  (по мотивам `manager.py`).
- Статус: **использовано**

### 3. vezlin1/antigravity-bypass-russia — IDE JS

- Ссылка: <https://github.com/vezlin1/antigravity-bypass-russia>
- Лицензия: MIT
- Что взяли: подход к патчу IDE (`isGoogleInternal -> true`), tolerant-regex
  для минифицированного JS.
- Статус: **использовано**

### 4. confeden/Antigravity — rename/asar

- Ссылка: <https://github.com/confeden/Antigravity>
- Лицензия: restricted (NOASSERTION)
- Что взяли: **только идеи из публичного README** — rename-гейт
  (`ineligible -> inexigible`) и подход к `app.asar`. Код не копировался.
- Статус: **использовано (идеи)**

### 5. AvenCores/open-antigravity-patcher — оригинальные байт-сигнатуры

- Оригинал удалён, зеркала:
  - <https://github.com/sara-dev12/open-antigravity-patcher> (GPL-3.0)
  - <https://github.com/top-master/ai-antigravity-patcher> (GPL-3.0)
  - <https://github.com/NoRoute2Koi/open-antigravity-patcher-nix> (GPL-3.0)
- Лицензия: GPL-3.0
- Что взяли: байт-сигнатуры MGR/CLI/ARM/IDE (через атрибуцию в патчере).
- Статус: **использовано (сигнатуры)**, оригинал удалён

---

## Изученные альтернативы

| Проект | Лицензия | Что это | Почему не взяли |
|---|---|---|---|
| [loysger/Antigravity](https://github.com/loysger/Antigravity) | MIT | Запуск без VPN, платный gateway | Пул аккаунтов и платный шлюз, риск бана |
| [mhosseini-dev/antigravity-patch-macos](https://github.com/mhosseini-dev/antigravity-patch-macos) | NOASSERTION | macOS-порт, прокси Happ/Clash/V2Ray | Узкая задача, свой прокси-слой |
| [RendeRR/antigravity-patcher](https://github.com/RendeRR/antigravity-patcher) | NOASSERTION | Отключение региональных ограничений | Нет проверенной x64-ветки |
| [Quenary/antigravity-patcher](https://github.com/Quenary/antigravity-patcher) | MIT | Патчер под macOS/Linux | Другой набор гейтов |
| [BenSouchet/antigravity-patcher](https://github.com/BenSouchet/antigravity-patcher) | MIT | Патч IDE | Только IDE, без `language_server` |
| [kakajan/antigravity-patch](https://github.com/kakajan/antigravity-patch) | MIT | Патч авторизации | Нет x64-маковской ветки |
| [yhan-sun/antigravity-patcher](https://github.com/yhan-sun/antigravity-patcher) | не указана | Патчер | Нет лицензии, нет проверки |
| [ewnry/angrplus](https://github.com/ewnry/angrplus) | Apache-2.0 | Мультиаккаунт, квоты, UI | Пул аккаунтов, не наш сценарий |
| [sara-dev12/open-antigravity-patcher](https://github.com/sara-dev12/open-antigravity-patcher) | GPL-3.0 | Зеркало AvenCores | Только как источник сигнатур |
| [top-master/ai-antigravity-patcher](https://github.com/top-master/ai-antigravity-patcher) | GPL-3.0 | Зеркало AvenCores | Только как источник сигнатур |
| [NoRoute2Koi/open-antigravity-patcher-nix](https://github.com/NoRoute2Koi/open-antigravity-patcher-nix) | GPL-3.0 | Nix-порт | Не для macOS |
| [MehdiBaneshiOfficial/OAPM](https://github.com/MehdiBaneshiOfficial/OAPM) | GPL-3.0 | Гайд (персидский/английский) | Документация, не код |
| [m4tinbeigi-official/combined-antigravity-patcher](https://github.com/m4tinbeigi-official/combined-antigravity-patcher) | NOASSERTION | Комбайн-скрипт | Нет проверки на Intel Mac |
| [X2X13211/Antigravity-Bypass-Russia-2](https://github.com/X2X13211/Antigravity-Bypass-Russia-2) | не указана | Альтернативный обход | Нет лицензии, нет кода для x64 |

---

## Официальные ресурсы (не GitHub)

- Скачать Antigravity: <https://antigravity.google/download>
- Доступные страны Gemini Code Assist:
  <https://developers.google.com/gemini-code-assist/resources/available-locations>
- Лицензия PolyForm Noncommercial 1.0.0:
  <https://polyformproject.org/licenses/noncommercial/1.0.0>

---

## Отдельно: `xbox_dns/175`

В коде патчера есть ссылка `xbox_dns/175` — это **не GitHub-репозиторий**, а
внешний источник (Telegram/форум), где разбирался eligibility-гейт. Прямую
ссылку не приводим, чтобы не рекламировать непроверенный канал.

---

## Что это значит для пользователя

Всё перечисленное — **бесплатно**. Если кто-то продаёт «сборку», «установку»
или «доступ» на основе этих проектов, он нарушает как минимум лицензии
проектов, а как максимум — занимается барыжничеством.

Проверка проста: откройте ссылки выше и сравните. Если ваш продавец не даёт
ссылку на первоисточник — вас обманывают.

См. также [anti-resale.md](anti-resale.md).
