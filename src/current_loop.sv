import tdef_prm::*;
import tdef_pkg::*;

module current_loop #(
    input   clock_t                 clock,
    input                           we,
    input   signed   [SYSRG_W-1:0]  q_set,          // Current from velocity ctrl loop
    input            [SYSRG_W-1:0]  e_pos,          // Electrical_Position
    input   dbl_s_t                 phase_data,     // data from current sensors    
    input   pid_t                   dpid_prm,       // D loop ctrl parameters
    input   pid_t                   qpid_prm,       // Q loop ctrl parameters
    output  logic                   oe,
    output  ph_data_t               out
);

//==============================================================================
epos_sincos_t   sincos_pos;
cordic
cordic_epos (
    .i_clk              ( clock.clk                     ),
    .i_reset            ( !clock.rstn                   ),
    .i_stb              ( we                            ),
    .i_xval             ( 18'h0                         ),
    .i_yval             ( CORDIC_GAIN                   ),
    .i_phase            ( e_pos                         ),
    .o_busy             (                               ),
    .o_done             ( sincos_pos.val                ),
    .o_xval             ( sincos_pos.ep_cos             ),
    .o_yval             ( sincos_pos.ep_sin             )
);

//==============================================================================
dbl_s_t ab_current, dq_current, dq_out;
// convert phase current to alpha/beta plane
clark_tf
clark_tf    (
    .clock              ( clock                         ),
    .we                 ( we                            ),
    .phase_data         ( phase_data                    ),
    .out                ( ab_current                    )
);

//==============================================================================
// convert alpha/beta current to DQ plane
wire dq_we;
park_tf
park_tf     (
    .clock              ( clock                         ),    
    .ab_current         ( ab_current                    ),
    .epos_sincos        ( sincos_pos                    ),
    .dq_current         ( dq_current                    ),
    .oe                 ( dq_we                         )
);

//==============================================================================
// DQ Current Control
wire d_rdy, q_rdy;
ctrl_loop #(
    .WIDTH      (   SYSRG_W     )
)
d_ctrl (
    .clock                  ( clock                     ),
    .we                     ( dq_we                     ),
    .set_in                 ( 'h0                       ),
    .sys_in                 ( dq_current.a              ),
    .pid_prm                ( dpid_prm                  ),
    .oe                     ( d_rdy                     ),
    .out                    ( dq_out.a                  )
);

ctrl_loop #(
    .WIDTH      (   SYSRG_W     )
)
q_ctrl (
    .clock                  ( clock                     ),
    .we                     ( dq_we                     ),
    .set_in                 ( q_set                     ),
    .sys_in                 ( dq_current.b              ),
    .pid_prm                ( qpid_prm                  ),
    .oe                     ( q_rdy                     ),
    .out                    ( dq_out.b                  )
);

logic dq_loop_rdy;
always_ff @(posedge clock.clk)
    if(!clock.rstn)     
        dq_loop_rdy <= 1'b0;
    else if(d_rdy || q_rdy)
        dq_loop_rdy <= 1'b1;
    else
        dq_loop_rdy <= 1'b1;

//==============================================================================
// TODO: inverse park & clark

//==============================================================================
// nop for build
always_ff @(posedge clock.clk)
    if(!clock.rstn) begin     
        out.data[0] <= 'h0;
        out.data[1] <= 'h0;
        out.data[2] <= 'h0;
    end
    else if(dq_loop_rdy)begin
        out.data[0] <= dq_out.a;
        out.data[1] <= dq_out.b;
        out.data[2] <= dq_out.a+dq_out.b;
    end
        
always_ff @(posedge clock.clk)
    if(!clock.rstn)         out.val <= 1'b0;
    else if(dq_loop_rdy)    out.val <= 1'b1;
    else                    out.val <= 1'b0;
    
endmodule  
