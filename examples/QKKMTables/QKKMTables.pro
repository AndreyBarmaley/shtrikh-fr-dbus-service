#-------------------------------------------------
#
# Project created by QtCreator 2017-04-28T11:25:22
#
#-------------------------------------------------

QT       += core gui dbus
*-g++*:QMAKE_CXXFLAGS += -std=c++0x

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = QKKMTables
TEMPLATE = app


SOURCES += main.cpp\
        mainwindow.cpp \
    dbuskkm.cpp

HEADERS  += mainwindow.h \
    dbuskkm.h

FORMS    += mainwindow.ui
