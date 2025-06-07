#include "include/tb_common.h"


extern VerilatedContext* contextp;
extern VerilatedVcdC* tfp;
extern Vtop* top;
#define CONFIG_WAVETRACE 1

void step_wave(){
  top->eval();
  contextp->timeInc(1);
  tfp->dump(contextp->time());
  top->eval();
}

void single_cycle() {
    top->clk = 1; 
    step_wave();
    top->clk = 0; 
    step_wave();
}

void cycle(int num) {
  for(int i = 0; i < num; i++) {
    single_cycle();
  }
}


  
void reset() {
    top->rst = 1;
    
    top->clk = 1; 
    step_wave();
    top->clk = 0; 
    step_wave();
    top->clk = 1; 
    step_wave();

    top->rst = 0;
    
    top->clk = 0; 
    step_wave();
}

void sim_init(){
  contextp = new VerilatedContext;
  tfp = new VerilatedVcdC;
  top = new Vtop;
  
  
  #if CONFIG_WAVETRACE
  contextp->traceEverOn(true);
  #endif
  top->trace(tfp, 10);
  #if CONFIG_WAVETRACE
  tfp->open("test10.vcd");
  #endif
}

void sim_exit(){
  step_wave();
  top->final();
  delete top;
  tfp->close();
  delete contextp;
}