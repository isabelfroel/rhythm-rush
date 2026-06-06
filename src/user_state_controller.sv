/* Tracks the player's alive, immune, and dead states.
 *
 * Player starts in alive state after reset, moves to the immune state when
 * a power-up is collected, and moves to the dead state when a crash occurs
 * without a power-up.
 *
 * Inputs:
 *   rst             - returns the player to the alive state
 *   clk             - system clock
 *   crash           - asserted when the player collides with an obstacle
 *   power_up_gained - asserted when the player collects a power-up
 *
 * Outputs:
 *   dead   - high when the player is in the dead state
 *   immune - high when the player is in the immune state
 */
module user_state_controller (rst, clk, crash, power_up_gained, dead, immune);
  // controll signals (out)
  output logic dead, immune;
  // external input (in)
  input logic rst, clk, crash, power_up_gained;
  
  // define state names and variables
  enum logic [1:0] {S_Alive, S_Immune, S_Dead} ps, ns;

  // controller logic w/synchronous reset
  always_ff @(posedge clk)
    if (rst)
      ps <= S_Alive;
    else
      ps <= ns;
  
  // next state logic
  always_comb
    case (ps)
      S_Alive: begin 
        ns = crash? S_Dead : power_up_gained? S_Immune : S_Alive;
        end
      S_Immune: begin 
        ns = crash? S_Alive : S_Immune;
        end
      S_Dead: begin 
        ns = S_Dead;
        end
    endcase
    
    assign immune = (ps == S_Immune);
    assign dead = (ps == S_Dead);
  
endmodule  // user_state_FSM


`timescale 1 ps / 1 ps
module user_state_controller_tb ();
    logic dead, immune;
    // external input (in)
    logic rst, clk, crash, power_up_gained;
	
	// instantiate module
	user_state_controller dut (.*);
	
	// create simulated clock
	parameter T = 20;
	initial begin
		clk <= 0;
		forever #(T/2) clk <= ~clk;
	end  // clock initial
	
	// simulated inputs
	initial begin
		// TODO:
    rst <= 1; crash <= 0; power_up_gained <= 0; @(posedge clk);
    rst <= 0; @(posedge clk); // reset 
    @(posedge clk); // self-loop
    power_up_gained <= 1; @(posedge clk); // go to immune
    power_up_gained <= 0; @(posedge clk); // stay in immune
    crash <= 1; @(posedge clk); // go to back to alive
    crash <= 0; @(posedge clk); 
    crash <= 1; @(posedge clk); // dead
    crash <= 1; @(posedge clk);
    crash <= 0; @(posedge clk); // stay dead
		$stop();
	end  // inputs initial
	
endmodule  // user_state_FSM_tb
