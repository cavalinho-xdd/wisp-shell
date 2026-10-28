# Maintainer: cavalinho-xdd <jakub.muzik@mendelova-stredni.cz>
pkgname=wisp-shell-git
pkgver=r1
pkgrel=1
pkgdesc="A modern floating pill-based shell for Hyprland built on Quickshell"
arch=('any')
url="https://github.com/cavalinho-xdd/wisp-shell"
license=('MIT')
# Keep in sync with `dependencies` in ./setup.
depends=('quickshell' 'hyprland' 'jq' 'upower' 'cliphist' 'wl-clipboard' 'grim' 'slurp' 'bc'
         'matugen' 'awww' 'libnotify' 'python' 'nodejs' 'xdg-user-dirs' 'xdg-utils' 'curl'
         'ttf-mona-sans' 'otf-monaspace' 'noto-fonts' 'ttf-jetbrains-mono-nerd'
         'hypridle' 'bluez' 'bluez-utils' 'networkmanager' 'brightnessctl' 'psmisc' 'polkit')
optdepends=(
    'hyprpaper: alternative wallpaper backend to awww'
    'qalc: launcher calculator'
    'nvidia-utils: GPU monitoring for Performance Widget (Nvidia only)'
)
makedepends=('git')
provides=('wisp-shell')
conflicts=('wisp-shell')
source=("git+https://github.com/cavalinho-xdd/wisp-shell.git")
md5sums=('SKIP')

pkgver() {
  cd "$srcdir/wisp-shell"
  printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

package() {
  cd "$srcdir/wisp-shell"

  install -d "$pkgdir/usr/share/wisp-shell"
  cp -a * "$pkgdir/usr/share/wisp-shell/"
  rm -rf "$pkgdir/usr/share/wisp-shell/probes"
  # Assistant skill; never part of the package (the `*` glob skips dotfiles
  # today, this keeps it that way if the copy changes).
  rm -rf "$pkgdir/usr/share/wisp-shell/.claude"
  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"

  install -d "$pkgdir/usr/bin"
  ln -s /usr/share/wisp-shell/wisp "$pkgdir/usr/bin/wisp"
}
