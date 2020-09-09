--------------------------------------------------------------------------------
--! @file       ti_tinyjambu_datapath.vhd
--! @brief      A three share threshold implementation protected TinyJAMBU
--              datapath
--! @author     Sammy Lin
--! @copyright  Copyright (c) 2020 Cryptographic Engineering Research Group
--!             ECE Department, George Mason University Fairfax, VA, U.S.A.
--!             All rights Reserved.
--! @license    This project is released under the GNU Public License.
--!             The license and distribution terms for this file may be
--!             found in the file LICENSE in this distribution or at
--!             http://www.gnu.org/licenses/gpl-3.0.txt
--! @note       This is publicly available encryption source code that falls
--!             under the License Exception TSU (Technology and software-
--!             unrestricted)
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.design_pkg.all;
use work.NIST_LWAPI_pkg.all;

entity tinyjambu_datapath is
    port (
        clk                 : in std_logic;
        reset               : in std_logic;
        nlfsr_load          : in std_logic;
        partial             : in std_logic;
        partial_bytes       : in std_logic_vector (1        downto 0);
        partial_bdo_out     : in std_logic_vector (3        downto 0);
        nlfsr_en            : in std_logic;
        nlfsr_reset         : in std_logic;
        decrypt             : in std_logic;
        bdi_a               : in std_logic_vector (CCW - 1  downto 0);
        bdi_b               : in std_logic_vector (CCW - 1  downto 0);
        bdi_c               : in std_logic_vector (CCW - 1  downto 0);
        key_a               : in std_logic_vector (CCSW - 1 downto 0);
        key_b               : in std_logic_vector (CCSW - 1 downto 0);
        key_c               : in std_logic_vector (CCSW - 1 downto 0);
        key_load            : in std_logic;
        key_index           : in std_logic_vector (1        downto 0);
        fbits_sel           : in std_logic_vector (1        downto 0);
        s_sel               : in std_logic_vector (1        downto 0);
        bdo_sel             : in std_logic;
        rdi_data            : in std_logic_vector (RW -1 downto 0);
        bdo_a               : out std_logic_vector (CCW - 1 downto 0);
        bdo_b               : out std_logic_vector (CCW - 1 downto 0);
        bdo_c               : out std_logic_vector (CCW - 1 downto 0)
    );
end entity tinyjambu_datapath;

architecture dataflow of tinyjambu_datapath is

-- Keep architecture ---------------------------------------------------------
attribute keep_hierarchy : string;
attribute keep_hierarchy of dataflow : architecture is "true";

constant REG_SIZE           : integer           := 128;

signal fbits_mux_out        : std_logic_vector (2           downto 0);

signal s_fbits_xor_out_a    : std_logic_vector (2           downto 0);
signal s_fbits_xor_out_b    : std_logic_vector (2           downto 0);
signal s_fbits_xor_out_c    : std_logic_vector (2           downto 0);

signal s_left_concat_out_a  : std_logic_vector (REG_SIZE-1  downto 0);
signal s_left_concat_out_b  : std_logic_vector (REG_SIZE-1  downto 0);
signal s_left_concat_out_c  : std_logic_vector (REG_SIZE-1  downto 0);

signal s_right_concat_out_a : std_logic_vector (REG_SIZE-1  downto 0);
signal s_right_concat_out_b : std_logic_vector (REG_SIZE-1  downto 0);
signal s_right_concat_out_c : std_logic_vector (REG_SIZE-1  downto 0);

signal s_mux_out_a          : std_logic_vector (REG_SIZE-1  downto 0);
signal s_mux_out_b          : std_logic_vector (REG_SIZE-1  downto 0);
signal s_mux_out_c          : std_logic_vector (REG_SIZE-1  downto 0);

signal partial_full_mux_out_a : std_logic_vector (95          downto 0);
signal partial_full_mux_out_b : std_logic_vector (95          downto 0);
signal partial_full_mux_out_c : std_logic_vector (95          downto 0);

signal partial_out_a        : std_logic_vector (95          downto 0);
signal partial_out_b        : std_logic_vector (95          downto 0);
signal partial_out_c        : std_logic_vector (95          downto 0);

signal bdo_masked_out_a     : std_logic_vector (CCW-1       downto 0);
signal bdo_masked_out_b     : std_logic_vector (CCW-1       downto 0);
signal bdo_masked_out_c     : std_logic_vector (CCW-1       downto 0);

