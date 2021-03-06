.ONESHELL:
include $(top_srcdir)/Common.am
include $(builddir)/test.conf

setup:
	nano $(builddir)/test.conf

TARGET  = $(TARGET_HOST):$(TARGET_PORT)
recipes = ${top_builddir}/recipes

ALL_PROTOCOLS = tcp udt ssh
PROTOCOLS ?= tcp udt

define _setenv =
 export PATH=${abs_top_srcdir}/conf:${PATH}
 export MDSIP_SSH_OPTIONS=${MDSIP_SSH_OPTIONS}
 export USE_NO_DISK=${USE_NO_DISK}
 export TARGET_SPOOL=${TARGET_SPOOL}
 export TCP_WINDOW_SIZE=${TCP_WINDOW_SIZE}
endef


RECIPE = $(top_builddir)/recipes/SegmentContent

# //////////////////////////////////////////////////////////////////////////// #
# ////  IMAGES   ///////////////////////////////////////////////////////////// #
# //////////////////////////////////////////////////////////////////////////// #


IMAGES = ${addprefix size-,${addsuffix .pdf,$(PROTOCOLS)}}
CLEANFILES += $(IMAGES:.pdf=.sh)

$(ALL_PROTOCOLS): $(RECIPE)
	@ $(_setenv)
	  ${addfunc_dialog_bar}
	  $(RECIPE) $@://$(TARGET_USER)@${TARGET} size-$@ \
	   --channels "${channels}" --segments "${segments}" \
	   --samples "${samples}" --probes ${probes} \
	   --clevel $(COMPRESSION) \
	   | tee -a SegmentContent-$@.log | dialog_bar "SegmentContent Test $@"

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
define([_TARGET_USER_],[${TARGET_USER}])
define([_PROTOCOLS_],[$(PROTOCOLS)])

define([_USE_NO_DISK_],[$(USE_NO_DISK)])
define([_COMPRESSION_],[$(COMPRESSION)])
define([_MDSIP_SSH_OPTIONS_],[$(MDSIP_SSH_OPTIONS)])
define([_gen_function_],[$(gen_function)])

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

define([_ssh_max_pt_],[esyscmd([. ./size-ssh.sh; printf \$${max_pt} ])])
define([_ssh_max_x_],[esyscmd([. ./size-ssh.sh; printf  \$${max_x} ])])
define([_ssh_max_y_],[esyscmd([. ./size-ssh.sh; printf "%.2f" \$${max_y} ])])
define([_ssh_max_e_],[esyscmd([. ./size-ssh.sh; printf "%.2f" \$${max_e} ])])

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

.PHONY: header.tex segment_content.tex
header.tex: ../header.tex.template
	@ ## building tex from template ##	
	$(MAKE) tex_subst.m4
	cat tex_subst.m4 $< | m4 > $@


segment_content.tex: segment_content.tex.template all_images header.tex
	@ ## building tex from template ##	
	$(MAKE) tex_subst.m4
	cat tex_subst.m4 $< | m4 > $@



CLEANFILES += *.pdf *.eps
segment_content.pdf: segment_content.tex










