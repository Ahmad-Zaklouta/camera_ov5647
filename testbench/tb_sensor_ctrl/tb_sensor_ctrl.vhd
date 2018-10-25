-------------------------------------------------------------------------------
--  MIST Project - SUED Expirement - Camera Task
--  Testbench for sensor_ctrl unit
-------------------------------------------------------------------------------
--  Brief description:
--
-------------------------------------------------------------------------------
--  Version/revision history:
--  <2017-03-12>, <Ahmad Zaklouta>, <Start>
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.camera_pkg.all;

entity tb_sensor_ctrl is
end entity tb_sensor_ctrl;

Architecture tb of tb_sensor_ctrl is
  
  -- Constants Declaration
  constant c_clk_half_period : time    := 20 ns;  -- Clock frequency
  constant c_clk_freq_mhz    : integer := 1000 / (2 * (c_clk_half_period / 1 ns));
  constant c_tco             : time    := 1 ns;   -- Clock to output
  
  -- Signals Declaration
  signal clk     : std_logic := '0';  -- System clock
  signal reset   : std_logic := '1';  -- System reset
  
  signal sensor_ctrl_in  : sensor_ctrl_in_type;
  signal sensor_ctrl_out : sensor_ctrl_out_type;
  signal i2c_sda         : std_logic;
  signal i2c_scl         : std_logic;
  signal data_from_slave : unsigned(7 downto 0) := x"CB";
  signal data_from_master : unsigned(7 downto 0);
  
  signal receiving       : boolean := true;
  signal rr : std_logic := '0';
begin

  clk   <= not clk after c_clk_half_period;
  reset <= '0' after 3*c_clk_half_period;
  
  receiving <= false when dummy = '1' else true;

  i2c_sda <= rr when not receiving else 'Z';

  process (i2c_scl)
  begin
    if (rising_edge(i2c_scl) and not receiving)  then
      data_from_master <= data_from_master(6 downto 0) & i2c_sda;
    end if;
  end process;
  
  process
  begin
    rr <= 'H'; 
    -- initialization
    wait until reset = '0';
    wait until rising_edge(clk);
 -- Configure Camera ----------------------------------------------------------
    sensor_ctrl_in.start_config <= '1';
    wait until rising_edge(clk);
    sensor_ctrl_in.start_config <= '0';
    wait until rising_edge(clk);
    wait until dummy = '1';
    report "here " & integer'image(now / 1 ns);
    for i in 7 downto 0 loop
        rr <= data_from_slave(i); 
        wait for 10 us;
    end loop;
    data_from_slave <= x"BB";
    wait until dummy = '1';
    report "here " & integer'image(now / 1 ns);
    for i in 7 downto 0 loop
        rr <= data_from_slave(i); 
        wait for 10 us;
    end loop;
    wait until sensor_ctrl_out.config_done = '1';
    report "config done " & integer'image(now / 1 ns);
 ------------------------------------------------------------------------------
    wait for 100 us;
 -- Read from Camera ----------------------------------------------------------
    sensor_ctrl_in.i2c_in.data_to_slave <= x"AA";  -- Register addr
    sensor_ctrl_in.i2c_in.rw_n          <= '1';
    sensor_ctrl_in.i2c_in.access_start  <= '1';
    wait until rising_edge(clk); 
    sensor_ctrl_in.i2c_in.access_start  <= '0';
    wait until sensor_ctrl_out.i2c_out.next_data = '1';
    sensor_ctrl_in.i2c_in.data_to_slave <= x"BB";  -- Register addr
    data_from_slave <= x"CC";
    wait until dummy = '1';
    
    for i in 7 downto 0 loop
        rr <= data_from_slave(i); 
        wait for 10 us;
    end loop;
    report "read done " & integer'image(now / 1 ns);
    wait until sensor_ctrl_out.i2c_out.access_done = '1';
 ------------------------------------------------------------------------------
    wait for 100 us;
 -- write to Camera -----------------------------------------------------------
    sensor_ctrl_in.i2c_in.data_to_slave <= x"AA";  -- Register addr
    sensor_ctrl_in.i2c_in.rw_n          <= '0';
    sensor_ctrl_in.i2c_in.access_start  <= '1';
    wait until rising_edge(clk); 
    sensor_ctrl_in.i2c_in.access_start  <= '0';
    wait until sensor_ctrl_out.i2c_out.next_data = '1';
    sensor_ctrl_in.i2c_in.data_to_slave <= x"BB";  -- Register addr
    wait until sensor_ctrl_out.i2c_out.next_data = '1';
    sensor_ctrl_in.i2c_in.data_to_slave <= x"CC";  -- Register addr
    wait until sensor_ctrl_out.i2c_out.access_done = '1';
    wait for 100 us;
    wait;
  end process;

  -- sensor_ctrl instantiation
  sensor_ctrl_DUT : entity work.sensor_ctrl(rtl)
            
    port map(clk             => clk,
             reset           => reset,
             sensor_ctrl_in  => sensor_ctrl_in,
             sensor_ctrl_out => sensor_ctrl_out,
             i2c_sda         => i2c_sda,
             i2c_scl         => i2c_scl
             );
             
end architecture tb;