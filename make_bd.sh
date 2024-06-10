#!/bin/sh

variant=unknown

variants="93 510 700 8m"

NPROC=$(($(nproc) - 4))

NFSROOT="/srv/nfs"
TFTPROOT="/srv/tftp"

# Only build the main kernel and dtbs and copy to tftp
KERNEL_ONLY=0

#	make defconfig
#	make boundary_defconfig
#       make ezurio_defconfig
#	make imx_v8_defconfig
#config_target=boundary_defconfig
config_target=ezurio_defconfig
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
# LWB5+(Summit) lwb5p NOT in laird-backport-11.171.0.19 ??
#
LAIRD_WIFI=0
# LAIRD_WIFI_DEFCONFIG=regression-test
# bdimx8 in next release
LAIRD_WIFI_DEFCONFIG=sona_nx611
#LAIRD_WIFI_DEFCONFIG=bdimx6
LAIRD_WIFI_BASE_PWD=/home/simong/Downloads/nx611-eng-11.0.0.263-20240411/release/laird-backport-11.0.0.263
LAIRD_WIFI_FW_PWD=/home/simong/Downloads/nx611-eng-11.0.0.263-20240411/release
#LAIRD_WIFI_BASE_PWD=~/githome/cp_release-backports-unreleased/backport
#LAIRD_WIFI_FW_PWD=~/githome/cp_release-radio_firmware-unreleased/laird-if573-sdio-firmware

# TODO Copy all relevant firmwares
# LAIRD_WIFI_FW_PWD=/home/simong/Downloads/laird-lwb5plus-sdio-sa-firmware-11.171.0.19
#
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
	export KERNEL_SRC=$PWD

	# Ubuntu is export INSTALL_MOD_PATH=$PWD/ubuntunize64/linux-staging
	export INSTALL_MOD_PATH=$PWD/out

	export ARCH=arm64

	export CROSS_COMPILE=aarch64-linux-gnu-

	export KERNEL_SRC=$PWD

	export KLIB=$KERNEL_SRC/out

	export KLIB_BUILD=$KERNEL_SRC
}

if [ ! -f $0 ]; then
	# "you sourced me"
	set_cc_env
	echo "Cross Compile environment set"
	return
fi

if [ -n "$1" ]; then

	if [ $1 = "-h" ]; then
		echo "Possible variants:\n"
		for i in $variants; do
			echo "$i\n"
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

set_cc_env

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

# make -j 16
make DTC_FLAGS="-@" -j $NPROC $TARGET

check_result Linux $?

kernel_release=`cat include/config/kernel.release`

make modules_install
check_result Linux-modules_install $?

case $variant in

	8m)
		DTBS="freescale/imx8*nitrogen*.dtb freescale/imx8mm-geno.dtb freescale/imx8mp-mmr.dtb freescale/imx8mp-abiomed.dtb freescale/imx8mm-ash.dtb"
		SUBDIR="nitrogen8m"
	;;

	93)
		DTBS="freescale/imx93-nitrogen-smarc.dtb freescale/imx93-nitrogen-smarc-lvds.dtb"
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

			make defconfig-${LAIRD_WIFI_DEFCONFIG}

			make -j $NPROC

			check_result laird_wifi_driver $?

			make modules_install

			cd $KERNEL_SRC

			# Copy laird-firmware
			sudo cp -a ${LAIRD_WIFI_FW_PWD}/lib/* ${NFSROOT}/${SUBDIR}/lib/

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

		sudo cp arch/arm64/boot/dts/mediatek/mt83x0-tungsten-smarc/*.dtbo ${TFTPROOT}/${SUBDIR}/devicetree

#		sudo cp arch/arm64/boot/dts/mediatek/dtbo/* ${TFTPROOT}/${SUBDIR}/devicetree

		if [ $variant = 510 ]; then
			sudo cp arch/arm64/boot/dts/mediatek/mt8370/*.dtbo ${TFTPROOT}/${SUBDIR}/devicetree
		elif [ $variant = 700 ]; then
			sudo cp arch/arm64/boot/dts/mediatek/mt8390/*.dtbo ${TFTPROOT}/${SUBDIR}/devicetree
		fi
	fi

fi # end KERNEL_ONLY=0

sudo cp -av out/lib/modules/${kernel_release} ${NFSROOT}/${SUBDIR}/lib/modules/

sudo cp arch/arm64/boot/Image ${TFTPROOT}/${SUBDIR}/

echo "\nCopying DTBs ..."
for i in $DTBS; do
	sudo cp -v arch/arm64/boot/dts/${i} ${TFTPROOT}/${SUBDIR}/
done
echo "----------------"
echo

sudo chown -R root:root ${NFSROOT}/${SUBDIR}/lib/modules/${kernel_release}


echo "\nBuilt kernel $kernel_release\n"

echo "Done!"

