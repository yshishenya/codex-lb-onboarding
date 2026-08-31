# Codex-LB: простая настройка Codex

[![Проверка установщиков](https://github.com/yshishenya/codex-lb-onboarding/actions/workflows/test.yml/badge.svg)](https://github.com/yshishenya/codex-lb-onboarding/actions/workflows/test.yml)
[![Релиз](https://img.shields.io/github/v/release/yshishenya/codex-lb-onboarding?label=версия)](https://github.com/yshishenya/codex-lb-onboarding/releases/latest)
[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4?logo=windows)](#windows)
[![macOS](https://img.shields.io/badge/macOS-поддерживается-000000?logo=apple)](#macos)

Этот установщик подключает **Codex Desktop или Codex CLI** к Codex-LB.
Нужно выполнить одну команду и один раз ввести выданный вам ключ.

## Выберите вашу систему

| Если у вас | Перейдите к инструкции |
|---|---|
| Компьютер с Windows 10 или 11 | [Настройка Windows](#windows) |
| MacBook, iMac или Mac mini | [Настройка macOS](#macos) |

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

Скопируйте всю строку ниже:

```powershell
irm https://github.com/yshishenya/codex-lb-onboarding/releases/latest/download/Install-CodexLb.ps1 | iex
```

Вернитесь в PowerShell, вставьте строку сочетанием <kbd>Ctrl</kbd> +
<kbd>V</kbd> и нажмите <kbd>Enter</kbd>.

### Шаг 3. Введите ключ

Когда появится сообщение `Enter Codex-LB API key`, вставьте выданный вам
ключ и нажмите <kbd>Enter</kbd>.

Во время ввода ключа символы **не отображаются**. Это нормально: PowerShell
скрывает ключ от посторонних.

Если установщик нашёл сохранённый ключ и спрашивает
`Saved Codex-LB key found. Reuse it? [Y/n]`, просто нажмите <kbd>Enter</kbd>,
чтобы использовать его снова.

### Шаг 4. Перезапустите Codex

Дождитесь сообщения `Setup complete`. Полностью закройте Codex Desktop и
откройте его снова. В списке моделей должны появиться:

- `gpt-5.6-luna`
- `gpt-5.6-terra`

Готово — окно PowerShell можно закрыть.

---

## macOS

### Шаг 1. Откройте Терминал

1. Нажмите <kbd>Command</kbd> + <kbd>Пробел</kbd>.
2. Напечатайте `Терминал` или `Terminal`.
3. Нажмите <kbd>Enter</kbd>.

Откроется окно с текстовой строкой для ввода команд.

### Шаг 2. Скопируйте и запустите команду

Скопируйте всю строку ниже:

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

Если установщик нашёл сохранённый ключ и спрашивает
`Saved Codex-LB key found. Reuse it? [Y/n]`, просто нажмите <kbd>Enter</kbd>,
чтобы использовать его снова.

### Шаг 4. Перезапустите Codex

Дождитесь сообщения `Setup complete`. Полностью закройте Codex сочетанием
<kbd>Command</kbd> + <kbd>Q</kbd>, затем откройте его снова. В списке моделей
должны появиться:

- `gpt-5.6-luna`
- `gpt-5.6-terra`

Готово — Терминал можно закрыть.

---

## Где взять ключ

Ключ Codex-LB выдаёт администратор вашего сервиса. Установщик не создаёт
ключ и не может восстановить его по электронной почте.

> [!WARNING]
> Не отправляйте ключ в чат, письмо или снимок экрана. Установщик запрашивает
> его скрыто и сохраняет только в профиле вашего пользователя.

## Что делает установщик

Установщик автоматически:

1. Проверяет, установлен ли Codex Desktop или Codex CLI.
2. Показывает найденную версию.
3. Обновляет Codex CLI официальной командой `codex update`.
4. Устанавливает официальный Codex CLI, если Codex ещё не установлен.
5. Устанавливает или обновляет официальный Desktop через Microsoft Store на
   Windows. Если Store недоступен, запускает официальный установщик Codex.
6. Проверяет ключ и доступность моделей Luna и Terra.
7. Создаёт резервную копию существующих настроек.
8. Настраивает Codex-LB и безопасно сохраняет переменную
   `CODEX_LB_API_KEY` для текущего пользователя.
9. Запускает Codex Desktop. На macOS встроенное обновление приложения проверит
   доступность новой подписанной версии.

Установщик не заменяет файлы Codex Desktop вручную и не нарушает цифровую
подпись приложения.

## Повторный запуск и обновление

Эту же команду можно запустить повторно. Установщик снова проверит Codex,
обновит CLI и аккуратно обновит настройки. Старый файл настроек сохранится
рядом с именем вида `config.toml.backup-20260831-120000`.

## Если появилась ошибка

Скопируйте весь текст ошибки и отправьте его администратору.

## Проверка без изменений

Этот раздел нужен только для диагностики. Команда покажет найденные версии,
но ничего не обновит и не изменит.

**macOS:**

```bash
curl -fsSL https://github.com/yshishenya/codex-lb-onboarding/releases/latest/download/install.sh | bash -s -- --dry-run
```

**Windows:** сначала скачайте файл, затем выполните:

```powershell
irm https://github.com/yshishenya/codex-lb-onboarding/releases/latest/download/Install-CodexLb.ps1 -OutFile $env:TEMP\Install-CodexLb.ps1
& $env:TEMP\Install-CodexLb.ps1 -DryRun
```

## Для администраторов

<details>
<summary>Технические параметры и файлы</summary>

Установщик использует:

- endpoint Codex: `https://cdx.2brain.pro/backend-api/codex`;
- каталог моделей: `https://cdx.2brain.pro/v1/models`;
- провайдер: `codex-lb`;
- API: `responses`;
- модель по умолчанию: `gpt-5.6-luna`;
- переменную: `CODEX_LB_API_KEY`;
- конфигурацию: `~/.codex/config.toml`.

CLI-параметры macOS/Linux:

```text
--endpoint URL
--models-url URL
--model MODEL
--dry-run
--no-desktop
```

Параметры Windows PowerShell:

```text
-ApiKey VALUE
-Endpoint URL
-ModelsUrl URL
-Model MODEL
-DryRun
-NoDesktop
```

На macOS ключ хранится в файле с правами `600`, подхватывается оболочкой и
передаётся новым процессам Desktop через пользовательский LaunchAgent. На
Windows ключ хранится в профиле с ограниченным ACL и в пользовательской
переменной среды.

</details>

## Поддерживаемые системы

- Windows 10 и 11: Windows PowerShell 5.1 или PowerShell 7.
- macOS: актуальные версии на Apple Silicon и Intel.
- Linux: установщик `install.sh` поддерживает CLI; используйте команду из
  раздела macOS в обычном терминале.

Официальная документация OpenAI:
[`codex app`, `codex update`, `codex doctor`](https://learn.chatgpt.com/docs/developer-commands).
