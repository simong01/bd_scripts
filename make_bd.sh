#!/bin/sh


variant=unknown

variants="93 510 700 8m"


NPROC=$(($(nproc) - 4))

NFSROOT="/srv/nfs"
TFTPROOT="/srv/tftp"

##################################################################
# Currently only for 8m targets

# imx-gpu-viv
IMX_GPU_VIV=1

# isp-vvcam
IMX_VVCAM=1
##################################################################

# Build IF573 out of tree module
IF573=0
IF573_BASE_PWD=/home/simong/Downloads/8MM_SMARC/if573/release
# IF573 laird-backport-11.0.0.138
IF573_VERSION=laird-backport-11.0.0.138
#

# Laird drivers https://jenkins.devops.rfpros.com/job/CS-Linux/job/BSP-Pipeline/job/lrd-11.171.0.x/lastSuccessfulBuild/artifact/buildroot/output/backports/images/
# 		https://jenkins.devops.rfpros.com/job/CS-Linux/job/BSP-Pipeline/job/lrd-11.171.0.x/19/artifact/buildroot/output/backports/images/backports-laird-11.171.0.19.tar.bz2
#
# Laird fw	https://jenkins.devops.rfpros.com/job/CS-Linux/job/BSP-Pipeline/job/lrd-11.171.0.x/lastSuccessfulBuild/artifact/buildroot/output/firmware/images/
#		https://jenkins.devops.rfpros.com/job/CS-Linux/job/BSP-Pipeline/job/lrd-11.171.0.x/19/artifact/buildroot/output/firmware/images/laird-bdsdmac-firmware-11.171.0.19.tar.bz2
# Build Laird out of tree module. And copy in firmware.
# BD_SDMAC is bdsdmac
# IF573 is lwb
# LWB5+ (Summit) lwb5p NOT in laird-backport-11.171.0.19 ??
#
LAIRD_WIFI=0
LAIRD_WIFI_DEFCONFIG=brcmfmac
LAIRD_WIFI_BASE_PWD=/home/simong/Downloads/laird-backport-11.171.0.19
#LAIRD_WIFI_FW_PWD=/home/simong/Downloads/laird-bdsdmac-firmware-11.171.0.19
LAIRD_WIFI_FW_PWD=/home/simong/Downloads/laird-lwb5plus-sdio-sa-firmware-11.171.0.19

##########################################################################################################################################################################################

# QCACLD_BASE_PWD=/home/simong/githome/qcacld-2.0/backport
#

# Install the old cypress fw
# LWB5+
CYPRESS_FW=1
CYPRESS_FW_BASE_PWD=/home/simong/githome/cypress-firmware


check_result() {
	local NAME=$1
	local RESULT=$2
	
	if [ $RESULT -ne 0 ]; then 
		echo "Oops ${NAME} compile problems.[$RESULT]"
		cd $KERNEL_SRC
		exit $RESULT
	fi
}

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

echo "Variant is $variant"

if [ $variant = "unknown" ]; then
	echo
	echo "For help ..."
	echo
	echo "$0 -h"
	echo
	exit 127
fi

export KERNEL_SRC=$PWD

# Ubuntu is export INSTALL_MOD_PATH=$PWD/ubuntunize64/linux-staging
export INSTALL_MOD_PATH=$PWD/out

export ARCH=arm64

export CROSS_COMPILE=aarch64-linux-gnu-

export KERNEL_SRC=$PWD

export KLIB=$KERNEL_SRC/out

export KLIB_BUILD=$KERNEL_SRC

# make clean

rm -rf out/*

# make imx93_bd_smarc_defconfig
#if [ $variant = "510" ]; then
#	make defconfig
#else
	make boundary_defconfig
#fi

# make -j 16
make DTC_FLAGS="-@" -j $NPROC

check_result Linux $?

kernel_release=`cat include/config/kernel.release`

make modules_install

case $variant in

	8m)
		DTBS="freescale/imx8m*nitrogen*.dtb"
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

# Common iMX stuff
# TODO
if [ $variant = 8m ]; then
	if [ $IMX_GPU_VIV -eq 1 ]; then
		cd ../kernel-module-imx-gpu-viv
		make -j16

		check_result imx-gpu-viv $?

		make modules_install
	fi

	if [ $IMX_VVCAM -eq 1 ]; then
		cd ../isp-vvcam/vvcam/v4l2
		make -j16

		check_result imx-vvcam $?

		make modules_install
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

	sudo cp arch/arm64/boot/dts/mediatek/dtbo/* ${TFTPROOT}/${SUBDIR}/devicetree
fi
# 



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

