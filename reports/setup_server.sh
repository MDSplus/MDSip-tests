#!/bin/sh

# exit on errors
set -e

SCRIPTNAME=$(basename "$0")
SCRIPT_DIR=$(dirname "$0")


export TARGET_PORT=${TARGET_PORT:=8000}
export TARGET_SPOOL=${TARGET_SPOOL:=/tmp/mdsip_test}

MDSPLUS_DIR=/home/andrea/devel/rfx/tests/mdsip-tests/mdsplus
SRCDIR=/home/andrea/devel/rfx/tests/mdsip-tests
BUILDDIR=/home/andrea/devel/rfx/tests/mdsip-tests
MDSIP=/home/andrea/devel/rfx/tests/mdsip-tests/mdsplus/bin64/mdsip
LD_LIBRARY_PATH=/home/andrea/devel/rfx/tests/mdsip-tests/mdsplus/lib64:${LD_LIBRARY_PATH}
export MDS_PATH=/home/andrea/devel/rfx/tests/mdsip-tests/mdsplus/tdi

DIALOG=dialog


print_help() {
cat << EOF
Usage: $SCRIPTNAME [options] [command]

       options
       -------
       -h|--help)         get this help      
       -p|--port)         set server port to be used (default=8000)
       -s|--spool)        set spool dir to store sent data (default=/tmp/mdsip_test)
       -v|--verbose)      show script source script
       
       commands
       --------       
       start              start server session
       xinetd             start server session using xinetd server
       stop               stop server session
       clean              empty the server spool directory
       gui                start dialog gui

EOF
}

## parse cmd parameters:
while [[ "$1" == -* ]] ; do
        case "$1" in
                -h|--help)
                        print_help
                        exit
                        ;;
                -v|--verbose)
                        set -o verbose
                        shift
                        ;;
                -p|--port)
			TARGET_PORT=$2
                        shift 2
                        ;;
                --)
                        shift
                        break
                        ;;
                *)
                        break
                        ;;
        esac
done

