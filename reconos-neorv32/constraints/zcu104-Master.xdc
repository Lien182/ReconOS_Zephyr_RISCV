## LEDS
set_property PACKAGE_PIN D5       [get_ports { gpio_o[0] }] ;# Bank  88 VCCO - VCC3V3   - IO_L11N_AD9N_88
set_property IOSTANDARD  LVCMOS33 [get_ports { gpio_o[0] }] ;# Bank  88 VCCO - VCC3V3   - IO_L11N_AD9N_88
set_property PACKAGE_PIN D6       [get_ports { gpio_o[1] }] ;# Bank  88 VCCO - VCC3V3   - IO_L11P_AD9P_88
set_property IOSTANDARD  LVCMOS33 [get_ports { gpio_o[1] }] ;# Bank  88 VCCO - VCC3V3   - IO_L11P_AD9P_88
set_property PACKAGE_PIN A5       [get_ports { gpio_o[2] }] ;# Bank  88 VCCO - VCC3V3   - IO_L10N_AD10N_88
set_property IOSTANDARD  LVCMOS33 [get_ports { gpio_o[2] }] ;# Bank  88 VCCO - VCC3V3   - IO_L10N_AD10N_88
set_property PACKAGE_PIN B5       [get_ports { gpio_o[3] }] ;# Bank  88 VCCO - VCC3V3   - IO_L10P_AD10P_88
set_property IOSTANDARD  LVCMOS33 [get_ports { gpio_o[3] }] ;# Bank  88 VCCO - VCC3V3   - IO_L10P_AD10P_88
set_property PACKAGE_PIN G8       [get_ports { gpio_o[4] } ] ;# Bank  87 VCCO - VCC3V3   - IO_L12N_AD0N_87
set_property IOSTANDARD  LVCMOS33 [get_ports { gpio_o[4] } ] ;# Bank  87 VCCO - VCC3V3   - IO_L12N_AD0N_87 
set_property PACKAGE_PIN H8       [get_ports { gpio_o[5] } ] ;# Bank  87 VCCO - VCC3V3   - IO_L12P_AD0P_87
set_property IOSTANDARD  LVCMOS33 [get_ports { gpio_o[5] } ] ;# Bank  87 VCCO - VCC3V3   - IO_L12P_AD0P_87
set_property PACKAGE_PIN G7       [get_ports { gpio_o[6] } ] ;# Bank  87 VCCO - VCC3V3   - IO_L11N_AD1N_87
set_property IOSTANDARD  LVCMOS33 [get_ports { gpio_o[6] } ] ;# Bank  87 VCCO - VCC3V3   - IO_L11N_AD1N_87
set_property PACKAGE_PIN H7       [get_ports { gpio_o[7] } ] ;# Bank  87 VCCO - VCC3V3   - IO_L11P_AD1P_87
set_property IOSTANDARD  LVCMOS33 [get_ports { gpio_o[7] } ] ;# Bank  87 VCCO - VCC3V3   - IO_L11P_AD1P_87

#Buttons
set_property PACKAGE_PIN B4       [get_ports { rstn_i }] ;# Bank  88 VCCO - VCC3V3   - IO_L7N_HDGC_88
set_property IOSTANDARD  LVCMOS33 [get_ports { rstn_i }] ;# Bank  88 VCCO - VCC3V3   - IO_L7N_HDGC_88

##USB-RS232 Interface
set_property PACKAGE_PIN A20      [get_ports { uart0_rxd_i } ] ;# Bank  28 VCCO - VCC1V8   - IO_L21P_T3L_N4_AD8P_28 uart2_rxd
set_property IOSTANDARD  LVCMOS18 [get_ports { uart0_rxd_i } ] ;# Bank  28 VCCO - VCC1V8   - IO_L21P_T3L_N4_AD8P_28
set_property PACKAGE_PIN C19      [get_ports { uart0_txd_o } ] ;# Bank  28 VCCO - VCC1V8   - IO_L20N_T3L_N3_AD1N_28 uart2_txd
set_property IOSTANDARD  LVCMOS18 [get_ports { uart0_txd_o } ] ;# Bank  28 VCCO - VCC1V8   - IO_L20N_T3L_N3_AD1N_28
