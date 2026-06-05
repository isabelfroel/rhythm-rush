/* This module increments cnt by 1 when enable is high.
 *
 * Inputs:
 *   clk    - system clock
 *   rst    - clears the counter to 0
 *   enable - increments the counter
 *
 * Outputs:
 *   cnt    - 5-bit count value
 */
module counter(
    input  logic clk,
    input  logic rst,
    input  logic enable,
    output logic [4:0] cnt
);

    always_ff @(posedge clk) begin
        if (rst) cnt <= 0;
        else if (enable) cnt <= cnt + 1; // should overflow back to 0
	end
	
endmodule // counter