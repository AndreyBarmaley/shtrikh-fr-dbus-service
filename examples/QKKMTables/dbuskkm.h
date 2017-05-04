#ifndef DBUSKKM_H
#define DBUSKKM_H

#include <QtDBus/QtDBus>

class DBusKKM
{
public:
    DBusKKM(const QString &, const QString &, const QString &);

    bool isValid(void) const;
    QMap<QString, QString> call(const QString &, QList<QVariant> &, int* = NULL);

private:
    QDBusInterface dbusInterface;
    int pass;
};

#endif // DBUSKKM_H
