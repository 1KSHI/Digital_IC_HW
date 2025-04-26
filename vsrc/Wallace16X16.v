module	Wallace16X16 ( 
	input	[15:0]	x_in, y_in,
	output	[31:0]	result_out
);
wire [31:0] opa, opb;	// 32-bit operands
wire pp [15:0][15:0];	// 16x16 partial products
genvar i, j;
generate
    for (i = 0; i < 16; i = i + 1) begin: pp_gen
        for (j = 0; j < 16; j = j + 1) begin: pp_gen2
            assign pp[i][j] = x_in[i] & y_in[j];
        end
    end
endgenerate


//============== First Stage ==================================================

wire	[15: 0]	Fir1_S, Fir1_C;
wire	[15: 0]	Fir2_S, Fir2_C;
wire	[15: 0]	Fir3_S, Fir3_C;
wire	[15: 0]	Fir4_S, Fir4_C;
wire	[15: 0]	Fir5_S, Fir5_C;

HalfAdder	fir1ha0( pp[0][1], pp[1][0], Fir1_S[0], Fir1_C[0] );
FullAdder	fir1fa1( pp[0][2], pp[1][1], pp[2][0], Fir1_S[1], Fir1_C[1] );
FullAdder	fir1fa2( pp[0][3], pp[1][2], pp[2][1], Fir1_S[2], Fir1_C[2] );
FullAdder	fir1fa3( pp[0][4], pp[1][3], pp[2][2], Fir1_S[3], Fir1_C[3] );
FullAdder	fir1fa4( pp[0][5], pp[1][4], pp[2][3], Fir1_S[4], Fir1_C[4] );
FullAdder	fir1fa5( pp[0][6], pp[1][5], pp[2][4], Fir1_S[5], Fir1_C[5] );
FullAdder	fir1fa6( pp[0][7], pp[1][6], pp[2][5], Fir1_S[6], Fir1_C[6] );
FullAdder	fir1fa7( pp[0][8], pp[1][7], pp[2][6], Fir1_S[7], Fir1_C[7] );
FullAdder	fir1fa8( pp[0][9], pp[1][8], pp[2][7], Fir1_S[8], Fir1_C[8] );
FullAdder	fir1fa9( pp[0][10], pp[1][9], pp[2][8], Fir1_S[9], Fir1_C[9] );
FullAdder	fir1fa10( pp[0][11], pp[1][10], pp[2][9], Fir1_S[10], Fir1_C[10] );
FullAdder	fir1fa11( pp[0][12], pp[1][11], pp[2][10], Fir1_S[11], Fir1_C[11] );
FullAdder	fir1fa12( pp[0][13], pp[1][12], pp[2][11], Fir1_S[12], Fir1_C[12] );
FullAdder	fir1fa13( pp[0][14], pp[1][13], pp[2][12], Fir1_S[13], Fir1_C[13] );
FullAdder	fir1fa14( pp[0][15], pp[1][14], pp[2][13], Fir1_S[14], Fir1_C[14] );
HalfAdder	fir1ha15( pp[1][15], pp[2][14], Fir1_S[15], Fir1_C[15] );

HalfAdder	fir2ha0( pp[3][1], pp[4][0], Fir2_S[0], Fir2_C[0] );
FullAdder	fir2fa1( pp[3][2], pp[4][1], pp[5][0], Fir2_S[1], Fir2_C[1] );
FullAdder	fir2fa2( pp[3][3], pp[4][2], pp[5][1], Fir2_S[2], Fir2_C[2] );
FullAdder	fir2fa3( pp[3][4], pp[4][3], pp[5][2], Fir2_S[3], Fir2_C[3] );
FullAdder	fir2fa4( pp[3][5], pp[4][4], pp[5][3], Fir2_S[4], Fir2_C[4] );
FullAdder	fir2fa5( pp[3][6], pp[4][5], pp[5][4], Fir2_S[5], Fir2_C[5] );
FullAdder	fir2fa6( pp[3][7], pp[4][6], pp[5][5], Fir2_S[6], Fir2_C[6] );
FullAdder	fir2fa7( pp[3][8], pp[4][7], pp[5][6], Fir2_S[7], Fir2_C[7] );
FullAdder	fir2fa8( pp[3][9], pp[4][8], pp[5][7], Fir2_S[8], Fir2_C[8] );
FullAdder	fir2fa9( pp[3][10], pp[4][9], pp[5][8], Fir2_S[9], Fir2_C[9] );
FullAdder	fir2fa10( pp[3][11], pp[4][10], pp[5][9], Fir2_S[10], Fir2_C[10] );
FullAdder	fir2fa11( pp[3][12], pp[4][11], pp[5][10], Fir2_S[11], Fir2_C[11] );
FullAdder	fir2fa12( pp[3][13], pp[4][12], pp[5][11], Fir2_S[12], Fir2_C[12] );
FullAdder	fir2fa13( pp[3][14], pp[4][13], pp[5][12], Fir2_S[13], Fir2_C[13] );
FullAdder	fir2fa14( pp[3][15], pp[4][14], pp[5][13], Fir2_S[14], Fir2_C[14] );
HalfAdder	fir2ha15( pp[4][15], pp[5][14], Fir2_S[15], Fir2_C[15] );

