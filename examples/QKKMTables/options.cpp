#include "options.h"
#include "ui_options.h"

Options::Options(const settings_t & s, QWidget *parent) :
    QDialog(parent), ui(new Ui::Options), settings("dc.baikal.ru", "KKMTables")
{
    ui->setupUi(this);

    ui->lineEditDBusService->setText(settings.value("dbus service", s.dbusService).toString());
    ui->lineEditDBusPath->setText(settings.value("dbus path", s.dbusPath).toString());
    ui->lineEditDBusInterface->setText(settings.value("dbus interface", s.dbusInterface).toString());

    ui->lineEditKKMPassword->setText(QString::number(settings.value("kkm password", s.kkmPassword).toInt()));
    ui->lineEditKKMTablesCount->setText(QString::number(settings.value("kkm tables count", s.kkmTables).toInt()));
    ui->lineEditKKMCharset->setText(settings.value("kkm charset", s.kkmCharset).toString());
}

void Options::closeEvent(QCloseEvent *)
{
    settings.setValue("dbus service", ui->lineEditDBusService->text());
    settings.setValue("dbus interface", ui->lineEditDBusInterface->text());
    settings.setValue("dbus path", ui->lineEditDBusPath->text());

    settings.setValue("kkm password", ui->lineEditKKMPassword->text());
    settings.setValue("kkm tables count", ui->lineEditKKMTablesCount->text());
    settings.setValue("kkm charset", ui->lineEditKKMCharset->text());
}

settings_t Options::result(void) const
{
    settings_t s;

    s.dbusService = ui->lineEditDBusService->text();
    s.dbusInterface = ui->lineEditDBusInterface->text();
    s.dbusPath = ui->lineEditDBusPath->text();

    s.kkmPassword = ui->lineEditKKMPassword->text().toInt();
    s.kkmTables = ui->lineEditKKMTablesCount->text().toInt();
    s.kkmCharset = ui->lineEditKKMCharset->text();

    return s;
}
Options::~Options()
{
    delete ui;
}
