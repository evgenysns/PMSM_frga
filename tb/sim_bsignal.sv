`timescale 1 ns / 10 ps

module sim_bsignal #(
    parameter FNAME
)(
    output logic out
);

real fs;
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
    code = $fscanf(fp, "%d", out); cnt++;
end

always #(fs) begin 
    code = $fscanf(fp, "%d", out); cnt++; 
end

endmodule