HalfAdder	fir3ha0( pp[6][1], pp[7][0], Fir3_S[0], Fir3_C[0] );
FullAdder	fir3fa1( pp[6][2], pp[7][1], pp[8][0], Fir3_S[1], Fir3_C[1] );
FullAdder	fir3fa2( pp[6][3], pp[7][2], pp[8][1], Fir3_S[2], Fir3_C[2] );
FullAdder	fir3fa3( pp[6][4], pp[7][3], pp[8][2], Fir3_S[3], Fir3_C[3] );
FullAdder	fir3fa4( pp[6][5], pp[7][4], pp[8][3], Fir3_S[4], Fir3_C[4] );
FullAdder	fir3fa5( pp[6][6], pp[7][5], pp[8][4], Fir3_S[5], Fir3_C[5] );
FullAdder	fir3fa6( pp[6][7], pp[7][6], pp[8][5], Fir3_S[6], Fir3_C[6] );
FullAdder	fir3fa7( pp[6][8], pp[7][7], pp[8][6], Fir3_S[7], Fir3_C[7] );
FullAdder	fir3fa8( pp[6][9], pp[7][8], pp[8][7], Fir3_S[8], Fir3_C[8] );
FullAdder	fir3fa9( pp[6][10], pp[7][9], pp[8][8], Fir3_S[9], Fir3_C[9] );
FullAdder	fir3fa10( pp[6][11], pp[7][10], pp[8][9], Fir3_S[10], Fir3_C[10] );
FullAdder	fir3fa11( pp[6][12], pp[7][11], pp[8][10], Fir3_S[11], Fir3_C[11] );
FullAdder	fir3fa12( pp[6][13], pp[7][12], pp[8][11], Fir3_S[12], Fir3_C[12] );
FullAdder	fir3fa13( pp[6][14], pp[7][13], pp[8][12], Fir3_S[13], Fir3_C[13] );
FullAdder	fir3fa14( pp[6][15], pp[7][14], pp[8][13], Fir3_S[14], Fir3_C[14] );
HalfAdder	fir3ha15( pp[7][15], pp[8][14], Fir3_S[15], Fir3_C[15] );

HalfAdder	fir4ha0( pp[9][1], pp[10][0], Fir4_S[0], Fir4_C[0] );
FullAdder	fir4fa1( pp[9][2], pp[10][1], pp[11][0], Fir4_S[1], Fir4_C[1] );
FullAdder	fir4fa2( pp[9][3], pp[10][2], pp[11][1], Fir4_S[2], Fir4_C[2] );
FullAdder	fir4fa3( pp[9][4], pp[10][3], pp[11][2], Fir4_S[3], Fir4_C[3] );
FullAdder	fir4fa4( pp[9][5], pp[10][4], pp[11][3], Fir4_S[4], Fir4_C[4] );
FullAdder	fir4fa5( pp[9][6], pp[10][5], pp[11][4], Fir4_S[5], Fir4_C[5] );
FullAdder	fir4fa6( pp[9][7], pp[10][6], pp[11][5], Fir4_S[6], Fir4_C[6] );
FullAdder	fir4fa7( pp[9][8], pp[10][7], pp[11][6], Fir4_S[7], Fir4_C[7] );
FullAdder	fir4fa8( pp[9][9], pp[10][8], pp[11][7], Fir4_S[8], Fir4_C[8] );
FullAdder	fir4fa9( pp[9][10], pp[10][9], pp[11][8], Fir4_S[9], Fir4_C[9] );
FullAdder	fir4fa10( pp[9][11], pp[10][10], pp[11][9], Fir4_S[10], Fir4_C[10] );
FullAdder	fir4fa11( pp[9][12], pp[10][11], pp[11][10], Fir4_S[11], Fir4_C[11] );
FullAdder	fir4fa12( pp[9][13], pp[10][12], pp[11][11], Fir4_S[12], Fir4_C[12] );
FullAdder	fir4fa13( pp[9][14], pp[10][13], pp[11][12], Fir4_S[13], Fir4_C[13] );
FullAdder	fir4fa14( pp[9][15], pp[10][14], pp[11][13], Fir4_S[14], Fir4_C[14] );
HalfAdder	fir4ha15( pp[10][15], pp[11][14], Fir4_S[15], Fir4_C[15] );

