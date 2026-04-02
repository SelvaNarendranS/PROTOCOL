// I2c master -- only for write(transmission only)

module i2c_master #(
  parameter ADDRESS_WIDTH = 7,
  parameter DATA_WIDTH    = 8)
  (
    // system
    input 					  clk,
    input 					  rst,
    
    // input control signals
    input 					  scl_clk,
    input 					  scl_tick,		// serial clock			
    input 					  i2c_en,		// i2c protocal enable
    input [ADDRESS_WIDTH-1:0] addr,
    input 					  rw,			// read - 1, write - 0 ---> read & write command
    input [DATA_WIDTH-1:0]	  data_in,		// input data for transmission
    
    // result output signal
    output 					  busy,
    output reg				  ack_err,		// acknowledgement error - not ack	
    
    // inout signal - serial clock and data
    inout 					  scl,			// serial clock port
    inout 					  sda			// serial data port
  );
  
  // local parameter - to find counter width
  localparam DATA_CNT_WDH = $clog2(DATA_WIDTH + 2);
  localparam ADDR_CNT_WDH = $clog2(ADDRESS_WIDTH + 2);	// extra bit to avoid overflow
  
  // internal counter & register
  reg [DATA_CNT_WDH-1:0] 	data_count;		// data bits counter
  reg [ADDR_CNT_WDH-1:0]	addr_count;		// address + rw bits counter 
  
  reg [DATA_WIDTH-1:0] 		data_sft_reg;	// input data shift register
  reg [ADDRESS_WIDTH:0] 	addr_sft_reg;	// input address + rw shift register	
  
  // internal register for -- open drain control
  reg  sda_out;		// serial data output signal
  
  // Logic to release SCL when not active
  reg scl_enable;
  
  // SDA & SCL line only drives "0" or "z" -- setting the both line as open drain
  assign sda = (sda_out) ? 1'bz : 1'b0;
  assign scl = (scl_enable && !scl_clk) ? 1'b0 : 1'bz;

  // serial clock edge detection
  wire scl_rising = scl_tick && scl_clk;
  wire scl_falling = scl_tick && (!scl_clk);
  
  // parameter for states
  parameter [2:0] 	IDLE 	  = 0,
  					START 	  = 1,
  					ADDRESS   = 2,
  					ADDR_ACK  = 3,
  					WRITE 	  = 4,
  					WRITE_ACK = 5,
  					STOP 	  = 6;
  reg [2:0]state;

  // i2c master fsm logic
  always @(posedge clk or negedge rst) begin
    if(!rst) begin			// active low reset
      state 	 <= IDLE;	// default state
      sda_out 	 <= 1;		// setting the scl and sda line high
      scl_enable <= 0;
      data_count <= 0;
      addr_count <= 0;		// resetting the counter
      ack_err	 <= 0;
    end
    
    else begin
      case(state)
        // -------------- IDLE state ------------------- 
        IDLE : begin
          sda_out <= 1;		// setting the scl and sda line high
          scl_enable <= 0;
          if(i2c_en) begin
            state <= START;
            data_sft_reg <= data_in;
            addr_sft_reg <= {addr, rw};
            ack_err	 	 <= 0;
          end
        end
        
        // -------------- START state -------------------
        START : begin
          sda_out    <= 0;		// sda line pulls low -- start bit --- sda falls while scl is high
          if(scl_falling) begin
            scl_enable <= 1;
            addr_count <= ADDRESS_WIDTH; // address + rw bit
            state 	   <= ADDRESS;	
            sda_out    <= addr_sft_reg[ADDRESS_WIDTH]; // preloading MSB bit
          end
        end
        
        // -------------- ADDRESS state -------------------
        ADDRESS : begin
          if(scl_falling) begin		
            if(addr_count == 0) begin
              state 	 <= ADDR_ACK;
              sda_out 	 <= 1;          // release SDA for AC
            end
            else begin
              addr_count <= addr_count - 1;		// decrementing the address counter
              sda_out	 <= addr_sft_reg[addr_count-1];	// sending address + rw bits on scl cl low
            end
          end
        end
        
        // -------------- ADDRESS ACKNOWLEDGEMENT state -------------------
        ADDR_ACK : begin
          sda_out <= 1;		//release sda line -- for slave to send acknowledgement
          if(scl_rising) begin			// at previous scl falling edge(low) and present scl should be high sample ack from slave
            if(sda) begin			// if ack(sda line) == 1 -- error in address received
              state <= STOP;
              ack_err <= 1;			// NACK received
            end
            else begin
              state <= (rw) ? STOP : WRITE;		// received ack
              data_count <= DATA_WIDTH;
            end
          end
        end
     
        // -------------- WRITE state -------------------
        WRITE : begin
          if(scl_falling) begin			// check previous clk high -- now present clk low(transmit happen)
            if(data_count == 0) begin
              state <= WRITE_ACK;
              sda_out <= 1;		// release for slave ACK
            end
            else begin
              sda_out <= data_sft_reg[data_count-1];	// data bit by bit transmission on negedge scl clk
              data_count <= data_count - 1;
            end
          end
        end
    
        // -------------- WRITE ACKNOWLEDGEMENT state -------------------
        WRITE_ACK : begin
          sda_out <= 1;		//release sda line -- for slave to send acknowledgement
          if(scl_rising) begin		// at present scl - high and previous - low sample data ack
            if(sda) 				// if ack(sda line) == 1 -- error in data received
              ack_err <= 1;			// NACK received
            state <= STOP;
          end
        end
        
        // -------------- STOP state -------------------
        STOP : begin
          if(scl_falling)
            sda_out <= 0;
          else if(scl_rising) begin		// negedge scl clk
            sda_out <= 1;		// Stop bit
            state   <= IDLE;
          end
        end
        
        default : state <= IDLE;
        
      endcase
    end
  end
  
  assign busy = (state != IDLE);
endmodule
