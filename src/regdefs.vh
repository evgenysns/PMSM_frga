`ifndef REGDEFS_H
`define REGDEFS_H

// registers address
`define DWG_BREAK_ADR       12'd01
`define DWG_STATE_ADR       12'd02
`define CURRENT_VAL_ADR     12'd04
`define SPEED_VAL_ADR       12'd05
`define DWG_SPEED_VAL_ADR   12'd06
`define CUR_D_P_ADR         12'd07
`define CUR_D_I_ADR         12'd08
`define CUR_D_D_ADR         12'd09
`define CUR_Q_P_ADR         12'd10
`define CUR_Q_I_ADR         12'd11
`define CUR_Q_D_ADR         12'd12
`define SPEED_P_ADR         12'd13
`define SPEED_I_ADR         12'd14
`define SPEED_D_ADR         12'd15
`define ADC_BIAS_GAIN_ADR   12'd16
`define ADC_BIASM1_GAIN_ADR 12'd17


// default register values
`define DEF_DWG_BREAK               1'b0
`define DEF_DWG_STATE               1'b0
`define DEF_CURRENT_VAL             16'h0
`define DEF_SPEED_VAL               16'h0
`define DEF_DWG_SPEED_VAL           16'h0

`define DEF_CUR_D_P                 16'h1
`define DEF_CUR_D_I                 16'h2
`define DEF_CUR_D_D                 16'h3
`define DEF_CUR_Q_P                 16'h4
`define DEF_CUR_Q_I                 16'h5
`define DEF_CUR_Q_D                 16'h6
`define DEF_SPEED_P                 18'h23A4 //18'h79
`define DEF_SPEED_I                 18'h156C1 //18'h491
`define DEF_SPEED_D                 18'h0

// DEF_SPEED_P = 0.27846518158912658691
// DEF_SPEED_I = 2.67776536941528320313

`define DEF_ADC_BIAS_GAIN           16'h28f
`define DEF_ADC_BIASM1_GAIN         16'hFD70

    
`endif
