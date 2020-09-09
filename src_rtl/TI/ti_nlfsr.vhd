--------------------------------------------------------------------------------
--! @file       ti_nlfsr.vhd
--! @brief      A three share threshold implementation of TinyJAMBU's NLFSR
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

entity ti_nlfsr is

    generic (
        WIDTH       : integer := 128;
        CONCURRENT  : natural := 32
    );
    port (
        clk         : in std_logic;
        reset       : in std_logic;
        enable      : in std_logic;
        key_a       : in std_logic_vector (WIDTH-1 downto 0);
        key_b       : in std_logic_vector (WIDTH-1 downto 0);
        key_c       : in std_logic_vector (WIDTH-1 downto 0);
        load        : in std_logic;
        input_a     : in std_logic_vector (WIDTH-1 downto 0);
        input_b     : in std_logic_vector (WIDTH-1 downto 0);
        input_c     : in std_logic_vector (WIDTH-1 downto 0);
        rdi_data    : in std_logic_vector (RW -1 downto 0);
        output_a    : out std_logic_vector (WIDTH-1 downto 0);
        output_b    : out std_logic_vector (WIDTH-1 downto 0);
        output_c    : out std_logic_vector (WIDTH-1 downto 0)
    );
attribute keep : string;
attribute keep of key_a, key_b, key_c, input_a, input_b, input_c, output_a, output_b, output_c : signal is "true";
end entity ti_nlfsr;

architecture behavioral of ti_nlfsr is
attribute keep_hierarchy : string;
attribute keep_hierarchy of behavioral: architecture is "true";

signal reg_a        : std_logic_vector (WIDTH-1 downto 0);
signal reg_b        : std_logic_vector (WIDTH-1 downto 0);
signal reg_c        : std_logic_vector (WIDTH-1 downto 0);
signal feedback_a   : std_logic_vector (CONCURRENT-1 downto 0);
signal feedback_b   : std_logic_vector (CONCURRENT-1 downto 0);
signal feedback_c   : std_logic_vector (CONCURRENT-1 downto 0);
signal nand_out_a   : std_logic_vector (CONCURRENT-1 downto 0);
signal nand_out_b   : std_logic_vector (CONCURRENT-1 downto 0);
signal nand_out_c   : std_logic_vector (CONCURRENT-1 downto 0);
signal rdi          : std_logic_vector (RW -1 downto 0);
signal counter      : unsigned (6 downto 0);
begin

    rdi <= rdi_data;

    feedback_a  <= reg_a((91 + CONCURRENT) - 1 downto 91) xor
                    nand_out_a xor
                    reg_a((47 + CONCURRENT) - 1 downto 47) xor
                    reg_a((0 + CONCURRENT) -1 downto 0) xor
                    key_a((to_integer(counter) + CONCURRENT) -1 downto to_integer(counter));

    feedback_b  <= reg_b((91 + CONCURRENT) - 1 downto 91) xor
                    nand_out_b xor
                    reg_b((47 + CONCURRENT) - 1 downto 47) xor
                    reg_b((0 + CONCURRENT) -1 downto 0) xor
                    key_b((to_integer(counter) + CONCURRENT) -1 downto to_integer(counter));

    feedback_c  <= reg_c((91 + CONCURRENT) - 1 downto 91) xor
                    nand_out_c xor
                    reg_c((47 + CONCURRENT) - 1 downto 47) xor
                    reg_c((0 + CONCURRENT) -1 downto 0) xor
                    key_c((to_integer(counter) + CONCURRENT) -1 downto to_integer(counter));

    output_a    <= reg_a;
    output_b    <= reg_b;
    output_c    <= reg_c;

    ti_nand : entity work.nand_3TI
                generic map (
                    WIDTH   => CONCURRENT
                )
                port map (
                    xa   => reg_a((70 + CONCURRENT) - 1 downto 70),
                    xb   => reg_b((70 + CONCURRENT) - 1 downto 70),
                    xc   => reg_c((70 + CONCURRENT) - 1 downto 70),
                    ya   => reg_a((85 + CONCURRENT) - 1 downto 85),
                    yb   => reg_b((85 + CONCURRENT) - 1 downto 85),
                    yc   => reg_c((85 + CONCURRENT) - 1 downto 85),
                    rdi    => rdi,
                    o1   => nand_out_a,
                    o2   => nand_out_b,
                    o3   => nand_out_c
                );

    shift_reg : process(clk)

    begin
        if rising_edge(clk) then
            if (reset = '1') then
                reg_a <= (others => '0');
                reg_b <= (others => '0');
                reg_c <= (others => '0');
                counter <= (others => '0');
            elsif (load = '1') then
                reg_a <= input_a;
                reg_b <= input_b;
                reg_c <= input_c;
                counter <= (others => '0');
            elsif (enable = '1') then
                counter <= counter + CONCURRENT;

                reg_a(reg_a'high downto (reg_a'high - (CONCURRENT-1))) <= feedback_a;
                reg_a((reg_a'high - CONCURRENT) downto 0) <= reg_a(reg_a'high downto CONCURRENT);

                reg_b(reg_b'high downto (reg_b'high - (CONCURRENT-1))) <= feedback_b;
                reg_b((reg_b'high - CONCURRENT) downto 0) <= reg_b(reg_b'high downto CONCURRENT);

                reg_c(reg_c'high downto (reg_c'high - (CONCURRENT-1))) <= feedback_c;
                reg_c((reg_c'high - CONCURRENT) downto 0) <= reg_c(reg_c'high downto CONCURRENT);
            end if;
        end if;

    end process shift_reg;

end architecture behavioral;
