----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/28/2020
-- Design Name: 
-- Module Name: sdi_sipo - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.NIST_LWAPI_pkg.all;
use work.design_pkg.all;

-- Entity
----------------------------------------------------------------------------------
entity sdi_sipo is
    Port (
        clk             : in  std_logic;
        rst             : in  std_logic;
             
        sdi_data        : in  std_logic_vector(SW-1 downto 0); -- from SDI_FIFO to SIPO
        sdi_valid       : in  std_logic; -- from SDI_FIFO to SIPO
        sdi_ready       : out std_logic; -- from SIPO to SDI_FIFO
        
        sdi_data_a      : out  std_logic_vector(SW-1 downto 0); -- from SIPO to PreProcessor
        sdi_data_b      : out  std_logic_vector(SW-1 downto 0); -- from SIPO to PreProcessor
        sdi_data_c      : out  std_logic_vector(SW-1 downto 0); -- from SIPO to PreProcessor
        sdi_sipo_valid  : out  std_logic; -- from SIPO to PreProcessor
        sdi_sipo_ready  : in   std_logic -- from PreProcessor to SIPO
    );
end sdi_sipo;

-- Architecture
----------------------------------------------------------------------------------
architecture Behavioral of sdi_sipo is

    -- Signals -------------------------------------------------------------------
    type state_type is (s_sdi_a, s_sdi_b, s_sdi_c, s_valid); 
    signal state, nx_state  : state_type;
 
    signal reg_a_en, reg_b_en, reg_c_en : std_logic;

----------------------------------------------------------------------------------
begin
      
    process (clk)
    begin
        if (rising_edge(clk)) then
            if (rst = '1')  then
                state <= s_sdi_a;
            else
                state <= nx_state;
            end if;
        end if;
    end process;
    
    process (state, sdi_data, sdi_valid, sdi_sipo_ready)
    begin
        sdi_sipo_valid  <= '0';
        reg_a_en        <= '0';
        reg_b_en        <= '0';
        reg_c_en        <= '0';
        sdi_ready       <= '0';
        case state is
            when s_sdi_a =>
                sdi_ready       <= '1';                             
                if (sdi_valid = '1') then 
                    reg_a_en    <= '1';                                   
                    nx_state    <= s_sdi_b;
                else
                    nx_state    <= s_sdi_a;
                end if;
                
            when s_sdi_b =>
                sdi_ready       <= '1';
                if (sdi_valid = '1') then
                    reg_b_en    <= '1'; 
                    nx_state    <= s_sdi_c;
                else
                    nx_state    <= s_sdi_b;
                end if;
            
            when s_sdi_c =>
                sdi_ready       <= '1';
                if (sdi_valid = '1') then
                    reg_c_en    <= '1'; 
                    nx_state    <= s_valid;
                else
                    nx_state    <= s_sdi_c;
                end if;
                
            when s_valid =>
                sdi_sipo_valid  <= '1';
                if (sdi_sipo_ready = '1') then
                    nx_state    <= s_sdi_a;
                else 
                    nx_state    <= s_valid;
                end if;
                
            when others => null;

        end case;        
    end process;
    
    reg_a: entity work.myReg
    generic map( b => W)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => reg_a_en,
        D_in    => sdi_data,
        D_out   => sdi_data_a
    );
    
    reg_b: entity work.myReg
    generic map( b => W)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => reg_b_en,
        D_in    => sdi_data,
        D_out   => sdi_data_b
    );
    
    reg_c: entity work.myReg
    generic map( b => W)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => reg_c_en,
        D_in    => sdi_data,
        D_out   => sdi_data_c
    );

end Behavioral;