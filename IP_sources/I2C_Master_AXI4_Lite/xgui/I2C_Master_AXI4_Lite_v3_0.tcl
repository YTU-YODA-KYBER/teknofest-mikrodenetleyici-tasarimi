# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "CLK_FREQ_HZ" -parent ${Page_0}
  ipgui::add_param $IPINST -name "HALF_PERIOD" -parent ${Page_0}
  ipgui::add_param $IPINST -name "I2C_FREQ_HZ" -parent ${Page_0}


}

proc update_PARAM_VALUE.CLK_FREQ_HZ { PARAM_VALUE.CLK_FREQ_HZ } {
	# Procedure called to update CLK_FREQ_HZ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CLK_FREQ_HZ { PARAM_VALUE.CLK_FREQ_HZ } {
	# Procedure called to validate CLK_FREQ_HZ
	return true
}

proc update_PARAM_VALUE.HALF_PERIOD { PARAM_VALUE.HALF_PERIOD } {
	# Procedure called to update HALF_PERIOD when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.HALF_PERIOD { PARAM_VALUE.HALF_PERIOD } {
	# Procedure called to validate HALF_PERIOD
	return true
}

proc update_PARAM_VALUE.I2C_FREQ_HZ { PARAM_VALUE.I2C_FREQ_HZ } {
	# Procedure called to update I2C_FREQ_HZ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.I2C_FREQ_HZ { PARAM_VALUE.I2C_FREQ_HZ } {
	# Procedure called to validate I2C_FREQ_HZ
	return true
}


proc update_MODELPARAM_VALUE.CLK_FREQ_HZ { MODELPARAM_VALUE.CLK_FREQ_HZ PARAM_VALUE.CLK_FREQ_HZ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CLK_FREQ_HZ}] ${MODELPARAM_VALUE.CLK_FREQ_HZ}
}

proc update_MODELPARAM_VALUE.I2C_FREQ_HZ { MODELPARAM_VALUE.I2C_FREQ_HZ PARAM_VALUE.I2C_FREQ_HZ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.I2C_FREQ_HZ}] ${MODELPARAM_VALUE.I2C_FREQ_HZ}
}

proc update_MODELPARAM_VALUE.HALF_PERIOD { MODELPARAM_VALUE.HALF_PERIOD PARAM_VALUE.HALF_PERIOD } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.HALF_PERIOD}] ${MODELPARAM_VALUE.HALF_PERIOD}
}

