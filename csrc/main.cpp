#include "include/tb_common.h"
#include <stdio.h>

VerilatedContext* contextp = NULL;
VerilatedVcdC* tfp = NULL;
Vtop* top;
#define PI 3.14159265358979323846
#define PRINTF 1

int count = 0;
int success = 0;

int a = 2040;
int b = 795;
int c = 123;
int d = 1383;
void cor_y(int a,int b, int c, int d){
    double y_true = 0;
    y_true = (a*b*cos(2*PI*c/pow(2, 12)))/(a+d)/pow(2, 12);
    #if PRINTF 
    printf("y_true=%.15f  ", y_true);
    #endif

    float y_result = top->y&0xFFF;
    int sign = top->y>>12;
    if(sign == 1){
        y_result = -y_result;
    }
    #if PRINTF 
    printf("y=%.15f  ", y_result/pow(2,12));
    #endif
    double error = 0;
    error = fabs(y_result/pow(2,12) - y_true);
    #if PRINTF 
    printf("error=%.15f \n", error);
    #endif
    if(error < pow(2, -10)){
        success++;
        printf("pass\n");
    }else{
        printf("fail\n");
    }
    count++;
}

void give_e(int e){
    for(int i = 0; i < 12; i++) {
        if(e & 1<<i){
            top->e = 1;
        }else{
            top->e = 0;
        }
        e>>1;
        cycle(1);
    }
}


int main(int argc, char *argv[]) {
    sim_init();
    reset(1);
    // d = rand() % 4096;
    d = 5;
    give_e(d);
    for(int i = 0; i < 1; i++) {
        cycle(1);
        // a = rand() % 4096;a=966, b=2153, c=2163, d=1383
        // b = rand() % 4096;
        // c = rand() % 2046;
        a = 5;
        b = 1;
        c = 1;
        top->a=a;
        top->b=b;
        top->c=c;
        cycle(17);
        printf("a=%d, b=%d, c=%d, d=%d\n", top->a, top->b, top->c, top->d);
        cor_y(top->a, top->b, top->c, top->d);
    }
    printf("success=%d, count=%d rate=%d%%\n", success, count, success*100/count);
    cycle(11);
    sim_exit();

    return 0;
}
