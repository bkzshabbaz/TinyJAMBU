library ieee;
use ieee.std_logic_1164.all;

package ksa_pkg is

type pg_row_type is array (0 to 31) of std_logic;
--type pg_array_type is array (0 to 5) of pg_row_type;
type pg_array_type is array (0 to 5) of std_logic_vector(0 to 31);

function log2_ceil (N : natural) return natural;
end ksa_pkg;

package body ksa_pkg is

function log2_ceil(N: natural) return natural is
    begin
        if (N=0) then
            return 0;
        elsif N <=2 then
            return 1;
        else 
            if (N mod 2 = 0) then
                  return 1 + log2_ceil(N/2);
            else
                  return 1 + log2_ceil((N+1)/2);
            end if;
        end if;
     end function log2_ceil;

end package body ksa_pkg;
