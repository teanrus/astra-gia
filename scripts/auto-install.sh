#!/bin/bash

usage() {
    cat <<'EOF'
Использование:
  ./auto-install.sh [опции]

Опции:
  --repo <frozen|stable>     Выбор ветки репозитория Astra Linux 1.8
  --no-repo                  Не подключать репозитории Astra Linux
  --dist-upgrade             Выполнить apt dist-upgrade -y
  --autoremove               Выполнить apt autoremove -y
  --autoclean                Выполнить apt autoclean
  --no-sane                  Не устанавливать подсистему сканирования SANE
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
  --list                     Показать список доступных пакетов и категорий
  --save-log                 Сохранить вывод скрипта в файл с временной меткой
  --r7-office                Установить R7 Office через репозиторий
  --max                      Установить MAX через репозиторий
  -h, --help                 Показать эту справку

Примеры:
  ./auto-install.sh --repo stable --office --internet
  ./auto-install.sh --repo frozen --programming --edu
  ./auto-install.sh --no-repo --office --no-sane
  ./auto-install.sh --repo stable --dist-upgrade --autoremove --autoclean --no-sane
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

[internet]
  - ВК Мессенджер
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

[extra]
  - R7 Office
  - MAX
EOF
}

REPO_BRANCH=""
AUTO_MODE=0
LIST_ONLY=0
DRY_RUN=0
SAVE_LOG=0
START_DIR="$PWD"
SKIP_REPOSITORIES=0
RUN_DIST_UPGRADE=0
RUN_AUTOREMOVE=0
RUN_AUTOCLEAN=0
SKIP_SANE=0
INSTALL_GROUPS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo)
            if [[ $# -lt 2 ]]; then
                echo "Ошибка: после --repo укажите frozen или stable." >&2
                exit 1
            fi
            case "$2" in
                frozen) REPO_BRANCH="1" ;;
                stable) REPO_BRANCH="2" ;;
                *)
                    echo "Ошибка: неизвестная ветка «$2». Укажите frozen или stable." >&2
                    exit 1
                    ;;
            esac
            shift 2
            ;;
        --no-repo)
            SKIP_REPOSITORIES=1
            shift
            ;;
        --dist-upgrade)
            RUN_DIST_UPGRADE=1
            shift
            ;;
        --autoremove)
            RUN_AUTOREMOVE=1
            shift
            ;;
        --autoclean)
            RUN_AUTOCLEAN=1
            shift
            ;;
        --no-sane)
            SKIP_SANE=1
            shift
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

if [[ $SKIP_REPOSITORIES -eq 1 && -n "$REPO_BRANCH" ]]; then
    echo "Ошибка: --no-repo нельзя использовать вместе с --repo." >&2
    exit 1
fi

if [[ $LIST_ONLY -eq 1 ]]; then
    print_package_list
    exit 0
fi

