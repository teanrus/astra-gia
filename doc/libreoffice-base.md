[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](/LICENSE)
![Application](https://img.shields.io/badge/Application-LibreOffice-18A303?style=for-the-badge) ![Database](https://img.shields.io/badge/Database-HSQLDB-4479A1?style=for-the-badge)

# Настройка LibreOffice Base для работы со встроенной базой данных

***

> Система управления базами данных Base входит в поставку офисного пакета LibreOffice по умолчанию, но не позволяет создавать и работать со встроенной базой данных

Для решения это проблемы необходимо установить пакет **sdbc-hsqldb** для LibreOffice - специальный драйвер (прослойка) для работы с HSQLDB (HyperSQL) внутри LibreOffice, для этого:

- Убедитесь в подключении [сетевых интернет репозиториев ОС](repo-update-install.md) и доступности сети интернет
- Откройте терминал: `Alt+T`
- Установите драйвер: `sudo apt -y install libreoffice-sdbc-hsqldb`

## Создание и работа с базой данных

- Запустите LibreOffice Base из Меню "Пуск" -> Офис 
- Укажите `Создать новую базу данных` и выберите `Встроенная база данных: HSQLDB `
- Нажмите конпку "Далее"
- Нажмите кнопку "Готово"
- Задайте имя новой создаваемой базы данных и путь сохранения файла
- Откроется привычный интерфейс, напоминающий аналогичный в MS Access
