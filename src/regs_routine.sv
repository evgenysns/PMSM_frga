`include "regdefs.vh"

import tdef_prm::*;
import tdef_pkg::*;

module regs_routine (
    input   clock_t     clock,
    input               spi2bus_wreq,
    input               spi2bus_rreq,
    input       [11:0]  spi2bus_addr,
    input       [15:0]  spi2bus_wdata,
    output  reg [15:0]  bus2spi_rdata,
    output  sys_regs_t  regs
);

// write registers
always_ff @(posedge clock.clk)
    if(!clock.rstn)begin
        regs.dwg_break              <= `DEF_DWG_BREAK;
        regs.dwg_state              <= `DEF_DWG_STATE;    
        regs.current_val            <= `DEF_CURRENT_VAL;
        regs.speed_val              <= `DEF_SPEED_VAL;    
        regs.dwg_speed_val          <= `DEF_DWG_SPEED_VAL;
        regs.d_curr_pid_prm.gain_p  <= `DEF_CUR_D_P;
        regs.d_curr_pid_prm.gain_i  <= `DEF_CUR_D_I;
        regs.d_curr_pid_prm.gain_d  <= `DEF_CUR_D_D;
        regs.q_curr_pid_prm.gain_p  <= `DEF_CUR_Q_P;
        regs.q_curr_pid_prm.gain_i  <= `DEF_CUR_Q_I;
        regs.q_curr_pid_prm.gain_d  <= `DEF_CUR_Q_D;
        regs.speed_pid_prm.gain_p   <= `DEF_SPEED_P;
        regs.speed_pid_prm.gain_i   <= `DEF_SPEED_I;
        regs.speed_pid_prm.gain_d   <= `DEF_SPEED_D;
        regs.bias_gain              <= `DEF_ADC_BIAS_GAIN;
        regs.bias_gainm1            <= `DEF_ADC_BIASM1_GAIN;        
    end
    else if(spi2bus_wreq) begin
        case(spi2bus_addr)
        `DWG_BREAK_ADR      :    regs.dwg_break             <= spi2bus_wdata[0];
        `DWG_STATE_ADR      :    regs.dwg_state             <= spi2bus_wdata[0];
        `CURRENT_VAL_ADR    :    regs.current_val           <= spi2bus_wdata;
        `SPEED_VAL_ADR      :    regs.speed_val             <= spi2bus_wdata;
        `DWG_SPEED_VAL_ADR  :    regs.dwg_speed_val         <= spi2bus_wdata;
        `CUR_D_P_ADR        :    regs.d_curr_pid_prm.gain_p <= spi2bus_wdata;
        `CUR_D_I_ADR        :    regs.d_curr_pid_prm.gain_i <= spi2bus_wdata;        
        `CUR_D_D_ADR        :    regs.d_curr_pid_prm.gain_d <= spi2bus_wdata;
        `CUR_Q_P_ADR        :    regs.q_curr_pid_prm.gain_p <= spi2bus_wdata;
        `CUR_Q_I_ADR        :    regs.q_curr_pid_prm.gain_i <= spi2bus_wdata;
        `CUR_Q_D_ADR        :    regs.q_curr_pid_prm.gain_d <= spi2bus_wdata;
        `SPEED_P_ADR        :    regs.speed_pid_prm.gain_p  <= spi2bus_wdata;
        `SPEED_I_ADR        :    regs.speed_pid_prm.gain_i  <= spi2bus_wdata;
        `SPEED_D_ADR        :    regs.speed_pid_prm.gain_d  <= spi2bus_wdata;
        `ADC_BIAS_GAIN_ADR  :    regs.bias_gain             <= spi2bus_wdata;
        `ADC_BIASM1_GAIN_ADR:    regs.bias_gainm1           <= spi2bus_wdata;
        endcase
    end

// read registers
always_ff @(posedge clock.clk)
    case(spi2bus_addr)
    `DWG_BREAK_ADR      :    bus2spi_rdata <= {15'h0, regs.dwg_break};
    `DWG_STATE_ADR      :    bus2spi_rdata <= {15'h0, regs.dwg_state};
    `CURRENT_VAL_ADR    :    bus2spi_rdata <= regs.current_val;
    `SPEED_VAL_ADR      :    bus2spi_rdata <= regs.speed_val;
    `DWG_SPEED_VAL_ADR  :    bus2spi_rdata <= regs.dwg_speed_val;
    `CUR_D_P_ADR        :    bus2spi_rdata <= regs.d_curr_pid_prm.gain_p;
    `CUR_D_I_ADR        :    bus2spi_rdata <= regs.d_curr_pid_prm.gain_i;        
    `CUR_D_D_ADR        :    bus2spi_rdata <= regs.d_curr_pid_prm.gain_d;        
    `CUR_Q_P_ADR        :    bus2spi_rdata <= regs.q_curr_pid_prm.gain_p;
    `CUR_Q_I_ADR        :    bus2spi_rdata <= regs.q_curr_pid_prm.gain_i;
    `CUR_Q_D_ADR        :    bus2spi_rdata <= regs.q_curr_pid_prm.gain_d;
    `SPEED_P_ADR        :    bus2spi_rdata <= regs.speed_pid_prm.gain_p; 
    `SPEED_I_ADR        :    bus2spi_rdata <= regs.speed_pid_prm.gain_i; 
    `SPEED_D_ADR        :    bus2spi_rdata <= regs.speed_pid_prm.gain_d; 
    `ADC_BIAS_GAIN_ADR  :    bus2spi_rdata <= regs.bias_gain;
    `ADC_BIASM1_GAIN_ADR:    bus2spi_rdata <= regs.bias_gainm1;
    endcase

endmodule
