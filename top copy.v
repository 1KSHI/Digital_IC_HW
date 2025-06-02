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
always @(posedge clk or posedge rst) begin
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
    0    : begin result_out <= 11'd2047;end
    1    : begin result_out <= 11'd2047;end
    2    : begin result_out <= 11'd2047;end
    3    : begin result_out <= 11'd2047;end
    4    : begin result_out <= 11'd2047;end
    5    : begin result_out <= 11'd2047;end
    6    : begin result_out <= 11'd2047;end
    7    : begin result_out <= 11'd2047;end
    8    : begin result_out <= 11'd2047;end
    9    : begin result_out <= 11'd2047;end
    10   : begin result_out <= 11'd2047;end
    11   : begin result_out <= 11'd2047;end
    12   : begin result_out <= 11'd2047;end
    13   : begin result_out <= 11'd2046;end
    14   : begin result_out <= 11'd2046;end
    15   : begin result_out <= 11'd2046;end
    16   : begin result_out <= 11'd2046;end
    17   : begin result_out <= 11'd2045;end
    18   : begin result_out <= 11'd2045;end
    19   : begin result_out <= 11'd2045;end
    20   : begin result_out <= 11'd2044;end
    21   : begin result_out <= 11'd2044;end
    22   : begin result_out <= 11'd2043;end
    23   : begin result_out <= 11'd2043;end
    24   : begin result_out <= 11'd2042;end
    25   : begin result_out <= 11'd2042;end
    26   : begin result_out <= 11'd2041;end
    27   : begin result_out <= 11'd2041;end
    28   : begin result_out <= 11'd2040;end
    29   : begin result_out <= 11'd2040;end
    30   : begin result_out <= 11'd2039;end
    31   : begin result_out <= 11'd2039;end
    32   : begin result_out <= 11'd2038;end
    33   : begin result_out <= 11'd2038;end
    34   : begin result_out <= 11'd2037;end
    35   : begin result_out <= 11'd2036;end
    36   : begin result_out <= 11'd2036;end
    37   : begin result_out <= 11'd2035;end
    38   : begin result_out <= 11'd2034;end
    39   : begin result_out <= 11'd2033;end
    40   : begin result_out <= 11'd2033;end
    41   : begin result_out <= 11'd2032;end
    42   : begin result_out <= 11'd2031;end
    43   : begin result_out <= 11'd2030;end
    44   : begin result_out <= 11'd2029;end
    45   : begin result_out <= 11'd2029;end
    46   : begin result_out <= 11'd2028;end
    47   : begin result_out <= 11'd2027;end
    48   : begin result_out <= 11'd2026;end
    49   : begin result_out <= 11'd2025;end
    50   : begin result_out <= 11'd2024;end
    51   : begin result_out <= 11'd2023;end
    52   : begin result_out <= 11'd2022;end
    53   : begin result_out <= 11'd2021;end
    54   : begin result_out <= 11'd2020;end
    55   : begin result_out <= 11'd2019;end
    56   : begin result_out <= 11'd2018;end
    57   : begin result_out <= 11'd2017;end
    58   : begin result_out <= 11'd2016;end
    59   : begin result_out <= 11'd2015;end
    60   : begin result_out <= 11'd2013;end
    61   : begin result_out <= 11'd2012;end
    62   : begin result_out <= 11'd2011;end
    63   : begin result_out <= 11'd2010;end
    64   : begin result_out <= 11'd2009;end
    65   : begin result_out <= 11'd2007;end
    66   : begin result_out <= 11'd2006;end
    67   : begin result_out <= 11'd2005;end
    68   : begin result_out <= 11'd2004;end
    69   : begin result_out <= 11'd2002;end
    70   : begin result_out <= 11'd2001;end
    71   : begin result_out <= 11'd2000;end
    72   : begin result_out <= 11'd1998;end
    73   : begin result_out <= 11'd1997;end
    74   : begin result_out <= 11'd1995;end
    75   : begin result_out <= 11'd1994;end
    76   : begin result_out <= 11'd1993;end
    77   : begin result_out <= 11'd1991;end
    78   : begin result_out <= 11'd1990;end
    79   : begin result_out <= 11'd1988;end
    80   : begin result_out <= 11'd1987;end
    81   : begin result_out <= 11'd1985;end
    82   : begin result_out <= 11'd1984;end
    83   : begin result_out <= 11'd1982;end
    84   : begin result_out <= 11'd1980;end
    85   : begin result_out <= 11'd1979;end
    86   : begin result_out <= 11'd1977;end
    87   : begin result_out <= 11'd1975;end
    88   : begin result_out <= 11'd1974;end
    89   : begin result_out <= 11'd1972;end
    90   : begin result_out <= 11'd1970;end
    91   : begin result_out <= 11'd1969;end
    92   : begin result_out <= 11'd1967;end
    93   : begin result_out <= 11'd1965;end
    94   : begin result_out <= 11'd1963;end
    95   : begin result_out <= 11'd1962;end
    96   : begin result_out <= 11'd1960;end
    97   : begin result_out <= 11'd1958;end
    98   : begin result_out <= 11'd1956;end
    99   : begin result_out <= 11'd1954;end
    100  : begin result_out <= 11'd1952;end
    101  : begin result_out <= 11'd1950;end
    102  : begin result_out <= 11'd1949;end
    103  : begin result_out <= 11'd1947;end
    104  : begin result_out <= 11'd1945;end
    105  : begin result_out <= 11'd1943;end
    106  : begin result_out <= 11'd1941;end
    107  : begin result_out <= 11'd1939;end
    108  : begin result_out <= 11'd1937;end
    109  : begin result_out <= 11'd1935;end
    110  : begin result_out <= 11'd1932;end
    111  : begin result_out <= 11'd1930;end
    112  : begin result_out <= 11'd1928;end
    113  : begin result_out <= 11'd1926;end
    114  : begin result_out <= 11'd1924;end
    115  : begin result_out <= 11'd1922;end
    116  : begin result_out <= 11'd1920;end
    117  : begin result_out <= 11'd1917;end
    118  : begin result_out <= 11'd1915;end
    119  : begin result_out <= 11'd1913;end
    120  : begin result_out <= 11'd1911;end
    121  : begin result_out <= 11'd1908;end
    122  : begin result_out <= 11'd1906;end
    123  : begin result_out <= 11'd1904;end
    124  : begin result_out <= 11'd1902;end
    125  : begin result_out <= 11'd1899;end
    126  : begin result_out <= 11'd1897;end
    127  : begin result_out <= 11'd1895;end
    128  : begin result_out <= 11'd1892;end
    129  : begin result_out <= 11'd1890;end
    130  : begin result_out <= 11'd1887;end
    131  : begin result_out <= 11'd1885;end
    132  : begin result_out <= 11'd1882;end
    133  : begin result_out <= 11'd1880;end
    134  : begin result_out <= 11'd1877;end
    135  : begin result_out <= 11'd1875;end
    136  : begin result_out <= 11'd1872;end
    137  : begin result_out <= 11'd1870;end
    138  : begin result_out <= 11'd1867;end
    139  : begin result_out <= 11'd1865;end
    140  : begin result_out <= 11'd1862;end
    141  : begin result_out <= 11'd1859;end
    142  : begin result_out <= 11'd1857;end
    143  : begin result_out <= 11'd1854;end
    144  : begin result_out <= 11'd1851;end
    145  : begin result_out <= 11'd1849;end
    146  : begin result_out <= 11'd1846;end
    147  : begin result_out <= 11'd1843;end
    148  : begin result_out <= 11'd1840;end
    149  : begin result_out <= 11'd1838;end
    150  : begin result_out <= 11'd1835;end
    151  : begin result_out <= 11'd1832;end
    152  : begin result_out <= 11'd1829;end
    153  : begin result_out <= 11'd1826;end
    154  : begin result_out <= 11'd1824;end
    155  : begin result_out <= 11'd1821;end
    156  : begin result_out <= 11'd1818;end
    157  : begin result_out <= 11'd1815;end
    158  : begin result_out <= 11'd1812;end
    159  : begin result_out <= 11'd1809;end
    160  : begin result_out <= 11'd1806;end
    161  : begin result_out <= 11'd1803;end
    162  : begin result_out <= 11'd1800;end
    163  : begin result_out <= 11'd1797;end
    164  : begin result_out <= 11'd1794;end
    165  : begin result_out <= 11'd1791;end
    166  : begin result_out <= 11'd1788;end
    167  : begin result_out <= 11'd1785;end
    168  : begin result_out <= 11'd1782;end
    169  : begin result_out <= 11'd1779;end
    170  : begin result_out <= 11'd1776;end
    171  : begin result_out <= 11'd1773;end
    172  : begin result_out <= 11'd1769;end
    173  : begin result_out <= 11'd1766;end
    174  : begin result_out <= 11'd1763;end
    175  : begin result_out <= 11'd1760;end
    176  : begin result_out <= 11'd1757;end
    177  : begin result_out <= 11'd1753;end
    178  : begin result_out <= 11'd1750;end
    179  : begin result_out <= 11'd1747;end
    180  : begin result_out <= 11'd1744;end
    181  : begin result_out <= 11'd1740;end
    182  : begin result_out <= 11'd1737;end
    183  : begin result_out <= 11'd1734;end
    184  : begin result_out <= 11'd1730;end
    185  : begin result_out <= 11'd1727;end
    186  : begin result_out <= 11'd1724;end
    187  : begin result_out <= 11'd1720;end
    188  : begin result_out <= 11'd1717;end
    189  : begin result_out <= 11'd1713;end
    190  : begin result_out <= 11'd1710;end
    191  : begin result_out <= 11'd1706;end
    192  : begin result_out <= 11'd1703;end
    193  : begin result_out <= 11'd1699;end
    194  : begin result_out <= 11'd1696;end
    195  : begin result_out <= 11'd1692;end
    196  : begin result_out <= 11'd1689;end
    197  : begin result_out <= 11'd1685;end
    198  : begin result_out <= 11'd1682;end
    199  : begin result_out <= 11'd1678;end
    200  : begin result_out <= 11'd1674;end
    201  : begin result_out <= 11'd1671;end
    202  : begin result_out <= 11'd1667;end
    203  : begin result_out <= 11'd1663;end
    204  : begin result_out <= 11'd1660;end
    205  : begin result_out <= 11'd1656;end
    206  : begin result_out <= 11'd1652;end
    207  : begin result_out <= 11'd1649;end
    208  : begin result_out <= 11'd1645;end
    209  : begin result_out <= 11'd1641;end
    210  : begin result_out <= 11'd1637;end
    211  : begin result_out <= 11'd1634;end
    212  : begin result_out <= 11'd1630;end
    213  : begin result_out <= 11'd1626;end
    214  : begin result_out <= 11'd1622;end
    215  : begin result_out <= 11'd1618;end
    216  : begin result_out <= 11'd1615;end
    217  : begin result_out <= 11'd1611;end
    218  : begin result_out <= 11'd1607;end
    219  : begin result_out <= 11'd1603;end
    220  : begin result_out <= 11'd1599;end
    221  : begin result_out <= 11'd1595;end
    222  : begin result_out <= 11'd1591;end
    223  : begin result_out <= 11'd1587;end
    224  : begin result_out <= 11'd1583;end
    225  : begin result_out <= 11'd1579;end
    226  : begin result_out <= 11'd1575;end
    227  : begin result_out <= 11'd1571;end
    228  : begin result_out <= 11'd1567;end
    229  : begin result_out <= 11'd1563;end
    230  : begin result_out <= 11'd1559;end
    231  : begin result_out <= 11'd1555;end
    232  : begin result_out <= 11'd1551;end
    233  : begin result_out <= 11'd1547;end
    234  : begin result_out <= 11'd1543;end
    235  : begin result_out <= 11'd1538;end
    236  : begin result_out <= 11'd1534;end
    237  : begin result_out <= 11'd1530;end
    238  : begin result_out <= 11'd1526;end
    239  : begin result_out <= 11'd1522;end
    240  : begin result_out <= 11'd1517;end
    241  : begin result_out <= 11'd1513;end
    242  : begin result_out <= 11'd1509;end
    243  : begin result_out <= 11'd1505;end
    244  : begin result_out <= 11'd1500;end
    245  : begin result_out <= 11'd1496;end
    246  : begin result_out <= 11'd1492;end
    247  : begin result_out <= 11'd1488;end
    248  : begin result_out <= 11'd1483;end
    249  : begin result_out <= 11'd1479;end
    250  : begin result_out <= 11'd1475;end
    251  : begin result_out <= 11'd1470;end
    252  : begin result_out <= 11'd1466;end
    253  : begin result_out <= 11'd1461;end
    254  : begin result_out <= 11'd1457;end
    255  : begin result_out <= 11'd1453;end
    256  : begin result_out <= 11'd1448;end
    257  : begin result_out <= 11'd1444;end
    258  : begin result_out <= 11'd1439;end
    259  : begin result_out <= 11'd1435;end
    260  : begin result_out <= 11'd1430;end
    261  : begin result_out <= 11'd1426;end
    262  : begin result_out <= 11'd1421;end
    263  : begin result_out <= 11'd1417;end
    264  : begin result_out <= 11'd1412;end
    265  : begin result_out <= 11'd1408;end
    266  : begin result_out <= 11'd1403;end
    267  : begin result_out <= 11'd1398;end
    268  : begin result_out <= 11'd1394;end
    269  : begin result_out <= 11'd1389;end
    270  : begin result_out <= 11'd1385;end
    271  : begin result_out <= 11'd1380;end
    272  : begin result_out <= 11'd1375;end
    273  : begin result_out <= 11'd1371;end
    274  : begin result_out <= 11'd1366;end
    275  : begin result_out <= 11'd1361;end
    276  : begin result_out <= 11'd1357;end
    277  : begin result_out <= 11'd1352;end
    278  : begin result_out <= 11'd1347;end
    279  : begin result_out <= 11'd1342;end
    280  : begin result_out <= 11'd1338;end
    281  : begin result_out <= 11'd1333;end
    282  : begin result_out <= 11'd1328;end
    283  : begin result_out <= 11'd1323;end
    284  : begin result_out <= 11'd1319;end
    285  : begin result_out <= 11'd1314;end
    286  : begin result_out <= 11'd1309;end
    287  : begin result_out <= 11'd1304;end
    288  : begin result_out <= 11'd1299;end
    289  : begin result_out <= 11'd1294;end
    290  : begin result_out <= 11'd1289;end
    291  : begin result_out <= 11'd1285;end
    292  : begin result_out <= 11'd1280;end
    293  : begin result_out <= 11'd1275;end
    294  : begin result_out <= 11'd1270;end
    295  : begin result_out <= 11'd1265;end
    296  : begin result_out <= 11'd1260;end
    297  : begin result_out <= 11'd1255;end
    298  : begin result_out <= 11'd1250;end
    299  : begin result_out <= 11'd1245;end
    300  : begin result_out <= 11'd1240;end
    301  : begin result_out <= 11'd1235;end
    302  : begin result_out <= 11'd1230;end
    303  : begin result_out <= 11'd1225;end
    304  : begin result_out <= 11'd1220;end
    305  : begin result_out <= 11'd1215;end
    306  : begin result_out <= 11'd1210;end
    307  : begin result_out <= 11'd1205;end
    308  : begin result_out <= 11'd1200;end
    309  : begin result_out <= 11'd1195;end
    310  : begin result_out <= 11'd1190;end
    311  : begin result_out <= 11'd1184;end
    312  : begin result_out <= 11'd1179;end
    313  : begin result_out <= 11'd1174;end
    314  : begin result_out <= 11'd1169;end
    315  : begin result_out <= 11'd1164;end
    316  : begin result_out <= 11'd1159;end
    317  : begin result_out <= 11'd1153;end
    318  : begin result_out <= 11'd1148;end
    319  : begin result_out <= 11'd1143;end
    320  : begin result_out <= 11'd1138;end
    321  : begin result_out <= 11'd1133;end
    322  : begin result_out <= 11'd1127;end
    323  : begin result_out <= 11'd1122;end
    324  : begin result_out <= 11'd1117;end
    325  : begin result_out <= 11'd1112;end
    326  : begin result_out <= 11'd1106;end
    327  : begin result_out <= 11'd1101;end
    328  : begin result_out <= 11'd1096;end
    329  : begin result_out <= 11'd1090;end
    330  : begin result_out <= 11'd1085;end
    331  : begin result_out <= 11'd1080;end
    332  : begin result_out <= 11'd1074;end
    333  : begin result_out <= 11'd1069;end
    334  : begin result_out <= 11'd1064;end
    335  : begin result_out <= 11'd1058;end
    336  : begin result_out <= 11'd1053;end
    337  : begin result_out <= 11'd1047;end
    338  : begin result_out <= 11'd1042;end
    339  : begin result_out <= 11'd1037;end
    340  : begin result_out <= 11'd1031;end
    341  : begin result_out <= 11'd1026;end
    342  : begin result_out <= 11'd1020;end
    343  : begin result_out <= 11'd1015;end
    344  : begin result_out <= 11'd1009;end
    345  : begin result_out <= 11'd1004;end
    346  : begin result_out <= 11'd999; end
    347  : begin result_out <= 11'd993; end
    348  : begin result_out <= 11'd988; end
    349  : begin result_out <= 11'd982; end
    350  : begin result_out <= 11'd976; end
    351  : begin result_out <= 11'd971; end
    352  : begin result_out <= 11'd965; end
    353  : begin result_out <= 11'd960; end
    354  : begin result_out <= 11'd954; end
    355  : begin result_out <= 11'd949; end
    356  : begin result_out <= 11'd943; end
    357  : begin result_out <= 11'd938; end
    358  : begin result_out <= 11'd932; end
    359  : begin result_out <= 11'd926; end
    360  : begin result_out <= 11'd921; end
    361  : begin result_out <= 11'd915; end
    362  : begin result_out <= 11'd910; end
    363  : begin result_out <= 11'd904; end
    364  : begin result_out <= 11'd898; end
    365  : begin result_out <= 11'd893; end
    366  : begin result_out <= 11'd887; end
    367  : begin result_out <= 11'd881; end
    368  : begin result_out <= 11'd876; end
    369  : begin result_out <= 11'd870; end
    370  : begin result_out <= 11'd864; end
    371  : begin result_out <= 11'd859; end
    372  : begin result_out <= 11'd853; end
    373  : begin result_out <= 11'd847; end
    374  : begin result_out <= 11'd841; end
    375  : begin result_out <= 11'd836; end
    376  : begin result_out <= 11'd830; end
    377  : begin result_out <= 11'd824; end
    378  : begin result_out <= 11'd818; end
    379  : begin result_out <= 11'd813; end
    380  : begin result_out <= 11'd807; end
    381  : begin result_out <= 11'd801; end
    382  : begin result_out <= 11'd795; end
    383  : begin result_out <= 11'd790; end
    384  : begin result_out <= 11'd784; end
    385  : begin result_out <= 11'd778; end
    386  : begin result_out <= 11'd772; end
    387  : begin result_out <= 11'd766; end
    388  : begin result_out <= 11'd760; end
    389  : begin result_out <= 11'd755; end
    390  : begin result_out <= 11'd749; end
    391  : begin result_out <= 11'd743; end
    392  : begin result_out <= 11'd737; end
    393  : begin result_out <= 11'd731; end
    394  : begin result_out <= 11'd725; end
    395  : begin result_out <= 11'd719; end
    396  : begin result_out <= 11'd714; end
    397  : begin result_out <= 11'd708; end
    398  : begin result_out <= 11'd702; end
    399  : begin result_out <= 11'd696; end
    400  : begin result_out <= 11'd690; end
    401  : begin result_out <= 11'd684; end
    402  : begin result_out <= 11'd678; end
    403  : begin result_out <= 11'd672; end
    404  : begin result_out <= 11'd666; end
    405  : begin result_out <= 11'd660; end
    406  : begin result_out <= 11'd654; end
    407  : begin result_out <= 11'd648; end
    408  : begin result_out <= 11'd642; end
    409  : begin result_out <= 11'd636; end
    410  : begin result_out <= 11'd630; end
    411  : begin result_out <= 11'd624; end
    412  : begin result_out <= 11'd619; end
    413  : begin result_out <= 11'd613; end
    414  : begin result_out <= 11'd607; end
    415  : begin result_out <= 11'd601; end
    416  : begin result_out <= 11'd595; end
    417  : begin result_out <= 11'd588; end
    418  : begin result_out <= 11'd582; end
    419  : begin result_out <= 11'd576; end
    420  : begin result_out <= 11'd570; end
    421  : begin result_out <= 11'd564; end
    422  : begin result_out <= 11'd558; end
    423  : begin result_out <= 11'd552; end
    424  : begin result_out <= 11'd546; end
    425  : begin result_out <= 11'd540; end
    426  : begin result_out <= 11'd534; end
    427  : begin result_out <= 11'd528; end
    428  : begin result_out <= 11'd522; end
    429  : begin result_out <= 11'd516; end
    430  : begin result_out <= 11'd510; end
    431  : begin result_out <= 11'd504; end
    432  : begin result_out <= 11'd498; end
    433  : begin result_out <= 11'd492; end
    434  : begin result_out <= 11'd485; end
    435  : begin result_out <= 11'd479; end
    436  : begin result_out <= 11'd473; end
    437  : begin result_out <= 11'd467; end
    438  : begin result_out <= 11'd461; end
    439  : begin result_out <= 11'd455; end
    440  : begin result_out <= 11'd449; end
    441  : begin result_out <= 11'd443; end
    442  : begin result_out <= 11'd436; end
    443  : begin result_out <= 11'd430; end
    444  : begin result_out <= 11'd424; end
    445  : begin result_out <= 11'd418; end
    446  : begin result_out <= 11'd412; end
    447  : begin result_out <= 11'd406; end
    448  : begin result_out <= 11'd400; end
    449  : begin result_out <= 11'd393; end
    450  : begin result_out <= 11'd387; end
    451  : begin result_out <= 11'd381; end
    452  : begin result_out <= 11'd375; end
    453  : begin result_out <= 11'd369; end
    454  : begin result_out <= 11'd363; end
    455  : begin result_out <= 11'd356; end
    456  : begin result_out <= 11'd350; end
    457  : begin result_out <= 11'd344; end
    458  : begin result_out <= 11'd338; end
    459  : begin result_out <= 11'd332; end
    460  : begin result_out <= 11'd325; end
    461  : begin result_out <= 11'd319; end
    462  : begin result_out <= 11'd313; end
    463  : begin result_out <= 11'd307; end
    464  : begin result_out <= 11'd301; end
    465  : begin result_out <= 11'd294; end
    466  : begin result_out <= 11'd288; end
    467  : begin result_out <= 11'd282; end
    468  : begin result_out <= 11'd276; end
    469  : begin result_out <= 11'd269; end
    470  : begin result_out <= 11'd263; end
    471  : begin result_out <= 11'd257; end
    472  : begin result_out <= 11'd251; end
    473  : begin result_out <= 11'd244; end
    474  : begin result_out <= 11'd238; end
    475  : begin result_out <= 11'd232; end
    476  : begin result_out <= 11'd226; end
    477  : begin result_out <= 11'd219; end
    478  : begin result_out <= 11'd213; end
    479  : begin result_out <= 11'd207; end
    480  : begin result_out <= 11'd201; end
    481  : begin result_out <= 11'd194; end
    482  : begin result_out <= 11'd188; end
    483  : begin result_out <= 11'd182; end
    484  : begin result_out <= 11'd176; end
    485  : begin result_out <= 11'd169; end
    486  : begin result_out <= 11'd163; end
    487  : begin result_out <= 11'd157; end
    488  : begin result_out <= 11'd151; end
    489  : begin result_out <= 11'd144; end
    490  : begin result_out <= 11'd138; end
    491  : begin result_out <= 11'd132; end
    492  : begin result_out <= 11'd126; end
    493  : begin result_out <= 11'd119; end
    494  : begin result_out <= 11'd113; end
    495  : begin result_out <= 11'd107; end
    496  : begin result_out <= 11'd100; end
    497  : begin result_out <= 11'd94;  end
    498  : begin result_out <= 11'd88;  end
    499  : begin result_out <= 11'd82;  end
    500  : begin result_out <= 11'd75;  end
    501  : begin result_out <= 11'd69;  end
    502  : begin result_out <= 11'd63;  end
    503  : begin result_out <= 11'd57;  end
    504  : begin result_out <= 11'd50;  end
    505  : begin result_out <= 11'd44;  end
    506  : begin result_out <= 11'd38;  end
    507  : begin result_out <= 11'd31;  end
    508  : begin result_out <= 11'd25;  end
    509  : begin result_out <= 11'd19;  end
    510  : begin result_out <= 11'd13;  end
    511  : begin result_out <= 11'd6;   end
    default: begin result_out <= 11'd0; end // Default case
    endcase
