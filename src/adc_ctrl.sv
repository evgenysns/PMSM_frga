import tdef_prm::*;
import tdef_pkg::*;

module adc_ctrl (
    input   clock_t     clock,    
    input   logic       adc_ce,
    output  adc_data_t  adc_data,
    output  flt_data_t  flt_data,
    
    // adc interface
    output logic        adc_sclk,
    output logic        adc_css,
    output  logic       adc_dout,
    input logic         adc_din
);
localparam ADC_CNT_W = $clog2(ADC_N) + 1;
wire adc_rdy;
logic [2:0]adc_channel;
wire chnl_done = (adc_channel == (ADC_N-1));

// control fsm
enum logic[1:0]{IDLE, ADC_START, ADC_WAIT, ADC_FRDY} fsm, nfsm;    
always_ff @(posedge clock.clk)
    if(!clock.rstn) fsm <= IDLE;
    else            fsm <= nfsm;

always_comb
case (fsm)
    IDLE        :
        if(adc_ce)      nfsm <= ADC_START;
        else            nfsm <= IDLE;        
    ADC_START   :       nfsm <= ADC_WAIT;        
    ADC_WAIT    :   
        if(adc_rdy)     nfsm <= ADC_FRDY;
        else            nfsm <= ADC_WAIT;
    ADC_FRDY     :
        if(chnl_done & !adc_ce)   
                        nfsm <= IDLE;
        else            nfsm <= ADC_START;
    default     :       nfsm <= IDLE;
endcase

wire [ADC_W-1:0]adc_res;

adc128s022
adc128s022_u(
    .clk            ( clock.clk                     ),
    .rstn           ( clock.rstn                    ),
    .channel        ( adc_channel                   ),
    .data           ( adc_res                       ),
                    
    .wr             ( (fsm == ADC_START)            ),
    .rdy            ( adc_rdy                       ),
    .clk_div        ( ADC_CLK_DIV                   ),
                                
    .adc_sclk       ( adc_sclk                      ),
    .adc_css        ( adc_css                       ),
    .adc_dout       ( adc_din                       ),
    .adc_din        ( adc_dout                      )
    
);

always_ff @(posedge clock.clk)
    if(adc_rdy) adc_data.data[adc_channel] <= adc_res;
    
always_ff @(posedge clock.clk)
    if(adc_rdy && chnl_done)    adc_data.val = 1'b1;
    else                        adc_data.val = 1'b0;

// count adc results
always_ff @(posedge clock.clk)
    if(fsm == IDLE)
        adc_channel <= '0;
    else if(fsm == ADC_FRDY)
        adc_channel <= (chnl_done)? '0: (adc_channel + 1'b1);

slpf
slpf_u (
    .clock          ( clock                         ),
    .chnl           ( adc_channel                   ),
    .we             ( adc_rdy                       ),
    .di             ( adc_res                       ),
    .fres           ( flt_data                      )
);


endmodule
