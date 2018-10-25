vsim -novopt work.tb_i2c(tb)
view wave
radix hex
do wave.do

run 1000 us
abort
