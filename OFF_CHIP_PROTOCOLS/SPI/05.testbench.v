// SPI(Serial Peripheral Interface) -- testbench

module spi_testbench;
  
  parameter DATA_WIDTH = 8;
  parameter SYS_CLK = 10_000_000;	// 10mhz
  parameter SPI_CLK = 500_000;	// 5khz
  
  reg clk;
  reg rst;
  reg sclk_gen_en;
  wire sclk_tick;
  
  reg 				  	spi_enable;				// spi start signal
  reg [DATA_WIDTH-1:0]  master_tx_datain;		// transmission data
  wire 			        busy;
  wire [DATA_WIDTH-1:0] master_rx_dataout;
  
  reg [DATA_WIDTH-1:0] 	slave_tx_datain;
  wire 				    done;
  wire [DATA_WIDTH-1:0] slave_rx_dataout;
  
  // instantation
  spi_top_module #(.SYS_CLK(SYS_CLK),
                   .SPI_CLK(SPI_CLK),
                   .DATA_WIDTH(DATA_WIDTH))
  spi_top (.clk(clk),
           .rst(rst),
           .sclk_gen_en(sclk_gen_en),
           .sclk_tick(sclk_tick),
           .spi_enable(spi_enable),
           .master_tx_datain(master_tx_datain),
           .busy(busy),
           .master_rx_dataout(master_rx_dataout),
           .slave_tx_datain(slave_tx_datain),
           .done(done),
           .slave_rx_dataout(slave_rx_dataout)
          );
  
  // clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  initial begin
    $monitor("  [%0t] -- spi_en = %0d | SCLK = %0b | cs = %b | MISO = %b | MOSI = %b | master_out = %0d(%b) | slave_out = %0d(%b) -- ms_st = %0d | slv_st = %0d", $time, spi_enable, spi_top.S_SCLK, spi_top.S_cs, spi_top.SOMI, spi_top.SIMO, master_rx_dataout,  master_rx_dataout, slave_rx_dataout, slave_rx_dataout, spi_top.master.state, spi_top.slave.state);
  end
  
  initial begin 
    $dumpfile ("dump.vcd");
    $dumpvars;
    
    // reset condition
    rst = 1;
    sclk_gen_en = 0;
    spi_enable = 0;
    master_tx_datain = 0;
    slave_tx_datain = 0;
    
    $display(" [%0t] ---------------- reset -----------", $time);
    #50;
    
    //release reset
    rst = 0;
    #50;
    $display(" [%0t] ---------------- reset released -----------", $time);
    
    run_task(1, 230, 145);
    run_task(1, 130, 56);
    run_task(1, 10, 8);
    
    #100;
    $finish;
  end
  
  task run_task( 
    input sclk_gen,
    input [DATA_WIDTH-1:0] master_datain, slave_datain
  );
    
    @(negedge clk);
    sclk_gen_en = sclk_gen;
    master_tx_datain = master_datain;
    slave_tx_datain = slave_datain;
    #20;
   
    $display("\t\t----------- NEXT DATA -----------------");
    $display("  [%0t] - master datain = %0d(%b) | slave datain = %0d(%b)", $time, master_tx_datain, master_tx_datain, slave_tx_datain, slave_tx_datain);
    
    $display(" --- spi enable done ---");
    
    spi_enable = 1;
    @(posedge busy);
    
    spi_enable = 0;
    @(posedge done);
    
    #10;
    $display("  [%0t] --- spi transmission and receive done ---", $time);
    if ((master_tx_datain == slave_rx_dataout) && (slave_tx_datain == master_rx_dataout)) begin
      $display("\t------------------------------------------------------------");
      $display("\t\t\t SUCCESS: Received master dataout = %0d | slave dataout = %0d correctly", master_rx_dataout, slave_rx_dataout);
      $display("\t--------------------------------------------------------------\n");
    end
    else begin
      $display("\t------------------------------------------------------------");
      $display("\t\t\t ERROR: Data mismatch send and receive failed");
      $display("\t--------------------------------------------------------------\n");
    end
    
    #100;
  endtask
  
endmodule