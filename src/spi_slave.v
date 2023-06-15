module spi_slave(
    // clock signals
    input           HCLK,
    input           HRESETn,
    input           SPI_SLAVE_CLK,
    input           SPI_SLAVE_CLKB,
    
    // SPI interface
    input           spi_slave_cs,
    input           spi_slave_mosi,
    output          spi_slave_miso,
    
    // SPI slave control signals
    input           spi_cpha,
    input           spi_dummy_len,  // 16/32
    
    // BUS interface
    output          spi2bus_wreq,
    output          spi2bus_rreq,
    output  reg [11:0]  spi2bus_addr,
    output  [31:0]  spi2bus_wdata,
    input   [31:0]  bus2spi_rdata
);

localparam  spi_wr_cmd          = 4'h4;
localparam  spi_wr_cmd_byte     = 4'h5;
localparam  spi_rd_cmd_single   = 4'h0;
localparam  spi_rd_cmd_multi    = 4'h2;

reg     header_phase,
        dummy_phase,
        read_phase,
        write_phase,
        cmd_mode,
        cmd_en,
        write_mode,
        write_mode_byte,
        read_mode,
        read_mode_multi,
        mem_mode,
        spi_mosi_dly,
        spi_miso_dly,
        header_phase_end_d1,
        first_word;

reg [4:0]bit_cnt;
reg [30:0]shift_in;
reg [31:0]shift_out;

