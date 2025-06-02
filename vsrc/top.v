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

`ifdef SIMULATION
always @(posedge clk)begin
    if( Eig_end_reg == 1'b1)begin
        check_finsih({19'b0,y});
    end
end
`endif

endmodule

