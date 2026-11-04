# Инструменты разработки и среды для языка Java

[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](/LICENSE)
![Language](https://img.shields.io/badge/Language-Java-ED8B00?style=for-the-badge) ![JDK](https://img.shields.io/badge/JDK-OpenJDK_17-437291?style=for-the-badge)

> В репозитории ОС доступна **OpenJDK** 17-ой версии — это открытая и свободная реализация платформы Java Standard Edition (Java SE). Это эталонная реализация, которая разрабатывается сообществом при официальном участии Oracle

Для установки OpenJDK:

- Откройте терминал: `Alt+T`
- Выполните команду: `sudo apt -y install openjdk-17-jdk`

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
- Перейдите в разде расширений (левая панель Меню) и установите расширение, найдя в поиске, для java - **Extension Pack for Java от Microsoft**
- При необходимости доустановите расширение поддержки русской локализации интерфейса программы - **Russian Languge Pack for Visual Studio Code от Microsoft**

> [Установка расширений в VS Code самостоятельно без Менеджера плагинов](vscode-extentions-manual.md)

### Создание простого проекта на Java

- Запустите редактор Visual Studio Code
- Создайте новый файл и сохраните его с расширением `.java`
- Напишите листинг программы
- Пример простой программы вида Hello, World для проверки работоспособности инструментов:

```js
    public class HelloWorld {
        public static void main(String args) {
            System.out.println("Hello, World!");
        }
    }
```

- Запустите программу из меню редактора (**значек play на панели**)
- Программа будет запущена во встроенном терминале среды разработки

***

### Иные решения

> **Eclipse IDE for Java Developers**

- Среда отсутствует в штатном репозитории операционной системы
- Установочный пакет доступен в релизе: [Скачать](https://github.com/teanrus/astra-gia/releases/download/v2.0/eclipse-java.deb)
- Скачайте пакет и его файл контрольной суммы, проверьте пакет и только затем установите:

  ```bash
  wget https://github.com/teanrus/astra-gia/releases/download/v2.0/eclipse-java.deb &&
  wget https://github.com/teanrus/astra-gia/releases/download/v2.0/eclipse-java.deb.sha256 &&
  sha256sum -c eclipse-java.deb.sha256 &&
  sudo apt install ./eclipse-java.deb
  ```

  Команда установки запустится только если проверка вывела `eclipse-java.deb: OK`.
