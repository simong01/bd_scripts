#!/bin/sh

variant=unknown

variants="62 6x 91 93 95 510 700 8m"

vnames="Carbon_AM625 Nitrogen_6X Nitrogen_91 Nitrogen_93 Nitrogen_95 Tungsten_510 Tungsten_700 Nitrogen_8M_series"

NPROC=$(($(nproc) - 4))

NFSROOT="/srv/nfs"
TFTPROOT="/srv/tftp"

# Only build the main kernel and dtbs and copy to tftp
KERNEL_ONLY=0

# Clean module directories on build and NFS
CLEAN_MODULES=1

#	make defconfig
#	make boundary_defconfig
#       make ezurio_defconfig
#	make imx_v8_defconfig
# config_target=boundary_defconfig
# config_target=ezurio_defconfig
# config_target=defconfig
##################################################################
# Currently only for 8m variants

# imx-gpu-viv
IMX_GPU_VIV=1
IMX_GPU_VIV_BASE_PWD=~/githome/kernel-module-imx-gpu-viv

# isp-vvcam
IMX_VVCAM=1
IMX_VVCAM_BASE_PWD=~/githome/isp-vvcam/vvcam/v4l2

##################################################################
TAC5X1X=0
TAC5X1X_BASE_PWD=~/githome/cp_linux-som-external/package-3rd-party/tac5x1x/files
# TAC5X1X_BASE_PWD=~/githome/tac5x1x-linux-driver/src
##################################################################
#
# SW
# https://github.com/rfpros/cp_release-backports-unreleased
#
# FW
# https://github.com/rfpros/cp_release-radio_firmware-unreleased
#
# Build Laird out of tree module. And copy in firmware.
# BD_SDMAC is	bdsdmac
# LWB5 is	brcmfmac ??
# IF573 is 	lwb
# LWB5+(Summit) lwb ??
# IF513 is 	lwb ??
# TI351		sona_ti
# NX611		sona_nx611
# ST60-SIPT	summit60
#
# NRC + NX611	nrc7292_sona_nx611
#
LAIRD_WIFI=1
# LAIRD_WIFI_DEFCONFIG=regression-test
# bdimx8 in next release
# LAIRD_WIFI_DEFCONFIG=morse
# LAIRD_WIFI_DEFCONFIG=sona_nx611
# LAIRD_WIFI_DEFCONFIG=bdimx6
# LAIRD_WIFI_DEFCONFIG=bdimx8
# LAIRD_WIFI_DEFCONFIG=sona_ti
# LAIRD_WIFI_DEFCONFIG=lwb
# LAIRD_WIFI_DEFCONFIG=summit60
# LAIRD_WIFI_DEFCONFIG=nrc7292_sona_nx611
LAIRD_WIFI_DEFCONFIG=regression-test

#LAIRD_WIFI_BASE_PWD=~/Downloads/nx611-eng-11.0.0.263-20240411/release/laird-backport-11.0.0.263
#LAIRD_WIFI_FW_PWD=~/Downloads/summit-backports-12.103.0.5

# Un-released SW
LAIRD_WIFI_BASE_PWD=~/githome/cp_release-backports-unreleased/backport

# Released SW URL (TAR FILES)
# https://github.com/Ezurio/summit_backports_release

# Released public GIT SRC then checkout tag eg. LRD-REL-12.103.0.5
# https://github.com/Ezurio/summit_backports_release.git

# Released FW URL (TAR FILES)
# https://github.com/Ezurio/radio_firmware_release

# Released public GIT FW then checkout tag eg. LRD-REL-12.103.0.5
# https://github.com/Ezurio/radio_firmware_release.git

# Engineering release SW
# LAIRD_WIFI_BASE_PWD=~/Downloads/ti351_eng-12.0.0.113-20241113/ti351-radio-stack-eng-12.0.0.113/release/summit-backports-12.0.0.113


#LAIRD_WIFI_BASE_PWD=~/Downloads/if513-radio-stack-eng-12.0.53.5/release/summit-backports-12.0.53.5
#LAIRD_WIFI_FW_PWD=~/Downloads/if513-radio-stack-eng-12.0.53.5/release/summit-if513-sdio-firmware-12.0.53.5

# Engineering release FW
LAIRD_WIFI_FW_BASE_PWD=~/githome/cp_release-radio_firmware-unreleased

