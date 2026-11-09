# Инструкция по подключению к сетевой папке Windows из ALSE 1.8

## Подключение через `mount.cifs`

---

### Шаг 1. Установка необходимых пакетов

```bash
sudo apt update
sudo apt install cifs-utils
```

---

### Шаг 2. Создание точки монтирования

```bash
sudo mkdir -p /mnt/share
```

---

### Шаг 3. Подключение сетевой папки

```bash
sudo mount -t cifs //IP_СЕРВЕРА/Имя_Папки /mnt/share \
  -o username=ваш_логин,password=ваш_пароль,iocharset=utf8,file_mode=0777,dir_mode=0777,vers=3.0
```

**Параметры:**

| Параметр | Описание |
| --- | --- |
| `//IP_СЕРВЕРА/Имя_Папки` | Путь к сетевой папке Windows |
| `username` | Логин пользователя Windows/домена |
| `password` | Пароль |
| `iocharset=utf8` | Кодировка (корректное отображение русских имён файлов) |
| `file_mode=0777` | Права на файлы |
| `dir_mode=0777` | Права на папки |
| `vers=3.0` | Версия SMB-протокола (можно попробовать `2.1` или `1.0`, если не работает) |

> ⚠️ Если сервер в домене, добавьте параметр: `domain=ИМЯ_ДОМЕНА`

---

### Шаг 4. Проверка подключения

```bash
ls -la /mnt/share
```

---

### Шаг 5. Автоматическое монтирование при загрузке (опционально)

1. Создать файл с учётными данными (чтобы не хранить пароль в fstab):

```bash
sudo nano /etc/cifs-credentials
```

Содержимое файла:

```bash
username=ваш_логин
password=ваш_пароль
domain=ИМЯ_ДОМЕНА
```

1. Установить права на файл:

```bash
sudo chmod 600 /etc/cifs-credentials
```

1. Добавить запись в `/etc/fstab`:

```bash
sudo nano /etc/fstab
```

Добавить строку:

```bash
//IP_СЕРВЕРА/Имя_Папки /mnt/share cifs credentials=/etc/cifs-credentials,iocharset=utf8,file_mode=0777,dir_mode=0777,vers=3.0,_netdev 0 0
```

1. Проверить:

```bash
sudo mount -a
```

---

### Шаг 6. Отключение папки

```bash
sudo umount /mnt/share
```

---

## Если не работает — troubleshooting

| Симптом | Решение |
| --- | --- |
| Ошибка авторизации | Проверить логин/пароль, добавить `domain=`, попробовать `vers=2.1` |
| Пустая папка | Скорее всего проблема с версией протокола — указать `vers=2.1` или `vers=1.0` |
| `mount error(115): Operation now in progress` | Проверить доступность сервера: `ping IP_СЕРВЕРА` и `smbclient -L //IP_СЕРВЕРА -U логин` |
| Ошибка `Permission denied` | Добавить `sec=ntlmssp` в параметры монтирования |

---

## Быстрая проверка доступности шары

```bash
sudo apt install smbclient
smbclient -L //IP_СЕРВЕРА -U ваш_логин
```

Эта команда покажет список доступных сетевых папок на сервере — поможет убедиться, что путь указан верно.
