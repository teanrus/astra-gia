# Решение проблемы потери сканера/принтера после перезагрузки/перехода в спящий режим/переподключения USB-сканера и USB-принтера на Astra Linux SE 1.8

[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](/LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Astra_Linux_SE_1.8-0066CC?style=for-the-badge)](https://astralinux.ru/products/special-edition/)
[![Context](https://img.shields.io/badge/Context-ГИА_ЕГЭ_ОГЭ-1E3A8A?style=for-the-badge)](https://astralinux.ru/education/)
[![Components](https://img.shields.io/badge/Components-SANE_and_CUPS-333333?style=for-the-badge)](https://ru.wikipedia.org/wiki/CUPS)
[![Content](https://img.shields.io/badge/Content-Shell_Scripts-4EAA25?style=for-the-badge)](https://www.gnu.org/software/bash/)

## Как это работает

- `configure_scanner.sh` показывает устройства, уже найденные SANE, и предлагает выбрать сканер. Для выбранного USB-сканера создаются собственные правило udev и helper. При каждом подключении helper обновляет только строку выбранного алиаса в стандартном `/etc/sane.d/dll.aliases`, сохраняя остальные настройки.
- `configure_printer.sh` показывает USB URI, обнаруженные CUPS, предлагает выбрать очередь и установленную модель драйвера, затем создаёт постоянную очередь CUPS. Очереди CUPS сохраняются при перезагрузке.

Для SANE используется стандартный `dll.aliases`.

## Вспомогательный сценарий udev

`gia_sane_udev_helper.sh` — внутренний помощник, который устанавливается
сценарием `configure_scanner.sh` в `/usr/local/libexec/gia-sane-udev-helper`.
Его не нужно запускать вручную: правило udev вызывает его при подключении
USB-устройства с выбранными VID/PID.

Правило передаёт помощнику псевдоним SANE, имя backend и USB VID/PID. Переменную
`DEVPATH` помощник получает из окружения udev; по ней он проверяет ID устройства,
определяет текущие номера шины и устройства и обновляет соответствующую строку
в `/etc/sane.d/dll.aliases`. Остальные алиасы в файле сохраняются. Ошибки
записываются в системный журнал с меткой `gia-sane-udev-helper`.

Не редактируйте и не устанавливайте helper отдельно: чтобы создать согласованные
правило udev и helper, используйте `configure_scanner.sh`. При удалении настройки
сканера удалите установленный helper вместе с правилом и записью алиаса, как
описано в разделе «Проверка и удаление».

## Требования

Подключите устройство и убедитесь, что для его модели установлен драйвер.

Нужны `bash`, `udev`, `usbutils`, SANE (`scanimage`) и CUPS (`lpinfo`, `lpadmin`, `lpstat`). Имена пакетов и доступность драйверов зависят от настроенных репозиториев ALSE 1.8; сначала проверьте наличие команд:

```bash
command -v scanimage lsusb udevadm lpinfo lpadmin
```

Если нужных утилит нет и системные репозитории ALSE доступны:

```bash
sudo apt update
sudo apt install sane-utils usbutils udev cups cups-client
```

Этот набор не включает драйвер конкретной модели сканера или принтера — его нужно установить отдельно из разрешённых для ППЭ репозиториев или локального пакета производителя.

Для диагностики используйте:

```bash
lsusb
scanimage -L
lpinfo -v
lpinfo -m
```

## Установка (рекомендуется для ППЭ)

Откройте терминал и выполните команды по порядку. Они создадут папку в домашнем каталоге пользователя и перейдут в неё:

```bash
mkdir -p ~/fix-printer-scaner
cd ~/fix-printer-scaner
```

Скачайте три файла. Для загрузки нужны доступ к интернету и команда `wget`:

```bash
wget https://raw.githubusercontent.com/teanrus/astra-gia/main/scripts/fix-printer-scaner/configure_scanner.sh
wget https://raw.githubusercontent.com/teanrus/astra-gia/main/scripts/fix-printer-scaner/gia_sane_udev_helper.sh
wget https://raw.githubusercontent.com/teanrus/astra-gia/main/scripts/fix-printer-scaner/configure_printer.sh
```

Если `wget` не установлен, установите его из разрешённого репозитория ALSE. Помощник `gia_sane_udev_helper.sh` нужен для настройки сканера; его отдельно запускать не нужно.

Подключите устройство и запустите сценарий настройки нужного устройства:

```bash
sudo bash ./configure_scanner.sh
```

Для принтера запустите:

```bash
sudo bash ./configure_printer.sh
```

При запросе введите пароль своей учётной записи с правами администратора.

Во время работы сценарии предложат выбрать устройство и ответить на вопросы.

Настраивать каждое устройство нужно отдельно. Для сканера сценарий поддерживает SANE-имена вида `backend:libusb:BBB:DDD`. Если backend использует другой формат, сценарий остановится без создания правила: тогда потребуется модельно-зависимая настройка.

Правило сканера сопоставляет USB VID/PID. Если подключено несколько устройств с одинаковым VID/PID, правило не может однозначно определить выбранный экземпляр;

подключайте по одному такому сканеру. Устройства, меняющие VID/PID при перезапуске или смене режима, требуют отдельного правила для каждой модели/режима.

Для принтера постоянная очередь CUPS переживает перезагрузку.

Стабильность при переподключении зависит от URI устройства: серийный номер в USB URI обычно позволяет отличить конкретный принтер; без него несколько одинаковых устройств могут быть неоднозначны. Сценарий предупреждает об этом и не меняет уже существующую очередь.

## Проверка и удаление

После настройки проверьте обнаружение:

```bash
scanimage -L
lpstat -v
```

Сканер должен появиться под выбранным алиасом, а очередь принтера — в `lpstat`.

Для удаления настройки сканера удалите созданное правило `/etc/udev/rules.d/99-gia-sane-<АЛИАС>.rules`, helper `/usr/local/libexec/gia-sane-udev-helper` и только строку `alias <АЛИАС> ...` из `/etc/sane.d/dll.aliases`, после чего выполните `udevadm control --reload-rules`. Очередь принтера удаляется отдельно командой `lpadmin -x <ИМЯ_ОЧЕРЕДИ>`.

## Статус проверки

> Сценарии подготовлены для стандартных интерфейсов SANE, udev и CUPS; аппаратную проверку и проверку на целевой ОС необходимо выполнить на ППЭ. После теста полезны выводы `scanimage -L`, `lsusb`, `lpinfo -v` и `lpstat -v`.