HalfAdder	fir5ha0( pp[12][1], pp[13][0], Fir5_S[0], Fir5_C[0] );
FullAdder	fir5fa1( pp[12][2], pp[13][1], pp[14][0], Fir5_S[1], Fir5_C[1] );
FullAdder	fir5fa2( pp[12][3], pp[13][2], pp[14][1], Fir5_S[2], Fir5_C[2] );
FullAdder	fir5fa3( pp[12][4], pp[13][3], pp[14][2], Fir5_S[3], Fir5_C[3] );
FullAdder	fir5fa4( pp[12][5], pp[13][4], pp[14][3], Fir5_S[4], Fir5_C[4] );
FullAdder	fir5fa5( pp[12][6], pp[13][5], pp[14][4], Fir5_S[5], Fir5_C[5] );
FullAdder	fir5fa6( pp[12][7], pp[13][6], pp[14][5], Fir5_S[6], Fir5_C[6] );
FullAdder	fir5fa7( pp[12][8], pp[13][7], pp[14][6], Fir5_S[7], Fir5_C[7] );
FullAdder	fir5fa8( pp[12][9], pp[13][8], pp[14][7], Fir5_S[8], Fir5_C[8] );
FullAdder	fir5fa9( pp[12][10], pp[13][9], pp[14][8], Fir5_S[9], Fir5_C[9] );
FullAdder	fir5fa10( pp[12][11], pp[13][10], pp[14][9], Fir5_S[10], Fir5_C[10] );
FullAdder	fir5fa11( pp[12][12], pp[13][11], pp[14][10], Fir5_S[11], Fir5_C[11] );
FullAdder	fir5fa12( pp[12][13], pp[13][12], pp[14][11], Fir5_S[12], Fir5_C[12] );
FullAdder	fir5fa13( pp[12][14], pp[13][13], pp[14][12], Fir5_S[13], Fir5_C[13] );
FullAdder	fir5fa14( pp[12][15], pp[13][14], pp[14][13], Fir5_S[14], Fir5_C[14] );
HalfAdder	fir5ha15( pp[13][15], pp[14][14], Fir5_S[15], Fir5_C[15] );

//============== Second Stage =================================================

wire	[15: 0]	Sec1_S, Sec1_C;
wire	[17: 0]	Sec2_S, Sec2_C;
wire	[15: 0]	Sec3_S, Sec3_C;

HalfAdder	sec1ha0( Fir1_S[1], Fir1_C[0], Sec1_S[0], Sec1_C[0] );
FullAdder	sec1fa1( Fir1_S[2], Fir1_C[1], pp[3][0], Sec1_S[1], Sec1_C[1] );
FullAdder	sec1fa2( Fir1_S[3], Fir1_C[2], Fir2_S[0], Sec1_S[2], Sec1_C[2] );
FullAdder	sec1fa3( Fir1_S[4], Fir1_C[3], Fir2_S[1], Sec1_S[3], Sec1_C[3] );
FullAdder	sec1fa4( Fir1_S[5], Fir1_C[4], Fir2_S[2], Sec1_S[4], Sec1_C[4] );
FullAdder	sec1fa5( Fir1_S[6], Fir1_C[5], Fir2_S[3], Sec1_S[5], Sec1_C[5] );
FullAdder	sec1fa6( Fir1_S[7], Fir1_C[6], Fir2_S[4], Sec1_S[6], Sec1_C[6] );
FullAdder	sec1fa7( Fir1_S[8], Fir1_C[7], Fir2_S[5], Sec1_S[7], Sec1_C[7] );
FullAdder	sec1fa8( Fir1_S[9], Fir1_C[8], Fir2_S[6], Sec1_S[8], Sec1_C[8] );
FullAdder	sec1fa9( Fir1_S[10], Fir1_C[9], Fir2_S[7], Sec1_S[9], Sec1_C[9] );
FullAdder	sec1fa10( Fir1_S[11], Fir1_C[10], Fir2_S[8], Sec1_S[10], Sec1_C[10] );
FullAdder	sec1fa11( Fir1_S[12], Fir1_C[11], Fir2_S[9], Sec1_S[11], Sec1_C[11] );
FullAdder	sec1fa12( Fir1_S[13], Fir1_C[12], Fir2_S[10], Sec1_S[12], Sec1_C[12] );
FullAdder	sec1fa13( Fir1_S[14], Fir1_C[13], Fir2_S[11], Sec1_S[13], Sec1_C[13] );
FullAdder	sec1fa14( Fir1_S[15], Fir1_C[14], Fir2_S[12], Sec1_S[14], Sec1_C[14] );
FullAdder	sec1fa15( pp[2][15], Fir1_C[15], Fir2_S[13], Sec1_S[15], Sec1_C[15] );

