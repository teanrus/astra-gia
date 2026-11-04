# Алгоритмический язык Кумир 2

[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](/LICENSE)
![Language](https://img.shields.io/badge/Language-Kumir_2-007ACC?style=for-the-badge) ![Topic](https://img.shields.io/badge/Topic-Programming_Education-2E8B57?style=for-the-badge)

> КуМир (Комплект Учебных МИРов) - система программирования, предназначенная для поддержки начальных курсов информатики и программирования в средней и высшей школе

## Установка среды

- Для Astra Linux Special Edition 1.8 доступен пакет из релиза проекта: [kumir2.deb](https://github.com/teanrus/astra-gia/releases/download/v2.0/kumir2.deb)
- Скачайте пакет и файл контрольной суммы, затем проверьте пакет:

  ```bash
  wget https://github.com/teanrus/astra-gia/releases/download/v2.0/kumir2.deb &&
  wget https://github.com/teanrus/astra-gia/releases/download/v2.0/kumir2.deb.sha256 &&
  sha256sum -c kumir2.deb.sha256 &&
  sudo apt install ./kumir2.deb
  ```

  Команда установки запустится только если проверка вывела `kumir2.deb: OK`. При запросе введите пароль пользователя.
- Запустите приложение из **Меню "Пуск" -> Научные -> Кумир Классик**

## Запуск среды и работа

- Запустите приложение
- Напишите листинг программы

```txt
использовать Робот
алг Квадрат
нач
    закрасить
    вправо
    закрасить
    вправо
    закрасить
    вниз
    закрасить
    вниз
    закрасить
    влево
    закрасить
    влево
    закрасить
    вверх
    закрасить
кон

```

- Запустите алгоритм, нажав кнопку запуска на панели инструментов или `Shift+F9`

***

### Дополнительная информация

- [Учебники](https://niisi.ru/kumir/books.htm)
- [Вопросы и ответы](https://niisi.ru/kumir/faq.htm)
- [Набор команд](http://test.kumir.su/Syntax%20Kumir.htm)
- [Решение задач в системе КуМир](http://test.kumir.su/)
