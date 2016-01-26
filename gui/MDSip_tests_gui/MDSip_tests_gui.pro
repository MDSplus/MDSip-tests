#-------------------------------------------------
#
# Project created by QtCreator 2016-01-20T15:15:07
#
#-------------------------------------------------

QT       += core gui
greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = MDSip_tests_gui
TEMPLATE = app


SOURCES += main.cpp\
        MainWindow.cpp

HEADERS  += MainWindow.h

FORMS    += MainWindow.ui




## include build of MDSip library ##

#mytarget.commands = make -C ../../build/
#QMAKE_EXTRA_TARGETS += mytarget
#PRE_TARGETDEPS += mytarget
#LIBS += -L../../build/.libs -lMDSipTest
#INCLUDEPATH += $$PWD/../../src
