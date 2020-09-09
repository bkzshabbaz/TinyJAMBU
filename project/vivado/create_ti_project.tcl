################################################################################
#! @file       create_project.tcl
#! @brief      Tcl script to create the Vivado project for TI TinyJAMBU
#! @author     Sammy Lin
#! @copyright  Copyright (c) 2020 Cryptographic Engineering Research Group
#!             ECE Department, George Mason University Fairfax, VA, U.S.A.
#!             All rights Reserved.
#! @license    This project is released under the GNU Public License.
#!             The license and distribution terms for this file may be
#!             found in the file LICENSE in this distribution or at
#!             http://www.gnu.org/licenses/gpl-3.0.txt
#! @note       This is publicly available encryption source code that falls
#!             under the License Exception TSU (Technology and software-
#!             unrestricted)
################################################################################

puts "Creating LWC TI TinyJAMBU project for Xilinx Artix-7"
set target_project "lwc_ti_tinyjambu"
set target_part "xc7a35ticsg324-1L"

set target_top "LWC"
set sim_top "LWC_TB"

set files_main [list \
 "[file normalize "../../src_rtl/design_pkg.vhd"]"\
 "[file normalize "../../src_rtl/TI/ti_tinyjambu_control.vhd"]"\
 "[file normalize "../../src_rtl/TI/ti_tinyjambu_datapath.vhd"]"\
 "[file normalize "../../src_rtl/TI/ti_CryptoCore.vhd"]"\
 "[file normalize "../../src_rtl/TI/ti_nlfsr.vhd"]"\
 "[file normalize "../../src_rtl/TI/nand_3TI.vhd"]"\
 "[file normalize "../../src_rtl/TI/nand_3TI_a.vhd"]"\
 "[file normalize "../../src_rtl/TI/nand_3TI_b.vhd"]"\
 "[file normalize "../../src_rtl/TI/nand_3TI_c.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/data_piso.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/data_sipo.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/do_piso.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/dut_reg1.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/dut_regn.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/fifo2.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/fifo.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/fobos_controller.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/fobos_dut_pkg.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/fobos_dut_tb.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/FOBOS_DUT.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/fwft_fifo.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/key_piso.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/LWC.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/myReg.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/NIST_LWAPI_pkg.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/pdi_sipo.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/PostProcessor.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/PreProcessor.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/prng_trivium_enhanced.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/prng_trivium_tb.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/Register_s.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/sdi_sipo.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/SomeFunctions.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/std_logic_1164_additions.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/StepDownCountLd.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/test_controller.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/trivium_tb.vhd"]"\
 "[file normalize "../../src_rtl/LWC_TI/trivium.vhd"]"\

]

set obj [create_project $target_project ./$target_project -force]
set_property "default_lib" "xil_defaultlib"     $obj
set_property "part" $target_part                $obj
set_property "sim.ip.auto_export_scripts" "1"   $obj
set_property "simulator_language" "Mixed"       $obj
set_property "target_language" "VHDL"           $obj
set proj_dir [get_property directory [current_project]]

set src_files [get_filesets sources_1]

foreach fi $files_main {
    set file_obj [add_files -norecurse -fileset $src_files $fi]
    set_property "file_type" "VHDL" $file_obj
    set_property "library" "xil_defaultlib" $file_obj
}

set_property "top" $target_top $src_files

set files_sim [list \
 "[file normalize "../../tb/LWC_TI_TB.vhd"]"\
]

set files_sim_data [list \
 "[file normalize "../../KAT/KAT_32_3_share/do.txt"]"\
 "[file normalize "../../KAT/KAT_32_3_share/sharedSDI.txt"]"\
 "[file normalize "../../KAT/KAT_32_3_share/sharedPDI.txt"]"\
]

set sim_files [get_filesets sim_1]

foreach fi $files_sim {
    set sim_file_obj [add_files -norecurse -fileset $sim_files $fi]
    set_property "file_type" "VHDL" $sim_file_obj
    set_property "used_in_synthesis" false $sim_file_obj
}
set_property -name {xsim.simulate.runtime} -value {800us} -objects [get_filesets sim_1]

foreach fi $files_sim_data {
    set sim_file_obj [add_files -norecurse -fileset $sim_files $fi]
}

set_property "top" $sim_top $sim_files
set_property "xelab.nosort" "1" $sim_files
set_property "xelab.unifast" "" $sim_files

puts "Project LWC TI TinyJAMBU created!"