HalfAdder	sec2ha0( Fir2_C[1], pp[6][0], Sec2_S[0], Sec2_C[0] );
HalfAdder	sec2ha1( Fir2_C[2], Fir3_S[0], Sec2_S[1], Sec2_C[1] );
FullAdder	sec2fa2( Fir2_C[3], Fir3_S[1], Fir3_C[0], Sec2_S[2], Sec2_C[2] );
FullAdder	sec2fa3( Fir2_C[4], Fir3_S[2], Fir3_C[1], Sec2_S[3], Sec2_C[3] );
FullAdder	sec2fa4( Fir2_C[5], Fir3_S[3], Fir3_C[2], Sec2_S[4], Sec2_C[4] );
FullAdder	sec2fa5( Fir2_C[6], Fir3_S[4], Fir3_C[3], Sec2_S[5], Sec2_C[5] );
FullAdder	sec2fa6( Fir2_C[7], Fir3_S[5], Fir3_C[4], Sec2_S[6], Sec2_C[6] );
FullAdder	sec2fa7( Fir2_C[8], Fir3_S[6], Fir3_C[5], Sec2_S[7], Sec2_C[7] );
FullAdder	sec2fa8( Fir2_C[9], Fir3_S[7], Fir3_C[6], Sec2_S[8], Sec2_C[8] );
FullAdder	sec2fa9( Fir2_C[10], Fir3_S[8], Fir3_C[7], Sec2_S[9], Sec2_C[9] );
FullAdder	sec2fa10( Fir2_C[11], Fir3_S[9], Fir3_C[8], Sec2_S[10], Sec2_C[10] );
FullAdder	sec2fa11( Fir2_C[12], Fir3_S[10], Fir3_C[9], Sec2_S[11], Sec2_C[11] );
FullAdder	sec2fa12( Fir2_C[13], Fir3_S[11], Fir3_C[10], Sec2_S[12], Sec2_C[12] );
FullAdder	sec2fa13( Fir2_C[14], Fir3_S[12], Fir3_C[11], Sec2_S[13], Sec2_C[13] );
FullAdder	sec2fa14( Fir2_C[15], Fir3_S[13], Fir3_C[12], Sec2_S[14], Sec2_C[14] );
HalfAdder	sec2ha15( Fir3_S[14], Fir3_C[13], Sec2_S[15], Sec2_C[15] );
HalfAdder	sec2ha16( Fir3_S[15], Fir3_C[14], Sec2_S[16], Sec2_C[16] );
HalfAdder	sec2ha17( pp[8][15], Fir3_C[15], Sec2_S[17], Sec2_C[17] );

HalfAdder	sec3ha0( Fir4_S[1], Fir4_C[0], Sec3_S[0], Sec3_C[0] );
FullAdder	sec3fa1( Fir4_S[2], Fir4_C[1], pp[12][0], Sec3_S[1], Sec3_C[1] );
FullAdder	sec3fa2( Fir4_S[3], Fir4_C[2], Fir5_S[0], Sec3_S[2], Sec3_C[2] );
FullAdder	sec3fa3( Fir4_S[4], Fir4_C[3], Fir5_S[1], Sec3_S[3], Sec3_C[3] );
FullAdder	sec3fa4( Fir4_S[5], Fir4_C[4], Fir5_S[2], Sec3_S[4], Sec3_C[4] );
FullAdder	sec3fa5( Fir4_S[6], Fir4_C[5], Fir5_S[3], Sec3_S[5], Sec3_C[5] );
FullAdder	sec3fa6( Fir4_S[7], Fir4_C[6], Fir5_S[4], Sec3_S[6], Sec3_C[6] );
FullAdder	sec3fa7( Fir4_S[8], Fir4_C[7], Fir5_S[5], Sec3_S[7], Sec3_C[7] );
FullAdder	sec3fa8( Fir4_S[9], Fir4_C[8], Fir5_S[6], Sec3_S[8], Sec3_C[8] );
FullAdder	sec3fa9( Fir4_S[10], Fir4_C[9], Fir5_S[7], Sec3_S[9], Sec3_C[9] );
FullAdder	sec3fa10( Fir4_S[11], Fir4_C[10], Fir5_S[8], Sec3_S[10], Sec3_C[10] );
FullAdder	sec3fa11( Fir4_S[12], Fir4_C[11], Fir5_S[9], Sec3_S[11], Sec3_C[11] );
FullAdder	sec3fa12( Fir4_S[13], Fir4_C[12], Fir5_S[10], Sec3_S[12], Sec3_C[12] );
FullAdder	sec3fa13( Fir4_S[14], Fir4_C[13], Fir5_S[11], Sec3_S[13], Sec3_C[13] );
FullAdder	sec3fa14( Fir4_S[15], Fir4_C[14], Fir5_S[12], Sec3_S[14], Sec3_C[14] );
FullAdder	sec3fa15( pp[11][15], Fir4_C[15], Fir5_S[13], Sec3_S[15], Sec3_C[15] );

