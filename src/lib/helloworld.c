#include <helloworld.h>

static int print_another() {
    printf("Hello World!\n");
    return 0;
}

int print_helloworld(void) {
    return print_another();
}