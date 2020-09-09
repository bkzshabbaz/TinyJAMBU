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

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;  
use ieee.numeric_std.all;

entity dut_fifo is
    generic (	
        G_LOG2DEPTH 		: integer := 9;         --! LOG(2) of depth
        G_W 				: integer := 64         --! Width of I/O (bits)
    );
    port (
        clk				    : in  std_logic;
        rst				    : in  std_logic;
        reinit              : in std_logic;
        write			    : in  std_logic; 
        read			    : in  std_logic;
        din 			    : in  std_logic_vector(G_W-1 downto 0);
        dout	 		    : out std_logic_vector(G_W-1 downto 0);
        almost_full         : out std_logic;
        almost_empty        : out std_logic;
        full			    : out std_logic; 
        empty 			    : out std_logic
    );
end dut_fifo;

architecture structure of dut_fifo is

	signal readpointer  	: std_logic_vector(G_LOG2DEPTH            -1 downto 0):=(OTHERS=>'0');
	signal writepointer 	: std_logic_vector(G_LOG2DEPTH            -1 downto 0):=(OTHERS=>'0');
	signal maxwritepointer 	: std_logic_vector(G_LOG2DEPTH            -1 downto 0):=(OTHERS=>'0');
	signal bytecounter  	: std_logic_vector(G_LOG2DEPTH               downto 0):=(OTHERS=>'0');
	signal maxbytecounter   : std_logic_vector(G_LOG2DEPTH               downto 0):=(OTHERS=>'0');
	signal write_s 			: std_logic:='0';
	signal full_s    	    : std_logic:='0';
	signal empty_s   	    : std_logic:='0';

    type 	mem is array (2**G_LOG2DEPTH-1 downto 0) of std_logic_vector(G_W-1 downto 0);
	signal 	memory 		    : mem;
begin		 
	
    p_fifo_ram:
    process(clk)
    begin
        if ( rising_edge(clk) ) then
            if (write_s = '1') then
                memory(to_integer(unsigned(writepointer))) <= din;
            end if;	 
            if (read = '1') then
                dout <= memory(to_integer(unsigned(readpointer)));
            end if;
        end if;
    end process; 
    
    p_fifo_ptr:
	process(clk)
	begin		
		if rising_edge( clk ) then
            if rst = '1' then                
                readpointer  <= (others => '0');
                writepointer <= (others => '0'); 
                bytecounter  <= (others => '0');  --differences (write pointer - read pointer)
            else
                if (reinit = '1') then
                    bytecounter <= maxbytecounter;
                    writepointer <= maxwritepointer;
                    readpointer <= (OTHERS => '0');             
                elsif ( write = '1' and full_s = '0' and read = '0') then
                    writepointer <= writepointer + 1;
                    maxwritepointer <= writepointer + 1;
                    bytecounter  <= bytecounter + 1;
                    maxbytecounter <= bytecounter + 1;
                elsif ( read = '1' and empty_s = '0' and write = '0') then
                    readpointer  <= readpointer + 1;
                    bytecounter  <= bytecounter - 1;
                elsif ( read = '1' and empty_s = '0' and write = '1' and full_s = '0') then
                    readpointer <= readpointer + 1;
                    writepointer <= writepointer + 1;
                    maxwritepointer <= writepointer + 1;
                elsif ( read = '1' and empty_s = '0' and write = '1' and full_s = '1') then	-- cant write
                    readpointer <= readpointer + 1;
                    bytecounter <= bytecounter - 1;
                elsif ( read = '1' and empty_s = '1' and write = '1' and full_s = '0') then -- cant read
                    writepointer <= writepointer + 1;
                    maxwritepointer <= writepointer + 1;
                    bytecounter <= bytecounter + 1;
                    maxbytecounter <= bytecounter + 1;
                end if;
            end if;
		end if;
	end process;

	empty_s         <= '1' when (bytecounter = 0) else  '0';
	full_s          <= bytecounter(G_LOG2DEPTH);
    almost_full     <= '1' when (bytecounter >= 2**G_LOG2DEPTH-1) else '0';    
	full            <= full_s;
	empty           <= empty_s;
    almost_empty    <= '1' when (bytecounter = 1) else '0';
    

	write_s <= '1' when ( write = '1' and full_s = '0') else '0';

end structure;
