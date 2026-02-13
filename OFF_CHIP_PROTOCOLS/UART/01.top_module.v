// UART(Universal asynchronous receiver-transmitter) top module
`include "tx_baud_generator.v"
`include "rx_baud_generator.v"
`include "transmitter.v"
`include "receiver.v"

module uart_top_module #(
  parameter TX_SYS_CLK   = 10_000_000, 		// MHz -- in mega hertz
  parameter RX_SYS_CLK   = 50_000_000, 		// MHz -- in mega hertz
  parameter BAUD_RATE = 9600,				// baud rate
  parameter DATA_WIDTH = 8) 
  (
    // system
  	input 						tx_clk,
    input 						rx_clk,
    input 						rst,
    
    // input signals
    input 						tx_en,			// transaction enable / write enable
    input 						baud_gen_en,
    input 						parity_en,		// parity bit enable
    input 						odd_r_even_parity,	// 0 - odd parity, 1 - even parity
    input 						rx,				// rx port
    input [DATA_WIDTH-1:0] 		data_in,		// parallel input data 
    
    // output signal
    output 						tx,
    output 						busy,	// tx_busy
    output 						done,	// rx_done
    output 						framing_error,
    output 						parity_error,
    output [DATA_WIDTH-1:0]		data_out			// parallel rx - out data
  );
  
  // internal wire
  wire tx_tick;
  wire rx_tick;
  
  // instantation
  
  // Transmitter baud generator
  tx_baud_generator #(.TX_SYS_CLK(TX_SYS_CLK), 
                      .BAUD_RATE(BAUD_RATE))
  tx_baud_gen(
    .tx_clk(tx_clk),
    .rst(rst),
    .baud_gen_en(baud_gen_en),
    .tx_tick(tx_tick)
  );
  
  // transmitter 
  transmitter #(.DATA_WIDTH(DATA_WIDTH)) 
  transmit(
    .tx_clk(tx_clk),
    .rst(rst), 
    .tx_en(tx_en), 
    .tx_tick(tx_tick),
    .parity_en(parity_en),
    .odd_r_even_parity(odd_r_even_parity),
    .data_in(data_in),
    .tx(tx), 
    .busy(busy)
  );
  
  // Receiver baud generator
  rx_baud_generator #(.RX_SYS_CLK(RX_SYS_CLK), 
                      .BAUD_RATE(BAUD_RATE))
  rx_baud_gen(
    .rx_clk(rx_clk),
    .rst(rst),
    .baud_gen_en(baud_gen_en),
    .rx_tick(rx_tick)
  );
  
  // receiver
  receiver #(.DATA_WIDTH(DATA_WIDTH))
  receive(
    .rx_clk(rx_clk),
    .rst(rst),  
    .rx_tick(rx_tick),
    .rx(rx),
    .parity_en(parity_en),
    .odd_r_even_parity(odd_r_even_parity),
    .done(done),
    .framing_error(framing_error),
    .parity_error(parity_error),
    .data_out(data_out)
  );
  
//   assign tx_baud_gen_en = 1'b1;		// always it IF UART is Enable
//     assign rx_baud_gen_en = 1'b1;
  
endmodule