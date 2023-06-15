module adc128s022(
    input               clk,
    input               rstn,
    input       [2:0]   channel,
    output  reg [11:0]  data,    
    input               wr,
    output  reg         rdy,
    input       [7:0]   clk_div,
    
    output reg          adc_sclk,
    output reg          adc_css,
    input               adc_dout,
    output reg          adc_din
);

reg [2:0]chnl_rg;
reg [11:0]r_data;

reg [7:0]div_cnt;
reg sclk2x;

reg [5:0]sclk_cnt;    
reg en;    

always@(posedge clk)
    if(!rstn)     chnl_rg <= 3'd0;
    else if(wr) chnl_rg <= channel;

always@(posedge clk)
    if(!rstn)     en <= 1'b0;
    else if(wr) en <= 1'b1;
    else if(rdy)en <= 1'b0;

wire div_cmp = (div_cnt == (clk_div - 1'b1));
always@(posedge clk)
    if(en)  div_cnt  <= (div_cmp)?'h0:(div_cnt + 1'b1);
    else    div_cnt  <= 'h0;

always@(posedge clk)
    if(!rstn)                 sclk2x  <= 1'b0;
    else if(en && div_cmp)  sclk2x  <= 1'b1;
    else                    sclk2x  <= 1'b0;
    
wire sclk_cmp = (sclk_cnt == 6'd33);
always@(posedge clk)
    if(!en)         sclk_cnt  <= 'h0;
    else if(sclk2x) sclk_cnt  <= (sclk_cmp)?'h0:(sclk_cnt + 1'b1);
    
always@(posedge clk)
if(!rstn)begin
    adc_sclk    <= 1'b1;
    adc_css     <= 1'b1;
    adc_din     <= 1'b1;
end else if(en) begin
    if(sclk2x)begin
        case(sclk_cnt)
            6'd0:begin adc_css <= 1'b0; end
            6'd1:begin adc_sclk <= 1'b0; adc_din  <= 1'b0; end
            6'd2:begin adc_sclk <= 1'b1; end
            6'd3:begin adc_sclk <= 1'b0; end
            6'd4:begin adc_sclk <= 1'b1; end
            6'd5:begin adc_sclk <= 1'b0; adc_din  <= chnl_rg[2];end    //addr[2]
            6'd6:begin adc_sclk <= 1'b1; end
            6'd7:begin adc_sclk <= 1'b0; adc_din  <= chnl_rg[1];end    //addr[1]
            6'd8:begin adc_sclk <= 1'b1; end
            6'd9:begin adc_sclk <= 1'b0; adc_din  <= chnl_rg[0];end    //addr[0]

            6'd10,6'd12,6'd14,6'd16,6'd18,6'd20,6'd22,6'd24,6'd26,6'd28,6'd30,6'd32:
                begin adc_sclk <= 1'b1; r_data <= {r_data[10:0], adc_dout};  adc_din<=adc_din; end    //循环移位寄存DOUT上的12个数据
            
            6'd11,6'd13,6'd15,6'd17,6'd19,6'd21,6'd23,6'd25,6'd27,6'd29,6'd31:
                begin adc_sclk <= 1'b0; adc_din<=1'b0; end
            
            6'd33:begin adc_css <= 1'b1; end
            default:begin adc_css <= 1'b1; end
        endcase
    end
    else ;
end else begin
    adc_css <= 1'b1;
end

always@(posedge clk)
    if(!rstn)
        rdy     <= 1'b0;
    else if(en && sclk2x && sclk_cmp && !rdy)begin
        data    <= r_data; 
        rdy     <= 1'b1;
    end 
    else
        rdy     <= 1'b0;

endmodule
