# Copyright 2011-2020 Martin V\"ath and others
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Provide support for /etc/portage/bashrc.d and /etc/portage/package.cflags"
HOMEPAGE="https://github.com/vaeth/portage-bashrc-mv/"
SRC_URI="https://github.com/vaeth/portage-bashrc-mv/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sparc ~x86"

RESTRICT="mirror"

RDEPEND="app-portage/eix"

src_install() {
	dodoc AUTHORS NEWS README.md
	insinto /etc/portage
	doins -r bashrc
	insinto /etc/portage/bashrc.d
	doins bashrc.d/[a-zA-Z]*
	docompress /etc/portage/bashrc.d/README
	doins bashrc.d/*flag*
	doins bashrc.d/*locale*purge*
}

pkg_postinst() {
	! test -d /var/cache/gpo || \
		ewarn "Obsolete /var/cache/gpo found. Please remove"
}
