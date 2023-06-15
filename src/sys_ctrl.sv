import tdef_prm::*;
import tdef_pkg::*;

module sys_ctrl(
    // clock signals
    input           clk,
    input           rstn,
    
    // SPI interface
    input           spi_slave_sclk,
    input           spi_slave_cs,
    input           spi_slave_mosi,
    output          spi_slave_miso,
    
    // ADC SPI meadure current 
    output          adc_master_sclk,
    output          adc_master_cs,
    output          adc_master_mosi,
    input           adc_master_miso,
            
    // hall signal input
    input   [2:0]   hall_sns,
            
    // incremental encoder input
    input   [1:0]   enc_snd,
    
    // output for gate driver
    output  logic   ah_out,
    output  logic   al_out,
    output  logic   bh_out,
    output  logic   bl_out,
    output  logic   ch_out,
    output  logic   cl_out,
    
    // for debug
    //input signed [SYSRG_W-1:0]dwg_speed
	 input [SYSRG_W-1:0]dwg_epos
);


wire spi2bus_wreq, spi2bus_rreq;
wire [11:0]spi2bus_addr;
wire[31:0]spi2bus_wdata;
wire[15:0]bus2spi_rdata;
wire 
    current_stb,
    current_busy,
    current_init,
    current_loop_stb,
	 speed_loop_stb,
    emergency_stop_stb;
//logic speed_loop_stb;

sys_regs_t  sys_regs;
clock_t     clock;
adc_data_t  adc_data;
flt_data_t  flt_data;
wire sns_ce;
assign clock.clk = clk;
assign clock.rstn = rstn;
assign clock.ce = 1'b1;

