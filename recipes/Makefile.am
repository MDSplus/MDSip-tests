SUBDIRS = .
include $(top_srcdir)/Common.am


bin_PROGRAMS = \
 PerfTestProc \
 PerfTestProcMultipleTrees \
 PerfTestThreads \
 MDSipTestMP \
 SpeedDistributionMP

PerfTestProc_SOURCES = PerfTestProc.cpp
PerfTestProcMultipleTrees_SOURCES = PerfTestProcMultipleTrees.cpp
PerfTestThreads_SOURCES = PerfTestThreads.cpp
MDSipTestMP_SOURCES = MDSipTestMP.cpp
SpeedDistributionMP_SOURCES = SpeedDistributionMP.cpp

LDADD = $(top_builddir)/libMDSipTest.la


