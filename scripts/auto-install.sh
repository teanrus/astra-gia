#!/bin/bash

##############################################################################
# auto-install.sh — Автоматизированная установка ПО для Astra Linux SE 1.8
#
# Описание:
#   Интерактивный и CLI-инсталлятор выбранного ПО с выбором репозитория Astra.
#   Полное обновление ОС выполняется только с --upgrade-os через astra-update.
#
# Использование:
#   ./auto-install.sh [опции]
#
# Зависимости: bash, apt-get, sudo, wget, curl, sha256sum
##############################################################################

# === КОНФИГУРАЦИЯ ===
readonly SCRIPT_VERSION="2.0"
readonly GITHUB_RELEASE_TAG="v2.0"
readonly GITHUB_RELEASE_BASE_URL="https://github.com/teanrus/astra-gia/releases/download/${GITHUB_RELEASE_TAG}/"

# === ГЛОБАЛЬНОЕ СОСТОЯНИЕ ===
REPO_BRANCH=""
AUTO_MODE=0
LIST_ONLY=0
DRY_RUN=0
SAVE_LOG=0
UPGRADE_OS=0
INSTALL_GROUPS=()
INSTALL_R7_REPO=0
INSTALL_R7_RELEASE=0
INSTALL_MAX_REPO=0
PACKAGE_INSTALL_FAILURES=()
SUDO_KEEPALIVE_PID=""

# === ФУНКЦИИ ===
cleanup_on_exit() {
    if [[ -n "$SUDO_KEEPALIVE_PID" ]]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
        wait "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    fi

    if [[ -n "${DOWNLOAD_OWNER_UID:-}" && -d "${DEB_DOWNLOAD_DIR:-}" ]]; then
        chown -R "$DOWNLOAD_OWNER_UID:$DOWNLOAD_OWNER_GID" "$DEB_DOWNLOAD_DIR" \
            || echo "Предупреждение: не удалось восстановить владельца временной папки." >&2
    fi
}
trap cleanup_on_exit EXIT

enable_sudo_auth() {
    if (( EUID == 0 )); then
        return 0
    fi

    if ! command sudo -v; then
        echo "Ошибка: не удалось подтвердить права sudo." >&2
        return 1
    fi

    sudo() {
        command sudo -n "$@"
    }

    (
        sleep_pid=""
        stop_keepalive() {
            if [[ -n "$sleep_pid" ]]; then
                kill "$sleep_pid" 2>/dev/null || true
                wait "$sleep_pid" 2>/dev/null || true
            fi
            exit 0
        }
        trap stop_keepalive TERM INT

        while :; do
            sleep 60 &
            sleep_pid=$!
            wait "$sleep_pid" || exit
            sleep_pid=""
            command sudo -n -v >/dev/null 2>&1 || exit
        done
    ) &
    SUDO_KEEPALIVE_PID=$!
}

usage() {
    cat <<'EOF'
Использование:
  ./auto-install.sh [опции]

Опции:
  --repo <frozen|stable>     Выбор ветки репозитория Astra Linux 1.8
  --office                   Установить офисный софт
  --internet                 Установить браузеры и мессенджеры
  --programming              Установить инструменты для программирования и информатики
  --graphics                 Установить графику, мультимедиа и утилиты
  --edu                      Установить учебные и образовательные инструменты
  --all                      Выбрать всё
  --full-os                  Полная установка всей ОС (все категории)
  --browsers-only            Только браузеры и мессенджеры
  --education-only           Только обучение/ЕГЭ/ОГЭ инструменты
  --dry-run                  Показать что будет установлено без реальной установки
  --upgrade-os               Обновить ОС утилитой Astra: astra-update -A -r -T
  --list                     Показать список доступных пакетов и категорий
  --save-log                 Сохранить вывод скрипта в файл с временной меткой
  --r7-office                Установить R7 Office через репозиторий
  --r7-office-release        Установить R7 Office из GitHub Releases без обращения к репозиторию
  --max                      Установить MAX через репозиторий
  -h, --help                 Показать эту справку

Примеры:
  ./auto-install.sh --repo stable --office --internet
  ./auto-install.sh --repo frozen --programming --edu
  ./auto-install.sh --full-os
  ./auto-install.sh --browsers-only --dry-run
  ./auto-install.sh --education-only --list
  ./auto-install.sh --all
EOF
}

print_package_list() {
    cat <<'EOF'
Доступные категории и пакеты:

[office]
  - Foxit PDF Reader
  - NAPS2
  - OnlyOffice Desktop Editors
  - Сервис Среда
  - R7 Office
  - MAX

[internet]
  - ВК Мессенджер
  - Сервис Среда
  - MAX
  - Яндекс Браузер

[programming]
  - Code::Blocks
  - Eclipse IDE for C/C++ Developers 2026.09
  - Eclipse IDE for Java Developers 2026.09
  - IDLE 3 (Python 3.11)
  - Notepad++ 8.9.8.1
  - PascalABC.NET
  - PyCharm
  - Visual Studio Code
  - Python 3.12.13

[graphics]
  - Scribus
  - Audacity
  - OBS Studio

[edu]
  - КуМир 2
  - Basic 256
  - Code::Blocks
  - Eclipse IDE for Java Developers 2026.09
  - IDLE 3 (Python 3.11)
  - Notepad++ 8.9.8.1
  - PascalABC.NET
  - PyCharm
  - Python 3.12.13
  - Visual Studio Code
  - R7 Office
  - Foxit PDF Reader

[extra: самостоятельные флаги]
  - R7 Office (--r7-office)
  - R7 Office из GitHub Releases (--r7-office-release)
  - MAX (--max)
EOF
}

detect_astra_version() {
    local candidate version="" base_version=""
    local -a version_candidates=()

    if [[ -r /etc/astra_version ]]; then
        version_candidates+=("$(< /etc/astra_version)")
    fi

    if [[ -r /etc/os-release ]]; then
        while IFS='=' read -r key value; do
            case "$key" in
                VERSION_ID|PRETTY_NAME)
                    value="${value%\"}"
                    value="${value#\"}"
                    version_candidates+=("$value")
                    ;;
            esac
        done < /etc/os-release
    fi

    for candidate in "${version_candidates[@]}"; do
        if [[ "$candidate" =~ (1\.8(\.[0-9]+)?) ]]; then
            version="${BASH_REMATCH[1]}"
            if [[ "$version" == 1.8.* ]]; then
                printf '%s\n' "$version"
                return 0
            fi
            base_version="$version"
        fi
    done

    if [[ -n "$base_version" ]]; then
        printf '%s\n' "$base_version"
        return 0
    fi

    echo "Ошибка: не удалось определить версию Astra Linux 1.8 из /etc/astra_version или /etc/os-release." >&2
    return 1
}

