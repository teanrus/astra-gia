# Инструкция по установке и настройке десктопного клиента Яндекс Диск

[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](/LICENSE)
![Application](https://img.shields.io/badge/Application-Yandex_Disk-FF0000?style=for-the-badge) ![Interface](https://img.shields.io/badge/Interface-CLI-555555?style=for-the-badge) ![Platform](https://img.shields.io/badge/Platform-Astra_Linux-0066CC?style=for-the-badge)

>**Клиент по умолчанию не имеет графической оболочки! Его настройка производится средствами CLI (Command Line Interface, интерфейс командной строки)**

## Установка клиента

- Официальная инструкция Яндекса: [Установка и настройка клиента для Linux](https://yandex.ru/support/yandex-360/customers/disk/desktop/linux/ru/installation)
- Клиент можно установить из официального репозитория Яндекса. Откройте терминал Fly (`Alt+T`) и выполните команду:

  ```bash
  echo "deb http://repo.yandex.ru/yandex-disk/deb/ stable main" | sudo tee -a /etc/apt/sources.list.d/yandex-disk.list > /dev/null && wget http://repo.yandex.ru/yandex-disk/YANDEX-DISK-KEY.GPG -O- | sudo apt-key add - && sudo apt-get update && sudo apt-get install -y yandex-disk
  ```

- В качестве альтернативы можно скачать пакет из Библиотеки приложений Astra Linux: [yandex-disk.deb](https://easyastra.ru/store1.8/yandex-disk.deb), перейти в каталог загрузки, открыть в нём терминал и установить пакет командой `sudo apt install ./yandex-disk.deb`
- При загрузке и установке программы действуют условия [лицензионного соглашения Яндекса](https://yandex.ru/legal/desktop_software_agreement/)

## Первичная настройка клиента

- Откройте терминал Fly (`Alt+T`) и запустите мастер настройки:

  ```bash
  yandex-disk setup
  ```

- В мастере укажите каталог для локальной копии Диска. Если оставить поле пустым, в домашнем каталоге будет создан `Yandex.Disk`
- Ответьте, нужно ли использовать прокси-сервер и запускать клиент при старте системы
- После настройки конфигурация клиента будет сохранена в `~/.config/yandex-disk/config.cfg`
- При включении запуска при старте системы клиент будет работать в фоновом режиме и синхронизировать данные через указанный каталог

## Индикация состояния работы Яндекс Диска

**Неофициальный пакет от стороннего разработчика!**

- Скачать с портала установочный пакет из Библиотеки приложений: [yandex-disk-indicator.deb](https://easyastra.ru/store1.8/yandex-disk-indicator.deb)
- Двойным кликом ЛКМ выполнить установку пакета средствами qApt
- Запустить единоразово утилиту из **Меню "Пуск" -> Интернет -> Индикатор Yandex.Disk**

>*В области уведомлений должен отображаться значек-индикатор работающего приложения. В конекстном меню утилиты доступны различные информационные данные и настройки*
