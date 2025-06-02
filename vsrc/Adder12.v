module Adder12(
    input [11:0] x_in,
    input [11:0] y_in,
    output [12:0] result_out
);

assign result_out = x_in+y_in;

endmodule