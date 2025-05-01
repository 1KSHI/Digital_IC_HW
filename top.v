module top(
    input clk,
    input rst,
    input [11:0]a,
    input [11:0]b,
    input [11:0]c,
    input [11:0]e,
    output [12:0] y,
    output [11:0] d
);
reg [11:0] d_reg;
assign d = d_reg;
reg [3:0]count;
wire init_end = (count == 4'd12) ? 1'b1 : 1'b0;


always @(posedge clk) begin
    if (rst) begin
        count <= 0;
        d_reg <= 0;
    end else if(!init_end) begin
        count <= count + 1;
        d_reg <= d_reg + (e<<count);
    end else begin
        count <= 4'd12;
        d_reg <= d_reg;
    end
end

reg [11:0] a_reg;
reg [11:0] b_reg;
reg [11:0] c_reg;

always @(posedge clk) begin
    if (rst) begin
        a_reg <= 0;
        b_reg <= 0;
        c_reg <= 0;
    end else begin
        a_reg <= a;
        b_reg <= b;
        c_reg <= c;
    end
end

//(a+d)  
//============= cycle 1 ==============
wire [12:0] Fir1_wire;
wire [11:0] Fir2_wire;
wire sign = Fir2_reg[11];
reg [12:0] Fir1_reg;//(a+d)
reg [11:0] Fir2_reg;//cos c>>12
reg [11:0] Fir3_reg;//cos c>>12

Adder12 Adder12 (
    .x_in(a_reg),
    .y_in(d_reg),
    .result_out(Fir1_wire)
);

Rom Rom(
    .x_in       	(c_reg        ),
    .res_out 	    (Fir2_wire    )
);

always @(posedge clk) begin
    if (rst) begin
        Fir1_reg <= 0;
        Fir2_reg <= 0;
        Fir3_reg <= 0;
    end else begin
        Fir1_reg <= Fir1_wire;
        Fir2_reg <= Fir2_wire;
        Fir3_reg <= a_reg;
    end
end

//a/(a+d)    //b*cos c>>12  //fifo
//============= cycle 2 ==============
wire [11:0] Sec1_wire;
wire [23:0] Sec2_wire;
wire done;
reg [11:0] Sec1_reg;//a*b/(a+d)
reg [23:0] Sec2_reg;//(b*cos c)>>12

ResDivider ResDivider(
    .clk       	(clk          ),
    .rst       	(rst          ),
    .start 	    (init_end     ),
    .dividend   ({1'b0,Fir3_reg} ),
    .divisor 	(Fir1_reg     ),
    .quotient   (Sec1_wire    ),//Q1.12
    .done 	    (done         )
);


Wallace12x12 Wallace12x12 (
    .x_in(b_reg         ),//Q12 
    .y_in({Fir2_reg[10:0],1'b0}),//Q.12
    .result_out(Sec2_wire)
);

wire [11:0] fifo_out;
wire fifo_full;
wire fifo_empty;

fifo #(
    .DATAWIDTH(12),
    .DEPTH(16)
) fifo (
    .clk        (clk            ),
    .rst        (rst            ),
    .data_in    (Sec2_wire[23:12]),//Q12
    .wr_en      (init_end       ),
    .rd_en      (done           ),
    .data_out   (fifo_out       ),
    .full       (fifo_full      ),
    .empty      (fifo_empty     )
);


always @(posedge clk) begin
    if (rst) begin
        Sec1_reg <= 0;
        Sec2_reg <= 0;
    end else begin
        Sec1_reg <= Sec1_wire;
        Sec2_reg <= Sec2_wire;
    end
end


//a/(a+d) *  b*cos c>>12
//============= cycle 3 ==============
wire [23:0] Thi1_wire;
reg [11:0] Thi1_reg;

Wallace12x12 Wallace12x12_2 (
    .x_in({Sec1_reg[10:0],1'b0}       ),//Q.12
    .y_in(fifo_out       ),//Q.12
    .result_out(Thi1_wire)
);

always @(posedge clk) begin
    if (rst) begin
        Thi1_reg <= 0;
    end else begin
        Thi1_reg <= Thi1_wire[23:12];
    end
end

reg [2:0]finish;
always @(posedge clk) begin
    if (rst) begin
        finish[0] <= 0;
        finish[1] <= 0;
        finish[2] <= 0;
    end else begin
        finish[0] <= done;
        finish[1] <= finish[0];
        finish[2] <= finish[1];
    end
end


assign y = {sign,Thi1_reg};

endmodule


module HalfAdder(a, b, sum, cout);

input a, b;
output sum, cout;

assign	sum = a ^ b;
assign	cout = a & b;

endmodule

module 	FullAdder(a, b, cin, sum, cout);

input 	a, b, cin;
output 	sum, cout;

assign	sum = a ^ b ^ cin;
assign 	cout = (a & b) | (a & cin) | (b & cin);

endmodule


module	Wallace12x12 ( 
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

wire [23:0] result_temp = opa + opb;

assign result_out = result_temp[23:0];

// adder_24bit adder_24bit_inst(
//     .opa(opa),
//     .opb(opb),
//     .result_out(result_out)
// );

endmodule


module adder_24bit(
    input [23:0] opa,
    input [23:0] opb,
    output [23:0] result_out
);

//============== First Level =================================================
wire [7:0] res_7_0;
wire sw2;

cla_8bit u_carry_ahead(
    .A(opa[7:0]),
    .B(opb[7:0]),
    .Cin(1'b0),
    .Sum(res_7_0),
    .Cout(sw2)
);

//============== Second Level =================================================
wire [7:0] res_15_8_1, res_15_8_0;
wire [7:0] res_15_8_fin;
wire sw3_1, sw3_0, sw3;

cla_8bit u_carry_ahead_21(
    .A(opa[15:8]),
    .B(opb[15:8]),
    .Cin(1'b1),
    .Sum(res_15_8_1),
    .Cout(sw3_1)
);

cla_8bit u_carry_ahead_20(
    .A(opa[15:8]),
    .B(opb[15:8]),
    .Cin(1'b0),
    .Sum(res_15_8_0),
    .Cout(sw3_0)
);

assign res_15_8_fin = sw2? (res_15_8_1) : (res_15_8_0);
assign sw3 = sw2 ? sw3_1 : sw3_0;

//============== Third  Level =================================================
wire [7:0] res_23_16_1, res_23_16_0;
wire [7:0] res_23_16_fin;
wire cout_0, cout_1;

cla_8bit u_carry_ahead_31(
    .A(opa[23:16]),
    .B(opb[23:16]),
    .Cin(1'b1),
    .Sum(res_23_16_1),
    .Cout(cout_1)
);

cla_8bit u_carry_ahead_30(
    .A(opa[23:16]),
    .B(opb[23:16]),
    .Cin(1'b0),
    .Sum(res_23_16_0),
    .Cout(cout_0)
);

assign res_23_16_fin = sw3? (res_23_16_1) : (res_23_16_0);

assign result_out = {res_23_16_fin, res_15_8_fin, res_7_0};

endmodule

module cla_8bit(
    input [7:0] A,
    input [7:0] B,
    input Cin,
    output [7:0] Sum,
    output Cout
);

    wire [7:0] G, P;
    assign G = A & B;
    assign P = A ^ B;
    wire C0, C1, C2, C3, C4, C5, C6, C7;
    assign C0 = Cin;

    assign C1 = G[0] | (P[0] & C0);

    assign C2 = G[1] | (P[1] & G[0]) | (P[1] & P[0] & C0);

    assign C3 = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & C0);

    assign C4 = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | 
                (P[3] & P[2] & P[1] & G[0]) | (P[3] & P[2] & P[1] & P[0] & C0);

    assign C5 = G[4] | (P[4] & G[3]) | (P[4] & P[3] & G[2]) | 
                (P[4] & P[3] & P[2] & G[1]) | (P[4] & P[3] & P[2] & P[1] & G[0]) | 
                (P[4] & P[3] & P[2] & P[1] & P[0] & C0);

    assign C6 = G[5] | (P[5] & G[4]) | (P[5] & P[4] & G[3]) | 
                (P[5] & P[4] & P[3] & G[2]) | (P[5] & P[4] & P[3] & P[2] & G[1]) | 
                (P[5] & P[4] & P[3] & P[2] & P[1] & G[0]) | 
                (P[5] & P[4] & P[3] & P[2] & P[1] & P[0] & C0);

    assign C7 = G[6] | (P[6] & G[5]) | (P[6] & P[5] & G[4]) | 
                (P[6] & P[5] & P[4] & G[3]) | (P[6] & P[5] & P[4] & P[3] & G[2]) | 
                (P[6] & P[5] & P[4] & P[3] & P[2] & G[1]) | 
                (P[6] & P[5] & P[4] & P[3] & P[2] & P[1] & G[0]) | 
                (P[6] & P[5] & P[4] & P[3] & P[2] & P[1] & P[0] & C0);

    assign Cout = G[7] | (P[7] & G[6]) | (P[7] & P[6] & G[5]) | 
                 (P[7] & P[6] & P[5] & G[4]) | (P[7] & P[6] & P[5] & P[4] & G[3]) | 
                 (P[7] & P[6] & P[5] & P[4] & P[3] & G[2]) | 
                 (P[7] & P[6] & P[5] & P[4] & P[3] & P[2] & G[1]) | 
                 (P[7] & P[6] & P[5] & P[4] & P[3] & P[2] & P[1] & G[0]) | 
                 (P[7] & P[6] & P[5] & P[4] & P[3] & P[2] & P[1] & P[0] & C0);

    assign Sum = P ^ {C7, C6, C5, C4, C3, C2, C1, C0};

endmodule



module ResDivider (
    input clk,
    input rst,
    input start,
    input  [12:0] dividend,
    input  [12:0] divisor,
    output [11:0] quotient,
    output reg done
);
//流水线寄存器,加一符号位
reg  signed [13:0] dd [0:11];
reg  signed [13:0] ds [0:11];
reg         [11:0] qo [0:11];
reg         [13:0] re [0:11];
wire signed [13:0] cal[0:11];
reg         [11:0] sign;
reg         [12:0] done_reg;

//========== cycle 0  ===============
always @(posedge clk) begin
    if (rst) begin
        dd[0] <= 0;
        ds[0] <= 0;
        qo[0] <= 0;
        done_reg[0] <= 1'b0;
    end else if (start) begin
        dd[0] <= {1'b0,dividend};
        ds[0] <= {1'b0,divisor};
        qo[0] <= 0;
        sign[0] <= cal[0][13];
        done_reg[0] <= 1'b1;
    end
end

assign cal[0] = dd[0] - ds[0];
//========== cycle 1  ===============

always @(posedge clk) begin
    if (rst) begin
        dd[1] <= 0;
        ds[1] <= 0;
        qo[1] <= 0;
        done_reg[1] <= 1'b0;
    end else if (start) begin
        dd[1] <= {cal[0][12:0],1'b0};
        ds[1] <= ds[0];
        if (sign[0]) begin
            qo[1] <= {12'b000000000000};
        end else begin
            qo[1] <= {12'b100000000000};
        end
        sign[1] <= cal[1][13];  
        done_reg[1] <= done_reg[0];
    end
end

assign cal[1] = sign[0]?dd[1] + ds[1]:dd[1] - ds[1];

//========== cycle 2  ===============
always @(posedge clk) begin
    if (rst) begin
        dd[2] <= 0;
        ds[2] <= 0;
        qo[2] <= 0;
        done_reg[2] <= 1'b0;
    end else if (start) begin
        dd[2] <= {cal[1][12:0],1'b0};
        ds[2] <= ds[1];
        if (sign[1]) begin
            qo[2] <= {qo[1][11],11'b00000000000};
        end else begin
            qo[2] <= {qo[1][11],11'b10000000000};
        end
        sign[2] <= cal[2][13];
        done_reg[2] <= done_reg[1];
    end
end

assign cal[2] = sign[1]?dd[2] + ds[2]:dd[2] - ds[2];


//========== cycle 3  ===============
always @(posedge clk) begin
    if (rst) begin
        dd[3] <= 0;
        ds[3] <= 0;
        qo[3] <= 0;
        done_reg[3] <= 1'b0;
    end else if (start) begin
        dd[3] <= {cal[2][12:0],1'b0};
        ds[3] <= ds[2];
        if (sign[2]) begin
            qo[3] <= {qo[2][11:10],10'b0000000000};
        end else begin
            qo[3] <= {qo[2][11:10],10'b1000000000};
        end
        sign[3] <= cal[3][13];
        done_reg[3] <= done_reg[2];
    end
end
assign cal[3] = sign[2]?dd[3] + ds[3]:dd[3] - ds[3];

//========== cycle 4  ===============
always @(posedge clk) begin
    if (rst) begin
        dd[4] <= 0;
        ds[4] <= 0;
        qo[4] <= 0;
        done_reg[4] <= 1'b0;
    end else if (start) begin
        dd[4] <= {cal[3][12:0],1'b0};
        ds[4] <= ds[3];
        if (sign[3]) begin
            qo[4] <= {qo[3][11:9],9'b000000000};
        end else begin
            qo[4] <= {qo[3][11:9],9'b100000000};
        end
        sign[4] <= cal[4][13];
        done_reg[4] <= done_reg[3];
    end
end
assign cal[4] = sign[3]?dd[4] + ds[4]:dd[4] - ds[4];

//========== cycle 5  ===============
always @(posedge clk) begin
    if (rst) begin
        dd[5] <= 0;
        ds[5] <= 0;
        qo[5] <= 0;
        done_reg[5] <= 1'b0;
    end else if (start) begin
        dd[5] <= {cal[4][12:0],1'b0};
        ds[5] <= ds[4];
        if (sign[4]) begin
            qo[5] <= {qo[4][11:8],8'b00000000};
        end else begin
            qo[5] <= {qo[4][11:8],8'b10000000};
        end
        sign[5] <= cal[5][13];
        done_reg[5] <= done_reg[4];
    end
end

assign cal[5] = sign[4]?dd[5] + ds[5]:dd[5] - ds[5];
//========== cycle 6  ===============
always @(posedge clk) begin
    if (rst) begin
        dd[6] <= 0;
        ds[6] <= 0;
        qo[6] <= 0;
        done_reg[6] <= 1'b0;
    end else if (start) begin
        dd[6] <= {cal[5][12:0],1'b0};
        ds[6] <= ds[5];
        if (sign[5]) begin
            qo[6] <= {qo[5][11:7],7'b0000000};
        end else begin
            qo[6] <= {qo[5][11:7],7'b1000000};
        end
        sign[6] <= cal[6][13];
        done_reg[6] <= done_reg[5];
    end
end
assign cal[6] = sign[5]?dd[6] + ds[6]:dd[6] - ds[6];
//========== cycle 7  ===============
always @(posedge clk) begin
    if (rst) begin
        dd[7] <= 0;
        ds[7] <= 0;
        qo[7] <= 0;
        done_reg[7] <= 1'b0;
    end else if (start) begin
        dd[7] <= {cal[6][12:0],1'b0};
        ds[7] <= ds[6];
        if (sign[6]) begin
            qo[7] <= {qo[6][11:6],6'b000000};
        end else begin
            qo[7] <= {qo[6][11:6],6'b100000};
        end
        sign[7] <= cal[7][13];
        done_reg[7] <= done_reg[6];
    end
end
assign cal[7] = sign[6]?dd[7] + ds[7]:dd[7] - ds[7];
//========== cycle 8  ===============
always @(posedge clk) begin
    if (rst) begin
        dd[8] <= 0;
        ds[8] <= 0;
        qo[8] <= 0;
        done_reg[8] <= 1'b0;
    end else if (start) begin
        dd[8] <= {cal[7][12:0],1'b0};
        ds[8] <= ds[7];
        if (sign[7]) begin
            qo[8] <= {qo[7][11:5],5'b00000};
        end else begin
            qo[8] <= {qo[7][11:5],5'b10000};
        end
        sign[8] <= cal[8][13];
        done_reg[8] <= done_reg[7];
    end
end
assign cal[8] = sign[7]?dd[8] + ds[8]:dd[8] - ds[8];
//========== cycle 9  ===============
always @(posedge clk) begin
    if (rst) begin
        dd[9] <= 0;
        ds[9] <= 0;
        qo[9] <= 0;
        done_reg[9] <= 1'b0;
    end else if (start) begin
        dd[9] <= {cal[8][12:0],1'b0};
        ds[9] <= ds[8];
        if (sign[8]) begin
            qo[9] <= {qo[8][11:4],4'b0000};
        end else begin
            qo[9] <= {qo[8][11:4],4'b1000};
        end
        sign[9] <= cal[9][13];
        done_reg[9] <= done_reg[8];
    end
end
assign cal[9] = sign[8]?dd[9] + ds[9]:dd[9] - ds[9];
//========== cycle 10  ===============
always @(posedge clk) begin
    if (rst) begin
        dd[10] <= 0;
        ds[10] <= 0;
        qo[10] <= 0;
        done_reg[10] <= 1'b0;
    end else if (start) begin
        dd[10] <= {cal[9][12:0],1'b0};
        ds[10] <= ds[9];
        if (sign[9]) begin
            qo[10] <= {qo[9][11:3],3'b000};
        end else begin
            qo[10] <= {qo[9][11:3],3'b100};
        end
        sign[10] <= cal[10][13];
        done_reg[10] <= done_reg[9];
    end
end
assign cal[10] = sign[9]?dd[10] + ds[10]:dd[10] - ds[10];
//========== cycle 11  ===============
always @(posedge clk) begin
    if (rst) begin
        dd[11] <= 0;
        ds[11] <= 0;
        qo[11] <= 0;
        done_reg[11] <= 1'b0;
    end else if (start) begin
        dd[11] <= {cal[10][12:0],1'b0};
        ds[11] <= ds[10];
        if (sign[10]) begin
            qo[11] <= {qo[10][11:2],2'b00};
        end else begin
            qo[11] <= {qo[10][11:2],2'b10};
        end
        done_reg[11] <= done_reg[10];
    end
end

always @(posedge clk) begin
    if (rst) begin
        done <= 1'b0;
        done_reg[12] <= 1'b0;
    end else if (start) begin
        done_reg[12] <= done_reg[11];
        done <= done_reg[12];
    end
end
assign quotient = qo[11][11:0];

endmodule


module fifo #(
    parameter DATAWIDTH = 8,
    parameter DEPTH = 8,
    parameter PTR_LEN = $clog2(DEPTH)
)(
    input                        clk,
    input                        rst,
    input      [DATAWIDTH - 1:0] data_in,
    input                        wr_en,
    input                        rd_en,
    output reg [DATAWIDTH - 1:0] data_out,
    output                       full,
    output                       empty
);

reg [DATAWIDTH - 1:0] fifo_mem [0:DEPTH-1];
reg [PTR_LEN:0] wr_ptr;
reg [PTR_LEN:0] rd_ptr;

always @(posedge clk) begin
    if (rst) begin
        wr_ptr <= 0;
        rd_ptr <= 0;
    end else begin
        if (wr_en & !full) begin
            fifo_mem[wr_ptr[PTR_LEN-1:0]] <= data_in;
            wr_ptr <= wr_ptr + 1;
        end
        if (rd_en & !empty) begin
            data_out <= fifo_mem[rd_ptr[PTR_LEN-1:0]];
            rd_ptr <= rd_ptr + 1;
        end else begin
            data_out <= 0;
        end
    end
end

assign full = (wr_ptr[PTR_LEN-1:0] == rd_ptr[PTR_LEN-1:0] && wr_ptr[PTR_LEN-1]!=rd_ptr[PTR_LEN-1]);
assign empty = (wr_ptr[PTR_LEN-1:0] == rd_ptr[PTR_LEN-1:0] && wr_ptr[PTR_LEN-1]==rd_ptr[PTR_LEN-1]);

endmodule


module Adder12(
    input [11:0] x_in,
    input [11:0] y_in,
    output [12:0] result_out
);

assign result_out = x_in+y_in;

endmodule


module Rom(
    input [11:0] x_in,
    output wire[11:0] res_out
);

reg[11:0] result_out;
wire [1:0] quadrant = x_in[11:10];
reg sign;

reg [9:0] addr;
wire [10:0] addr_temp;
assign addr_temp = 1024 - {1'b0,x_in[9:0]};

reg zero;
assign res_out = zero?0:result_out;
always @(*) begin
    case (quadrant)
        2'b00: begin
            addr = x_in[9:0];
            sign = 0;
            zero = 0;
        end
        2'b01: begin
            addr = addr_temp[9:0];
            sign = 1;
            zero = (addr==0);
        end
        2'b10: begin
            addr = x_in[9:0];
            sign = 1;
            zero = 0;
        end
        2'b11: begin
            addr = addr_temp[9:0];
            sign = 0;
            zero = (addr==0);
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
    14   : result_out = {sign,11'd2047};//2048
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



