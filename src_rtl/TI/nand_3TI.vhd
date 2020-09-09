--------------------------------------------------------------------------------
--! @file       nand_3TI.vhd
--! @brief      A three share threshold implementation protected NAND gate
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

entity nand_3TI is
    generic (
        WIDTH : integer := 32
    );
    port (
        xa, xb, xc, ya, yb, yc, rdi  : in  std_logic_vector(WIDTH-1 downto 0);
        o1, o2, o3                   : out std_logic_vector(WIDTH-1 downto 0)
    );
attribute keep : string;
attribute keep of xa, xb, xc, ya, yb, yc, o1, o2, o3 : signal is "true";

end entity nand_3TI;

architecture structural of nand_3TI is

begin

nand_a: entity work.nand_3TI_a(dataflow)
    generic map (
        WIDTH => WIDTH
    )
    port map (
        xa  => xb,
        xb  => xc,
        rdi => rdi,
        ya  => yb,
        yb  => yc,
        o   => o1
    );

nand_b: entity work.nand_3TI_b(dataflow)
    generic map (
        WIDTH => WIDTH
    )
    port map (
        xa  => xc,
        xb  => xa,
        rdi => rdi,
        ya  => yc,
        yb  => ya,
        o   => o2
    );

nand_c: entity work.nand_3TI_c(dataflow)
    generic map (
        WIDTH => WIDTH
    )
    port map (
        xa  => xa,
        xb  => xb,
        rdi => rdi,
        ya  => ya,
        yb  => yb,
        o   => o3
    );

end structural;
