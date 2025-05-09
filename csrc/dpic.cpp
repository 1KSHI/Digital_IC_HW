#include "verilated_dpi.h"

extern int a_mem[4096];
extern int b_mem[4096];
extern int c_mem[4096];
extern int d;
extern void cor_y(int a,int b, int c, int d);
extern int count_dpi;

extern "C" void check_finsih(int y){
    int a = a_mem[count_dpi];
    int b = b_mem[count_dpi];
    int c = c_mem[count_dpi];
    //printf("a=%d, b=%d, c=%d, d=%d\n", a, b, c, d);
    cor_y(a, b, c, d);
    count_dpi++;
}