# If below is set then it is multiple FW directories
LAIRD_WIFI_FW_LIST="summit-nx61x-firmware summit-if573-sdio-firmware summit-ti351-US-firmware"

# Else set below to point to one directory

# LAIRD_WIFI_FW_PWD=~/Downloads/ti351_eng-12.0.0.113-20241113/ti351-radio-stack-eng-12.0.0.113/release/summit-ti351-WW-firmware-12.0.0.113

# LAIRD_WIFI_FW_PWD=${LAIRD_WIFI_FW_BASE_PWD}/morse
# LAIRD_WIFI_FW_PWD=${LAIRD_WIFI_FW_BASE_PWD}/sona-nx61x-firmware # OLD NAME !!
# LAIRD_WIFI_FW_PWD=${LAIRD_WIFI_FW_BASE_PWD}/summit-nx61x-firmware
# LAIRD_WIFI_FW_PWD=${LAIRD_WIFI_FW_BASE_PWD}/summit-if573-sdio-firmware
# LAIRD_WIFI_FW_PWD=${LAIRD_WIFI_FW_BASE_PWD}/summit-ti351-US-firmware
# LAIRD_WIFI_FW_PWD=${LAIRD_WIFI_FW_BASE_PWD}/summit-if513-sdio-firmware
# LAIRD_WIFI_FW_PWD=${LAIRD_WIFI_FW_BASE_PWD}/summit-lwb5plus-sdio-sa-m2-firmware
# LAIRD_WIFI_FW_PWD=${LAIRD_WIFI_FW_BASE_PWD}/laird-lwb5plus-sdio-sa-firmware # OLD NAME !!
# LAIRD_WIFI_FW_PWD=${LAIRD_WIFI_FW_BASE_PWD}/summit-lwb5plus-sdio-sa-firmware
# LAIRD_WIFI_FW_PWD=${LAIRD_WIFI_FW_BASE_PWD}/laird-if573-sdio-firmware # OLD NAME !!
# LAIRD_WIFI_FW_PWD=${LAIRD_WIFI_FW_BASE_PWD}/summit-60-radio-firmware-sdio-uart
# LAIRD_WIFI_FW_PWD=${LAIRD_WIFI_FW_BASE_PWD}/summit-60-radio-firmware-sdio-sdio


# TODO Copy all relevant firmwares
# LAIRD_WIFI_FW_PWD=~/Downloads/laird-lwb5plus-sdio-sa-firmware-11.171.0.19
#
##########################################################################################################################################################################################
#
# NewRaCom Wifi (HALO / 802.11ah) (SPI)
NRC_WIFI=0
NRC_BUILD_ORIGINAL=0 # 0 = DO NOT BUILD here; 1 = DO build here
NRC_WIFI_BASE_PWD=~/githome/nrc7394_sw_pkg/package/src/nrc
# NRC_WIFI_FW_PWD=~/githome/nrc7394_sw_pkg/package/evk/binary
NRC_WIFI_FW_PWD=~/githome/nrc7394_sw_pkg/package/evk/sw_pkg/nrc_pkg/sw/firmware
NRC_WIFI_SCR_PWD=~/githome/nrc7394_sw_pkg/package/evk/sw_pkg/nrc_pkg
NRC_WIFI_CLI_APP=1
#
##########################################################################################################################################################################################
#
##########################################################################################################################################################################################
#
# Morse Wifi (HALO / 802.11ah) (SDIO)
MORSE_WIFI=0
MORSE_WIFI_BASE_PWD=~/Downloads/morse/morsemicro_driver_rel_1_12_4_2024_Jun_11
MORSE_WIFI_FW_PWD=~/Downloads/morse/firmware_binaries_1_12_4
#
##########################################################################################################################################################################################
#
# OLD !!! NXP IW611 Wifi USE LAIRD_WIFI instead

NXP_WIFI=0
NXP_WIFI_FW_PWD=~/Downloads/nx611-eng-11.0.0.263-20240411/release
NXP_WIFI_BASE_PWD=~/githome/mwifiex/mxm_wifiex/wlan_src
# NXP_WIFI_BASE_PWD=${NXP_WIFI_FW_PWD}/laird-backport-11.0.0.263
##########################################################################################################################################################################################

# QCACLD_BASE_PWD=/home/simong/githome/qcacld-2.0/backport
#

