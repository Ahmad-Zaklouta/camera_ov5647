-------------------------------------------------------------------------------
--  MIST Project - SUED Expirement - Camera Task
--  frame_ctrl
-------------------------------------------------------------------------------
--  Brief description:
--  Frame buffer to interface PCI with SDRAM cntroller
-------------------------------------------------------------------------------
--  Version/revision history:
--  <2017-06-10>, <Ahmad Zaklouta>, <Start>
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.camera_pkg.all;

entity frame_ctrl is
  port(clk            : in  std_logic;
       reset          : in  std_logic;
       frame_ctrl_in  : in  frame_ctrl_in_type;
       frame_ctrl_out : out frame_ctrl_out_type
      );
end entity frame_ctrl;

architecture rtl of frame_ctrl is

  -- FIFO Declaration
  component fifo_generator_0
    port(rst       : in std_logic;
         wr_clk    : in std_logic;
         rd_clk    : in std_logic;
         din       : in std_logic_vector(7 downto 0);
         wr_en     : in std_logic;
         rd_en     : in std_logic;
         dout      : out std_logic_vector(7 downto 0);
         full      : out std_logic;
         empty     : out std_logic;
         valid     : out std_logic;
         prog_full : out std_logic
    );
  end component;

  -- Constants Declaration

  
  -- FSM Declaration
  type frame_ctrl_machine_type is (idle, read_from_buffer, sdram_wr_grant, frame_wr_finished);
  
  -- internal Record Declaration
  type reg_type is record
    frame_ctrl_machine : frame_ctrl_machine_type;
    data_to_sdram      : unsigned(7 downto 0);
    addr_to_sdram      : unsigned(7 downto 0);
    sdram_access_req   : std_logic;
    frame_stored       : std_logic;
    fifo_rd_en         : std_logic;
    fifo_rst           : std_logic;
    frame_bytes_cnt    : integer range 0 to bytes_per_frame;
  end record;
  
  -- Signals Declaration
  signal reg_s    : reg_type;
  signal reg_next : reg_type;
  
  -- FIFO Outputs
  signal data_from_fifo  : std_logic_vector(7 downto 0);
  signal fifo_valid_flag : std_logic;
  signal fifo_pfull_flag : std_logic;  -- full_prog flag from fifo
  signal fifo_full_flag  : std_logic;
  signal fifo_empty_flag : std_logic;

begin

  -- Rigesters to output ports assignments
  frame_ctrl_out.data_to_sdram    <= reg_s.data_to_sdram;
  frame_ctrl_out.addr_to_sdram    <= reg_s.addr_to_sdram;
  frame_ctrl_out.sdram_access_req <= reg_s.sdram_access_req;
  frame_ctrl_out.frame_stored     <= reg_s.frame_stored;
  
  combinatorial_p : process(all)
    variable reg_v : reg_type;
  begin
  
    -- Default Assignments
    reg_v                  := reg_s;
    reg_v.fifo_rst         := '0';
--    reg_v.sdram_access_req := '0'; check if it is spike or continuous
    
    case reg_s.frame_ctrl_machine is
      when idle =>
        if frame_ctrl_in.start_recording = '1' then ------ Take a picture
          reg_v.addr_to_sdram      := start_addr - 1; ---- Fisrt address for first byte
          reg_v.frame_stored       := '0'; --------------- Frame not stored in SDRAM
          reg_v.frame_ctrl_machine := read_from_buffer; -- Next state (Go to read_from_buffer)
        end if;

      when read_from_buffer =>
        if (reg_s.frame_bytes_cnt < bytes_per_frame) then ------------------------ Frame not finished yet
          if ((fifo_full_flag = '1') or ------------------------------------------ FIFO has enough bytes to start reading
              (bytes_per_frame - reg_s.frame_bytes_cnt < read_flag_bytes)) then -- The last bytes (less than read_flag_bytes)
            reg_v.fifo_rd_en         := '1'; ------------------------------------- Read enable for FIFO
            reg_v.sdram_access_req   := '1'; ------------------------------------- Request access from SDRAM
            reg_v.frame_ctrl_machine := sdram_wr_grant; -------------------------- Next state (Go to sdram_wr_grant)
          end if;
        end if;
        
      when sdram_wr_grant =>
        if (frame_ctrl_in.sdram_access_grant = '1' and fifo_valid_flag = '1') then -- Access granted and fifo dout ready
          reg_v.data_to_sdram := unsigned(data_from_fifo); -------------------------- Send data to SDRAM
          reg_v.addr_to_sdram := reg_s.addr_to_sdram + 1; --------------------------- Send addr to SDRAM
          if (reg_s.frame_bytes_cnt < bytes_per_frame) then ------------------------- Frame not finished yet
            reg_v.frame_bytes_cnt    := reg_s.frame_bytes_cnt + 1; ------------------ increase byte counter
            reg_v.frame_ctrl_machine := read_from_buffer; --------------------------- Next state (Go to read_from_buffer)
          else ---------------------------------------------------------------------- Frame finished
            reg_v.frame_ctrl_machine := frame_wr_finished; -------------------------- Next state (Go to frame_wr_finished)
          end if;
        end if;
        
      when frame_wr_finished =>
        reg_v.frame_stored       := '1'; --- Frame stored in SDRAM
        reg_v.frame_ctrl_machine := idle; -- Next state (Go to idle)
        
    end case;
    
    reg_next <= reg_v;
  end process combinatorial_p;

  sequential_p : process(clk, reset)
  begin
    if (reset = '1') then
      reg_s.frame_ctrl_machine <= idle;
      reg_s.addr_to_sdram      <= start_addr - 1;
      reg_s.frame_stored       <= '0';
      reg_s.fifo_rst           <= '1';
      reg_s.fifo_rd_en         <= '0';
    elsif rising_edge(clk) then
      reg_s <= reg_next;
    end if;

  end process sequential_p;
  
  -- FIFO Instantiation
  FIFO : fifo_generator_0
    port map(rst       => reg_s.fifo_rst,
             wr_clk    => frame_ctrl_in.fifo_wr_clk,
             rd_clk    => clk,
             din       => std_logic_vector(frame_ctrl_in.data_to_fifo),
             wr_en     => frame_ctrl_in.fifo_wr_en,
             rd_en     => reg_s.fifo_rd_en,
             dout      => data_from_fifo,
             full      => fifo_full_flag,
             empty     => fifo_empty_flag,
             valid     => fifo_valid_flag,
             prog_full => fifo_pfull_flag
            );

end architecture rtl;
