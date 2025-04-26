module top(
    input clk,
    input rst,
    // input [11:0]mula,
    // input [11:0]mulb,
    output [24:0] res
);
reg [11:0]mula;
reg [11:0]mulb;

Wallace12x12 Wallace12x12 (
    .x_in(mula),
    .y_in(mulb),
    .result_out(res)
);

// assign res = mula * mulb;

always @(posedge clk) begin
    if (rst) begin
        mula <= 0;
        mulb <= 0;
    end else begin
        mula <= mula + 2;
        mulb <= mulb + 1;
    end
end

endmodule
