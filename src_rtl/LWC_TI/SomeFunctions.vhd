----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/09/2019 04:10:23 PM
-- Design Name: 
-- Module Name: SomeFunctions - Behavioral
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

-- Declarations
----------------------------------------------------------------------------------
package SomeFunction is
    
    function pad      (I         : in std_logic_vector(127 downto 0);
                       bytes_Num : in natural) return std_logic_vector;
    function doubling (Zp0       : in std_logic_vector(63 downto 0)) return std_logic_vector;
    function phi      (Zp        : in std_logic_vector(127 downto 0)) return std_logic_vector;
    function shuffle  (X         : in std_logic_vector(127 downto 0)) return std_logic_vector;
    function myMux    (Reg_out   : in std_logic_vector(127 downto 0);
                       bdi       : in std_logic_vector(31 downto 0);
                       ctr_words : in std_logic_vector(2 downto 0)) return std_logic_vector;
    function chop     (output    : in std_logic_vector(31 downto 0);
                       bdi_size  : in std_logic_vector(4 downto 0)) return std_logic_vector;  
    function BE2LE    (output    : in std_logic_vector(31 downto 0)) return std_logic_vector;
                  
    
end package SomeFunction;

-- Body
----------------------------------------------------------------------------------
package body SomeFunction is

    -- Padding --------------------------------------------------
    function pad (I : in std_logic_vector(127 downto 0); bytes_Num : in natural) return std_logic_vector is
    variable temp : std_logic_vector(127 downto 0);
    begin
        if (bytes_Num = 0) then -- pad_I = 0*1
            temp(127 downto 1)  := (others => '0');
            temp(0)             := '1'; 
        elsif (bytes_Num < 16) then -- pad_I = 0*1 || I
            temp(127 downto 8*bytes_Num + 1)    := (others => '0');
            temp(8*bytes_Num)                   := '1';
            temp(8*bytes_Num - 1 downto 0)      := I(8*bytes_Num - 1 downto 0);
        else -- pad_I = I
            temp := I;
        end if;
        return temp;
    end function;

    -- 2*b -----------------------------------------------------------------------
    function doubling (Zp0 : in std_logic_vector(63 downto 0)) return std_logic_vector is
    variable temp : std_logic_vector(63 downto 0);
    begin
        if (Zp0(63) = '0') then
            temp := Zp0(62 downto 0) & '0'; -- A<<1, if a(63)=0
        else
            temp := Zp0(62 downto 4) & ( (Zp0(3 downto 0) & '0') xor "11011"); -- (A<<1) xor 27, if a(63)=1
        end if;
        return temp;
    end function;   
    
    -- phi -----------------------------------------------------------------------
    function phi (Zp : in std_logic_vector(127 downto 0)) return std_logic_vector is -- permute function (get_blk_key)
    variable Z0 : std_logic_vector(63 downto 0);
    variable Z : std_logic_vector(127 downto 0);
    begin
        Z0  := doubling (Zp(63 downto 0)); -- Zp = (Zp1, Zp0), Z0 = Zp0 * 2
        Z   := Zp(127 downto 64) & Z0(63 downto 0); -- Z = (Zp1, Z0)
        return Z;     
    end function;
    
    -- shuffle -------------------------------------------------------------------
    function shuffle (X : in std_logic_vector(127 downto 0)) return std_logic_vector is
    variable X2     : std_logic_vector(31 downto 0);
    variable temp   : std_logic_vector(127 downto 0);
    begin
        X2   := X(64) & X(95 downto 65); -- X2 >>> 1
        temp := X(63 downto 32) & X(31 downto 0) & X2 & X(127 downto 96); -- (X1, x0, Xp2, Xp)
        return temp;
    end function;
    
    -- Multiplexer ---------------------------------------------------------------
    function myMux (Reg_out   : in std_logic_vector(127 downto 0);
                    bdi       : in std_logic_vector(31 downto 0);
                    ctr_words : in std_logic_vector(2 downto 0)) return std_logic_vector is
    variable temp : std_logic_vector(127 downto 0);
    begin
        if (ctr_words = 0) then
            temp := Reg_out(127 downto 32) & bdi;
        elsif (ctr_words = 1) then
            temp := Reg_out(127 downto 64) & bdi & Reg_out(31 downto 0);
        elsif (ctr_words = 2) then
            temp := Reg_out(127 downto 96) & bdi & Reg_out(63 downto 0);
        else
            temp := bdi & Reg_out(95 downto 0);
        end if;
        return temp;
    end function;
    
    -- Truncate -----------------------------------------------------------------
    function chop (output : in std_logic_vector(31 downto 0); bdi_size : in std_logic_vector(4 downto 0)) return std_logic_vector is
    variable temp : std_logic_vector(31 downto 0);
    begin
        if (bdi_size = 1) then
            temp := output(31 downto 24) & x"000000";
        elsif (bdi_size = 2) then
            temp := output(31 downto 16) & x"0000";
        elsif (bdi_size = 3) then
            temp := output(31 downto 8) & x"00";
        elsif (bdi_size = 4) then
            temp := output;
        end if;
        return temp;
    end function;
    
    -- Big endian to little endian ----------------------------------------------
    function BE2LE (output : in std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return output(7 downto 0) & output(15 downto 8) & output(23 downto 16) & output(31 downto 24);
    end function;
    
end package body SomeFunction;

