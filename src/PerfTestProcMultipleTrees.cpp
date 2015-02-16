#include <iostream>

#include <string.h>
#include <unistd.h>

#include <sys/time.h>
#include <sys/ipc.h>
#include <sys/wait.h>

#include <mdsobjects.h>

using namespace MDSplus;
#define MAX_THREADS 100
#define SLEEP_TIME 10
struct TestInfo {
    int shot;
    char nodeName[256];
    int sigSize;
    int blockSize;
}infos[MAX_THREADS];

pid_t pids[MAX_THREADS];


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
        // 	try {
        node->makeSegment(start, end, dim, data);
        //	} catch(MdsException *exc)
        //	{
        //	    std::cout<< "Error writing data: " << exc->what() << std::endl;
        //	}
        deleteData(dim);
        deleteData(start);
        deleteData(end);
        deleteData(data);
    }
}

static void *handleChan(void *infoPtr)
{
    struct TestInfo *info = (struct TestInfo *)infoPtr;
    TreeNode *node;
    try {
        Tree *tree = new Tree((char *)"test", info->shot);
        node = tree->getNode(info->nodeName);
    } catch(MdsException *exc)
    {
        std::cout<< "Error Opening tree: " << exc->what() << std::endl;
        exit(0);
    }
    sleep(SLEEP_TIME);
    try {
        //node->setCompressOnPut(false);
        writeSignal(node, info->sigSize, info->blockSize);
    } catch(MdsException *exc)
    {
        std::cout<< "Error writing channel " << info->nodeName << " : " << exc->what() << std::endl;
    }
    //pthread_exit(infoPtr);
}


int main(int argc, char *argv[])
{
    if(argc != 4)
    {
        printf("Usage: PerfTestProc <DataSize (MB)> <NumThreads> <Block Size (KB)>\n");
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
        //Tree *model = new Tree((char *)"test", -1);
        //model->createPulse(1);
        for(int nodeIdx = 0; nodeIdx < numThreads; nodeIdx++)
        {
            //	    sprintf(nodeName, "SUB%d:DATA", nodeIdx+1);
            sprintf(nodeName, "SIG%d:DATA", nodeIdx);
            strcpy(infos[nodeIdx].nodeName, nodeName);
            infos[nodeIdx].sigSize = dataSizeInFloats / numThreads;
            infos[nodeIdx].blockSize = blockSizeInFloats;
            infos[nodeIdx].shot = nodeIdx + 5;
        }
    } catch(MdsException *exc)
    {
        std::cout<< "Error getting node: " << exc->what() << std::endl;
        exit(0);
    }
    pthread_t threads[MAX_THREADS];
    struct timeval startTime, endTime;

    gettimeofday(&startTime, NULL);
    int threadIdx;
    for(threadIdx = 0; threadIdx < numThreads; threadIdx++)
    {
        if((pids[threadIdx] = fork()) == 0)
        {
            handleChan((void *)&infos[threadIdx]);
            exit(0);
        }
    }
    void *retval;
    for(threadIdx = 0; threadIdx < numThreads; threadIdx++)
        waitpid(pids[threadIdx], NULL, 0);
    gettimeofday(&endTime, NULL);

    double timeSec = endTime.tv_sec - startTime.tv_sec + (endTime.tv_usec - startTime.tv_usec)*1E-6;
    std::cout<< "Execution time(sec): " << timeSec - SLEEP_TIME << std::endl;
    std::cout<< "Throughput (MB/s): " << (int)(dataSize/(timeSec - SLEEP_TIME)) << std::endl;
}


