# Append additional TTYs to the shadow-securetty file
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://extra-ttys"

do_install:append() {
    cat ${WORKDIR}/extra-ttys >> ${D}${sysconfdir}/securetty
}