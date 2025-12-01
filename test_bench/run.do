vlib work
vlog AES_Verilog_main/*.v
vlog test_bench/*.sv
vsim -voptargs=+acc work.top_level
run -all
