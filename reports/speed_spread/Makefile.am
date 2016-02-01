.ONESHELL:
include $(top_srcdir)/Common.am
include $(builddir)/test.conf


setup:
	nano $(builddir)/test.conf


TARGET = "$(TARGET_HOST):$(TARGET_PORT)"
recipes = ${top_builddir}/recipes

	

# //////////////////////////////////////////////////////////////////////////// #
# ////  PROGRAM   //////////////////////////////////////////////////////////// #
# //////////////////////////////////////////////////////////////////////////// #

bin_PROGRAMS = \
               SpeedSpread

SpeedSpread_SOURCES = SpeedSpread.cpp

LDADD = $(top_builddir)/libMDSipTest.la


# //////////////////////////////////////////////////////////////////////////// #
# ////  IMAGES   ///////////////////////////////////////////////////////////// #
# //////////////////////////////////////////////////////////////////////////// #

IMAGES = \
	distr-tcp-speed.eps \
	distr-tcp-time.eps \
	distr-udt-speed.eps \
	distr-udt-time.eps

distr_tcp_command = $(builddir)/SpeedSpread tcp://${TARGET} "distr-tcp-" \
		    --channels ${channels} --segments ${segments} --samples ${samples} \
		    --speed_limits ${speed_limits} --time_limits ${time_limits}

distr_udt_command = $(builddir)/SpeedSpread udt://${TARGET} "distr-udt-" \
		    --channels ${channels} --segments ${segments} --samples ${samples} \
		    --speed_limits ${speed_limits} --time_limits ${time_limits}


distr-tcp-speed.csv distr-tcp-time.csv: SpeedSpread
	@${distr_tcp_command}

distr-udt-speed.csv distr-udt-time.csv: SpeedSpread
	@${distr_udt_command}

PHONY: all_images
all_images: ${IMAGES}

define COMMAND =
${distr_tcp_command}
${distr_udt_command}
endef



# //////////////////////////////////////////////////////////////////////////// #
# ///  REPORTS  ////////////////////////////////////////////////////////////// #
# //////////////////////////////////////////////////////////////////////////// #


#
# Set of m4 macro definitions to insert command and confguration in TeX report
# 
define M4_TEX_SUBST =
dnl ------------------------------------------------------------------------

dnl # change quote to a m4_sugar stile that is more friendly with sh
changequote(\`[',\`]')

dnl # change comment to a tex friendly character
changecom(\`%', \`')

dnl # substitutions 
define([_HOSTNAME_],[${HOSTNAME}])
define([_TARGET_HOST_],[${TARGET_HOST}])
define([_TARGET_PORT_],[${TARGET_PORT}])
define([_LOCAL_TIME_], [esyscmd([date])])
define([_route_tcp_],[esyscmd([traceroute ${TARGET_HOST}])])
define([_route_udp_],[esyscmd([traceroute -U ${TARGET_HOST}])])
define([_recipe_command_],[${COMMAND}])

define([_ping_result_],[esyscmd([ping ${TARGET_HOST} -i .2 -c 20 | tail -n 1 | tr -d '\n' ])])


dnl ------------------------------------------------------------------------
endef




.PHONY: tex_subst.m4
CLEANFILES += tex_subst.m4
tex_subst.m4:
	@ ## Build of script macros ##
	cat > $@ << EOF
	${M4_TEX_SUBST}
	EOF


SUFFIXES   += .tex.template .tex
.tex.template.tex:
	@ ## building tex from template ##
	$(MAKE) tex_subst.m4
	cat tex_subst.m4 $< | m4 > $@



CLEANFILES += header.tex speed_spread.tex
.PHONY: header.tex speed_spread.tex
header.tex: ../header.tex.template
	@ ## building tex from template ##	
	$(MAKE) tex_subst.m4
	cat tex_subst.m4 $< | m4 > $@

CLEANFILES += speed_spread.tex
speed_spread.tex: speed_spread.tex.template distr-tcp-speed.eps distr-udt-speed.eps header.tex
	@ ## building tex from template ##	
	$(MAKE) tex_subst.m4
	cat tex_subst.m4 $< | m4 > $@



CLEANFILES += *.pdf *.eps
speed_spread.pdf: speed_spread.tex










