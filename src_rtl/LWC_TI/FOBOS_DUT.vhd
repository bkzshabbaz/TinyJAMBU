--##############################################################################
--#                                                                            #
--#	Copyright 2018 Cryptographic Engineering Research Group (CERG)           #
--#	George Mason University							                         #	
--#   http://cryptography.gmu.edu/fobos                                        #                            
--#									                                         #
--#	Licensed under the Apache License, Version 2.0 (the "License");        	 #
--#	you may not use this file except in compliance with the License.       	 #
--#	You may obtain a copy of the License at                                	 #
--#	                                                                       	 #
--#	    http://www.apache.org/licenses/LICENSE-2.0                         	 #
--#	                                                                       	 #
--#	Unless required by applicable law or agreed to in writing, software    	 #
--#	distributed under the License is distributed on an "AS IS" BASIS,      	 #
--#	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. #
--#	See the License for the specific language governing permissions and      #
--#	limitations under the License.                                           #
--#                                                                          	 #
--##############################################################################

-- Modified 03/06/2020 by William Diehl
-- Virginia Tech Signatures Analysis Lab (SAL)

-- v4 is prototype that supports N = 4 (designed for Spartan 6 or Artix 7)
-- FOBOS_DUT(din) and FOBOS_DUT(dout) are 4 bit interfaces
-- W and SW are independently any multiple of 4
-- Supports pdi, sdi, rdi
-- Reinit fifo not supported
-- Only interface width (N=4) supported

--! Caution: W = 8, 16, 32, 64, 128 supported in prototype; DO FIFO must be modified for other cases

library ieee;
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;  
use IEEE.NUMERIC_STD.ALL;
use work.fobos_dut_pkg.all;

entity FOBOS_DUT is

generic(       
    W : integer:=32; -- pdi and do width (mulltiple of 4)
    SW: integer:=32;  -- sdi width (multiple of 4)
    RW: integer:=64 -- rdi width which will be supplied to LWC                                   
);
port(
    
	clk : in std_logic;
	rst : in std_logic;
	
	di_valid, do_ready : in std_logic;
	di_ready, do_valid : out std_logic;
    
-- data signals

	din	: in std_logic_vector(3 downto 0);
	dout : out std_logic_vector(3 downto 0)
	
	--state_debug : out std_logic_vector(7 downto 0)
	
);

end FOBOS_DUT;

architecture structural of FOBOS_DUT is

--! These constants should be adjusted by user based on maximum size of test vectors

constant PDI_FIFO_DEPTH : integer:=12; -- size of FIFOs (2^FIFO_DEPTH N-bit words)
constant SDI_FIFO_DEPTH : integer:=12; -- size of FIFOs (2^FIFO_DEPTH N-bit words) 
--constant RDI_FIFO_DEPTH : integer:=2; -- size of FIFOs (2^FIFO_DEPTH N-bit words)
constant DO_FIFO_DEPTH : integer:=12; -- size of FIFOs (2^FIFO_DEPTH N-bit words)

signal pdi_data : std_logic_vector(W-1 downto 0); 
signal rdi_data : std_logic_vector(RW-1 downto 0); 
signal sdi_data : std_logic_vector(SW-1 downto 0);
signal pdi_valid, pdi_ready, sdi_valid, sdi_ready, rdi_valid, rdi_ready : std_logic; 

