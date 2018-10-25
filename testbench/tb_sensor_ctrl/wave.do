onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_sensor_ctrl/sensor_ctrl_DUT/clk
add wave -noupdate /tb_sensor_ctrl/sensor_ctrl_DUT/reset
add wave -noupdate -expand /tb_sensor_ctrl/sensor_ctrl_DUT/sensor_ctrl_in
add wave -noupdate -expand -subitemconfig {/tb_sensor_ctrl/sensor_ctrl_DUT/sensor_ctrl_out.i2c_out -expand} /tb_sensor_ctrl/sensor_ctrl_DUT/sensor_ctrl_out
add wave -noupdate /tb_sensor_ctrl/sensor_ctrl_DUT/i2c
add wave -noupdate -expand -subitemconfig {/tb_sensor_ctrl/sensor_ctrl_DUT/reg_s.i2c_in -expand} /tb_sensor_ctrl/sensor_ctrl_DUT/reg_s
add wave -noupdate -expand /tb_sensor_ctrl/sensor_ctrl_DUT/i2c_unit/reg_s
add wave -noupdate /tb_sensor_ctrl/sensor_ctrl_DUT/i2c_out
add wave -noupdate /tb_sensor_ctrl/sensor_ctrl_DUT/register_map_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {74700 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 50
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
WaveRestoreZoom {0 ns} {266091 ns}
