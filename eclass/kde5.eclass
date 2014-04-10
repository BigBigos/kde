# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

# @ECLASS: kde5.eclass
# @MAINTAINER:
# kde@gentoo.org
# @BLURB: Support eclass for KDE 5-related packages.
# @DESCRIPTION:
# The kde5.eclass provides support for building KDE 5-related packages.

if [[ ${___ECLASS_ONCE_KDE5} != "recur -_+^+_- spank" ]] ; then
___ECLASS_ONCE_KDE5="recur -_+^+_- spank"

CMAKE_MIN_VERSION="2.8.12"

# @ECLASS-VARIABLE: VIRTUALX_REQUIRED
# @DESCRIPTION:
# For proper description see virtualx.eclass manpage.
# Here we redefine default value to be manual, if your package needs virtualx
# for tests you should proceed with setting VIRTUALX_REQUIRED=test.
: ${VIRTUALX_REQUIRED:=manual}

inherit kde5-functions toolchain-funcs fdo-mime flag-o-matic gnome2-utils virtualx eutils cmake-utils

if [[ ${KDE_BUILD_TYPE} = live ]]; then
	inherit git-r3
fi

EXPORT_FUNCTIONS pkg_setup src_unpack src_prepare src_configure src_compile src_test src_install pkg_preinst pkg_postinst pkg_postrm

# @ECLASS-VARIABLE: QT_MINIMAL
# @DESCRIPTION:
# Minimal Qt version to require for the package.
: ${QT_MINIMAL:=5.2.0}

# @ECLASS-VARIABLE: KDE_AUTODEPS
# @DESCRIPTION:
# If set to "false", do nothing.
# For any other value, add a dependency on dev-libs/extra-cmake-modules and dev-qt/qtcore.
: ${KDE_AUTODEPS:=true}

# @ECLASS-VARIABLE: KDE_DEBUG
# @DESCRIPTION:
# If set to "false", unconditionally build with -DNDEBUG.
# Otherwise, add debug to IUSE to control building with that flag.
: ${KDE_DEBUG:=true}

# @ECLASS-VARIABLE: KDE_DOXYGEN
# @DESCRIPTION:
# If set to "false", do nothing.
# Otherwise, add "doc" to IUSE, add appropriate dependencies, and generate and
# install API documentation.
if [[ ${CATEGORY} = kde-frameworks ]]; then
	: ${KDE_DOXYGEN:=true}
else
	: ${KDE_DOXYGEN:=false}
fi

# @ECLASS-VARIABLE: KDE_EXAMPLES
# @DESCRIPTION:
# If set to "false", unconditionally ignore a top-level examples subdirectory.
# Otherwise, add "examples" to IUSE to toggle adding that subdirectory.
: ${KDE_EXAMPLES:=false}

# @ECLASS-VARIABLE: KDE_HANDBOOK
# @DESCRIPTION:
# If set to "false", do nothing".
# Otherwise, add "+handbook" to IUSE, add the appropriate dependency, and
# generate and install KDE handbook.
KDE_HANDBOOK="${KDE_HANDBOOK:-false}"

# @ECLASS-VARIABLE: KDE_TEST
# @DESCRIPTION:
# If set to "false", do nothing.
# For any other value, add test to IUSE and add a dependency on qttest.
if [[ ${CATEGORY} = kde-frameworks ]]; then
	: ${KDE_TEST:=true}
else
	: ${KDE_TEST:=false}
fi

HOMEPAGE="http://www.kde.org/"
LICENSE="GPL-2"

SLOT=5

case ${KDE_AUTODEPS} in
	false)	;;
	*)
		DEPEND+=" >=dev-libs/extra-cmake-modules-0.0.12"
		RDEPEND+=" kde-frameworks/kf-env"
		COMMONDEPEND+="	>=dev-qt/qtcore-${QT_MINIMAL}:5"
		;;
esac

