# Настройка среды разработки VS Code для работы и запуска проектов на языках C/C++

[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](/LICENSE)
![Language](https://img.shields.io/badge/Language-C_and_C%2B%2B-00599C?style=for-the-badge) ![IDE](https://img.shields.io/badge/IDE-VS_Code-007ACC?style=for-the-badge) ![Compiler](https://img.shields.io/badge/Compiler-GCC-555555?style=for-the-badge)

> Версия компилятора GCC (GNU C Compiler), доступная по дефолту в репозитория ОС - 12.2.0

## Установка дополнительных зависимостей

- Откройте териминал Fly: `Alt+T`
- Обновите базу с информацией о пакетах: `sudo apt update`
- Устноавите инструменты разработки: `sudo apt -y install gcc g++ make gdb`

## Редактор Visual Studio Code

> Рекомендуемая среде разработки (IDE) для Astra Linux Special Edition 1.8

- Скачайте редактор одним из способов:
  - Официальная страница загрузки: [Visual Studio Code](https://code.visualstudio.com/download)
  - Для Astra Linux Special Edition 1.8 доступен пакет из релиза проекта: [Astra-GIA](https://github.com/teanrus/astra-gia/releases/download/v2.0/code.deb)
- Установка скачанного пакета из терминала (рекомендуется):
  - перейдите в каталог с загруженным пакетом `code*.deb`
  - нажмите ПКМ внутри каталога и выберите **Открыть в терминале**
  - выполните команду: `sudo apt install ./code*.deb`
  - при запросе введите пароль пользователя и подтвердите установку
- Запустите редактор из **Меню "Пуск" -> Разработка -> Visual Studio Code**
- Перейдите в разде расширений (левая панель Меню) и установите расширения, найдя в поиске, для C/C++: **C/C++ DevTools и С/C++ Extantion Pack от Microsoft**
- При необходимости доустановите расширение поддержки русской локализации интерфейса программы: **Russian Languge Pack for Visual Studio Code от Microsoft**

> [Установка расширений в VS Code самостоятельно без Менеджера плагинов](vscode-extentions-manual.md)

### Создание простого проекта на C++

- Запустите редактор Visual Studio Code
- Создайте новый файл и сохраните его с расширением `.cpp`
- Напишите листинг программы
- Пример простой программы вида Hello, World для проверки работоспособности инструментов:

```c++
    #include <iostream>

    int main() {
        std::cout << "Hello, world!" << std::endl;
        return 0;
    }
```

- Из меню редактора рядом с кнопкой запуска (**значек play на панели**) нажмите стрелочку и выберите `Запустить файл C/C++`
- В выпадающем списке укажите компилятор **g++**
- Программа будет скомпилирована и запущена во встроенном терминале среды разработки

***

#### Альтернативные решения

> **Geany** - лёгкий кроссплатформенный текстовый редактор с открытым исходным кодом, предназначенный для программистов

- Установите необходимые зависимости, выполнив в терминале: `sudo apt -y install gcc g++ make gdb`
- Редактор может быть установлен из репозитория ОС: `sudo apt -y install geany geany-plugins`

> **Code::Blocks** - свободная кроссплатформенная среда разработки, поддерживает C и C++

- Среда отсутсвует в штатном репозитории операционной системы
- Актуальная версия пакета доступна в релизе: [Скачать](https://github.com/teanrus/astra-gia/releases/download/v2.0/codeblocks.deb)

**Руссификация интерфейса среды:**

- В главном меню программы перейдите **Settings -> Environment...**
- Перейдите в категорию **View**
- Установите галку `Internationalization`
- В выпадающем списке выберите `Russian`
- Перезапустите приложение

> **Eclipse IDE for C/C++ Developers** - среда разработки Eclipse для работы с проектами на C и C++

- Среда отсутсвует в штатном репозитории операционной системы
- Актуальная версия пакета доступна в релизе: [Скачать](https://github.com/teanrus/astra-gia/releases/download/v2.0/eclipse-cpp.deb)

> Альтернативные версии компилятора GCC в виде tarball доступны тут: [Перейти](https://disk.yandex.ru/d/rQWnFi4yyjJbYQ)
