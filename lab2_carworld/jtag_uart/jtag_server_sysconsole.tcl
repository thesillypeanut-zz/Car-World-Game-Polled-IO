# -----------------------------------------------------------------
# jtag_server.tcl
#
# 9/14/2011 D. W. Hawkins (dwh@ovro.caltech.edu)
# 10/2/2015 Kevin Nam (knam@altera.com) - modified to use systemconsole commands thru JTAG-to-Avalon Bridge
#
# Altera JTAG socket server.
#
# This script sets up the server environment, accesses the JTAG
# device (if not in debug mode), and then starts the server.
#
# -----------------------------------------------------------------
# Notes:
# ------
#
# 1. Command line operation
#
#    quartus_stp -t jtag_server.tcl <port> <debug>
#
#    where 
#
#    <port>   Server port number (defaults to 2540)
#
#    <debug>  Debug flag (defaults to 0)
#
#             If <debug> = 1, the server runs in debug mode, where
#             reads and writes are performed on a Tcl variable,
#             rather than to the JTAG interface.
#
#  2. Console operation
#
#     The port number and debug flag can be set prior to sourcing
#     the script from a Tcl console.
#
# -----------------------------------------------------------------
# References
# ----------
#
# 1. Brent Welch, "Practical Programming in Tcl and Tk",
#    3rd Ed, 2000.
#
# -----------------------------------------------------------------

# -----------------------------------------------------------------
# Load the server commands
# -----------------------------------------------------------------
#
source ./jtag_server_cmds_systemconsole.tcl

# -----------------------------------------------------------------
# Check the Tcl console supports JTAG
# -----------------------------------------------------------------
#
# if {![is_tool_ok]} {
	# puts "Sorry, this script can only run using quartus_stp or SystemConsole"
	# return
# }

# -----------------------------------------------------------------
# Command line arguments?
# -----------------------------------------------------------------

# port
if {$::argc > 0} {
    set port [lindex $::argv 0]
}
if {![info exists port]} {
	set port 2540
}

# -----------------------------------------------------------------
# Start-up message
# -----------------------------------------------------------------
#

puts "Starting the JTAG-to-Avalon Bridge Server. Designed for the DE1-SoC Board."

# DEFINE THE CABLE NAME HERE.
set cable_name "DE-SoC"

# Open up the device
set device_service_paths [get_service_paths device]
set device_service_path [lindex $device_service_paths [lsearch $device_service_paths "*$cable_name*"]]
set master_service_paths [get_service_paths master]
# JTAG-to-AVALON has id 132
set jtag_avalon_bridge_service_path [lindex $master_service_paths [lsearch $master_service_paths "*:132*"]]

# Open the jtag-to-avalon bridge service
open_service master $jtag_avalon_bridge_service_path
puts "JTAG-to-Avalon Bridge opened!"

# -----------------------------------------------------------------
# Start the server and wait for clients
# -----------------------------------------------------------------
#
puts "Start the server on port $port\n"
server_listen $port

puts "Wait for clients\n"
vwait forever