case ${KDE_DOXYGEN} in
	false)	;;
	*)
		IUSE+=" doc"
		DEPEND+=" doc? (
				app-doc/doxygen
				$(add_frameworks_dep kapidox)
			)"
esac

case ${KDE_DEBUG} in
	false)	;;
	*)
		IUSE+=" debug"
		;;
esac

case ${KDE_EXAMPLES} in
	false)  ;;
	*)
		IUSE+=" examples"
		;;
esac

case ${KDE_HANDBOOK} in
	false)	;;
	*)
		IUSE+=" +handbook"
		DEPEND+=" handbook? ( $(add_frameworks_dep kdoctools) )"
		;;
esac

case ${KDE_TEST} in
	false)	;;
	*)
		IUSE+=" test"
		DEPEND+=" test? ( dev-qt/qttest:5 )"
		;;
esac

DEPEND+=" ${COMMONDEPEND}"
RDEPEND+=" ${COMMONDEPEND}"
unset COMMONDEPEND

if [[ -n ${KMNAME} && ${KMNAME} != ${PN} && ${KDE_BUILD_TYPE} = release ]]; then
	S=${WORKDIR}/${KMNAME}-${PV}
fi

# Determine fetch location for released tarballs
_calculate_src_uri() {
	debug-print-function ${FUNCNAME} "$@"

	local _kmname

	if [[ -n ${KMNAME} ]]; then
		_kmname=${KMNAME}
	else
		_kmname=${PN}
	fi

	DEPEND+=" app-arch/xz-utils"
	SRC_URI="mirror://kde/unstable/frameworks/${PV}/${_kmname}-${PV}.tar.xz"
}

# Determine fetch location for live sources
_calculate_live_repo() {
	debug-print-function ${FUNCNAME} "$@"

	SRC_URI=""

	local _kmname
	# @ECLASS-VARIABLE: EGIT_MIRROR
	# @DESCRIPTION:
	# This variable allows easy overriding of default kde mirror service
	# (anongit) with anything else you might want to use.
	EGIT_MIRROR=${EGIT_MIRROR:=git://anongit.kde.org}

	if [[ -n ${KMNAME} ]]; then
		_kmname=${KMNAME}
	else
		_kmname=${PN}
	fi

	# default repo uri
	EGIT_REPO_URI="${EGIT_MIRROR}/${_kmname}"
}

case ${KDE_BUILD_TYPE} in
	live) _calculate_live_repo ;;
	*) _calculate_src_uri ;;
esac

debug-print "${LINENO} ${ECLASS} ${FUNCNAME}: SRC_URI is ${SRC_URI}"

# @FUNCTION: kde5_pkg_setup
# @DESCRIPTION:
# Do some basic settings
kde5_pkg_setup() {
	debug-print-function ${FUNCNAME} "$@"

	# Check if gcc compiler is fresh enough.
	# In theory should be in pkg_pretend but we check it only for kdelibs there
	# and for others we do just quick scan in pkg_setup because pkg_pretend
	# executions consume quite some time.
	if [[ ${MERGE_TYPE} != binary ]]; then
		[[ $(gcc-major-version) -lt 4 ]] || \
				( [[ $(gcc-major-version) -eq 4 && $(gcc-minor-version) -le 5 ]] ) \
			&& die "Sorry, but gcc-4.5 or later is required for KDE 5."
	fi
}

# @FUNCTION: kde5_src_unpack
# @DESCRIPTION:
# Function for unpacking KDE 5.
kde5_src_unpack() {
	debug-print-function ${FUNCNAME} "$@"

	if [[ ${KDE_BUILD_TYPE} = live ]]; then
		git-r3_src_unpack
	else
		unpack ${A}
	fi
}

