-------------------------------------------------------------------------------
--  MIST Project - SUED Expirement - Camera Task
--  Testbench for i2c unit
-------------------------------------------------------------------------------
--  Brief description:
--
-------------------------------------------------------------------------------
--  Version/revision history:
--  <2017-03-05>, <Ahmad Zaklouta>, <Start>
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.camera_pkg.all;

entity tb_i2c is
end entity tb_i2c;

Architecture tb of tb_i2c is
  
  -- Constants Declaration
  constant c_clk_half_period : time    := 32 ns;  -- Clock frequency
  constant c_clk_freq_mhz    : integer := 1000 / (2 * (c_clk_half_period / 1 ns));
  constant c_tco             : time    := 1 ns;   -- Clock to output
  
  -- Signals Declaration
  signal clk     : std_logic := '0';  -- System clock
  signal reset   : std_logic := '1';  -- System reset 
  signal i2c_in  : i2c_in_type;
  signal i2c_out : i2c_out_type;
  signal data_from_slave : unsigned(7 downto 0) := x"0A";
  signal receiving : boolean := true;
signal rr : std_logic := '0';
signal ack : std_logic;
signal       i2c_sda :  std_logic;
 signal      i2c_scl :  std_logic;
begin

  clk   <= not clk after c_clk_half_period;
  reset <= '0' after 3*c_clk_half_period;
receiving <= false when dummy = '1' else true;

  i2c_sda <= rr when not receiving else 'Z';
  
  i2c_in.data_to_slave <= x"0A";

  
  
  
  process
  begin
  i2c_in.access_start <= '0';
    rr <= 'H'; 
    -- initialization
    -- i2c_in.rw_n <= '0';
    -- i2c_in.access_start <= '0';
    -- wait until reset = '0';
    -- wait until rising_edge(clk);
    -- i2c_in.access_start <= '1';
    -- wait until rising_edge(clk); 
    -- i2c_in.access_start <= '0';
    -- wait until i2c_out.busy = '0';
    wait for 50 us;
    wait until rising_edge(clk);
    i2c_in.rw_n <= '1';
    wait until rising_edge(clk);
    i2c_in.access_start <= '1';
    wait until rising_edge(clk); 
    i2c_in.access_start <= '0';
    wait until dummy = '1';
    report "here " & integer'image(now / 1 ns);
    for i in 7 downto 0 loop
      rr <= data_from_slave(i);
			wait for 10240 ns;
		end loop; -- debug 75260 ns
    
    wait for 50 us;
    wait until rising_edge(clk);
    i2c_in.rw_n <= '0';
    wait until rising_edge(clk);
    i2c_in.access_start <= '1';
    wait until rising_edge(clk); 
    i2c_in.access_start <= '0';
    
    wait until i2c_out.access_done = '1';
        
    wait;
    
  end process;

  -- i2c instantiation
  i2c_DUT : entity work.i2c(rtl)
    generic map(g_clk_freq_mhz => 16000,
                buad_rate      => 100
               )
    port map(clk     => clk,
             reset   => reset,
             i2c_in  => i2c_in,
             i2c_out => i2c_out,
             i2c_sda     => i2c_sda,
              i2c_scl => i2c_scl,
             ack_o   => ack
            );
             
end architecture tb;