# === ОСНОВНОЙ СЦЕНАРИЙ: АРГУМЕНТЫ И ОПРЕДЕЛЕНИЕ ОС ===
while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo)
            if [[ $# -lt 2 ]]; then
                echo "Ошибка: после --repo укажите frozen или stable." >&2
                exit 1
            fi
            if [[ "$2" != "frozen" && "$2" != "stable" ]]; then
                echo "Ошибка: поддерживаются только ветки frozen или stable." >&2
                exit 1
            fi
            REPO_BRANCH="$2"
            shift 2
            ;;
        --office|--internet|--programming|--graphics|--edu|--all)
            INSTALL_GROUPS+=("${1#--}")
            shift
            ;;
        --full-os)
            INSTALL_GROUPS+=("all")
            shift
            ;;
        --browsers-only)
            INSTALL_GROUPS+=("internet")
            shift
            ;;
        --education-only)
            INSTALL_GROUPS+=("edu")
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --upgrade-os)
            UPGRADE_OS=1
            shift
            ;;
        --list)
            LIST_ONLY=1
            shift
            ;;
        --save-log)
            SAVE_LOG=1
            shift
            ;;
        --r7-office)
            INSTALL_R7_REPO=1
            shift
            ;;
        --r7-office-release)
            INSTALL_R7_RELEASE=1
            shift
            ;;
        --max)
            INSTALL_MAX_REPO=1
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

if [[ $LIST_ONLY -eq 1 ]]; then
    print_package_list
    exit 0
fi

if ! ASTRA_VERSION=$(detect_astra_version); then
    exit 1
fi
if [[ "$ASTRA_VERSION" != 1.8 && "$ASTRA_VERSION" != 1.8.* ]]; then
    echo "Ошибка: обнаружена Astra Linux версии $ASTRA_VERSION; этот скрипт поддерживает только ветку 1.8." >&2
    exit 1
fi

FROZEN_VERSION=""
case "$ASTRA_VERSION" in
    1.8.4|1.8.5|1.8.6)
        FROZEN_VERSION="$ASTRA_VERSION"
        ;;
esac

if [[ ${#INSTALL_GROUPS[@]} -gt 0 || -n "$REPO_BRANCH" || $UPGRADE_OS -eq 1 || "${INSTALL_R7_REPO:-0}" == "1" || "${INSTALL_R7_RELEASE:-0}" == "1" || "${INSTALL_MAX_REPO:-0}" == "1" ]]; then
    AUTO_MODE=1
fi
if [[ "$INSTALL_R7_RELEASE" == "1" ]]; then
    INSTALL_R7_REPO=0
fi

if [[ $SAVE_LOG -eq 0 && -t 0 ]]; then
    read -r -p "Сохранить лог работы скрипта? (y/n): " save_log_ans
    if [[ "$save_log_ans" =~ ^[YyДд]$ ]]; then
        SAVE_LOG=1
    fi
fi

if [[ $SAVE_LOG -eq 1 ]]; then
    LOG_FILE="$PWD/auto-install-$(date +%Y%m%d-%H%M%S).log"
    if ! touch "$LOG_FILE"; then
        echo "Ошибка: не удалось создать файл лога: $LOG_FILE" >&2
        exit 1
    fi
    exec > >(tee -a "$LOG_FILE") 2>&1
    echo "Лог работы сохраняется в: $LOG_FILE"
fi

echo "==============================================================================="
echo "Интерактивный скрипт автоматизации установки ПО для ALSE 1.8"
echo "Версия скрипта: $SCRIPT_VERSION"
echo "R.Tyan (c) 2026 | tyanrv@lbt.yanao.ru"
echo ""
echo ""
echo "================================================================================"
echo "Обнаружена Astra Linux $ASTRA_VERSION."

if [[ $AUTO_MODE -eq 0 ]]; then
    read -p "Нажмите Enter для начала настройки списка установки..."
fi

echo " "
echo "Активация репозиториев в ALSE 1.8 для установки стороннего софта и зависимостей"
echo " "

if [[ -n "$REPO_BRANCH" ]]; then
    NUMBER="$REPO_BRANCH"
else
    if [[ $AUTO_MODE -eq 1 ]]; then
        if [[ ${#INSTALL_GROUPS[@]} -gt 0 ]]; then
            echo "Авто-режим активирован. Выбираем репозиторий с учетом версии ОС..."
        fi
        if [[ -n "$FROZEN_VERSION" ]]; then
            NUMBER="frozen"
        else
            NUMBER="stable"
        fi
    else
        echo "1 - Ветка Stable для Astra Linux 1.8 (получение оперативных обновлений ОС)"
        if [[ -n "$FROZEN_VERSION" ]]; then
            echo "2 - Ветка Frozen для установленной версии Astra Linux $FROZEN_VERSION"
        else
            echo "Для версии $ASTRA_VERSION ветка Frozen в скрипте не поддерживается; доступна Stable."
        fi
        read -r -p "Укажите числовое значение: " REPO_CHOICE
        case "$REPO_CHOICE" in
            1) NUMBER="stable" ;;
            2)
                if [[ -n "$FROZEN_VERSION" ]]; then
                    NUMBER="frozen"
                else
                    echo "Ошибка: для версии $ASTRA_VERSION ветка Frozen недоступна." >&2
                    exit 1
                fi
                ;;
            *)
                echo "Ошибка: укажите 1 (Stable) или доступный номер ветки Frozen." >&2
                exit 1
                ;;
        esac
    fi
fi

# === НАСТРОЙКА РЕПОЗИТОРИЯ ОС ===
case "$NUMBER" in
    frozen)
        if [[ -z "$FROZEN_VERSION" ]]; then
            echo "Ошибка: для установленной версии Astra Linux $ASTRA_VERSION ветка Frozen не поддерживается." >&2
            exit 1
        fi
        REPO_FILE="/etc/apt/sources.list.d/astra-frozen-extended.list"
        OTHER_REPO_FILE="/etc/apt/sources.list.d/astra-stable-extended.list"
        REPO_LINES=(
            "deb [arch=amd64] https://download.astralinux.ru/astra/frozen/1.8_x86-64/$FROZEN_VERSION/repository-extended/ 1.8_x86-64 main contrib non-free non-free-firmware"
            "deb [arch=amd64] https://download.astralinux.ru/astra/frozen/1.8_x86-64/$FROZEN_VERSION/repository-main/ 1.8_x86-64 main contrib non-free non-free-firmware"
        )
        echo "Выбрана ветка Frozen для Astra Linux $FROZEN_VERSION."
        ;;
    stable)
        REPO_FILE="/etc/apt/sources.list.d/astra-stable-extended.list"
        OTHER_REPO_FILE="/etc/apt/sources.list.d/astra-frozen-extended.list"
        REPO_LINES=(
            "deb [arch=amd64] https://download.astralinux.ru/astra/stable/1.8_x86-64/repository-extended/ 1.8_x86-64 main contrib non-free non-free-firmware"
            "deb [arch=amd64] https://download.astralinux.ru/astra/stable/1.8_x86-64/repository-main/ 1.8_x86-64 main contrib non-free non-free-firmware"
        )
        echo "Выбрана ветка Stable для Astra Linux 1.8."
        ;;
    *)
        echo "Ошибка: неизвестная ветка репозитория: $NUMBER." >&2
        exit 1
        ;;
