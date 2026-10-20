#!/bin/bash

workdir="/tmp/wrk_hmod"
tmpDir="/tmp/gnuboy"
saveDir="/media/hakchi/gnuboy"
watchdog="/usr/bin/n00b-watchdog"
tiny7z="/bin/tiny7zx"
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
exec /usr/games/$wrapper_2nd_script "\$@"
wrp1


/bin/cat /dev/null > ${workdir}/${wrapper_2nd_script}
/bin/cat <<wrp2 >> ${workdir}/${wrapper_2nd_script}
#!/bin/sh

cleanup() {
	
    sync
    local rom_sav=\$(find $tmpDir/sav -type f -name "*.sav" -print 2>/dev/null)
    [ -z \$rom_sav ] && rom_h=0 || rom_h=1
    
    if [ \$rom_h -eq 1 ];then

        chmod 0744 \$rom_sav
        local rom_sav_n=\$(basename \$rom_sav)
        rsync \$rom_sav $saveDir/\$rom_sav_n
        
    fi 
    
    [ -d $tmpDir ] && rm -rf $tmpDir
    dd if=/dev/zero of=/dev/fb0 bs=4096 count=1800 status=none
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

                mkdir -p $tmpDir/rom
                cd $tmpDir/rom
                $tiny7z x -e\$rom_echck
                rom_f=\$(find $tmpDir/rom -type f -regex ".*\.\(gb\|gbc\)\$")
                cd -

            fi
            ;;

        *.gb|*.gbc)

            rom_f=\$rom_echck
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

if [ ! \$(which $watchdog) ];then

    # if the watchdog isn't available we have to stop...
    uistart
    exit

fi

if [ ! -f "/usr/lib/libSDL2-2.0.so.0.14.0" ];then

    # if SDL2.0.14 isn't installed we have to stop...
    uistart
    exit

fi

trap cleanup EXIT INT TERM

if [ ! -d $saveDir ]; then 

    mkdir -p $saveDir

else

    rom_srm_n=\$(basename \$rom_f | awk -F. '{print \$1 ".sav"}')
    lf_rom_srm=\$(find $saveDir -type f -name \$rom_srm_n -print 2>/dev/null)
    [ -z \$lf_rom_srm ] && rom_h=0 || rom_h=1

    if [ \$rom_h -eq 1 ];then
    
        [ ! -d $tmpDir/sav ] && mkdir -p $tmpDir/sav
        rsync \$lf_rom_srm $tmpDir/sav/\$rom_srm_n

    fi 
 
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
/bin/cat <<install >> ${workdir}/install
#!/bin/sh

copy ./$gnuboy_bin \$rootfs/usr/bin/$gnuboy_bin
chmod 0755 \$rootfs/usr/bin/$gnuboy_bin
echo "overmount \$rootfs/usr/bin/$gnuboy_bin > \$preinitpath/p9000_$gnuboy_bin"

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
