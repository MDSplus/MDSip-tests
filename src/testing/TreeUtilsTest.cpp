
#include "ClassUtils.h"
#include "TreeUtils.h"
#include "testing-prototype.h"


namespace mds = MDSplus;





int main(int argc, char *argv[])
{
    BEGIN_TESTING(Tree Utils);


    { // TEST STRING PARSING //
        TestTree::TreeName tn;

        tn = "my_path";
        TEST1( tn.name == "my_path" );
        TEST1( tn.server == "" );
        std::cout << tn << "\n";

        tn = "server::my_path";
        TEST1( tn.name == "my_path" );
        TEST1( tn.server == "server" );
        TEST1( tn.port == "" );
        TEST1( tn.protocol == "" );
        std::cout << tn << "\n";

        tn = "server:8000::my_path";
        TEST1( tn.name == "my_path" );
        TEST1( tn.server == "server" );
        TEST1( tn.port == "8000" );
        TEST1( tn.protocol == "" );
        std::cout << tn << "\n";

        tn = "tcp://server:8000::my_path";
        TEST1( tn.name == "my_path" );
        TEST1( tn.server == "server" );
        TEST1( tn.port == "8000" );
        TEST1( tn.protocol == "tcp" );
        std::cout << tn << "\n";

        tn = "tcp://server::my_path";
        TEST1( tn.name == "my_path" );
        TEST1( tn.server == "server" );
        TEST1( tn.port == "" );
        TEST1( tn.protocol == "tcp" );
        std::cout << tn << "\n";
    }

    {
        // CREATE AND POPULATE TREE //

        TestTree tree("testing_tree");
        FileUtils::CreateDir("testing_tree");
        tree.Create();

        {
            unique_ptr<mds::Tree> mdst = tree.Edit();
            mdst->addNode("sig1","SIGNAL");
        }

    }



    END_TESTING;
}

