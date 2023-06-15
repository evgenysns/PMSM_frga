package tdef_prm;

parameter ADC_N = 2;        // phaseA, phaseB, phaseC
parameter ADC_W = 12;       // adc width bits
parameter ADC_CLK_DIV = 8'h8;  // 50e6/(2*8) = 3.125MHz
parameter ADC_ONE_TS = 552;                // 552 ns
parameter ADC_TS = ADC_ONE_TS * ADC_N;      // 552 * 2 = 1104ns (1,104ms)
// signal freq = 5-10kHz
// f3db @100kHz: a = 0,4869516630878880
parameter EXP_FLT_W = 18;
parameter EXP_FLT_TOP = (1<<EXP_FLT_W)-1;   // max flt (0x3FFFF)
parameter EXP_FLT_A = 18'h07ca8;//18'h01f2a;
parameter EXP_FLT_B = 18'h18358;//18'h3ffff - EXP_FLT_A;   // (ONE - EXP_FLT_A)

parameter CORDIC_GAIN = 18'h1FFEA;

parameter ADC_MAX = 1 << ADC_W;
parameter ADC_H = (ADC_MAX>>1);
parameter SYSRG_W = 18;
parameter M_W = 16;
parameter SYS_CLK_PERIOD = 20;          // 20e-9 @ 50MHz
parameter DELTA_INC_VAL = 16;

endpackage

package tdef_pkg;
import tdef_prm::*;

typedef struct {
    logic           [SYSRG_W-1:0]   gain_p;
    logic           [SYSRG_W-1:0]   gain_i;
    logic           [SYSRG_W-1:0]   gain_d;
    logic   signed  [SYSRG_W-1:0]   low_lim;
    logic   signed  [SYSRG_W-1:0]   up_lim;
}pid_t; 

typedef struct {
    logic signed [SYSRG_W-1:0]a;
    logic signed [SYSRG_W-1:0]b;
}dbl_s_t;
/*
typedef struct {
    logic [SYSRG_W-1:0]a;
    logic [SYSRG_W-1:0]b;
}dbl_u_t;
*/
typedef struct {
    logic                   dwg_break;
    logic                   dwg_state;

    logic [SYSRG_W-1:0]     current_val;
    logic [SYSRG_W-1:0]     speed_val;
    logic [SYSRG_W-1:0]     dwg_speed_val;
    logic [SYSRG_W-1:0]     bias_gain;
    logic [SYSRG_W-1:0]     bias_gainm1;
    logic [SYSRG_W-1:0]     rated_speed;
    pid_t                   d_curr_pid_prm;
    pid_t                   q_curr_pid_prm;
    pid_t                   speed_pid_prm;    
    //trpl_u_t                ph_time;
}sys_regs_t; 

typedef struct {
    logic   clk;        // global clock
    logic   rstn;       // n_reset
    logic   ce;         // clock enable
}clock_t; 

typedef struct {
    logic   [ADC_W-1:0]data[ADC_N-1:0];
    logic   val;        // valid
}adc_data_t; 

typedef struct {
    logic   signed [SYSRG_W-1:0]data[2:0];
    logic   val;        // valid
}ph_data_t; 

typedef struct {
    logic   signed[EXP_FLT_W-1:0]data[ADC_N-1:0];
    logic   val;        // valid
}flt_data_t; 

typedef struct {
    logic   signed[SYSRG_W-1:0]ep_sin;
    logic   signed[SYSRG_W-1:0]ep_cos;
    logic   val;
}epos_sincos_t;

endpackage

