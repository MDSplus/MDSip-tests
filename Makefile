

FLAGS=-I/opt/mdsplus/include/ -L/opt/mdsplus/lib/
LIBS=-lMdsObjectsCppShr -lstdc++

all: PerfTestProc PerfTestThreads PerfTestProcMultipleTrees


PerfTestProcMultipleTrees: PerfTestProcMultipleTrees.cpp
	gcc $^ -o $@ ${FLAGS} ${LIBS} -lpthread

PerfTestProc: PerfTestProc.cpp
	gcc $^ -o $@ ${FLAGS} ${LIBS}

PerfTestThreads: PerfTestThreads.cpp
	gcc $^ -o $@ ${FLAGS} ${LIBS} -lpthread



clean:
	rm -rf *.o PerfTestProc PerfTestThreads PerfTestProcMultipleTrees
