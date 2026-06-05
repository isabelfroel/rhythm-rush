/* Detects a rising edge on the input signal.
 *
 * Inputs:
 *   clk - system clock
 *   rst - clears input state
 *   in  - input signal
 *
 * Outputs:
 *   out - one-cycle pulse
 */
module pulse (input logic clk, rst, in, output logic out);
  enum logic {ZERO, ONE} ps, ns;
  assign ns = in ? ONE : ZERO;
  always_ff @(posedge clk)
    ps <= rst ? ZERO : ns;
  assign out = (ps == ZERO) & in;
endmodule // pulse