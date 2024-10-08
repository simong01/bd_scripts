#!/bin/sh

variant=unknown

variants="62 6x 93 510 700 8m"

vnames="Carbon_AM625 Nitrogen_6X Nitrogen_93 Tungsten_510 Tungsten_700 Nitrogen_8M_series"

NPROC=$(($(nproc) - 4))

NFSROOT="/srv/nfs"
TFTPROOT="/srv/tftp"

# Only build the main kernel and dtbs and copy to tftp
KERNEL_ONLY=1

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

# isp-vvcam
IMX_VVCAM=0
##################################################################

# Build IF573 out of tree module
IF573=0
IF573_BASE_PWD=/home/simong/Downloads/8MM_SMARC/if573/release
# IF573 laird-backport-11.0.0.138
IF573_VERSION=laird-backport-11.0.0.138
#
##################################################################
#
# Laird drivers https://jenkins.devops.rfpros.com/job/CS-Linux/job/BSP-Pipeline/job/lrd-11.171.0.x/lastSuccessfulBuild/artifact/buildroot/output/backports/images/
# 		https://jenkins.devops.rfpros.com/job/CS-Linux/job/BSP-Pipeline/job/lrd-11.171.0.x/19/artifact/buildroot/output/backports/images/backports-laird-11.171.0.19.tar.bz2
#
#		https://github.com/rfpros/cp_release-backports-unreleased/archive/refs/tags/LRD-REL-11.171.0.24.tar.gz
#
# Laird fw	https://jenkins.devops.rfpros.com/job/CS-Linux/job/BSP-Pipeline/job/lrd-11.171.0.x/lastSuccessfulBuild/artifact/buildroot/output/firmware/images/
#		https://jenkins.devops.rfpros.com/job/CS-Linux/job/BSP-Pipeline/job/lrd-11.171.0.x/19/artifact/buildroot/output/firmware/images/laird-bdsdmac-firmware-11.171.0.19.tar.bz2
#
#		https://github.com/rfpros/cp_release-radio_firmware-unreleased/archive/refs/tags/LRD-REL-11.171.0.24.tar.gz
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
#
LAIRD_WIFI=0
# LAIRD_WIFI_DEFCONFIG=regression-test
# bdimx8 in next release
# LAIRD_WIFI_DEFCONFIG=sona_nx611
# LAIRD_WIFI_DEFCONFIG=bdimx6
# LAIRD_WIFI_DEFCONFIG=bdimx8
LAIRD_WIFI_DEFCONFIG=lwb

#LAIRD_WIFI_BASE_PWD=/home/simong/Downloads/nx611-eng-11.0.0.263-20240411/release/laird-backport-11.0.0.263
#LAIRD_WIFI_FW_PWD=/home/simong/Downloads/nx611-eng-11.0.0.263-20240411/release

#LAIRD_WIFI_BASE_PWD=/home/simong/Downloads/summit-backports-12.29.0.13
#LAIRD_WIFI_FW_PWD=/home/simong/Downloads/nx611-eng-11.0.0.263-20240411/release
LAIRD_WIFI_BASE_PWD=~/githome/cp_release-backports-unreleased/backport
LAIRD_WIFI_FW_PWD=~/githome/cp_release-radio_firmware-unreleased/summit-lwb5plus-sdio-sa-m2-firmware
# LAIRD_WIFI_FW_PWD=~/githome/cp_release-radio_firmware-unreleased/laird-lwb5plus-sdio-sa-firmware
# TODO Copy all relevant firmwares
# LAIRD_WIFI_FW_PWD=/home/simong/Downloads/laird-lwb5plus-sdio-sa-firmware-11.171.0.19
#
##########################################################################################################################################################################################
#
# NXP IW611 Wifi

NXP_WIFI=0
NXP_WIFI_BASE_PWD=/home/simong/githome/mwifiex/mxm_wifiex/wlan_src
NXP_WIFI_FW_PWD=/home/simong/Downloads/nx611-eng-11.0.0.263-20240411/release
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
	export INSTALL_MOD_PATH=$PWD/out

	if [ $cc_env = 64 ]; then
		export ARCH=arm64

		export CROSS_COMPILE=aarch64-linux-gnu-

	else

		export ARCH=arm

		export CROSS_COMPILE=arm-linux-gnueabihf-
	fi

	export KERNEL_SRC=$PWD

	# For NXP IW611
	export KERNELDIR=$PWD

	export KLIB=$KERNEL_SRC/out

	export KLIB_BUILD=$KERNEL_SRC

	echo "Cross Compile environment ${cc_env}bit set"
}

if [ ! -f $0 ]; then
	# "you sourced me"
	cc_env=64
	if [ -n "$1" ]&&[ $1 = 32 ]; then
		cc_env=32
	fi
	set_cc_env $cc_env
	return
fi

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

	for i in $variants; do
		if [ $i = $variant ]; then
			found=1
			break
		fi
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

echo "Variant is $variant"

