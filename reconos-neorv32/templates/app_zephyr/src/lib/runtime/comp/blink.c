#include "blink.h"
/**********************************************************************//**
 * Main function; shows an incrementing 8-bit counter on GPIO.output(7:0).
 *
 * @note This program requires the GPIO controller to be synthesized.
 *
 * @return Will never return.
 **************************************************************************/
void neorv32_gpio_port_set(uint64_t port_data) {
  union {
    uint64_t uint64;
    uint32_t uint32[sizeof(uint64_t)/sizeof(uint32_t)];
  } data;

  data.uint64 = port_data;
  NEORV32_GPIO.OUTPUT_LO = data.uint32[0];
  NEORV32_GPIO.OUTPUT_HI = data.uint32[1];
}