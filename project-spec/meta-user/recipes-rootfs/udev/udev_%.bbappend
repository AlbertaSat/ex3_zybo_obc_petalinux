FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "file://interfaces.rules"

do_install () {
    echo "udev install task invoked"

    install -m 0666 ${WOKRDIR}/interfaces.rules    ${D}/etc/udev/rules.d/interfaces.rules

}

FILES_${PN} += " /etc/udev/rules.d/interfaces.rules"
