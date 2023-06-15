import tdef_prm::*;
import tdef_pkg::*;

module ctrl_loop #(
    parameter WIDTH
)(
    input           clock_t         clock,
    input                           we,
    input           [WIDTH-1:0]     set_in,
    input           [WIDTH-1:0]     sys_in,
    input           pid_t           pid_prm,
    output  logic                   oe,
    output  logic   [WIDTH-1:0]     out
);

enum logic[1:0]{F_IDLE, F_MULT, F_ADD, F_ADJ} fsm, nfsm;

logic [1:0]     calc_cnt;
logic  signed[SYSRG_W:0]    pid_err, pid_err_l, pid_err_p;
logic [SYSRG_W-1:0] pa;
logic [SYSRG_W+2:0] pb;
wire[SYSRG_W*2+2:0] prod = pa * pb;

always_ff @(posedge clock.clk)
    if(!clock.rstn) fsm <= F_IDLE;
    else            fsm <= nfsm;
    
always_comb begin
    case (fsm)
        F_IDLE: if (we)                 nfsm <= F_MULT;
                else                    nfsm <= fsm;
        F_MULT: if (calc_cnt == 'd3)    nfsm <= F_ADD;
                else                    nfsm <= fsm;
        F_ADD:  if (calc_cnt == 'd2)    nfsm <= F_ADJ;
                else                    nfsm <= fsm;
        F_ADJ:                          nfsm <= F_IDLE;
        default :                       nfsm <= F_IDLE;
    endcase
    end

always_ff @(posedge clock.clk)
    if(!clock.rstn)                         calc_cnt <= 'h0;
    else if ((fsm == F_IDLE) && we)         calc_cnt <= 'h0;
    else if (fsm == F_MULT || fsm == F_ADD) calc_cnt <= calc_cnt + 1'b1;
    //else                                    calc_cnt <= 'h0;

always_ff @(posedge clock.clk)
    if (fsm == F_IDLE && we)
        pid_err <= set_in - sys_in;

always @(*)begin
    if (fsm == F_MULT)
        case (calc_cnt)
            'h0:        pa = pid_prm.gain_p;
            'd1:        pa = pid_prm.gain_i;
            'd2:        pa = pid_prm.gain_d;
            default:    pa = 'h0;
        endcase 
	else pa = 'h0;
end

always @(*)begin
    if (fsm == F_MULT)
        case (calc_cnt)
            'h0:    pb = pid_err - pid_err_l;
            'h1:    pb = pid_err;
            'h2:    pb = (pid_err - pid_err_l) + (-pid_err_l - pid_err_p);
            default:pb = 'h0;
        endcase
	else pb = 'h0;
end

logic signed[SYSRG_W*2+4:0]   pid_acc;
always_ff @(posedge clock.clk)
    if(!clock.rstn) 
        pid_acc <= 'h0;
    else if (fsm == F_ADD || fsm == F_MULT)
        pid_acc <= pid_acc + {{2{prod[SYSRG_W * 2 + 2]}}, prod>>2};
    else
        pid_acc <= 'h0;

wire signed[SYSRG_W*2+5:0]pid_val = {pid_acc[SYSRG_W * 2 + 4], pid_acc} + {{7{out[SYSRG_W - 1]}}, out,15'h0};
always_ff @(posedge clock.clk)
    if(!clock.rstn)
        out <= 'h0;
    else if (fsm == F_ADJ) begin        
        if (pid_val[(SYSRG_W * 2 + 5) -: 8] != 8'h0 && pid_val[(SYSRG_W * 2 + 5) -: 8] != 8'hff)
            out <= {pid_val[SYSRG_W * 2 + 5], {(SYSRG_W - 1){~pid_val[SYSRG_W * 2 + 5]}}};
        else
            out <= {pid_val[SYSRG_W * 2 + 5], pid_val[(SYSRG_W * 2 - 3) -: (SYSRG_W - 1)]};
    end

always_ff @(posedge clock.clk)
    if(!clock.rstn)         oe <= 1'b0;
    else if (fsm == F_ADJ)  oe <= 1'b1;
    else                    oe <= 1'b0;

always_ff @(posedge clock.clk)
    if(!clock.rstn)         {pid_err_l, pid_err_p} <= 'h0;
    else if (fsm == F_ADJ)  {pid_err_l, pid_err_p} <= {pid_err, pid_err_l};
    
endmodule  
