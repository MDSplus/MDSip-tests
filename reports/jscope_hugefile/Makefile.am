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

bin_PROGRAMS = write_huge
write_huge_SOURCES = write_huge.cpp


LDADD = $(AM_LIBS)

HUGE_FILES = ${TARGET_SPOOL}/huge_001.characteristics \
             ${TARGET_SPOOL}/huge_001.datafile  \
             ${TARGET_SPOOL}/huge_001.tree  \
             ${TARGET_SPOOL}/huge_model.characteristics  \
             ${TARGET_SPOOL}/huge_model.datafile  \
             ${TARGET_SPOOL}/huge_model.tree

MOSTLYCLEANFILES = ${HUGE_FILES}

# // Must be triggered by server only //
.PHONY: do_write_huge
do_write_huge: ${TARGET_SPOOL}/huge_001.datafile

# // Must be triggered by server only //
${HUGE_FILES}: write_huge
	@ \
	  eval ${_envset}; \
	  export huge_path=${TARGET_SPOOL}; \
	  $(builddir)/write_huge


.PHONY: jscope_hugefile
jscope_hugefile: huge_tcp.jscp huge_udt.jscp
	@ \
	  eval ${_envset}; \
	  p=$$(echo "${PROTOCOL}" | awk '{print tolower($$0)}')
	  java jScope ${builddir}/huge_$$p.jscp
	  

.PHONY: jtraverser
jtraverser:
	 \
	  eval ${_envset}; \
	  export huge_path=${TARGET_SPOOL}; \
	  java jTraverser




# //////////////////////////////////////////////////////////////////////////// #
# //////////////////////////////////////////////////////////////////////////// #
# Set of m4 macro definitions to insert command and confguration in jscp files #
# NOTE: Make 4 needed for this to work
define M4_SUBST =
dnl ------------------------------------------------------------------------
dnl # change quote to a m4_sugar stile that is more friendly with sh
changequote(\`[',\`]')
dnl # change comment to a tex friendly character
changecom(\`%', \`')
dnl # substitutions 
define([_TARGET_HOST_],[${TARGET_HOST}])
define([_TARGET_PORT_],[${TARGET_PORT}])
define([_TARGET_SPOOL_],[${TARGET_SPOOL}])
dnl ------------------------------------------------------------------------
endef


.PHONY: huge_tcp.jscp
huge_tcp.jscp: huge_tcp.jscp.m4
	@ \
	  echo "building jscp from template"; \
	  (echo "${M4_SUBST}"; cat $<) | m4 > $@


.PHONY: huge_udt.jscp
huge_udt.jscp: huge_udt.jscp.m4
	@ \
	  echo "building jscp from template"; \
	  (echo "${M4_SUBST}"; cat $<) | m4 > $@

all:
