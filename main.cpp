

#include <iostream>

#include <mdsobjects.h>

#include "FileUtils.h"
#include "TreeUtils.h"

#include "TestContent.h"
#include "TestConnection.h"

using namespace MDSplus;


// TEST PER IMPARARE //

void write_test_tree()
{

    Tree * tree = TreeUtils::CreateTree("test_tree");

    tree->addNode("node1",(char *)"NUMERIC");
    tree->addNode("sub1",(char *)"STRUCTURE");

    tree->setDefault(tree->getNode("sub1"));
    tree->addNode("node11",(char *)"NUMERIC");

    tree->setDefault(tree->getNode("\\TEST_TREE::TOP"));
    tree->addNode("sub2",(char *)"STRUCTURE");
    tree->setDefault(tree->getNode("sub2"));
    tree->addNode("node21",(char *)"NUMERIC");

    //    tree->addDevice("demoADC1",(char *)"DEMOADC");

    tree->write();    

    tree->setDefault(tree->getNode("\\test_tree::TOP"));
    std::cout << TreeUtils::PreOrderVisitTree(tree) << "\n";

    {
        std::cout << " --- \n";
        TreeNodeArray *array = TreeUtils::PreOrderVisitTree(tree);
        for (int i=0; i<array->getNumNodes(); ++i) {
            TreeNode *node = array->operator [](i);
            std::cout << "path: " <<  node->getPath() << "\n";
            std::cout << "full: " <<  node->getFullPath() << "\n";
        }
    }

    {
        std::cout << " --- \n";
        tree->setDefault(tree->getNode("sub1"));
        TreeNodeArray *array = TreeUtils::PreOrderVisitTree(tree);
        for (int i=0; i<array->getNumNodes(); ++i) {
            TreeNode *node = array->operator [](i);
            std::cout << "path: " <<  node->getPath() << "\n";
            std::cout << "full: " <<  node->getFullPath() << "\n";
        }
    }

    delete tree;

    tree = new Tree("test_tree",-1);
    tree->createPulse(1);
    delete tree;

    tree = new Tree("test_tree",1);
    TreeNode *n = tree->getNode("\\TEST_TREE::TOP:NODE1");
    n->putData(new Int32( 5552368 ));
    delete tree;
}

void read_test_tree()
{
    //    Tree * tree = new Tree("test_tree",1);
    Tree * tree = TreeUtils::OpenTree("test_tree",1);

    // PERCHE NON VANNO MA SONO PERMESSI ? //
    //    std::cout << tree->getNode("node1")->getInt() << "\n";
    //    std::cout << tree->getNode("node1")->getString() << "\n";

    std::cout << "data: " << tree->getNode("node1")->getData()->getInt() << "\n";
    delete tree;
}

void write_segment() {
    Tree * tree = TreeUtils::OpenTree("test_tree",1);
    TreeNode *node = tree->getNode("node1");

    int len = 10;
    int data[len];
    for(int i=0; i<len; ++i ) data[i] = i;

    Int32Array *array = new Int32Array( data, len );
    Range *dim = new Range(new Float32(0.), new Float32(1.), new Float32(0.001));
    node->makeSegment(new Float32(0.), new Float32(1.), dim, array);
    node->makeSegment(new Float32(0.), new Float32(1.), dim, array);

    deleteData(array);
    deleteData(dim);
    delete tree;
}

void read_segment()  {
    Tree * tree = TreeUtils::OpenTree("test_tree",1);
    TreeNode *node = tree->getNode("node1");

    std::cout << "\n";
    std::cout << "number of segments: " << node->getNumSegments() << "\n";

    Array *ar1 = node->getSegment(0);
    std::cout << "array1 size: " << ar1->getSize() << "\n";

    Data *dim = node->getSegmentDim(0);
    std::cout << "dim: " << dim << "\n";
    std::cout << ar1 << "\n";

    std::cout << "---\n";

    // NOTE: [andrea] Ancora non funziona
    std::cout << tree->getNodeWild("\\TEST_TREE::TOP***",
                                   1 << TreeUSAGE_SIGNAL &
                                   1 << TreeUSAGE_NUMERIC &
                                   1 << TreeUSAGE_STRUCTURE
                                   )
              << "\n";
}



int main(int argc, char *argv[])
{

    ContentFunction cs1("test_c1");
    cs1.SetGenFunction(ContentFunction::NoiseW);

    ContentFunction cs2("test_c2");
    cs2.SetGenFunction(ContentFunction::NoiseG);

    ContentFunction cs3("test_c3");
    ContentFunction cs4("test_c4");

    ConnectionMT dc("test_tree");
    dc.SetConnectionSize(500); // 100MB;

    dc.AddContent(&cs1);
    dc.AddContent(&cs2);
    dc.AddContent(&cs3);
    dc.AddContent(&cs4);

    dc.AddChannel( Channel::NewDC(100) );
    dc.AddChannel( Channel::NewDC(100) );
    dc.AddChannel( Channel::NewDC(100) );
    dc.AddChannel( Channel::NewDC(100) );
    dc.AddChannel( Channel::NewDC(100) );
    dc.AddChannel( Channel::NewDC(100) );
    dc.AddChannel( Channel::NewDC(100) );
    dc.AddChannel( Channel::NewDC(100) );

//    dc.AddChannel( Channel::NewTC(10,"localhost:8000") );
//    dc.AddChannel( Channel::NewTC(20,"localhost:8000") );
//    dc.AddChannel( Channel::NewTC(50,"localhost:8000") );

    dc.StartConnection();

    return 0;
}









