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

wire [11:0] Thi_rom_wire;
reg  [11:0] Thi_rom_reg;//cos c>>12

reg [11:0] Fir_a_reg;//a
reg [11:0] Fir_b_reg;//b

Adder12 Adder12 (
    .x_in      (a           ),
    .y_in      (d_reg       ),
    .result_out(Fir_add_wire)
);

Rom Rom(
    .clk       (clk          ),
    .x_in      (c            ),
    .res_out   (Thi_rom_wire )//两周期
);

always @(posedge clk) begin
    if (rst) begin
        Thi_rom_reg <= 0;
        Fir_add_reg <= 0;
        Fir_a_reg <= 0;
        Fir_b_reg <= 0;
    end else begin
        Thi_rom_reg <= Thi_rom_wire;
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
        Fir_sign_reg <= Thi_rom_wire[11];
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

//=========================== cycle 2 ============================
reg [3:0] Sec_sft_reg;
reg [9:0] Sec_add_reg;
always @(posedge clk) begin
    casez (Fir_add_reg)
        13'b000000000000?:begin Sec_sft_reg <= 0;  Sec_add_reg <= 0;                        end
        13'b000000000001?:begin Sec_sft_reg <= 1;  Sec_add_reg <= {Fir_add_reg[0]  ,9'b0};  end
        13'b00000000001??:begin Sec_sft_reg <= 2;  Sec_add_reg <= {Fir_add_reg[1:0],8'b0};  end
        13'b0000000001???:begin Sec_sft_reg <= 3;  Sec_add_reg <= {Fir_add_reg[2:0],7'b0};  end
        13'b000000001????:begin Sec_sft_reg <= 4;  Sec_add_reg <= {Fir_add_reg[3:0],6'b0};  end
        13'b00000001?????:begin Sec_sft_reg <= 5;  Sec_add_reg <= {Fir_add_reg[4:0],5'b0};  end
        13'b0000001??????:begin Sec_sft_reg <= 6;  Sec_add_reg <= {Fir_add_reg[5:0],4'b0};  end
        13'b000001???????:begin Sec_sft_reg <= 7;  Sec_add_reg <= {Fir_add_reg[6:0],3'b0};  end
        13'b00001????????:begin Sec_sft_reg <= 8;  Sec_add_reg <= {Fir_add_reg[7:0],2'b0};  end
        13'b0001?????????:begin Sec_sft_reg <= 9;  Sec_add_reg <= {Fir_add_reg[8:0],1'b0};  end
        13'b001??????????:begin Sec_sft_reg <= 10; Sec_add_reg <= Fir_add_reg[9:0];         end
        13'b01???????????:begin Sec_sft_reg <= 11; Sec_add_reg <= Fir_add_reg[10:1];        end
        13'b1????????????:begin Sec_sft_reg <= 12; Sec_add_reg <= Fir_add_reg[11:2];        end
    endcase
end

reg [11:0] Sec_b_reg;
reg [11:0] Sec_a_reg;
reg [11:0] Sec_rom_reg;
always @(posedge clk) begin
    if (rst) begin
        Sec_b_reg <= 0;
        Sec_a_reg <= 0;
        Sec_rom_reg <= 0;

    end else begin
        Sec_b_reg <= Fir_b_reg;
        Sec_a_reg <= Fir_a_reg;
        Sec_rom_reg <= Thi_rom_reg;
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


//1/(a+d)    
//=========================== cycle 3 ============================
wire [11:0] Thi_div_wire;
reg  [11:0] Thi_div_reg;//a*b/(a+d)

reg  [3:0]  Thi_sft_reg;

reg  [11:0] Thi_a_reg;//a



DivRom DivRom(
    .in  (Sec_add_reg  ),
    .div (Thi_div_wire  )
);


always @(posedge clk) begin
    if (rst) begin
        Thi_div_reg <= 0;
        Thi_a_reg <= 0;
        Thi_sft_reg <= 0;
    end else begin
        Thi_div_reg <= Thi_div_wire;
        Thi_sft_reg <= Sec_sft_reg;
        Thi_a_reg <= Sec_a_reg;
    end
end

reg [11:0] Thi_b_reg;
always @(posedge clk) begin
    if (rst) begin
        Thi_b_reg <= 0;
    end else begin
        Thi_b_reg <= Sec_b_reg;
    end
end

reg Thi_sign_reg;
always @(posedge clk) begin
    if (rst) begin
        Thi_sign_reg <= 0;
    end else begin
        Thi_sign_reg <= Sec_sign_reg;
    end
end

reg Thi_end_reg;
always @(posedge clk) begin
    if (rst) begin
        Thi_end_reg <= 0;
    end else begin
        Thi_end_reg <= Sec_end_reg;
    end
end

//a * 1/(a+d)  //b*cos c>>12
//=========================== cycle 4 5 ============================//两周期
wire [23:0]  Fou_muldiv_wire;
reg  [11:0]  Fou_muldiv_reg;

reg  [3:0]   Fou_sft_reg;
reg  [3:0]   Fif_sft_reg;


wire [23:0] Fou_bcos_wire;//(b*cos c)>>12
reg [11:0] Fou_bcos_reg;//(b*cos c)>>12

Wallace12x12 Wallace12x12_2 (
    .clk        (clk             ),
    .rst        (rst             ),
    .x_in       (Thi_a_reg       ),
    .y_in       (Thi_div_reg     ),
    .result_out (Fou_muldiv_wire )
);

