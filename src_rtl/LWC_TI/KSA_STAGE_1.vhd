--KSA_STAGE_1

library ieee;
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use work.ksa_pkg.all;
use work.design_pkg.all;  

-- Entity
-------------------------------------------------------
entity KSA_STAGE_1 is
generic (n : integer:= 8);
port(  
    clk     :in  std_logic; 
    m       :in  std_logic_vector(RW - 1 downto 0); -- Random input 
	gin0	:in  std_logic_vector(0 to 31);
	gin1	:in  std_logic_vector(0 to 31);
	gin2	:in  std_logic_vector(0 to 31);
	pin0	:in  std_logic_vector(0 to 31);
	pin1	:in  std_logic_vector(0 to 31);
	pin2	:in  std_logic_vector(0 to 31);
	gout0	:out std_logic_vector(0 to 31);
	gout1	:out std_logic_vector(0 to 31);
	gout2	:out std_logic_vector(0 to 31);
	pout0	:out std_logic_vector(0 to 31);
	pout1	:out std_logic_vector(0 to 31);
	pout2	:out std_logic_vector(0 to 31)
	);
end KSA_STAGE_1;

-- Architecture
-------------------------------------------------------
architecture dataflow of KSA_STAGE_1 is

    -- Keep architecture -----------------------------------------------
    attribute keep_hierarchy : string;
    attribute keep_hierarchy of dataflow: architecture is "true"; 

    -- Signals ----------------------------------------
    signal gANDp0, gANDp0_reg           : std_logic_vector(0 to 31);
    signal gANDp1, gANDp1_reg           : std_logic_vector(0 to 31);
    signal gANDp2, gANDp2_reg           : std_logic_vector(0 to 31); 
    signal pANDp0, pANDp1, pANDp2       : std_logic_vector(0 to 31);
    
    signal gin0_reg, gin1_reg, gin2_reg : std_logic_vector(0 to 31);
    
    -- Keep signals -----------------------------------------------
    attribute keep : string;
    attribute keep of gANDp0, gANDp0_reg            : signal is "true";
    attribute keep of gANDp1, gANDp1_reg            : signal is "true";
    attribute keep of gANDp2, gANDp2_reg            : signal is "true";
    attribute keep of pANDp0, pANDp1, pANDp2        : signal is "true";
    attribute keep of gin0_reg, gin1_reg, gin2_reg  : signal is "true";

-------------------------------------------------------
begin

    -- stage 1 of carry generation and propagation
    
    gANDp0(0) <= gin0(0);
    gANDp1(0) <= gin1(0);
    gANDp2(0) <= gin2(0);
    
    gout0(0)  <= gANDp0_reg(0);
    gout1(0)  <= gANDp1_reg(0);
    gout2(0)  <= gANDp2_reg(0);
    
    pANDp0(0) <= pin0(0);
    pANDp1(0) <= pin1(0);
    pANDp2(0) <= pin2(0);

    sj: for j in 1 to n-1 generate
    
        gANDp_masked: entity work.and_3TI(structural) -- g(i) and p(j)
        port map(
            xa  => gin0(j-1),
            xb  => gin1(j-1),
            xc  => gin2(j-1),
            ya  => pin0(j),
            yb  => pin1(j),
            yc  => pin2(j),
            m   => m(j-1),
            o1  => gANDp0(j),
            o2  => gANDp1(j),
            o3  => gANDp2(j)
        );       
            
        gout0(j) <= gin0_reg(j) xor gANDp0_reg(j); -- g(j:i) = g(j) xor (g(i) and p(j))
        gout1(j) <= gin1_reg(j) xor gANDp1_reg(j);
        gout2(j) <= gin2_reg(j) xor gANDp2_reg(j);
           
        pANDp_masked: entity work.and_3TI(structural) -- p(j:i) = p(i) and p(j)
        port map(
            xa  => pin0(j-1),
            xb  => pin1(j-1),
            xc  => pin2(j-1),
            ya  => pin0(j),
            yb  => pin1(j),
            yc  => pin2(j),
            m   => m(j + 30),
            o1  => pANDp0(j),
            o2  => pANDp1(j),
            o3  => pANDp2(j)
        );    
           
    end generate sj;
    
    -- Second stage of registers
    ginReg0: entity work.myReg
    generic map( b => n)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => '1',
        D_in    => gin0,
        D_out   => gin0_reg
    );
    
    ginReg1: entity work.myReg
    generic map( b => n)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => '1',
        D_in    => gin1,
        D_out   => gin1_reg
    );
    
    ginReg2: entity work.myReg
    generic map( b => n)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => '1',
        D_in    => gin2,
        D_out   => gin2_reg
    );
    
    gANDpReg0: entity work.myReg
    generic map( b => n)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => '1',
        D_in    => gANDp0,
        D_out   => gANDp0_reg
    );
    
    gANDpReg1: entity work.myReg
    generic map( b => n)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => '1',
        D_in    => gANDp1,
        D_out   => gANDp1_reg
    );
    
    gANDpReg2: entity work.myReg
    generic map( b => n)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => '1',
        D_in    => gANDp2,
        D_out   => gANDp2_reg
    );
    
    pANDpReg0: entity work.myReg
    generic map( b => n)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => '1',
        D_in    => pANDp0,
        D_out   => pout0
    );
    
    pANDpReg1: entity work.myReg
    generic map( b => n)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => '1',
        D_in    => pANDp1,
        D_out   => pout1
    );
    
    pANDpReg2: entity work.myReg
    generic map( b => n)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => '1',
        D_in    => pANDp2,
        D_out   => pout2
    );

end dataflow; 

