# Environment Dotfiles

Настройки рабочей среды для быстрого развёртывания на новой машине.

## Структура

```
terminal/
├── setup-terminal.sh        # Главный скрипт установки (запускать его)
├── kitty.conf               # Конфиг Kitty с темой Kanagawa
├── config.fish              # Конфиг Fish shell
├── fish-colors-kanagawa.fish # Цветовая схема Fish (Kanagawa)
└── tide-theme.fish          # Настройки промпта Tide v6
```

## Что входит

| Компонент | Описание |
|---|---|
| **Fish** | Оболочка с автодополнением и подсветкой |
| **Tide v6** | Powerline-промпт с иконками git, node, python, java |
| **Fisher** | Менеджер плагинов Fish |
| **Kitty** | GPU-ускоренный терминал |
| **Kanagawa** | Японская тёмная тема (Kitty + Fish) |
| **Noto Sans Mono** | Шрифт с поддержкой CJK |
| **fastfetch** | Вывод системной информации |

## Быстрая установка

```bash
git clone https://github.com/ntdim/environment.git
cd environment/terminal
chmod +x setup-terminal.sh
./setup-terminal.sh
```

После установки перезапустить терминал (Kitty), запустить `fastfetch`.

## KDE Plasma

Чтобы Kitty был терминалом по умолчанию:
> Системные настройки → Приложения по умолчанию → Эмулятор терминала → Kitty
