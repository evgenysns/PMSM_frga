`timescale 1 ns / 10 ps

module sim_adcsignal #(
    parameter FNAME,
    parameter WIDTH,
    parameter MIN,
    parameter MAX
)(
    output logic [WIDTH-1:0]out
);

localparam integer range = MAX - MIN;
localparam integer ADC_MAX = 1 << WIDTH;
localparam integer ADC_TOP = ADC_MAX - 1'b1;
localparam real scale = $itor(ADC_MAX) / $itor(range);
localparam integer hrange = range >> 1;
/*
    
    localparam real scale = $itor((1<<WIDTH)) / $itor(range);
*/

real fs, fout;
integer fp, code;
integer cnt;

initial begin
    out = 0;
    cnt = 0;
    fp = $fopen(FNAME, "r");
    if(fp==0)begin
        $error ("Error Open File %s", FNAME);
        $stop;
    end 
    code = $fscanf(fp, "%f", fs);
    fs *= 1e8;
    
    code = $fscanf(fp, "%f", fout); 
    out = $rtoi((fout + $itor(hrange))*scale); cnt++; 
end

always #(fs) begin 
    code = $fscanf(fp, "%f", fout); 
    out = $rtoi((fout + $itor(hrange))*scale); cnt++; 
end

endmodule

