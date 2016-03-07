#include <mdsobjects.h>
#include <stdio.h>
#include <time.h>
#include <sys/time.h>
#include<math.h>

#define SEGMENT_SAMPLES 1000

int main(int argc, char *argv[])
{
	int loopCount = 0;
	struct timespec waitTime;
	struct timeval currTime;
	waitTime.tv_sec = 0;
	waitTime.tv_nsec = 500000000;
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
		while(true)
		{
			MDSplus::Float32 *floatData = new MDSplus::Float32(sin(loopCount/5.));
			int64_t currTimeVal = 0;
			gettimeofday(&currTime, NULL);
			currTimeVal = currTime.tv_sec * 1000L;
			currTimeVal += currTime.tv_usec/1000;
			node->putRow(floatData, &currTimeVal);
			MDSplus::deleteData(floatData);
			loopCount++;
			nanosleep(&waitTime, NULL);
		}
	} catch(MDSplus::MdsException &exc)
	{
		std::cout << exc.what() << std::endl;
	}
	return 0;
}

