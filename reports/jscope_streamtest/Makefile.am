.ONESHELL:
include $(top_srcdir)/Common.am
include $(builddir)/test.conf


setup:
	nano $(builddir)/test.conf



TARGET = "tcp://${TARGET_HOST}:${TARGET_PORT}::${TARGET_SPOOL}"

define _envset
 export LD_LIBRARY_PATH=${MDS_LIBDIR}:${LD_LIBRARY_PATH}
 export MDS_PATH=${MDS_SRCDIR}/tdi
 export PATH=${MDS_BINDIR}:${PATH}
 export CLASSPATH=${MDS_CLASSPATH}
endef



bin_PROGRAMS = write_stream

write_stream_SOURCES = write_stream.cpp

LDADD = $(AM_LIBS)


jscope_streamtest: write_stream
	@ \
	  eval ${_envset}; \
	  export stream_path=${TARGET}; \
	  $(builddir)/write_stream & _wpid="$$!"; \
	  [ -n "$${_wpid}" ] && java jScope ${srcdir}/streamtest.jscp;  \
	  [ -n "$${_wpid}" ] && kill $${_wpid};

