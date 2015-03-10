

#include "DataUtils.h"
#include "FileUtils.h"

#include "testing-prototype.h"





int main(int argc, char *argv[])
{

    float f = 0;
    Vector3f fv(1,2,3);
    std::vector<float> vv;

    std::string str = "default";

    vv << (float)555,23,68;

    Options opt;

    opt.AddOptions()
            ("effe", &f, "")
            ("f_v",&fv,"test tuple")
            ("vv",&vv,"test vector")
            ("string",&str,"test string")
            ;

    opt.Parse(argc,argv);


    std::cout << "f = " << f << "\n";
    std::cout << "f_v = " << fv << "\n";
    std::cout << "vv = " << vv << "\n";
    std::cout << "str = " << str << "\n";

    return 0;
}