Wallace12x12 Wallace12x12_1 (
    .clk        (clk                      ),
    .rst        (rst                      ),
    .x_in       (Thi_b_reg                ),
    .y_in       ({Sec_rom_reg[10:0],1'b0} ),//Q.12
    .result_out (Fou_bcos_wire            )
);

always @(posedge clk) begin
    if (rst) begin
        Fou_sft_reg <= 0;
        Fou_bcos_reg <= 0;
    end else begin
        Fou_sft_reg <= Thi_sft_reg;
        Fou_bcos_reg <= Fou_bcos_wire[23:12];
    end
end


wire [23:0] Sec_sft_reg_wire;
assign Sec_sft_reg_wire = Fou_muldiv_wire>>Fou_sft_reg;

reg [11:0] Six_bcos_reg;

always @(posedge clk) begin
    if (rst) begin
        Fou_muldiv_reg <= 0;
    end else begin
        Fou_muldiv_reg <= Sec_sft_reg_wire[11:0];
    end
end

reg Fou_sign_reg;
reg Fif_sign_reg;
always @(posedge clk) begin
    if (rst) begin
        Fou_sign_reg <= 0;
        Fif_sign_reg <= 0;
    end else begin
        Fou_sign_reg <= Thi_sign_reg;
        Fif_sign_reg <= Fou_sign_reg;
    end
end

reg Fou_end_reg;
reg Fif_end_reg;
always @(posedge clk) begin
    if (rst) begin
        Fou_end_reg <= 0;
        Fif_end_reg <= 0;
    end else begin
        Fou_end_reg <= Thi_end_reg;
        Fif_end_reg <= Fou_end_reg;
    end
end

//a * 1/(a+d) >> sft
//=========================== cycle 6 ============================
wire [23:0] Six_mul_wire;
reg [11:0]  Six_mul_reg;

Wallace12x12 Wallace12x12_3 (
    .clk        (clk            ),
    .rst        (rst            ),
    .x_in       (Fou_muldiv_reg ),
    .y_in       (Fou_bcos_reg   ),
    .result_out (Six_mul_wire   )
);

always @(posedge clk) begin
    if (rst) begin
        Six_mul_reg <= 0;
    end else begin
        Six_mul_reg <= Six_mul_wire[23:12];
    end
end

reg Six_sign_reg;
always @(posedge clk) begin
    if (rst) begin
        Six_sign_reg <= 0;
    end else begin
        Six_sign_reg <= Fif_sign_reg;
    end
end

reg Six_end_reg;
reg Sev_end_reg;
always @(posedge clk) begin
    if (rst) begin
        Six_end_reg <= 0;
        Sev_end_reg <= 0;
    end else begin
        Six_end_reg <= Fif_end_reg;
        Sev_end_reg <= Six_end_reg;
    end
end

assign y = {Six_sign_reg,Six_mul_reg};


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
    output wire[11:0] res_out
);

reg[11:0] result_out;
wire [1:0] quadrant = x_in[11:10];
reg sign;

reg [9:0] addr;
wire [9:0] addr_temp;
assign addr_temp = ~x_in[9:0]+1;

reg zero;
assign res_out = zero?0:result_out;
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
            zero <= (addr==0);
        end
        2'b10: begin
            addr <= x_in[9:0];
            sign <= 1;
            zero <= 0;
        end
        2'b11: begin
            addr <= addr_temp;
            sign <= 0;
            zero <= (addr==0);
        end
    endcase
end


always @(*) begin
    case(addr)
    0    : result_out = {sign,11'd2047};
    1    : result_out = {sign,11'd2047};
    2    : result_out = {sign,11'd2047};
    3    : result_out = {sign,11'd2047};
    4    : result_out = {sign,11'd2047};
    5    : result_out = {sign,11'd2047};
    6    : result_out = {sign,11'd2047};
    7    : result_out = {sign,11'd2047};
    8    : result_out = {sign,11'd2047};
    9    : result_out = {sign,11'd2047};
    10   : result_out = {sign,11'd2047};
    11   : result_out = {sign,11'd2047};
    12   : result_out = {sign,11'd2047};
    13   : result_out = {sign,11'd2047};
    14   : result_out = {sign,11'd2047};
    15   : result_out = {sign,11'd2047};
    16   : result_out = {sign,11'd2047};
    17   : result_out = {sign,11'd2047};
    18   : result_out = {sign,11'd2047};
    19   : result_out = {sign,11'd2047};
    20   : result_out = {sign,11'd2047};
    21   : result_out = {sign,11'd2047};
    22   : result_out = {sign,11'd2047};
    23   : result_out = {sign,11'd2047};
    24   : result_out = {sign,11'd2047};
    25   : result_out = {sign,11'd2046};
    26   : result_out = {sign,11'd2046};
    27   : result_out = {sign,11'd2046};
    28   : result_out = {sign,11'd2046};
    29   : result_out = {sign,11'd2046};
    30   : result_out = {sign,11'd2046};
    31   : result_out = {sign,11'd2046};
    32   : result_out = {sign,11'd2046};
    33   : result_out = {sign,11'd2045};
    34   : result_out = {sign,11'd2045};
    35   : result_out = {sign,11'd2045};
    36   : result_out = {sign,11'd2045};
    37   : result_out = {sign,11'd2045};
    38   : result_out = {sign,11'd2045};
    39   : result_out = {sign,11'd2044};
    40   : result_out = {sign,11'd2044};
    41   : result_out = {sign,11'd2044};
    42   : result_out = {sign,11'd2044};
    43   : result_out = {sign,11'd2044};
    44   : result_out = {sign,11'd2043};
    45   : result_out = {sign,11'd2043};
    46   : result_out = {sign,11'd2043};
    47   : result_out = {sign,11'd2043};
    48   : result_out = {sign,11'd2042};
    49   : result_out = {sign,11'd2042};
    50   : result_out = {sign,11'd2042};
    51   : result_out = {sign,11'd2042};
    52   : result_out = {sign,11'd2041};
    53   : result_out = {sign,11'd2041};
    54   : result_out = {sign,11'd2041};
    55   : result_out = {sign,11'd2041};
    56   : result_out = {sign,11'd2040};
    57   : result_out = {sign,11'd2040};
    58   : result_out = {sign,11'd2040};
    59   : result_out = {sign,11'd2040};
    60   : result_out = {sign,11'd2039};
    61   : result_out = {sign,11'd2039};
    62   : result_out = {sign,11'd2039};
    63   : result_out = {sign,11'd2038};
    64   : result_out = {sign,11'd2038};
    65   : result_out = {sign,11'd2038};
    66   : result_out = {sign,11'd2038};
    67   : result_out = {sign,11'd2037};
    68   : result_out = {sign,11'd2037};
    69   : result_out = {sign,11'd2037};
    70   : result_out = {sign,11'd2036};
    71   : result_out = {sign,11'd2036};
    72   : result_out = {sign,11'd2036};
    73   : result_out = {sign,11'd2035};
    74   : result_out = {sign,11'd2035};
    75   : result_out = {sign,11'd2034};
    76   : result_out = {sign,11'd2034};
    77   : result_out = {sign,11'd2034};
    78   : result_out = {sign,11'd2033};
    79   : result_out = {sign,11'd2033};
    80   : result_out = {sign,11'd2033};
    81   : result_out = {sign,11'd2032};
    82   : result_out = {sign,11'd2032};
    83   : result_out = {sign,11'd2031};
    84   : result_out = {sign,11'd2031};
    85   : result_out = {sign,11'd2031};
    86   : result_out = {sign,11'd2030};
    87   : result_out = {sign,11'd2030};
    88   : result_out = {sign,11'd2029};
    89   : result_out = {sign,11'd2029};
    90   : result_out = {sign,11'd2029};
    91   : result_out = {sign,11'd2028};
    92   : result_out = {sign,11'd2028};
    93   : result_out = {sign,11'd2027};
    94   : result_out = {sign,11'd2027};
    95   : result_out = {sign,11'd2026};
    96   : result_out = {sign,11'd2026};
    97   : result_out = {sign,11'd2025};
    98   : result_out = {sign,11'd2025};
    99   : result_out = {sign,11'd2024};
    100  : result_out = {sign,11'd2024}; 
    101  : result_out = {sign,11'd2023}; 
    102  : result_out = {sign,11'd2023}; 
    103  : result_out = {sign,11'd2022}; 
    104  : result_out = {sign,11'd2022}; 
    105  : result_out = {sign,11'd2021}; 
    106  : result_out = {sign,11'd2021}; 
    107  : result_out = {sign,11'd2020}; 
    108  : result_out = {sign,11'd2020}; 
    109  : result_out = {sign,11'd2019}; 
    110  : result_out = {sign,11'd2019}; 
    111  : result_out = {sign,11'd2018}; 
    112  : result_out = {sign,11'd2018}; 
    113  : result_out = {sign,11'd2017}; 
    114  : result_out = {sign,11'd2017}; 
    115  : result_out = {sign,11'd2016}; 
    116  : result_out = {sign,11'd2016}; 
    117  : result_out = {sign,11'd2015}; 
    118  : result_out = {sign,11'd2015}; 
    119  : result_out = {sign,11'd2014}; 
    120  : result_out = {sign,11'd2013}; 
    121  : result_out = {sign,11'd2013}; 
    122  : result_out = {sign,11'd2012}; 
    123  : result_out = {sign,11'd2012}; 
    124  : result_out = {sign,11'd2011}; 
    125  : result_out = {sign,11'd2010}; 
    126  : result_out = {sign,11'd2010}; 
    127  : result_out = {sign,11'd2009}; 
    128  : result_out = {sign,11'd2009}; 
    129  : result_out = {sign,11'd2008}; 
    130  : result_out = {sign,11'd2007}; 
    131  : result_out = {sign,11'd2007}; 
    132  : result_out = {sign,11'd2006}; 
    133  : result_out = {sign,11'd2006}; 
    134  : result_out = {sign,11'd2005}; 
    135  : result_out = {sign,11'd2004}; 
    136  : result_out = {sign,11'd2004}; 
    137  : result_out = {sign,11'd2003}; 
    138  : result_out = {sign,11'd2002}; 
    139  : result_out = {sign,11'd2002}; 
    140  : result_out = {sign,11'd2001}; 
    141  : result_out = {sign,11'd2000}; 
    142  : result_out = {sign,11'd2000}; 
    143  : result_out = {sign,11'd1999};
    144  : result_out = {sign,11'd1998};
    145  : result_out = {sign,11'd1998};
    146  : result_out = {sign,11'd1997};
    147  : result_out = {sign,11'd1996};
    148  : result_out = {sign,11'd1995};
    149  : result_out = {sign,11'd1995};
    150  : result_out = {sign,11'd1994};
    151  : result_out = {sign,11'd1993};
    152  : result_out = {sign,11'd1993};
    153  : result_out = {sign,11'd1992};
    154  : result_out = {sign,11'd1991};
    155  : result_out = {sign,11'd1990};
    156  : result_out = {sign,11'd1990};
    157  : result_out = {sign,11'd1989};
    158  : result_out = {sign,11'd1988};
    159  : result_out = {sign,11'd1987};
    160  : result_out = {sign,11'd1987};
    161  : result_out = {sign,11'd1986};
    162  : result_out = {sign,11'd1985};
    163  : result_out = {sign,11'd1984};
    164  : result_out = {sign,11'd1984};
    165  : result_out = {sign,11'd1983};
    166  : result_out = {sign,11'd1982};
    167  : result_out = {sign,11'd1981};
    168  : result_out = {sign,11'd1980};
    169  : result_out = {sign,11'd1980};
    170  : result_out = {sign,11'd1979};
    171  : result_out = {sign,11'd1978};
    172  : result_out = {sign,11'd1977};
    173  : result_out = {sign,11'd1976};
    174  : result_out = {sign,11'd1975};
    175  : result_out = {sign,11'd1975};
    176  : result_out = {sign,11'd1974};
    177  : result_out = {sign,11'd1973};
    178  : result_out = {sign,11'd1972};
    179  : result_out = {sign,11'd1971};
    180  : result_out = {sign,11'd1970};
    181  : result_out = {sign,11'd1970};
    182  : result_out = {sign,11'd1969};
    183  : result_out = {sign,11'd1968};
    184  : result_out = {sign,11'd1967};
    185  : result_out = {sign,11'd1966};
    186  : result_out = {sign,11'd1965};
    187  : result_out = {sign,11'd1964};
    188  : result_out = {sign,11'd1963};
    189  : result_out = {sign,11'd1963};
    190  : result_out = {sign,11'd1962};
    191  : result_out = {sign,11'd1961};
    192  : result_out = {sign,11'd1960};
    193  : result_out = {sign,11'd1959};
    194  : result_out = {sign,11'd1958};
    195  : result_out = {sign,11'd1957};
    196  : result_out = {sign,11'd1956};
    197  : result_out = {sign,11'd1955};
    198  : result_out = {sign,11'd1954};
    199  : result_out = {sign,11'd1953};
    200  : result_out = {sign,11'd1952};
    201  : result_out = {sign,11'd1951};
    202  : result_out = {sign,11'd1950};
    203  : result_out = {sign,11'd1950};
    204  : result_out = {sign,11'd1949};
    205  : result_out = {sign,11'd1948};
    206  : result_out = {sign,11'd1947};
    207  : result_out = {sign,11'd1946};
    208  : result_out = {sign,11'd1945};
    209  : result_out = {sign,11'd1944};
    210  : result_out = {sign,11'd1943};
    211  : result_out = {sign,11'd1942};
    212  : result_out = {sign,11'd1941};
    213  : result_out = {sign,11'd1940};
    214  : result_out = {sign,11'd1939};
    215  : result_out = {sign,11'd1938};
    216  : result_out = {sign,11'd1937};
    217  : result_out = {sign,11'd1936};
    218  : result_out = {sign,11'd1935};
    219  : result_out = {sign,11'd1934};
    220  : result_out = {sign,11'd1932};
    221  : result_out = {sign,11'd1931};
    222  : result_out = {sign,11'd1930};
    223  : result_out = {sign,11'd1929};
    224  : result_out = {sign,11'd1928};
    225  : result_out = {sign,11'd1927};
    226  : result_out = {sign,11'd1926};
    227  : result_out = {sign,11'd1925};
    228  : result_out = {sign,11'd1924};
    229  : result_out = {sign,11'd1923};
    230  : result_out = {sign,11'd1922};
    231  : result_out = {sign,11'd1921};
    232  : result_out = {sign,11'd1920};
    233  : result_out = {sign,11'd1919};
    234  : result_out = {sign,11'd1917};
    235  : result_out = {sign,11'd1916};
    236  : result_out = {sign,11'd1915};
    237  : result_out = {sign,11'd1914};
    238  : result_out = {sign,11'd1913};
    239  : result_out = {sign,11'd1912};
    240  : result_out = {sign,11'd1911};
    241  : result_out = {sign,11'd1910};
    242  : result_out = {sign,11'd1908};
    243  : result_out = {sign,11'd1907};
    244  : result_out = {sign,11'd1906};
    245  : result_out = {sign,11'd1905};
    246  : result_out = {sign,11'd1904};
    247  : result_out = {sign,11'd1903};
    248  : result_out = {sign,11'd1902};
    249  : result_out = {sign,11'd1900};
    250  : result_out = {sign,11'd1899};
    251  : result_out = {sign,11'd1898};
    252  : result_out = {sign,11'd1897};
    253  : result_out = {sign,11'd1896};
    254  : result_out = {sign,11'd1895};
    255  : result_out = {sign,11'd1893};
    256  : result_out = {sign,11'd1892};
    257  : result_out = {sign,11'd1891};
    258  : result_out = {sign,11'd1890};
    259  : result_out = {sign,11'd1888};
    260  : result_out = {sign,11'd1887};
    261  : result_out = {sign,11'd1886};
    262  : result_out = {sign,11'd1885};
    263  : result_out = {sign,11'd1884};
    264  : result_out = {sign,11'd1882};
    265  : result_out = {sign,11'd1881};
    266  : result_out = {sign,11'd1880};
    267  : result_out = {sign,11'd1879};
    268  : result_out = {sign,11'd1877};
    269  : result_out = {sign,11'd1876};
    270  : result_out = {sign,11'd1875};
    271  : result_out = {sign,11'd1874};
    272  : result_out = {sign,11'd1872};
    273  : result_out = {sign,11'd1871};
    274  : result_out = {sign,11'd1870};
    275  : result_out = {sign,11'd1868};
    276  : result_out = {sign,11'd1867};
    277  : result_out = {sign,11'd1866};
    278  : result_out = {sign,11'd1865};
    279  : result_out = {sign,11'd1863};
    280  : result_out = {sign,11'd1862};
    281  : result_out = {sign,11'd1861};
    282  : result_out = {sign,11'd1859};
    283  : result_out = {sign,11'd1858};
    284  : result_out = {sign,11'd1857};
    285  : result_out = {sign,11'd1855};
    286  : result_out = {sign,11'd1854};
    287  : result_out = {sign,11'd1853};
    288  : result_out = {sign,11'd1851};
    289  : result_out = {sign,11'd1850};
    290  : result_out = {sign,11'd1849};
    291  : result_out = {sign,11'd1847};
    292  : result_out = {sign,11'd1846};
    293  : result_out = {sign,11'd1845};
    294  : result_out = {sign,11'd1843};
    295  : result_out = {sign,11'd1842};
    296  : result_out = {sign,11'd1840};
    297  : result_out = {sign,11'd1839};
    298  : result_out = {sign,11'd1838};
    299  : result_out = {sign,11'd1836};
    300  : result_out = {sign,11'd1835};
    301  : result_out = {sign,11'd1834};
    302  : result_out = {sign,11'd1832};
    303  : result_out = {sign,11'd1831};
    304  : result_out = {sign,11'd1829};
    305  : result_out = {sign,11'd1828};
    306  : result_out = {sign,11'd1826};
    307  : result_out = {sign,11'd1825};
    308  : result_out = {sign,11'd1824};
    309  : result_out = {sign,11'd1822};
    310  : result_out = {sign,11'd1821};
    311  : result_out = {sign,11'd1819};
    312  : result_out = {sign,11'd1818};
    313  : result_out = {sign,11'd1816};
    314  : result_out = {sign,11'd1815};
    315  : result_out = {sign,11'd1814};
    316  : result_out = {sign,11'd1812};
    317  : result_out = {sign,11'd1811};
    318  : result_out = {sign,11'd1809};
    319  : result_out = {sign,11'd1808};
    320  : result_out = {sign,11'd1806};
    321  : result_out = {sign,11'd1805};
    322  : result_out = {sign,11'd1803};
    323  : result_out = {sign,11'd1802};
    324  : result_out = {sign,11'd1800};
    325  : result_out = {sign,11'd1799};
    326  : result_out = {sign,11'd1797};
    327  : result_out = {sign,11'd1796};
    328  : result_out = {sign,11'd1794};
    329  : result_out = {sign,11'd1793};
    330  : result_out = {sign,11'd1791};
    331  : result_out = {sign,11'd1790};
    332  : result_out = {sign,11'd1788};
    333  : result_out = {sign,11'd1787};
    334  : result_out = {sign,11'd1785};
    335  : result_out = {sign,11'd1783};
    336  : result_out = {sign,11'd1782};
    337  : result_out = {sign,11'd1780};
    338  : result_out = {sign,11'd1779};
    339  : result_out = {sign,11'd1777};
    340  : result_out = {sign,11'd1776};
    341  : result_out = {sign,11'd1774};
    342  : result_out = {sign,11'd1773};
    343  : result_out = {sign,11'd1771};
    344  : result_out = {sign,11'd1769};
    345  : result_out = {sign,11'd1768};
    346  : result_out = {sign,11'd1766};
    347  : result_out = {sign,11'd1765};
    348  : result_out = {sign,11'd1763};
    349  : result_out = {sign,11'd1761};
    350  : result_out = {sign,11'd1760};
    351  : result_out = {sign,11'd1758};
    352  : result_out = {sign,11'd1757};
    353  : result_out = {sign,11'd1755};
    354  : result_out = {sign,11'd1753};
    355  : result_out = {sign,11'd1752};
    356  : result_out = {sign,11'd1750};
    357  : result_out = {sign,11'd1749};
    358  : result_out = {sign,11'd1747};
    359  : result_out = {sign,11'd1745};
    360  : result_out = {sign,11'd1744};
    361  : result_out = {sign,11'd1742};
    362  : result_out = {sign,11'd1740};
    363  : result_out = {sign,11'd1739};
    364  : result_out = {sign,11'd1737};
    365  : result_out = {sign,11'd1735};
    366  : result_out = {sign,11'd1734};
    367  : result_out = {sign,11'd1732};
    368  : result_out = {sign,11'd1730};
    369  : result_out = {sign,11'd1729};
    370  : result_out = {sign,11'd1727};
    371  : result_out = {sign,11'd1725};
    372  : result_out = {sign,11'd1724};
    373  : result_out = {sign,11'd1722};
    374  : result_out = {sign,11'd1720};
    375  : result_out = {sign,11'd1718};
    376  : result_out = {sign,11'd1717};
    377  : result_out = {sign,11'd1715};
    378  : result_out = {sign,11'd1713};
    379  : result_out = {sign,11'd1712};
    380  : result_out = {sign,11'd1710};
    381  : result_out = {sign,11'd1708};
    382  : result_out = {sign,11'd1706};
    383  : result_out = {sign,11'd1705};
    384  : result_out = {sign,11'd1703};
    385  : result_out = {sign,11'd1701};
    386  : result_out = {sign,11'd1699};
    387  : result_out = {sign,11'd1698};
    388  : result_out = {sign,11'd1696};
    389  : result_out = {sign,11'd1694};
    390  : result_out = {sign,11'd1692};
    391  : result_out = {sign,11'd1691};
    392  : result_out = {sign,11'd1689};
    393  : result_out = {sign,11'd1687};
    394  : result_out = {sign,11'd1685};
    395  : result_out = {sign,11'd1683};
    396  : result_out = {sign,11'd1682};
    397  : result_out = {sign,11'd1680};
    398  : result_out = {sign,11'd1678};
    399  : result_out = {sign,11'd1676};
    400  : result_out = {sign,11'd1674};
    401  : result_out = {sign,11'd1673};
    402  : result_out = {sign,11'd1671};
    403  : result_out = {sign,11'd1669};
    404  : result_out = {sign,11'd1667};
    405  : result_out = {sign,11'd1665};
    406  : result_out = {sign,11'd1663};
    407  : result_out = {sign,11'd1662};
    408  : result_out = {sign,11'd1660};
    409  : result_out = {sign,11'd1658};
    410  : result_out = {sign,11'd1656};
    411  : result_out = {sign,11'd1654};
    412  : result_out = {sign,11'd1652};
    413  : result_out = {sign,11'd1651};
    414  : result_out = {sign,11'd1649};
    415  : result_out = {sign,11'd1647};
    416  : result_out = {sign,11'd1645};
    417  : result_out = {sign,11'd1643};
    418  : result_out = {sign,11'd1641};
    419  : result_out = {sign,11'd1639};
    420  : result_out = {sign,11'd1637};
    421  : result_out = {sign,11'd1636};
    422  : result_out = {sign,11'd1634};
    423  : result_out = {sign,11'd1632};
    424  : result_out = {sign,11'd1630};
    425  : result_out = {sign,11'd1628};
    426  : result_out = {sign,11'd1626};
    427  : result_out = {sign,11'd1624};
    428  : result_out = {sign,11'd1622};
    429  : result_out = {sign,11'd1620};
    430  : result_out = {sign,11'd1618};
    431  : result_out = {sign,11'd1616};
    432  : result_out = {sign,11'd1615};
    433  : result_out = {sign,11'd1613};
    434  : result_out = {sign,11'd1611};
    435  : result_out = {sign,11'd1609};
    436  : result_out = {sign,11'd1607};
    437  : result_out = {sign,11'd1605};
    438  : result_out = {sign,11'd1603};
    439  : result_out = {sign,11'd1601};
    440  : result_out = {sign,11'd1599};
    441  : result_out = {sign,11'd1597};
    442  : result_out = {sign,11'd1595};
    443  : result_out = {sign,11'd1593};
    444  : result_out = {sign,11'd1591};
    445  : result_out = {sign,11'd1589};
    446  : result_out = {sign,11'd1587};
    447  : result_out = {sign,11'd1585};
    448  : result_out = {sign,11'd1583};
    449  : result_out = {sign,11'd1581};
    450  : result_out = {sign,11'd1579};
    451  : result_out = {sign,11'd1577};
    452  : result_out = {sign,11'd1575};
    453  : result_out = {sign,11'd1573};
    454  : result_out = {sign,11'd1571};
    455  : result_out = {sign,11'd1569};
    456  : result_out = {sign,11'd1567};
    457  : result_out = {sign,11'd1565};
    458  : result_out = {sign,11'd1563};
    459  : result_out = {sign,11'd1561};
    460  : result_out = {sign,11'd1559};
    461  : result_out = {sign,11'd1557};
    462  : result_out = {sign,11'd1555};
    463  : result_out = {sign,11'd1553};
    464  : result_out = {sign,11'd1551};
    465  : result_out = {sign,11'd1549};
    466  : result_out = {sign,11'd1547};
    467  : result_out = {sign,11'd1545};
    468  : result_out = {sign,11'd1543};
    469  : result_out = {sign,11'd1540};
    470  : result_out = {sign,11'd1538};
    471  : result_out = {sign,11'd1536};
    472  : result_out = {sign,11'd1534};
    473  : result_out = {sign,11'd1532};
    474  : result_out = {sign,11'd1530};
    475  : result_out = {sign,11'd1528};
    476  : result_out = {sign,11'd1526};
    477  : result_out = {sign,11'd1524};
    478  : result_out = {sign,11'd1522};
    479  : result_out = {sign,11'd1520};
    480  : result_out = {sign,11'd1517};
    481  : result_out = {sign,11'd1515};
    482  : result_out = {sign,11'd1513};
    483  : result_out = {sign,11'd1511};
    484  : result_out = {sign,11'd1509};
    485  : result_out = {sign,11'd1507};
    486  : result_out = {sign,11'd1505};
    487  : result_out = {sign,11'd1503};
    488  : result_out = {sign,11'd1500};
    489  : result_out = {sign,11'd1498};
    490  : result_out = {sign,11'd1496};
    491  : result_out = {sign,11'd1494};
    492  : result_out = {sign,11'd1492};
    493  : result_out = {sign,11'd1490};
    494  : result_out = {sign,11'd1488};
    495  : result_out = {sign,11'd1485};
    496  : result_out = {sign,11'd1483};
    497  : result_out = {sign,11'd1481};
    498  : result_out = {sign,11'd1479};
    499  : result_out = {sign,11'd1477};
    500  : result_out = {sign,11'd1475};
    501  : result_out = {sign,11'd1472};
    502  : result_out = {sign,11'd1470};
    503  : result_out = {sign,11'd1468};
    504  : result_out = {sign,11'd1466};
    505  : result_out = {sign,11'd1464};
    506  : result_out = {sign,11'd1461};
    507  : result_out = {sign,11'd1459};
    508  : result_out = {sign,11'd1457};
    509  : result_out = {sign,11'd1455};
    510  : result_out = {sign,11'd1453};
    511  : result_out = {sign,11'd1450};
    512  : result_out = {sign,11'd1448};
    513  : result_out = {sign,11'd1446};
    514  : result_out = {sign,11'd1444};
    515  : result_out = {sign,11'd1441};
    516  : result_out = {sign,11'd1439};
    517  : result_out = {sign,11'd1437};
    518  : result_out = {sign,11'd1435};
    519  : result_out = {sign,11'd1433};
    520  : result_out = {sign,11'd1430};
    521  : result_out = {sign,11'd1428};
    522  : result_out = {sign,11'd1426};
    523  : result_out = {sign,11'd1424};
    524  : result_out = {sign,11'd1421};
    525  : result_out = {sign,11'd1419};
    526  : result_out = {sign,11'd1417};
    527  : result_out = {sign,11'd1414};
    528  : result_out = {sign,11'd1412};
    529  : result_out = {sign,11'd1410};
    530  : result_out = {sign,11'd1408};
    531  : result_out = {sign,11'd1405};
    532  : result_out = {sign,11'd1403};
    533  : result_out = {sign,11'd1401};
    534  : result_out = {sign,11'd1398};
    535  : result_out = {sign,11'd1396};
    536  : result_out = {sign,11'd1394};
    537  : result_out = {sign,11'd1392};
    538  : result_out = {sign,11'd1389};
    539  : result_out = {sign,11'd1387};
    540  : result_out = {sign,11'd1385};
    541  : result_out = {sign,11'd1382};
    542  : result_out = {sign,11'd1380};
    543  : result_out = {sign,11'd1378};
    544  : result_out = {sign,11'd1375};
    545  : result_out = {sign,11'd1373};
    546  : result_out = {sign,11'd1371};
    547  : result_out = {sign,11'd1368};
    548  : result_out = {sign,11'd1366};
    549  : result_out = {sign,11'd1364};
    550  : result_out = {sign,11'd1361};
    551  : result_out = {sign,11'd1359};
    552  : result_out = {sign,11'd1357};
    553  : result_out = {sign,11'd1354};
    554  : result_out = {sign,11'd1352};
    555  : result_out = {sign,11'd1350};
    556  : result_out = {sign,11'd1347};
    557  : result_out = {sign,11'd1345};
    558  : result_out = {sign,11'd1342};
    559  : result_out = {sign,11'd1340};
    560  : result_out = {sign,11'd1338};
    561  : result_out = {sign,11'd1335};
    562  : result_out = {sign,11'd1333};
    563  : result_out = {sign,11'd1331};
    564  : result_out = {sign,11'd1328};
    565  : result_out = {sign,11'd1326};
    566  : result_out = {sign,11'd1323};
    567  : result_out = {sign,11'd1321};
    568  : result_out = {sign,11'd1319};
    569  : result_out = {sign,11'd1316};
    570  : result_out = {sign,11'd1314};
    571  : result_out = {sign,11'd1311};
    572  : result_out = {sign,11'd1309};
    573  : result_out = {sign,11'd1307};
    574  : result_out = {sign,11'd1304};
    575  : result_out = {sign,11'd1302};
    576  : result_out = {sign,11'd1299};
    577  : result_out = {sign,11'd1297};
    578  : result_out = {sign,11'd1294};
    579  : result_out = {sign,11'd1292};
    580  : result_out = {sign,11'd1289};
    581  : result_out = {sign,11'd1287};
    582  : result_out = {sign,11'd1285};
    583  : result_out = {sign,11'd1282};
    584  : result_out = {sign,11'd1280};
    585  : result_out = {sign,11'd1277};
    586  : result_out = {sign,11'd1275};
    587  : result_out = {sign,11'd1272};
    588  : result_out = {sign,11'd1270};
    589  : result_out = {sign,11'd1267};
    590  : result_out = {sign,11'd1265};
    591  : result_out = {sign,11'd1262};
    592  : result_out = {sign,11'd1260};
    593  : result_out = {sign,11'd1258};
    594  : result_out = {sign,11'd1255};
    595  : result_out = {sign,11'd1253};
    596  : result_out = {sign,11'd1250};
    597  : result_out = {sign,11'd1248};
    598  : result_out = {sign,11'd1245};
    599  : result_out = {sign,11'd1243};
    600  : result_out = {sign,11'd1240};
    601  : result_out = {sign,11'd1238};
    602  : result_out = {sign,11'd1235};
    603  : result_out = {sign,11'd1233};
    604  : result_out = {sign,11'd1230};
    605  : result_out = {sign,11'd1228};
    606  : result_out = {sign,11'd1225};
    607  : result_out = {sign,11'd1223};
    608  : result_out = {sign,11'd1220};
    609  : result_out = {sign,11'd1217};
    610  : result_out = {sign,11'd1215};
    611  : result_out = {sign,11'd1212};
    612  : result_out = {sign,11'd1210};
    613  : result_out = {sign,11'd1207};
    614  : result_out = {sign,11'd1205};
    615  : result_out = {sign,11'd1202};
    616  : result_out = {sign,11'd1200};
    617  : result_out = {sign,11'd1197};
    618  : result_out = {sign,11'd1195};
    619  : result_out = {sign,11'd1192};
    620  : result_out = {sign,11'd1190};
    621  : result_out = {sign,11'd1187};
    622  : result_out = {sign,11'd1184};
    623  : result_out = {sign,11'd1182};
    624  : result_out = {sign,11'd1179};
    625  : result_out = {sign,11'd1177};
    626  : result_out = {sign,11'd1174};
    627  : result_out = {sign,11'd1172};
    628  : result_out = {sign,11'd1169};
    629  : result_out = {sign,11'd1166};
    630  : result_out = {sign,11'd1164};
    631  : result_out = {sign,11'd1161};
    632  : result_out = {sign,11'd1159};
    633  : result_out = {sign,11'd1156};
    634  : result_out = {sign,11'd1153};
    635  : result_out = {sign,11'd1151};
    636  : result_out = {sign,11'd1148};
    637  : result_out = {sign,11'd1146};
    638  : result_out = {sign,11'd1143};
    639  : result_out = {sign,11'd1140};
    640  : result_out = {sign,11'd1138};
    641  : result_out = {sign,11'd1135};
    642  : result_out = {sign,11'd1133};
    643  : result_out = {sign,11'd1130};
    644  : result_out = {sign,11'd1127};
    645  : result_out = {sign,11'd1125};
    646  : result_out = {sign,11'd1122};
    647  : result_out = {sign,11'd1119};
    648  : result_out = {sign,11'd1117};
    649  : result_out = {sign,11'd1114};
    650  : result_out = {sign,11'd1112};
    651  : result_out = {sign,11'd1109};
    652  : result_out = {sign,11'd1106};
    653  : result_out = {sign,11'd1104};
    654  : result_out = {sign,11'd1101};
    655  : result_out = {sign,11'd1098};
    656  : result_out = {sign,11'd1096};
    657  : result_out = {sign,11'd1093};
    658  : result_out = {sign,11'd1090};
    659  : result_out = {sign,11'd1088};
    660  : result_out = {sign,11'd1085};
    661  : result_out = {sign,11'd1082};
    662  : result_out = {sign,11'd1080};
    663  : result_out = {sign,11'd1077};
    664  : result_out = {sign,11'd1074};
    665  : result_out = {sign,11'd1072};
    666  : result_out = {sign,11'd1069};
    667  : result_out = {sign,11'd1066};
    668  : result_out = {sign,11'd1064};
    669  : result_out = {sign,11'd1061};
    670  : result_out = {sign,11'd1058};
    671  : result_out = {sign,11'd1056};
    672  : result_out = {sign,11'd1053};
    673  : result_out = {sign,11'd1050};
    674  : result_out = {sign,11'd1047};
    675  : result_out = {sign,11'd1045};
    676  : result_out = {sign,11'd1042};
    677  : result_out = {sign,11'd1039};
    678  : result_out = {sign,11'd1037};
    679  : result_out = {sign,11'd1034};
    680  : result_out = {sign,11'd1031};
    681  : result_out = {sign,11'd1029};
    682  : result_out = {sign,11'd1026};
    683  : result_out = {sign,11'd1023};
    684  : result_out = {sign,11'd1020};
    685  : result_out = {sign,11'd1018};
    686  : result_out = {sign,11'd1015};
    687  : result_out = {sign,11'd1012};
    688  : result_out = {sign,11'd1009};
    689  : result_out = {sign,11'd1007};
    690  : result_out = {sign,11'd1004};
    691  : result_out = {sign,11'd1001};
    692  : result_out = {sign,11'd999};
    693  : result_out = {sign,11'd996};
    694  : result_out = {sign,11'd993};
    695  : result_out = {sign,11'd990};
    696  : result_out = {sign,11'd988};
    697  : result_out = {sign,11'd985};
    698  : result_out = {sign,11'd982};
    699  : result_out = {sign,11'd979};
    700  : result_out = {sign,11'd976};
    701  : result_out = {sign,11'd974};
    702  : result_out = {sign,11'd971};
    703  : result_out = {sign,11'd968};
    704  : result_out = {sign,11'd965};
    705  : result_out = {sign,11'd963};
    706  : result_out = {sign,11'd960};
    707  : result_out = {sign,11'd957};
    708  : result_out = {sign,11'd954};
    709  : result_out = {sign,11'd952};
    710  : result_out = {sign,11'd949};
    711  : result_out = {sign,11'd946};
    712  : result_out = {sign,11'd943};
    713  : result_out = {sign,11'd940};
    714  : result_out = {sign,11'd938};
    715  : result_out = {sign,11'd935};
    716  : result_out = {sign,11'd932};
    717  : result_out = {sign,11'd929};
    718  : result_out = {sign,11'd926};
    719  : result_out = {sign,11'd924};
    720  : result_out = {sign,11'd921};
    721  : result_out = {sign,11'd918};
    722  : result_out = {sign,11'd915};
    723  : result_out = {sign,11'd912};
    724  : result_out = {sign,11'd910};
    725  : result_out = {sign,11'd907};
    726  : result_out = {sign,11'd904};
    727  : result_out = {sign,11'd901};
    728  : result_out = {sign,11'd898};
    729  : result_out = {sign,11'd895};
    730  : result_out = {sign,11'd893};
    731  : result_out = {sign,11'd890};
    732  : result_out = {sign,11'd887};
    733  : result_out = {sign,11'd884};
    734  : result_out = {sign,11'd881};
    735  : result_out = {sign,11'd878};
    736  : result_out = {sign,11'd876};
    737  : result_out = {sign,11'd873};
    738  : result_out = {sign,11'd870};
    739  : result_out = {sign,11'd867};
    740  : result_out = {sign,11'd864};
    741  : result_out = {sign,11'd861};
    742  : result_out = {sign,11'd859};
    743  : result_out = {sign,11'd856};
    744  : result_out = {sign,11'd853};
    745  : result_out = {sign,11'd850};
    746  : result_out = {sign,11'd847};
    747  : result_out = {sign,11'd844};
    748  : result_out = {sign,11'd841};
    749  : result_out = {sign,11'd839};
    750  : result_out = {sign,11'd836};
    751  : result_out = {sign,11'd833};
    752  : result_out = {sign,11'd830};
    753  : result_out = {sign,11'd827};
    754  : result_out = {sign,11'd824};
    755  : result_out = {sign,11'd821};
    756  : result_out = {sign,11'd818};
    757  : result_out = {sign,11'd816};
    758  : result_out = {sign,11'd813};
    759  : result_out = {sign,11'd810};
    760  : result_out = {sign,11'd807};
    761  : result_out = {sign,11'd804};
    762  : result_out = {sign,11'd801};
    763  : result_out = {sign,11'd798};
    764  : result_out = {sign,11'd795};
    765  : result_out = {sign,11'd792};
    766  : result_out = {sign,11'd790};
    767  : result_out = {sign,11'd787};
    768  : result_out = {sign,11'd784};
    769  : result_out = {sign,11'd781};
    770  : result_out = {sign,11'd778};
    771  : result_out = {sign,11'd775};
    772  : result_out = {sign,11'd772};
    773  : result_out = {sign,11'd769};
    774  : result_out = {sign,11'd766};
    775  : result_out = {sign,11'd763};
    776  : result_out = {sign,11'd760};
    777  : result_out = {sign,11'd758};
    778  : result_out = {sign,11'd755};
    779  : result_out = {sign,11'd752};
    780  : result_out = {sign,11'd749};
    781  : result_out = {sign,11'd746};
    782  : result_out = {sign,11'd743};
    783  : result_out = {sign,11'd740};
    784  : result_out = {sign,11'd737};
    785  : result_out = {sign,11'd734};
    786  : result_out = {sign,11'd731};
    787  : result_out = {sign,11'd728};
    788  : result_out = {sign,11'd725};
    789  : result_out = {sign,11'd722};
    790  : result_out = {sign,11'd719};
    791  : result_out = {sign,11'd717};
    792  : result_out = {sign,11'd714};
    793  : result_out = {sign,11'd711};
    794  : result_out = {sign,11'd708};
    795  : result_out = {sign,11'd705};
    796  : result_out = {sign,11'd702};
    797  : result_out = {sign,11'd699};
    798  : result_out = {sign,11'd696};
    799  : result_out = {sign,11'd693};
    800  : result_out = {sign,11'd690};
    801  : result_out = {sign,11'd687};
    802  : result_out = {sign,11'd684};
    803  : result_out = {sign,11'd681};
    804  : result_out = {sign,11'd678};
    805  : result_out = {sign,11'd675};
    806  : result_out = {sign,11'd672};
    807  : result_out = {sign,11'd669};
    808  : result_out = {sign,11'd666};
    809  : result_out = {sign,11'd663};
    810  : result_out = {sign,11'd660};
    811  : result_out = {sign,11'd657};
    812  : result_out = {sign,11'd654};
    813  : result_out = {sign,11'd651};
    814  : result_out = {sign,11'd648};
    815  : result_out = {sign,11'd645};
    816  : result_out = {sign,11'd642};
    817  : result_out = {sign,11'd639};
    818  : result_out = {sign,11'd636};
    819  : result_out = {sign,11'd633};
    820  : result_out = {sign,11'd630};
    821  : result_out = {sign,11'd627};
    822  : result_out = {sign,11'd624};
    823  : result_out = {sign,11'd622};
    824  : result_out = {sign,11'd619};
    825  : result_out = {sign,11'd616};
    826  : result_out = {sign,11'd613};
    827  : result_out = {sign,11'd610};
    828  : result_out = {sign,11'd607};
    829  : result_out = {sign,11'd604};
    830  : result_out = {sign,11'd601};
    831  : result_out = {sign,11'd598};
    832  : result_out = {sign,11'd595};
    833  : result_out = {sign,11'd591};
    834  : result_out = {sign,11'd588};
    835  : result_out = {sign,11'd585};
    836  : result_out = {sign,11'd582};
    837  : result_out = {sign,11'd579};
    838  : result_out = {sign,11'd576};
    839  : result_out = {sign,11'd573};
    840  : result_out = {sign,11'd570};
    841  : result_out = {sign,11'd567};
    842  : result_out = {sign,11'd564};
    843  : result_out = {sign,11'd561};
    844  : result_out = {sign,11'd558};
    845  : result_out = {sign,11'd555};
    846  : result_out = {sign,11'd552};
    847  : result_out = {sign,11'd549};
    848  : result_out = {sign,11'd546};
    849  : result_out = {sign,11'd543};
    850  : result_out = {sign,11'd540};
    851  : result_out = {sign,11'd537};
    852  : result_out = {sign,11'd534};
    853  : result_out = {sign,11'd531};
    854  : result_out = {sign,11'd528};
    855  : result_out = {sign,11'd525};
    856  : result_out = {sign,11'd522};
    857  : result_out = {sign,11'd519};
    858  : result_out = {sign,11'd516};
    859  : result_out = {sign,11'd513};
    860  : result_out = {sign,11'd510};
    861  : result_out = {sign,11'd507};
    862  : result_out = {sign,11'd504};
    863  : result_out = {sign,11'd501};
    864  : result_out = {sign,11'd498};
    865  : result_out = {sign,11'd495};
    866  : result_out = {sign,11'd492};
    867  : result_out = {sign,11'd488};
    868  : result_out = {sign,11'd485};
    869  : result_out = {sign,11'd482};
    870  : result_out = {sign,11'd479};
    871  : result_out = {sign,11'd476};
    872  : result_out = {sign,11'd473};
    873  : result_out = {sign,11'd470};
    874  : result_out = {sign,11'd467};
    875  : result_out = {sign,11'd464};
    876  : result_out = {sign,11'd461};
    877  : result_out = {sign,11'd458};
    878  : result_out = {sign,11'd455};
    879  : result_out = {sign,11'd452};
    880  : result_out = {sign,11'd449};
    881  : result_out = {sign,11'd446};
    882  : result_out = {sign,11'd443};
    883  : result_out = {sign,11'd440};
    884  : result_out = {sign,11'd436};
    885  : result_out = {sign,11'd433};
    886  : result_out = {sign,11'd430};
    887  : result_out = {sign,11'd427};
    888  : result_out = {sign,11'd424};
    889  : result_out = {sign,11'd421};
    890  : result_out = {sign,11'd418};
    891  : result_out = {sign,11'd415};
    892  : result_out = {sign,11'd412};
    893  : result_out = {sign,11'd409};
    894  : result_out = {sign,11'd406};
    895  : result_out = {sign,11'd403};
    896  : result_out = {sign,11'd400};
    897  : result_out = {sign,11'd396};
    898  : result_out = {sign,11'd393};
    899  : result_out = {sign,11'd390};
    900  : result_out = {sign,11'd387};
    901  : result_out = {sign,11'd384};
    902  : result_out = {sign,11'd381};
    903  : result_out = {sign,11'd378};
    904  : result_out = {sign,11'd375};
    905  : result_out = {sign,11'd372};
    906  : result_out = {sign,11'd369};
    907  : result_out = {sign,11'd366};
    908  : result_out = {sign,11'd363};
    909  : result_out = {sign,11'd359};
    910  : result_out = {sign,11'd356};
    911  : result_out = {sign,11'd353};
    912  : result_out = {sign,11'd350};
    913  : result_out = {sign,11'd347};
    914  : result_out = {sign,11'd344};
    915  : result_out = {sign,11'd341};
    916  : result_out = {sign,11'd338};
    917  : result_out = {sign,11'd335};
    918  : result_out = {sign,11'd332};
    919  : result_out = {sign,11'd328};
    920  : result_out = {sign,11'd325};
    921  : result_out = {sign,11'd322};
    922  : result_out = {sign,11'd319};
    923  : result_out = {sign,11'd316};
    924  : result_out = {sign,11'd313};
    925  : result_out = {sign,11'd310};
    926  : result_out = {sign,11'd307};
    927  : result_out = {sign,11'd304};
    928  : result_out = {sign,11'd301};
    929  : result_out = {sign,11'd297};
    930  : result_out = {sign,11'd294};
    931  : result_out = {sign,11'd291};
    932  : result_out = {sign,11'd288};
    933  : result_out = {sign,11'd285};
    934  : result_out = {sign,11'd282};
    935  : result_out = {sign,11'd279};
    936  : result_out = {sign,11'd276};
    937  : result_out = {sign,11'd273};
    938  : result_out = {sign,11'd269};
    939  : result_out = {sign,11'd266};
    940  : result_out = {sign,11'd263};
    941  : result_out = {sign,11'd260};
    942  : result_out = {sign,11'd257};
    943  : result_out = {sign,11'd254};
    944  : result_out = {sign,11'd251};
    945  : result_out = {sign,11'd248};
    946  : result_out = {sign,11'd244};
    947  : result_out = {sign,11'd241};
    948  : result_out = {sign,11'd238};
    949  : result_out = {sign,11'd235};
    950  : result_out = {sign,11'd232};
    951  : result_out = {sign,11'd229};
    952  : result_out = {sign,11'd226};
    953  : result_out = {sign,11'd223};
    954  : result_out = {sign,11'd219};
    955  : result_out = {sign,11'd216};
    956  : result_out = {sign,11'd213};
    957  : result_out = {sign,11'd210};
    958  : result_out = {sign,11'd207};
    959  : result_out = {sign,11'd204};
    960  : result_out = {sign,11'd201};
    961  : result_out = {sign,11'd198};
    962  : result_out = {sign,11'd194};
    963  : result_out = {sign,11'd191};
    964  : result_out = {sign,11'd188};
    965  : result_out = {sign,11'd185};
    966  : result_out = {sign,11'd182};
    967  : result_out = {sign,11'd179};
    968  : result_out = {sign,11'd176};
    969  : result_out = {sign,11'd173};
    970  : result_out = {sign,11'd169};
    971  : result_out = {sign,11'd166};
    972  : result_out = {sign,11'd163};
    973  : result_out = {sign,11'd160};
    974  : result_out = {sign,11'd157};
    975  : result_out = {sign,11'd154};
    976  : result_out = {sign,11'd151};
    977  : result_out = {sign,11'd148};
    978  : result_out = {sign,11'd144};
    979  : result_out = {sign,11'd141};
    980  : result_out = {sign,11'd138};
    981  : result_out = {sign,11'd135};
    982  : result_out = {sign,11'd132};
    983  : result_out = {sign,11'd129};
    984  : result_out = {sign,11'd126};
    985  : result_out = {sign,11'd122};
    986  : result_out = {sign,11'd119};
    987  : result_out = {sign,11'd116};
    988  : result_out = {sign,11'd113};
    989  : result_out = {sign,11'd110};
    990  : result_out = {sign,11'd107};
    991  : result_out = {sign,11'd104};
    992  : result_out = {sign,11'd100};
    993  : result_out = {sign,11'd97};
    994  : result_out = {sign,11'd94};
    995  : result_out = {sign,11'd91};
    996  : result_out = {sign,11'd88};
    997  : result_out = {sign,11'd85};
    998  : result_out = {sign,11'd82};
    999  : result_out = {sign,11'd79};
    1000 : result_out = {sign,11'd75};
    1001 : result_out = {sign,11'd72};
    1002 : result_out = {sign,11'd69};
    1003 : result_out = {sign,11'd66};
    1004 : result_out = {sign,11'd63};
    1005 : result_out = {sign,11'd60};
    1006 : result_out = {sign,11'd57};
    1007 : result_out = {sign,11'd53};
    1008 : result_out = {sign,11'd50};
    1009 : result_out = {sign,11'd47};
    1010 : result_out = {sign,11'd44};
    1011 : result_out = {sign,11'd41};
    1012 : result_out = {sign,11'd38};
    1013 : result_out = {sign,11'd35};
    1014 : result_out = {sign,11'd31};
    1015 : result_out = {sign,11'd28};
    1016 : result_out = {sign,11'd25};
    1017 : result_out = {sign,11'd22};
    1018 : result_out = {sign,11'd19};
    1019 : result_out = {sign,11'd16};
    1020 : result_out = {sign,11'd13};
    1021 : result_out = {sign,11'd9};
    1022 : result_out = {sign,11'd6};
    1023 : result_out = {sign,11'd3};
    default: result_out = 0; // Default case
    endcase
end

endmodule



module DivRom (
    input wire [9:0] in,
    output wire [11:0] div
);
assign div = div_out;
reg [11:0] div_out;
always @(*) begin
case(in)
0    : div_out = 12'd4095;//2^22
1    : div_out = 12'd4092;
2    : div_out = 12'd4088;
3    : div_out = 12'd4084;
4    : div_out = 12'd4080;
5    : div_out = 12'd4076;
6    : div_out = 12'd4072;
7    : div_out = 12'd4068;
8    : div_out = 12'd4064;
9    : div_out = 12'd4060;
10   : div_out = 12'd4056;
11   : div_out = 12'd4052;
12   : div_out = 12'd4049;
13   : div_out = 12'd4045;
14   : div_out = 12'd4041;
15   : div_out = 12'd4037;
16   : div_out = 12'd4033;
17   : div_out = 12'd4029;
18   : div_out = 12'd4025;
19   : div_out = 12'd4021;
20   : div_out = 12'd4018;
21   : div_out = 12'd4014;
22   : div_out = 12'd4010;
23   : div_out = 12'd4006;
24   : div_out = 12'd4002;
25   : div_out = 12'd3998;
26   : div_out = 12'd3995;
27   : div_out = 12'd3991;
28   : div_out = 12'd3987;
29   : div_out = 12'd3983;
30   : div_out = 12'd3979;
31   : div_out = 12'd3976;
32   : div_out = 12'd3972;
33   : div_out = 12'd3968;
34   : div_out = 12'd3964;
35   : div_out = 12'd3961;
36   : div_out = 12'd3957;
37   : div_out = 12'd3953;
38   : div_out = 12'd3949;
39   : div_out = 12'd3946;
40   : div_out = 12'd3942;
41   : div_out = 12'd3938;
42   : div_out = 12'd3935;
43   : div_out = 12'd3931;
44   : div_out = 12'd3927;
45   : div_out = 12'd3924;
46   : div_out = 12'd3920;
47   : div_out = 12'd3916;
48   : div_out = 12'd3913;
49   : div_out = 12'd3909;
50   : div_out = 12'd3905;
51   : div_out = 12'd3902;
52   : div_out = 12'd3898;
53   : div_out = 12'd3894;
54   : div_out = 12'd3891;
55   : div_out = 12'd3887;
56   : div_out = 12'd3884;
57   : div_out = 12'd3880;
58   : div_out = 12'd3876;
59   : div_out = 12'd3873;
60   : div_out = 12'd3869;
61   : div_out = 12'd3866;
62   : div_out = 12'd3862;
63   : div_out = 12'd3859;
64   : div_out = 12'd3855;
65   : div_out = 12'd3852;
66   : div_out = 12'd3848;
67   : div_out = 12'd3844;
68   : div_out = 12'd3841;
69   : div_out = 12'd3837;
70   : div_out = 12'd3834;
71   : div_out = 12'd3830;
72   : div_out = 12'd3827;
73   : div_out = 12'd3823;
74   : div_out = 12'd3820;
75   : div_out = 12'd3816;
76   : div_out = 12'd3813;
77   : div_out = 12'd3810;
78   : div_out = 12'd3806;
79   : div_out = 12'd3803;
80   : div_out = 12'd3799;
81   : div_out = 12'd3796;
82   : div_out = 12'd3792;
83   : div_out = 12'd3789;
84   : div_out = 12'd3785;
85   : div_out = 12'd3782;
86   : div_out = 12'd3779;
87   : div_out = 12'd3775;
88   : div_out = 12'd3772;
89   : div_out = 12'd3768;
90   : div_out = 12'd3765;
91   : div_out = 12'd3762;
92   : div_out = 12'd3758;
93   : div_out = 12'd3755;
94   : div_out = 12'd3752;
95   : div_out = 12'd3748;
96   : div_out = 12'd3745;
97   : div_out = 12'd3742;
98   : div_out = 12'd3738;
99   : div_out = 12'd3735;
100  : div_out = 12'd3732;
101  : div_out = 12'd3728;
102  : div_out = 12'd3725;
103  : div_out = 12'd3722;
104  : div_out = 12'd3718;
105  : div_out = 12'd3715;
106  : div_out = 12'd3712;
107  : div_out = 12'd3708;
108  : div_out = 12'd3705;
109  : div_out = 12'd3702;
110  : div_out = 12'd3699;
111  : div_out = 12'd3695;
112  : div_out = 12'd3692;
113  : div_out = 12'd3689;
114  : div_out = 12'd3686;
115  : div_out = 12'd3682;
116  : div_out = 12'd3679;
117  : div_out = 12'd3676;
118  : div_out = 12'd3673;
119  : div_out = 12'd3670;
120  : div_out = 12'd3666;
121  : div_out = 12'd3663;
122  : div_out = 12'd3660;
123  : div_out = 12'd3657;
124  : div_out = 12'd3654;
125  : div_out = 12'd3650;
126  : div_out = 12'd3647;
127  : div_out = 12'd3644;
128  : div_out = 12'd3641;
129  : div_out = 12'd3638;
130  : div_out = 12'd3635;
131  : div_out = 12'd3631;
132  : div_out = 12'd3628;
133  : div_out = 12'd3625;
134  : div_out = 12'd3622;
135  : div_out = 12'd3619;
136  : div_out = 12'd3616;
137  : div_out = 12'd3613;
138  : div_out = 12'd3610;
139  : div_out = 12'd3606;
140  : div_out = 12'd3603;
141  : div_out = 12'd3600;
142  : div_out = 12'd3597;
143  : div_out = 12'd3594;
144  : div_out = 12'd3591;
145  : div_out = 12'd3588;
146  : div_out = 12'd3585;
147  : div_out = 12'd3582;
148  : div_out = 12'd3579;
149  : div_out = 12'd3576;
150  : div_out = 12'd3573;
151  : div_out = 12'd3570;
152  : div_out = 12'd3567;
153  : div_out = 12'd3564;
154  : div_out = 12'd3561;
155  : div_out = 12'd3558;
156  : div_out = 12'd3554;
157  : div_out = 12'd3551;
158  : div_out = 12'd3548;
159  : div_out = 12'd3545;
160  : div_out = 12'd3542;
161  : div_out = 12'd3539;
162  : div_out = 12'd3537;
163  : div_out = 12'd3534;
164  : div_out = 12'd3531;
165  : div_out = 12'd3528;
166  : div_out = 12'd3525;
167  : div_out = 12'd3522;
168  : div_out = 12'd3519;
169  : div_out = 12'd3516;
170  : div_out = 12'd3513;
171  : div_out = 12'd3510;
172  : div_out = 12'd3507;
173  : div_out = 12'd3504;
174  : div_out = 12'd3501;
175  : div_out = 12'd3498;
176  : div_out = 12'd3495;
177  : div_out = 12'd3492;
178  : div_out = 12'd3489;
179  : div_out = 12'd3487;
180  : div_out = 12'd3484;
181  : div_out = 12'd3481;
182  : div_out = 12'd3478;
183  : div_out = 12'd3475;
184  : div_out = 12'd3472;
185  : div_out = 12'd3469;
186  : div_out = 12'd3466;
187  : div_out = 12'd3464;
188  : div_out = 12'd3461;
189  : div_out = 12'd3458;
190  : div_out = 12'd3455;
191  : div_out = 12'd3452;
192  : div_out = 12'd3449;
193  : div_out = 12'd3446;
194  : div_out = 12'd3444;
195  : div_out = 12'd3441;
196  : div_out = 12'd3438;
197  : div_out = 12'd3435;
198  : div_out = 12'd3432;
199  : div_out = 12'd3430;
200  : div_out = 12'd3427;
201  : div_out = 12'd3424;
202  : div_out = 12'd3421;
203  : div_out = 12'd3418;
204  : div_out = 12'd3416;
205  : div_out = 12'd3413;
206  : div_out = 12'd3410;
207  : div_out = 12'd3407;
208  : div_out = 12'd3404;
209  : div_out = 12'd3402;
210  : div_out = 12'd3399;
211  : div_out = 12'd3396;
212  : div_out = 12'd3393;
213  : div_out = 12'd3391;
214  : div_out = 12'd3388;
215  : div_out = 12'd3385;
216  : div_out = 12'd3383;
217  : div_out = 12'd3380;
218  : div_out = 12'd3377;
219  : div_out = 12'd3374;
220  : div_out = 12'd3372;
221  : div_out = 12'd3369;
222  : div_out = 12'd3366;
223  : div_out = 12'd3364;
224  : div_out = 12'd3361;
225  : div_out = 12'd3358;
226  : div_out = 12'd3355;
227  : div_out = 12'd3353;
228  : div_out = 12'd3350;
229  : div_out = 12'd3347;
230  : div_out = 12'd3345;
231  : div_out = 12'd3342;
232  : div_out = 12'd3339;
233  : div_out = 12'd3337;
234  : div_out = 12'd3334;
235  : div_out = 12'd3331;
236  : div_out = 12'd3329;
237  : div_out = 12'd3326;
238  : div_out = 12'd3324;
239  : div_out = 12'd3321;
240  : div_out = 12'd3318;
241  : div_out = 12'd3316;
242  : div_out = 12'd3313;
243  : div_out = 12'd3310;
244  : div_out = 12'd3308;
245  : div_out = 12'd3305;
246  : div_out = 12'd3303;
247  : div_out = 12'd3300;
248  : div_out = 12'd3297;
249  : div_out = 12'd3295;
250  : div_out = 12'd3292;
251  : div_out = 12'd3290;
252  : div_out = 12'd3287;
253  : div_out = 12'd3284;
254  : div_out = 12'd3282;
255  : div_out = 12'd3279;
256  : div_out = 12'd3277;
257  : div_out = 12'd3274;
258  : div_out = 12'd3272;
259  : div_out = 12'd3269;
260  : div_out = 12'd3267;
261  : div_out = 12'd3264;
262  : div_out = 12'd3262;
263  : div_out = 12'd3259;
264  : div_out = 12'd3256;
265  : div_out = 12'd3254;
266  : div_out = 12'd3251;
267  : div_out = 12'd3249;
268  : div_out = 12'd3246;
269  : div_out = 12'd3244;
270  : div_out = 12'd3241;
271  : div_out = 12'd3239;
272  : div_out = 12'd3236;
273  : div_out = 12'd3234;
274  : div_out = 12'd3231;
275  : div_out = 12'd3229;
276  : div_out = 12'd3226;
277  : div_out = 12'd3224;
278  : div_out = 12'd3221;
279  : div_out = 12'd3219;
280  : div_out = 12'd3216;
281  : div_out = 12'd3214;
282  : div_out = 12'd3212;
283  : div_out = 12'd3209;
284  : div_out = 12'd3207;
285  : div_out = 12'd3204;
286  : div_out = 12'd3202;
287  : div_out = 12'd3199;
288  : div_out = 12'd3197;
289  : div_out = 12'd3194;
290  : div_out = 12'd3192;
291  : div_out = 12'd3190;
292  : div_out = 12'd3187;
293  : div_out = 12'd3185;
294  : div_out = 12'd3182;
295  : div_out = 12'd3180;
296  : div_out = 12'd3178;
297  : div_out = 12'd3175;
298  : div_out = 12'd3173;
299  : div_out = 12'd3170;
300  : div_out = 12'd3168;
301  : div_out = 12'd3166;
302  : div_out = 12'd3163;
303  : div_out = 12'd3161;
304  : div_out = 12'd3158;
305  : div_out = 12'd3156;
306  : div_out = 12'd3154;
307  : div_out = 12'd3151;
308  : div_out = 12'd3149;
309  : div_out = 12'd3147;
310  : div_out = 12'd3144;
311  : div_out = 12'd3142;
312  : div_out = 12'd3139;
313  : div_out = 12'd3137;
314  : div_out = 12'd3135;
315  : div_out = 12'd3132;
316  : div_out = 12'd3130;
317  : div_out = 12'd3128;
318  : div_out = 12'd3125;
319  : div_out = 12'd3123;
320  : div_out = 12'd3121;
321  : div_out = 12'd3118;
322  : div_out = 12'd3116;
323  : div_out = 12'd3114;
324  : div_out = 12'd3112;
325  : div_out = 12'd3109;
326  : div_out = 12'd3107;
327  : div_out = 12'd3105;
328  : div_out = 12'd3102;
329  : div_out = 12'd3100;
330  : div_out = 12'd3098;
331  : div_out = 12'd3095;
332  : div_out = 12'd3093;
333  : div_out = 12'd3091;
334  : div_out = 12'd3089;
335  : div_out = 12'd3086;
336  : div_out = 12'd3084;
337  : div_out = 12'd3082;
338  : div_out = 12'd3080;
339  : div_out = 12'd3077;
340  : div_out = 12'd3075;
341  : div_out = 12'd3073;
342  : div_out = 12'd3071;
343  : div_out = 12'd3068;
344  : div_out = 12'd3066;
345  : div_out = 12'd3064;
346  : div_out = 12'd3062;
347  : div_out = 12'd3059;
348  : div_out = 12'd3057;
349  : div_out = 12'd3055;
350  : div_out = 12'd3053;
351  : div_out = 12'd3050;
352  : div_out = 12'd3048;
353  : div_out = 12'd3046;
354  : div_out = 12'd3044;
355  : div_out = 12'd3042;
356  : div_out = 12'd3039;
357  : div_out = 12'd3037;
358  : div_out = 12'd3035;
359  : div_out = 12'd3033;
360  : div_out = 12'd3031;
361  : div_out = 12'd3028;
362  : div_out = 12'd3026;
363  : div_out = 12'd3024;
364  : div_out = 12'd3022;
365  : div_out = 12'd3020;
366  : div_out = 12'd3017;
367  : div_out = 12'd3015;
368  : div_out = 12'd3013;
369  : div_out = 12'd3011;
370  : div_out = 12'd3009;
371  : div_out = 12'd3007;
372  : div_out = 12'd3005;
373  : div_out = 12'd3002;
374  : div_out = 12'd3000;
375  : div_out = 12'd2998;
376  : div_out = 12'd2996;
377  : div_out = 12'd2994;
378  : div_out = 12'd2992;
379  : div_out = 12'd2990;
380  : div_out = 12'd2987;
381  : div_out = 12'd2985;
382  : div_out = 12'd2983;
383  : div_out = 12'd2981;
384  : div_out = 12'd2979;
385  : div_out = 12'd2977;
386  : div_out = 12'd2975;
387  : div_out = 12'd2973;
388  : div_out = 12'd2970;
389  : div_out = 12'd2968;
390  : div_out = 12'd2966;
391  : div_out = 12'd2964;
392  : div_out = 12'd2962;
393  : div_out = 12'd2960;
394  : div_out = 12'd2958;
395  : div_out = 12'd2956;
396  : div_out = 12'd2954;
397  : div_out = 12'd2952;
398  : div_out = 12'd2950;
399  : div_out = 12'd2948;
400  : div_out = 12'd2945;
401  : div_out = 12'd2943;
402  : div_out = 12'd2941;
403  : div_out = 12'd2939;
404  : div_out = 12'd2937;
405  : div_out = 12'd2935;
406  : div_out = 12'd2933;
407  : div_out = 12'd2931;
408  : div_out = 12'd2929;
409  : div_out = 12'd2927;
410  : div_out = 12'd2925;
411  : div_out = 12'd2923;
412  : div_out = 12'd2921;
413  : div_out = 12'd2919;
414  : div_out = 12'd2917;
415  : div_out = 12'd2915;
416  : div_out = 12'd2913;
417  : div_out = 12'd2911;
418  : div_out = 12'd2909;
419  : div_out = 12'd2907;
420  : div_out = 12'd2905;
421  : div_out = 12'd2903;
422  : div_out = 12'd2901;
423  : div_out = 12'd2899;
424  : div_out = 12'd2897;
425  : div_out = 12'd2895;
426  : div_out = 12'd2893;
427  : div_out = 12'd2891;
428  : div_out = 12'd2889;
429  : div_out = 12'd2887;
430  : div_out = 12'd2885;
431  : div_out = 12'd2883;
432  : div_out = 12'd2881;
433  : div_out = 12'd2879;
434  : div_out = 12'd2877;
435  : div_out = 12'd2875;
436  : div_out = 12'd2873;
437  : div_out = 12'd2871;
438  : div_out = 12'd2869;
439  : div_out = 12'd2867;
440  : div_out = 12'd2865;
441  : div_out = 12'd2863;
442  : div_out = 12'd2861;
443  : div_out = 12'd2859;
444  : div_out = 12'd2857;
445  : div_out = 12'd2855;
446  : div_out = 12'd2853;
447  : div_out = 12'd2851;
448  : div_out = 12'd2849;
449  : div_out = 12'd2847;
450  : div_out = 12'd2846;
451  : div_out = 12'd2844;
452  : div_out = 12'd2842;
453  : div_out = 12'd2840;
454  : div_out = 12'd2838;
455  : div_out = 12'd2836;
456  : div_out = 12'd2834;
457  : div_out = 12'd2832;
458  : div_out = 12'd2830;
459  : div_out = 12'd2828;
460  : div_out = 12'd2826;
461  : div_out = 12'd2824;
462  : div_out = 12'd2823;
463  : div_out = 12'd2821;
464  : div_out = 12'd2819;
465  : div_out = 12'd2817;
466  : div_out = 12'd2815;
467  : div_out = 12'd2813;
468  : div_out = 12'd2811;
469  : div_out = 12'd2809;
470  : div_out = 12'd2807;
471  : div_out = 12'd2806;
472  : div_out = 12'd2804;
473  : div_out = 12'd2802;
474  : div_out = 12'd2800;
475  : div_out = 12'd2798;
476  : div_out = 12'd2796;
477  : div_out = 12'd2794;
478  : div_out = 12'd2792;
479  : div_out = 12'd2791;
480  : div_out = 12'd2789;
481  : div_out = 12'd2787;
482  : div_out = 12'd2785;
483  : div_out = 12'd2783;
484  : div_out = 12'd2781;
485  : div_out = 12'd2780;
486  : div_out = 12'd2778;
487  : div_out = 12'd2776;
488  : div_out = 12'd2774;
489  : div_out = 12'd2772;
490  : div_out = 12'd2770;
491  : div_out = 12'd2769;
492  : div_out = 12'd2767;
493  : div_out = 12'd2765;
494  : div_out = 12'd2763;
495  : div_out = 12'd2761;
496  : div_out = 12'd2759;
497  : div_out = 12'd2758;
498  : div_out = 12'd2756;
499  : div_out = 12'd2754;
500  : div_out = 12'd2752;
501  : div_out = 12'd2750;
502  : div_out = 12'd2749;
503  : div_out = 12'd2747;
504  : div_out = 12'd2745;
505  : div_out = 12'd2743;
506  : div_out = 12'd2741;
507  : div_out = 12'd2740;
508  : div_out = 12'd2738;
509  : div_out = 12'd2736;
510  : div_out = 12'd2734;
511  : div_out = 12'd2732;
512  : div_out = 12'd2731;
513  : div_out = 12'd2729;
514  : div_out = 12'd2727;
515  : div_out = 12'd2725;
516  : div_out = 12'd2724;
517  : div_out = 12'd2722;
518  : div_out = 12'd2720;
519  : div_out = 12'd2718;
520  : div_out = 12'd2717;
521  : div_out = 12'd2715;
522  : div_out = 12'd2713;
523  : div_out = 12'd2711;
524  : div_out = 12'd2709;
525  : div_out = 12'd2708;
526  : div_out = 12'd2706;
527  : div_out = 12'd2704;
528  : div_out = 12'd2703;
529  : div_out = 12'd2701;
530  : div_out = 12'd2699;
531  : div_out = 12'd2697;
532  : div_out = 12'd2696;
533  : div_out = 12'd2694;
534  : div_out = 12'd2692;
535  : div_out = 12'd2690;
536  : div_out = 12'd2689;
537  : div_out = 12'd2687;
538  : div_out = 12'd2685;
539  : div_out = 12'd2683;
540  : div_out = 12'd2682;
541  : div_out = 12'd2680;
542  : div_out = 12'd2678;
543  : div_out = 12'd2677;
544  : div_out = 12'd2675;
545  : div_out = 12'd2673;
546  : div_out = 12'd2672;
547  : div_out = 12'd2670;
548  : div_out = 12'd2668;
549  : div_out = 12'd2666;
550  : div_out = 12'd2665;
551  : div_out = 12'd2663;
552  : div_out = 12'd2661;
553  : div_out = 12'd2660;
554  : div_out = 12'd2658;
555  : div_out = 12'd2656;
556  : div_out = 12'd2655;
557  : div_out = 12'd2653;
558  : div_out = 12'd2651;
559  : div_out = 12'd2650;
560  : div_out = 12'd2648;
561  : div_out = 12'd2646;
562  : div_out = 12'd2645;
563  : div_out = 12'd2643;
564  : div_out = 12'd2641;
565  : div_out = 12'd2640;
566  : div_out = 12'd2638;
567  : div_out = 12'd2636;
568  : div_out = 12'd2635;
569  : div_out = 12'd2633;
570  : div_out = 12'd2631;
571  : div_out = 12'd2630;
572  : div_out = 12'd2628;
573  : div_out = 12'd2626;
574  : div_out = 12'd2625;
575  : div_out = 12'd2623;
576  : div_out = 12'd2621;
577  : div_out = 12'd2620;
578  : div_out = 12'd2618;
579  : div_out = 12'd2617;
580  : div_out = 12'd2615;
581  : div_out = 12'd2613;
582  : div_out = 12'd2612;
583  : div_out = 12'd2610;
584  : div_out = 12'd2608;
585  : div_out = 12'd2607;
586  : div_out = 12'd2605;
587  : div_out = 12'd2604;
588  : div_out = 12'd2602;
589  : div_out = 12'd2600;
590  : div_out = 12'd2599;
591  : div_out = 12'd2597;
592  : div_out = 12'd2595;
593  : div_out = 12'd2594;
594  : div_out = 12'd2592;
595  : div_out = 12'd2591;
596  : div_out = 12'd2589;
597  : div_out = 12'd2587;
598  : div_out = 12'd2586;
599  : div_out = 12'd2584;
600  : div_out = 12'd2583;
601  : div_out = 12'd2581;
602  : div_out = 12'd2580;
603  : div_out = 12'd2578;
604  : div_out = 12'd2576;
605  : div_out = 12'd2575;
606  : div_out = 12'd2573;
607  : div_out = 12'd2572;
608  : div_out = 12'd2570;
609  : div_out = 12'd2568;
610  : div_out = 12'd2567;
611  : div_out = 12'd2565;
612  : div_out = 12'd2564;
613  : div_out = 12'd2562;
614  : div_out = 12'd2561;
615  : div_out = 12'd2559;
616  : div_out = 12'd2558;
617  : div_out = 12'd2556;
618  : div_out = 12'd2554;
619  : div_out = 12'd2553;
620  : div_out = 12'd2551;
621  : div_out = 12'd2550;
622  : div_out = 12'd2548;
623  : div_out = 12'd2547;
624  : div_out = 12'd2545;
625  : div_out = 12'd2544;
626  : div_out = 12'd2542;
627  : div_out = 12'd2540;
628  : div_out = 12'd2539;
629  : div_out = 12'd2537;
630  : div_out = 12'd2536;
631  : div_out = 12'd2534;
632  : div_out = 12'd2533;
633  : div_out = 12'd2531;
634  : div_out = 12'd2530;
635  : div_out = 12'd2528;
636  : div_out = 12'd2527;
637  : div_out = 12'd2525;
638  : div_out = 12'd2524;
639  : div_out = 12'd2522;
640  : div_out = 12'd2521;
641  : div_out = 12'd2519;
642  : div_out = 12'd2518;
643  : div_out = 12'd2516;
644  : div_out = 12'd2515;
645  : div_out = 12'd2513;
646  : div_out = 12'd2512;
647  : div_out = 12'd2510;
648  : div_out = 12'd2509;
649  : div_out = 12'd2507;
650  : div_out = 12'd2506;
651  : div_out = 12'd2504;
652  : div_out = 12'd2503;
653  : div_out = 12'd2501;
654  : div_out = 12'd2500;
655  : div_out = 12'd2498;
656  : div_out = 12'd2497;
657  : div_out = 12'd2495;
658  : div_out = 12'd2494;
659  : div_out = 12'd2492;
660  : div_out = 12'd2491;
661  : div_out = 12'd2489;
662  : div_out = 12'd2488;
663  : div_out = 12'd2486;
664  : div_out = 12'd2485;
665  : div_out = 12'd2483;
666  : div_out = 12'd2482;
667  : div_out = 12'd2480;
668  : div_out = 12'd2479;
669  : div_out = 12'd2477;
670  : div_out = 12'd2476;
671  : div_out = 12'd2475;
672  : div_out = 12'd2473;
673  : div_out = 12'd2472;
674  : div_out = 12'd2470;
675  : div_out = 12'd2469;
676  : div_out = 12'd2467;
677  : div_out = 12'd2466;
678  : div_out = 12'd2464;
679  : div_out = 12'd2463;
680  : div_out = 12'd2461;
681  : div_out = 12'd2460;
682  : div_out = 12'd2459;
683  : div_out = 12'd2457;
684  : div_out = 12'd2456;
685  : div_out = 12'd2454;
686  : div_out = 12'd2453;
687  : div_out = 12'd2451;
688  : div_out = 12'd2450;
689  : div_out = 12'd2449;
690  : div_out = 12'd2447;
691  : div_out = 12'd2446;
692  : div_out = 12'd2444;
693  : div_out = 12'd2443;
694  : div_out = 12'd2441;
695  : div_out = 12'd2440;
696  : div_out = 12'd2439;
697  : div_out = 12'd2437;
698  : div_out = 12'd2436;
699  : div_out = 12'd2434;
700  : div_out = 12'd2433;
701  : div_out = 12'd2431;
702  : div_out = 12'd2430;
703  : div_out = 12'd2429;
704  : div_out = 12'd2427;
705  : div_out = 12'd2426;
706  : div_out = 12'd2424;
707  : div_out = 12'd2423;
708  : div_out = 12'd2422;
709  : div_out = 12'd2420;
710  : div_out = 12'd2419;
711  : div_out = 12'd2417;
712  : div_out = 12'd2416;
713  : div_out = 12'd2415;
714  : div_out = 12'd2413;
715  : div_out = 12'd2412;
716  : div_out = 12'd2411;
717  : div_out = 12'd2409;
718  : div_out = 12'd2408;
719  : div_out = 12'd2406;
720  : div_out = 12'd2405;
721  : div_out = 12'd2404;
722  : div_out = 12'd2402;
723  : div_out = 12'd2401;
724  : div_out = 12'd2399;
725  : div_out = 12'd2398;
726  : div_out = 12'd2397;
727  : div_out = 12'd2395;
728  : div_out = 12'd2394;
729  : div_out = 12'd2393;
730  : div_out = 12'd2391;
731  : div_out = 12'd2390;
732  : div_out = 12'd2389;
733  : div_out = 12'd2387;
734  : div_out = 12'd2386;
735  : div_out = 12'd2384;
736  : div_out = 12'd2383;
737  : div_out = 12'd2382;
738  : div_out = 12'd2380;
739  : div_out = 12'd2379;
740  : div_out = 12'd2378;
741  : div_out = 12'd2376;
742  : div_out = 12'd2375;
743  : div_out = 12'd2374;
744  : div_out = 12'd2372;
745  : div_out = 12'd2371;
746  : div_out = 12'd2370;
747  : div_out = 12'd2368;
748  : div_out = 12'd2367;
749  : div_out = 12'd2366;
750  : div_out = 12'd2364;
751  : div_out = 12'd2363;
752  : div_out = 12'd2362;
753  : div_out = 12'd2360;
754  : div_out = 12'd2359;
755  : div_out = 12'd2358;
756  : div_out = 12'd2356;
757  : div_out = 12'd2355;
758  : div_out = 12'd2354;
759  : div_out = 12'd2352;
760  : div_out = 12'd2351;
761  : div_out = 12'd2350;
762  : div_out = 12'd2348;
763  : div_out = 12'd2347;
764  : div_out = 12'd2346;
765  : div_out = 12'd2344;
766  : div_out = 12'd2343;
767  : div_out = 12'd2342;
768  : div_out = 12'd2341;
769  : div_out = 12'd2339;
770  : div_out = 12'd2338;
771  : div_out = 12'd2337;
772  : div_out = 12'd2335;
773  : div_out = 12'd2334;
774  : div_out = 12'd2333;
775  : div_out = 12'd2331;
776  : div_out = 12'd2330;
777  : div_out = 12'd2329;
778  : div_out = 12'd2328;
779  : div_out = 12'd2326;
780  : div_out = 12'd2325;
781  : div_out = 12'd2324;
782  : div_out = 12'd2322;
783  : div_out = 12'd2321;
784  : div_out = 12'd2320;
785  : div_out = 12'd2319;
786  : div_out = 12'd2317;
787  : div_out = 12'd2316;
788  : div_out = 12'd2315;
789  : div_out = 12'd2313;
790  : div_out = 12'd2312;
791  : div_out = 12'd2311;
792  : div_out = 12'd2310;
793  : div_out = 12'd2308;
794  : div_out = 12'd2307;
795  : div_out = 12'd2306;
796  : div_out = 12'd2305;
797  : div_out = 12'd2303;
798  : div_out = 12'd2302;
799  : div_out = 12'd2301;
800  : div_out = 12'd2300;
801  : div_out = 12'd2298;
802  : div_out = 12'd2297;
803  : div_out = 12'd2296;
804  : div_out = 12'd2294;
805  : div_out = 12'd2293;
806  : div_out = 12'd2292;
807  : div_out = 12'd2291;
808  : div_out = 12'd2289;
809  : div_out = 12'd2288;
810  : div_out = 12'd2287;
811  : div_out = 12'd2286;
812  : div_out = 12'd2284;
813  : div_out = 12'd2283;
814  : div_out = 12'd2282;
815  : div_out = 12'd2281;
816  : div_out = 12'd2280;
817  : div_out = 12'd2278;
818  : div_out = 12'd2277;
819  : div_out = 12'd2276;
820  : div_out = 12'd2275;
821  : div_out = 12'd2273;
822  : div_out = 12'd2272;
823  : div_out = 12'd2271;
824  : div_out = 12'd2270;
825  : div_out = 12'd2268;
826  : div_out = 12'd2267;
827  : div_out = 12'd2266;
828  : div_out = 12'd2265;
829  : div_out = 12'd2264;
830  : div_out = 12'd2262;
831  : div_out = 12'd2261;
832  : div_out = 12'd2260;
833  : div_out = 12'd2259;
834  : div_out = 12'd2257;
835  : div_out = 12'd2256;
836  : div_out = 12'd2255;
837  : div_out = 12'd2254;
838  : div_out = 12'd2253;
839  : div_out = 12'd2251;
840  : div_out = 12'd2250;
841  : div_out = 12'd2249;
842  : div_out = 12'd2248;
843  : div_out = 12'd2247;
844  : div_out = 12'd2245;
845  : div_out = 12'd2244;
846  : div_out = 12'd2243;
847  : div_out = 12'd2242;
848  : div_out = 12'd2241;
849  : div_out = 12'd2239;
850  : div_out = 12'd2238;
851  : div_out = 12'd2237;
852  : div_out = 12'd2236;
853  : div_out = 12'd2235;
854  : div_out = 12'd2233;
855  : div_out = 12'd2232;
856  : div_out = 12'd2231;
857  : div_out = 12'd2230;
858  : div_out = 12'd2229;
859  : div_out = 12'd2227;
860  : div_out = 12'd2226;
861  : div_out = 12'd2225;
862  : div_out = 12'd2224;
863  : div_out = 12'd2223;
864  : div_out = 12'd2222;
865  : div_out = 12'd2220;
866  : div_out = 12'd2219;
867  : div_out = 12'd2218;
868  : div_out = 12'd2217;
869  : div_out = 12'd2216;
870  : div_out = 12'd2215;
871  : div_out = 12'd2213;
872  : div_out = 12'd2212;
873  : div_out = 12'd2211;
874  : div_out = 12'd2210;
875  : div_out = 12'd2209;
876  : div_out = 12'd2208;
877  : div_out = 12'd2206;
878  : div_out = 12'd2205;
879  : div_out = 12'd2204;
880  : div_out = 12'd2203;
881  : div_out = 12'd2202;
882  : div_out = 12'd2201;
883  : div_out = 12'd2199;
884  : div_out = 12'd2198;
885  : div_out = 12'd2197;
886  : div_out = 12'd2196;
887  : div_out = 12'd2195;
888  : div_out = 12'd2194;
889  : div_out = 12'd2193;
890  : div_out = 12'd2191;
891  : div_out = 12'd2190;
892  : div_out = 12'd2189;
893  : div_out = 12'd2188;
894  : div_out = 12'd2187;
895  : div_out = 12'd2186;
896  : div_out = 12'd2185;
897  : div_out = 12'd2183;
898  : div_out = 12'd2182;
899  : div_out = 12'd2181;
900  : div_out = 12'd2180;
901  : div_out = 12'd2179;
902  : div_out = 12'd2178;
903  : div_out = 12'd2177;
904  : div_out = 12'd2175;
905  : div_out = 12'd2174;
906  : div_out = 12'd2173;
907  : div_out = 12'd2172;
908  : div_out = 12'd2171;
909  : div_out = 12'd2170;
910  : div_out = 12'd2169;
911  : div_out = 12'd2168;
912  : div_out = 12'd2166;
913  : div_out = 12'd2165;
914  : div_out = 12'd2164;
915  : div_out = 12'd2163;
916  : div_out = 12'd2162;
917  : div_out = 12'd2161;
918  : div_out = 12'd2160;
919  : div_out = 12'd2159;
920  : div_out = 12'd2158;
921  : div_out = 12'd2156;
922  : div_out = 12'd2155;
923  : div_out = 12'd2154;
924  : div_out = 12'd2153;
925  : div_out = 12'd2152;
926  : div_out = 12'd2151;
927  : div_out = 12'd2150;
928  : div_out = 12'd2149;
929  : div_out = 12'd2148;
930  : div_out = 12'd2147;
931  : div_out = 12'd2145;
932  : div_out = 12'd2144;
933  : div_out = 12'd2143;
934  : div_out = 12'd2142;
935  : div_out = 12'd2141;
936  : div_out = 12'd2140;
937  : div_out = 12'd2139;
938  : div_out = 12'd2138;
939  : div_out = 12'd2137;
940  : div_out = 12'd2136;
941  : div_out = 12'd2135;
942  : div_out = 12'd2133;
943  : div_out = 12'd2132;
944  : div_out = 12'd2131;
945  : div_out = 12'd2130;
946  : div_out = 12'd2129;
947  : div_out = 12'd2128;
948  : div_out = 12'd2127;
949  : div_out = 12'd2126;
950  : div_out = 12'd2125;
951  : div_out = 12'd2124;
952  : div_out = 12'd2123;
953  : div_out = 12'd2122;
954  : div_out = 12'd2120;
955  : div_out = 12'd2119;
956  : div_out = 12'd2118;
957  : div_out = 12'd2117;
958  : div_out = 12'd2116;
959  : div_out = 12'd2115;
960  : div_out = 12'd2114;
961  : div_out = 12'd2113;
962  : div_out = 12'd2112;
963  : div_out = 12'd2111;
964  : div_out = 12'd2110;
965  : div_out = 12'd2109;
966  : div_out = 12'd2108;
967  : div_out = 12'd2107;
968  : div_out = 12'd2106;
969  : div_out = 12'd2105;
970  : div_out = 12'd2103;
971  : div_out = 12'd2102;
972  : div_out = 12'd2101;
973  : div_out = 12'd2100;
974  : div_out = 12'd2099;
975  : div_out = 12'd2098;
976  : div_out = 12'd2097;
977  : div_out = 12'd2096;
978  : div_out = 12'd2095;
979  : div_out = 12'd2094;
980  : div_out = 12'd2093;
981  : div_out = 12'd2092;
982  : div_out = 12'd2091;
983  : div_out = 12'd2090;
984  : div_out = 12'd2089;
985  : div_out = 12'd2088;
986  : div_out = 12'd2087;
987  : div_out = 12'd2086;
988  : div_out = 12'd2085;
989  : div_out = 12'd2084;
990  : div_out = 12'd2083;
991  : div_out = 12'd2082;
992  : div_out = 12'd2081;
993  : div_out = 12'd2079;
994  : div_out = 12'd2078;
995  : div_out = 12'd2077;
996  : div_out = 12'd2076;
997  : div_out = 12'd2075;
998  : div_out = 12'd2074;
999  : div_out = 12'd2073;
1000 : div_out = 12'd2072;
1001 : div_out = 12'd2071;
1002 : div_out = 12'd2070;
1003 : div_out = 12'd2069;
1004 : div_out = 12'd2068;
1005 : div_out = 12'd2067;
1006 : div_out = 12'd2066;
1007 : div_out = 12'd2065;
1008 : div_out = 12'd2064;
1009 : div_out = 12'd2063;
1010 : div_out = 12'd2062;
1011 : div_out = 12'd2061;
1012 : div_out = 12'd2060;
1013 : div_out = 12'd2059;
1014 : div_out = 12'd2058;
1015 : div_out = 12'd2057;
1016 : div_out = 12'd2056;
1017 : div_out = 12'd2055;
1018 : div_out = 12'd2054;
1019 : div_out = 12'd2053;
1020 : div_out = 12'd2052;
1021 : div_out = 12'd2051;
1022 : div_out = 12'd2050;
1023 : div_out = 12'd2049;
default : div_out = 12'd0;
endcase
end

assign div = div_out;
endmodule

