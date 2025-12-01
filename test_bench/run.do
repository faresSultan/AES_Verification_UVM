vlib work
vlog AES_Verilog_main/*.v +cover -covercells
vlog test_bench/*.sv
vsim -voptargs=+acc work.top_level -classdebug -uvmcontrol=all -cover
add wave /top_level/in1/*
coverage save AES_tb.ucdb -onexit 
run -all
