module Shift12(
    input [23:0] x_in,
    output [11:0] result_out
);

assign result_out = x_in[23:12];

endmodule