signal bdo_masked_a         : std_logic_vector (CCW-1       downto 0);
signal bdo_masked_b         : std_logic_vector (CCW-1       downto 0);
signal bdo_masked_c         : std_logic_vector (CCW-1       downto 0);

signal in_xor_out_a         : std_logic_vector (CCW-1       downto 0);
signal in_xor_out_b         : std_logic_vector (CCW-1       downto 0);
signal in_xor_out_c         : std_logic_vector (CCW-1       downto 0);

signal m_mux_out_a          : std_logic_vector (CCW-1       downto 0);
signal m_mux_out_b          : std_logic_vector (CCW-1       downto 0);
signal m_mux_out_c          : std_logic_vector (CCW-1       downto 0);

signal bdo_out_a            : std_logic_vector (CCW-1       downto 0);
signal bdo_out_b            : std_logic_vector (CCW-1       downto 0);
signal bdo_out_c            : std_logic_vector (CCW-1       downto 0);

signal tag_out_a            : std_logic_vector (CCW-1       downto 0);
signal tag_out_b            : std_logic_vector (CCW-1       downto 0);
signal tag_out_c            : std_logic_vector (CCW-1       downto 0);

signal bdi_swapped_a        : std_logic_vector (CCW-1       downto 0);
signal bdi_swapped_b        : std_logic_vector (CCW-1       downto 0);
signal bdi_swapped_c        : std_logic_vector (CCW-1       downto 0);

signal bdo_swapped_a        : std_logic_vector (CCW-1       downto 0);
signal bdo_swapped_b        : std_logic_vector (CCW-1       downto 0);
signal bdo_swapped_c        : std_logic_vector (CCW-1       downto 0);

signal tag_swapped_a        : std_logic_vector (CCSW-1      downto 0);
signal tag_swapped_b        : std_logic_vector (CCSW-1      downto 0);
signal tag_swapped_c        : std_logic_vector (CCSW-1      downto 0);

signal key_swapped_a        : std_logic_vector (CCSW-1      downto 0);
signal key_swapped_b        : std_logic_vector (CCSW-1      downto 0);
signal key_swapped_c        : std_logic_vector (CCSW-1      downto 0);

signal bdo_mux_out_a        : std_logic_vector (CCW-1       downto 0); -- Select between c/m and tag
signal bdo_mux_out_b        : std_logic_vector (CCW-1       downto 0); -- Select between c/m and tag
signal bdo_mux_out_c        : std_logic_vector (CCW-1       downto 0); -- Select between c/m and tag

signal pad_mux_out_a        : std_logic_vector (CCW-1       downto 0);
signal pad_mux_out_b        : std_logic_vector (CCW-1       downto 0);
signal pad_mux_out_c        : std_logic_vector (CCW-1       downto 0);

signal tag_a                : std_logic_vector (CCW-1       downto 0);
signal tag_b                : std_logic_vector (CCW-1       downto 0);
signal tag_c                : std_logic_vector (CCW-1       downto 0);

signal full_key_a           : std_logic_vector (REG_SIZE-1  downto 0);
signal full_key_b           : std_logic_vector (REG_SIZE-1  downto 0);
signal full_key_c           : std_logic_vector (REG_SIZE-1  downto 0);

--signal for the NLFSR
signal s_a                  : std_logic_vector (REG_SIZE-1  downto 0);
signal s_b                  : std_logic_vector (REG_SIZE-1  downto 0);
signal s_c                  : std_logic_vector (REG_SIZE-1  downto 0);

signal key_array_a          : t_slv_array(3 downto 0) := (others => (others => '0'));
signal key_array_b          : t_slv_array(3 downto 0) := (others => (others => '0'));
signal key_array_c          : t_slv_array(3 downto 0) := (others => (others => '0'));

-- Keep signals -----------------------------------------------
attribute keep : string;
attribute keep of fbits_mux_out        : signal is "true";

attribute keep of s_fbits_xor_out_a    : signal is "true";
attribute keep of s_fbits_xor_out_b    : signal is "true";
attribute keep of s_fbits_xor_out_c    : signal is "true";

attribute keep of s_left_concat_out_a  : signal is "true";
attribute keep of s_left_concat_out_b  : signal is "true";
attribute keep of s_left_concat_out_c  : signal is "true";

