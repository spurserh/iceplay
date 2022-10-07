
// Credit to https://www.eevblog.com/forum/fpga/looking-for-good-32-bit-pseudo-rng-in-systemverilog/
module LFSR_rng(
    input clk,
    output [31:0] rand_out
);

  reg [31:0] rand_ff = 32'hDEADBEEF;

  always @(posedge clk)
  begin
     rand_ff<={(rand_ff[31]^rand_ff[30]^rand_ff[10]^rand_ff[0]),rand_ff[31:1]};
  end

  assign rand_out = rand_ff;
endmodule



module window_sum(input clk, input raw_in, output [$clog2(WINDOW_BITS)-1:0] count_out);  
  parameter WINDOW_BITS = 16;

  reg [WINDOW_BITS-1:0] in_latched = {0};
  reg [$clog2(WINDOW_BITS)-1:0] latched_set = {0};

  always @(posedge clk) begin
    latched_set <= latched_set - (in_latched[WINDOW_BITS-1] ? 1 : 0) + (in_latched[0] ? 1 : 0);    
    in_latched <= {in_latched[WINDOW_BITS-2:0], ~raw_in};
  end

  assign count_out = latched_set;  

endmodule

module voltage_dac(input clk, output threshold, input [VOLTAGE_BITS-1:0] voltage);
  // Must be <= 32
  parameter VOLTAGE_BITS = 12;

  wire [31:0] rand_data;
  LFSR_rng rand_pwm(.clk(clk), .rand_out(rand_data));

  assign threshold = rand_data[VOLTAGE_BITS-1:0] < voltage;
endmodule

// 12Mhz
module top(input clkin, 
           input diff_input, input btn, output out, output threshold, output [7:0] led);


  wire clk = clkin;

 wire diff_in_0, diff_in_1;
`define PINTYPE 6'b010000
// `define IOSTANDARD "SB_LVCMOS"
`define IOSTANDARD "SB_LVDS_INPUT"
  ILVDS IO_PIN_I (
    .A(diff_input),
    .AN(1'b0),
    .Z(diff_in_0),
  );

  localparam BIG_WINDOW_BITS = 1024;
  localparam BIG_WINDOW_COUNT_BITS = $clog2(BIG_WINDOW_BITS);
  wire [BIG_WINDOW_COUNT_BITS-1:0] big_window_count;
  window_sum #(BIG_WINDOW_BITS) big_window(.clk(clk), .raw_in(diff_in_0), .count_out(big_window_count));




  reg in_latched;
  always @(posedge clk) begin
    in_latched <= diff_in_0;
  end

  assign out = in_latched;

  localparam SLOW_COUNT_BITS = 26;
  reg [SLOW_COUNT_BITS-1:0] slow_count = {0};
  always @(posedge clk) begin
    slow_count <= slow_count + 1;
  end

  localparam VOLTAGE_SERVO_BITS = BIG_WINDOW_COUNT_BITS;

  // Start in the middle
  reg [VOLTAGE_SERVO_BITS-1:0] voltage_servo = 1'b1 << (VOLTAGE_SERVO_BITS-1);

  localparam seek_threshold = 850;
  localparam seek_within = 20;

  always @(posedge clk) begin
    // Going too fast creates feedbacks
    if(slow_count[20:0] == 0) begin

      if(big_window_count < (seek_threshold - seek_within)) begin
        voltage_servo <= voltage_servo - (1 + (seek_threshold - big_window_count) >> 4);
      end else if(big_window_count > (seek_threshold + seek_within)) begin
        voltage_servo <= voltage_servo + (1 + (big_window_count - seek_threshold) >> 4);
      end
    end

  end


  voltage_dac #(VOLTAGE_SERVO_BITS) voltage_out(.clk(clk), .threshold(threshold), .voltage(voltage_servo));

  assign led = big_window_count[BIG_WINDOW_COUNT_BITS-1:BIG_WINDOW_COUNT_BITS-8];
endmodule
