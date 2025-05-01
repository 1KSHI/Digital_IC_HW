import "DPI-C" function void check_finsih(int y);

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

always @(posedge clk)begin
    if( finish[2] == 1'b1)begin
        check_finsih({19'b0,y});
    end
end

endmodule

