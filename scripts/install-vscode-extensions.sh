#!/bin/bash

set -euo pipefail

usage() {
    cat <<'EOF'
Использование:
  ./install-vscode-extensions.sh [опции]

Опции:
  --home <path>         Целевой домашний каталог пользователя (по умолчанию: $HOME)
  --release <tag>       Тег релиза GitHub, например v2.0 (по умолчанию: v2.0)
  --user <name>         Имя пользователя из списка /home/*
  --select-user         Показать список пользователей и выбрать нужного интерактивно
  --list-users          Показать список пользователей без установки
  --auto                Автоматически выбрать первый найденный профиль из /home/*
  --dry-run             Показать, что будет сделано, без скачивания и распаковки
  -h, --help            Показать эту справку

Примеры:
  ./install-vscode-extensions.sh
  ./install-vscode-extensions.sh --home /home/student
  ./install-vscode-extensions.sh --user student
  ./install-vscode-extensions.sh --select-user
  ./install-vscode-extensions.sh --list-users
  ./install-vscode-extensions.sh --auto
  ./install-vscode-extensions.sh --dry-run
  ./install-vscode-extensions.sh --release v2.0
EOF
}

TARGET_HOME="${HOME}"
RELEASE_TAG="v2.0"
DRY_RUN=0
SELECT_USER=0
AUTO_USER=0
LIST_USERS_ONLY=0

list_users() {
    local user_list=()
    for d in /home/*; do
        if [[ -d "$d" ]]; then
            user_list+=("$(basename "$d")")
        fi
    done

    if [[ ${#user_list[@]} -eq 0 ]]; then
        echo "Не найдено пользователей в /home/." >&2
        return 1
    fi

    printf '%s\n' "${user_list[@]}" | sort -u
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --home)
            if [[ $# -lt 2 ]]; then
                echo "Ошибка: после --home укажите путь к домашнему каталогу." >&2
                exit 1
            fi
            TARGET_HOME="$2"
            shift 2
            ;;
        --release)
            if [[ $# -lt 2 ]]; then
                echo "Ошибка: после --release укажите тег релиза." >&2
                exit 1
            fi
            RELEASE_TAG="$2"
            shift 2
            ;;
        --user)
            if [[ $# -lt 2 ]]; then
                echo "Ошибка: после --user укажите имя пользователя." >&2
                exit 1
            fi
            USER_NAME="$2"
            TARGET_HOME="/home/$USER_NAME"
            shift 2
            ;;
        --select-user)
            SELECT_USER=1
            shift
            ;;
        --list-users)
            LIST_USERS_ONLY=1
            shift
            ;;
        --auto)
            AUTO_USER=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Неизвестный параметр: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ "$LIST_USERS_ONLY" -eq 1 ]]; then
    mapfile -t USERS < <(list_users || true)
    if [[ ${#USERS[@]} -eq 0 ]]; then
        echo "Не найдено пользователей в /home/." >&2
        exit 1
    fi
    echo "Доступные пользователи:"
    for i in "${!USERS[@]}"; do
        echo "$((i+1))) ${USERS[$i]}"
    done
    exit 0
fi

if [[ "$AUTO_USER" -eq 1 ]]; then
    mapfile -t USERS < <(list_users || true)
    if [[ ${#USERS[@]} -eq 0 ]]; then
        echo "Не найдено пользователей в /home/." >&2
        exit 1
    fi
    USER_NAME="${USERS[0]}"
    TARGET_HOME="/home/$USER_NAME"
    echo "Автовыбор пользователя: $USER_NAME"
fi

if [[ "$SELECT_USER" -eq 1 ]]; then
    echo "Доступные пользователи:"
    mapfile -t USERS < <(list_users || true)
    if [[ ${#USERS[@]} -eq 0 ]]; then
        echo "Не найдено пользователей в /home/." >&2
        exit 1
    fi
    for i in "${!USERS[@]}"; do
        echo "$((i+1))) ${USERS[$i]}"
    done
    echo ""
    read -p "Выберите номер пользователя: " USER_CHOICE
    if ! [[ "$USER_CHOICE" =~ ^[0-9]+$ ]] || (( USER_CHOICE < 1 || USER_CHOICE > ${#USERS[@]} )); then
        echo "Ошибка: неверный номер пользователя." >&2
        exit 1
    fi
    USER_NAME="${USERS[$((USER_CHOICE-1))]}"
    TARGET_HOME="/home/$USER_NAME"
fi

REPO_OWNER="teanrus"
REPO_NAME="astra-gia"
ASSET_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${RELEASE_TAG}/extensions.tar.gz"
ARCHIVE_NAME="extensions.tar.gz"

printf '%s\n' "============================================================"
printf '%s\n' "Установка расширений VS Code из релиза Astra GIA"
printf '%s\n' "============================================================"
printf 'Целевой каталог: %s\n' "$TARGET_HOME/.vscode"
printf 'URL архива: %s\n' "$ASSET_URL"

if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '\nРежим dry-run: скачивание и распаковка будут пропущены.\n'
    exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "Ошибка: curl не найден. Установите curl и повторите запуск." >&2
    exit 1
fi

mkdir -p "$TARGET_HOME/.vscode"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

ARCHIVE_PATH="$TMP_DIR/$ARCHIVE_NAME"

echo "Скачивание архива расширений..."
curl -fL --retry 3 --retry-delay 2 -o "$ARCHIVE_PATH" "$ASSET_URL"

echo "Распаковка архива..."
mkdir -p "$TMP_DIR/extract"
tar -xzf "$ARCHIVE_PATH" -C "$TMP_DIR/extract"

SOURCE_EXT_DIR="$TMP_DIR/extract/extensions"
if [[ ! -d "$SOURCE_EXT_DIR" ]]; then
    echo "Ошибка: в архиве отсутствует каталог extensions/." >&2
    exit 1
fi

echo "Копирование расширений в $TARGET_HOME/.vscode/ ..."
cp -a "$SOURCE_EXT_DIR"/. "$TARGET_HOME/.vscode/"

echo "============================================================"
echo "Готово. Расширения VS Code установлены в $TARGET_HOME/.vscode/"
echo "============================================================"
