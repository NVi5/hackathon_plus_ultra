create_clock -period 50MHz [get_ports {CLK_50}]
create_clock -period 50MHz [get_ports {L1_OSC}]


set_clock_groups -asynchronous -group [get_clocks {CLK_50}] \
-group [get_clocks {L1_OSC}] \
-group [get_clocks {altera_reserved_tck}]
