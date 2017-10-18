
#include "TreeUtils.h"
#include "TestContent.h"

#include "testing-prototype.h"


using namespace mdsip_test;

int main()
{
    BEGIN_TESTING(Test Content);

//        ContentReader reader("test reader",10240);

//        TestTree src_tree("rfx","raserver.igi.cnr.it");
//        src_tree.SetClientType( TestTree::DC );
//        reader.SetTree(src_tree,37900);

//        Content::Element el;
//        while ( reader.GetNextElement(128,el) );

    const float array[2] = { 0, 1 };
    Content::Element el;
    el.data = new MDSplus::Float32Array(array,2);



    Content::Element &el_ref = el;
    Content::Element el2(el_ref);

//    std::cout << "el.data  = " << el.data.base() << "\n";
    TEST1_P( el.data == NULL );
    std::cout << "el2.data = " << el2.data.base() << "\n";

    END_TESTING;
}