signal fifo_sel, fifo_sel_reg : std_logic_vector(1 downto 0);
signal reg_sel, reg_sel_reg : std_logic_vector(3 downto 0);
signal pdi_cnt_reg_en, sdi_cnt_reg_en, rdi_cnt_reg_en, do_cnt_reg_en, cmd_reg_en : std_logic;
signal cmd_en, fifo_sel_en : std_logic;
signal pdi_cnt_reg, sdi_cnt_reg, rdi_cnt_reg, do_cnt_reg, cmd_reg : std_logic_vector(15 downto 0); 
signal next_pdi_cnt_reg, next_sdi_cnt_reg, next_rdi_cnt_reg, next_do_cnt_reg, next_cmd_reg : std_logic_vector(15 downto 0); 
signal pdi_fifo_write, pdi_fifo_read, pdi_fifo_almost_full, pdi_fifo_almost_empty, pdi_fifo_full, pdi_fifo_empty : std_logic;
signal sdi_fifo_write, sdi_fifo_read, sdi_fifo_almost_full, sdi_fifo_almost_empty, sdi_fifo_full, sdi_fifo_empty : std_logic;
signal rdi_fifo_write, rdi_fifo_read, rdi_fifo_almost_full, rdi_fifo_almost_empty, rdi_fifo_full, rdi_fifo_empty : std_logic;
signal do_fifo_write, do_fifo_read, do_fifo_almost_full, do_fifo_almost_empty, do_fifo_full, do_fifo_empty : std_logic;
signal pdi_cntr, sdi_cntr, rdi_cntr, do_cntr : std_logic_vector(15 downto 0); 
signal next_pdi_cntr, next_sdi_cntr, next_rdi_cntr, next_do_cntr : std_logic_vector(15 downto 0); 
signal pdi_fifo_finished, sdi_fifo_finished, rdi_fifo_finished, do_fifo_finished, load_fifo_finished : std_logic;
signal pdi_cntr_en, sdi_cntr_en, rdi_cntr_en, do_cntr_en, do_cntr_en_in, load_cntr_en, fifo_write : std_logic; 
signal pdi_cntr_init, sdi_cntr_init, rdi_cntr_init, do_cntr_init : std_logic;
signal is_fifo, is_fifo_reg, start : std_logic;
signal pdi_start, sdi_start, rdi_start : std_logic;
signal pdi_fifo_reinit, sdi_fifo_reinit, rdi_fifo_reinit, do_fifo_reinit : std_logic:='0';
signal result_data : std_logic_vector(W-1 downto 0);
signal result_valid, result_ready : std_logic;
signal pdi_fifo_buffer_en, sdi_fifo_buffer_en, rdi_fifo_buffer_en, fifo_buffer_en : std_logic;
signal next_pdi_fifo_buffer, pdi_fifo_buffer, do_fifo_buffer : std_logic_vector(W-1 downto 0);
signal next_sdi_fifo_buffer, sdi_fifo_buffer : std_logic_vector(SW-1 downto 0);
signal next_rdi_fifo_buffer, rdi_fifo_buffer : std_logic_vector(W-1 downto 0);

signal reg_0_en, reg_1_en, reg_2_en, reg_3_en : std_logic;
signal in_reg_0, in_reg_1, in_reg_2 : std_logic_vector(3 downto 0);
signal input : std_logic_vector(15 downto 0); -- command words are 16 bits
signal output : std_logic_vector(W-1 downto 0);
signal pdi_ld_cnt_en, sdi_ld_cnt_en, rdi_ld_cnt_en, do_rd_cnt_en, do_rd_cnt_empty : std_logic;
signal fifo_ld_cnt_full, pdi_ld_cnt_full, sdi_ld_cnt_full, rdi_ld_cnt_full : std_logic;
signal next_pdi_ld_cnt, pdi_ld_cnt, next_rdi_ld_cnt, rdi_ld_cnt : std_logic_vector(log2_ceil(W/4)-1 downto 0);
signal next_sdi_ld_cnt, sdi_ld_cnt : std_logic_vector(log2_ceil(SW/4)-1 downto 0);
signal next_do_rd_cnt, do_rd_cnt : std_logic_vector(log2_ceil(W/4)-1 downto 0);
signal ld_cnt_init, rd_cnt_init : std_logic;

-- embedded random number generator
constant RSEEDLEN : integer:=RW*2; -- assumed to be width of random data * 2
signal rnd_reg : std_logic_vector(RSEEDLEN - 1 downto 0); -- random seed
signal rnd_init : std_logic:='0';

begin

