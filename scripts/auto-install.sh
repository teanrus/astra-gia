#!/bin/bash

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
  --list                     Показать список доступных пакетов и категорий
  --r7-office                Установить R7 Office через репозиторий
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
  - GIMP 3
  - InkScape
  - Scribus
  - Audacity
  - OBS Studio
  - VLC

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
INSTALL_GROUPS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo)
            if [[ $# -lt 2 ]]; then
                echo "Ошибка: после --repo укажите frozen или stable." >&2
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
        --list)
            LIST_ONLY=1
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

if [[ $LIST_ONLY -eq 1 ]]; then
    print_package_list
    exit 0
fi

if [[ ${#INSTALL_GROUPS[@]} -gt 0 || -n "$REPO_BRANCH" || "${INSTALL_R7_REPO:-0}" == "1" || "${INSTALL_MAX_REPO:-0}" == "1" ]]; then
    AUTO_MODE=1
fi

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

if [[ -n "$REPO_BRANCH" ]]; then
    NUMBER="$REPO_BRANCH"
else
    if [[ $AUTO_MODE -eq 1 ]]; then
        if [[ ${#INSTALL_GROUPS[@]} -gt 0 ]]; then
            echo "Авто-режим активирован. Проверяем метки репозитория..."
        fi
        if [[ -z "$REPO_BRANCH" ]]; then
            NUMBER="1"
        fi
    else
        echo "1 - Ветка Frozen для 1.8.4.48 (Рекомендуется для АРМ ГИА-11 в ППЭ)"
        echo "2 - Ветка Stable для 1.8 (Получение оперативных обновлений ОС)"
        read -p "Укажите числовое значение: " NUMBER
    fi
fi

if [[ $DRY_RUN -eq 1 ]]; then
    echo "Режим dry-run активирован. Изменения в системных репозиториях и установка пакетов будут пропущены."
else
    case "$NUMBER" in
        1)
            echo "deb [arch=amd64] https://download.astralinux.ru/astra/frozen/1.8_x86-64/1.8.4/repository-extended/ 1.8_x86-64 main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list.d/astra-frozen-extended.list >/dev/null
            echo "deb [arch=amd64] https://download.astralinux.ru/astra/frozen/1.8_x86-64/1.8.4/repository-main/ 1.8_x86-64 main contrib non-free non-free-firmware" | sudo tee -a /etc/apt/sources.list.d/astra-frozen-extended.list >/dev/null
            echo "Выбрана ветка Frozen для 1.8.4.48. Продолжаем настройку системы..."
            ;;
        2)
            echo "deb [arch=amd64] https://download.astralinux.ru/astra/stable/1.8_x86-64/repository-extended/ 1.8_x86-64 main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list.d/astra-stable-extended.list >/dev/null
            echo "deb [arch=amd64] https://download.astralinux.ru/astra/stable/1.8_x86-64/repository-main/ 1.8_x86-64 main contrib non-free non-free-firmware" | sudo tee -a /etc/apt/sources.list.d/astra-stable-extended.list >/dev/null
            echo "Выбрана ветка Stable для 1.8. Продолжаем настройку системы..."
            ;;
        *)
            echo "======================"
            echo "Действие отсутствует..."
            echo "======================"
            exit 0
            ;;
    esac
fi

# --- БЛОК ПОДГОТОВКИ СИСТЕМЫ (РЕШАЕТ ПРОБЛЕМУ С DVD И СЛОМАННЫМИ ПАКЕТАМИ) ---
if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY-RUN: пропускаем отключение CD-ROM, подготовку apt-репозиториев, установку SANE и обновление системы."
else
    echo "Отключение CD-ROM репозитория (чтобы система не просила вставить диск)..."
    sudo sed -i '/cdrom:/ s/^/#/' /etc/apt/sources.list
    sudo find /etc/apt/sources.list.d/ -type f -name "*.list" -exec sed -i '/cdrom:/ s/^/#/' {} \; 2>/dev/null

    echo "Проверка и исправление состояния пакетной базы (fix-broken)..."
    sudo apt clean
    sudo apt --fix-broken install -y

    echo "Проверка и исправление некорректных записей репозиториев от предыдущих запусков..."
    sudo find /etc/apt/sources.list /etc/apt/sources.list.d/ -type f -name "*.list" -exec sed -i 's|downloads.r7-office.ru/repository/r7-desktop-astra r7|downloads.r7-office.ru/repository/r7-desktop-astra/ astralinux|g' {} \; 2>/dev/null
    sudo find /etc/apt/sources.list /etc/apt/sources.list.d/ -type f -name "*.list" -exec sed -i 's|downloads.r7-office.ru/repository/r7-desktop-astra/ r7|downloads.r7-office.ru/repository/r7-desktop-astra/ astralinux|g' {} \; 2>/dev/null

    if ! grep -q "dl.astralinux.ru/astra/stable/1.8_x86-64/main-repository" /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null; then
        echo "Добавление основного репозитория Astra Linux 1.8 для разрешения зависимостей..."
        echo "deb https://dl.astralinux.ru/astra/stable/1.8_x86-64/main-repository/ 1.8_x86-64 main contrib non-free" | sudo tee /etc/apt/sources.list.d/astra-main.list
    fi

    echo "Обновление списков пакетов (это может занять некоторое время)..."
    sudo apt update

    echo "Установка подсистемы сканирования SANE..."
    if ! sudo apt install -y sane sane-utils; then
        echo "Ошибка: не удалось установить подсистему сканирования SANE." >&2
        exit 1
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
INSTALL_R7_REPO=${INSTALL_R7_REPO:-0}
INSTALL_MAX_REPO=${INSTALL_MAX_REPO:-0}

add_group_package() {
    local name="$1"
    local url="$2"
    local existing_url
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

add_group_python() {
    local name="$1"
    local url="$2"
    add_group_package "$name" "$url"
}

# Функция для обычного .deb пакета
ask_deb() {
local name=$1
local url=$2
read -p "Установить [ $name ]? (y/n): " ans
if [[ "$ans" =~ ^[YyДд]$ ]]; then
URLS_TO_DOWNLOAD+=("$url")
NAMES_TO_DOWNLOAD+=("$name")
echo -e "\e[32m  -> Добавлено в очередь на скачивание.\e[0m"
else
echo -e "\e[33m  -> Пропущено.\e[0m"
fi
}

# Функция для пакетов-дубликатов (wget vs репозиторий)
ask_duplicate() {
local name=$1
local url=$2
local repo_flag=$3 # "R7" или "MAX"
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
local py_url=""
local py_name=""
case $py_ans in
1) py_url="https://gitflic.ru/project/ddavydov/python3-alse-18/blob/raw?file=python-3.9.25-alse1.8-amd64.deb&inline=false&commit=2285a97abf5fbd7dcd869df45c61228618bbf6f6"; py_name="Python 3.9.25" ;;
2) py_url="https://gitflic.ru/project/ddavydov/python3-alse-18/blob/raw?file=python-3.10.20-alse1.8-amd64.deb&inline=false&commit=2285a97abf5fbd7dcd869df45c61228618bbf6f6"; py_name="Python 3.10.20" ;;
3) py_url="https://gitflic.ru/project/ddavydov/python3-alse-18/blob/raw?file=python-3.12.13-alse1.8-amd64.deb&inline=false&commit=2285a97abf5fbd7dcd869df45c61228618bbf6f6"; py_name="Python 3.12.13" ;;
4) py_url="https://gitflic.ru/project/ddavydov/python3-alse-18/blob/raw?file=python-3.13.15-alse1.8-amd64.deb&inline=false&commit=2285a97abf5fbd7dcd869df45c61228618bbf6f6"; py_name="Python 3.13.15" ;;
5) py_url="https://gitflic.ru/project/ddavydov/python3-alse-18/blob/raw?file=python-3.14.7-alse1.8-amd64.deb&inline=false&commit=2285a97abf5fbd7dcd869df45c61228618bbf6f6"; py_name="Python 3.14.7" ;;
*)
echo -e "\e[33m  -> Пропущено.\e[0m"
return
;;
esac
if [ -n "$py_url" ]; then
URLS_TO_DOWNLOAD+=("$py_url")
NAMES_TO_DOWNLOAD+=("$py_name")
echo -e "\e[32m  -> Выбран $py_name. Добавлено в очередь.\e[0m"
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
                add_group_package "Foxit PDF Reader" "https://easyastra.ru/store1.8/foxitreader.deb"
                add_group_package "NAPS2" "https://easyastra.ru/store1.8/naps2.deb"
                add_group_package "OnlyOffice Desktop Editors" "https://easyastra.ru/store1.8/onlyoffice-desktopeditors.deb"
                add_group_package "Сервис Среда" "https://easyastra.ru/store1.8/sreda.deb"
                ;;
            internet)
                add_group_package "ВК Мессенджер" "https://easyastra.ru/store1.8/vkmessenger.deb"
                add_group_package "Яндекс Браузер" "https://easyastra.ru/store1.8/Yandex.deb"
                ;;
            programming)
                add_group_package "Code::Blocks" "https://easyastra.ru/store1.8/codeblocks.deb"
                add_group_package "Eclipse IDE for C/C++ Developers 2026.09" "https://easyastra.ru/store1.8/eclipse-cpp.deb"
                add_group_package "Eclipse IDE for Java Developers 2026.09" "https://easyastra.ru/store1.8/eclipse-java.deb"
                add_group_package "IDLE 3 (Python 3.11)" "https://easyastra.ru/store1.8/idle-python3.11.deb"
                add_group_package "Notepad++ 8.9.8.1" "https://easyastra.ru/store1.8/notepadplus.deb"
                add_group_package "PascalABC.NET" "https://easyastra.ru/store1.8/pascalABC.deb"
                add_group_package "PyCharm" "https://easyastra.ru/store1.8/pycharm.deb"
                add_group_package "Visual Studio Code" "https://easyastra.ru/store1.8/code.deb"
                add_group_python "Python 3.12.13" "https://gitflic.ru/project/ddavydov/python3-alse-18/blob/raw?file=python-3.12.13-alse1.8-amd64.deb&inline=false&commit=2285a97abf5fbd7dcd869df45c61228618bbf6f6"
                ;;
            graphics)
                add_group_package "GIMP 3" "https://easyastra.ru/store1.8/gimp3.deb"
                add_group_package "InkScape" "https://easyastra.ru/store1.8/inkscape.deb"
                add_group_package "Scribus" "https://easyastra.ru/store1.8/scribus.deb"
                add_group_package "Audacity" "https://easyastra.ru/store1.8/audacity.deb"
                add_group_package "OBS Studio" "https://easyastra.ru/store1.8/obs-studio.deb"
                add_group_package "VLC" "https://easyastra.ru/store1.8/vlc.deb"
                ;;
            edu)
                add_group_package "КуМир 2" "https://easyastra.ru/store1.8/kumir2.deb"
                add_group_package "Basic 256" "https://easyastra.ru/store1.8/basic256.deb"
                add_group_package "Code::Blocks" "https://easyastra.ru/store1.8/codeblocks.deb"
                add_group_package "Eclipse IDE for Java Developers 2026.09" "https://easyastra.ru/store1.8/eclipse-java.deb"
                add_group_package "IDLE 3 (Python 3.11)" "https://easyastra.ru/store1.8/idle-python3.11.deb"
                add_group_package "Notepad++ 8.9.8.1" "https://easyastra.ru/store1.8/notepadplus.deb"
                add_group_package "PascalABC.NET" "https://easyastra.ru/store1.8/pascalABC.deb"
                add_group_package "PyCharm" "https://easyastra.ru/store1.8/pycharm.deb"
                add_group_python "Python 3.12.13" "https://gitflic.ru/project/ddavydov/python3-alse-18/blob/raw?file=python-3.12.13-alse1.8-amd64.deb&inline=false&commit=2285a97abf5fbd7dcd869df45c61228618bbf6f6"
                add_group_package "Visual Studio Code" "https://easyastra.ru/store1.8/code.deb"
                add_group_package "R7 Office" "https://easyastra.ru/store1.8/r7-office.deb"
                add_group_package "Foxit PDF Reader" "https://easyastra.ru/store1.8/foxitreader.deb"
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
    ask_deb "Foxit PDF Reader" "https://easyastra.ru/store1.8/foxitreader.deb"
    ask_deb "NAPS2" "https://easyastra.ru/store1.8/naps2.deb"
    ask_deb "OnlyOffice Desktop Editors" "https://easyastra.ru/store1.8/onlyoffice-desktopeditors.deb"
    ask_deb "ВК Мессенджер" "https://easyastra.ru/store1.8/vkmessenger.deb"
    ask_deb "Сервис Среда" "https://easyastra.ru/store1.8/sreda.deb"
    ask_deb "Яндекс Браузер" "https://easyastra.ru/store1.8/Yandex.deb"
    ask_deb "GIMP 3" "https://easyastra.ru/store1.8/gimp3.deb"
    ask_deb "InkScape" "https://easyastra.ru/store1.8/inkscape.deb"
    ask_deb "Scribus" "https://easyastra.ru/store1.8/scribus.deb"
    ask_deb "Audacity" "https://easyastra.ru/store1.8/audacity.deb"
    ask_deb "OBS Studio" "https://easyastra.ru/store1.8/obs-studio.deb"
    ask_deb "VLC" "https://easyastra.ru/store1.8/vlc.deb"
    ask_deb "КуМир 2" "https://easyastra.ru/store1.8/kumir2.deb"
    ask_deb "Basic 256" "https://easyastra.ru/store1.8/basic256.deb"
    ask_deb "Code::Blocks" "https://easyastra.ru/store1.8/codeblocks.deb"
    ask_deb "Eclipse IDE for C/C++ Developers 2026.09" "https://easyastra.ru/store1.8/eclipse-cpp.deb"
    ask_deb "Eclipse IDE for Java Developers 2026.09" "https://easyastra.ru/store1.8/eclipse-java.deb"
    ask_deb "IDLE 3 (Python 3.11)" "https://easyastra.ru/store1.8/idle-python3.11.deb"
    ask_deb "Notepad++ 8.9.8.1" "https://easyastra.ru/store1.8/notepadplus.deb"
    ask_deb "PascalABC.NET" "https://easyastra.ru/store1.8/pascalABC.deb"
    ask_deb "PyCharm" "https://easyastra.ru/store1.8/pycharm.deb"
    ask_deb "Visual Studio Code" "https://easyastra.ru/store1.8/code.deb"

    echo ""
    echo "=== РАЗДЕЛ 2: ПАКЕТЫ С ВЫБОРОМ ИСТОЧНИКА ==="
    ask_duplicate "R7 Office" "https://easyastra.ru/store1.8/r7-office.deb" "R7"
    ask_duplicate "MAX" "https://easyastra.ru/store1.8/max.deb" "MAX"

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
echo "Создание временной директории..."
mkdir -p "$PWD/tmp_deb/"
echo "Загрузка выбранных .deb пакетов..."
for i in "${!URLS_TO_DOWNLOAD[@]}"; do
echo "Загрузка: ${NAMES_TO_DOWNLOAD[$i]}..."
filename=$(basename "${URLS_TO_DOWNLOAD[$i]}" | sed 's/.*file=\(.*\.deb\).*/\1/')
if [[ "$filename" == *"raw"* ]] || [[ -z "$filename" ]]; then
filename="package_${i}.deb"
fi
wget --no-check-certificate "${URLS_TO_DOWNLOAD[$i]}" -O "$PWD/tmp_deb/$filename" -q --show-progress
done
echo "Переход в директорию с пакетами и установка (с автоматической подгрузкой зависимостей)..."
cd "$PWD/tmp_deb/" || exit 1
# Используем -f (fix-broken), чтобы apt сам подтянул недостающие пакеты из сети
sudo apt -f -y install ./*.deb
echo "Очистка временных файлов..."
cd ../ || exit 1
rm -rf "$PWD/tmp_deb/"
else
echo "Вы не выбрали ни одного пакета для установки через .deb."
fi

# --- ЭТАП 2: Установка R7 Office через репозиторий (если выбрано) ---
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
sudo apt update
sudo apt install -y r7-office
fi

# --- ЭТАП 3: Установка MAX через репозиторий (если выбрано) ---
if [ "$INSTALL_MAX_REPO" == "1" ]; then
echo "Настройка репозитория и установка MAX..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.max.ru/linux/deb/public.asc | sudo gpg --yes --dearmor -o /etc/apt/keyrings/max.gpg >/dev/null
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/max.gpg] https://download.max.ru/linux/deb stable main" | sudo tee /etc/apt/sources.list.d/max.list
sudo apt update
sudo apt install -y max
apt policy max
fi

# --- Восстановление CD-ROM репозитория после завершения операций ---
echo "Восстановление CD-ROM репозитория..."
sudo sed -i '/cdrom:/ s/^#//' /etc/apt/sources.list
sudo find /etc/apt/sources.list.d/ -type f -name "*.list" -exec sed -i '/cdrom:/ s/^#//' {} \; 2>/dev/null

# --- Завершение ---
clear
echo "======================================"
echo "Установка завершена! Закройте терминал"
echo "======================================"
exit 0