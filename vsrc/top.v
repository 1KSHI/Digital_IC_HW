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

//a*b    //(a+d)  //cos c>>12
wire [23:0] Fir1_wire;
wire [12:0] Fir2_wire;
wire [12:0] Fir3_wire;

reg [23:0] Fir1_reg;//a*b 
reg [12:0] Fir2_reg;//(a+d)
reg [12:0] Fir3_reg;//cos c>>12

Wallace12x12 Wallace12x12 (
    .x_in(a_reg),
    .y_in(b_reg),
    .result_out(Fir1_wire)
);

Adder12 Adder12 (
    .x_in(a_reg),
    .y_in(d_reg),
    .result_out(Fir2_wire)
);

Rom Rom(
    .x_in       	(c_reg        ),
    .result_out 	(Fir3_wire    )
);


always @(posedge clk) begin
    if (rst) begin
        Fir1_reg <= 0;
        Fir2_reg <= 0;
        Fir3_reg <= 0;
    end else begin
        Fir1_reg <= Fir1_wire;
        Fir2_reg <= Fir2_wire;
        Fir3_reg <= Fir3_wire;
    end
end

//a*b/(a+d) 
wire [23:0] Sec1_wire;

reg [23:0] Sec1_reg;//a*b/(a+d)

Divder12 u_Divder12(
    .x_in       	(Fir1_reg     ),
    .y_in       	({11'b0,Fir2_reg}     ),
    .result_out 	(Sec1_wire    )
);


always @(posedge clk) begin
    if (rst) begin
        Sec1_reg <= 0;
    end else begin
        Sec1_reg <= Sec1_wire;
    end
end


//a*b/(a+d) * cos c>>12
wire [23:0] Thi1_wire;
reg [23:0] Thi1_reg;

Wallace12x12 Wallace12x12_2 (
    .x_in(Sec1_reg[11:0]),
    .y_in(Fir3_reg[11:0]),
    .result_out(Thi1_wire)
);

always @(posedge clk) begin
    if (rst) begin
        Thi1_reg <= 0;
    end else begin
        Thi1_reg <= Thi1_wire;
    end
end


//a*b/(a+d) * cos c>>12 >>(12+10)
reg [11:0] Fou1_reg;
wire [11:0] Fou1_wire;

Shift12 Shift12 (
    .x_in(Thi1_reg),
    .result_out(Fou1_wire)
);

always @(posedge clk) begin
    if (rst) begin
        Fou1_reg <= 0;
    end else begin
        Fou1_reg <= Fou1_wire;
    end
end


assign y = {Fir3_reg[12],Fou1_reg};

endmodule
