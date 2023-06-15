import tdef_prm::*;
import tdef_pkg::*;

module main_fsm(
    input   clock_t     clock,
    input   sys_regs_t  regs,
    
    input               init_done,    
    output logic        current_loop_stb,
    output              speed_loop_stb,
    output logic        emergency_stop_stb,
    output logic        sns_ce,
    
    input               chnla_err,
    input               chnlb_err,
    input               gate_error
);

// sys time constants
localparam TMR_1US_TOP = 1_000 / SYS_CLK_PERIOD;
localparam TMR_1US_TOP_W = $clog2(TMR_1US_TOP);
localparam TMR_400US_TOP_W = $clog2(400);
localparam TMR_1MS_TOP_W = $clog2(1_000);

reg[TMR_1US_TOP_W-1:0]cnt_1us;
reg[TMR_400US_TOP_W-1:0]cnt_400us;
reg[TMR_1MS_TOP_W-1:0]cnt_1ms;
wire tmr_1us_cmp   = (cnt_1us == (TMR_1US_TOP - 1'b1));
wire tmr_400us_cmp = (cnt_400us == 'd399);
wire tmr_1ms_cmp   = (cnt_1ms == 'd999);


/*
localparam TMR_1MS_TOP = 1_000_000 / SYS_CLK_PERIOD;
localparam TMR_1MS_TOP_W = $clog2(TMR_1MS_TOP);
localparam TMR_10MS_TOP_W = $clog2(10);
localparam TMR_100MS_TOP_W = $clog2(100);

reg[TMR_1MS_TOP_W-1:0]cnt_1ms;
reg[TMR_10MS_TOP_W-1:0]cnt_10ms;
reg[TMR_100MS_TOP_W-1:0]cnt_100ms;

wire tmr_1ms_cmp   = (cnt_1ms == (TMR_1MS_TOP - 1'b1));
wire tmr_10ms_cmp  = (cnt_10ms == 'd9);
//wire tmr_100ms_cmp = (cnt_100ms == 'd99);
wire tmr_100ms_cmp = (cnt_100ms == 'd9);
*/
enum logic[2:0]{
    F_IDLE,
    F_INIT,
    F_WAIT,
    F_MOTOR_RUN,
    F_EXCEPTION} fsm, nfsm;
    
//==============================================================================
// main fsm
always_ff @(posedge clock.clk)
    if(!clock.rstn) fsm <= F_IDLE;
    else            fsm <= nfsm;
    
always_comb begin
case (fsm)
    F_IDLE          :
                    if(tmr_1us_cmp)// && tmr_100ms_cmp)
                        nfsm <= F_INIT;
                    else
                        nfsm <= fsm;
    F_INIT          :
                    if(init_done)
                        nfsm <= F_WAIT;
                    else
                        nfsm <= fsm;
    F_WAIT      :
                    if((regs.dwg_break == 1'b0) && (regs.dwg_state == 1'b1))
                        nfsm <= F_MOTOR_RUN;
                    else
                        nfsm <= fsm;
    F_MOTOR_RUN  :  
                    if(regs.dwg_state == 1'b0)
                        nfsm <= F_WAIT;
                    else if(chnla_err || chnlb_err || gate_error)
                        nfsm <= F_EXCEPTION;
                    else
                        nfsm <= fsm;
    F_EXCEPTION   :
                    if(regs.dwg_state == 1'b0)
                        nfsm <= F_WAIT;
                    else if(~gate_error)
                        nfsm <= F_MOTOR_RUN;
                    else
                        nfsm <= fsm;
    default         :   nfsm <= F_IDLE;
endcase
end

//==============================================================================
// System timers
// 1us timer
always_ff @(posedge clock.clk)
    if(!clock.rstn)     cnt_1us <= 'h0;
    else if(fsm != nfsm)cnt_1us <= 'h0;
    else if(!((fsm == F_INIT) || (fsm == F_WAIT)))begin
        if(tmr_1us_cmp) cnt_1us <= 'h0;
        else            cnt_1us <= cnt_1us + 1'b1;
    end
    else                cnt_1us <= 'h0;
    
// 400us timer
always_ff @(posedge clock.clk)
    if(!clock.rstn)     cnt_400us <= 'h0;
    else if(fsm == F_MOTOR_RUN)begin
        if(tmr_400us_cmp && tmr_1us_cmp)
                        cnt_400us <= 'h0;
        else if(tmr_1us_cmp)
                        cnt_400us <= cnt_400us + 1'b1;
    end
    else                cnt_400us <= 'h0;
    
// 1ms timer
always_ff @(posedge clock.clk)
    if(!clock.rstn)     cnt_1ms <= 'h0;
    else if(fsm == F_MOTOR_RUN)begin
        if(tmr_1ms_cmp && tmr_1us_cmp)
                        cnt_1ms <= 'h0;
        else if(tmr_1us_cmp)
                        cnt_1ms <= cnt_1ms + 1'b1;
    end
    else                cnt_1ms <= 'h0;
    
//==============================================================================
logic current_loop_p;
always_ff @(posedge clock.clk)
    if(!clock.rstn)
        current_loop_p <= 'd0;
    else if ((fsm == F_EXCEPTION || fsm == F_MOTOR_RUN) && tmr_400us_cmp)
        current_loop_p <= 'd1;
    else
        current_loop_p <= 'd0;
        
assign current_loop_stb = ((fsm == F_EXCEPTION || fsm == F_MOTOR_RUN) && tmr_400us_cmp) & !current_loop_p;
//==============================================================================
always_ff @(posedge clock.clk)
    if(!clock.rstn)
        emergency_stop_stb <= 'd0;
    else if (fsm == F_EXCEPTION)
        emergency_stop_stb <= 'd1;
    else
        emergency_stop_stb <= 'd0;
    
//==============================================================================
logic speed_loop_p;
always_ff @(posedge clock.clk)
    if(!clock.rstn)
        speed_loop_p <= 1'b0;
    //else if ((fsm == F_MOTOR_RUN) && ((cnt_10ms == 'd4) && tmr_1ms_cmp))
    else if ((fsm == F_MOTOR_RUN) && tmr_1ms_cmp)
        speed_loop_p <= 1'b1;
    else
        speed_loop_p <= 1'b0;
        
assign speed_loop_stb = ((fsm == F_MOTOR_RUN) && tmr_1ms_cmp) & !speed_loop_p;
//==============================================================================
always_ff @(posedge clock.clk)
    if(!clock.rstn)
        sns_ce <= 1'b0;
    else if(fsm == F_EXCEPTION || fsm == F_MOTOR_RUN)
        sns_ce <= 1'b1;
    else
        sns_ce <= 1'b0;

endmodule
