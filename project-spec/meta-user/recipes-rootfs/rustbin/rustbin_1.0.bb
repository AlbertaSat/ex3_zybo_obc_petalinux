SUMMARY = "Prebuilt Rust toolchain (offline installer)"
DESCRIPTION = "Installs a prebuilt Rust toolchain into /opt/rust and exports PATH globally."
LICENSE = "CLOSED"

SRC_URI = "https://static.rust-lang.org/dist/rust-1.93.0-armv7-unknown-linux-gnueabihf.tar.xz \
           file://rust-1.93.0-armv7-unknown-linux-gnueabihf.tar.xz.asc \
           file://rust-key.gpg \
"
SRC_URI[sha256sum] = ""

S = "${WORKDIR}/rust-1.93.0-armv7-unknown-linux-gnueabihf"

INSANE_SKIP:${PN} += "already-stripped"

DEPENDS += "gnupg-native"

do_unpack:append() {
    # Verify the vendor tarball signature using the shipped public key.
    gpgv --keyring ${WORKDIR}/rust-key.gpg \
         ${WORKDIR}/rust-1.93.0-armv7-unknown-linux-gnueabihf.tar.xz.asc \
         ${WORKDIR}/rust-1.93.0-armv7-unknown-linux-gnueabihf.tar.xz
}

do_install() {
    # Use the vendor install script to lay out the toolchain under /opt/rust.
    install -d ${D}/opt/rust
    sh ${S}/install.sh --destdir=${D} --prefix=/opt/rust --disable-ldconfig

    # Export PATH globally for all users.
    install -d ${D}${sysconfdir}/profile.d
    cat > ${D}${sysconfdir}/profile.d/rust.sh << 'EOF'
export PATH=/opt/rust/bin:$PATH
EOF
}

FILES:${PN} += "/opt/rust ${sysconfdir}/profile.d/rust.sh"
RDEPENDS:${PN} += "libgcc libstdc++"
