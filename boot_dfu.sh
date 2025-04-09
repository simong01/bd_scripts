#!/bin/sh

WAIT_TIME=10

check_result() {
	if [ $# -ne 2 ]; then
		echo "Oops not enough arguments [${#}] to check_result should be 2"
		exit 127
	fi
	local NAME=$1
	local RESULT=$2

	if [ $RESULT -ne 0 ]; then
		echo "Oops ${NAME} problems.[$RESULT]"
		exit $RESULT
	fi
}


wait4dfu() {

	loader_name="NONE"
	if [ -z "$1" ]; then
		echo "missing loader name!"
		return 1
	else
		loader_name="$1"
		echo -n "Waiting for DFU $loader_name ..."
	fi

	timeout_s=$WAIT_TIME
	while [ $timeout_s -gt 1 ]||[ $timeout_s -eq -1 ]; do
		if [ $timeout_s -gt 1 ]; then
			timeout_s=$(expr $timeout_s - 1)
			echo -n $timeout_s
		else
			echo -n "."
		fi
		check_4_loader=`sudo dfu-util -l | grep -c $loader_name`
		if [ $check_4_loader -eq 1 ]; then
			echo
			return 0
		fi
		sleep 1
	done
	echo
	echo "DFU $loader_name NOT FOUND!"
	return 2
}




wait4dfu bootloader
check_result "wait for bootloader" $?

sudo dfu-util -a bootloader -D tiboot3_dfu.bin
check_result "load bootloader" $?

wait4dfu tispl.bin
check_result "wait for tispl.bin" $?

sudo dfu-util -R -a tispl.bin -D tispl.bin
check_result "load tispl.bin" $?

wait4dfu u-boot.img
check_result "wait for u-boot.img" $?

sudo dfu-util -R -a u-boot.img -D u-boot.img
check_result "load u-boot.img" $?

echo "Done!"




