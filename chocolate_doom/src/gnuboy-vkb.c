#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <linux/input.h>
#include <linux/uinput.h>

#define DEV_GAMEPAD "/dev/input/event24"
#define DEV_UINPUT  "/dev/uinput"

struct mapping {
    int btn_gamepad;
    int keyboad_key;
};

static struct mapping mappings[] = {
    { 704, KEY_LEFT },       
    { 705, KEY_RIGHT },      
    { 706, KEY_UP },         
    { 707, KEY_DOWN },       

    // actions
    { 304, KEY_LEFTCTRL },   // A -> Fire
    { 305, KEY_SPACE },      // B -> Use
    { 307, KEY_LEFTSHIFT },  // X -> Run
    { 308, KEY_LEFTALT },    // Y -> Strafe

    // menu 
    { 314, KEY_ENTER },      // Select -> Automap
    { 315, KEY_BACKSPACE },  // Start -> Menu
    { 310, KEY_1 },          // L -> Gun 1
    { 311, KEY_2 },          // R -> Gun 2

    { -1, -1 }
};

static int find_key(int btn) {
    for (int i = 0; mappings[i].btn_gamepad != -1; i++) {
        if (mappings[i].btn_gamepad == btn)
            return mappings[i].keyboad_key;
    }
    return -1;
}

static int send_keystroke(int fd, int code, int value) {
    struct input_event ev;

    memset(&ev, 0, sizeof(ev));
    ev.type  = EV_KEY;
    ev.code  = code;
    ev.value = value;
    if (write(fd, &ev, sizeof(ev)) < 0) {
        perror("write EV_KEY");
        return -1;
    }

    memset(&ev, 0, sizeof(ev));
    ev.type  = EV_SYN;
    ev.code  = SYN_REPORT;
    ev.value = 0;
    if (write(fd, &ev, sizeof(ev)) < 0) {
        perror("write SYN_REPORT");
        return -1;
    }

    return 0;
}

int main(void) {

    // reads the gamepad event
    int fd_gamepad = open(DEV_GAMEPAD, O_RDONLY);
    if (fd_gamepad < 0) {
        perror("open gamepad");
        return 1;
    }

    // uinput is open
    int fd_uinput = open(DEV_UINPUT, O_WRONLY | O_NONBLOCK);
    if (fd_uinput < 0) {
        perror("open uinput");
        close(fd_gamepad);
        return 1;
    }

    // virtual keyboard has been set
    if (ioctl(fd_uinput, UI_SET_EVBIT, EV_KEY) < 0) {
        perror("UI_SET_EVBIT EV_KEY");
        close(fd_uinput);
        close(fd_gamepad);
        return 1;
    }
    if (ioctl(fd_uinput, UI_SET_EVBIT, EV_SYN) < 0) {
        perror("UI_SET_EVBIT EV_SYN");
        close(fd_uinput);
        close(fd_gamepad);
        return 1;
    }
    for (int i = 0; mappings[i].btn_gamepad != -1; i++) {
        if (ioctl(fd_uinput, UI_SET_KEYBIT, mappings[i].keyboad_key) < 0) {
            perror("UI_SET_KEYBIT");
            close(fd_uinput);
            close(fd_gamepad);
            return 1;
        }
    }

    // uinput device configuration
    struct uinput_user_dev uidev;
    memset(&uidev, 0, sizeof(uidev));
    snprintf(uidev.name, UINPUT_MAX_NAME_SIZE, "Clovercon Virtual Keyboard");
    uidev.id.bustype = BUS_VIRTUAL;
    uidev.id.vendor  = 0x0001;
    uidev.id.product = 0x0001;
    uidev.id.version = 1;

    if (write(fd_uinput, &uidev, sizeof(uidev)) < 0) {
        perror("write uinput_user_dev");
        close(fd_uinput);
        close(fd_gamepad);
        return 1;
    }

    // create the device
    if (ioctl(fd_uinput, UI_DEV_CREATE) < 0) {
        perror("UI_DEV_CREATE");
        close(fd_uinput);
        close(fd_gamepad);
        return 1;
    }

    printf("Virtual keyboad plugged ! Waiting inputs...\n");
    fflush(stdout);

    // The gamepad writes keystrokes.
    struct input_event ev_gamepad;

    while (read(fd_gamepad, &ev_gamepad, sizeof(ev_gamepad)) > 0) {
        
        // axes are ignored
        if (ev_gamepad.type != EV_KEY)
            continue;

        int touche = find_key(ev_gamepad.code);
        
        if (touche < 0)
            continue; 

        if (send_keystroke(fd_uinput, touche, ev_gamepad.value) < 0) {
            fprintf(stderr, "error code : %d\n", ev_gamepad.code);
            break;
        }
    }
	
	// virtual keyboard unplugged
    ioctl(fd_uinput, UI_DEV_DESTROY);
    close(fd_uinput);
    close(fd_gamepad);
    return 0;
}
