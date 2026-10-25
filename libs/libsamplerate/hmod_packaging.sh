#!/bin/bash

f_chck=$(find pkg/ -type f)
libsamplerate=${f_chck#*/}
workdir="/tmp/wrk_hmod"
pkg_name="libsamplerate.hmod"
script_init="p8000_libsamplerate"
currentD=$(pwd)

if [[ ! -f "${f_chck}" ]];then

    echo "the lib ${libsamplerate} is missing"
    exit 0

fi

[[ -d ${workdir} ]] && rm -rf ${workdir}
[[ -f ${pkg_name} ]] && rm ${pkg_name}
mkdir ${workdir}

cp ${f_chck} ${workdir}

/bin/cat /dev/null > ${workdir}/install
/bin/cat <<install >> ${workdir}/install
#!/bin/sh

copy ./$libsamplerate \$rootfs/usr/lib/$libsamplerate
chmod 0755 \$rootfs/usr/lib/$libsamplerate

echo "overmount /usr/lib" > \$preinitpath/$script_init

return 1
install

/bin/cat /dev/null > ${workdir}/uninstall
/bin/cat <<undo >> ${workdir}/uninstall
#!/bin/sh

rm \$rootfs/usr/lib/$libsamplerate \$preinitpath/$script_init
undo

/bin/cat /dev/null > ${workdir}/readme.txt
/bin/cat <<read >> ${workdir}/readme.txt
Chocolate doom requires the library libsamplerate.
read

cd ${workdir}
tar -czf "../${pkg_name}" .
mv ../${pkg_name} ${currentD}
cd - >/dev/null 2>&1
rm -rf ${workdir}