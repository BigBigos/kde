# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

KMNAME="kde-runtime"
inherit kde4-meta

DESCRIPTION="KDED Password Module"
KEYWORDS="~amd64 ~arm ~ppc ~x86 ~amd64-linux ~x86-linux"
IUSE="debug"

RESTRICT="test"
# bug 393097