end

always @(posedge clk) begin
    case(addr[9:1])
    0    : begin offset <= 3'd0  ;end
    1    : begin offset <= 3'd0  ;end
    2    : begin offset <= 3'd0  ;end
    3    : begin offset <= 3'd0  ;end
    4    : begin offset <= 3'd0  ;end
    5    : begin offset <= 3'd0  ;end
    6    : begin offset <= 3'd0  ;end
    7    : begin offset <= 3'd0  ;end
    8    : begin offset <= 3'd0  ;end
    9    : begin offset <= 3'd0  ;end
    10   : begin offset <= 3'd0  ;end
    11   : begin offset <= 3'd0  ;end
    12   : begin offset <= 3'd1  ;end
    13   : begin offset <= 3'd0  ;end
    14   : begin offset <= 3'd0  ;end
    15   : begin offset <= 3'd0  ;end
    16   : begin offset <= 3'd1  ;end
    17   : begin offset <= 3'd0  ;end
    18   : begin offset <= 3'd0  ;end
    19   : begin offset <= 3'd1  ;end
    20   : begin offset <= 3'd0  ;end
    21   : begin offset <= 3'd0  ;end
    22   : begin offset <= 3'd0  ;end
    23   : begin offset <= 3'd0  ;end
    24   : begin offset <= 3'd0  ;end
    25   : begin offset <= 3'd0  ;end
    26   : begin offset <= 3'd0  ;end
    27   : begin offset <= 3'd0  ;end
    28   : begin offset <= 3'd0  ;end
    29   : begin offset <= 3'd0  ;end
    30   : begin offset <= 3'd0  ;end
    31   : begin offset <= 3'd1  ;end
    32   : begin offset <= 3'd0  ;end
    33   : begin offset <= 3'd1  ;end
    34   : begin offset <= 3'd0  ;end
    35   : begin offset <= 3'd0  ;end
    36   : begin offset <= 3'd1  ;end
    37   : begin offset <= 3'd1  ;end
    38   : begin offset <= 3'd0  ;end
    39   : begin offset <= 3'd0  ;end
    40   : begin offset <= 3'd1  ;end
    41   : begin offset <= 3'd1  ;end
    42   : begin offset <= 3'd0  ;end
    43   : begin offset <= 3'd0  ;end
    44   : begin offset <= 3'd0  ;end
    45   : begin offset <= 3'd1  ;end
    46   : begin offset <= 3'd1  ;end
    47   : begin offset <= 3'd1  ;end
    48   : begin offset <= 3'd1  ;end
    49   : begin offset <= 3'd1  ;end
    50   : begin offset <= 3'd1  ;end
    51   : begin offset <= 3'd1  ;end
    52   : begin offset <= 3'd1  ;end
    53   : begin offset <= 3'd1  ;end
    54   : begin offset <= 3'd1  ;end
    55   : begin offset <= 3'd1  ;end
    56   : begin offset <= 3'd1  ;end
    57   : begin offset <= 3'd1  ;end
    58   : begin offset <= 3'd1  ;end
    59   : begin offset <= 3'd1  ;end
    60   : begin offset <= 3'd0  ;end
    61   : begin offset <= 3'd0  ;end
    62   : begin offset <= 3'd1  ;end
    63   : begin offset <= 3'd1  ;end
    64   : begin offset <= 3'd1  ;end
    65   : begin offset <= 3'd0  ;end
    66   : begin offset <= 3'd0  ;end
    67   : begin offset <= 3'd1  ;end
    68   : begin offset <= 3'd1  ;end
    69   : begin offset <= 3'd0  ;end
    70   : begin offset <= 3'd1  ;end
    71   : begin offset <= 3'd1  ;end
    72   : begin offset <= 3'd0  ;end
    73   : begin offset <= 3'd1  ;end
    74   : begin offset <= 3'd0  ;end
    75   : begin offset <= 3'd1  ;end
    76   : begin offset <= 3'd1  ;end
    77   : begin offset <= 3'd1  ;end
    78   : begin offset <= 3'd1  ;end
    79   : begin offset <= 3'd1  ;end
    80   : begin offset <= 3'd1  ;end
    81   : begin offset <= 3'd1  ;end
    82   : begin offset <= 3'd1  ;end
    83   : begin offset <= 3'd1  ;end
    84   : begin offset <= 3'd0  ;end
    85   : begin offset <= 3'd1  ;end
    86   : begin offset <= 3'd1  ;end
    87   : begin offset <= 3'd0  ;end
    88   : begin offset <= 3'd1  ;end
    89   : begin offset <= 3'd1  ;end
    90   : begin offset <= 3'd0  ;end
    91   : begin offset <= 3'd1  ;end
    92   : begin offset <= 3'd1  ;end
    93   : begin offset <= 3'd1  ;end
    94   : begin offset <= 3'd0  ;end
    95   : begin offset <= 3'd1  ;end
    96   : begin offset <= 3'd1  ;end
    97   : begin offset <= 3'd1  ;end
    98   : begin offset <= 3'd1  ;end
    99   : begin offset <= 3'd1  ;end
    100  : begin offset <= 3'd1  ;end
    101  : begin offset <= 3'd0  ;end
    102  : begin offset <= 3'd1  ;end
    103  : begin offset <= 3'd1  ;end
    104  : begin offset <= 3'd1  ;end
    105  : begin offset <= 3'd1  ;end
    106  : begin offset <= 3'd1  ;end
    107  : begin offset <= 3'd1  ;end
    108  : begin offset <= 3'd1  ;end
    109  : begin offset <= 3'd1  ;end
    110  : begin offset <= 3'd1  ;end
    111  : begin offset <= 3'd1  ;end
    112  : begin offset <= 3'd1  ;end
    113  : begin offset <= 3'd1  ;end
    114  : begin offset <= 3'd1  ;end
    115  : begin offset <= 3'd1  ;end
    116  : begin offset <= 3'd1  ;end
    117  : begin offset <= 3'd1  ;end
    118  : begin offset <= 3'd1  ;end
    119  : begin offset <= 3'd1  ;end
    120  : begin offset <= 3'd1  ;end
    121  : begin offset <= 3'd1  ;end
    122  : begin offset <= 3'd1  ;end
    123  : begin offset <= 3'd1  ;end
    124  : begin offset <= 3'd2  ;end
    125  : begin offset <= 3'd1  ;end
    126  : begin offset <= 3'd1  ;end
    127  : begin offset <= 3'd2  ;end
    128  : begin offset <= 3'd1  ;end
    129  : begin offset <= 3'd2  ;end
    130  : begin offset <= 3'd1  ;end
    131  : begin offset <= 3'd1  ;end
    132  : begin offset <= 3'd1  ;end
    133  : begin offset <= 3'd1  ;end
    134  : begin offset <= 3'd1  ;end
    135  : begin offset <= 3'd1  ;end
    136  : begin offset <= 3'd1  ;end
    137  : begin offset <= 3'd2  ;end
    138  : begin offset <= 3'd1  ;end
    139  : begin offset <= 3'd2  ;end
    140  : begin offset <= 3'd1  ;end
    141  : begin offset <= 3'd1  ;end
    142  : begin offset <= 3'd2  ;end
    143  : begin offset <= 3'd1  ;end
    144  : begin offset <= 3'd1  ;end
    145  : begin offset <= 3'd2  ;end
    146  : begin offset <= 3'd1  ;end
    147  : begin offset <= 3'd1  ;end
    148  : begin offset <= 3'd1  ;end
    149  : begin offset <= 3'd2  ;end
    150  : begin offset <= 3'd1  ;end
    151  : begin offset <= 3'd1  ;end
    152  : begin offset <= 3'd1  ;end
    153  : begin offset <= 3'd1  ;end
    154  : begin offset <= 3'd2  ;end
    155  : begin offset <= 3'd2  ;end
    156  : begin offset <= 3'd2  ;end
    157  : begin offset <= 3'd1  ;end
    158  : begin offset <= 3'd1  ;end
    159  : begin offset <= 3'd1  ;end
    160  : begin offset <= 3'd1  ;end
    161  : begin offset <= 3'd1  ;end
    162  : begin offset <= 3'd1  ;end
    163  : begin offset <= 3'd1  ;end
    164  : begin offset <= 3'd1  ;end
    165  : begin offset <= 3'd1  ;end
    166  : begin offset <= 3'd1  ;end
    167  : begin offset <= 3'd2  ;end
    168  : begin offset <= 3'd2  ;end
    169  : begin offset <= 3'd2  ;end
    170  : begin offset <= 3'd2  ;end
    171  : begin offset <= 3'd2  ;end
    172  : begin offset <= 3'd1  ;end
    173  : begin offset <= 3'd1  ;end
    174  : begin offset <= 3'd2  ;end
    175  : begin offset <= 3'd2  ;end
    176  : begin offset <= 3'd2  ;end
    177  : begin offset <= 3'd1  ;end
    178  : begin offset <= 3'd1  ;end
    179  : begin offset <= 3'd2  ;end
    180  : begin offset <= 3'd2  ;end
    181  : begin offset <= 3'd1  ;end
    182  : begin offset <= 3'd2  ;end
    183  : begin offset <= 3'd2  ;end
    184  : begin offset <= 3'd1  ;end
    185  : begin offset <= 3'd2  ;end
    186  : begin offset <= 3'd2  ;end
    187  : begin offset <= 3'd2  ;end
    188  : begin offset <= 3'd2  ;end
    189  : begin offset <= 3'd1  ;end
    190  : begin offset <= 3'd2  ;end
    191  : begin offset <= 3'd1  ;end
    192  : begin offset <= 3'd2  ;end
    193  : begin offset <= 3'd1  ;end
    194  : begin offset <= 3'd2  ;end
    195  : begin offset <= 3'd1  ;end
    196  : begin offset <= 3'd2  ;end
    197  : begin offset <= 3'd2  ;end
    198  : begin offset <= 3'd2  ;end
    199  : begin offset <= 3'd2  ;end
    200  : begin offset <= 3'd1  ;end
    201  : begin offset <= 3'd2  ;end
    202  : begin offset <= 3'd2  ;end
    203  : begin offset <= 3'd1  ;end
    204  : begin offset <= 3'd2  ;end
    205  : begin offset <= 3'd2  ;end
    206  : begin offset <= 3'd1  ;end
    207  : begin offset <= 3'd2  ;end
    208  : begin offset <= 3'd2  ;end
    209  : begin offset <= 3'd2  ;end
    210  : begin offset <= 3'd1  ;end
    211  : begin offset <= 3'd2  ;end
    212  : begin offset <= 3'd2  ;end
    213  : begin offset <= 3'd2  ;end
    214  : begin offset <= 3'd2  ;end
    215  : begin offset <= 3'd2  ;end
    216  : begin offset <= 3'd2  ;end
    217  : begin offset <= 3'd2  ;end
    218  : begin offset <= 3'd2  ;end
    219  : begin offset <= 3'd2  ;end
    220  : begin offset <= 3'd2  ;end
    221  : begin offset <= 3'd2  ;end
    222  : begin offset <= 3'd2  ;end
    223  : begin offset <= 3'd2  ;end
    224  : begin offset <= 3'd2  ;end
    225  : begin offset <= 3'd2  ;end
    226  : begin offset <= 3'd2  ;end
    227  : begin offset <= 3'd2  ;end
    228  : begin offset <= 3'd2  ;end
    229  : begin offset <= 3'd2  ;end
    230  : begin offset <= 3'd2  ;end
    231  : begin offset <= 3'd2  ;end
    232  : begin offset <= 3'd2  ;end
    233  : begin offset <= 3'd2  ;end
    234  : begin offset <= 3'd3  ;end
    235  : begin offset <= 3'd2  ;end
    236  : begin offset <= 3'd2  ;end
    237  : begin offset <= 3'd2  ;end
    238  : begin offset <= 3'd2  ;end
    239  : begin offset <= 3'd2  ;end
    240  : begin offset <= 3'd2  ;end
    241  : begin offset <= 3'd2  ;end
    242  : begin offset <= 3'd2  ;end
    243  : begin offset <= 3'd2  ;end
    244  : begin offset <= 3'd2  ;end
    245  : begin offset <= 3'd2  ;end
    246  : begin offset <= 3'd2  ;end
    247  : begin offset <= 3'd3  ;end
    248  : begin offset <= 3'd2  ;end
    249  : begin offset <= 3'd2  ;end
    250  : begin offset <= 3'd3  ;end
    251  : begin offset <= 3'd2  ;end
    252  : begin offset <= 3'd2  ;end
    253  : begin offset <= 3'd2  ;end
    254  : begin offset <= 3'd2  ;end
    255  : begin offset <= 3'd3  ;end
    256  : begin offset <= 3'd2  ;end
    257  : begin offset <= 3'd3  ;end
    258  : begin offset <= 3'd2  ;end
    259  : begin offset <= 3'd2  ;end
    260  : begin offset <= 3'd2  ;end
    261  : begin offset <= 3'd2  ;end
    262  : begin offset <= 3'd2  ;end
    263  : begin offset <= 3'd3  ;end
    264  : begin offset <= 3'd2  ;end
    265  : begin offset <= 3'd3  ;end
    266  : begin offset <= 3'd2  ;end
    267  : begin offset <= 3'd2  ;end
    268  : begin offset <= 3'd2  ;end
    269  : begin offset <= 3'd2  ;end
    270  : begin offset <= 3'd3  ;end
    271  : begin offset <= 3'd2  ;end
    272  : begin offset <= 3'd2  ;end
    273  : begin offset <= 3'd3  ;end
    274  : begin offset <= 3'd2  ;end
    275  : begin offset <= 3'd2  ;end
    276  : begin offset <= 3'd3  ;end
    277  : begin offset <= 3'd2  ;end
    278  : begin offset <= 3'd2  ;end
    279  : begin offset <= 3'd2  ;end
    280  : begin offset <= 3'd3  ;end
    281  : begin offset <= 3'd2  ;end
    282  : begin offset <= 3'd2  ;end
    283  : begin offset <= 3'd2  ;end
    284  : begin offset <= 3'd3  ;end
    285  : begin offset <= 3'd3  ;end
    286  : begin offset <= 3'd2  ;end
    287  : begin offset <= 3'd2  ;end
    288  : begin offset <= 3'd2  ;end
    289  : begin offset <= 3'd2  ;end
    290  : begin offset <= 3'd2  ;end
    291  : begin offset <= 3'd3  ;end
    292  : begin offset <= 3'd3  ;end
    293  : begin offset <= 3'd3  ;end
    294  : begin offset <= 3'd3  ;end
    295  : begin offset <= 3'd3  ;end
    296  : begin offset <= 3'd2  ;end
    297  : begin offset <= 3'd2  ;end
    298  : begin offset <= 3'd2  ;end
    299  : begin offset <= 3'd2  ;end
    300  : begin offset <= 3'd2  ;end
    301  : begin offset <= 3'd2  ;end
    302  : begin offset <= 3'd2  ;end
    303  : begin offset <= 3'd2  ;end
    304  : begin offset <= 3'd3  ;end
    305  : begin offset <= 3'd3  ;end
    306  : begin offset <= 3'd3  ;end
    307  : begin offset <= 3'd3  ;end
    308  : begin offset <= 3'd3  ;end
    309  : begin offset <= 3'd3  ;end
    310  : begin offset <= 3'd3  ;end
    311  : begin offset <= 3'd2  ;end
    312  : begin offset <= 3'd2  ;end
    313  : begin offset <= 3'd2  ;end
    314  : begin offset <= 3'd3  ;end
    315  : begin offset <= 3'd3  ;end
    316  : begin offset <= 3'd3  ;end
    317  : begin offset <= 3'd2  ;end
    318  : begin offset <= 3'd2  ;end
    319  : begin offset <= 3'd3  ;end
    320  : begin offset <= 3'd3  ;end
    321  : begin offset <= 3'd3  ;end
    322  : begin offset <= 3'd2  ;end
    323  : begin offset <= 3'd3  ;end
    324  : begin offset <= 3'd3  ;end
    325  : begin offset <= 3'd3  ;end
    326  : begin offset <= 3'd2  ;end
    327  : begin offset <= 3'd3  ;end
    328  : begin offset <= 3'd3  ;end
    329  : begin offset <= 3'd2  ;end
    330  : begin offset <= 3'd3  ;end
    331  : begin offset <= 3'd3  ;end
    332  : begin offset <= 3'd2  ;end
    333  : begin offset <= 3'd3  ;end
    334  : begin offset <= 3'd3  ;end
    335  : begin offset <= 3'd2  ;end
    336  : begin offset <= 3'd3  ;end
    337  : begin offset <= 3'd2  ;end
    338  : begin offset <= 3'd3  ;end
    339  : begin offset <= 3'd3  ;end
    340  : begin offset <= 3'd2  ;end
    341  : begin offset <= 3'd3  ;end
    342  : begin offset <= 3'd2  ;end
    343  : begin offset <= 3'd3  ;end
    344  : begin offset <= 3'd2  ;end
    345  : begin offset <= 3'd3  ;end
    346  : begin offset <= 3'd3  ;end
    347  : begin offset <= 3'd3  ;end
    348  : begin offset <= 3'd3  ;end
    349  : begin offset <= 3'd3  ;end
    350  : begin offset <= 3'd2  ;end
    351  : begin offset <= 3'd3  ;end
    352  : begin offset <= 3'd2  ;end
    353  : begin offset <= 3'd3  ;end
    354  : begin offset <= 3'd2  ;end
    355  : begin offset <= 3'd3  ;end
    356  : begin offset <= 3'd3  ;end
    357  : begin offset <= 3'd3  ;end
    358  : begin offset <= 3'd3  ;end
    359  : begin offset <= 3'd2  ;end
    360  : begin offset <= 3'd3  ;end
    361  : begin offset <= 3'd3  ;end
    362  : begin offset <= 3'd3  ;end
    363  : begin offset <= 3'd3  ;end
    364  : begin offset <= 3'd3  ;end
    365  : begin offset <= 3'd3  ;end
    366  : begin offset <= 3'd3  ;end
    367  : begin offset <= 3'd3  ;end
    368  : begin offset <= 3'd3  ;end
    369  : begin offset <= 3'd3  ;end
    370  : begin offset <= 3'd3  ;end
    371  : begin offset <= 3'd3  ;end
    372  : begin offset <= 3'd3  ;end
    373  : begin offset <= 3'd3  ;end
    374  : begin offset <= 3'd2  ;end
    375  : begin offset <= 3'd3  ;end
    376  : begin offset <= 3'd3  ;end
    377  : begin offset <= 3'd3  ;end
    378  : begin offset <= 3'd2  ;end
    379  : begin offset <= 3'd3  ;end
    380  : begin offset <= 3'd3  ;end
    381  : begin offset <= 3'd3  ;end
    382  : begin offset <= 3'd3  ;end
    383  : begin offset <= 3'd3  ;end
    384  : begin offset <= 3'd3  ;end
    385  : begin offset <= 3'd3  ;end
    386  : begin offset <= 3'd3  ;end
    387  : begin offset <= 3'd3  ;end
    388  : begin offset <= 3'd2  ;end
    389  : begin offset <= 3'd3  ;end
    390  : begin offset <= 3'd3  ;end
    391  : begin offset <= 3'd3  ;end
    392  : begin offset <= 3'd3  ;end
    393  : begin offset <= 3'd3  ;end
    394  : begin offset <= 3'd3  ;end
    395  : begin offset <= 3'd2  ;end
    396  : begin offset <= 3'd3  ;end
    397  : begin offset <= 3'd3  ;end
    398  : begin offset <= 3'd3  ;end
    399  : begin offset <= 3'd3  ;end
    400  : begin offset <= 3'd3  ;end
    401  : begin offset <= 3'd3  ;end
    402  : begin offset <= 3'd3  ;end
    403  : begin offset <= 3'd3  ;end
    404  : begin offset <= 3'd3  ;end
    405  : begin offset <= 3'd3  ;end
    406  : begin offset <= 3'd3  ;end
    407  : begin offset <= 3'd3  ;end
    408  : begin offset <= 3'd3  ;end
    409  : begin offset <= 3'd3  ;end
    410  : begin offset <= 3'd3  ;end
    411  : begin offset <= 3'd2  ;end
    412  : begin offset <= 3'd3  ;end
    413  : begin offset <= 3'd3  ;end
    414  : begin offset <= 3'd3  ;end
    415  : begin offset <= 3'd3  ;end
    416  : begin offset <= 3'd4  ;end
    417  : begin offset <= 3'd3  ;end
    418  : begin offset <= 3'd3  ;end
    419  : begin offset <= 3'd3  ;end
    420  : begin offset <= 3'd3  ;end
    421  : begin offset <= 3'd3  ;end
    422  : begin offset <= 3'd3  ;end
    423  : begin offset <= 3'd3  ;end
    424  : begin offset <= 3'd3  ;end
    425  : begin offset <= 3'd3  ;end
    426  : begin offset <= 3'd3  ;end
    427  : begin offset <= 3'd3  ;end
    428  : begin offset <= 3'd3  ;end
    429  : begin offset <= 3'd3  ;end
    430  : begin offset <= 3'd3  ;end
    431  : begin offset <= 3'd3  ;end
    432  : begin offset <= 3'd3  ;end
    433  : begin offset <= 3'd4  ;end
    434  : begin offset <= 3'd3  ;end
    435  : begin offset <= 3'd3  ;end
    436  : begin offset <= 3'd3  ;end
    437  : begin offset <= 3'd3  ;end
    438  : begin offset <= 3'd3  ;end
    439  : begin offset <= 3'd3  ;end
    440  : begin offset <= 3'd3  ;end
    441  : begin offset <= 3'd3  ;end
    442  : begin offset <= 3'd3  ;end
    443  : begin offset <= 3'd3  ;end
    444  : begin offset <= 3'd3  ;end
    445  : begin offset <= 3'd3  ;end
    446  : begin offset <= 3'd3  ;end
    447  : begin offset <= 3'd3  ;end
    448  : begin offset <= 3'd4  ;end
    449  : begin offset <= 3'd3  ;end
    450  : begin offset <= 3'd3  ;end
    451  : begin offset <= 3'd3  ;end
    452  : begin offset <= 3'd3  ;end
    453  : begin offset <= 3'd3  ;end
    454  : begin offset <= 3'd4  ;end
    455  : begin offset <= 3'd3  ;end
    456  : begin offset <= 3'd3  ;end
    457  : begin offset <= 3'd3  ;end
    458  : begin offset <= 3'd3  ;end
    459  : begin offset <= 3'd4  ;end
    460  : begin offset <= 3'd3  ;end
    461  : begin offset <= 3'd3  ;end
    462  : begin offset <= 3'd3  ;end
    463  : begin offset <= 3'd3  ;end
    464  : begin offset <= 3'd4  ;end
    465  : begin offset <= 3'd3  ;end
    466  : begin offset <= 3'd3  ;end
    467  : begin offset <= 3'd3  ;end
    468  : begin offset <= 3'd3  ;end
    469  : begin offset <= 3'd3  ;end
    470  : begin offset <= 3'd3  ;end
    471  : begin offset <= 3'd3  ;end
    472  : begin offset <= 3'd3  ;end
    473  : begin offset <= 3'd3  ;end
    474  : begin offset <= 3'd3  ;end
    475  : begin offset <= 3'd3  ;end
    476  : begin offset <= 3'd3  ;end
    477  : begin offset <= 3'd3  ;end
    478  : begin offset <= 3'd3  ;end
    479  : begin offset <= 3'd3  ;end
    480  : begin offset <= 3'd3  ;end
    481  : begin offset <= 3'd3  ;end
    482  : begin offset <= 3'd3  ;end
    483  : begin offset <= 3'd3  ;end
    484  : begin offset <= 3'd3  ;end
    485  : begin offset <= 3'd3  ;end
    486  : begin offset <= 3'd3  ;end
    487  : begin offset <= 3'd3  ;end
    488  : begin offset <= 3'd3  ;end
    489  : begin offset <= 3'd3  ;end
    490  : begin offset <= 3'd3  ;end
    491  : begin offset <= 3'd3  ;end
    492  : begin offset <= 3'd4  ;end
    493  : begin offset <= 3'd3  ;end
    494  : begin offset <= 3'd3  ;end
    495  : begin offset <= 3'd3  ;end
    496  : begin offset <= 3'd3  ;end
    497  : begin offset <= 3'd3  ;end
    498  : begin offset <= 3'd3  ;end
    499  : begin offset <= 3'd3  ;end
    500  : begin offset <= 3'd3  ;end
    501  : begin offset <= 3'd3  ;end
    502  : begin offset <= 3'd3  ;end
    503  : begin offset <= 3'd4  ;end
    504  : begin offset <= 3'd3  ;end
    505  : begin offset <= 3'd3  ;end
    506  : begin offset <= 3'd3  ;end
    507  : begin offset <= 3'd3  ;end
    508  : begin offset <= 3'd3  ;end
    509  : begin offset <= 3'd3  ;end
    510  : begin offset <= 3'd4  ;end
    511  : begin offset <= 3'd3  ;end
    default: begin offset <= 3'b0  ;end // Default case
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
reg [11:0] result_out;
reg [2:0] offset;

