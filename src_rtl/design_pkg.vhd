--------------------------------------------------------------------------------
--! @file       design_pkg.vhd
--! @brief      Package for CryptoCore
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

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package Design_pkg is

    --! design parameters needed by the PreProcessor, PostProcessor, and LWC; assigned in the package body below!

    constant TAG_SIZE        : integer; --! Tag size
    constant HASH_VALUE_SIZE : integer; --! Hash value size

    constant CCSW            : integer; --! Internal key width. If SW = 8 or 16, CCSW = SW. If SW=32, CCSW = 8, 16, or 32.
    constant CCW             : integer; --! Internal data width. If W = 8 or 16, CCW = W. If W=32, CCW = 8, 16, or 32.
    constant CCWdiv8         : integer; --! derived from the parameters above, assigned in the package body below.

    constant CONCURRENT      : integer; --! This value specifies how many bits in the NLFSR to process concurrently,
                                        --! Valid settings: 1, 2, 4, 8, 16, 32
    constant RW              : integer; --! This variable is used for random values (protected LWC)

    --! design parameters specific to the CryptoCore; assigned in the package body below!
    --! place declarations of your types here
    type t_slv_array is array (integer range <>) of std_logic_vector (31 downto 0);

    --! place declarations of your constants here

    --! place declarations of your functions here
    function to_slv(slvv : t_slv_array) return std_logic_vector;    

end Design_pkg;

package body Design_pkg is

    --! assign values to all constants and aliases here
    constant TAG_SIZE           : integer := 64;
    constant HASH_VALUE_SIZE    : integer := 256; -- WE DO NOT SUPPORT HASHING
    constant CCSW               : integer := 32;
    constant CCW                : integer := 32;
    constant CCWdiv8            : integer := CCW/8;
    constant CONCURRENT         : integer := 32;  -- Valid values: 1, 2, 4, 8, 16, 32
    constant RW                 : integer := 32; -- Used for protected LWC

    --! define your functions here
    function to_slv(slvv : t_slv_array) return std_logic_vector is
    variable slv : std_logic_vector((slvv'length * 32) - 1 downto 0);
    begin
        for i in slvv'range loop
            slv((i * 32) + 31 downto (i * 32))      := slvv(i);
        end loop;
        return slv;
    end function;
end package body Design_pkg;

