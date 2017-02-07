include $(top_srcdir)/Common.am

#AM_DEFAULT_SOURCE_EXT = .cpp

if HAVE_CHECK
TESTS = \
 BuildTest \
 SerializeToBinTest \
 SerializeToShmTest \
 TreeUtilsTest \
 ContentProducerTest \
 ClassUtilsTest \
 DataUtilsTest \
 StatisticsUtilsTest \
 TestContentTest \
 OptionsTest \
 threadstest \
 BandUtilsTest

else
 TESTS =
endif


LDADD = $(AM_LIBS) ../libMDSipTest.la ../ext_tools/libnllink.la

if USE_VALGRIND
LOG_COMPILER = valgrind
AM_LOG_FLAGS = --quiet --trace-children=yes --error-exitcode=1 \
               --dsymutil=yes --leak-check=yes
endif

check_PROGRAMS = $(TESTS)


all: $(TESTS)

