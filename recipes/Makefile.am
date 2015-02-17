SUBDIRS = .
include $(top_srcdir)/Common.am


bin_PROGRAMS = \
 PerfTestProc \
 PerfTestProcMultipleTrees \
 PerfTestThreads \
 MDSipTestMP

PerfTestProc_SOURCES = PerfTestProc.cpp
PerfTestProcMultipleTrees_SOURCES = PerfTestProcMultipleTrees.cpp
PerfTestThreads_SOURCES = PerfTestThreads.cpp
MDSipTestMP_SOURCES = MDSipTestMP.cpp


LDADD = $(top_builddir)/libMDSipTest.la


