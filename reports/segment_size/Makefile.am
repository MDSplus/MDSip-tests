.ONESHELL:
include $(top_srcdir)/Common.am
include $(builddir)/test.conf


setup:
	nano $(builddir)/test.conf


TARGET  = $(TARGET_HOST):$(TARGET_PORT)
recipes = ${top_builddir}/recipes

PROTOCOLS = ssh tcp udt

size_tcp_command = $(builddir)/SegmentSize tcp://${TARGET} size-tcp \
		   --channels ${channels} --segments ${segments} --samples ${samples} --probes ${probes}

size_udt_command = $(builddir)/SegmentSize udt://${TARGET} size-udt \
		   --channels ${channels} --segments ${segments} --samples ${samples} --probes ${probes}

size_ssh_command = $(builddir)/SegmentSize ssh://${TARGET} size-ssh \
		   --channels ${channels} --segments ${segments} --samples ${samples} --probes ${probes}


define size_command =
function cmd {
 $(builddir)/SegmentSize $$1://${TARGET} size-$$1 \
 --channels ${channels} --segments ${segments} --samples ${samples} --probes ${probes}
 }
endef

define COMMAND =
${size_tcp_command}
${size_udt_command}
endef

define _setenv =
 export PATH=${abs_top_srcdir}/conf:${PATH}
endef


# //////////////////////////////////////////////////////////////////////////// #
# ////  PROGRAM   //////////////////////////////////////////////////////////// #
# //////////////////////////////////////////////////////////////////////////// #

bin_PROGRAMS = \
               SegmentSize

SegmentSize_SOURCES = SegmentSize.cpp

LDADD = $(AM_LIBS) $(top_builddir)/libMDSipTest.la


# //////////////////////////////////////////////////////////////////////////// #
# ////  IMAGES   ///////////////////////////////////////////////////////////// #
# //////////////////////////////////////////////////////////////////////////// #


CLEANFILES += size-tcp.sh size-udt.sh

IMAGES = \
	size-ssh.eps \
	size-tcp.eps \
	size-udt.eps

size-tcp.dat: SegmentSize
	@ $(_setenv)
	  ${addfunc_dialog_bar}
	  ${size_tcp_command} 2>&1 | tee -a SegmentSize-tcp.log | dialog_bar "SegmentSize Test TCP"

size-udt.dat: SegmentSize
	@ $(_setenv)
	  ${addfunc_dialog_bar}
	  ${size_udt_command} 2>&1 | tee -a SegmentSize-udt.log | dialog_bar "SegmentSize Test UDT"

size-ssh.dat: SegmentSize
	@ $(_setenv)
	  ${addfunc_dialog_bar}
	  ${size_ssh_command} 2>&1 | tee -a SegmentSize-ssh.log | dialog_bar "SegmentSize Test SSH"


PHONY: all_images
all_images: ${IMAGES}


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

define([_tcp_max_pt_],[esyscmd([. ./size-tcp.sh; printf \$${max_pt} ])])
define([_tcp_max_x_],[esyscmd([. ./size-tcp.sh; printf  \$${max_x} ])])
define([_tcp_max_y_],[esyscmd([. ./size-tcp.sh; printf "%.2f" \$${max_y} ])])
define([_tcp_max_e_],[esyscmd([. ./size-tcp.sh; printf "%.2f" \$${max_e} ])])

define([_udt_max_pt_],[esyscmd([. ./size-udt.sh; printf \$${max_pt} ])])
define([_udt_max_x_],[esyscmd([. ./size-udt.sh; printf  \$${max_x} ])])
define([_udt_max_y_],[esyscmd([. ./size-udt.sh; printf "%.2f" \$${max_y} ])])
define([_udt_max_e_],[esyscmd([. ./size-udt.sh; printf "%.2f" \$${max_e} ])])

define([_channels_],[${channels}])
define([_segments_],[${segments}])
define([_samples_],[${samples}])


dnl ------------------------------------------------------------------------
endef




.PHONY: tex_subst.m4
CLEANFILES += tex_subst.m4
tex_subst.m4:
	@## Build of script macros ##
	cat > $@ << EOF
	${M4_TEX_SUBST}
	EOF


SUFFIXES   += .tex.template .tex
.tex.template.tex:
	@ ## building tex from template ##
	$(MAKE) tex_subst.m4
	cat tex_subst.m4 $< | m4 > $@


# LOCALTEST HEADER
CLEANFILES += header.tex segment_size.tex

.PHONY: header.tex segment_size.tex
header.tex: ../header.tex.template
	@ ## building tex from template ##	
	$(MAKE) tex_subst.m4
	cat tex_subst.m4 $< | m4 > $@


segment_size.tex: segment_size.tex.template all_images header.tex
	@ ## building tex from template ##	
	$(MAKE) tex_subst.m4
	cat tex_subst.m4 $< | m4 > $@



CLEANFILES += *.pdf *.eps
segment_size.pdf: segment_size.tex










