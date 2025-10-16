SUMMARY = "Create mock Q7 commands"
DESCRIPTION = "This recipe is responsible for providing mock commands available on the q7 but not the zybo."
LICENSE = "CLOSED"
PR = "r0"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "file://q7hw"

do_install() {
    # Install mock commands to /usr/bin
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/q7hw ${D}${bindir}/q7hw
}

FILES:${PN} = "${bindir}/q7hw"
