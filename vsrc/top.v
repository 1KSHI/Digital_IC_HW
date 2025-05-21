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

reg [11:0] Fir_a_reg;//a
reg [11:0] Fir_b_reg;//b
reg [11:0] Fir_c_reg;

Adder12 Adder12 (
    .x_in      (a           ),
    .y_in      (d_reg       ),
    .result_out(Fir_add_wire)
);


always @(posedge clk) begin
    if (rst) begin
        Fir_add_reg <= 0;
        Fir_a_reg <= 0;
        Fir_b_reg <= 0;
        Fir_c_reg <= 0;
    end else begin
        Fir_add_reg <= Fir_add_wire;
        Fir_a_reg <= a;
        Fir_b_reg <= b;
        Fir_c_reg <= c;
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

//=========================== cycle 2 3 4 ============================
wire Sec_sign_wire;
wire [11:0] Sec_div_wire;
wire [10:0] Sec_rom_wire;
wire [3:0] Sec_sft_wire;
reg [11:0] Sec_div_reg;
reg [10:0] Sec_rom_reg;
reg [3:0] Sec_sft_reg;

Rom Rom (
    .clk        (clk            ),
    .x_in       (Fir_c_reg      ),
    .sign_o     (Sec_sign_wire  ),
    .res_out    (Sec_rom_wire   )
);

DivRom DivRom (
    .clk          (clk            ),
    .add_in       (Fir_add_reg    ),
    .sft_reg      (Sec_sft_wire   ),
    .div          (Sec_div_wire   )
);

always @(posedge clk) begin
    if (rst) begin
        Sec_div_reg <= 0;
        Sec_rom_reg <= 0;
        Sec_sft_reg <= 0;
    end else begin
        Sec_div_reg <= Sec_div_wire;
        Sec_rom_reg <= Sec_rom_wire;
        Sec_sft_reg <= Sec_sft_wire;
    end
end

reg [11:0]Sec_a_reg;
reg [11:0]Sec_b_reg;
reg [11:0]Thi_a_reg;
reg [11:0]Thi_b_reg;
reg [11:0]Fou_a_reg;
reg [11:0]Fou_b_reg;
always @(posedge clk) begin
    if (rst) begin
        Sec_a_reg <= 0;
        Sec_b_reg <= 0;
        Thi_a_reg <= 0;
        Thi_b_reg <= 0;
        Fou_a_reg <= 0;
        Fou_b_reg <= 0;
    end else begin
        Sec_a_reg <= Fir_a_reg;
        Sec_b_reg <= Fir_b_reg;
        Thi_a_reg <= Sec_a_reg;
        Thi_b_reg <= Sec_b_reg;
        Fou_a_reg <= Thi_a_reg;
        Fou_b_reg <= Thi_b_reg;
    end
end

reg Sec_sign_reg;
always @(posedge clk) begin
    if (rst) begin
        Sec_sign_reg <= 0;
    end else begin
        Sec_sign_reg <= Sec_sign_wire;
    end
end

reg Sec_end_reg;
reg Thi_end_reg;
reg Fou_end_reg;
always @(posedge clk) begin
    if (rst) begin
        Sec_end_reg <= 0;
        Thi_end_reg <= 0;
        Fou_end_reg <= 0;
    end else begin
        Sec_end_reg <= Fir_end_reg;
        Thi_end_reg <= Sec_end_reg;
        Fou_end_reg <= Thi_end_reg;
    end
end



//a * 1/(a+d)  //b*cos c>>12
//=========================== cycle 5 6 ============================//两周期
wire [23:0]  Fif_muldiv_wire;
reg  [11:0]  Fif_muldiv_reg;

reg  [3:0]   Fif_sft_reg;
reg  [3:0]   Six_sft_reg;


wire [23:0] Fif_bcos_wire;//(b*cos c)>>12
reg [11:0] Fif_bcos_reg;//(b*cos c)>>12

Wallace12x12 Wallace12x12_2 (
    .clk        (clk             ),
    .rst        (rst             ),
    .x_in       (Fou_a_reg       ),
    .y_in       (Sec_div_reg     ),
    .result_out (Fif_muldiv_wire )
);

