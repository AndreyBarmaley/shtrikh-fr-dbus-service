#include <QMap>
#include <QList>
#include <QVariant>
#include <QDebug>

#include "dbuskkm.h"

DBusKKM::DBusKKM(const QString & service, const QString & path, const QString & interface)
    : dbusInterface(service, path, interface, QDBusConnection::systemBus())
{
}

bool DBusKKM::isValid(void) const
{
    return dbusInterface.isValid();
}

QMap<QString, QString> DBusKKM::call(const QString & subroutine, QList<QVariant> & params, int* error_code)
{
    QMap<QString, QString> result;

    if(! dbusInterface.isValid())
        return result;

    QDBusMessage message = dbusInterface.callWithArgumentList(QDBus::CallMode::AutoDetect, subroutine, params);
    QList<QVariant> arguments = message.arguments();

    if(arguments.size())
    {
        QVariant first = arguments.at(0);
        QDBusArgument optionsArgument = first.value<QDBusArgument>();

        optionsArgument.beginMap();
        while(!optionsArgument.atEnd())
        {
            QPair<QString, QString> pair;
            optionsArgument >> pair;
            result.insert(pair.first, pair.second);
        }
    }

    int code = result.value("ERROR_CODE").toInt();
    if(error_code) *error_code = code;
    if(code) qWarning() << "Error message:" << result.value("ERROR_MESSAGE") << subroutine << params;

    return result;
}