attribute keep of s_right_concat_out_a : signal is "true";
attribute keep of s_right_concat_out_b : signal is "true";
attribute keep of s_right_concat_out_c : signal is "true";

attribute keep of s_mux_out_a          : signal is "true";
attribute keep of s_mux_out_b          : signal is "true";
attribute keep of s_mux_out_c          : signal is "true";

attribute keep of partial_full_mux_out_a : signal is "true";
attribute keep of partial_full_mux_out_b : signal is "true";
attribute keep of partial_full_mux_out_c : signal is "true";

attribute keep of partial_out_a        : signal is "true";
attribute keep of partial_out_b        : signal is "true";
attribute keep of partial_out_c        : signal is "true";

attribute keep of bdo_masked_out_a     : signal is "true";
attribute keep of bdo_masked_out_b     : signal is "true";
attribute keep of bdo_masked_out_c     : signal is "true";

attribute keep of bdo_masked_a         : signal is "true";
attribute keep of bdo_masked_b         : signal is "true";
attribute keep of bdo_masked_c         : signal is "true";

attribute keep of in_xor_out_a         : signal is "true";
attribute keep of in_xor_out_b         : signal is "true";
attribute keep of in_xor_out_c         : signal is "true";

attribute keep of m_mux_out_a          : signal is "true";
attribute keep of m_mux_out_b          : signal is "true";
attribute keep of m_mux_out_c          : signal is "true";

attribute keep of bdo_out_a            : signal is "true";
attribute keep of bdo_out_b            : signal is "true";
attribute keep of bdo_out_c            : signal is "true";

attribute keep of tag_out_a            : signal is "true";
attribute keep of tag_out_b            : signal is "true";
attribute keep of tag_out_c            : signal is "true";

attribute keep of bdi_swapped_a        : signal is "true";
attribute keep of bdi_swapped_b        : signal is "true";
attribute keep of bdi_swapped_c        : signal is "true";

attribute keep of bdo_swapped_a        : signal is "true";
attribute keep of bdo_swapped_b        : signal is "true";
attribute keep of bdo_swapped_c        : signal is "true";

attribute keep of tag_swapped_a        : signal is "true";
attribute keep of tag_swapped_b        : signal is "true";
attribute keep of tag_swapped_c        : signal is "true";

attribute keep of key_swapped_a        : signal is "true";
attribute keep of key_swapped_b        : signal is "true";
attribute keep of key_swapped_c        : signal is "true";

attribute keep of bdo_mux_out_a        : signal is "true";
attribute keep of bdo_mux_out_b        : signal is "true";
attribute keep of bdo_mux_out_c        : signal is "true";

attribute keep of pad_mux_out_a        : signal is "true";
attribute keep of pad_mux_out_b        : signal is "true";
attribute keep of pad_mux_out_c        : signal is "true";

attribute keep of tag_a                : signal is "true";
attribute keep of tag_b                : signal is "true";
attribute keep of tag_c                : signal is "true";

attribute keep of full_key_a           : signal is "true";
attribute keep of full_key_b           : signal is "true";
attribute keep of full_key_c           : signal is "true";

--attribute keep of for the NLFSR
attribute keep of s_a                  : signal is "true";
attribute keep of s_b                  : signal is "true";
attribute keep of s_c                  : signal is "true";

attribute keep of key_array_a          : signal is "true";
attribute keep of key_array_b          : signal is "true";
attribute keep of key_array_c          : signal is "true";

-- temporary signals
begin
full_key_a          <= to_slv(key_array_a);
full_key_b          <= to_slv(key_array_b);
full_key_c          <= to_slv(key_array_c);

bdi_swapped_a       <= bdi_a(7 downto 0) &
                       bdi_a(15 downto 8) &
                       bdi_a(23 downto 16) &
                       bdi_a(31 downto 24);

bdi_swapped_b       <= bdi_b(7 downto 0) &
                       bdi_b(15 downto 8) &
                       bdi_b(23 downto 16) &
                       bdi_b(31 downto 24);

bdi_swapped_c       <= bdi_c(7 downto 0) &
                       bdi_c(15 downto 8) &
                       bdi_c(23 downto 16) &
                       bdi_c(31 downto 24);

key_swapped_a       <= key_a(7 downto 0) &
                       key_a(15 downto 8) &
                       key_a(23 downto 16) &
                       key_a(31 downto 24);

