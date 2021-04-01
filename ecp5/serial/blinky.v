
module top(input clkin, input btn, 
           output out, output outk, 
           output uart_tx, input uart_rx,
           output [7:0] led);
  wire clk = clkin;

  localparam STATE_SIZE = 184;

  reg [STATE_SIZE-1:0] printer_state = {STATE_SIZE{1'b0}};
  wire [STATE_SIZE-1:0] printer_state_next;

  reg [31:0] number = 32'd0;

  printer i_printer(
    .this(printer_state),
    .tx_out(0),
    .number_in(number),
    .out({printer_state_next, uart_tx})
  );

  assign out = uart_tx;

  reg[7:0] led_st = ~0;

  reg [31:0] count = 32'd0;
  always @(posedge clk) begin
    printer_state <= printer_state_next;
    led[0] <= uart_tx;
    number <= count[26:21];
    count <= count + 1;
  end

  assign led = led_st;
endmodule
