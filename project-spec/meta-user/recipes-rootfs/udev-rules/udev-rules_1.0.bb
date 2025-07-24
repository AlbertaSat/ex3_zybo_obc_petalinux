SUMMARY = "Custom UDEV rules"
DESCRIPTION = "Installs custom udev rules for interfaces"
LICENSE = "CLOSED"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "file://interface_permissions.rules \
file://dev_symlink.rules"

do_install() {
    bbnote "udev install task invoked"
    mkdir -p ${D}/etc/udev/rules.d/
    install -m 0644 ${WORKDIR}/interface_permissions.rules ${D}${sysconfdir}/udev/rules.d/interface_permissions.rules
    install -m 0644 ${WORKDIR}/dev_symlink.rules ${D}${sysconfdir}/udev/rules.d/dev_symlink.rules
}

FILES_${PN} += "${sysconfdir}/udev/rules.d/interface_permissions.rules \
${sysconfdir}/udev/rules.d/dev_symlink.rules"

CONFFILES_${PN} += "${sysconfdir}/udev/rules.d/interface_permissions.rules \
${sysconfdir}/udev/rules.d/dev_symlink.rules"