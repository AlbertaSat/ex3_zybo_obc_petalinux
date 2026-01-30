FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://bsp.cfg"
KERNEL_FEATURES:append = " bsp.cfg"
SRC_URI += "file://user_2024-07-04-17-51-00.cfg \
            file://user_2024-07-31-22-21-00.cfg \
            file://user_2024-08-06-19-56-00.cfg \
            file://user_2024-08-06-20-49-00.cfg \
            file://user_2024-08-06-21-38-00.cfg \
            file://user_2024-08-13-21-55-00.cfg \
            file://user_2025-07-31-19-57-00.cfg \
            file://user_2025-08-01-01-19-00.cfg \
            file://user_2026-01-30-16-07-00.cfg \
            file://user_2026-01-30-16-13-00.cfg \
            "

# Add patches for usb251xb driver
SRC_URI += "file://usb251xb-fix-bad-conf1.patch \
            "

KERNEL_MODULE_PROBECONF += "usb251xb"
module_conf_usb251xb = "blacklist usb251xb"