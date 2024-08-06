FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://bsp.cfg"
KERNEL_FEATURES:append = " bsp.cfg"
SRC_URI += "file://user_2024-07-04-17-51-00.cfg \
            file://user_2024-07-31-22-21-00.cfg \
            file://user_2024-08-06-19-56-00.cfg \
            "

