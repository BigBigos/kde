# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit kde4-base

DESCRIPTION="KDE digital camera raw image library wrapper"
KEYWORDS=" ~amd64 ~x86"
IUSE="debug"

DEPEND="
	>=media-libs/libraw-0.16_beta1-r1:=
"
RDEPEND="${DEPEND}"
