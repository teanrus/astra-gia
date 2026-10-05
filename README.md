[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](/LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Astra_Linux-0066CC?style=for-the-badge)](https://astralinux.ru/)
[![Topic](https://img.shields.io/badge/Topic-Disk_Partitioning-6B7280?style=for-the-badge)](https://wiki.astralinux.ru/kb/rekomendatsii-po-ruchnoj-razmetke-diska-238450060.html?searchId=4F9K4AQA2)
![Storage](https://img.shields.io/badge/Storage-SSD-555555?style=for-the-badge)

![Logo](assets/computer-lab.png)

# Astra GIA

Набор скриптов и инструкций для подготовки рабочих мест на Astra Linux Special Edition 1.8 к проведению ГИА (ЕГЭ, ОГЭ, экзамены по информатике и смежным предметам).

## Что входит в репозиторий

- Скрипты автоматизации установки программного обеспечения и настройки окружения.
- Инструкции по настройке ОС, сетевых подключений, программирования и учебных приложений.
- Руководства для администраторов и преподавателей по подготовке и обслуживанию рабочих мест.

Полный каталог материалов: [документация проекта](doc/README.md).

## Основные сценарии

### 1. Автоматическая установка ПО

Скрипт: `scripts/auto-install.sh`

Назначение:

- установка пакетов для ГИА;
- выбор ветки репозитория Astra Linux;
- работа в интерактивном режиме или через CLI-флаги;
- установка пакетов по категориям: офис, браузеры, программирование, графика, образование;
- режим `--dry-run`, `--list`, `--full-os`, `--browsers-only`, `--education-only`.

Подробнее: [`scripts/auto-install.md`](scripts/auto-install.md)

### 2. Установка расширений VS Code из релиза

Скрипт: `scripts/install-vscode-extensions.sh`

Назначение:

- скачивание архива с расширениями из GitHub Releases;
- распаковка в `~/.vscode/`;
- выбор пользователя из списка `/home/*` или автоматическое определение;
- поддержка `--select-user`, `--list-users`, `--auto`, `--dry-run`.

Подробнее: `scripts/install-vscode-extensions.md`

Для ручной установки расширений без скрипта см. [отдельную инструкцию](doc/vscode-extentions-manual.md).

### 3. Активация репозиториев

Скрипт: `scripts/repository-activation.sh`

Назначение:

- активация нужной ветки репозитория Astra Linux 1.8;
- подготовка системы для установки стороннего ПО и зависимостей.

### 4. Рекомендуемая схема разделов диска

Документ: `doc/disk-layout.md`

Содержит описание рекомендованной схемы разделов для Astra Linux, включая `/`, `/var`, `/tmp`, `/home`, `swap` и загрузочные разделы.

## Документация

### Подготовка и обслуживание Astra Linux

- [Разметка диска](doc/disk-layout.md)
- [Подключение репозиториев, обновление ОС и установка программ](doc/repo-update-install.md)
- [Настройка сети через ЕСПД](doc/espd.md)

### Языки программирования и учебные среды

- [1С:Элемент](doc/1c-element-language.md)
- [Basic 256](doc/basic256.md)
- [C и C++ в VS Code](doc/c-cpp-vscode.md)
- [C# и .NET](doc/dotnet-csharp.md)
- [Java](doc/java.md)
- [КуМир 2](doc/kumir2.md)
- [Pascal](doc/pascal.md)
- [Python в VS Code](doc/python.md)

### Приложения и дополнительные настройки

- [КриптоПро и порталы Госуслуг](doc/cryptopro-gos.md)
- [LibreOffice Base](doc/libreoffice-base.md)
- [Установка расширений VS Code вручную](doc/vscode-extentions-manual.md)
- [Яндекс Диск](doc/yandex-disk.md)

## Быстрый старт

### Запуск автоматической установки

```bash
cd scripts
./auto-install.sh
```

### Запуск установки расширений VS Code

```bash
cd scripts
./install-vscode-extensions.sh --select-user
```

### Показать список пользователей

```bash
cd scripts
./install-vscode-extensions.sh --list-users
```

## Требования

- Astra Linux Special Edition 1.8 (x86_64)
- Пользователь с правами `sudo`
- Подключение к интернету для загрузки пакетов и релизных архивов
- Установленный `curl` для сценариев загрузки из GitHub Releases

## Лицензия

Проект распространяется по лицензии MIT. Подробности см. в [LICENSE](LICENSE).

## Благодарности

Особая благодарность за предоставление части инструкций Денису Давыдову [ddavydov@astralinux.ru](mailto:ddavydov@astralinux.ru)

## Контакты

- Редактура и сопровождение: Руслан Тян
- Email: [tyanrv@lbt.yanao.ru](mailto:tyanrv@lbt.yanao.ru)
