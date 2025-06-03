module tb_top;

    reg clk;
    reg rst;
    reg [11:0] a;
    reg [11:0] b;
    reg [11:0] c;
    reg e;

    wire [12:0] y;
    
    top uut (
        .clk(clk),
        .rst(rst),
        .a(a),
        .b(b),
        .c(c),
        .e(e),
        .y(y)
    );

    initial begin
        clk = 1;
        forever #2.5 clk = ~clk;
    end
    
    integer i;

    initial begin
	#10;
	repeat (12) begin
            e = $random % 2;
		$display("d: %0b", uut.d_reg);
            #5;
        end
    end

    initial begin

        rst = 1;
        a = 0;
        b = 0;
        c = 0;
        e = 0;

        #7.5;
        rst = 0;
	#62.5;
        

        e = 0;
        for (i = 0; i < 20; i = i + 1) begin
            a = $random % 4096;
            b = $random % 4096;
            c = $random % 4096;
            $display("Index: %0d | a: %0d | b: %0d | c: %0d | d: %0d", i,  a,b,c,uut.d_reg);
            #5;

        end

        #50;
        
    end

    initial begin
        #110;
        for (i = 0; i < 20; i = i + 1) begin
            $display("Index: %0d | y_decimal: %0d", i,  y[12:0]);
            #5;
        end
        #5;
        $finish;
    end

endmodule