-- FOBOS Protocol
-- W-bit words 
-- Byte 1 (MSB: Not used)
-- Byte 1 (LSB: 11000000 PDI FIFO
--              11000001 SDI FIFO
--              11000010 RDI FIFO
--              11100000 DO (Status) - not yet supported
--              10000001 Expected Output Size register
--              10000000 Command register
--! Caution: "Reinit" commands not yet supported
--! Until supported, the complete expected pdi and sdi contents must be transmitted to FOBOS DUT for each trace

-- insert victim algorithm here

victim: entity work.LWC(structure)

-- Choices for W and SW are independently any multiple of 4, defined in generics above

port map(
	clk => clk,
	rst => start,  --! The FOBOS_DUT start signal meets requirements for synchronous resets used in 
		       --! CAESAR or LWC HW Development Packages

-- data signals

	pdi_data  => pdi_data,
	pdi_valid => pdi_valid,
	pdi_ready => pdi_ready,

    sdi_data => sdi_data,
	sdi_valid => sdi_valid,
	sdi_ready => sdi_ready,

	do_data => result_data,
	do_ready => result_ready,
	do_valid => result_valid,

----! if rdi_interface for side-channel protected versions is required, uncomment the rdi interface
   rdi_data => rdi_data,
   rdi_ready => open, --rdi_ready, not required in this implementation
   rdi_valid => rdi_valid

    --state_debug => state_debug

);

in_rg0: entity work.dut_regn(behavioral)
    generic map(N=> 4)
    port map(
        clk => clk,
        rst => rst,
        en => reg_0_en,
        d => din,
        q => in_reg_0
        );

in_rg1: entity work.dut_regn(behavioral)
    generic map(N=> 4)
    port map(
        clk => clk,
        rst => rst,
        en => reg_1_en,
        d => din,
        q => in_reg_1
        );

in_rg2: entity work.dut_regn(behavioral)
    generic map(N=> 4)
    port map(
        clk => clk,
        rst => rst,
        en => reg_2_en,
        d => din,
        q => in_reg_2
        );

input <= in_reg_0 & in_reg_1 & in_reg_2 & din;

reg_sel <= input(7 downto 6) & input(1 downto 0);

-- Currently supports only 16 possible register and FIFO combinations; can be expanded

reg_sel_rg: entity work.dut_regn(behavioral)
    generic map(N=> 4)
    port map(
        clk => clk,
        rst => rst,
        en => cmd_en,
        d => reg_sel,
        q => reg_sel_reg
        );

-- see "reg_sel" and "FOBOS Protocol" for meaning of reg_sel_reg

pdi_cnt_reg_en <= '1' when (reg_3_en = '1' and reg_sel_reg = "1100") else '0';
sdi_cnt_reg_en <= '1' when (reg_3_en = '1' and reg_sel_reg = "1101") else '0';
rdi_cnt_reg_en <= '1' when (reg_3_en = '1' and reg_sel_reg = "1110") else '0';
do_cnt_reg_en <= '1' when (reg_3_en = '1' and reg_sel_reg = "1001") else '0';
cmd_reg_en <= '1' when ((cmd_en = '1' and reg_sel_reg = "1000") or (start = '1')) else '0';

fifo_sel <= input(1 downto 0);
is_fifo <= input(6); -- used by FSM decision logic

str_fifo_rg: entity work.dut_reg1(behavioral)
    port map(
        clk => clk,
        en => cmd_en,
        d => is_fifo,
        q => is_fifo_reg
        );

-- datapath and FSM need to know which FIFO is selected for loading
-- only one FIFO can load at a time

fifo_sel_rg: entity work.dut_regn(behavioral)
    generic map(N=> 2)
    port map(
        clk => clk,
        rst => rst,
        en => cmd_en,
        d => fifo_sel,
        q => fifo_sel_reg
        );

-- FIFO expected count registers
-- Stores the number of W-bit WORDS that the FIFO should expect
--! Since FOBOS protocol specifies length in bytes, the number of expected bytes should be converted
--! to number of expected words

next_pdi_cnt_reg <=  std_logic_vector(to_unsigned(conv_integer(input),16)/(W/8));
next_sdi_cnt_reg <= std_logic_vector(to_unsigned(conv_integer(input),16)/(SW/8));
next_rdi_cnt_reg <= std_logic_vector(to_unsigned(conv_integer(input),16)/(W/8));
next_do_cnt_reg <= std_logic_vector(to_unsigned(conv_integer(input),16)/(W/8));

next_cmd_reg <= (OTHERS => '0') when (start = '1') else input;

pdi_cnt_rg: entity work.dut_regn(behavioral)
    generic map(N=> 16)
    port map(
        clk => clk,
        rst => rst,
        en => pdi_cnt_reg_en,
        d => next_pdi_cnt_reg,
        q => pdi_cnt_reg
        );
            
sdi_cnt_rg: entity work.dut_regn(behavioral)
    generic map(N=> 16)
    port map(
        clk => clk,
        rst => rst,
        en => sdi_cnt_reg_en,
        d => next_sdi_cnt_reg,
        q => sdi_cnt_reg
        );

rdi_cnt_rg: entity work.dut_regn(behavioral)
    generic map(N=> 16)
    port map(
        clk => clk,
        rst => rst,
        en => rdi_cnt_reg_en,
        d => next_rdi_cnt_reg,
        q => rdi_cnt_reg
        );

do_cnt_rg: entity work.dut_regn(behavioral)
    generic map(N=> 16)
    port map(
        clk => clk,
        rst => rst,
        en => do_cnt_reg_en,
        d => next_do_cnt_reg,
        q => do_cnt_reg
        );

cmd_rg: entity work.dut_regn(behavioral)
    generic map(N=> 16)
    port map(
        clk => clk,
        rst => rst,
        en => cmd_reg_en,
        d => next_cmd_reg,
        q => cmd_reg
        );

start <= cmd_reg(0);
pdi_start <= start; -- FSM currently driven on pdi_start
sdi_start <= start; -- sdi_start should occur simultaneously (a staggered start is not currently supported in controller)
rdi_start <= start; -- rdi_start should occur simultaneously 

-- FIFO counter registers
-- contains the number of W-bit WORDS that the FIFO has currently received 
-- pdi, sdi, and rdi received from FOBOS CONTROL
-- do received from victim algorithm

next_pdi_cntr <= (OTHERS => '0') when (pdi_cntr_init = '1') else (pdi_cntr + 1);        
next_sdi_cntr <= (OTHERS => '0') when (sdi_cntr_init = '1') else (sdi_cntr + 1);
next_rdi_cntr <= (OTHERS => '0') when (rdi_cntr_init = '1') else (rdi_cntr + 1);
next_do_cntr <= (OTHERS => '0') when (do_cntr_init = '1') else (do_cntr + 1);

pdi_cntr_en <= '1' when (pdi_cntr_init = '1' or (load_cntr_en = '1' and fifo_sel_reg = "00")) else '0';
sdi_cntr_en <= '1' when (sdi_cntr_init = '1' or (load_cntr_en = '1' and fifo_sel_reg = "01")) else '0';
rdi_cntr_en <= '1' when (rdi_cntr_init = '1' or (load_cntr_en = '1' and fifo_sel_reg = "10")) else '0';
do_cntr_en <= do_cntr_en_in or do_cntr_init;

pdi_cntr_rg: entity work.dut_regn(behavioral)
    generic map(N=> 16)
    port map(
        clk => clk,
        rst => rst,
        en => pdi_cntr_en,
        d => next_pdi_cntr,
        q => pdi_cntr
        );

sdi_cntr_rg: entity work.dut_regn(behavioral)
    generic map(N=> 16)
    port map(
        clk => clk,
        rst => rst,
        en => sdi_cntr_en,
        d => next_sdi_cntr,
        q => sdi_cntr
        );

rdi_cntr_rg: entity work.dut_regn(behavioral)
    generic map(N=> 16)
    port map(
        clk => clk,
        rst => rst,
        en => rdi_cntr_en,
        d => next_rdi_cntr,
        q => rdi_cntr
        );

do_cntr_rg: entity work.dut_regn(behavioral)
    generic map(N=> 16)
    port map(
        clk => clk,
        rst => rst,
        en => do_cntr_en,
        d => next_do_cntr,
        q => do_cntr
        );

-- Only one fifo_write signal comes from FSM; the below decoder selects the correct FIFO

pdi_fifo_write <= '1' when (fifo_write = '1' and fifo_sel_reg = "00") else '0';
sdi_fifo_write <= '1' when (fifo_write = '1' and fifo_sel_reg = "01") else '0';
rdi_fifo_write <= '1' when (fifo_write = '1' and fifo_sel_reg = "10") else '0';

pdi_fifo_buffer_en <= '1' when (fifo_buffer_en = '1' and fifo_sel_reg = "00") else '0';
sdi_fifo_buffer_en <= '1' when (fifo_buffer_en = '1' and fifo_sel_reg = "01") else '0';
rdi_fifo_buffer_en <= '1' when (fifo_buffer_en = '1' and fifo_sel_reg = "10") else '0';

pdi_ld_cnt_en <= pdi_fifo_buffer_en;
sdi_ld_cnt_en <= sdi_fifo_buffer_en;
rdi_ld_cnt_en <= rdi_fifo_buffer_en;

-- "fifo_finished" signals are asserted when word length matches what it has been told to expect

pdi_fifo_finished <= '1' when (pdi_cntr = pdi_cnt_reg) else '0';
sdi_fifo_finished <= '1' when (sdi_cntr = sdi_cnt_reg) else '0';
rdi_fifo_finished <= '1' when (rdi_cntr = rdi_cnt_reg) else '0';
do_fifo_finished <= '1' when (do_cntr = do_cnt_reg) else '0';

-- there is only one FSM in the controller to load FIFOs, since only one set of data can be sent
-- from FOBOS CONTROL at a time.  Therefore, the status signal must be selected to match the FIFO in use

with fifo_sel_reg select
    load_fifo_finished <= pdi_fifo_finished when "00",
                          sdi_fifo_finished when "01",
                          rdi_fifo_finished when "10",
                          pdi_fifo_finished when others;
								  
with fifo_sel_reg select
    fifo_ld_cnt_full <=   pdi_ld_cnt_full when "00",
                          sdi_ld_cnt_full when "01",
                          rdi_ld_cnt_full when "10",
                          pdi_ld_cnt_full when others;
								  
-- pdi_fifo
-- reinit function not yet supported

pdi_ld_cntr: entity work.dut_regn(behavioral)
	 generic map( N => log2_ceil(W/4))
	 port map(
		 clk => clk,
		 rst => rst,
		 en => pdi_ld_cnt_en,
		 d => next_pdi_ld_cnt,
		 q => pdi_ld_cnt
		 );
		 
next_pdi_ld_cnt <= (others => '0') when (ld_cnt_init = '1') else pdi_ld_cnt + 1;
pdi_ld_cnt_full <= '1' when (pdi_ld_cnt = (W/4)-1) else '0';

pdi_fifo : entity work.fifo2 (rtl)
          generic map (
            g_WIDTH => W,
            g_DEPTH => 2**PDI_FIFO_DEPTH
            )
          port map(
            i_rst_sync => rst,
            i_clk      => clk,
         
            -- FIFO Write Interface
            i_wr_en   => pdi_fifo_write,
            i_wr_data => next_pdi_fifo_buffer,
            o_full    => pdi_fifo_full,
         
            -- FIFO Read Interface
            i_rd_en   => pdi_fifo_read,
            o_rd_data => pdi_data,
            o_empty   => pdi_fifo_empty
            );

pdi_buffer_rg: entity work.dut_regn(behavioral)
    generic map(N=> W)
    port map(
        clk => clk,
        rst => rst,
        en => pdi_fifo_buffer_en,
        d => next_pdi_fifo_buffer,
        q => pdi_fifo_buffer
        );

next_pdi_fifo_buffer <= pdi_fifo_buffer(W - 4 - 1 downto 0) & din;

rdi_ld_cntr: entity work.dut_regn(behavioral)
	 generic map( N => log2_ceil(W/4))
	 port map(
		 clk => clk,
		 rst => rst,
		 en => rdi_ld_cnt_en,
		 d => next_rdi_ld_cnt,
		 q => rdi_ld_cnt
		 );
		 
next_rdi_ld_cnt <= (others => '0') when (ld_cnt_init = '1') else rdi_ld_cnt + 1;
rdi_ld_cnt_full <= '1' when (rdi_ld_cnt = (W/4)-1) else '0';

--! Trivium-based PRNG

rndnumgen: entity work.prng_trivium_enhanced(structural)
     generic map(N => 1) -- number of Trivium instances, which provides 64 random bits per instance up to N = 4
     port map(
     clk => clk,
     rst => rst,
     en_prng => '1',
     seed => rnd_reg,
     reseed => rnd_init,
     reseed_ack => open,
     rdi_data => rdi_data,
     rdi_valid => rdi_valid,
     rdi_ready => '1' -- assumed that PRNG will provide random bits on every clock cycle in current version
     );
     
-- rseed write process

process(clk)

begin
	if (rising_edge(clk)) then
		if (rdi_fifo_buffer_en = '1') then
			rnd_reg <= rnd_reg(RSEEDLEN - 4 - 1 downto 0) & din;
		end if;
	end if;
end process;

-- sdi_fifo
-- reinit function not yet supported

sdi_ld_cntr: entity work.dut_regn(behavioral)
	 generic map( N => log2_ceil(SW/4))
	 port map(
		 clk => clk,
		 rst => rst,
		 en => sdi_ld_cnt_en,
		 d => next_sdi_ld_cnt,
		 q => sdi_ld_cnt
		 );
		 
next_sdi_ld_cnt <= (others => '0') when (ld_cnt_init = '1') else sdi_ld_cnt + 1;
sdi_ld_cnt_full <= '1' when (sdi_ld_cnt = (SW/4)-1) else '0';

sdi_fifo : entity work.fifo2 (rtl)
          generic map (
            g_WIDTH => SW,
            g_DEPTH => 2**SDI_FIFO_DEPTH
            )
          port map(
            i_rst_sync => rst,
            i_clk      => clk,
         
            -- FIFO Write Interface
            i_wr_en   => sdi_fifo_write,
            i_wr_data => next_sdi_fifo_buffer,
            o_full    => sdi_fifo_full,
         
            -- FIFO Read Interface
            i_rd_en   => sdi_fifo_read,
            o_rd_data => sdi_data,
            o_empty   => sdi_fifo_empty
            );
            
sdi_buffer_rg: entity work.dut_regn(behavioral)
    generic map(N=> SW)
    port map(
        clk => clk,
        rst => rst,
        en => sdi_fifo_buffer_en,
        d => next_sdi_fifo_buffer,
        q => sdi_fifo_buffer
        );

next_sdi_fifo_buffer <= sdi_fifo_buffer(SW - 4 - 1 downto 0) & din;

-- do_fifo
-- reinit function not yet supported

do_rd_cntr: entity work.dut_regn(behavioral)
	 generic map( N => log2_ceil(W/4))
	 port map(
		 clk => clk,
		 rst => rst,
		 en => do_rd_cnt_en,
		 d => next_do_rd_cnt,
		 q => do_rd_cnt
		 );
		 
next_do_rd_cnt <= (others => '0') when (rd_cnt_init = '1') else do_rd_cnt + 1;
do_rd_cnt_empty <= '1' when (do_rd_cnt = (W/4)-1) else '0';

do_fifo : entity work.fifo2 (rtl)
          generic map (
            g_WIDTH => W,
            g_DEPTH => 2**DO_FIFO_DEPTH
            )
          port map(
            i_rst_sync => rst,
            i_clk      => clk,
         
            -- FIFO Write Interface
            i_wr_en   => do_fifo_write,
            i_wr_data => result_data,
            o_full    => do_fifo_full,
         
            -- FIFO Read Interface
            i_rd_en   => do_fifo_read,
            o_rd_data => output,
            o_empty   => do_fifo_empty
            );

do_w8: if (W = 8) generate

with do_rd_cnt select
	dout <= output(7 downto 4) when "0",
		     output(3 downto 0) when "1",
			  (others => '0') when others;
        
end generate do_w8;

do_w16: if (W = 16) generate

with do_rd_cnt select
	dout <= output(15 downto 12) when "00",
			  output(11 downto 8) when "01",
           output(7 downto 4) when "10",
           output(3 downto 0) when "11",
           (others => '0') when others;
        
end generate do_w16;     

do_w32: if (W = 32) generate

with do_rd_cnt select
	dout <= output(31 downto 28) when "000",
			  output(27 downto 24) when "001",
			  output(23 downto 20) when "010",
           output(19 downto 16) when "011",			  
           output(15 downto 12) when "100",
			  output(11 downto 8) when "101",
           output(7 downto 4) when "110",
           output(3 downto 0) when "111",
           (others => '0') when others;
        
end generate do_w32;        

do_w64: if (W = 64) generate

with do_rd_cnt select
   dout <= output(63 downto 60) when x"0",
			  output(59 downto 56) when x"1",
			  output(55 downto 52) when x"2",
           output(51 downto 48) when x"3",			  
           output(47 downto 44) when x"4",
			  output(43 downto 40) when x"5",
           output(39 downto 36) when x"6",
           output(35 downto 32) when x"7",
	        output(31 downto 28) when x"8",
			  output(27 downto 24) when x"9",
			  output(23 downto 20) when x"a",
           output(19 downto 16) when x"b",			  
           output(15 downto 12) when x"c",
			  output(11 downto 8) when x"d",
           output(7 downto 4) when x"e",
           output(3 downto 0) when x"f",
           (others => '0') when others;
        
end generate do_w64;          

do_w128: if (W = 128) generate

with do_rd_cnt select
   dout <= output(127 downto 124) when "00000",
           output(123 downto 120) when "00001",
           output(119 downto 116) when "00010",
           output(115 downto 112) when "00011",              
           output(111 downto 108) when "00100",
           output(107 downto 104) when "00101",
           output(103 downto 100) when "00110",
           output(99 downto 96) when "00111",
           output(95 downto 92) when "01000",
           output(91 downto 88) when "01001",
           output(87 downto 84) when "01010",
           output(83 downto 80) when "01011",              
           output(79 downto 76) when "01100",
           output(75 downto 72) when "01101",
           output(71 downto 68) when "01110",
           output(67 downto 64) when "01111",
           output(63 downto 60) when "10000",
           output(59 downto 56) when "10001",
	   output(55 downto 52) when "10010",
           output(51 downto 48) when "10011",			  
           output(47 downto 44) when "10100",
	   output(43 downto 40) when "10101",
           output(39 downto 36) when "10110",
           output(35 downto 32) when "10111",
	   output(31 downto 28) when "11000",
	   output(27 downto 24) when "11001",
	   output(23 downto 20) when "11010",
           output(19 downto 16) when "11011",			  
           output(15 downto 12) when "11100",
	   output(11 downto 8) when "11101",
           output(7 downto 4) when "11110",
           output(3 downto 0) when "11111",
           (others => '0') when others;
        
end generate do_w128;          

fobos_ctrl: entity work.fobos_controller(behavioral)
    port map(

    clk => clk,
    rst => rst,
    is_fifo => is_fifo_reg,
    di_valid => di_valid,
    di_ready => di_ready,
    do_valid => do_valid,
    do_ready => do_ready,    
    result_valid => result_valid,
    result_ready => result_ready,
    
    load_fifo_finished => load_fifo_finished,
    pdi_fifo_empty => pdi_fifo_empty,
    pdi_ready => pdi_ready,
    pdi_start => pdi_start,
    rdi_fifo_empty => rdi_fifo_empty,
    rdi_ready => '0', -- rdi process disabled
    rdi_start => rdi_start,
    sdi_start => sdi_start,
    sdi_fifo_empty => sdi_fifo_empty,
    sdi_ready => sdi_ready,
    do_finished => do_fifo_finished,
    do_fifo_empty => do_fifo_empty,
    do_rd_cnt_empty => do_rd_cnt_empty,
    do_rd_cnt_en => do_rd_cnt_en,
    ld_cnt_full => fifo_ld_cnt_full,
    reg_0_en => reg_0_en,
    reg_1_en => reg_1_en,
    reg_2_en => reg_2_en,
    reg_3_en => reg_3_en,
    cmd_en => cmd_en,
    fifo_write => fifo_write,
    load_cntr => load_cntr_en,
    pdi_fifo_read => pdi_fifo_read,
    pdi_valid => pdi_valid,
    pdi_cntr_init => pdi_cntr_init,
    rdi_fifo_read => rdi_fifo_read,
    rdi_valid => open, -- process disabled
    rdi_cntr_init => rdi_cntr_init,
    sdi_fifo_read => sdi_fifo_read,
    sdi_valid => sdi_valid,
    sdi_cntr_init => sdi_cntr_init,
    do_fifo_write => do_fifo_write,
    do_fifo_read => do_fifo_read,
    do_cntr => do_cntr_en_in,
    do_cntr_init => do_cntr_init,
    fifo_buffer_en => fifo_buffer_en,
    ld_cnt_init => ld_cnt_init,
    rd_cnt_init => rd_cnt_init,
    rnd_init => rnd_init
	
    );

end structural;