key_swapped_b       <= key_b(7 downto 0) &
                       key_b(15 downto 8) &
                       key_b(23 downto 16) &
                       key_b(31 downto 24);

key_swapped_c       <= key_c(7 downto 0) &
                       key_c(15 downto 8) &
                       key_c(23 downto 16) &
                       key_c(31 downto 24);

bdo_out_a           <= s_a(95 downto 64) xor bdi_swapped_a;
bdo_out_b           <= s_b(95 downto 64) xor bdi_swapped_b;
bdo_out_c           <= s_c(95 downto 64) xor bdi_swapped_c;

bdo_swapped_a       <= bdo_out_a(7 downto 0) &
                       bdo_out_a(15 downto 8) &
                       bdo_out_a(23 downto 16) &
                       bdo_out_a(31 downto 24);

bdo_swapped_b       <= bdo_out_b(7 downto 0) &
                       bdo_out_b(15 downto 8) &
                       bdo_out_b(23 downto 16) &
                       bdo_out_b(31 downto 24);

bdo_swapped_c       <= bdo_out_c(7 downto 0) &
                       bdo_out_c(15 downto 8) &
                       bdo_out_c(23 downto 16) &
                       bdo_out_c(31 downto 24);

with partial_bdo_out select
    bdo_masked_a    <= x"000000" & bdo_out_a(7  downto 0)   when "1000",
                       x"0000"   & bdo_out_a(15 downto 0)   when "1100",
                       x"00"     & bdo_out_a(23 downto 0)   when "1110",
                       bdo_out_a(31 downto 0)               when others;

with partial_bdo_out select
    bdo_masked_b    <= x"000000" & bdo_out_b(7  downto 0)   when "1000",
                       x"0000"   & bdo_out_b(15 downto 0)   when "1100",
                       x"00"     & bdo_out_b(23 downto 0)   when "1110",
                       bdo_out_b(31 downto 0)               when others;

with partial_bdo_out select
    bdo_masked_c    <= x"000000" & bdo_out_c(7  downto 0)   when "1000",
                       x"0000"   & bdo_out_c(15 downto 0)   when "1100",
                       x"00"     & bdo_out_c(23 downto 0)   when "1110",
                       bdo_out_c(31 downto 0)               when others;

with partial_bdo_out select
    bdo_masked_out_a<= bdo_mux_out_a(31 downto 24) & x"000000"  when "1000",
                       bdo_mux_out_a(31 downto 16) & x"0000"    when "1100",
                       bdo_mux_out_a(31 downto 8)  & x"00"      when "1110",
                       bdo_mux_out_a(31 downto 0)               when others;

with partial_bdo_out select
    bdo_masked_out_b<= bdo_mux_out_b(31 downto 24) & x"000000"  when "1000",
                       bdo_mux_out_b(31 downto 16) & x"0000"    when "1100",
                       bdo_mux_out_b(31 downto 8)  & x"00"      when "1110",
                       bdo_mux_out_b(31 downto 0)               when others; 
                       
with partial_bdo_out select
    bdo_masked_out_c<= bdo_mux_out_c(31 downto 24) & x"000000"  when "1000",
                       bdo_mux_out_c(31 downto 16) & x"0000"    when "1100",
                       bdo_mux_out_c(31 downto 8)  & x"00"      when "1110",
                       bdo_mux_out_c(31 downto 0)               when others;

bdo_a               <= bdo_masked_out_a;
bdo_b               <= bdo_masked_out_b;
bdo_c               <= bdo_masked_out_c;

tag_out_a           <= s_a(95 downto 64);
tag_out_b           <= s_b(95 downto 64);
tag_out_c           <= s_c(95 downto 64);

tag_swapped_a       <= tag_out_a(7 downto 0) &
                       tag_out_a(15 downto 8) &
                       tag_out_a(23 downto 16) &
                       tag_out_a(31 downto 24);

tag_swapped_b       <= tag_out_b(7 downto 0) &
                       tag_out_b(15 downto 8) &
                       tag_out_b(23 downto 16) &
                       tag_out_b(31 downto 24);

tag_swapped_c       <= tag_out_c(7 downto 0) &
                       tag_out_c(15 downto 8) &
                       tag_out_c(23 downto 16) &
                       tag_out_c(31 downto 24);

