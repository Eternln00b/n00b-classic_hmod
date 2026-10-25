#!/bin/bash

f_chck=$(find pkg/ -type f)
libsdl2_mixer=${f_chck#*/}
workdir="/tmp/wrk_hmod"
pkg_name="sdl2_mixer.hmod"
script_init="p8000_libsdl2_mixer"
currentD=$(pwd)

if [[ ! -f "${f_chck}" ]];then

    echo "the lib ${libsdl2_mixer} is missing"
    exit 0

fi

[[ -d ${workdir} ]] && rm -rf ${workdir}
[[ -f ${pkg_name} ]] && rm ${pkg_name}
mkdir ${workdir}

cp ${f_chck} ${workdir}

shared_lib=("libSDL2-2.0.so.0" "libmodplug.so.1")
shared_lib_v=("libSDL2-2.0.so.0.14.0" "libmodplug.so.1.0.0")

while read -r lib_1st_ver <&3 && read -r lib_2nd_ver <&4
do

    patchelf --replace-needed "${lib_1st_ver}" "${lib_2nd_ver}" ${workdir}/${libsdl2_mixer} 

done 3< <(printf "%s\n" "${shared_lib[@]}") 4< <(printf "%s\n" "${shared_lib_v[@]}")

patchelf --remove-rpath ${workdir}/${libsdl2_mixer}

/bin/cat /dev/null > ${workdir}/install
/bin/cat <<install >> ${workdir}/install
#!/bin/sh

copy ./$libsdl2_mixer \$rootfs/usr/lib/$libsdl2_mixer
chmod 0755 \$rootfs/usr/lib/$libsdl2_mixer

echo "overmount /usr/lib" > \$preinitpath/$script_init

return 1
install

/bin/cat /dev/null > ${workdir}/uninstall
/bin/cat <<undo >> ${workdir}/uninstall
#!/bin/sh

rm \$rootfs/usr/lib/$libsdl2_mixer \$preinitpath/$script_init
undo

/bin/cat /dev/null > ${workdir}/readme.txt
/bin/cat <<read >> ${workdir}/readme.txt
Chocolate doom requires the library sdl_mixer. 
read

cd ${workdir}
tar -czf "../${pkg_name}" .
mv ../${pkg_name} ${currentD}
cd - >/dev/null 2>&1
rm -rf ${workdir}