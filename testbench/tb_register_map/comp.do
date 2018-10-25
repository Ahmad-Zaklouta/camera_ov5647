if {![file isdirectory work]} {
  vlib -type directory work
}

vcom ../../design/camera_pkg.vhd
vcom ../../design/register_map.vhd
vcom tb_register_map.vhd
