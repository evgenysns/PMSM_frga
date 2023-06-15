import tdef_prm::*;
import tdef_pkg::*;

module svmod(
    input           clock_t         clock,
    input           ph_data_t       voltage,
    output          ph_data_t       out
);

wire signed [SYSRG_W-1:0]top_lim = (voltage.data[0] < voltage.data[1]?
                        (voltage.data[0]<voltage.data[2]?voltage.data[0]:voltage.data[2])
                       :(voltage.data[1]<voltage.data[2]?voltage.data[1]:voltage.data[2]));

wire signed [SYSRG_W-1:0]low_lim = (voltage.data[0] > voltage.data[1]?
                        (voltage.data[0]>voltage.data[2]?voltage.data[0]:voltage.data[2])
                       :(voltage.data[1]>voltage.data[2]?voltage.data[1]:voltage.data[2]));

logic signed [SYSRG_W-1:0]low_lim_rg, top_lim_rg;
logic [2:0]sft;
always_ff @(posedge clock.clk)
    if(!clock.rstn) sft <= 'h0;
    else            sft <= {sft[1:0], voltage.val};
    
always_ff @(posedge clock.clk)
    if(!clock.rstn) begin
        low_lim_rg <= 'h0;
        top_lim_rg <= 'h0;
    end
    else if(voltage.val)begin
        low_lim_rg <= low_lim;
        top_lim_rg <= top_lim;
    end

wire signed [SYSRG_W-1:0]mid = (top_lim + low_lim) >>> 1;
logic signed [SYSRG_W-1:0]mid_rg;

always_ff @(posedge clock.clk)
    if(!clock.rstn)     mid_rg <= 'h0;
    else if(sft[0])     mid_rg <= mid;

genvar i;
generate 
for(i=0;i<3;i++)begin:SVM_LOOP
always_ff @(posedge clock.clk)
    if(!clock.rstn)     out.data[i] <= 'h0;
    else if(sft[1])     out.data[i] <= (voltage.data[i] - mid_rg)>>>1;
end
endgenerate

always_ff @(posedge clock.clk)
    if(!clock.rstn)     out.val <= 1'b0;
    else if(sft[2])     out.val <= 1'b1;
    else                out.val <= 1'b0;
    
endmodule
