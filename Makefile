
MDSPLUS_DIR=${MDS_PATH}/..

OPT=-O0 -g3

CC=g++
CFLAGS= -I${MDSPLUS_DIR}/include -Wall ${OPT}
LDFLAGS=-L${MDSPLUS_DIR}/lib -lMdsObjectsCppShr -lstdc++ -lpthread -lm

SOURCES = FileUtils.cpp TreeUtils.cpp TestContent.cpp TestConnection.cpp StatisticsUtils.cpp

HEADERS = $(wildcard *.h)
 
OBJECTS=$(SOURCES:.cpp=.o)

#$(EXECUTABLE): $(OBJECTS) 
#	$(CC) $(LDFLAGS) $(OBJECTS) -o $@

.cpp.o: ${HEADERS}
	$(CC) $(CFLAGS) $< -c -o $@

all: main

main: ${OBJECTS} main.o
	gcc $^ -o $@ ${CFLAGS} ${LDFLAGS} -lpthread

PerfTestProcMultipleTrees: PerfTestProcMultipleTrees.cpp
	gcc $^ -o $@ ${CFLAGS} ${LDFLAGS} -lpthread

PerfTestProc: PerfTestProc.cpp
	gcc $^ -o $@ ${CFLAGS} ${LDFLAGS}

PerfTestThreads: PerfTestThreads.cpp
	gcc $^ -o $@ ${CFLAGS} ${LDFLAGS} -lpthread



clean:
	rm -rf *.o PerfTestProc PerfTestThreads PerfTestProcMultipleTrees main
