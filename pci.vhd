-------------------------------------------------------------------------------
--  MIST Project - SUED Expirement - Camera Task
--  PCI (Parallel Camera Interface)
-------------------------------------------------------------------------------
--  Brief description:
--  Parallel interface bus to capture data (pixel) from camera.
-------------------------------------------------------------------------------
--  Version/revision history:
--  <2017-05-21>, <Ahmad Zaklouta>, <Start>
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.camera_pkg.all;

entity pci is
  port(reset   : in  std_logic;
       pci_in  : in  pci_in_type;
       pci_out : out pci_out_type
      );
end entity pci;

architecture rtl of pci is

  -- Constants Declaration

  
  -- FSM Declaration
    type frame_machine_type is (idle, frame_start, receive_row, frame_end);
    type row_machine_type   is (idle, receive_byte, row_end);
    
  -- Internal Record Declaration
  type reg_type is record
    frame_machine       : frame_machine_type;
    row_machine         : row_machine_type;
    trigger_row_machine : std_logic;
    data_to_fifo        : unsigned(7 downto 0);
    fifo_wr_en          : std_logic;
    byte_received       : std_logic;
    row_received        : std_logic;
    frame_received      : std_logic;
    row_bytes_cnt       : integer range 0 to bytes_per_row;
    rows_cnt            : integer range 0 to rows_per_frame;
  end record;
  
  -- Signals Declaration
  signal reg_s    : reg_type;
  signal reg_next : reg_type;
  
begin

  -- Rigesters to output ports assignments
  pci_out.data_to_fifo  <= reg_s.data_to_fifo;
  pci_out.fifo_wr_en    <= reg_s.fifo_wr_en;
   
  combinatorial_p : process(all)
    variable reg_v : reg_type;
  begin
    -- Default Assignments
    reg_v := reg_s;

    reg_v.trigger_row_machine := '0';
    reg_v.byte_received       := '0';
    reg_v.row_received        := '0';

    case reg_s.row_machine is
      when idle =>
        if reg_s.trigger_row_machine = '1' then ---- Start receiving row
          reg_v.row_machine      := receive_byte; -- Next state (Go to receive_byte)
          reg_v.row_bytes_cnt    := 0; ------------- Reset byte counter
        end if;
        
      when receive_byte =>
        if pci_in.href_pin = '1' then ------------------------ Start of the row
          if reg_v.row_bytes_cnt < bytes_per_row then -------- Not all row's bytes have been received yet
            reg_v.fifo_wr_en    := '1'; ---------------------- Enable writing to FIFO buffer
            reg_v.data_to_fifo  := pci_in.pixel_data; -------- Send byte to FIFO
            reg_v.byte_received := '1'; ---------------------- Byte has been received
            reg_v.row_bytes_cnt := reg_v.row_bytes_cnt + 1; -- Increase the byte's counter
            reg_v.row_machine   := receive_byte; ------------- Next state (Go to receive_byte)
          else ----------------------------------------------- all row's bytes are received
            reg_v.row_machine   := row_end; ------------------ Next state (Go to row_end)
            reg_v.fifo_wr_en    := '0'; ---------------------- Disable writing to FIFO buffer
          end if;
        end if;  

      when row_end =>
        reg_v.rows_cnt     := reg_s.rows_cnt + 1; -- Increase the row's counter
        reg_v.row_received := '1'; ----------------- Row has been received
        reg_v.row_machine  := idle; ---------------- Next state (Go back to idle)
    end case;

    
    case reg_s.frame_machine is
      when idle =>
        if pci_in.start_recording = '1' then ---- Take a picture
          reg_v.rows_cnt       := 0; ------------ Reset the row's counter
          reg_v.frame_received := '0'; ---------- Frame not done yet
          reg_v.frame_machine  := frame_start; -- Next state (Go to frame_start)
        end if;

      when frame_start =>
        if pci_in.vsync_pin = '1' then --------------- Frame beginning
          reg_v.trigger_row_machine := '1'; ---------- Go to row machine to start receiving the frame row by row
          reg_v.frame_machine       := receive_row; -- Next state (Go to receive_row)
        end if;
        
      when receive_row =>
        if reg_s.rows_cnt < rows_per_frame then -- Not all rows have been received yet
          if reg_s.row_received = '1' then ------- row has been received
            reg_v.trigger_row_machine := '1'; ---- keep triggering row machine to receive the next row
          end if;
        else ------------------------------------- all rows are received
          reg_v.frame_machine := frame_end; ------ Next state (Go to frame_end)
        end if;
        
      when frame_end =>
        if pci_in.vsync_pin = '1' then --- Frame end
          reg_v.frame_received := '1'; --- Frame has been received
          reg_v.frame_machine  := idle; -- Next state (Go back to idle)
        end if; 
        
    end case;

    reg_next <= reg_v;
    
  end process combinatorial_p;

  sequential_p : process(pci_in.pclk_pin, reset)
  begin
    if (reset = '1') then
      reg_s.frame_machine <= idle;
      reg_s.row_machine   <= idle;
      reg_s.fifo_wr_en    <= '0';
      reg_s.data_to_fifo  <= x"00";
    elsif rising_edge(pci_in.pclk_pin) then
      reg_s <= reg_next;
    end if;

  end process sequential_p;
  
end architecture rtl;