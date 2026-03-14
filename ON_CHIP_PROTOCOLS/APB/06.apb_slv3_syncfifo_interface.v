// APB Synchronous fifo slave

`include "synchronous_fifo.sv"

module apb_slave3 #(parameter DATA_WIDTH = 32,		// data width
                    parameter SLAVE_MODE = 2,		// mode = 0 -> read only register, mode = 1 -> write only register, mode = 2 -> both read/write register
                    parameter DEPTH      = 256,
                    parameter ADDR_WIDTH  = 16)(		// 12 address bits and 4 slave select bits
               
  // system 
  input 						pclk,
  input 						presetn,			// asynchronous reset
  
  // input control signals from master
  input 						psel,				// slave select
  input [ADDR_WIDTH-1:0]		paddr,				// peripheral address
  input [DATA_WIDTH-1:0]		pwdata,			// peripheral write data
  input 						pwrite,			// peripheral read/write command --- write - 1, read - 0
  input 						penable, 		// peripheral slave enable
  
  // output status signal
  output reg [DATA_WIDTH-1:0]	prdata,				// read data
  output reg 					pready,				// slave ready signal
  output   			 			pslverr			// peripheral transmission failed -- error
);
  
  // internal wire 
  wire wr_en;
  wire rd_en;
  wire full, empty;
  wire [DATA_WIDTH-1:0] fifo_out;
  reg rd_delay;				// delay read data
  
  // generation of read/ write for FIFO by APB control signal
  assign wr_en = psel && penable && pwrite;		// fifo write enable
  assign rd_en = psel && penable && ~pwrite;		// fifo read enable
  
  assign pslverr = ((wr_en && full) | (rd_en && empty));
  
  // synchronous fifo instantation
  sync_fifo #(.WIDTH(DATA_WIDTH),
              .DEPTH(DEPTH))
  fifo_slave3 (.clk(pclk),
          	   .rstn(presetn),
          	   .wr_en(wr_en),
          	   .rd_en(rd_en),
               .data_in(pwdata),
               .data_out(fifo_out),
          	   .full(full),
          	   .empty(empty)
              );
  
  // APB read handling from FIFO
  always @(posedge pclk or negedge presetn) begin
    if(!presetn) begin
      pready   <= 0;
      prdata   <= 0;
      rd_delay <= 0;
    end
    else begin
      pready   <= 0;
      rd_delay <= 0;
      
      if(psel && penable) begin        
        if(!pwrite)
          rd_delay <= 1;
        else
          pready <= 1;        
      end
      if(rd_delay) begin		// added one cycle delay for the read data for output get reflect stable 
        pready <= 1;
        prdata <= fifo_out;
      end
    end
  end
endmodule
