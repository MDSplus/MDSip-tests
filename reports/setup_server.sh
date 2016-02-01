#!/bin/sh

# exit on errors
set -e

SCRIPTNAME=$(basename "$0")
SCRIPT_DIR=$(dirname "$0")

SRCDIR=${SRCDIR:=${SCRIPT_DIR}/../}
BUILDDIR=${BUILDDIR:=$(pwd)}
SPOOLDIR=${SPOOLDIR:=$(pwd)/spool}

MDSPLUS_DIR=${MDSPLUS_DIR:=/usr/local}
PORT=8000


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
                        PORT=$2
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
  ${MDSPLUS_DIR}/bin/mdsip -p ${PORT} -m -h ${MDSPLUS_DIR}/etc/mdsip.hosts -P tcp > ${SPOOLDIR}/tcp.log &
  ${MDSPLUS_DIR}/bin/mdsip -p ${PORT} -m -h ${MDSPLUS_DIR}/etc/mdsip.hosts -P udt > ${SPOOLDIR}/udt.log &
}


# ///////////////////////////////////////////////////////////////////////////
# /// start inted server      ///////////////////////////////////////////////
# ///////////////////////////////////////////////////////////////////////////

XINETD_CONF="
defaults
{
        log_type                = FILE mdsip_xinetd.log
        log_on_success          = HOST PID
        log_on_failure          = HOST
}

service mdsip
{
        disable          = no
        socket_type      = stream
        wait             = no
        cps              = 10000 1
        instances        = UNLIMITED
        per_source       = UNLIMITED
        type             = UNLISTED
        flags            = KEEPALIVE NODELAY NOLIBWRAP

        user             = ${USER}
        port             = ${PORT}
        protocol         = tcp
        server           = ${MDSPLUS_DIR}/bin/mdsipd
        server_args      = mdsip tcp ${SPOOLDIR}/log ${MDSPLUS_DIR}/etc/mdsip.hosts
}


service mdsip_udt
{
        disable          = no
        socket_type      = dgram
        wait             = yes
        instances        = 1
        per_source       = 1
        type             = UNLISTED
#        flags            =

        user             = ${USER}
        port             = ${PORT}
        protocol         = udp
        server           = ${MDSPLUS_DIR}/bin/mdsipd
        server_args      = mdsip udt ${SPOOLDIR}/log ${MDSPLUS_DIR}/etc/mdsip.hosts
}
"

function xinetd() {
  eval set_path
  echo "${XINETD_CONF}" > ${SPOOLDIR}/mdsipd.xinetd
  
  sh -c "xinetd -d -f ${SPOOLDIR}/mdsipd.xinetd"
}



# ///////////////////////////////////////////////////////////////////////////
# /// execute commands   ////////////////////////////////////////////////////
# ///////////////////////////////////////////////////////////////////////////

eval $1 ${@:2}
exit