//==============================================================================
// spi slave communication logic
spi_slave
spi_slave_u(
    // clock signals
    .HCLK                   ( clock.clk                 ),
    .HRESETn                ( clock.rstn                ),
    .SPI_SLAVE_CLK          ( spi_slave_sclk            ),
    .SPI_SLAVE_CLKB         ( ~spi_slave_sclk           ),
    
    // SPI interface
    .spi_slave_cs           ((!spi_slave_cs & rstn)     ),
    .spi_slave_mosi         ( spi_slave_mosi            ),
    .spi_slave_miso         ( spi_slave_miso            ),
    
    // SPI slave control signals
    .spi_cpha               ( 1'b0                      ),
    .spi_dummy_len          ( 1'b0                      ),
    
    // BUS interface
    .spi2bus_wreq           ( spi2bus_wreq              ),
    .spi2bus_rreq           ( spi2bus_rreq              ),
    .spi2bus_addr           ( spi2bus_addr              ),
    .spi2bus_wdata          ( spi2bus_wdata             ),
    .bus2spi_rdata          ( {16'h0, bus2spi_rdata}    )
);

//==============================================================================
// system settings
regs_routine
regs_routine_u(
    .clock                  ( clock                     ),
    .spi2bus_wreq           ( spi2bus_wreq              ),
    .spi2bus_rreq           ( spi2bus_rreq              ),
    .spi2bus_addr           ( spi2bus_addr              ),
    .spi2bus_wdata          ( spi2bus_wdata[15:0]       ),
    .bus2spi_rdata          ( bus2spi_rdata             ),
    .regs                   ( sys_regs                  )
);


//==============================================================================
// main control unit
main_fsm
main_fsm_u(
    .clock                  ( clock                     ),
    .regs                   ( sys_regs                  ),
    .init_done              ( 1'b1                      ),
    
    .current_loop_stb       ( current_loop_stb          ),
    .speed_loop_stb         ( speed_loop_stb            ),//speed_loop_stb
    .emergency_stop_stb     ( emergency_stop_stb        ),
    .sns_ce                 ( sns_ce                    ),
    
    .chnla_err              (                           ),
    .chnlb_err              (                           ),
    .gate_error             (                           )
);

//==============================================================================
// adc controller for sense phase current
adc_ctrl
adc_ctrl_u (
    .clock                  ( clock                     ),
    .adc_ce                 ( sns_ce                    ),
    .adc_data               ( adc_data                  ),
    .flt_data               ( flt_data                  ),
    .adc_sclk               ( adc_master_sclk           ),
    .adc_css                ( adc_master_cs             ),
    .adc_dout               ( adc_master_mosi           ),
    .adc_din                ( adc_master_miso           )
);

dbl_s_t                 flt_current;
always_comb begin
    flt_current.a = flt_data.data[0];
    flt_current.b = flt_data.data[1];
end

//==============================================================================
// debug ram for phase cuurnt
localparam DBG_CURR_RAM_SZ = 4096;
localparam DBG_CURR_RAM_W = $clog2(DBG_CURR_RAM_SZ);
logic [DBG_CURR_RAM_W-1:0]cur_ram_wadr;
always @(posedge clock.clk)
    if(!clock.rstn)         cur_ram_wadr <= 'h0;
    else if(adc_data.val)   cur_ram_wadr++;
    
dp_ram #(
    .DATA_WIDTH         (2*ADC_W            ),
    .ADDR_WIDTH         ( DBG_CURR_RAM_W    )
)
dbg_phase_curr_ram (
    .clk                    ( clock.clk                 ),
    .we                     ( adc_data.val              ),
	.data                   ( {adc_data.data[1], adc_data.data[0]}),
	.read_addr              ( ),
    .write_addr             ( cur_ram_wadr              ),
	.q                      ( )
);

//==============================================================================

wire signed [SYSRG_W-1:0]speed_loop_out;
ctrl_loop #(
    .WIDTH      (   SYSRG_W     )
)
speed_loop_ctrl (
    .clock                  ( clock                     ),
    .we                     ( speed_loop_stb            ),
    .set_in                 ( sys_regs.speed_val        ),
    .sys_in                 ( sys_regs.dwg_speed_val        ),
    //.sys_in                 ( dwg_speed                 ),        // for debug
    .pid_prm                ( sys_regs.speed_pid_prm    ),
    .oe                     ( ),
    .out                    ( speed_loop_out            )
);

//==============================================================================
wire current_loop_oe;
ph_data_t current_loop_out;
ph_data_t spwm_cmp;
current_loop #(
    .WIDTH      ( SYSRG_W       )
)
current_loop    (
    .clock                  ( clock                     ),
    .we                     ( current_loop_stb          ),
    .q_set                  ( speed_loop_out            ),
    .e_pos                  ( dwg_epos                  ),    
    .phase_data             ( flt_current               ),
    .dpid_prm               ( sys_regs.d_curr_pid_prm   ),    
    .qpid_prm               ( sys_regs.q_curr_pid_prm   ),
    .oe					    ( current_loop_oe			),
    .out					( current_loop_out			)
);


//==============================================================================
// for debug compilation
svmod
svmod   (
    .clock                  ( clock                     ),
    .voltage                ( current_loop_out          ),
    .out                    ( spwm_cmp                  )
);

always_ff @(posedge clock.clk)begin
    if(!clock.rstn)begin
        ah_out <= 1'b0;
        al_out <= 1'b0;    
        bh_out <= 1'b0;    
        bl_out <= 1'b0;    
        ch_out <= 1'b0;    
        cl_out <= 1'b0;    
    end
    else if(spwm_cmp.val)begin
        {ah_out, al_out} <= {(spwm_cmp.data[0] == 'h0), (spwm_cmp.data[0] == {{SYSRG_W}{1'b1}})};
        {bh_out, bl_out} <= {(spwm_cmp.data[1] == 'h0), (spwm_cmp.data[1] == {{SYSRG_W}{1'b1}})};
        {ch_out, cl_out} <= {(spwm_cmp.data[2] == 'h0), (spwm_cmp.data[2] == {{SYSRG_W}{1'b1}})};
    end
end

endmodule
