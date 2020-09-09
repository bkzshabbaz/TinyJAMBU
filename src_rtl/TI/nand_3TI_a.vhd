--------------------------------------------------------------------------------
--! @file       nand_3TI_a.vhd
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

entity nand_3TI_a is
    generic (
        WIDTH : integer := 32
    );
    port (
        xa, xb, ya, yb, rdi  : in  std_logic_vector(WIDTH-1 downto 0);
        o                    : out std_logic_vector(WIDTH-1 downto 0)
    );

end entity nand_3TI_a;

architecture dataflow of nand_3TI_a is

attribute keep_hierarchy : string;
attribute keep_hierarchy of dataflow: architecture is "true";

begin

    o <= (xb and ya) xor (xa and yb) xor (xa and ya) xor (xb and rdi) xor (rdi and yb) xor rdi;

end dataflow;
