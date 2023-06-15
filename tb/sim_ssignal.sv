`timescale 1 ns / 10 ps

module sim_ssignal #(
    parameter FNAME,
    parameter WIDTH,
    parameter MIN,
    parameter MAX
)(
    output logic signed [WIDTH-1:0]out
);

localparam real range = MAX - MIN;
localparam real scale = $itor(1<<WIDTH) / range;

real fs, fout, rrr;
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
    if(code !=0 )begin
        fs *= 1e8;        
        code = $fscanf(fp, "%f", fout); 
        if(code !=0 ) begin
            rrr = fout*scale;
            out = $rtoi(rrr); 
            cnt++;
        end
    end
end

always #(fs) begin 
    code = $fscanf(fp, "%f", fout); 
    if(code !=0 ) begin
        rrr = fout*scale;
        out = $rtoi(rrr); 
        cnt++;
    end
    //out = $rtoi((fout + $itor(hrange))*scale); cnt++; 
end

endmodule

