/* Passes async input through 2 flip flops to avoid metastability.
 * It takes heavy inspiration from cse 369 but is parameterized to take a bus for convenience.
 *
 * Inputs:
 *   clk - clock domain
 *   rst - clears everything
 *   in  - input signal
 *
 * Outputs:
 *   out - synchronized version of in after two flip-flops
 */
module sync #(parameter W = 1) (clk, rst, in, out);
	input logic clk, rst;
	input logic [W-1:0] in;
	output logic [W-1:0] out;

  logic [W-1:0] mid;  // output of first FF

  always_ff @(posedge clk)
    if (rst)
      {mid, out} <= '0;
    else
      {mid, out} <= {in, mid};

endmodule  // sync