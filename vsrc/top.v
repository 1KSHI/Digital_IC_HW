`ifdef SIMULATION
import "DPI-C" function void check_finsih(int y);
`endif

module top(
    input clk,
    input rst,
    input [11:0]a,
    input [11:0]b,
    input [11:0]c,
    input e,
    output [12:0] y
);
reg [11:0] d_reg;
reg [3:0]count;
wire init_end = (count == 4'd12) ? 1'b1 : 1'b0;


always @(posedge clk) begin
    if (rst) begin
        count <= 0;
        d_reg <= 0;
    end else if(!init_end) begin
        count <= count + 1;
        d_reg[count] <= e;
    end else begin
        count <= 4'd12;
        d_reg <= d_reg;
    end
end


//(a+d)  
//=========================== cycle 1 ============================
wire [12:0] Fir_add_wire;
reg  [12:0] Fir_add_reg;

wire [11:0] Sec_rom_wire;
reg  [11:0] Sec_rom_reg;//cos c>>12

reg [11:0] Fir_a_reg;//a
reg [11:0] Fir_b_reg;//b

Adder12 Adder12 (
    .x_in      (a           ),
    .y_in      (d_reg       ),
    .result_out(Fir_add_wire)
);

Rom Rom(
    .clk       (clk          ),
    .rst       (rst          ),
    .x_in      (c            ),
    .res_out   (Sec_rom_wire )//两周期
);

always @(posedge clk) begin
    if (rst) begin
        Sec_rom_reg <= 0;
        Fir_add_reg <= 0;
        Fir_a_reg <= 0;
        Fir_b_reg <= 0;
    end else begin
        Sec_rom_reg <= Sec_rom_wire;
        Fir_add_reg <= Fir_add_wire;
        Fir_a_reg <= a;
        Fir_b_reg <= b;
    end
end

reg  Fir_sign_reg;
always @(posedge clk) begin
    if (rst) begin
        Fir_sign_reg <= 0;
    end else begin
        Fir_sign_reg <= Sec_rom_wire[11];
    end
end

reg Fir_end_reg;
always @(posedge clk) begin
    if (rst) begin
        Fir_end_reg <= 0;
    end else begin
        Fir_end_reg <= init_end;
    end
end

//1/(a+d)    
//=========================== cycle 2 ============================
wire [11:0] Sec_div_wire;
reg  [11:0] Sec_div_reg;//a*b/(a+d)

wire [3:0]  Sec_sft_wire;
reg  [3:0]  Sec_sft_reg;

reg  [11:0] Sec_a_reg;//a

reg [10:0] div_in;
reg [1:0] sftsel;
always @(*)begin
    if (Fir_add_reg[12]) begin
        div_in = Fir_add_reg[12:2];
        sftsel = 2'b10;
    end
    else if (Fir_add_reg[11]) begin
        div_in = Fir_add_reg[11:1];
        sftsel = 2'b01;
    end
    else begin
        div_in = Fir_add_reg[10:0];
        sftsel = 2'b00;
    end
end

DivRom DivRom(
    .sel (sftsel        ),
    .in  (div_in        ),
    .sft (Sec_sft_wire  ),//Q1.12
    .div (Sec_div_wire  )
);


always @(posedge clk) begin
    if (rst) begin
        Sec_div_reg <= 0;
        Sec_a_reg <= 0;
        Sec_sft_reg <= 0;
    end else begin
        Sec_div_reg <= Sec_div_wire;
        Sec_sft_reg <= Sec_sft_wire;
        Sec_a_reg <= Fir_a_reg;
    end
end

reg [11:0] Sec_b_reg;
always @(posedge clk) begin
    if (rst) begin
        Sec_b_reg <= 0;
    end else begin
        Sec_b_reg <= Fir_b_reg;
    end
end

reg Sec_sign_reg;
always @(posedge clk) begin
    if (rst) begin
        Sec_sign_reg <= 0;
    end else begin
        Sec_sign_reg <= Fir_sign_reg;
    end
end

reg Sec_end_reg;
always @(posedge clk) begin
    if (rst) begin
        Sec_end_reg <= 0;
    end else begin
        Sec_end_reg <= Fir_end_reg;
    end
end

//a * 1/(a+d)  //b*cos c>>12
//=========================== cycle 3 4 ============================//两周期
wire [23:0]  Thi_muldiv_wire;
reg  [11:0]  Thi_muldiv_reg;

reg  [3:0]   Thi_sft_reg;
reg  [3:0]   Fou_sft_reg;


wire [23:0] Thi_bcos_wire;//(b*cos c)>>12
reg [11:0] Thi_bcos_reg;//(b*cos c)>>12

Wallace12x12 Wallace12x12_2 (
    .clk        (clk             ),
    .rst        (rst             ),
    .x_in       (Sec_a_reg       ),
    .y_in       (Sec_div_reg     ),
    .result_out (Thi_muldiv_wire )
);

Wallace12x12 Wallace12x12_1 (
    .clk        (clk                      ),
    .rst        (rst                      ),
    .x_in       (Sec_b_reg                ),
    .y_in       ({Sec_rom_reg[10:0],1'b0} ),//Q.12
    .result_out (Thi_bcos_wire            )
);

always @(posedge clk) begin
    if (rst) begin
        Thi_sft_reg <= 0;
        Thi_bcos_reg <= 0;
    end else begin
        Thi_sft_reg <= Sec_sft_reg;
        Thi_bcos_reg <= Thi_bcos_wire[23:12];
    end
end


wire [23:0] shift_wire;
assign shift_wire = Thi_muldiv_wire>>Thi_sft_reg;

reg [11:0] Fif_bcos_reg;

always @(posedge clk) begin
    if (rst) begin
        Thi_muldiv_reg <= 0;
    end else begin
        Thi_muldiv_reg <= shift_wire[11:0];
    end
end

reg Thi_sign_reg;
reg Fou_sign_reg;
always @(posedge clk) begin
    if (rst) begin
        Thi_sign_reg <= 0;
        Fou_sign_reg <= 0;
    end else begin
        Thi_sign_reg <= Sec_sign_reg;
        Fou_sign_reg <= Thi_sign_reg;
    end
end

reg Thi_end_reg;
reg Fou_end_reg;
always @(posedge clk) begin
    if (rst) begin
        Thi_end_reg <= 0;
        Fou_end_reg <= 0;
    end else begin
        Thi_end_reg <= Sec_end_reg;
        Fou_end_reg <= Thi_end_reg;
    end
end

//a * 1/(a+d) >> sft
//=========================== cycle 5 ============================
wire [23:0] Fif_mul_wire;
reg [11:0]  Fif_mul_reg;

Wallace12x12 Wallace12x12_3 (
    .clk        (clk            ),
    .rst        (rst            ),
    .x_in       (Thi_muldiv_reg ),
    .y_in       (Thi_bcos_reg   ),
    .result_out (Fif_mul_wire   )
);

always @(posedge clk) begin
    if (rst) begin
        Fif_mul_reg <= 0;
    end else begin
        Fif_mul_reg <= Fif_mul_wire[23:12];
    end
end

reg Fif_sign_reg;
always @(posedge clk) begin
    if (rst) begin
        Fif_sign_reg <= 0;
    end else begin
        Fif_sign_reg <= Fou_sign_reg;
    end
end

reg Fif_end_reg;
reg Six_end_reg;
always @(posedge clk) begin
    if (rst) begin
        Fif_end_reg <= 0;
        Six_end_reg <= 0;
    end else begin
        Fif_end_reg <= Fou_end_reg;
        Six_end_reg <= Fif_end_reg;
    end
end

assign y = {Fif_sign_reg,Fif_mul_reg};

`ifdef SIMULATION
always @(posedge clk)begin
    if( Six_end_reg == 1'b1)begin
        check_finsih({19'b0,y});
    end
end
`endif

endmodule
