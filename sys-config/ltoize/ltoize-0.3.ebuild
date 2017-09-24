# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit versionator toolchain-funcs

DESCRIPTION="A configuration for portage to make building with LTO easy."
HOMEPAGE="https://github.com/InBetweenNames/gentooLTO"
KEYWORDS="~*"

SRC_URI=""

LICENSE="GPL-2+"
SLOT="0"
IUSE="ltopluginsymlink"

DEPEND=">=sys-devel/gcc-4.9.4:* >=sys-devel/binutils-2.28.1:*"
#DEPEND="graphite ? ( gcc[graphite] )"

RDEPEND="${DEPEND}"

#Test binutils and gcc version

pkg_setup() {

	ACTIVE_GCC=$(gcc-fullversion)

	if ! version_is_at_least 7.2.0 "${ACTIVE_GCC}"; then
		ewarn "Warning: Active GCC version < 7.2.0, it is recommended that you use the newest GCC if you want LTO."
		if [ "${I_KNOW_WHAT_I_AM_DOING}" != "y" ]; then
			eerror "Aborting LTOize installation due to older GCC -- set I_KNOW_WHAT_I_AM_DOING=y if you want to override this behaviour."
		else
			ewarn "I_KNOW_WHAT_I_AM_DOING=y -- continuing anyway"
		fi
	fi

	if [ -f "${ROOT}etc/portage/package.env" ]; then
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

	ACTIVE_GCC=$(gcc-fullversion)

	if use ltopluginsymlink; then
		elog "Installing liblto_plugin.so symlink because gcc binutils may require it."
		dosym "${ROOT}usr/libexec/gcc/${CHOST}/${ACTIVE_GCC}/liblto_plugin.so" "${ROOT}usr/${CHOST}/binutils-bin/lib/bfd-plugins/liblto_plugin.so"
	fi

	#Insert make.conf sample...

	elog "Installing make.conf.lto sample for make.conf modifications"
	insinto "/etc/portage"
	doins "${FILESDIR}/make.conf.lto"

	if [ -f "${ROOT}etc/portage/bashrc" ]; then
		ewarn "${ROOT}etc/portage/bashrc already exists!  Installing LTOize-specific bashrc functionality into bashrc.lto"
		dosym "${LTO_PORTAGE_DIR}/bashrc" "${ROOT}etc/portage/bashrc.lto"
	else
		elog "Installing bashrc symlink into ${ROOT}etc/portage"
		dosym "${LTO_PORTAGE_DIR}/bashrc" "${ROOT}etc/portage/bashrc"
	fi

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

	BINUTILS_VER=$(binutils-config -c | sed -e "s/.*-//")

	if ! version_is_at_least 2.29 "${BINUTILS_VER}"; then
		ewarn "Warning: active binutils version < 2.29, it is recommended that you use the newest binutils for LTO."
	fi

	if use ltopluginsymlink; then
		elog "A symlink to your GCC's liblto_plugin.so was installed in ${ROOT}usr/${CHOST}/binutils-bin/lib/bfd-plugins/liblto_plugin.so"
		elog "The version of GCC used to make the symlink was $(gcc-fullversion).  If this is not the GCC version you want, please update the symlink by hand."
		elog "See this repo's README for details in how to do this."
		ewarn "WARNING: If you change your active version of GCC, you will have to update this symlink by hand or re-emerge ltoize!"
	else
		elog "No liblto_plugin.so symlink was installed into ${ROOT}usr/${CHOST}/binutils-bin/lib/bfd-plugins/ for your GCC.  If this was not what you wanted, add ltopluginsymlink to your USE.  This will only affect packages which do not respect the AR, NM, and RANLIB variables.  For information about this see this repo's README."
	fi

	if [[ -f "${ROOT}etc/portage/bashrc.lto" ]]; then
		ewarn "LTOize requires special ${ROOT}etc/portage/bashrc support in order to function with certain packages."
		ewarn "You already have a bashrc inside ${ROOT}etc/portage -- LTOize bashrc settings were installed into ${ROOT}etc/portage/bashrc.lto"
		ewarn "Please ensure you merge the LTOize settings from bashrc.lto into your Portage bashrc before your next emerge"
		ewarn "Failure to do this could mean certain packages will not build correctly"
	else
		elog "LTOize installed a special Portage bashrc hook in ${ROOT}etc/portage/bashrc -- this was done automatically and nothing more is required from you."
	fi
}
