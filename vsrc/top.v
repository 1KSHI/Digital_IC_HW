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

`ifdef SIMULATION
always @(posedge clk)begin
    if( Sev_end_reg == 1'b1)begin
        check_finsih({19'b0,y});
    end
end
`endif

endmodule
