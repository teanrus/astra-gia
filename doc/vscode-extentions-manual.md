# Установка расширений в VS Code самостоятельно без Менеджера плагинов

[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](/LICENSE)
![IDE](https://img.shields.io/badge/IDE-VS_Code-007ACC?style=for-the-badge) ![Topic](https://img.shields.io/badge/Topic-Extensions-6B7280?style=for-the-badge) ![Install](https://img.shields.io/badge/Install-Manual-2E8B57?style=for-the-badge)

> Механизм установки расширений среды разработки VS Code для язков **C, C++, C#, Python, Java** и русской локализации интерфейса в случае невозможности их установки встроенным Менеджером расширений

## Установка среды и расширений

- Скачайте редактор одним из способов:
  - Официальная страница загрузки: [Visual Studio Code](https://code.visualstudio.com/download)
  - Для Astra Linux Special Edition 1.8 доступен пакет из релиза проекта: [Astra-GIA](https://github.com/teanrus/astra-gia/releases/download/v2.0/code.deb)
- Установка скачанного пакета из терминала (рекомендуется):
  - перейдите в каталог с загруженным пакетом `code.deb`
  - нажмите ПКМ внутри каталога и выберите **Открыть в терминале**
  - выполните команду: `sudo apt install ./code.deb`
  - при запросе введите пароль пользователя и подтвердите установку
- Запустите среду один раз в сессии требуемого пользователя и сразу закройте
- Скачайте архив с расширениями: [extensions.tar.gz](https://github.com/teanrus/astra-gia/releases/download/v2.0/extensions.tar.gz)

```bash
wget https://github.com/teanrus/astra-gia/releases/download/v2.0/extensions.tar.gz
```

Распакуйте скачанный архив

```bash
tar -xzvf extensions.tar.gz
```

Скопируйте распакованный каталог `extensions/` в скрытый каталог `$HOME/.vscode/` Домашнего каталог пользователя с заменой содержимого или в Терминале, выполнив команду `cp -r /path/to/extensions/ ~/.vscode/`

```bash
sudo cp -r ~/Загрузки/scripts/extensions/ /home/std/.vscode/
```

> Для отображения скрытых каталогов в Домашнем каталоге пользователя нажмите комбинацию клавиш `Ctrl+H`

- Запустите **VS Code** повторно

### Настройка локализации интерфейса среды на русский язык

- Запустите **VS Code**
- Нажмите комбинацию клавиш `Ctrl+Shift+P`
- В строке для ввода начните вводить `display`
- Выберите в появившемся выводе опцию `Configure Display Language`
- В открывшемся списке языков выберите `русский (ru)`
- Среда предложить перезапуститься, согласитесь, нажав кнопку **Restart**, и дождитесь перезапуска программы
