#!/bin/bash

##############################################################################
# configure_printer.sh — Настройка USB-принтера в CUPS
#
# Описание:
#   Интерактивно находит USB-принтер, предлагает выбрать установленную
#   модель CUPS и создаёт очередь печати.
#
# Использование:
#   sudo ./configure_printer.sh
#
# Зависимости: bash, CUPS (cups-client), awk, grep, sed
#
# Разработчик: Руслан Тян <tyanrv@lbt.yanao.ru>
##############################################################################

set -euo pipefail

error() {
    printf '[ОШИБКА] %s\n' "$*" >&2
}

if [ "$EUID" -ne 0 ]; then
    error "Запустите этот сценарий от имени root: sudo $0"
    exit 1
fi

for command_name in lpinfo lpadmin lpstat awk grep sed; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        error "Не найдена обязательная команда: $command_name"
        error "Установите и запустите CUPS, затем установите cups-client."
        exit 1
    fi
done

mapfile -t PRINTER_URIS < <(
    lpinfo -v 2>/dev/null | awk '$1 == "direct" && $2 ~ /^usb:\/\// { print $2 }'
)

if [ "${#PRINTER_URIS[@]}" -eq 0 ]; then
    error "CUPS не обнаружил принтеры, подключённые напрямую через USB."
    error "Проверьте вывод «lpinfo -v», USB-подключение и службу CUPS."
    exit 1
fi

printf 'Обнаруженные подключения принтеров по USB:\n'
for index in "${!PRINTER_URIS[@]}"; do
    printf '  %d) %s\n' "$((index + 1))" "${PRINTER_URIS[$index]}"
done

read -r -p "Выберите номер принтера: " selection
if [[ ! "$selection" =~ ^[0-9]+$ ]] ||
    [ "$selection" -lt 1 ] ||
    [ "$selection" -gt "${#PRINTER_URIS[@]}" ]; then
    error "Неверно выбран принтер."
    exit 1
fi
DEVICE_URI="${PRINTER_URIS[$((selection - 1))]}"

read -r -p "Имя очереди CUPS [GIA_PRINTER_1]: " QUEUE
QUEUE="${QUEUE:-GIA_PRINTER_1}"
if [[ ! "$QUEUE" =~ ^[A-Za-z0-9_-]+$ ]]; then
    error "Имя очереди может содержать только латинские буквы, цифры, подчёркивания и дефисы."
    exit 1
fi

if lpstat -p "$QUEUE" >/dev/null 2>&1; then
    error "Очередь CUPS «$QUEUE» уже существует; она не изменена."
    exit 1
fi

URI_HINT="$(printf '%s' "$DEVICE_URI" | sed 's|^usb://||; s|?.*||; s|/| |g')"
printf '\nНайдите установленную модель CUPS для обнаруженного принтера (%s).\n' "$URI_HINT"
read -r -p "Введите производителя или модель принтера для поиска: " MODEL_SEARCH
if [ -z "$MODEL_SEARCH" ]; then
    error "Нужно указать производителя или модель; очередь не создана."
    exit 1
fi

mapfile -t MODELS < <(lpinfo --make-and-model "$MODEL_SEARCH" -m 2>/dev/null)
if [ "${#MODELS[@]}" -eq 0 ]; then
    error "Среди установленных моделей CUPS нет совпадений с «$MODEL_SEARCH»."
    error "Проверьте вывод «lpinfo -m» и при необходимости установите драйвер производителя для ALSE."
    exit 1
fi

printf '\nПодходящие установленные модели:\n'
for index in "${!MODELS[@]}"; do
    printf '  %d) %s\n' "$((index + 1))" "${MODELS[$index]}"
done
read -r -p "Выберите номер модели: " model_selection
if [[ ! "$model_selection" =~ ^[0-9]+$ ]] ||
    [ "$model_selection" -lt 1 ] ||
    [ "$model_selection" -gt "${#MODELS[@]}" ]; then
    error "Неверно выбрана модель."
    exit 1
fi
MODEL_ID="$(printf '%s\n' "${MODELS[$((model_selection - 1))]}" | awk '{print $1}')"

if ! printf '%s\n' "$DEVICE_URI" | grep -Eq '[?&]serial=[^&]+'; then
    printf '\nВНИМАНИЕ: в USB URI от CUPS не указан серийный номер.\n'
    printf 'Если подключено несколько одинаковых принтеров, их USB-порты могут быть неоднозначны.\n'
    read -r -p "Продолжить с этим подключением? [д/Н]: " confirmation
    case "$confirmation" in
        д|Д|да|ДА|y|Y|yes|YES) ;;
        *) printf 'Очередь не создана.\n'; exit 0 ;;
    esac
fi

if ! lpadmin -p "$QUEUE" -E -v "$DEVICE_URI" -m "$MODEL_ID"; then
    error "CUPS не удалось создать очередь. Проверьте выбранную модель и журналы CUPS."
    exit 1
fi

printf '\nОчередь CUPS создана:\n  Очередь: %s\n  URI: %s\n  Модель: %s\n' \
    "$QUEUE" "$DEVICE_URI" "$MODEL_ID"
printf "Проверьте её командой: lpstat -v %s\n" "$QUEUE"
