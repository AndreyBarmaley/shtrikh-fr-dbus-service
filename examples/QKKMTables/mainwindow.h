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

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = 0);
    ~MainWindow();

protected:
    void applyTableChanges(void);
    void closeEvent(QCloseEvent *event);

private slots:
    void on_listWidget_itemClicked(QListWidgetItem *item);
    void on_tableWidget_cellChanged(int row, int column);

private:
    Ui::MainWindow *ui;
    DBusKKM* kkm;
    QListWidgetItem* currentTable;
    QTextCodec *codec;
    QString kkmCharset;
    int kkmPassword;
    bool tableWidgetAccepted;
    QList< QPair<int, int> > cellsChanged;
};

#endif // MAINWINDOW_H
