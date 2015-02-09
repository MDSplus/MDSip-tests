

#include <iostream>
#include <fstream>
#include <time.h>

#include <mdsobjects.h>


#include "FileUtils.h"
#include "TreeUtils.h"

#include "TestContent.h"
#include "TestConnection.h"

#include "DataUtils.h"


using namespace MDSplus;





////////////////////////////////////////////////////////////////////////////////
//  TEST: SEGMENT SIZE  ////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


int segment_size_testMP(size_t size_KB, Histogram<double> &speed, int nch = 1, size_t tot_size = 1024) {

    //    static const int tot_size = 1024; // KB

    std::vector<ContentFunction *> functions;
    std::vector<Channel *>         channels;

    TestConnectionMP conn("test_size");
    for(int i=0; i<nch; ++i) {
        std::stringstream name;
        name << "sine" << i;
        functions.push_back( new ContentFunction(name.str().c_str(),tot_size) );
        channels.push_back( Channel::NewTC(size_KB,"localhost:8000") );
        conn.AddChannel(functions[i],channels[i]);
    }

    for(int i=0; i<10; ++i) {
        std::cout << "connecting: -> " << std::flush;


        for(unsigned int i=0; i<functions.size(); ++i)
            functions[i]->ResetSize(tot_size);

        conn.ResetTimes();

        speed << ((double)tot_size) / 1024 / conn.StartConnection() * nch;
        // conn.StartConnection();
        // speed << ((double)tot_size)/1024 / conn.GetTotalTime();
    }

    std::cout << "--- connection segment size: " << size_KB << " [KB] ";
    std::cout  << speed << "\n";
    std::cout << "speed [MB/s] | Mean: " << speed.MeanAll() << " Rms: " << speed.RmsAll() <<  "\n\n";

    for(unsigned int i=0; i<channels.size(); ++i) {
        delete channels[i];
        delete functions[i];
    }


    return 0;
}






int main(int argc, char *argv[])
{
    static const int n_channels = 4;
    static const int seg_step   = 32;
    static const int seg_max    = 1024;

    std::vector<Curve2D> speeds;
    std::vector<Curve2D> speed_errors;

    for(int nch = 1; nch <= n_channels; nch++ )
    {
        std::stringstream curve_name;
        curve_name << "ch" << nch;
        speeds.push_back(Curve2D(curve_name.str().c_str()));
        curve_name << "_err";
        speed_errors.push_back(Curve2D(curve_name.str().c_str()));
        for(unsigned int sid = 0; sid < seg_max/seg_step; ++sid )
        {
            unsigned int seg_size = seg_step*(sid+1);
            Histogram<double> sph("test_segment_size",40,0,2);
            segment_size_testMP(seg_size,sph,nch);

            Curve2D &speed = speeds.back();
            Curve2D &speed_error = speed_errors.back();

            Point2D<double> pt;
            pt << seg_size,sph.MeanAll();
            speed.AddPoint(pt);
            pt << seg_size,sph.RmsAll();
            speed_error.AddPoint(pt);
        }
    }

    std::ofstream file;
    file.open("test_segment_size.csv");
    static const char sep = ';';

    std::cout << " ---- COLLECTED SPEEDS  ------ \n";
    file << "segment size";
    for(unsigned int nch=0; nch<n_channels; ++nch)
    {
        Curve2D &speed = speeds[nch];
        Curve2D &speed_error = speed_errors[nch];

        std::cout << speed << "\n";
        file << sep << speed.GetName() << sep << speed_error.GetName();
    }
    file << std::endl;

    for(unsigned int sid = 0; sid < seg_max/seg_step; ++sid )
    {
        unsigned int seg_size = seg_step*(sid+1);
        file << seg_size;
        for(unsigned int nch=0; nch<n_channels; ++nch ) {
            Curve2D &speed = speeds[nch];
            Curve2D &speed_error = speed_errors[nch];
            file << sep << speed[sid](1) << sep << speed_error[sid](1);
        }
        file << std::endl;
    }

    file.close();

    return 0;
}







////////////////////////////////////////////////////////////////////////////////
//  TEST SERIALIZATION  ////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////





struct MyObj {
    int i;
    float f;
    std::string str;
};


template < class Archive >
void  serialize(Archive &ar, MyObj &obj) {
    ar & obj.f & obj.i/* & obj.str*/;
}



struct MyOb2 {
    MyObj ob1,ob2;
};

template < class Archive >
void  serialize(Archive &ar, MyOb2 &obj) {
    ar & obj.ob1 & obj.ob2;
}




int _main(int argc, char *argv[])
{
    SerializeToBin ser;

    MyObj ob;
    ob.i = 5552368;
    ob.f = 5.55;
    ob.str = "ciao";

    ser.Write() & ob;

    ob.i = 123;
    ob.f = 12;
    ob.str = "no";

    ser.Read() & ob;

    std::cout << ob.f << " " << ob.i << " " << ob.str << "\n";



    MyOb2 ob2;



    return 0;
}


























