
########################
## CONFIG FILE FOR AC ##
########################

# M4 PREABLE

# uLib version:
m4_define([MDSipTest_major_version], [1])
m4_define([MDSipTest_minor_version], [0])
# if the minor version number is odd, then we want debugging.  Otherwise
# we only want minimal debugging support.
##m4_define([IB_debug_default],
##	  [m4_if(m4_eval(IB_minor_version % 2), [1], [yes])])



########### INIT #######################################
AC_INIT([MdsPlus MDSipTest],[MDSipTest_major_version.MDSipTest_minor_version],[andrea.rigoni@igi.cnr.it])

AC_CONFIG_AUX_DIR([conf])
AC_CONFIG_SRCDIR([Common.am])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_MACRO_DIR([m4])


dnl docker helpers
DK_SET_DOCKER_BUILD

AC_CANONICAL_TARGET
AM_INIT_AUTOMAKE([subdir-objects])
AM_MAINTAINER_MODE


# Checks for programs.
CFLAGS=""
CXXFLAGS=""
AC_PROG_CC
AC_PROG_CXX


######### ROOT MACROS ###################################
#AC_DEFINE([HAVE_ROOT], [no], [Having root installed])
#ROOT_PATH( [5.0] , [HAVE_ROOT=1], [HAVE_ROOT=0])
#AM_CONDITIONAL(HAVE_ROOT, [test HAVE_ROOT=1])
#AS_IF([test HAVE_ROOT=1],[AC_DEFINE([HAVE_ROOT],[1],[])] )

#AC_DEFINE([HAVE_GEANT4], [no], [Having Geant4 installed])
#GEANT4_PATH( [9.6] , [HAVE_GEANT4=1], [HAVE_GEANT4=0])
#AM_CONDITIONAL(HAVE_GEANT4, [test HAVE_GEANT4])
#AS_IF([test HAVE_GEANT4=1],[AC_DEFINE([HAVE_GEANT4],[1],[])] )

######### LIBTOOL ########################################

AM_PROG_CC_C_O

AC_PROG_LIBTOOL
LIBADD_DL="-ldl"
AC_SUBST(LIBADD_DL)

AC_SEARCH_LIBS([strerror],[cposix])

LT_INIT()
AC_SUBST([LIBTOOL_DEPS])



######### CHECKS ########################################
# Checks for header files.
AC_CHECK_HEADERS([stdlib.h string.h assert.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_HEADER_STDBOOL
AC_C_INLINE
AC_TYPE_SIZE_T

# Checks for library functions.
AC_FUNC_MALLOC
AC_CHECK_FUNCS([fesetround floor pow sqrt strdup strstr])

AC_SEARCH_LIBS([strerror],[cposix])

# Check for gnu test suite
PKG_CHECK_MODULES([CHECK], [check], [have_check=yes], [have_check=no])
AM_CONDITIONAL(HAVE_CHECK, test x"$have_check" = "xyes")



# ///////////////////////////////////////////////////////////////////////////////////////////////// #
# /////  MDSPLUS  ///////////////////////////////////////////////////////////////////////////////// #
# ///////////////////////////////////////////////////////////////////////////////////////////////// #

AC_ARG_WITH([mdsplus-dir],
            [AS_HELP_STRING([--with-mdsplus-dir],[specify mdsplus directory])],[],
            [AS_VAR_SET_IF([MDSPLUS_DIR],[AS_VAR_SET([with_mdsplus_dir], ["${MDSPLUS_DIR}"])])])
AS_VAR_SET_IF([with_mdsplus_dir],              
              [AS_VAR_SET([MDSPLUS_DIR],["${with_mdsplus_dir}"])],
              [AS_VAR_SET([MDSPLUS_DIR],["/usr/local"])])
AC_SUBST(MDSPLUS_DIR)


AC_ARG_ENABLE([mdsplus-build],
              [AS_HELP_STRING([--enable-mdsplus-build],[build mdsplus as submodule])])              
AS_VAR_SET_IF([enable_mdsplus_build],[
               echo "ENABLE SUBMODULE MDSPLUS"
               pushd ${srcdir}; source ./conf/update_submodules.sh; popd
	       autoreconf -fi ${srcdir}/mdsplus -I ${srcdir}/mdsplus/m4
               AC_CONFIG_SUBDIRS([mdsplus])
              ])
AM_CONDITIONAL(BUILD_MDSPLUS, test x"${enable_mdsplus_build}" = x"yes")



########## CONDITIONALS ##################################


# Configure script arguments
dnl declare --enable-* args and collect ac_help strings
AC_ARG_ENABLE(debug, AS_HELP_STRING([--enable-debug=no/yes],[turn on debugging, default: no]),
	      [case "${enableval}" in
	       yes) debug=true ;;
	       no)  debug=false ;;
	       *)   AC_MSG_ERROR([bad value ${enableval} for --enable-debug]) ;;
	      esac],[debug=false])
