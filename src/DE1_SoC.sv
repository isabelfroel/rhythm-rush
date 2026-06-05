/* Top-level module for my lab 8 "Rhythm Rush" side-scrolling game on the DE1-SoC.
 * Synchronizes player input for jump and start. Screen controller switches 
 * between start, game, and end screen. Routes the selected screen's RGB values
 * to the VGA driver. Displays the current score on the seven-segment displays
 *
 * Inputs:
 *   CLOCK_50 - 50 MHz system clock
 *   KEY[0]   - jump
 *   KEY[3]   - start
 *   SW[9]    - reset
 *   SW[8-0]  - gameplay bias to increase "randomly" spawned obstacles
 *
 * Outputs:
 *   VGA_*    - VGA timing and RGB signals for 640x480 video output
 *   HEX0-HEX1- score board
 */
module DE1_SoC  #(
    parameter int Y_GROUND = 300,
    parameter int Y_TOP = 0,
    parameter int GRAVITY = 1,
    parameter int JUMP_VY = -20,
    parameter int SPRITE_SIZE = 20,
    parameter int X_LEFT = 100,
    parameter int SCREEN_W = 640,
    parameter int OBJ_H = 9,
    parameter int OBJ_WIDTH = 16,
    parameter int NUM_OBS = 10
)
(HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, KEY, LEDR, SW,
					 CLOCK_50, VGA_R, VGA_G, VGA_B, VGA_BLANK_N, VGA_CLK, VGA_HS, VGA_SYNC_N, VGA_VS);
	output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	output logic [9:0] LEDR;
	input logic [3:0] KEY;
	input logic [9:0] SW;

	input CLOCK_50;
	output [7:0] VGA_R;
	output [7:0] VGA_G;
	output [7:0] VGA_B;
	output VGA_BLANK_N;
	output VGA_CLK;
	output VGA_HS;
	output VGA_SYNC_N;
	output VGA_VS;

	logic reset;
	logic [9:0] x;
	logic [8:0] y;
	logic [7:0] r, g, b;
	
	video_driver #(.WIDTH(640), .HEIGHT(480))
		v1 (.CLOCK_50, .reset(1'b0), .x, .y, .r, .g, .b,
			 .VGA_R, .VGA_G, .VGA_B, .VGA_BLANK_N,
			 .VGA_CLK, .VGA_HS, .VGA_SYNC_N, .VGA_VS);
			 
	
	assign rst = SW[9];
	assign LEDR[0] = dead;
	logic jump, start, dead, game_ip;
	
	// user input and position updates
	user_input oui(.clk(CLOCK_50), .rst, .in(~KEY[0]), .out(jump));
	user_input ouii(.clk(CLOCK_50), .rst, .in(~KEY[3]), .out(start));
    
    logic [7:0] r_game, g_game, b_game, r_start, g_start, b_start, r_end, g_end, b_end;
    game_screen_manager  #(Y_GROUND, Y_TOP, GRAVITY, JUMP_VY, SPRITE_SIZE, X_LEFT, 
           NUM_OBS) gdm(.start, .rst, .jump, .bias(SW), .dead, .clk(CLOCK_50), .x, .y, .r(r_game), .g(g_game), .b(b_game), .game_ip, .score);
           
    end_screen_manager esm(.rst, .clk(CLOCK_50), .x, .y, .r(r_end), .g(g_end), .b(b_end));
	start_screen_manager ssm(.rst, .clk(CLOCK_50), .x, .y, .r(r_start), .g(g_start), .b(b_start));
	
	logic [1:0] screen_select; // 00 is start screen, 01 is game screen, 10 is end screen
	screen_controller dsm(.rst, .clk(CLOCK_50), .screen_select, .start, .dead);
	
	assign game_ip = (screen_select == 2'b01);
	assign LEDR[9:8] = screen_select;
	always_comb
    case (screen_select)
      2'b00: begin
        r = r_start;
        b = b_start;
        g = g_start;
        end
      2'b01: begin
        r = r_game;
        b = b_game;
        g = g_game;
        end
      2'b10: begin
        r = r_end;
        b = b_end;
        g = g_end;
        end
      default: begin
        r = 8'h00;
        b = 8'h00;
        g = 8'h00;
        end
    endcase
    
    logic [4:0] score;
    logic [6:0] h0, h1;
    seg7 s5(.hex({3'b000, score[4]}), .leds(h1)); // second hex digit for address
    seg7 s4(.hex(score[3:0]), .leds(h0)); // first hex digit for address
	
	assign HEX0 = h0;
	assign HEX1 = h1;
	assign HEX2 = '1;
	assign HEX3 = '1;
	assign HEX4 = '1;
	assign HEX5 = '1;
	
endmodule  // DE1_SoC


`timescale 1 ps / 1 ps
module DE1_SoC_testbench ();
	logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	logic [9:0] LEDR, SW;
	logic [3:0] KEY;
	logic CLOCK_50;
	logic [7:0] VGA_R, VGA_G, VGA_B;
	logic VGA_BLANK_N, VGA_CLK, VGA_HS, VGA_SYNC_N, VGA_VS;
	
	// instantiate module
	DE1_SoC dut (.*);
	
	// create simulated clock
	parameter T = 20;
	initial begin
		CLOCK_50 <= 0;
		forever #(T/2) CLOCK_50 <= ~CLOCK_50;
	end  // clock initial
	
	// simulated inputs
	initial begin
		
		$stop();
	end  // inputs initial
	
endmodule  // DE1_SoC_testbench