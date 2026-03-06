// APB -- TOP MODULE

`include "master.sv"
`include "slave1.sv"
`include "slave2.sv"
`include "slave_decoder1.sv"
`include "apb_fifo_slave3.sv"

`define SLAVE_MODE 2
`define SLV_ADDR_WIDTH 12

module apb_top_module #(parameter DATA_WIDTH  = 16,		// data width
                        parameter DEPTH       = 256,
                        parameter ADDR_WIDTH  = 16)(		// 12 address bits and 4 slave select bits	
  // system 
  input 						pclk,
  input 						presetn,			// asynchronous reset
  
  // input control signals
  input [DATA_WIDTH-1:0]		apb_pwdata,			// apb write data
  input [ADDR_WIDTH-1:0]		apb_pwaddr,			// apb write address
  input [ADDR_WIDTH-1:0]	    apb_praddr,			// apb read address
  input 						apb_pwrite,			// apb read/ write signal -- write - 1, read - 0
  input 						apb_tx_enable,		// apb master transmission enable
  
  // output status signal
  output [DATA_WIDTH-1:0]		apb_prdata,			// apb read data
  output    					busy,
  output 		 				pslverr			// peripheral transmission failed -- error
);
  
  wire 					slv_penable, slv_pwrite;
  wire [ADDR_WIDTH-1:0] slv_paddr;
  wire [DATA_WIDTH-1:0] slv_pwdata, prdata;
  wire 					pready;
  wire 					mux_psel;
  
  wire psel1, psel2, psel3, psel4;
  
  // multiple slave output pins connecting wire
  wire [DATA_WIDTH-1:0] slv1_prdata, slv2_prdata, slv3_prdata;
  wire 					slv1_pready, slv2_pready, slv3_pready;
  wire 					slv1_pslverr, slv2_pslverr, slv3_pslverr;
  
  assign prdata = (psel1) ? slv1_prdata : 
    				  (psel2) ? slv2_prdata : 
    				  (psel3) ? slv3_prdata : 32'h0;
  
  assign pready = (psel1) ? slv1_pready : 
    			  (psel2) ? slv2_pready : 
    			  (psel3) ? slv3_pready : 1'h1;
  
  assign pslverr = (psel1) ? slv1_pslverr : 
    			   (psel2) ? slv2_pslverr : 
    			   (psel3) ? slv3_pslverr : 1'h0;   
  
  // instantation
  // master
  apb_master #(.DEPTH(DEPTH),
               .DATA_WIDTH(DATA_WIDTH),
               .ADDR_WIDTH(ADDR_WIDTH))
  master (
    .pclk            (pclk),
    .presetn         (presetn),
    .apb_pwdata      (apb_pwdata),
    .apb_pwaddr      (apb_pwaddr),
    .apb_praddr      (apb_praddr), 
    .apb_prdata      (apb_prdata),          
    .apb_pwrite      (apb_pwrite),
    .apb_tx_enable   (apb_tx_enable),
    .prdata          (prdata),           // input from slave
    .pready          (pready),               // input from slave via top net
    .pslverr         (pslverr),              // input from slave via top net
    .psel            (mux_psel),	
    .paddr           (slv_paddr),	
    .pwdata          (slv_pwdata),
    .pwrite          (slv_pwrite),
    .penable         (slv_penable),
    .busy            (busy)
  );
  
  // slave decoder
  apb_slv_mux #(.DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH))
  slave_mux (.mas_psel(mux_psel),
             .paddr(slv_paddr),
             .psel1(psel1),
             .psel2(psel2),
             .psel3(psel3)
            );
  
  // slave1 instantiation				--- memory as slave
  apb_slave1 #(.DATA_WIDTH(DATA_WIDTH),
               .SLAVE_MODE(`SLAVE_MODE),
               .DEPTH(DEPTH),
               .ADDR_WIDTH(`SLV_ADDR_WIDTH))
  slave1 (
    .pclk     (pclk),
    .presetn  (presetn),
    .psel     (psel1),
    .paddr    (slv_paddr[`SLV_ADDR_WIDTH-1:0]),
    .pwdata   (slv_pwdata),
    .pwrite   (slv_pwrite),
    .penable  (slv_penable),
    .prdata   (slv1_prdata),           // output to master
    .pready   (slv1_pready),                // output to top and master
    .pslverr  (slv1_pslverr)                 // output to top and master
  );
  
  // slave2 instantiation				-- memory as slave
  apb_slave2 #(.DATA_WIDTH(DATA_WIDTH),
               .SLAVE_MODE(`SLAVE_MODE),
               .DEPTH(DEPTH),
               .ADDR_WIDTH(`SLV_ADDR_WIDTH))
  slave2 (
    .pclk     (pclk),
    .presetn  (presetn),
    .psel     (psel2),
    .paddr    (slv_paddr[`SLV_ADDR_WIDTH-1:0]),
    .pwdata   (slv_pwdata),
    .pwrite   (slv_pwrite),
    .penable  (slv_penable),
    .prdata   (slv2_prdata),           // output to master
    .pready   (slv2_pready),                // output to top and master
    .pslverr  (slv2_pslverr)                 // output to top and master
  );
  
  // slave3 instantiation			--- synshronous fifo
  apb_slave3 #(.DATA_WIDTH(DATA_WIDTH),
               .SLAVE_MODE(`SLAVE_MODE),
               .DEPTH(DEPTH),
               .ADDR_WIDTH(`SLV_ADDR_WIDTH))
  slave3 (
    .pclk     (pclk),
    .presetn  (presetn),
    .psel     (psel3),
    .paddr    (slv_paddr[`SLV_ADDR_WIDTH-1:0]),
    .pwdata   (slv_pwdata),
    .pwrite   (slv_pwrite),
    .penable  (slv_penable),
    .prdata   (slv3_prdata),           // output to master
    .pready   (slv3_pready),                // output to top and master
    .pslverr  (slv3_pslverr)                 // output to top and master
  );
  
endmodule