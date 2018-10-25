if {![file isdirectory work]} {
  vlib -type directory work
}

vcom ../../design/camera_pkg.vhd
vcom ../../design/i2c.vhd
vcom tb_i2c.vhd
