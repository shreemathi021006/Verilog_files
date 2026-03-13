create_clock -period 10 [get_ports hclk]

set_input_delay 2 -clock hclk  [all_inputs] 
set_output_delay 2 -clock hclk [all_outputs]