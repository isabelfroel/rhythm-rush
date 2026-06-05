/* Generates a one-cycle enable for player movement.
 *
 * Inputs:
 *   rst - clears the counter to 0
 *   clk - system clock
 *
 * Outputs:
 *   enable - used to advance player animation
 */
module slower_enable(enable, rst, clk);
	output logic enable;
	input logic rst, clk;
	
	logic [20:0] cnt;
	assign enable = (cnt == '1);
	
	always_ff @(posedge clk) begin 
		cnt <= rst? '0 : cnt + 1; // should overflow back to 0
	end
	
endmodule // slower_enable