#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "dbuskkm.h"

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

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow), kkm(NULL), currentTable(NULL), codec(NULL), tableWidgetAccepted(false)
{
    ui->setupUi(this);

    QString service = "ru.shtrih_m.fr.kassa1";
    QString path = "/ru/shtrih_m/fr/kassa1/object";
    QString interface = "ru.shtrih_m.fr.kassa1.interface";
    kkmCharset = "CP1251";
    kkmPassword = 30;

    int tablesCount = 24;
    int error = 0;

    codec = QTextCodec::codecForName(kkmCharset.toStdString().c_str());
    kkm = new DBusKKM(service, path, interface);

    if(kkm->isValid())
    for(int tid = 1; tid <= tablesCount; ++tid)
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
