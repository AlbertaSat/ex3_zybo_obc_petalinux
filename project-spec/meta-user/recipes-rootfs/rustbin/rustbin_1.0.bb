SUMMARY = "Prebuilt Rust toolchain (offline installer)"
DESCRIPTION = "Installs a prebuilt Rust toolchain into /opt/rust and exports PATH globally."
LICENSE = "CLOSED"

SRC_URI = "https://static.rust-lang.org/dist/rust-1.93.0-armv7-unknown-linux-gnueabihf.tar.xz \
"
SRC_URI[sha256sum] = "f79a675930b599dc738af9b759f4ebd0e9ba7953a9c107530eb847c163a4d54c"

S = "${WORKDIR}/rust-1.93.0-armv7-unknown-linux-gnueabihf"

INSANE_SKIP:${PN} += "already-stripped"

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
