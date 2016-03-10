#include <mdsobjects.h>
#include <stdio.h>
#include <time.h>
#include <math.h>
#include <sys/time.h>
#include<math.h>

#define SEGMENT_SAMPLES 50000
#define NUM_SEGMENTS 1000
int main(int argc, char *argv[])
{
	int loopCount = 0;
	struct timespec waitTime;
	struct timeval currTime;
	waitTime.tv_sec = 0;
	waitTime.tv_nsec = 500000000;
    try {
		MDSplus::Tree *tree = new MDSplus::Tree("huge", -1, "NEW");
		MDSplus::TreeNode *node = tree->addNode("HUGE_0", "SIGNAL");
		delete node;
		tree->write();
		delete tree;
		tree = new MDSplus::Tree("huge", -1);
		tree->createPulse(1);
		delete tree;
		tree = new MDSplus::Tree("huge", 1);
		node = tree->getNode("HUGE_0");
		
		float *values = new float[SEGMENT_SAMPLES];
		double currTime = 0;
		double startTime, endTime;
		double deltaTime = 1;
		for(int i = 0; i < NUM_SEGMENTS; i++)
		{
			std::cout << "Writing Segment " << i << std::endl;
			startTime = currTime;
			for(int j = 0; j < SEGMENT_SAMPLES; j++)
			{
				values[j] = sin(currTime/1000.);
				currTime++;
			}
			endTime = currTime;
			MDSplus::Data *startData = new MDSplus::Float64(startTime);
			MDSplus::Data *endData = new MDSplus::Float64(endTime);
			MDSplus::Data *deltaData = new MDSplus::Float64(deltaTime);
			MDSplus::Data *dimData = new MDSplus::Range(startData, endData, deltaData);
			MDSplus::Array *valsData = new MDSplus::Float32Array(values, SEGMENT_SAMPLES);
			node->makeSegment(startData, endData, dimData, valsData);
			deleteData(dimData);
			deleteData(valsData);
		}
	} catch(MDSplus::MdsException &exc)
	{
		std::cout << exc.what() << std::endl;
	}
	return 0;
}
