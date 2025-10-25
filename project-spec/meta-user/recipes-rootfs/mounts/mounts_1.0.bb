SUMMARY = "Create mount points for SD card partitions"
DESCRIPTION = "This recipe creates the mountpoints defined in the OBC ICD for the sd cards"
LICENSE = "CLOSED"
PR = "r0"

inherit systemd

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "file://mounts/ \
           file://services/ \
           "

do_install() {
    # Create storage mountpoints
    install -d ${D}/mnt/storage/hk
    install -d ${D}/mnt/storage/logs
    install -d ${D}/mnt/storage/fsw
    install -d ${D}/mnt/storage/iris
    install -d ${D}/mnt/storage/dfgm

    # Create backup mountpoints
    install -d ${D}/mnt/backup/hk
    install -d ${D}/mnt/backup/logs
    install -d ${D}/mnt/backup/fsw
    install -d ${D}/mnt/backup/iris
    install -d ${D}/mnt/backup/dfgm

    # Create /var/log
    install -d ${D}/var/log

    # Install systemd services and mounts
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/services/* ${D}${systemd_system_unitdir}/
    install -m 0644 ${WORKDIR}/mounts/* ${D}${systemd_system_unitdir}/
}

SYSTEMD_SERVICE:${PN} = " \
    mnt-storage-hk.mount \
    mnt-storage-logs.mount \
    mnt-storage-fsw.mount \
    mnt-storage-iris.mount \
    mnt-storage-dfgm.mount \
    var-log.mount \
    enable-sd.service \
    journal-flush-on-shutdown.service \
    journal-flush-to-sd.service \
    var-log-prep.service \
    "

FILES:${PN} = "/mnt/* \
               /var/log \
               ${systemd_system_unitdir}/*.service \
               ${systemd_system_unitdir}/*.mount"
