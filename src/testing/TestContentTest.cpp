
#include "TreeUtils.h"
#include "TestContent.h"

#include "testing-prototype.h"

using namespace mdsip_test;


int main()
{
    BEGIN_TESTING(Test Content);

        ContentReader reader("test reader",10240);

        TestTree src_tree("rfx","raserver.igi.cnr.it");
        src_tree.SetClientType( TestTree::DC );
        reader.SetTree(src_tree,37900);

        Content::Element el;
        while ( reader.GetNextElement(128,el) );


    END_TESTING;
}