//============== Third Stage =================================================

wire	[17: 0]	Thi1_S, Thi1_C;
wire	[18: 0]	Thi2_S, Thi2_C;

HalfAdder	thi1ha0( Sec1_S[1], Sec1_C[0], Thi1_S[0], Thi1_C[0] );
HalfAdder	thi1ha1( Sec1_S[2], Sec1_C[1], Thi1_S[1], Thi1_C[1] );
FullAdder	thi1fa2( Sec1_S[3], Sec1_C[2], Fir2_C[0], Thi1_S[2], Thi1_C[2] );
FullAdder	thi1fa3( Sec1_S[4], Sec1_C[3], Sec2_S[0], Thi1_S[3], Thi1_C[3] );
FullAdder	thi1fa4( Sec1_S[5], Sec1_C[4], Sec2_S[1], Thi1_S[4], Thi1_C[4] );
FullAdder	thi1fa5( Sec1_S[6], Sec1_C[5], Sec2_S[2], Thi1_S[5], Thi1_C[5] );
FullAdder	thi1fa6( Sec1_S[7], Sec1_C[6], Sec2_S[3], Thi1_S[6], Thi1_C[6] );
FullAdder	thi1fa7( Sec1_S[8], Sec1_C[7], Sec2_S[4], Thi1_S[7], Thi1_C[7] );
FullAdder	thi1fa8( Sec1_S[9], Sec1_C[8], Sec2_S[5], Thi1_S[8], Thi1_C[8] );
FullAdder	thi1fa9( Sec1_S[10], Sec1_C[9], Sec2_S[6], Thi1_S[9], Thi1_C[9] );
FullAdder	thi1fa10( Sec1_S[11], Sec1_C[10], Sec2_S[7], Thi1_S[10], Thi1_C[10] );
FullAdder	thi1fa11( Sec1_S[12], Sec1_C[11], Sec2_S[8], Thi1_S[11], Thi1_C[11] );
FullAdder	thi1fa12( Sec1_S[13], Sec1_C[12], Sec2_S[9], Thi1_S[12], Thi1_C[12] );
FullAdder	thi1fa13( Sec1_S[14], Sec1_C[13], Sec2_S[10], Thi1_S[13], Thi1_C[13] );
FullAdder	thi1fa14( Sec1_S[15], Sec1_C[14], Sec2_S[11], Thi1_S[14], Thi1_C[14] );
FullAdder	thi1fa15( Fir2_S[14], Sec1_C[15], Sec2_S[12], Thi1_S[15], Thi1_C[15] );
HalfAdder	thi1ha16( Fir2_S[15], Sec2_S[13], Thi1_S[16], Thi1_C[16] );
HalfAdder	thi1ha17( pp[5][15], Sec2_S[14], Thi1_S[17], Thi1_C[17] );

