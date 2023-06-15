import tdef_prm::*;
import tdef_pkg::*;

module slpf (
    input   clock_t             clock,
    input   logic   [2:0]       chnl,
    input   logic               we,
    input   logic   [ADC_W-1:0] di,    
    output  flt_data_t          fres
);

logic [2:0]chnl_rg;
logic [ADC_W-1:0]di_rg;
logic [EXP_FLT_W-1:0]acc_hi[ADC_N-1:0];
logic [EXP_FLT_W-1:0]acc_lo[ADC_N-1:0];
wire [2*EXP_FLT_W-1:0]acc_sm[ADC_N-1:0];
logic [EXP_FLT_W-1:0]a, b;
logic [3:0]est;

wire [2*EXP_FLT_W-1:0]prod_mul = a * b;
logic [2*EXP_FLT_W-1:0]acc;

always_comb begin    
    if(est == 4'h0) begin
        a = EXP_FLT_B;
        b = acc_lo[chnl_rg];
    end
    else if(est == 4'h1) begin
        a = EXP_FLT_B;
        b = acc_hi[chnl_rg];
    end
    else begin
        a = EXP_FLT_A;
        b = {{(EXP_FLT_W-ADC_W){1'b0}}, di_rg};
    end
end

always_ff @(posedge clock.clk)
    if(!clock.rstn) est <= 'h0;
    else            est <= {est[2:0], we};

always_ff @(posedge clock.clk)
    if(est == 'h0)
        acc <= {{{(EXP_FLT_W-1)}{1'b0}}, prod_mul>>(EXP_FLT_W-1)};
    else if((est == 4'b0001) || (est == 4'b0010))
        acc <= acc + prod_mul;

genvar i;
generate 
for(i=0;i<ADC_N;i=i+1)begin: PLF_REGS    
    
    always_ff @(posedge clock.clk) begin
        if(!clock.rstn) begin
            acc_hi[i] <= (ADC_MAX>>1);
            acc_lo[i] <= 'h0;
        end
        else if((est == 4'b0100) && (chnl_rg == i))begin
            acc_hi[i] <= acc >> (EXP_FLT_W-1);
            acc_lo[i][EXP_FLT_W-1] <= 1'b0;
            acc_lo[i][(EXP_FLT_W-2):0] <= acc[(EXP_FLT_W-2):0];
        end
    end
    assign acc_sm[i] = acc_hi[i][(EXP_FLT_W-3):0]+acc_lo[i][(EXP_FLT_W-2)];
end
endgenerate

always_ff @(posedge clock.clk)
    if(est == 4'b1000)
        //fres.data[chnl_rg] <= acc_sm[chnl_rg];
        fres.data[chnl_rg] <= $signed(ADC_H - (acc_hi[chnl_rg][(EXP_FLT_W-3):0] + acc_lo[chnl_rg][(EXP_FLT_W-2)]));

// input regs
always_ff @(posedge clock.clk)  
    if(!clock.rstn) begin 
        chnl_rg <= 'h0;
        di_rg   <= 'h0;
    end
    else if(we) begin 
        chnl_rg <= chnl;
        di_rg   <= di;
    end
    
always_ff @(posedge clock.clk)  
    if((est[3] == 1'b1) && (chnl_rg == (ADC_N-1)))
        fres.val <= 1'b1;
    else
        fres.val <= 1'b0;

endmodule
