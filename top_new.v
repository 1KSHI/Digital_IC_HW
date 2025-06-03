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
reg e_reg;
reg [3:0]  count;

wire init_end = (count == 4'd12) ? 1'b1 : 1'b0;
reg vld;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        count <= 0;
    end else if (!init_end) begin
        count <= count + 1;
    end else begin
        count <= 4'd12;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        vld <= 0;
    end else if (!init_end) begin
        vld <= 1;
    end else begin
        vld <= 0;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        e_reg <= 0;
    end else begin
        e_reg <= e;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        d_reg <= 0;
    end else if (vld) begin
        d_reg[11] <= e_reg;
        d_reg[10] <= d_reg[11];
        d_reg[9]  <= d_reg[10];
        d_reg[8]  <= d_reg[9];
        d_reg[7]  <= d_reg[8];
        d_reg[6]  <= d_reg[7];
        d_reg[5]  <= d_reg[6];
        d_reg[4]  <= d_reg[5];
        d_reg[3]  <= d_reg[4];
        d_reg[2]  <= d_reg[3];
        d_reg[1]  <= d_reg[2];
        d_reg[0]  <= d_reg[1];
    end else begin
        d_reg <= d_reg;
    end
end

//=========================== cycle 0 ============================
reg [11:0] Zeo_a_reg;//a
reg [11:0] Zeo_b_reg;//b
reg [11:0] Zeo_c_reg;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        Zeo_a_reg <= 0;
        Zeo_b_reg <= 0;
        Zeo_c_reg <= 0;
    end else begin
        Zeo_a_reg <= a;
        Zeo_b_reg <= b;
        Zeo_c_reg <= c;
    end
end

reg Zero_end_reg;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        Zero_end_reg <= 0;
    end else begin
        Zero_end_reg <= init_end;
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
    .x_in      (Zeo_a_reg           ),
    .y_in      (d_reg       ),
    .result_out(Fir_add_wire)
);


always @(posedge clk or posedge rst) begin
    if (rst) begin
        Fir_add_reg <= 0;
        Fir_a_reg <= 0;
        Fir_b_reg <= 0;
        Fir_c_reg <= 0;
    end else begin
        Fir_add_reg <= Fir_add_wire;
        Fir_a_reg <= Zeo_a_reg;
        Fir_b_reg <= Zeo_b_reg;
        Fir_c_reg <= Zeo_c_reg;
    end
end

reg Fir_end_reg;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        Fir_end_reg <= 0;
    end else begin
        Fir_end_reg <= Zero_end_reg;
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

