

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


/// \param size_KB size of segment to be sent
/// \param speed a reference to histogram to collect speed
/// \param nch number of forked channels (sine) to be used
/// \param tot_size total size per channel to be sent
/// \return 0
///
/// Test for segment size in Multi Process using Thin Client connection.
/// In histogram a value of equivalent data troughput is added in MB/s
/// This is not the actual line speed becouse reflects the time to sent actual
/// data into the channel.
///
int segment_size_testMP(size_t size_KB,
                        Histogram<double> &speed,
                        int nch = 1,
                        size_t tot_size = 1024)
{
    std::vector<ContentFunction *> functions; // function generators //
    std::vector<Channel *>         channels;  // forked channels //

    TestConnectionMP conn("test_size");

    for(int i=0; i<nch; ++i) {
        std::stringstream name;
        name << "sine" << i;
        functions.push_back( new ContentFunction(name.str().c_str(),tot_size) );
        // << FIX: server name is hard coded !
        channels.push_back( Channel::NewTC(size_KB,"localhost:8000") );
        conn.AddChannel(functions[i],channels[i]);
    }

    for(int i=0; i<10; ++i) {
        std::cout << "connecting: -> " << std::flush;


        for(unsigned int i=0; i<functions.size(); ++i)
            functions[i]->ResetSize(tot_size); // reset time of generator //
        conn.ResetTimes();             // reset per channel distributions //

        // speed is total size in MB [tot_size/1024] multiplied per number of
        // channels (as each channel send tot_size data) and divided  by  the
        // total connection time.
        speed << ((double)tot_size) / 1024 / conn.StartConnection() * nch;

        //        conn.StartConnection();
        //        Channel *ch = channels[0];
        //        TestConnection::TimeHistogram &h = conn.GetChannelTimes(ch);
        //        std::cout << "----> " << h << "\n";
        //        speed << ((double)tot_size)/ 1024 / conn.GetTotalTime() * nch;
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
    static const int seg_step   = 3200;
    static const int seg_max    = 102400;

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
            Histogram<double> sph("test_segment_size",40,0,30);
            segment_size_testMP(seg_size,sph,nch,102400);

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
    float i;
    float f[2];
    Point2D<float> p;
    std::string str;
    MyObj *next;

    MyObj() : next(0) {}

    friend std::ostream &
    operator << (std::ostream &o, const MyObj &ob) {
        o << "i:" << ob.i << " "
          << "f[0]:" << ob.f[0] << " "
          << "f[1]:" << ob.f[1] << " "
          << "p:" << ob.p << " "
          << "str:" << ob.str << " "
          << "next:" << ob.next << "\n";
        return o;
    }

};

template < class Archive >
void  serialize(Archive &ar, MyObj &ob) {
    ar & ob.i;
    ar & ob.f;
    ar & ob.p;
    ar & ob.str;
    ar & ob.next;
}


int test_ser(int argc, char *argv[])
{

    {

        MyObj ob;
        ob.i = 368;
        ob.f[0] = 1.23;
        ob.f[1] = 4.56;
        ob.p << 55,2368;
        ob.str = "ciao";

        MyObj ob2 = ob;
        ob.next = &ob2;
        ob2.str = "ciao2";


        SerializeToBin sr;
        sr.Write() & ob;


        sr.Store();

        ob.i = 0;
        ob.f[0] = 0;
        ob.f[1] = 0;
        ob.p << 0,0;
        ob.str = "no";

        ob2.i = 0;
        ob2.f[0] = 0;
        ob2.f[1] = 0;
        ob2.p << 0,0;
        ob2.str = "no";

        sr.Read() & ob;

        std::cout << ob << "\n";
        std::cout << ob2 << "\n";

    }



    return 0;
}


int test_histogram_serialization()
{
    Histogram<float> h("test",40,0,10);
    for (int i=0; i<100000; ++i) {
        float data = box_muller(0) + 5;
        h << data;
    }

    SerializeToBin sr;
    sr.Write() & h;
    sr.Store();


    h.Clear();
    h << 5 << 6 << 7;
    //    h.SetName("error");

    sr.Clear();
    sr.Write() & h;
    sr.Store();

    h.Clear();

    sr.Read() & h;
    std::cout << h.GetName() << " " << h << "\n";

    return 0;
}




int test_shm_serialize(int argc, char *argv[])
{
    Histogram<float> h("test",40,0,10);
    for (int i=0; i<100000; ++i) {
        float data = box_muller(0) + 5;
        h << data;
    }

    SerializeToShm sr;
    sr.Write() & h;
    sr.Store();

    h.Clear();
    h.SetName("error");

    sr.Read() & h;
    std::cout << h.GetName() << " " << h << "\n";

    return 0;
}






















