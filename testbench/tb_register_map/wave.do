onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_register_map/clk
add wave -noupdate /tb_register_map/enable
add wave -noupdate /tb_register_map/register_map_DUT/addr
add wave -noupdate -childformat {{/tb_register_map/register_map_out.config_data -radix hexadecimal}} -expand -subitemconfig {/tb_register_map/register_map_out.config_data {-height 15 -radix hexadecimal}} /tb_register_map/register_map_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {963983 ps} 0}
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
WaveRestoreZoom {0 ps} {52500 ns}
