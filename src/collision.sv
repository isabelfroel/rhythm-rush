/* Detects obstacle and power-up collisions.
 *
 * The sprite can span up to three 10-pixel chunks at once. This checks the left,
 * middle, and right covered columns for overlap with obstacle and power-up regions.
 *
 * Inputs:
 *   clk           - system clock
 *   rst           - synchronous reset for the pulse FSMs
 *   y_coord       - top-left y-coordinate of the  sprite
 *   shift_count   - pixel offset within the current scrolling chunk
 *   left_ptr      - circular-buffer pointer to the leftmost visible object slot
 *   obstacles     - circular memory storing obstacle heights for each chunk
 *   power_ups     - circular memory storing power-up vertical offsets for each chunk
 *
 * Outputs:
 *   crash_detected - high when a collision is detected
 *   power_up_detected- high when a power-up pickup is detected
 */
module collision #(
    parameter int Y_GROUND    = 300,
    parameter int SPRITE_SIZE = 30,
    parameter int PLAYER_X    = 80,
    parameter int DEPTH       = 64,
    parameter int CHUNK_W     = 10,
    parameter int POWER_UP_TOP = 100
) (
    input  logic [8:0] y_coord,
    input  logic [3:0] shift_count,
    input  logic [5:0] left_ptr,
    input  logic [DEPTH-1:0][5:0] obstacles,
    input  logic [DEPTH-1:0][5:0] power_ups,
    output logic crash_detected,
    output logic power_up_detected
);
    
    logic [8:0] p_y_left, p_y_mid, p_y_right;
    logic [8:0] player_top, player_bottom;
    logic [6:0] screen_col_left, screen_col_mid, screen_col_right;
    logic [5:0] mem_idx_left, mem_idx_mid, mem_idx_right;
    logic [5:0] h_left, h_mid, h_right;
    logic [5:0] pu_left, pu_mid, pu_right;
    logic mid_valid;

    always_comb begin
        player_top    = y_coord;
        player_bottom = y_coord + SPRITE_SIZE - 1;

        screen_col_left  = (PLAYER_X + shift_count) / CHUNK_W;
        screen_col_right = (PLAYER_X + SPRITE_SIZE - 1 + shift_count) / CHUNK_W;
        screen_col_mid   = screen_col_left + 1;

        mem_idx_left  = (left_ptr + screen_col_left)  & 6'b111111;
        mem_idx_mid   = (left_ptr + screen_col_mid)   & 6'b111111;
        mem_idx_right = (left_ptr + screen_col_right) & 6'b111111;

        h_left  = obstacles[mem_idx_left];
        h_mid   = obstacles[mem_idx_mid];
        h_right = obstacles[mem_idx_right];

        pu_left  = power_ups[mem_idx_left];
        pu_mid   = power_ups[mem_idx_mid];
        pu_right = power_ups[mem_idx_right];

        p_y_left  = POWER_UP_TOP + pu_left;
        p_y_mid   = POWER_UP_TOP + pu_mid;
        p_y_right = POWER_UP_TOP + pu_right;

        crash_detected  = 1'b0;
        power_up_detected = 1'b0;

        mid_valid = (screen_col_left + 1 < screen_col_right);

        if ((h_left != 0) && (player_bottom >= (Y_GROUND - h_left)))
            crash_detected = 1'b1;

        if (mid_valid && (h_mid != 0) && (player_bottom >= (Y_GROUND - h_mid)))
            crash_detected = 1'b1;

        if ((screen_col_right != screen_col_left) &&
            (h_right != 0) &&
            (player_bottom >= (Y_GROUND - h_right)))
            crash_detected = 1'b1;

        if ((pu_left != 0) &&
            (player_top <= p_y_left + 9) &&
            (player_bottom >= p_y_left))
            power_up_detected = 1'b1;

        if (mid_valid &&
            (pu_mid != 0) &&
            (player_top <= p_y_mid + 9) &&
            (player_bottom >= p_y_mid))
            power_up_detected = 1'b1;

        if ((screen_col_right != screen_col_left) &&
            (pu_right != 0) &&
            (player_top <= p_y_right + 9) &&
            (player_bottom >= p_y_right))
            power_up_detected = 1'b1;
    end

endmodule // collision

/* tests collisions 
*/
`timescale 1 ps / 1 ps
module collision_tb ();

	logic [8:0] y_coord;
	logic [3:0] shift_count;
	logic [5:0] left_ptr;
	logic [63:0][5:0] obstacles, power_ups;
	logic crash_detected, power_up_detected;
	
	// instantiate module
	collision dut (.*);
	
	parameter T = 10;
	
	// simulated inputs
	initial begin
		y_coord <= 0; shift_count <= 0; left_ptr <= 0; obstacles <= '0; power_ups <= '0; #T; 
        // no collision, no power-up
		y_coord <= 9'd200; shift_count <= 4'd0; left_ptr <= 6'd0; obstacles <= '0; power_ups <= '0; #T;

		// left chunk obstacle collision, screen_col_left = 8 when shift_count = 0
		obstacles[8] <= 6'd20;   // obstacle top at 300-20 = 280
		y_coord <= 9'd260;       // player_bottom = 289, should overlap
		#T;
        obstacles <= '0;

		// middle chunk obstacle collision, screen_col_mid = 9 when shift_count = 0
		obstacles[9] <= 6'd25;   // obstacle top at 275
		y_coord <= 9'd250;       // player_bottom = 279
		#T;
		obstacles <= '0;

		// right chunk obstacle collision, screen_col_right = 10 when shift_count = 0
		obstacles[10] <= 6'd30;  // obstacle top at 270
		y_coord <= 9'd245;       // player_bottom = 274
		#T;
		obstacles <= '0;

		// left chunk power-up pickup, power-up spans p_y to p_y+9
		power_ups[8] <= 6'd20;   // power-up at y = 100+20 = 120
		y_coord <= 9'd115;       // player spans 115..144
		#T;
		power_ups <= '0;

		// middle chunk power-up pickup
		power_ups[9] <= 6'd35;   // power-up at y = 135
		y_coord <= 9'd130;       // player spans 130..159
		#T;
		power_ups <= '0;

		// right chunk power-up pickup
		power_ups[10] <= 6'd50;  // power-up at y = 150
		y_coord <= 9'd145;       // player spans 145..174
		#T;
		power_ups <= '0;


		// shifted case: changes which chunks are checked
		shift_count <= 4'd9;
		left_ptr <= 6'd0;
		obstacles[8] <= 6'd0;
		obstacles[9] <= 6'd24;
		obstacles[11] <= 6'd24;
		y_coord <= 9'd248;
		#T;
		obstacles <= '0;
		$stop();
	end  // inputs initial
	
endmodule  // collision_tb