# @FUNCTION: kde5_src_prepare
# @DESCRIPTION:
# Function for preparing the KDE 5 sources.
kde5_src_prepare() {
	debug-print-function ${FUNCNAME} "$@"

	# never build manual tests
	comment_add_subdirectory tests

	# only build examples when required
	if ! in_iuse examples || ! use examples ; then
		comment_add_subdirectory examples
	fi

	# only build unit tests when required
	if ! in_iuse test || ! use test ; then
		comment_add_subdirectory autotests
	fi

	# only enable handbook when required
	if ! use_if_iuse handbook ; then
		comment_add_subdirectory doc
	fi

	cmake-utils_src_prepare
}

# @FUNCTION: kde5_src_configure
# @DESCRIPTION:
# Function for configuring the build of KDE 5.
kde5_src_configure() {
	debug-print-function ${FUNCNAME} "$@"

	# we rely on cmake-utils.eclass to append -DNDEBUG too
	if ! use_if_iuse debug; then
		append-cppflags -DQT_NO_DEBUG
	fi

	local cmakeargs

	if ! use_if_iuse test ; then
		cmakeargs+=( -DBUILD_TESTING=OFF )
	fi

	# allow the ebuild to override what we set here
	mycmakeargs=("${cmakeargs[@]}" "${mycmakeargs[@]}")

	cmake-utils_src_configure
}

# @FUNCTION: kde5_src_compile
# @DESCRIPTION:
# Function for compiling KDE 5.
kde5_src_compile() {
	debug-print-function ${FUNCNAME} "$@"

	cmake-utils_src_compile "$@"

	# Build doxygen documentation if applicable
	if use_if_iuse doc ; then
		kgenapidox --doxdatadir=/usr/share/doc/HTML/en/common/ . || die
	fi
}

# @FUNCTION: kde5_src_test
# @DESCRIPTION:
# Function for testing KDE 5.
kde5_src_test() {
	debug-print-function ${FUNCNAME} "$@"

	_test_runner() {
		if [[ -n "${VIRTUALDBUS_TEST}" ]]; then
			export $(dbus-launch)
		fi

		cmake-utils_src_test
	}		

	# When run as normal user during ebuild development with the ebuild command, the
	# kde tests tend to access the session DBUS. This however is not possible in a real
	# emerge or on the tinderbox.
	# > make sure it does not happen, so bad tests can be recognized and disabled
	unset DBUS_SESSION_BUS_ADDRESS DBUS_SESSION_BUS_PID

	if [[ ${VIRTUALX_REQUIRED} == always || ${VIRTUALX_REQUIRED} == test ]]; then
		VIRTUALX_COMMAND="_test_runner" virtualmake
	else
		_test_runner
	fi

	if [ -n "${DBUS_SESSION_BUS_PID}" ] ; then
		kill ${DBUS_SESSION_BUS_PID}
	fi
}

# @FUNCTION: kde5_src_install
# @DESCRIPTION:
# Function for installing KDE 5.
kde5_src_install() {
	debug-print-function ${FUNCNAME} "$@"

	# Install doxygen documentation if applicable
	if use_if_iuse doc ; then
		dohtml -r ${P}-apidocs/html/*
	fi

	cmake-utils_src_install
}

# @FUNCTION: kde5_pkg_preinst
# @DESCRIPTION:
# Function storing icon caches
kde5_pkg_preinst() {
	debug-print-function ${FUNCNAME} "$@"

	gnome2_icon_savelist
}

# @FUNCTION: kde5_pkg_postinst
# @DESCRIPTION:
# Function to rebuild the KDE System Configuration Cache after an application has been installed.
kde5_pkg_postinst() {
	debug-print-function ${FUNCNAME} "$@"

	gnome2_icon_cache_update
	fdo-mime_desktop_database_update
}

# @FUNCTION: kde5_pkg_postrm
# @DESCRIPTION:
# Function to rebuild the KDE System Configuration Cache after an application has been removed.
kde5_pkg_postrm() {
	debug-print-function ${FUNCNAME} "$@"

	gnome2_icon_cache_update
	fdo-mime_desktop_database_update
}

fi