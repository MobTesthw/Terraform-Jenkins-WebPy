#!/bin/bash
#!/bin/bash

# Обновление пакетов
apt update
apt upgrade -y

# Установка Apache2
apt install apache2 -y

# Настройка веб-страницы
echo "<h1>Hello world from highly available group of ec2 instances</h1>" > /var/www/html/index.html

# Запуск и настройка автоматического запуска Apache2
systemctl start apache2
systemctl enable apache2

# Установка Python и pip
apt install python3 -y
apt install python3-pip -y

# Установка виртуального окружения (опционально)
pip3 install virtualenv

# Установка дополнительных пакетов (при необходимости)
# Например, установка необходимых библиотек для веб-приложения:
# pip3 install flask django

# Создание каталога для вашего Python проекта (опционально)
mkdir -p /var/www/my_python_app

# Пример создания виртуального окружения (опционально)
cd /var/www/my_python_app
virtualenv venv

# Активируем виртуальное окружение (опционально)
source venv/bin/activate

# Установка зависимостей Python проекта (если есть файл requirements.txt)
# Например:
# pip install -r requirements.txt

# Деактивируем виртуальное окружение
deactivate

# Примечание: На этом этапе вы можете скопировать или клонировать свой проект в /var/www/my_python_app
# и настроить его запуск как сервис, или с помощью gunicorn/uwsgi и Apache/Nginx.

# Скрипт завершен