assign div = divadd_sel?result_out-{8'b0,offset}:result_out;
assign sft_reg = sft_reg_2;

//======================  table  =========================
always @(posedge clk) begin
    case(div_in[9:1])
    0    : begin result_out <= 12'd4095;end
    1    : begin result_out <= 12'd4088;end
    2    : begin result_out <= 12'd4080;end
    3    : begin result_out <= 12'd4072;end
    4    : begin result_out <= 12'd4064;end
    5    : begin result_out <= 12'd4056;end
    6    : begin result_out <= 12'd4049;end
    7    : begin result_out <= 12'd4041;end
    8    : begin result_out <= 12'd4033;end
    9    : begin result_out <= 12'd4025;end
    10   : begin result_out <= 12'd4018;end
    11   : begin result_out <= 12'd4010;end
    12   : begin result_out <= 12'd4002;end
    13   : begin result_out <= 12'd3995;end
    14   : begin result_out <= 12'd3987;end
    15   : begin result_out <= 12'd3979;end
    16   : begin result_out <= 12'd3972;end
    17   : begin result_out <= 12'd3964;end
    18   : begin result_out <= 12'd3957;end
    19   : begin result_out <= 12'd3949;end
    20   : begin result_out <= 12'd3942;end
    21   : begin result_out <= 12'd3935;end
    22   : begin result_out <= 12'd3927;end
    23   : begin result_out <= 12'd3920;end
    24   : begin result_out <= 12'd3913;end
    25   : begin result_out <= 12'd3905;end
    26   : begin result_out <= 12'd3898;end
    27   : begin result_out <= 12'd3891;end
    28   : begin result_out <= 12'd3884;end
    29   : begin result_out <= 12'd3876;end
    30   : begin result_out <= 12'd3869;end
    31   : begin result_out <= 12'd3862;end
    32   : begin result_out <= 12'd3855;end
    33   : begin result_out <= 12'd3848;end
    34   : begin result_out <= 12'd3841;end
    35   : begin result_out <= 12'd3834;end
    36   : begin result_out <= 12'd3827;end
    37   : begin result_out <= 12'd3820;end
    38   : begin result_out <= 12'd3813;end
    39   : begin result_out <= 12'd3806;end
    40   : begin result_out <= 12'd3799;end
    41   : begin result_out <= 12'd3792;end
    42   : begin result_out <= 12'd3785;end
    43   : begin result_out <= 12'd3779;end
    44   : begin result_out <= 12'd3772;end
    45   : begin result_out <= 12'd3765;end
    46   : begin result_out <= 12'd3758;end
    47   : begin result_out <= 12'd3752;end
    48   : begin result_out <= 12'd3745;end
    49   : begin result_out <= 12'd3738;end
    50   : begin result_out <= 12'd3732;end
    51   : begin result_out <= 12'd3725;end
    52   : begin result_out <= 12'd3718;end
    53   : begin result_out <= 12'd3712;end
    54   : begin result_out <= 12'd3705;end
    55   : begin result_out <= 12'd3699;end
    56   : begin result_out <= 12'd3692;end
    57   : begin result_out <= 12'd3686;end
    58   : begin result_out <= 12'd3679;end
    59   : begin result_out <= 12'd3673;end
    60   : begin result_out <= 12'd3666;end
    61   : begin result_out <= 12'd3660;end
    62   : begin result_out <= 12'd3654;end
    63   : begin result_out <= 12'd3647;end
    64   : begin result_out <= 12'd3641;end
    65   : begin result_out <= 12'd3635;end
    66   : begin result_out <= 12'd3628;end
    67   : begin result_out <= 12'd3622;end
    68   : begin result_out <= 12'd3616;end
    69   : begin result_out <= 12'd3610;end
    70   : begin result_out <= 12'd3603;end
    71   : begin result_out <= 12'd3597;end
    72   : begin result_out <= 12'd3591;end
    73   : begin result_out <= 12'd3585;end
    74   : begin result_out <= 12'd3579;end
    75   : begin result_out <= 12'd3573;end
    76   : begin result_out <= 12'd3567;end
    77   : begin result_out <= 12'd3561;end
    78   : begin result_out <= 12'd3554;end
    79   : begin result_out <= 12'd3548;end
    80   : begin result_out <= 12'd3542;end
    81   : begin result_out <= 12'd3537;end
    82   : begin result_out <= 12'd3531;end
    83   : begin result_out <= 12'd3525;end
    84   : begin result_out <= 12'd3519;end
    85   : begin result_out <= 12'd3513;end
    86   : begin result_out <= 12'd3507;end
    87   : begin result_out <= 12'd3501;end
    88   : begin result_out <= 12'd3495;end
    89   : begin result_out <= 12'd3489;end
    90   : begin result_out <= 12'd3484;end
    91   : begin result_out <= 12'd3478;end
    92   : begin result_out <= 12'd3472;end
    93   : begin result_out <= 12'd3466;end
    94   : begin result_out <= 12'd3461;end
    95   : begin result_out <= 12'd3455;end
    96   : begin result_out <= 12'd3449;end
    97   : begin result_out <= 12'd3444;end
    98   : begin result_out <= 12'd3438;end
    99   : begin result_out <= 12'd3432;end
    100  : begin result_out <= 12'd3427;end
    101  : begin result_out <= 12'd3421;end
    102  : begin result_out <= 12'd3416;end
    103  : begin result_out <= 12'd3410;end
    104  : begin result_out <= 12'd3404;end
    105  : begin result_out <= 12'd3399;end
    106  : begin result_out <= 12'd3393;end
    107  : begin result_out <= 12'd3388;end
    108  : begin result_out <= 12'd3383;end
    109  : begin result_out <= 12'd3377;end
    110  : begin result_out <= 12'd3372;end
    111  : begin result_out <= 12'd3366;end
    112  : begin result_out <= 12'd3361;end
    113  : begin result_out <= 12'd3355;end
    114  : begin result_out <= 12'd3350;end
    115  : begin result_out <= 12'd3345;end
    116  : begin result_out <= 12'd3339;end
    117  : begin result_out <= 12'd3334;end
    118  : begin result_out <= 12'd3329;end
    119  : begin result_out <= 12'd3324;end
    120  : begin result_out <= 12'd3318;end
    121  : begin result_out <= 12'd3313;end
    122  : begin result_out <= 12'd3308;end
    123  : begin result_out <= 12'd3303;end
    124  : begin result_out <= 12'd3297;end
    125  : begin result_out <= 12'd3292;end
    126  : begin result_out <= 12'd3287;end
    127  : begin result_out <= 12'd3282;end
    128  : begin result_out <= 12'd3277;end
    129  : begin result_out <= 12'd3272;end
    130  : begin result_out <= 12'd3267;end
    131  : begin result_out <= 12'd3262;end
    132  : begin result_out <= 12'd3256;end
    133  : begin result_out <= 12'd3251;end
    134  : begin result_out <= 12'd3246;end
    135  : begin result_out <= 12'd3241;end
    136  : begin result_out <= 12'd3236;end
    137  : begin result_out <= 12'd3231;end
    138  : begin result_out <= 12'd3226;end
    139  : begin result_out <= 12'd3221;end
    140  : begin result_out <= 12'd3216;end
    141  : begin result_out <= 12'd3212;end
    142  : begin result_out <= 12'd3207;end
    143  : begin result_out <= 12'd3202;end
    144  : begin result_out <= 12'd3197;end
    145  : begin result_out <= 12'd3192;end
    146  : begin result_out <= 12'd3187;end
    147  : begin result_out <= 12'd3182;end
    148  : begin result_out <= 12'd3178;end
    149  : begin result_out <= 12'd3173;end
    150  : begin result_out <= 12'd3168;end
    151  : begin result_out <= 12'd3163;end
    152  : begin result_out <= 12'd3158;end
    153  : begin result_out <= 12'd3154;end
    154  : begin result_out <= 12'd3149;end
    155  : begin result_out <= 12'd3144;end
    156  : begin result_out <= 12'd3139;end
    157  : begin result_out <= 12'd3135;end
    158  : begin result_out <= 12'd3130;end
    159  : begin result_out <= 12'd3125;end
    160  : begin result_out <= 12'd3121;end
    161  : begin result_out <= 12'd3116;end
    162  : begin result_out <= 12'd3112;end
    163  : begin result_out <= 12'd3107;end
    164  : begin result_out <= 12'd3102;end
    165  : begin result_out <= 12'd3098;end
    166  : begin result_out <= 12'd3093;end
    167  : begin result_out <= 12'd3089;end
    168  : begin result_out <= 12'd3084;end
    169  : begin result_out <= 12'd3080;end
    170  : begin result_out <= 12'd3075;end
    171  : begin result_out <= 12'd3071;end
    172  : begin result_out <= 12'd3066;end
    173  : begin result_out <= 12'd3062;end
    174  : begin result_out <= 12'd3057;end
    175  : begin result_out <= 12'd3053;end
    176  : begin result_out <= 12'd3048;end
    177  : begin result_out <= 12'd3044;end
    178  : begin result_out <= 12'd3039;end
    179  : begin result_out <= 12'd3035;end
    180  : begin result_out <= 12'd3031;end
    181  : begin result_out <= 12'd3026;end
    182  : begin result_out <= 12'd3022;end
    183  : begin result_out <= 12'd3017;end
    184  : begin result_out <= 12'd3013;end
    185  : begin result_out <= 12'd3009;end
    186  : begin result_out <= 12'd3005;end
    187  : begin result_out <= 12'd3000;end
    188  : begin result_out <= 12'd2996;end
    189  : begin result_out <= 12'd2992;end
    190  : begin result_out <= 12'd2987;end
    191  : begin result_out <= 12'd2983;end
    192  : begin result_out <= 12'd2979;end
    193  : begin result_out <= 12'd2975;end
    194  : begin result_out <= 12'd2970;end
    195  : begin result_out <= 12'd2966;end
    196  : begin result_out <= 12'd2962;end
    197  : begin result_out <= 12'd2958;end
    198  : begin result_out <= 12'd2954;end
    199  : begin result_out <= 12'd2950;end
    200  : begin result_out <= 12'd2945;end
    201  : begin result_out <= 12'd2941;end
    202  : begin result_out <= 12'd2937;end
    203  : begin result_out <= 12'd2933;end
    204  : begin result_out <= 12'd2929;end
    205  : begin result_out <= 12'd2925;end
    206  : begin result_out <= 12'd2921;end
    207  : begin result_out <= 12'd2917;end
    208  : begin result_out <= 12'd2913;end
    209  : begin result_out <= 12'd2909;end
    210  : begin result_out <= 12'd2905;end
    211  : begin result_out <= 12'd2901;end
    212  : begin result_out <= 12'd2897;end
    213  : begin result_out <= 12'd2893;end
    214  : begin result_out <= 12'd2889;end
    215  : begin result_out <= 12'd2885;end
    216  : begin result_out <= 12'd2881;end
    217  : begin result_out <= 12'd2877;end
    218  : begin result_out <= 12'd2873;end
    219  : begin result_out <= 12'd2869;end
    220  : begin result_out <= 12'd2865;end
    221  : begin result_out <= 12'd2861;end
    222  : begin result_out <= 12'd2857;end
    223  : begin result_out <= 12'd2853;end
    224  : begin result_out <= 12'd2849;end
    225  : begin result_out <= 12'd2846;end
    226  : begin result_out <= 12'd2842;end
    227  : begin result_out <= 12'd2838;end
    228  : begin result_out <= 12'd2834;end
    229  : begin result_out <= 12'd2830;end
    230  : begin result_out <= 12'd2826;end
    231  : begin result_out <= 12'd2823;end
    232  : begin result_out <= 12'd2819;end
    233  : begin result_out <= 12'd2815;end
    234  : begin result_out <= 12'd2811;end
    235  : begin result_out <= 12'd2807;end
    236  : begin result_out <= 12'd2804;end
    237  : begin result_out <= 12'd2800;end
    238  : begin result_out <= 12'd2796;end
    239  : begin result_out <= 12'd2792;end
    240  : begin result_out <= 12'd2789;end
    241  : begin result_out <= 12'd2785;end
    242  : begin result_out <= 12'd2781;end
    243  : begin result_out <= 12'd2778;end
    244  : begin result_out <= 12'd2774;end
    245  : begin result_out <= 12'd2770;end
    246  : begin result_out <= 12'd2767;end
    247  : begin result_out <= 12'd2763;end
    248  : begin result_out <= 12'd2759;end
    249  : begin result_out <= 12'd2756;end
    250  : begin result_out <= 12'd2752;end
    251  : begin result_out <= 12'd2749;end
    252  : begin result_out <= 12'd2745;end
    253  : begin result_out <= 12'd2741;end
    254  : begin result_out <= 12'd2738;end
    255  : begin result_out <= 12'd2734;end
    256  : begin result_out <= 12'd2731;end
    257  : begin result_out <= 12'd2727;end
    258  : begin result_out <= 12'd2724;end
    259  : begin result_out <= 12'd2720;end
    260  : begin result_out <= 12'd2717;end
    261  : begin result_out <= 12'd2713;end
    262  : begin result_out <= 12'd2709;end
    263  : begin result_out <= 12'd2706;end
    264  : begin result_out <= 12'd2703;end
    265  : begin result_out <= 12'd2699;end
    266  : begin result_out <= 12'd2696;end
    267  : begin result_out <= 12'd2692;end
    268  : begin result_out <= 12'd2689;end
    269  : begin result_out <= 12'd2685;end
    270  : begin result_out <= 12'd2682;end
    271  : begin result_out <= 12'd2678;end
    272  : begin result_out <= 12'd2675;end
    273  : begin result_out <= 12'd2672;end
    274  : begin result_out <= 12'd2668;end
    275  : begin result_out <= 12'd2665;end
    276  : begin result_out <= 12'd2661;end
    277  : begin result_out <= 12'd2658;end
    278  : begin result_out <= 12'd2655;end
    279  : begin result_out <= 12'd2651;end
    280  : begin result_out <= 12'd2648;end
    281  : begin result_out <= 12'd2645;end
    282  : begin result_out <= 12'd2641;end
    283  : begin result_out <= 12'd2638;end
    284  : begin result_out <= 12'd2635;end
    285  : begin result_out <= 12'd2631;end
    286  : begin result_out <= 12'd2628;end
    287  : begin result_out <= 12'd2625;end
    288  : begin result_out <= 12'd2621;end
    289  : begin result_out <= 12'd2618;end
    290  : begin result_out <= 12'd2615;end
    291  : begin result_out <= 12'd2612;end
    292  : begin result_out <= 12'd2608;end
    293  : begin result_out <= 12'd2605;end
    294  : begin result_out <= 12'd2602;end
    295  : begin result_out <= 12'd2599;end
    296  : begin result_out <= 12'd2595;end
    297  : begin result_out <= 12'd2592;end
    298  : begin result_out <= 12'd2589;end
    299  : begin result_out <= 12'd2586;end
    300  : begin result_out <= 12'd2583;end
    301  : begin result_out <= 12'd2580;end
    302  : begin result_out <= 12'd2576;end
    303  : begin result_out <= 12'd2573;end
    304  : begin result_out <= 12'd2570;end
    305  : begin result_out <= 12'd2567;end
    306  : begin result_out <= 12'd2564;end
    307  : begin result_out <= 12'd2561;end
    308  : begin result_out <= 12'd2558;end
    309  : begin result_out <= 12'd2554;end
    310  : begin result_out <= 12'd2551;end
    311  : begin result_out <= 12'd2548;end
    312  : begin result_out <= 12'd2545;end
    313  : begin result_out <= 12'd2542;end
    314  : begin result_out <= 12'd2539;end
    315  : begin result_out <= 12'd2536;end
    316  : begin result_out <= 12'd2533;end
    317  : begin result_out <= 12'd2530;end
    318  : begin result_out <= 12'd2527;end
    319  : begin result_out <= 12'd2524;end
    320  : begin result_out <= 12'd2521;end
    321  : begin result_out <= 12'd2518;end
    322  : begin result_out <= 12'd2515;end
    323  : begin result_out <= 12'd2512;end
    324  : begin result_out <= 12'd2509;end
    325  : begin result_out <= 12'd2506;end
    326  : begin result_out <= 12'd2503;end
    327  : begin result_out <= 12'd2500;end
    328  : begin result_out <= 12'd2497;end
    329  : begin result_out <= 12'd2494;end
    330  : begin result_out <= 12'd2491;end
    331  : begin result_out <= 12'd2488;end
    332  : begin result_out <= 12'd2485;end
    333  : begin result_out <= 12'd2482;end
    334  : begin result_out <= 12'd2479;end
    335  : begin result_out <= 12'd2476;end
    336  : begin result_out <= 12'd2473;end
    337  : begin result_out <= 12'd2470;end
    338  : begin result_out <= 12'd2467;end
    339  : begin result_out <= 12'd2464;end
    340  : begin result_out <= 12'd2461;end
    341  : begin result_out <= 12'd2459;end
    342  : begin result_out <= 12'd2456;end
    343  : begin result_out <= 12'd2453;end
    344  : begin result_out <= 12'd2450;end
    345  : begin result_out <= 12'd2447;end
    346  : begin result_out <= 12'd2444;end
    347  : begin result_out <= 12'd2441;end
    348  : begin result_out <= 12'd2439;end
    349  : begin result_out <= 12'd2436;end
    350  : begin result_out <= 12'd2433;end
    351  : begin result_out <= 12'd2430;end
    352  : begin result_out <= 12'd2427;end
    353  : begin result_out <= 12'd2424;end
    354  : begin result_out <= 12'd2422;end
    355  : begin result_out <= 12'd2419;end
    356  : begin result_out <= 12'd2416;end
    357  : begin result_out <= 12'd2413;end
    358  : begin result_out <= 12'd2411;end
    359  : begin result_out <= 12'd2408;end
    360  : begin result_out <= 12'd2405;end
    361  : begin result_out <= 12'd2402;end
    362  : begin result_out <= 12'd2399;end
    363  : begin result_out <= 12'd2397;end
    364  : begin result_out <= 12'd2394;end
    365  : begin result_out <= 12'd2391;end
    366  : begin result_out <= 12'd2389;end
    367  : begin result_out <= 12'd2386;end
    368  : begin result_out <= 12'd2383;end
    369  : begin result_out <= 12'd2380;end
    370  : begin result_out <= 12'd2378;end
    371  : begin result_out <= 12'd2375;end
    372  : begin result_out <= 12'd2372;end
    373  : begin result_out <= 12'd2370;end
    374  : begin result_out <= 12'd2367;end
    375  : begin result_out <= 12'd2364;end
    376  : begin result_out <= 12'd2362;end
    377  : begin result_out <= 12'd2359;end
    378  : begin result_out <= 12'd2356;end
    379  : begin result_out <= 12'd2354;end
    380  : begin result_out <= 12'd2351;end
    381  : begin result_out <= 12'd2348;end
    382  : begin result_out <= 12'd2346;end
    383  : begin result_out <= 12'd2343;end
    384  : begin result_out <= 12'd2341;end
    385  : begin result_out <= 12'd2338;end
    386  : begin result_out <= 12'd2335;end
    387  : begin result_out <= 12'd2333;end
    388  : begin result_out <= 12'd2330;end
    389  : begin result_out <= 12'd2328;end
    390  : begin result_out <= 12'd2325;end
    391  : begin result_out <= 12'd2322;end
    392  : begin result_out <= 12'd2320;end
    393  : begin result_out <= 12'd2317;end
    394  : begin result_out <= 12'd2315;end
    395  : begin result_out <= 12'd2312;end
    396  : begin result_out <= 12'd2310;end
    397  : begin result_out <= 12'd2307;end
    398  : begin result_out <= 12'd2305;end
    399  : begin result_out <= 12'd2302;end
    400  : begin result_out <= 12'd2300;end
    401  : begin result_out <= 12'd2297;end
    402  : begin result_out <= 12'd2294;end
    403  : begin result_out <= 12'd2292;end
    404  : begin result_out <= 12'd2289;end
    405  : begin result_out <= 12'd2287;end
    406  : begin result_out <= 12'd2284;end
    407  : begin result_out <= 12'd2282;end
    408  : begin result_out <= 12'd2280;end
    409  : begin result_out <= 12'd2277;end
    410  : begin result_out <= 12'd2275;end
    411  : begin result_out <= 12'd2272;end
    412  : begin result_out <= 12'd2270;end
    413  : begin result_out <= 12'd2267;end
    414  : begin result_out <= 12'd2265;end
    415  : begin result_out <= 12'd2262;end
    416  : begin result_out <= 12'd2260;end
    417  : begin result_out <= 12'd2257;end
    418  : begin result_out <= 12'd2255;end
    419  : begin result_out <= 12'd2253;end
    420  : begin result_out <= 12'd2250;end
    421  : begin result_out <= 12'd2248;end
    422  : begin result_out <= 12'd2245;end
    423  : begin result_out <= 12'd2243;end
    424  : begin result_out <= 12'd2241;end
    425  : begin result_out <= 12'd2238;end
    426  : begin result_out <= 12'd2236;end
    427  : begin result_out <= 12'd2233;end
    428  : begin result_out <= 12'd2231;end
    429  : begin result_out <= 12'd2229;end
    430  : begin result_out <= 12'd2226;end
    431  : begin result_out <= 12'd2224;end
    432  : begin result_out <= 12'd2222;end
    433  : begin result_out <= 12'd2219;end
    434  : begin result_out <= 12'd2217;end
    435  : begin result_out <= 12'd2215;end
    436  : begin result_out <= 12'd2212;end
    437  : begin result_out <= 12'd2210;end
    438  : begin result_out <= 12'd2208;end
    439  : begin result_out <= 12'd2205;end
    440  : begin result_out <= 12'd2203;end
    441  : begin result_out <= 12'd2201;end
    442  : begin result_out <= 12'd2198;end
    443  : begin result_out <= 12'd2196;end
    444  : begin result_out <= 12'd2194;end
    445  : begin result_out <= 12'd2191;end
    446  : begin result_out <= 12'd2189;end
    447  : begin result_out <= 12'd2187;end
    448  : begin result_out <= 12'd2185;end
    449  : begin result_out <= 12'd2182;end
    450  : begin result_out <= 12'd2180;end
    451  : begin result_out <= 12'd2178;end
    452  : begin result_out <= 12'd2175;end
    453  : begin result_out <= 12'd2173;end
    454  : begin result_out <= 12'd2171;end
    455  : begin result_out <= 12'd2169;end
    456  : begin result_out <= 12'd2166;end
    457  : begin result_out <= 12'd2164;end
    458  : begin result_out <= 12'd2162;end
    459  : begin result_out <= 12'd2160;end
    460  : begin result_out <= 12'd2158;end
    461  : begin result_out <= 12'd2155;end
    462  : begin result_out <= 12'd2153;end
    463  : begin result_out <= 12'd2151;end
    464  : begin result_out <= 12'd2149;end
    465  : begin result_out <= 12'd2147;end
    466  : begin result_out <= 12'd2144;end
    467  : begin result_out <= 12'd2142;end
    468  : begin result_out <= 12'd2140;end
    469  : begin result_out <= 12'd2138;end
    470  : begin result_out <= 12'd2136;end
    471  : begin result_out <= 12'd2133;end
    472  : begin result_out <= 12'd2131;end
    473  : begin result_out <= 12'd2129;end
    474  : begin result_out <= 12'd2127;end
    475  : begin result_out <= 12'd2125;end
    476  : begin result_out <= 12'd2123;end
    477  : begin result_out <= 12'd2120;end
    478  : begin result_out <= 12'd2118;end
    479  : begin result_out <= 12'd2116;end
    480  : begin result_out <= 12'd2114;end
    481  : begin result_out <= 12'd2112;end
    482  : begin result_out <= 12'd2110;end
    483  : begin result_out <= 12'd2108;end
    484  : begin result_out <= 12'd2106;end
    485  : begin result_out <= 12'd2103;end
    486  : begin result_out <= 12'd2101;end
    487  : begin result_out <= 12'd2099;end
    488  : begin result_out <= 12'd2097;end
    489  : begin result_out <= 12'd2095;end
    490  : begin result_out <= 12'd2093;end
    491  : begin result_out <= 12'd2091;end
    492  : begin result_out <= 12'd2089;end
    493  : begin result_out <= 12'd2087;end
    494  : begin result_out <= 12'd2085;end
    495  : begin result_out <= 12'd2083;end
    496  : begin result_out <= 12'd2081;end
    497  : begin result_out <= 12'd2078;end
    498  : begin result_out <= 12'd2076;end
    499  : begin result_out <= 12'd2074;end
    500  : begin result_out <= 12'd2072;end
    501  : begin result_out <= 12'd2070;end
    502  : begin result_out <= 12'd2068;end
    503  : begin result_out <= 12'd2066;end
    504  : begin result_out <= 12'd2064;end
    505  : begin result_out <= 12'd2062;end
    506  : begin result_out <= 12'd2060;end
    507  : begin result_out <= 12'd2058;end
    508  : begin result_out <= 12'd2056;end
    509  : begin result_out <= 12'd2054;end
    510  : begin result_out <= 12'd2052;end
    511  : begin result_out <= 12'd2050;end
    default : begin result_out <= 12'd0;end
    endcase
end

always @(posedge clk) begin
case(div_in[9:1])
    0    : begin offset <= 3'd3; end
    1    : begin offset <= 3'd4; end
    2    : begin offset <= 3'd4; end
    3    : begin offset <= 3'd4; end
    4    : begin offset <= 3'd4; end
    5    : begin offset <= 3'd4; end
    6    : begin offset <= 3'd4; end
    7    : begin offset <= 3'd4; end
    8    : begin offset <= 3'd4; end
    9    : begin offset <= 3'd4; end
    10   : begin offset <= 3'd4; end
    11   : begin offset <= 3'd4; end
    12   : begin offset <= 3'd4; end
    13   : begin offset <= 3'd4; end
    14   : begin offset <= 3'd4; end
    15   : begin offset <= 3'd3; end
    16   : begin offset <= 3'd4; end
    17   : begin offset <= 3'd3; end
    18   : begin offset <= 3'd4; end
    19   : begin offset <= 3'd3; end
    20   : begin offset <= 3'd4; end
    21   : begin offset <= 3'd4; end
    22   : begin offset <= 3'd3; end
    23   : begin offset <= 3'd4; end
    24   : begin offset <= 3'd4; end
    25   : begin offset <= 3'd3; end
    26   : begin offset <= 3'd4; end
    27   : begin offset <= 3'd4; end
    28   : begin offset <= 3'd4; end
    29   : begin offset <= 3'd3; end
    30   : begin offset <= 3'd3; end
    31   : begin offset <= 3'd3; end
    32   : begin offset <= 3'd3; end
    33   : begin offset <= 3'd4; end
    34   : begin offset <= 3'd4; end
    35   : begin offset <= 3'd4; end
    36   : begin offset <= 3'd4; end
    37   : begin offset <= 3'd4; end
    38   : begin offset <= 3'd3; end
    39   : begin offset <= 3'd3; end
    40   : begin offset <= 3'd3; end
    41   : begin offset <= 3'd3; end
    42   : begin offset <= 3'd3; end
    43   : begin offset <= 3'd4; end
    44   : begin offset <= 3'd4; end
    45   : begin offset <= 3'd3; end
    46   : begin offset <= 3'd3; end
    47   : begin offset <= 3'd4; end
    48   : begin offset <= 3'd3; end
    49   : begin offset <= 3'd3; end
    50   : begin offset <= 3'd4; end
    51   : begin offset <= 3'd3; end
    52   : begin offset <= 3'd3; end
    53   : begin offset <= 3'd4; end
    54   : begin offset <= 3'd3; end
    55   : begin offset <= 3'd4; end
    56   : begin offset <= 3'd3; end
    57   : begin offset <= 3'd4; end
    58   : begin offset <= 3'd3; end
    59   : begin offset <= 3'd3; end
    60   : begin offset <= 3'd3; end
    61   : begin offset <= 3'd3; end
    62   : begin offset <= 3'd4; end
    63   : begin offset <= 3'd3; end
    64   : begin offset <= 3'd3; end
    65   : begin offset <= 3'd4; end
    66   : begin offset <= 3'd3; end
    67   : begin offset <= 3'd3; end
    68   : begin offset <= 3'd3; end
    69   : begin offset <= 3'd4; end
    70   : begin offset <= 3'd3; end
    71   : begin offset <= 3'd3; end
    72   : begin offset <= 3'd3; end
    73   : begin offset <= 3'd3; end
    74   : begin offset <= 3'd3; end
    75   : begin offset <= 3'd3; end
    76   : begin offset <= 3'd3; end
    77   : begin offset <= 3'd3; end
    78   : begin offset <= 3'd3; end
    79   : begin offset <= 3'd3; end
    80   : begin offset <= 3'd3; end
    81   : begin offset <= 3'd3; end
    82   : begin offset <= 3'd3; end
    83   : begin offset <= 3'd3; end
    84   : begin offset <= 3'd3; end
    85   : begin offset <= 3'd3; end
    86   : begin offset <= 3'd3; end
    87   : begin offset <= 3'd3; end
    88   : begin offset <= 3'd3; end
    89   : begin offset <= 3'd2; end
    90   : begin offset <= 3'd3; end
    91   : begin offset <= 3'd3; end
    92   : begin offset <= 3'd3; end
    93   : begin offset <= 3'd2; end
    94   : begin offset <= 3'd3; end
    95   : begin offset <= 3'd3; end
    96   : begin offset <= 3'd3; end
    97   : begin offset <= 3'd3; end
    98   : begin offset <= 3'd3; end
    99   : begin offset <= 3'd2; end
    100  : begin offset <= 3'd3; end
    101  : begin offset <= 3'd3; end
    102  : begin offset <= 3'd3; end
    103  : begin offset <= 3'd3; end
    104  : begin offset <= 3'd2; end
    105  : begin offset <= 3'd3; end
    106  : begin offset <= 3'd2; end
    107  : begin offset <= 3'd3; end
    108  : begin offset <= 3'd3; end
    109  : begin offset <= 3'd3; end
    110  : begin offset <= 3'd3; end
    111  : begin offset <= 3'd2; end
    112  : begin offset <= 3'd3; end
    113  : begin offset <= 3'd2; end
    114  : begin offset <= 3'd3; end
    115  : begin offset <= 3'd3; end
    116  : begin offset <= 3'd2; end
    117  : begin offset <= 3'd3; end
    118  : begin offset <= 3'd3; end
    119  : begin offset <= 3'd3; end
    120  : begin offset <= 3'd2; end
    121  : begin offset <= 3'd3; end
    122  : begin offset <= 3'd3; end
    123  : begin offset <= 3'd3; end
    124  : begin offset <= 3'd2; end
    125  : begin offset <= 3'd2; end
    126  : begin offset <= 3'd3; end
    127  : begin offset <= 3'd3; end
    128  : begin offset <= 3'd3; end
    129  : begin offset <= 3'd3; end
    130  : begin offset <= 3'd3; end
    131  : begin offset <= 3'd3; end
    132  : begin offset <= 3'd2; end
    133  : begin offset <= 3'd2; end
    134  : begin offset <= 3'd2; end
    135  : begin offset <= 3'd2; end
    136  : begin offset <= 3'd2; end
    137  : begin offset <= 3'd2; end
    138  : begin offset <= 3'd2; end
    139  : begin offset <= 3'd2; end
    140  : begin offset <= 3'd2; end
    141  : begin offset <= 3'd3; end
    142  : begin offset <= 3'd3; end
    143  : begin offset <= 3'd3; end
    144  : begin offset <= 3'd3; end
    145  : begin offset <= 3'd2; end
    146  : begin offset <= 3'd2; end
    147  : begin offset <= 3'd2; end
    148  : begin offset <= 3'd3; end
    149  : begin offset <= 3'd3; end
    150  : begin offset <= 3'd2; end
    151  : begin offset <= 3'd2; end
    152  : begin offset <= 3'd2; end
    153  : begin offset <= 3'd3; end
    154  : begin offset <= 3'd2; end
    155  : begin offset <= 3'd2; end
    156  : begin offset <= 3'd2; end
    157  : begin offset <= 3'd3; end
    158  : begin offset <= 3'd2; end
    159  : begin offset <= 3'd2; end
    160  : begin offset <= 3'd3; end
    161  : begin offset <= 3'd2; end
    162  : begin offset <= 3'd3; end
    163  : begin offset <= 3'd2; end
    164  : begin offset <= 3'd2; end
    165  : begin offset <= 3'd3; end
    166  : begin offset <= 3'd2; end
    167  : begin offset <= 3'd3; end
    168  : begin offset <= 3'd2; end
    169  : begin offset <= 3'd3; end
    170  : begin offset <= 3'd2; end
    171  : begin offset <= 3'd3; end
    172  : begin offset <= 3'd2; end
    173  : begin offset <= 3'd3; end
    174  : begin offset <= 3'd2; end
    175  : begin offset <= 3'd3; end
    176  : begin offset <= 3'd2; end
    177  : begin offset <= 3'd2; end
    178  : begin offset <= 3'd2; end
    179  : begin offset <= 3'd2; end
    180  : begin offset <= 3'd3; end
    181  : begin offset <= 3'd2; end
    182  : begin offset <= 3'd2; end
    183  : begin offset <= 3'd2; end
    184  : begin offset <= 3'd2; end
    185  : begin offset <= 3'd2; end
    186  : begin offset <= 3'd3; end
    187  : begin offset <= 3'd2; end
    188  : begin offset <= 3'd2; end
    189  : begin offset <= 3'd2; end
    190  : begin offset <= 3'd2; end
    191  : begin offset <= 3'd2; end
    192  : begin offset <= 3'd2; end
    193  : begin offset <= 3'd2; end
    194  : begin offset <= 3'd2; end
    195  : begin offset <= 3'd2; end
    196  : begin offset <= 3'd2; end
    197  : begin offset <= 3'd2; end
    198  : begin offset <= 3'd2; end
    199  : begin offset <= 3'd2; end
    200  : begin offset <= 3'd2; end
    201  : begin offset <= 3'd2; end
    202  : begin offset <= 3'd2; end
    203  : begin offset <= 3'd2; end
    204  : begin offset <= 3'd2; end
    205  : begin offset <= 3'd2; end
    206  : begin offset <= 3'd2; end
    207  : begin offset <= 3'd2; end
    208  : begin offset <= 3'd2; end
    209  : begin offset <= 3'd2; end
    210  : begin offset <= 3'd2; end
    211  : begin offset <= 3'd2; end
    212  : begin offset <= 3'd2; end
    213  : begin offset <= 3'd2; end
    214  : begin offset <= 3'd2; end
    215  : begin offset <= 3'd2; end
    216  : begin offset <= 3'd2; end
    217  : begin offset <= 3'd2; end
    218  : begin offset <= 3'd2; end
    219  : begin offset <= 3'd2; end
    220  : begin offset <= 3'd2; end
    221  : begin offset <= 3'd2; end
    222  : begin offset <= 3'd2; end
    223  : begin offset <= 3'd2; end
    224  : begin offset <= 3'd2; end
    225  : begin offset <= 3'd2; end
    226  : begin offset <= 3'd2; end
    227  : begin offset <= 3'd2; end
    228  : begin offset <= 3'd2; end
    229  : begin offset <= 3'd2; end
    230  : begin offset <= 3'd2; end
    231  : begin offset <= 3'd2; end
    232  : begin offset <= 3'd2; end
    233  : begin offset <= 3'd2; end
    234  : begin offset <= 3'd2; end
    235  : begin offset <= 3'd1; end
    236  : begin offset <= 3'd2; end
    237  : begin offset <= 3'd2; end
    238  : begin offset <= 3'd2; end
    239  : begin offset <= 3'd1; end
    240  : begin offset <= 3'd2; end
    241  : begin offset <= 3'd2; end
    242  : begin offset <= 3'd1; end
    243  : begin offset <= 3'd2; end
    244  : begin offset <= 3'd2; end
    245  : begin offset <= 3'd1; end
    246  : begin offset <= 3'd2; end
    247  : begin offset <= 3'd2; end
    248  : begin offset <= 3'd1; end
    249  : begin offset <= 3'd2; end
    250  : begin offset <= 3'd2; end
    251  : begin offset <= 3'd2; end
    252  : begin offset <= 3'd2; end
    253  : begin offset <= 3'd1; end
    254  : begin offset <= 3'd2; end
    255  : begin offset <= 3'd2; end
    256  : begin offset <= 3'd2; end
    257  : begin offset <= 3'd2; end
    258  : begin offset <= 3'd2; end
    259  : begin offset <= 3'd2; end
    260  : begin offset <= 3'd2; end
    261  : begin offset <= 3'd2; end
    262  : begin offset <= 3'd1; end
    263  : begin offset <= 3'd2; end
    264  : begin offset <= 3'd2; end
    265  : begin offset <= 3'd2; end
    266  : begin offset <= 3'd2; end
    267  : begin offset <= 3'd2; end
    268  : begin offset <= 3'd2; end
    269  : begin offset <= 3'd2; end
    270  : begin offset <= 3'd2; end
    271  : begin offset <= 3'd1; end
    272  : begin offset <= 3'd2; end
    273  : begin offset <= 3'd2; end
    274  : begin offset <= 3'd2; end
    275  : begin offset <= 3'd2; end
    276  : begin offset <= 3'd1; end
    277  : begin offset <= 3'd2; end
    278  : begin offset <= 3'd2; end
    279  : begin offset <= 3'd1; end
    280  : begin offset <= 3'd2; end
    281  : begin offset <= 3'd2; end
    282  : begin offset <= 3'd1; end
    283  : begin offset <= 3'd2; end
    284  : begin offset <= 3'd2; end
    285  : begin offset <= 3'd1; end
    286  : begin offset <= 3'd2; end
    287  : begin offset <= 3'd2; end
    288  : begin offset <= 3'd1; end
    289  : begin offset <= 3'd1; end
    290  : begin offset <= 3'd2; end
    291  : begin offset <= 3'd2; end
    292  : begin offset <= 3'd1; end
    293  : begin offset <= 3'd1; end
    294  : begin offset <= 3'd2; end
    295  : begin offset <= 3'd2; end
    296  : begin offset <= 3'd1; end
    297  : begin offset <= 3'd1; end
    298  : begin offset <= 3'd2; end
    299  : begin offset <= 3'd2; end
    300  : begin offset <= 3'd2; end
    301  : begin offset <= 3'd2; end
    302  : begin offset <= 3'd1; end
    303  : begin offset <= 3'd1; end
    304  : begin offset <= 3'd2; end
    305  : begin offset <= 3'd2; end
    306  : begin offset <= 3'd2; end
    307  : begin offset <= 3'd2; end
    308  : begin offset <= 3'd2; end
    309  : begin offset <= 3'd1; end
    310  : begin offset <= 3'd1; end
    311  : begin offset <= 3'd1; end
    312  : begin offset <= 3'd1; end
    313  : begin offset <= 3'd2; end
    314  : begin offset <= 3'd2; end
    315  : begin offset <= 3'd2; end
    316  : begin offset <= 3'd2; end
    317  : begin offset <= 3'd2; end
    318  : begin offset <= 3'd2; end
    319  : begin offset <= 3'd2; end
    320  : begin offset <= 3'd2; end
    321  : begin offset <= 3'd2; end
    322  : begin offset <= 3'd2; end
    323  : begin offset <= 3'd2; end
    324  : begin offset <= 3'd2; end
    325  : begin offset <= 3'd2; end
    326  : begin offset <= 3'd2; end
    327  : begin offset <= 3'd2; end
    328  : begin offset <= 3'd2; end
    329  : begin offset <= 3'd2; end
    330  : begin offset <= 3'd2; end
    331  : begin offset <= 3'd2; end
    332  : begin offset <= 3'd2; end
    333  : begin offset <= 3'd2; end
    334  : begin offset <= 3'd2; end
    335  : begin offset <= 3'd1; end
    336  : begin offset <= 3'd1; end
    337  : begin offset <= 3'd1; end
    338  : begin offset <= 3'd1; end
    339  : begin offset <= 3'd1; end
    340  : begin offset <= 3'd1; end
    341  : begin offset <= 3'd2; end
    342  : begin offset <= 3'd2; end
    343  : begin offset <= 3'd2; end
    344  : begin offset <= 3'd1; end
    345  : begin offset <= 3'd1; end
    346  : begin offset <= 3'd1; end
    347  : begin offset <= 3'd1; end
    348  : begin offset <= 3'd2; end
    349  : begin offset <= 3'd2; end
    350  : begin offset <= 3'd2; end
    351  : begin offset <= 3'd1; end
    352  : begin offset <= 3'd1; end
    353  : begin offset <= 3'd1; end
    354  : begin offset <= 3'd2; end
    355  : begin offset <= 3'd2; end
    356  : begin offset <= 3'd1; end
    357  : begin offset <= 3'd1; end
    358  : begin offset <= 3'd2; end
    359  : begin offset <= 3'd2; end
    360  : begin offset <= 3'd1; end
    361  : begin offset <= 3'd1; end
    362  : begin offset <= 3'd1; end
    363  : begin offset <= 3'd2; end
    364  : begin offset <= 3'd1; end
    365  : begin offset <= 3'd1; end
    366  : begin offset <= 3'd2; end
    367  : begin offset <= 3'd2; end
    368  : begin offset <= 3'd1; end
    369  : begin offset <= 3'd1; end
    370  : begin offset <= 3'd2; end
    371  : begin offset <= 3'd1; end
    372  : begin offset <= 3'd1; end
    373  : begin offset <= 3'd2; end
    374  : begin offset <= 3'd1; end
    375  : begin offset <= 3'd1; end
    376  : begin offset <= 3'd2; end
    377  : begin offset <= 3'd1; end
    378  : begin offset <= 3'd1; end
    379  : begin offset <= 3'd2; end
    380  : begin offset <= 3'd1; end
    381  : begin offset <= 3'd1; end
    382  : begin offset <= 3'd2; end
    383  : begin offset <= 3'd1; end
    384  : begin offset <= 3'd2; end
    385  : begin offset <= 3'd1; end
    386  : begin offset <= 3'd1; end
    387  : begin offset <= 3'd2; end
    388  : begin offset <= 3'd1; end
    389  : begin offset <= 3'd2; end
    390  : begin offset <= 3'd1; end
    391  : begin offset <= 3'd1; end
    392  : begin offset <= 3'd1; end
    393  : begin offset <= 3'd1; end
    394  : begin offset <= 3'd2; end
    395  : begin offset <= 3'd1; end
    396  : begin offset <= 3'd2; end
    397  : begin offset <= 3'd1; end
    398  : begin offset <= 3'd2; end
    399  : begin offset <= 3'd1; end
    400  : begin offset <= 3'd2; end
    401  : begin offset <= 3'd1; end
    402  : begin offset <= 3'd1; end
    403  : begin offset <= 3'd1; end
    404  : begin offset <= 3'd1; end
    405  : begin offset <= 3'd1; end
    406  : begin offset <= 3'd1; end
    407  : begin offset <= 3'd1; end
    408  : begin offset <= 3'd2; end
    409  : begin offset <= 3'd1; end
    410  : begin offset <= 3'd2; end
    411  : begin offset <= 3'd1; end
    412  : begin offset <= 3'd2; end
    413  : begin offset <= 3'd1; end
    414  : begin offset <= 3'd1; end
    415  : begin offset <= 3'd1; end
    416  : begin offset <= 3'd1; end
    417  : begin offset <= 3'd1; end
    418  : begin offset <= 3'd1; end
    419  : begin offset <= 3'd2; end
    420  : begin offset <= 3'd1; end
    421  : begin offset <= 3'd1; end
    422  : begin offset <= 3'd1; end
    423  : begin offset <= 3'd1; end
    424  : begin offset <= 3'd2; end
    425  : begin offset <= 3'd1; end
    426  : begin offset <= 3'd1; end
    427  : begin offset <= 3'd1; end
    428  : begin offset <= 3'd1; end
    429  : begin offset <= 3'd2; end
    430  : begin offset <= 3'd1; end
    431  : begin offset <= 3'd1; end
    432  : begin offset <= 3'd2; end
    433  : begin offset <= 3'd1; end
    434  : begin offset <= 3'd1; end
    435  : begin offset <= 3'd2; end
    436  : begin offset <= 3'd1; end
    437  : begin offset <= 3'd1; end
    438  : begin offset <= 3'd2; end
    439  : begin offset <= 3'd1; end
    440  : begin offset <= 3'd1; end
    441  : begin offset <= 3'd2; end
    442  : begin offset <= 3'd1; end
    443  : begin offset <= 3'd1; end
    444  : begin offset <= 3'd1; end
    445  : begin offset <= 3'd1; end
    446  : begin offset <= 3'd1; end
    447  : begin offset <= 3'd1; end
    448  : begin offset <= 3'd2; end
    449  : begin offset <= 3'd1; end
    450  : begin offset <= 3'd1; end
    451  : begin offset <= 3'd1; end
    452  : begin offset <= 3'd1; end
    453  : begin offset <= 3'd1; end
    454  : begin offset <= 3'd1; end
    455  : begin offset <= 3'd1; end
    456  : begin offset <= 3'd1; end
    457  : begin offset <= 3'd1; end
    458  : begin offset <= 3'd1; end
    459  : begin offset <= 3'd1; end
    460  : begin offset <= 3'd2; end
    461  : begin offset <= 3'd1; end
    462  : begin offset <= 3'd1; end
    463  : begin offset <= 3'd1; end
    464  : begin offset <= 3'd1; end
    465  : begin offset <= 3'd2; end
    466  : begin offset <= 3'd1; end
    467  : begin offset <= 3'd1; end
    468  : begin offset <= 3'd1; end
    469  : begin offset <= 3'd1; end
    470  : begin offset <= 3'd1; end
    471  : begin offset <= 3'd1; end
    472  : begin offset <= 3'd1; end
    473  : begin offset <= 3'd1; end
    474  : begin offset <= 3'd1; end
    475  : begin offset <= 3'd1; end
    476  : begin offset <= 3'd1; end
    477  : begin offset <= 3'd1; end
    478  : begin offset <= 3'd1; end
    479  : begin offset <= 3'd1; end
    480  : begin offset <= 3'd1; end
    481  : begin offset <= 3'd1; end
    482  : begin offset <= 3'd1; end
    483  : begin offset <= 3'd1; end
    484  : begin offset <= 3'd1; end
    485  : begin offset <= 3'd1; end
    486  : begin offset <= 3'd1; end
    487  : begin offset <= 3'd1; end
    488  : begin offset <= 3'd1; end
    489  : begin offset <= 3'd1; end
    490  : begin offset <= 3'd1; end
    491  : begin offset <= 3'd1; end
    492  : begin offset <= 3'd1; end
    493  : begin offset <= 3'd1; end
    494  : begin offset <= 3'd1; end
    495  : begin offset <= 3'd1; end
    496  : begin offset <= 3'd2; end
    497  : begin offset <= 3'd1; end
    498  : begin offset <= 3'd1; end
    499  : begin offset <= 3'd1; end
    500  : begin offset <= 3'd1; end
    501  : begin offset <= 3'd1; end
    502  : begin offset <= 3'd1; end
    503  : begin offset <= 3'd1; end
    504  : begin offset <= 3'd1; end
    505  : begin offset <= 3'd1; end
    506  : begin offset <= 3'd1; end
    507  : begin offset <= 3'd1; end
    508  : begin offset <= 3'd1; end
    509  : begin offset <= 3'd1; end
    510  : begin offset <= 3'd1; end
    511  : begin offset <= 3'd1; end
default : begin offset <= 3'd1; end
endcase
end

endmodule



