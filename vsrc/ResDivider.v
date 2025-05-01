
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
reg         [11:0] done_reg;

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
    end else if (start) begin
        done <= done_reg[11];
    end
end
assign quotient = qo[11][11:0];

endmodule
