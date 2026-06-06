/* Tracks a user's movement
 * jumps up with acceleration and falls down due to gravity
 *
 * Inputs:
 *   clk    - should be connected to the 50 MHz clock
 *   reset  - resets the position to zero
 *   enable - is high when we should move the sprite
 *   up - user input to start a jump
 *
 * Outputs:
 *   y_coord - top left corner of the user's position
 */
module user_movement #(
    parameter int Y_GROUND    = 300,
    parameter int Y_TOP    = 100,
    parameter int GRAVITY     = 1,
    parameter int JUMP_VY     = -12,
    parameter int SPRITE_SIZE = 20
) (
    input  logic clk,
    input  logic rst,
    input  logic enable,
    input  logic up,
    output logic [8:0] y_coord
);

    logic signed [10:0] y_q,  y_d;
    logic signed [10:0] vy_q, vy_d;

    always_comb begin
        y_d = y_q;
        vy_d = vy_q;

        if (up & (y_q == Y_GROUND - SPRITE_SIZE)) begin
            vy_d = JUMP_VY;
            y_d = y_q + vy_d;
        end else if (enable) begin
            vy_d = vy_q + GRAVITY;
            
            y_d = y_q + vy_d;
            if (y_d >= Y_GROUND - SPRITE_SIZE) begin
                y_d  = Y_GROUND - SPRITE_SIZE;
                vy_d = 0;
            end else if (y_d < Y_TOP) begin
                 y_d  = Y_TOP;
                 if (vy_d < 0)
                     vy_d = 0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            y_q <= Y_GROUND - SPRITE_SIZE;
            vy_q <= 0;
        end else begin
            y_q <= y_d;
            vy_q <= vy_d;
        end
    end

    assign y_coord = y_q[8:0];

endmodule // user_movement

/* Testbench for user_movement
 * checks that the ball moves up and down correctly.
 * checks that a user can't double click to double bounce
 */
// `timescale 1ns/1ps
module user_movement_tb;
    logic clk, rst, enable, up;
    logic [8:0] y_coord;

    user_movement dut (.*);

    initial clk = 0;
    always #10 clk = ~clk;   // 20 ns period

    initial begin
        rst <= 1; enable <= 0; up <= 0; @(posedge clk); 
        rst <= 0; @(posedge clk);
        up <= 1; @(posedge clk); // start moving up immediately 
        up <= 0; @(posedge clk); // but doesn't continue moving until enable is high 
        @(posedge clk);
        enable <= 1; @(posedge clk); // should start moving
        up <= 0; @(posedge clk);
        repeat (30) @(posedge clk); // let it hit the top and fall down
        up <= 1; @(posedge clk);
        up <= 0; @(posedge clk); // jump again
        repeat (10) @(posedge clk);
        up <= 1; @(posedge clk); // interupt with up and see what happens
        repeat (20) @(posedge clk); 
        $stop;
    end

endmodule // user_movement_tb