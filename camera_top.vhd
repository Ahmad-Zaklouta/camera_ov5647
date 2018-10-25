-------------------------------------------------------------------------------
--  MIST Project - SUED Expirement - Camera Task
--  camera_top
-------------------------------------------------------------------------------
--  Brief description:
--  Top design for MIST camera
-------------------------------------------------------------------------------
--  Version/revision history:
--  <2017-06-19>, <Ahmad Zaklouta>, <Start>
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.camera_pkg.all;

entity camera_top is
  port(clk            : in std_logic;
       reset          : in std_logic;
       camera_top_in  : in camera_top_in_type;
       camera_top_out : out camera_top_out_type;
       i2c_sda        : inout std_logic;
       i2c_scl        : out std_logic
      );
end entity camera_top;

architecture rtl of camera_top is

  -- Interconnect Signals Declaration
  -- sensor_ctrl unit signals
  signal sensor_ctrl_in  : sensor_ctrl_in_type;
  signal sensor_ctrl_out : sensor_ctrl_out_type;
  -- pci unit signals 
  signal pci_in          : pci_in_type;
  signal pci_out         : pci_out_type;
  -- frame_ctrl unit signals  
  signal frame_ctrl_in   : frame_ctrl_in_type;
  signal frame_ctrl_out  : frame_ctrl_out_type;

begin


  -- Components Instantiation and Mapping
  
  -- Mapping for sensor_ctrl_in port
  sensor_ctrl_in.start_config <= camera_top_in.capture;
  -- sensor_ctrl Instantiation
  sensor_ctrl_u : entity work.sensor_ctrl(rtl)
    port map(clk             => clk,
             reset           => reset,
             sensor_ctrl_in  => sensor_ctrl_in,
             sensor_ctrl_out => sensor_ctrl_out,
             i2c_sda         => i2c_sda,
             i2c_scl         => i2c_scl
            );

  -- Mapping for pci_in port
  pci_in.pclk_pin        <= camera_top_in.pci_in.pclk_pin;
  pci_in.vsync_pin       <= camera_top_in.pci_in.vsync_pin;
  pci_in.href_pin        <= camera_top_in.pci_in.href_pin;
  pci_in.pixel_data      <= camera_top_in.pci_in.pixel_data;
  pci_in.start_recording <= sensor_ctrl_out.start_recording;
  
  -- pci Instantiation
  pci_u : entity work.pci(rtl)
    port map(reset   => reset,
             pci_in  => pci_in,
             pci_out => pci_out
            );    
  
  -- Mapping for frame_ctrl_in port
  frame_ctrl_in.data_to_fifo       <= pci_out.data_to_fifo;
  frame_ctrl_in.fifo_wr_en         <= pci_out.fifo_wr_en;
  frame_ctrl_in.fifo_wr_clk        <= camera_top_in.pci_in.pclk_pin;
  frame_ctrl_in.sdram_access_grant <= camera_top_in.sdram_access_grant;
  frame_ctrl_in.start_recording    <= sensor_ctrl_out.start_recording;
  
  -- frame_ctrl Instantiation
  frame_ctrl_u : entity work.frame_ctrl(rtl)
    port map(clk            => clk,
             reset          => reset,
             frame_ctrl_in  => frame_ctrl_in,
             frame_ctrl_out => frame_ctrl_out
            );
            
  -- Mapping for camera_top_out port
  camera_top_out.frame_ctrl_out.data_to_sdram    <= frame_ctrl_out.data_to_sdram;
  camera_top_out.frame_ctrl_out.addr_to_sdram    <= frame_ctrl_out.addr_to_sdram;
  camera_top_out.frame_ctrl_out.sdram_access_req <= frame_ctrl_out.sdram_access_req;
  camera_top_out.frame_ctrl_out.frame_stored     <= frame_ctrl_out.frame_stored;
  camera_top_out.xclk_pin                        <= clk;     -- from pll
  camera_top_out.reset_pin                       <= '1'; -- Normal mode
            
end architecture rtl;