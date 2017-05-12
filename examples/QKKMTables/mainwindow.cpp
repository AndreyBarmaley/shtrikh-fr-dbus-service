#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "dbuskkm.h"
#include "options.h"

#include <QMap>
#include <QList>
#include <QVariant>
#include <QRegExp>
#include <QListWidgetItem>
#include <QTableWidgetItem>
#include <QDataStream>
#include <QTextCodec>
#include <QMessageBox>

#include <QDebug>
#define VERSION 20170502

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow), kkm(NULL), currentTable(NULL), codec(NULL), tableWidgetAccepted(false)
{
    ui->setupUi(this);
    setWindowTitle(QString("KKM Tables, version: ").append(QString::number(VERSION)));

    readSettings();

    int error = 0;
    codec = QTextCodec::codecForName(kkmCharset.toStdString().c_str());

    while(1)
    {
        kkm = new DBusKKM(dbusService, dbusPath, dbusInterface);
        if(kkm->isValid()) break;
        if(showOptions() == QDialog::Rejected) break;
    }

    for(int tid = 1; tid <= kkmTables; ++tid)
    {
        auto tableMap = kkm->call("device_get_structure_table", QList<QVariant>() << kkmPassword << tid, &error);
        if(error) break;

        QListWidgetItem* item = new QListWidgetItem(QString::number(tid).append(". ").append(tableMap.value("TABLE_NAME")));
        item->setData(Qt::UserRole, QVariant(tid));

        ui->listWidget->addItem(item);
    }
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::readSettings(void)
{
    QSettings settings("dc.baikal.ru", "KKMTables");

    dbusService = settings.value("dbus service", dbusService).toString();
    dbusPath = settings.value("dbus path", dbusPath).toString();
    dbusInterface = settings.value("dbus interface", dbusInterface).toString();

    kkmPassword = settings.value("kkm password", kkmPassword).toInt();
    kkmTables = settings.value("kkm tables count", kkmTables).toInt();
    kkmCharset = settings.value("kkm charset", kkmCharset).toString();
}

void MainWindow::applyTableChanges(void)
{
    int tid = currentTable->data(Qt::UserRole).toInt();

    for(auto it = cellsChanged.begin(); it != cellsChanged.end(); ++it)
    {
        int error = 0;
        int row = (*it).first;
        int column = (*it).second;

        QTableWidgetItem* item = ui->tableWidget->item(row, column);
        if(! item) break;

        auto tableMap = kkm->call("device_get_structure_table", QList<QVariant>() << kkmPassword << tid, &error);
        if(error) break;

        int fid = row + 1;
        auto fieldMap = kkm->call("device_get_structure_field", QList<QVariant>() << kkmPassword << tid << fid, &error);
        if(error) break;

        QString fieldType = fieldMap.value("FIELD_TYPE");
        int fieldSize = fieldMap.value("FIELD_SIZE").toInt();
        int cid = column + 1;

        QByteArray array(fieldSize, 0);

        // reset record
        kkm->call("device_set_write_table", QList<QVariant>() << kkmPassword << tid << cid << fid << array, &error);
        if(error) break;

        // write record
        QDataStream ds(&array, QIODevice::WriteOnly);

        if(fieldType == "BIN")
        {
            ds.setByteOrder(QDataStream::LittleEndian);
            int value = item->text().toInt();

            switch(fieldSize)
            {
            case 1:
            {
                ds << (quint8) value;
                break;
            }

            case 2:
            {
                ds << (quint16) value;
                break;
            }

            case 4:
            {
                ds << (quint32) value;
                break;
            }

            default:
                qDebug() << "unknown binary width type:" << fieldSize;
            }
        }
        else
        if(fieldType == "CHAR" && codec)
        {
            QByteArray ba = codec->fromUnicode(item->text());
            ds.writeRawData(ba.data(), ba.size());
        }
        else
            array.clear();

        if(array.size())
            kkm->call("device_set_write_table", QList<QVariant>() << kkmPassword << tid << cid << fid << array, &error);
    }
}

void MainWindow::on_listWidget_itemClicked(QListWidgetItem *item)
{
    if(cellsChanged.size())
    {
        int ret = QMessageBox::warning(this, tr("KKM Tables"), tr("The table has been modified.\nDo you want to apply your changes?"),
                                       QMessageBox::Apply | QMessageBox::Discard);
        if(ret == QMessageBox::Apply)
            applyTableChanges();

        cellsChanged.clear();
    }

    int error = 0;
    int tid = item->data(Qt::UserRole).toInt();
    auto tableMap = kkm->call("device_get_structure_table", QList<QVariant>() << kkmPassword << tid, &error);
    if(error) return;

    int columns = tableMap.value("COLUMN_COUNT").toInt();
    int fields = tableMap.value("FIELD_COUNT").toInt();

    QStringList fieldsName;

    currentTable = item;

    ui->tableWidget->setColumnCount(columns);
    ui->tableWidget->setRowCount(fields);

    tableWidgetAccepted = false;

    for(int fid = 1; fid <= fields; ++fid)
    {
        auto fieldMap = kkm->call("device_get_structure_field", QList<QVariant>() << kkmPassword << tid << fid, &error);
        if(error) break;

        fieldsName << fieldMap.value("FIELD_NAME");

        for(int cid = 1; cid <= columns; ++cid)
        {
            auto valueMap = kkm->call("device_get_read_table", QList<QVariant>() << kkmPassword << tid << cid << fid, &error);
            if(error) break;

            QString fieldType = fieldMap.value("FIELD_TYPE");
            QString valueHex = valueMap.value("VALUE");
            valueHex.remove(QRegExp("0x"));
            valueHex.remove(QRegExp(",\\s+"));
            QByteArray arr = QByteArray::fromHex(valueHex.toLatin1());
            QTextCodec *codec = QTextCodec::codecForName(kkmCharset.toStdString().c_str());
            QTableWidgetItem* item = NULL;

            if(fieldType == "CHAR" && codec)
            {
                QString str = codec->toUnicode(arr.toStdString().c_str());
                item = new QTableWidgetItem(str);
            }
            else
            if(fieldType == "BIN")
            {
                int fieldSize = fieldMap.value("FIELD_SIZE").toInt();
                QDataStream ds(arr);
                ds.setByteOrder(QDataStream::LittleEndian);
                int value = 0;

                switch(fieldSize)
                {
                case 1:
                {
                    quint8 v;
                    ds >> v;
                    value = v;
                    break;
                }

                case 2:
                {
                    quint16 v;
                    ds >> v;
                    value = v;
                    break;
                }

                case 4:
                {
                    quint32 v;
                    ds >> v;
                    value = v;
                    break;
                }

                default:
                    qDebug() << "unknown binary width type:" << fieldSize;
                }

                item = new QTableWidgetItem(QString::number(value));
            }

            if(item) ui->tableWidget->setItem(fid - 1, cid - 1, item);
        }
    }

    ui->tableWidget->setVerticalHeaderLabels(fieldsName);
    tableWidgetAccepted = true;
}

void MainWindow::on_tableWidget_cellChanged(int row, int column)
{
    if(tableWidgetAccepted)
    {
        cellsChanged << QPair<int, int>(row, column);
    }
}

int MainWindow::showOptions(void)
{
    Options dialog(*this, this);
    int result = dialog.exec();

    if(result == QDialog::Accepted)
    {
        const settings_t & s = dialog.result();

        dbusService = s.dbusService;
        dbusInterface = s.dbusInterface;
        dbusPath = s.dbusPath;

        kkmPassword = s.kkmPassword;
        kkmTables = s.kkmTables;
        kkmCharset = s.kkmCharset;
    }
    return result;
}

void MainWindow::on_menuOptions_show(void)
{
    showOptions();
}

void MainWindow::closeEvent(QCloseEvent*)
{
    if(cellsChanged.size())
    {
        int ret = QMessageBox::warning(this, tr("KKM Tables"), tr("The table has been modified.\nDo you want to apply your changes?"),
                                       QMessageBox::Apply | QMessageBox::Discard);
        if(ret == QMessageBox::Apply)
            applyTableChanges();

        cellsChanged.clear();
    }
}
