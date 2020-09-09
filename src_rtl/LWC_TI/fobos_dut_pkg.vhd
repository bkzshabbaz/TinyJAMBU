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

--! Defines ceil function for FOBOS_DUT

library ieee;
use ieee.std_logic_1164.all;

package fobos_dut_pkg is

function log2_ceil (N : natural) return natural;
end fobos_dut_pkg;

package body fobos_dut_pkg is

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

end package body fobos_dut_pkg;
