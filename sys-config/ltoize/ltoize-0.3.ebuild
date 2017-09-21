# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit versionator toolchain-funcs

DESCRIPTION="A configuration for portage to make building with LTO easy."
HOMEPAGE="https://github.com/InBetweenNames/gentooLTO"
KEYWORDS="~amd64"

SRC_URI=""

LICENSE="GPL-2+"
SLOT="0"
IUSE="lto graphite o3"

DEPEND="graphite? ( >=sys-devel/gcc-4.9.4:=[graphite] )
	lto? ( >=sys-devel/gcc-4.9.4:= )"
RDEPEND="${DEPEND}"

pkg_preinst() {

	GENTOOLTO_PORTDIR=$(portageq get_repo_path / lto-overlay)
	LTO_PROFILE_DIR="${GENTOOLTO_PORTDIR}/profiles/lto-overlay/default"

	if use lto; then
		elog "Installing symlink for LTO override configurations"
		dosym "${LTO_PORTAGE_DIR}/LTO/env" "${ROOT}etc/portage/env/LTO"
		dosym "${LTO_PORTAGE_DIR}/package.env" "${ROOT}etc/portage/package.env/LTO"
	fi
	if use graphite; then
		elog "Installing symlink for Graphite override configurations"
		dosym "${LTO_PORTAGE_DIR}/Graphite/env" "${ROOT}etc/portage/env/Graphite"
		dosym "${LTO_PORTAGE_DIR}/package.env" "${ROOT}etc/portage/package.env/Graphite"
	fi
	if use o3; then
		elog "Installing symlink for O3 override configurations"
		dosym "${LTO_PORTAGE_DIR}/O3/env" "${ROOT}etc/portage/env/O3"
		dosym "${LTO_PORTAGE_DIR}/package.env" "${ROOT}etc/portage/package.env/O3"
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
}
