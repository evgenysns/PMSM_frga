vlog -f ./vlog.opt

vsim -voptargs="+acc" -L work work.testtb
do wave.do
run -all
wave zoom full

