[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](/LICENSE)
![Language](https://img.shields.io/badge/Language-Java-ED8B00?style=for-the-badge) ![JDK](https://img.shields.io/badge/JDK-OpenJDK_17-437291?style=for-the-badge)

# Инструменты разработки и среды для языка Java

***

> В репозитории ОС доступна **OpenJDK** 17-ой версии — это открытая и свободная реализация платформы Java Standard Edition (Java SE). Это эталонная реализация, которая разрабатывается сообществом при официальном участии Oracle

Для установки OpenJDK:
- Откройте терминал: `Alt+T`
- Выполните команду: `sudo apt -y install openjdk-17-jdk`

## Редактор Visual Studio Code

> Рекомендуемая среде разработки (IDE) для Astra Linux Special Edition 1.8

- Скачайте с портала из Библиотеки приложений пакет: [code.deb](https://easyastra.ru/store1.8/code.deb)
- Запустите его установку двойным кликом ЛКМ средствами утилиты qApt
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

> **OpenIDE**

- Среда отсутствует в штатном репозитории операционной системы
- Актуальная версия пакета доступна на портале: [Скачать](https://easyastra.ru/store1.8/openide.deb)
- *При создании проекта имеется возможность использовать AxiomJDK, установив соответсвующую реализацию Java*

**Руссификация интерфейса OpenIDE**

- После первого запуска среды нажмите в левом нижнем углу **значек шестеренки (Options Menu)**
- В открывшемся списке выберите пункт `Settings`
- Перейдите **Appearance & Behavior -> System Settings -> Language and Region**
- В поле **Language** выберите опцию `Russian`
- Нажмите кнопку **Apply** и согласитесь на перезапуск среды, нажав кнопку **Restart**

> **intellij IDEA**

- Среда отсутствует в штатном репозитории операционной системы
- Актуальная версия пакета доступна на портале: [Скачать](https://easyastra.ru/store1.8/intellijidea.deb)

> **Eclipse IDE for Java Developers**

- Среда отсутствует в штатном репозитории операционной системы
- Актуальная версия пакета доступна на портале: [Скачать](https://easyastra.ru/store1.8/eclipse-java.deb)