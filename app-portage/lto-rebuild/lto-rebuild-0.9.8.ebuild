# Copyright 2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Avoid a full system rebuild when using GentooLTO"
HOMEPAGE="https://github.com/InBetweenNames/gentooLTO"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="
	app-portage/portage-utils
	app-shells/bash:*
	sys-devel/binutils:*
	sys-devel/gcc:*
	"
RDEPEND="${DEPEND}"
BDEPEND=""

pkg_preinst() {
	dobin "${FILESDIR}"/lto-rebuild
}
