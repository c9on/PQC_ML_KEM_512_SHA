# Vivado TCL project creation for ML-KEM-512 RTL modules
set project_name "ml_kem_512_rtl"
set project_dir  "[file normalize [file join [pwd] vivado_build]]"
set rtl_dir      "[file normalize [file join [pwd] rtl]]"
set sim_dir      "[file normalize [file join [pwd] sim]]"
set tb_dir       "[file normalize [file join $sim_dir tb]]"
set constr_dir   "[file normalize [file join [pwd] vivado]]"
set report_dir   "[file normalize [file join $project_dir reports]]"

create_project -force $project_name $project_dir -part xc7a100tcsg324-1
# The exact Nexys A7 part is used without a board_part dependency, so project
# creation also works when Digilent board-definition files are not installed.

# The production hierarchy is intentionally restricted to files used by
# ml_kem_512_top. Other arithmetic/hash primitives remain in the repository for
# focused functional simulation but are not part of production synthesis.
add_files -norecurse [file join $rtl_dir common ml_kem_fips203_pkg.sv]
add_files -norecurse [file join $rtl_dir ml_kem ml_kem_512_engine.sv]
add_files -norecurse [file join $rtl_dir ml_kem ml_kem_512_top.sv]
add_files -fileset constrs_1 -norecurse [file join $constr_dir ml_kem_512.xdc]

# End-to-end verification uses the complete generated ACVP catalog.
add_files -fileset sim_1 -norecurse [file join $tb_dir tb_ml_kem_512_acvp_full.sv]

set_property top ml_kem_512_top [get_filesets sources_1]
set_property top tb_ml_kem_512_acvp_full [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Reproducible non-project reports are written after synthesis when Vivado is run.
file mkdir $report_dir
puts "ML-KEM-512 Vivado project created in $project_dir"
puts "Constraint file: [file join $constr_dir ml_kem_512.xdc]"
