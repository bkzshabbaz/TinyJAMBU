----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/27/2020
-- Design Name: 
-- Module Name: pdi_sipo - Behavioral
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
entity pdi_sipo is
    Port (
        clk             : in  std_logic;
        rst             : in  std_logic;
             
        pdi_data        : in  std_logic_vector(W-1 downto 0); -- from TB FIFO to SIPO
        pdi_valid       : in  std_logic; -- from TB FIFO to SIPO
        pdi_ready       : out std_logic; -- from SIPO to TB FIFO 
        
        pdi_data_a      : out  std_logic_vector(W-1 downto 0); -- from SIPO to PreProcessor
        pdi_data_b      : out  std_logic_vector(W-1 downto 0); -- from SIPO to PreProcessor
        pdi_data_c      : out  std_logic_vector(W-1 downto 0); -- from SIPO to PreProcessor
        pdi_sipo_valid  : out  std_logic; -- from SIPO to PreProcessor
        pdi_sipo_ready  : in   std_logic -- from PreProcessor to SIPO
    );
end pdi_sipo;

-- Architecture
----------------------------------------------------------------------------------
architecture Behavioral of pdi_sipo is

    -- Signals -------------------------------------------------------------------
    type state_type is (s_pdi_a, s_pdi_b, s_pdi_c, s_valid); 
    signal state, nx_state  : state_type;

    signal reg_a_en, reg_b_en, reg_c_en : std_logic;

----------------------------------------------------------------------------------
begin
      
    process (clk)
    begin
        if (rising_edge(clk)) then
            if (rst = '1')  then
                state <= s_pdi_a;
            else
                state <= nx_state;
            end if;
        end if;
    end process;
    
    process (state, pdi_data, pdi_valid, pdi_sipo_ready)
    begin
        pdi_sipo_valid  <= '0';
        reg_a_en        <= '0';
        reg_b_en        <= '0';
        reg_c_en        <= '0';
        pdi_ready       <= '0';
        case state is
            when s_pdi_a =>
                pdi_ready       <= '1';                             
                if (pdi_valid = '1') then 
                    reg_a_en    <= '1';                                   
                    nx_state    <= s_pdi_b;
                else
                    nx_state    <= s_pdi_a;
                end if;
                
            when s_pdi_b =>
                pdi_ready       <= '1';
                if (pdi_valid = '1') then
                    reg_b_en    <= '1'; 
                    nx_state    <= s_pdi_c;
                else
                    nx_state    <= s_pdi_b;
                end if;
            
            when s_pdi_c =>
                pdi_ready       <= '1';
                if (pdi_valid = '1') then
                    reg_c_en    <= '1'; 
                    nx_state    <= s_valid;
                else
                    nx_state    <= s_pdi_c;
                end if;
                
            when s_valid =>
                pdi_sipo_valid  <= '1';
                if (pdi_sipo_ready = '1') then
                    nx_state    <= s_pdi_a;
                else 
                    nx_state    <= s_valid;
                end if;
                
            when others => null;

        end case;        
    end process;
    
    pdi_reg_a: entity work.myReg
    generic map( b => W)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => reg_a_en,
        D_in    => pdi_data,
        D_out   => pdi_data_a
    );
    
    pdi_reg_b: entity work.myReg
    generic map( b => W)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => reg_b_en,
        D_in    => pdi_data,
        D_out   => pdi_data_b
    );
    
    pdi_reg_c: entity work.myReg
    generic map( b => W)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => reg_c_en,
        D_in    => pdi_data,
        D_out   => pdi_data_c
    );

end Behavioral;
