onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -group TEST_TB -radix hexadecimal {sim:/testtb/*}
#add wave -group SIGNALS -radix hexadecimal {sim:/testtb/sim_signals/*}
add wave -group SPEED_CMD -radix hexadecimal {sim:/testtb/sim_signals/velocity_cmd/*}
add wave -group SPEED_SNS -radix hexadecimal {sim:/testtb/sim_signals/velocity_sns/*}

add wave -group ADC_MODEL_TB -radix hexadecimal {sim:/testtb/adc_model_tb/*}
add wave -group SYS_TOP -radix hexadecimal {sim:/testtb/sys_ctrl_dut/*}
add wave -group MAIN_FSM -radix hexadecimal {sim:/testtb/sys_ctrl_dut/main_fsm_u/*}
add wave -group CURRENT_LOOP -radix hexadecimal {sim:/testtb/sys_ctrl_dut/current_loop/*}
add wave -group SPEED_LOOP -radix hexadecimal {sim:/testtb/sys_ctrl_dut/speed_loop_ctrl/*}



#add wave -group ADC_CTRL -radix hexadecimal {sim:/testtb/sys_ctrl_dut/adc_ctrl_u/*}
#add wave -group LPF -radix hexadecimal {sim:/testtb/sys_ctrl_dut/adc_ctrl_u/slpf_u/*}
#add wave -position insertpoint /testtb/sys_ctrl_dut/adc_ctrl_u/slpf_u/acc_hi
#add wave -position insertpoint /testtb/sys_ctrl_dut/adc_ctrl_u/slpf_u/acc_lo
#add wave -position insertpoint /testtb/sys_ctrl_dut/adc_ctrl_u/slpf_u/acc_sm
#add wave -group ADC_128S_CTRL -radix hexadecimal {sim:/testtb/sys_ctrl_dut/adc_ctrl_u/adc128s022_u/*}
#add wave -group HALL_0 -radix hexadecimal {sim:/testtb/sim_signals/hall_0/*}
#add wave -group ABC_0 -radix hexadecimal {sim:/testtb/sim_signals/abc_voltage_0/*}



TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {15062810 ps} 0}
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
