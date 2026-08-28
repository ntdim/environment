# Environment Dotfiles

Настройки рабочей среды для быстрого развёртывания на новой машине.
Поддерживаются Linux (Ubuntu/Debian, любое DE) и macOS.

## Структура

```
terminal/
├── setup-terminal.sh        # Установка на Linux (запускать его)
├── setup-terminal-mac.sh    # Установка на macOS
├── kitty.conf               # Конфиг Kitty: тема Kanagawa + Nerd Font иконки
├── config.fish              # Конфиг Fish shell (PATH и пр.)
├── theme.fish               # Цвета Fish (Kanagawa) + тема Tide v6 — единый источник
├── tide-theme.fish          # Дамп tide-переменных (источник для theme.fish)
├── fish-colors-kanagawa.fish # Дамп цветовых переменных fish (источник для theme.fish)
└── fastfetch-config.jsonc   # Конфиг fastfetch в стиле Kanagawa
network-notes.md             # Обход блокировок GitHub (если сеть «из РФ»)
```

## Что входит

| Компонент | Описание |
|---|---|
| **Fish** | Оболочка с автодополнением и подсветкой |
| **Tide v6** | Powerline-промпт с иконками git, node, python, java |
| **Fisher** | Менеджер плагинов Fish |
| **Kitty** | GPU-ускоренный терминал |
| **Kanagawa** | Японская тёмная тема (Kitty + Fish + fastfetch) |
| **Noto Sans Mono** | Шрифт с поддержкой CJK (италиков у семейства нет — kitty берёт системные) |
| **Symbols Nerd Font Mono** | Иконки Tide и powerline-разделители (подключён через `symbol_map`) |
| **fastfetch** | Вывод системной информации |

## Быстрая установка — Linux (Ubuntu/Debian)

```bash
git clone https://github.com/ntdim/environment.git
cd environment/terminal
chmod +x setup-terminal.sh
./setup-terminal.sh
```

Спросит пароль sudo (apt-пакеты + `chsh`). После установки перезапустить
терминал, запустить `fastfetch`.

## Быстрая установка — macOS

```bash
git clone https://github.com/ntdim/environment.git
cd environment/terminal
chmod +x setup-terminal-mac.sh
./setup-terminal-mac.sh
```

Скрипт сам ставит Homebrew (если его нет, в стандартный префикс), пакеты,
шрифты и меняет оболочку (спросит пароль sudo для `/etc/shells` + `chsh`).

Нюансы macOS:

- **Префикс Homebrew обязан быть стандартным** (`/opt/homebrew` на Apple
  Silicon). При кастомном префиксе llvm и прочие «неперемещаемые» bottle
  собираются из исходников часами — скрипт откажется работать и попросит
  переустановить brew.
- Если релизы GitHub недоступны из сети (типично для РФ), cask kitty и font-кегов
  падают — скрипт автоматически переключается на сборку kitty из исходников и
  получение шрифтов с jsDelivr / git (подробнее: `network-notes.md`).
- Kitty живёт в `/Applications`; CLI-обёртки `kitty`/`kitten` слинкованы в
  `$(brew --prefix)/bin`. Запуск: `open -a kitty`.

## Изменение темы

Тема Tide и цвета fish применяются из **`theme.fish`** (набор `set -U`) — это
единый источник для обеих ОС. Он сгенерирован из дампов `tide-theme.fish` и
`fish-colors-kanagawa.fish`; при ручной настройке через `tide configure`
обновите дамп и перегенерируйте `theme.fish`, чтобы машины оставались
синхронными.

> Историческая заметка: Tide v6 читает **публичные** переменные
> `tide_left_prompt_items` / `tide_right_prompt_items`. Старая версия
> setup-скрипта писала `_tide_left_items` — это мёртвые переменные, список
> элементов промпта реально брался из fish_variables-дампа.

## KDE Plasma

Чтобы Kitty был терминалом по умолчанию:
> Системные настройки → Приложения по умолчанию → Эмулятор терминала → Kitty
