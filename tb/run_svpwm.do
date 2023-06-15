vlog -f ./vlog_svpwm.opt

vsim -voptargs="+acc" -L work work.testtb_svpwm
do wave_svpwm.do
run -all
wave zoom full

