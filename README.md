In order to use the emulator [gnuboy](https://github.com/Eternln00b/gnuboy), you need to install the module [Eternln00b-watchdog](Eternln00b-watchdog) and the module [SDL2_rev](SDL2_rev).
To install the modules, you have to place them inside a subdirectory of hakchi2 called "user_mods". Most of the time, the root directory "hakchi2" is inside "Documents."

![Screenshot](./.pictures/pathway.png)

=============================================

![Screenshot](./.pictures/hmod.png)

Once the modules are installed with [hakchi2](https://github.com/teamshinkansen/hakchi2-ce/releases) you juste have to use the wrapper script "/usr/games/gnuboy-cmd". 
It doesn't require argument. 

![Screenshot](./.pictures/cmdline1.png)

This version has been compiled with my SDK with my version of [SDL2 (2.0.14)](https://github.com/Eternln00b/n00b-classic.SDL2/tree/release-2.0.14). 
The emulator runs pretty well and the Nintendo gamepads are directly recognized.
The 8bitdo bluetooth gamepads should work too. I tested it with the [8BitDo Mod Kit](https://shop.8bitdo.com/products/8bitdo-mod-kit-for-original-dogbone-controller) and it worked. 

There's no save state mechanism here. However, the sram saves work. 


