-------------------------------------------------------------------------------
--  MIST Project - SUED Expirement - Camera Task
--  sensor_ctrl unit
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

entity sensor_ctrl is
  generic(g_clk_freq_mhz : natural := 25000000;
          buad_rate      : natural := 100000
          );

  port(clk             : in  std_logic;
       reset           : in  std_logic;
       sensor_ctrl_in  : in  sensor_ctrl_in_type;
       sensor_ctrl_out : out sensor_ctrl_out_type;
       i2c_sda         : inout std_logic;
       i2c_scl         : out   std_logic
       );
end entity sensor_ctrl;

Architecture rtl of sensor_ctrl is

  -- FSM Declaration
  type sensor_ctrl_machine_type is (idle, prepare_sensor, sensor_config, config_finished);

  -- Internal Record Declaration
  type reg_type is record
    sensor_ctrl_machine : sensor_ctrl_machine_type;
    -- i2c input signals
    i2c_in              : i2c_in_type;
    -- Register_map input signals  
    register_map_in     : register_map_in_type;
    -- Sensor_ctrl output signals
    config_done         : std_logic;
    pwdn_pin            : std_logic;
    -- Internal signals
    config_cnt          : integer range 0 to c_num_of_reg;
    access_done         : std_logic;
    start_recording     : std_logic;
  end record;
  
  signal reg_s    : reg_type;
  signal reg_next : reg_type;
  
  -- Output Signals for components
  signal i2c_out          : i2c_out_type;
  signal register_map_out : register_map_out_type;
  
  
begin

  -- Actual to formal mapping
  sensor_ctrl_out.config_done             <= reg_s.config_done;
  sensor_ctrl_out.pwdn_pin                <= reg_s.pwdn_pin;
  sensor_ctrl_out.start_recording         <= reg_s.start_recording;
  combinatorial_p : process(all)
    variable reg_v : reg_type;
  begin
    -- Default Assignments
    reg_v                     := reg_s;
    reg_v.i2c_in.access_start := '0';
    reg_v.access_done         := i2c_out.access_done;
    reg_v.start_recording     := '0';
    
    case reg_s.sensor_ctrl_machine is
      when idle =>
        if sensor_ctrl_in.start_config = '1' then ------- Wait until request for configuration
          reg_v.pwdn_pin            := '0'; ------------- Power the device up       
          reg_v.config_done         := '0'; ------------- Not configured 
          reg_v.sensor_ctrl_machine := prepare_sensor; -- Next state (Go to prepare_sensor)
        end if;
        
      when prepare_sensor =>
        reg_v.config_cnt           := 0; -------------- Reset the counter
        reg_v.i2c_in.access_start  := '1'; ------------ Request access from i2c
        reg_v.i2c_in.rw_n          := '0'; ------------ write operation
        reg_v.sensor_ctrl_machine  := sensor_config; -- Next state (Go to sensor_config)
        
      when sensor_config =>
        -- Mapping outputs to internal signals
        reg_v.i2c_in.data_to_slave      := register_map_out.data_to_slave; -- Data from register_map
        reg_v.register_map_in.next_data := i2c_out.next_data; --------------- Trigger for next data in register_map
        if reg_s.access_done = '1' then ------------------------------------- Wait until access_done is done (one register configured)
          if (reg_s.config_cnt < c_num_of_reg) then ------------------------- Not all registers have been configured yet
            reg_v.config_cnt          := reg_s.config_cnt + 1; -------------- Increase configuration counter
            reg_v.i2c_in.access_start := '1'; ------------------------------- Request access from i2c
          else -------------------------------------------------------------- All registers have been configured
            reg_v.sensor_ctrl_machine := config_finished; ------------------- Next state (Go to config_finished)
          end if;
        end if;

      when config_finished =>
        if register_map_out.config_finished = '1' then -- All addresses have been accessed
          reg_v.config_done         := '1'; ------------- Configuration is done and device is ready to capture picture
          reg_v.start_recording     := '1'; ------------- Trigger for pci and frame_ctrl to start
          reg_v.sensor_ctrl_machine := idle; ------------ Next state (Go to idle)
        end if;
          
    end case;
    
    reg_next <= reg_v;
    
  end process combinatorial_p;

  sequential_p : process(clk, reset)
  begin
    if (reset = '1') then
      reg_s.sensor_ctrl_machine <= idle;
      reg_s.config_done         <= '0';
      reg_s.start_recording     <= '0';
      reg_s.config_cnt          <= 0;
    elsif rising_edge(clk) then
      reg_s <= reg_next;
    end if;

  end process sequential_p;

  -- Components Instantiation
  i2c_unit : entity work.i2c(rtl)
    generic map(g_clk_freq_mhz => c_clk_freq_mhz, 
                buad_rate      => c_buad_rate
               )     
    port map(clk     => clk,
             reset   => reset,
             i2c_in  => reg_s.i2c_in,
             i2c_out => i2c_out,
             i2c_sda => i2c_sda,
             i2c_scl => i2c_scl
             );
           
  register_map_unit : entity work.register_map(rtl)
    port map(clk              => clk,
             register_map_in  => reg_s.register_map_in,
             register_map_out => register_map_out
             );
           
end architecture rtl;
