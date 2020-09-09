----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity prng_tb is

end prng_tb;

architecture behavioral of prng_tb is
constant period : time:= 8 ns;
constant M_SIZE : integer:=64;

signal clk: std_logic:='0';
signal rst: std_logic;
signal done      : std_logic;
signal key       : std_logic_vector(80 - 1 downto 0):= (others => '0');
signal iv        : std_logic_vector(80 - 1 downto 0):= (others => '0');
signal key_iv_update  : std_logic:= '0';

signal din        : std_logic_vector(M_SIZE - 1 downto 0):= (others => '0');
signal din_valid  : std_logic:= '0';
signal din_ready  : std_logic;
signal dout       : std_logic_vector(M_SIZE - 1 downto 0);
signal dout_valid : std_logic;
signal dout_ready : std_logic:= '0';

begin

clk <= not clk after period/2;


trivium_inst : entity work.trivium(behavioral)
    generic map (M_SIZE => M_SIZE)
    port map(
        clk       => clk,
        rst       => rst,
		done      => done,

        key       => key,
		iv        => iv,
        key_iv_update => key_iv_update,

		din       => din,
		din_ready => din_ready,
		din_valid => din_valid,

        dout       => dout,
        dout_ready => dout_ready,
        dout_valid => dout_valid
	);

test_process: process
begin
    key    <= x"0F62B5085BAE0154A7FA";
    iv     <= x"288FF65DC42B92F960C7";
    --din    <= x"0123456789abcdef0123456789abcdef";
    wait for period*(1/4);
	rst <= '1';
	wait for period*4;
	rst <= '0';


	key_iv_update <= '1';
	wait for period;
	key_iv_update <= '0';

	din_valid  <= '1';
    dout_ready <= '1';
	wait for period * 100;
	din_valid  <= '0';
    dout_ready <= '0';


	wait;

end process;

end behavioral;
