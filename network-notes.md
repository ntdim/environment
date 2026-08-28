# Особенности сети: обход блокировок GitHub

Проверено на macOS 26 / Linux из сети, где заблокированы не все, а только
часть хостов GitHub. Setup-скрипты репозитория учитывают это автоматически
(fallback-и), этот документ — справка «почему так» и рецепты для ручной работы.

## Что доступно, а что нет

| Хост | Статус | Для чего нужен |
|---|---|---|
| `github.com` | ✅ работает | git clone/push, страницы репозиториев |
| `codeload.github.com` | ✅ работает | tarball-ы веток/тегов (`/tar.gz/refs/tags/v6`) |
| `ghcr.io` | ✅ работает | официальные bottle Homebrew |
| `mirrors.ustc.edu.cn` | ✅ работает | зеркала Homebrew (bottles, api), PyPI |
| `cdn.jsdelivr.net` | ✅ работает | зеркала **файлов git-репозиториев** |
| `raw.githubusercontent.com` | ❌ заблокирован | «сырые» файлы репозиториев, скрипты установки |
| `objects.githubusercontent.com` | ❌ заблокирован | **артефакты релизов** (dmg/zip из Releases) |

## Рецепты

### 1. Файл репозитория вместо raw.githubusercontent.com

```bash
# было (не работает):
curl -sL https://raw.githubusercontent.com/OWNER/REPO/REF/path/file.fish
# стало (jsDelivr, тот же контент):
curl -sL https://cdn.jsdelivr.net/gh/OWNER/REPO@REF/path/file.fish
```

Ограничение: файл должен быть закоммичен в репозиторий (не артефакт релиза),
размер ≤ 50 МБ. Контент идентичен — контрольные суммы совпадают.

### 2. Tarball конкретного тега/ветки

```bash
curl -sL -o tide.tar.gz https://codeload.github.com/ilancosman/tide/tar.gz/refs/tags/v6
```

### 3. Один файл из большого репозитория (без полного клона)

Partial clone качает только дерево коммитов, blob — по требованию:

```bash
git clone --filter=blob:none --no-checkout --depth 1 \
    https://github.com/ryanoasis/nerd-fonts.git /tmp/nf
cd /tmp/nf
git checkout HEAD -- patched-fonts/NerdFontsSymbolsOnly/SymbolsNerdFontMono-Regular.ttf
```

Так из ~300 МБ репозитория достаётся один ttf в пару мегабайт.

### 4. Homebrew

Зеркала USTC (в `~/.zshenv` или `~/.zprofile`):

```sh
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
```

Нюансы:

- **Префикс brew обязан быть стандартным** (`/opt/homebrew` на Apple Silicon,
  `/usr/local` на Intel). При кастомном префиксе (например, `~/homebrew`)
  llvm/openssl и другие «неперемещаемые» bottle считаются непригодными, и brew
  начинает часовые сборки из исходников.
- Даже с зеркалами brew ходит проверять свежесть формул на
  `raw.githubusercontent.com`. Обход — подмена curl:

  ```bash
  #!/bin/bash
  # ~/brew-curl (chmod +x), использовать: HOMEBREW_CURL_PATH=~/brew-curl brew install ...
  new=()
  for a in "$@"; do
    case "$a" in
      https://raw.githubusercontent.com/*)
        rest="${a#https://raw.githubusercontent.com/}"
        o="${rest%%/*}"; rest="${rest#*/}"
        r="${rest%%/*}"; rest="${rest#*/}"
        ref="${rest%%/*}"; p="/${rest#*/}"
        a="https://cdn.jsdelivr.net/gh/${o}/${r}@${ref}${p}"
        ;;
    esac
    new+=("$a")
  done
  exec /usr/bin/curl --connect-timeout 10 "${new[@]}"
  ```

### 5. PyPI

```bash
pip install -i https://mirrors.ustc.edu.cn/pypi/web/simple PACKAGE
```

### 6. Артефакты Releases (dmg/zip) — самое сложное

Прямые ссылки (`github.com/.../releases/download/...`) редиректят на
заблокированный `objects.githubusercontent.com`. Варианты по убыванию качества:

1. **Собрать из исходников** — tarball-ы с `codeload` доступны (так собран
   kitty: зависимости через brew, доки через venv со sphinx<9).
2. **Файл закоммичен в репозиторий** — тогда jsDelivr (см. рецепт 1) или
   partial clone (рецепт 3).
3. **gh-прокси** (`gh-proxy.com`, `ghfast.top`, `gh.llkk.cc`) — работают, но
   публичные инстансы режут поток на ~15–20 КБ на запрос. Пригодны только для
   чанковой докачки по Range-запросам с обязательной проверкой целостности
   (CRC/unzip -t): примерно один кусок из ~200 приходит битым.
