# Copyright 2019-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Avoid a full system rebuild when using GentooLTO"
HOMEPAGE="https://github.com/InBetweenNames/gentooLTO"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"

RDEPEND="app-portage/portage-utils"

S="${WORKDIR}"

src_install() {
	dobin "${FILESDIR}/lto-rebuild"
}
