SUBDIRS = ext_tools

include $(top_srcdir)/Common.am

library_includedir = $(includedir)/MDSipTest

library_include_HEADERS = \
 ClassUtils.h \
 SerializeUtils.h \
 DataUtils.h \
 FileUtils.h \
 MDSTest.h \
 ProducerConsumer.h \
 StatisticsUtils.h \
 TestConnection.h \
 TestChannel.h \
 TestContent.h \
 Threads.h \
 TreeUtils.h



_CORE_SOURCES = \
ClassUtils.cpp \
SerializeUtils.cpp \
DataUtils.cpp \
FileUtils.cpp \
ProducerConsumer.cpp \
StatisticsUtils.cpp \
TestConnection.cpp \
TestChannel.cpp \
TestContent.cpp \
TreeUtils.cpp \
BandUtils.cpp


noinst_LTLIBRARIES = libMDSipTest.la
libMDSipTest_la_SOURCES = ${_CORE_SOURCES}
libMDSipTest_la_LIBADD = ext_tools/libnllink.la

