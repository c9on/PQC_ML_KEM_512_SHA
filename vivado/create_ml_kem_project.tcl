# Vivado TCL project creation for ML-KEM-512 RTL modules
set project_name "ml_kem_512_rtl"
set project_dir  "[file normalize [file join [pwd] vivado_build]]"
set rtl_dir      "[file normalize [file join [pwd] rtl]]"
set sim_dir      "[file normalize [file join [pwd] sim]]"

create_project -force $project_name $project_dir -part xc7a100tcsg324-1
set_property board_part digilentinc.com:nexys-a7-100t:part0:1.0 [current_project]

# RTL files
add_files -norecurse [file join $rtl_dir common ml_kem_512_pkg.sv]
add_files -norecurse [file join $rtl_dir common ml_kem_fips203_pkg.sv]
add_files -norecurse [file join $rtl_dir ml_kem ml_kem_512_engine.sv]
add_files -norecurse [file join $rtl_dir ml_kem ml_kem_512_keygen.sv]
add_files -norecurse [file join $rtl_dir ml_kem ml_kem_512_encaps.sv]
add_files -norecurse [file join $rtl_dir ml_kem ml_kem_512_decaps.sv]
add_files -norecurse [file join $rtl_dir ml_kem ml_kem_512_kdf.sv]
add_files -norecurse [file join $rtl_dir ml_kem ml_kem_512_top.sv]

# Legacy standalone arithmetic/hash modules remain useful for focused unit
# tests, but they are not instantiated by the production ML-KEM top-level.
add_files -norecurse [file join $rtl_dir keccak keccak_f1600.sv]
add_files -norecurse [file join $rtl_dir sha3 sha3_256.sv]
add_files -norecurse [file join $rtl_dir sha3 sha3_512.sv]
add_files -norecurse [file join $rtl_dir sha3 shake128.sv]
add_files -norecurse [file join $rtl_dir sha3 shake256.sv]
add_files -norecurse [file join $rtl_dir ntt ntt_256.sv]
add_files -norecurse [file join $rtl_dir ntt intt_256.sv]
add_files -norecurse [file join $rtl_dir poly poly_arith.sv]

# The ACVP full-vector bench is the end-to-end conformance regression.
add_files -fileset sim_1 -norecurse [file join $sim_dir tb_ml_kem_512_acvp.sv]
add_files -fileset sim_1 -norecurse [file join $sim_dir tb_ml_kem_512_top.sv]
add_files -fileset sim_1 -norecurse [file join $sim_dir tb_ml_kem_512_keygen.sv]
add_files -fileset sim_1 -norecurse [file join $sim_dir tb_ml_kem_512_encaps.sv]
add_files -fileset sim_1 -norecurse [file join $sim_dir tb_ml_kem_512_decaps.sv]
add_files -fileset sim_1 -norecurse [file join $sim_dir tb_ml_kem_512_kdf.sv]

set_property top ml_kem_512_top [get_filesets sources_1]
set_property top tb_ml_kem_512_acvp [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "ML-KEM-512 Vivado project created in $project_dir"
