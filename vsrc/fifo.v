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
