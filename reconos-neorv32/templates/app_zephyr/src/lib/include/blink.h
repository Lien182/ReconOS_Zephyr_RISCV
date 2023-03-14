#include <zephyr/zephyr.h>
#define NEORV32_GPIO_BASE (0xFFFFFFC0U)
#define NEORV32_GPIO (*((volatile neorv32_gpio_t*) (NEORV32_GPIO_BASE)))

typedef struct __attribute__((packed,aligned(4))) {
  const uint32_t INPUT_LO;  /**< offset 0:  parallel input port lower 32-bit, read-only */
  const uint32_t INPUT_HI;  /**< offset 4:  parallel input port upper 32-bit, read-only */
  uint32_t       OUTPUT_LO; /**< offset 8:  parallel output port lower 32-bit */
  uint32_t       OUTPUT_HI; /**< offset 12: parallel output port upper 32-bit */
} neorv32_gpio_t;

void neorv32_gpio_port_set(uint64_t port_data);