esac

if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY-RUN: пропускаем изменение системных репозиториев и установку пакетов."
else
    if ! enable_sudo_auth; then
        exit 1
    fi
    if ! sudo rm -f "$OTHER_REPO_FILE" || ! printf '%s\n' "${REPO_LINES[@]}" | sudo tee "$REPO_FILE" >/dev/null; then
        echo "Ошибка: не удалось записать выбранный репозиторий в $REPO_FILE." >&2
        exit 1
    fi
fi

deduplicate_apt_sources() {
    local apt_dir="${1:-/etc/apt}"
    sudo bash -s -- "$apt_dir" <<'ROOT_SCRIPT'
set -euo pipefail
shopt -s nullglob
apt_dir="$1"
source_files=("$apt_dir/sources.list" "$apt_dir"/sources.list.d/*.list)
declare -A seen_entries=()
declare -A processed_files=()
duplicates_removed=0

for source_path in "${source_files[@]}"; do
    [[ -f "$source_path" ]] || continue
    source_file=$(readlink -f -- "$source_path")
    [[ ! ${processed_files["$source_file"]+present} ]] || continue
    processed_files["$source_file"]=1
    temp_file=$(mktemp "${source_file}.XXXXXX")
    cp -p "$source_file" "$temp_file"
    : > "$temp_file"

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^[[:space:]]*deb(-src)?[[:space:]] ]]; then
            read -r -a fields <<< "$line"
            normalized_line=""
            for field in "${fields[@]}"; do
                [[ "$field" == \#* ]] && break
                if [[ "$field" =~ ^https?:// ]]; then
                    while [[ "$field" == */ ]]; do
                        field="${field%/}"
                    done
                fi
                normalized_line+="${field} "
            done
            normalized_line="${normalized_line% }"

            if [[ -n "$normalized_line" && ${seen_entries["$normalized_line"]+present} ]]; then
                duplicates_removed=$((duplicates_removed + 1))
                continue
            fi
            if [[ -n "$normalized_line" ]]; then
                seen_entries["$normalized_line"]=1
            fi
        fi
        printf '%s\n' "$line" >> "$temp_file"
    done < "$source_file"

    if cmp -s "$source_file" "$temp_file"; then
        rm -f "$temp_file"
    else
        mv "$temp_file" "$source_file"
    fi
done

printf 'Удалено дублирующихся записей APT: %s\n' "$duplicates_removed"
ROOT_SCRIPT
}

disable_obsolete_frozen_sources() {
    local apt_dir="${1:-/etc/apt}"
    local selected_version="$2"
    sudo python3 - "$apt_dir" "$selected_version" <<'PYTHON'
import re
import sys
from pathlib import Path

apt_dir = Path(sys.argv[1])
selected_version = sys.argv[2]
frozen_url = re.compile(
    r"https?://(?:download|dl)\.astralinux\.ru/astra/frozen/1\.8_x86-64/([^/\s]+)/"
)
source_files = [apt_dir / "sources.list"]
source_dir = apt_dir / "sources.list.d"
source_files.extend(sorted(source_dir.glob("*.list")))
source_files.extend(sorted(source_dir.glob("*.sources")))
disabled = 0

for source_file in source_files:
    if not source_file.is_file():
        continue
    with source_file.open("r", encoding="utf-8", newline="") as source:
        content = source.read()
    if source_file.suffix == ".sources":
        parts = re.split(r"((?:\r?\n)[ \t]*(?:\r?\n))", content)
        for index in range(0, len(parts), 2):
            stanza = parts[index]
            if not re.search(r"(?im)^URIs?:", stanza):
                continue
            versions = frozen_url.findall(stanza)
            if not any(version != selected_version for version in versions):
                continue
            enabled = re.search(r"(?im)^Enabled:[ \t]*([^\r\n]*)", stanza)
            if enabled and enabled.group(1).strip().lower() == "no":
                continue
            if enabled:
                stanza = re.sub(
                    r"(?im)^Enabled:[^\r\n]*", "Enabled: no", stanza, count=1
                )
            else:
                newline = "\r\n" if "\r\n" in stanza else "\n"
                stanza = stanza.rstrip("\r\n") + newline + "Enabled: no" + newline
            parts[index] = stanza
            disabled += 1
        updated_content = "".join(parts)
    else:
        updated_lines = []
        for line in content.splitlines(keepends=True):
            if line.lstrip().startswith("#"):
                updated_lines.append(line)
                continue
            versions = frozen_url.findall(line)
            if any(version != selected_version for version in versions):
                indent = line[: len(line) - len(line.lstrip())]
                line = indent + "# disabled by auto-install.sh: " + line[len(indent) :]
                disabled += 1
            updated_lines.append(line)
        updated_content = "".join(updated_lines)

    if updated_content != content:
        with source_file.open("w", encoding="utf-8", newline="") as source:
            source.write(updated_content)

print(f"Отключено устаревших Astra Frozen-источников: {disabled}")
PYTHON
}

# --- Подготовка репозиториев и пакетов ---
if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY-RUN: пропускаем изменения системы, обновление списков пакетов и установку."
    if [[ $UPGRADE_OS -eq 1 ]]; then
        echo "DRY-RUN: было бы выполнено обновление ОС: sudo astra-update -A -r -T."
    fi
