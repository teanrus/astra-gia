[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](/LICENSE)
![Language](https://img.shields.io/badge/Language-Pascal-B0A0D0?style=for-the-badge) ![IDE](https://img.shields.io/badge/IDE-PascalABC-00599C?style=for-the-badge) ![IDE](https://img.shields.io/badge/IDE-Lazarus-444444?style=for-the-badge)

# Инструменты разработки на языке Pascal

***

> **PascalABC**

- Среда отсутствует в штатном репозитории операционной системы
- Актуальная версия пакета доступна на портале: [Скачать](https://easyastra.ru/store1.8/pascalABC.deb)

> **Geany**

- Установите необходимые зависимости, выполнив в терминале: `sudo apt -y install fpc`
- Редактор может быть установлен из репозитория ОС: `sudo apt -y install geany geany-plugins`
- Более свежая версия доступна на портале: [Скачать](https://easyastra.ru/store1.8/geany.deb)

> **Lazarus**

- В штатном репозитории ОС доступна достаточно старая версия среды: `sudo apt -y install lazarus-ide`
- Актуальная версия ветки 3.Х досутпна на портале: [Скачать](https://easyastra.ru/store1.8/lazarus36.deb)
- Актуальная версия ветки 4.Х досутпна на портале: [Скачать](https://easyastra.ru/store1.8/lazarus46.deb)

**Среда позволяет вести разработку графических приложений с ипользованием ООП на диалекте ObjectPascal**

***

## Пример листинга проcтой программы сложения двух целых чисел

```pascal
    var x,y:integer;
    begin
        writeln('Введите первое число: ');
        readln(x);
        writeln('Введите второе число: ');
        readln(y);
        writeln('Сумма чисел = ', x+y);
    end.
```
