#!/bin/sh
# Finalize target file system before generating image
# Create symlinks in /etc/rcX.d directories using insserv
# Created By AK
# Revision V1.0 25/04/2023
VERSION="postbuildVersion=1.0"
OSVERSION="5.0"
TARGET_DIR=$1
INSSERV=$(dirname $0)/insserv
BOARD_PATH="/home/dell/Documents/Code"
LINUX_EXEC_PATH="/home/dell/Documents/SW/arm-bins/linuxbin"
LINUX_EXECS="perf testptp"
DISABLE_INITD="syslog busybox-udhcpd"
DELETE_DIRS="\
/etc/apache2/original
"
DELETE_FILES="\
/etc/network/nfs_check
/etc/profile.d/umask.sh
/etc/ssl/ct_log_list.cnf.dist
/etc/ssl/openssl.cnf.dist
/etc/xattr.conf
/usr/libexec/resolvconf/libc.d/avahi-daemon
/usr/libexec/resolvconf/libc.d/mdnsd
/usr/libexec/resolvconf/dnsmasq
/usr/libexec/resolvconf/pdnsd
/usr/libexec/resolvconf/pdns_recursor
/usr/libexec/resolvconf/unbound
"

make_rc_dirs()
{
	for num in 0 1 2 3 4 5 6 S; do
		mkdir -p "${TARGET_DIR}/etc/rc${num}.d"
		rm -f ${TARGET_DIR}/etc/rc${num}.d/*
	done
}

build_symlinks()
{
	for path in $(ls -1 ${TARGET_DIR}/etc/init.d/*); do
		scr=$(basename ${path})
		case "${scr}" in
		rc|rcS)
#			echo "DEBUG: skipping ${scr}"
			;;
		*)
#			echo "DEBUG: processing ${scr}"
			${INSSERV} -f -e -p ${TARGET_DIR}/etc/init.d ${scr}
			;;
		esac
	done
}

copy_linux_execs()
{
	if ! test -d ${LINUX_EXEC_PATH}; then
		echo "ERROR: ${LINUX_EXEC_PATH} doesn't exist!"
		return 1
	fi

	for fl in ${LINUX_EXECS}; do
		if ! test -e ${LINUX_EXEC_PATH}/${fl}; then
			echo "ERROR: ${LINUX_EXEC_PATH}/${fl} doesn't exist!"
			return 1
		fi

		echo "Copying linux tool ${fl}"
		rsync -t ${LINUX_EXEC_PATH}/${fl} ${TARGET_DIR}/usr/sbin
	done
	return 0
}

delete_dirs()
{
	for dir in ${DELETE_DIRS}; do
		if test -d ${TARGET_DIR}${dir}; then
			echo "Deleting ${dir}"
			rm -r ${TARGET_DIR}${dir}
		fi
	done
}

delete_files()
{
	for fl in ${DELETE_FILES}; do
		if test -e ${TARGET_DIR}${fl}; then
			echo "Deleting ${fl}"
			rm ${TARGET_DIR}${fl}
		fi
	done
}

disable_initd()
{
	for scr in ${DISABLE_INITD}; do
		if test -e ${TARGET_DIR}/etc/init.d/${scr}; then
			echo "Disabling /etc/init.d/${scr}"
			mv ${TARGET_DIR}/etc/init.d/${scr} ${TARGET_DIR}/etc/init.d/__${scr}
		fi
	done
}

add_board_execs()
{
	lelib="libleiodc.so.2.0.0"
	libpath="${BOARD_PATH}/Eclipse/libleiodc/imx287/${lelib}"
	if test -f "${libpath}"; then
		echo "Copying ${libpath}"
		rsync -t --chmod=0644 ${libpath} ${TARGET_DIR}/usr/lib
		ln -sf ${lelib} ${TARGET_DIR}/usr/lib/libleiodc.so
	else
		echo "ERROR: ${lelib} doesn't exist!"
		exit 1
	fi

	hbpath="${BOARD_PATH}/Eclipse/heartbeat/imx287/heartbeat"
	if test -f "${hbpath}"; then
		echo "Copying ${hbpath}"
		rsync -t --chmod=0755 ${hbpath} ${TARGET_DIR}/usr/bin/heartbeat
	else
		echo "ERROR: ${hbpath} doesn't exist!"
		exit 1
	fi
}

generate_timestamp()
{
	# See /etc/init.d/save-rtc.sh for required date format
	TS=$(date -u +%4Y%2m%2d%2H)
	echo "${TS}00" >${TARGET_DIR}/etc/timestamp
}

print_version()
{
	motdfile="${TARGET_DIR}/etc/update-motd.d/10-help-text"
	if test -f ${motdfile}; then
		osstr="V${OSVERSION} "$(date -u +%4Y-%2m-%2d)
		sed -i s/"@SYSVER@"/"${osstr}"/ ${motdfile}
	else
		echo "ERROR: ${motdfile} doesn't exist!"
		exit 1
	fi

	osrelfile="${TARGET_DIR}/usr/lib/os-release"
	if test -f ${osrelfile}; then
		echo "NAME=\"Londelec_Buildroot\"" >${osrelfile}
		echo "VERSION=\"Londelec OS V${OSVERSION}\"" >>${osrelfile}
		echo "ID=londelec" >>${osrelfile}
		echo "VERSION_ID=\"${OSVERSION}\"" >>${osrelfile}
		echo "PRETTY_NAME=\"Londelec OS V${OSVERSION} (built with Buildroot ${BR2_VERSION})\"" >>${osrelfile}
	else
		echo "ERROR: ${osrelfile} doesn't exist!"
		exit 1
	fi
}


if ! test -d ${TARGET_DIR}; then
	echo "ERROR: Target directory ${TARGET_DIR} doesn't exist!"
	exit 1
fi

if ! test -x ${INSSERV}; then
	echo "ERROR: ${INSSERV} binary is not found!"
	exit 1
fi

echo "Creating /etc/rcX.d directories"
make_rc_dirs

echo "Installing symlinks in /etc/rcX.d"
build_symlinks

if ! copy_linux_execs; then exit 1; fi

delete_dirs
delete_files

disable_initd

add_board_execs
generate_timestamp
print_version
exit 0

