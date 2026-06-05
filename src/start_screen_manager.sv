/* Draws the game start screen from ROM.
 *
 * Inputs:
 *   rst - reset input
 *   clk - system clock
 *   x   - VGA x-coordinate
 *   y   - VGA y-coordinate
 *
 * Outputs:
 *   r   - red color for that pixel
 *   g   - green color for that pixel
 *   b   - blue color for that pixel
 */
module start_screen_manager (rst, clk, x, y, r, g, b);
    output logic [7:0] r, g, b;
	input logic [9:0] x;
	input logic [8:0] y;
	input logic rst, clk;

	logic [7:0] r_next, g_next, b_next;
	logic [8:0]  address;
	logic	[639:0]  q;
	start_ROM str(.address, .clock(clk), .q);
	logic on;
    
    always_ff @(posedge clk) begin
	    r <= r_next;
		g <= g_next;
		b <= b_next;
	end

	always_comb begin
	    address = y;
	    on = q[640 - x];
	    if (on) begin 
            r_next = 8'hFF;
            g_next = 8'hFF;
            b_next = 8'hFF;
        end else begin 
    	    r_next = 8'd0;
            g_next = 8'd0;
            b_next = 8'd0;
        end
        
    end
endmodule // start_screen_manager