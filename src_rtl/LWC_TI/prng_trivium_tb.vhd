----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity prng_trivium_tb is

end prng_trivium_tb;

architecture behavioral of prng_trivium_tb is
constant period : time:= 10 ns;
constant RW : integer:=64;
constant N: integer:=4;

signal clk: std_logic:='0';
signal rst: std_logic;
signal seed       : std_logic_vector(N*128 - 1 downto 0):= (others => '0');

signal rdi_data        : std_logic_vector(N*RW-1 downto 0):= (others => '0');
signal rdi_valid  : std_logic;
signal rdi_ready  : std_logic;
signal en_prng, reseed, reseed_ack : std_logic;

begin

clk <= not clk after period/2;

trivium_inst : entity work.prng_trivium_enhanced(structural)
    generic map (N =>N)
    port map(
		
		clk         => clk,
        rst         => rst,
		en_prng     => en_prng,
        seed        => seed,
		reseed      => reseed,
		reseed_ack  => reseed_ack,
		rdi_data    => rdi_data,
		rdi_ready   => rdi_ready,
		rdi_valid   => rdi_valid
	);

test_process: process
begin
    --seed  <= x"0123456789abcdef0123456789abcdef";
    --seed  <= x"0123456789abcdef0123456789abcdefaabbccddeeff00112233445566778899ffeeddccbbaa99887766554433221100";
    seed  <= x"0123456789abcdef0123456789abcdefaabbccddeeff00112233445566778899ffeeddccbbaa998877665544332211000123456789abcdef0123456789abcdef";
    
    rst <= '0';
    reseed <= '1';
    wait for period;
    reseed <= '0';
	en_prng <= '1';
	rdi_ready <= '1';
	wait;

end process;

end behavioral;
