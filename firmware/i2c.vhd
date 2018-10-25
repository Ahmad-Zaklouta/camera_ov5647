-------------------------------------------------------------------------------
--  MIST Project - SUED Expirement - Camera Task
--  i2c unit
-------------------------------------------------------------------------------
--  Brief description:
--
-------------------------------------------------------------------------------
--  Version/revision history:
--  <2017-02-23>, <Ahmad Zaklouta>, <Start>
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.camera_pkg.all;

entity i2c is
  generic(g_clk_freq_mhz : natural := 24000;
          buad_rate      : natural := 200
          );

  port(clk     : in    std_logic;
       reset   : in    std_logic;
       i2c_in  : in    i2c_in_type;
       i2c_out : out   i2c_out_type;
       i2c_sda : inout std_logic;
       i2c_scl : out   std_logic
       );
end entity i2c;

Architecture rtl of i2c is

  -- Constants Declaration
  constant c_clk_per_quarter_scl : integer := g_clk_freq_mhz / buad_rate / 4;
  constant c_clk_per_half_scl    : integer := c_clk_per_quarter_scl * 2;
  constant c_clk_per_scl         : integer := c_clk_per_half_scl * 2;

  -- FSM Declaration
  type bit_machine_type   is (idle, data_bits, ack_bit);
  type phase_machine_type is (idle, sda_high, start_bit, send_device_addr, send_reg_addr, send_write_data, stop_bit);

  -- Internal Record Declaration
  type reg_type is record
    bit_machine         : bit_machine_type;
    phase_machine       : phase_machine_type;
    -- output signals
    busy                : std_logic;
    next_data           : std_logic;
    -- Input signals
    rw_n                : std_logic;
    -- i2c signals
    scl                 : std_logic;
    -- Internal signals
    divisor_cnt         : integer range 0 to c_clk_per_scl - 1;
    trigger_bit_machine : std_logic;
    byte_done           : std_logic;
    access_done         : std_logic;
    trx_bit_cnt         : integer range 0 to 8;
    trx_byte            : unsigned(8 downto 0);
    scl_en              : std_logic;
    transsmision        : boolean; -- sda output enable (SIO_D_OE_M_ in datasheet)
    addr_cnt            : integer range 0 to reg_addr_size;
  end record;
  
  -- Signals Declaration
  signal reg_s    : reg_type;
  signal reg_next : reg_type;
  signal i2c_rx   : std_logic;
  

