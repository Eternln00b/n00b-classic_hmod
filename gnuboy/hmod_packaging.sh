#!/bin/bash

workdir="/tmp/wrk_hmod"
tmpDir="/tmp/gnuboy"
saveDir="/media/hakchi/gnuboy"
watchdog="/usr/bin/n00b-watchdog"
gnuboy_bin_chck=$(find pkgs/ -type f)
gnuboy_bin=${gnuboy_bin_chck##*/}
pkg_name="gnuboy.hmod"
wrapper_1st_script="gnuboy-cmd"
wrapper_2nd_script="gnuboy-wrp"
currentD=$(pwd)

#####################################

if [[ ! -f "${gnuboy_bin_chck}" ]];then

    echo "the emulator ${gnuboy_bin} is missing."
    exit 0

fi

if [[ ! -x $(command -v patchelf) ]];then

    echo "the command patchelf isn't installed..."
    exit 0

fi

[[ -d ${workdir} ]] && rm -rf ${workdir}
[[ -f ${pkg_name} ]] && rm ${pkg_name}
mkdir ${workdir}

cp ${gnuboy_bin_chck} ${workdir}
patchelf --replace-needed libSDL2-2.0.so.0 libSDL2-2.0.so.0.14.0 ${workdir}/${gnuboy_bin}  

/bin/cat /dev/null > ${workdir}/${wrapper_1st_script}
/bin/cat <<wrp1 >> ${workdir}/${wrapper_1st_script}
#!/bin/sh

extractRom(){

    local rom_name="\$(basename \$1)"
    local rom_e="\$(find /media/hakchi/games -type f -name \$rom_name)"
    
    if [ -n \$rom_e ];then

        tmp_e="$tmpDir"
        [ -d \$tmp_e/rom ] && rm -rf \$tmp_e/rom
        mkdir -p \$tmp_e/rom

        case \$rom_e in

            *.7z)

                if [ ! \$(which tiny7zx) ];then

                    # if tiny7zx isn't available we have to stop...
                    uistart
                    exit

                else

                    cd \$tmp_e/rom
                    tiny7zx x -e\$rom_e
                    rom_f=\$(find \$tmp_e/rom -type f -regex ".*\.\(gb\|gbc\)\$")
                    cd - >/dev/null

                fi
                ;;

            *.gb|*.gbc)

                rom_f=\$rom_e
                ;;
            
            *)
            
                # the extension is maybe not supported
                uistart
                exit
                ;;

        esac

    else

        # can't find the rom...
        uistart
        exit

    fi 
    
} >/dev/null 2>&1

export MALI_NOCLEAR=1
uistop

if [ ! \$(which n00b-watchdog) ] || [ ! -f "/usr/lib/libSDL2-2.0.so.0.14.0" ];then

    # if the watchdog isn't available we have to stop...
    uistart
    exit

else

    extractRom "\$@"
    exec /usr/games/gnuboy-wrp "\$rom_f"

fi
wrp1


/bin/cat /dev/null > ${workdir}/${wrapper_2nd_script}
/bin/cat <<wrp2 >> ${workdir}/${wrapper_2nd_script}
#!/bin/sh

cleanup() {

    sync
    find $tmpDir/sav -type f \( -name "*.sav" -o -name "*.00[0-9]" \) 2>/dev/null | while IFS= read -r sav; do
    
        chmod 0744 "\$sav"
        rsync "\$sav" "/media/hakchi/gnuboy/\$(basename "\$sav")"
    
    done

    [ -d /tmp/gnuboy ] && rm -rf /tmp/gnuboy
    dd if=/dev/zero of=/dev/fb0 bs=4096 count=1800 status=none
    uistart

}

trap cleanup EXIT INT TERM

rom_f=\$1

if [ ! -d $saveDir ]; then

    mkdir -p $saveDir

else

    rom_n=\$(basename \${rom_f%%.*})
    [ ! -d $tmpDir/sav ] && mkdir -p $tmpDir/sav
    find /media/hakchi/gnuboy -type f \( -name "\$rom_n.sav" -o -name "\$rom_n.00[0-9]" \) 2>/dev/null | while IFS= read -r sav; do

        rsync "\$sav" "$tmpDir/sav/\$(basename "\$sav")"
    
    done

fi

/bin/reset
fb_state=\$(cat /sys/devices/virtual/vtconsole/vtcon1/bind)
[ \$fb_state -eq 1 ] && echo 0 > /sys/devices/virtual/vtconsole/vtcon1/bind
/usr/bin/$gnuboy_bin --fullscreen=1 --vmode=640,480 \$rom_f &
GNUBOY_PID=\$!
$watchdog -p \$GNUBOY_PID &
WATCHDOG_PID=\$!
wait \$GNUBOY_PID 2>/dev/null
kill \$WATCHDOG_PID 2>/dev/null
kill \$GNUBOY_PID 2>/dev/null
wrp2

/bin/cat /dev/null > ${workdir}/install
/bin/cat <<inst >> ${workdir}/install
#!/bin/sh

install -m 0755 ./$gnuboy_bin \$rootfs/usr/bin/$gnuboy_bin
echo "overmount \$rootfs/usr/bin/$gnuboy_bin" > \$preinitpath/p9000_$gnuboy_bin

set -- "$wrapper_1st_script" "$wrapper_2nd_script"

for script in "\$@"
do 

    install -m 0755 ./\$script \$rootfs/usr/games/\$script
    echo "overmount \$rootfs/usr/games/\$script" > \$preinitpath/p9000_\$script

done

return 1
inst

/bin/cat /dev/null > ${workdir}/uninstall
/bin/cat <<undo >> ${workdir}/uninstall
#!/bin/sh

rm \$preinitpath/p9000_$wrapper_1st_script \$preinitpath/p9000_$wrapper_2nd_script
rm \$preinitpath/p9000_$gnuboy_bin \$rootfs/usr/bin/$gnuboy_bin 
rm \$rootfs/usr/games/$wrapper_1st_script \$rootfs/usr/games/$wrapper_2nd_script

undo

/bin/cat /dev/null > ${workdir}/readme.txt
/bin/cat <<read >> ${workdir}/readme.txt
An oldschool standalone Gameboy emulator (https://github.com/rofl0r/gnuboy).
In order to use it you need to install the module "Eternln00b_watchdog" and the module "SDL2_rev".
Optionally you have to install "tiny7zx" if you plan to compress your roms. 
read

cd ${workdir}
tar -czf "../${pkg_name}" .
mv ../${pkg_name} ${currentD}
cd - >/dev/null 2>&1
rm -rf ${workdir}
