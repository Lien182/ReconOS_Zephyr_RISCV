#                                                        ____  _____
#                            ________  _________  ____  / __ \/ ___/
#                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
#                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
#                         /_/   \___/\___/\____/_/ /_/\____//____/
# 
# ======================================================================
#
#   title:        ReconOS setup script for Vivado
#
#   project:      ReconOS
#   author:       Sebastian Meisner, University of Paderborn
#   description:  This TCL script sets up all modules and connections
#                 in an IP integrator block design needed to create
#                 a fully functional ReconoOS design.
#
# ======================================================================

<<reconos_preproc>>

variable script_file
set script_file "system.tcl"


# Help information for this script
proc help {} {
  variable script_file
  puts "\nDescription:"
  puts "This TCL script sets up all modules and connections in an IP integrator"
  puts "block design needed to create a fully functional ReconoOS design.\n"
  puts "Syntax when called in batch mode:"
  puts "vivado -mode tcl -source $script_file -tclargs \[-proj_name <Name> -proj_path <Path>\]" 
  puts "$script_file -tclargs \[--help\]\n"
  puts "Usage:"
  puts "Name                   Description"
  puts "-------------------------------------------------------------------------"
  puts "-proj_name <Name>        Optional: When given, a new preject will be"
  puts "                         created with the given name"
  puts "-proj_path <path>        Path to the newly created project"
  puts "\[--help\]               Print help information for this script"
  puts "-------------------------------------------------------------------------\n"
  exit 0
}


# Set the directory where the IP integrator cores live
set reconos_ip_dir [pwd]/pcores

set proj_name ""
set proj_path ""

# Parse command line arguments
if { $::argc > 0 } {
  for {set i 0} {$i < [llength $::argc]} {incr i} {
    set option [string trim [lindex $::argv $i]]
    switch -regexp -- $option {
      "-proj_name" { incr i; set proj_name  [lindex $::argv $i] }
      "-proj_path" { incr i; set proj_path  [lindex $::argv $i] }
      "-help"      { help }
      default {
        if { [regexp {^-} $option] } {
          puts "ERROR: Unknown option '$option' specified, please type '$script_file -tclargs --help' for usage info.\n"
          return 1
        }
      }
    }
  }
}


proc reconos_hw_delete {} {
    
    # get current project name and directory
    set proj_name [current_project]
    set proj_dir [get_property directory [current_project]]
    
    open_bd_design $proj_dir/$proj_name.srcs/sources_1/bd/design_1/design_1.bd
    remove_files $proj_dir/$proj_name.srcs/sources_1/bd/design_1/hdl/design_1_wrapper.vhd
    file delete -force $proj_dir/$proj_name.srcs/sources_1/bd/design_1/hdl/design_1_wrapper.vhd
    set_property source_mgmt_mode DisplayOnly [current_project]
    update_compile_order -fileset sim_1
    remove_files $proj_dir/$proj_name.srcs/sources_1/bd/design_1/design_1.bd
    file delete -force $proj_dir/$proj_name.srcs/sources_1/bd/design_1

}


proc reconos_hw_setup {new_project_name new_project_path reconos_ip_dir} {

    # Create new project if "new_project_name" is given.
    # Otherwise current project will be reused.
    if { [llength $new_project_name] > 0} {
        create_project -force $new_project_name $new_project_path -part xc7a35tcpg236-1
    }


    # Save directory and project names to variables for easy reuse
    set proj_name [current_project]
    set proj_dir [get_property directory [current_project]]
    
    # Set project properties
    set_property "board_part" "digilentinc.com:basys3:part0:1.2" $proj_name
    set_property "default_lib" "xil_defaultlib" $proj_name
    set_property "sim.ip.auto_export_scripts" "1" $proj_name
    set_property "simulator_language" "Mixed" $proj_name
    set_property "target_language" "VHDL" $proj_name

    # Create 'sources_1' fileset (if not found)
    if {[string equal [get_filesets -quiet sources_1] ""]} {
    create_fileset -srcset sources_1
    }


    # Create 'constrs_1' fileset (if not found)
    if {[string equal [get_filesets -quiet constrs_1] ""]} {
    create_fileset -constrset constrs_1
    }


    # Create 'sim_1' fileset (if not found)
    if {[string equal [get_filesets -quiet sim_1] ""]} {
    create_fileset -simset sim_1
    }

    ## Constraints
    set fileset_constraints $proj_dir/Basys-3-Master.xdc

    ## Constraints
    add_files -fileset constrs_1 $fileset_constraints
    
    # Set 'sim_1' fileset properties
    set obj [get_filesets sim_1]
    set_property "transport_int_delay" "0" $obj
    set_property "transport_path_delay" "0" $obj
    set_property "xelab.nosort" "1" $obj
    set_property "xelab.unifast" "" $obj

    # Create 'synth_1' run (if not found)
    if {[string equal [get_runs -quiet synth_1] ""]} {
        create_run -name synth_1 -part xc7a35tcpg236-1 -flow {Vivado Synthesis 2020} -strategy "Vivado Synthesis Defaults" -constrset constrs_1
    } else {
        set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
        set_property flow "Vivado Synthesis 2020" [get_runs synth_1]
    }

    # set the current synth run
    current_run -synthesis [get_runs synth_1]

    # Create 'impl_1' run (if not found)
    if {[string equal [get_runs -quiet impl_1] ""]} {
        create_run -name xc7a35tcpg236-1 -flow {Vivado Implementation 2020} -strategy "Vivado Implementation Defaults" -constrset constrs_1 -parent_run synth_1
    } else {
        set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
        set_property flow "Vivado Implementation 2020" [get_runs impl_1]
    }
    
    set obj [get_runs impl_1]
    set_property "steps.write_bitstream.args.readback_file" "0" $obj
    set_property "steps.write_bitstream.args.verbose" "0" $obj

    # set the current impl run
    current_run -implementation [get_runs impl_1]

    #
    # Start block design
    #
    create_bd_design "design_1"
update_compile_order -fileset sources_1

# Add repositories
set_property  ip_repo_paths  {pcores IP} [current_project]
update_ip_catalog

# Add system reset module
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 reset_0
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 reset_1
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not} CONFIG.LOGO_FILE {data/sym_notgate.png}] [get_bd_cells util_vector_logic_0]



