.ONESHELL:
include $(top_srcdir)/Common.am


TARGET = "tcp://localhost:8000::/tmp"


bin_PROGRAMS = write_stream

write_stream_SOURCES = write_stream.cpp

LDADD = $(AM_LIBS)


stream-start:
	@ stream_path=${TARGET} $(builddir)/write_stream 

jscope-start:
	@ \
	  export stream_path=${TARGET}; \
	  $(builddir)/write_stream &    \
	  java -cp ${MDS_BUILDPATH}/mdsobjects/java/mdsobjects.jar:${MDS_BUILDPATH}/javascope/jScope.jar jScope ${srcdir}/streamtest.jscp
	

