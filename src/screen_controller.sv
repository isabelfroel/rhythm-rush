/* Controls which screen is currently displayed (start screen, gameplay screen,
 * and end screen)
 *
 * Inputs:
 *   rst   - synchronous reset; returns the controller to the start screen
 *   clk   - system clock
 *   start - signal to begin the game from the start screen
 *   dead  - signal indicating the player has died
 *
 * Outputs:
 *   screen_select - 2'b00 = start screen
 *                   2'b01 = gameplay screen
 *                   2'b10 = end screen
 */
module screen_controller (rst, clk, screen_select, start, dead);
  // controll signals (out)
  output logic [1:0] screen_select; // 00 is start screen, 01 is game screen, 10 is end screen
  // external input (in)
  input logic rst, clk, start, dead;
  
  // define state names and variables
  enum logic [3:0] {S_Start, S_Game, S_End} ps, ns;

  // controller logic w/synchronous reset
  always_ff @(posedge clk)
    if (rst)
      ps <= S_Start;
    else
      ps <= ns;
  
  // next state logic
  always_comb
    case (ps)
      S_Start: begin 
        ns = start? S_Game : S_Start;
        screen_select = 2'b0;
        end
      S_Game: begin 
        ns = dead? S_End : S_Game;
        screen_select = 2'b01;
        end
      S_End: begin 
        ns = S_End;
        screen_select = 2'b10;
        end
    endcase
  
endmodule  // screen_controller

`timescale 1 ps / 1 ps
module screen_controller_tb ();

	logic [1:0] screen_select;
   logic rst, clk, start, dead;
	
	// instantiate module
	screen_controller dut (.*);
	
	// create simulated clock
	parameter T = 20;
	initial begin
		clk <= 0;
		forever #(T/2) clk <= ~clk;
	end  // clock initial
	
	// simulated inputs
	initial begin
    rst <= 1; start <= 0; dead <= 0; @(posedge clk);
    rst <= 0; @(posedge clk); // reset 
    @(posedge clk); // self-loop
    start <= 1; @(posedge clk); // go to immune
    start <= 0; @(posedge clk); // stay in immune
    dead <= 1; @(posedge clk); // go to back to alive
    dead <= 0; @(posedge clk); 
		$stop();
	end  // inputs initial
	
endmodule  // screen_controller_tb