if [ $variant = "unknown" ]; then
	echo
	echo "For help ..."
	echo
	echo "$0 -h"
	echo
	exit 127
fi

rm -rf out/*

cc_env=64

if [ $variant = "6x" ]; then
	cc_env=32
fi

set_cc_env $cc_env

if [ $variant = "62" ]; then
	config_target="defconfig ti_arm64_prune.config"
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
#

# make imx93_bd_smarc_defconfig
#if [ $variant = "510" ]; then
#	make defconfig
#else
#	make defconfig
#	make boundary_defconfig
#	make imx_v8_defconfig
#fi
make $config_target

check_result Linux-config $?

# make clean

if [ $cc_env = 32 ]; then
	make zImage modules dtbs -j $NPROC $TARGET
else
	# make -j 16
	make DTC_FLAGS="-@" -j $NPROC $TARGET
fi

check_result Linux $?

kernel_release=`cat include/config/kernel.release`

make modules_install
check_result Linux-modules_install $?

case $variant in
	62)
		DTBS="ti/k3-am625-sk.dtb ti/k3-am625-carbon.dtb"
		SUBDIR="carbon62"
	;;

	6x)
		DTBS="imx6*nitrogen*.dtb imx6q-ltch.dtb"
		SUBDIR="nitrogen6x"
	;;

	8m)
		DTBS="freescale/imx8*nitrogen*.dtb freescale/imx8mm-geno.dtb freescale/imx8mp-mmr.dtb freescale/imx8mp-abiomed.dtb freescale/imx8mm-ash.dtb"
		SUBDIR="nitrogen8m"
	;;

	93)
		DTBS="freescale/imx93-nitrogen-smarc*.dtb"
		SUBDIR="nitrogen93"
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
		make -j16

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
			cd ../kernel-module-imx-gpu-viv
			make -j16

			check_result imx-gpu-viv $?

			make modules_install

			cd $KERNEL_SRC
		fi

		if [ $IMX_VVCAM -eq 1 ]; then
			cd ../isp-vvcam/vvcam/v4l2
			make -j16

			check_result imx-vvcam $?

			make modules_install

			cd $KERNEL_SRC
		fi

	fi

	if [ $variant = 93 ]||[ $variant = 8m ]; then

		if [ $IF573 -eq 1 ]; then
			###############################################################
			# IF573 laird

			cd ${IF573_BASE_PWD}/${IF573_VERSION}
			make defconfig-lwb

			make -j $NPROC

			check_result if573-driver $?

			make modules_install -j2

			cd $KERNEL_SRC

			# Copy IF573 firmware
			sudo cp -a ${IF573_BASE_PWD}/lib/* ${NFSROOT}/${SUBDIR}/lib/
			###############################################################
		fi

		if [ $LAIRD_WIFI -eq 1 ]; then
			###############################################################
			# Laird WiFi

			cd ${LAIRD_WIFI_BASE_PWD}

			LAIRD_WIFI_GIT_VER=`git symbolic-ref -q --short HEAD || git describe --tags --exact-match`

			make mrproper

			check_result laird_wifi_driver_clean $?

			make defconfig-${LAIRD_WIFI_DEFCONFIG}

			check_result laird_wifi_defconfig

			make -j $NPROC

			check_result laird_wifi_driver $?

			make modules_install

			cd $KERNEL_SRC

			# Copy laird-firmware
			cd ${LAIRD_WIFI_FW_PWD}

			check_result laird_wifi_firmware $?

			LAIRD_WIFI_FW_GIT_VER=`git symbolic-ref -q --short HEAD || git describe --tags --exact-match`

			sudo cp -a lib/* ${NFSROOT}/${SUBDIR}/lib/

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

			sudo cp ../bin_wlan/*.ko ${NFSROOT}/${SUBDIR}/home/root/

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
	fi
	#

	# Common Mediatek stuff
	if [ $variant = 510 ]||[ $variant = 700 ]; then

		cd ../mtk-mali-gpu-driver
		make -j16

		check_result mtk-mali-gpu-driver $?

		make modules_install -j2

		cd ../mtk-vcodec-driver

		TARGET_PLATFORM=mt8395 make -j16

		check_result mtk-vcodec-driver $?

		make modules_install

		cd ../mtk-vcu-driver

		TARGET_PLATFORM=mt8395 EXTRA_SYMBOLS_PATH=../mtk-vcodec-driver/Module.symvers make -j16

		check_result mtk-vcu-driver $?

		make modules_install

		cd ../mtk-camisp-driver

		PLATFORM=mt8188 make -j12

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

fi # end KERNEL_ONLY=0

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


echo "\nBuilt kernel $kernel_release\n"

if [ $LAIRD_WIFI -eq 1 ]; then
	echo "\nBuilt Laird Wifi $LAIRD_WIFI_GIT_VER defconfig-${LAIRD_WIFI_DEFCONFIG}"
	echo "Using Laird FW   $LAIRD_WIFI_FW_GIT_VER from ${LAIRD_WIFI_FW_PWD}\n"
fi

echo "Done!"