Wallace12x12 Wallace12x12_1 (
    .clk        (clk                      ),
    .rst        (rst                      ),
    .x_in       (Fou_b_reg                ),
    .y_in       ({Sec_rom_reg[10:0],1'b0} ),//Q.12
    .result_out (Fif_bcos_wire            )
);

always @(posedge clk) begin
    if (rst) begin
        Fif_sft_reg <= 0;
        Fif_bcos_reg <= 0;
    end else begin
        Fif_sft_reg <= Sec_sft_reg;
        Fif_bcos_reg <= Fif_bcos_wire[23:12];
    end
end


wire [23:0] Sec_sft_reg_wire;
assign Sec_sft_reg_wire = Fif_muldiv_wire>>Fif_sft_reg;

always @(posedge clk) begin
    if (rst) begin
        Fif_muldiv_reg <= 0;
    end else begin
        Fif_muldiv_reg <= Sec_sft_reg_wire[11:0];
    end
end

reg Fif_sign_reg;
reg Six_sign_reg;
always @(posedge clk) begin
    if (rst) begin
        Fif_sign_reg <= 0;
        Six_sign_reg <= 0;
    end else begin
        Fif_sign_reg <= Sec_sign_reg;
        Six_sign_reg <= Fif_sign_reg;
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

//a * 1/(a+d) >> sft
//=========================== cycle 7 8 ============================
wire [23:0] Sev_mul_wire;
reg [11:0]  Sev_mul_reg;

Wallace12x12 Wallace12x12_3 (
    .clk        (clk            ),
    .rst        (rst            ),
    .x_in       (Fif_muldiv_reg ),
    .y_in       (Fif_bcos_reg   ),
    .result_out (Sev_mul_wire   )
);

always @(posedge clk) begin
    if (rst) begin
        Sev_mul_reg <= 0;
    end else begin
        Sev_mul_reg <= Sev_mul_wire[23:12];
    end
end

reg Sev_sign_reg;
reg Eig_sign_reg;
always @(posedge clk) begin
    if (rst) begin
        Sev_sign_reg <= 0;
        Eig_sign_reg <= 0;
    end else begin
        Sev_sign_reg <= Six_sign_reg;
        Eig_sign_reg <= Sev_sign_reg;
    end
end

reg Sev_end_reg;
reg Eig_end_reg;
always @(posedge clk) begin
    if (rst) begin
        Sev_end_reg <= 0;
        Eig_end_reg <= 0;
    end else begin
        Sev_end_reg <= Six_end_reg;
        Eig_end_reg <= Sev_end_reg;
    end
end

assign y = {Eig_sign_reg,Sev_mul_reg};

`ifdef SIMULATION
always @(posedge clk)begin
    if( Eig_end_reg == 1'b1)begin
        check_finsih({19'b0,y});
    end
end
`endif

endmodule


module Adder12(
    input [11:0] x_in,
    input [11:0] y_in,
    output [12:0] result_out
);

assign result_out = x_in+y_in;

endmodule

module 	FullAdder(a, b, cin, sum, cout);

input 	a, b, cin;
output 	sum, cout;

assign	sum = a ^ b ^ cin;
assign 	cout = (a & b) | (a & cin) | (b & cin);

endmodule

module HalfAdder(a, b, sum, cout);

input a, b;
output sum, cout;

assign	sum = a ^ b;
assign	cout = a & b;

endmodule

module	Wallace12x12 ( 
    input   clk,
    input   rst,
	input	[11:0]	x_in, y_in,
	output	[23:0]	result_out
);
wire [23:0] opa, opb;	// 32-bit operands
wire pp [11:0][11:0];	// 16x16 partial products
genvar i, j;


generate
    for (i = 0; i < 12; i = i + 1) begin: pp_gen
        for (j = 0; j < 12; j = j + 1) begin: pp_gen2
            assign pp[i][j] = x_in[i] & y_in[j];
        end
    end
endgenerate

//============== First Stage ==================================================

wire	[11: 0]	Fir1_S, Fir1_C;
wire	[11: 0]	Fir2_S, Fir2_C;
wire	[11: 0]	Fir3_S, Fir3_C;
wire	[11: 0]	Fir4_S, Fir4_C;

HalfAdder	fir1ha0 ( pp[0][1],  pp[1][0],             Fir1_S[0],  Fir1_C[0]  );
FullAdder	fir1fa1 ( pp[0][2],  pp[1][1],  pp[2][0],  Fir1_S[1],  Fir1_C[1]  );
FullAdder	fir1fa2 ( pp[0][3],  pp[1][2],  pp[2][1],  Fir1_S[2],  Fir1_C[2]  );
FullAdder	fir1fa3 ( pp[0][4],  pp[1][3],  pp[2][2],  Fir1_S[3],  Fir1_C[3]  );
FullAdder	fir1fa4 ( pp[0][5],  pp[1][4],  pp[2][3],  Fir1_S[4],  Fir1_C[4]  );
FullAdder	fir1fa5 ( pp[0][6],  pp[1][5],  pp[2][4],  Fir1_S[5],  Fir1_C[5]  );
FullAdder	fir1fa6 ( pp[0][7],  pp[1][6],  pp[2][5],  Fir1_S[6],  Fir1_C[6]  );
FullAdder	fir1fa7 ( pp[0][8],  pp[1][7],  pp[2][6],  Fir1_S[7],  Fir1_C[7]  );
FullAdder	fir1fa8 ( pp[0][9],  pp[1][8],  pp[2][7],  Fir1_S[8],  Fir1_C[8]  );
FullAdder	fir1fa9 ( pp[0][10], pp[1][9],  pp[2][8],  Fir1_S[9],  Fir1_C[9]  );
FullAdder	fir1fa10( pp[0][11], pp[1][10], pp[2][9],  Fir1_S[10], Fir1_C[10] );
HalfAdder	fir1ha11(            pp[1][11], pp[2][10], Fir1_S[11], Fir1_C[11] );

HalfAdder	fir2ha0 ( pp[3][1],  pp[4][0],             Fir2_S[0],  Fir2_C[0]  );
FullAdder	fir2fa1 ( pp[3][2],  pp[4][1],  pp[5][0],  Fir2_S[1],  Fir2_C[1]  );
FullAdder	fir2fa2 ( pp[3][3],  pp[4][2],  pp[5][1],  Fir2_S[2],  Fir2_C[2]  );
FullAdder	fir2fa3 ( pp[3][4],  pp[4][3],  pp[5][2],  Fir2_S[3],  Fir2_C[3]  );
FullAdder	fir2fa4 ( pp[3][5],  pp[4][4],  pp[5][3],  Fir2_S[4],  Fir2_C[4]  );
FullAdder	fir2fa5 ( pp[3][6],  pp[4][5],  pp[5][4],  Fir2_S[5],  Fir2_C[5]  );
FullAdder	fir2fa6 ( pp[3][7],  pp[4][6],  pp[5][5],  Fir2_S[6],  Fir2_C[6]  );
FullAdder	fir2fa7 ( pp[3][8],  pp[4][7],  pp[5][6],  Fir2_S[7],  Fir2_C[7]  );
FullAdder	fir2fa8 ( pp[3][9],  pp[4][8],  pp[5][7],  Fir2_S[8],  Fir2_C[8]  );
FullAdder	fir2fa9 ( pp[3][10], pp[4][9],  pp[5][8],  Fir2_S[9],  Fir2_C[9]  );
FullAdder	fir2fa10( pp[3][11], pp[4][10], pp[5][9],  Fir2_S[10], Fir2_C[10] );
HalfAdder	fir2ha11(            pp[4][11], pp[5][10], Fir2_S[11], Fir2_C[11] );

HalfAdder	fir3ha0 ( pp[6][1],  pp[7][0],             Fir3_S[0],  Fir3_C[0]  );
FullAdder	fir3fa1 ( pp[6][2],  pp[7][1],  pp[8][0],  Fir3_S[1],  Fir3_C[1]  );
FullAdder	fir3fa2 ( pp[6][3],  pp[7][2],  pp[8][1],  Fir3_S[2],  Fir3_C[2]  );
FullAdder	fir3fa3 ( pp[6][4],  pp[7][3],  pp[8][2],  Fir3_S[3],  Fir3_C[3]  );
FullAdder	fir3fa4 ( pp[6][5],  pp[7][4],  pp[8][3],  Fir3_S[4],  Fir3_C[4]  );
FullAdder	fir3fa5 ( pp[6][6],  pp[7][5],  pp[8][4],  Fir3_S[5],  Fir3_C[5]  );
FullAdder	fir3fa6 ( pp[6][7],  pp[7][6],  pp[8][5],  Fir3_S[6],  Fir3_C[6]  );
FullAdder	fir3fa7 ( pp[6][8],  pp[7][7],  pp[8][6],  Fir3_S[7],  Fir3_C[7]  );
FullAdder	fir3fa8 ( pp[6][9],  pp[7][8],  pp[8][7],  Fir3_S[8],  Fir3_C[8]  );
FullAdder	fir3fa9 ( pp[6][10], pp[7][9],  pp[8][8],  Fir3_S[9],  Fir3_C[9]  );
FullAdder	fir3fa10( pp[6][11], pp[7][10], pp[8][9],  Fir3_S[10], Fir3_C[10] );
HalfAdder	fir3ha11(            pp[7][11], pp[8][10], Fir3_S[11], Fir3_C[11] );

HalfAdder	fir4ha0 ( pp[9][1],   pp[10][0],              Fir4_S[0],  Fir4_C[0]  );
FullAdder	fir4fa1 ( pp[9][2],   pp[10][1],  pp[11][0],  Fir4_S[1],  Fir4_C[1]  );
FullAdder	fir4fa2 ( pp[9][3],   pp[10][2],  pp[11][1],  Fir4_S[2],  Fir4_C[2]  );
FullAdder	fir4fa3 ( pp[9][4],   pp[10][3],  pp[11][2],  Fir4_S[3],  Fir4_C[3]  );
FullAdder	fir4fa4 ( pp[9][5],   pp[10][4],  pp[11][3],  Fir4_S[4],  Fir4_C[4]  );
FullAdder	fir4fa5 ( pp[9][6],   pp[10][5],  pp[11][4],  Fir4_S[5],  Fir4_C[5]  );
FullAdder	fir4fa6 ( pp[9][7],   pp[10][6],  pp[11][5],  Fir4_S[6],  Fir4_C[6]  );
FullAdder	fir4fa7 ( pp[9][8],   pp[10][7],  pp[11][6],  Fir4_S[7],  Fir4_C[7]  );
FullAdder	fir4fa8 ( pp[9][9],   pp[10][8],  pp[11][7],  Fir4_S[8],  Fir4_C[8]  );
FullAdder	fir4fa9 ( pp[9][10],  pp[10][9],  pp[11][8],  Fir4_S[9],  Fir4_C[9]  );
FullAdder	fir4fa10( pp[9][11],  pp[10][10], pp[11][9],  Fir4_S[10], Fir4_C[10] );
HalfAdder	fir4ha11(             pp[10][11], pp[11][10], Fir4_S[11], Fir4_C[11] );


//============== Second Stage =================================================

wire	[11: 0]	Sec1_S, Sec1_C;
wire	[13: 0]	Sec2_S, Sec2_C;

HalfAdder	sec1ha0 ( Fir1_S[1],  Fir1_C[0],             Sec1_S[0],  Sec1_C[0]  );
FullAdder	sec1fa1 ( Fir1_S[2],  Fir1_C[1],  pp[3][0],  Sec1_S[1],  Sec1_C[1]  );
FullAdder	sec1fa2 ( Fir1_S[3],  Fir1_C[2],  Fir2_S[0], Sec1_S[2],  Sec1_C[2]  );
FullAdder	sec1fa3 ( Fir1_S[4],  Fir1_C[3],  Fir2_S[1], Sec1_S[3],  Sec1_C[3]  );
FullAdder	sec1fa4 ( Fir1_S[5],  Fir1_C[4],  Fir2_S[2], Sec1_S[4],  Sec1_C[4]  );
FullAdder	sec1fa5 ( Fir1_S[6],  Fir1_C[5],  Fir2_S[3], Sec1_S[5],  Sec1_C[5]  );
FullAdder	sec1fa6 ( Fir1_S[7],  Fir1_C[6],  Fir2_S[4], Sec1_S[6],  Sec1_C[6]  );
FullAdder	sec1fa7 ( Fir1_S[8],  Fir1_C[7],  Fir2_S[5], Sec1_S[7],  Sec1_C[7]  );
FullAdder	sec1fa8 ( Fir1_S[9],  Fir1_C[8],  Fir2_S[6], Sec1_S[8],  Sec1_C[8]  );
FullAdder	sec1fa9 ( Fir1_S[10], Fir1_C[9],  Fir2_S[7], Sec1_S[9],  Sec1_C[9]  );
FullAdder	sec1fa10( Fir1_S[11], Fir1_C[10], Fir2_S[8], Sec1_S[10], Sec1_C[10] );
FullAdder	sec1fa11( pp[2][11],  Fir1_C[11], Fir2_S[9], Sec1_S[11], Sec1_C[11] );

HalfAdder	sec2ha0 ( Fir2_C[1],  pp[6][0],               Sec2_S[0],  Sec2_C[0]  );
HalfAdder	sec2ha1 ( Fir2_C[2],  Fir3_S[0],              Sec2_S[1],  Sec2_C[1]  );
FullAdder	sec2fa2 ( Fir2_C[3],  Fir3_S[1],  Fir3_C[0],  Sec2_S[2],  Sec2_C[2]  );
FullAdder	sec2fa3 ( Fir2_C[4],  Fir3_S[2],  Fir3_C[1],  Sec2_S[3],  Sec2_C[3]  );
FullAdder	sec2fa4 ( Fir2_C[5],  Fir3_S[3],  Fir3_C[2],  Sec2_S[4],  Sec2_C[4]  );
FullAdder	sec2fa5 ( Fir2_C[6],  Fir3_S[4],  Fir3_C[3],  Sec2_S[5],  Sec2_C[5]  );
FullAdder	sec2fa6 ( Fir2_C[7],  Fir3_S[5],  Fir3_C[4],  Sec2_S[6],  Sec2_C[6]  );
FullAdder	sec2fa7 ( Fir2_C[8],  Fir3_S[6],  Fir3_C[5],  Sec2_S[7],  Sec2_C[7]  );
FullAdder	sec2fa8 ( Fir2_C[9],  Fir3_S[7],  Fir3_C[6],  Sec2_S[8],  Sec2_C[8]  );
FullAdder	sec2fa9 ( Fir2_C[10], Fir3_S[8],  Fir3_C[7],  Sec2_S[9],  Sec2_C[9]  );
FullAdder	sec2fa10( Fir2_C[11], Fir3_S[9],  Fir3_C[8],  Sec2_S[10], Sec2_C[10] );
HalfAdder	sec2ha11(             Fir3_S[10], Fir3_C[9],  Sec2_S[11], Sec2_C[11] );
HalfAdder	sec2ha12(             Fir3_S[11], Fir3_C[10], Sec2_S[12], Sec2_C[12] );
HalfAdder	sec2ha13(             pp[8][11],  Fir3_C[11], Sec2_S[13], Sec2_C[13] );

//============== Third Stage =================================================

wire	[13: 0]	Thi1_S, Thi1_C;
wire	[13: 0]	Thi2_S, Thi2_C;

HalfAdder	thi1ha0 ( Sec1_S[1],  Sec1_C[0],              Thi1_S[0],  Thi1_C[0]  );
HalfAdder	thi1ha1 ( Sec1_S[2],  Sec1_C[1],              Thi1_S[1],  Thi1_C[1]  );
FullAdder	thi1fa2 ( Sec1_S[3],  Sec1_C[2],  Fir2_C[0],  Thi1_S[2],  Thi1_C[2]  );
FullAdder	thi1fa3 ( Sec1_S[4],  Sec1_C[3],  Sec2_S[0],  Thi1_S[3],  Thi1_C[3]  );
FullAdder	thi1fa4 ( Sec1_S[5],  Sec1_C[4],  Sec2_S[1],  Thi1_S[4],  Thi1_C[4]  );
FullAdder	thi1fa5 ( Sec1_S[6],  Sec1_C[5],  Sec2_S[2],  Thi1_S[5],  Thi1_C[5]  );
FullAdder	thi1fa6 ( Sec1_S[7],  Sec1_C[6],  Sec2_S[3],  Thi1_S[6],  Thi1_C[6]  );
FullAdder	thi1fa7 ( Sec1_S[8],  Sec1_C[7],  Sec2_S[4],  Thi1_S[7],  Thi1_C[7]  );
FullAdder	thi1fa8 ( Sec1_S[9],  Sec1_C[8],  Sec2_S[5],  Thi1_S[8],  Thi1_C[8]  );
FullAdder	thi1fa9 ( Sec1_S[10], Sec1_C[9],  Sec2_S[6],  Thi1_S[9],  Thi1_C[9]  );
FullAdder	thi1fa10( Sec1_S[11], Sec1_C[10], Sec2_S[7],  Thi1_S[10], Thi1_C[10] );
FullAdder	thi1fa11( Fir2_S[10], Sec1_C[11], Sec2_S[8],  Thi1_S[11], Thi1_C[11] );
HalfAdder	thi1ha12(             Fir2_S[11], Sec2_S[9],  Thi1_S[12], Thi1_C[12] );
HalfAdder	thi1ha13(             pp[5][11],  Sec2_S[10], Thi1_S[13], Thi1_C[13] );

HalfAdder	thi2ha0 ( Sec2_C[2],  pp[9][0],               Thi2_S[0],  Thi2_C[0]  );
HalfAdder	thi2ha1 ( Sec2_C[3],  Fir4_S[0],              Thi2_S[1],  Thi2_C[1]  );
FullAdder	thi2fa3 ( Sec2_C[4],  Fir4_S[1],  Fir4_C[0],  Thi2_S[2],  Thi2_C[2]  );
FullAdder	thi2fa4 ( Sec2_C[5],  Fir4_S[2],  Fir4_C[1],  Thi2_S[3],  Thi2_C[3]  );
FullAdder	thi2fa5 ( Sec2_C[6],  Fir4_S[3],  Fir4_C[2],  Thi2_S[4],  Thi2_C[4]  );
FullAdder	thi2fa6 ( Sec2_C[7],  Fir4_S[4],  Fir4_C[3],  Thi2_S[5],  Thi2_C[5]  );
FullAdder	thi2fa7 ( Sec2_C[8],  Fir4_S[5],  Fir4_C[4],  Thi2_S[6],  Thi2_C[6]  );
FullAdder	thi2fa8 ( Sec2_C[9],  Fir4_S[6],  Fir4_C[5],  Thi2_S[7],  Thi2_C[7]  );
FullAdder	thi2fa9 ( Sec2_C[10], Fir4_S[7],  Fir4_C[6],  Thi2_S[8],  Thi2_C[8]  );
FullAdder	thi2fa10( Sec2_C[11], Fir4_S[8],  Fir4_C[7],  Thi2_S[9],  Thi2_C[9] );
FullAdder	thi2fa11( Sec2_C[12], Fir4_S[9],  Fir4_C[8],  Thi2_S[10], Thi2_C[10] );
FullAdder	thi2fa12( Sec2_C[13], Fir4_S[10], Fir4_C[9],  Thi2_S[11], Thi2_C[11] );
HalfAdder	thi2ha13(             Fir4_S[11], Fir4_C[10], Thi2_S[12], Thi2_C[12] );
HalfAdder	thi2ha14(             pp[11][11], Fir4_C[11], Thi2_S[13], Thi2_C[13] );

//============== Fourth Stage =================================================

wire	[15: 0]	Fou1_S, Fou1_C;
 
HalfAdder	fou1ha0 ( Thi1_S[1],  Thi1_C[0],              Fou1_S[0],  Fou1_C[0]  );
HalfAdder	fou1ha1 ( Thi1_S[2],  Thi1_C[1],              Fou1_S[1],  Fou1_C[1]  );
HalfAdder	fou1ha2 ( Thi1_S[3],  Thi1_C[2],              Fou1_S[2],  Fou1_C[2]  );
FullAdder	fou1fa3 ( Thi1_S[4],  Thi1_C[3],  Sec2_C[0],  Fou1_S[3],  Fou1_C[3]  );
FullAdder	fou1fa4 ( Thi1_S[5],  Thi1_C[4],  Sec2_C[1],  Fou1_S[4],  Fou1_C[4]  );
FullAdder	fou1fa5 ( Thi1_S[6],  Thi1_C[5],  Thi2_S[0],  Fou1_S[5],  Fou1_C[5]  );
FullAdder	fou1fa6 ( Thi1_S[7],  Thi1_C[6],  Thi2_S[1],  Fou1_S[6],  Fou1_C[6]  );
FullAdder	fou1fa7 ( Thi1_S[8],  Thi1_C[7],  Thi2_S[2],  Fou1_S[7],  Fou1_C[7]  );
FullAdder	fou1fa8 ( Thi1_S[9],  Thi1_C[8],  Thi2_S[3],  Fou1_S[8],  Fou1_C[8]  );
FullAdder	fou1fa9 ( Thi1_S[10], Thi1_C[9],  Thi2_S[4],  Fou1_S[9],  Fou1_C[9]  );
FullAdder	fou1fa10( Thi1_S[11], Thi1_C[10], Thi2_S[5],  Fou1_S[10], Fou1_C[10] );
FullAdder	fou1fa11( Thi1_S[12], Thi1_C[11], Thi2_S[6],  Fou1_S[11], Fou1_C[11] );
FullAdder	fou1fa12( Thi1_S[13], Thi1_C[12], Thi2_S[7],  Fou1_S[12], Fou1_C[12] );
FullAdder	fou1fa13( Sec2_S[11], Thi1_C[13], Thi2_S[8],  Fou1_S[13], Fou1_C[13] );
HalfAdder	fou1ha14(             Sec2_S[12], Thi2_S[9],  Fou1_S[14], Fou1_C[14] );
HalfAdder	fou1ha15(             Sec2_S[13], Thi2_S[10], Fou1_S[15], Fou1_C[15] );

//============== Fifth Stage =================================================

wire	[17: 0]	Fif_S, Fif_C;

HalfAdder	fifha0 ( Fou1_S[1],  Fou1_C[0],              Fif_S[0],  Fif_C[0]  );
HalfAdder	fifha1 ( Fou1_S[2],  Fou1_C[1],              Fif_S[1],  Fif_C[1]  );
HalfAdder	fifha2 ( Fou1_S[3],  Fou1_C[2],              Fif_S[2],  Fif_C[2]  );
HalfAdder	fifha3 ( Fou1_S[4],  Fou1_C[3],              Fif_S[3],  Fif_C[3]  );
HalfAdder	fifha4 ( Fou1_S[5],  Fou1_C[4],              Fif_S[4],  Fif_C[4]  );
FullAdder	fiffa5 ( Fou1_S[6],  Fou1_C[5],  Thi2_C[0],  Fif_S[5],  Fif_C[5]  );
FullAdder	fiffa6 ( Fou1_S[7],  Fou1_C[6],  Thi2_C[1],  Fif_S[6],  Fif_C[6]  );
FullAdder	fiffa7 ( Fou1_S[8],  Fou1_C[7],  Thi2_C[2],  Fif_S[7],  Fif_C[7]  );
FullAdder	fiffa8 ( Fou1_S[9],  Fou1_C[8],  Thi2_C[3],  Fif_S[8],  Fif_C[8]  );
FullAdder	fiffa9 ( Fou1_S[10], Fou1_C[9],  Thi2_C[4],  Fif_S[9],  Fif_C[9]  );
FullAdder	fiffa10( Fou1_S[11], Fou1_C[10], Thi2_C[5],  Fif_S[10], Fif_C[10] );
FullAdder	fiffa11( Fou1_S[12], Fou1_C[11], Thi2_C[6],  Fif_S[11], Fif_C[11] );
FullAdder	fiffa12( Fou1_S[13], Fou1_C[12], Thi2_C[7],  Fif_S[12], Fif_C[12] );
FullAdder	fiffa13( Fou1_S[14], Fou1_C[13], Thi2_C[8],  Fif_S[13], Fif_C[13] );
FullAdder	fiffa14( Fou1_S[15], Fou1_C[14], Thi2_C[9],  Fif_S[14], Fif_C[14] );
FullAdder	fiffa15( Thi2_S[11], Fou1_C[15], Thi2_C[10], Fif_S[15], Fif_C[15] );
HalfAdder	fifha16(             Thi2_S[12], Thi2_C[11], Fif_S[16], Fif_C[16] );
HalfAdder	fifha17(             Thi2_S[13], Thi2_C[12], Fif_S[17], Fif_C[17] );

//============== Result Assignment ============================================


assign	opa = { Thi2_C[13], Fif_S[17: 0], Fou1_S[0], Thi1_S[0],Sec1_S[0], Fir1_S[0], pp[0][0] };
assign	opb = { Fif_C[17: 0], 6'b0 };

reg [23:0]opa_reg, opb_reg;
always @(posedge clk) begin
    if (rst) begin
        opa_reg <= 0;
        opb_reg <= 0;
    end else begin
        opa_reg <= opa;
        opb_reg <= opb;
    end
end

wire [23:0] result_temp = opa_reg + opb_reg;

assign result_out = result_temp[23:0];


endmodule

module Rom(
    input clk,
    input [11:0] x_in,
    output reg sign_o,
    output wire [10:0] res_out
);

//========================= cycle 1 ==========================

wire [1:0] quadrant = x_in[11:10];
wire [9:0] addr_temp;
assign addr_temp = ~x_in[9:0]+1;

reg zero;
reg sign;
reg [9:0] addr;
always @(posedge clk) begin
    case (quadrant)
        2'b00: begin
            addr <= x_in[9:0];
            sign <= 0;
            zero <= 0;
        end
        2'b01: begin
            addr <= addr_temp;
            sign <= 1;
            zero <= (addr_temp==0);
        end
        2'b10: begin
            addr <= x_in[9:0];
            sign <= 1;
            zero <= 0;
        end
        2'b11: begin
            addr <= addr_temp;
            sign <= 0;
            zero <= (addr_temp==0);
        end
    endcase
end



//========================= cycle 2 ==========================

reg zero_2;
reg cosadd_sel;
always @(posedge clk) begin
    sign_o <= sign;
    zero_2 <= zero;
    cosadd_sel <= addr[0];
end

//========================= cycle 3 ==========================

reg [2:0] bias;
reg[10:0] result_out;

assign res_out = zero_2?11'b0:cosadd_sel?(result_out-{8'b0,bias}):result_out;


always @(posedge clk) begin
    case(addr[9:1])
    0    : begin result_out <= 11'd2047; bias <= 3'd0  ;end
    1    : begin result_out <= 11'd2047; bias <= 3'd0  ;end
    2    : begin result_out <= 11'd2047; bias <= 3'd0  ;end
    3    : begin result_out <= 11'd2047; bias <= 3'd0  ;end
    4    : begin result_out <= 11'd2047; bias <= 3'd0  ;end
    5    : begin result_out <= 11'd2047; bias <= 3'd0  ;end
    6    : begin result_out <= 11'd2047; bias <= 3'd0  ;end
    7    : begin result_out <= 11'd2047; bias <= 3'd0  ;end
    8    : begin result_out <= 11'd2047; bias <= 3'd0  ;end
    9    : begin result_out <= 11'd2047; bias <= 3'd0  ;end
    10   : begin result_out <= 11'd2047; bias <= 3'd0  ;end
    11   : begin result_out <= 11'd2047; bias <= 3'd0  ;end
    12   : begin result_out <= 11'd2047; bias <= 3'd1  ;end
    13   : begin result_out <= 11'd2046; bias <= 3'd0  ;end
    14   : begin result_out <= 11'd2046; bias <= 3'd0  ;end
    15   : begin result_out <= 11'd2046; bias <= 3'd0  ;end
    16   : begin result_out <= 11'd2046; bias <= 3'd1  ;end
    17   : begin result_out <= 11'd2045; bias <= 3'd0  ;end
    18   : begin result_out <= 11'd2045; bias <= 3'd0  ;end
    19   : begin result_out <= 11'd2045; bias <= 3'd1  ;end
    20   : begin result_out <= 11'd2044; bias <= 3'd0  ;end
    21   : begin result_out <= 11'd2044; bias <= 3'd0  ;end
    22   : begin result_out <= 11'd2043; bias <= 3'd0  ;end
    23   : begin result_out <= 11'd2043; bias <= 3'd0  ;end
    24   : begin result_out <= 11'd2042; bias <= 3'd0  ;end
    25   : begin result_out <= 11'd2042; bias <= 3'd0  ;end
    26   : begin result_out <= 11'd2041; bias <= 3'd0  ;end
    27   : begin result_out <= 11'd2041; bias <= 3'd0  ;end
    28   : begin result_out <= 11'd2040; bias <= 3'd0  ;end
    29   : begin result_out <= 11'd2040; bias <= 3'd0  ;end
    30   : begin result_out <= 11'd2039; bias <= 3'd0  ;end
    31   : begin result_out <= 11'd2039; bias <= 3'd1  ;end
    32   : begin result_out <= 11'd2038; bias <= 3'd0  ;end
    33   : begin result_out <= 11'd2038; bias <= 3'd1  ;end
    34   : begin result_out <= 11'd2037; bias <= 3'd0  ;end
    35   : begin result_out <= 11'd2036; bias <= 3'd0  ;end
    36   : begin result_out <= 11'd2036; bias <= 3'd1  ;end
    37   : begin result_out <= 11'd2035; bias <= 3'd1  ;end
    38   : begin result_out <= 11'd2034; bias <= 3'd0  ;end
    39   : begin result_out <= 11'd2033; bias <= 3'd0  ;end
    40   : begin result_out <= 11'd2033; bias <= 3'd1  ;end
    41   : begin result_out <= 11'd2032; bias <= 3'd1  ;end
    42   : begin result_out <= 11'd2031; bias <= 3'd0  ;end
    43   : begin result_out <= 11'd2030; bias <= 3'd0  ;end
    44   : begin result_out <= 11'd2029; bias <= 3'd0  ;end
    45   : begin result_out <= 11'd2029; bias <= 3'd1  ;end
    46   : begin result_out <= 11'd2028; bias <= 3'd1  ;end
    47   : begin result_out <= 11'd2027; bias <= 3'd1  ;end
    48   : begin result_out <= 11'd2026; bias <= 3'd1  ;end
    49   : begin result_out <= 11'd2025; bias <= 3'd1  ;end
    50   : begin result_out <= 11'd2024; bias <= 3'd1  ;end
    51   : begin result_out <= 11'd2023; bias <= 3'd1  ;end
    52   : begin result_out <= 11'd2022; bias <= 3'd1  ;end
    53   : begin result_out <= 11'd2021; bias <= 3'd1  ;end
    54   : begin result_out <= 11'd2020; bias <= 3'd1  ;end
    55   : begin result_out <= 11'd2019; bias <= 3'd1  ;end
    56   : begin result_out <= 11'd2018; bias <= 3'd1  ;end
    57   : begin result_out <= 11'd2017; bias <= 3'd1  ;end
    58   : begin result_out <= 11'd2016; bias <= 3'd1  ;end
    59   : begin result_out <= 11'd2015; bias <= 3'd1  ;end
    60   : begin result_out <= 11'd2013; bias <= 3'd0  ;end
    61   : begin result_out <= 11'd2012; bias <= 3'd0  ;end
    62   : begin result_out <= 11'd2011; bias <= 3'd1  ;end
    63   : begin result_out <= 11'd2010; bias <= 3'd1  ;end
    64   : begin result_out <= 11'd2009; bias <= 3'd1  ;end
    65   : begin result_out <= 11'd2007; bias <= 3'd0  ;end
    66   : begin result_out <= 11'd2006; bias <= 3'd0  ;end
    67   : begin result_out <= 11'd2005; bias <= 3'd1  ;end
    68   : begin result_out <= 11'd2004; bias <= 3'd1  ;end
    69   : begin result_out <= 11'd2002; bias <= 3'd0  ;end
    70   : begin result_out <= 11'd2001; bias <= 3'd1  ;end
    71   : begin result_out <= 11'd2000; bias <= 3'd1  ;end
    72   : begin result_out <= 11'd1998; bias <= 3'd0  ;end
    73   : begin result_out <= 11'd1997; bias <= 3'd1  ;end
    74   : begin result_out <= 11'd1995; bias <= 3'd0  ;end
    75   : begin result_out <= 11'd1994; bias <= 3'd1  ;end
    76   : begin result_out <= 11'd1993; bias <= 3'd1  ;end
    77   : begin result_out <= 11'd1991; bias <= 3'd1  ;end
    78   : begin result_out <= 11'd1990; bias <= 3'd1  ;end
    79   : begin result_out <= 11'd1988; bias <= 3'd1  ;end
    80   : begin result_out <= 11'd1987; bias <= 3'd1  ;end
    81   : begin result_out <= 11'd1985; bias <= 3'd1  ;end
    82   : begin result_out <= 11'd1984; bias <= 3'd1  ;end
    83   : begin result_out <= 11'd1982; bias <= 3'd1  ;end
    84   : begin result_out <= 11'd1980; bias <= 3'd0  ;end
    85   : begin result_out <= 11'd1979; bias <= 3'd1  ;end
    86   : begin result_out <= 11'd1977; bias <= 3'd1  ;end
    87   : begin result_out <= 11'd1975; bias <= 3'd0  ;end
    88   : begin result_out <= 11'd1974; bias <= 3'd1  ;end
    89   : begin result_out <= 11'd1972; bias <= 3'd1  ;end
    90   : begin result_out <= 11'd1970; bias <= 3'd0  ;end
    91   : begin result_out <= 11'd1969; bias <= 3'd1  ;end
    92   : begin result_out <= 11'd1967; bias <= 3'd1  ;end
    93   : begin result_out <= 11'd1965; bias <= 3'd1  ;end
    94   : begin result_out <= 11'd1963; bias <= 3'd0  ;end
    95   : begin result_out <= 11'd1962; bias <= 3'd1  ;end
    96   : begin result_out <= 11'd1960; bias <= 3'd1  ;end
    97   : begin result_out <= 11'd1958; bias <= 3'd1  ;end
    98   : begin result_out <= 11'd1956; bias <= 3'd1  ;end
    99   : begin result_out <= 11'd1954; bias <= 3'd1  ;end
    100  : begin result_out <= 11'd1952; bias <= 3'd1  ;end
    101  : begin result_out <= 11'd1950; bias <= 3'd0  ;end
    102  : begin result_out <= 11'd1949; bias <= 3'd1  ;end
    103  : begin result_out <= 11'd1947; bias <= 3'd1  ;end
    104  : begin result_out <= 11'd1945; bias <= 3'd1  ;end
    105  : begin result_out <= 11'd1943; bias <= 3'd1  ;end
    106  : begin result_out <= 11'd1941; bias <= 3'd1  ;end
    107  : begin result_out <= 11'd1939; bias <= 3'd1  ;end
    108  : begin result_out <= 11'd1937; bias <= 3'd1  ;end
    109  : begin result_out <= 11'd1935; bias <= 3'd1  ;end
    110  : begin result_out <= 11'd1932; bias <= 3'd1  ;end
    111  : begin result_out <= 11'd1930; bias <= 3'd1  ;end
    112  : begin result_out <= 11'd1928; bias <= 3'd1  ;end
    113  : begin result_out <= 11'd1926; bias <= 3'd1  ;end
    114  : begin result_out <= 11'd1924; bias <= 3'd1  ;end
    115  : begin result_out <= 11'd1922; bias <= 3'd1  ;end
    116  : begin result_out <= 11'd1920; bias <= 3'd1  ;end
    117  : begin result_out <= 11'd1917; bias <= 3'd1  ;end
    118  : begin result_out <= 11'd1915; bias <= 3'd1  ;end
    119  : begin result_out <= 11'd1913; bias <= 3'd1  ;end
    120  : begin result_out <= 11'd1911; bias <= 3'd1  ;end
    121  : begin result_out <= 11'd1908; bias <= 3'd1  ;end
    122  : begin result_out <= 11'd1906; bias <= 3'd1  ;end
    123  : begin result_out <= 11'd1904; bias <= 3'd1  ;end
    124  : begin result_out <= 11'd1902; bias <= 3'd2  ;end
    125  : begin result_out <= 11'd1899; bias <= 3'd1  ;end
    126  : begin result_out <= 11'd1897; bias <= 3'd1  ;end
    127  : begin result_out <= 11'd1895; bias <= 3'd2  ;end
    128  : begin result_out <= 11'd1892; bias <= 3'd1  ;end
    129  : begin result_out <= 11'd1890; bias <= 3'd2  ;end
    130  : begin result_out <= 11'd1887; bias <= 3'd1  ;end
    131  : begin result_out <= 11'd1885; bias <= 3'd1  ;end
    132  : begin result_out <= 11'd1882; bias <= 3'd1  ;end
    133  : begin result_out <= 11'd1880; bias <= 3'd1  ;end
    134  : begin result_out <= 11'd1877; bias <= 3'd1  ;end
    135  : begin result_out <= 11'd1875; bias <= 3'd1  ;end
    136  : begin result_out <= 11'd1872; bias <= 3'd1  ;end
    137  : begin result_out <= 11'd1870; bias <= 3'd2  ;end
    138  : begin result_out <= 11'd1867; bias <= 3'd1  ;end
    139  : begin result_out <= 11'd1865; bias <= 3'd2  ;end
    140  : begin result_out <= 11'd1862; bias <= 3'd1  ;end
    141  : begin result_out <= 11'd1859; bias <= 3'd1  ;end
    142  : begin result_out <= 11'd1857; bias <= 3'd2  ;end
    143  : begin result_out <= 11'd1854; bias <= 3'd1  ;end
    144  : begin result_out <= 11'd1851; bias <= 3'd1  ;end
    145  : begin result_out <= 11'd1849; bias <= 3'd2  ;end
    146  : begin result_out <= 11'd1846; bias <= 3'd1  ;end
    147  : begin result_out <= 11'd1843; bias <= 3'd1  ;end
    148  : begin result_out <= 11'd1840; bias <= 3'd1  ;end
    149  : begin result_out <= 11'd1838; bias <= 3'd2  ;end
    150  : begin result_out <= 11'd1835; bias <= 3'd1  ;end
    151  : begin result_out <= 11'd1832; bias <= 3'd1  ;end
    152  : begin result_out <= 11'd1829; bias <= 3'd1  ;end
    153  : begin result_out <= 11'd1826; bias <= 3'd1  ;end
    154  : begin result_out <= 11'd1824; bias <= 3'd2  ;end
    155  : begin result_out <= 11'd1821; bias <= 3'd2  ;end
    156  : begin result_out <= 11'd1818; bias <= 3'd2  ;end
    157  : begin result_out <= 11'd1815; bias <= 3'd1  ;end
    158  : begin result_out <= 11'd1812; bias <= 3'd1  ;end
    159  : begin result_out <= 11'd1809; bias <= 3'd1  ;end
    160  : begin result_out <= 11'd1806; bias <= 3'd1  ;end
    161  : begin result_out <= 11'd1803; bias <= 3'd1  ;end
    162  : begin result_out <= 11'd1800; bias <= 3'd1  ;end
    163  : begin result_out <= 11'd1797; bias <= 3'd1  ;end
    164  : begin result_out <= 11'd1794; bias <= 3'd1  ;end
    165  : begin result_out <= 11'd1791; bias <= 3'd1  ;end
    166  : begin result_out <= 11'd1788; bias <= 3'd1  ;end
    167  : begin result_out <= 11'd1785; bias <= 3'd2  ;end
    168  : begin result_out <= 11'd1782; bias <= 3'd2  ;end
    169  : begin result_out <= 11'd1779; bias <= 3'd2  ;end
    170  : begin result_out <= 11'd1776; bias <= 3'd2  ;end
    171  : begin result_out <= 11'd1773; bias <= 3'd2  ;end
    172  : begin result_out <= 11'd1769; bias <= 3'd1  ;end
    173  : begin result_out <= 11'd1766; bias <= 3'd1  ;end
    174  : begin result_out <= 11'd1763; bias <= 3'd2  ;end
    175  : begin result_out <= 11'd1760; bias <= 3'd2  ;end
    176  : begin result_out <= 11'd1757; bias <= 3'd2  ;end
    177  : begin result_out <= 11'd1753; bias <= 3'd1  ;end
    178  : begin result_out <= 11'd1750; bias <= 3'd1  ;end
    179  : begin result_out <= 11'd1747; bias <= 3'd2  ;end
    180  : begin result_out <= 11'd1744; bias <= 3'd2  ;end
    181  : begin result_out <= 11'd1740; bias <= 3'd1  ;end
    182  : begin result_out <= 11'd1737; bias <= 3'd2  ;end
    183  : begin result_out <= 11'd1734; bias <= 3'd2  ;end
    184  : begin result_out <= 11'd1730; bias <= 3'd1  ;end
    185  : begin result_out <= 11'd1727; bias <= 3'd2  ;end
    186  : begin result_out <= 11'd1724; bias <= 3'd2  ;end
    187  : begin result_out <= 11'd1720; bias <= 3'd2  ;end
    188  : begin result_out <= 11'd1717; bias <= 3'd2  ;end
    189  : begin result_out <= 11'd1713; bias <= 3'd1  ;end
    190  : begin result_out <= 11'd1710; bias <= 3'd2  ;end
    191  : begin result_out <= 11'd1706; bias <= 3'd1  ;end
    192  : begin result_out <= 11'd1703; bias <= 3'd2  ;end
    193  : begin result_out <= 11'd1699; bias <= 3'd1  ;end
    194  : begin result_out <= 11'd1696; bias <= 3'd2  ;end
    195  : begin result_out <= 11'd1692; bias <= 3'd1  ;end
    196  : begin result_out <= 11'd1689; bias <= 3'd2  ;end
    197  : begin result_out <= 11'd1685; bias <= 3'd2  ;end
    198  : begin result_out <= 11'd1682; bias <= 3'd2  ;end
    199  : begin result_out <= 11'd1678; bias <= 3'd2  ;end
    200  : begin result_out <= 11'd1674; bias <= 3'd1  ;end
    201  : begin result_out <= 11'd1671; bias <= 3'd2  ;end
    202  : begin result_out <= 11'd1667; bias <= 3'd2  ;end
    203  : begin result_out <= 11'd1663; bias <= 3'd1  ;end
    204  : begin result_out <= 11'd1660; bias <= 3'd2  ;end
    205  : begin result_out <= 11'd1656; bias <= 3'd2  ;end
    206  : begin result_out <= 11'd1652; bias <= 3'd1  ;end
    207  : begin result_out <= 11'd1649; bias <= 3'd2  ;end
    208  : begin result_out <= 11'd1645; bias <= 3'd2  ;end
    209  : begin result_out <= 11'd1641; bias <= 3'd2  ;end
    210  : begin result_out <= 11'd1637; bias <= 3'd1  ;end
    211  : begin result_out <= 11'd1634; bias <= 3'd2  ;end
    212  : begin result_out <= 11'd1630; bias <= 3'd2  ;end
    213  : begin result_out <= 11'd1626; bias <= 3'd2  ;end
    214  : begin result_out <= 11'd1622; bias <= 3'd2  ;end
    215  : begin result_out <= 11'd1618; bias <= 3'd2  ;end
    216  : begin result_out <= 11'd1615; bias <= 3'd2  ;end
    217  : begin result_out <= 11'd1611; bias <= 3'd2  ;end
    218  : begin result_out <= 11'd1607; bias <= 3'd2  ;end
    219  : begin result_out <= 11'd1603; bias <= 3'd2  ;end
    220  : begin result_out <= 11'd1599; bias <= 3'd2  ;end
    221  : begin result_out <= 11'd1595; bias <= 3'd2  ;end
    222  : begin result_out <= 11'd1591; bias <= 3'd2  ;end
    223  : begin result_out <= 11'd1587; bias <= 3'd2  ;end
    224  : begin result_out <= 11'd1583; bias <= 3'd2  ;end
    225  : begin result_out <= 11'd1579; bias <= 3'd2  ;end
    226  : begin result_out <= 11'd1575; bias <= 3'd2  ;end
    227  : begin result_out <= 11'd1571; bias <= 3'd2  ;end
    228  : begin result_out <= 11'd1567; bias <= 3'd2  ;end
    229  : begin result_out <= 11'd1563; bias <= 3'd2  ;end
    230  : begin result_out <= 11'd1559; bias <= 3'd2  ;end
    231  : begin result_out <= 11'd1555; bias <= 3'd2  ;end
    232  : begin result_out <= 11'd1551; bias <= 3'd2  ;end
    233  : begin result_out <= 11'd1547; bias <= 3'd2  ;end
    234  : begin result_out <= 11'd1543; bias <= 3'd3  ;end
    235  : begin result_out <= 11'd1538; bias <= 3'd2  ;end
    236  : begin result_out <= 11'd1534; bias <= 3'd2  ;end
    237  : begin result_out <= 11'd1530; bias <= 3'd2  ;end
    238  : begin result_out <= 11'd1526; bias <= 3'd2  ;end
    239  : begin result_out <= 11'd1522; bias <= 3'd2  ;end
    240  : begin result_out <= 11'd1517; bias <= 3'd2  ;end
    241  : begin result_out <= 11'd1513; bias <= 3'd2  ;end
    242  : begin result_out <= 11'd1509; bias <= 3'd2  ;end
    243  : begin result_out <= 11'd1505; bias <= 3'd2  ;end
    244  : begin result_out <= 11'd1500; bias <= 3'd2  ;end
    245  : begin result_out <= 11'd1496; bias <= 3'd2  ;end
    246  : begin result_out <= 11'd1492; bias <= 3'd2  ;end
    247  : begin result_out <= 11'd1488; bias <= 3'd3  ;end
    248  : begin result_out <= 11'd1483; bias <= 3'd2  ;end
    249  : begin result_out <= 11'd1479; bias <= 3'd2  ;end
    250  : begin result_out <= 11'd1475; bias <= 3'd3  ;end
    251  : begin result_out <= 11'd1470; bias <= 3'd2  ;end
    252  : begin result_out <= 11'd1466; bias <= 3'd2  ;end
    253  : begin result_out <= 11'd1461; bias <= 3'd2  ;end
    254  : begin result_out <= 11'd1457; bias <= 3'd2  ;end
    255  : begin result_out <= 11'd1453; bias <= 3'd3  ;end
    256  : begin result_out <= 11'd1448; bias <= 3'd2  ;end
    257  : begin result_out <= 11'd1444; bias <= 3'd3  ;end
    258  : begin result_out <= 11'd1439; bias <= 3'd2  ;end
    259  : begin result_out <= 11'd1435; bias <= 3'd2  ;end
    260  : begin result_out <= 11'd1430; bias <= 3'd2  ;end
    261  : begin result_out <= 11'd1426; bias <= 3'd2  ;end
    262  : begin result_out <= 11'd1421; bias <= 3'd2  ;end
    263  : begin result_out <= 11'd1417; bias <= 3'd3  ;end
    264  : begin result_out <= 11'd1412; bias <= 3'd2  ;end
    265  : begin result_out <= 11'd1408; bias <= 3'd3  ;end
    266  : begin result_out <= 11'd1403; bias <= 3'd2  ;end
    267  : begin result_out <= 11'd1398; bias <= 3'd2  ;end
    268  : begin result_out <= 11'd1394; bias <= 3'd2  ;end
    269  : begin result_out <= 11'd1389; bias <= 3'd2  ;end
    270  : begin result_out <= 11'd1385; bias <= 3'd3  ;end
    271  : begin result_out <= 11'd1380; bias <= 3'd2  ;end
    272  : begin result_out <= 11'd1375; bias <= 3'd2  ;end
    273  : begin result_out <= 11'd1371; bias <= 3'd3  ;end
    274  : begin result_out <= 11'd1366; bias <= 3'd2  ;end
    275  : begin result_out <= 11'd1361; bias <= 3'd2  ;end
    276  : begin result_out <= 11'd1357; bias <= 3'd3  ;end
    277  : begin result_out <= 11'd1352; bias <= 3'd2  ;end
    278  : begin result_out <= 11'd1347; bias <= 3'd2  ;end
    279  : begin result_out <= 11'd1342; bias <= 3'd2  ;end
    280  : begin result_out <= 11'd1338; bias <= 3'd3  ;end
    281  : begin result_out <= 11'd1333; bias <= 3'd2  ;end
    282  : begin result_out <= 11'd1328; bias <= 3'd2  ;end
    283  : begin result_out <= 11'd1323; bias <= 3'd2  ;end
    284  : begin result_out <= 11'd1319; bias <= 3'd3  ;end
    285  : begin result_out <= 11'd1314; bias <= 3'd3  ;end
    286  : begin result_out <= 11'd1309; bias <= 3'd2  ;end
    287  : begin result_out <= 11'd1304; bias <= 3'd2  ;end
    288  : begin result_out <= 11'd1299; bias <= 3'd2  ;end
    289  : begin result_out <= 11'd1294; bias <= 3'd2  ;end
    290  : begin result_out <= 11'd1289; bias <= 3'd2  ;end
    291  : begin result_out <= 11'd1285; bias <= 3'd3  ;end
    292  : begin result_out <= 11'd1280; bias <= 3'd3  ;end
    293  : begin result_out <= 11'd1275; bias <= 3'd3  ;end
    294  : begin result_out <= 11'd1270; bias <= 3'd3  ;end
    295  : begin result_out <= 11'd1265; bias <= 3'd3  ;end
    296  : begin result_out <= 11'd1260; bias <= 3'd2  ;end
    297  : begin result_out <= 11'd1255; bias <= 3'd2  ;end
    298  : begin result_out <= 11'd1250; bias <= 3'd2  ;end
    299  : begin result_out <= 11'd1245; bias <= 3'd2  ;end
    300  : begin result_out <= 11'd1240; bias <= 3'd2  ;end
    301  : begin result_out <= 11'd1235; bias <= 3'd2  ;end
    302  : begin result_out <= 11'd1230; bias <= 3'd2  ;end
    303  : begin result_out <= 11'd1225; bias <= 3'd2  ;end
    304  : begin result_out <= 11'd1220; bias <= 3'd3  ;end
    305  : begin result_out <= 11'd1215; bias <= 3'd3  ;end
    306  : begin result_out <= 11'd1210; bias <= 3'd3  ;end
    307  : begin result_out <= 11'd1205; bias <= 3'd3  ;end
    308  : begin result_out <= 11'd1200; bias <= 3'd3  ;end
    309  : begin result_out <= 11'd1195; bias <= 3'd3  ;end
    310  : begin result_out <= 11'd1190; bias <= 3'd3  ;end
    311  : begin result_out <= 11'd1184; bias <= 3'd2  ;end
    312  : begin result_out <= 11'd1179; bias <= 3'd2  ;end
    313  : begin result_out <= 11'd1174; bias <= 3'd2  ;end
    314  : begin result_out <= 11'd1169; bias <= 3'd3  ;end
    315  : begin result_out <= 11'd1164; bias <= 3'd3  ;end
    316  : begin result_out <= 11'd1159; bias <= 3'd3  ;end
    317  : begin result_out <= 11'd1153; bias <= 3'd2  ;end
    318  : begin result_out <= 11'd1148; bias <= 3'd2  ;end
    319  : begin result_out <= 11'd1143; bias <= 3'd3  ;end
    320  : begin result_out <= 11'd1138; bias <= 3'd3  ;end
    321  : begin result_out <= 11'd1133; bias <= 3'd3  ;end
    322  : begin result_out <= 11'd1127; bias <= 3'd2  ;end
    323  : begin result_out <= 11'd1122; bias <= 3'd3  ;end
    324  : begin result_out <= 11'd1117; bias <= 3'd3  ;end
    325  : begin result_out <= 11'd1112; bias <= 3'd3  ;end
    326  : begin result_out <= 11'd1106; bias <= 3'd2  ;end
    327  : begin result_out <= 11'd1101; bias <= 3'd3  ;end
    328  : begin result_out <= 11'd1096; bias <= 3'd3  ;end
    329  : begin result_out <= 11'd1090; bias <= 3'd2  ;end
    330  : begin result_out <= 11'd1085; bias <= 3'd3  ;end
    331  : begin result_out <= 11'd1080; bias <= 3'd3  ;end
    332  : begin result_out <= 11'd1074; bias <= 3'd2  ;end
    333  : begin result_out <= 11'd1069; bias <= 3'd3  ;end
    334  : begin result_out <= 11'd1064; bias <= 3'd3  ;end
    335  : begin result_out <= 11'd1058; bias <= 3'd2  ;end
    336  : begin result_out <= 11'd1053; bias <= 3'd3  ;end
    337  : begin result_out <= 11'd1047; bias <= 3'd2  ;end
    338  : begin result_out <= 11'd1042; bias <= 3'd3  ;end
    339  : begin result_out <= 11'd1037; bias <= 3'd3  ;end
    340  : begin result_out <= 11'd1031; bias <= 3'd2  ;end
    341  : begin result_out <= 11'd1026; bias <= 3'd3  ;end
    342  : begin result_out <= 11'd1020; bias <= 3'd2  ;end
    343  : begin result_out <= 11'd1015; bias <= 3'd3  ;end
    344  : begin result_out <= 11'd1009; bias <= 3'd2  ;end
    345  : begin result_out <= 11'd1004; bias <= 3'd3  ;end
    346  : begin result_out <= 11'd999;  bias <= 3'd3  ;end
    347  : begin result_out <= 11'd993;  bias <= 3'd3  ;end
    348  : begin result_out <= 11'd988;  bias <= 3'd3  ;end
    349  : begin result_out <= 11'd982;  bias <= 3'd3  ;end
    350  : begin result_out <= 11'd976;  bias <= 3'd2  ;end
    351  : begin result_out <= 11'd971;  bias <= 3'd3  ;end
    352  : begin result_out <= 11'd965;  bias <= 3'd2  ;end
    353  : begin result_out <= 11'd960;  bias <= 3'd3  ;end
    354  : begin result_out <= 11'd954;  bias <= 3'd2  ;end
    355  : begin result_out <= 11'd949;  bias <= 3'd3  ;end
    356  : begin result_out <= 11'd943;  bias <= 3'd3  ;end
    357  : begin result_out <= 11'd938;  bias <= 3'd3  ;end
    358  : begin result_out <= 11'd932;  bias <= 3'd3  ;end
    359  : begin result_out <= 11'd926;  bias <= 3'd2  ;end
    360  : begin result_out <= 11'd921;  bias <= 3'd3  ;end
    361  : begin result_out <= 11'd915;  bias <= 3'd3  ;end
    362  : begin result_out <= 11'd910;  bias <= 3'd3  ;end
    363  : begin result_out <= 11'd904;  bias <= 3'd3  ;end
    364  : begin result_out <= 11'd898;  bias <= 3'd3  ;end
    365  : begin result_out <= 11'd893;  bias <= 3'd3  ;end
    366  : begin result_out <= 11'd887;  bias <= 3'd3  ;end
    367  : begin result_out <= 11'd881;  bias <= 3'd3  ;end
    368  : begin result_out <= 11'd876;  bias <= 3'd3  ;end
    369  : begin result_out <= 11'd870;  bias <= 3'd3  ;end
    370  : begin result_out <= 11'd864;  bias <= 3'd3  ;end
    371  : begin result_out <= 11'd859;  bias <= 3'd3  ;end
    372  : begin result_out <= 11'd853;  bias <= 3'd3  ;end
    373  : begin result_out <= 11'd847;  bias <= 3'd3  ;end
    374  : begin result_out <= 11'd841;  bias <= 3'd2  ;end
    375  : begin result_out <= 11'd836;  bias <= 3'd3  ;end
    376  : begin result_out <= 11'd830;  bias <= 3'd3  ;end
    377  : begin result_out <= 11'd824;  bias <= 3'd3  ;end
    378  : begin result_out <= 11'd818;  bias <= 3'd2  ;end
    379  : begin result_out <= 11'd813;  bias <= 3'd3  ;end
    380  : begin result_out <= 11'd807;  bias <= 3'd3  ;end
    381  : begin result_out <= 11'd801;  bias <= 3'd3  ;end
    382  : begin result_out <= 11'd795;  bias <= 3'd3  ;end
    383  : begin result_out <= 11'd790;  bias <= 3'd3  ;end
    384  : begin result_out <= 11'd784;  bias <= 3'd3  ;end
    385  : begin result_out <= 11'd778;  bias <= 3'd3  ;end
    386  : begin result_out <= 11'd772;  bias <= 3'd3  ;end
    387  : begin result_out <= 11'd766;  bias <= 3'd3  ;end
    388  : begin result_out <= 11'd760;  bias <= 3'd2  ;end
    389  : begin result_out <= 11'd755;  bias <= 3'd3  ;end
    390  : begin result_out <= 11'd749;  bias <= 3'd3  ;end
    391  : begin result_out <= 11'd743;  bias <= 3'd3  ;end
    392  : begin result_out <= 11'd737;  bias <= 3'd3  ;end
    393  : begin result_out <= 11'd731;  bias <= 3'd3  ;end
    394  : begin result_out <= 11'd725;  bias <= 3'd3  ;end
    395  : begin result_out <= 11'd719;  bias <= 3'd2  ;end
    396  : begin result_out <= 11'd714;  bias <= 3'd3  ;end
    397  : begin result_out <= 11'd708;  bias <= 3'd3  ;end
    398  : begin result_out <= 11'd702;  bias <= 3'd3  ;end
    399  : begin result_out <= 11'd696;  bias <= 3'd3  ;end
    400  : begin result_out <= 11'd690;  bias <= 3'd3  ;end
    401  : begin result_out <= 11'd684;  bias <= 3'd3  ;end
    402  : begin result_out <= 11'd678;  bias <= 3'd3  ;end
    403  : begin result_out <= 11'd672;  bias <= 3'd3  ;end
    404  : begin result_out <= 11'd666;  bias <= 3'd3  ;end
    405  : begin result_out <= 11'd660;  bias <= 3'd3  ;end
    406  : begin result_out <= 11'd654;  bias <= 3'd3  ;end
    407  : begin result_out <= 11'd648;  bias <= 3'd3  ;end
    408  : begin result_out <= 11'd642;  bias <= 3'd3  ;end
    409  : begin result_out <= 11'd636;  bias <= 3'd3  ;end
    410  : begin result_out <= 11'd630;  bias <= 3'd3  ;end
    411  : begin result_out <= 11'd624;  bias <= 3'd2  ;end
    412  : begin result_out <= 11'd619;  bias <= 3'd3  ;end
    413  : begin result_out <= 11'd613;  bias <= 3'd3  ;end
    414  : begin result_out <= 11'd607;  bias <= 3'd3  ;end
    415  : begin result_out <= 11'd601;  bias <= 3'd3  ;end
    416  : begin result_out <= 11'd595;  bias <= 3'd4  ;end
    417  : begin result_out <= 11'd588;  bias <= 3'd3  ;end
    418  : begin result_out <= 11'd582;  bias <= 3'd3  ;end
    419  : begin result_out <= 11'd576;  bias <= 3'd3  ;end
    420  : begin result_out <= 11'd570;  bias <= 3'd3  ;end
    421  : begin result_out <= 11'd564;  bias <= 3'd3  ;end
    422  : begin result_out <= 11'd558;  bias <= 3'd3  ;end
    423  : begin result_out <= 11'd552;  bias <= 3'd3  ;end
    424  : begin result_out <= 11'd546;  bias <= 3'd3  ;end
    425  : begin result_out <= 11'd540;  bias <= 3'd3  ;end
    426  : begin result_out <= 11'd534;  bias <= 3'd3  ;end
    427  : begin result_out <= 11'd528;  bias <= 3'd3  ;end
    428  : begin result_out <= 11'd522;  bias <= 3'd3  ;end
    429  : begin result_out <= 11'd516;  bias <= 3'd3  ;end
    430  : begin result_out <= 11'd510;  bias <= 3'd3  ;end
    431  : begin result_out <= 11'd504;  bias <= 3'd3  ;end
    432  : begin result_out <= 11'd498;  bias <= 3'd3  ;end
    433  : begin result_out <= 11'd492;  bias <= 3'd4  ;end
    434  : begin result_out <= 11'd485;  bias <= 3'd3  ;end
    435  : begin result_out <= 11'd479;  bias <= 3'd3  ;end
    436  : begin result_out <= 11'd473;  bias <= 3'd3  ;end
    437  : begin result_out <= 11'd467;  bias <= 3'd3  ;end
    438  : begin result_out <= 11'd461;  bias <= 3'd3  ;end
    439  : begin result_out <= 11'd455;  bias <= 3'd3  ;end
    440  : begin result_out <= 11'd449;  bias <= 3'd3  ;end
    441  : begin result_out <= 11'd443;  bias <= 3'd3  ;end
    442  : begin result_out <= 11'd436;  bias <= 3'd3  ;end
    443  : begin result_out <= 11'd430;  bias <= 3'd3  ;end
    444  : begin result_out <= 11'd424;  bias <= 3'd3  ;end
    445  : begin result_out <= 11'd418;  bias <= 3'd3  ;end
    446  : begin result_out <= 11'd412;  bias <= 3'd3  ;end
    447  : begin result_out <= 11'd406;  bias <= 3'd3  ;end
    448  : begin result_out <= 11'd400;  bias <= 3'd4  ;end
    449  : begin result_out <= 11'd393;  bias <= 3'd3  ;end
    450  : begin result_out <= 11'd387;  bias <= 3'd3  ;end
    451  : begin result_out <= 11'd381;  bias <= 3'd3  ;end
    452  : begin result_out <= 11'd375;  bias <= 3'd3  ;end
    453  : begin result_out <= 11'd369;  bias <= 3'd3  ;end
    454  : begin result_out <= 11'd363;  bias <= 3'd4  ;end
    455  : begin result_out <= 11'd356;  bias <= 3'd3  ;end
    456  : begin result_out <= 11'd350;  bias <= 3'd3  ;end
    457  : begin result_out <= 11'd344;  bias <= 3'd3  ;end
    458  : begin result_out <= 11'd338;  bias <= 3'd3  ;end
    459  : begin result_out <= 11'd332;  bias <= 3'd4  ;end
    460  : begin result_out <= 11'd325;  bias <= 3'd3  ;end
    461  : begin result_out <= 11'd319;  bias <= 3'd3  ;end
    462  : begin result_out <= 11'd313;  bias <= 3'd3  ;end
    463  : begin result_out <= 11'd307;  bias <= 3'd3  ;end
    464  : begin result_out <= 11'd301;  bias <= 3'd4  ;end
    465  : begin result_out <= 11'd294;  bias <= 3'd3  ;end
    466  : begin result_out <= 11'd288;  bias <= 3'd3  ;end
    467  : begin result_out <= 11'd282;  bias <= 3'd3  ;end
    468  : begin result_out <= 11'd276;  bias <= 3'd3  ;end
    469  : begin result_out <= 11'd269;  bias <= 3'd3  ;end
    470  : begin result_out <= 11'd263;  bias <= 3'd3  ;end
    471  : begin result_out <= 11'd257;  bias <= 3'd3  ;end
    472  : begin result_out <= 11'd251;  bias <= 3'd3  ;end
    473  : begin result_out <= 11'd244;  bias <= 3'd3  ;end
    474  : begin result_out <= 11'd238;  bias <= 3'd3  ;end
    475  : begin result_out <= 11'd232;  bias <= 3'd3  ;end
    476  : begin result_out <= 11'd226;  bias <= 3'd3  ;end
    477  : begin result_out <= 11'd219;  bias <= 3'd3  ;end
    478  : begin result_out <= 11'd213;  bias <= 3'd3  ;end
    479  : begin result_out <= 11'd207;  bias <= 3'd3  ;end
    480  : begin result_out <= 11'd201;  bias <= 3'd3  ;end
    481  : begin result_out <= 11'd194;  bias <= 3'd3  ;end
    482  : begin result_out <= 11'd188;  bias <= 3'd3  ;end
    483  : begin result_out <= 11'd182;  bias <= 3'd3  ;end
    484  : begin result_out <= 11'd176;  bias <= 3'd3  ;end
    485  : begin result_out <= 11'd169;  bias <= 3'd3  ;end
    486  : begin result_out <= 11'd163;  bias <= 3'd3  ;end
    487  : begin result_out <= 11'd157;  bias <= 3'd3  ;end
    488  : begin result_out <= 11'd151;  bias <= 3'd3  ;end
    489  : begin result_out <= 11'd144;  bias <= 3'd3  ;end
    490  : begin result_out <= 11'd138;  bias <= 3'd3  ;end
    491  : begin result_out <= 11'd132;  bias <= 3'd3  ;end
    492  : begin result_out <= 11'd126;  bias <= 3'd4  ;end
    493  : begin result_out <= 11'd119;  bias <= 3'd3  ;end
    494  : begin result_out <= 11'd113;  bias <= 3'd3  ;end
    495  : begin result_out <= 11'd107;  bias <= 3'd3  ;end
    496  : begin result_out <= 11'd100;  bias <= 3'd3  ;end
    497  : begin result_out <= 11'd94;   bias <= 3'd3  ;end
    498  : begin result_out <= 11'd88;   bias <= 3'd3  ;end
    499  : begin result_out <= 11'd82;   bias <= 3'd3  ;end
    500  : begin result_out <= 11'd75;   bias <= 3'd3  ;end
    501  : begin result_out <= 11'd69;   bias <= 3'd3  ;end
    502  : begin result_out <= 11'd63;   bias <= 3'd3  ;end
    503  : begin result_out <= 11'd57;   bias <= 3'd4  ;end
    504  : begin result_out <= 11'd50;   bias <= 3'd3  ;end
    505  : begin result_out <= 11'd44;   bias <= 3'd3  ;end
    506  : begin result_out <= 11'd38;   bias <= 3'd3  ;end
    507  : begin result_out <= 11'd31;   bias <= 3'd3  ;end
    508  : begin result_out <= 11'd25;   bias <= 3'd3  ;end
    509  : begin result_out <= 11'd19;   bias <= 3'd3  ;end
    510  : begin result_out <= 11'd13;   bias <= 3'd4  ;end
    511  : begin result_out <= 11'd6;    bias <= 3'd3  ;end
    default: begin result_out <= 11'd0;    bias <= 3'b0  ;end // Default case
    endcase
end

endmodule



module DivRom (
    input clk,
    input wire [12:0] add_in,
    output wire [3:0]sft_reg,
    output wire [11:0] div
);
//====================== cycle 1 =========================
reg [3:0] sft_reg_1;
reg [9:0] div_in;


always @(posedge clk) begin
    casez (add_in)
        13'b000000000000?:begin sft_reg_1 <= 0;  div_in <= 0;                   end
        13'b000000000001?:begin sft_reg_1 <= 1;  div_in <= {add_in[0]  ,9'b0};  end
        13'b00000000001??:begin sft_reg_1 <= 2;  div_in <= {add_in[1:0],8'b0};  end
        13'b0000000001???:begin sft_reg_1 <= 3;  div_in <= {add_in[2:0],7'b0};  end
        13'b000000001????:begin sft_reg_1 <= 4;  div_in <= {add_in[3:0],6'b0};  end
        13'b00000001?????:begin sft_reg_1 <= 5;  div_in <= {add_in[4:0],5'b0};  end
        13'b0000001??????:begin sft_reg_1 <= 6;  div_in <= {add_in[5:0],4'b0};  end
        13'b000001???????:begin sft_reg_1 <= 7;  div_in <= {add_in[6:0],3'b0};  end
        13'b00001????????:begin sft_reg_1 <= 8;  div_in <= {add_in[7:0],2'b0};  end
        13'b0001?????????:begin sft_reg_1 <= 9;  div_in <= {add_in[8:0],1'b0};  end
        13'b001??????????:begin sft_reg_1 <= 10; div_in <= add_in[9:0];         end
        13'b01???????????:begin sft_reg_1 <= 11; div_in <= add_in[10:1];        end
        13'b1????????????:begin sft_reg_1 <= 12; div_in <= add_in[11:2];        end
    endcase
