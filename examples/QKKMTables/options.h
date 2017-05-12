#ifndef OPTIONS_H
#define OPTIONS_H

#include <QDialog>
#include <QSettings>

#include "mainwindow.h"

namespace Ui {
class Options;
}

class Options : public QDialog
{
    Q_OBJECT

public:
    explicit Options(const settings_t &, QWidget *parent = 0);
    ~Options();

    settings_t result(void) const;

protected:
    void closeEvent(QCloseEvent *);

private:
    Ui::Options *ui;
    QSettings settings;
};

#endif // OPTIONS_H
