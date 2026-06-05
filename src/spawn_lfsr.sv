/* Produces a random number each cycle and whether or not to spawn a new object
 * Follows the table in https://courses.cs.washington.edu/courses/cse369/26sp/labs/lab7.html
 * to produce a maximum-length sequence
 *
 * Inputs:
 *   clk    - should be connected to the 50 MHz clock
 *   reset  - resets the output to zero
 *   enable - is high when we need to get a new output (set to 1 until i figure out what should trigger that)
 *   bias - is a value to add to the LFSR output to increase how often we see an object (set to zero to ignore functionality for now)
 *
 * Outputs:
 *   S0 	- for testing purposes, goes high when in the all zeros state
 *   Q 		- output
 *   obs_spawn  - high when a new obj should be spawned
 *   pow_spawn  - high when a new power-up should be spawned
 */
module spawn_lfsr (
  output logic [10:0] Q, // present state
  output logic S0,
  output logic obs_spawn,
  output logic pow_spawn,
  input logic clk, rst, enable, // clock input
  input logic [10:0] bias
  );

  always_ff @(posedge clk)
    if (rst)
      Q <= 0;
    else if (enable)
      Q <= {Q[9:0], ~(Q[10] ^ Q[8])};
  
  assign S0 = (Q == 0);
  assign obs_spawn = (({1'b0, Q} + {1'b0, bias}) < 'd128);
  assign pow_spawn = (({1'b0, Q} + {1'b0, bias}) < 'd64);
  
endmodule // spawn_lfsr



/* Testbench for height_lfsr
 * Checks cycle length
 */
module spawn_lfsr_tb ();
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
endmodule // spawn_lfsr
