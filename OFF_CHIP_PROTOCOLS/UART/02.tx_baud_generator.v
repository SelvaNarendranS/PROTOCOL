// UART Transmitter baud generator
// `timescale 1ns/1ps

module tx_baud_generator #(
  parameter TX_SYS_CLK   = 50_000_000, 		// Hz -- in hertz(mhz)
  parameter BAUD_RATE = 9600)				// baud rate
  (
    input 		tx_clk,
    input 		rst,
    input 		baud_gen_en,
    output reg 	tx_tick		// transmitter baud clock
  );
  
  // baud clock cycle calculation
  localparam integer tx_cycle = TX_SYS_CLK / BAUD_RATE;	// transmitter clk pulse per system clock - count of sys clk required

  // counter 
  localparam TX_CNT_WDH = $clog2(tx_cycle);		
  
  reg [TX_CNT_WDH-1:0]tx_count;	// transmitter sys clk cycle counter
  
  // transmitter baud generator
  always @(posedge tx_clk or negedge rst) begin
    if(!rst) begin
      tx_count <= 0;
      tx_tick  <= 0;
    end
    else if(baud_gen_en) begin
      if(tx_count == tx_cycle - 1) begin	// transmitter baud clk pulse & counter reset
        tx_count <= 0;
        tx_tick  <= 1;
      endza
      else begin
        tx_tick <= 0;
        tx_count <= tx_count + 1'b1;			// counter updatation
      end
    end
  end
  
endmodule