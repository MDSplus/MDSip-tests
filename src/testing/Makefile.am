include $(top_srcdir)/Common.am

#AM_DEFAULT_SOURCE_EXT = .cpp

# if HAVE_CHECK
TESTS = \
 BuildTest \
 SerializeToBinTest \
 SerializeToShmTest \
 TreeUtilsTest \
 ContentProducerTest \
 ClassUtilsTest \
 DataUtilsTest \
 StatisticsUtilsTest


# UuidTest

# else
# TEST =
# endif

LDADD = ../libMDSipTest.la

check_PROGRAMS = $(TESTS)


all: $(TESTS)