HalfAdder	thi2ha0( Sec2_C[2], pp[9][0], Thi2_S[0], Thi2_C[0] );
HalfAdder	thi2ha1( Sec2_C[3], Fir4_S[0], Thi2_S[1], Thi2_C[1] );
HalfAdder	thi2ha2( Sec2_C[4], Sec3_S[0], Thi2_S[2], Thi2_C[2] );
FullAdder	thi2fa3( Sec2_C[5], Sec3_S[1], Sec3_C[0], Thi2_S[3], Thi2_C[3] );
FullAdder	thi2fa4( Sec2_C[6], Sec3_S[2], Sec3_C[1], Thi2_S[4], Thi2_C[4] );
FullAdder	thi2fa5( Sec2_C[7], Sec3_S[3], Sec3_C[2], Thi2_S[5], Thi2_C[5] );
FullAdder	thi2fa6( Sec2_C[8], Sec3_S[4], Sec3_C[3], Thi2_S[6], Thi2_C[6] );
FullAdder	thi2fa7( Sec2_C[9], Sec3_S[5], Sec3_C[4], Thi2_S[7], Thi2_C[7] );
FullAdder	thi2fa8( Sec2_C[10], Sec3_S[6], Sec3_C[5], Thi2_S[8], Thi2_C[8] );
FullAdder	thi2fa9( Sec2_C[11], Sec3_S[7], Sec3_C[6], Thi2_S[9], Thi2_C[9] );
FullAdder	thi2fa10( Sec2_C[12], Sec3_S[8], Sec3_C[7], Thi2_S[10], Thi2_C[10] );
FullAdder	thi2fa11( Sec2_C[13], Sec3_S[9], Sec3_C[8], Thi2_S[11], Thi2_C[11] );
FullAdder	thi2fa12( Sec2_C[14], Sec3_S[10], Sec3_C[9], Thi2_S[12], Thi2_C[12] );
FullAdder	thi2fa13( Sec2_C[15], Sec3_S[11], Sec3_C[10], Thi2_S[13], Thi2_C[13] );
FullAdder	thi2fa14( Sec2_C[16], Sec3_S[12], Sec3_C[11], Thi2_S[14], Thi2_C[14] );
FullAdder	thi2fa15( Sec2_C[17], Sec3_S[13], Sec3_C[12], Thi2_S[15], Thi2_C[15] );
HalfAdder	thi2ha16( Sec3_S[14], Sec3_C[13], Thi2_S[16], Thi2_C[16] );
HalfAdder	thi2ha17( Sec3_S[15], Sec3_C[14], Thi2_S[17], Thi2_C[17] );
HalfAdder	thi2ha18( Fir5_S[14], Sec3_C[15], Thi2_S[18], Thi2_C[18] );

//============== Fourth Stage =================================================

wire	[19: 0]	Fou1_S, Fou1_C;
wire	[15: 0]	Fou2_S, Fou2_C;

HalfAdder	fou1ha0( Thi1_S[1], Thi1_C[0], Fou1_S[0], Fou1_C[0] );
HalfAdder	fou1ha1( Thi1_S[2], Thi1_C[1], Fou1_S[1], Fou1_C[1] );
HalfAdder	fou1ha2( Thi1_S[3], Thi1_C[2], Fou1_S[2], Fou1_C[2] );
FullAdder	fou1fa3( Thi1_S[4], Thi1_C[3], Sec2_C[0], Fou1_S[3], Fou1_C[3] );
FullAdder	fou1fa4( Thi1_S[5], Thi1_C[4], Sec2_C[1], Fou1_S[4], Fou1_C[4] );
FullAdder	fou1fa5( Thi1_S[6], Thi1_C[5], Thi2_S[0], Fou1_S[5], Fou1_C[5] );
FullAdder	fou1fa6( Thi1_S[7], Thi1_C[6], Thi2_S[1], Fou1_S[6], Fou1_C[6] );
FullAdder	fou1fa7( Thi1_S[8], Thi1_C[7], Thi2_S[2], Fou1_S[7], Fou1_C[7] );
FullAdder	fou1fa8( Thi1_S[9], Thi1_C[8], Thi2_S[3], Fou1_S[8], Fou1_C[8] );
FullAdder	fou1fa9( Thi1_S[10], Thi1_C[9], Thi2_S[4], Fou1_S[9], Fou1_C[9] );
FullAdder	fou1fa10( Thi1_S[11], Thi1_C[10], Thi2_S[5], Fou1_S[10], Fou1_C[10] );
FullAdder	fou1fa11( Thi1_S[12], Thi1_C[11], Thi2_S[6], Fou1_S[11], Fou1_C[11] );
FullAdder	fou1fa12( Thi1_S[13], Thi1_C[12], Thi2_S[7], Fou1_S[12], Fou1_C[12] );
FullAdder	fou1fa13( Thi1_S[14], Thi1_C[13], Thi2_S[8], Fou1_S[13], Fou1_C[13] );
FullAdder	fou1fa14( Thi1_S[15], Thi1_C[14], Thi2_S[9], Fou1_S[14], Fou1_C[14] );
FullAdder	fou1fa15( Thi1_S[16], Thi1_C[15], Thi2_S[10], Fou1_S[15], Fou1_C[15] );
FullAdder	fou1fa16( Thi1_S[17], Thi1_C[16], Thi2_S[11], Fou1_S[16], Fou1_C[16] );
FullAdder	fou1fa17( Sec2_S[15], Thi1_C[17], Thi2_S[12], Fou1_S[17], Fou1_C[17] );
HalfAdder	fou1ha18( Sec2_S[16], Thi2_S[13], Fou1_S[18], Fou1_C[18] );
HalfAdder	fou1ha19( Sec2_S[17], Thi2_S[14], Fou1_S[19], Fou1_C[19] );