end

//====================== cycle 2 =========================

reg [3:0] sft_reg_2;
always @(posedge clk)begin
    sft_reg_2 <= sft_reg_1;
end

reg divadd_sel;
always @(posedge clk) begin
    divadd_sel <= div_in[0];
end

//====================== cycle 3 =========================
reg [11:0] div_out;
reg [2:0] bias;

assign div = divadd_sel?div_out-{8'b0,bias}:div_out;
assign sft_reg = sft_reg_2;

//======================  table  =========================

always @(posedge clk) begin
case(div_in[9:1])
0    : begin div_out <= 12'd4095; bias <= 3'd3; end
1    : begin div_out <= 12'd4088; bias <= 3'd4; end
2    : begin div_out <= 12'd4080; bias <= 3'd4; end
3    : begin div_out <= 12'd4072; bias <= 3'd4; end
4    : begin div_out <= 12'd4064; bias <= 3'd4; end
5    : begin div_out <= 12'd4056; bias <= 3'd4; end
6    : begin div_out <= 12'd4049; bias <= 3'd4; end
7    : begin div_out <= 12'd4041; bias <= 3'd4; end
8    : begin div_out <= 12'd4033; bias <= 3'd4; end
9    : begin div_out <= 12'd4025; bias <= 3'd4; end
10   : begin div_out <= 12'd4018; bias <= 3'd4; end
11   : begin div_out <= 12'd4010; bias <= 3'd4; end
12   : begin div_out <= 12'd4002; bias <= 3'd4; end
13   : begin div_out <= 12'd3995; bias <= 3'd4; end
14   : begin div_out <= 12'd3987; bias <= 3'd4; end
15   : begin div_out <= 12'd3979; bias <= 3'd3; end
16   : begin div_out <= 12'd3972; bias <= 3'd4; end
17   : begin div_out <= 12'd3964; bias <= 3'd3; end
18   : begin div_out <= 12'd3957; bias <= 3'd4; end
19   : begin div_out <= 12'd3949; bias <= 3'd3; end
20   : begin div_out <= 12'd3942; bias <= 3'd4; end
21   : begin div_out <= 12'd3935; bias <= 3'd4; end
22   : begin div_out <= 12'd3927; bias <= 3'd3; end
23   : begin div_out <= 12'd3920; bias <= 3'd4; end
24   : begin div_out <= 12'd3913; bias <= 3'd4; end
25   : begin div_out <= 12'd3905; bias <= 3'd3; end
26   : begin div_out <= 12'd3898; bias <= 3'd4; end
27   : begin div_out <= 12'd3891; bias <= 3'd4; end
28   : begin div_out <= 12'd3884; bias <= 3'd4; end
29   : begin div_out <= 12'd3876; bias <= 3'd3; end
30   : begin div_out <= 12'd3869; bias <= 3'd3; end
31   : begin div_out <= 12'd3862; bias <= 3'd3; end
32   : begin div_out <= 12'd3855; bias <= 3'd3; end
33   : begin div_out <= 12'd3848; bias <= 3'd4; end
34   : begin div_out <= 12'd3841; bias <= 3'd4; end
35   : begin div_out <= 12'd3834; bias <= 3'd4; end
36   : begin div_out <= 12'd3827; bias <= 3'd4; end
37   : begin div_out <= 12'd3820; bias <= 3'd4; end
38   : begin div_out <= 12'd3813; bias <= 3'd3; end
39   : begin div_out <= 12'd3806; bias <= 3'd3; end
40   : begin div_out <= 12'd3799; bias <= 3'd3; end
41   : begin div_out <= 12'd3792; bias <= 3'd3; end
42   : begin div_out <= 12'd3785; bias <= 3'd3; end
43   : begin div_out <= 12'd3779; bias <= 3'd4; end
44   : begin div_out <= 12'd3772; bias <= 3'd4; end
45   : begin div_out <= 12'd3765; bias <= 3'd3; end
46   : begin div_out <= 12'd3758; bias <= 3'd3; end
47   : begin div_out <= 12'd3752; bias <= 3'd4; end
48   : begin div_out <= 12'd3745; bias <= 3'd3; end
49   : begin div_out <= 12'd3738; bias <= 3'd3; end
50   : begin div_out <= 12'd3732; bias <= 3'd4; end
51   : begin div_out <= 12'd3725; bias <= 3'd3; end
52   : begin div_out <= 12'd3718; bias <= 3'd3; end
53   : begin div_out <= 12'd3712; bias <= 3'd4; end
54   : begin div_out <= 12'd3705; bias <= 3'd3; end
55   : begin div_out <= 12'd3699; bias <= 3'd4; end
56   : begin div_out <= 12'd3692; bias <= 3'd3; end
57   : begin div_out <= 12'd3686; bias <= 3'd4; end
58   : begin div_out <= 12'd3679; bias <= 3'd3; end
59   : begin div_out <= 12'd3673; bias <= 3'd3; end
60   : begin div_out <= 12'd3666; bias <= 3'd3; end
61   : begin div_out <= 12'd3660; bias <= 3'd3; end
62   : begin div_out <= 12'd3654; bias <= 3'd4; end
63   : begin div_out <= 12'd3647; bias <= 3'd3; end
64   : begin div_out <= 12'd3641; bias <= 3'd3; end
65   : begin div_out <= 12'd3635; bias <= 3'd4; end
66   : begin div_out <= 12'd3628; bias <= 3'd3; end
67   : begin div_out <= 12'd3622; bias <= 3'd3; end
68   : begin div_out <= 12'd3616; bias <= 3'd3; end
69   : begin div_out <= 12'd3610; bias <= 3'd4; end
70   : begin div_out <= 12'd3603; bias <= 3'd3; end
71   : begin div_out <= 12'd3597; bias <= 3'd3; end
72   : begin div_out <= 12'd3591; bias <= 3'd3; end
73   : begin div_out <= 12'd3585; bias <= 3'd3; end
74   : begin div_out <= 12'd3579; bias <= 3'd3; end
75   : begin div_out <= 12'd3573; bias <= 3'd3; end
76   : begin div_out <= 12'd3567; bias <= 3'd3; end
77   : begin div_out <= 12'd3561; bias <= 3'd3; end
78   : begin div_out <= 12'd3554; bias <= 3'd3; end
79   : begin div_out <= 12'd3548; bias <= 3'd3; end
80   : begin div_out <= 12'd3542; bias <= 3'd3; end
81   : begin div_out <= 12'd3537; bias <= 3'd3; end
82   : begin div_out <= 12'd3531; bias <= 3'd3; end
83   : begin div_out <= 12'd3525; bias <= 3'd3; end
84   : begin div_out <= 12'd3519; bias <= 3'd3; end
85   : begin div_out <= 12'd3513; bias <= 3'd3; end
86   : begin div_out <= 12'd3507; bias <= 3'd3; end
87   : begin div_out <= 12'd3501; bias <= 3'd3; end
88   : begin div_out <= 12'd3495; bias <= 3'd3; end
89   : begin div_out <= 12'd3489; bias <= 3'd2; end
90   : begin div_out <= 12'd3484; bias <= 3'd3; end
91   : begin div_out <= 12'd3478; bias <= 3'd3; end
92   : begin div_out <= 12'd3472; bias <= 3'd3; end
93   : begin div_out <= 12'd3466; bias <= 3'd2; end
94   : begin div_out <= 12'd3461; bias <= 3'd3; end
95   : begin div_out <= 12'd3455; bias <= 3'd3; end
96   : begin div_out <= 12'd3449; bias <= 3'd3; end
97   : begin div_out <= 12'd3444; bias <= 3'd3; end
98   : begin div_out <= 12'd3438; bias <= 3'd3; end
99   : begin div_out <= 12'd3432; bias <= 3'd2; end
100  : begin div_out <= 12'd3427; bias <= 3'd3; end
101  : begin div_out <= 12'd3421; bias <= 3'd3; end
102  : begin div_out <= 12'd3416; bias <= 3'd3; end
103  : begin div_out <= 12'd3410; bias <= 3'd3; end
104  : begin div_out <= 12'd3404; bias <= 3'd2; end
105  : begin div_out <= 12'd3399; bias <= 3'd3; end
106  : begin div_out <= 12'd3393; bias <= 3'd2; end
107  : begin div_out <= 12'd3388; bias <= 3'd3; end
108  : begin div_out <= 12'd3383; bias <= 3'd3; end
109  : begin div_out <= 12'd3377; bias <= 3'd3; end
110  : begin div_out <= 12'd3372; bias <= 3'd3; end
111  : begin div_out <= 12'd3366; bias <= 3'd2; end
112  : begin div_out <= 12'd3361; bias <= 3'd3; end
113  : begin div_out <= 12'd3355; bias <= 3'd2; end
114  : begin div_out <= 12'd3350; bias <= 3'd3; end
115  : begin div_out <= 12'd3345; bias <= 3'd3; end
116  : begin div_out <= 12'd3339; bias <= 3'd2; end
117  : begin div_out <= 12'd3334; bias <= 3'd3; end
118  : begin div_out <= 12'd3329; bias <= 3'd3; end
119  : begin div_out <= 12'd3324; bias <= 3'd3; end
120  : begin div_out <= 12'd3318; bias <= 3'd2; end
121  : begin div_out <= 12'd3313; bias <= 3'd3; end
122  : begin div_out <= 12'd3308; bias <= 3'd3; end
123  : begin div_out <= 12'd3303; bias <= 3'd3; end
124  : begin div_out <= 12'd3297; bias <= 3'd2; end
125  : begin div_out <= 12'd3292; bias <= 3'd2; end
126  : begin div_out <= 12'd3287; bias <= 3'd3; end
127  : begin div_out <= 12'd3282; bias <= 3'd3; end
128  : begin div_out <= 12'd3277; bias <= 3'd3; end
129  : begin div_out <= 12'd3272; bias <= 3'd3; end
130  : begin div_out <= 12'd3267; bias <= 3'd3; end
131  : begin div_out <= 12'd3262; bias <= 3'd3; end
132  : begin div_out <= 12'd3256; bias <= 3'd2; end
133  : begin div_out <= 12'd3251; bias <= 3'd2; end
134  : begin div_out <= 12'd3246; bias <= 3'd2; end
135  : begin div_out <= 12'd3241; bias <= 3'd2; end
136  : begin div_out <= 12'd3236; bias <= 3'd2; end
137  : begin div_out <= 12'd3231; bias <= 3'd2; end
138  : begin div_out <= 12'd3226; bias <= 3'd2; end
139  : begin div_out <= 12'd3221; bias <= 3'd2; end
140  : begin div_out <= 12'd3216; bias <= 3'd2; end
141  : begin div_out <= 12'd3212; bias <= 3'd3; end
142  : begin div_out <= 12'd3207; bias <= 3'd3; end
143  : begin div_out <= 12'd3202; bias <= 3'd3; end
144  : begin div_out <= 12'd3197; bias <= 3'd3; end
145  : begin div_out <= 12'd3192; bias <= 3'd2; end
146  : begin div_out <= 12'd3187; bias <= 3'd2; end
147  : begin div_out <= 12'd3182; bias <= 3'd2; end
148  : begin div_out <= 12'd3178; bias <= 3'd3; end
149  : begin div_out <= 12'd3173; bias <= 3'd3; end
150  : begin div_out <= 12'd3168; bias <= 3'd2; end
151  : begin div_out <= 12'd3163; bias <= 3'd2; end
152  : begin div_out <= 12'd3158; bias <= 3'd2; end
153  : begin div_out <= 12'd3154; bias <= 3'd3; end
154  : begin div_out <= 12'd3149; bias <= 3'd2; end
155  : begin div_out <= 12'd3144; bias <= 3'd2; end
156  : begin div_out <= 12'd3139; bias <= 3'd2; end
157  : begin div_out <= 12'd3135; bias <= 3'd3; end
158  : begin div_out <= 12'd3130; bias <= 3'd2; end
159  : begin div_out <= 12'd3125; bias <= 3'd2; end
160  : begin div_out <= 12'd3121; bias <= 3'd3; end
161  : begin div_out <= 12'd3116; bias <= 3'd2; end
162  : begin div_out <= 12'd3112; bias <= 3'd3; end
163  : begin div_out <= 12'd3107; bias <= 3'd2; end
164  : begin div_out <= 12'd3102; bias <= 3'd2; end
165  : begin div_out <= 12'd3098; bias <= 3'd3; end
166  : begin div_out <= 12'd3093; bias <= 3'd2; end
167  : begin div_out <= 12'd3089; bias <= 3'd3; end
168  : begin div_out <= 12'd3084; bias <= 3'd2; end
169  : begin div_out <= 12'd3080; bias <= 3'd3; end
170  : begin div_out <= 12'd3075; bias <= 3'd2; end
171  : begin div_out <= 12'd3071; bias <= 3'd3; end
172  : begin div_out <= 12'd3066; bias <= 3'd2; end
173  : begin div_out <= 12'd3062; bias <= 3'd3; end
174  : begin div_out <= 12'd3057; bias <= 3'd2; end
175  : begin div_out <= 12'd3053; bias <= 3'd3; end
176  : begin div_out <= 12'd3048; bias <= 3'd2; end
177  : begin div_out <= 12'd3044; bias <= 3'd2; end
178  : begin div_out <= 12'd3039; bias <= 3'd2; end
179  : begin div_out <= 12'd3035; bias <= 3'd2; end
180  : begin div_out <= 12'd3031; bias <= 3'd3; end
181  : begin div_out <= 12'd3026; bias <= 3'd2; end
182  : begin div_out <= 12'd3022; bias <= 3'd2; end
183  : begin div_out <= 12'd3017; bias <= 3'd2; end
184  : begin div_out <= 12'd3013; bias <= 3'd2; end
185  : begin div_out <= 12'd3009; bias <= 3'd2; end
186  : begin div_out <= 12'd3005; bias <= 3'd3; end
187  : begin div_out <= 12'd3000; bias <= 3'd2; end
188  : begin div_out <= 12'd2996; bias <= 3'd2; end
189  : begin div_out <= 12'd2992; bias <= 3'd2; end
190  : begin div_out <= 12'd2987; bias <= 3'd2; end
191  : begin div_out <= 12'd2983; bias <= 3'd2; end
192  : begin div_out <= 12'd2979; bias <= 3'd2; end
193  : begin div_out <= 12'd2975; bias <= 3'd2; end
194  : begin div_out <= 12'd2970; bias <= 3'd2; end
195  : begin div_out <= 12'd2966; bias <= 3'd2; end
196  : begin div_out <= 12'd2962; bias <= 3'd2; end
197  : begin div_out <= 12'd2958; bias <= 3'd2; end
198  : begin div_out <= 12'd2954; bias <= 3'd2; end
199  : begin div_out <= 12'd2950; bias <= 3'd2; end
200  : begin div_out <= 12'd2945; bias <= 3'd2; end
201  : begin div_out <= 12'd2941; bias <= 3'd2; end
202  : begin div_out <= 12'd2937; bias <= 3'd2; end
203  : begin div_out <= 12'd2933; bias <= 3'd2; end
204  : begin div_out <= 12'd2929; bias <= 3'd2; end
205  : begin div_out <= 12'd2925; bias <= 3'd2; end
206  : begin div_out <= 12'd2921; bias <= 3'd2; end
207  : begin div_out <= 12'd2917; bias <= 3'd2; end
208  : begin div_out <= 12'd2913; bias <= 3'd2; end
209  : begin div_out <= 12'd2909; bias <= 3'd2; end
210  : begin div_out <= 12'd2905; bias <= 3'd2; end
211  : begin div_out <= 12'd2901; bias <= 3'd2; end
212  : begin div_out <= 12'd2897; bias <= 3'd2; end
213  : begin div_out <= 12'd2893; bias <= 3'd2; end
214  : begin div_out <= 12'd2889; bias <= 3'd2; end
215  : begin div_out <= 12'd2885; bias <= 3'd2; end
216  : begin div_out <= 12'd2881; bias <= 3'd2; end
217  : begin div_out <= 12'd2877; bias <= 3'd2; end
218  : begin div_out <= 12'd2873; bias <= 3'd2; end
219  : begin div_out <= 12'd2869; bias <= 3'd2; end
220  : begin div_out <= 12'd2865; bias <= 3'd2; end
221  : begin div_out <= 12'd2861; bias <= 3'd2; end
222  : begin div_out <= 12'd2857; bias <= 3'd2; end
223  : begin div_out <= 12'd2853; bias <= 3'd2; end
224  : begin div_out <= 12'd2849; bias <= 3'd2; end
225  : begin div_out <= 12'd2846; bias <= 3'd2; end
226  : begin div_out <= 12'd2842; bias <= 3'd2; end
227  : begin div_out <= 12'd2838; bias <= 3'd2; end
228  : begin div_out <= 12'd2834; bias <= 3'd2; end
229  : begin div_out <= 12'd2830; bias <= 3'd2; end
230  : begin div_out <= 12'd2826; bias <= 3'd2; end
231  : begin div_out <= 12'd2823; bias <= 3'd2; end
232  : begin div_out <= 12'd2819; bias <= 3'd2; end
233  : begin div_out <= 12'd2815; bias <= 3'd2; end
234  : begin div_out <= 12'd2811; bias <= 3'd2; end
235  : begin div_out <= 12'd2807; bias <= 3'd1; end
236  : begin div_out <= 12'd2804; bias <= 3'd2; end
237  : begin div_out <= 12'd2800; bias <= 3'd2; end
238  : begin div_out <= 12'd2796; bias <= 3'd2; end
239  : begin div_out <= 12'd2792; bias <= 3'd1; end
240  : begin div_out <= 12'd2789; bias <= 3'd2; end
241  : begin div_out <= 12'd2785; bias <= 3'd2; end
242  : begin div_out <= 12'd2781; bias <= 3'd1; end
243  : begin div_out <= 12'd2778; bias <= 3'd2; end
244  : begin div_out <= 12'd2774; bias <= 3'd2; end
245  : begin div_out <= 12'd2770; bias <= 3'd1; end
246  : begin div_out <= 12'd2767; bias <= 3'd2; end
247  : begin div_out <= 12'd2763; bias <= 3'd2; end
248  : begin div_out <= 12'd2759; bias <= 3'd1; end
249  : begin div_out <= 12'd2756; bias <= 3'd2; end
250  : begin div_out <= 12'd2752; bias <= 3'd2; end
251  : begin div_out <= 12'd2749; bias <= 3'd2; end
252  : begin div_out <= 12'd2745; bias <= 3'd2; end
253  : begin div_out <= 12'd2741; bias <= 3'd1; end
254  : begin div_out <= 12'd2738; bias <= 3'd2; end
255  : begin div_out <= 12'd2734; bias <= 3'd2; end
256  : begin div_out <= 12'd2731; bias <= 3'd2; end
257  : begin div_out <= 12'd2727; bias <= 3'd2; end
258  : begin div_out <= 12'd2724; bias <= 3'd2; end
259  : begin div_out <= 12'd2720; bias <= 3'd2; end
260  : begin div_out <= 12'd2717; bias <= 3'd2; end
261  : begin div_out <= 12'd2713; bias <= 3'd2; end
262  : begin div_out <= 12'd2709; bias <= 3'd1; end
263  : begin div_out <= 12'd2706; bias <= 3'd2; end
264  : begin div_out <= 12'd2703; bias <= 3'd2; end
265  : begin div_out <= 12'd2699; bias <= 3'd2; end
266  : begin div_out <= 12'd2696; bias <= 3'd2; end
267  : begin div_out <= 12'd2692; bias <= 3'd2; end
268  : begin div_out <= 12'd2689; bias <= 3'd2; end
269  : begin div_out <= 12'd2685; bias <= 3'd2; end
270  : begin div_out <= 12'd2682; bias <= 3'd2; end
271  : begin div_out <= 12'd2678; bias <= 3'd1; end
272  : begin div_out <= 12'd2675; bias <= 3'd2; end
273  : begin div_out <= 12'd2672; bias <= 3'd2; end
274  : begin div_out <= 12'd2668; bias <= 3'd2; end
275  : begin div_out <= 12'd2665; bias <= 3'd2; end
276  : begin div_out <= 12'd2661; bias <= 3'd1; end
277  : begin div_out <= 12'd2658; bias <= 3'd2; end
278  : begin div_out <= 12'd2655; bias <= 3'd2; end
279  : begin div_out <= 12'd2651; bias <= 3'd1; end
280  : begin div_out <= 12'd2648; bias <= 3'd2; end
281  : begin div_out <= 12'd2645; bias <= 3'd2; end
282  : begin div_out <= 12'd2641; bias <= 3'd1; end
283  : begin div_out <= 12'd2638; bias <= 3'd2; end
284  : begin div_out <= 12'd2635; bias <= 3'd2; end
285  : begin div_out <= 12'd2631; bias <= 3'd1; end
286  : begin div_out <= 12'd2628; bias <= 3'd2; end
287  : begin div_out <= 12'd2625; bias <= 3'd2; end
288  : begin div_out <= 12'd2621; bias <= 3'd1; end
289  : begin div_out <= 12'd2618; bias <= 3'd1; end
290  : begin div_out <= 12'd2615; bias <= 3'd2; end
291  : begin div_out <= 12'd2612; bias <= 3'd2; end
292  : begin div_out <= 12'd2608; bias <= 3'd1; end
293  : begin div_out <= 12'd2605; bias <= 3'd1; end
294  : begin div_out <= 12'd2602; bias <= 3'd2; end
295  : begin div_out <= 12'd2599; bias <= 3'd2; end
296  : begin div_out <= 12'd2595; bias <= 3'd1; end
297  : begin div_out <= 12'd2592; bias <= 3'd1; end
298  : begin div_out <= 12'd2589; bias <= 3'd2; end
299  : begin div_out <= 12'd2586; bias <= 3'd2; end
300  : begin div_out <= 12'd2583; bias <= 3'd2; end
301  : begin div_out <= 12'd2580; bias <= 3'd2; end
302  : begin div_out <= 12'd2576; bias <= 3'd1; end
303  : begin div_out <= 12'd2573; bias <= 3'd1; end
304  : begin div_out <= 12'd2570; bias <= 3'd2; end
305  : begin div_out <= 12'd2567; bias <= 3'd2; end
306  : begin div_out <= 12'd2564; bias <= 3'd2; end
307  : begin div_out <= 12'd2561; bias <= 3'd2; end
308  : begin div_out <= 12'd2558; bias <= 3'd2; end
309  : begin div_out <= 12'd2554; bias <= 3'd1; end
310  : begin div_out <= 12'd2551; bias <= 3'd1; end
311  : begin div_out <= 12'd2548; bias <= 3'd1; end
312  : begin div_out <= 12'd2545; bias <= 3'd1; end
313  : begin div_out <= 12'd2542; bias <= 3'd2; end
314  : begin div_out <= 12'd2539; bias <= 3'd2; end
315  : begin div_out <= 12'd2536; bias <= 3'd2; end
316  : begin div_out <= 12'd2533; bias <= 3'd2; end
317  : begin div_out <= 12'd2530; bias <= 3'd2; end
318  : begin div_out <= 12'd2527; bias <= 3'd2; end
319  : begin div_out <= 12'd2524; bias <= 3'd2; end
320  : begin div_out <= 12'd2521; bias <= 3'd2; end
321  : begin div_out <= 12'd2518; bias <= 3'd2; end
322  : begin div_out <= 12'd2515; bias <= 3'd2; end
323  : begin div_out <= 12'd2512; bias <= 3'd2; end
324  : begin div_out <= 12'd2509; bias <= 3'd2; end
325  : begin div_out <= 12'd2506; bias <= 3'd2; end
326  : begin div_out <= 12'd2503; bias <= 3'd2; end
327  : begin div_out <= 12'd2500; bias <= 3'd2; end
328  : begin div_out <= 12'd2497; bias <= 3'd2; end
329  : begin div_out <= 12'd2494; bias <= 3'd2; end
330  : begin div_out <= 12'd2491; bias <= 3'd2; end
331  : begin div_out <= 12'd2488; bias <= 3'd2; end
332  : begin div_out <= 12'd2485; bias <= 3'd2; end
333  : begin div_out <= 12'd2482; bias <= 3'd2; end
334  : begin div_out <= 12'd2479; bias <= 3'd2; end
335  : begin div_out <= 12'd2476; bias <= 3'd1; end
336  : begin div_out <= 12'd2473; bias <= 3'd1; end
337  : begin div_out <= 12'd2470; bias <= 3'd1; end
338  : begin div_out <= 12'd2467; bias <= 3'd1; end
339  : begin div_out <= 12'd2464; bias <= 3'd1; end
340  : begin div_out <= 12'd2461; bias <= 3'd1; end
341  : begin div_out <= 12'd2459; bias <= 3'd2; end
342  : begin div_out <= 12'd2456; bias <= 3'd2; end
343  : begin div_out <= 12'd2453; bias <= 3'd2; end
344  : begin div_out <= 12'd2450; bias <= 3'd1; end
345  : begin div_out <= 12'd2447; bias <= 3'd1; end
346  : begin div_out <= 12'd2444; bias <= 3'd1; end
347  : begin div_out <= 12'd2441; bias <= 3'd1; end
348  : begin div_out <= 12'd2439; bias <= 3'd2; end
349  : begin div_out <= 12'd2436; bias <= 3'd2; end
350  : begin div_out <= 12'd2433; bias <= 3'd2; end
351  : begin div_out <= 12'd2430; bias <= 3'd1; end
352  : begin div_out <= 12'd2427; bias <= 3'd1; end
353  : begin div_out <= 12'd2424; bias <= 3'd1; end
354  : begin div_out <= 12'd2422; bias <= 3'd2; end
355  : begin div_out <= 12'd2419; bias <= 3'd2; end
356  : begin div_out <= 12'd2416; bias <= 3'd1; end
357  : begin div_out <= 12'd2413; bias <= 3'd1; end
358  : begin div_out <= 12'd2411; bias <= 3'd2; end
359  : begin div_out <= 12'd2408; bias <= 3'd2; end
360  : begin div_out <= 12'd2405; bias <= 3'd1; end
361  : begin div_out <= 12'd2402; bias <= 3'd1; end
362  : begin div_out <= 12'd2399; bias <= 3'd1; end
363  : begin div_out <= 12'd2397; bias <= 3'd2; end
364  : begin div_out <= 12'd2394; bias <= 3'd1; end
365  : begin div_out <= 12'd2391; bias <= 3'd1; end
366  : begin div_out <= 12'd2389; bias <= 3'd2; end
367  : begin div_out <= 12'd2386; bias <= 3'd2; end
368  : begin div_out <= 12'd2383; bias <= 3'd1; end
369  : begin div_out <= 12'd2380; bias <= 3'd1; end
370  : begin div_out <= 12'd2378; bias <= 3'd2; end
371  : begin div_out <= 12'd2375; bias <= 3'd1; end
372  : begin div_out <= 12'd2372; bias <= 3'd1; end
373  : begin div_out <= 12'd2370; bias <= 3'd2; end
374  : begin div_out <= 12'd2367; bias <= 3'd1; end
375  : begin div_out <= 12'd2364; bias <= 3'd1; end
376  : begin div_out <= 12'd2362; bias <= 3'd2; end
377  : begin div_out <= 12'd2359; bias <= 3'd1; end
378  : begin div_out <= 12'd2356; bias <= 3'd1; end
379  : begin div_out <= 12'd2354; bias <= 3'd2; end
380  : begin div_out <= 12'd2351; bias <= 3'd1; end
381  : begin div_out <= 12'd2348; bias <= 3'd1; end
382  : begin div_out <= 12'd2346; bias <= 3'd2; end
383  : begin div_out <= 12'd2343; bias <= 3'd1; end
384  : begin div_out <= 12'd2341; bias <= 3'd2; end
385  : begin div_out <= 12'd2338; bias <= 3'd1; end
386  : begin div_out <= 12'd2335; bias <= 3'd1; end
387  : begin div_out <= 12'd2333; bias <= 3'd2; end
388  : begin div_out <= 12'd2330; bias <= 3'd1; end
389  : begin div_out <= 12'd2328; bias <= 3'd2; end
390  : begin div_out <= 12'd2325; bias <= 3'd1; end
391  : begin div_out <= 12'd2322; bias <= 3'd1; end
392  : begin div_out <= 12'd2320; bias <= 3'd1; end
393  : begin div_out <= 12'd2317; bias <= 3'd1; end
394  : begin div_out <= 12'd2315; bias <= 3'd2; end
395  : begin div_out <= 12'd2312; bias <= 3'd1; end
396  : begin div_out <= 12'd2310; bias <= 3'd2; end
397  : begin div_out <= 12'd2307; bias <= 3'd1; end
398  : begin div_out <= 12'd2305; bias <= 3'd2; end
399  : begin div_out <= 12'd2302; bias <= 3'd1; end
400  : begin div_out <= 12'd2300; bias <= 3'd2; end
401  : begin div_out <= 12'd2297; bias <= 3'd1; end
402  : begin div_out <= 12'd2294; bias <= 3'd1; end
403  : begin div_out <= 12'd2292; bias <= 3'd1; end
404  : begin div_out <= 12'd2289; bias <= 3'd1; end
405  : begin div_out <= 12'd2287; bias <= 3'd1; end
406  : begin div_out <= 12'd2284; bias <= 3'd1; end
407  : begin div_out <= 12'd2282; bias <= 3'd1; end
408  : begin div_out <= 12'd2280; bias <= 3'd2; end
409  : begin div_out <= 12'd2277; bias <= 3'd1; end
410  : begin div_out <= 12'd2275; bias <= 3'd2; end
411  : begin div_out <= 12'd2272; bias <= 3'd1; end
412  : begin div_out <= 12'd2270; bias <= 3'd2; end
413  : begin div_out <= 12'd2267; bias <= 3'd1; end
414  : begin div_out <= 12'd2265; bias <= 3'd1; end
415  : begin div_out <= 12'd2262; bias <= 3'd1; end
416  : begin div_out <= 12'd2260; bias <= 3'd1; end
417  : begin div_out <= 12'd2257; bias <= 3'd1; end
418  : begin div_out <= 12'd2255; bias <= 3'd1; end
419  : begin div_out <= 12'd2253; bias <= 3'd2; end
420  : begin div_out <= 12'd2250; bias <= 3'd1; end
421  : begin div_out <= 12'd2248; bias <= 3'd1; end
422  : begin div_out <= 12'd2245; bias <= 3'd1; end
423  : begin div_out <= 12'd2243; bias <= 3'd1; end
424  : begin div_out <= 12'd2241; bias <= 3'd2; end
425  : begin div_out <= 12'd2238; bias <= 3'd1; end
426  : begin div_out <= 12'd2236; bias <= 3'd1; end
427  : begin div_out <= 12'd2233; bias <= 3'd1; end
428  : begin div_out <= 12'd2231; bias <= 3'd1; end
429  : begin div_out <= 12'd2229; bias <= 3'd2; end
430  : begin div_out <= 12'd2226; bias <= 3'd1; end
431  : begin div_out <= 12'd2224; bias <= 3'd1; end
432  : begin div_out <= 12'd2222; bias <= 3'd2; end
433  : begin div_out <= 12'd2219; bias <= 3'd1; end
434  : begin div_out <= 12'd2217; bias <= 3'd1; end
435  : begin div_out <= 12'd2215; bias <= 3'd2; end
436  : begin div_out <= 12'd2212; bias <= 3'd1; end
437  : begin div_out <= 12'd2210; bias <= 3'd1; end
438  : begin div_out <= 12'd2208; bias <= 3'd2; end
439  : begin div_out <= 12'd2205; bias <= 3'd1; end
440  : begin div_out <= 12'd2203; bias <= 3'd1; end
441  : begin div_out <= 12'd2201; bias <= 3'd2; end
442  : begin div_out <= 12'd2198; bias <= 3'd1; end
443  : begin div_out <= 12'd2196; bias <= 3'd1; end
444  : begin div_out <= 12'd2194; bias <= 3'd1; end
445  : begin div_out <= 12'd2191; bias <= 3'd1; end
446  : begin div_out <= 12'd2189; bias <= 3'd1; end
447  : begin div_out <= 12'd2187; bias <= 3'd1; end
448  : begin div_out <= 12'd2185; bias <= 3'd2; end
449  : begin div_out <= 12'd2182; bias <= 3'd1; end
450  : begin div_out <= 12'd2180; bias <= 3'd1; end
451  : begin div_out <= 12'd2178; bias <= 3'd1; end
452  : begin div_out <= 12'd2175; bias <= 3'd1; end
453  : begin div_out <= 12'd2173; bias <= 3'd1; end
454  : begin div_out <= 12'd2171; bias <= 3'd1; end
455  : begin div_out <= 12'd2169; bias <= 3'd1; end
456  : begin div_out <= 12'd2166; bias <= 3'd1; end
457  : begin div_out <= 12'd2164; bias <= 3'd1; end
458  : begin div_out <= 12'd2162; bias <= 3'd1; end
459  : begin div_out <= 12'd2160; bias <= 3'd1; end
460  : begin div_out <= 12'd2158; bias <= 3'd2; end
461  : begin div_out <= 12'd2155; bias <= 3'd1; end
462  : begin div_out <= 12'd2153; bias <= 3'd1; end
463  : begin div_out <= 12'd2151; bias <= 3'd1; end
464  : begin div_out <= 12'd2149; bias <= 3'd1; end
465  : begin div_out <= 12'd2147; bias <= 3'd2; end
466  : begin div_out <= 12'd2144; bias <= 3'd1; end
467  : begin div_out <= 12'd2142; bias <= 3'd1; end
468  : begin div_out <= 12'd2140; bias <= 3'd1; end
469  : begin div_out <= 12'd2138; bias <= 3'd1; end
470  : begin div_out <= 12'd2136; bias <= 3'd1; end
471  : begin div_out <= 12'd2133; bias <= 3'd1; end
472  : begin div_out <= 12'd2131; bias <= 3'd1; end
473  : begin div_out <= 12'd2129; bias <= 3'd1; end
474  : begin div_out <= 12'd2127; bias <= 3'd1; end
475  : begin div_out <= 12'd2125; bias <= 3'd1; end
476  : begin div_out <= 12'd2123; bias <= 3'd1; end
477  : begin div_out <= 12'd2120; bias <= 3'd1; end
478  : begin div_out <= 12'd2118; bias <= 3'd1; end
479  : begin div_out <= 12'd2116; bias <= 3'd1; end
480  : begin div_out <= 12'd2114; bias <= 3'd1; end
481  : begin div_out <= 12'd2112; bias <= 3'd1; end
482  : begin div_out <= 12'd2110; bias <= 3'd1; end
483  : begin div_out <= 12'd2108; bias <= 3'd1; end
484  : begin div_out <= 12'd2106; bias <= 3'd1; end
485  : begin div_out <= 12'd2103; bias <= 3'd1; end
486  : begin div_out <= 12'd2101; bias <= 3'd1; end
487  : begin div_out <= 12'd2099; bias <= 3'd1; end
488  : begin div_out <= 12'd2097; bias <= 3'd1; end
489  : begin div_out <= 12'd2095; bias <= 3'd1; end
490  : begin div_out <= 12'd2093; bias <= 3'd1; end
491  : begin div_out <= 12'd2091; bias <= 3'd1; end
492  : begin div_out <= 12'd2089; bias <= 3'd1; end
493  : begin div_out <= 12'd2087; bias <= 3'd1; end
494  : begin div_out <= 12'd2085; bias <= 3'd1; end
495  : begin div_out <= 12'd2083; bias <= 3'd1; end
496  : begin div_out <= 12'd2081; bias <= 3'd2; end
497  : begin div_out <= 12'd2078; bias <= 3'd1; end
498  : begin div_out <= 12'd2076; bias <= 3'd1; end
499  : begin div_out <= 12'd2074; bias <= 3'd1; end
500  : begin div_out <= 12'd2072; bias <= 3'd1; end
501  : begin div_out <= 12'd2070; bias <= 3'd1; end
502  : begin div_out <= 12'd2068; bias <= 3'd1; end
503  : begin div_out <= 12'd2066; bias <= 3'd1; end
504  : begin div_out <= 12'd2064; bias <= 3'd1; end
505  : begin div_out <= 12'd2062; bias <= 3'd1; end
506  : begin div_out <= 12'd2060; bias <= 3'd1; end
507  : begin div_out <= 12'd2058; bias <= 3'd1; end
508  : begin div_out <= 12'd2056; bias <= 3'd1; end
509  : begin div_out <= 12'd2054; bias <= 3'd1; end
510  : begin div_out <= 12'd2052; bias <= 3'd1; end
511  : begin div_out <= 12'd2050; bias <= 3'd1; end
default : begin div_out <= 12'd0; bias <= 3'd1; end
endcase
end

endmodule


