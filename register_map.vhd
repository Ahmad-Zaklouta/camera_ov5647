-------------------------------------------------------------------------------
--  MIST Project - SUED Expirement - Camera Task
--  Register Map unit
-------------------------------------------------------------------------------
--  Brief description:
--
-------------------------------------------------------------------------------
--  Version/revision history:
--  <2017-03-11>, <Ahmad Zaklouta>, <Start>
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.camera_pkg.all;

entity register_map is
  port(clk              : in std_logic;
       register_map_in  : in register_map_in_type;
       register_map_out : out register_map_out_type
      );
end entity register_map;

architecture rtl of register_map is
  signal addr : integer range 0 to c_rom_size := 0;
  signal config_finished : std_logic := '0';
  -- Types & Signals Declaration
  type rom_type is array(0 to c_rom_size - 1) of unsigned(7 downto 0);
--------------------------- 

  signal rom : rom_type := (
--        addr , value ,    Name                Description
  			 x"12" , x"80" , -- COM7                Reset
				 x"12" , x"80" , -- COM7                Reset
				 x"12" , x"01" , -- COM7                Raw Bayer RGB output (8-bit R or 8-bit G or 8-bit B)
				 x"11" , x"81" , -- CLKRC               Prescaler - Fin*4/(2*(1+1))
         x"6b" , x"70" , -- DBLV                Bit[7:6]PLL Multiplier, input clock by 4
				 x"0C" , x"00" , -- COM3                Disable scaling, (PCLK, HREF/HSYNC, VSYNC, D[7:0]) Tri-stated at power-down period
				 x"3E" , x"00" , -- COM14               Normal PCLK, PCLK scaling off
         x"70" , x"3A" , -- SCALING_XSC         Bit[6:0]: Vertical scale factor, No test pattern output
         x"71" , x"35" , -- SCALING_YSC         Bit[6:0]: Horizontal scale factor, No test pattern output
         x"72" , x"00" , -- SCALING_DCWCTR      No Horizontal down sample, No Vertical down sample
         x"73" , x"F0" , -- SCALING_PCLK_DIV    Enable clock divider, Divided by 1
         x"A2" , x"02" , -- SCALING_PCLK_DELAY  Pixel Clock Delay
         x"1e" , x"00" , -- MVFP                Bit[5]HMirror/Bit[4]VFlip Enable, Normal Image
         x"17" , x"11" , -- HSTART              HREF start (high 8 bits)
				 x"18" , x"61" , -- HSTOP               HREF stop (high 8 bits)
				 x"32" , x"80" , -- HREF                Edge offset and low 3 bits of HSTART and HSTOP
				 x"19" , x"03" , -- VSTART              VSYNC start (high 8 bits)
				 x"1A" , x"7b" , -- VSTOP               VSYNC stop (high 8 bits) 
				 x"03" , x"00"   -- VREF                VSYNC low two bits
--         x"74" , x"00" , -- REG74               [6:0]: Horizontal Scaling Ratio (Conflict Discription in Datasheet)
--         x"75" , x"00" , -- REG75               [6:0]: Vertical Scaling Ratio   (Conflict Discription in Datasheet)
         );
----------------------------------------------------------------------
begin
  rom_p : process(clk)
    --variable addr : integer range 0 to c_rom_size := 0;
  begin
      --addr := register_map_in.addr;
      if rising_edge(clk) then
        if (register_map_in.next_data = '1') and (addr < c_rom_size) then
          register_map_out.data_to_slave <= rom(addr);
          addr <= addr + 1;
          config_finished <= '0';
        elsif (addr = c_rom_size) then
          addr <= 0;
          config_finished <= '1';
        end if;
      end if;
  end process rom_p;
  register_map_out.config_finished <= config_finished;
end architecture rtl;