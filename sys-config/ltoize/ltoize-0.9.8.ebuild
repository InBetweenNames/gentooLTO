# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit toolchain-funcs

DESCRIPTION="A configuration for portage to make building with LTO easy."
HOMEPAGE="https://github.com/InBetweenNames/gentooLTO"

#Note: there's nothing preventing this from working on stable, but the dependencies of ltoize aren't keyworded for
#stable, so we only can do testing
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sparc ~x86"

SRC_URI=""

LICENSE="GPL-2+"
SLOT="0"
IUSE="override-flagomatic keep-nocommon"

#portage-bashrc-mv can be obtained from mv overlay
DEPEND="
	>=sys-devel/binutils-2.32:*
	>=sys-devel/gcc-config-1.9.1
	>=sys-apps/portage-2.3.52
	app-portage/portage-bashrc-mv[cflags]
	"

RDEPEND="${DEPEND}"

#Test binutils and gcc version

pkg_setup() {

	ACTIVE_GCC=$(gcc-fullversion)

	if ver_test "${ACTIVE_GCC}" -lt 10.2.0; then
		ewarn "Warning: Active GCC version '$ACTIVE_GCC' is lower then the expected version '10.2.0', it is recommended that you use the newest GCC if you want LTO."
		if [ "${I_KNOW_WHAT_I_AM_DOING}" != "y" ]; then
			eerror "Aborting LTOize installation due to older GCC version '$ACTIVE_GCC' -- set I_KNOW_WHAT_I_AM_DOING=y if you want to override this behaviour."
			die
		else
			ewarn "I_KNOW_WHAT_I_AM_DOING=y -- continuing anyway"
		fi
	fi

	if [ -f "${PORTAGE_CONFIGROOT%/}/etc/portage/package.cflags" ]; then
		eerror "${PORTAGE_CONFIGROOT%/}/etc/portage/package.cflags is a file not a directory.  Please convert package.cflags to a directory with the current contents of package.cflags being moved to a file inside it."
		die
	fi

}

pkg_preinst() {
	GENTOOLTO_PORTDIR=$(portageq get_repo_path ${PORTAGE_CONFIGROOT} lto-overlay)
	LTO_PORTAGE_DIR="${GENTOOLTO_PORTDIR}/${CATEGORY}/${PN}/files"
	COMMON_WORKAROUNDS=(
		cmake-makefile.conf
		devirtualize-at-ltrans.conf
		graphite.conf
		ipa-pta.conf
		lto.conf
		no-common-libtool.conf
		no-plt.conf
		no-semantic-interposition.conf
		optimizations.conf
		tls-dialect.conf
		use-ld.conf
	)

	ACTIVE_GCC=$(gcc-fullversion)

	#Install make.conf settings

	elog "Installing make.conf.lto.defines definitions for optimizations used in this overlay"
	dosym "${LTO_PORTAGE_DIR}/make.conf.lto.defines" "${PORTAGE_CONFIGROOT%/}/etc/portage/make.conf.lto.defines"

	elog "Installing make.conf.lto default full optimization config for make.conf"
	dosym "${LTO_PORTAGE_DIR}/make.conf.lto" "${PORTAGE_CONFIGROOT%/}/etc/portage/make.conf.lto"

	#Install main workarounds files
	for i in "${COMMON_WORKAROUNDS[@]}"; do
		elog "Installing package.cflags ${i} override"
		dosym "${LTO_PORTAGE_DIR}/package.cflags/${i}" "${PORTAGE_CONFIGROOT%/}/etc/portage/package.cflags/${i}"
	done

	#Install -fno-common workarounds file
	use keep-nocommon && dosym "${LTO_PORTAGE_DIR}/package.cflags/no-common.conf" \
	"${PORTAGE_CONFIGROOT%/}/etc/portage/package.cflags/no-common.conf"

	#Install patch framework
	elog "Installing bashrc.d hook symlink to apply LTO patches directly from lto-overlay"
	dosym "${LTO_PORTAGE_DIR}/bashrc.d/41-lto-patch.sh" "${PORTAGE_CONFIGROOT%/}/etc/portage/bashrc.d/41-lto-patch.sh"

	#Optional: install flag-o-matic overrides
	if use override-flagomatic; then
		ewarn "Installing bashrc.d hook to override strip-flags and replace-flags functions in flag-o-matic.  This is an experimental feature!"
		dosym "${LTO_PORTAGE_DIR}/bashrc.d/42-lto-flag-o-matic.sh" "${PORTAGE_CONFIGROOT%/}/etc/portage/bashrc.d/42-lto-flag-o-matic.sh"
		dosym "${LTO_PORTAGE_DIR}/package.cflags/flag-o-matic.conf" "${PORTAGE_CONFIGROOT%/}/etc/portage/package.cflags/flag-o-matic.conf"
	fi

	elog "Installing bashrc.d hook symlink to override package libtool lt_cv_sys_global_symbol_pipe and lt_cv_sys_global_symbol_to_cdecl"
	dosym "${LTO_PORTAGE_DIR}/bashrc.d/43-lto-no-common.sh" "${PORTAGE_CONFIGROOT%/}/etc/portage/bashrc.d/43-lto-no-common.sh"

}

pkg_postinst()
{
	elog "If you have not done so, you will need to modify your make.conf settings to enable LTO building on your system."
	elog "A symlink has been placed in ${PORTAGE_CONFIGROOT%/}/etc/portage/make.conf.lto that can be used as a basis for these modifications."
	elog "See README.md for more details."
	elog "lto-overlay and ltoize are part of a project to help find undefined behaviour in C and C++ programs through the use of aggressive compiler optimizations."
	elog "One of the aims of this project is also to improve the performance of linux distributions through these mechanisms as well."
	elog "Occasionally, you will experience breakage due to LTO problems.  These are documented in the README.md of this repository."
	elog "If you add an override for a particular package, please consider sending a pull request upstream so that other users of this repository can benefit."
	ewarn "You will require a complete system rebuild in order to gain the benefits of LTO system-wide."
	echo
	elog "Please consider reading the README.md at the root of this repository before attempting to rebuild your system to familiarize yourself with the goals of this project and potential pitfalls you could run into."
	echo
	ewarn "This is an experimental project and should not be used on a stable system in its current state."

	BINUTILS_VER=$(binutils-config ${CHOST} -c | sed -e "s/.*-//")

	if ver_test "${BINUTILS_VER}" -lt 2.34; then
		ewarn "Warning: active binutils version < 2.34, it is recommended that you use the newest binutils for LTO."
	fi
}
