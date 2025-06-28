# Maintainer: initMayday <initMayday@protonmail.com>

_pkgname="declarages"
pkgname="$_pkgname-git"
pkgrel=1
pkgver=1
pkgdesc='A way to manage your packages in lua'
arch=('any')
url='https://github.com/initMayday/declarages.git'
makedepends=()
depends=('lua' 'git' 'pacman-contrib') # pacman-contrib required for pacman core
provides=("$_pkgname")
conflicts=("$_pkgname")
license=('CC-BY-NC-SA-4.0')
source=("$_pkgname::git+$url")
sha256sums=('SKIP')

pkgver() {
    cd "$_pkgname"
    printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

package() {
    cd "$_pkgname"
    install -Dm755 ./wrapper.sh "$pkgdir/usr/bin/declarages"
    mkdir -p "$pkgdir/usr/share/$_pkgname"
    cp -rf ./* "$pkgdir/usr/share/$_pkgname/"
}
