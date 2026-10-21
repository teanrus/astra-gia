[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](/LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Astra_Linux_1.8-0066CC?style=for-the-badge)](https://astralinux.ru/)
[![XRDP](https://img.shields.io/badge/XRDP-Remote_Desktop-0078D7?style=for-the-badge&logo=windows)](https://github.com/neutrinolabs/xrdp)
[![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?style=for-the-badge&logo=gnubash)](https://www.gnu.org/software/bash/)
[![SysAdmin](https://img.shields.io/badge/Role-System_Administration-333333?style=for-the-badge)]()
[![Automation](https://img.shields.io/badge/Automation-Ready-brightgreen?style=for-the-badge)]()

# Краткое руководство по установке и использованию XRDP в Astra Linux 1.8

## 1. Быстрая установка (Работает в 95% случаев)

Убедитесь, что выполнены следующие базовые шаги для стабильной работы:

### Шаг 1. Установка

```bash
sudo apt update
sudo apt install xrdp
```

### Шаг 2. Предоставление прав на сертификаты (Рекомендуется)

Это предотвращает тихие ошибки запуска службы xrdp:

```bash
sudo adduser xrdp ssl-cert
sudo systemctl restart xrdp
```

### Шаг 3. Настройка брандмауэра (Если включен UFW)

```bash
sudo ufw allow 3389/tcp
```

### ⚠️ ЗОЛОТОЕ ПРАВИЛО XRDP В LINUX

**Перед подключением по RDP обязательно завершите локальный сеанс (Log Out / Выйти из системы) на самой машине Astra Linux.**

В Linux один и тот же пользователь не может одновременно иметь активную локальную и удаленную графическую сессию. Если вы просто заблокируете экран (`Win+L`), подключение через RDP, скорее всего, покажет черный экран или зависнет.

---

## 2. Подключение из Windows

1. Нажмите `Win + R`, введите `mstsc` и нажмите Enter.
2. Введите IP-адрес или хост машины.
3. Нажмите «Подключить».
4. В появившемся окне входа XRDP введите логин и пароль пользователя Astra Linux.
5. Нажмите OK.

---

## 3. Диагностика и решение проблем (Раздел «Танцы с бубном»)

*Используйте этот раздел только если что-то пошло не так.*

### Проблема 1: Черный экран после ввода пароля или мгновенный разрыв соединения

**Причина:** Пользователь уже вошел в систему локально, или остался «висящий» процесс сессии.

**Решение:**

1. Физически или через консоль (TTY: `Ctrl+Alt+F3`) завершите сеанс пользователя: `loginctl terminate-user пользователь`.
2. Очистите кэш сессий Fly (иногда помогает): `rm -rf ~/.cache/sessions/*`.
3. Попробуйте подключиться снова.

### Проблема 2: Черный экран с курсором мыши (Ошибка startwm.sh)

**Причина:** Скрипт запуска не смог определить оболочку Fly (редко для 1.8.6, но бывает при кастомных сборках).

**Решение:** Принудительно указать запуск Fly.

1. Откройте файл: `sudo nano /etc/xrdp/startwm.sh`
2. Перед строками `test -x /etc/X11/Xsession...` добавьте:

```bash
unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR
exec fly-wm
```

3. Сохраните (`Ctrl+O`, `Enter`, `Ctrl+X`) и перезапустите службу: `sudo systemctl restart xrdp`.

### Проблема 3: Всплывающие окна «Authentication is required to create a color managed device»

**Причина:** Политики Polkit требуют прав администратора для управления цветовыми профилями в удаленной сессии.

**Решение:** Создать разрешающее правило.

1. Создайте файл: `sudo nano /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla`
2. Вставьте в него:

```ini
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
```

3. Перезагрузите компьютер или службу polkit.

### Проблема 4: Не работает буфер обмена (Copy/Paste между Windows и Astra)

**Причина:** Отключен в клиенте или на уровне сервера.

**Решение:**

1. В окне `mstsc` (перед подключением) нажмите «Показать параметры» → вкладка «Локальные ресурсы» → убедитесь, что стоит галочка **«Буфер обмена»**.
2. На стороне Astra Linux проверьте файл `/etc/xrdp/xrdp.ini`. В нем должна быть строка `cliprdr=true` (обычно она там есть по умолчанию).

### Проблема 5: Требуется перенаправление звука (чтобы слышать звук из Astra на Windows)

**Причина:** По умолчанию звук через RDP не передается. В вашем логе установки система сама подсказала решение: `xrdp-pulseaudio-installer`.

**Решение:**

1. Установите модуль: `sudo apt install xrdp-pulseaudio-installer`
2. Запустите скрипт настройки (он сам скачает и соберет нужные модули pulseaudio для xrdp):

```bash
sudo xrdp-pulseaudio-installer
```

3. В клиенте `mstsc` на вкладке «Локальные ресурсы» в разделе «Удаленный звук» нажмите «Параметры» и выберите **«Воспроизводить на этом компьютере»**.

### Проблема 6: Ошибки, связанные с ПАРСЭК (мандатные метки)

**Причина:** Если на системе включен строгий контроль целостности или мандатное разграничение, процесс `xrdp-sesman` может не иметь права создавать сокет или запускать X-сервер.

**Решение:**

Убедитесь, что контекст безопасности пользователя и процессы X-сервера совместимы. В большинстве рабочих сценариев достаточно убедиться, что пользователь входит в группу `xrdp`, а файлы конфигурации `/etc/xrdp/` имеют корректные метки (обычно решается через `parsec-set-label` или сброс меток на файлы конфигурации, если это допускается политиками ИБ вашей организации).
