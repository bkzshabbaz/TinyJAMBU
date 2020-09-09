--------------------------------------------------------------------------------
--! @file       ti_CryptoCore.vhd
--! @brief      A three share threshold implementation protected TinyJAMBU's
--              CryptoCore
--! @author     Sammy Lin
--! @copyright  Copyright (c) 2020 Cryptographic Engineering Research Group
--!             ECE Department, George Mason University Fairfax, VA, U.S.A.
--!             All rights Reserved.
--! @license    This project is released under the GNU Public License.
--!             The license and distribution terms for this file may be
--!             found in the file LICENSE in this distribution or at
--!             http://www.gnu.org/licenses/gpl-3.0.txt
--! @note       This is publicly available encryption source code that falls
--!             under the License Exception TSU (Technology and software-
--!             unrestricted)
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.design_pkg.all;
use work.NIST_LWAPI_pkg.all;

entity CryptoCore is
    generic (
        WIDTH               : integer := 128
    );
    
    port (
        clk                 : in   std_logic;
        rst                 : in   std_logic;
        --PreProcessor===============================================
        ----!key----------------------------------------------------
        key_a               : in   std_logic_vector (CCSW    -1 downto 0);
        key_b               : in   std_logic_vector (CCSW    -1 downto 0);
        key_c               : in   std_logic_vector (CCSW    -1 downto 0);
        key_valid           : in   std_logic;
        key_update          : in   std_logic;
        key_ready           : out  std_logic;
        ----!Data----------------------------------------------------
        bdi_a               : in   std_logic_vector (CCW     -1 downto 0);
        bdi_b               : in   std_logic_vector (CCW     -1 downto 0);
        bdi_c               : in   std_logic_vector (CCW     -1 downto 0);
        bdi_valid           : in   std_logic;
        bdi_ready           : out  std_logic;
        bdi_pad_loc         : in   std_logic_vector (CCWdiv8 -1 downto 0);
        bdi_valid_bytes     : in   std_logic_vector (CCWdiv8 -1 downto 0);
        bdi_size            : in   std_logic_vector (3       -1 downto 0);
        bdi_eot             : in   std_logic;
        bdi_eoi             : in   std_logic;
        bdi_type            : in   std_logic_vector (4       -1 downto 0);
        decrypt_in          : in   std_logic;
        hash_in             : in   std_logic;
        --!Post Processor=========================================
        bdo_a               : out  std_logic_vector (CCW     -1 downto 0);
        bdo_b               : out  std_logic_vector (CCW     -1 downto 0);
        bdo_c               : out  std_logic_vector (CCW     -1 downto 0);
        bdo_valid           : out  std_logic;
        bdo_ready           : in   std_logic;
        bdo_type            : out  std_logic_vector (4       -1 downto 0);
        bdo_valid_bytes     : out  std_logic_vector (CCWdiv8 -1 downto 0);
        end_of_block        : out  std_logic;
        msg_auth_valid      : out  std_logic;
        msg_auth_ready      : in   std_logic;
        msg_auth            : out  std_logic;
        
        rdi_data            : in   std_logic_vector(RW       -1 downto 0)
    );
end entity CryptoCore;

architecture structural of CryptoCore is
-- Keep architecture ---------------------------------------------------------
attribute keep_hierarchy : string;
attribute keep_hierarchy of structural : architecture is "true";

signal bdo_sel, nlfsr_load, nlfsr_en, nlfsr_reset, ctrl_decrypt : std_logic;
signal key_load, partial                                        : std_logic;
signal fbits_sel, s_sel, key_index, partial_bytes               : std_logic_vector (1 downto 0);
signal bdo_a_sig, bdo_b_sig, bdo_c_sig                          : std_logic_vector (31 downto 0);

-- Keep signals
attribute keep : string;

attribute keep of bdo_sel, nlfsr_load, nlfsr_en, nlfsr_reset, ctrl_decrypt : signal is "true";
attribute keep of key_load, partial                                        : signal is "true";
attribute keep of fbits_sel, s_sel, key_index, partial_bytes               : signal is "true";
attribute keep of bdo_a_sig, bdo_b_sig, bdo_c_sig                          : signal is "true";

begin
bdo_a     <= bdo_a_sig;
bdo_b     <= bdo_b_sig;
bdo_c     <= bdo_c_sig;

datapath : entity work.tinyjambu_datapath
            port map (
                clk             => clk,
                reset           => rst,
                nlfsr_load      => nlfsr_load,
                partial         => partial,
                partial_bytes   => partial_bytes,
                key_load        => key_load,
                key_index       => key_index,
                nlfsr_en        => nlfsr_en,
                nlfsr_reset     => nlfsr_reset,
                decrypt         => ctrl_decrypt,
                bdi_a           => bdi_a,
                bdi_b           => bdi_b,
                bdi_c           => bdi_c,
                fbits_sel       => fbits_sel,
                partial_bdo_out => bdi_valid_bytes,
                s_sel           => s_sel,
                key_a           => key_a,
                key_b           => key_b,
                key_c           => key_c,
                rdi_data        => rdi_data,
                bdo_sel         => bdo_sel,
                bdo_a           => bdo_a_sig,
                bdo_b           => bdo_b_sig,
                bdo_c           => bdo_c_sig
            );

control : entity work.tinyjambu_control
            port map (
                clk             => clk,
                reset           => rst,
                decrypt_in      => decrypt_in,
                decrypt_out     => ctrl_decrypt,
                nlfsr_reset     => nlfsr_reset,
                nlfsr_en        => nlfsr_en,
                nlfsr_load      => nlfsr_load,
                key_load        => key_load,
                key_index       => key_index,
                key_ready       => key_ready,
                key             => key_a,
                key_valid       => key_valid,
                key_update      => key_update,
                bdo_valid       => bdo_valid,
                bdo_ready       => bdo_ready,
                bdo_type        => bdo_type,
                partial         => partial,
                partial_bytes   => partial_bytes,
                bdi_a           => bdi_a,
                bdi_b           => bdi_b,
                bdi_c           => bdi_c,
                bdi_valid       => bdi_valid,
                bdi_ready       => bdi_ready,
                bdi_pad_loc     => bdi_pad_loc,
                bdi_size        => bdi_size,
                bdi_eoi         => bdi_eoi,
                bdi_eot         => bdi_eot,
                bdi_valid_bytes => bdi_valid_bytes,
                bdo_valid_bytes => bdo_valid_bytes,
                end_of_block    => end_of_block,
                bdi_type        => bdi_type,
                fbits_sel       => fbits_sel,
                bdo_sel         => bdo_sel,
                bdo_a           => bdo_a_sig,
                bdo_b           => bdo_b_sig,
                bdo_c           => bdo_c_sig,
                hash_in         => hash_in,
                s_sel           => s_sel,
                msg_auth_valid  => msg_auth_valid,
                msg_auth_ready  => msg_auth_ready,
                msg_auth        => msg_auth,
                m               => rdi_data
            );
end architecture structural;