s_fbits_xor_out_a   <= fbits_mux_out xor s_a(38 downto 36);
s_fbits_xor_out_b   <= fbits_mux_out xor s_b(38 downto 36);
s_fbits_xor_out_c   <= fbits_mux_out xor s_c(38 downto 36);

s_left_concat_out_a <= s_a(127 downto 39) & s_fbits_xor_out_a & s_a(35 downto 0);
s_left_concat_out_b <= s_b(127 downto 39) & s_fbits_xor_out_b & s_b(35 downto 0);
s_left_concat_out_c <= s_c(127 downto 39) & s_fbits_xor_out_c & s_c(35 downto 0);

in_xor_out_a        <= m_mux_out_a xor s_a(127 downto 96);
in_xor_out_b        <= m_mux_out_b xor s_b(127 downto 96);
in_xor_out_c        <= m_mux_out_c xor s_c(127 downto 96);

s_right_concat_out_a<= in_xor_out_a & partial_full_mux_out_a;
s_right_concat_out_b<= in_xor_out_b & partial_full_mux_out_b;
s_right_concat_out_c<= in_xor_out_c & partial_full_mux_out_c;

partial_out_a       <= s_a(95 downto 34) & (s_a(33 downto 32) xor partial_bytes) & s_a(31 downto 0);
partial_out_b       <= s_b(95 downto 34) & (s_b(33 downto 32) xor partial_bytes) & s_b(31 downto 0);
partial_out_c       <= s_c(95 downto 34) & (s_c(33 downto 32) xor partial_bytes) & s_c(31 downto 0);

-- Multiplexer to select which input we want to XOR with the state
with decrypt select
    m_mux_out_a     <= bdo_masked_a when '1',
                       bdi_swapped_a when others;
with decrypt select
    m_mux_out_b     <= bdo_masked_b when '1',
                       bdi_swapped_b when others;
with decrypt select
    m_mux_out_c     <= bdo_masked_c when '1',
                       bdi_swapped_c when others;

with bdo_sel select
    bdo_mux_out_a   <= tag_swapped_a when '1',
                       bdo_swapped_a when others;
with bdo_sel select
    bdo_mux_out_b   <= tag_swapped_b when '1',
                       bdo_swapped_b when others;
with bdo_sel select
    bdo_mux_out_c   <= tag_swapped_c when '1',
                       bdo_swapped_c when others;

-- Multiplexer to select which constant for FrameBits
with fbits_sel select
    fbits_mux_out   <= b"001" when "00",
                       b"011" when "01",
                       b"101" when "10",
                       b"111" when others;


-- Multiplexer to select the input of the NLFSR
with s_sel select
    s_mux_out_a     <= s_left_concat_out_a   when b"00",
                       s_right_concat_out_a  when others;
with s_sel select
    s_mux_out_b     <= s_left_concat_out_b   when b"00",
                       s_right_concat_out_b  when others;
with s_sel select
    s_mux_out_c     <= s_left_concat_out_c   when b"00",
                       s_right_concat_out_c  when others;

-- Handle partial blocks
with partial select
    partial_full_mux_out_a <= partial_out_a when '1',
                            s_a(95 downto 0) when others;
with partial select
    partial_full_mux_out_b <= partial_out_b when '1',
                            s_b(95 downto 0) when others;
with partial select
    partial_full_mux_out_c <= partial_out_c when '1',
                            s_c(95 downto 0) when others;

-- Load the key into a local array
key_load_proc : process(clk)
begin
    if rising_edge(clk) then
        if (key_load = '1') then
            key_array_a(to_integer(unsigned(key_index))) <= key_swapped_a;
            key_array_b(to_integer(unsigned(key_index))) <= key_swapped_b;
            key_array_c(to_integer(unsigned(key_index))) <= key_swapped_c;
        end if;
    end if;
end process key_load_proc;

state : entity work.ti_nlfsr 
        generic map (
            WIDTH   => 128,
            CONCURRENT => CONCURRENT
        )
        port map (
            clk     => clk,
            reset   => nlfsr_reset,
            enable  => nlfsr_en,
            key_a   => full_key_a,
            key_b   => full_key_b,
            key_c   => full_key_c,
            load    => nlfsr_load,
            input_a => s_mux_out_a,
            input_b => s_mux_out_b,
            input_c => s_mux_out_c,
            rdi_data=> rdi_data,
            output_a=> s_a,
            output_b=> s_b,
            output_c=> s_c
        );
end architecture dataflow;