if [[ ${#INSTALL_GROUPS[@]} -gt 0 || -n "$REPO_BRANCH" || $SKIP_REPOSITORIES -eq 1 ||
    $RUN_DIST_UPGRADE -eq 1 || $RUN_AUTOREMOVE -eq 1 || $RUN_AUTOCLEAN -eq 1 || $SKIP_SANE -eq 1 ||
    "${INSTALL_R7_REPO:-0}" == "1" || "${INSTALL_MAX_REPO:-0}" == "1" ]]; then
    AUTO_MODE=1
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
    exec 3>&2
    exec > >(tee -a "$LOG_FILE") 2>&1
    echo "Лог работы сохраняется в: $LOG_FILE"
fi

apt_cmd() {
    sudo apt-get -o Dpkg::Use-Pty=0 -o Dpkg::Progress-Fancy=0 "$@"
}

log_incident() {
    local step="$1"
    local status="$2"
    local log_file="${LOG_FILE:-$PWD/auto-install-incidents-$(date +%Y%m%d-%H%M%S).log}"

    if ! printf '[%s] Ошибка на шаге "%s" (код завершения: %s)\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" "$step" "$status" >> "$log_file"; then
        echo "Предупреждение: не удалось записать инцидент в лог $log_file." >&2
    else
        echo "Инцидент записан в лог: $log_file"
    fi
}

run_step() {
    local step="$1"
    shift
    local status

    if "$@"; then
        return 0
    else
        status=$?
    fi

    echo "Предупреждение: не удалось выполнить шаг «$step»." >&2
    log_incident "$step" "$status"

    if [[ $AUTO_MODE -eq 0 && -t 0 ]]; then
        local continue_ans
        read -r -p "Продолжить работу со следующего пункта? (y/n): " continue_ans
        if [[ ! "$continue_ans" =~ ^[YyДд]$ ]]; then
            echo "Работа скрипта остановлена по выбору пользователя."
            exit 1
        fi
    fi

    return "$status"
}

deduplicate_astra_repositories() {
    local apt_dir="${1:-/etc/apt}"
    sudo bash -s -- "$apt_dir" <<'ROOT_SCRIPT'
set -e
apt_dir="$1"
shopt -s nullglob
source_files=("$apt_dir/sources.list" "$apt_dir"/sources.list.d/*.list)
declare -A seen_entries=()
duplicates_removed=0

for source_file in "${source_files[@]}"; do
    [[ -f "$source_file" && ! -L "$source_file" ]] || continue
    temp_file=$(mktemp "${source_file}.XXXXXX")
    cp -p "$source_file" "$temp_file"
    : > "$temp_file"

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^[[:space:]]*deb(-src)?[[:space:]] &&
            ( "$line" == *"download.astralinux.ru/astra/"* || "$line" == *"dl.astralinux.ru/astra/"* ) ]]; then
            if [[ ${seen_entries["$line"]+present} ]]; then
                duplicates_removed=$((duplicates_removed + 1))
                continue
            fi
            seen_entries["$line"]=1
        fi
        printf '%s\n' "$line" >> "$temp_file"
    done < "$source_file"

    if cmp -s "$source_file" "$temp_file"; then
        rm -f "$temp_file"
    else
        mv "$temp_file" "$source_file"
    fi
done

printf 'Удалено точных дубликатов репозиториев Astra: %s\n' "$duplicates_removed"
ROOT_SCRIPT
}

echo "==============================================================================="
echo " "
echo "R.Tyan (c) 2026 | tyanrv@lbt.yanao.ru"
echo " "
echo "-------------------------------------------------------------------------------"
echo " "
echo "Интерактивный скрипт автоматизации установки ПО для ALSE 1.8"
echo " "
echo "================================================================================"

if [[ $AUTO_MODE -eq 0 ]]; then
    read -p "Нажмите Enter для начала настройки списка установки..."
fi

echo "==============================================================================="
echo "Активация репозиториев в ALSE 1.8 для установки стороннего софта и зависимостей"
echo "==============================================================================="

REPOSITORIES_CONNECTED=0
if [[ -n "$REPO_BRANCH" ]]; then
    NUMBER="$REPO_BRANCH"
else
    if [[ $AUTO_MODE -eq 1 ]]; then
        if [[ ${#INSTALL_GROUPS[@]} -gt 0 ]]; then
            echo "Авто-режим активирован. Проверяем метки репозитория..."
        fi
        if [[ $SKIP_REPOSITORIES -eq 1 ]]; then
            NUMBER="skip"
            echo "Подключение репозиториев Astra Linux пропущено по параметру --no-repo."
        elif [[ -z "$REPO_BRANCH" ]]; then
            NUMBER="1"
        fi
    else
        read -r -p "Подключить репозитории ALSE 1.8 для установки стороннего ПО и зависимостей? (y/n): " connect_repos_ans
        if [[ "$connect_repos_ans" =~ ^[YyДд]$ ]]; then
            echo "1 - Ветка Frozen для 1.8.4.48 (Рекомендуется для АРМ ГИА-11 в ППЭ)"
            echo "2 - Ветка Stable для 1.8 (Получение оперативных обновлений ОС)"
            read -r -p "Укажите числовое значение: " NUMBER
        else
            NUMBER="skip"
            echo "Подключение репозиториев пропущено."
        fi
    fi
fi

if [[ $DRY_RUN -eq 1 ]]; then
    echo "Режим dry-run активирован. Изменения в системных репозиториях и установка пакетов будут пропущены."
else
    case "$NUMBER" in
        1|frozen)
            echo "deb [arch=amd64] https://download.astralinux.ru/astra/frozen/1.8_x86-64/1.8.4/repository-extended/ 1.8_x86-64 main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list.d/astra-frozen-extended.list >/dev/null
            echo "deb [arch=amd64] https://download.astralinux.ru/astra/frozen/1.8_x86-64/1.8.4/repository-main/ 1.8_x86-64 main contrib non-free non-free-firmware" | sudo tee -a /etc/apt/sources.list.d/astra-frozen-extended.list >/dev/null
            echo "Выбрана ветка Frozen для 1.8.4.48. Продолжаем настройку системы..."
            ;;
        2|stable)
            echo "deb [arch=amd64] https://download.astralinux.ru/astra/stable/1.8_x86-64/repository-extended/ 1.8_x86-64 main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list.d/astra-stable-extended.list >/dev/null
            echo "deb [arch=amd64] https://download.astralinux.ru/astra/stable/1.8_x86-64/repository-main/ 1.8_x86-64 main contrib non-free non-free-firmware" | sudo tee -a /etc/apt/sources.list.d/astra-stable-extended.list >/dev/null
            echo "Выбрана ветка Stable для 1.8. Продолжаем настройку системы..."
            ;;
        skip)
            ;;
        *)
            echo "Предупреждение: неизвестная ветка репозитория «$NUMBER», подключение пропущено." >&2
            ;;
    esac

    if [[ -n "${REPOSITORY_FILE:-}" ]]; then
        if run_step "подключение репозиториев $REPOSITORY_LABEL" sudo tee "$REPOSITORY_FILE" <<< "$REPOSITORY_CONTENT" >/dev/null; then
            REPOSITORIES_CONNECTED=1
            run_step "удаление файла невыбранной ветки репозитория" sudo rm -f "$OTHER_REPOSITORY_FILE"
            run_step "проверка и устранение дублирующих репозиториев Astra" deduplicate_astra_repositories
            echo "Выбрана ветка $REPOSITORY_LABEL. Продолжаем настройку системы..."
        fi
    fi
fi

# --- БЛОК ПОДГОТОВКИ СИСТЕМЫ (РЕШАЕТ ПРОБЛЕМУ С DVD И СЛОМАННЫМИ ПАКЕТАМИ) ---
if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY-RUN: пропускаем отключение CD-ROM, подготовку apt-репозиториев, установку SANE и обновление системы."
else
    echo "Отключение CD-ROM репозитория (чтобы система не просила вставить диск)..."
    run_step "отключение CD-ROM репозитория в sources.list" sudo sed -i '/cdrom:/ s/^/#/' /etc/apt/sources.list
    run_step "отключение CD-ROM репозиториев в sources.list.d" sudo find /etc/apt/sources.list.d/ -type f -name "*.list" -exec sed -i '/cdrom:/ s/^/#/' {} \;

    echo "Проверка и исправление состояния пакетной базы (fix-broken)..."
    run_step "очистка кэша apt перед установкой" apt_cmd clean
    run_step "исправление состояния пакетной базы" apt_cmd --fix-broken install -y

    echo "Проверка и исправление некорректных записей репозиториев от предыдущих запусков..."
    run_step "исправление старых записей репозитория R7 Office" sudo find /etc/apt/sources.list /etc/apt/sources.list.d/ -type f -name "*.list" -exec sed -i 's|downloads.r7-office.ru/repository/r7-desktop-astra r7|downloads.r7-office.ru/repository/r7-desktop-astra/ astralinux|g' {} \;
    run_step "исправление записей репозитория R7 Office" sudo find /etc/apt/sources.list /etc/apt/sources.list.d/ -type f -name "*.list" -exec sed -i 's|downloads.r7-office.ru/repository/r7-desktop-astra/ r7|downloads.r7-office.ru/repository/r7-desktop-astra/ astralinux|g' {} \;

    if [[ $REPOSITORIES_CONNECTED -eq 1 ]] && ! grep -q "dl.astralinux.ru/astra/stable/1.8_x86-64/main-repository" /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null; then
        echo "Добавление основного репозитория Astra Linux 1.8 для разрешения зависимостей..."
        run_step "подключение основного репозитория Astra Linux" sudo tee /etc/apt/sources.list.d/astra-main.list <<< "deb https://dl.astralinux.ru/astra/stable/1.8_x86-64/main-repository/ 1.8_x86-64 main contrib non-free" >/dev/null
    fi

    echo "Обновление системы..."
    if ! sudo apt dist-upgrade -y; then
        echo "Ошибка: не удалось выполнить dist-upgrade." >&2
        exit 1
    fi
    echo "Удаление неиспользуемых пакетов..."
    if ! sudo apt autoremove -y; then
        echo "Ошибка: не удалось выполнить autoremove." >&2
        exit 1
    fi
    echo "Очистка локального кэша пакетов..."
    if ! sudo apt autoclean; then
        echo "Ошибка: не удалось выполнить autoclean." >&2
        exit 1
    fi

    echo "Обновление списков пакетов (это может занять некоторое время)..."
    if ! sudo apt update; then
        echo "Ошибка: не удалось обновить списки пакетов." >&2
        exit 1
    fi

    if [[ $SKIP_SANE -eq 0 ]]; then
        echo "Установка подсистемы сканирования SANE..."
        if ! sudo apt install -y sane sane-utils; then
            echo "Ошибка: не удалось установить подсистему сканирования SANE." >&2
            exit 1
        fi
    else
        echo "Подсистема SANE пропущена по параметру --no-sane."
    fi

    if [[ $AUTO_MODE -eq 0 ]]; then
        read -r -p "Выполнить обновление системы и очистку пакетов (dist-upgrade, autoremove, autoclean)? (y/n): " upgrade_ans
        if [[ "$upgrade_ans" =~ ^[YyДд]$ ]]; then
            echo "Обновление системы..."
            if ! sudo apt dist-upgrade -y; then
                echo "Ошибка: не удалось выполнить dist-upgrade." >&2
                exit 1
            fi
            echo "Удаление неиспользуемых пакетов..."
            if ! sudo apt autoremove -y; then
                echo "Ошибка: не удалось выполнить autoremove." >&2
                exit 1
            fi
            echo "Очистка локального кэша пакетов..."
            if ! sudo apt autoclean; then
                echo "Ошибка: не удалось выполнить autoclean." >&2
                exit 1
            fi
        else
            echo "Обновление и очистка пакетов пропущены."
        fi
    fi
fi
# -----------------------------------------------------------------------------

# Массивы для хранения выбора пользователя
declare -a URLS_TO_DOWNLOAD
declare -a NAMES_TO_DOWNLOAD
declare -A PACKAGE_NAMES=(
    [foxit]="Foxit PDF Reader"
    [naps2]="NAPS2"
    [onlyoffice]="OnlyOffice Desktop Editors"
    [sreda]="Сервис Среда"
    [vkmessenger]="ВК Мессенджер"
    [yandex]="Яндекс Браузер"
    [codeblocks]="Code::Blocks"
    [eclipse-cpp]="Eclipse IDE for C/C++ Developers 2026.09"
    [eclipse-java]="Eclipse IDE for Java Developers 2026.09"
    [idle]="IDLE 3 (Python 3.11)"
    [notepadplus]="Notepad++ 8.9.8.1"
    [pascalabc]="PascalABC.NET"
    [pycharm]="PyCharm"
    [vscode]="Visual Studio Code"
    [python-3.9]="Python 3.9.25"
    [python-3.10]="Python 3.10.20"
    [python-3.12]="Python 3.12.13"
    [python-3.13]="Python 3.13.15"
    [python-3.14]="Python 3.14.7"
    [scribus]="Scribus"
    [audacity]="Audacity"
    [obs]="OBS Studio"
    [kumir]="КуМир 2"
    [basic256]="Basic 256"
    [r7-office]="R7 Office"
    [max]="MAX"
)
declare -A APT_PACKAGE_NAMES=(
    [yandex]="yandex-browser-stable"
    [idle]="idle"
    [basic256]="basic256"
    [scribus]="scribus"
    [audacity]="audacity"
)
declare -A PACKAGE_URLS=(
    [foxit]="https://easyastra.ru/store1.8/foxitreader.deb"
    [naps2]="https://easyastra.ru/store1.8/naps2.deb"
    [onlyoffice]="https://github.com/teanrus/astra-gia/releases/download/v2.0/onlyoffice.deb"
    [sreda]="https://easyastra.ru/store1.8/sreda.deb"
    [vkmessenger]="https://github.com/teanrus/astra-gia/releases/download/v2.0/vk-messenger.deb"
    [codeblocks]="https://easyastra.ru/store1.8/codeblocks.deb"
    [eclipse-cpp]="https://easyastra.ru/store1.8/eclipse-cpp.deb"
    [eclipse-java]="https://easyastra.ru/store1.8/eclipse-java.deb"
    [notepadplus]="https://easyastra.ru/store1.8/notepadplus.deb"
    [pascalabc]="https://easyastra.ru/store1.8/pascalABC.deb"
    [pycharm]="https://easyastra.ru/store1.8/pycharm.deb"
    [vscode]="https://github.com/teanrus/astra-gia/releases/download/v2.0/code.deb"
    [python-3.9]="https://gitflic.ru/project/ddavydov/python3-alse-18/blob/raw?file=python-3.9.25-alse1.8-amd64.deb&inline=false&commit=2285a97abf5fbd7dcd869df45c61228618bbf6f6"
    [python-3.10]="https://gitflic.ru/project/ddavydov/python3-alse-18/blob/raw?file=python-3.10.20-alse1.8-amd64.deb&inline=false&commit=2285a97abf5fbd7dcd869df45c61228618bbf6f6"
    [python-3.12]="https://gitflic.ru/project/ddavydov/python3-alse-18/blob/raw?file=python-3.12.13-alse1.8-amd64.deb&inline=false&commit=2285a97abf5fbd7dcd869df45c61228618bbf6f6"
    [python-3.13]="https://gitflic.ru/project/ddavydov/python3-alse-18/blob/raw?file=python-3.13.15-alse1.8-amd64.deb&inline=false&commit=2285a97abf5fbd7dcd869df45c61228618bbf6f6"
    [python-3.14]="https://gitflic.ru/project/ddavydov/python3-alse-18/blob/raw?file=python-3.14.7-alse1.8-amd64.deb&inline=false&commit=2285a97abf5fbd7dcd869df45c61228618bbf6f6"
    [obs]="https://easyastra.ru/store1.8/obs-studio.deb"
    [kumir]="https://easyastra.ru/store1.8/kumir2.deb"
    [r7-office]="https://github.com/teanrus/astra-gia/releases/download/v2.0/r7-office.deb"
    [max]="https://easyastra.ru/store1.8/max.deb"
)
declare -a APT_PACKAGES_TO_INSTALL
INSTALL_R7_REPO=${INSTALL_R7_REPO:-0}
INSTALL_MAX_REPO=${INSTALL_MAX_REPO:-0}

add_group_package() {
    local package_key="$1"
    local name="${PACKAGE_NAMES[$package_key]:-}"
    local apt_package="${APT_PACKAGE_NAMES[$package_key]:-}"
    local url="${PACKAGE_URLS[$package_key]:-}"
    local existing_url
    if [[ -z "$name" ]]; then
        echo "Ошибка: неизвестный ключ пакета: $package_key" >&2
        return 1
    fi
    if [[ -n "$apt_package" ]]; then
        for existing_url in "${APT_PACKAGES_TO_INSTALL[@]}"; do
            if [[ "$existing_url" == "$apt_package" ]]; then
                return
            fi
        done
        APT_PACKAGES_TO_INSTALL+=("$apt_package")
        echo -e "\e[32m  -> $name добавлен в очередь apt install.\e[0m"
        return
    fi
    if [[ -z "$url" ]]; then
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

add_group_duplicate() {
    local name="$1"
    local url="$2"
    local repo_flag="$3"
    if [[ "$repo_flag" == "R7" ]]; then INSTALL_R7_REPO=1; fi
    if [[ "$repo_flag" == "MAX" ]]; then INSTALL_MAX_REPO=1; fi
    URLS_TO_DOWNLOAD+=("$url")
    NAMES_TO_DOWNLOAD+=("$name")
}

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

ask_apt_package() {
local package_key=$1
local name="${PACKAGE_NAMES[$package_key]}"
local apt_package="${APT_PACKAGE_NAMES[$package_key]}"
read -p "Установить [ $name ]? (y/n): " ans
if [[ "$ans" =~ ^[YyДд]$ ]]; then
APT_PACKAGES_TO_INSTALL+=("$apt_package")
echo -e "\e[32m  -> Добавлено в очередь apt install.\e[0m"
else
echo -e "\e[33m  -> Пропущено.\e[0m"
fi
}

# Функция для пакетов-дубликатов (wget vs репозиторий)
ask_duplicate() {
local package_key=$1
local name="${PACKAGE_NAMES[$package_key]}"
local url="${PACKAGE_URLS[$package_key]}"
local repo_flag=$2
echo "--------------------------------------------------------------------------------"
echo "Пакет [ $name ] доступен из двух источников. Выберите действие:"
echo "  1) Скачать .deb пакет (wget)"
echo "  2) Подключить официальный репозиторий и установить"
echo "  3) Пропустить"
read -p "Ваш выбор (1/2/3): " ans
case $ans in
1)
URLS_TO_DOWNLOAD+=("$url")
NAMES_TO_DOWNLOAD+=("$name (.deb)")
echo -e "\e[32m  -> Выбран .deb пакет. Добавлено в очередь.\e[0m"
;;
2)
if [ "$repo_flag" == "R7" ]; then INSTALL_R7_REPO=1; fi
if [ "$repo_flag" == "MAX" ]; then INSTALL_MAX_REPO=1; fi
echo -e "\e[32m  -> Выбран репозиторий. Добавлено в очередь.\e[0m"
;;
*)
echo -e "\e[33m  -> Пропущено.\e[0m"
;;
esac
echo "--------------------------------------------------------------------------------"
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
if [[ $AUTO_MODE -eq 1 ]]; then
    process_group_selection() {
        local group="$1"
        case "$group" in
            office)
                add_group_package foxit
                add_group_package naps2
                add_group_package onlyoffice
                add_group_package sreda
                ;;
            internet)
                add_group_package vkmessenger
                add_group_package yandex
                ;;
            programming)
                add_group_package codeblocks
                add_group_package eclipse-cpp
                add_group_package eclipse-java
                add_group_package idle
                add_group_package notepadplus
                add_group_package pascalabc
                add_group_package pycharm
                add_group_package vscode
                add_group_package python-3.12
                ;;
            graphics)
                add_group_package scribus
                add_group_package audacity
                add_group_package obs
                ;;
            edu)
                add_group_package kumir
                add_group_package basic256
                add_group_package codeblocks
                add_group_package eclipse-java
                add_group_package idle
                add_group_package notepadplus
                add_group_package pascalabc
                add_group_package pycharm
                add_group_package python-3.12
                add_group_package vscode
                add_group_package r7-office
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
    if [[ ${#INSTALL_GROUPS[@]} -eq 0 ]]; then
        echo "Не выбрана ни одна категория. Ничего не добавлено в очередь." 
    fi
else
    echo "=== РАЗДЕЛ 1: СТАНДАРТНЫЕ .DEB ПАКЕТЫ ==="
    ask_deb foxit
    ask_deb naps2
    ask_deb onlyoffice
    ask_deb vkmessenger
    ask_deb sreda
    ask_apt_package yandex
    ask_apt_package scribus
    ask_apt_package audacity
    ask_deb obs
    ask_deb kumir
    ask_apt_package basic256
    ask_deb codeblocks
    ask_deb eclipse-cpp
    ask_deb eclipse-java
    ask_apt_package idle
    ask_deb notepadplus
    ask_deb pascalabc
    ask_deb pycharm
    ask_deb vscode

    echo ""
    echo "=== РАЗДЕЛ 2: ПАКЕТЫ С ВЫБОРОМ ИСТОЧНИКА ==="
    ask_duplicate r7-office R7
    ask_duplicate max MAX

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
        echo "  - R7 Office (через репозиторий)"
    fi
    if [ "$INSTALL_MAX_REPO" == "1" ]; then
        echo "  - MAX (через репозиторий)"
    fi
    exit 0
fi

# --- ЭТАП 1: Скачивание и установка .deb пакетов ---
if [ ${#URLS_TO_DOWNLOAD[@]} -gt 0 ]; then
if ! DEB_DOWNLOAD_DIR="$(mktemp -d "$START_DIR/tmp_deb.XXXXXX")"; then
    echo "Ошибка: не удалось создать папку для скачанных пакетов." >&2
    exit 1
fi
declare -a VALID_DEB_FILES=()
echo "Папка для скачанных пакетов: $DEB_DOWNLOAD_DIR"
echo "Загрузка выбранных .deb пакетов..."
for i in "${!URLS_TO_DOWNLOAD[@]}"; do
echo "Скачивание: ${NAMES_TO_DOWNLOAD[$i]}"
filename=$(basename "${URLS_TO_DOWNLOAD[$i]}" | sed 's/.*file=\(.*\.deb\).*/\1/')
if [[ "$filename" == *"raw"* ]] || [[ -z "$filename" ]]; then
filename="package_${i}.deb"
fi
package_path="$DEB_DOWNLOAD_DIR/$filename"
if [[ $SAVE_LOG -eq 1 ]]; then
    wget --no-check-certificate "${URLS_TO_DOWNLOAD[$i]}" -O "$package_path" -q --show-progress --progress=bar:force:noscroll 2>&3
else
    wget --no-check-certificate "${URLS_TO_DOWNLOAD[$i]}" -O "$package_path" -q --show-progress --progress=bar:force:noscroll
fi
download_status=$?
if [[ $download_status -ne 0 ]]; then
    echo "Ошибка: не удалось скачать пакет «${NAMES_TO_DOWNLOAD[$i]}» (код wget: $download_status)." >&2
    exit "$download_status"
fi
package_size=$(du -h "$package_path" | cut -f1)
echo "Скачан пакет: ${NAMES_TO_DOWNLOAD[$i]} — $package_size"
if dpkg-deb --info "$package_path" >/dev/null &&
    dpkg-deb --contents "$package_path" >/dev/null; then
    VALID_DEB_FILES+=("$package_path")
else
    echo "Ошибка: пакет «${NAMES_TO_DOWNLOAD[$i]}» повреждён или не является корректным .deb; он будет пропущен." >&2
fi
done
if [[ ${#VALID_DEB_FILES[@]} -gt 0 ]]; then
    echo "Переход к установке ${#VALID_DEB_FILES[@]} корректных .deb-пакетов (с автоматической подгрузкой зависимостей)..."
    run_step "обновление списков пакетов перед установкой выбранных программ" apt_cmd update
    # Используем -f (fix-broken), чтобы apt сам подтянул недостающие пакеты из сети.
    run_step "установка выбранных .deb-пакетов" apt_cmd -f -y install "${VALID_DEB_FILES[@]}"
else
    echo "Нет корректных .deb-пакетов для установки." >&2
fi
else
echo "Вы не выбрали ни одного пакета для установки через .deb."
fi

# --- ЭТАП 2: Установка пакетов из репозитория ---
if [ ${#APT_PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
    echo "Установка выбранных пакетов из репозитория..."
    if ! sudo apt install -y "${APT_PACKAGES_TO_INSTALL[@]}"; then
        echo "Ошибка: не удалось установить пакеты из репозитория." >&2
        exit 1
    fi
fi

# --- ЭТАП 3: Установка R7 Office через репозиторий (если выбрано) ---
if [ "$INSTALL_R7_REPO" == "1" ]; then
echo "Настройка репозитория и установка R7 Office..."
sudo wget -qO /etc/apt/trusted.gpg.d/r7-office.asc https://download.r7-office.ru/repos/RPM-GPG-KEY-R7-OFFICE.public
sudo mkdir -p /etc/apt/auth.conf.d
sudo tee /etc/apt/auth.conf.d/r7.conf > /dev/null <<EOF
machine downloads.r7-office.ru
login desktop
password gyxiLab84FByn7sCTd5JY
EOF
sudo chmod 600 /etc/apt/auth.conf.d/r7.conf
# Правильная строка репозитория с кодовым именем 'astralinux'
echo "deb https://downloads.r7-office.ru/repository/r7-desktop-astra/ astralinux main" | sudo tee /etc/apt/sources.list.d/r7-office.list
apt_cmd update
apt_cmd install -y r7-office
fi

# --- ЭТАП 4: Установка MAX через репозиторий (если выбрано) ---
if [ "$INSTALL_MAX_REPO" == "1" ]; then
echo "Настройка репозитория и установка MAX..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.max.ru/linux/deb/public.asc | sudo gpg --yes --dearmor -o /etc/apt/keyrings/max.gpg >/dev/null
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/max.gpg] https://download.max.ru/linux/deb stable main" | sudo tee /etc/apt/sources.list.d/max.list
apt_cmd update
apt_cmd install -y max
apt-cache policy max
fi

# --- Восстановление CD-ROM репозитория после завершения операций ---
echo "Восстановление CD-ROM репозитория..."
sudo sed -i '/cdrom:/ s/^#//' /etc/apt/sources.list
sudo find /etc/apt/sources.list.d/ -type f -name "*.list" -exec sed -i '/cdrom:/ s/^#//' {} \; 2>/dev/null

# --- Завершение ---
#clear
if [[ -t 0 ]]; then
    read -r -p "Удалить скачанные .deb-файлы и очистить кэш APT? (y/n): " cleanup_ans
    if [[ "$cleanup_ans" =~ ^[YyДд]$ ]]; then
        if [[ -n "${DEB_DOWNLOAD_DIR:-}" && -d "$DEB_DOWNLOAD_DIR" ]]; then
            if run_step "удаление скачанных .deb-файлов" rm -rf -- "$DEB_DOWNLOAD_DIR"; then
                echo "Скачанные .deb-файлы удалены."
            fi
        fi
        run_step "очистка кэша APT" apt_cmd clean
    else
        if [[ -n "${DEB_DOWNLOAD_DIR:-}" && -d "$DEB_DOWNLOAD_DIR" ]]; then
            echo "Скачанные .deb-файлы оставлены: $DEB_DOWNLOAD_DIR"
        fi
        echo "Кэш APT оставлен."
    fi
elif [[ -n "${DEB_DOWNLOAD_DIR:-}" && -d "$DEB_DOWNLOAD_DIR" ]]; then
    echo "Интерактивный запрос пропущен; скачанные .deb-файлы оставлены: $DEB_DOWNLOAD_DIR"
fi
echo "======================================"
echo "Установка завершена!"
echo "======================================"
exit 0
