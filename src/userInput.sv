/* Synchronizes and edge-detects a user input signal.
 *
 * Inputs:
 *   clk - system clock
 *   rst - synchronous reset
 *   in  - asynchronous user input signal
 *
 * Outputs:
 *   out - one-cycle synchronous pulse
 */
module user_input (input logic clk, rst, in, output logic out);
  logic sync;
  sync s (.clk, .rst, .in, .out(sync));
  pulse p (.clk, .rst, .in(sync), .out);
endmodule // user_input