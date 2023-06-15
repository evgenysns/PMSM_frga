onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -group TEST_TB -radix hexadecimal {sim:/testtb_svpwm/*}
add wave -group ABC_0 -radix hexadecimal {sim:/testtb_svpwm/svmod/*}

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
