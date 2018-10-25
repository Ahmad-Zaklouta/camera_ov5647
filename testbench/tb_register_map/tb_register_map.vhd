-------------------------------------------------------------------------------
--  MIST Project - SUED Expirement - Camera Task
--  Testbench for register map unit
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

entity tb_register_map is
end entity tb_register_map;

Architecture tb of tb_register_map is
  
  -- Constants Declaration
  constant c_clk_half_period : time    := 20 ns;  -- Clock frequency
  constant c_clk_freq_mhz    : integer := 1000 / (2 * (c_clk_half_period / 1 ns));
  constant c_tco             : time    := 1 ns;   -- Clock to output
  
  -- Signals Declaration
  signal clk              : std_logic := '0';  -- System clock
  signal register_map_in  : register_map_in_type;
  signal register_map_out : register_map_out_type;

begin

  clk   <= not clk after c_clk_half_period;

  test_cases_p : process
  begin
    -- initialization
    register_map_in.enable <= '0';
    wait for 100 ns;
    
    for i in 0 to rom_size loop
      wait until rising_edge(clk);
      register_map_in.enable <= '1';
      wait until rising_edge(clk);
      register_map_in.enable <= '0';
      wait for 1 us;
    end loop;
    wait for 100 ns;
    wait;
  end process test_cases_p;

  -- register_map instantiation
  register_map_DUT : entity work.register_map(rtl)
    port map(clk              => clk,
             register_map_in  => register_map_in,
             register_map_out => register_map_out
             );

end architecture tb;