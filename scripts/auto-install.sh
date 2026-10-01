#!/bin/bash
echo "==============================================================================="
echo " "
echo "R.Tyan (c) 2026 | tyanrv@lbt.yanao.ru"
echo "Модернизация скрипта auto-install-soft | ddavydov@astralinux.ru"
echo " "
echo "-------------------------------------------------------------------------------"
echo " "
echo "Интерактивный скрипт автоматизации установки ПО для ALSE 1.8"
echo " "
echo "================================================================================"
read -p "Нажмите Enter для начала настройки списка установки..."

# ИСПРАВЛЕНИЕ 1: Автоматическое исправление старых некорректных записей R7-Офис 
# (заменяет ошибочное кодовое имя 'r7' на правильное 'astralinux' во всех файлах apt)
echo "Проверка и исправление некорректных записей репозиториев от предыдущих запусков..."
sudo find /etc/apt/sources.list /etc/apt/sources.list.d/ -type f -name "*.list" -exec sed -i 's|downloads.r7-office.ru/repository/r7-desktop-astra r7|downloads.r7-office.ru/repository/r7-desktop-astra/ astralinux|g' {} \; 2>/dev/null
sudo find /etc/apt/sources.list /etc/apt/sources.list.d/ -type f -name "*.list" -exec sed -i 's|downloads.r7-office.ru/repository/r7-desktop-astra/ r7|downloads.r7-office.ru/repository/r7-desktop-astra/ astralinux|g' {} \; 2>/dev/null

# ИСПРАВЛЕНИЕ 2: Добавление основного репозитория Astra Linux 1.8 для разрешения зависимостей
if ! grep -q "dl.astralinux.ru/astra/stable/1.8_x86-64/main-repository" /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null; then
    echo "Добавление основного репозитория Astra Linux 1.8 для разрешения зависимостей..."
    echo "deb https://dl.astralinux.ru/astra/stable/1.8_x86-64/main-repository/ 1.8_x86-64 main contrib non-free" | sudo tee /etc/apt/sources.list.d/astra-main.list
fi

# Обновление списка пакетов
echo "Обновление списков пакетов (это может занять некоторое время)..."
sudo apt update

# Массивы для хранения выбора пользователя
declare -a URLS_TO_DOWNLOAD
declare -a NAMES_TO_DOWNLOAD
INSTALL_R7_REPO=0
INSTALL_MAX_REPO=0

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
ask_deb "IDLE 3 (Python 3.11)" "https://easyastra.ru/store1.8/idle-python3.11.deb"
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

echo ""
echo "=== ОПРОС ЗАВЕРШЕН ==="
echo ""

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
echo "Переход в директорию с пакетами и установка..."
cd "$PWD/tmp_deb/" || exit 1
sudo apt -y install ./*.deb
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
# ИСПРАВЛЕНО: добавлен флаг --yes для предотвращения интерактивного запроса при перезаписи
curl -fsSL https://download.max.ru/linux/deb/public.asc | sudo gpg --yes --dearmor -o /etc/apt/keyrings/max.gpg >/dev/null
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/max.gpg] https://download.max.ru/linux/deb stable main" | sudo tee /etc/apt/sources.list.d/max.list
sudo apt update
sudo apt install -y max
apt policy max
fi

# --- Завершение ---
clear
echo "======================================"
echo "Установка завершена! Закройте терминал"
echo "======================================"
exit 0