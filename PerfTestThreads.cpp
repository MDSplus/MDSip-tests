#include <iostream>

#include <mdsobjects.h>
#include <sys/time.h>

using namespace MDSplus;
#define MAX_THREADS 100

struct TestInfo {
    TreeNode *node;
    int sigSize;
    int blockSize;
}infos[MAX_THREADS];

void writeSignal(TreeNode *node, int sigSize, int blockSize)
{
    int numBlocks = 1000*sigSize/blockSize;
    blockSize *= 1000;
    float *dataArr = new float[blockSize];
    for(int i = 0; i < blockSize; i++)
	dataArr[i] = i;

    for(int segIdx = 0; segIdx < numBlocks; segIdx++)
    {
    	Array *data = new Float32Array(dataArr, blockSize);
    	Data *dim = new Range(new Float32(segIdx*blockSize), new Float32(segIdx*blockSize + blockSize - 1), new Float32(1.));
	Data *start = new Float32(segIdx*blockSize);
	Data *end = new Float32(segIdx*blockSize + blockSize - 1);
 	try {    
	    node->makeSegment(start, end, dim, data);
	} catch(MdsException *exc)
	{
        std::cout << "Error writing data: " << exc->what() << std::endl;
	}
	deleteData(dim);
	deleteData(start);
	deleteData(end);
	deleteData(data);
    }
}

static void *handleChan(void *infoPtr)
{
    struct TestInfo *info = (struct TestInfo *)infoPtr;
    writeSignal(info->node, info->sigSize, info->blockSize);
    pthread_exit(infoPtr);
}


int main(int argc, char *argv[])
{
    if(argc != 4)
    {
	printf("Usage: PerfTestThreads <DataSize (MB)> <NumThreads> <Block Size (KB)>\n");
	exit(0);
    }
    int dataSize, dataSizeInFloats, numThreads, blockSize, blockSizeInFloats;
    sscanf(argv[1], "%d", &dataSize);
    dataSizeInFloats = dataSize/sizeof(float);
    sscanf(argv[2], "%d", &numThreads);
    sscanf(argv[3], "%d", &blockSize);
    blockSizeInFloats = blockSize/sizeof(float);

    char nodeName[64];
    try {
	Tree *model = new Tree((char *)"test", -1);
	model->createPulse(1);
	Tree *tree = new Tree((char *)"test", 1);
	for(int nodeIdx = 0; nodeIdx < numThreads; nodeIdx++)
	{
	    sprintf(nodeName, "SIG%d:DATA", nodeIdx);
//	    sprintf(nodeName, "SUB%d:DATA", nodeIdx+1);
	    infos[nodeIdx].node = tree->getNode(nodeName);
   	    //infos[nodeIdx].node->setCompressOnPut(true);
	    infos[nodeIdx].sigSize = dataSizeInFloats / numThreads;
	    infos[nodeIdx].blockSize = blockSizeInFloats;
	}
    } catch(MdsException *exc)
    {
    std::cout << "Error getting node: " << exc->what() << std::endl;
	exit(0);
    }

    pthread_t threads[MAX_THREADS];
    struct timeval startTime, endTime;

    gettimeofday(&startTime, NULL);

    int threadIdx;
    for(threadIdx = 0; threadIdx < numThreads; threadIdx++)
     	pthread_create(&threads[threadIdx], NULL, handleChan, (void *)&infos[threadIdx]);
    void *retval;	
    for(threadIdx = 0; threadIdx < numThreads; threadIdx++)
    	pthread_join(threads[threadIdx], &retval);
     gettimeofday(&endTime, NULL);
 	
    double timeSec = endTime.tv_sec - startTime.tv_sec + (endTime.tv_usec - startTime.tv_usec)*1E-6;
    std::cout << "Execution time(sec): " << timeSec << std::endl;
    std::cout << "Throughput (MB/s): " << (int)(dataSize/timeSec) << std::endl;
}
	 

