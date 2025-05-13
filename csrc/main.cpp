#include "include/tb_common.h"
#include <stdio.h>

VerilatedContext* contextp = NULL;
VerilatedVcdC* tfp = NULL;
Vtop* top;
#define PI 3.14159265358979323846
#define PRINTF 1
#define PRINTF_DAT 0
int count_dpi = 0;
int a_mem[4096];
int b_mem[4096];
int c_mem[4096];

int count = 0;
int success = 0;

int a = 2040;
int b = 795;
int c = 123;
int d = 1383;
void cor_y(int a,int b, int c, int d){
    double y_true = 0;
    y_true = (a*b*cos(2*PI*c/pow(2, 12)))/(a+d)/pow(2, 12);
    #if PRINTF_DAT 
    printf("y_true=%.15f  ", y_true);
    #endif

    float y_result = top->y&0xFFF;
    int sign = top->y>>12;
    if(sign == 1){
        y_result = -y_result;
    }
    #if PRINTF_DAT 
    printf("y=%.15f  ", y_result/pow(2,12));
    #endif
    double error = 0;
    error = fabs(y_result/pow(2,12) - y_true);
    #if PRINTF_DAT 
    printf("error=%.15f \n", error);
    #endif
    
    if(error < pow(2, -10)){
        success++;
        #if PRINTF_DAT 
        printf("pass\n");
        #endif
    }else{
        //#if PRINTF_DAT 
        printf("fail\n");
        printf("a=%d, b=%d, c=%d, d=%d\n", a, b, c, d);
        printf("y_true=%.15f  ", y_true);
        printf("y=%.15f  ", y_result/pow(2,12));
        
        printf("error=%.15f \n", error);
        printf("count=%d\n", count);
        
        //#endif
    }
    if(count == 4087){
        printf("a=%d, b=%d, c=%d, d=%d\n", a, b, c, d);
        printf("y_true=%.15f  ", y_true);
        printf("y=%.15f  ", y_result/pow(2,12));
        
        printf("error=%.15f \n", error);
        printf("count=%d\n", count);
    }

    //printf("y=%x  ", top->y);
    
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


void data_test(int num){
    for(int i = 0; i < num; i++) {
        a = rand() % 4096;
        b = rand() % 4096;
        c = rand() % 4096;
        top->a=a;
        top->b=b;
        top->c=c;
        a_mem[i] = a;
        b_mem[i] = b;
        c_mem[i] = c;
        //printf("a=%d, b=%d, c=%d, d=%d\n", top->a, top->b, top->c, top->d);
        cycle(1);
    }
}

void fix_test(){
    a = 1305;
    b = 1897;
    c = 2551;
    top->a=a;
    top->b=b;
    top->c=c;
    a_mem[0] = a;
    b_mem[0] = b;
    c_mem[0] = c;
    cycle(1);
    a = 69;
    b = 1411;
    c = 2993;
    top->a=a;
    top->b=b;
    top->c=c;
    a_mem[1] = a;
    b_mem[1] = b;
    c_mem[1] = c;
    cycle(1);
    a = 1155;
    b = 1546;
    c = 3258;
    top->a=a;
    top->b=b;
    top->c=c;
    a_mem[2] = a;
    b_mem[2] = b;
    c_mem[2] = c;
    cycle(1);
    //printf("a=%d, b=%d, c=%d, d=%d\n", top->a, top->b, top->c, top->d);
}


int main(int argc, char *argv[]) {
    sim_init();
    reset(1);
    srand(44);
    d = rand() % 4096;
    // d = 1383;
    give_e(d);
    //fix_test();
    //data_test(1);
    
    data_test(4000);

    cycle(8);
    printf("total=%d, success=%d, rate=%.2f%%\n", count, success, (float)success/count*100);
    // for(int i = 0; i < 1; i++) {
    //     cycle(1);
    //     // a = rand() % 4096;a=966, b=2153, c=2163, d=1383
    //     // b = rand() % 4096;
    //     // c = rand() % 2046;
    //     a = 323;
    //     b = 2153;
    //     c = 23;
    //     top->a=a;
    //     top->b=b;
    //     top->c=c;
    //     printf("a=%d, b=%d, c=%d, d=%d\n", top->a, top->b, top->c, top->d);
    //     cycle(1);
    //     a = 12;
    //     b = 334;
    //     c = 12;
    //     top->a=a;
    //     top->b=b;
    //     top->c=c;
    //     printf("a=%d, b=%d, c=%d, d=%d\n", top->a, top->b, top->c, top->d);
    //     cycle(16);
    //     cor_y(323, 2153, 23, top->d);
    //     cycle(1);
    //     cor_y(12, 334, 12, top->d);
    // }
    // printf("success=%d, count=%d rate=%d%%\n", success, count, success*100/count);
    // cycle(11);
    sim_exit();

    return 0;
}
