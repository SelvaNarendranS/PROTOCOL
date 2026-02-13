// UART Receiver baud generator
// `timescale 1ns/1ps

module rx_baud_generator #(
  parameter RX_SYS_CLK   = 50_000_000, 		// Hz -- in hertz(mhz)
  parameter BAUD_RATE = 9600)				// baud rate
  (
    input 		rx_clk,
    input 		rst,
    input 		baud_gen_en,
    output reg 	rx_tick		// receiver baud clock oversample -- 16x 
  );
  
  // baud clock cycle calculation
  localparam integer rx_cycle = RX_SYS_CLK / (BAUD_RATE * 16); // receiver clk pulse per system clock - count of sys clk required -- samples 16 times of the transmitter baud clk
  
  // counter 	
  localparam RX_CNT_WDH = $clog2(rx_cycle);
  
  reg [RX_CNT_WDH-1:0]rx_count;	// receiver sys clk cycle counter
  
  
  // reeciver baud generator
  always @(posedge rx_clk or negedge rst) begin
    if(!rst) begin					
      rx_count <= 0;
      rx_tick  <= 0;
    end
    else if(baud_gen_en) begin
      if(rx_count == rx_cycle - 1) begin		// receiver baud clk pulse & counter reset
        rx_count <= 0;
        rx_tick  <= 1;
      end
      else begin
        rx_tick <= 0;
        rx_count <= rx_count + 1'b1;		// counter updation
      end
    end
  end
endmodule