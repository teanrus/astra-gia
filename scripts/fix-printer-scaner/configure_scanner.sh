#!/bin/bash

set -euo pipefail

ALIAS_DEFAULT="GIA_SCANNER"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
HELPER_SOURCE="${SCRIPT_DIR}/gia_sane_udev_helper.sh"
RULE_DIR="/etc/udev/rules.d"
HELPER_DIR="/usr/local/libexec"
SANE_CONFIG_DIR="/etc/sane.d"

error() {
    printf '[ОШИБКА] %s\n' "$*" >&2
}

if [ "$EUID" -ne 0 ]; then
    error "Запустите этот сценарий от имени root: sudo $0"
    exit 1
fi

for command_name in scanimage lsusb udevadm awk grep install mktemp sed dirname readlink; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        error "Не найдена обязательная команда: $command_name"
        error "Установите пакеты ALSE: sane-utils, usbutils и udev."
        exit 1
    fi
done

if [ ! -f "$HELPER_SOURCE" ]; then
    error "Не найден вспомогательный сценарий: $HELPER_SOURCE"
    exit 1
fi

mapfile -t SCANNER_NAMES < <(
    scanimage -L 2>/dev/null |
        sed -n "s/^device \`\([^']*\)'.*/\1/p"
)

if [ "${#SCANNER_NAMES[@]}" -eq 0 ]; then
    error "SANE не обнаружил сканеры."
    error "Проверьте USB-подключение, драйвер сканера и вывод «scanimage -L»."
    exit 1
fi

printf 'Сканеры, обнаруженные SANE:\n'
for index in "${!SCANNER_NAMES[@]}"; do
    printf '  %d) %s\n' "$((index + 1))" "${SCANNER_NAMES[$index]}"
done

read -r -p "Выберите номер сканера: " selection
if [[ ! "$selection" =~ ^[0-9]+$ ]] ||
    [ "$selection" -lt 1 ] ||
    [ "$selection" -gt "${#SCANNER_NAMES[@]}" ]; then
    error "Неверно выбран сканер."
    exit 1
fi

DEVICE_NAME="${SCANNER_NAMES[$((selection - 1))]}"
if [[ ! "$DEVICE_NAME" =~ ^([[:alnum:]_]+):libusb:([0-9]{3}):([0-9]{3})$ ]]; then
    error "У этого сканера нет адреса SANE libusb: $DEVICE_NAME"
    error "Для данного backend требуется отдельная настройка для модели устройства."
    exit 1
fi

BACKEND="${BASH_REMATCH[1]}"
USB_BUS="${BASH_REMATCH[2]}"
USB_DEVICE="${BASH_REMATCH[3]}"
USB_LINE="$(lsusb -s "${USB_BUS}:${USB_DEVICE}" 2>/dev/null)" || USB_LINE=""
VID_PID="$(printf '%s\n' "$USB_LINE" | grep -oE 'ID [[:xdigit:]]{4}:[[:xdigit:]]{4}' | awk '{print $2}')" || VID_PID=""

if [[ ! "$VID_PID" =~ ^([[:xdigit:]]{4}):([[:xdigit:]]{4})$ ]]; then
    error "Не удалось определить USB ID производителя и устройства для SANE."
    error "lsusb не обнаружил шину ${USB_BUS}, устройство ${USB_DEVICE}."
    exit 1
fi

VID="${BASH_REMATCH[1],,}"
PID="${BASH_REMATCH[2],,}"

read -r -p "Постоянный псевдоним SANE [${ALIAS_DEFAULT}]: " ALIAS
ALIAS="${ALIAS:-$ALIAS_DEFAULT}"
if [[ ! "$ALIAS" =~ ^[A-Za-z0-9_]+$ ]]; then
    error "Псевдоним может содержать только латинские буквы, цифры и подчёркивания."
    exit 1
fi

HELPER_PATH="${HELPER_DIR}/gia-sane-udev-helper"
RULE_PATH="${RULE_DIR}/99-gia-sane-${ALIAS}.rules"
if [ -e "$HELPER_PATH" ] || [ -e "$RULE_PATH" ]; then
    error "Для этой настройки уже существует управляемый файл:"
    error "  $HELPER_PATH"
    error "  $RULE_PATH"
    error "Проверьте или удалите существующую настройку перед повторным запуском сценария."
    exit 1
fi
if [ -f "${SANE_CONFIG_DIR}/dll.aliases" ] &&
    awk -v alias="$ALIAS" '$1 == "alias" && $2 == alias { found = 1 } END { exit !found }' \
        "${SANE_CONFIG_DIR}/dll.aliases"; then
    error "Псевдоним «$ALIAS» уже настроен в ${SANE_CONFIG_DIR}/dll.aliases."
    error "Выберите другой псевдоним или сначала проверьте существующую запись."
    exit 1
fi

mkdir -p "$HELPER_DIR" "$RULE_DIR" "$SANE_CONFIG_DIR" || {
    error "Не удалось создать системные каталоги конфигурации."
    exit 1
}

RULE_TEMP="$(mktemp "${RULE_DIR}/.gia-sane.XXXXXX")" || {
    error "Не удалось создать временное правило udev."
    exit 1
}
cleanup() {
    rm -f "$RULE_TEMP"
}
trap cleanup EXIT

if ! install -m 0755 "$HELPER_SOURCE" "$HELPER_PATH"; then
    error "Не удалось установить вспомогательный сценарий udev."
    exit 1
fi

if ! printf 'SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="%s", ATTR{idProduct}=="%s", RUN+="%s %s %s %s %s"\n' \
    "$VID" "$PID" "$HELPER_PATH" "$ALIAS" "$BACKEND" "$VID" "$PID" > "$RULE_TEMP"; then
    rm -f "$HELPER_PATH"
    error "Не удалось записать правило udev."
    exit 1
fi

if ! install -m 0644 "$RULE_TEMP" "$RULE_PATH"; then
    rm -f "$HELPER_PATH"
    error "Не удалось установить правило udev."
    exit 1
fi

udevadm control --reload-rules || {
    rm -f "$RULE_PATH" "$HELPER_PATH"
    error "udevadm не удалось перезагрузить правила; новые файлы удалены."
    exit 1
}

udevadm trigger --subsystem-match=usb \
    --attr-match="idVendor=${VID}" --attr-match="idProduct=${PID}" || {
    error "Правило установлено, но udev не удалось повторно обработать выбранный сканер."
    error "Переподключите сканер и проверьте системный журнал."
    exit 1
}
udevadm settle || {
    error "udevadm не дождался завершения обработки событий устройств."
    exit 1
}

printf '\nНастройка установлена:\n  Псевдоним: %s\n  USB ID: %s:%s\n  Правило: %s\n' \
    "$ALIAS" "$VID" "$PID" "$RULE_PATH"
if scanimage -L 2>/dev/null | grep -F "$ALIAS" >/dev/null; then
    printf 'SANE обнаружил выбранный сканер под псевдонимом %s.\n' "$ALIAS"
else
    printf 'ВНИМАНИЕ: SANE пока не обнаружил псевдоним %s.\n' "$ALIAS"
    printf 'Переподключите сканер и проверьте системный журнал и вывод scanimage -L.\n'
fi
printf 'Для точного определения устройства подключайте только один сканер с USB ID %s:%s.\n' \
    "$VID" "$PID"