# Install the old cypress fw
# LWB5+
CYPRESS_FW=0
CYPRESS_FW_BASE_PWD=/home/simong/githome/cypress-firmware

# Intel Wifi (> 6.1 kernel)
IWL_WIFI=0
IWL_WIFI_FW=0
IWL_WIFI_FW_VER=iwlwifi-ty-59.601f3a66.0
IWL_WIFI_FW_BASE_PWD=/home/simong/Downloads/

##########################################################################################################################################################################################

check_result() {
	if [ $# -ne 2 ]; then
		echo "Oops not enough arguments [${#}] to check_result should be 2"
		exit 127
	fi
	local NAME=$1
	local RESULT=$2

	if [ $RESULT -ne 0 ]; then
		echo "Oops ${NAME} compile problems.[$RESULT]"
		cd $KERNEL_SRC
		exit $RESULT
	fi
}


# Cross-Compile Environment
set_cc_env() {
	cc_env=$1

	export KERNEL_SRC=$PWD

	# Ubuntu is export INSTALL_MOD_PATH=$PWD/ubuntunize64/linux-staging
	export INSTALL_MOD_PATH=$KERNEL_SRC/out

	if [ $cc_env = 64 ]; then
		export ARCH=arm64

		export CROSS_COMPILE=aarch64-linux-gnu-

	else

		export ARCH=arm

		export CROSS_COMPILE=arm-linux-gnueabihf-
	fi

	export KERNEL_SRC=$PWD

	# For NXP IW611 and TI Rogue
	export KERNELDIR=$PWD

	export KLIB=$KERNEL_SRC/out

	export KLIB_BUILD=$KERNEL_SRC

	# Boris TI tac5x1x
	export KERNEL_PATH=$KERNEL_SRC

	# NRC7394
	export KDIR=$KERNEL_SRC

	echo "Cross Compile environment ${cc_env}bit set"
}

if [ ! -f $0 ]; then
	# "you sourced me"
	cc_env=64
	if [ -n "$1" ]&&[ $1 == 32 ]; then
		cc_env=32
	fi
	set_cc_env $cc_env
	return
fi

varient_name=unset

if [ -n "$1" ]; then

	if [ $1 = "-h" ]; then
		echo "Possible variants:\n"
		i=1
		for this_varient in $variants; do
			echo -n "$this_varient\t- "
			echo ${vnames} | cut -d' ' -f${i}
			i=$((i+1))
		done
		echo
		exit
	fi

	variant=$1
	found=0

	i=1
	for item in $variants; do
		if [ $item = $variant ]; then
			varient_name=`echo ${vnames} | cut -d' ' -f${i}`
			found=1
			break
		fi
		i=$((i+1))
	done
	if [ $found -eq 0 ]; then
		variant=unknown
	fi
fi
TARGET=""
if [ -n "$2" ]; then
	TARGET=$2
	# Then only make the kernel
	# and copy it and dtbo to TFTP
	KERNEL_ONLY=1
fi

echo "Variant is $variant \"$varient_name\""

if [ $variant = "unknown" ]; then
	echo
	echo "For help ..."
	echo
	echo "$0 -h"
	echo
	exit 127
fi

cc_env=64

if [ $variant = "6x" ]; then
	cc_env=32
fi

set_cc_env $cc_env

if [ $variant = "62" ]; then
	config_target="defconfig ezurio_ti_arm64_prune.config"
	# config_target="defconfig ti_arm64_prune.config"
	echo "Autoconfig CARBON : $config_target"
fi

# if config_target is not set
# try to set it based on git branch name
#
if [ -z "$config_target" ]; then
	check_boundary=`git branch --show-current | grep -c boundary`
	if [ $check_boundary -eq 1 ]; then
		config_target=boundary_defconfig
		echo "Autoconfig : $config_target"
	fi
fi
if [ -z "$config_target" ]; then
	check_ezurio=`git branch --show-current | grep -c ezurio`
	if [ $check_ezurio -eq 1 ]; then
		config_target=ezurio_defconfig
		echo "Autoconfig : $config_target"
	fi
fi
if [ -z "$config_target" ]; then
	echo "Cannot figure out correct target. Assuming ezurio_defconfig"
	read -p "Press enter to continue" ans
	config_target=ezurio_defconfig
fi
#

if [ $CLEAN_MODULES -eq 1 ]; then
	echo -e "\nCLEANING Kernel modules output directory $INSTALL_MOD_PATH\n"
	sudo rm -rf ${INSTALL_MOD_PATH}/*
fi

# make imx93_bd_smarc_defconfig
#if [ $variant = "510" ]; then
#	make defconfig
#else
#	make defconfig
#	make boundary_defconfig
#	make imx_v8_defconfig
#fi
echo -e "\nConfiguring kernel $config_target ... "
make $config_target

check_result Linux-config $?

if [ $cc_env = 32 ]; then
	echo -e "\nBuilding 32 bit kernel -j $NPROC $TARGET ... "
	make zImage modules dtbs -j $NPROC $TARGET
else
	# make -j 16
	echo -e "\nBuilding 64 bit kernel -j $NPROC $TARGET ... "
	make DTC_FLAGS="-@" -j $NPROC $TARGET
fi

check_result Linux $?

kernel_release=`cat include/config/kernel.release`

make modules_install
check_result Linux-modules_install $?

case $variant in
	62)
		DTBS="ti/k3-am625-sk.dtb ti/k3-am625-sk-m2-cc3301.dtbo ti/k3-am625-carbon.dtb ti/k3-am625-carbon-*.dtbo"
		SUBDIR="carbon62"
	;;

	6x)
		DTBS="imx6*nitrogen*.dtb imx6q-ltch.dtb imx6ull-jde.dtb"
		SUBDIR="nitrogen6x"
	;;

	8m)
		DTBS="freescale/imx8*nitrogen*.dtb freescale/imx8mm-geno.dtb freescale/imx8mp-mmr.dtb"
		DTBS="${DTBS} freescale/imx8mp-abiomed.dtb freescale/imx8mm-ash.dtb freescale/imx8ulp-porpoise.dtb"
		SUBDIR="nitrogen8m"
	;;

	91)
		DTBS="freescale/imx91-nitrogen-smarc*.dtb"
		SUBDIR="nitrogen93"
	;;

	93)
		DTBS="freescale/imx93-bdx.dtb freescale/imx93-nitrogen-smarc*.dtb freescale/imx93-nvc.dtb"
		SUBDIR="nitrogen93"
	;;

	95)
		DTBS="freescale/imx95-nitrogen-smarc*.dtb*"
		SUBDIR="nitrogen95"
	;;

	510)
		DTBS="mediatek/mt8370-tungsten-smarc.dtb"
		SUBDIR="tungsten510"
	;;

	700)
		DTBS="mediatek/mt8390-tungsten-smarc.dtb"
		SUBDIR="tungsten700"
	;;

	*)
		echo "Oops unknown variant : $variant"
		exit 64
	;;
esac

if [ $KERNEL_ONLY -eq 0 ]; then
	#########################################################################
	#
	# Common stuff
	if [ $IWL_WIFI -eq 1 ]; then
		cd ../backport-iwlwifi

		make defconfig-iwlwifi-public
		make -j $NPROC

		check_result iwlwifi $?

		make modules_install

		if [ $IWL_WIFI_FW -eq 1 ]; then
			sudo cp ${IWL_WIFI_FW_BASE_PWD}/${IWL_WIFI_FW_VER}/iwlwifi-ty-*.ucode ${NFSROOT}/${SUBDIR}/lib/firmware/
		fi
		cd $KERNEL_SRC
	fi
	#########################################################################

	# Common iMX stuff
	if [ $variant = 8m ]; then
		if [ $IMX_GPU_VIV -eq 1 ]; then
			cd $IMX_GPU_VIV_BASE_PWD

			export CONFIG_MXC_GPU_VIV=m

			make -j $NPROC

			check_result imx-gpu-viv $?

			make modules_install

			cd $KERNEL_SRC
		fi

		if [ $IMX_VVCAM -eq 1 ]; then
			cd $IMX_VVCAM_BASE_PWD
			make -j $NPROC

			check_result imx-vvcam $?

			make modules_install

			cd $KERNEL_SRC
		fi

	fi

	# iMX 91, 93, 95, 8m or Carbon 62
	if [ $variant = 91 ]||[ $variant = 93 ]||[ $variant = 95 ]||[ $variant = 8m ]||[ $variant = "62" ]; then
		if [ $TAC5X1X -eq 1 ]; then
			###############################################################
			# TAC5X1X
			echo -e "\nBuilding TAC5X1X ...\n"

			cd ${TAC5X1X_BASE_PWD}

			TAC5X1X_GIT_VER=`git symbolic-ref -q --short HEAD`

			make clean

			make

			check_result tac5x1x $?

			make modules_install

			check_result "tac5x1x install" $?

			cd $KERNEL_SRC

		fi
		if [ $LAIRD_WIFI -eq 1 ]; then
			###############################################################
			# Laird WiFi
			echo -e "\nBuilding Laird WiFi defconfig-${LAIRD_WIFI_DEFCONFIG} ...\n"

			cd ${LAIRD_WIFI_BASE_PWD}

			LAIRD_WIFI_GIT_VER=`git symbolic-ref -q --short HEAD || git describe --tags --exact-match`
			result=$?
			if [ $result -eq 128 ]; then
				echo "NOT a GIT repo"
				LAIRD_WIFI_GIT_VER="from ${LAIRD_WIFI_BASE_PWD}"
			fi

			make mrproper

			check_result laird_wifi_driver_clean $?

			make defconfig-${LAIRD_WIFI_DEFCONFIG}

			check_result laird_wifi_defconfig $?

			make -j $NPROC

			check_result laird_wifi_driver $?

			make modules_install

			cd $KERNEL_SRC

			if [ -n "$LAIRD_WIFI_FW_LIST" ]; then
				for item in $LAIRD_WIFI_FW_LIST; do
					LAIRD_WIFI_FW_PWD="${LAIRD_WIFI_FW_BASE_PWD}/${item}"
					cd ${LAIRD_WIFI_FW_PWD}
					check_result laird_wifi_firmware $?
					sudo cp -a lib/* ${NFSROOT}/${SUBDIR}/lib/
				done
				LAIRD_WIFI_FW_GIT_VER=`git symbolic-ref -q --short HEAD || git describe --tags --exact-match`
			else

				# Copy laird-firmware
				cd ${LAIRD_WIFI_FW_PWD}

				check_result laird_wifi_firmware $?

				LAIRD_WIFI_FW_GIT_VER=`git symbolic-ref -q --short HEAD || git describe --tags --exact-match`

				sudo cp -a lib/* ${NFSROOT}/${SUBDIR}/lib/

			fi

			cd $KERNEL_SRC

			###############################################################
		fi

		if [ $NXP_WIFI -eq 1 ]; then
			###############################################################
			# NXP WiFi

			cd ${NXP_WIFI_BASE_PWD}

			make clean

			check_result nxp_wifi_driver_clean $?

			# make defconfig-${LAIRD_WIFI_DEFCONFIG}

			make -j $NPROC

			check_result nxp_wifi_driver $?

			make build

			#sudo cp ../bin_wlan/*.ko ${NFSROOT}/${SUBDIR}/lib/modules/${kernel_release}/kernel/drivers/net/wireless/
			sudo cp ../bin_wlan/*.ko ${KERNEL_SRC}/out/lib/modules/${kernel_release}/kernel/drivers/net/wireless/
			# sudo cp -r drivers/net/wireless/laird/mwifiex ${KERNEL_SRC}/out/lib/modules/${kernel_release}/kernel/

			cd $KERNEL_SRC

			# Copy wifi-firmware
			sudo cp -a ${NXP_WIFI_FW_PWD}/lib/* ${NFSROOT}/${SUBDIR}/lib/

			###############################################################
		fi

		if [ $CYPRESS_FW -eq 1 ]; then
			###############################################################
			# Cypress FW

			cd $CYPRESS_FW_BASE_PWD

			sudo DESTDIR=${NFSROOT}/${SUBDIR} make install

			check_result cypress_fw $?

			cd $KERNEL_SRC

			###############################################################
		fi

		if [ $NRC_WIFI -eq 1 ]; then
			###############################################################
			# NRC Wifi

			if [ $NRC_BUILD_ORIGINAL -eq 1 ]; then

				cd $NRC_WIFI_BASE_PWD

				make clean

				check_result nrc_wifi_driver_clean $?

				# Build against Summit WiFi drivers ??
				# if [ $LAIRD_WIFI -eq 1 ]; then

				# 	export NOSTDINC_FLAGS="-I${LAIRD_WIFI_BASE_PWD}/backport-include -I ${LAIRD_WIFI_BASE_PWD}/include -include backport/backport.h"
				# fi
				#

				make -j $NPROC

				check_result nrc_wifi_driver_compile $?

				make modules_install

				check_result nrc_wifi_driver_install $?

				# Clean-up src build
				make clean

				cd $KERNEL_SRC

			fi

			# Copy wifi-firmware
			sudo cp -va ${NRC_WIFI_FW_PWD}/nrc* ${NFSROOT}/${SUBDIR}/lib/firmware/

			# Copy scripts etc.
			# sudo cp -a ${NRC_WIFI_SCR_PWD} ${NFSROOT}/${SUBDIR}/root/

			# More hacks

			if [ $NRC_BUILD_ORIGINAL -eq 1 ]; then
				sudo cp -va ${KERNEL_SRC}/out/lib/modules/${kernel_release}/updates/nrc.ko ${NFSROOT}/${SUBDIR}/root/nrc_pkg/sw/driver/
			else
				sudo cp -va ${KERNEL_SRC}/out/lib/modules/${kernel_release}/updates/drivers/net/wireless/nrc/nrc7292/nrc.ko ${NFSROOT}/${SUBDIR}/root/nrc_pkg/sw/driver/
			fi

			cd ${NFSROOT}/${SUBDIR}/lib/firmware/

			# Use the normal binary file, instead of the eeprom one (nrc7394_cspi_eeprom.bin)
			sudo rm uni_s1g.bin
			sudo ln -s nrc7394_cspi.bin uni_s1g.bin
			# Using a uni_s1g.bin from the EVK HW board
			cd -

			if [ $NRC_WIFI_CLI_APP -eq 1 ]; then
				cd ${NRC_WIFI_BASE_PWD}/../cli_app
				export CC=${CROSS_COMPILE}gcc
				export AR=${CROSS_COMPILE}ar

				make

				check_result nrc_wifi_cli_app_compile $?

				sudo cp -va cli_app ${NFSROOT}/${SUBDIR}/root/nrc_pkg/script/

				make clean

			fi

			cd $KERNEL_SRC

		fi

		if [ $MORSE_WIFI -eq 1 ]; then
			###############################################################
			# MORSE Wifi

			cd $MORSE_WIFI_BASE_PWD

			make clean

			check_result morse_wifi_driver_clean $?

			make -j $NPROC MORSE_TRACE_PATH=`pwd` CONFIG_WLAN_VENDOR_MORSE=m \
				CONFIG_MORSE_SDIO=y CONFIG_MORSE_USER_ACCESS=y \
				CONFIG_MORSE_SDIO_ALIGNMENT=4 CONFIG_MORSE_VENDOR_COMMAND=y DEBUG=y

			check_result morse_wifi_driver_compile $?

			make modules_install

			check_result morse_wifi_driver_install $?

			cd $KERNEL_SRC

			# Copy wifi-firmware
			sudo mkdir ${NFSROOT}/${SUBDIR}/lib/firmware/morse
			sudo cp -a ${MORSE_WIFI_FW_PWD}/* ${NFSROOT}/${SUBDIR}/lib/firmware/morse/

		fi
	fi
	#

	# Common Mediatek stuff
	if [ $variant = 510 ]||[ $variant = 700 ]; then

		cd ../mtk-mali-gpu-driver
		make -j $NPROC

		check_result mtk-mali-gpu-driver $?

		make modules_install -j2

		cd ../mtk-vcodec-driver

		TARGET_PLATFORM=mt8395 make -j $NPROC

		check_result mtk-vcodec-driver $?

		make modules_install

		cd ../mtk-vcu-driver

		TARGET_PLATFORM=mt8395 EXTRA_SYMBOLS_PATH=../mtk-vcodec-driver/Module.symvers make -j16

		check_result mtk-vcu-driver $?

		make modules_install

		cd ../mtk-camisp-driver

		PLATFORM=mt8188 make -j $NPROC

		check_result mtk-camisp-driver $?

		make modules_install

		cd $KERNEL_SRC

		# Clean up the DTBOs
		sudo rm ${TFTPROOT}/${SUBDIR}/devicetree/*

		echo "\nCopying DTBOs from arch/arm64/boot/dts/mediatek/mt83x0-tungsten-smarc"
		sudo cp arch/arm64/boot/dts/mediatek/mt83x0-tungsten-smarc/*.dtbo ${TFTPROOT}/${SUBDIR}/devicetree

		if [ $variant = 510 ]; then
			echo "\nCopying DTBOs from arch/arm64/boot/dts/mediatek/mt8370"
			sudo cp arch/arm64/boot/dts/mediatek/mt8370/*.dtbo ${TFTPROOT}/${SUBDIR}/devicetree
		elif [ $variant = 700 ]; then
			echo "\nCopying DTBOs from arch/arm64/boot/dts/mediatek/mt8390"
			sudo cp arch/arm64/boot/dts/mediatek/mt8390/*.dtbo ${TFTPROOT}/${SUBDIR}/devicetree
		fi
	fi

	# Common TI stuff
	if [ $variant = "62" ]; then

		echo
		echo " #################################   ti-img-rogue-driver ##################################"
		echo

		# git clone https://git.ti.com/git/graphics/ti-img-rogue-driver.git -b linuxws/scarthgap/k6.6/24.1.6554834

		cd ../ti-img-rogue-driver

		TARGET_PRODUCT="am62_linux"

		PVR_BUILD="release"
		# PVR_WS="lws-generic"
		PVR_WS="wayland"

		export SYSROOT="${NFSROOT}/${SUBDIR}"
		export DISCIMAGE=${KERNEL_SRC}/out

		make -j $NPROC BUILD=${PVR_BUILD} PVR_BUILD_DIR=${TARGET_PRODUCT} WINDOW_SYSTEM=${PVR_WS} SYSROOT=${SYSROOT}

		check_result ti-img-rogue-driver $?

		cd build/linux/${TARGET_PRODUCT}

		sudo -E make install BUILD=${PVR_BUILD}

		check_result ti-img-rogue-driver-mod-install $?

		cd $KERNEL_SRC

		make modules_install

		check_result ti-img-rogue-driver-linux-mod-install $?

	fi

fi # end KERNEL_ONLY=0

if [ $CLEAN_MODULES -eq 1 ]; then
	echo -e "\nCLEANING Kernel modules NFS directory ${NFSROOT}/${SUBDIR}/lib/modules/\n"
	sudo rm -rf ${NFSROOT}/${SUBDIR}/lib/modules/*
fi

sudo cp -av out/lib/modules/${kernel_release} ${NFSROOT}/${SUBDIR}/lib/modules/

if [ $cc_env = 32 ]; then
	sudo cp arch/arm/boot/zImage ${TFTPROOT}/${SUBDIR}/
else
	sudo cp arch/arm64/boot/Image ${TFTPROOT}/${SUBDIR}/
fi

echo "\nCopying ${cc_env}bit DTBs ..."
for i in $DTBS; do
	if [ $cc_env = 32 ]; then
		arm_bits=''
	else
		arm_bits=64
	fi
	sudo cp -v arch/arm${arm_bits}/boot/dts/${i} ${TFTPROOT}/${SUBDIR}/
done
echo "----------------"
echo

sudo chown -R root:root ${NFSROOT}/${SUBDIR}/lib/modules/${kernel_release}


echo "\nBuilt kernel $kernel_release using config : $config_target\n"

if [ $KERNEL_ONLY -eq 0 ]; then
	if [ $TAC5X1X -eq 1 ]; then
		echo "\nBuilt tac5x1x $TAC5X1X_GIT_VER"
	fi
	if [ $LAIRD_WIFI -eq 1 ]; then
		echo "\nBuilt Laird Wifi $LAIRD_WIFI_GIT_VER defconfig-${LAIRD_WIFI_DEFCONFIG}"

		echo -n "Using Laird FW   $LAIRD_WIFI_FW_GIT_VER from"
		if [ -n "$LAIRD_WIFI_FW_LIST" ]; then
			echo " ${LAIRD_WIFI_FW_BASE_PWD}/[${LAIRD_WIFI_FW_LIST}]\n"
		else
			echo " ${LAIRD_WIFI_FW_PWD}\n"
		fi
	fi
	if [ $MORSE_WIFI -eq 1 ]; then
		echo "\nBuilt Morse Wifi (802.11ah) using driver source at $MORSE_WIFI_BASE_PWD"
		echo "And Firmware from $MORSE_WIFI_FW_PWD"
	fi
else
	echo "\nKernel ONLY build!"
fi

echo "Done!"

