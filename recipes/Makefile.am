SUBDIRS = .
include $(top_srcdir)/Common.am


bin_PROGRAMS = \
 PerfTestProc \
 PerfTestProcMultipleTrees \
 PerfTestThreads \
 SegmentSize \
 SpeedDistribution

# needed by obsolete automake versions (ra22.igi.cnr.it)
PerfTestProc_SOURCES = PerfTestProc.cpp
PerfTestProcMultipleTrees_SOURCES = PerfTestProcMultipleTrees.cpp
PerfTestThreads_SOURCES = PerfTestThreads.cpp
SegmentSize_SOURCES = SegmentSize.cpp
SpeedDistribution_SOURCES = SpeedDistribution.cpp


LDADD = $(top_builddir)/libMDSipTest.la