begin

  -- Rigesters to output ports assignments
  i2c_out.busy            <= reg_s.busy;
  i2c_out.next_data       <= reg_s.next_data;
  i2c_out.access_done     <= reg_s.access_done;
  i2c_scl                 <= reg_s.scl;
  i2c_sda                 <= reg_s.trx_byte(8) when reg_s.transsmision else 'Z';
  i2c_rx                  <= i2c_sda;

  combinatorial_p : process(all)
    variable reg_v : reg_type;
  begin
    -- Default Assignments
    reg_v                     := reg_s;
    -- voting here
    reg_v.access_done         := '0';
    reg_v.byte_done           := '0';
    reg_v.next_data           := '0';
    reg_v.trigger_bit_machine := '0';

    -- Handling scl
    if reg_s.scl_en = '1' then ------------------------------------------------------ Assert scl
      if (reg_s.divisor_cnt = c_clk_per_quarter_scl - 1 or -------------------------- first quarter of divisor_cnt
          reg_s.divisor_cnt = c_clk_per_quarter_scl + c_clk_per_half_scl - 1) then -- third quarter of divisor_cnt
        reg_v.scl := not reg_s.scl; ------------------------------------------------- Toggel
      end if;
    else ---------------------------------------------------------------------------- Deassert scl
      reg_v.scl := '1'; ------------------------------------------------------------- pull-up scl
    end if;

    -- FSM to handle bit trasmitting & receiving
    case reg_s.bit_machine is
    
      when idle =>
        if reg_s.trigger_bit_machine = '1' then -- Bit_machine triggerred
          reg_v.trx_bit_cnt := 0; ---------------- Reset bit counter
          reg_v.bit_machine := data_bits; -------- Next state (Go to data_bits)
        end if;
      
      when data_bits =>
        -- Wait until scl cycle finish to transmit next bit (depend on the initiation of divisor_cnt)
        if reg_s.divisor_cnt = c_clk_per_scl - 1 then
          reg_v.divisor_cnt := 0;  ----------------------------------- Reset divisors' counter
          reg_v.trx_byte    := reg_s.trx_byte(7 downto 0) & i2c_rx; -- Left shift to feed sda bit by bit
          if reg_s.trx_bit_cnt = 8 then ------------------------------ 8-bits transsmision is finished
            reg_v.trx_bit_cnt  := 0; --------------------------------- Reset bits' counter
            reg_v.transsmision := not reg_s.transsmision; ------------ Toggle for Ack bit
            reg_v.bit_machine  := ack_bit; --------------------------- Next state (Go to ack_bit)
            -- Handling next_data signal for register_map
            if ((reg_s.phase_machine = send_device_addr and reg_s.rw_n = '0') or reg_s.phase_machine = send_reg_addr) then
              reg_v.next_data := '1'; -------------------------------- Enable for next configuration data (addr or value)
            end if;
          else ------------------------------------------------------- transsmision bits not finished yet
            reg_v.trx_bit_cnt := reg_s.trx_bit_cnt + 1; -------------- Increase bits' counter
          end if;
        else --------------------------------------------------------- scl cycle not finished yet
          reg_v.divisor_cnt := reg_s.divisor_cnt + 1; ---------------- Increase divisors' counter
        end if;

      when ack_bit =>
        if reg_s.divisor_cnt = c_clk_per_scl - 1 then -- Ack bit has been transmitted
          reg_v.divisor_cnt := 0; ---------------------- Reset divisors' counter
          reg_v.byte_done   := '1'; -------------------- Byte transsmision is done 
          reg_v.bit_machine := idle; ------------------- Next state (Go to idle)
        else ------------------------------------------- scl cycle not finished yet
          reg_v.divisor_cnt := reg_s.divisor_cnt + 1; -- Increase divisors' counter
        end if;
      
    end case; -- End bit_machine FSM
    
    -- FSM to prepare each phase & feed bit_machine
    case reg_s.phase_machine is
      when idle =>
        reg_v.scl_en      := '0'; ---------------------------- Release scl (Pull-up)
        reg_v.busy        := '0'; ---------------------------- I2C_U is not busy and ready to transmit or receive
        reg_v.divisor_cnt := 0; ------------------------------ Reset divisors' counter
        reg_v.trx_byte    := (others => '1'); ---------------- Initialize trx_byte register by '1'
        if (i2c_in.access_start = '1') then ------------------ Rrequest access to sensor
          reg_v.divisor_cnt          := c_clk_per_half_scl; -- Initilize by half_scl so sda change in the middle of the low part of scl
          reg_v.transsmision         := true; ---------------- Enable transsmision (I2C ==> Sensor)
          reg_v.busy                 := '1'; ----------------- I2C_U is busy
          reg_v.trx_byte(7 downto 0) := c_slave_id; ---------- Initialize trx_byte by Sensor address
          reg_v.phase_machine        := sda_high; ------------ Next state (Go to sda_high)
        end if;

      when sda_high => --------------------- Minimum 15 ns
        reg_v.scl_en        := '1'; -------- Assert scl
        reg_v.trx_byte(8)   := '0'; -------- Initialize trx_byte(8) register by '1' Start bit (High to low)
        reg_v.phase_machine := start_bit; -- Next state (Go to start_bit)
        
      when start_bit =>
        reg_v.trigger_bit_machine := '1'; --------------- Trigger bit machine to transmit device address
        reg_v.phase_machine       := send_device_addr; -- Next state (Go to send_device_addr)
        
      when send_device_addr =>
        if reg_s.byte_done = '1' then -------------------------------- Device address transsmision is done
          reg_v.trigger_bit_machine  := '1'; ------------------------- Trigger bit machine to transmit register address
          reg_v.transsmision         := true; ------------------------ Enable transsmision (I2C ==> Sensor)
          reg_v.divisor_cnt          := c_clk_per_scl - 1; ----------- Reaset divisors' counter check?
          reg_v.trx_byte(8 downto 0) := i2c_in.data_to_slave & '1'; -- Initialize trx_byte by register address byte
          reg_v.addr_cnt             := 0; --------------------------- Reset register address byte counter
          reg_v.phase_machine        := send_reg_addr; --------------- Next state (Go to send_reg_addr)
        end if;

      when send_reg_addr =>
        if reg_s.byte_done = '1' then ---------------------------------- Register address transsmision is done
          reg_v.divisor_cnt  := 0; ------------------------------------- Reaset divisors' counter 
          reg_v.transsmision := true; ---------------------------------- Enable transsmision (I2C ==> Sensor)
          if reg_s.addr_cnt = reg_addr_size - 1 then ------------------- All Register address bytes has been transmitted
            reg_v.divisor_cnt          := c_clk_per_scl - 1; ----------- check?
            reg_v.trigger_bit_machine  := '1'; ------------------------- Trigger bit machine to transmit register value
            reg_v.trx_byte(8 downto 0) := i2c_in.data_to_slave & '1'; -- Initialize trx_byte by register value (8 bits)
            reg_v.phase_machine        := send_write_data; ------------- Next state (Go to send_write_data)
          else --------------------------------------------------------- Register address is more than 1 byte
            reg_v.trigger_bit_machine  := '1'; ------------------------- Trigger bit machine to transmit next register address byte
            reg_v.trx_byte(8 downto 0) := i2c_in.data_to_slave & '1'; -- Initialize trx_byte by next register address byte
            reg_v.addr_cnt             := reg_s.addr_cnt + 1; ---------- Increase register address byte counter
            reg_v.phase_machine        := send_reg_addr; --------------- Next state (Go to send_reg_addr)
          end if;
        end if;
        
      when send_write_data =>
        if reg_s.byte_done = '1' then ------- Register value transsmision is done
          reg_v.transsmision  := true; ------ Enable transsmision (I2C ==> Sensor)
          reg_v.trx_byte(8)   := '0'; ------- Initialize trx_byte(8) register by '0' to drive sda to '0' after Ack bit
          reg_v.phase_machine := stop_bit; -- Next state (Go to stop_bit)
        end if;      
        
      when stop_bit =>
        if reg_s.divisor_cnt = c_clk_per_scl - c_clk_per_quarter_scl then -- 3rd-quarter of divisor_cnt (Terminate the access)
          reg_v.transsmision  := false; ------------------------------------ Disable transsmision (I2C ==> Sensor)
          reg_v.access_done   := '1'; -------------------------------------- Terminate the access
          reg_v.phase_machine := idle; ------------------------------------- Next state (Go to idle)
        else --------------------------------------------------------------- 1st-quarter or 2nd-quarter of divisor_cnt
          if reg_s.divisor_cnt = c_clk_per_quarter_scl - 1 then ------------ 1st-quarter of divisor_cnt (release scl)
            reg_v.scl_en := '0'; ------------------------------------------- Release scl (Pull-up)
          elsif reg_s.divisor_cnt = c_clk_per_half_scl then ---------------- 2nd-quarter of divisor_cnt (stop bit)
            reg_v.trx_byte(8) := '1'; -------------------------------------- Initialize trx_byte(8) register by '0' Stop bit (Low to High)
          end if;
          reg_v.divisor_cnt := reg_s.divisor_cnt + 1; ---------------------- Increase divisors' counter
        end if;  
        
    end case;

    reg_next <= reg_v;
    
  end process combinatorial_p;

  sequential_p : process(clk, reset)
  begin
    if (reset = '1') then
      reg_s.phase_machine   <= idle;
      i2c_sda               <= 'Z';
      reg_s.scl             <= '1';
      reg_s.scl_en          <= '0';
      reg_s.busy            <= '1';
      reg_s.next_data       <= '0';
      reg_s.divisor_cnt     <= 0;
    elsif rising_edge(clk) then
      reg_s <= reg_next;
    end if;

  end process sequential_p;

end architecture rtl;