CosRom CosRom (
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

always @(posedge clk or posedge rst) begin
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
always @(posedge clk or posedge rst) begin
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
always @(posedge clk or posedge rst) begin
    if (rst) begin
        Sec_sign_reg <= 0;
    end else begin
        Sec_sign_reg <= Sec_sign_wire;
    end
end

reg Sec_end_reg;
reg Thi_end_reg;
reg Fou_end_reg;
always @(posedge clk or posedge rst) begin
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

always @(posedge clk or posedge rst) begin
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

always @(posedge clk or posedge rst) begin
    if (rst) begin
        Fif_muldiv_reg <= 0;
    end else begin
        Fif_muldiv_reg <= Sec_sft_reg_wire[11:0];
    end
end

reg Fif_sign_reg;
reg Six_sign_reg;
always @(posedge clk or posedge rst) begin
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
always @(posedge clk or posedge rst) begin
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

always @(posedge clk or posedge rst) begin
    if (rst) begin
        Sev_mul_reg <= 0;
    end else begin
        Sev_mul_reg <= Sev_mul_wire[23:12];
    end
end

reg Sev_sign_reg;
reg Eig_sign_reg;
always @(posedge clk or posedge rst) begin
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
always @(posedge clk or posedge rst) begin
    if (rst) begin
        Sev_end_reg <= 0;
        Eig_end_reg <= 0;
    end else begin
        Sev_end_reg <= Six_end_reg;
        Eig_end_reg <= Sev_end_reg;
    end
end

assign y = {Eig_sign_reg,Sev_mul_reg};

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
wire [15:0] opa, opb;	// 32-bit operands
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

FullAdder	fir1fa7 ( pp[0][8],  pp[1][7],  pp[2][6],  Fir1_S[7],  Fir1_C[7]  );
FullAdder	fir1fa8 ( pp[0][9],  pp[1][8],  pp[2][7],  Fir1_S[8],  Fir1_C[8]  );
FullAdder	fir1fa9 ( pp[0][10], pp[1][9],  pp[2][8],  Fir1_S[9],  Fir1_C[9]  );
FullAdder	fir1fa10( pp[0][11], pp[1][10], pp[2][9],  Fir1_S[10], Fir1_C[10] );
HalfAdder	fir1ha11(            pp[1][11], pp[2][10], Fir1_S[11], Fir1_C[11] );

FullAdder	fir2fa4 ( pp[3][5],  pp[4][4],  pp[5][3],  Fir2_S[4],  Fir2_C[4]  );
FullAdder	fir2fa5 ( pp[3][6],  pp[4][5],  pp[5][4],  Fir2_S[5],  Fir2_C[5]  );
FullAdder	fir2fa6 ( pp[3][7],  pp[4][6],  pp[5][5],  Fir2_S[6],  Fir2_C[6]  );
FullAdder	fir2fa7 ( pp[3][8],  pp[4][7],  pp[5][6],  Fir2_S[7],  Fir2_C[7]  );
FullAdder	fir2fa8 ( pp[3][9],  pp[4][8],  pp[5][7],  Fir2_S[8],  Fir2_C[8]  );
FullAdder	fir2fa9 ( pp[3][10], pp[4][9],  pp[5][8],  Fir2_S[9],  Fir2_C[9]  );
FullAdder	fir2fa10( pp[3][11], pp[4][10], pp[5][9],  Fir2_S[10], Fir2_C[10] );
HalfAdder	fir2ha11(            pp[4][11], pp[5][10], Fir2_S[11], Fir2_C[11] );

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

FullAdder	sec1fa6 ( Fir1_S[7],  Fir1_C[6],  Fir2_S[4], Sec1_S[6],  Sec1_C[6]  );
FullAdder	sec1fa7 ( Fir1_S[8],  Fir1_C[7],  Fir2_S[5], Sec1_S[7],  Sec1_C[7]  );
FullAdder	sec1fa8 ( Fir1_S[9],  Fir1_C[8],  Fir2_S[6], Sec1_S[8],  Sec1_C[8]  );
FullAdder	sec1fa9 ( Fir1_S[10], Fir1_C[9],  Fir2_S[7], Sec1_S[9],  Sec1_C[9]  );
FullAdder	sec1fa10( Fir1_S[11], Fir1_C[10], Fir2_S[8], Sec1_S[10], Sec1_C[10] );
FullAdder	sec1fa11( pp[2][11],  Fir1_C[11], Fir2_S[9], Sec1_S[11], Sec1_C[11] );

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

assign	opa = { Thi2_C[13], Fif_S[17: 3]};
assign	opb = { Fif_C[17: 2]};

reg [15:0]opa_reg, opb_reg;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        opa_reg <= 0;
        opb_reg <= 0;
    end else begin
        opa_reg <= opa;
        opb_reg <= opb;
    end
end

wire [15:0] result_temp = opa_reg + opb_reg;

assign result_out = {result_temp,8'b0};


endmodule

module CosRom(
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

reg [2:0] offset;
reg[10:0] result_out;

assign res_out = zero_2?11'b0:cosadd_sel?(result_out-{8'b0,offset}):result_out;


always @(posedge clk) begin
    case(addr[9:1])
    0       : begin result_out <= 11'b111_1111_1111 ; end
    1       : begin result_out <= 11'b111_1111_1111 ; end
    2       : begin result_out <= 11'b111_1111_1111 ; end
    3       : begin result_out <= 11'b111_1111_1111 ; end
    4       : begin result_out <= 11'b111_1111_1111 ; end
    5       : begin result_out <= 11'b111_1111_1111 ; end
    6       : begin result_out <= 11'b111_1111_1111 ; end
    7       : begin result_out <= 11'b111_1111_1111 ; end
    8       : begin result_out <= 11'b111_1111_1111 ; end
    9       : begin result_out <= 11'b111_1111_1111 ; end
    10      : begin result_out <= 11'b111_1111_1111 ; end
    11      : begin result_out <= 11'b111_1111_1111 ; end
    12      : begin result_out <= 11'b111_1111_1111 ; end
    13      : begin result_out <= 11'b111_1111_1110 ; end
    14      : begin result_out <= 11'b111_1111_1110 ; end
    15      : begin result_out <= 11'b111_1111_1110 ; end
    16      : begin result_out <= 11'b111_1111_1110 ; end
    17      : begin result_out <= 11'b111_1111_1101 ; end
    18      : begin result_out <= 11'b111_1111_1101 ; end
    19      : begin result_out <= 11'b111_1111_1101 ; end
    20      : begin result_out <= 11'b111_1111_1100 ; end
    21      : begin result_out <= 11'b111_1111_1100 ; end
    22      : begin result_out <= 11'b111_1111_1011 ; end
    23      : begin result_out <= 11'b111_1111_1011 ; end
    24      : begin result_out <= 11'b111_1111_1010 ; end
    25      : begin result_out <= 11'b111_1111_1010 ; end
    26      : begin result_out <= 11'b111_1111_1001 ; end
    27      : begin result_out <= 11'b111_1111_1001 ; end
    28      : begin result_out <= 11'b111_1111_1000 ; end
    29      : begin result_out <= 11'b111_1111_1000 ; end
    30      : begin result_out <= 11'b111_1111_0111 ; end
    31      : begin result_out <= 11'b111_1111_0111 ; end
    32      : begin result_out <= 11'b111_1111_0110 ; end
    33      : begin result_out <= 11'b111_1111_0110 ; end
    34      : begin result_out <= 11'b111_1111_0101 ; end
    35      : begin result_out <= 11'b111_1111_0100 ; end
    36      : begin result_out <= 11'b111_1111_0100 ; end
    37      : begin result_out <= 11'b111_1111_0011 ; end
    38      : begin result_out <= 11'b111_1111_0010 ; end
    39      : begin result_out <= 11'b111_1111_0001 ; end
    40      : begin result_out <= 11'b111_1111_0001 ; end
    41      : begin result_out <= 11'b111_1111_0000 ; end
    42      : begin result_out <= 11'b111_1110_1111 ; end
    43      : begin result_out <= 11'b111_1110_1110 ; end
    44      : begin result_out <= 11'b111_1110_1101 ; end
    45      : begin result_out <= 11'b111_1110_1101 ; end
    46      : begin result_out <= 11'b111_1110_1100 ; end
    47      : begin result_out <= 11'b111_1110_1011 ; end
    48      : begin result_out <= 11'b111_1110_1010 ; end
    49      : begin result_out <= 11'b111_1110_1001 ; end
    50      : begin result_out <= 11'b111_1110_1000 ; end
    51      : begin result_out <= 11'b111_1110_0111 ; end
    52      : begin result_out <= 11'b111_1110_0110 ; end
    53      : begin result_out <= 11'b111_1110_0101 ; end
    54      : begin result_out <= 11'b111_1110_0100 ; end
    55      : begin result_out <= 11'b111_1110_0011 ; end
    56      : begin result_out <= 11'b111_1110_0010 ; end
    57      : begin result_out <= 11'b111_1110_0001 ; end
    58      : begin result_out <= 11'b111_1110_0000 ; end
    59      : begin result_out <= 11'b111_1101_1111 ; end
    60      : begin result_out <= 11'b111_1101_1101 ; end
    61      : begin result_out <= 11'b111_1101_1100 ; end
    62      : begin result_out <= 11'b111_1101_1011 ; end
    63      : begin result_out <= 11'b111_1101_1010 ; end
    64      : begin result_out <= 11'b111_1101_1001 ; end
    65      : begin result_out <= 11'b111_1101_0111 ; end
    66      : begin result_out <= 11'b111_1101_0110 ; end
    67      : begin result_out <= 11'b111_1101_0101 ; end
    68      : begin result_out <= 11'b111_1101_0100 ; end
    69      : begin result_out <= 11'b111_1101_0010 ; end
    70      : begin result_out <= 11'b111_1101_0001 ; end
    71      : begin result_out <= 11'b111_1101_0000 ; end
    72      : begin result_out <= 11'b111_1100_1110 ; end
    73      : begin result_out <= 11'b111_1100_1101 ; end
    74      : begin result_out <= 11'b111_1100_1011 ; end
    75      : begin result_out <= 11'b111_1100_1010 ; end
    76      : begin result_out <= 11'b111_1100_1001 ; end
    77      : begin result_out <= 11'b111_1100_0111 ; end
    78      : begin result_out <= 11'b111_1100_0110 ; end
    79      : begin result_out <= 11'b111_1100_0100 ; end
    80      : begin result_out <= 11'b111_1100_0011 ; end
    81      : begin result_out <= 11'b111_1100_0001 ; end
    82      : begin result_out <= 11'b111_1100_0000 ; end
    83      : begin result_out <= 11'b111_1011_1110 ; end
    84      : begin result_out <= 11'b111_1011_1100 ; end
    85      : begin result_out <= 11'b111_1011_1011 ; end
    86      : begin result_out <= 11'b111_1011_1001 ; end
    87      : begin result_out <= 11'b111_1011_0111 ; end
    88      : begin result_out <= 11'b111_1011_0110 ; end
    89      : begin result_out <= 11'b111_1011_0100 ; end
    90      : begin result_out <= 11'b111_1011_0010 ; end
    91      : begin result_out <= 11'b111_1011_0001 ; end
    92      : begin result_out <= 11'b111_1010_1111 ; end
    93      : begin result_out <= 11'b111_1010_1101 ; end
    94      : begin result_out <= 11'b111_1010_1011 ; end
    95      : begin result_out <= 11'b111_1010_1010 ; end
    96      : begin result_out <= 11'b111_1010_1000 ; end
    97      : begin result_out <= 11'b111_1010_0110 ; end
    98      : begin result_out <= 11'b111_1010_0100 ; end
    99      : begin result_out <= 11'b111_1010_0010 ; end
    100     : begin result_out <= 11'b111_1010_0000 ; end
    101     : begin result_out <= 11'b111_1001_1110 ; end
    102     : begin result_out <= 11'b111_1001_1101 ; end
    103     : begin result_out <= 11'b111_1001_1011 ; end
    104     : begin result_out <= 11'b111_1001_1001 ; end
    105     : begin result_out <= 11'b111_1001_0111 ; end
    106     : begin result_out <= 11'b111_1001_0101 ; end
    107     : begin result_out <= 11'b111_1001_0011 ; end
    108     : begin result_out <= 11'b111_1001_0001 ; end
    109     : begin result_out <= 11'b111_1000_1111 ; end
    110     : begin result_out <= 11'b111_1000_1100 ; end
    111     : begin result_out <= 11'b111_1000_1010 ; end
    112     : begin result_out <= 11'b111_1000_1000 ; end
    113     : begin result_out <= 11'b111_1000_0110 ; end
    114     : begin result_out <= 11'b111_1000_0100 ; end
    115     : begin result_out <= 11'b111_1000_0010 ; end
    116     : begin result_out <= 11'b111_1000_0000 ; end
    117     : begin result_out <= 11'b111_0111_1101 ; end
    118     : begin result_out <= 11'b111_0111_1011 ; end
    119     : begin result_out <= 11'b111_0111_1001 ; end
    120     : begin result_out <= 11'b111_0111_0111 ; end
    121     : begin result_out <= 11'b111_0111_0100 ; end
    122     : begin result_out <= 11'b111_0111_0010 ; end
    123     : begin result_out <= 11'b111_0111_0000 ; end
    124     : begin result_out <= 11'b111_0110_1110 ; end
    125     : begin result_out <= 11'b111_0110_1011 ; end
    126     : begin result_out <= 11'b111_0110_1001 ; end
    127     : begin result_out <= 11'b111_0110_0111 ; end
    128     : begin result_out <= 11'b111_0110_0100 ; end
    129     : begin result_out <= 11'b111_0110_0010 ; end
    130     : begin result_out <= 11'b111_0101_1111 ; end
    131     : begin result_out <= 11'b111_0101_1101 ; end
    132     : begin result_out <= 11'b111_0101_1010 ; end
    133     : begin result_out <= 11'b111_0101_1000 ; end
    134     : begin result_out <= 11'b111_0101_0101 ; end
    135     : begin result_out <= 11'b111_0101_0011 ; end
    136     : begin result_out <= 11'b111_0101_0000 ; end
    137     : begin result_out <= 11'b111_0100_1110 ; end
    138     : begin result_out <= 11'b111_0100_1011 ; end
    139     : begin result_out <= 11'b111_0100_1001 ; end
    140     : begin result_out <= 11'b111_0100_0110 ; end
    141     : begin result_out <= 11'b111_0100_0011 ; end
    142     : begin result_out <= 11'b111_0100_0001 ; end
    143     : begin result_out <= 11'b111_0011_1110 ; end
    144     : begin result_out <= 11'b111_0011_1011 ; end
    145     : begin result_out <= 11'b111_0011_1001 ; end
    146     : begin result_out <= 11'b111_0011_0110 ; end
    147     : begin result_out <= 11'b111_0011_0011 ; end
    148     : begin result_out <= 11'b111_0011_0000 ; end
    149     : begin result_out <= 11'b111_0010_1110 ; end
    150     : begin result_out <= 11'b111_0010_1011 ; end
    151     : begin result_out <= 11'b111_0010_1000 ; end
    152     : begin result_out <= 11'b111_0010_0101 ; end
    153     : begin result_out <= 11'b111_0010_0010 ; end
    154     : begin result_out <= 11'b111_0010_0000 ; end
    155     : begin result_out <= 11'b111_0001_1101 ; end
    156     : begin result_out <= 11'b111_0001_1010 ; end
    157     : begin result_out <= 11'b111_0001_0111 ; end
    158     : begin result_out <= 11'b111_0001_0100 ; end
    159     : begin result_out <= 11'b111_0001_0001 ; end
    160     : begin result_out <= 11'b111_0000_1110 ; end
    161     : begin result_out <= 11'b111_0000_1011 ; end
    162     : begin result_out <= 11'b111_0000_1000 ; end
    163     : begin result_out <= 11'b111_0000_0101 ; end
    164     : begin result_out <= 11'b111_0000_0010 ; end
    165     : begin result_out <= 11'b110_1111_1111 ; end
    166     : begin result_out <= 11'b110_1111_1100 ; end
    167     : begin result_out <= 11'b110_1111_1001 ; end
    168     : begin result_out <= 11'b110_1111_0110 ; end
    169     : begin result_out <= 11'b110_1111_0011 ; end
    170     : begin result_out <= 11'b110_1111_0000 ; end
    171     : begin result_out <= 11'b110_1110_1101 ; end
    172     : begin result_out <= 11'b110_1110_1001 ; end
    173     : begin result_out <= 11'b110_1110_0110 ; end
    174     : begin result_out <= 11'b110_1110_0011 ; end
    175     : begin result_out <= 11'b110_1110_0000 ; end
    176     : begin result_out <= 11'b110_1101_1101 ; end
    177     : begin result_out <= 11'b110_1101_1001 ; end
    178     : begin result_out <= 11'b110_1101_0110 ; end
    179     : begin result_out <= 11'b110_1101_0011 ; end
    180     : begin result_out <= 11'b110_1101_0000 ; end
    181     : begin result_out <= 11'b110_1100_1100 ; end
    182     : begin result_out <= 11'b110_1100_1001 ; end
    183     : begin result_out <= 11'b110_1100_0110 ; end
    184     : begin result_out <= 11'b110_1100_0010 ; end
    185     : begin result_out <= 11'b110_1011_1111 ; end
    186     : begin result_out <= 11'b110_1011_1100 ; end
    187     : begin result_out <= 11'b110_1011_1000 ; end
    188     : begin result_out <= 11'b110_1011_0101 ; end
    189     : begin result_out <= 11'b110_1011_0001 ; end
    190     : begin result_out <= 11'b110_1010_1110 ; end
    191     : begin result_out <= 11'b110_1010_1010 ; end
    192     : begin result_out <= 11'b110_1010_0111 ; end
    193     : begin result_out <= 11'b110_1010_0011 ; end
    194     : begin result_out <= 11'b110_1010_0000 ; end
    195     : begin result_out <= 11'b110_1001_1100 ; end
    196     : begin result_out <= 11'b110_1001_1001 ; end
    197     : begin result_out <= 11'b110_1001_0101 ; end
    198     : begin result_out <= 11'b110_1001_0010 ; end
    199     : begin result_out <= 11'b110_1000_1110 ; end
    200     : begin result_out <= 11'b110_1000_1010 ; end
    201     : begin result_out <= 11'b110_1000_0111 ; end
    202     : begin result_out <= 11'b110_1000_0011 ; end
    203     : begin result_out <= 11'b110_0111_1111 ; end
    204     : begin result_out <= 11'b110_0111_1100 ; end
    205     : begin result_out <= 11'b110_0111_1000 ; end
    206     : begin result_out <= 11'b110_0111_0100 ; end
    207     : begin result_out <= 11'b110_0111_0001 ; end
    208     : begin result_out <= 11'b110_0110_1101 ; end
    209     : begin result_out <= 11'b110_0110_1001 ; end
    210     : begin result_out <= 11'b110_0110_0101 ; end
    211     : begin result_out <= 11'b110_0110_0010 ; end
    212     : begin result_out <= 11'b110_0101_1110 ; end
    213     : begin result_out <= 11'b110_0101_1010 ; end
    214     : begin result_out <= 11'b110_0101_0110 ; end
    215     : begin result_out <= 11'b110_0101_0010 ; end
    216     : begin result_out <= 11'b110_0100_1111 ; end
    217     : begin result_out <= 11'b110_0100_1011 ; end
    218     : begin result_out <= 11'b110_0100_0111 ; end
    219     : begin result_out <= 11'b110_0100_0011 ; end
    220     : begin result_out <= 11'b110_0011_1111 ; end
    221     : begin result_out <= 11'b110_0011_1011 ; end
    222     : begin result_out <= 11'b110_0011_0111 ; end
    223     : begin result_out <= 11'b110_0011_0011 ; end
    224     : begin result_out <= 11'b110_0010_1111 ; end
    225     : begin result_out <= 11'b110_0010_1011 ; end
    226     : begin result_out <= 11'b110_0010_0111 ; end
    227     : begin result_out <= 11'b110_0010_0011 ; end
    228     : begin result_out <= 11'b110_0001_1111 ; end
    229     : begin result_out <= 11'b110_0001_1011 ; end
    230     : begin result_out <= 11'b110_0001_0111 ; end
    231     : begin result_out <= 11'b110_0001_0011 ; end
    232     : begin result_out <= 11'b110_0000_1111 ; end
    233     : begin result_out <= 11'b110_0000_1011 ; end
    234     : begin result_out <= 11'b110_0000_0111 ; end
    235     : begin result_out <= 11'b110_0000_0010 ; end
    236     : begin result_out <= 11'b101_1111_1110 ; end
    237     : begin result_out <= 11'b101_1111_1010 ; end
    238     : begin result_out <= 11'b101_1111_0110 ; end
    239     : begin result_out <= 11'b101_1111_0010 ; end
    240     : begin result_out <= 11'b101_1110_1101 ; end
    241     : begin result_out <= 11'b101_1110_1001 ; end
    242     : begin result_out <= 11'b101_1110_0101 ; end
    243     : begin result_out <= 11'b101_1110_0001 ; end
    244     : begin result_out <= 11'b101_1101_1100 ; end
    245     : begin result_out <= 11'b101_1101_1000 ; end
    246     : begin result_out <= 11'b101_1101_0100 ; end
    247     : begin result_out <= 11'b101_1101_0000 ; end
    248     : begin result_out <= 11'b101_1100_1011 ; end
    249     : begin result_out <= 11'b101_1100_0111 ; end
    250     : begin result_out <= 11'b101_1100_0011 ; end
    251     : begin result_out <= 11'b101_1011_1110 ; end
    252     : begin result_out <= 11'b101_1011_1010 ; end
    253     : begin result_out <= 11'b101_1011_0101 ; end
    254     : begin result_out <= 11'b101_1011_0001 ; end
    255     : begin result_out <= 11'b101_1010_1101 ; end
    256     : begin result_out <= 11'b101_1010_1000 ; end
    257     : begin result_out <= 11'b101_1010_0100 ; end
    258     : begin result_out <= 11'b101_1001_1111 ; end
    259     : begin result_out <= 11'b101_1001_1011 ; end
    260     : begin result_out <= 11'b101_1001_0110 ; end
    261     : begin result_out <= 11'b101_1001_0010 ; end
    262     : begin result_out <= 11'b101_1000_1101 ; end
    263     : begin result_out <= 11'b101_1000_1001 ; end
    264     : begin result_out <= 11'b101_1000_0100 ; end
    265     : begin result_out <= 11'b101_1000_0000 ; end
    266     : begin result_out <= 11'b101_0111_1011 ; end
    267     : begin result_out <= 11'b101_0111_0110 ; end
    268     : begin result_out <= 11'b101_0111_0010 ; end
    269     : begin result_out <= 11'b101_0110_1101 ; end
    270     : begin result_out <= 11'b101_0110_1001 ; end
    271     : begin result_out <= 11'b101_0110_0100 ; end
    272     : begin result_out <= 11'b101_0101_1111 ; end
    273     : begin result_out <= 11'b101_0101_1011 ; end
    274     : begin result_out <= 11'b101_0101_0110 ; end
    275     : begin result_out <= 11'b101_0101_0001 ; end
    276     : begin result_out <= 11'b101_0100_1101 ; end
    277     : begin result_out <= 11'b101_0100_1000 ; end
    278     : begin result_out <= 11'b101_0100_0011 ; end
    279     : begin result_out <= 11'b101_0011_1110 ; end
    280     : begin result_out <= 11'b101_0011_1010 ; end
    281     : begin result_out <= 11'b101_0011_0101 ; end
    282     : begin result_out <= 11'b101_0011_0000 ; end
    283     : begin result_out <= 11'b101_0010_1011 ; end
    284     : begin result_out <= 11'b101_0010_0111 ; end
    285     : begin result_out <= 11'b101_0010_0010 ; end
    286     : begin result_out <= 11'b101_0001_1101 ; end
    287     : begin result_out <= 11'b101_0001_1000 ; end
    288     : begin result_out <= 11'b101_0001_0011 ; end
    289     : begin result_out <= 11'b101_0000_1110 ; end
    290     : begin result_out <= 11'b101_0000_1001 ; end
    291     : begin result_out <= 11'b101_0000_0101 ; end
    292     : begin result_out <= 11'b101_0000_0000 ; end
    293     : begin result_out <= 11'b100_1111_1011 ; end
    294     : begin result_out <= 11'b100_1111_0110 ; end
    295     : begin result_out <= 11'b100_1111_0001 ; end
    296     : begin result_out <= 11'b100_1110_1100 ; end
    297     : begin result_out <= 11'b100_1110_0111 ; end
    298     : begin result_out <= 11'b100_1110_0010 ; end
    299     : begin result_out <= 11'b100_1101_1101 ; end
    300     : begin result_out <= 11'b100_1101_1000 ; end
    301     : begin result_out <= 11'b100_1101_0011 ; end
    302     : begin result_out <= 11'b100_1100_1110 ; end
    303     : begin result_out <= 11'b100_1100_1001 ; end
    304     : begin result_out <= 11'b100_1100_0100 ; end
    305     : begin result_out <= 11'b100_1011_1111 ; end
    306     : begin result_out <= 11'b100_1011_1010 ; end
    307     : begin result_out <= 11'b100_1011_0101 ; end
    308     : begin result_out <= 11'b100_1011_0000 ; end
    309     : begin result_out <= 11'b100_1010_1011 ; end
    310     : begin result_out <= 11'b100_1010_0110 ; end
    311     : begin result_out <= 11'b100_1010_0000 ; end
    312     : begin result_out <= 11'b100_1001_1011 ; end
    313     : begin result_out <= 11'b100_1001_0110 ; end
    314     : begin result_out <= 11'b100_1001_0001 ; end
    315     : begin result_out <= 11'b100_1000_1100 ; end
    316     : begin result_out <= 11'b100_1000_0111 ; end
    317     : begin result_out <= 11'b100_1000_0001 ; end
    318     : begin result_out <= 11'b100_0111_1100 ; end
    319     : begin result_out <= 11'b100_0111_0111 ; end
    320     : begin result_out <= 11'b100_0111_0010 ; end
    321     : begin result_out <= 11'b100_0110_1101 ; end
    322     : begin result_out <= 11'b100_0110_0111 ; end
    323     : begin result_out <= 11'b100_0110_0010 ; end
    324     : begin result_out <= 11'b100_0101_1101 ; end
    325     : begin result_out <= 11'b100_0101_1000 ; end
    326     : begin result_out <= 11'b100_0101_0010 ; end
    327     : begin result_out <= 11'b100_0100_1101 ; end
    328     : begin result_out <= 11'b100_0100_1000 ; end
    329     : begin result_out <= 11'b100_0100_0010 ; end
    330     : begin result_out <= 11'b100_0011_1101 ; end
    331     : begin result_out <= 11'b100_0011_1000 ; end
    332     : begin result_out <= 11'b100_0011_0010 ; end
    333     : begin result_out <= 11'b100_0010_1101 ; end
    334     : begin result_out <= 11'b100_0010_1000 ; end
    335     : begin result_out <= 11'b100_0010_0010 ; end
    336     : begin result_out <= 11'b100_0001_1101 ; end
    337     : begin result_out <= 11'b100_0001_0111 ; end
    338     : begin result_out <= 11'b100_0001_0010 ; end
    339     : begin result_out <= 11'b100_0000_1101 ; end
    340     : begin result_out <= 11'b100_0000_0111 ; end
    341     : begin result_out <= 11'b100_0000_0010 ; end
    342     : begin result_out <= 11'b011_1111_1100 ; end
    343     : begin result_out <= 11'b011_1111_0111 ; end
    344     : begin result_out <= 11'b011_1111_0001 ; end
    345     : begin result_out <= 11'b011_1110_1100 ; end
    346     : begin result_out <= 11'b011_1110_0111 ; end
    347     : begin result_out <= 11'b011_1110_0001 ; end
    348     : begin result_out <= 11'b011_1101_1100 ; end
    349     : begin result_out <= 11'b011_1101_0110 ; end
    350     : begin result_out <= 11'b011_1101_0000 ; end
    351     : begin result_out <= 11'b011_1100_1011 ; end
    352     : begin result_out <= 11'b011_1100_0101 ; end
    353     : begin result_out <= 11'b011_1100_0000 ; end
    354     : begin result_out <= 11'b011_1011_1010 ; end
    355     : begin result_out <= 11'b011_1011_0101 ; end
    356     : begin result_out <= 11'b011_1010_1111 ; end
    357     : begin result_out <= 11'b011_1010_1010 ; end
    358     : begin result_out <= 11'b011_1010_0100 ; end
    359     : begin result_out <= 11'b011_1001_1110 ; end
    360     : begin result_out <= 11'b011_1001_1001 ; end
    361     : begin result_out <= 11'b011_1001_0011 ; end
    362     : begin result_out <= 11'b011_1000_1110 ; end
    363     : begin result_out <= 11'b011_1000_1000 ; end
    364     : begin result_out <= 11'b011_1000_0010 ; end
    365     : begin result_out <= 11'b011_0111_1101 ; end
    366     : begin result_out <= 11'b011_0111_0111 ; end
    367     : begin result_out <= 11'b011_0111_0001 ; end
    368     : begin result_out <= 11'b011_0110_1100 ; end
    369     : begin result_out <= 11'b011_0110_0110 ; end
    370     : begin result_out <= 11'b011_0110_0000 ; end
    371     : begin result_out <= 11'b011_0101_1011 ; end
    372     : begin result_out <= 11'b011_0101_0101 ; end
    373     : begin result_out <= 11'b011_0100_1111 ; end
    374     : begin result_out <= 11'b011_0100_1001 ; end
    375     : begin result_out <= 11'b011_0100_0100 ; end
    376     : begin result_out <= 11'b011_0011_1110 ; end
    377     : begin result_out <= 11'b011_0011_1000 ; end
    378     : begin result_out <= 11'b011_0011_0010 ; end
    379     : begin result_out <= 11'b011_0010_1101 ; end
    380     : begin result_out <= 11'b011_0010_0111 ; end
    381     : begin result_out <= 11'b011_0010_0001 ; end
    382     : begin result_out <= 11'b011_0001_1011 ; end
    383     : begin result_out <= 11'b011_0001_0110 ; end
    384     : begin result_out <= 11'b011_0001_0000 ; end
    385     : begin result_out <= 11'b011_0000_1010 ; end
    386     : begin result_out <= 11'b011_0000_0100 ; end
    387     : begin result_out <= 11'b010_1111_1110 ; end
    388     : begin result_out <= 11'b010_1111_1000 ; end
    389     : begin result_out <= 11'b010_1111_0011 ; end
    390     : begin result_out <= 11'b010_1110_1101 ; end
    391     : begin result_out <= 11'b010_1110_0111 ; end
    392     : begin result_out <= 11'b010_1110_0001 ; end
    393     : begin result_out <= 11'b010_1101_1011 ; end
    394     : begin result_out <= 11'b010_1101_0101 ; end
    395     : begin result_out <= 11'b010_1100_1111 ; end
    396     : begin result_out <= 11'b010_1100_1010 ; end
    397     : begin result_out <= 11'b010_1100_0100 ; end
    398     : begin result_out <= 11'b010_1011_1110 ; end
    399     : begin result_out <= 11'b010_1011_1000 ; end
    400     : begin result_out <= 11'b010_1011_0010 ; end
    401     : begin result_out <= 11'b010_1010_1100 ; end
    402     : begin result_out <= 11'b010_1010_0110 ; end
    403     : begin result_out <= 11'b010_1010_0000 ; end
    404     : begin result_out <= 11'b010_1001_1010 ; end
    405     : begin result_out <= 11'b010_1001_0100 ; end
    406     : begin result_out <= 11'b010_1000_1110 ; end
    407     : begin result_out <= 11'b010_1000_1000 ; end
    408     : begin result_out <= 11'b010_1000_0010 ; end
    409     : begin result_out <= 11'b010_0111_1100 ; end
    410     : begin result_out <= 11'b010_0111_0110 ; end
    411     : begin result_out <= 11'b010_0111_0000 ; end
    412     : begin result_out <= 11'b010_0110_1011 ; end
    413     : begin result_out <= 11'b010_0110_0101 ; end
    414     : begin result_out <= 11'b010_0101_1111 ; end
    415     : begin result_out <= 11'b010_0101_1001 ; end
    416     : begin result_out <= 11'b010_0101_0011 ; end
    417     : begin result_out <= 11'b010_0100_1100 ; end
    418     : begin result_out <= 11'b010_0100_0110 ; end
    419     : begin result_out <= 11'b010_0100_0000 ; end
    420     : begin result_out <= 11'b010_0011_1010 ; end
    421     : begin result_out <= 11'b010_0011_0100 ; end
    422     : begin result_out <= 11'b010_0010_1110 ; end
    423     : begin result_out <= 11'b010_0010_1000 ; end
    424     : begin result_out <= 11'b010_0010_0010 ; end
    425     : begin result_out <= 11'b010_0001_1100 ; end
    426     : begin result_out <= 11'b010_0001_0110 ; end
    427     : begin result_out <= 11'b010_0001_0000 ; end
    428     : begin result_out <= 11'b010_0000_1010 ; end
    429     : begin result_out <= 11'b010_0000_0100 ; end
    430     : begin result_out <= 11'b001_1111_1110 ; end
    431     : begin result_out <= 11'b001_1111_1000 ; end
    432     : begin result_out <= 11'b001_1111_0010 ; end
    433     : begin result_out <= 11'b001_1110_1100 ; end
    434     : begin result_out <= 11'b001_1110_0101 ; end
    435     : begin result_out <= 11'b001_1101_1111 ; end
    436     : begin result_out <= 11'b001_1101_1001 ; end
    437     : begin result_out <= 11'b001_1101_0011 ; end
    438     : begin result_out <= 11'b001_1100_1101 ; end
    439     : begin result_out <= 11'b001_1100_0111 ; end
    440     : begin result_out <= 11'b001_1100_0001 ; end
    441     : begin result_out <= 11'b001_1011_1011 ; end
    442     : begin result_out <= 11'b001_1011_0100 ; end
    443     : begin result_out <= 11'b001_1010_1110 ; end
    444     : begin result_out <= 11'b001_1010_1000 ; end
    445     : begin result_out <= 11'b001_1010_0010 ; end
    446     : begin result_out <= 11'b001_1001_1100 ; end
    447     : begin result_out <= 11'b001_1001_0110 ; end
    448     : begin result_out <= 11'b001_1001_0000 ; end
    449     : begin result_out <= 11'b001_1000_1001 ; end
    450     : begin result_out <= 11'b001_1000_0011 ; end
    451     : begin result_out <= 11'b001_0111_1101 ; end
    452     : begin result_out <= 11'b001_0111_0111 ; end
    453     : begin result_out <= 11'b001_0111_0001 ; end
    454     : begin result_out <= 11'b001_0110_1011 ; end
    455     : begin result_out <= 11'b001_0110_0100 ; end
    456     : begin result_out <= 11'b001_0101_1110 ; end
    457     : begin result_out <= 11'b001_0101_1000 ; end
    458     : begin result_out <= 11'b001_0101_0010 ; end
    459     : begin result_out <= 11'b001_0100_1100 ; end
    460     : begin result_out <= 11'b001_0100_0101 ; end
    461     : begin result_out <= 11'b001_0011_1111 ; end
    462     : begin result_out <= 11'b001_0011_1001 ; end
    463     : begin result_out <= 11'b001_0011_0011 ; end
    464     : begin result_out <= 11'b001_0010_1101 ; end
    465     : begin result_out <= 11'b001_0010_0110 ; end
    466     : begin result_out <= 11'b001_0010_0000 ; end
    467     : begin result_out <= 11'b001_0001_1010 ; end
    468     : begin result_out <= 11'b001_0001_0100 ; end
    469     : begin result_out <= 11'b001_0000_1101 ; end
    470     : begin result_out <= 11'b001_0000_0111 ; end
    471     : begin result_out <= 11'b001_0000_0001 ; end
    472     : begin result_out <= 11'b000_1111_1011 ; end
    473     : begin result_out <= 11'b000_1111_0100 ; end
    474     : begin result_out <= 11'b000_1110_1110 ; end
    475     : begin result_out <= 11'b000_1110_1000 ; end
    476     : begin result_out <= 11'b000_1110_0010 ; end
    477     : begin result_out <= 11'b000_1101_1011 ; end
    478     : begin result_out <= 11'b000_1101_0101 ; end
    479     : begin result_out <= 11'b000_1100_1111 ; end
    480     : begin result_out <= 11'b000_1100_1001 ; end
    481     : begin result_out <= 11'b000_1100_0010 ; end
    482     : begin result_out <= 11'b000_1011_1100 ; end
    483     : begin result_out <= 11'b000_1011_0110 ; end
    484     : begin result_out <= 11'b000_1011_0000 ; end
    485     : begin result_out <= 11'b000_1010_1001 ; end
    486     : begin result_out <= 11'b000_1010_0011 ; end
    487     : begin result_out <= 11'b000_1001_1101 ; end
    488     : begin result_out <= 11'b000_1001_0111 ; end
    489     : begin result_out <= 11'b000_1001_0000 ; end
    490     : begin result_out <= 11'b000_1000_1010 ; end
    491     : begin result_out <= 11'b000_1000_0100 ; end
    492     : begin result_out <= 11'b000_0111_1110 ; end
    493     : begin result_out <= 11'b000_0111_0111 ; end
    494     : begin result_out <= 11'b000_0111_0001 ; end
    495     : begin result_out <= 11'b000_0110_1011 ; end
    496     : begin result_out <= 11'b000_0110_0100 ; end
    497     : begin result_out <= 11'b000_0101_1110 ; end
    498     : begin result_out <= 11'b000_0101_1000 ; end
    499     : begin result_out <= 11'b000_0101_0010 ; end
    500     : begin result_out <= 11'b000_0100_1011 ; end
    501     : begin result_out <= 11'b000_0100_0101 ; end
    502     : begin result_out <= 11'b000_0011_1111 ; end
    503     : begin result_out <= 11'b000_0011_1001 ; end
    504     : begin result_out <= 11'b000_0011_0010 ; end
    505     : begin result_out <= 11'b000_0010_1100 ; end
    506     : begin result_out <= 11'b000_0010_0110 ; end
    507     : begin result_out <= 11'b000_0001_1111 ; end
    508     : begin result_out <= 11'b000_0001_1001 ; end
    509     : begin result_out <= 11'b000_0001_0011 ; end
    510     : begin result_out <= 11'b000_0000_1101 ; end
    511     : begin result_out <= 11'b000_0000_0110 ; end
    default : begin result_out <= 11'b000_0000_0000 ; end
    endcase
end

always @(posedge clk) begin
    case(addr[9:1])
    0       : begin offset <= 3'b000  ;end
    1       : begin offset <= 3'b000  ;end
    2       : begin offset <= 3'b000  ;end
    3       : begin offset <= 3'b000  ;end
    4       : begin offset <= 3'b000  ;end
    5       : begin offset <= 3'b000  ;end
    6       : begin offset <= 3'b000  ;end
    7       : begin offset <= 3'b000  ;end
    8       : begin offset <= 3'b000  ;end
    9       : begin offset <= 3'b000  ;end
    10      : begin offset <= 3'b000  ;end
    11      : begin offset <= 3'b000  ;end
    12      : begin offset <= 3'b001  ;end
    13      : begin offset <= 3'b000  ;end
    14      : begin offset <= 3'b000  ;end
    15      : begin offset <= 3'b000  ;end
    16      : begin offset <= 3'b001  ;end
    17      : begin offset <= 3'b000  ;end
    18      : begin offset <= 3'b000  ;end
    19      : begin offset <= 3'b001  ;end
    20      : begin offset <= 3'b000  ;end
    21      : begin offset <= 3'b000  ;end
    22      : begin offset <= 3'b000  ;end
    23      : begin offset <= 3'b000  ;end
    24      : begin offset <= 3'b000  ;end
    25      : begin offset <= 3'b000  ;end
    26      : begin offset <= 3'b000  ;end
    27      : begin offset <= 3'b000  ;end
    28      : begin offset <= 3'b000  ;end
    29      : begin offset <= 3'b000  ;end
    30      : begin offset <= 3'b000  ;end
    31      : begin offset <= 3'b001  ;end
    32      : begin offset <= 3'b000  ;end
    33      : begin offset <= 3'b001  ;end
    34      : begin offset <= 3'b000  ;end
    35      : begin offset <= 3'b000  ;end
    36      : begin offset <= 3'b001  ;end
    37      : begin offset <= 3'b001  ;end
    38      : begin offset <= 3'b000  ;end
    39      : begin offset <= 3'b000  ;end
    40      : begin offset <= 3'b001  ;end
    41      : begin offset <= 3'b001  ;end
    42      : begin offset <= 3'b000  ;end
    43      : begin offset <= 3'b000  ;end
    44      : begin offset <= 3'b000  ;end
    45      : begin offset <= 3'b001  ;end
    46      : begin offset <= 3'b001  ;end
    47      : begin offset <= 3'b001  ;end
    48      : begin offset <= 3'b001  ;end
    49      : begin offset <= 3'b001  ;end
    50      : begin offset <= 3'b001  ;end
    51      : begin offset <= 3'b001  ;end
    52      : begin offset <= 3'b001  ;end
    53      : begin offset <= 3'b001  ;end
    54      : begin offset <= 3'b001  ;end
    55      : begin offset <= 3'b001  ;end
    56      : begin offset <= 3'b001  ;end
    57      : begin offset <= 3'b001  ;end
    58      : begin offset <= 3'b001  ;end
    59      : begin offset <= 3'b001  ;end
    60      : begin offset <= 3'b000  ;end
    61      : begin offset <= 3'b000  ;end
    62      : begin offset <= 3'b001  ;end
    63      : begin offset <= 3'b001  ;end
    64      : begin offset <= 3'b001  ;end
    65      : begin offset <= 3'b000  ;end
    66      : begin offset <= 3'b000  ;end
    67      : begin offset <= 3'b001  ;end
    68      : begin offset <= 3'b001  ;end
    69      : begin offset <= 3'b000  ;end
    70      : begin offset <= 3'b001  ;end
    71      : begin offset <= 3'b001  ;end
    72      : begin offset <= 3'b000  ;end
    73      : begin offset <= 3'b001  ;end
    74      : begin offset <= 3'b000  ;end
    75      : begin offset <= 3'b001  ;end
    76      : begin offset <= 3'b001  ;end
    77      : begin offset <= 3'b001  ;end
    78      : begin offset <= 3'b001  ;end
    79      : begin offset <= 3'b001  ;end
    80      : begin offset <= 3'b001  ;end
    81      : begin offset <= 3'b001  ;end
    82      : begin offset <= 3'b001  ;end
    83      : begin offset <= 3'b001  ;end
    84      : begin offset <= 3'b000  ;end
    85      : begin offset <= 3'b001  ;end
    86      : begin offset <= 3'b001  ;end
    87      : begin offset <= 3'b000  ;end
    88      : begin offset <= 3'b001  ;end
    89      : begin offset <= 3'b001  ;end
    90      : begin offset <= 3'b000  ;end
    91      : begin offset <= 3'b001  ;end
    92      : begin offset <= 3'b001  ;end
    93      : begin offset <= 3'b001  ;end
    94      : begin offset <= 3'b000  ;end
    95      : begin offset <= 3'b001  ;end
    96      : begin offset <= 3'b001  ;end
    97      : begin offset <= 3'b001  ;end
    98      : begin offset <= 3'b001  ;end
    99      : begin offset <= 3'b001  ;end
    100     : begin offset <= 3'b001  ;end
    101     : begin offset <= 3'b000  ;end
    102     : begin offset <= 3'b001  ;end
    103     : begin offset <= 3'b001  ;end
    104     : begin offset <= 3'b001  ;end
    105     : begin offset <= 3'b001  ;end
    106     : begin offset <= 3'b001  ;end
    107     : begin offset <= 3'b001  ;end
    108     : begin offset <= 3'b001  ;end
    109     : begin offset <= 3'b001  ;end
    110     : begin offset <= 3'b001  ;end
    111     : begin offset <= 3'b001  ;end
    112     : begin offset <= 3'b001  ;end
    113     : begin offset <= 3'b001  ;end
    114     : begin offset <= 3'b001  ;end
    115     : begin offset <= 3'b001  ;end
    116     : begin offset <= 3'b001  ;end
    117     : begin offset <= 3'b001  ;end
    118     : begin offset <= 3'b001  ;end
    119     : begin offset <= 3'b001  ;end
    120     : begin offset <= 3'b001  ;end
    121     : begin offset <= 3'b001  ;end
    122     : begin offset <= 3'b001  ;end
    123     : begin offset <= 3'b001  ;end
    124     : begin offset <= 3'b010  ;end
    125     : begin offset <= 3'b001  ;end
    126     : begin offset <= 3'b001  ;end
    127     : begin offset <= 3'b010  ;end
    128     : begin offset <= 3'b001  ;end
    129     : begin offset <= 3'b010  ;end
    130     : begin offset <= 3'b001  ;end
    131     : begin offset <= 3'b001  ;end
    132     : begin offset <= 3'b001  ;end
    133     : begin offset <= 3'b001  ;end
    134     : begin offset <= 3'b001  ;end
    135     : begin offset <= 3'b001  ;end
    136     : begin offset <= 3'b001  ;end
    137     : begin offset <= 3'b010  ;end
    138     : begin offset <= 3'b001  ;end
    139     : begin offset <= 3'b010  ;end
    140     : begin offset <= 3'b001  ;end
    141     : begin offset <= 3'b001  ;end
    142     : begin offset <= 3'b010  ;end
    143     : begin offset <= 3'b001  ;end
    144     : begin offset <= 3'b001  ;end
    145     : begin offset <= 3'b010  ;end
    146     : begin offset <= 3'b001  ;end
    147     : begin offset <= 3'b001  ;end
    148     : begin offset <= 3'b001  ;end
    149     : begin offset <= 3'b010  ;end
    150     : begin offset <= 3'b001  ;end
    151     : begin offset <= 3'b001  ;end
    152     : begin offset <= 3'b001  ;end
    153     : begin offset <= 3'b001  ;end
    154     : begin offset <= 3'b010  ;end
    155     : begin offset <= 3'b010  ;end
    156     : begin offset <= 3'b010  ;end
    157     : begin offset <= 3'b001  ;end
    158     : begin offset <= 3'b001  ;end
    159     : begin offset <= 3'b001  ;end
    160     : begin offset <= 3'b001  ;end
    161     : begin offset <= 3'b001  ;end
    162     : begin offset <= 3'b001  ;end
    163     : begin offset <= 3'b001  ;end
    164     : begin offset <= 3'b001  ;end
    165     : begin offset <= 3'b001  ;end
    166     : begin offset <= 3'b001  ;end
    167     : begin offset <= 3'b010  ;end
    168     : begin offset <= 3'b010  ;end
    169     : begin offset <= 3'b010  ;end
    170     : begin offset <= 3'b010  ;end
    171     : begin offset <= 3'b010  ;end
    172     : begin offset <= 3'b001  ;end
    173     : begin offset <= 3'b001  ;end
    174     : begin offset <= 3'b010  ;end
    175     : begin offset <= 3'b010  ;end
    176     : begin offset <= 3'b010  ;end
    177     : begin offset <= 3'b001  ;end
    178     : begin offset <= 3'b001  ;end
    179     : begin offset <= 3'b010  ;end
    180     : begin offset <= 3'b010  ;end
    181     : begin offset <= 3'b001  ;end
    182     : begin offset <= 3'b010  ;end
    183     : begin offset <= 3'b010  ;end
    184     : begin offset <= 3'b001  ;end
    185     : begin offset <= 3'b010  ;end
    186     : begin offset <= 3'b010  ;end
    187     : begin offset <= 3'b010  ;end
    188     : begin offset <= 3'b010  ;end
    189     : begin offset <= 3'b001  ;end
    190     : begin offset <= 3'b010  ;end
    191     : begin offset <= 3'b001  ;end
    192     : begin offset <= 3'b010  ;end
    193     : begin offset <= 3'b001  ;end
    194     : begin offset <= 3'b010  ;end
    195     : begin offset <= 3'b001  ;end
    196     : begin offset <= 3'b010  ;end
    197     : begin offset <= 3'b010  ;end
    198     : begin offset <= 3'b010  ;end
    199     : begin offset <= 3'b010  ;end
    200     : begin offset <= 3'b001  ;end
    201     : begin offset <= 3'b010  ;end
    202     : begin offset <= 3'b010  ;end
    203     : begin offset <= 3'b001  ;end
    204     : begin offset <= 3'b010  ;end
    205     : begin offset <= 3'b010  ;end
    206     : begin offset <= 3'b001  ;end
    207     : begin offset <= 3'b010  ;end
    208     : begin offset <= 3'b010  ;end
    209     : begin offset <= 3'b010  ;end
    210     : begin offset <= 3'b001  ;end
    211     : begin offset <= 3'b010  ;end
    212     : begin offset <= 3'b010  ;end
    213     : begin offset <= 3'b010  ;end
    214     : begin offset <= 3'b010  ;end
    215     : begin offset <= 3'b010  ;end
    216     : begin offset <= 3'b010  ;end
    217     : begin offset <= 3'b010  ;end
    218     : begin offset <= 3'b010  ;end
    219     : begin offset <= 3'b010  ;end
    220     : begin offset <= 3'b010  ;end
    221     : begin offset <= 3'b010  ;end
    222     : begin offset <= 3'b010  ;end
    223     : begin offset <= 3'b010  ;end
    224     : begin offset <= 3'b010  ;end
    225     : begin offset <= 3'b010  ;end
    226     : begin offset <= 3'b010  ;end
    227     : begin offset <= 3'b010  ;end
    228     : begin offset <= 3'b010  ;end
    229     : begin offset <= 3'b010  ;end
    230     : begin offset <= 3'b010  ;end
    231     : begin offset <= 3'b010  ;end
    232     : begin offset <= 3'b010  ;end
    233     : begin offset <= 3'b010  ;end
    234     : begin offset <= 3'b011  ;end
    235     : begin offset <= 3'b010  ;end
    236     : begin offset <= 3'b010  ;end
    237     : begin offset <= 3'b010  ;end
    238     : begin offset <= 3'b010  ;end
    239     : begin offset <= 3'b010  ;end
    240     : begin offset <= 3'b010  ;end
    241     : begin offset <= 3'b010  ;end
    242     : begin offset <= 3'b010  ;end
    243     : begin offset <= 3'b010  ;end
    244     : begin offset <= 3'b010  ;end
    245     : begin offset <= 3'b010  ;end
    246     : begin offset <= 3'b010  ;end
    247     : begin offset <= 3'b011  ;end
    248     : begin offset <= 3'b010  ;end
    249     : begin offset <= 3'b010  ;end
    250     : begin offset <= 3'b011  ;end
    251     : begin offset <= 3'b010  ;end
    252     : begin offset <= 3'b010  ;end
    253     : begin offset <= 3'b010  ;end
    254     : begin offset <= 3'b010  ;end
    255     : begin offset <= 3'b011  ;end
    256     : begin offset <= 3'b010  ;end
    257     : begin offset <= 3'b011  ;end
    258     : begin offset <= 3'b010  ;end
    259     : begin offset <= 3'b010  ;end
    260     : begin offset <= 3'b010  ;end
    261     : begin offset <= 3'b010  ;end
    262     : begin offset <= 3'b010  ;end
    263     : begin offset <= 3'b011  ;end
    264     : begin offset <= 3'b010  ;end
    265     : begin offset <= 3'b011  ;end
    266     : begin offset <= 3'b010  ;end
    267     : begin offset <= 3'b010  ;end
    268     : begin offset <= 3'b010  ;end
    269     : begin offset <= 3'b010  ;end
    270     : begin offset <= 3'b011  ;end
    271     : begin offset <= 3'b010  ;end
    272     : begin offset <= 3'b010  ;end
    273     : begin offset <= 3'b011  ;end
    274     : begin offset <= 3'b010  ;end
    275     : begin offset <= 3'b010  ;end
    276     : begin offset <= 3'b011  ;end
    277     : begin offset <= 3'b010  ;end
    278     : begin offset <= 3'b010  ;end
    279     : begin offset <= 3'b010  ;end
    280     : begin offset <= 3'b011  ;end
    281     : begin offset <= 3'b010  ;end
    282     : begin offset <= 3'b010  ;end
    283     : begin offset <= 3'b010  ;end
    284     : begin offset <= 3'b011  ;end
    285     : begin offset <= 3'b011  ;end
    286     : begin offset <= 3'b010  ;end
    287     : begin offset <= 3'b010  ;end
    288     : begin offset <= 3'b010  ;end
    289     : begin offset <= 3'b010  ;end
    290     : begin offset <= 3'b010  ;end
    291     : begin offset <= 3'b011  ;end
    292     : begin offset <= 3'b011  ;end
    293     : begin offset <= 3'b011  ;end
    294     : begin offset <= 3'b011  ;end
    295     : begin offset <= 3'b011  ;end
    296     : begin offset <= 3'b010  ;end
    297     : begin offset <= 3'b010  ;end
    298     : begin offset <= 3'b010  ;end
    299     : begin offset <= 3'b010  ;end
    300     : begin offset <= 3'b010  ;end
    301     : begin offset <= 3'b010  ;end
    302     : begin offset <= 3'b010  ;end
    303     : begin offset <= 3'b010  ;end
    304     : begin offset <= 3'b011  ;end
    305     : begin offset <= 3'b011  ;end
    306     : begin offset <= 3'b011  ;end
    307     : begin offset <= 3'b011  ;end
    308     : begin offset <= 3'b011  ;end
    309     : begin offset <= 3'b011  ;end
    310     : begin offset <= 3'b011  ;end
    311     : begin offset <= 3'b010  ;end
    312     : begin offset <= 3'b010  ;end
    313     : begin offset <= 3'b010  ;end
    314     : begin offset <= 3'b011  ;end
    315     : begin offset <= 3'b011  ;end
    316     : begin offset <= 3'b011  ;end
    317     : begin offset <= 3'b010  ;end
    318     : begin offset <= 3'b010  ;end
    319     : begin offset <= 3'b011  ;end
    320     : begin offset <= 3'b011  ;end
    321     : begin offset <= 3'b011  ;end
    322     : begin offset <= 3'b010  ;end
    323     : begin offset <= 3'b011  ;end
    324     : begin offset <= 3'b011  ;end
    325     : begin offset <= 3'b011  ;end
    326     : begin offset <= 3'b010  ;end
    327     : begin offset <= 3'b011  ;end
    328     : begin offset <= 3'b011  ;end
    329     : begin offset <= 3'b010  ;end
    330     : begin offset <= 3'b011  ;end
    331     : begin offset <= 3'b011  ;end
    332     : begin offset <= 3'b010  ;end
    333     : begin offset <= 3'b011  ;end
    334     : begin offset <= 3'b011  ;end
    335     : begin offset <= 3'b010  ;end
    336     : begin offset <= 3'b011  ;end
    337     : begin offset <= 3'b010  ;end
    338     : begin offset <= 3'b011  ;end
    339     : begin offset <= 3'b011  ;end
    340     : begin offset <= 3'b010  ;end
    341     : begin offset <= 3'b011  ;end
    342     : begin offset <= 3'b010  ;end
    343     : begin offset <= 3'b011  ;end
    344     : begin offset <= 3'b010  ;end
    345     : begin offset <= 3'b011  ;end
    346     : begin offset <= 3'b011  ;end
    347     : begin offset <= 3'b011  ;end
    348     : begin offset <= 3'b011  ;end
    349     : begin offset <= 3'b011  ;end
    350     : begin offset <= 3'b010  ;end
    351     : begin offset <= 3'b011  ;end
    352     : begin offset <= 3'b010  ;end
    353     : begin offset <= 3'b011  ;end
    354     : begin offset <= 3'b010  ;end
    355     : begin offset <= 3'b011  ;end
    356     : begin offset <= 3'b011  ;end
    357     : begin offset <= 3'b011  ;end
    358     : begin offset <= 3'b011  ;end
    359     : begin offset <= 3'b010  ;end
    360     : begin offset <= 3'b011  ;end
    361     : begin offset <= 3'b011  ;end
    362     : begin offset <= 3'b011  ;end
    363     : begin offset <= 3'b011  ;end
    364     : begin offset <= 3'b011  ;end
    365     : begin offset <= 3'b011  ;end
    366     : begin offset <= 3'b011  ;end
    367     : begin offset <= 3'b011  ;end
    368     : begin offset <= 3'b011  ;end
    369     : begin offset <= 3'b011  ;end
    370     : begin offset <= 3'b011  ;end
    371     : begin offset <= 3'b011  ;end
    372     : begin offset <= 3'b011  ;end
    373     : begin offset <= 3'b011  ;end
    374     : begin offset <= 3'b010  ;end
    375     : begin offset <= 3'b011  ;end
    376     : begin offset <= 3'b011  ;end
    377     : begin offset <= 3'b011  ;end
    378     : begin offset <= 3'b010  ;end
    379     : begin offset <= 3'b011  ;end
    380     : begin offset <= 3'b011  ;end
    381     : begin offset <= 3'b011  ;end
    382     : begin offset <= 3'b011  ;end
    383     : begin offset <= 3'b011  ;end
    384     : begin offset <= 3'b011  ;end
    385     : begin offset <= 3'b011  ;end
    386     : begin offset <= 3'b011  ;end
    387     : begin offset <= 3'b011  ;end
    388     : begin offset <= 3'b010  ;end
    389     : begin offset <= 3'b011  ;end
    390     : begin offset <= 3'b011  ;end
    391     : begin offset <= 3'b011  ;end
    392     : begin offset <= 3'b011  ;end
    393     : begin offset <= 3'b011  ;end
    394     : begin offset <= 3'b011  ;end
    395     : begin offset <= 3'b010  ;end
    396     : begin offset <= 3'b011  ;end
    397     : begin offset <= 3'b011  ;end
    398     : begin offset <= 3'b011  ;end
    399     : begin offset <= 3'b011  ;end
    400     : begin offset <= 3'b011  ;end
    401     : begin offset <= 3'b011  ;end
    402     : begin offset <= 3'b011  ;end
    403     : begin offset <= 3'b011  ;end
    404     : begin offset <= 3'b011  ;end
    405     : begin offset <= 3'b011  ;end
    406     : begin offset <= 3'b011  ;end
    407     : begin offset <= 3'b011  ;end
    408     : begin offset <= 3'b011  ;end
    409     : begin offset <= 3'b011  ;end
    410     : begin offset <= 3'b011  ;end
    411     : begin offset <= 3'b010  ;end
    412     : begin offset <= 3'b011  ;end
    413     : begin offset <= 3'b011  ;end
    414     : begin offset <= 3'b011  ;end
    415     : begin offset <= 3'b011  ;end
    416     : begin offset <= 3'b100  ;end
    417     : begin offset <= 3'b011  ;end
    418     : begin offset <= 3'b011  ;end
    419     : begin offset <= 3'b011  ;end
    420     : begin offset <= 3'b011  ;end
    421     : begin offset <= 3'b011  ;end
    422     : begin offset <= 3'b011  ;end
    423     : begin offset <= 3'b011  ;end
    424     : begin offset <= 3'b011  ;end
    425     : begin offset <= 3'b011  ;end
    426     : begin offset <= 3'b011  ;end
    427     : begin offset <= 3'b011  ;end
    428     : begin offset <= 3'b011  ;end
    429     : begin offset <= 3'b011  ;end
    430     : begin offset <= 3'b011  ;end
    431     : begin offset <= 3'b011  ;end
    432     : begin offset <= 3'b011  ;end
    433     : begin offset <= 3'b100  ;end
    434     : begin offset <= 3'b011  ;end
    435     : begin offset <= 3'b011  ;end
    436     : begin offset <= 3'b011  ;end
    437     : begin offset <= 3'b011  ;end
    438     : begin offset <= 3'b011  ;end
    439     : begin offset <= 3'b011  ;end
    440     : begin offset <= 3'b011  ;end
    441     : begin offset <= 3'b011  ;end
    442     : begin offset <= 3'b011  ;end
    443     : begin offset <= 3'b011  ;end
    444     : begin offset <= 3'b011  ;end
    445     : begin offset <= 3'b011  ;end
    446     : begin offset <= 3'b011  ;end
    447     : begin offset <= 3'b011  ;end
    448     : begin offset <= 3'b100  ;end
    449     : begin offset <= 3'b011  ;end
    450     : begin offset <= 3'b011  ;end
    451     : begin offset <= 3'b011  ;end
    452     : begin offset <= 3'b011  ;end
    453     : begin offset <= 3'b011  ;end
    454     : begin offset <= 3'b100  ;end
    455     : begin offset <= 3'b011  ;end
    456     : begin offset <= 3'b011  ;end
    457     : begin offset <= 3'b011  ;end
    458     : begin offset <= 3'b011  ;end
    459     : begin offset <= 3'b100  ;end
    460     : begin offset <= 3'b011  ;end
    461     : begin offset <= 3'b011  ;end
    462     : begin offset <= 3'b011  ;end
    463     : begin offset <= 3'b011  ;end
    464     : begin offset <= 3'b100  ;end
    465     : begin offset <= 3'b011  ;end
    466     : begin offset <= 3'b011  ;end
    467     : begin offset <= 3'b011  ;end
    468     : begin offset <= 3'b011  ;end
    469     : begin offset <= 3'b011  ;end
    470     : begin offset <= 3'b011  ;end
    471     : begin offset <= 3'b011  ;end
    472     : begin offset <= 3'b011  ;end
    473     : begin offset <= 3'b011  ;end
    474     : begin offset <= 3'b011  ;end
    475     : begin offset <= 3'b011  ;end
    476     : begin offset <= 3'b011  ;end
    477     : begin offset <= 3'b011  ;end
    478     : begin offset <= 3'b011  ;end
    479     : begin offset <= 3'b011  ;end
    480     : begin offset <= 3'b011  ;end
    481     : begin offset <= 3'b011  ;end
    482     : begin offset <= 3'b011  ;end
    483     : begin offset <= 3'b011  ;end
    484     : begin offset <= 3'b011  ;end
    485     : begin offset <= 3'b011  ;end
    486     : begin offset <= 3'b011  ;end
    487     : begin offset <= 3'b011  ;end
    488     : begin offset <= 3'b011  ;end
    489     : begin offset <= 3'b011  ;end
    490     : begin offset <= 3'b011  ;end
    491     : begin offset <= 3'b011  ;end
    492     : begin offset <= 3'b100  ;end
    493     : begin offset <= 3'b011  ;end
    494     : begin offset <= 3'b011  ;end
    495     : begin offset <= 3'b011  ;end
    496     : begin offset <= 3'b011  ;end
    497     : begin offset <= 3'b011  ;end
    498     : begin offset <= 3'b011  ;end
    499     : begin offset <= 3'b011  ;end
    500     : begin offset <= 3'b011  ;end
    501     : begin offset <= 3'b011  ;end
    502     : begin offset <= 3'b011  ;end
    503     : begin offset <= 3'b100  ;end
    504     : begin offset <= 3'b011  ;end
    505     : begin offset <= 3'b011  ;end
    506     : begin offset <= 3'b011  ;end
    507     : begin offset <= 3'b011  ;end
    508     : begin offset <= 3'b011  ;end
    509     : begin offset <= 3'b011  ;end
    510     : begin offset <= 3'b100  ;end
    511     : begin offset <= 3'b011  ;end
    default : begin offset <= 3'b000  ;end
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
        13'b000000000000?:begin sft_reg_1 <= 4'b0000; div_in <= 10'b0             ; end
        13'b000000000001?:begin sft_reg_1 <= 4'b0001; div_in <= {add_in[0]  ,9'b0}; end
        13'b00000000001??:begin sft_reg_1 <= 4'b0010; div_in <= {add_in[1:0],8'b0}; end
        13'b0000000001???:begin sft_reg_1 <= 4'b0011; div_in <= {add_in[2:0],7'b0}; end
        13'b000000001????:begin sft_reg_1 <= 4'b0100; div_in <= {add_in[3:0],6'b0}; end
        13'b00000001?????:begin sft_reg_1 <= 4'b0101; div_in <= {add_in[4:0],5'b0}; end
        13'b0000001??????:begin sft_reg_1 <= 4'b0110; div_in <= {add_in[5:0],4'b0}; end
        13'b000001???????:begin sft_reg_1 <= 4'b0111; div_in <= {add_in[6:0],3'b0}; end
        13'b00001????????:begin sft_reg_1 <= 4'b1000; div_in <= {add_in[7:0],2'b0}; end
        13'b0001?????????:begin sft_reg_1 <= 4'b1001; div_in <= {add_in[8:0],1'b0}; end
        13'b001??????????:begin sft_reg_1 <= 4'b1010; div_in <= add_in[9:0]       ; end
        13'b01???????????:begin sft_reg_1 <= 4'b1011; div_in <= add_in[10:1]      ; end
        13'b1????????????:begin sft_reg_1 <= 4'b1100; div_in <= add_in[11:2]      ; end
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
reg [11:0] result_out;
reg [2:0] offset;

assign div = divadd_sel?result_out-{8'b0,offset}:result_out;
assign sft_reg = sft_reg_2;

//======================  table  =========================
always @(posedge clk) begin
    case(div_in[9:1])
    0       : begin result_out <= 12'b1111_1111_1111;end
    1       : begin result_out <= 12'b1111_1111_1000;end
    2       : begin result_out <= 12'b1111_1111_0000;end
    3       : begin result_out <= 12'b1111_1110_1000;end
    4       : begin result_out <= 12'b1111_1110_0000;end
    5       : begin result_out <= 12'b1111_1101_1000;end
    6       : begin result_out <= 12'b1111_1101_0001;end
    7       : begin result_out <= 12'b1111_1100_1001;end
    8       : begin result_out <= 12'b1111_1100_0001;end
    9       : begin result_out <= 12'b1111_1011_1001;end
    10      : begin result_out <= 12'b1111_1011_0010;end
    11      : begin result_out <= 12'b1111_1010_1010;end
    12      : begin result_out <= 12'b1111_1010_0010;end
    13      : begin result_out <= 12'b1111_1001_1011;end
    14      : begin result_out <= 12'b1111_1001_0011;end
    15      : begin result_out <= 12'b1111_1000_1011;end
    16      : begin result_out <= 12'b1111_1000_0100;end
    17      : begin result_out <= 12'b1111_0111_1100;end
    18      : begin result_out <= 12'b1111_0111_0101;end
    19      : begin result_out <= 12'b1111_0110_1101;end
    20      : begin result_out <= 12'b1111_0110_0110;end
    21      : begin result_out <= 12'b1111_0101_1111;end
    22      : begin result_out <= 12'b1111_0101_0111;end
    23      : begin result_out <= 12'b1111_0101_0000;end
    24      : begin result_out <= 12'b1111_0100_1001;end
    25      : begin result_out <= 12'b1111_0100_0001;end
    26      : begin result_out <= 12'b1111_0011_1010;end
    27      : begin result_out <= 12'b1111_0011_0011;end
    28      : begin result_out <= 12'b1111_0010_1100;end
    29      : begin result_out <= 12'b1111_0010_0100;end
    30      : begin result_out <= 12'b1111_0001_1101;end
    31      : begin result_out <= 12'b1111_0001_0110;end
    32      : begin result_out <= 12'b1111_0000_1111;end
    33      : begin result_out <= 12'b1111_0000_1000;end
    34      : begin result_out <= 12'b1111_0000_0001;end
    35      : begin result_out <= 12'b1110_1111_1010;end
    36      : begin result_out <= 12'b1110_1111_0011;end
    37      : begin result_out <= 12'b1110_1110_1100;end
    38      : begin result_out <= 12'b1110_1110_0101;end
    39      : begin result_out <= 12'b1110_1101_1110;end
    40      : begin result_out <= 12'b1110_1101_0111;end
    41      : begin result_out <= 12'b1110_1101_0000;end
    42      : begin result_out <= 12'b1110_1100_1001;end
    43      : begin result_out <= 12'b1110_1100_0011;end
    44      : begin result_out <= 12'b1110_1011_1100;end
    45      : begin result_out <= 12'b1110_1011_0101;end
    46      : begin result_out <= 12'b1110_1010_1110;end
    47      : begin result_out <= 12'b1110_1010_1000;end
    48      : begin result_out <= 12'b1110_1010_0001;end
    49      : begin result_out <= 12'b1110_1001_1010;end
    50      : begin result_out <= 12'b1110_1001_0100;end
    51      : begin result_out <= 12'b1110_1000_1101;end
    52      : begin result_out <= 12'b1110_1000_0110;end
    53      : begin result_out <= 12'b1110_1000_0000;end
    54      : begin result_out <= 12'b1110_0111_1001;end
    55      : begin result_out <= 12'b1110_0111_0011;end
    56      : begin result_out <= 12'b1110_0110_1100;end
    57      : begin result_out <= 12'b1110_0110_0110;end
    58      : begin result_out <= 12'b1110_0101_1111;end
    59      : begin result_out <= 12'b1110_0101_1001;end
    60      : begin result_out <= 12'b1110_0101_0010;end
    61      : begin result_out <= 12'b1110_0100_1100;end
    62      : begin result_out <= 12'b1110_0100_0110;end
    63      : begin result_out <= 12'b1110_0011_1111;end
    64      : begin result_out <= 12'b1110_0011_1001;end
    65      : begin result_out <= 12'b1110_0011_0011;end
    66      : begin result_out <= 12'b1110_0010_1100;end
    67      : begin result_out <= 12'b1110_0010_0110;end
    68      : begin result_out <= 12'b1110_0010_0000;end
    69      : begin result_out <= 12'b1110_0001_1010;end
    70      : begin result_out <= 12'b1110_0001_0011;end
    71      : begin result_out <= 12'b1110_0000_1101;end
    72      : begin result_out <= 12'b1110_0000_0111;end
    73      : begin result_out <= 12'b1110_0000_0001;end
    74      : begin result_out <= 12'b1101_1111_1011;end
    75      : begin result_out <= 12'b1101_1111_0101;end
    76      : begin result_out <= 12'b1101_1110_1111;end
    77      : begin result_out <= 12'b1101_1110_1001;end
    78      : begin result_out <= 12'b1101_1110_0010;end
    79      : begin result_out <= 12'b1101_1101_1100;end
    80      : begin result_out <= 12'b1101_1101_0110;end
    81      : begin result_out <= 12'b1101_1101_0001;end
    82      : begin result_out <= 12'b1101_1100_1011;end
    83      : begin result_out <= 12'b1101_1100_0101;end
    84      : begin result_out <= 12'b1101_1011_1111;end
    85      : begin result_out <= 12'b1101_1011_1001;end
    86      : begin result_out <= 12'b1101_1011_0011;end
    87      : begin result_out <= 12'b1101_1010_1101;end
    88      : begin result_out <= 12'b1101_1010_0111;end
    89      : begin result_out <= 12'b1101_1010_0001;end
    90      : begin result_out <= 12'b1101_1001_1100;end
    91      : begin result_out <= 12'b1101_1001_0110;end
    92      : begin result_out <= 12'b1101_1001_0000;end
    93      : begin result_out <= 12'b1101_1000_1010;end
    94      : begin result_out <= 12'b1101_1000_0101;end
    95      : begin result_out <= 12'b1101_0111_1111;end
    96      : begin result_out <= 12'b1101_0111_1001;end
    97      : begin result_out <= 12'b1101_0111_0100;end
    98      : begin result_out <= 12'b1101_0110_1110;end
    99      : begin result_out <= 12'b1101_0110_1000;end
    100     : begin result_out <= 12'b1101_0110_0011;end
    101     : begin result_out <= 12'b1101_0101_1101;end
    102     : begin result_out <= 12'b1101_0101_1000;end
    103     : begin result_out <= 12'b1101_0101_0010;end
    104     : begin result_out <= 12'b1101_0100_1100;end
    105     : begin result_out <= 12'b1101_0100_0111;end
    106     : begin result_out <= 12'b1101_0100_0001;end
    107     : begin result_out <= 12'b1101_0011_1100;end
    108     : begin result_out <= 12'b1101_0011_0111;end
    109     : begin result_out <= 12'b1101_0011_0001;end
    110     : begin result_out <= 12'b1101_0010_1100;end
    111     : begin result_out <= 12'b1101_0010_0110;end
    112     : begin result_out <= 12'b1101_0010_0001;end
    113     : begin result_out <= 12'b1101_0001_1011;end
    114     : begin result_out <= 12'b1101_0001_0110;end
    115     : begin result_out <= 12'b1101_0001_0001;end
    116     : begin result_out <= 12'b1101_0000_1011;end
    117     : begin result_out <= 12'b1101_0000_0110;end
    118     : begin result_out <= 12'b1101_0000_0001;end
    119     : begin result_out <= 12'b1100_1111_1100;end
    120     : begin result_out <= 12'b1100_1111_0110;end
    121     : begin result_out <= 12'b1100_1111_0001;end
    122     : begin result_out <= 12'b1100_1110_1100;end
    123     : begin result_out <= 12'b1100_1110_0111;end
    124     : begin result_out <= 12'b1100_1110_0001;end
    125     : begin result_out <= 12'b1100_1101_1100;end
    126     : begin result_out <= 12'b1100_1101_0111;end
    127     : begin result_out <= 12'b1100_1101_0010;end
    128     : begin result_out <= 12'b1100_1100_1101;end
    129     : begin result_out <= 12'b1100_1100_1000;end
    130     : begin result_out <= 12'b1100_1100_0011;end
    131     : begin result_out <= 12'b1100_1011_1110;end
    132     : begin result_out <= 12'b1100_1011_1000;end
    133     : begin result_out <= 12'b1100_1011_0011;end
    134     : begin result_out <= 12'b1100_1010_1110;end
    135     : begin result_out <= 12'b1100_1010_1001;end
    136     : begin result_out <= 12'b1100_1010_0100;end
    137     : begin result_out <= 12'b1100_1001_1111;end
    138     : begin result_out <= 12'b1100_1001_1010;end
    139     : begin result_out <= 12'b1100_1001_0101;end
    140     : begin result_out <= 12'b1100_1001_0000;end
    141     : begin result_out <= 12'b1100_1000_1100;end
    142     : begin result_out <= 12'b1100_1000_0111;end
    143     : begin result_out <= 12'b1100_1000_0010;end
    144     : begin result_out <= 12'b1100_0111_1101;end
    145     : begin result_out <= 12'b1100_0111_1000;end
    146     : begin result_out <= 12'b1100_0111_0011;end
    147     : begin result_out <= 12'b1100_0110_1110;end
    148     : begin result_out <= 12'b1100_0110_1010;end
    149     : begin result_out <= 12'b1100_0110_0101;end
    150     : begin result_out <= 12'b1100_0110_0000;end
    151     : begin result_out <= 12'b1100_0101_1011;end
    152     : begin result_out <= 12'b1100_0101_0110;end
    153     : begin result_out <= 12'b1100_0101_0010;end
    154     : begin result_out <= 12'b1100_0100_1101;end
    155     : begin result_out <= 12'b1100_0100_1000;end
    156     : begin result_out <= 12'b1100_0100_0011;end
    157     : begin result_out <= 12'b1100_0011_1111;end
    158     : begin result_out <= 12'b1100_0011_1010;end
    159     : begin result_out <= 12'b1100_0011_0101;end
    160     : begin result_out <= 12'b1100_0011_0001;end
    161     : begin result_out <= 12'b1100_0010_1100;end
    162     : begin result_out <= 12'b1100_0010_1000;end
    163     : begin result_out <= 12'b1100_0010_0011;end
    164     : begin result_out <= 12'b1100_0001_1110;end
    165     : begin result_out <= 12'b1100_0001_1010;end
    166     : begin result_out <= 12'b1100_0001_0101;end
    167     : begin result_out <= 12'b1100_0001_0001;end
    168     : begin result_out <= 12'b1100_0000_1100;end
    169     : begin result_out <= 12'b1100_0000_1000;end
    170     : begin result_out <= 12'b1100_0000_0011;end
    171     : begin result_out <= 12'b1011_1111_1111;end
    172     : begin result_out <= 12'b1011_1111_1010;end
    173     : begin result_out <= 12'b1011_1111_0110;end
    174     : begin result_out <= 12'b1011_1111_0001;end
    175     : begin result_out <= 12'b1011_1110_1101;end
    176     : begin result_out <= 12'b1011_1110_1000;end
    177     : begin result_out <= 12'b1011_1110_0100;end
    178     : begin result_out <= 12'b1011_1101_1111;end
    179     : begin result_out <= 12'b1011_1101_1011;end
    180     : begin result_out <= 12'b1011_1101_0111;end
    181     : begin result_out <= 12'b1011_1101_0010;end
    182     : begin result_out <= 12'b1011_1100_1110;end
    183     : begin result_out <= 12'b1011_1100_1001;end
    184     : begin result_out <= 12'b1011_1100_0101;end
    185     : begin result_out <= 12'b1011_1100_0001;end
    186     : begin result_out <= 12'b1011_1011_1101;end
    187     : begin result_out <= 12'b1011_1011_1000;end
    188     : begin result_out <= 12'b1011_1011_0100;end
    189     : begin result_out <= 12'b1011_1011_0000;end
    190     : begin result_out <= 12'b1011_1010_1011;end
    191     : begin result_out <= 12'b1011_1010_0111;end
    192     : begin result_out <= 12'b1011_1010_0011;end
    193     : begin result_out <= 12'b1011_1001_1111;end
    194     : begin result_out <= 12'b1011_1001_1010;end
    195     : begin result_out <= 12'b1011_1001_0110;end
    196     : begin result_out <= 12'b1011_1001_0010;end
    197     : begin result_out <= 12'b1011_1000_1110;end
    198     : begin result_out <= 12'b1011_1000_1010;end
    199     : begin result_out <= 12'b1011_1000_0110;end
    200     : begin result_out <= 12'b1011_1000_0001;end
    201     : begin result_out <= 12'b1011_0111_1101;end
    202     : begin result_out <= 12'b1011_0111_1001;end
    203     : begin result_out <= 12'b1011_0111_0101;end
    204     : begin result_out <= 12'b1011_0111_0001;end
    205     : begin result_out <= 12'b1011_0110_1101;end
    206     : begin result_out <= 12'b1011_0110_1001;end
    207     : begin result_out <= 12'b1011_0110_0101;end
    208     : begin result_out <= 12'b1011_0110_0001;end
    209     : begin result_out <= 12'b1011_0101_1101;end
    210     : begin result_out <= 12'b1011_0101_1001;end
    211     : begin result_out <= 12'b1011_0101_0101;end
    212     : begin result_out <= 12'b1011_0101_0001;end
    213     : begin result_out <= 12'b1011_0100_1101;end
    214     : begin result_out <= 12'b1011_0100_1001;end
    215     : begin result_out <= 12'b1011_0100_0101;end
    216     : begin result_out <= 12'b1011_0100_0001;end
    217     : begin result_out <= 12'b1011_0011_1101;end
    218     : begin result_out <= 12'b1011_0011_1001;end
    219     : begin result_out <= 12'b1011_0011_0101;end
    220     : begin result_out <= 12'b1011_0011_0001;end
    221     : begin result_out <= 12'b1011_0010_1101;end
    222     : begin result_out <= 12'b1011_0010_1001;end
    223     : begin result_out <= 12'b1011_0010_0101;end
    224     : begin result_out <= 12'b1011_0010_0001;end
    225     : begin result_out <= 12'b1011_0001_1110;end
    226     : begin result_out <= 12'b1011_0001_1010;end
    227     : begin result_out <= 12'b1011_0001_0110;end
    228     : begin result_out <= 12'b1011_0001_0010;end
    229     : begin result_out <= 12'b1011_0000_1110;end
    230     : begin result_out <= 12'b1011_0000_1010;end
    231     : begin result_out <= 12'b1011_0000_0111;end
    232     : begin result_out <= 12'b1011_0000_0011;end
    233     : begin result_out <= 12'b1010_1111_1111;end
    234     : begin result_out <= 12'b1010_1111_1011;end
    235     : begin result_out <= 12'b1010_1111_0111;end
    236     : begin result_out <= 12'b1010_1111_0100;end
    237     : begin result_out <= 12'b1010_1111_0000;end
    238     : begin result_out <= 12'b1010_1110_1100;end
    239     : begin result_out <= 12'b1010_1110_1000;end
    240     : begin result_out <= 12'b1010_1110_0101;end
    241     : begin result_out <= 12'b1010_1110_0001;end
    242     : begin result_out <= 12'b1010_1101_1101;end
    243     : begin result_out <= 12'b1010_1101_1010;end
    244     : begin result_out <= 12'b1010_1101_0110;end
    245     : begin result_out <= 12'b1010_1101_0010;end
    246     : begin result_out <= 12'b1010_1100_1111;end
    247     : begin result_out <= 12'b1010_1100_1011;end
    248     : begin result_out <= 12'b1010_1100_0111;end
    249     : begin result_out <= 12'b1010_1100_0100;end
    250     : begin result_out <= 12'b1010_1100_0000;end
    251     : begin result_out <= 12'b1010_1011_1101;end
    252     : begin result_out <= 12'b1010_1011_1001;end
    253     : begin result_out <= 12'b1010_1011_0101;end
    254     : begin result_out <= 12'b1010_1011_0010;end
    255     : begin result_out <= 12'b1010_1010_1110;end
    256     : begin result_out <= 12'b1010_1010_1011;end
    257     : begin result_out <= 12'b1010_1010_0111;end
    258     : begin result_out <= 12'b1010_1010_0100;end
    259     : begin result_out <= 12'b1010_1010_0000;end
    260     : begin result_out <= 12'b1010_1001_1101;end
    261     : begin result_out <= 12'b1010_1001_1001;end
    262     : begin result_out <= 12'b1010_1001_0101;end
    263     : begin result_out <= 12'b1010_1001_0010;end
    264     : begin result_out <= 12'b1010_1000_1111;end
    265     : begin result_out <= 12'b1010_1000_1011;end
    266     : begin result_out <= 12'b1010_1000_1000;end
    267     : begin result_out <= 12'b1010_1000_0100;end
    268     : begin result_out <= 12'b1010_1000_0001;end
    269     : begin result_out <= 12'b1010_0111_1101;end
    270     : begin result_out <= 12'b1010_0111_1010;end
    271     : begin result_out <= 12'b1010_0111_0110;end
    272     : begin result_out <= 12'b1010_0111_0011;end
    273     : begin result_out <= 12'b1010_0111_0000;end
    274     : begin result_out <= 12'b1010_0110_1100;end
    275     : begin result_out <= 12'b1010_0110_1001;end
    276     : begin result_out <= 12'b1010_0110_0101;end
    277     : begin result_out <= 12'b1010_0110_0010;end
    278     : begin result_out <= 12'b1010_0101_1111;end
    279     : begin result_out <= 12'b1010_0101_1011;end
    280     : begin result_out <= 12'b1010_0101_1000;end
    281     : begin result_out <= 12'b1010_0101_0101;end
    282     : begin result_out <= 12'b1010_0101_0001;end
    283     : begin result_out <= 12'b1010_0100_1110;end
    284     : begin result_out <= 12'b1010_0100_1011;end
    285     : begin result_out <= 12'b1010_0100_0111;end
    286     : begin result_out <= 12'b1010_0100_0100;end
    287     : begin result_out <= 12'b1010_0100_0001;end
    288     : begin result_out <= 12'b1010_0011_1101;end
    289     : begin result_out <= 12'b1010_0011_1010;end
    290     : begin result_out <= 12'b1010_0011_0111;end
    291     : begin result_out <= 12'b1010_0011_0100;end
    292     : begin result_out <= 12'b1010_0011_0000;end
    293     : begin result_out <= 12'b1010_0010_1101;end
    294     : begin result_out <= 12'b1010_0010_1010;end
    295     : begin result_out <= 12'b1010_0010_0111;end
    296     : begin result_out <= 12'b1010_0010_0011;end
    297     : begin result_out <= 12'b1010_0010_0000;end
    298     : begin result_out <= 12'b1010_0001_1101;end
    299     : begin result_out <= 12'b1010_0001_1010;end
    300     : begin result_out <= 12'b1010_0001_0111;end
    301     : begin result_out <= 12'b1010_0001_0100;end
    302     : begin result_out <= 12'b1010_0001_0000;end
    303     : begin result_out <= 12'b1010_0000_1101;end
    304     : begin result_out <= 12'b1010_0000_1010;end
    305     : begin result_out <= 12'b1010_0000_0111;end
    306     : begin result_out <= 12'b1010_0000_0100;end
    307     : begin result_out <= 12'b1010_0000_0001;end
    308     : begin result_out <= 12'b1001_1111_1110;end
    309     : begin result_out <= 12'b1001_1111_1010;end
    310     : begin result_out <= 12'b1001_1111_0111;end
    311     : begin result_out <= 12'b1001_1111_0100;end
    312     : begin result_out <= 12'b1001_1111_0001;end
    313     : begin result_out <= 12'b1001_1110_1110;end
    314     : begin result_out <= 12'b1001_1110_1011;end
    315     : begin result_out <= 12'b1001_1110_1000;end
    316     : begin result_out <= 12'b1001_1110_0101;end
    317     : begin result_out <= 12'b1001_1110_0010;end
    318     : begin result_out <= 12'b1001_1101_1111;end
    319     : begin result_out <= 12'b1001_1101_1100;end
    320     : begin result_out <= 12'b1001_1101_1001;end
    321     : begin result_out <= 12'b1001_1101_0110;end
    322     : begin result_out <= 12'b1001_1101_0011;end
    323     : begin result_out <= 12'b1001_1101_0000;end
    324     : begin result_out <= 12'b1001_1100_1101;end
    325     : begin result_out <= 12'b1001_1100_1010;end
    326     : begin result_out <= 12'b1001_1100_0111;end
    327     : begin result_out <= 12'b1001_1100_0100;end
    328     : begin result_out <= 12'b1001_1100_0001;end
    329     : begin result_out <= 12'b1001_1011_1110;end
    330     : begin result_out <= 12'b1001_1011_1011;end
    331     : begin result_out <= 12'b1001_1011_1000;end
    332     : begin result_out <= 12'b1001_1011_0101;end
    333     : begin result_out <= 12'b1001_1011_0010;end
    334     : begin result_out <= 12'b1001_1010_1111;end
    335     : begin result_out <= 12'b1001_1010_1100;end
    336     : begin result_out <= 12'b1001_1010_1001;end
    337     : begin result_out <= 12'b1001_1010_0110;end
    338     : begin result_out <= 12'b1001_1010_0011;end
    339     : begin result_out <= 12'b1001_1010_0000;end
    340     : begin result_out <= 12'b1001_1001_1101;end
    341     : begin result_out <= 12'b1001_1001_1011;end
    342     : begin result_out <= 12'b1001_1001_1000;end
    343     : begin result_out <= 12'b1001_1001_0101;end
    344     : begin result_out <= 12'b1001_1001_0010;end
    345     : begin result_out <= 12'b1001_1000_1111;end
    346     : begin result_out <= 12'b1001_1000_1100;end
    347     : begin result_out <= 12'b1001_1000_1001;end
    348     : begin result_out <= 12'b1001_1000_0111;end
    349     : begin result_out <= 12'b1001_1000_0100;end
    350     : begin result_out <= 12'b1001_1000_0001;end
    351     : begin result_out <= 12'b1001_0111_1110;end
    352     : begin result_out <= 12'b1001_0111_1011;end
    353     : begin result_out <= 12'b1001_0111_1000;end
    354     : begin result_out <= 12'b1001_0111_0110;end
    355     : begin result_out <= 12'b1001_0111_0011;end
    356     : begin result_out <= 12'b1001_0111_0000;end
    357     : begin result_out <= 12'b1001_0110_1101;end
    358     : begin result_out <= 12'b1001_0110_1011;end
    359     : begin result_out <= 12'b1001_0110_1000;end
    360     : begin result_out <= 12'b1001_0110_0101;end
    361     : begin result_out <= 12'b1001_0110_0010;end
    362     : begin result_out <= 12'b1001_0101_1111;end
    363     : begin result_out <= 12'b1001_0101_1101;end
    364     : begin result_out <= 12'b1001_0101_1010;end
    365     : begin result_out <= 12'b1001_0101_0111;end
    366     : begin result_out <= 12'b1001_0101_0101;end
    367     : begin result_out <= 12'b1001_0101_0010;end
    368     : begin result_out <= 12'b1001_0100_1111;end
    369     : begin result_out <= 12'b1001_0100_1100;end
    370     : begin result_out <= 12'b1001_0100_1010;end
    371     : begin result_out <= 12'b1001_0100_0111;end
    372     : begin result_out <= 12'b1001_0100_0100;end
    373     : begin result_out <= 12'b1001_0100_0010;end
    374     : begin result_out <= 12'b1001_0011_1111;end
    375     : begin result_out <= 12'b1001_0011_1100;end
    376     : begin result_out <= 12'b1001_0011_1010;end
    377     : begin result_out <= 12'b1001_0011_0111;end
    378     : begin result_out <= 12'b1001_0011_0100;end
    379     : begin result_out <= 12'b1001_0011_0010;end
    380     : begin result_out <= 12'b1001_0010_1111;end
    381     : begin result_out <= 12'b1001_0010_1100;end
    382     : begin result_out <= 12'b1001_0010_1010;end
    383     : begin result_out <= 12'b1001_0010_0111;end
    384     : begin result_out <= 12'b1001_0010_0101;end
    385     : begin result_out <= 12'b1001_0010_0010;end
    386     : begin result_out <= 12'b1001_0001_1111;end
    387     : begin result_out <= 12'b1001_0001_1101;end
    388     : begin result_out <= 12'b1001_0001_1010;end
    389     : begin result_out <= 12'b1001_0001_1000;end
    390     : begin result_out <= 12'b1001_0001_0101;end
    391     : begin result_out <= 12'b1001_0001_0010;end
    392     : begin result_out <= 12'b1001_0001_0000;end
    393     : begin result_out <= 12'b1001_0000_1101;end
    394     : begin result_out <= 12'b1001_0000_1011;end
    395     : begin result_out <= 12'b1001_0000_1000;end
    396     : begin result_out <= 12'b1001_0000_0110;end
    397     : begin result_out <= 12'b1001_0000_0011;end
    398     : begin result_out <= 12'b1001_0000_0001;end
    399     : begin result_out <= 12'b1000_1111_1110;end
    400     : begin result_out <= 12'b1000_1111_1100;end
    401     : begin result_out <= 12'b1000_1111_1001;end
    402     : begin result_out <= 12'b1000_1111_0110;end
    403     : begin result_out <= 12'b1000_1111_0100;end
    404     : begin result_out <= 12'b1000_1111_0001;end
    405     : begin result_out <= 12'b1000_1110_1111;end
    406     : begin result_out <= 12'b1000_1110_1100;end
    407     : begin result_out <= 12'b1000_1110_1010;end
    408     : begin result_out <= 12'b1000_1110_1000;end
    409     : begin result_out <= 12'b1000_1110_0101;end
    410     : begin result_out <= 12'b1000_1110_0011;end
    411     : begin result_out <= 12'b1000_1110_0000;end
    412     : begin result_out <= 12'b1000_1101_1110;end
    413     : begin result_out <= 12'b1000_1101_1011;end
    414     : begin result_out <= 12'b1000_1101_1001;end
    415     : begin result_out <= 12'b1000_1101_0110;end
    416     : begin result_out <= 12'b1000_1101_0100;end
    417     : begin result_out <= 12'b1000_1101_0001;end
    418     : begin result_out <= 12'b1000_1100_1111;end
    419     : begin result_out <= 12'b1000_1100_1101;end
    420     : begin result_out <= 12'b1000_1100_1010;end
    421     : begin result_out <= 12'b1000_1100_1000;end
    422     : begin result_out <= 12'b1000_1100_0101;end
    423     : begin result_out <= 12'b1000_1100_0011;end
    424     : begin result_out <= 12'b1000_1100_0001;end
    425     : begin result_out <= 12'b1000_1011_1110;end
    426     : begin result_out <= 12'b1000_1011_1100;end
    427     : begin result_out <= 12'b1000_1011_1001;end
    428     : begin result_out <= 12'b1000_1011_0111;end
    429     : begin result_out <= 12'b1000_1011_0101;end
    430     : begin result_out <= 12'b1000_1011_0010;end
    431     : begin result_out <= 12'b1000_1011_0000;end
    432     : begin result_out <= 12'b1000_1010_1110;end
    433     : begin result_out <= 12'b1000_1010_1011;end
    434     : begin result_out <= 12'b1000_1010_1001;end
    435     : begin result_out <= 12'b1000_1010_0111;end
    436     : begin result_out <= 12'b1000_1010_0100;end
    437     : begin result_out <= 12'b1000_1010_0010;end
    438     : begin result_out <= 12'b1000_1010_0000;end
    439     : begin result_out <= 12'b1000_1001_1101;end
    440     : begin result_out <= 12'b1000_1001_1011;end
    441     : begin result_out <= 12'b1000_1001_1001;end
    442     : begin result_out <= 12'b1000_1001_0110;end
    443     : begin result_out <= 12'b1000_1001_0100;end
    444     : begin result_out <= 12'b1000_1001_0010;end
    445     : begin result_out <= 12'b1000_1000_1111;end
    446     : begin result_out <= 12'b1000_1000_1101;end
    447     : begin result_out <= 12'b1000_1000_1011;end
    448     : begin result_out <= 12'b1000_1000_1001;end
    449     : begin result_out <= 12'b1000_1000_0110;end
    450     : begin result_out <= 12'b1000_1000_0100;end
    451     : begin result_out <= 12'b1000_1000_0010;end
    452     : begin result_out <= 12'b1000_0111_1111;end
    453     : begin result_out <= 12'b1000_0111_1101;end
    454     : begin result_out <= 12'b1000_0111_1011;end
    455     : begin result_out <= 12'b1000_0111_1001;end
    456     : begin result_out <= 12'b1000_0111_0110;end
    457     : begin result_out <= 12'b1000_0111_0100;end
    458     : begin result_out <= 12'b1000_0111_0010;end
    459     : begin result_out <= 12'b1000_0111_0000;end
    460     : begin result_out <= 12'b1000_0110_1110;end
    461     : begin result_out <= 12'b1000_0110_1011;end
    462     : begin result_out <= 12'b1000_0110_1001;end
    463     : begin result_out <= 12'b1000_0110_0111;end
    464     : begin result_out <= 12'b1000_0110_0101;end
    465     : begin result_out <= 12'b1000_0110_0011;end
    466     : begin result_out <= 12'b1000_0110_0000;end
    467     : begin result_out <= 12'b1000_0101_1110;end
    468     : begin result_out <= 12'b1000_0101_1100;end
    469     : begin result_out <= 12'b1000_0101_1010;end
    470     : begin result_out <= 12'b1000_0101_1000;end
    471     : begin result_out <= 12'b1000_0101_0101;end
    472     : begin result_out <= 12'b1000_0101_0011;end
    473     : begin result_out <= 12'b1000_0101_0001;end
    474     : begin result_out <= 12'b1000_0100_1111;end
    475     : begin result_out <= 12'b1000_0100_1101;end
    476     : begin result_out <= 12'b1000_0100_1011;end
    477     : begin result_out <= 12'b1000_0100_1000;end
    478     : begin result_out <= 12'b1000_0100_0110;end
    479     : begin result_out <= 12'b1000_0100_0100;end
    480     : begin result_out <= 12'b1000_0100_0010;end
    481     : begin result_out <= 12'b1000_0100_0000;end
    482     : begin result_out <= 12'b1000_0011_1110;end
    483     : begin result_out <= 12'b1000_0011_1100;end
    484     : begin result_out <= 12'b1000_0011_1010;end
    485     : begin result_out <= 12'b1000_0011_0111;end
    486     : begin result_out <= 12'b1000_0011_0101;end
    487     : begin result_out <= 12'b1000_0011_0011;end
    488     : begin result_out <= 12'b1000_0011_0001;end
    489     : begin result_out <= 12'b1000_0010_1111;end
    490     : begin result_out <= 12'b1000_0010_1101;end
    491     : begin result_out <= 12'b1000_0010_1011;end
    492     : begin result_out <= 12'b1000_0010_1001;end
    493     : begin result_out <= 12'b1000_0010_0111;end
    494     : begin result_out <= 12'b1000_0010_0101;end
    495     : begin result_out <= 12'b1000_0010_0011;end
    496     : begin result_out <= 12'b1000_0010_0001;end
    497     : begin result_out <= 12'b1000_0001_1110;end
    498     : begin result_out <= 12'b1000_0001_1100;end
    499     : begin result_out <= 12'b1000_0001_1010;end
    500     : begin result_out <= 12'b1000_0001_1000;end
    501     : begin result_out <= 12'b1000_0001_0110;end
    502     : begin result_out <= 12'b1000_0001_0100;end
    503     : begin result_out <= 12'b1000_0001_0010;end
    504     : begin result_out <= 12'b1000_0001_0000;end
    505     : begin result_out <= 12'b1000_0000_1110;end
    506     : begin result_out <= 12'b1000_0000_1100;end
    507     : begin result_out <= 12'b1000_0000_1010;end
    508     : begin result_out <= 12'b1000_0000_1000;end
    509     : begin result_out <= 12'b1000_0000_0110;end
    510     : begin result_out <= 12'b1000_0000_0100;end
    511     : begin result_out <= 12'b1000_0000_0010;end
    default : begin result_out <= 12'b0000_0000_0000;end
    endcase
end

always @(posedge clk) begin
case(div_in[9:1])
    0       : begin offset <= 3'b011; end
    1       : begin offset <= 3'b100; end
    2       : begin offset <= 3'b100; end
    3       : begin offset <= 3'b100; end
    4       : begin offset <= 3'b100; end
    5       : begin offset <= 3'b100; end
    6       : begin offset <= 3'b100; end
    7       : begin offset <= 3'b100; end
    8       : begin offset <= 3'b100; end
    9       : begin offset <= 3'b100; end
    10      : begin offset <= 3'b100; end
    11      : begin offset <= 3'b100; end
    12      : begin offset <= 3'b100; end
    13      : begin offset <= 3'b100; end
    14      : begin offset <= 3'b100; end
    15      : begin offset <= 3'b011; end
    16      : begin offset <= 3'b100; end
    17      : begin offset <= 3'b011; end
    18      : begin offset <= 3'b100; end
    19      : begin offset <= 3'b011; end
    20      : begin offset <= 3'b100; end
    21      : begin offset <= 3'b100; end
    22      : begin offset <= 3'b011; end
    23      : begin offset <= 3'b100; end
    24      : begin offset <= 3'b100; end
    25      : begin offset <= 3'b011; end
    26      : begin offset <= 3'b100; end
    27      : begin offset <= 3'b100; end
    28      : begin offset <= 3'b100; end
    29      : begin offset <= 3'b011; end
    30      : begin offset <= 3'b011; end
    31      : begin offset <= 3'b011; end
    32      : begin offset <= 3'b011; end
    33      : begin offset <= 3'b100; end
    34      : begin offset <= 3'b100; end
    35      : begin offset <= 3'b100; end
    36      : begin offset <= 3'b100; end
    37      : begin offset <= 3'b100; end
    38      : begin offset <= 3'b011; end
    39      : begin offset <= 3'b011; end
    40      : begin offset <= 3'b011; end
    41      : begin offset <= 3'b011; end
    42      : begin offset <= 3'b011; end
    43      : begin offset <= 3'b100; end
    44      : begin offset <= 3'b100; end
    45      : begin offset <= 3'b011; end
    46      : begin offset <= 3'b011; end
    47      : begin offset <= 3'b100; end
    48      : begin offset <= 3'b011; end
    49      : begin offset <= 3'b011; end
    50      : begin offset <= 3'b100; end
    51      : begin offset <= 3'b011; end
    52      : begin offset <= 3'b011; end
    53      : begin offset <= 3'b100; end
    54      : begin offset <= 3'b011; end
    55      : begin offset <= 3'b100; end
    56      : begin offset <= 3'b011; end
    57      : begin offset <= 3'b100; end
    58      : begin offset <= 3'b011; end
    59      : begin offset <= 3'b011; end
    60      : begin offset <= 3'b011; end
    61      : begin offset <= 3'b011; end
    62      : begin offset <= 3'b100; end
    63      : begin offset <= 3'b011; end
    64      : begin offset <= 3'b011; end
    65      : begin offset <= 3'b100; end
    66      : begin offset <= 3'b011; end
    67      : begin offset <= 3'b011; end
    68      : begin offset <= 3'b011; end
    69      : begin offset <= 3'b100; end
    70      : begin offset <= 3'b011; end
    71      : begin offset <= 3'b011; end
    72      : begin offset <= 3'b011; end
    73      : begin offset <= 3'b011; end
    74      : begin offset <= 3'b011; end
    75      : begin offset <= 3'b011; end
    76      : begin offset <= 3'b011; end
    77      : begin offset <= 3'b011; end
    78      : begin offset <= 3'b011; end
    79      : begin offset <= 3'b011; end
    80      : begin offset <= 3'b011; end
    81      : begin offset <= 3'b011; end
    82      : begin offset <= 3'b011; end
    83      : begin offset <= 3'b011; end
    84      : begin offset <= 3'b011; end
    85      : begin offset <= 3'b011; end
    86      : begin offset <= 3'b011; end
    87      : begin offset <= 3'b011; end
    88      : begin offset <= 3'b011; end
    89      : begin offset <= 3'b010; end
    90      : begin offset <= 3'b011; end
    91      : begin offset <= 3'b011; end
    92      : begin offset <= 3'b011; end
    93      : begin offset <= 3'b010; end
    94      : begin offset <= 3'b011; end
    95      : begin offset <= 3'b011; end
    96      : begin offset <= 3'b011; end
    97      : begin offset <= 3'b011; end
    98      : begin offset <= 3'b011; end
    99      : begin offset <= 3'b010; end
    100     : begin offset <= 3'b011; end
    101     : begin offset <= 3'b011; end
    102     : begin offset <= 3'b011; end
    103     : begin offset <= 3'b011; end
    104     : begin offset <= 3'b010; end
    105     : begin offset <= 3'b011; end
    106     : begin offset <= 3'b010; end
    107     : begin offset <= 3'b011; end
    108     : begin offset <= 3'b011; end
    109     : begin offset <= 3'b011; end
    110     : begin offset <= 3'b011; end
    111     : begin offset <= 3'b010; end
    112     : begin offset <= 3'b011; end
    113     : begin offset <= 3'b010; end
    114     : begin offset <= 3'b011; end
    115     : begin offset <= 3'b011; end
    116     : begin offset <= 3'b010; end
    117     : begin offset <= 3'b011; end
    118     : begin offset <= 3'b011; end
    119     : begin offset <= 3'b011; end
    120     : begin offset <= 3'b010; end
    121     : begin offset <= 3'b011; end
    122     : begin offset <= 3'b011; end
    123     : begin offset <= 3'b011; end
    124     : begin offset <= 3'b010; end
    125     : begin offset <= 3'b010; end
    126     : begin offset <= 3'b011; end
    127     : begin offset <= 3'b011; end
    128     : begin offset <= 3'b011; end
    129     : begin offset <= 3'b011; end
    130     : begin offset <= 3'b011; end
    131     : begin offset <= 3'b011; end
    132     : begin offset <= 3'b010; end
    133     : begin offset <= 3'b010; end
    134     : begin offset <= 3'b010; end
    135     : begin offset <= 3'b010; end
    136     : begin offset <= 3'b010; end
    137     : begin offset <= 3'b010; end
    138     : begin offset <= 3'b010; end
    139     : begin offset <= 3'b010; end
    140     : begin offset <= 3'b010; end
    141     : begin offset <= 3'b011; end
    142     : begin offset <= 3'b011; end
    143     : begin offset <= 3'b011; end
    144     : begin offset <= 3'b011; end
    145     : begin offset <= 3'b010; end
    146     : begin offset <= 3'b010; end
    147     : begin offset <= 3'b010; end
    148     : begin offset <= 3'b011; end
    149     : begin offset <= 3'b011; end
    150     : begin offset <= 3'b010; end
    151     : begin offset <= 3'b010; end
    152     : begin offset <= 3'b010; end
    153     : begin offset <= 3'b011; end
    154     : begin offset <= 3'b010; end
    155     : begin offset <= 3'b010; end
    156     : begin offset <= 3'b010; end
    157     : begin offset <= 3'b011; end
    158     : begin offset <= 3'b010; end
    159     : begin offset <= 3'b010; end
    160     : begin offset <= 3'b011; end
    161     : begin offset <= 3'b010; end
    162     : begin offset <= 3'b011; end
    163     : begin offset <= 3'b010; end
    164     : begin offset <= 3'b010; end
    165     : begin offset <= 3'b011; end
    166     : begin offset <= 3'b010; end
    167     : begin offset <= 3'b011; end
    168     : begin offset <= 3'b010; end
    169     : begin offset <= 3'b011; end
    170     : begin offset <= 3'b010; end
    171     : begin offset <= 3'b011; end
    172     : begin offset <= 3'b010; end
    173     : begin offset <= 3'b011; end
    174     : begin offset <= 3'b010; end
    175     : begin offset <= 3'b011; end
    176     : begin offset <= 3'b010; end
    177     : begin offset <= 3'b010; end
    178     : begin offset <= 3'b010; end
    179     : begin offset <= 3'b010; end
    180     : begin offset <= 3'b011; end
    181     : begin offset <= 3'b010; end
    182     : begin offset <= 3'b010; end
    183     : begin offset <= 3'b010; end
    184     : begin offset <= 3'b010; end
    185     : begin offset <= 3'b010; end
    186     : begin offset <= 3'b011; end
    187     : begin offset <= 3'b010; end
    188     : begin offset <= 3'b010; end
    189     : begin offset <= 3'b010; end
    190     : begin offset <= 3'b010; end
    191     : begin offset <= 3'b010; end
    192     : begin offset <= 3'b010; end
    193     : begin offset <= 3'b010; end
    194     : begin offset <= 3'b010; end
    195     : begin offset <= 3'b010; end
    196     : begin offset <= 3'b010; end
    197     : begin offset <= 3'b010; end
    198     : begin offset <= 3'b010; end
    199     : begin offset <= 3'b010; end
    200     : begin offset <= 3'b010; end
    201     : begin offset <= 3'b010; end
    202     : begin offset <= 3'b010; end
    203     : begin offset <= 3'b010; end
    204     : begin offset <= 3'b010; end
    205     : begin offset <= 3'b010; end
    206     : begin offset <= 3'b010; end
    207     : begin offset <= 3'b010; end
    208     : begin offset <= 3'b010; end
    209     : begin offset <= 3'b010; end
    210     : begin offset <= 3'b010; end
    211     : begin offset <= 3'b010; end
    212     : begin offset <= 3'b010; end
    213     : begin offset <= 3'b010; end
    214     : begin offset <= 3'b010; end
    215     : begin offset <= 3'b010; end
    216     : begin offset <= 3'b010; end
    217     : begin offset <= 3'b010; end
    218     : begin offset <= 3'b010; end
    219     : begin offset <= 3'b010; end
    220     : begin offset <= 3'b010; end
    221     : begin offset <= 3'b010; end
    222     : begin offset <= 3'b010; end
    223     : begin offset <= 3'b010; end
    224     : begin offset <= 3'b010; end
    225     : begin offset <= 3'b010; end
    226     : begin offset <= 3'b010; end
    227     : begin offset <= 3'b010; end
    228     : begin offset <= 3'b010; end
    229     : begin offset <= 3'b010; end
    230     : begin offset <= 3'b010; end
    231     : begin offset <= 3'b010; end
    232     : begin offset <= 3'b010; end
    233     : begin offset <= 3'b010; end
    234     : begin offset <= 3'b010; end
    235     : begin offset <= 3'b001; end
    236     : begin offset <= 3'b010; end
    237     : begin offset <= 3'b010; end
    238     : begin offset <= 3'b010; end
    239     : begin offset <= 3'b001; end
    240     : begin offset <= 3'b010; end
    241     : begin offset <= 3'b010; end
    242     : begin offset <= 3'b001; end
    243     : begin offset <= 3'b010; end
    244     : begin offset <= 3'b010; end
    245     : begin offset <= 3'b001; end
    246     : begin offset <= 3'b010; end
    247     : begin offset <= 3'b010; end
    248     : begin offset <= 3'b001; end
    249     : begin offset <= 3'b010; end
    250     : begin offset <= 3'b010; end
    251     : begin offset <= 3'b010; end
    252     : begin offset <= 3'b010; end
    253     : begin offset <= 3'b001; end
    254     : begin offset <= 3'b010; end
    255     : begin offset <= 3'b010; end
    256     : begin offset <= 3'b010; end
    257     : begin offset <= 3'b010; end
    258     : begin offset <= 3'b010; end
    259     : begin offset <= 3'b010; end
    260     : begin offset <= 3'b010; end
    261     : begin offset <= 3'b010; end
    262     : begin offset <= 3'b001; end
    263     : begin offset <= 3'b010; end
    264     : begin offset <= 3'b010; end
    265     : begin offset <= 3'b010; end
    266     : begin offset <= 3'b010; end
    267     : begin offset <= 3'b010; end
    268     : begin offset <= 3'b010; end
    269     : begin offset <= 3'b010; end
    270     : begin offset <= 3'b010; end
    271     : begin offset <= 3'b001; end
    272     : begin offset <= 3'b010; end
    273     : begin offset <= 3'b010; end
    274     : begin offset <= 3'b010; end
    275     : begin offset <= 3'b010; end
    276     : begin offset <= 3'b001; end
    277     : begin offset <= 3'b010; end
    278     : begin offset <= 3'b010; end
    279     : begin offset <= 3'b001; end
    280     : begin offset <= 3'b010; end
    281     : begin offset <= 3'b010; end
    282     : begin offset <= 3'b001; end
    283     : begin offset <= 3'b010; end
    284     : begin offset <= 3'b010; end
    285     : begin offset <= 3'b001; end
    286     : begin offset <= 3'b010; end
    287     : begin offset <= 3'b010; end
    288     : begin offset <= 3'b001; end
    289     : begin offset <= 3'b001; end
    290     : begin offset <= 3'b010; end
    291     : begin offset <= 3'b010; end
    292     : begin offset <= 3'b001; end
    293     : begin offset <= 3'b001; end
    294     : begin offset <= 3'b010; end
    295     : begin offset <= 3'b010; end
    296     : begin offset <= 3'b001; end
    297     : begin offset <= 3'b001; end
    298     : begin offset <= 3'b010; end
    299     : begin offset <= 3'b010; end
    300     : begin offset <= 3'b010; end
    301     : begin offset <= 3'b010; end
    302     : begin offset <= 3'b001; end
    303     : begin offset <= 3'b001; end
    304     : begin offset <= 3'b010; end
    305     : begin offset <= 3'b010; end
    306     : begin offset <= 3'b010; end
    307     : begin offset <= 3'b010; end
    308     : begin offset <= 3'b010; end
    309     : begin offset <= 3'b001; end
    310     : begin offset <= 3'b001; end
    311     : begin offset <= 3'b001; end
    312     : begin offset <= 3'b001; end
    313     : begin offset <= 3'b010; end
    314     : begin offset <= 3'b010; end
    315     : begin offset <= 3'b010; end
    316     : begin offset <= 3'b010; end
    317     : begin offset <= 3'b010; end
    318     : begin offset <= 3'b010; end
    319     : begin offset <= 3'b010; end
    320     : begin offset <= 3'b010; end
    321     : begin offset <= 3'b010; end
    322     : begin offset <= 3'b010; end
    323     : begin offset <= 3'b010; end
    324     : begin offset <= 3'b010; end
    325     : begin offset <= 3'b010; end
    326     : begin offset <= 3'b010; end
    327     : begin offset <= 3'b010; end
    328     : begin offset <= 3'b010; end
    329     : begin offset <= 3'b010; end
    330     : begin offset <= 3'b010; end
    331     : begin offset <= 3'b010; end
    332     : begin offset <= 3'b010; end
    333     : begin offset <= 3'b010; end
    334     : begin offset <= 3'b010; end
    335     : begin offset <= 3'b001; end
    336     : begin offset <= 3'b001; end
    337     : begin offset <= 3'b001; end
    338     : begin offset <= 3'b001; end
    339     : begin offset <= 3'b001; end
    340     : begin offset <= 3'b001; end
    341     : begin offset <= 3'b010; end
    342     : begin offset <= 3'b010; end
    343     : begin offset <= 3'b010; end
    344     : begin offset <= 3'b001; end
    345     : begin offset <= 3'b001; end
    346     : begin offset <= 3'b001; end
    347     : begin offset <= 3'b001; end
    348     : begin offset <= 3'b010; end
    349     : begin offset <= 3'b010; end
    350     : begin offset <= 3'b010; end
    351     : begin offset <= 3'b001; end
    352     : begin offset <= 3'b001; end
    353     : begin offset <= 3'b001; end
    354     : begin offset <= 3'b010; end
    355     : begin offset <= 3'b010; end
    356     : begin offset <= 3'b001; end
    357     : begin offset <= 3'b001; end
    358     : begin offset <= 3'b010; end
    359     : begin offset <= 3'b010; end
    360     : begin offset <= 3'b001; end
    361     : begin offset <= 3'b001; end
    362     : begin offset <= 3'b001; end
    363     : begin offset <= 3'b010; end
    364     : begin offset <= 3'b001; end
    365     : begin offset <= 3'b001; end
    366     : begin offset <= 3'b010; end
    367     : begin offset <= 3'b010; end
    368     : begin offset <= 3'b001; end
    369     : begin offset <= 3'b001; end
    370     : begin offset <= 3'b010; end
    371     : begin offset <= 3'b001; end
    372     : begin offset <= 3'b001; end
    373     : begin offset <= 3'b010; end
    374     : begin offset <= 3'b001; end
    375     : begin offset <= 3'b001; end
    376     : begin offset <= 3'b010; end
    377     : begin offset <= 3'b001; end
    378     : begin offset <= 3'b001; end
    379     : begin offset <= 3'b010; end
    380     : begin offset <= 3'b001; end
    381     : begin offset <= 3'b001; end
    382     : begin offset <= 3'b010; end
    383     : begin offset <= 3'b001; end
    384     : begin offset <= 3'b010; end
    385     : begin offset <= 3'b001; end
    386     : begin offset <= 3'b001; end
    387     : begin offset <= 3'b010; end
    388     : begin offset <= 3'b001; end
    389     : begin offset <= 3'b010; end
    390     : begin offset <= 3'b001; end
    391     : begin offset <= 3'b001; end
    392     : begin offset <= 3'b001; end
    393     : begin offset <= 3'b001; end
    394     : begin offset <= 3'b010; end
    395     : begin offset <= 3'b001; end
    396     : begin offset <= 3'b010; end
    397     : begin offset <= 3'b001; end
    398     : begin offset <= 3'b010; end
    399     : begin offset <= 3'b001; end
    400     : begin offset <= 3'b010; end
    401     : begin offset <= 3'b001; end
    402     : begin offset <= 3'b001; end
    403     : begin offset <= 3'b001; end
    404     : begin offset <= 3'b001; end
    405     : begin offset <= 3'b001; end
    406     : begin offset <= 3'b001; end
    407     : begin offset <= 3'b001; end
    408     : begin offset <= 3'b010; end
    409     : begin offset <= 3'b001; end
    410     : begin offset <= 3'b010; end
    411     : begin offset <= 3'b001; end
    412     : begin offset <= 3'b010; end
    413     : begin offset <= 3'b001; end
    414     : begin offset <= 3'b001; end
    415     : begin offset <= 3'b001; end
    416     : begin offset <= 3'b001; end
    417     : begin offset <= 3'b001; end
    418     : begin offset <= 3'b001; end
    419     : begin offset <= 3'b010; end
    420     : begin offset <= 3'b001; end
    421     : begin offset <= 3'b001; end
    422     : begin offset <= 3'b001; end
    423     : begin offset <= 3'b001; end
    424     : begin offset <= 3'b010; end
    425     : begin offset <= 3'b001; end
    426     : begin offset <= 3'b001; end
    427     : begin offset <= 3'b001; end
    428     : begin offset <= 3'b001; end
    429     : begin offset <= 3'b010; end
    430     : begin offset <= 3'b001; end
    431     : begin offset <= 3'b001; end
    432     : begin offset <= 3'b010; end
    433     : begin offset <= 3'b001; end
    434     : begin offset <= 3'b001; end
    435     : begin offset <= 3'b010; end
    436     : begin offset <= 3'b001; end
    437     : begin offset <= 3'b001; end
    438     : begin offset <= 3'b010; end
    439     : begin offset <= 3'b001; end
    440     : begin offset <= 3'b001; end
    441     : begin offset <= 3'b010; end
    442     : begin offset <= 3'b001; end
    443     : begin offset <= 3'b001; end
    444     : begin offset <= 3'b001; end
    445     : begin offset <= 3'b001; end
    446     : begin offset <= 3'b001; end
    447     : begin offset <= 3'b001; end
    448     : begin offset <= 3'b010; end
    449     : begin offset <= 3'b001; end
    450     : begin offset <= 3'b001; end
    451     : begin offset <= 3'b001; end
    452     : begin offset <= 3'b001; end
    453     : begin offset <= 3'b001; end
    454     : begin offset <= 3'b001; end
    455     : begin offset <= 3'b001; end
    456     : begin offset <= 3'b001; end
    457     : begin offset <= 3'b001; end
    458     : begin offset <= 3'b001; end
    459     : begin offset <= 3'b001; end
    460     : begin offset <= 3'b010; end
    461     : begin offset <= 3'b001; end
    462     : begin offset <= 3'b001; end
    463     : begin offset <= 3'b001; end
    464     : begin offset <= 3'b001; end
    465     : begin offset <= 3'b010; end
    466     : begin offset <= 3'b001; end
    467     : begin offset <= 3'b001; end
    468     : begin offset <= 3'b001; end
    469     : begin offset <= 3'b001; end
    470     : begin offset <= 3'b001; end
    471     : begin offset <= 3'b001; end
    472     : begin offset <= 3'b001; end
    473     : begin offset <= 3'b001; end
    474     : begin offset <= 3'b001; end
    475     : begin offset <= 3'b001; end
    476     : begin offset <= 3'b001; end
    477     : begin offset <= 3'b001; end
    478     : begin offset <= 3'b001; end
    479     : begin offset <= 3'b001; end
    480     : begin offset <= 3'b001; end
    481     : begin offset <= 3'b001; end
    482     : begin offset <= 3'b001; end
    483     : begin offset <= 3'b001; end
    484     : begin offset <= 3'b001; end
    485     : begin offset <= 3'b001; end
    486     : begin offset <= 3'b001; end
    487     : begin offset <= 3'b001; end
    488     : begin offset <= 3'b001; end
    489     : begin offset <= 3'b001; end
    490     : begin offset <= 3'b001; end
    491     : begin offset <= 3'b001; end
    492     : begin offset <= 3'b001; end
    493     : begin offset <= 3'b001; end
    494     : begin offset <= 3'b001; end
    495     : begin offset <= 3'b001; end
    496     : begin offset <= 3'b010; end
    497     : begin offset <= 3'b001; end
    498     : begin offset <= 3'b001; end
    499     : begin offset <= 3'b001; end
    500     : begin offset <= 3'b001; end
    501     : begin offset <= 3'b001; end
    502     : begin offset <= 3'b001; end
    503     : begin offset <= 3'b001; end
    504     : begin offset <= 3'b001; end
    505     : begin offset <= 3'b001; end
    506     : begin offset <= 3'b001; end
    507     : begin offset <= 3'b001; end
    508     : begin offset <= 3'b001; end
    509     : begin offset <= 3'b001; end
    510     : begin offset <= 3'b001; end
    511     : begin offset <= 3'b001; end
    default : begin offset <= 3'b001; end
endcase
end

endmodule



