# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

KDE_TEST="false"
inherit kde5

DESCRIPTION="Helper library to speed up start of applications on KDE work spaces"
LICENSE="LGPL-2+"
KEYWORDS=" ~amd64 ~x86 ~amd64-linux ~x86-linux"
IUSE=""

RDEPEND="
	$(add_frameworks_dep kconfig)
	$(add_frameworks_dep kcrash)
	$(add_frameworks_dep ki18n)
	$(add_frameworks_dep kio)
	$(add_frameworks_dep kservice)
	$(add_frameworks_dep kwindowsystem)
	dev-qt/qtdbus:5
	dev-qt/qtgui:5
	x11-libs/libX11
"
DEPEND="${RDEPEND}
	x11-proto/xproto
"