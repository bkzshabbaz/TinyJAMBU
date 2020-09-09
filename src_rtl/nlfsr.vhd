--------------------------------------------------------------------------------
--! @file       nlfsr.vhd
--! @brief      Implementation of a non-linear shift register used for TinyJAMBU
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
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

entity nlfsr is

    generic (
        WIDTH       : integer   := 128;
        CONCURRENT  : natural   := 1
    );
    port (
        clk         : in std_logic;
        reset       : in std_logic;
        enable      : in std_logic;
        key         : in std_logic_vector (WIDTH-1 downto 0);
        load        : in std_logic;
        input       : in std_logic_vector (WIDTH-1 downto 0);
        output      : out std_logic_vector (WIDTH-1 downto 0)
    );
end entity nlfsr;

architecture behavioral of nlfsr is
signal reg      : std_logic_vector (WIDTH-1 downto 0);
signal feedback : std_logic_vector (CONCURRENT-1 downto 0);
signal nand_out : std_logic_vector (CONCURRENT-1 downto 0);
signal counter  : unsigned (6 downto 0);

begin
nand_out    <= reg((70 + CONCURRENT) - 1 downto 70) nand reg((85 + CONCURRENT) - 1 downto 85);

feedback    <= reg((91 + CONCURRENT) - 1 downto 91) xor 
                nand_out xor 
                reg((47 + CONCURRENT) - 1 downto 47) xor 
                reg((0 + CONCURRENT) - 1 downto 0) xor 
                key((to_integer(counter) + CONCURRENT) - 1 downto to_integer(counter));

output      <= reg;

    shift_reg : process(clk)

    begin
        if rising_edge(clk) then
            if (reset = '1') then
                reg <= (others => '0');
                counter <= (others => '0');
            elsif (load = '1') then
                reg <= input;
                counter <= (others => '0');
            elsif (enable = '1') then
                counter <= counter + CONCURRENT;

                reg(reg'high downto (reg'high - (CONCURRENT-1))) <= feedback;
                reg((reg'high - CONCURRENT) downto 0) <= reg(reg'high downto CONCURRENT);
            end if;
        end if;

    end process shift_reg;

end architecture behavioral;
