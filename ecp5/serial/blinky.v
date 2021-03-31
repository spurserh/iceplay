
module top(input clkin, input btn, 
           output out, output outk, 
           output uart_tx, input uart_rx,
           output [7:0] led);
  wire clk = clkin;

  reg [59:0] printer_state = {60{1'b0}};
  wire [59:0] printer_state_next;

  wire [63:0] word = 64'h0A42414241424142;

  printer i_printer(
    .state(printer_state),
    .tx_out(0),
    .word(word),
    // ... ?
    .out({printer_state_next, uart_tx})
  );

  assign out = uart_tx;

  reg[7:0] led_st = ~0;

  always @(posedge clk) begin
    printer_state <= printer_state_next;
    led[0] <= uart_tx;
  end

  assign led = led_st;
endmodule
