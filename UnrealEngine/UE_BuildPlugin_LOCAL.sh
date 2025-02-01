#!/bin/bash

# Convenient script to manually build plugin for UE project or engine version.
#
# Usage:
#
#      UE_BuildPlugin_LOCAL.sh   $ENGINE_ROOT   $PLUGIN_FILE...
#
# where:
#	$ENGINE_ROOT	is the installation directory for the engine version
#			that will be used to compile the plugin.
#	$PLUGIN_FILE	is the plugin to be compiled, which should already have
#			been copied to the desired project or engine target.
#
# The $INSTALL_ROOT must refer to the same $ENGINE_ROOT to install the plugin to
# that engine, or to a project directory of the same engine version.
#
# Author: Scott Courtney
# License: GNU/Affero General Public License 3.0

function usage
{
	echo ""
	echo "Usage: ${0} \$ENGINE_ROOT \$PLUGIN_FILE..."
	echo ""
	echo "See comments in script for parameter details."
	exit -1
}

# Parameter is any string; returns a string for the dotted
# version (with one, two, or three segments) plus three
# integers for major, minor, and patch revision, in order.
# Integers in the input are assigned to the three fields in
# order major, minor, patch, and any missing fields are
# assigned the value zero.
function extract_revision
{
	VERSION=$(echo "$1" | tr -d '[:alpha:]/_,"')
	MAJOR="${VERSION%%.*}"
	if [[ "${#MAJOR}" == 0 ]]
	then
		let MAJOR=0
		let MINOR=0
		let PATCH=0
	else
		NONMAJOR="${VERSION#*.}"
		if [[ "${#MAJOR}" == "${#VERSION}" ]]
		then
			let MINOR=0
			let PATCH=0
		else
			MINOR="${NONMAJOR%%.*}"
			if [[ "${#MINOR}" == "${#NONMAJOR}" ]]
			then
				let PATCH=0
			else
				let PATCH=${NONMAJOR##*.}
			fi
		fi
		# Force numeric now that we're done with string length compare
		let MAJOR=${MAJOR}
	fi
	echo "${VERSION}" ${MAJOR} ${MINOR} ${PATCH}
}

# Parameters ENGINE_ROOT
function find_build_script
{
	SCRIPT="${ENGINE_ROOT}/Engine/Build/BatchFiles/RunUAT.sh"
	if test -x "${SCRIPT}"
	then
		echo "${SCRIPT}"
	else
		echo "ERROR: ${SCRIPT} not found. Skipping build." >&2
	fi
}

# Parameters PLUGIN_BASE ENGINE_ROOT PLUGIN_FILE
function build_plugin
{
	# The PID on the end of the build directory precludes reuse of intermediates
	# but saves a lot of time on rebuilds.
	# BUILD_DIR="/tmp/${PLUGIN_BASE}-$$"
	
	# Keep one backup of the build directory
	BUILD_DIR="/tmp/${PLUGIN_BASE}"
	if test -d "${BUILD_DIR}"
	then
		echo "Making backup of previous build"
		rm -rf "${BUILD_DIR}.1"
		cp -rpd "${BUILD_DIR}" "${BUILD_DIR}.1"
	fi

	echo "BUILD_DIR ${BUILD_DIR}" >&2
	SCRIPT="$(find_build_script ${2})"
	if [[ "${SCRIPT}" != "" ]]
	then
		ECHO_CMD="${SCRIPT} BuildPlugin -Plugin=\"${3}\" -Package=\"${BUILD_DIR}\" ${HOST_PLATFORMS} ${TARGET_PLATFORMS} ${ARCHITECTURES}"
		echo "Build command line: ${ECHO_CMD}"

		if ${SCRIPT} BuildPlugin -Plugin="${3}" -Package="${BUILD_DIR}" ${HOST_PLATFORMS} ${TARGET_PLATFORMS} ${ARCHITECTURES}
#		if ${SCRIPT} BuildPlugin -Plugin="${3}" -Package="${BUILD_DIR}"
		then
			echo "Build completed for ${1}. Result in ${BUILD_DIR}."
			TARGET_DIR=$(dirname "${3}")
			echo "Intalling binaries to ${TARGET_DIR}"
			cp -rpd "${BUILD_DIR}"/* "${TARGET_DIR}/"
#			echo "Cleaning up build directory."
#			rm -rf "${BUILD_DIR}"
		else
			echo "Build FAILED for ${1}. Result in ${BUILD_DIR} will be retained for debugging."
		fi
	fi
}

if [[ "${1}" == "--help" || "${1}" == "" ]]
then
	usage
fi

ENGINE_ROOT=$(realpath "${1}")
shift

if [[ "${1}" == "--linux" || "${1}" == "--Linux" ]]
then
	shift
	echo "Building only for Linux x64 platform"
	HOST_PLATFORMS="-HostPlatforms=Linux"
	TARGET_PLATFORMS="-TargetPlatforms=Linux"
	ARCHITECTURES="-Architecture_Linux=x64"
else
	echo "Building for ALL supported platforms"
	HOST_PLATFORMS=""
	TARGET_PLATFORMS=""
	ARCHITECTURES=""
fi

if ! test -d "${ENGINE_ROOT}"
then
	echo "No engine at ${ENGINE_ROOT}"
	echo ""
	usage
fi

read ENGINE_VERSION ENGINE_MAJOR ENGINE_MINOR ENGINE_PATCH <<< $(extract_revision "${ENGINE_ROOT}")
	
for PLUGIN_FILE in $*
do
	PLUGIN_FILE=$(realpath "${PLUGIN_FILE}")
	if ! test -f "${PLUGIN_FILE}"
	then
		echo "Cannot open plugin file ${PLUGIN_FILE}. Skipping."
	else
		PLUGIN_BASE="$(basename ${PLUGIN_FILE%.*})"
		echo "Examining ${PLUGIN_BASE} plugin..."
		PLUGIN_ENGINE_VERSION_STRING=$(grep '"EngineVersion":' "${PLUGIN_FILE}" | cut -f2 -d':' | tr -d '",')
		read PLUGIN_VERSION PLUGIN_MAJOR PLUGIN_MINOR PLUGIN_PATCH <<< $(extract_revision "${PLUGIN_ENGINE_VERSION_STRING}")
		echo "Plugin engine version: ${PLUGIN_VERSION}"
	fi

	if [[ $ENGINE_MAJOR == $PLUGIN_MAJOR && $ENGINE_MINOR == $PLUGIN_MINOR ]]
	then
		echo "Engine and plugin versions are both $ENGINE_MAJOR.$ENGINE_MINOR.x. Build can proceed."
		build_plugin ${PLUGIN_BASE} ${ENGINE_ROOT} ${PLUGIN_FILE}
	else
		echo "Engine and plugin versions $ENGINE_MAJOR.$ENGINE_MINOR and $PLUGIN_MAJOR.$PLUGIN_MINOR mismatch. Build skipped."
	fi
done
