import tdef_prm::*;
import tdef_pkg::*;

module clark_tf (
    input   clock_t     clock,
    input               we,
    input   dbl_s_t     phase_data,
    output  dbl_s_t     out
);
localparam sqrt_3 = 19'hBAE00;

logic [SYSRG_W-1:0]o_sft;
logic [SYSRG_W-1:0]a_phase;
always_comb begin
    out.a = a_phase;
    out.b = o_sft;
end

wire [2*SYSRG_W-1:0]sft = (phase_data.b << 1) * sqrt_3 ;

always_ff @(posedge clock.clk)
    if(!clock.rstn) o_sft <= 'h0;
    else if(we)     o_sft <= sft >> SYSRG_W;

always_ff @(posedge clock.clk)
    if(!clock.rstn) a_phase <= 'h0;
    else if(we)     a_phase <= phase_data.a;

endmodule

