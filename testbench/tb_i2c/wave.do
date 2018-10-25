onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_i2c/clk
add wave -noupdate /tb_i2c/reset
add wave -noupdate /tb_i2c/i2c_in
add wave -noupdate /tb_i2c/i2c_out
add wave -noupdate /tb_i2c/data_from_slave
add wave -noupdate /tb_i2c/rr
add wave -noupdate /tb_i2c/ack
add wave -noupdate /tb_i2c/i2c_scl
add wave -noupdate /tb_i2c/i2c_sda
add wave -noupdate /tb_i2c/i2c_DUT/reg_s.scl_en
add wave -noupdate /tb_i2c/i2c_DUT/reg_s.transmitting
add wave -noupdate -childformat {{/tb_i2c/i2c_DUT/reg_s.divisor_cnt -radix decimal}} -expand -subitemconfig {/tb_i2c/i2c_DUT/reg_s.divisor_cnt {-radix decimal}} /tb_i2c/i2c_DUT/reg_s
add wave -noupdate /tb_i2c/i2c_DUT/reg_s.transmitting
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {50530 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
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
WaveRestoreZoom {34114 ns} {66946 ns}
