/* Draws and updates the active game screen.
 *
 * Updates the player position, scrolls obstacles and power-ups, detects
 * collisions, tracks immunity/death state, and renders the current
 * frame as VGA RGB pixel data.
 *
 * Inputs:
 *   start   - starts gameplay from the start screen
 *   rst     - resets game state
 *   jump    - player jump
 *   bias    - increase spawn generator
 *   game_ip - high when the game screen is currently active
 *   clk     - system clock
 *   x       - VGA x-coordinate
 *   y       - VGA y-coordinate
 *
 * Outputs:
 *   dead    - high when the player has died
 *   r       - red color for that pixel
 *   g       - green color for that pixel
 *   b       - blue color for that pixel
 *   score   - pickup count
 */
module game_screen_manager  #(
    parameter int Y_GROUND = 300,
    parameter int Y_TOP    = 0,
    parameter int GRAVITY  = 1,
    parameter int JUMP_VY  = -20,
    parameter int SPRITE_SIZE = 20,
    parameter int X_LEFT = 100,
    parameter int NUM_OBS   = 10,
    parameter int POWER_UP_TOP = 100,
    parameter DEPTH = 64,
    parameter RAD = SPRITE_SIZE/2,
    parameter RAD_2 = RAD * RAD
)
(start, rst, jump, bias, dead, game_ip, clk, x, y, r, g, b, score);
	output logic [7:0] r, g, b;
	output logic dead;
	input logic [9:0] x;
	input logic [8:0] y;
	input logic start, jump, rst, clk, game_ip;
	input logic [9:0] bias;
	output logic [4:0] score;

	logic [7:0] r_next, g_next, b_next;
	
	always_ff @(posedge clk) begin
	    r <= r_next;
		g <= g_next;
		b <= b_next;
	end // always_ff
	
    integer index;
    integer height;
    integer power_up_height;
    integer screen_col;

    logic signed [11:0] dx, dy;
    logic        [23:0] dist2;

	always_comb begin
        // default: black
        r_next = 8'd0;
        g_next = 8'd0;
        b_next = 8'd0;
        dx = '0;
        dy = '0;
        dist2 = '0;
        
        screen_col = (x + shift_count) / 10;
        index = (left_ptr + screen_col) & 6'b111111; // same as mod 64
        height = objects[index];
        power_up_height = power_ups[index];

        if ((height != 0) &&
            (y >= Y_GROUND - height) &&
            (y <  Y_GROUND)) begin
            r_next = 8'hFF;
            g_next = 8'h00;
            b_next = 8'h00;
        end
        
        if ((power_up_height != 0) &&
            (y >= POWER_UP_TOP + power_up_height) &&
            (y <  POWER_UP_TOP + power_up_height + 10)) begin
            r_next = 8'hFF;
            g_next = 8'hFF;
            b_next = 8'h00;
        end
    
        // floor
        if (y == Y_GROUND+1) begin
            r_next = 8'hFF;
            g_next = 8'hFF;
            b_next = 8'hFF;
        end
        
        // only test pixels inside the sprite's square bounding box
        if ((x >= X_LEFT) && (x < X_LEFT + SPRITE_SIZE) &&
            (y >= y_coord) && (y < y_coord + SPRITE_SIZE)) begin
    
            dx = $signed({1'b0, x}) - $signed(X_LEFT + RAD);
            dy = $signed({1'b0, y}) - $signed(y_coord + RAD);
            dist2 = dx*dx + dy*dy;
    
            if (dist2 <= RAD_2) begin
                if (immune) begin
                    r_next = 8'd204;
                    g_next = 8'd0;
                    b_next = 8'd204;
                end else begin
                    r_next = 8'h00;
                    g_next = 8'h00;
                    b_next = 8'hFF;
                end
            end
        end
    end // always_comb
    

	
	logic enable, obs_enable;
	logic [8:0] y_coord;
	
	// user input and position updates
	user_movement #(Y_GROUND, Y_TOP, GRAVITY, JUMP_VY, SPRITE_SIZE) umm (.clk(clk), .rst, .enable, .up(jump), .y_coord);
	slower_enable erm(.enable(enable), .rst, .clk(clk));
	
	
	logic [5:0] height_lfsr_in;
	logic [10:0] spawn_lfsr_in;
	logic [3:0] shift_count;
	logic [5:0] left_ptr, right_ptr;
	logic [63:0][5:0] objects;
	logic [63:0][5:0] power_ups;
	logic [5:0] obj_height;
	logic obs_spawn, pow_spawn, power_up_gained, crash, immune, power_up_detected, crash_detected;
	
	
	obstacle_enable qhhh(.enable(obs_enable), .rst, .clk(clk));
	height_lfsr uhf(.Q(height_lfsr_in), .clk(clk), .rst, .enable(1'b1));
    
	object_manager arrr(.clk(clk), .rst, .enable(obs_enable & game_ip), .new_obs_height(height_lfsr_in), .new_pow_height(height_lfsr_in),
	        .shift_count, .left_ptr, .right_ptr, .obstacles(objects), .power_ups, .obs_spawn(obs_spawn), .pow_spawn(pow_spawn));
	spawn_lfsr sp(.obs_spawn, .pow_spawn, .clk(clk), .rst, .enable(1'b1), .bias({1'b0,bias}));
	
    collision #(Y_GROUND, SPRITE_SIZE, X_LEFT, DEPTH, NUM_OBS, POWER_UP_TOP) col(.y_coord, .shift_count, 
                .left_ptr, .obstacles(objects), .power_ups, .power_up_detected, .crash_detected);
    
    pulse p (.clk, .rst, .in(power_up_detected), .out(power_up_gained));
    pulse p2 (.clk, .rst, .in(crash_detected), .out(crash));
    
    user_state_controller (.rst, .clk, .crash(crash), .power_up_gained, .dead, .immune);
    
    counter csjsd(.clk, .rst, .enable(power_up_gained), .cnt(score));
    
endmodule  // game_screen_manager