#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include "dbuskkm.h"

namespace Ui {
class MainWindow;
}

QT_BEGIN_NAMESPACE
class QListWidgetItem;
QT_END_NAMESPACE

struct settings_t
{
    QString dbusService;
    QString dbusPath;
    QString dbusInterface;
    QString kkmCharset;
    int kkmPassword;
    int kkmTables;

    settings_t() :
        dbusService("ru.shtrih_m.fr.kassa1"),
        dbusPath("/ru/shtrih_m/fr/kassa1/object"),
        dbusInterface("ru.shtrih_m.fr.kassa1.interface"),
        kkmCharset("CP1251"), kkmPassword(30), kkmTables(24) {}
};

class MainWindow : public QMainWindow, protected settings_t
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = 0);
    ~MainWindow();

protected:
    int showOptions(void);
    void readSettings(void);
    void applyTableChanges(void);
    void closeEvent(QCloseEvent *event);

private slots:
    void on_listWidget_itemClicked(QListWidgetItem *item);
    void on_tableWidget_cellChanged(int row, int column);
    void on_menuOptions_show(void);

    void on_pushButtonGetDeviceStatus_clicked();

private:
    Ui::MainWindow *ui;
    DBusKKM* kkm;
    QListWidgetItem* currentTable;
    QTextCodec *codec;
    bool tableWidgetAccepted;
    QList< QPair<int, int> > cellsChanged;
};

#endif // MAINWINDOW_H
