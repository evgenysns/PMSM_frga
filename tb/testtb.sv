`timescale 1 ns / 10 ps

import tdef_prm::*;
import tdef_pkg::*;

module testtb;

localparam PW = 25,
           OW = 18;
localparam ADC_W = 12;

// test vector input registers
clock_t     clock;
reg SPI_MOSI, SPI_CS, SPI_SCLK;
wire SPI_MISO;
reg [31:0]spi_tx_data, spi_rx_data;
integer spi_tx_idx, spi_rx_idx;
real spi_ht;
wire adc_sclk, adc_css, adc_dout, adc_din;
wire [2:0]sim_hall;
wire [1:0]sim_enc;
wire [15:0]sim_pwm_cmp[2:0];
wire [15:0]sim_abc_voltage[2:0];
wire signed [SYSRG_W-1:0]sim_vel_cmd, sim_vel_sns, sim_e_pos;
logic signed [SYSRG_W-1:0]sim_vel_sns_l;
wire [ADC_W-1:0]sim_phase_current[1:0];

initial begin                                                  
    clock.clk <= 1'b0;
    clock.rstn <= 1'b0;  
    clock.ce <= 1'b0;
    spi_init(20_000_000.0);    
end

initial begin                                                  
    $display("//===================================");
    $display($time, " Simulation start");
    
    init_module;
    reset_module;
    repeat(100) @(posedge clock.clk);
    
   
    //repeat(1_000_000) @(posedge clock.clk);
    repeat(20_000_000) @(posedge clock.clk);
    
    #10_000 $stop;
end                                                    

always 
  #10  clock.clk <= !clock.clk;                                                    
  
always_ff @(posedge clock.clk) begin
    testtb.sys_ctrl_dut.regs_routine_u.regs.dwg_state <= !(sim_vel_cmd == 'h0);
    testtb.sys_ctrl_dut.regs_routine_u.regs.dwg_break <= (sim_vel_cmd == 'h0);
    testtb.sys_ctrl_dut.regs_routine_u.regs.speed_val <= sim_vel_cmd;
    //testtb.sys_ctrl_dut.dwg_speed <= sim_vel_sns;
    testtb.sys_ctrl_dut.dwg_epos <= sim_e_pos;    
    testtb.sys_ctrl_dut.speed_loop_stb <= (sim_vel_sns != sim_vel_sns_l);
    sim_vel_sns_l<=sim_vel_sns;
end


sys_ctrl
sys_ctrl_dut (
    .clk                    ( clock.clk         ),
    .rstn                   ( clock.rstn        ),
    
    // SPI interface    
    .spi_slave_sclk         ( SPI_SCLK          ),
    .spi_slave_cs           ( SPI_CS            ),
    .spi_slave_mosi         ( SPI_MOSI          ),
    .spi_slave_miso         ( SPI_MISO          ),
    
    // ADC SPI meadure current 
    .adc_master_sclk        ( adc_sclk          ),
    .adc_master_cs          ( adc_css           ),
    .adc_master_mosi        ( adc_dout          ),
    .adc_master_miso        ( adc_din           ),
    
    // hall signal input
    .hall_sns               ( sim_hall          ),
    
    // incremental encoder input
    .enc_snd                ( sim_enc           ),
    
    // output for gate driver
    .ah_out                 ( ),
    .al_out                 ( ),
    .bh_out                 ( ),
    .bl_out                 ( ),
    .ch_out                 ( ),
    .cl_out                 ( ),
    
    //.dwg_speed              ( sim_vel_sns       )
    .dwg_epos               ()
);


//==============================================================================
sim_signals #(
    .ADC_W      ( ADC_W         ),
    .SYSRG_W    ( SYSRG_W       )
)
sim_signals(
    .hall_sensor            ( sim_hall          ),    
    .encoder                ( sim_enc           ),    
    .pwm_cmp                ( sim_pwm_cmp       ),
    .abc_voltage            ( sim_abc_voltage   ),
        
    .velocity_command       ( sim_vel_cmd       ),
    .velocity_measured      ( sim_vel_sns       ),
    .phase_current          ( sim_phase_current ),
    .electrical_position    ( sim_e_pos         )
);

adc_model #(
    .ADC_N          ( 2      ),
    .ADC_W          ( ADC_W      )
)adc_model_tb(
    .adc_sclk               ( adc_sclk          ),
    .adc_css                ( adc_css           ),
    .adc_dout               ( adc_dout          ),
    .adc_din                ( adc_din           ),
    .adc_data               ( sim_phase_current )
);
//==============================================================================
// task description
//==============================================================================
task init_module;
begin
    clock.rstn = 1'b0;   
    sim_vel_sns_l ='h0;    
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

