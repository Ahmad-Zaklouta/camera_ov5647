if {![file isdirectory work]} {
  vlib -type directory work
}

vcom ../../design/camera_pkg.vhd
vcom ../../design/i2c.vhd
vcom ../../design/register_map.vhd
vcom ../../design/sensor_ctrl.vhd

vcom tb_sensor_ctrl.vhd
