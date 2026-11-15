#!/bin/bash

##############################################################################
# gia_sane_udev_helper.sh — Помощник udev для настройки сканера SANE
#
# Описание:
#   Обновляет псевдоним SANE при обнаружении USB-сканера.
#   Запускается правилом udev; для ручного запуска не предназначен.
#
# Использование:
#   Вызывается правилом udev с аргументами <псевдоним> <backend> <VID> <PID>
#
# Зависимости: bash, awk, coreutils, logger
#
# Разработчик: Руслан Тян <tyanrv@lbt.yanao.ru>
# Авторские права: Руслан Тян
##############################################################################

set -euo pipefail

ALIAS="${1:-}"
BACKEND="${2:-}"
EXPECTED_VID="${3:-}"
EXPECTED_PID="${4:-}"
ALIAS_FILE="/etc/sane.d/dll.aliases"

if [[ ! "$ALIAS" =~ ^[A-Za-z0-9_]+$ ]] ||
    [[ ! "$BACKEND" =~ ^[A-Za-z0-9_]+$ ]] ||
    [[ ! "$EXPECTED_VID" =~ ^[[:xdigit:]]{4}$ ]] ||
    [[ ! "$EXPECTED_PID" =~ ^[[:xdigit:]]{4}$ ]] ||
    [ -z "${DEVPATH:-}" ]; then
    logger -t gia-sane-udev-helper "Неверные аргументы или отсутствует DEVPATH"
    exit 1
fi

DEVICE_PATH="/sys${DEVPATH}"
if [ ! -r "${DEVICE_PATH}/idVendor" ] || [ ! -r "${DEVICE_PATH}/idProduct" ]; then
    logger -t gia-sane-udev-helper "Не удалось получить идентификаторы USB-устройства из ${DEVICE_PATH}"
    exit 1
fi

VENDOR="$(tr '[:upper:]' '[:lower:]' < "${DEVICE_PATH}/idVendor")"
PRODUCT="$(tr '[:upper:]' '[:lower:]' < "${DEVICE_PATH}/idProduct")"
EXPECTED_VID="${EXPECTED_VID,,}"
EXPECTED_PID="${EXPECTED_PID,,}"
if [ "$VENDOR" != "$EXPECTED_VID" ] || [ "$PRODUCT" != "$EXPECTED_PID" ]; then
    logger -t gia-sane-udev-helper "Идентификаторы USB-устройства не совпадают с настройкой сканера"
    exit 1
fi

BUS="$(cat "${DEVICE_PATH}/busnum" 2>/dev/null)" || BUS=""
DEVICE="$(cat "${DEVICE_PATH}/devnum" 2>/dev/null)" || DEVICE=""
if [[ ! "$BUS" =~ ^[0-9]+$ ]] || [[ ! "$DEVICE" =~ ^[0-9]+$ ]]; then
    logger -t gia-sane-udev-helper "Не удалось получить номера USB-шины и устройства"
    exit 1
fi

DEVICE_NAME="$(printf '%s:libusb:%03d:%03d' "$BACKEND" "$((10#$BUS))" "$((10#$DEVICE))")"
TEMP_FILE="$(mktemp "${ALIAS_FILE}.XXXXXX")" || {
    logger -t gia-sane-udev-helper "Не удалось создать временный файл псевдонимов SANE"
    exit 1
}
trap 'rm -f "$TEMP_FILE"' EXIT

if [ -f "$ALIAS_FILE" ]; then
    if ! awk -v alias="$ALIAS" '$1 != "alias" || $2 != alias { print }' \
        "$ALIAS_FILE" > "$TEMP_FILE"; then
        logger -t gia-sane-udev-helper "Не удалось прочитать существующий файл псевдонимов SANE"
        exit 1
    fi
fi

if ! printf 'alias %s %s\n' "$ALIAS" "$DEVICE_NAME" >> "$TEMP_FILE" ||
    ! chmod 0644 "$TEMP_FILE" ||
    ! mv -f "$TEMP_FILE" "$ALIAS_FILE"; then
    logger -t gia-sane-udev-helper "Не удалось обновить ${ALIAS_FILE}"
    exit 1
fi

logger -t gia-sane-udev-helper "Псевдоним ${ALIAS} обновлён: ${DEVICE_NAME}"
