# shrikh-fr-dbus-service
dbus service for cash register (ShtrikhFR)

Драйвер для ККМ аппаратов серии Штрих. Сделан в виде сервиса DBus.
Преимущество - работает в любых тулкитах биндинг на DBus (bash, javascript, c++, perl, python и.т.д), можно расшарить через сеть. В драйвере реализован протокол Штрих 1.12 (+добавлена несколько новых команд из нового протокола 2.0.24, открыть смету и.т.д.). Есть пример чтения/записи таблиц на Qt.

Установка:
- скопировать shtrikh-fr-dbus-service например в /opt
- установить в систему дополнительные модули для Perl - Device::SerialPort, Time::HiRes, Math::BigInt, Unix::Syslog, Net::DBus
- в файле /etc/dbus-1/system.conf определить сервисную директорию /etc/dbus-1/system-services
   <standard_system_servicedirs/>
   <servicedir>/etc/dbus-1/system-services</servicedir>
- в файле ru.shtrih_m.fr.service исправить путь до исполняемого файла shtrih_fr.service, поправить права на запуск, также User=XXXX должен быть реальным пользователем системы которые имеет доступ чтения и записи в порты ttyS*,ttyUSB* 
- файл ru.shtrih_m.fr.conf скопировать в директорию /etc/dbus-1/system.d
- файл ru.shtrih_m.fr.service скопировать в сервисную директорию /etc/dbus-1/system-services
- в зависисмости от версии DBus он либо сам перечитает все свои конфиги либо надо будет перезапустить службу DBus
- запустить команду на получение статуса ККМ examples/get_status.sh
