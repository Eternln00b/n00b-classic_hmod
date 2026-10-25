#!/bin/bash

doom_inst=$(find pkgs/doom -type f)
doom_s_inst=$(find pkgs/doom_setup -type f)
driver_inst=$(find pkgs/driver -type f)

doom_bin=${doom_inst##*/}
doom_s_bin=${doom_s_inst##*/}
driver_bin=${driver_inst##*/}

#################################################

workdir="/tmp/wrk_hmod"
pkg_name="Chocolate_DOOM.hmod"
script_init="p9000_Chocolate_DOOM"
currentD=$(pwd)

#################################################

wrapper_1st_script="chocolatedoom-cmd"
wrapper_2nd_script="chocolatedoom-wrp"
tmp_dir="/tmp/doom"

#################################################

vkeyboard="gnuboy-vkb"
watchdog="n00b-watchdog"
tiny7z="/bin/tiny7zx"

#################################################

if [[ ! -f "${doom_inst}" ]];then

    echo "the game ${doom_bin} is missing"
    exit 0

fi

if [[ ! -f "${doom_s_inst}" ]];then

    echo "the tool ${doom_s_bin} is missing"
    exit 0

fi

if [[ ! -f "${driver_inst}" ]];then

    echo "the driver ${driver_bin} is missing"
    exit 0

fi

[[ -d ${workdir} ]] && rm -rf ${workdir}
[[ -f ${pkg_name} ]] && rm ${pkg_name}
mkdir ${workdir}

ITEMS=("${doom_inst}" "${doom_s_inst}" "${driver_inst}")
 
for i in "${ITEMS[@]}"
do

    cp ${i} ${workdir}

done

shared_lib=("libsamplerate.so.0" "libSDL2_mixer-2.0.so.0" "libSDL2-2.0.so.0")
shared_lib_v=("libsamplerate.so.0.2.2" "libSDL2_mixer-2.0.so.0.2.2" "libSDL2-2.0.so.0.14.0")
doom_bins=("${doom_bin}" "${doom_s_bin}")

for i in "${doom_bins[@]}"
do

    while read -r lib_1st_ver <&3 && read -r lib_2nd_ver <&4
    do

        patchelf --replace-needed "${lib_1st_ver}" "${lib_2nd_ver}" ${workdir}/${i} 

    done 3< <(printf "%s\n" "${shared_lib[@]}") 4< <(printf "%s\n" "${shared_lib_v[@]}")

done

/bin/cat /dev/null > ${workdir}/${wrapper_1st_script}
/bin/cat <<wrp1 >> ${workdir}/${wrapper_1st_script}
#!/bin/sh
exec /usr/games/$wrapper_2nd_script "\$@"
wrp1

/bin/cat /dev/null > ${workdir}/${wrapper_2nd_script}
/bin/cat <<wrp2 >> ${workdir}/${wrapper_2nd_script}
#!/bin/sh

cleanup() {
	
    pkill -f $vkeyboard 2>/dev/null
    dd if=/dev/zero of=/dev/fb0 bs=4096 count=1800 status=none
    [ -d $tmp_dir ] && rm -rf $tmp_dir
    uistart
    
}

export MALI_NOCLEAR=1
uistop
rom_arg=\$1
rom_name=\$(basename \$rom_arg)
rom_echck=\$(find /media -type f -name \$rom_name)

if [ -n \$rom_echck ];then 

    case \$rom_echck in
        *.7z)

            if [ ! \$(which $tiny7z) ];then

                # if tiny7zx isn't available we have to stop...
                uistart
                exit

            else

                mkdir -p $tmp_dir
                cd $tmp_dir
                $tiny7z x -e\$rom_echck
                rom_f=\$(find $tmp_dir -type f -name "*.wad")
                cd \$HOME

            fi
            ;;

        *.wad)

            rom_f=\$rom_echck
            ;;

        *)
            # Something wrong...
            uistart
            exit
            ;;

    esac

else

    # can't find the rom...
    uistart
    exit

fi

trap cleanup EXIT INT TERM

/bin/reset
fb_state=\$(cat /sys/devices/virtual/vtconsole/vtcon1/bind)
[ \$fb_state -eq 1 ] && echo 0 > /sys/devices/virtual/vtconsole/vtcon1/bind
setsid /usr/bin/$vkeyboard < /dev/null > /dev/null 2>&1 &
/usr/bin/$doom_bin -savedir /media/hakchi/doom -fullscreen -iwad \$rom_f &
DOOM_PID=\$!
/usr/bin/$watchdog -p \$DOOM_PID &
WATCHDOG_PID=\$!
wait \$DOOM_PID 2>/dev/null
kill \$WATCHDOG_PID 2>/dev/null
kill \$DOOM_PID 2>/dev/null
wrp2

/bin/cat /dev/null > ${workdir}/install
/bin/cat <<install >> ${workdir}/install
#!/bin/sh

set -- "$doom_bin" "$doom_s_bin" "$driver_bin"

for b in "\$@"
do

    copy ./\$b \$rootfs/usr/bin/\$b
    chmod 0755 \$rootfs/usr/bin/\$b
    echo "overmount \$rootfs/usr/bin/\$b > \$preinitpath/p9000_\$b"

done

set -- "$wrapper_1st_script" "$wrapper_2nd_script"

for script in "\$@"
do 

    copy ./\$script \$rootfs/usr/games/\$script
    chmod 0755 \$rootfs/usr/games/\$script
    echo "overmount \$rootfs/usr/games/\$script > \$preinitpath/p9000_\$script"

done

return 1
install


/bin/cat /dev/null > ${workdir}/uninstall
/bin/cat <<undo >> ${workdir}/uninstall
#!/bin/sh

rm \$preinitpath/p9000_$wrapper_1st_script \$preinitpath/p9000_$wrapper_2nd_script \$preinitpath/p9000_$driver_bin
rm \$preinitpath/p9000_$doom_bin \$preinitpath/p9000_$doom_s_bin \$rootfs/usr/games/$wrapper_1st_script
rm \$rootfs/usr/games/$wrapper_2nd_script \$rootfs/usr/bin/$driver_bin \$rootfs/usr/bin/$doom_bin
rm \$rootfs/usr/bin/$doom_s_bin
undo

/bin/cat /dev/null > ${workdir}/readme.txt
/bin/cat <<read >> ${workdir}/readme.txt
Chocolate Doom is a Doom source port that is minimalist and historically accurate.
This version (3.1.0) has been ported for Nintendo Classic platforms.
In order to run my port you need the modules libmodplug, libsamplerate, sdl2_mixer and SDL2_rev.
read

cd ${workdir}
tar -czf "../${pkg_name}" .
mv ../${pkg_name} ${currentD}
cd - >/dev/null 2>&1
rm -rf ${workdir}