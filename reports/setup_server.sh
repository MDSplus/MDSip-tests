#!/bin/sh

# exit on errors
set -e

SCRIPTNAME=$(basename "$0")
SCRIPT_DIR=$(dirname "$0")

SRCDIR=${SRCDIR:=${SCRIPT_DIR}/../}
BUILDDIR=${BUILDDIR:=$(pwd)}
SPOOLDIR=${SPOOLDIR:=$(pwd)/spool}

MDSPLUS_DIR=${MDSPLUS_DIR:=/usr/local}
export TARGET_PORT=${TARGET_PORT:=8000}

DIALOG=dialog

MDSIP=${MDSIP}
if [ -z "${MDSIP}" ]; then
[ -x ${MDSPLUS_DIR}/bin/mdsip ] && MDSIP=${MDSPLUS_DIR}/bin/mdsip
[ -x ${MDSPLUS_DIR}/bin32/mdsip ] && MDSIP=${MDSPLUS_DIR}/bin32/mdsip
[ -x ${MDSPLUS_DIR}/bin64/mdsip ] && MDSIP=${MDSPLUS_DIR}/bin64/mdsip
fi

print_help() {
cat << EOF
Usage: $SCRIPTNAME [options] [commands]

       options
       -------
       -h|--help)         get this help      
       -p|--port)         set server port to be used (default=8000)
       -m|--mdsplus)      set server dir (default=/usr/local)
       -s|--spooldir)     set spool dir to store sent data (default=<pwd>/spool)
       -v|--verbose)      show script source script
       
       commands
       --------       
       start              start server session
       xinetd             start server session using xinetd server
       stop               stop server session
       
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
                        # export TCP_WINDOW_SIZE=33554432
                        # export DEBUG_WINDOW_SIZE=true                 
                        shift
                        ;;
                -p|--port)
			TARGET_PORT=$2
                        shift 2
                        ;;
                -m|--mdsplus)
                        MDSPLUS_DIR=$2
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


## ensure mdsplusdir is set abs
MDSPLUS_DIR=$(cd ${MDSPLUS_DIR}; pwd)
MDS_PATH=${MDS_PATH:=${MDSPLUS_DIR}/tdi}


function set_path() {
   mkdir -p ${SPOOLDIR}
   mkdir -p ${SPOOLDIR}/log
   mkdir -p ${SPOOLDIR}/run
   export test_spool_path=${SPOOLDIR}
   export segment_size_path=${SPOOLDIR}
   export speed_spread_path=${SPOOLDIR}
   export speed_trend_path=${SPOOLDIR}
}





# ///////////////////////////////////////////////////////////////////////////
# /// start server       ////////////////////////////////////////////////////
# ///////////////////////////////////////////////////////////////////////////

function start() {
  eval set_path
  ${MDSIP} -p ${TARGET_PORT} -m -h ${MDSPLUS_DIR}/etc/mdsip.hosts -P tcp > ${SPOOLDIR}/tcp.log &
  echo "$!" > ${SPOOLDIR}/run/tcp.pid && echo "mdsip TCP server started"
  ${MDSIP} -p ${TARGET_PORT} -m -h ${MDSPLUS_DIR}/etc/mdsip.hosts -P udt > ${SPOOLDIR}/udt.log &
  echo "$!" > ${SPOOLDIR}/run/udt.pid && echo "mdsip UDT server started"
}


# ///////////////////////////////////////////////////////////////////////////
# /// start inted server      ///////////////////////////////////////////////
# ///////////////////////////////////////////////////////////////////////////

XINETD_CONF="
defaults
{
        log_type                = FILE ${SPOOLDIR}/log/mdsip_xinetd.log
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

        user             = ${USER}
	port             = ${TARGET_PORT}
        server           = ${SPOOLDIR}/mdsipd
	server_args      = ${TARGET_PORT} tcp ${SPOOLDIR}/mdsip.hosts ${SPOOLDIR}/log
}

# Currently UDT is not supported in xinetd connection #
# service mdsip_udt
# {
#        disable          = no
#        protocol         = udp
#        socket_type      = dgram
#        wait             = yes
#        type             = UNLISTED