HalfAdder	fou2ha0( Thi2_C[4], Fir5_C[0], Fou2_S[0], Fou2_C[0] );
FullAdder	fou2fa1( Thi2_C[5], Fir5_C[1], pp[15][0], Fou2_S[1], Fou2_C[1] );
FullAdder	fou2fa2( Thi2_C[6], Fir5_C[2], pp[15][1], Fou2_S[2], Fou2_C[2] );
FullAdder	fou2fa3( Thi2_C[7], Fir5_C[3], pp[15][2], Fou2_S[3], Fou2_C[3] );
FullAdder	fou2fa4( Thi2_C[8], Fir5_C[4], pp[15][3], Fou2_S[4], Fou2_C[4] );
FullAdder	fou2fa5( Thi2_C[9], Fir5_C[5], pp[15][4], Fou2_S[5], Fou2_C[5] );
FullAdder	fou2fa6( Thi2_C[10], Fir5_C[6], pp[15][5], Fou2_S[6], Fou2_C[6] );
FullAdder	fou2fa7( Thi2_C[11], Fir5_C[7], pp[15][6], Fou2_S[7], Fou2_C[7] );
FullAdder	fou2fa8( Thi2_C[12], Fir5_C[8], pp[15][7], Fou2_S[8], Fou2_C[8] );
FullAdder	fou2fa9( Thi2_C[13], Fir5_C[9], pp[15][8], Fou2_S[9], Fou2_C[9] );
FullAdder	fou2fa10( Thi2_C[14], Fir5_C[10], pp[15][9], Fou2_S[10], Fou2_C[10] );
FullAdder	fou2fa11( Thi2_C[15], Fir5_C[11], pp[15][10], Fou2_S[11], Fou2_C[11] );
FullAdder	fou2fa12( Thi2_C[16], Fir5_C[12], pp[15][11], Fou2_S[12], Fou2_C[12] );
FullAdder	fou2fa13( Thi2_C[17], Fir5_C[13], pp[15][12], Fou2_S[13], Fou2_C[13] );
FullAdder	fou2fa14( Thi2_C[18], Fir5_C[14], pp[15][13], Fou2_S[14], Fou2_C[14] );
FullAdder	fou2fa15( pp[14][15], Fir5_C[15], pp[15][14], Fou2_S[15], Fou2_C[15] );

//============== Fifth Stage =================================================

wire	[23: 0]	Fif_S, Fif_C;

HalfAdder	fifha0( Fou1_S[1], Fou1_C[0], Fif_S[0], Fif_C[0] );
HalfAdder	fifha1( Fou1_S[2], Fou1_C[1], Fif_S[1], Fif_C[1] );
HalfAdder	fifha2( Fou1_S[3], Fou1_C[2], Fif_S[2], Fif_C[2] );
HalfAdder	fifha3( Fou1_S[4], Fou1_C[3], Fif_S[3], Fif_C[3] );
HalfAdder	fifha4( Fou1_S[5], Fou1_C[4], Fif_S[4], Fif_C[4] );
FullAdder	fiffa5( Fou1_S[6], Fou1_C[5], Thi2_C[0], Fif_S[5], Fif_C[5] );
FullAdder	fiffa6( Fou1_S[7], Fou1_C[6], Thi2_C[1], Fif_S[6], Fif_C[6] );
FullAdder	fiffa7( Fou1_S[8], Fou1_C[7], Thi2_C[2], Fif_S[7], Fif_C[7] );
FullAdder	fiffa8( Fou1_S[9], Fou1_C[8], Thi2_C[3], Fif_S[8], Fif_C[8] );
FullAdder	fiffa9( Fou1_S[10], Fou1_C[9], Fou2_S[0], Fif_S[9], Fif_C[9] );
FullAdder	fiffa10( Fou1_S[11], Fou1_C[10], Fou2_S[1], Fif_S[10], Fif_C[10] );
FullAdder	fiffa11( Fou1_S[12], Fou1_C[11], Fou2_S[2], Fif_S[11], Fif_C[11] );
FullAdder	fiffa12( Fou1_S[13], Fou1_C[12], Fou2_S[3], Fif_S[12], Fif_C[12] );
FullAdder	fiffa13( Fou1_S[14], Fou1_C[13], Fou2_S[4], Fif_S[13], Fif_C[13] );
FullAdder	fiffa14( Fou1_S[15], Fou1_C[14], Fou2_S[5], Fif_S[14], Fif_C[14] );
FullAdder	fiffa15( Fou1_S[16], Fou1_C[15], Fou2_S[6], Fif_S[15], Fif_C[15] );
FullAdder	fiffa16( Fou1_S[17], Fou1_C[16], Fou2_S[7], Fif_S[16], Fif_C[16] );
FullAdder	fiffa17( Fou1_S[18], Fou1_C[17], Fou2_S[8], Fif_S[17], Fif_C[17] );
FullAdder	fiffa18( Fou1_S[19], Fou1_C[18], Fou2_S[9], Fif_S[18], Fif_C[18] );
FullAdder	fiffa19( Thi2_S[15], Fou1_C[19], Fou2_S[10], Fif_S[19], Fif_C[19] );
HalfAdder	fifha20( Thi2_S[16], Fou2_S[11], Fif_S[20], Fif_C[20] );
HalfAdder	fifha21( Thi2_S[17], Fou2_S[12], Fif_S[21], Fif_C[21] );
HalfAdder	fifha22( Thi2_S[18], Fou2_S[13], Fif_S[22], Fif_C[22] );
HalfAdder	fifha23( Fir5_S[15], Fou2_S[14], Fif_S[23], Fif_C[23] );

