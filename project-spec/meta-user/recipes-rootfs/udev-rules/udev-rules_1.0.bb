SUMMARY = "Custom udev rules"
DESCRIPTION = "Installs custom udev rules for interfaces"
LICENSE = "CLOSED"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "file://interface_permissions.rules \
file://dev_symlink.rules"

do_install() {
    echo "udev install task invoked"
    mkdir -p ${D}/etc/udev/rules.d/
    install -m 0666 ${WORKDIR}/interface_permissions.rules ${D}/etc/udev/rules.d/interface_permissions.rules
    install -m 0666 ${WORKDIR}/dev_symlink.rules ${D}/etc/udev/rules.d/dev_symlink.rules
}

INSANE_SKIP_${PN} += "fileattr"

FILES_${PN} += "${sysconfdir}/udev/rules.d/interface_permissions.rules:config \
${sysconfdir}/udev/rules.d/dev_symlink.rules:config"
