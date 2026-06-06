/* Tracks objects positions and heights using a circular queue. 
 * Basically the object memory rotates as the game scrolls to the left.
 * This also adds a new objects of height "new_height" on the right. 
 *
 *   each object takes up a fixed like 10 bit chunk of the screen
 *   any given object is essentially at x = (index - left_ptr) * 10 - shift_count
 *   its top left y_coord is at a fixed bottom + stored height at objects[index]
 *   this is all handled in my top level, but i could take in an x,y and output the height there?
 *   if the vga is going super fast, could there be timing issues?
 *
 * Inputs:
 *   clk    - should be connected to the 50 MHz clock
 *   reset  - resets the left and right pointers and clears the objects
 *   enable - is high when we should scroll left
 *   obs_spawn      - spawns new obstacle at the rightmost slot
 *   pow_spawn      - spawns new power-up at the rightmost slot
 *   new_obs_height - heigh for the new obstacle
 *   new_pow_height - height for the new power-up
 *
 * Outputs:
 *   shift_count - once an object has been shifted over enough, the pointers advance
 *   right_ptr - points to the object slot at the right edge of the screen
 *   left_ptr  - points to the object slot at the left edge of the screen
 *   obstacles - circular array of obstacle heights
 *   power_ups - circular array of power-up heights
 */
 module object_manager #(
    parameter int DEPTH  = 64) (
    input  logic clk,
    input  logic rst,
    input  logic enable,
    input  logic obs_spawn,
    input logic pow_spawn,
    input logic  [5:0] new_obs_height,
    input logic  [5:0] new_pow_height,
    output logic [3:0] shift_count,
    output logic [5:0] left_ptr,
    output logic [5:0] right_ptr,
    output logic [DEPTH-1:0][5:0] obstacles,
    output logic [DEPTH-1:0][5:0] power_ups
);
    
    always_ff @(posedge clk) begin
        if (rst) begin
            left_ptr <= 0;
            right_ptr <= DEPTH-1;
            shift_count <= 0;
            obstacles <= 0;
            power_ups <= 0;
        end else if (enable) begin
            if (shift_count == 4'd9) begin // finished shifting a column 10 pixels over
                shift_count <= 0;
                if (left_ptr == DEPTH-1) left_ptr <= 0; // wrap around
                else left_ptr <= left_ptr + 1; // advance
                if (right_ptr == DEPTH-1) right_ptr <= 0; // wrap around
                else right_ptr <= right_ptr + 1; // advance
                if (obs_spawn) obstacles[right_ptr - 1] <= new_obs_height; // fill right slot in obstacles
                else obstacles[right_ptr] <= 0;
                if (pow_spawn) power_ups[right_ptr - 1] <= new_pow_height; // fill right slot in power_ups
                else power_ups[right_ptr] <= 0;
            end else begin
                shift_count <= shift_count + 1;
            end
        end
    end // always_ff

endmodule // object_manager

`timescale 1 ps / 1 ps
module object_manager_tb ();

	logic clk, rst, enable;
	logic obs_spawn, pow_spawn;
	logic [5:0] new_obs_height, new_pow_height;
	logic [3:0] shift_count;
	logic [5:0] left_ptr, right_ptr;
	logic [63:0][5:0] obstacles, power_ups;
	
	// instantiate module
	object_manager dut (.*);
	
	// create simulated clock
	parameter T = 20;
	initial begin
		clk <= 0;
		forever #(T/2) clk <= ~clk;
	end  // clock initial
	
	// simulated inputs
	initial begin
		rst <= 1; enable <= 0; obs_spawn <= 0; pow_spawn <= 0; new_obs_height <= 0; new_pow_height <= 0; @(posedge clk);
        rst <= 0; @(posedge clk);
        @(posedge clk); // idle with enable low
		@(posedge clk); // idle with enable low
        enable <= 1; obs_spawn <= 1; pow_spawn <= 0; new_obs_height <= 6'd12; new_pow_height <= 0; repeat (10) @(posedge clk); // first rollover: obstacle only

		obs_spawn <= 0; pow_spawn <= 1; new_obs_height <= 0; new_pow_height <= 6'd9; repeat (10) @(posedge clk); // second rollover: power-up only

		obs_spawn <= 1; pow_spawn <= 1; new_obs_height <= 6'd20; new_pow_height <= 6'd5; repeat (10) @(posedge clk); // third rollover: both spawn

		obs_spawn <= 0; pow_spawn <= 0; new_obs_height <= 6'd31; new_pow_height <= 6'd31; repeat (10) @(posedge clk); // fourth rollover: no spawn

		obs_spawn <= 1; pow_spawn <= 1; new_obs_height <= 6'd3; new_pow_height <= 6'd2; repeat (10) @(posedge clk); // partial shift
		obs_spawn <= 1; pow_spawn <= 0; new_obs_height <= 6'd15; new_pow_height <= 6'd1; repeat (120*10) @(posedge clk); // long run to force pointer wraparound
		obs_spawn <= 0; pow_spawn <= 0; new_obs_height <= 6'd15; new_pow_height <= 0; repeat (20) @(posedge clk); // fill w zeros

		$stop();
	end  // inputs initial
	
endmodule  // object_manager_tb