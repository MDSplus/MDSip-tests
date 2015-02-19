SUBDIRS = . testing

include $(top_srcdir)/Common.am

library_includedir = $(includedir)/MDSipTest

library_include_HEADERS = \
 ClassUtils.h \
 DataUtils.h \
 FileUtils.h \
 MDSTest.h \
 ProducerConsumer.h \
 StatisticsUtils.h \
 TestConnection.h \
 TestContent.h \
 Threads.h \
 TreeUtils.h



_CORE_SOURCES = \
ClassUtils.cpp \
FileUtils.cpp \
ProducerConsumer.cpp \
StatisticsUtils.cpp \
TestConnection.cpp \
TestContent.cpp \
TreeUtils.cpp


noinst_LTLIBRARIES = libMDSipTest.la
libMDSipTest_la_SOURCES = ${_CORE_SOURCES}

