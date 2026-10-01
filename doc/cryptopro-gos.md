# Установка КриптПРО 5 и плагинов для работы с ГОС порталами

**Уставнока и проверка выполнялись на сертифицированной версии криптопровайдера 5.0.13000**

***

> Перед установкой убедиться в наличии подключенных сетевых интернет репозиториев ОС и доступа к сети Интернет

## Установка КриптоПРО 5

- Получить дистрибутив вида **linux-amd64_deb.tgz** на официальном сайте: [cryptopro.ru](https://cryptopro.ru/downloads)
- Скачать срипт автоматизации установки с портала: [Скачать](https://easyastra.ru/scripts/crypto5-install-gos.tar.gz)
- Распаковать скачанный архив и перейти в каталог
- Двойным кликом ЛКМ запустить скрипт `RUN.sh` и следовать инструкциям на экране

> Во время установки скрипт попросит указать место расположения архива с дистрибутивом вида linux-amd64_deb.tgz
> Вместе с Крипто ПРО так же автоматически будет установлен cades browser plugin

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