# Add Processing system
create_bd_cell -type ip -vlnv user.org:user:neorv32_SystemTop_axi4lite:1.0 neorv32_SystemTop_ax_0
set_property name processing_system7_0 [get_bd_cells neorv32_SystemTop_ax_0]
set_property -dict [list CONFIG.IO_TWI_EN {false} CONFIG.IO_WDT_EN {false} CONFIG.IO_TRNG_EN {false} CONFIG.IO_NEOLED_EN {false} CONFIG.CUSTOM_ID {0x000000ab} CONFIG.MEM_INT_IMEM_SIZE {131072} CONFIG.MEM_INT_DMEM_SIZE {65536} CONFIG.XIRQ_NUM_CH {32}] [get_bd_cells processing_system7_0]

# Add Processing system modules
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0
set_property -dict [list CONFIG.DIN_FROM {7} CONFIG.DIN_WIDTH {64} CONFIG.DOUT_WIDTH {8}] [get_bd_cells xlslice_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0
set_property -dict [list CONFIG.CONST_WIDTH {64}] [get_bd_cells xlconstant_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1
set_property -dict [list CONFIG.CONST_WIDTH {16}] [get_bd_cells xlconstant_1]
set_property -dict [list CONFIG.CONST_VAL {0}] [get_bd_cells xlconstant_1]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0
set_property -dict [list CONFIG.IN0_WIDTH.VALUE_SRC USER CONFIG.IN1_WIDTH.VALUE_SRC USER] [get_bd_cells xlconcat_0]
set_property -dict [list CONFIG.IN0_WIDTH {16} CONFIG.IN1_WIDTH {16}] [get_bd_cells xlconcat_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0
set_property -dict [list CONFIG.PRIMITIVE {PLL} CONFIG.CLKOUT2_USED {true} CONFIG.CLK_OUT1_PORT {main_out} CONFIG.CLK_OUT2_PORT {FCLK_0} CONFIG.USE_LOCKED {false} CONFIG.USE_RESET {false} CONFIG.CLKOUT1_DRIVES {BUFG} CONFIG.CLKOUT2_DRIVES {BUFG} CONFIG.CLKOUT3_DRIVES {BUFG} CONFIG.CLKOUT4_DRIVES {BUFG} CONFIG.CLKOUT5_DRIVES {BUFG} CONFIG.CLKOUT6_DRIVES {BUFG} CONFIG.CLKOUT7_DRIVES {BUFG} CONFIG.MMCM_BANDWIDTH {OPTIMIZED} CONFIG.MMCM_CLKFBOUT_MULT_F {9} CONFIG.MMCM_COMPENSATION {ZHOLD} CONFIG.MMCM_CLKOUT0_DIVIDE_F {9} CONFIG.MMCM_CLKOUT1_DIVIDE {9} CONFIG.NUM_OUT_CLKS {2} CONFIG.CLKOUT1_JITTER {137.681} CONFIG.CLKOUT1_PHASE_ERROR {105.461} CONFIG.CLKOUT2_JITTER {137.681} CONFIG.CLKOUT2_PHASE_ERROR {105.461}] [get_bd_cells clk_wiz_0]

#Add Memory modules for processing system
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0
set_property name dmem [get_bd_cells axi_bram_ctrl_0]
set_property -dict [list CONFIG.PROTOCOL {AXI4LITE} CONFIG.ECC_TYPE {0} CONFIG.SINGLE_PORT_BRAM {1}] [get_bd_cells dmem]

create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0
set_property name ram [get_bd_cells blk_mem_gen_0]
connect_bd_intf_net [get_bd_intf_pins dmem/BRAM_PORTA] [get_bd_intf_pins ram/BRAM_PORTA]

#External Pins
make_bd_pins_external  [get_bd_pins util_vector_logic_0/Op1]
set_property name rstn_i [get_bd_ports Op1_0]

make_bd_pins_external  [get_bd_pins xlslice_0/Dout]
set_property name gpio_o [get_bd_ports Dout_0]

make_bd_pins_external  [get_bd_pins processing_system7_0/uart0_rxd_i]
make_bd_pins_external  [get_bd_pins processing_system7_0/uart0_txd_o]
set_property name uart0_rxd_i [get_bd_ports uart0_rxd_i_0]
set_property name uart0_txd_o [get_bd_ports uart0_txd_o_0]

make_bd_pins_external  [get_bd_pins clk_wiz_0/clk_in1]
set_property name clk_i [get_bd_ports clk_in1_0]

#PS Connections
connect_bd_net [get_bd_pins processing_system7_0/gpio_o] [get_bd_pins xlslice_0/Din]
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins processing_system7_0/gpio_i]
connect_bd_net [get_bd_pins xlconcat_0/dout] [get_bd_pins processing_system7_0/xirq_i]
connect_bd_net [get_bd_pins xlconstant_1/dout] [get_bd_pins xlconcat_0/In1]
connect_bd_net [get_bd_pins clk_wiz_0/main_out] [get_bd_pins processing_system7_0/main_clk]

    # Add AXI Busses and set properties
    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_mem
    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_hwt
    
    set_property -dict [ list CONFIG.NUM_MI {1}  ] [get_bd_cells axi_mem]
    set_property -dict [ list CONFIG.NUM_SI {2}  ] [get_bd_cells axi_mem]
    set_property -dict [ list CONFIG.NUM_MI {6}  ] [get_bd_cells axi_hwt]

     # PS memory interface 
    connect_bd_intf_net [get_bd_intf_pins processing_system7_0/m_axi] [get_bd_intf_pins axi_dmem/S00_AXI]
    connect_bd_intf_net -intf_net axi_dmem_M00_AXI [get_bd_intf_pins axi_dmem/M00_AXI] [get_bd_intf_pins dmem/S_AXI]

    # Memory clock connections
    connect_bd_net [get_bd_pins clk_wiz_0/main_out] [get_bd_pins reset_1/slowest_sync_clk] 
    connect_bd_net [get_bd_pins clk_wiz_0/main_out] [get_bd_pins axi_dmem/ACLK] 
    connect_bd_net [get_bd_pins clk_wiz_0/main_out] [get_bd_pins axi_dmem/M00_ACLK] 
    connect_bd_net [get_bd_pins clk_wiz_0/main_out] [get_bd_pins axi_dmem/S00_ACLK] 
    connect_bd_net [get_bd_pins clk_wiz_0/main_out] [get_bd_pins dmem/s_axi_aclk]

    # PS and Memory reset connections
    connect_bd_net [get_bd_pins reset_1/peripheral_aresetn] \
                            [get_bd_pins processing_system7_0/main_reset] \
                            [get_bd_pins dmem/s_axi_aresetn]
                            
                            
    connect_bd_net [get_bd_pins reset_1/interconnect_aresetn] \
                            [get_bd_pins axi_dmem/ARESETN] \
                            [get_bd_pins axi_dmem/S00_ARESETN] \
                            [get_bd_pins axi_dmem/M00_ARESETN]


    # Add reconos stuff
    create_bd_cell -type ip -vlnv cs.upb.de:reconos:reconos_clock:1.0 reconos_clock_0
    set_property -dict [list CONFIG.C_NUM_CLOCKS <<NUM_CLOCKS>>] [get_bd_cells reconos_clock_0]
    <<generate for CLOCKS>>
    set_property -dict [list CONFIG.C_CLK<<Id>>_CLKFBOUT_MULT <<M>>] [get_bd_cells reconos_clock_0]
    set_property -dict [list CONFIG.C_CLK<<Id>>_DIVCLK_DIVIDE 1    ] [get_bd_cells reconos_clock_0]
    set_property -dict [list CONFIG.C_CLK<<Id>>_CLKOUT_DIVIDE <<O>>] [get_bd_cells reconos_clock_0]
    <<end generate>>
    # Bugfix: literal for C_CLKIN_PERIOD has to be a real literal, e.g. needs to include the decimal point
    # Bugfix 2: Hmm, now vivado requests it to be an integer again....
    #set_property -dict [list CONFIG.C_CLKIN_PERIOD {10.0}] [get_bd_cells reconos_clock_0]
    
    create_bd_cell -type ip -vlnv cs.upb.de:reconos:reconos_memif_arbiter:1.0 reconos_memif_arbiter_0
    set_property -dict [list CONFIG.C_NUM_HWTS <<NUM_SLOTS>> ] [get_bd_cells reconos_memif_arbiter_0]
    
    create_bd_cell -type ip -vlnv cs.upb.de:reconos:reconos_memif_memory_controller:1.0 reconos_memif_memory_controller_0
    #create_bd_cell -type ip -vlnv cs.upb.de:reconos:reconos_memif_mmu_zynq:1.0 reconos_memif_mmu_zynq_0
    create_bd_cell -type ip -vlnv cs.upb.de:reconos:reconos_osif_intc:1.0 reconos_osif_intc_0
    set_property -dict [list CONFIG.C_NUM_INTERRUPTS <<NUM_SLOTS>> ] [get_bd_cells reconos_osif_intc_0]
    
    create_bd_cell -type ip -vlnv cs.upb.de:reconos:reconos_osif:1.0 reconos_osif_0
    set_property -dict [list CONFIG.C_NUM_HWTS  <<NUM_SLOTS>> ] [get_bd_cells reconos_osif_0]
    
    create_bd_cell -type ip -vlnv cs.upb.de:reconos:reconos_proc_control:1.0 reconos_proc_control_0
    set_property -dict [list CONFIG.C_NUM_HWTS  <<NUM_SLOTS>> ] [get_bd_cells reconos_proc_control_0]
    
    create_bd_cell -type ip -vlnv cs.upb.de:reconos:timer:1.0 timer_0

	<<generate for SLOTS>>
	create_bd_cell -type ip -vlnv cs.upb.de:reconos:<<HwtCoreName>>:[string range <<HwtCoreVersion>> 0 2] "slot_<<Id>>"
	
	<<end generate>>
        #"rt_sortdemo" { create_bd_cell -type ip -vlnv cs.upb.de:reconos:rt_sortdemo:1.0 "rt_sortdemo_$i" }
        
	<<generate for SLOTS(Async == "sync")>>
        # Add FIFOS between hardware threads and MEMIF and OSIF
        create_bd_cell -type ip -vlnv cs.upb.de:reconos:reconos_fifo_sync:1.0 "reconos_fifo_osif_hw2sw_<<Id>>"
        create_bd_cell -type ip -vlnv cs.upb.de:reconos:reconos_fifo_sync:1.0 "reconos_fifo_osif_sw2hw_<<Id>>"
        create_bd_cell -type ip -vlnv cs.upb.de:reconos:reconos_fifo_sync:1.0 "reconos_fifo_memif_hwt2mem_<<Id>>"
        create_bd_cell -type ip -vlnv cs.upb.de:reconos:reconos_fifo_sync:1.0 "reconos_fifo_memif_mem2hwt_<<Id>>"
	
	# Connect clock signals
	# FIFOs
        connect_bd_net [get_bd_pins reconos_clock_0/CLK<<SYSCLK>>_Out] [get_bd_pins "reconos_fifo_osif_hw2sw_<<Id>>/FIFO_Clk"]
        connect_bd_net [get_bd_pins reconos_clock_0/CLK<<SYSCLK>>_Out] [get_bd_pins "reconos_fifo_osif_sw2hw_<<Id>>/FIFO_Clk"]
        connect_bd_net [get_bd_pins reconos_clock_0/CLK<<SYSCLK>>_Out] [get_bd_pins "reconos_fifo_memif_hwt2mem_<<Id>>/FIFO_Clk"]
        connect_bd_net [get_bd_pins reconos_clock_0/CLK<<SYSCLK>>_Out] [get_bd_pins "reconos_fifo_memif_mem2hwt_<<Id>>/FIFO_Clk"]

	<<end generate>>

	<<generate for SLOTS(Async == "async")>>
	create_bd_cell -type ip -vlnv cs.upb.de:reconos:reconos_fifo_async:1.0 "reconos_fifo_osif_hw2sw_<<Id>>"
	create_bd_cell -type ip -vlnv cs.upb.de:reconos:reconos_fifo_async:1.0 "reconos_fifo_osif_sw2hw_<<Id>>"
	create_bd_cell -type ip -vlnv cs.upb.de:reconos:reconos_fifo_async:1.0 "reconos_fifo_memif_hwt2mem_<<Id>>"
	create_bd_cell -type ip -vlnv cs.upb.de:reconos:reconos_fifo_async:1.0 "reconos_fifo_memif_mem2hwt_<<Id>>"
	
	# Connect clock signals
	# FIFOs
	connect_bd_net [get_bd_pins reconos_clock_0/CLK<<SYSCLK>>_Out] [get_bd_pins "reconos_fifo_osif_hw2sw_<<Id>>/FIFO_S_Clk"]
	connect_bd_net [get_bd_pins reconos_clock_0/CLK<<Clk>>_Out] [get_bd_pins "reconos_fifo_osif_sw2hw_<<Id>>/FIFO_S_Clk"]
	connect_bd_net [get_bd_pins reconos_clock_0/CLK<<SYSCLK>>_Out] [get_bd_pins "reconos_fifo_memif_hwt2mem_<<Id>>/FIFO_S_Clk"]
	connect_bd_net [get_bd_pins reconos_clock_0/CLK<<Clk>>_Out] [get_bd_pins "reconos_fifo_memif_mem2hwt_<<Id>>/FIFO_S_Clk"]
	
	connect_bd_net [get_bd_pins reconos_clock_0/CLK<<Clk>>_Out] [get_bd_pins "reconos_fifo_osif_hw2sw_<<Id>>/FIFO_M_Clk"]
	connect_bd_net [get_bd_pins reconos_clock_0/CLK<<SYSCLK>>_Out] [get_bd_pins "reconos_fifo_osif_sw2hw_<<Id>>/FIFO_M_Clk"]
	connect_bd_net [get_bd_pins reconos_clock_0/CLK<<Clk>>_Out] [get_bd_pins "reconos_fifo_memif_hwt2mem_<<Id>>/FIFO_M_Clk"]
	connect_bd_net [get_bd_pins reconos_clock_0/CLK<<SYSCLK>>_Out] [get_bd_pins "reconos_fifo_memif_mem2hwt_<<Id>>/FIFO_M_Clk"]

	<<end generate>>

        # Add connections between FIFOs and other modules
	<<generate for SLOTS>>
        connect_bd_intf_net [get_bd_intf_pins "slot_<<Id>>/OSIF_Hw2SW"] [get_bd_intf_pins "reconos_fifo_osif_hw2sw_<<Id>>/FIFO_M"]
        connect_bd_intf_net [get_bd_intf_pins "slot_<<Id>>/OSIF_Sw2Hw"] [get_bd_intf_pins "reconos_fifo_osif_sw2hw_<<Id>>/FIFO_S"]
        connect_bd_intf_net [get_bd_intf_pins "reconos_fifo_osif_hw2sw_<<Id>>/FIFO_S"] [get_bd_intf_pins "reconos_osif_0/OSIF_hw2sw_<<Id>>"]
        connect_bd_intf_net [get_bd_intf_pins "reconos_fifo_osif_sw2hw_<<Id>>/FIFO_M"] [get_bd_intf_pins "reconos_osif_0/OSIF_sw2hw_<<Id>>"]
        connect_bd_net [get_bd_pins "reconos_fifo_osif_hw2sw_<<Id>>/FIFO_Has_Data"] [get_bd_pins "reconos_osif_intc_0/OSIF_INTC_In_<<Id>>"]

        connect_bd_intf_net [get_bd_intf_pins "slot_<<Id>>/MEMIF_Hwt2Mem"] [get_bd_intf_pins "reconos_fifo_memif_hwt2mem_<<Id>>/FIFO_M"]
        connect_bd_intf_net [get_bd_intf_pins "slot_<<Id>>/MEMIF_Mem2Hwt"] [get_bd_intf_pins "reconos_fifo_memif_mem2hwt_<<Id>>/FIFO_S"]
        connect_bd_intf_net [get_bd_intf_pins "reconos_memif_arbiter_0/MEMIF_Hwt2Mem_<<Id>>"] [get_bd_intf_pins "reconos_fifo_memif_hwt2mem_<<Id>>/FIFO_S"]
        connect_bd_intf_net [get_bd_intf_pins "reconos_memif_arbiter_0/MEMIF_Mem2Hwt_<<Id>>"] [get_bd_intf_pins "reconos_fifo_memif_mem2hwt_<<Id>>/FIFO_M"]
        
        # Set sizes of FIFOs
        set_property -dict [list CONFIG.C_FIFO_ADDR_WIDTH {3}] [get_bd_cells "reconos_fifo_osif_hw2sw_<<Id>>"]
        set_property -dict [list CONFIG.C_FIFO_ADDR_WIDTH {3}] [get_bd_cells "reconos_fifo_osif_sw2hw_<<Id>>"]
        
        set_property -dict [list CONFIG.C_FIFO_ADDR_WIDTH {7}] [get_bd_cells "reconos_fifo_memif_hwt2mem_<<Id>>"]
        set_property -dict [list CONFIG.C_FIFO_ADDR_WIDTH {7}] [get_bd_cells "reconos_fifo_memif_mem2hwt_<<Id>>"]

        # HWTs
        connect_bd_net [get_bd_pins reconos_clock_0/CLK<<Clk>>_Out] [get_bd_pins "slot_<<Id>>/HWT_Clk"]

        # Resets
        connect_bd_net [get_bd_pins "reconos_proc_control_0/PROC_Hwt_Rst_<<Id>>"] [get_bd_pins "slot_<<Id>>/HWT_Rst"]
        connect_bd_net [get_bd_pins "reconos_proc_control_0/PROC_Hwt_Rst_<<Id>>"] [get_bd_pins "reconos_fifo_memif_mem2hwt_<<Id>>/FIFO_Rst"]
        connect_bd_net [get_bd_pins "reconos_proc_control_0/PROC_Hwt_Rst_<<Id>>"] [get_bd_pins "reconos_fifo_memif_hwt2mem_<<Id>>/FIFO_Rst"]
        connect_bd_net [get_bd_pins "reconos_proc_control_0/PROC_Hwt_Rst_<<Id>>"] [get_bd_pins "reconos_fifo_osif_hw2sw_<<Id>>/FIFO_Rst"]
        connect_bd_net [get_bd_pins "reconos_proc_control_0/PROC_Hwt_Rst_<<Id>>"] [get_bd_pins "reconos_fifo_osif_sw2hw_<<Id>>/FIFO_Rst"]

	# Misc
        connect_bd_net [get_bd_pins "reconos_proc_control_0/PROC_Hwt_Signal_<<Id>>"] [get_bd_pins "slot_<<Id>>/HWT_Signal"]
	<<end generate>>


    #
    # Connections between components
    #

    # AXI
    connect_bd_intf_net -intf_net reconos_memif_memory_controller_0_M_AXI [get_bd_intf_pins reconos_memif_memory_controller_0/M_AXI] [get_bd_intf_pins axi_mem/S01_AXI]
    
    connect_bd_intf_net -intf_net axi_hwt_S00_AXI [get_bd_intf_pins axi_hwt/S00_AXI] [get_bd_intf_pins processing_system7_0/m_axi] 
    connect_bd_intf_net -intf_net axi_hwt_M01_AXI [get_bd_intf_pins axi_hwt/M01_AXI] [get_bd_intf_pins reconos_clock_0/S_AXI] 
    connect_bd_intf_net -intf_net axi_hwt_M02_AXI [get_bd_intf_pins axi_hwt/M02_AXI] [get_bd_intf_pins reconos_osif_intc_0/S_AXI]
    connect_bd_intf_net -intf_net axi_hwt_M03_AXI [get_bd_intf_pins axi_hwt/M03_AXI] [get_bd_intf_pins reconos_osif_0/S_AXI]
    connect_bd_intf_net -intf_net axi_hwt_M04_AXI [get_bd_intf_pins axi_hwt/M04_AXI] [get_bd_intf_pins reconos_proc_control_0/S_AXI]
    connect_bd_intf_net -intf_net axi_hwt_M05_AXI [get_bd_intf_pins axi_hwt/M05_AXI] [get_bd_intf_pins timer_0/S_AXI]
    connect_bd_intf_net -intf_net axi_hwt_M00_AXI [get_bd_intf_pins axi_hwt/M00_AXI] [get_bd_intf_pins axi_mem/S00_AXI]


    # Memory controller
    #connect_bd_intf_net [get_bd_intf_pins reconos_memif_memory_controller_0/MEMIF_Hwt2Mem_In] [get_bd_intf_pins reconos_memif_mmu_zynq_0/MEMIF_Hwt2Mem_Out]
    #connect_bd_intf_net [get_bd_intf_pins reconos_memif_memory_controller_0/MEMIF_Mem2Hwt_In] [get_bd_intf_pins reconos_memif_mmu_zynq_0/MEMIF_Mem2Hwt_Out]

    connect_bd_intf_net [get_bd_intf_pins reconos_memif_memory_controller_0/MEMIF_Hwt2Mem_In] [get_bd_intf_pins reconos_memif_arbiter_0/MEMIF_Hwt2Mem_OUT]
    connect_bd_intf_net [get_bd_intf_pins reconos_memif_memory_controller_0/MEMIF_Mem2Hwt_In] [get_bd_intf_pins reconos_memif_arbiter_0/MEMIF_Mem2Hwt_Out]
    #MMU
    # connect_bd_intf_net [get_bd_intf_pins reconos_memif_mmu_zynq_0/MEMIF_Hwt2Mem_In] [get_bd_intf_pins reconos_memif_arbiter_0/MEMIF_Hwt2Mem_OUT]
    # connect_bd_intf_net [get_bd_intf_pins reconos_memif_mmu_zynq_0/MEMIF_Mem2Hwt_In] [get_bd_intf_pins reconos_memif_arbiter_0/MEMIF_Mem2Hwt_Out]
    # connect_bd_net [get_bd_pins reconos_memif_mmu_zynq_0/MMU_Pgf] [get_bd_pins reconos_proc_control_0/MMU_Pgf]
    # connect_bd_net [get_bd_pins reconos_memif_mmu_zynq_0/MMU_Retry] [get_bd_pins reconos_proc_control_0/MMU_Retry]
    # connect_bd_net [get_bd_pins reconos_memif_mmu_zynq_0/MMU_Pgd] [get_bd_pins reconos_proc_control_0/MMU_Pgd]
    # connect_bd_net [get_bd_pins reconos_memif_mmu_zynq_0/MMU_Fault_Addr] [get_bd_pins reconos_proc_control_0/MMU_Fault_Addr]
    # set_property -dict [list CONFIG.C_TLB_SIZE {16}] [get_bd_cells reconos_memif_mmu_zynq_0]

    #
    # Connect clocks - most clock inputs come from the reconos_clock module
    #
    connect_bd_net [get_bd_pins clk_wiz_0/FCLK_0] [get_bd_pins reconos_clock_0/CLK_Ref]


    connect_bd_net [get_bd_pins reconos_clock_0/CLK<<SYSCLK>>_Out] \
                          [get_bd_pins reconos_clock_0/S_AXI_ACLK] \
                          [get_bd_pins reconos_memif_memory_controller_0/M_AXI_ACLK] \
                          [get_bd_pins reconos_memif_arbiter_0/SYS_Clk] \
                          [get_bd_pins axi_hwt/S00_ACLK] \
                          [get_bd_pins axi_hwt/M00_ACLK] \
                          [get_bd_pins axi_hwt/M01_ACLK] \
                          [get_bd_pins axi_hwt/M02_ACLK] \
                          [get_bd_pins axi_hwt/M03_ACLK] \
                          [get_bd_pins axi_hwt/M04_ACLK] \
                          [get_bd_pins axi_hwt/ACLK] \
                          [get_bd_pins axi_mem/S00_ACLK] \
                          [get_bd_pins axi_mem/M00_ACLK] \
                          [get_bd_pins axi_mem/ACLK] \
                          [get_bd_pins axi_dmem/M01_ACLK] \
                          [get_bd_pins axi_dmem/S01_ACLK] \
                          [get_bd_pins reconos_osif_0/S_AXI_ACLK] \
                          [get_bd_pins reconos_osif_intc_0/S_AXI_ACLK] \
                          [get_bd_pins reconos_proc_control_0/S_AXI_ACLK] \
                          [get_bd_pins reset_0/slowest_sync_clk] \
                          [get_bd_pins timer_0/S_AXI_ACLK]
    #
    # Connect Resets
    #
    connect_bd_net [get_bd_pins reconos_clock_0/CLK<<SYSCLK>>_Locked] [get_bd_pins reset_0/DCM_Locked] 

    connect_bd_net [get_bd_pins reset_0/Interconnect_aresetn] \
                            [get_bd_pins axi_hwt/M00_ARESETN] \
                            [get_bd_pins axi_hwt/M01_ARESETN] \
                            [get_bd_pins axi_hwt/M02_ARESETN] \
                            [get_bd_pins axi_hwt/M03_ARESETN] \
                            [get_bd_pins axi_hwt/M04_ARESETN] \
                            [get_bd_pins axi_hwt/S00_ARESETN] \
                            [get_bd_pins axi_hwt/ARESETN] \
                            [get_bd_pins axi_mem/S00_ARESETN] \
                            [get_bd_pins axi_mem/ARESETN] \
                            [get_bd_pins axi_mem/M00_ARESETN] \
                            [get_bd_pins axi_dmem/S01_ARESETN] \
                            [get_bd_pins axi_dmem/M01_ARESETN]

    
    connect_bd_net [get_bd_pins util_vector_logic_0/Res] [get_bd_pins reset_0/ext_reset_in]
    connect_bd_net [get_bd_pins reset_1/ext_reset_in] [get_bd_pins util_vector_logic_0/Res]

    # Proc_control resets
    connect_bd_net [get_bd_pins reconos_proc_control_0/PROC_Sys_Rst] [get_bd_pins reconos_memif_arbiter_0/SYS_Rst]
    #connect_bd_net [get_bd_pins reconos_memif_mmu_zynq_0/SYS_Rst] [get_bd_pins reconos_proc_control_0/PROC_Sys_Rst]

    # ReconoOS Peripherals reset by peripheral_aresetn
    connect_bd_net [get_bd_pins reset_0/peripheral_aresetn] [get_bd_pins reconos_clock_0/S_AXI_ARESETN]
    connect_bd_net [get_bd_pins reset_0/peripheral_aresetn] [get_bd_pins timer_0/S_AXI_ARESETN]
    connect_bd_net [get_bd_pins reset_0/peripheral_aresetn] [get_bd_pins reconos_proc_control_0/S_AXI_ARESETN]
    connect_bd_net [get_bd_pins reset_0/peripheral_aresetn] [get_bd_pins reconos_osif_intc_0/S_AXI_ARESETN]
    connect_bd_net [get_bd_pins reset_0/peripheral_aresetn] [get_bd_pins reconos_osif_0/S_AXI_ARESETN]
    connect_bd_net [get_bd_pins reset_0/peripheral_aresetn] [get_bd_pins reconos_memif_memory_controller_0/M_AXI_ARESETN]

    #
    # Connect interrupts
    #
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_2
    set_property -dict [list CONFIG.CONST_VAL {0}] [get_bd_cells xlconstant_2]
    
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_1
    set_property -dict [list CONFIG.NUM_PORTS {16}] [get_bd_cells xlconcat_1]
    
    # This is needed to shift the interrupt lines to the right positions
    connect_bd_net [get_bd_pins xlconstant_2/dout] [get_bd_pins xlconcat_1/In0]
    connect_bd_net [get_bd_pins xlconstant_2/dout] [get_bd_pins xlconcat_1/In1]
    connect_bd_net [get_bd_pins xlconstant_2/dout] [get_bd_pins xlconcat_1/In2]
    connect_bd_net [get_bd_pins xlconstant_2/dout] [get_bd_pins xlconcat_1/In3]
    connect_bd_net [get_bd_pins xlconstant_2/dout] [get_bd_pins xlconcat_1/In4]
    connect_bd_net [get_bd_pins xlconstant_2/dout] [get_bd_pins xlconcat_1/In5]
    connect_bd_net [get_bd_pins xlconstant_2/dout] [get_bd_pins xlconcat_1/In6]
    connect_bd_net [get_bd_pins xlconstant_2/dout] [get_bd_pins xlconcat_1/In7]
    connect_bd_net [get_bd_pins xlconstant_2/dout] [get_bd_pins xlconcat_1/In8]
    connect_bd_net [get_bd_pins xlconstant_2/dout] [get_bd_pins xlconcat_1/In9]
    connect_bd_net [get_bd_pins xlconstant_2/dout] [get_bd_pins xlconcat_1/In10]
    connect_bd_net [get_bd_pins xlconstant_2/dout] [get_bd_pins xlconcat_1/In11]
    connect_bd_net [get_bd_pins xlconstant_2/dout] [get_bd_pins xlconcat_1/In12]
    connect_bd_net [get_bd_pins xlconstant_2/dout] [get_bd_pins xlconcat_1/In13]
    connect_bd_net [get_bd_pins reconos_osif_intc_0/OSIF_INTC_Out] [get_bd_pins xlconcat_1/In14]
    connect_bd_net [get_bd_pins reconos_proc_control_0/PROC_Pgf_Int] [get_bd_pins xlconcat_1/In15]
    connect_bd_net [get_bd_pins xlconcat_1/dout] [get_bd_pins xlconcat_0/In0]


    #
    # Memory Map of peripheperals
    #

    set_property -dict [list CONFIG.C_BASEADDR {0x86fe0000} CONFIG.C_HIGHADDR {0x86feffff}] [get_bd_cells reconos_proc_control_0]
    set_property -dict [list CONFIG.C_BASEADDR {0x875a0000} CONFIG.C_HIGHADDR {0x875affff}] [get_bd_cells reconos_osif_0]
    set_property -dict [list CONFIG.C_BASEADDR {0x864a0000} CONFIG.C_HIGHADDR {0x864affff}] [get_bd_cells timer_0]
    set_property -dict [list CONFIG.C_BASEADDR {0x87b40000} CONFIG.C_HIGHADDR {0x87b4ffff}] [get_bd_cells reconos_osif_intc_0]
    set_property -dict [list CONFIG.C_BASEADDR {0x869e0000} CONFIG.C_HIGHADDR {0x869effff}] [get_bd_cells reconos_clock_0]

    create_bd_addr_seg -range 64K -offset 0x86FE0000 [get_bd_addr_spaces processing_system7_0/m_axi] [get_bd_addr_segs {reconos_proc_control_0/S_AXI/reg0 }] SEG1
    create_bd_addr_seg -range 64K -offset 0x875a0000 [get_bd_addr_spaces processing_system7_0/m_axi] [get_bd_addr_segs {reconos_osif_0/S_AXI/reg0 }] SEG2
    create_bd_addr_seg -range 64K -offset 0x864a0000 [get_bd_addr_spaces processing_system7_0/m_axi] [get_bd_addr_segs {timer_0/S_AXI/reg0 }] SEG3
    create_bd_addr_seg -range 64K -offset 0x87b40000 [get_bd_addr_spaces processing_system7_0/m_axi] [get_bd_addr_segs {reconos_osif_intc_0/S_AXI/reg0 }] SEG4
    create_bd_addr_seg -range 64K -offset 0x869e0000 [get_bd_addr_spaces processing_system7_0/m_axi] [get_bd_addr_segs {reconos_clock_0/S_AXI/reg0 }] SEG5
    
    exclude_bd_addr_seg [get_bd_addr_segs reconos_clock_0/S_AXI/reg0] -target_address_space [get_bd_addr_spaces reconos_memif_memory_controller_0/M_AXI]
    exclude_bd_addr_seg [get_bd_addr_segs reconos_osif_0/S_AXI/reg0] -target_address_space [get_bd_addr_spaces reconos_memif_memory_controller_0/M_AXI]
    exclude_bd_addr_seg [get_bd_addr_segs reconos_osif_intc_0/S_AXI/reg0] -target_address_space [get_bd_addr_spaces reconos_memif_memory_controller_0/M_AXI]
    exclude_bd_addr_seg [get_bd_addr_segs reconos_proc_control_0/S_AXI/reg0] -target_address_space [get_bd_addr_spaces reconos_memif_memory_controller_0/M_AXI]
    exclude_bd_addr_seg [get_bd_addr_segs timer_0/S_AXI/reg0] -target_address_space [get_bd_addr_spaces reconos_memif_memory_controller_0/M_AXI]
    
    assign_bd_address [get_bd_addr_segs {dmem/S_AXI/Mem0 }]
    set_property offset 0x80000000 [get_bd_addr_segs {processing_system7_0/m_axi/SEG_dmem_Mem0}]
    set_property range 64K [get_bd_addr_segs {processing_system7_0/m_axi/SEG_dmem_Mem0}]
    set_property offset 0x80000000 [get_bd_addr_segs {reconos_memif_memory_controller_0/M_AXI/SEG_dmem_Mem0}]
    set_property range 64K [get_bd_addr_segs {reconos_memif_memory_controller_0/M_AXI/SEG_dmem_Mem0}]

    set_property -dict [list CONFIG.MEM_INT_DMEM_EN {false}] [get_bd_cells processing_system7_0]

    # Update layout of block design
    regenerate_bd_layout

    #make wrapper file; vivado needs it to implement design
    make_wrapper -files [get_files $proj_dir/$proj_name.srcs/sources_1/bd/design_1/design_1.bd] -top
    add_files -norecurse $proj_dir/$proj_name.srcs/sources_1/bd/design_1/hdl/design_1_wrapper.vhd
    update_compile_order -fileset sources_1
    update_compile_order -fileset sim_1
    set_property top design_1_wrapper [current_fileset]
	
	# Set BD generation mode to global (defaults to OOC only from Vivado 2016.3 onwards)
	set_property synth_checkpoint_mode None [get_files $proj_dir/$proj_name.srcs/sources_1/bd/design_1/design_1.bd]
	
  # Generate bitstream in .bin format (in addition to .bit)
  set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]

    save_bd_design
}

#
# MAIN
#

reconos_hw_setup $proj_name $proj_path $reconos_ip_dir
puts "\[RDK\]: Project creation finished."