AM_CONDITIONAL(DEBUG, test x"$debug" = x"true")


AC_ARG_ENABLE(parallel, AS_HELP_STRING([--enable-parallel=no/yes],[turn on openMP parallel processing, default: yes]),
	      [case "${enableval}" in
	       yes) parallel=true ;;
	       no)  parallel=false ;;
	       *)   AC_MSG_ERROR([bad value ${enableval} for --enable-parallel]) ;;
	      esac],[parallel=true])
AM_CONDITIONAL(PARAL_MP, test x"$parallel" = x"true")


AC_ARG_ENABLE(autovector,AS_HELP_STRING([--enable-autovector=no/yes],[turn on gcc auto vectorize loops with simd instructions, default: no]),
	      [case "${enableval}" in
	       yes) autovector=true ;;
	       no)  autovector=false ;;
	       *)   AC_MSG_ERROR([bad value ${enableval} for --enable-autovector]) ;;
	      esac], [autovector=false])
AM_CONDITIONAL(SIMD_AUTOVECTOR, test x"$autovector" = x"true")


AC_ARG_ENABLE([valgrind],
              [AS_HELP_STRING([--enable-valgrind],
                              [Use valgrind when running unit tests])],
              [AS_VAR_SET([use_valgrind], [yes])],
              [])
if [[ "$use_valgrind" = "yes" ]]; then
 AC_CHECK_PROG(HAVE_VALGRIND, valgrind, yes, no)
 if [[ "$HAVE_VALGRIND" = "no" ]]; then
  AC_MSG_ERROR([Valgrind not found in PATH. ])
 fi
fi
AM_CONDITIONAL(USE_VALGRIND, test x"$use_valgrind" = "xyes")






# Check for presence of pdfLaTeX
AS_VAR_SET_IF([PDFLATEX],
              [],
              [AC_CHECK_PROG(PDFLATEX, pdflatex, pdflatex)])
if test -z "$PDFLATEX"; then
  AC_MSG_WARN([Unable to create PDF report.])
fi

AM_CONDITIONAL([HAVE_PDFLATEX], test -n "$PDFLATEX")


AC_CHECK_PROG(MKDIR_P, mkdir, [mkdir -p])
AC_SUBST([MKDIR_P])

# TODO: add whiptail if dialog not found
#       eventually add zenith for X11
AC_CHECK_PROG(DIALOG, dialog, dialog)
AC_SUBST([DIALOG])

AC_CHECK_PROG([GNUPLOT], gnuplot, gnuplot)
AC_SUBST([GNUPLOT])




# //////////////////////////////////////////////////////////////////////////// #
# ///  CONFIG_H  ///////////////////////////////////////////////////////////// #
# //////////////////////////////////////////////////////////////////////////// #

dnl Here we define all custom autoheader adds to config.h.in 
dnl Needed because mdsplus uses config.h in headers

dnl add here what goes on tom of config.h
AH_TOP()

AH_VERBATIM([_LL_CONSTANTS], [
#ifdef HAVE_LL_CONSTANTS
#define LONG_LONG_CONSTANT(value) value##ll
#else
#define LONG_LONG_CONSTANT(value) value
#endif
])


AH_VERBATIM([_WIN32], [
#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#elif HAVE_VISIBILITY
# define EXPORT __attribute__((__visibility__("default")))
#else
#define EXPORT
#endif
])

dnl add here what goes on bottom of config.h
AH_BOTTOM()




######### MAKEFILES #########################################

AC_CONFIG_FILES([
        Makefile
        src/Makefile
        src/testing/Makefile
        src/ext_tools/Makefile
        recipes/Makefile
        tex/Makefile
	tex/img/Makefile
	tex/packages/Makefile
	reports/Makefile
	reports/segment_size/Makefile
	reports/segment_size/test.conf
	reports/speed_trend/Makefile
	reports/speed_trend/test.conf
	reports/speed_spread/Makefile
	reports/speed_spread/test.conf
	])
AC_OUTPUT

		 
