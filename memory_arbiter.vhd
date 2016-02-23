library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

use work.memory_arbiter_lib.all;

-- Do not modify the port map of this structure
entity memory_arbiter is
port (clk 	: in STD_LOGIC;
      reset : in STD_LOGIC;
      
			--Memory port #1
			addr1	: in NATURAL;
			data1	:	inout STD_LOGIC_VECTOR(MEM_DATA_WIDTH-1 downto 0);
			re1		: in STD_LOGIC;
			we1		: in STD_LOGIC;
			busy1 : out STD_LOGIC;
			
			--Memory port #2
			addr2	: in NATURAL;
			data2	:	inout STD_LOGIC_VECTOR(MEM_DATA_WIDTH-1 downto 0);
			re2		: in STD_LOGIC;
			we2		: in STD_LOGIC;
			busy2 : out STD_LOGIC
  );
end memory_arbiter;

architecture behavioral of memory_arbiter is

	--Main memory signals
  --Use these internal signals to interact with the main memory
  SIGNAL mm_address       : NATURAL                                       := 0;
  SIGNAL mm_we            : STD_LOGIC                                     := '0';
  SIGNAL mm_wr_done       : STD_LOGIC                                     := '0';
  SIGNAL mm_re            : STD_LOGIC                                     := '0';
  SIGNAL mm_rd_ready      : STD_LOGIC                                     := '0';
  SIGNAL mm_data          : STD_LOGIC_VECTOR(MEM_DATA_WIDTH-1 downto 0)   := (others => 'Z');
  SIGNAL mm_initialize    : STD_LOGIC                                     := '0';
  type state is (idle, read1, read2, write1, write2);
  signal y : state;
begin

	--Instantiation of the main memory component (DO NOT MODIFY)
	main_memory : ENTITY work.Main_Memory
      GENERIC MAP (
				Num_Bytes_in_Word	=> NUM_BYTES_IN_WORD,
				Num_Bits_in_Byte 	=> NUM_BITS_IN_BYTE,
        Read_Delay        => 3, 
        Write_Delay       => 3
      )
      PORT MAP (
        clk					=> clk,
        address     => mm_address,
        Word_Byte   => '1',
        we          => mm_we,
        wr_done     => mm_wr_done,
        re          => mm_re,
        rd_ready    => mm_rd_ready,
        data        => mm_data,
        initialize  => mm_initialize,
        dump        => '0'
      );

process (clk, reset)
begin
	if reset = '1' then
		y <= idle;
		busy1 <= '0';
		busy2 <= '0';
		mm_re <= '0';
		mm_we <= '0';
	elsif (clk'event) then
		case y is
			when idle =>
				if re1 = '1' then
					y <= read1;
				elsif we1 = '1' then
					y <= write1;
				elsif re2 = '1' then
					y <= read2;
				elsif we2 = '1' then
					y <= write2;
				else
					y <= idle;
				end if;
			when read1 => 
				busy1 <= '1';
				mm_address <= addr1;
				mm_data <= data1;
				mm_re <= re1;
				mm_we <= we1;
				if (re2 = '1' or we2 = '1') then
					busy2 <= '1';
				else
					busy2 <= '0'; -- user cancels mem access on 2
				end if;
				if (mm_rd_ready = '1') then
					busy1 <= '0';
					y <= idle;
				else
					y <= read1;
				end if;
			when write1 =>
				busy1 <= '1';
				mm_address <= addr1;
				mm_data <= data1;
				mm_we <= we1;
				mm_re <= re1;
				if (re2 = '1' or we2 = '1') then
					busy2 <= '1';
				else
					busy2 <= '0'; -- user cancels mem access on 2
				end if;
				if (mm_wr_done = '1') then
					busy1 <= '0';
					y <= idle;
				else
					y <= write1;
				end if;
			when read2 =>
				busy2 <= '1';
				mm_address <= addr2;
				mm_data <= data2;
				mm_re <= re2;
				mm_we <= we2;
				if (re1 = '1' or we1 = '1') then
					busy1 <= '1';
				else
					busy1 <= '0'; -- user cancels mem access on 1
				end if;
				if (mm_rd_ready = '1') then
					busy2 <= '0';
					y <= idle;
				else
					y <= read2;
				end if;
			when write2 =>
				busy2 <= '1';
				mm_address <= addr2;
				mm_data <= data2;
				mm_we <= we2;
				mm_re <= re2;
				if (re1 = '1' or we1 = '1') then
					busy1 <= '1';
				else
					busy1 <= '0'; -- user cancels mem access on 1
				end if;
				if (mm_wr_done = '1') then
					busy2 <= '0';
					y <= idle;
				else
					y <= write2;
				end if;
			end case;
		end if;
end process;
			


end behavioral;