----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/28/2020
-- Design Name: 
-- Module Name: do_piso - Behavioral
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
entity do_piso is
    Port (
        clk             : in  std_logic;
        rst             : in  std_logic;
             
        do_data         : out std_logic_vector(W-1 downto 0); -- from PISO to DO_FIFO
        do_valid        : out std_logic; -- from PISO to DO_FIFO
        do_ready        : in  std_logic; -- from FIFO to DO_PISO
        
        do_data_a       : in  std_logic_vector(W-1 downto 0); -- from PostProcessor to PISO
        do_data_b       : in  std_logic_vector(W-1 downto 0); -- from PostProcessor to PISO
        do_data_c       : in  std_logic_vector(W-1 downto 0); -- from PostProcessor to PISO
        do_piso_valid   : in  std_logic; -- from PostProcessor to PISO
        do_piso_ready   : out std_logic -- from PISO to PostProcessor 
    );
end do_piso;

-- Architecture
----------------------------------------------------------------------------------
architecture Behavioral of do_piso is

    -- Signals -------------------------------------------------------------------
    type state_type is (s_do_a, s_do_b, s_do_c, s_ready); 
    signal state, nx_state  : state_type;

    signal reg_a_en, reg_b_en, reg_c_en : std_logic;
    signal reg_a_Q, reg_b_Q, reg_c_Q    : std_logic_vector(W-1 downto 0);

----------------------------------------------------------------------------------
begin
      
    process (clk)
    begin
        if (rising_edge(clk)) then
            if (rst = '1')  then
                state <= s_ready;
            else
                state <= nx_state;
            end if;
        end if;
    end process;
    
    process (state, do_data_a, do_data_b, do_data_c, do_ready, do_piso_valid)
    begin
        do_piso_ready   <= '0';
        reg_a_en        <= '0';
        reg_b_en        <= '0';
        reg_c_en        <= '0';
        do_valid        <= '0';
        case state is
            when s_ready =>  
                do_piso_ready   <= '1';                     
                if (do_piso_valid = '1') then                        
                    reg_a_en    <= '1';
                    reg_b_en    <= '1';
                    reg_c_en    <= '1';                                   
                    nx_state    <= s_do_a;
                else
                    nx_state    <= s_ready;
                end if;
                
            when s_do_a =>
                do_valid        <= '1';
                do_data         <= reg_a_Q; -- do_data_a
                if (do_ready = '1') then
                    
                    nx_state    <= s_do_b;
                else
                    nx_state    <= s_do_a;
                end if;
            
            when s_do_b =>
                do_valid        <= '1';
                do_data         <= reg_b_Q; -- do_data_b
                if (do_ready = '1') then   
                    nx_state    <= s_do_c;
                else
                    nx_state    <= s_do_b;
                end if;
                
            when s_do_c =>
                do_valid        <= '1';
                do_data         <= reg_c_Q; -- do_data_c
                if (do_ready = '1') then                 
                    nx_state    <= s_ready;
                else 
                    nx_state    <= s_do_c;
                end if;
                
            when others => null;

        end case;        
    end process;
    
    do_reg_a: entity work.myReg
    generic map( b => W)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => reg_a_en,
        D_in    => do_data_a,
        D_out   => reg_a_Q
    );
    
    do_reg_b: entity work.myReg
    generic map( b => W)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => reg_b_en,
        D_in    => do_data_b,
        D_out   => reg_b_Q
    );
    
    do_reg_c: entity work.myReg
    generic map( b => W)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => reg_c_en,
        D_in    => do_data_c,
        D_out   => reg_c_Q
    );

end Behavioral;
