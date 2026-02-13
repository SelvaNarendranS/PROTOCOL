// UART receiver

module receiver #(
  parameter DATA_WIDTH = 8)
  (
    // system
    input 					    rx_clk,
    input 					    rst,
    
    // input control signal
    input 			 		    rx_tick,			// receiver baud tick
    input 					    rx,				// receiver port
    input 					    parity_en,		// parity bit enable
    input 					    odd_r_even_parity,	// 0 - odd parity, 1 - even parity
    
    // status output signal
    output reg				    done,
    output reg				    framing_error,
    output reg				    parity_error,
    output reg [DATA_WIDTH-1:0] data_out			// parallel rx - out data
  );
  
  // internal counter and registers
  localparam DATA_CNT_WDH = $clog2(DATA_WIDTH);
  
  reg [DATA_CNT_WDH-1:0]	data_count;		// data bits counter
  reg [DATA_WIDTH-1:0]		data_sft_reg;	// input data shift register
  reg [3:0]					rx_tick_count;	// counter to count 16 pulse per 1-tx tick - sample counter
  
  // paameter of states
  parameter [2:0] IDLE 	 = 0,
  				  START  = 1,
  				  DATA 	 = 2,
  				  PARITY = 3,
  				  STOP 	 = 4;
  reg [2:0]state;
  
  always @(posedge rx_clk or negedge rst) begin
    if(!rst) begin
      state 		<= IDLE;		// default state is idle
      data_count 	<= 0;			// resetting data counter
      rx_tick_count <= 0;
      data_out 	 	<= 0;
      parity_error	<= 0;
      framing_error	<= 0;
      done			<= 0;
    end
    
    else if(rx_tick) begin
      done <= 0;
      case(state)
        // -------------- IDLE state -------------------
        IDLE : begin
          rx_tick_count <= 0;
          data_count 	<= 0;			// resetting data counter
          parity_error	<= 0;
      	  framing_error	<= 0;
          if(rx == 0)
            state <= START; 		// detect start bit
        end
        
        // -------------- START state -------------------
        START : begin
          if(rx_tick_count == 7) begin			// rx sample at the middle of the tx clocl tick
            if(rx == 0) begin
              state <= DATA;
              rx_tick_count <= 0;			// resetting the sample counter
              data_count 	<= 0;			// resetting data counter
            end
            else
              state <= IDLE;		// false start
          end
          else
            rx_tick_count <= rx_tick_count + 1; // sample counter updation
        end
        
        // -------------- DATA state -------------------
        DATA : begin
          if(rx_tick_count == 15) begin
            data_sft_reg[data_count] <= rx;		// storing the data into shift register
//             data_sft_reg <= {rx, data_sft_reg[DATA_WIDTH-1:1]};	// storing the data into shift register
            rx_tick_count <= 0;
            if(data_count == DATA_WIDTH-1) begin
              data_count <= 0;
              state 	 <= (parity_en) ? PARITY : STOP;
            end
            else
              data_count <= data_count + 1;
          end
          else begin
            rx_tick_count <= rx_tick_count + 1;	// sample counter updation
          end
        end
        
        // -------------- PARITY state -------------------
        PARITY : begin
          if(rx_tick_count == 15) begin
            rx_tick_count <= 0;
            parity_error  <= (odd_r_even_parity) ? (^data_sft_reg != rx) : (~(^data_sft_reg) != rx);				// receives parity bit and compare 
            state 		  <= STOP;
          end
          else
            rx_tick_count <= rx_tick_count + 1;	// sample counter updation
        end
        
        // -------------- STOP state -------------------
        STOP : begin
          if(rx_tick_count == 15) begin
            if(rx == 1) begin
              done 	   	  <= 1;
              data_out 	  <= data_sft_reg;		// passing the output received data
              rx_tick_count <= 0;
              state	   	  <= IDLE;
            end
            else
              framing_error <= (rx != 1);		// error if stop bit not received              
          end
          else begin
           rx_tick_count <= rx_tick_count + 1;	// sample counter updation
          end
        end        
        
        default : state <= IDLE;
      endcase
    end
  end
endmodule