# Maintainer: KnownGecko <KnownGecko@protonmail.com>

_pkgname="declarages"
pkgname="$_pkgname-git"
pkgrel=1.1
pkgver=1
pkgdesc="A way to manage your packages in lua"
arch=("x86_64")
url="https://github.com/knowngecko/declarages.git"
makedepends=()
depends=("lua" "git" "jshon" "pacman-contrib") # json, pacman-contrib required for pacman core
provides=(declarages)
conflicts=(declarages)
license=("custom")
source=(git+$url)
sha256sums=("SKIP")

pkgver() {
    cd "${_pkgname}"
    printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

package() {
    cd "${_pkgname}"
    install -Dm755 ./wrapper.sh "$pkgdir/usr/bin/declarages"
    mkdir -p "$pkgdir/usr/share/${_pkgname}"
    cp -rf ./* "$pkgdir/usr/share/${_pkgname}/"
}