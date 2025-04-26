#include "include/tb_common.h"

VerilatedContext* contextp = NULL;
VerilatedVcdC* tfp = NULL;
Vtop* top;


int main(int argc, char *argv[]) {
    sim_init();
    reset(1);
    int count=0;
    int success=0;

    for(int i=0; i<4096; i=i+3) {
        for(int j=0; j <4096 ; j=j+3){
            int mula = i;
            int mulb = j;
            int res = mula * mulb;
            top->mula = mula;
            top->mulb = mulb;
            printf("i: %d, j: %d\n", i, j);
            top->eval();
            if(top->res != res) {
                printf("Error: Expected %d, got %d\n", res, top->res);
            } else {
                //printf("Success: Expected %d, got %d\n", res, top->res);
                success++;
            }
            cycle(1);
            count++;
        }
    }
    printf("total test %d, success %d, correct rate %d %%\n", count, success,success*100/count);

    sim_exit();

    return 0;
}
