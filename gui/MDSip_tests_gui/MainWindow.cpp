#include "MainWindow.h"
#include "ui_MainWindow.h"
#include <vector>

#include <QList>

//#include "ClassUtils.h"
//#include "DataUtils.h"




//using namespace mdsip_test;

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);

//    mdsip_test::Accumulator<float> ac("test_acc");
       
    QList<QString> l;
    
    
}

MainWindow::~MainWindow()
{
    delete ui;
}
