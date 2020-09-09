-- =====================================================================
-- Copyright © 2017-2018 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.
-- Author: Farnoud Farahmand
-- =====================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Register_s is
          generic ( N : integer := 128 ) ;
          port   (
			         d                      : in  std_logic_vector(N-1 downto 0) ;
                  reset, clock, enable   : in  std_logic ;
                  q                      : OUT std_logic_vector(N-1 DOWNTO 0)
				 );

end Register_s;

architecture behavioral of Register_s is

begin

    process (clock)
      begin
		   if rising_edge(clock) then
            if reset = '1' then
               q <= (others => '0') ;
            elsif enable= '1' then
               q <= d ;
            end if ;
		   end if ;

     end process ;

end behavioral;
