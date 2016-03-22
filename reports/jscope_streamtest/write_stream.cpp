#include <mdsobjects.h>
#include <stdio.h>
#include <time.h>
#include <sys/time.h>
#include<math.h>

#define SEGMENT_SAMPLES 1000

int main(int argc, char *argv[])
{
	struct timespec waitTime;
	struct timeval currTime;
	waitTime.tv_sec = 0;
	waitTime.tv_nsec = 50000000;
    try {
		MDSplus::Tree *tree = new MDSplus::Tree("stream", -1, "NEW");
		MDSplus::TreeNode *node = tree->addNode("STREAM_0", "SIGNAL");
		delete node;
		tree->write();
		delete tree;
		tree = new MDSplus::Tree("stream", -1);
		tree->createPulse(1);
		delete tree;
		tree = new MDSplus::Tree("stream", 1);
		node = tree->getNode("STREAM_0");

        
        int64_t currTimeVal = 0;
        while(true)
		{
            gettimeofday(&currTime, NULL);
			currTimeVal = currTime.tv_sec * 1E3 + currTime.tv_usec / 1E3;
			MDSplus::Float32 *floatData = new MDSplus::Float32(sin(currTimeVal/2E3));
			node->putRow(floatData, &currTimeVal);
			MDSplus::deleteData(floatData);
			nanosleep(&waitTime, NULL);
		}
	} catch(MDSplus::MdsException &exc)
	{
		std::cout << exc.what() << std::endl;
	}
	return 0;
}