if [ $# -lt 1 ] ; then
        echo "Incorrect parameters. Use --help for usage instructions."
        exit 1
fi




function set_path() {
   mkdir -p ${TARGET_SPOOL}
   mkdir -p ${TARGET_SPOOL}/log
   mkdir -p ${TARGET_SPOOL}/run
   export test_spool_path=${TARGET_SPOOL}
   export segment_size_path=${TARGET_SPOOL}
   export speed_spread_path=${TARGET_SPOOL}
   export speed_trend_path=${TARGET_SPOOL}
   export stream_path=${TARGET_SPOOL}
   export huge_path=${TARGET_SPOOL}

   export rfx_path=${TARGET_SPOOL}/rfxdata
   export mhd_ac_path=${TARGET_SPOOL}/rfxdata
   export mhd_bc_path=${TARGET_SPOOL}/rfxdata
   export mhd_br_path=${TARGET_SPOOL}/rfxdata
   export eda1_path=${TARGET_SPOOL}/rfxdata
   export eda2_path=${TARGET_SPOOL}/rfxdata
   export eda3_path=${TARGET_SPOOL}/rfxdata
   export edam_path=${TARGET_SPOOL}/rfxdata
   export edav_path=${TARGET_SPOOL}/rfxdata
   export edag_path=${TARGET_SPOOL}/rfxdata
   export dstc_path=${TARGET_SPOOL}/rfxdata
   export dequ_path=${TARGET_SPOOL}/rfxdata
   export dflu_path=${TARGET_SPOOL}/rfxdata
   export a_path=${TARGET_SPOOL}/rfxdata

   export dequ_raw_path=${TARGET_SPOOL}/rfxdata
   export dflu_raw_path=${TARGET_SPOOL}/rfxdata
   export dico28_raw_path=${TARGET_SPOOL}/rfxdata
   export dtsr_raw_path=${TARGET_SPOOL}/rfxdata
   export dtse_raw_path=${TARGET_SPOOL}/rfxdata
   export dssp_raw_path=${TARGET_SPOOL}/rfxdata
   export dsxm_raw_path=${TARGET_SPOOL}/rfxdata
   export dsfm_raw_path=${TARGET_SPOOL}/rfxdata
   export a_raw_path=${TARGET_SPOOL}/rfxdata
   export dbol_raw_path=${TARGET_SPOOL}/rfxdata
   export dbot_raw_path=${TARGET_SPOOL}/rfxdata
   export dedg_raw_path=${TARGET_SPOOL}/rfxdata
   export dmwr_raw_path=${TARGET_SPOOL}/rfxdata
   export dofl_raw_path=${TARGET_SPOOL}/rfxdata
   export dpel_raw_path=${TARGET_SPOOL}/rfxdata
   export dpfr_raw_path=${TARGET_SPOOL}/rfxdata
   export dsct_raw_path=${TARGET_SPOOL}/rfxdata
   export dscv_raw_path=${TARGET_SPOOL}/rfxdata
   export dstc_raw_path=${TARGET_SPOOL}/rfxdata
   export dstcj_raw_path=${TARGET_SPOOL}/rfxdata
   export dstcu_raw_path=${TARGET_SPOOL}/rfxdata
   export dsxt_raw_path=${TARGET_SPOOL}/rfxdata
   export dsxv_raw_path=${TARGET_SPOOL}/rfxdata
   export dtof_raw_path=${TARGET_SPOOL}/rfxdata
   export dccd_raw_path=${TARGET_SPOOL}/rfxdata
   export dter_raw_path=${TARGET_SPOOL}/rfxdata
   export disis_raw_path=${TARGET_SPOOL}/rfxdata
   export dgpi_raw_path=${TARGET_SPOOL}/rfxdata
   export dgpi2_raw_path=${TARGET_SPOOL}/rfxdata
   export dsxc_raw_path=${TARGET_SPOOL}/rfxdata
   export dmoss_raw_path=${TARGET_SPOOL}/rfxdata
   export dftc_raw_path=${TARGET_SPOOL}/rfxdata
   export deso_raw_path=${TARGET_SPOOL}/rfxdata
   export dnbi_raw_path=${TARGET_SPOOL}/rfxdata
   export dnpa_raw_path=${TARGET_SPOOL}/rfxdata
   export dli3_raw_path=${TARGET_SPOOL}/rfxdata
   export dirc_raw_path=${TARGET_SPOOL}/rfxdata
   export dgpi2_raw_path=${TARGET_SPOOL}/rfxdata

   make -C ${BUILDDIR}/reports/jscope_hugefile do_write_huge
}





# ///////////////////////////////////////////////////////////////////////////
# /// start server       ////////////////////////////////////////////////////
# ///////////////////////////////////////////////////////////////////////////

function start() {
  eval set_path
  check_server_running

  if [ ! "${tcp_running}" ]; then
  ${MDSIP} -p ${TARGET_PORT} -m -h ${MDSPLUS_DIR}/etc/mdsip.hosts -P tcp > ${TARGET_SPOOL}/tcp.log &
  echo "$!" > ${TARGET_SPOOL}/run/tcp.pid && echo "mdsip TCP server started"
  fi  

  if [ ! "${udt_running}" ]; then
  ${MDSIP} -p ${TARGET_PORT} -m -h ${MDSPLUS_DIR}/etc/mdsip.hosts -P udt > ${TARGET_SPOOL}/udt.log &
  echo "$!" > ${TARGET_SPOOL}/run/udt.pid && echo "mdsip UDT server started"
  fi
  
  check_server_running
  echo "${IS_SERVER_RUNNING}"
}


# ///////////////////////////////////////////////////////////////////////////
# /// start inted server      ///////////////////////////////////////////////
# ///////////////////////////////////////////////////////////////////////////

XINETD_CONF="
defaults
{
	log_type                = FILE \${TARGET_SPOOL}/log/mdsip_xinetd.log
        log_on_success          = HOST PID
        log_on_failure          = HOST
}

service mdsip_tcp
{
        disable          = no
        protocol         = tcp
        socket_type      = stream
        wait             = no
        cps              = 10000 1
        instances        = UNLIMITED
        per_source       = UNLIMITED
        type             = UNLISTED
        flags            = KEEPALIVE NODELAY NOLIBWRAP

	user             = \${USER}
	port             = \${TARGET_PORT}
	server           = \${TARGET_SPOOL}/mdsipd
	server_args      = \${TARGET_PORT} tcp \${TARGET_SPOOL}/mdsip.hosts \${TARGET_SPOOL}/log
}

# Currently UDT is not supported in xinetd connection #
# service mdsip_udt
# {
#        disable          = no
#        protocol         = udp
#        socket_type      = dgram
#        wait             = yes
#        type             = UNLISTED

#        user             = \${USER}
#        port             = \${TARGET_PORT}
#        server           = \${TARGET_SPOOL}/mdsipd
#        server_args      = \${TARGET_PORT} udt \${TARGET_SPOOL}/mdsip.hosts \${TARGET_SPOOL}/log
# }
"

MDSIP_HOSTS="
# This file maps remote connections to local users. The mdsip
# data server will change itself into the appropriate local user
# for access control. Use * to match zero or more characters or
# % to match one and only one character.
#
# Comments can be included by placing a # character in the beginning
# of the line. You can deny access to a particular connection by placing
# a ! character in the beginning of the line. Connection matching proceeds
# from the first line containing a map and continues until the first match
# is found. Trailing comments are not permitted in the mapping lines.
# You can use either ip address names or numbers in the match string.
# For local account mapping you can also use the keyword MAP_TO_LOCAL which
# maps the username of the remote user to the same name on the local system.
#
# If you want to run an mdsip server from a non-privileged account you will
# need to map all permitted connections to the special keyword SELF. This
# instructs the server to not attempt to switch user id when incoming connections
# occur. Do not use the SELF mapping when running the server from the root
# account as this will compromise system security.
#
# Changes to this file take effect immediately without restarting inetd or
# any other service. They do not effect existing connections however.
#
* | SELF
"


MDSIPD_SCRIPT="#!/bin/sh
# source $MDSPLUS_DIR/setup.sh
export LD_LIBRARY_PATH=${MDS_LIBRARY_PATH}:${LD_LIBRARY_PATH}
export MDSPLUS_DIR=${MDSPLUS_DIR}
export MDS_PATH=${MDS_PATH}
export test_spool_path=\${TARGET_SPOOL}
export segment_size_path=\${TARGET_SPOOL}
export speed_spread_path=\${TARGET_SPOOL}
export speed_trend_path=\${TARGET_SPOOL}
export stream_path=\${TARGET_SPOOL}
export huge_path=\${TARGET_SPOOL}

export rfx_path=\${TARGET_SPOOL}/rfxdata
export mhd_ac_path=\${TARGET_SPOOL}/rfxdata
export mhd_bc_path=\${TARGET_SPOOL}/rfxdata
export mhd_br_path=\${TARGET_SPOOL}/rfxdata
export eda1_path=\${TARGET_SPOOL}/rfxdata
export eda2_path=\${TARGET_SPOOL}/rfxdata
export eda3_path=\${TARGET_SPOOL}/rfxdata
export edam_path=\${TARGET_SPOOL}/rfxdata
export edav_path=\${TARGET_SPOOL}/rfxdata
export edag_path=\${TARGET_SPOOL}/rfxdata
export dstc_path=\${TARGET_SPOOL}/rfxdata
export dequ_path=\${TARGET_SPOOL}/rfxdata
export dflu_path=\${TARGET_SPOOL}/rfxdata
export a_path=\${TARGET_SPOOL}/rfxdata


export dequ_raw_path=\${TARGET_SPOOL}/rfxdata
export dflu_raw_path=\${TARGET_SPOOL}/rfxdata
export dico28_raw_path=\${TARGET_SPOOL}/rfxdata
export dtsr_raw_path=\${TARGET_SPOOL}/rfxdata
export dtse_raw_path=\${TARGET_SPOOL}/rfxdata
export dssp_raw_path=\${TARGET_SPOOL}/rfxdata
export dsxm_raw_path=\${TARGET_SPOOL}/rfxdata
export dsfm_raw_path=\${TARGET_SPOOL}/rfxdata
export a_raw_path=\${TARGET_SPOOL}/rfxdata
export dbol_raw_path=\${TARGET_SPOOL}/rfxdata
export dbot_raw_path=\${TARGET_SPOOL}/rfxdata
export dedg_raw_path=\${TARGET_SPOOL}/rfxdata
export dmwr_raw_path=\${TARGET_SPOOL}/rfxdata
export dofl_raw_path=\${TARGET_SPOOL}/rfxdata
export dpel_raw_path=\${TARGET_SPOOL}/rfxdata
export dpfr_raw_path=\${TARGET_SPOOL}/rfxdata
export dsct_raw_path=\${TARGET_SPOOL}/rfxdata
export dscv_raw_path=\${TARGET_SPOOL}/rfxdata
export dstc_raw_path=\${TARGET_SPOOL}/rfxdata
export dstcj_raw_path=\${TARGET_SPOOL}/rfxdata
export dstcu_raw_path=\${TARGET_SPOOL}/rfxdata
export dsxt_raw_path=\${TARGET_SPOOL}/rfxdata
export dsxv_raw_path=\${TARGET_SPOOL}/rfxdata
export dtof_raw_path=\${TARGET_SPOOL}/rfxdata
export dccd_raw_path=\${TARGET_SPOOL}/rfxdata
export dter_raw_path=\${TARGET_SPOOL}/rfxdata
export disis_raw_path=\${TARGET_SPOOL}/rfxdata
export dgpi_raw_path=\${TARGET_SPOOL}/rfxdata
export dgpi2_raw_path=\${TARGET_SPOOL}/rfxdata
export dsxc_raw_path=\${TARGET_SPOOL}/rfxdata
export dmoss_raw_path=\${TARGET_SPOOL}/rfxdata
export dftc_raw_path=\${TARGET_SPOOL}/rfxdata
export deso_raw_path=\${TARGET_SPOOL}/rfxdata
export dnbi_raw_path=\${TARGET_SPOOL}/rfxdata
export dnpa_raw_path=\${TARGET_SPOOL}/rfxdata
export dli3_raw_path=\${TARGET_SPOOL}/rfxdata
export dirc_raw_path=\${TARGET_SPOOL}/rfxdata
export dgpi2_raw_path=\${TARGET_SPOOL}/rfxdata

if test \\\$2 = \"ssh\"; then
 exec ${MDSIP} -P ssh 2>> \\\$4/\\\$2.errors
else
 exec ${MDSIP} -p \\\$1 -P \\\$2 -h \\\$3 -c 0 >> \\\$4/\\\$2.access 2>> \\\$4/\\\$2.errors
fi
"




function xinetd() {
  eval set_path
  eval "echo \"${XINETD_CONF}\""   > ${TARGET_SPOOL}/mdsipd.xinetd
  eval "echo \"${MDSIP_HOSTS}\""   > ${TARGET_SPOOL}/mdsip.hosts
  eval "echo \"${MDSIPD_SCRIPT}\"" > ${TARGET_SPOOL}/mdsipd
  chmod +x ${TARGET_SPOOL}/mdsipd
  
  mkdir -p ${TARGET_SPOOL}/log
  
  check_server_running
  # UDT session
  if [ ! "${udt_running}" ]; then
  ${MDSIP} -p ${TARGET_PORT} -P udt -m -h ${TARGET_SPOOL}/mdsip.hosts \
    >> ${TARGET_SPOOL}/log/udt.access 2>>${TARGET_SPOOL}/log/udt.errors &
   echo "$!" > ${TARGET_SPOOL}/run/udt.pid && echo "mdsip UDT server started"
  fi
  
  # TCP session in xinetd
  if [ ! "${tcp_running}" ]; then
  sh -c "xinetd -f ${TARGET_SPOOL}/mdsipd.xinetd -pidfile ${TARGET_SPOOL}/run/tcp.pid" && \
   echo "mdsip TCP server started"
  fi
  
  check_server_running
  echo "${IS_SERVER_RUNNING}"
}





# ///////////////////////////////////////////////////////////////////////////
# /// STOP   ////////////////////////////////////////////////////////////////
# ///////////////////////////////////////////////////////////////////////////

function stop() {
_pidf=${TARGET_SPOOL}/run/tcp.pid
[ -f ${_pidf} ] && ( kill $(cat ${_pidf}); rm -f ${_pidf} ) ||:
_pidf=${TARGET_SPOOL}/run/udt.pid
[ -f ${_pidf} ] && ( kill $(cat ${_pidf}); rm -f ${_pidf} ) ||:
}


# ///////////////////////////////////////////////////////////////////////////
# /// CLEAN  ////////////////////////////////////////////////////////////////
# ///////////////////////////////////////////////////////////////////////////

function clean() {
 (stop; rm -rf ${TARGET_SPOOL} ) && \
  echo "Spool directory succesfully cleaned"
}





# ///////////////////////////////////////////////////////////////////////////
# /// GUI    ////////////////////////////////////////////////////////////////
# ///////////////////////////////////////////////////////////////////////////

BACKTITLE=" MDSip throughput tests - Server configuration "
DIALOG=dialog

# SELECT PARAMS #
function gui_select_port() {
VALUES=$(${DIALOG} --ok-label "Submit" \
	  --backtitle "${BACKTITLE}" \
	  --title "Server port selection" \
	  --form "\nSelect tests default server port \n " 15 50 0 \
	  "Port:"     1 1	"$TARGET_PORT" 	1 10 20 0 \
	  "Spool:"    2 1	"$TARGET_SPOOL" 	2 10 20 0 \
3>&1 1>&2 2>&3)
opt=$?
if [ $opt = 0 ]; then
 export TARGET_PORT=$(echo ${VALUES} | awk '{print $1}')
 export TARGET_SPOOL=$(echo ${VALUES} | awk '{print $2}')
fi
eval gui_main Start
}


function check_server_running() {  
  tcp_running=
  _pid=$( f=${TARGET_SPOOL}/run/tcp.pid; test -f $f && cat $f ||: )
  [ -n "${_pid}" ] && _comm=$(ps -q ${_pid} -o comm=) || _comm="null"
  [ ${_comm} = "xinetd" -o ${_comm} = "mdsip" ] && tcp_running="${_comm} (${_pid})"
   
  udt_running=
  _pid=$( f=${TARGET_SPOOL}/run/udt.pid; test -f $f && cat $f ||: )
  [ -n "${_pid}" ] && _comm=$(ps -q ${_pid} -o comm=) || _comm="null"
  [ ${_comm} = "xinetd" -o ${_comm} = "mdsip" ] && udt_running="${_comm} (${_pid})"  

IS_SERVER_RUNNING="
$([ -n "${tcp_running}" ] && echo "TCP service active: ${tcp_running} \n" || echo "\n")
$([ -n "${udt_running}" ] && echo "UDT service active: ${udt_running} \n" || echo "\n")
"
}


# MAIN #
function gui_main() {
 check_server_running
[ $1 ] && DEF_ITEM="--default-item $1"
VALUES=$(${DIALOG} --cancel-label "Exit" \
	  --backtitle "${BACKTITLE}" --title "Main Menu" \
	  ${DEF_ITEM} \
	  --menu "\n\
Navigate options using [UP] [DOWN],[Enter] to Select items.\n\
\n\
${HOSTNAME}:${TARGET_PORT} [${TARGET_SPOOL}] \n\
\n\
${IS_SERVER_RUNNING} \n\
	  \n " \
	  20 50 3 \
	  Target      "Select ports " \
	  Start       "Start serer daemons " \
	  Stop        "Stop server daemons " \
3>&1 1>&2 2>&3)
opt=$?

if [ $opt = 0 ]; then
 case ${VALUES} in
  Target) gui_select_port;;
  Start)  eval xinetd; eval gui_main Stop;;
  Stop)   eval stop;   eval gui_main Start;;
  *) gui_main;;
 esac
fi
clear
}

function gui() { eval gui_main; }

# ///////////////////////////////////////////////////////////////////////////
# /// execute commands   ////////////////////////////////////////////////////
# ///////////////////////////////////////////////////////////////////////////

eval $1 ${@:2} ||:
