module adc_model #(
    parameter ADC_N,
    parameter ADC_W
)(
    input   logic   adc_sclk,
    input   logic   adc_css,
    output  logic   adc_dout,
    input   logic   adc_din,
    input   logic   [ADC_W-1:0]adc_data[ADC_N-1:0]
);

logic [7:0]clkp_cnt;
logic [2:0]adc_n_sft;
logic [2:0]sel_ch;
logic   [ADC_W-1:0]adc_data_rg[ADC_N-1:0];

logic [ADC_W-1:0]snd_data;
integer snt_idx;
logic sft;

initial begin    
    clkp_cnt = 0;
    sel_ch = 0;
    snt_idx = 10;
end

always @(negedge adc_css)
    if(sel_ch == 'h0)
        adc_data_rg <= adc_data;

always @(negedge adc_sclk, posedge adc_css) begin
    if(adc_css) begin
        clkp_cnt    = 'h0;
        adc_n_sft   = 'h0;
        snd_data    = 'h0;
        sft=0;
        snt_idx<=10;
    end 
    else begin
        clkp_cnt    = clkp_cnt + 1'b1;
        adc_n_sft   = {adc_n_sft[1:0], adc_din};
        
        
        if(clkp_cnt == 'h5)begin
            sel_ch <= adc_n_sft;
            snd_data <= adc_data_rg[adc_n_sft];
            adc_dout <= adc_data_rg[adc_n_sft][ADC_W-1];
            snt_idx<=10;
            sft=1;
        end
        else if(sft && (snt_idx >= 0))begin
            adc_dout <= adc_data_rg[sel_ch][snt_idx];
            snt_idx <= snt_idx-1;
        end
    end
end

endmodule
