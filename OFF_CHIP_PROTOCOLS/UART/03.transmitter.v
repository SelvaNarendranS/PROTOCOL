// UART transmitter
module transmitter #(
  parameter DATA_WIDTH = 8)
  (
    // system 
    input 					tx_clk,
    input 					rst,
    
    // input control signals
    input 					tx_en,			// transaction enable / write enable
    input 					tx_tick,
    input 					parity_en,		// parity bit enable
    input 					odd_r_even_parity,	// 0 - odd parity, 1 - even parity
    input [DATA_WIDTH-1:0] 	data_in,
    
    // status output signals
    output reg 				tx,				// transmission port
    output 					busy
  );
  
  // internal counter and registers
  localparam DATA_CNT_WDH = $clog2(DATA_WIDTH);
  
  reg [DATA_CNT_WDH-1:0] data_count;		// data bits counter
  reg [DATA_WIDTH-1:0]	 data_sft_reg;		// input data shift register
  reg parity_bit;
  
  // paameter of states
  parameter [2:0] IDLE 	 = 0,
  				  START  = 1,
  				  DATA 	 = 2,
  				  PARITY = 3,
  				  STOP 	 = 4;
  reg [2:0]state;
  
  always @(posedge tx_clk or negedge rst) begin
    if(!rst) begin
      state 	 <= IDLE;	// default state is idle
      tx 		 <= 1;		// tx line set to high
      data_count <= 0;
    end
    
    else begin
      case(state)
        // -------------- IDLE state -------------------
        IDLE : begin
          tx <= 1;
          if(tx_en) begin
            data_sft_reg <= data_in;	// storing input data to shift register
            state 		 <= START;
            parity_bit <= (odd_r_even_parity) ? ^data_in : ~(^data_in);
          end
        end
        
        // -------------- START state -------------------
        START : begin
          tx 		   <= 1;			// tx line high	
          if(tx_tick) begin
            state 	   <= DATA;
            tx 		   <= 0;	// start signal -- tx line set to low - start bit
            data_count <= 0;	// resetting the counter
          end
        end
        
        // -------------- DATA state -------------------
        DATA : begin
          if(tx_tick) begin
            tx <= data_sft_reg[data_count];		// passing data bit by bit from shift register to tx line  -- LSB first
            if(data_count == DATA_WIDTH-1) begin
              data_count <= 0;		// resetting the counter
              state 	 <= (parity_en) ? PARITY : STOP;
            end
            else
              data_count <= data_count + 1;
          end
        end
        
        // -------------- PARITY state -------------------
        PARITY : begin
          if(tx_tick) begin
            tx		<= parity_bit;	// transmit parity bit
            state 	<= STOP;
          end
        end
        
        // -------------- STOP state -------------------
        STOP : begin
          if(tx_tick) begin
            tx 	  <= 1'b1;			// stop bit
            state <= IDLE;
          end
        end
        
        default : state <= IDLE;
      endcase
    end
  end
  
  assign busy = (state != IDLE);		
endmodule