#
# use:     AC_SEARCH_MDSPLUS([MDS])
# defines: MDS_CPPFLAGS MDS_LDFLAGS MDSPLUS_DIR have_mdsplus mdsplus_srcdir mdsplus_builddir
#

AC_DEFUN([AC_SEARCH_MDSPLUS],
[
  AC_ARG_WITH([mdsplus-dir],
              [AS_HELP_STRING([--with-mdsplus-dir=MDSPLUS_DIR],[specify mdsplus directory])],
              [],
              [AS_VAR_SET_IF([MDSPLUS_DIR],
                             [AS_VAR_SET([with_mdsplus_dir], ["${MDSPLUS_DIR}"])])])
  AS_VAR_SET_IF([with_mdsplus_dir],              
                [AS_VAR_SET([MDSPLUS_DIR],$(cd ${with_mdsplus_dir};pwd))],
                [AS_VAR_SET([MDSPLUS_DIR],["/usr/local"])])
  
  AC_SUBST(MDSPLUS_DIR)
  if test -d "${with_mdsplus_dir}" ; then

     dnl // find srcdir from config.status if MDSPLUS_DIR is pointing to a builddir
     if test -f ${MDSPLUS_DIR}/config.status ; then  
      AS_VAR_SET([mdsplus_srcdir], $(echo '@abs_top_srcdir@' | ${MDSPLUS_DIR}/config.status --file=-))
     else
      AS_VAR_SET([mdsplus_srcdir], ${MDSPLUS_DIR})
     fi  
     AS_VAR_SET([mdsplus_builddir], $(cd ${MDSPLUS_DIR}; pwd))
     
     dnl // search for all possible lib directories //
     for _dir in "" "64" "32" ; do

        LIBS_save=$LIBS
        CPPFLAGS_save=$CPPFLAGS
        LDFLAGS_save=$LDFLAGS
        
        AS_VAR_SET([mdsplus_libdir],[${mdsplus_builddir}/lib${_dir}])
        AS_VAR_SET([mdsplus_bindir],[${mdsplus_builddir}/bin${_dir}])
        _mdsplus_cppflags="-I${mdsplus_srcdir}/include"
        _mdsplus_ldflags="-L${mdsplus_libdir}"
        
        dnl // setting test program flags //        
        CPPFLAGS="${_mdsplus_cppflags} $CPPFLAGS"
        LDFLAGS="${_mdsplus_ldflags} $LDFLAGS"
        LIBS="-lMdsLib -lMdsShr -lTdiShr $LIBS"
        
        dnl ////////////////////////////////////////////////////////////////////
        dnl // test program source  ////////////////////////////////////////////
        dnl ////////////////////////////////////////////////////////////////////
	AC_TRY_RUN(
                   AC_LANG_SOURCE([[
////////////////////////////////////////////////////////////////////////////////
#include <stdio.h>
#include <mdsshr.h>
#include <mdslib.h>
int main(int argc, char **argv)
{ 
  return 0;
}
////////////////////////////////////////////////////////////////////////////////
                                  ]]),
                                  dnl action if true:
                                  [have_mdsplus=yes],
                                  dnl action if false:
                                  [have_mdsplus=no],
                                  dnl action if cross compiling:
                                  dnl If cross compilation is done the configure is not able to run the test
                                  AC_SEARCH_LIBS([MdsShr],[MdsGetMsg],[have_mdsplus=yes],[have_mdsplus=no])
                                  ) dnl AC_TRY_RUN
                
        dnl restore LIBS 
        LIBS=$LIBS_save
        CPPFLAGS=$CPPFLAGS_save
        LDFLAGS=$LDFLAGS_save
        
        if test $have_mdsplus = yes ; then 
          AC_SUBST($1[]_CPPFLAGS,"$_mdsplus_cppflags")
          AC_SUBST($1[]_LDFLAGS, "$_mdsplus_ldflags")
          # AC_SUBST($1[]_LIBS,"-l...")
          break 
        fi
     done 
     dnl end for
     
     AS_VAR_IF([have_mdsplus],[no],[
      unset mdsplus_srcdir
      unset mdsplus_builddir
      unset mdsplus_libdir
      unset mdsplus_bindir
     ])

     unset LIBS_save
     unset CPPFLAGS_save
     unset LDFLAGS_save
  fi
])




AC_DEFUN([AC_SEARCH_MDSPLUS_JAVA],
[
  dnl recursively call mdsplus search if not present
  AS_VAR_IF([have_mdsplus],[yes],,AC_SEARCH_MDSPLUS([$1]))

  dnl // find srcdir from config.status if MDSPLUS_DIR is pointing to a builddir
  if [ test -f ${MDSPLUS_DIR}/config.status ]; then  
   _jars="\
          javascope/jScope.jar \
          javascope/WaveDisaply.jar \
          mdsobjects/java/mdsobjects.jar \
          javatraverser/DeviceBeans.jar \
          javatraverser/jTraverser.jar \
          javadevices/jDevices.jar \
          javadispatcher/jDispatcher.jar \
         "
  else
   _cdir="java/classes"
   _jars="\
          ${_cdir}/jScope.jar \
          ${_cdir}/WaveDisaply.jar \
          ${_cdir}/mdsobjects.jar \
          ${_cdir}/DeviceBeans.jar \
          ${_cdir}/jTraverser.jar \
          ${_cdir}/jDevices.jar \
          ${_cdir}/jDispatcher.jar \
         "
  fi    
  for j in ${_jars}; do
   
   if [ test -f "${MDSPLUS_DIR}/${j}" ]; then    
    AS_VAR_SET_IF([mdsplus_classpath],
                  [AS_VAR_SET([mdsplus_classpath],"${MDSPLUS_DIR}/${j}:${mdsplus_classpath}")],
                  [AS_VAR_SET([mdsplus_classpath],"${MDSPLUS_DIR}/${j}")])
   fi
  done    
  AC_SUBST($1[]_CLASSPATH,"${mdsplus_classpath}")  
])





AC_DEFUN([AC_SEARCH_MDSPLUS_FUNC],
[
  dnl recursively call mdsplus search if not present
  AS_VAR_IF([have_mdsplus],[yes],,AC_SEARCH_MDSPLUS([$1]))
  AS_VAR_IF([have_mdsplus],[yes],[


   

  ])
])

















