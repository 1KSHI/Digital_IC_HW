`timescale 1ns/1ps

module tb_top;

    // Inputs
    reg clk;
    reg rst;
    reg [11:0] a;
    reg [11:0] b;
    reg [11:0] c;
    reg e;

    // Output
    wire [12:0] y;

    // Instantiate the Unit Under Test (UUT)
    top uut (
        .clk(clk),
        .rst(rst),
        .a(a),
        .b(b),
        .c(c),
        .e(e),
        .y(y)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    // Test sequence
    real y_decimal;
    real y_true;
    real cos_value;
    integer i;

    initial begin
        // Initialize inputs
        rst = 1;
        a = 0;
        b = 0;
        c = 0;
        e = 0;

        // Reset the design
        #20;
        rst = 0;

        // Initialize d_reg with e for 12 cycles
        repeat (12) begin
            e = $random % 2; // Randomize e
            #10; // Wait for one clock cycle
        end

        // Start providing inputs for a, b, and c
        e = 0; // Stop updating d_reg
        for (i = 0; i < 20; i = i + 1) begin
            a = $random % 4096; // Randomize a (12-bit)
            b = $random % 4096; // Randomize b (12-bit)
            c = $random % 4096; // Randomize c (12-bit)

            // Calculate y_true
            cos_value = $cos(2 * 3.141592653589793 * c / 4096.0); // cos(2π * c / 2^12)
            y_true = (a * b * cos_value) / (a + 12) / 4096.0; // y_true = (abcos(2πc/2^12))/(a+d)/2^12

            #10; // Wait for one clock cycle

            // Convert y to decimal
            y_decimal = y / 4096.0;

            // Display results
            $display("Time: %0t | a: %0d | b: %0d | c: %0d | e: %0b | y: %0f | y_true: %0f", 
                     $time, a, b, c, e, y_decimal, y_true);
        end

        // Finish simulation
        #100;
        $finish;
    end

    // Monitor outputs
    initial begin
        $monitor("Time: %0t | a: %0d | b: %0d | c: %0d | e: %0b | y: %0f", 
                 $time, a, b, c, e, y[11:0] / 4096.0);
    end

endmodule
