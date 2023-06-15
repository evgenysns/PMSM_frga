`timescale 1 ns / 10 ps

import tdef_prm::*;
import tdef_pkg::*;

module testtb_svpwm;

localparam MAX_VOLTAGE = 24;

// test vector input registers
clock_t     clock;
logic SPI_MOSI, SPI_CS, SPI_SCLK;
wire SPI_MISO;
logic [31:0]spi_tx_data, spi_rx_data;
integer spi_tx_idx, spi_rx_idx;
real spi_ht;
ph_data_t sim_voltage, sim_voltage_l, swpwm;
logic sim_voltage_val;

initial begin            
    
    clock.clk = 1'b0;
    clock.rstn = 1'b0;  
    clock.ce = 1'b0;
    spi_init(20_000_000.0);    
end

initial begin                                                  
    $display("//===================================");
    $display($time, " Simulation start");
    
    init_module;
    reset_module;
    repeat(100) @(posedge clock.clk);
    
   
    //repeat(1_000_000) @(posedge clock.clk);
    repeat(5_000_000) @(posedge clock.clk);
    
    #10_000 $stop;
end                                                    

always
  #10  clock.clk <= !clock.clk;  
  
always_ff @(posedge clock.clk) begin
    if(!clock.rstn)begin
        sim_voltage_l.data <= {'h0, 'h0, 'h0};
        sim_voltage.val <= 1'b0;
    end
    if(!(sim_voltage.data[0] == sim_voltage_l.data[0] 
        && sim_voltage.data[1] == sim_voltage_l.data[1]
        && sim_voltage.data[2] == sim_voltage_l.data[2])) begin
           sim_voltage_l.data[0] <= sim_voltage.data[0];
           sim_voltage_l.data[1] <= sim_voltage.data[1];
           sim_voltage_l.data[2] <= sim_voltage.data[2];
           sim_voltage.val <= 1'b1;
    end
    else 
        sim_voltage.val <= 1'b0;
end

//-----------------------------------------------------------
// DUT
//-----------------------------------------------------------
svmod
svmod   (
    .clock          ( clock             ),
    .voltage        ( sim_voltage       ),
    .out            ( swpwm             )
);

//-----------------------------------------------------------
// FOC voltage output
//-----------------------------------------------------------
sim_ssignal#(
    .FNAME("./msim_data/abcvoltage_0.msim"),
    .WIDTH      ( 18        ),
    .MIN        ( -MAX_VOLTAGE   ),
    .MAX        ( MAX_VOLTAGE   )
)
voltage_a  (
    .out     ( sim_voltage.data[0]     )
);

sim_ssignal#( 
    .FNAME("./msim_data/abcvoltage_1.msim"),
    .WIDTH      ( 18        ),
    .MIN        ( -MAX_VOLTAGE   ),
    .MAX        ( MAX_VOLTAGE   )
)
voltage_b  (
    .out     ( sim_voltage.data[1]     )
);

sim_ssignal#( 
    .FNAME("./msim_data/abcvoltage_2.msim"),
    .WIDTH      ( 18        ),
    .MIN        ( -MAX_VOLTAGE   ),
    .MAX        ( MAX_VOLTAGE   )
)
voltage_c  (
    .out     ( sim_voltage.data[2]     )
);


//==============================================================================
// task description
//==============================================================================
task init_module;
begin
    clock.rstn = 1'b0;
end
endtask

//==============================================================================
task reset_module;
begin
    clock.rstn = 1'b0;
    #777
    clock.rstn = 1'b1;
end
endtask

//==============================================================================
task spi_init;
    input spi_freq;
    real spi_freq;
begin
    spi_ht = (1e9/(2.0*spi_freq));
    spi_tx_idx     = 0;
    spi_rx_idx     = 0;
    SPI_CS      = 1'b1;
    SPI_MOSI    = 1'b0;
    SPI_SCLK    = 1'b0;
end
endtask

//==============================================================================
task spi_start;
begin
    SPI_MOSI = 1'b0;
    SPI_SCLK = 1'b0;
    SPI_CS   = 1'b0;
    #(spi_ht);
end
endtask

//==============================================================================
task spi_stop;
begin
    #(spi_ht)SPI_CS = 1'b1;
    
    SPI_MOSI = 1'b0;
    SPI_SCLK = 1'b0;
    #(spi_ht);
end
endtask

//==============================================================================
task spi_push16;
    input [15:0]data;
begin
    spi_tx_idx = 15;
    spi_tx_data = data;
    SPI_MOSI = spi_tx_data[spi_tx_idx];
    repeat(16)begin
        #(spi_ht)   SPI_SCLK = 1'b1;
        #(spi_ht)   SPI_SCLK = 1'b0;
        spi_tx_idx = spi_tx_idx - 1;
        if(spi_tx_idx >= 0)
            SPI_MOSI = spi_tx_data[spi_tx_idx];
        if((spi_tx_idx+1)%8==0) #(spi_ht);
    end
    SPI_MOSI=1'b0;
end
endtask

//==============================================================================
task spi_push32;
    input [31:0]data;
begin
    spi_tx_idx = 31;
    spi_tx_data = data;
    SPI_MOSI = spi_tx_data[spi_tx_idx];
    repeat(32)begin
        #(spi_ht)   SPI_SCLK = 1'b1;
        #(spi_ht)   SPI_SCLK = 1'b0;
        spi_tx_idx = spi_tx_idx - 1;
        if(spi_tx_idx >= 0)
            SPI_MOSI = spi_tx_data[spi_tx_idx];
        if((spi_tx_idx+1)%8==0) #(spi_ht);
    end
    SPI_MOSI=1'b0;
end
endtask

//==============================================================================
task spi_push32_read;
begin
    spi_rx_data = 'h0;
    spi_rx_idx  = 31;
    SPI_MOSI    = 1'b0;
    
    repeat(32)begin
        #(spi_ht)   SPI_SCLK = 1'b1;
        #(spi_ht)   SPI_SCLK = 1'b0;
        if(spi_rx_idx >= 0)begin
            spi_rx_data[spi_rx_idx] = SPI_MISO;
            spi_rx_idx = spi_rx_idx - 1;
        end
        if((spi_rx_idx !=0) && (spi_rx_idx+1)%8==0) #(spi_ht);
    end
end
endtask

//==============================================================================
task spi_write_reg;
    input [11:0]reg_addr;
    input [31:0]reg_data;
begin
    spi_start;
    spi_push16({4'b0100, reg_addr});
    spi_push32(reg_data);
    spi_stop;
    $display($time, " Write reg 0x%x = 0x%x", reg_addr, reg_data[15:0]);
end
endtask

//==============================================================================
task spi_read_reg;
    input [11:0]reg_addr;
begin
    spi_start;
    spi_push16({4'h0, reg_addr});
    spi_push32_read;
    spi_stop;
    $display($time, " Read reg 0x%x = 0x%x", reg_addr, spi_rx_data[15:0]);
end
endtask
//==============================================================================
//==============================================================================



endmodule

