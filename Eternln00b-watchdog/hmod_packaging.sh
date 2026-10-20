#!/bin/bash

pkg_chck=$(find pkg/ -type f)
Eternln00b_watchdog=${pkg_chck#*/}
workdir="/tmp/wrk_hmod"
pkg_name="Eternln00b_watchdog.hmod"
currentD=$(pwd)

if [[ ! -f "${pkg_chck}" ]];then

    echo "the watchdog ${Eternln00b_watchdog} is missing"
    exit 0

fi

[[ -d ${workdir} ]] && rm -rf ${workdir}
[[ -f ${pkg_name} ]] && rm ${pkg_name}
mkdir ${workdir}
cp ${pkg_chck} ${workdir}

/bin/cat /dev/null > ${workdir}/install
/bin/cat <<install >> ${workdir}/install
#!/bin/sh

copy ./$Eternln00b_watchdog \$rootfs/usr/bin/$Eternln00b_watchdog
chmod 0755 \$rootfs/usr/bin/$Eternln00b_watchdog
echo "overmount \$rootfs/usr/bin/$Eternln00b_watchdog > \$preinitpath/p8000_$Eternln00b_watchdog"

return 1
install

/bin/cat /dev/null > ${workdir}/uninstall
/bin/cat <<undo >> ${workdir}/uninstall
#!/bin/sh

rm \$rootfs/usr/bin/$Eternln00b_watchdog \$preinitpath/p8000_$Eternln00b_watchdog
undo

/bin/cat /dev/null > ${workdir}/readme.txt
/bin/cat <<read >> ${workdir}/readme.txt
This module is a watchdog that makes the reset button and the switch on/off usables during the game. 
This module is mandatory if you want to use my ported stuffs.
read

cd ${workdir}
tar -czf "../${pkg_name}" .
mv ../${pkg_name} ${currentD}
cd - >/dev/null 2>&1
rm -rf ${workdir}
