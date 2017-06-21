#include <stdio.h>
#include <sys/time.h>
#include<math.h>

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
using namespace mdsip_test;


TestTree g_target_tree;

#define SEGMENT_SAMPLES 1000

int main(int argc, char *argv[])
{
    std::string program_name(argv[0]);
    struct timespec waitTime;
	struct timeval currTime;
	waitTime.tv_sec = 0;
    waitTime.tv_nsec = 5000000;
    
    if(argc > 1) g_target_tree = TestTree("stream", argv[1]);
    else {
        char *path = TestTree::GetEnvPath("stream");
        if(path) { g_target_tree = TestTree("stream",path); }
    }
    
    g_target_tree.SetClientType(TestTree::TC);    
    std::cout << "CONNECTING TARGET: "
              << TestTree::TreePath::toString(g_target_tree.Path()) << "\n";
          
    g_target_tree.Create();
    g_target_tree.AddNode("STREAM_0","SIGNAL");
    g_target_tree.AddNode("STREAM_1","SIGNAL");
    g_target_tree.CreatePulse(1);
    
    // Thin client write //
    try {
        std::string cnx_path = TestTree::TreePath::toString(g_target_tree.Path());
        MDSplus::Connection *cnx = new MDSplus::Connection((char *)cnx_path.c_str());
        cnx->openTree((char *)"stream",1);
        int64_t currTimeVal = 0;

        double  currRelTimeVal = 0;
        double  sample_time = 1E-6;
        float   currRelData[1000];
        int     currRelDataIndex = 0;

        while(true)
		{
            gettimeofday(&currTime, NULL);
			currTimeVal = currTime.tv_sec * 1E3 + currTime.tv_usec / 1E3;
            MDSplus::Int64 *currTimeValData = new MDSplus::Int64(currTimeVal);
			MDSplus::Float32 *floatData = new MDSplus::Float32(sin(currTimeVal/2E3));
            MDSplus::Data *args[2];
            args[0] = currTimeValData;
            args[1] = floatData;
            cnx->get("PutRow('STREAM_0',1000,$,$)",args,2);


            currRelData[currRelDataIndex] = sin(currTimeVal/2E3)+sin(currTimeVal/1E1)/10; //floatData->getFloat();
            ++currRelDataIndex %= 1000;
            if(currRelDataIndex == 0) {
                unique_ptr<MDSplus::Float32Array> currRelDataArray = new MDSplus::Float32Array(currRelData,1000);
                args[0] = currRelDataArray;
                // write to disk making segment into parse file
                unique_ptr<MDSplus::Range> range = new MDSplus::Range(new Float32(currRelTimeVal-1000*sample_time), new Float32(currRelTimeVal), new Float32(sample_time));
                char * begin = range->getBegin()->getString();
                char * end   = range->getEnding()->getString();
                char * delta = range->getDeltaVal()->getString();
                std::stringstream ss;
                // TDI: public fun MakeSegment(as_is _node, in _start, in _end,
                //          as_is _dim, in _array, optional _idx, in _rows_filled)
                ss << "MakeSegment("
                   << "STREAM_1" << ","
                   << begin << ","
                   << end << ","
                   << "make_range(" << begin << "," << end << "," << delta << ")" << ","
                   << "$1" << ",,"
                   << 1000 << ")";
                cnx->get(ss.str().c_str(),args,1);
            }
            currRelTimeVal += sample_time;

            MDSplus::deleteData(floatData);
            MDSplus::deleteData(currTimeValData);            
			nanosleep(&waitTime, NULL);
		}
    }
    
    catch(MDSplus::MdsException &exc)
	{
		std::cout << exc.what() << std::endl;
	}
	return 0;
}