else
    echo "Отключение CD-ROM репозитория (чтобы система не просила вставить диск)..."
    sudo sed -i '/cdrom:/ s/^/#/' /etc/apt/sources.list
    sudo find /etc/apt/sources.list.d/ -type f -name "*.list" -exec sed -i '/cdrom:/ s/^/#/' {} \; 2>/dev/null

    echo "Подготовка раскладки клавиатуры для безынтерактивной установки..."
    if ! printf '%s\n' \
        'keyboard-configuration keyboard-configuration/layoutcode string ru' \
        'keyboard-configuration keyboard-configuration/xkb-keymap select ru' \
        | sudo debconf-set-selections; then
        echo "Ошибка: не удалось задать безынтерактивные параметры keyboard-configuration." >&2
        exit 1
    fi
    echo "Проверка и исправление некорректных записей репозиториев от предыдущих запусков..."
    sudo find /etc/apt/sources.list /etc/apt/sources.list.d/ -type f -name "*.list" -exec sed -i \
        -e 's|downloads.r7-office.ru/repository/r7-desktop-astra r7|downloads.r7-office.ru/repository/r7-desktop-astra/ astralinux|g' \
        -e 's|downloads.r7-office.ru/repository/r7-desktop-astra/ r7|downloads.r7-office.ru/repository/r7-desktop-astra/ astralinux|g' \
        -e 's|downloads.r7-office.ru/repository/r7-desktop-astra astralinux|downloads.r7-office.ru/repository/r7-desktop-astra/ astralinux|g' \
        {} \; 2>/dev/null

    if [[ "$NUMBER" == "frozen" ]]; then
        echo "Отключение дополнительного Stable main-repository, чтобы не смешивать его с Frozen..."
        if ! sudo sed -i '\|^deb https://dl.astralinux.ru/astra/stable/1\.8_x86-64/main-repository/|s|^|# disabled: |' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null; then
            echo "Ошибка: не удалось отключить Stable main-repository при выборе Frozen." >&2
            exit 1
        fi
    else
        if ! sudo sed -i '\|^# disabled: deb https://dl.astralinux.ru/astra/stable/1\.8_x86-64/main-repository/|s|^# disabled: ||' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null; then
            echo "Ошибка: не удалось повторно включить Stable main-repository." >&2
            exit 1
        fi
        if ! grep -Eq "^[[:space:]]*deb .*dl.astralinux.ru/astra/stable/1.8_x86-64/main-repository" /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null; then
            echo "Добавление основного репозитория Astra Linux 1.8 для разрешения зависимостей..."
            echo "deb https://dl.astralinux.ru/astra/stable/1.8_x86-64/main-repository/ 1.8_x86-64 main contrib non-free" | sudo tee /etc/apt/sources.list.d/astra-main.list >/dev/null
        fi
    fi

    if [[ "$NUMBER" == "frozen" ]]; then
        echo "Отключение Astra Frozen-репозиториев других версий..."
        if ! disable_obsolete_frozen_sources /etc/apt "$FROZEN_VERSION"; then
            echo "Ошибка: не удалось отключить устаревшие Astra Frozen-репозитории." >&2
            exit 1
        fi
    fi

    echo "Проверка конфигурации на дублирующиеся APT-репозитории..."
    if ! deduplicate_apt_sources; then
        echo "Ошибка: не удалось проверить и исправить дублирующиеся APT-репозитории." >&2
        exit 1
    fi

    echo "Обновление списков пакетов (это может занять некоторое время)..."
    if ! sudo apt-get update; then
        echo "Ошибка: не удалось обновить списки пакетов." >&2
        exit 1
    fi

    if [[ $UPGRADE_OS -eq 1 ]]; then
        echo "Запрошено полное обновление ОС..."
        if ! sudo astra-update -A -r -T; then
            echo "Ошибка: не удалось выполнить astra-update -A -r -T." >&2
            exit 1
        fi
    else
        echo "Полное обновление ОС пропущено; будут установлены только выбранные приложения."
    fi

    install_sane=0
    if [[ $AUTO_MODE -eq 0 ]]; then
        read -r -p "Установить подсистему сканирования SANE (sane, sane-utils)? (y/n): " sane_ans
        if [[ "$sane_ans" =~ ^[YyДд]$ ]]; then
            install_sane=1
        else
            echo "Установка SANE пропущена."
        fi
    fi

    if [[ $install_sane -eq 1 ]]; then
        echo "Установка подсистемы сканирования SANE..."
        if ! sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y sane sane-utils; then
            echo "Ошибка: не удалось установить подсистему сканирования SANE." >&2
            exit 1
        fi
    fi
fi
# -----------------------------------------------------------------------------

# === КАТАЛОГ ПАКЕТОВ И ОЧЕРЕДЬ УСТАНОВКИ ===
# Массивы для хранения выбора пользователя
declare -a URLS_TO_DOWNLOAD
declare -a NAMES_TO_DOWNLOAD
declare -a APT_PACKAGES_TO_INSTALL
declare -A PACKAGE_NAMES=(
    [foxit]="Foxit PDF Reader"
    [naps2]="NAPS2"
    [onlyoffice]="OnlyOffice Desktop Editors"
    [r7-office]="R7 Office"
    [sreda]="Сервис Среда"
    [vkmessenger]="ВК Мессенджер"
    [codeblocks]="Code::Blocks"
    [eclipse-cpp]="Eclipse IDE for C/C++ Developers 2026.09"
    [eclipse-java]="Eclipse IDE for Java Developers 2026.09"
    [notepadplus]="Notepad++ 8.9.8.1"
    [pascalabc]="PascalABC.NET"
    [pycharm]="PyCharm"
    [vscode]="Visual Studio Code"
    [python-3.9]="Python 3.9.25"
    [python-3.10]="Python 3.10.20"
    [python-3.12]="Python 3.12.13"
    [python-3.13]="Python 3.13.15"
    [python-3.14]="Python 3.14.7"
    [obs]="OBS Studio"
    [kumir]="КуМир 2"
)
declare -A PACKAGE_URLS=(
    [foxit]="${GITHUB_RELEASE_BASE_URL}foxitreader.deb"
    [naps2]="${GITHUB_RELEASE_BASE_URL}naps2.deb"
    [onlyoffice]="${GITHUB_RELEASE_BASE_URL}onlyoffice.deb"
    [r7-office]="${GITHUB_RELEASE_BASE_URL}r7-office.deb"
    [sreda]="${GITHUB_RELEASE_BASE_URL}sreda.deb"
    [vkmessenger]="${GITHUB_RELEASE_BASE_URL}vk-messenger.deb"
    [codeblocks]="${GITHUB_RELEASE_BASE_URL}codeblocks.deb"
    [eclipse-cpp]="${GITHUB_RELEASE_BASE_URL}eclipse-cpp.deb"
    [eclipse-java]="${GITHUB_RELEASE_BASE_URL}eclipse-java.deb"
    [notepadplus]="${GITHUB_RELEASE_BASE_URL}notepadplus.deb"
    [pascalabc]="${GITHUB_RELEASE_BASE_URL}pascalABC.deb"
    [pycharm]="${GITHUB_RELEASE_BASE_URL}pycharm.deb"
    [vscode]="${GITHUB_RELEASE_BASE_URL}code.deb"
    [python-3.9]="${GITHUB_RELEASE_BASE_URL}python-3.9.25-alse1.8-amd64.deb"
    [python-3.10]="${GITHUB_RELEASE_BASE_URL}python-3.10.20-alse1.8-amd64.deb"
    [python-3.12]="${GITHUB_RELEASE_BASE_URL}python-3.12.13-alse1.8-amd64.deb"
    [python-3.13]="${GITHUB_RELEASE_BASE_URL}python-3.13.15-alse1.8-amd64.deb"
    [python-3.14]="${GITHUB_RELEASE_BASE_URL}python-3.14.7-alse1.8-amd64.deb"
    [obs]="${GITHUB_RELEASE_BASE_URL}obs-studio.deb"
    [kumir]="${GITHUB_RELEASE_BASE_URL}kumir2.deb"
)
add_group_apt() {
    local package="$1"
    local existing_package
    for existing_package in "${APT_PACKAGES_TO_INSTALL[@]}"; do
        if [[ "$existing_package" == "$package" ]]; then
            return
        fi
    done
    APT_PACKAGES_TO_INSTALL+=("$package")
}

