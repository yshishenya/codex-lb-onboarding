# Codex-LB: настройка Codex одной командой

[![Проверка установщиков](https://github.com/yshishenya/codex-lb-onboarding/actions/workflows/test.yml/badge.svg)](https://github.com/yshishenya/codex-lb-onboarding/actions/workflows/test.yml)
[![Релиз](https://img.shields.io/github/v/release/yshishenya/codex-lb-onboarding?label=версия)](https://github.com/yshishenya/codex-lb-onboarding/releases/latest)
[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4?logo=windows)](#windows)
[![macOS](https://img.shields.io/badge/macOS-поддерживается-000000?logo=apple)](#macos)
[![Лицензия: MIT](https://img.shields.io/badge/лицензия-MIT-green)](LICENSE)

**Codex** — помощник с искусственным интеллектом от OpenAI для работы с кодом.
Он бывает в двух видах: приложение **Codex Desktop** и программа для терминала
**Codex CLI**.

Этот установщик сам ставит Codex, если его ещё нет, и подключает его к серверу
вашей организации (**CPA**). Вам нужно выполнить одну команду и один раз ввести
ключ доступа. **Аккаунт OpenAI или ChatGPT не нужен.**

## Что понадобится

- компьютер с Windows 10/11 или macOS;
- интернет;
- **ключ Codex-LB** — его выдаёт администратор вашего сервиса
  ([подробнее](#где-взять-ключ));
- 5–10 минут.

## Выберите вашу систему

| Если у вас | Перейдите к инструкции |
|---|---|
| Компьютер с Windows 10 или 11 | [Настройка Windows](#windows) |
| MacBook, iMac или Mac mini | [Настройка macOS](#macos) |
| Linux (только Codex CLI) | [Настройка Linux](#linux) |

---

## Windows

### Шаг 1. Откройте PowerShell

1. Нажмите кнопку **Пуск**.
2. Напечатайте `PowerShell`.
3. Откройте приложение **Windows PowerShell**.

Запускать PowerShell от имени администратора не нужно.

> [!NOTE]
> Не используйте приложение «Командная строка» (`cmd`). Нужен именно
> **PowerShell** с синим значком.

### Шаг 2. Скопируйте и запустите команду

Скопируйте всю строку ниже. Для этого наведите на неё мышь и нажмите значок
копирования справа.

```powershell
irm https://github.com/yshishenya/codex-lb-onboarding/releases/latest/download/Install-CodexLb.ps1 | iex
```

Вернитесь в PowerShell, вставьте строку сочетанием <kbd>Ctrl</kbd> +
<kbd>V</kbd> или правой кнопкой мыши и нажмите <kbd>Enter</kbd>.

### Шаг 3. Введите ключ

Когда появится сообщение `Enter Codex-LB API key`, вставьте выданный вам
ключ и нажмите <kbd>Enter</kbd>.

Во время ввода ключа символы **не отображаются**. Это нормально: PowerShell
скрывает ключ от посторонних.

Если вы уже запускали установщик, он спросит
`Saved Codex-LB key found. Reuse it? [Y/n]`. Просто нажмите <kbd>Enter</kbd>,
чтобы оставить прежний ключ. Чтобы ввести новый, напечатайте `n` и нажмите
<kbd>Enter</kbd>.

### Шаг 4. Дождитесь окончания установки

Установка может занять **до 10 минут**, особенно если Codex ставится впервые.
Не закрывайте окно PowerShell.

- Может открыться Microsoft Store или отдельное окно установки Codex. Если
  оно просит подтвердить установку, подтвердите.
- Сообщения на английском — это нормально. Важно только последнее.

### Шаг 5. Перезапустите Codex

Дождитесь сообщения `Setup complete`. Закройте Codex Desktop и откройте его
снова. Если не уверены, что приложение закрылось полностью, перезагрузите
компьютер.

После этого в Codex появятся модели сервера CPA. Входить в OpenAI или ChatGPT
не нужно.

Готово — окно PowerShell можно закрыть.

---

## macOS

### Шаг 1. Откройте Терминал

1. Нажмите <kbd>Command</kbd> + <kbd>Пробел</kbd>.
2. Напечатайте `Терминал` или `Terminal`.
3. Нажмите <kbd>Enter</kbd>.

Откроется окно с текстовой строкой для ввода команд.

### Шаг 2. Скопируйте и запустите команду

Скопируйте всю строку ниже. Для этого наведите на неё мышь и нажмите значок
копирования справа.

```bash
curl -fsSL https://github.com/yshishenya/codex-lb-onboarding/releases/latest/download/install.sh | bash
```

Вернитесь в Терминал, вставьте строку сочетанием <kbd>Command</kbd> +
<kbd>V</kbd> и нажмите <kbd>Enter</kbd>.

### Шаг 3. Введите ключ

Когда появится сообщение `Enter Codex-LB API key (hidden)`, вставьте
выданный вам ключ и нажмите <kbd>Enter</kbd>.

Во время ввода ключа символы **не отображаются**. Это нормально: Терминал
скрывает ключ от посторонних.

Если вы уже запускали установщик, он спросит
`Saved Codex-LB key found. Reuse it? [Y/n]`. Просто нажмите <kbd>Enter</kbd>,
чтобы оставить прежний ключ. Чтобы ввести новый, напечатайте `n` и нажмите
<kbd>Enter</kbd>.

### Шаг 4. Дождитесь окончания установки

Если Codex Desktop ещё не установлен, откроется официальное окно его
установки. Завершите установку в этом окне в течение 5 минут: установщик
дождётся её и продолжит сам.

Сообщения на английском — это нормально. Важно только последнее.

### Шаг 5. Перезапустите Codex

Дождитесь сообщения `Setup complete`. Установщик сам откроет Codex, но его
нужно перезапустить, чтобы он увидел новые настройки. Полностью закройте Codex
сочетанием <kbd>Command</kbd> + <kbd>Q</kbd>, затем откройте его снова.

После этого в Codex появятся модели сервера CPA. Входить в OpenAI или ChatGPT
не нужно.

Готово — Терминал можно закрыть.

---

## Linux

На Linux установщик настраивает только Codex CLI. Откройте терминал и
выполните ту же команду, что и для macOS:

```bash
curl -fsSL https://github.com/yshishenya/codex-lb-onboarding/releases/latest/download/install.sh | bash
```

Затем введите ключ, как описано в [шаге 3 для macOS](#шаг-3-введите-ключ-1),
и откройте новое окно терминала.

---

## Где взять ключ

Ключ Codex-LB выдаёт администратор вашего сервиса. Установщик не создаёт
ключ и не может восстановить его по электронной почте.

> [!WARNING]
> Ключ — это как пароль. Не отправляйте его в чат, письмо, на снимке экрана и
> не публикуйте в GitHub. Установщик запрашивает ключ скрыто и сохраняет его
> только в профиле вашего пользователя. Если ключ попал к посторонним,
> следуйте [инструкции по безопасности](SECURITY.md).

## Безопасно ли запускать команду

Команда скачивает установщик из [последнего релиза](https://github.com/yshishenya/codex-lb-onboarding/releases/latest)
этого репозитория и сразу его запускает. Код установщика открыт:
[`Install-CodexLb.ps1`](Install-CodexLb.ps1) для Windows и
[`install.sh`](install.sh) для macOS и Linux.

Установщик:

- работает с правами вашего пользователя: запускать его от имени
  администратора не нужно;
- скачивает Codex только из официальных источников OpenAI и Microsoft Store;
- не трогает цифровую подпись приложения Codex Desktop;
- перед изменением настроек сохраняет их резервную копию;
- не отправляет ключ никуда, кроме сервера CPA.

Чтобы посмотреть, что установщик найдёт на компьютере, ничего при этом не
меняя, выполните [проверку без изменений](#проверка-без-изменений).

## Что делает установщик

1. Проверяет, установлены ли Codex Desktop и Codex CLI, и показывает их версии.
2. Ставит официальный Codex CLI, если его нет, или обновляет его командой
   `codex update`.
3. Ставит или обновляет Codex Desktop. На Windows — через Microsoft Store
   (`winget`), а если это не получилось, через официальный установщик
   `codex app`. На macOS — через `codex app`.
4. Проверяет ключ и получает от сервера CPA список моделей.
5. Сохраняет резервную копию текущих настроек Codex.
6. Подключает Codex к CPA без входа в OpenAI и сохраняет ключ для вашего
   пользователя.
7. Запускает Codex Desktop.

Если установку Codex Desktop не удалось подтвердить, установщик завершится
ошибкой и не сообщит о готовности. Ваши собственные настройки Codex, например
профили в `[profiles.*]`, установщик не меняет.

## Повторный запуск и переход со старого сервера

Ту же команду можно запускать сколько угодно раз: например, чтобы обновить
Codex или заменить ключ. Установщик снова проверит Codex и аккуратно обновит
настройки.

Если вы раньше пользовались старым сервером `cdx.2brain.pro`, просто запустите
команду ещё раз и оставьте сохранённый ключ: ранее выданные ключи Codex-LB
продолжают работать. Вручную ничего менять не нужно.

Перед каждым изменением старые настройки сохраняются рядом, в файл с именем
вида `config.toml.backup-20260831-120000`.

## Если что-то пошло не так

Найдите в таблице сообщение, которое вы видите, — обычно оно в последних
строках.

| Сообщение | Что это значит | Что сделать |
|---|---|---|
| `'irm' не является внутренней или внешней командой` | Команда вставлена в «Командную строку», а не в PowerShell | Откройте **PowerShell**, как в [шаге 1](#шаг-1-откройте-powershell) |
| `Codex-LB rejected the API key` | Ключ неверный или отключён | Запустите команду снова, на вопрос `Reuse it?` ответьте `n` и вставьте ключ целиком. Если не помогло — попросите новый ключ |
| `API key cannot be empty` | Ключ не был вставлен | Запустите команду снова и вставьте ключ перед нажатием <kbd>Enter</kbd> |
| `Codex-LB model check failed` | Нет связи с сервером CPA | Проверьте интернет. Если вы в корпоративной сети или с VPN, попробуйте без него или повторите позже |
| `Codex Desktop installation was not confirmed` | Установка Codex Desktop не была завершена | Завершите установку в открывшемся окне и запустите команду ещё раз |
| `Interactive terminal is required` | Команда запущена не в обычном окне Терминала | Откройте Терминал и вставьте команду вручную |
| `Warning: codex doctor reported diagnostics` | Это предупреждение, а не ошибка | Ничего делать не нужно |
| `Warning: LaunchAgent will load at next login` | Настройки применятся после повторного входа | Выйдите из учётной записи macOS и войдите снова или перезагрузите Mac |
| После перезапуска в Codex нет моделей CPA | Codex не перечитал настройки | Перезагрузите компьютер |

Если ничего не помогло, скопируйте весь текст из окна и отправьте тому, кто
выдал вам ключ. Установщик не печатает ключ, но перед отправкой всё равно
проверьте, что ключа в тексте нет.

Нашли ошибку в самом установщике? [Сообщите о ней здесь](https://github.com/yshishenya/codex-lb-onboarding/issues/new/choose).

## Проверка без изменений

Эта команда только покажет найденные версии Codex. Она ничего не установит и
не изменит.

**macOS и Linux:**

```bash
curl -fsSL https://github.com/yshishenya/codex-lb-onboarding/releases/latest/download/install.sh | bash -s -- --dry-run
```

**Windows:** выполните две команды по очереди. Первая скачивает установщик,
вторая запускает проверку.

```powershell
irm https://github.com/yshishenya/codex-lb-onboarding/releases/latest/download/Install-CodexLb.ps1 -OutFile $env:TEMP\Install-CodexLb.ps1
```

```powershell
& $env:TEMP\Install-CodexLb.ps1 -DryRun
```

## Как отключить Codex от CPA

Самый простой способ — вернуть настройки, которые были до первой установки.

1. Откройте папку с настройками Codex:
   - Windows: нажмите <kbd>Win</kbd> + <kbd>R</kbd>, введите
     `%USERPROFILE%\.codex` и нажмите <kbd>Enter</kbd>;
   - macOS: в Finder нажмите <kbd>Command</kbd> + <kbd>Shift</kbd> +
     <kbd>G</kbd>, введите `~/.codex` и нажмите <kbd>Enter</kbd>.
2. Найдите файлы `config.toml.backup-…`. Самый ранний по дате — это настройки
   до первой установки.
3. Удалите `config.toml` и переименуйте эту копию в `config.toml`. Если копий
   нет, значит, настроек до установки не было: просто удалите `config.toml`.
4. Удалите файл `codex-lb-api-key` с сохранённым ключом.

Затем удалите сохранённый ключ из системы.

**Windows** (в PowerShell):

```powershell
[Environment]::SetEnvironmentVariable("CODEX_LB_API_KEY", $null, "User")
```

**macOS** (в Терминале, две команды по очереди):

```bash
launchctl bootout "gui/$(id -u)" ~/Library/LaunchAgents/pro.2brain.codex-lb-env.plist; rm -f ~/Library/LaunchAgents/pro.2brain.codex-lb-env.plist ~/.codex/set-codex-lb-env.sh; launchctl unsetenv CODEX_LB_API_KEY
```

```bash
sed -i '' '/^# BEGIN CODEX-LB MANAGED$/,/^# END CODEX-LB MANAGED$/d' ~/.zshrc
```

На Linux удалите блок между строками `# BEGIN CODEX-LB MANAGED` и
`# END CODEX-LB MANAGED` в файле `~/.profile`.

После этого перезапустите Codex. Чтобы снова подключиться к CPA, достаточно
повторить установку.

## Для администраторов

<details>
<summary>Технические параметры и файлы</summary>

Установщик использует:

- endpoint Codex: `https://cpa.2brain.pro/v1`;
- каталог моделей: `https://cpa.2brain.pro/v1/models`;
- провайдер: `codex-lb`;
- API: `responses`, потоковые ответы по HTTP (`supports_websockets = false`);
- вход в OpenAI: не требуется (`requires_openai_auth = false`);
- модель по умолчанию: `gpt-5.6-luna` (`model` и `review_model`);
- переменную: `CODEX_LB_API_KEY`;
- каталог моделей: та же ссылка в `model_catalog_url`, чтобы Codex знал уровни
  рассуждений и другие свойства моделей сервера;
- конфигурацию: `~/.codex/config.toml` или `$CODEX_HOME/config.toml`.

Установщик меняет только ключи `model`, `review_model` и `model_provider` на
верхнем уровне `config.toml`, а также блок между строками
`# BEGIN CODEX-LB MANAGED` и `# END CODEX-LB MANAGED`. Остальные настройки,
включая `[profiles.*]` и `[projects.*]`, сохраняются.

Параметры для macOS и Linux:

```text
--endpoint URL
--models-url URL
--model MODEL
--dry-run
--no-desktop
```

Параметры для Windows PowerShell:

```text
-ApiKey VALUE
-Endpoint URL
-ModelsUrl URL
-Model MODEL
-DryRun
-NoDesktop
```

Чтобы установщик не задавал вопросов, передайте ключ в переменной среды
`CODEX_LB_API_KEY`. `--no-desktop` и `-NoDesktop` полностью пропускают
установку и запуск Codex Desktop.

Где хранится ключ:

- macOS: файл `~/.codex/codex-lb-api-key` с правами `600`. Оболочка получает
  ключ через блок в `~/.zshrc`, а приложение Codex Desktop — через
  пользовательский LaunchAgent `pro.2brain.codex-lb-env`;
- Linux: тот же файл и блок в `~/.profile`;
- Windows: файл `%USERPROFILE%\.codex\codex-lb-api-key` с ограниченным ACL и
  пользовательская переменная среды.

При проверке ключа он передаётся `curl` через временный файл с правами `600`,
а не в командной строке.

</details>

## Поддерживаемые системы

- Windows 10 и 11: Windows PowerShell 5.1 или PowerShell 7.
- macOS: актуальные версии на Apple Silicon и Intel.
- Linux: только Codex CLI.

Официальная документация OpenAI:
[`codex app`, `codex update`, `codex doctor`](https://learn.chatgpt.com/docs/developer-commands).

## Безопасность и лицензия

- Как сообщить об уязвимости и что делать, если ключ попал к посторонним:
  [SECURITY.md](SECURITY.md).
- Лицензия: [MIT](LICENSE).
