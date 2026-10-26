#include <linux/input.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>

int main() {

    int fd = open("/dev/input/event24", O_RDONLY);
    struct input_event ev;
    
    while (read(fd, &ev, sizeof(ev)) > 0) {
        printf("Type: %d, Code: %d, Value: %d\n", ev.type, ev.code, ev.value);
    }
    
    close(fd);
    return 0;

}