add_group_package() {
    local package_key="$1"
    local name="${PACKAGE_NAMES[$package_key]:-}"
    local url="${PACKAGE_URLS[$package_key]:-}"
    local existing_url
    if [[ -z "$name" || -z "$url" ]]; then
        echo "Ошибка: неизвестный ключ пакета: $package_key" >&2
        return 1
    fi
    for existing_url in "${URLS_TO_DOWNLOAD[@]}"; do
        if [[ "$existing_url" == "$url" ]]; then
            return
        fi
    done
    URLS_TO_DOWNLOAD+=("$url")
    NAMES_TO_DOWNLOAD+=("$name")
}

# === ФУНКЦИИ ВЫБОРА ПАКЕТОВ ===
# Функция для обычного .deb пакета
ask_deb() {
local package_key=$1
local name="${PACKAGE_NAMES[$package_key]}"
local url="${PACKAGE_URLS[$package_key]}"
read -p "Установить [ $name ]? (y/n): " ans
if [[ "$ans" =~ ^[YyДд]$ ]]; then
URLS_TO_DOWNLOAD+=("$url")
NAMES_TO_DOWNLOAD+=("$name")
echo -e "\e[32m  -> Добавлено в очередь на скачивание.\e[0m"
else
echo -e "\e[33m  -> Пропущено.\e[0m"
fi
}

ask_apt() {
local package="$1"
local name="$2"
read -r -p "Установить [ $name ] из репозитория? (y/n): " ans
if [[ "$ans" =~ ^[YyДд]$ ]]; then
    add_group_apt "$package"
    echo -e "\e[32m  -> Добавлено в очередь apt install.\e[0m"
else
    echo -e "\e[33m  -> Пропущено.\e[0m"
fi
}

ask_repository_package() {
local name="$1"
local repo_flag="$2"
read -r -p "Установить [ $name ] из официального репозитория? (y/n): " ans
if [[ "$ans" =~ ^[YyДд]$ ]]; then
    if [[ "$repo_flag" == "R7" ]]; then
        INSTALL_R7_REPO=1
    else
        INSTALL_MAX_REPO=1
    fi
    echo -e "\e[32m  -> Добавлено в очередь установки из репозитория.\e[0m"
else
    echo -e "\e[33m  -> Пропущено.\e[0m"
fi
}

# Функция для выбора версии Python
ask_python() {
read -p "Установить Python (выбор конкретной версии)? (y/n): " ans
if [[ "$ans" =~ ^[YyДд]$ ]]; then
echo "Доступные версии Python для ALSE 1.8:"
echo "  1) Python 3.9.25"
echo "  2) Python 3.10.20"
echo "  3) Python 3.12.13"
echo "  4) Python 3.13.15"
echo "  5) Python 3.14.7"
echo "  0) Пропустить"
read -p "Выберите версию (1-5 или 0): " py_ans
local py_key=""
case $py_ans in
1) py_key="python-3.9" ;;
2) py_key="python-3.10" ;;
3) py_key="python-3.12" ;;
4) py_key="python-3.13" ;;
5) py_key="python-3.14" ;;
*)
echo -e "\e[33m  -> Пропущено.\e[0m"
return
;;
esac
if [ -n "$py_key" ]; then
URLS_TO_DOWNLOAD+=("${PACKAGE_URLS[$py_key]}")
NAMES_TO_DOWNLOAD+=("${PACKAGE_NAMES[$py_key]}")
echo -e "\e[32m  -> Выбран ${PACKAGE_NAMES[$py_key]}. Добавлено в очередь.\e[0m"
fi
else
echo -e "\e[33m  -> Пропущено.\e[0m"
fi
}