#        user             = ${USER}
#        port             = ${TARGET_PORT}
#        server           = ${SPOOLDIR}/mdsipd
#        server_args      = ${TARGET_PORT} udt ${SPOOLDIR}/mdsip.hosts ${SPOOLDIR}/log
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
source $MDSPLUS_DIR/setup.sh
exec   ${MDSIP} -p \$1 -P \$2 -h \$3 -c 0 >> \$4/tcp.access 2>> \$4/tcp.errors
"



function xinetd() {
  eval set_path
  echo "${XINETD_CONF}" > ${SPOOLDIR}/mdsipd.xinetd
  echo "${MDSIP_HOSTS}" > ${SPOOLDIR}/mdsip.hosts
  echo "${MDSIPD_SCRIPT}" > ${SPOOLDIR}/mdsipd
  chmod +x ${SPOOLDIR}/mdsipd
  
  mkdir -p ${SPOOLDIR}/log
  
  # UDT session
  ${MDSIP} -p ${TARGET_PORT} -P udt -m -h ${SPOOLDIR}/mdsip.hosts \
    >> ${SPOOLDIR}/log/udt.access 2>>${SPOOLDIR}/log/udt.errors &
   echo "$!" > ${SPOOLDIR}/run/udt.pid && echo "mdsip UDT server started"
  
  # TCP session in xinetd
  sh -c "xinetd -f ${SPOOLDIR}/mdsipd.xinetd -pidfile ${SPOOLDIR}/run/tcp.pid" && \
   echo "mdsip TCP server started"
}





# ///////////////////////////////////////////////////////////////////////////
# /// STOP   ////////////////////////////////////////////////////////////////
# ///////////////////////////////////////////////////////////////////////////

function stop() {
_pidf=${SPOOLDIR}/run/tcp.pid
[ -f ${_pidf} ] && ( kill $(cat ${_pidf}); rm -f ${_pidf} )
_pidf=${SPOOLDIR}/run/udt.pid
[ -f ${_pidf} ] && ( kill $(cat ${_pidf}); rm -f ${_pidf} )
}


# ///////////////////////////////////////////////////////////////////////////
# /// CLEAN  ////////////////////////////////////////////////////////////////
# ///////////////////////////////////////////////////////////////////////////

function clean() {
 echo "Not implemented yet .. please remove files by hand"
}



# ///////////////////////////////////////////////////////////////////////////
# /// GUI    ////////////////////////////////////////////////////////////////
# ///////////////////////////////////////////////////////////////////////////

BACKTITLE=" MDSip throughput tests - Server configuration "
DIALOG=dialog

# SELECT PORT #
function gui_select_port() {
VALUES=$(${DIALOG} --ok-label "Submit" \
	  --backtitle "${BACKTITLE}" \
	  --title "Server port selection" \
	  --form "\nSelect tests default server port \n " 15 50 0 \
	  "Port:"     2 1	"$TARGET_PORT" 	2 10 20 0 \
3>&1 1>&2 2>&3)
opt=$?

if [ $opt = 0 ]; then
 export TARGET_PORT=$(echo ${VALUES} | awk '{print $2}')
fi
eval gui_main Start
}

IS_SERVER_RUNNING=

# MAIN #
function gui_main() {
[ -n "$1" ] && DEF_ITEM="--default-item $1"
VALUES=$(${DIALOG} --cancel-label "Exit" \
	  --backtitle "${BACKTITLE}" --title "Main Menu" \
	  ${DEF_ITEM} \
	  --menu "\n\
Navigate options using [UP] [DOWN],[Enter] to Select items.\
The current selected connection port is ${TARGET_PORT}\n \
\n ${IS_SERVER_RUNNING} \n \
	  \n " \
	  18 50 5 \
	  Target      "Select ports " \
	  Start       "Start serer daemons " \
	  Stop        "Stop server daemons " \
3>&1 1>&2 2>&3)
opt=$?

if [ $opt = 0 ]; then
 case ${VALUES} in
  Target) gui_select_port;;
  Start)  eval start; IS_SERVER_RUNNING="[Server running]"; eval gui_main Stop;;
  Stop)   eval stop;  IS_SERVER_RUNNING=""; eval gui_main Start;;
  *) gui_main;;
 esac
fi
clear
}

function gui() { eval gui_main; }

# ///////////////////////////////////////////////////////////////////////////
# /// execute commands   ////////////////////////////////////////////////////
# ///////////////////////////////////////////////////////////////////////////

eval $1 ${@:2}

