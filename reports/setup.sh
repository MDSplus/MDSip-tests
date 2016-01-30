



BACKTITLE=" MDSip throughput tests "
DIALOG=dialog

TARGET_HOST=${TARGET_HOST:=localhost}
TARGET_PORT=${TARGET_PORT:=8000}



TESTS="segment_size speed_spread speed_trend"

segment_size_desc=" TCP/UDT Throughput vs segment size "
speed_spread_desc=" Bandwidth distribution "
speed_trend_desc=" Throughput time trend "



# /////////////////////////////////////////////////////////////////////////// #
# /// SELECT TESTS  ///////////////////////////////////////////////////////// #
# /////////////////////////////////////////////////////////////////////////// #


function select_tests() {
TESTS=$(${DIALOG} --backtitle "${BACKTITLE}" \
		  --title "Tests selection" --checklist \
		  "Choose preferred tests to be launched" 15 60 4 \
		  "segment_size" "${segment_size_desc}" ON \
		  "speed_spread" "${speed_spread_desc}" ON \
		  "speed_trend"  "${speed_trend_desc}"  ON \
		  3>&1 1>&2 2>&3)
exitstatus=$?
eval main
}


function config_tests() {
VALUES=$(${DIALOG} --backtitle "${BACKTITLE}" \
		  --title "Tests selection" --menu \
		  "Choose test to edit configuration" 15 60 4 \
		  "segment_size" "${segment_size_desc}" \
		  "speed_spread" "${speed_spread_desc}" \
		  "speed_trend"  "${speed_trend_desc}"  \
		  3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
 make -C ${VALUES} setup
 eval config_tests
else
 eval main
fi
}




# /////////////////////////////////////////////////////////////////////////// #
# /// SELECT TARGET ///////////////////////////////////////////////////////// #
# /////////////////////////////////////////////////////////////////////////// #

function select_target() {
VALUES=$(${DIALOG} --ok-label "Submit" \
	  --backtitle "${BACKTITLE}" \
	  --title "Target selection" \
	  --form "Select tests default target host/port " 15 50 0 \
	  "Host:" 1 1	"$TARGET_HOST" 	1 10 20 0 \
	  "Port:" 2 1	"$TARGET_PORT" 	2 10 20 0 \
3>&1 1>&2 2>&3)

# export values just entered
export TARGET_HOST=$(echo ${VALUES} | awk '{print $1}')
export TARGET_PORT=$(echo ${VALUES} | awk '{print $2}')
eval main
}


# /////////////////////////////////////////////////////////////////////////// #
# /// MAIN ////////////////////////////////////////////////////////////////// #
# /////////////////////////////////////////////////////////////////////////// #

function main() {
VALUES=$(${DIALOG} --cancel-label "Exit" \
	  --backtitle "${BACKTITLE}" --title "Main Menu" \
	  --menu "Move using [UP] [DOWN],[Enter] to Select" 15 50 5 \
	  Target      "Select target host/port" \
	  SelectTests "Select active tests" \
	  ConfigTests "Configure tests parameters" \
	  " " "" \
	  Do "Preform tests" \
3>&1 1>&2 2>&3)
opt=$?

if [ $opt = 0 ]; then
 case ${VALUES} in
  Target) select_target;;
  SelectTests) select_tests;;
  ConfigTests) config_tests;;
  Do) make ${TESTS};;
  *) main;;
 esac
fi
exit 0

}



# DO ############
eval main
