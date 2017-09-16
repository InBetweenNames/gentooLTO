# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit versionator

DESCRIPTION="A configuration for portage to make building with LTO easy."
HOMEPAGE="https://github.com/InBetweenNames/gentooLTO"
KEYWORDS="~*"

SRC_URI=""

LICENSE="BSD"
SLOT="0"
IUSE=""

DEPEND=">=sys-devel/gcc-6.4.0:* >=sys-devel/binutils-2.28.1:*"
#DEPEND="graphite ? ( gcc[graphite] )"

RDEPEND="${DEPEND}"

#Test binutils and gcc version

pkg_setup() {

	BINUTILS_VER=$(portageq best_version / sys-devel/binutils | sed -e "s/.*-//")
	GCC_VER=$(portageq best_version / sys-devel/gcc | sed -e "s/.*-//")

	if ! version_is_at_least 2.29 "${BINUTILS_VER}"; then
		ewarn "Warning: binutils version < 2.29, it is recommended that you upgrade"
	fi

	if ! version_is_at_least 7.2.0 "${GCC_VER}"; then
		ewarn "Warning: GCC version < 7.2.0, it is recommended that you upgrade"
	fi

	if [ -z "${ROOT}etc/portage/package.env" ] && [ -f "${ROOT}etc/portage/package.env" ]; then
		eerror "${ROOT}etc/portage/package.env is a file not a directory.  Please convert package.env to a directory with the current contents of package.env being moved to a file inside it."
		die
	fi

}

pkg_preinst() {

	GENTOOLTO_PORTDIR=$(portageq get_repo_path / lto-overlay)
	LTO_PORTAGE_DIR="${GENTOOLTO_PORTDIR}/${CATEGORY}/${PN}/files"

	elog "Installing symlink for LTO override configurations"

	dosym "${LTO_PORTAGE_DIR}/env/lto" "${ROOT}etc/portage/env/lto"

	elog "Installing symlink for LTO per-package overrides"

	dosym "${LTO_PORTAGE_DIR}/package.env/ltoworkarounds.conf" "${ROOT}etc/portage/package.env/ltoworkarounds.conf"

	ACTIVE_GCC=$(gcc-config -c | sed -e 's/.*-//')

	LIBLTO_TARGET="${ROOT}usr/libexec/gcc/${CHOST}/${ACTIVE_GCC}/liblto_plugin.so"

	LIBLTO_LINK_NAME="${ROOT}usr/${CHOST}/binutils-bin/lib/bfd-plugins/liblto_plugin.so"

	elog "Installing liblto_plugin.so symlink because gcc and/or binutils may require it"
	dosym "${ROOT}usr/libexec/gcc/${CHOST}/${ACTIVE_GCC}/liblto_plugin.so" "${ROOT}usr/${CHOST}/binutils-bin/lib/bfd-plugins/liblto_plugin.so"

	#Insert make.conf sample...

	elog "Installing make.conf.lto sample for make.conf modifications"
	insinto "/etc/portage"
	doins "${FILESDIR}/make.conf.lto"

	elog "Installing patches to help certain software build with this configuration (installed as symlinks)"
	for i in $(ls ${LTO_PORTAGE_DIR}/patches); do
		dosym "${LTO_PORTAGE_DIR}/patches/$i" "${ROOT}etc/portage/patches/$i"
	done

}

pkg_postinst()
{
	elog "If you have not done so, you will need to modify your make.conf settings to enable LTO building on your system.  A sample file has been placed in ${ROOT}etc/portage/make.conf.lto that can be used as a basis for these modifications."
	elog "lto-overlay and ltoize are part of a project to help find undefined behaviour in C and C++ programs through the use of aggressive compiler optimizations.  One of the aims of this project is also to improve the performance of linux distributions through these mechanisms as well."
	elog "Occasionally, you will experience breakage due to LTO problems.  These are documented in the README.md of this repository.  If you add an override for a particular package, please consider sending a pull request upstream so that other users of this repository can benefit."
	elog "You will require a complete system rebuild in order to gain the benefits of LTO system-wide.  Please consider reading the README.md at the root of this repository before attempting to rebuild your system to familiarize yourself with the goals of this project and potential pitfalls you could run into."
	elog "This is an experimental project and should not be used on a stable system in its current state."
}
