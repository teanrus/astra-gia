# Установка КриптПРО 5 и плагинов для работы с ГОС порталами

[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](/LICENSE)
![Software](https://img.shields.io/badge/Software-CryptoPro_CSP_5-0066CC?style=for-the-badge) ![Plugin](https://img.shields.io/badge/Plugin-CAdES-2E8B57?style=for-the-badge) ![Browser](https://img.shields.io/badge/Browser-Chromium_GOST-4285F4?style=for-the-badge)

## Установка и проверка

> Выполнялись на сертифицированной версии криптопровайдера 5.0.13000

***

> Перед установкой убедиться в наличии подключенных сетевых интернет репозиториев ОС и доступа к сети Интернет

## Установка КриптоПРО 5

- Получить дистрибутив вида **linux-amd64_deb.tgz** на официальном сайте: [cryptopro.ru](https://cryptopro.ru/downloads)
- Скачать срипт автоматизации установки с портала: [Скачать](https://easyastra.ru/scripts/crypto5-install-gos.tar.gz)
- Распаковать скачанный архив и перейти в каталог
- Перейдите в каталог с распакованным архивом
- Нажмите ПКМ внутри каталога и выберите **Открыть в терминале**
- Выполните команду: `sudo bash ./RUN.sh`
- Следуйте инструкциям на экране

> Во время установки скрипт попросит указать место расположения архива с дистрибутивом вида linux-amd64_deb.tgz
> Вместе с Крипто ПРО так же автоматически будет установлен cades browser plugin

## Установка драйверов и плагинов для Рутокен

- Если в работе используется носитель Рутокен, дополнительно установите официальные драйверы и плагины Рутокен для ОС Astra Linux
- Дистрибутивы и инструкции обычно доступны на официальном сайте производителя: [Rutoken](https://www.rutoken.ru/)
- После установки драйверов перезагрузите систему или выполните повторный вход в сеанс
- Проверьте, что токен определяется в системе и доступен через приложения КриптоПРО/Рутокен

## Установка расширения для браузера

- Запустите браузер Chromium GOST
- Перейдите по ссылке установки расширения: [https://chromewebstore.google.com/detail/extension-for-cades-brows/pfhgbfnnjiafkhfdkmpiflachepdcjod](https://chromewebstore.google.com/detail/extension-for-cades-brows/pfhgbfnnjiafkhfdkmpiflachepdcjod)
- Нажмите установить

> Если магазин расширений по каким-то причинам недоступен, то:

- Скачать расширение на компьютер: [Ссылка](https://easyastra.ru/scripts/pfhgbfnnjiafkhfdkmpiflachepdcjod.crx)
- Запустить браузер Chromium GOST
- Перейти в браузере в **Настройки -> Расширения -> Управление расширениями**
- Активировать переключатель "Режим разработчика"
- Перетащить скачанный ранее файл расширения в окно браузера

### Проверка работоспособности

- Сертификаты ЭЦП установите средствами утилиты "Инструменты КриптоПРО": **Меню "Пуск" -> Инструменты -> Инструменты КриптоПРО**
- Для проверки работоспособности перейдите в браузере Chromium GOST по адресу: [https://cryptopro.ru/sites/default/files/products/cades/demopage/cades_bes_sample.html](https://cryptopro.ru/sites/default/files/products/cades/demopage/cades_bes_sample.html)
