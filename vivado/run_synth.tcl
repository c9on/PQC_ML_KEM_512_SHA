# Run Vivado synthesis and produce utilization, timing, and methodology reports.
# IMPORTANT: the current behavioral ML-KEM engine evaluates the cryptographic
# functions in one COMPUTE state. Vivado 2026.2 can elaborate this hierarchy,
# but netlist expansion of the resulting combinational graph was observed to
# exceed 10 GB RSS and did not complete. The reports below are therefore expected
# only after refactoring Keccak/NTT into iterative, cycle-bounded datapaths.
source [file normalize [file join [file dirname [info script]] create_ml_kem_project.tcl]]

set report_dir [file normalize [file join $project_dir reports]]
file mkdir $report_dir

launch_runs synth_1 -jobs 1
wait_on_run synth_1

open_run synth_1
report_utilization -file [file join $report_dir utilization.rpt]
report_timing_summary -file [file join $report_dir timing_summary.rpt]
report_timing -max_paths 20 -sort_by slack -file [file join $report_dir timing_paths.rpt]
report_methodology -file [file join $report_dir methodology.rpt]
report_design_analysis -timing -file [file join $report_dir design_analysis.rpt]

puts "Synthesis complete. Reports are in $report_dir"
