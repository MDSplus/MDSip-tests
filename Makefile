
MDSPLUS_DIR=/usr/local/mdsplus

OPT=-O0 -g

CC=g++
CFLAGS= -I${MDSPLUS_DIR}/include -Wall ${OPT}
LDFLAGS=-L${MDSPLUS_DIR}/lib -lMdsObjectsCppShr -lstdc++ -lpthread -lm

SOURCES = FileUtils.cpp TreeUtils.cpp TestContent.cpp TestConnection.cpp StatisticsUtils.cpp
OBJECTS=$(SOURCES:.cpp=.o)

#$(EXECUTABLE): $(OBJECTS) 
#	$(CC) $(LDFLAGS) $(OBJECTS) -o $@

.cpp.o:
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
