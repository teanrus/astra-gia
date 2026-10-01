#!/bin/bash
echo "==============================================================================="
echo "Активация репозиториев в ALSE 1.8 для установки стороннего софта и зависимостей"
echo "==============================================================================="
echo "1 - Ветка Frozen для 1.8.4.48 (Рекомендуется для АРМ ГИА-11 в ППЭ)"
echo "2 - Ветка Stable для 1.8 (Получение оперативных обновлений ОС)"
echo -n "Укажите числовое значение: "
read NUMBER

if [[ $NUMBER == "1" ]];then
    echo "deb [arch=amd64] https://download.astralinux.ru/astra/frozen/1.8_x86-64/1.8.4/repository-extended/ 1.8_x86-64 main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list
    echo "deb [arch=amd64] https://download.astralinux.ru/astra/frozen/1.8_x86-64/1.8.4/repository-main/ 1.8_x86-64 main contrib non-free non-free-firmware" | sudo tee -a /etc/apt/sources.list
    sudo apt update
    echo "Операции завершены! Закройте терминал..."
else if [[ $NUMBER == "2" ]];then
    echo "deb [arch=amd64] https://download.astralinux.ru/astra/stable/1.8_x86-64/repository-extended/ 1.8_x86-64 main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list
    echo "deb [arch=amd64] https://download.astralinux.ru/astra/stable/1.8_x86-64/repository-main/ 1.8_x86-64 main contrib non-free non-free-firmware" | sudo tee -a /etc/apt/sources.list
    sudo apt update
    echo "========================================"
    echo "Операции завершены! Закройте терминал..."
    echo "========================================"
else
    echo "======================"
    echo "Действие отсуствует..."
    echo "======================"
fi
fi
exit 0