//============== Sixth Stage =================================================

wire	[24: 0]	Six_S, Six_C;

HalfAdder	sixha0( Fif_S[1], Fif_C[0], Six_S[0], Six_C[0] );
HalfAdder	sixha1( Fif_S[2], Fif_C[1], Six_S[1], Six_C[1] );
HalfAdder	sixha2( Fif_S[3], Fif_C[2], Six_S[2], Six_C[2] );
HalfAdder	sixha3( Fif_S[4], Fif_C[3], Six_S[3], Six_C[3] );
HalfAdder	sixha4( Fif_S[5], Fif_C[4], Six_S[4], Six_C[4] );
HalfAdder	sixha5( Fif_S[6], Fif_C[5], Six_S[5], Six_C[5] );
HalfAdder	sixha6( Fif_S[7], Fif_C[6], Six_S[6], Six_C[6] );
HalfAdder	sixha7( Fif_S[8], Fif_C[7], Six_S[7], Six_C[7] );
HalfAdder	sixha8( Fif_S[9], Fif_C[8], Six_S[8], Six_C[8] );
FullAdder	sixfa9( Fif_S[10], Fif_C[9], Fou2_C[0], Six_S[9], Six_C[9] );
FullAdder	sixfa10( Fif_S[11], Fif_C[10], Fou2_C[1], Six_S[10], Six_C[10] );
FullAdder	sixfa11( Fif_S[12], Fif_C[11], Fou2_C[2], Six_S[11], Six_C[11] );
FullAdder	sixfa12( Fif_S[13], Fif_C[12], Fou2_C[3], Six_S[12], Six_C[12] );
FullAdder	sixfa13( Fif_S[14], Fif_C[13], Fou2_C[4], Six_S[13], Six_C[13] );
FullAdder	sixfa14( Fif_S[15], Fif_C[14], Fou2_C[5], Six_S[14], Six_C[14] );
FullAdder	sixfa15( Fif_S[16], Fif_C[15], Fou2_C[6], Six_S[15], Six_C[15] );
FullAdder	sixfa16( Fif_S[17], Fif_C[16], Fou2_C[7], Six_S[16], Six_C[16] );
FullAdder	sixfa17( Fif_S[18], Fif_C[17], Fou2_C[8], Six_S[17], Six_C[17] );
FullAdder	sixfa18( Fif_S[19], Fif_C[18], Fou2_C[9], Six_S[18], Six_C[18] );
FullAdder	sixfa19( Fif_S[20], Fif_C[19], Fou2_C[10], Six_S[19], Six_C[19] );
FullAdder	sixfa20( Fif_S[21], Fif_C[20], Fou2_C[11], Six_S[20], Six_C[20] );
FullAdder	sixfa21( Fif_S[22], Fif_C[21], Fou2_C[12], Six_S[21], Six_C[21] );
FullAdder	sixfa22( Fif_S[23], Fif_C[22], Fou2_C[13], Six_S[22], Six_C[22] );
FullAdder	sixfa23( Fou2_S[15], Fif_C[23], Fou2_C[14], Six_S[23], Six_C[23] );
HalfAdder	sixha24( pp[15][15], Fou2_C[15], Six_S[24], Six_C[24] );

//============== Result Assignment ============================================

assign	opa = { 1'b0, Six_S[24: 0], Fif_S[0], Fou1_S[0], Thi1_S[0],Sec1_S[0], Fir1_S[0], pp[0][0] };
assign	opb = { Six_C[24: 0], 7'b0 };

assign result_out = opa + opb;


endmodule