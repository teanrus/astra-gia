# Настройка среды разработки VS Code для работы и запуска проектов на языке Python3

[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](/LICENSE)
![Language](https://img.shields.io/badge/Language-Python_3-3776AB?style=for-the-badge) ![IDE](https://img.shields.io/badge/IDE-VS_Code-007ACC?style=for-the-badge)

> Версия интерпретатора, доступная по дефолту в репозитория ОС - 3.11.2 (установлена по умолчанию)

Иные версии интерпретатора доступны в [релизе Astra-GIA v2.0](https://github.com/teanrus/astra-gia/releases/tag/v2.0): `python-3.9.25-alse1.8-amd64.deb`, `python-3.10.20-alse1.8-amd64.deb`, `python-3.12.13-alse1.8-amd64.deb`, `python-3.13.15-alse1.8-amd64.deb` и `python-3.14.7-alse1.8-amd64.deb`. Для скачивания выбранного пакета и проверки контрольной суммы замените имя файла в `PACKAGE` на нужное и выполните команды:

```bash
PACKAGE=python-3.14.7-alse1.8-amd64.deb
BASE_URL=https://github.com/teanrus/astra-gia/releases/download/v2.0
wget "$BASE_URL/$PACKAGE" "$BASE_URL/$PACKAGE.sha256"
sha256sum -c "$PACKAGE.sha256" && sudo apt install "./$PACKAGE"
```

Установка запустится только если команда проверки вывела имя файла с результатом `OK`.

## Редактор Visual Studio Code

> Рекомендуемая среде разработки (IDE) для Astra Linux Special Edition 1.8

- Скачайте редактор одним из способов:
  - Официальная страница загрузки: [Visual Studio Code](https://code.visualstudio.com/download)
  - Для Astra Linux Special Edition 1.8 доступен пакет из релиза проекта: [Astra-GIA](https://github.com/teanrus/astra-gia/releases/download/v2.0/code.deb)
- Чтобы скачать пакет и проверить его контрольную сумму, откройте терминал в каталоге загрузки и выполните:

  ```bash
  wget https://github.com/teanrus/astra-gia/releases/download/v2.0/code.deb &&
  wget https://github.com/teanrus/astra-gia/releases/download/v2.0/code.deb.sha256 &&
  sha256sum -c code.deb.sha256 &&
  sudo apt install ./code.deb
  ```

  Команда установки запустится только если проверка завершилась сообщением `code.deb: OK`. При запросе введите пароль пользователя.
- Запустите редактор из **Меню "Пуск" -> Разработка -> Visual Studio Code**
- Перейдите в разде расширений (левая панель Меню) и установите расширение, найдя в поиске, для python3 - **Python от Microsoft**
- При необходимости доустановите расширение поддержки русской локализации интерфейса программы - **Russian Languge Pack for Visual Studio Code от Microsoft**

> [Установка расширений в VS Code самостоятельно без Менеджера плагинов](vscode-extentions-manual.md)

### Создание простого проекта на Python

- Запустите редактор Visual Studio Code
- Создайте новый файл и сохраните его с расширением `.py` (или сразу выберите в выпадающем списке `Файл Python`)
- Напишите листинг программы
- Пример простой программы вида Hello, World для проверки работоспособности инструментов:

```Python
    print("Hello, World!")
```

- Запустите программу из меню редактора (**значек play на панели**)
- Программа будет запущена во встроенном терминале среды разработки

***

#### Альтернативные решения

> **IDLE**

- Среда доступна в сетевом репозитории ОС: `sudo apt -y install idle-python3.11`
- При необходимости работы с фреймворком Tk установите его из репозитория: `sudo apt -y install python3-tk`
- общая информация по работе с Tk: [Перейти](https://docs.astralinux.ru/latest/desktop/python/tkinter/)

> Перевод IDLE из интерактивного режима в режим редактора:

- Запуститие среду разработки из **Меню "Пуск" -> Разработка**
- Перейдите в Настройки: **Options -> Configure IDLE -> вкладка Windows**
- Включите настройку `Open Edit Window`
- Примените изменения и перезапустите среду разработки

> **Geany**

- Редактор может быть установлен из репозитория ОС: `sudo apt -y install geany geany-plugins`

> **PyCharm**

- Среда отсутствует в штатном репозитории операционной системы
- Для Astra Linux Special Edition 1.8 доступен пакет из релиза проекта: [Скачать](https://github.com/teanrus/astra-gia/releases/download/v2.0/pycharm.deb)
- Скачайте пакет и его файл контрольной суммы, проверьте пакет и только затем установите:

  ```bash
  wget https://github.com/teanrus/astra-gia/releases/download/v2.0/pycharm.deb &&
  wget https://github.com/teanrus/astra-gia/releases/download/v2.0/pycharm.deb.sha256 &&
  sha256sum -c pycharm.deb.sha256 &&
  sudo apt install ./pycharm.deb
  ```

  Команда установки запустится только если проверка вывела `pycharm.deb: OK`.

#### Руссификация интерфейса PyCharm

>*Использование встроенного Менеджера плагинов для загрузки расширения невозможно по причине блокировки нашей страны со стороны разработчиков среды. В пакет среды разработки на портале уже подложен заранее сам плагин руссификации интерфейса среды*

- Запустите среду разработки PyCharm
- Перейдите в управление плагинами: **Значок шестеренки на панели инструментов -> Plugins...**
- В открывшемся окне щелкните по **значку шестеренки** и выберите опцию `Install Plugin From Disk`
- Укажите путь к файлу плагина с расширением **.jar** по адресу `/opt/pycharm/LANG_RU/`
- Нажмите кнопку **Apply** и согласитесь с предупреждением, после нажмите кнопку **OK**
- Перейдите в настройки для активации установленного плагина: **Значок шестеренки на панели инструментов -> Settings...**
- Откройте раздел **Appearance & Behavior -> System Settings -> Language and Region**
- В поле **Language** выберите опцию `Russian`
- Нажмите кнопку **Apply** и согласитесь на перезапуск среды, нажав кнопку **Restart**

## PyQT5

> **PyQt5** — это один из самых популярных фреймворков для создания графических интерфейсов (GUI) на языке Python. Он предоставляет мощные инструменты для создания десктопных приложений в ALSE

Подробнее о фреймворке [тут](https://docs.astralinux.ru/latest/desktop/python/pyqt5/)
