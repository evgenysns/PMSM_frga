import tdef_prm::*;
import tdef_pkg::*;

module park_tf (
    input   clock_t         clock,
    input   dbl_s_t         ab_current,     // alpha, beta current from clark transform
    input   epos_sincos_t   epos_sincos,
    output  logic           oe,
    output  dbl_s_t         dq_current
);

logic [2:0]sft;
always_ff @(posedge clock.clk)
    if(!clock.rstn) sft <= 'h0;
    else            sft <= {sft[1:0], epos_sincos.val};

logic signed[SYSRG_W-1:0]a, b;
wire signed[2*SYSRG_W-1:0]prod = a * b;
wire signed[SYSRG_W-1:0]prod_w = prod>>SYSRG_W;

always_comb begin
    if(sft == 3'b001)
        a = ab_current.a;
    else 
        a = ab_current.b;
end

always_comb begin
    if(sft == 3'b001)
        b = epos_sincos.ep_cos;
    else 
        b = epos_sincos.ep_sin;
end

always_ff @(posedge clock.clk)
    if(sft == 3'b001)
        dq_current.a = prod_w;
    else if(sft == 3'b010)
        dq_current.b = prod_w;

always_ff @(posedge clock.clk)
    if(!clock.rstn)         oe <= 1'b0;
    else if(sft == 3'b100)  oe <= 1'b1;
    else                    oe <= 1'b0;

endmodule
