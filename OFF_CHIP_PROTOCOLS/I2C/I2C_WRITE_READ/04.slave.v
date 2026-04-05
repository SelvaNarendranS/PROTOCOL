// I2c slave - write and read operation

module i2c_slave #(
  parameter ADDRESS_WIDTH = 7,
  parameter DATA_WIDTH    = 8,
  parameter SLAVE_ADDR 	  = 32)
  (
    // ststem
    input 						clk,
    input 						rst,
    input [DATA_WIDTH-1:0]		data_in,
    
    // status output signals
    output reg 					done,
    output reg [DATA_WIDTH-1:0] data_out,		// output data -- received data
    
    // inout signal - serial clock and data
    inout 						scl,	// serial clock port
    inout 						sda		// serial data port
  );
  
  // local parameter - to find counter width
  localparam DATA_CNT_WDH = $clog2(DATA_WIDTH +1) + 1;
  localparam ADDR_CNT_WDH = $clog2(ADDRESS_WIDTH +1) + 1;
  
  // internal counter & register
  reg [DATA_CNT_WDH-1:0] 	data_count;		// data bits counter
  reg [ADDR_CNT_WDH-1:0] 	addr_count;		// address bits counter + rw bit
   
  reg [DATA_WIDTH-1:0] 		tx_data_sft_reg;	// data transfer shift register
  reg [DATA_WIDTH-1:0] 		rx_data_sft_reg;	// data receiver shift register
  reg [ADDRESS_WIDTH:0] 	addr_sft_reg;	// address shift register + rw bit
  
   // internal register for -- open drain control
  reg sda_out;		// serial data output signal
  
  // SDA & SCL line only drives "0" or "z" -- setting the both line as open drain
  assign scl = 1'bz;	
  assign sda = (sda_out) ? 1'bz : 1'b0;
  
  // synchronize the scl and sda for debouncing and metastability
  reg [2:0] scl_sync;
  reg [2:0] sda_sync;	// stores {previous, present, (current value in sda line)}
  						// receives on clk-3, <-- clk-2, <--- clk-1 on each clk-2 it get synchronized
  
  // synchronizer for scl and sda of master to slave
  always @(posedge clk) begin
    scl_sync <= {scl_sync[1:0], scl};		
    sda_sync <= {sda_sync[1:0], sda};		// gets current value(actual high/low) flowing in the line
  end
  
  // finding the scl and sda clock edge transition
  wire scl_rising  = (scl_sync[2:1] == 2'b01);	// detectes (previous & present) value => transition from 0 --> 1
  wire scl_falling = (scl_sync[2:1] == 2'b10);
  wire sda_rising  = (sda_sync[2:1] == 2'b01);
  wire sda_falling = (sda_sync[2:1] == 2'b10);
  
  wire scl_level = scl_sync[1];
  wire sda_level = sda_sync[1];
  
  // parameter for states
  parameter [2:0] 	IDLE 	  = 0,
  					ADDRESS   = 1,
  					ADDR_ACK  = 2,
  					WRITE 	  = 3,
  					WRITE_ACK = 4,
    				READ 	  = 5,
  					READ_ACK  = 6,
  					STOP 	  = 7;
  reg [2:0]state;
  
  always @(posedge clk or negedge rst) begin
    if(!rst) begin 	// active low reset
      state 	  	<= IDLE;	// default state
      sda_out 	  	<= 1;		// setting the scl and sda line high 
      data_count  	<= 0;
      addr_count  	<= 0;		// resetting the counter
      done			<= 0;
      data_out		<= 0;
      addr_sft_reg  <= 0;
      tx_data_sft_reg  <= 0;
      rx_data_sft_reg  <= 0;
    end
    else begin
      done <= 0;
      
      case(state)
        
        // -------------- IDLE state ------------------- 
        IDLE : begin
          sda_out 		<= 1;		// setting the scl and sda line high 
          if(sda_falling && scl_level) begin // start bit detection --- scl should be high and sda should be falling(low -- 1->0)
            addr_count   <= ADDRESS_WIDTH;	// setting the counter to maximum -- address + rw bits
            addr_sft_reg <= 'b0;		// clearing shift register
            state 	     <= ADDRESS;
          end
        end 
        
        ADDRESS : begin
          if(scl_rising) begin		// scl rising edge sample the address bits + read/write
            addr_sft_reg[addr_count] <= sda_level;		// sampling synchronized address bits + read/write
            if(addr_count == 0) 
              state <= ADDR_ACK;
            else
              addr_count <= addr_count - 1;		// address + rw counter decrementing counter
          end
          if(sda_falling && scl_level) begin
            addr_count <= ADDRESS_WIDTH;
            addr_sft_reg <= 0;
          end
        end
        
        // -------------- ADDRESS ACKNOWLEDGEMENT state -------------------
        ADDR_ACK : begin
          if(scl_falling) begin		// sending ack bit at posedge scl clk
            if(addr_sft_reg[ADDRESS_WIDTH:1] == SLAVE_ADDR[ADDRESS_WIDTH-1:0]) begin
              sda_out <= 0;			// ack bit sending
            end
            else
              sda_out <= 1;			// NACK
          end
		  else if (scl_rising) begin		
            sda_out <= 1; // release line -- after Ack bit
            if(addr_sft_reg[ADDRESS_WIDTH:1] == SLAVE_ADDR[ADDRESS_WIDTH-1:0]) begin
              if(!addr_sft_reg[0]) begin		// write
                rx_data_sft_reg <= 0;
                data_count 		<= DATA_WIDTH - 1;
                state 			<= WRITE;
              end
              else begin			// read
                data_count 	  	<= DATA_WIDTH - 1;
                tx_data_sft_reg <= data_in;
                state		  	<= READ;
              end
            end
            else
              state <= IDLE;
          end
        end
          
        // -------------- WRITE state -------------------
        WRITE : begin
          if(scl_rising) begin	// scl rising edge -- sampling the data bits
            rx_data_sft_reg[data_count] <= sda_level;	// sampling synchronizer data bits
            if(data_count == 0) begin
              state 		<= WRITE_ACK;
            end
            else
              data_count <= data_count - 1;		// decrementing data counter
          end
        end
        
        // -------------- WRITE ACKNOWLEDGEMENT state -------------------
        WRITE_ACK : begin
          if(scl_falling) begin		// sending ack bit at posedge scl clk
            sda_out <= 0;			// sending ack bit 
          end
		  else if (scl_rising) begin	// After ACK bit, release SDA
            sda_out <= 1; // release line
            state   <= STOP;
          end
        end
        
        
        // -------------- READ state -------------------
        READ : begin
          if(scl_falling) begin
            sda_out <= tx_data_sft_reg[data_count];			// driving read data's to master
            if(data_count == 0)
              state <= READ_ACK;
            else
              data_count <= data_count - 1'b1;
          end
        end
        
        // ------------------- READ ACKNOWLEDGEMENT state -------------------
        READ_ACK : begin
          if(scl_rising) begin
            if(sda_level) begin		// nack
              done <= 1;
              state <= STOP;
            end
            else begin			// ACK
              done <= 1;
              state <= STOP;
            end
          end
        end
        
        
        // -------------- STOP state -------------------
        STOP : begin
          if(sda_rising && scl_level) begin	// stop bit detection --- scl should be high and sda should be rising(low -- 0->1)
            data_out <= rx_data_sft_reg;
            done	 <= 1;
            state 	 <= IDLE;
          end
        end
        
        default : state <= IDLE;
        
      endcase
    end
  end
endmodule
