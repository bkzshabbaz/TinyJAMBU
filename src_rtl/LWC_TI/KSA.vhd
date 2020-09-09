--KSA_mod_TI (n-bit kogge stone adder with 3-share threshold implementation)

library ieee;
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all; 
use work.ksa_pkg.all;
use work.design_pkg.all;

-- Entity
-----------------------------------------------------------------------
entity KSA is
generic (n : integer:= 8);
port(
    clk    : in  std_logic;
    m      : in  std_logic_vector(RW - 1 downto 0); -- Random input
	a0     : in  std_logic_vector(n-1 downto 0);
	a1     : in  std_logic_vector(n-1 downto 0);
	a2     : in  std_logic_vector(n-1 downto 0);
	b0     : in  std_logic_vector(n-1 downto 0);
	b1     : in  std_logic_vector(n-1 downto 0);
	b2     : in  std_logic_vector(n-1 downto 0);
	s0     : out std_logic_vector(n-1 downto 0);
	s1     : out std_logic_vector(n-1 downto 0);
	s2     : out std_logic_vector(n-1 downto 0)
	);
end KSA;

-- Architecture
------------------------------------------------------------------------
architecture structural of KSA is

    -- Keep architecture -----------------------------------------------
    attribute keep_hierarchy : string;
    attribute keep_hierarchy of structural: architecture is "true";  

    -- Signals ---------------------------------------------------------
    signal p0, p1, p2                       : pg_array_type;
    signal g0, g1, g2                       : pg_array_type;
    signal g0Reg0_in, g0Reg1_in, g0Reg2_in  : std_logic_vector(0 to n-1);
    signal p0Reg0_in, p0Reg1_in, p0Reg2_in  : std_logic_vector(0 to n-1);
    
    -- Keep signals ---------------------------------------------------
    attribute keep : string;
    attribute keep of p0, p1, p2, g0, g1, g2           : signal is "true";
    attribute keep of g0Reg0_in, g0Reg1_in, g0Reg2_in  : signal is "true";
    attribute keep of p0Reg0_in, p0Reg1_in, p0Reg2_in  : signal is "true";
    
-----------------------------------------------------------------------
begin

    -- stage 0 carry generation and propagation with mask refresh (Preprocessing)
    pg: for j in 0 to n-1 generate
        g_masked: entity work.and_3TI(structural) -- g0 = a and b
        port map(
            xa  => a0(j),
            xb  => a1(j),
            xc  => a2(j),
            ya  => b0(j),
            yb  => b1(j),
            yc  => b2(j),
            m   => m(j),
            o1  => g0Reg0_in(j),
            o2  => g0Reg1_in(j),
            o3  => g0Reg2_in(j)
        );     
        p0Reg0_in(j) <= a0(j) xor b0(j);  -- p0 = a xor b
        p0Reg1_in(j) <= a1(j) xor b1(j); 
        p0Reg2_in(j) <= a2(j) xor b2(j);           
    end generate pg;
    
    -- First stage of registers
    g0Reg0: entity work.myReg
    generic map( b => n)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => '1',
        D_in    => g0Reg0_in,
        D_out   => g0(0)
    );
    
    g0Reg1: entity work.myReg
    generic map( b => n)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => '1',
        D_in    => g0Reg1_in,
        D_out   => g1(0)
    );
    
    g0Reg2: entity work.myReg
    generic map( b => n)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => '1',
        D_in    => g0Reg2_in,
        D_out   => g2(0)
    );
    
    p0Reg0: entity work.myReg
    generic map( b => n)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => '1',
        D_in    => p0Reg0_in,
        D_out   => p0(0)
    );
    
    p0Reg1: entity work.myReg
    generic map( b => n)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => '1',
        D_in    => p0Reg1_in,
        D_out   => p1(0)
    );
    
    p0Reg2: entity work.myReg
    generic map( b => n)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => '1',
        D_in    => p0Reg2_in,
        D_out   => p2(0)
    );
    

    -- stage 1 
    s_1: entity work.KSA_STAGE_1(dataflow)
        generic map (n => n)
        port map(
            clk   => clk,
            m     => m,
            gin0  => g0(0),
            gin1  => g1(0),
            gin2  => g2(0),
            pin0  => p0(0),
            pin1  => p1(0),
            pin2  => p2(0),
            gout0 => g0(1),
            gout1 => g1(1),
            gout2 => g2(1),
            pout0 => p0(1),
            pout1 => p1(1),
            pout2 => p2(1)
            );
    
    -- stages 2 to log2(n)
    si: for i in 2 to log2_ceil(n) generate

    s_2_2: entity work.KSA_STAGE_I(dataflow)
        generic map (i => i, n => n)
        port map(
            clk   => clk,
            m     => m,
            gin0  => g0(i-1),
            gin1  => g1(i-1),
            gin2  => g2(i-1),
            pin0  => p0(i-1),
            pin1  => p1(i-1),
            pin2  => p2(i-1),
            gout0 => g0(i),
            gout1 => g1(i),
            gout2 => g2(i),
            pout0 => p0(i),
            pout1 => p1(i),
            pout2 => p2(i)
            );

    end generate si;
  
    -- addition stage   
    s0(0) <= a0(0) xor b0(0);
    s1(0) <= a1(0) xor b1(0);
    s2(0) <= a2(0) xor b2(0);

    m1: for i in 1 to n-1 generate
        s0(i) <= a0(i) xor b0(i) xor g0(log2_ceil(n))(i-1); 
        s1(i) <= a1(i) xor b1(i) xor g1(log2_ceil(n))(i-1); 
        s2(i) <= a2(i) xor b2(i) xor g2(log2_ceil(n))(i-1);
    end generate m1;

end structural;
