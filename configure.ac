
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
AM_INIT_AUTOMAKE([subdir-objects])

##AC_PREREQ([2.67])
AC_CONFIG_MACRO_DIR([m4])


AC_CONFIG_SRCDIR([Common.am])
AC_CONFIG_HEADERS([config.h])

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

# Check for BOOST Libraries
# BOOST_REQUIRE([1.34])

# BOOST_ARRAY
# BOOST_DATE_TIME
# BOOST_SERIALIZATION
# BOOST_SIGNALS
# BOOST_PROGRAM_OPTIONS(mt-p)


# Check for Vtk installation
# AM_OPTIONS_VTK
# AM_PATH_VTK([5.0],[HAVE_VTK=1],[HAVE_VTK=0])
# AM_CONDITIONAL([HAVE_VTK], [test HAVE_VTK=1] ) # fix?
# AM_CONDITIONAL([VTK_5_x], [1])


# PKG_CHECK_MODULES([EIGEN3],[eigen3 >= 0.1])

# PKG_CHECK_MODULES(QT4, [QtCore QtGui >= 4.4.0], [
#   AC_PATH_PROGS(MOC, [moc-qt4 moc], moc,`eval pkg-config --variable=exec_prefix QtCore`/bin)
#   AC_PATH_PROG(RCC, rcc, rcc,`eval pkg-config --variable=exec_prefix QtCore`/bin)
#   AC_PATH_PROGS(UIC, [uic-qt4 uic], uic,`eval pkg-config --variable=exec_prefix QtCore`/bin)
# ],[HAVE_QT=0])


########## CONDITIONALS ##################################


# Configure script arguments
dnl declare --enable-* args and collect ac_help strings
AC_ARG_ENABLE(debug,
		AS_HELP_STRING([--enable-debug=no/yes],[turn on debugging, default: no]),
[case "${enableval}" in
             yes) debug=true ;;
             no)  debug=false ;;
             *)   AC_MSG_ERROR([bad value ${enableval} for --enable-debug]) ;;
esac],
		[debug=false])

AC_ARG_ENABLE(parallel,
		AS_HELP_STRING([--enable-parallel=no/yes],[turn on openMP parallel processing, default: yes]),
[case "${enableval}" in
             yes) parallel=true ;;
             no)  parallel=false ;;
             *)   AC_MSG_ERROR([bad value ${enableval} for --enable-parallel]) ;;
esac],
		[parallel=true])

AC_ARG_ENABLE(autovector,
                AS_HELP_STRING([--enable-autovector=no/yes],[turn on gcc auto vectorize loops with simd instructions, default: no]),
[case "${enableval}" in
             yes) autovector=true ;;
             no)  autovector=false ;;
             *)   AC_MSG_ERROR([bad value ${enableval} for --enable-autovector]) ;;
esac],
                [autovector=false])





dnl AC_ARG_ENABLE(vtk,
dnl                AS_HELP_STRING([--enable-vtk=no/yes],[turn on vtk visualization wrappers, default: no]),
dnl [case "${enableval}" in
dnl             yes) vtk=true ;;
dnl             no)  vtk=false ;;
dnl             *)   AC_MSG_ERROR([bad value ${enableval} for --enable-vtk]) ;;
dnl esac],
dnl                [vtk=false])


dnl AC_ARG_WITH([readline],
dnl [AS_HELP_STRING([--with-readline],
dnl [support fancy command line editing @<:@default=check@:>@])],
dnl [],
dnl [with_readline=check])

dnl LIBREADLINE=
dnl AS_IF([test "x$with_readline" != xno],
dnl [AC_CHECK_LIB([readline], [main],
dnl [AC_SUBST([LIBREADLINE], ["-lreadline -lncurses"])
dnl AC_DEFINE([HAVE_LIBREADLINE], [1],
dnl [Define if you have libreadline])
dnl ],
dnl [if test "x$with_readline" != xcheck; then
dnl AC_MSG_FAILURE(
dnl [--with-readline was given, but test for readline failed])
dnl fi
dnl ], -lncurses)])

AM_CONDITIONAL(DEBUG, test x"$debug" = x"true")
AM_CONDITIONAL(PARAL_MP, test x"$parallel" = x"true")
AM_CONDITIONAL(SIMD_AUTOVECTOR, test x"$autovector" = x"true")
dnl AM_CONDITIONAL(ENABLE_VTK, [test x"$vtk" = x"true"])


# Forcing variadic macro compiler feature (for gcc without cxx11 flag)
dnl AC_DEFINE_UNQUOTED(BOOST_PP_VARIADICS,1,[Compiler must have variadic macros])



######### MAKEFILES #########################################


AC_CONFIG_FILES([
        Makefile
        src/Makefile
        src/testing/Makefile
	])
AC_OUTPUT

		 