wire bit_cnt15 = (bit_cnt == 5'd15);
wire bit_cnt31 = (bit_cnt == 5'd31);
wire header_phase_end = header_phase & bit_cnt15;
wire dummy_phase_end  = dummy_phase & (bit_cnt31 || (!spi_dummy_len && bit_cnt15));
wire write_phase_end  = write_phase & bit_cnt31;

always @(posedge SPI_SLAVE_CLK) spi_mosi_dly <= spi_slave_mosi;
wire spi_mosi_int = spi_cpha ? spi_slave_mosi : spi_mosi_dly;

// msg bits counter
always @(posedge SPI_SLAVE_CLKB, negedge spi_slave_cs)
    if(!spi_slave_cs)   bit_cnt <= 'h0;
    else if(header_phase_end || dummy_phase_end || write_phase_end)
                        bit_cnt <= 'h0;
    else                bit_cnt <= bit_cnt + 1'b1;

always @(posedge SPI_SLAVE_CLKB, negedge spi_slave_cs)
    if(!spi_slave_cs)   first_word <= 1'b1;
    else if(bit_cnt31)  first_word <= 1'b0;

// input shift register
always @(posedge SPI_SLAVE_CLKB, negedge spi_slave_cs)
    if(!spi_slave_cs)   shift_in <= 'h0;
    else if(header_phase || write_phase)
                        shift_in <= {shift_in[29:0], spi_mosi_int};

// output shift register
always @(posedge SPI_SLAVE_CLKB, negedge spi_slave_cs)
    if(!spi_slave_cs)   
        shift_out <= 'h0;
    else if(dummy_phase_end)
        shift_out <= {bus2spi_rdata[15:8], bus2spi_rdata[7:0],
                    bus2spi_rdata[31:24], bus2spi_rdata[23:16] };
    else if(read_phase & bit_cnt31)
        shift_out <= {bus2spi_rdata[15:8], bus2spi_rdata[7:0],
                    bus2spi_rdata[31:24], bus2spi_rdata[23:16] };
    else
        shift_out <= {shift_out[30:0], 1'b0};

wire spi_miso_pre = shift_out[31];
always @(posedge SPI_SLAVE_CLK) spi_miso_dly <= spi_miso_pre;
assign spi_slave_miso = spi_cpha ? spi_miso_dly : spi_miso_pre;

always @(posedge SPI_SLAVE_CLKB, negedge spi_slave_cs)
    if(!spi_slave_cs)           
        header_phase <= 1'b1;
    else if(header_phase_end)
        header_phase <= 1'b0;

always @(posedge SPI_SLAVE_CLKB, negedge spi_slave_cs)
    if(!spi_slave_cs)           
        mem_mode <= 1'b0;
    else if(header_phase && (bit_cnt == 5'd8) && (shift_in[3:0] == 4'h3))
        mem_mode <= 1'b1;

always @(posedge SPI_SLAVE_CLKB, negedge spi_slave_cs)
    if(!spi_slave_cs)                       dummy_phase <= 1'b0;
    else if(header_phase_end && read_mode)  dummy_phase <= 1'b1;
    else if(dummy_phase_end)                dummy_phase <= 1'b0;

always @(posedge SPI_SLAVE_CLKB, negedge spi_slave_cs)
    if(!spi_slave_cs)           read_phase <= 1'b0;
    else if(dummy_phase_end)    read_phase <= 1'b1;

always @(posedge SPI_SLAVE_CLKB, negedge spi_slave_cs)
    if(!spi_slave_cs)                       write_phase <= 1'b0;
    else if(header_phase_end && write_mode) write_phase <= 1'b1;

always @(posedge SPI_SLAVE_CLK, negedge spi_slave_cs)
    if(!spi_slave_cs)
        header_phase_end_d1 <= 1'b0;
    else
        header_phase_end_d1 <= header_phase_end;

// operation modes selection
wire mode_sel           = header_phase && (bit_cnt == 5'd4);
wire rd_cmd_single      = (shift_in[3:0] == spi_rd_cmd_single);
wire rd_cmd_multi       = (shift_in[3:0] == spi_rd_cmd_multi);
wire wr_cmd             = (shift_in[3:0] == spi_wr_cmd);
wire wr_cmd_byte        = (shift_in[3:0] == spi_wr_cmd_byte);

always @(posedge SPI_SLAVE_CLKB, negedge spi_slave_cs)
    if(!spi_slave_cs)   
        read_mode <= 1'b0;
    else if(mode_sel && (rd_cmd_single || rd_cmd_multi))
        read_mode <= 1'b1;
        
always @(posedge SPI_SLAVE_CLKB, negedge spi_slave_cs)
    if(!spi_slave_cs)   
        read_mode_multi <= 1'b0;
    else if(mode_sel && rd_cmd_multi)
        read_mode_multi <= 1'b1;

always @(posedge SPI_SLAVE_CLKB, negedge spi_slave_cs)
    if(!spi_slave_cs)   
        write_mode <= 1'b0;
    else if(mode_sel && wr_cmd)
        write_mode <= 1'b1;
        
always @(posedge SPI_SLAVE_CLKB, negedge spi_slave_cs)
    if(!spi_slave_cs)   
        write_mode_byte <= 1'b0;
    else if(mode_sel && wr_cmd_byte)
        write_mode_byte <= 1'b1;

wire inc_waddr = write_phase && !first_word && (bit_cnt == 5'd30);
wire inc_raddr = read_phase && (bit_cnt == 5'd2);

always @(posedge SPI_SLAVE_CLKB)
    if(header_phase_end)    spi2bus_addr <= {shift_in[10:0], spi_mosi_int};
    else if(!mem_mode && (inc_waddr || (inc_raddr && read_mode_multi)))
                            spi2bus_addr <= spi2bus_addr + 1'b1;

reg spi_wreq_pre,
    spi_wreq_pre_d1,
    spi_wreq_pre_d2,
    spi_wreq_pre_d3,
    spi_rreq_pre,
    spi_rreq_pre_d1,
    spi_rreq_pre_d2,
    spi_rreq_pre_d3,
    spi_rreq_pre_d4;
    
always @(posedge SPI_SLAVE_CLKB, negedge spi_slave_cs)
    if(!spi_slave_cs)
        spi_wreq_pre <= 1'b0;
    else if(write_mode && bit_cnt31)
        spi_wreq_pre <= 1'b1;
    else if(write_mode_byte && write_phase && (bit_cnt == 5'd7))
        spi_wreq_pre <= 1'b1;
    else if(bit_cnt == 5'd3)
        spi_wreq_pre <= 1'b0;
        
reg [31:0]spi2bus_wdata_tmp;
always @(posedge SPI_SLAVE_CLKB)
    if(write_mode && bit_cnt31)
        spi2bus_wdata_tmp <= {shift_in[30:0], spi_mosi_int};
    else if(write_mode_byte && (bit_cnt == 5'd7))
        spi2bus_wdata_tmp <= {shift_in[6:0], spi_mosi_int, 24'h0};
        
assign spi2bus_wdata = spi2bus_wdata_tmp;
        
always @(posedge SPI_SLAVE_CLKB, negedge spi_slave_cs)
    if(!spi_slave_cs)
        spi_rreq_pre <= 1'b0;
    else if(read_mode && header_phase_end)
        spi_rreq_pre <= 1'b1;
    else if(read_phase && (bit_cnt ==5'd2))
        spi_rreq_pre <= 1'b1;
    else if(bit_cnt == 5'd4)
        spi_rreq_pre <= 1'b0;

//Sync to HCLK
always @(posedge HCLK, negedge HRESETn)
    if(!HRESETn) begin
        spi_wreq_pre_d1 <= 1'b0;
        spi_wreq_pre_d2 <= 1'b0;
        spi_wreq_pre_d3 <= 1'b0;
        
        spi_rreq_pre_d1 <= 1'b0;
        spi_rreq_pre_d2 <= 1'b0;
        spi_rreq_pre_d3 <= 1'b0;
        spi_rreq_pre_d4 <= 1'b0;        
    end
    else begin
        spi_wreq_pre_d1 <= spi_wreq_pre;
        spi_wreq_pre_d2 <= spi_wreq_pre_d1;
        spi_wreq_pre_d3 <= spi_wreq_pre_d2;
        
        spi_rreq_pre_d1 <= spi_rreq_pre;
        spi_rreq_pre_d2 <= spi_rreq_pre_d1;
        spi_rreq_pre_d3 <= spi_rreq_pre_d2;
        spi_rreq_pre_d4 <= spi_rreq_pre_d3;
    end

assign spi2bus_wreq = spi_wreq_pre_d2 && !spi_wreq_pre_d3;
assign spi2bus_rreq = spi_rreq_pre_d3 && !spi_rreq_pre_d4;

endmodule