echo ""
# === ФОРМИРОВАНИЕ ОЧЕРЕДИ УСТАНОВКИ ===
if [[ $AUTO_MODE -eq 1 ]]; then
    process_group_selection() {
        local group="$1"
        case "$group" in
            office)
                add_group_package foxit
                add_group_package naps2
                add_group_package onlyoffice
                if [[ "$INSTALL_R7_RELEASE" == "0" ]]; then
                    INSTALL_R7_REPO=1
                fi
                INSTALL_MAX_REPO=1
                add_group_package sreda
                ;;
            internet)
                add_group_package vkmessenger
                add_group_package sreda
                INSTALL_MAX_REPO=1
                add_group_apt yandex-browser-stable
                ;;
            programming)
                add_group_package codeblocks
                add_group_package eclipse-cpp
                add_group_package eclipse-java
                add_group_apt idle
                add_group_package notepadplus
                add_group_package pascalabc
                add_group_package pycharm
                add_group_package vscode
                add_group_package python-3.12
                ;;
            graphics)
                add_group_apt scribus
                add_group_apt audacity
                add_group_package obs
                ;;
            edu)
                add_group_package kumir
                add_group_apt basic256
                add_group_package codeblocks
                add_group_package eclipse-java
                add_group_apt idle
                add_group_package notepadplus
                add_group_package pascalabc
                add_group_package pycharm
                add_group_package python-3.12
                add_group_package vscode
                if [[ "$INSTALL_R7_RELEASE" == "0" ]]; then
                    INSTALL_R7_REPO=1
                fi
                add_group_package foxit
                ;;
            all)
                process_group_selection office
                process_group_selection internet
                process_group_selection programming
                process_group_selection graphics
                process_group_selection edu
                ;;
        esac
    }

    echo "=== РАЗДЕЛ 1: ВЫБРАННЫЕ КАТЕГОРИИ ==="
    for group in "${INSTALL_GROUPS[@]}"; do
        process_group_selection "$group"
    done
    if [[ "$INSTALL_R7_RELEASE" == "1" ]]; then
        add_group_package r7-office
    fi
    if [[ ${#INSTALL_GROUPS[@]} -eq 0 \
        && ${#URLS_TO_DOWNLOAD[@]} -eq 0 \
        && ${#APT_PACKAGES_TO_INSTALL[@]} -eq 0 \
        && "$INSTALL_R7_REPO" == "0" \
        && "$INSTALL_R7_RELEASE" == "0" \
        && "$INSTALL_MAX_REPO" == "0" ]]; then
        echo "Не выбрана ни одна категория. Ничего не добавлено в очередь." 
    fi
else
    echo "=== РАЗДЕЛ 1: СТАНДАРТНЫЕ .DEB ПАКЕТЫ ==="
    ask_deb foxit
    ask_deb naps2
    ask_deb onlyoffice
    ask_deb vkmessenger
    ask_deb sreda
    ask_apt yandex-browser-stable "Яндекс Браузер"
    ask_apt scribus "Scribus"
    ask_apt audacity "Audacity"
    ask_deb obs
    ask_deb kumir
    ask_apt basic256 "Basic 256"
    ask_deb codeblocks
    ask_deb eclipse-cpp
    ask_deb eclipse-java
    ask_apt idle "IDLE 3 (Python 3.11)"
    ask_deb notepadplus
    ask_deb pascalabc
    ask_deb pycharm
    ask_deb vscode

    echo ""
    echo "=== РАЗДЕЛ 2: УСТАНОВКА ИЗ ОФИЦИАЛЬНЫХ РЕПОЗИТОРИЕВ ==="
    ask_repository_package "R7 Office" R7
    ask_repository_package "MAX" MAX

    echo ""
    echo "=== РАЗДЕЛ 3: СПЕЦИАЛЬНЫЕ ПАКЕТЫ ==="
    ask_python
fi

echo ""
echo "=== ОПРОС ЗАВЕРШЕН ==="
echo ""

if [[ $DRY_RUN -eq 1 ]]; then
    echo "Режим dry-run: список пакетов, которые были бы установлены:"
    if [ ${#URLS_TO_DOWNLOAD[@]} -gt 0 ]; then
        for i in "${!URLS_TO_DOWNLOAD[@]}"; do
            echo "  - ${NAMES_TO_DOWNLOAD[$i]} -> ${URLS_TO_DOWNLOAD[$i]}"
        done
    else
        echo "  - пустой список"
    fi
    if [ ${#APT_PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
        printf '  - apt install: %s\n' "${APT_PACKAGES_TO_INSTALL[*]}"
    fi
    if [ "$INSTALL_R7_REPO" == "1" ]; then
        echo "  - R7 Office"
    fi
    if [ "$INSTALL_MAX_REPO" == "1" ]; then
        echo "  - MAX"
    fi
    exit 0
fi

# --- Подготовка репозитория R7 Office и выбор резервного пакета ---
if [[ "$INSTALL_R7_REPO" == "1" ]]; then
    echo "Настройка репозитория и установка R7 Office..."
    R7_REPO_READY=1

    if ! sudo wget -qO /etc/apt/trusted.gpg.d/r7-office.asc \
        https://download.r7-office.ru/repos/RPM-GPG-KEY-R7-OFFICE.public; then
        echo "ОШИБКА: не удалось загрузить ключ репозитория R7 Office." >&2
        R7_REPO_READY=0
    fi

    if [[ "$R7_REPO_READY" -eq 1 ]] && ! sudo mkdir -p /etc/apt/auth.conf.d; then
        echo "ОШИБКА: не удалось создать каталог конфигурации авторизации APT." >&2
        R7_REPO_READY=0
    fi

    if [[ "$R7_REPO_READY" -eq 1 ]] && ! sudo tee /etc/apt/auth.conf.d/r7.conf > /dev/null <<EOF
machine downloads.r7-office.ru
login desktop
password gyxiLab84FByn7sCTd5JY
EOF
    then
        echo "ОШИБКА: не удалось записать конфигурацию авторизации APT для R7 Office." >&2
        R7_REPO_READY=0
    fi

    if [[ "$R7_REPO_READY" -eq 1 ]] && ! sudo chmod 600 /etc/apt/auth.conf.d/r7.conf; then
        echo "ОШИБКА: не удалось защитить файл авторизации APT для R7 Office." >&2
        R7_REPO_READY=0
    fi

    if [[ "$R7_REPO_READY" -eq 1 ]] \
        && ! echo "deb https://downloads.r7-office.ru/repository/r7-desktop-astra/ astralinux main" \
            | sudo tee /etc/apt/sources.list.d/r7-office.list > /dev/null; then
        echo "ОШИБКА: не удалось записать APT-репозиторий R7 Office." >&2
        R7_REPO_READY=0
    fi

    R7_REPO_FAILED=0
    if [[ "$R7_REPO_READY" -eq 1 ]]; then
        if ! sudo apt-get update; then
            echo "ОШИБКА: не удалось обновить списки пакетов для R7 Office." >&2
            R7_REPO_FAILED=1
        elif ! sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y r7-office; then
            echo "ОШИБКА: не удалось установить R7 Office из репозитория." >&2
            R7_REPO_FAILED=1
        fi
    else
        R7_REPO_FAILED=1
    fi

    if [[ "$R7_REPO_FAILED" == "1" ]]; then
        if [[ -t 0 ]]; then
            read -r -p "Репозиторий R7 Office недоступен. Установить пакет из GitHub Releases? (y/n): " fallback_answer
            if [[ "$fallback_answer" =~ ^[YyДд]$ ]]; then
                if ! add_group_package r7-office; then
                    echo "ОШИБКА: не удалось добавить резервный пакет R7 Office в очередь." >&2
                    PACKAGE_INSTALL_FAILURES+=("R7 Office (резервный пакет)")
                fi
            else
                echo "Резервная установка R7 Office пропущена."
                PACKAGE_INSTALL_FAILURES+=("R7 Office (не установлен)")
            fi
        else
            echo "Для резервной установки запустите скрипт с параметром --r7-office-release." >&2
            PACKAGE_INSTALL_FAILURES+=("R7 Office (репозиторий недоступен; резервный пакет не выбран)")
        fi
    fi
fi

# === УСТАНОВКА ВЫБРАННЫХ ПАКЕТОВ ===
# --- ЭТАП 1: Скачивание и установка .deb пакетов ---
if [ ${#URLS_TO_DOWNLOAD[@]} -gt 0 ]; then
DOWNLOAD_OWNER_UID=""
DOWNLOAD_OWNER_GID=""
if (( EUID == 0 )); then
    if [[ "${SUDO_UID:-}" =~ ^[1-9][0-9]*$ ]]; then
        DOWNLOAD_OWNER_UID="$SUDO_UID"
        DOWNLOAD_OWNER_GID="${SUDO_GID:-}"
        if [[ -z "$DOWNLOAD_OWNER_GID" ]]; then
            DOWNLOAD_OWNER_GID="$(stat -c %g -- "$PWD")"
        fi
    else
        DOWNLOAD_OWNER_UID="$(stat -c %u -- "$PWD")"
        if [[ "$DOWNLOAD_OWNER_UID" =~ ^[1-9][0-9]*$ ]]; then
            DOWNLOAD_OWNER_GID="$(stat -c %g -- "$PWD")"
        else
            echo "Ошибка: скрипт запущен от root без SUDO_USER, а текущая папка принадлежит root." >&2
            echo "Запустите скрипт от обычного пользователя; для системных операций он сам использует sudo." >&2
            exit 1
        fi
    fi
fi

DEB_DOWNLOAD_DIR="$PWD/deb-downloads"
if ! mkdir -p -- "$DEB_DOWNLOAD_DIR" || ! chmod 700 "$DEB_DOWNLOAD_DIR"; then
    echo "Ошибка: не удалось подготовить папку кэша пакетов: $DEB_DOWNLOAD_DIR" >&2
    exit 1
fi
if [[ -n "$DOWNLOAD_OWNER_UID" ]]; then
    if ! chown "$DOWNLOAD_OWNER_UID:$DOWNLOAD_OWNER_GID" "$DEB_DOWNLOAD_DIR"; then
        echo "Ошибка: не удалось назначить владельцем временной папки пользователя, запустившего скрипт." >&2
        exit 1
    fi
fi

is_valid_cached_deb() {
    local package_file="$1"
    local expected_checksum="$2"
    [[ -s "$package_file" ]] \
        && printf '%s  %s\n' "$expected_checksum" "$package_file" | sha256sum --check --status \
        && dpkg-deb --info "$package_file" >/dev/null 2>&1
}

declare -a DEB_FILES_TO_INSTALL=()
declare -a DEB_NAMES_TO_INSTALL=()
echo "Постоянный кэш пакетов: $DEB_DOWNLOAD_DIR"
echo "Загрузка выбранных .deb пакетов..."
for i in "${!URLS_TO_DOWNLOAD[@]}"; do
    package_name="${NAMES_TO_DOWNLOAD[$i]}"
    package_url="${URLS_TO_DOWNLOAD[$i]}"
    filename=$(basename "$package_url" | sed 's/.*file=\(.*\.deb\).*/\1/')
    if [[ "$filename" == *"raw"* ]] || [[ -z "$filename" ]]; then
        filename="package_${i}.deb"
    fi

    package_file="$DEB_DOWNLOAD_DIR/$filename"
    download_tmp="$package_file.part.$$"
    if [[ "$package_url" == "$GITHUB_RELEASE_BASE_URL"* ]]; then
        checksum_file="$package_file.sha256"
        checksum_tmp="$checksum_file.part.$$"
        if ! wget -q "${package_url}.sha256" -O "$checksum_tmp"; then
            echo "ОШИБКА: не удалось получить контрольную сумму для «$package_name»; пакет пропущен." >&2
            rm -f -- "$checksum_tmp"
            PACKAGE_INSTALL_FAILURES+=("$package_name")
            continue
        fi
        expected_checksum=$(awk -v filename="$filename" '$2 == filename || $2 == "*" filename { print $1; count++ } END { if (count != 1) exit 1 }' "$checksum_tmp") || expected_checksum=""
        if [[ ! "$expected_checksum" =~ ^[[:xdigit:]]{64}$ ]]; then
            echo "ОШИБКА: некорректная контрольная сумма для «$package_name»; пакет пропущен." >&2
            rm -f -- "$checksum_tmp"
            PACKAGE_INSTALL_FAILURES+=("$package_name")
            continue
        fi

        if is_valid_cached_deb "$package_file" "$expected_checksum"; then
            echo "Пакет уже есть в кэше, контрольная сумма проверена: $package_name"
        else
            rm -f -- "$package_file"
            reused_legacy=0
            for legacy_file in "$PWD"/tmp_deb.*/"$filename"; do
                if [[ -f "$legacy_file" ]] && is_valid_cached_deb "$legacy_file" "$expected_checksum"; then
                    if ! ln -- "$legacy_file" "$package_file" 2>/dev/null; then
                        cp -p -- "$legacy_file" "$download_tmp" && mv -- "$download_tmp" "$package_file" || continue
                    fi
                    echo "Пакет взят из ранее сохранённой папки; повторное скачивание не требуется: $package_name"
                    reused_legacy=1
                    break
                fi
            done

            if [[ "$reused_legacy" -eq 0 ]]; then
                echo "Загрузка: $package_name..."
                if ! wget --no-check-certificate "$package_url" -O "$download_tmp" \
                    -q --show-progress --progress=bar:force:noscroll; then
                    echo "ОШИБКА: не удалось скачать пакет «$package_name»; перехожу к следующему." >&2
                    rm -f -- "$download_tmp"
                    PACKAGE_INSTALL_FAILURES+=("$package_name")
                    continue
                fi
                if ! is_valid_cached_deb "$download_tmp" "$expected_checksum"; then
                    echo "ОШИБКА: пакет «$package_name» повреждён или не прошёл SHA-256; пакет пропущен." >&2
                    rm -f -- "$download_tmp"
                    PACKAGE_INSTALL_FAILURES+=("$package_name")
                    continue
                fi
                if ! mv -- "$download_tmp" "$package_file"; then
                    echo "ОШИБКА: не удалось сохранить пакет «$package_name» в кэш; пакет пропущен." >&2
                    rm -f -- "$download_tmp"
                    PACKAGE_INSTALL_FAILURES+=("$package_name")
                    continue
                fi
                echo "Контрольная сумма проверена: $package_name"
            fi
        fi
        if ! mv -- "$checksum_tmp" "$checksum_file"; then
            echo "ОШИБКА: не удалось сохранить контрольную сумму пакета «$package_name»; пакет пропущен." >&2
            PACKAGE_INSTALL_FAILURES+=("$package_name")
            continue
        fi
    else
        echo "Загрузка: $package_name..."
        if ! wget --no-check-certificate "$package_url" -O "$download_tmp" \
            -q --show-progress --progress=bar:force:noscroll \
            || ! dpkg-deb --info "$download_tmp" >/dev/null 2>&1 \
            || ! mv -- "$download_tmp" "$package_file"; then
            echo "ОШИБКА: не удалось получить корректный пакет «$package_name»; пакет пропущен." >&2
            rm -f -- "$download_tmp"
            PACKAGE_INSTALL_FAILURES+=("$package_name")
            continue
        fi
    fi
    DEB_FILES_TO_INSTALL+=("$package_file")
    DEB_NAMES_TO_INSTALL+=("$package_name")
done

declare -a VALID_DEB_FILES=()
declare -a VALID_DEB_NAMES=()
for i in "${!DEB_FILES_TO_INSTALL[@]}"; do
    if ! dpkg-deb --info "${DEB_FILES_TO_INSTALL[$i]}" >/dev/null 2>&1; then
        echo "ОШИБКА: пакет «${DEB_NAMES_TO_INSTALL[$i]}» не является корректным .deb; пакет пропущен. Файл: ${DEB_FILES_TO_INSTALL[$i]}" >&2
        PACKAGE_INSTALL_FAILURES+=("${DEB_NAMES_TO_INSTALL[$i]}")
        continue
    fi
    VALID_DEB_FILES+=("${DEB_FILES_TO_INSTALL[$i]}")
    VALID_DEB_NAMES+=("${DEB_NAMES_TO_INSTALL[$i]}")
done
DEB_FILES_TO_INSTALL=("${VALID_DEB_FILES[@]}")
DEB_NAMES_TO_INSTALL=("${VALID_DEB_NAMES[@]}")

declare -a INSTALLABLE_DEB_FILES=()
declare -a INSTALLABLE_DEB_NAMES=()
for i in "${!DEB_FILES_TO_INSTALL[@]}"; do
    package_id=$(dpkg-deb -f "${DEB_FILES_TO_INSTALL[$i]}" Package)
    package_version=$(dpkg-deb -f "${DEB_FILES_TO_INSTALL[$i]}" Version)
    installed_version=$(dpkg-query -W -f='${Version}' "$package_id" 2>/dev/null || true)
    if [[ -n "$installed_version" ]] && dpkg --compare-versions "$installed_version" gt "$package_version"; then
        echo "Пакет «${DEB_NAMES_TO_INSTALL[$i]}» пропущен: уже установлена более новая версия $installed_version; downgrade до $package_version не выполняется."
        continue
    fi
    INSTALLABLE_DEB_FILES+=("${DEB_FILES_TO_INSTALL[$i]}")
    INSTALLABLE_DEB_NAMES+=("${DEB_NAMES_TO_INSTALL[$i]}")
done
DEB_FILES_TO_INSTALL=("${INSTALLABLE_DEB_FILES[@]}")
DEB_NAMES_TO_INSTALL=("${INSTALLABLE_DEB_NAMES[@]}")

if [[ ${#DEB_FILES_TO_INSTALL[@]} -gt 0 ]]; then
    echo "Установка скачанных пакетов (с автоматической подгрузкой зависимостей)..."
    # Используем -f (fix-broken), чтобы apt сам подтянул недостающие пакеты из сети
    if ! sudo env DEBIAN_FRONTEND=noninteractive apt-get -f -y install "${DEB_FILES_TO_INSTALL[@]}"; then
        echo "Предупреждение: групповая установка .deb завершилась ошибкой; проверяю пакеты по одному." >&2
        for i in "${!DEB_FILES_TO_INSTALL[@]}"; do
            if ! sudo env DEBIAN_FRONTEND=noninteractive apt-get -f -y install "${DEB_FILES_TO_INSTALL[$i]}"; then
                echo "ОШИБКА: пакет «${DEB_NAMES_TO_INSTALL[$i]}» не установлен; перехожу к следующему." >&2
                PACKAGE_INSTALL_FAILURES+=("${DEB_NAMES_TO_INSTALL[$i]}")
            fi
        done
    fi
else
    echo "Нет пакетов для установки: файлы отсутствуют либо уже установлена более новая версия."
fi
else
echo "Вы не выбрали ни одного пакета для установки через .deb."
fi

# --- ЭТАП 2: Установка пакетов из репозитория ---
if [ ${#APT_PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
    echo "Установка выбранных пакетов из репозитория..."
    if ! sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "${APT_PACKAGES_TO_INSTALL[@]}"; then
        echo "Ошибка: не удалось установить выбранные пакеты из репозитория." >&2
        exit 1
    fi
fi

# --- ЭТАП 3: Установка MAX через репозиторий (если выбрано) ---
if [ "$INSTALL_MAX_REPO" == "1" ]; then
echo "Настройка репозитория и установка MAX..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.max.ru/linux/deb/public.asc | sudo gpg --yes --dearmor -o /etc/apt/keyrings/max.gpg >/dev/null
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/max.gpg] https://download.max.ru/linux/deb stable main" | sudo tee /etc/apt/sources.list.d/max.list
sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y max
apt-cache policy max
fi

# --- Восстановление CD-ROM репозитория после завершения операций ---
echo "Восстановление CD-ROM репозитория..."
sudo sed -i '/cdrom:/ s/^#//' /etc/apt/sources.list
sudo find /etc/apt/sources.list.d/ -type f -name "*.list" -exec sed -i '/cdrom:/ s/^#//' {} \; 2>/dev/null

# --- Сохранение кэша скачанных .deb пакетов ---
if [[ -n "${DEB_DOWNLOAD_DIR:-}" && -d "$DEB_DOWNLOAD_DIR" ]]; then
    echo "Проверенные .deb-пакеты оставлены в кэше: $DEB_DOWNLOAD_DIR"
fi

# --- Завершение ---
#clear
echo "======================================"
if [[ ${#PACKAGE_INSTALL_FAILURES[@]} -gt 0 ]]; then
    echo "Установка завершилась с ошибками. Не установлены или пропущены пакеты:"
    printf '  - %s\n' "${PACKAGE_INSTALL_FAILURES[@]}"
    echo "======================================"
    exit 1
fi
echo "Установка завершена!"
echo "======================================"
exit 0