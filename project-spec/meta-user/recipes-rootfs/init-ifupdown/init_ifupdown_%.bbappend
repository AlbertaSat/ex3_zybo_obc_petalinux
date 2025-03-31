# init-ifupdown_%.bbappend content
  
SRC_URI += " \
        file://myinterfaces \
        "
# For 2022.1 release onwards
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
# For 2021.2 and old releases
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
 
# Overwrite interface file with myinterface file in rootfs
# For 2022.1 release onwards
do_install:append() {
     install -m 0644 ${WORKDIR}/myinterfaces ${D}${sysconfdir}/network/interfaces
}
 
#For 2021.2 and old releases
do_install_append() {
     install -m 0644 ${WORKDIR}/myinterfaces ${D}${sysconfdir}/network/interfaces
}