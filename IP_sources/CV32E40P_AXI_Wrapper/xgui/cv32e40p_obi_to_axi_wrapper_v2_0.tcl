# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "boot_addr" -parent ${Page_0}
  ipgui::add_param $IPINST -name "dm_exception_addr" -parent ${Page_0}
  ipgui::add_param $IPINST -name "dm_halt_addr" -parent ${Page_0}
  ipgui::add_param $IPINST -name "hart_id" -parent ${Page_0}
  ipgui::add_param $IPINST -name "mtvec_addr" -parent ${Page_0}


}

proc update_PARAM_VALUE.boot_addr { PARAM_VALUE.boot_addr } {
	# Procedure called to update boot_addr when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.boot_addr { PARAM_VALUE.boot_addr } {
	# Procedure called to validate boot_addr
	return true
}

proc update_PARAM_VALUE.dm_exception_addr { PARAM_VALUE.dm_exception_addr } {
	# Procedure called to update dm_exception_addr when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.dm_exception_addr { PARAM_VALUE.dm_exception_addr } {
	# Procedure called to validate dm_exception_addr
	return true
}

proc update_PARAM_VALUE.dm_halt_addr { PARAM_VALUE.dm_halt_addr } {
	# Procedure called to update dm_halt_addr when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.dm_halt_addr { PARAM_VALUE.dm_halt_addr } {
	# Procedure called to validate dm_halt_addr
	return true
}

proc update_PARAM_VALUE.hart_id { PARAM_VALUE.hart_id } {
	# Procedure called to update hart_id when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.hart_id { PARAM_VALUE.hart_id } {
	# Procedure called to validate hart_id
	return true
}

proc update_PARAM_VALUE.mtvec_addr { PARAM_VALUE.mtvec_addr } {
	# Procedure called to update mtvec_addr when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.mtvec_addr { PARAM_VALUE.mtvec_addr } {
	# Procedure called to validate mtvec_addr
	return true
}


proc update_MODELPARAM_VALUE.boot_addr { MODELPARAM_VALUE.boot_addr PARAM_VALUE.boot_addr } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.boot_addr}] ${MODELPARAM_VALUE.boot_addr}
}

proc update_MODELPARAM_VALUE.mtvec_addr { MODELPARAM_VALUE.mtvec_addr PARAM_VALUE.mtvec_addr } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.mtvec_addr}] ${MODELPARAM_VALUE.mtvec_addr}
}

proc update_MODELPARAM_VALUE.dm_halt_addr { MODELPARAM_VALUE.dm_halt_addr PARAM_VALUE.dm_halt_addr } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.dm_halt_addr}] ${MODELPARAM_VALUE.dm_halt_addr}
}

proc update_MODELPARAM_VALUE.hart_id { MODELPARAM_VALUE.hart_id PARAM_VALUE.hart_id } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.hart_id}] ${MODELPARAM_VALUE.hart_id}
}

proc update_MODELPARAM_VALUE.dm_exception_addr { MODELPARAM_VALUE.dm_exception_addr PARAM_VALUE.dm_exception_addr } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.dm_exception_addr}] ${MODELPARAM_VALUE.dm_exception_addr}
}

