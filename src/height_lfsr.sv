/* Produces a random height for the next object
 * Follows the table in https://courses.cs.washington.edu/courses/cse369/26sp/labs/lab7.html
 * to produce a maximum-length sequence
 *
 * Inputs:
 *   clk    - should be connected to the 50 MHz clock
 *   reset  - resets the output to zero
 *   enable - is high when we need to get a new output (set to 1 until i figure out what should trigger that)
 *
 * Outputs:
 *   S0 	- for testing purposes, goes high when in the all zeros state
 *   Q 		- output
 */
module height_lfsr (
  output logic [5:0] Q, // present state
  output logic S0,
  input logic clk, rst, enable // clock input
  );

  always_ff @(posedge clk)
    if (rst)
      Q <= 0;
    else if (enable)
      Q <= {Q[4:0], ~(Q[5] ^ Q[4])};
  
  assign S0 = (Q == 0);
endmodule // height_lfsr



/* Testbench for height_lfsr
 * Checks cycle length
 */
module height_lfsr_tb ();
  logic [5:0] Q;
  logic S0;
  logic clk, rst, enable;

  height_lfsr dut (.*);
  parameter CLOCK_PERIOD=100;
  initial begin
    clk <= 0;
    forever #(CLOCK_PERIOD/2) clk <= ~clk;
  end

  integer i;
  initial begin
     rst <= 1; enable <= 1; @(posedge clk);
	 rst <= 0; @(posedge clk);
	 for (i = 0; i < 68; i = i + 1) begin
	   @(posedge clk);
	 end
    $stop;
  end
endmodule 
