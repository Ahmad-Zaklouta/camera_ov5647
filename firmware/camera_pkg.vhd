library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package camera_pkg is

  -- Constant Declaration
  -- Sensor Constants
  constant c_slave_id      : unsigned(7 downto 0) := x"42"; ------------------ Common ID, bit[0]= 1 read, bit[0]= 0 write
  constant c_num_of_reg    : natural := 19; ---------------------------------- Number of register to configure
  constant reg_addr_size   : natural := 1; ----------------------------------- Size of register address in Bytes
  constant c_rom_size      : natural := (reg_addr_size + 1) * c_num_of_reg; -- ROM size (No.register * ( No.reg_addr_bytes + 1 reg_value)
  constant c_buad_rate     : natural := 100000; ------------------------------ Buad rate for I2C
  constant c_clk_freq_mhz  : natural := 125000000; --------------------------- Main clk frequency
  -- PCI constants
  constant bytes_per_pixel : natural := 3; ----------------------------------- Number of bytes per each pixel
  constant bytes_per_row   : natural := 640 * bytes_per_pixel; --------------- Number of bytes per each row
  constant rows_per_frame  : natural := 480; --------------------------------- Number of rows per each frame
  constant bytes_per_frame : natural := rows_per_frame * bytes_per_row; ------ Number of bytes per each frame
  -- Frame Ctrl Constants
  constant start_addr      : unsigned(7 downto 0) := x"01"; ------------------ Starting address in SDRAM to store first byte of first pixel
  constant read_flag_bytes : natural := 3; ----------------------------------- Number of bytes available in FIFO to start reading from it "prog_flag"
  
  signal dummy : std_logic;
  

  -- Types Declaration

  -- i2c unit
	type i2c_in_type is record
		Data_to_slave : unsigned(7 downto 0);
		rw_n          : std_logic;
		access_start  : std_logic;
	end record i2c_in_type;
	
	type i2c_out_type is record
		busy            : std_logic;
		next_data       : std_logic;
		access_done     : std_logic;
	end record i2c_out_type;

	type sensor_ctrl_in_type is record
    start_config : std_logic;
  end record sensor_ctrl_in_type;

	 type sensor_ctrl_out_type is record
    config_done     : std_logic;
    start_recording : std_logic;
    pwdn_pin        : std_logic;
  end record sensor_ctrl_out_type;

  type register_map_in_type is record
    next_data : std_logic;
  end record register_map_in_type;
  
  type register_map_out_type is record
    Data_to_slave   : unsigned(7 downto 0);
    config_finished : std_logic;
  end record register_map_out_type;
	
  type pci_in_type is record
    pclk_pin           : std_logic;
    vsync_pin          : std_logic;
    href_pin           : std_logic;
    pixel_data         : unsigned(7 downto 0);
    start_recording    : std_logic;
  end record pci_in_type;
  
  type pci_out_type is record
    data_to_fifo : unsigned(7 downto 0);
    fifo_wr_en   : std_logic;
  end record pci_out_type;
  
  type frame_ctrl_in_type is record
    data_to_fifo       : unsigned(7 downto 0);
    fifo_wr_clk        : std_logic;
    fifo_wr_en         : std_logic;
    sdram_access_grant : std_logic;
    start_recording    : std_logic;
  end record frame_ctrl_in_type;
  
  type frame_ctrl_out_type is record
    data_to_sdram      : unsigned(7 downto 0);
    addr_to_sdram      : unsigned(7 downto 0);
    sdram_access_req   : std_logic;
    frame_stored       : std_logic;
  end record frame_ctrl_out_type;
  
  type camera_top_in_type is record
    capture            : std_logic;
    sdram_access_grant : std_logic;
    pci_in             : pci_in_type;
  end record camera_top_in_type;
  
  type camera_top_out_type is record
    frame_ctrl_out : frame_ctrl_out_type;
    xclk_pin       : std_logic;
    reset_pin      : std_logic;
  end record camera_top_out_type;
  
end camera_pkg; 
