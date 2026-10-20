#!/bin/bash

f_chck=$(find pkg/ -type f)
libsdl2=${f_chck#*/}
workdir="/tmp/wrk_hmod"
pkg_name="SDL2_rev.hmod"
script_init="p8000_libsdl2"
currentD=$(pwd)

if [[ ! -f "${f_chck}" ]];then

    echo "the lib ${libsdl2} is missing"
    exit 0

fi

[[ -d ${workdir} ]] && rm -rf ${workdir}
[[ -f ${pkg_name} ]] && rm ${pkg_name}
mkdir ${workdir}

cp ${f_chck} ${workdir}

/bin/cat /dev/null > ${workdir}/install
/bin/cat <<install >> ${workdir}/install
#!/bin/sh

copy ./$libsdl2 \$rootfs/usr/lib/$libsdl2
chmod 0755 \$rootfs/usr/lib/$libsdl2

echo "overmount /usr/lib" > \$preinitpath/$script_init

return 1
install

/bin/cat /dev/null > ${workdir}/uninstall
/bin/cat <<undo >> ${workdir}/uninstall
#!/bin/sh

rm \$rootfs/usr/lib/$libsdl2 \$preinitpath/$script_init
undo

/bin/cat /dev/null > ${workdir}/readme.txt
/bin/cat <<read >> ${workdir}/readme.txt
An updated version of SDL2 (2.0.14) for Nintendo Classic platforms.
read

cd ${workdir}
tar -czf "../${pkg_name}" .
mv ../${pkg_name} ${currentD}
cd - >/dev/null 2>&1
rm -rf ${workdir}