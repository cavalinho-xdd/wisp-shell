# Sandbox for testing `./setup bootstrap` end-to-end on a fresh Arch install.
# No GPU/Wayland here -- this validates package installs, file placement, and
# `wisp doctor`, not a graphical shell launch.
FROM archlinux:base-devel

RUN pacman -Syu --noconfirm --needed git sudo glibc-locales \
    && sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen

ENV LANG=en_US.UTF-8

# makepkg (used to bootstrap yay/paru and to build AUR packages) refuses to
# run as root, so the whole install runs as a normal user with passwordless
# sudo -- same shape as a real machine, where `setup` primes `sudo -v` once
# up front.
RUN useradd -m -G wheel tester \
    && echo 'tester ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/tester

USER tester
WORKDIR /home/tester/wisp-shell
