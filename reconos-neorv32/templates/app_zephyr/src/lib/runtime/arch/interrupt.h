#include <zephyr/zephyr.h>
#define asm __asm__

/** XIRQ module base address */
#define NEORV32_XIRQ_BASE (0xFFFFFF80U)

/** XIRQ module hardware access (#neorv32_xirq_t) */
#define NEORV32_XIRQ (*((volatile neorv32_xirq_t*) (NEORV32_XIRQ_BASE)))

/**********************************************************************//**
 * CPU <b>mstatus</b> CSR (r/w): Machine status
 **************************************************************************/
enum NEORV32_CSR_MSTATUS_enum {
  CSR_MSTATUS_MIE   =  3, /**< CPU mstatus CSR  (3): MIE - Machine interrupt enable bit (r/w) */
  CSR_MSTATUS_MPIE  =  7, /**< CPU mstatus CSR  (7): MPIE - Machine previous interrupt enable bit (r/w) */
  CSR_MSTATUS_MPP_L = 11, /**< CPU mstatus CSR (11): MPP_L - Machine previous privilege mode bit low (r/w) */
  CSR_MSTATUS_MPP_H = 12, /**< CPU mstatus CSR (12): MPP_H - Machine previous privilege mode bit high (r/w) */
  CSR_MSTATUS_MPRV  = 17, /**< CPU mstatus CSR (17): MPRV - Use MPP as effective privilege for M-mode load/stores when set (r/w) */
  CSR_MSTATUS_TW    = 21  /**< CPU mstatus CSR (21): TW - Disallow execution of wfi instruction in user mode when set (r/w) */
};

/**********************************************************************//**
 * @name IO Device: External Interrupt Controller (XIRQ)
 **************************************************************************/
/**@{*/
/** XIRQ module prototype */
typedef struct __attribute__((packed,aligned(4))) {
  uint32_t       IER;      /**< offset 0:  IRQ input enable register */
  uint32_t       IPR;      /**< offset 4:  pending IRQ register /ack/clear */
  uint32_t       SCR;      /**< offset 8:  interrupt source register */
  const uint32_t reserved; /**< offset 12: reserved */
} neorv32_xirq_t;

/**********************************************************************//**
 * Write data to CPU configuration and status register (CSR).
 *
 * @param[in] csr_id ID of CSR to write. See #NEORV32_CSR_enum.
 * @param[in] data Data to write (uint32_t).
 **************************************************************************/
inline void __attribute__ ((always_inline)) neorv32_cpu_csr_write(const int csr_id, uint32_t data) {

  register uint32_t csr_data = data;

  asm volatile ("csrw %[input_i], %[input_j]" :  : [input_i] "i" (csr_id), [input_j] "r" (csr_data));
}


/**********************************************************************//**
 * @name IO Device: System Configuration Information Memory (SYSINFO)
 **************************************************************************/
/**@{*/
/** SYSINFO module prototype - whole module is read-only */
typedef struct __attribute__((packed,aligned(4))) {
  const uint32_t CLK;         /**< offset 0:  clock speed in Hz */
  const uint32_t CUSTOM_ID;   /**< offset 4:  custom user-defined ID (via top generic) */
  const uint32_t SOC;         /**< offset 8:  SoC features (#NEORV32_SYSINFO_SOC_enum) */
  const uint32_t CACHE;       /**< offset 12: cache configuration (#NEORV32_SYSINFO_CACHE_enum) */
  const uint32_t ISPACE_BASE; /**< offset 16: instruction memory address space base */
  const uint32_t DSPACE_BASE; /**< offset 20: data memory address space base */
  const uint32_t IMEM_SIZE;   /**< offset 24: internal instruction memory (IMEM) size in bytes */
  const uint32_t DMEM_SIZE;   /**< offset 28: internal data memory (DMEM) size in bytes */
} neorv32_sysinfo_t;

/** SYSINFO module base address */
#define NEORV32_SYSINFO_BASE (0xFFFFFFE0U)

/** SYSINFO module hardware access (#neorv32_sysinfo_t) */
#define NEORV32_SYSINFO (*((volatile neorv32_sysinfo_t*) (NEORV32_SYSINFO_BASE)))

/** NEORV32_SYSINFO.SOC (r/-): Implemented processor devices/features */

#define  SYSINFO_SOC_IO_XIRQ  28 /**< SYSINFO_FEATURES (28) (r/-): External interrupt controller implemented when 1 (via XIRQ_NUM_IO generic) */

enum NEORV32_CSR_MIE_enum {
  CSR_MIE_MSIE    =  3, /**< CPU mie CSR  (3): MSIE - Machine software interrupt enable (r/w) */
  CSR_MIE_MTIE    =  7, /**< CPU mie CSR  (7): MTIE - Machine timer interrupt enable bit (r/w) */
  CSR_MIE_MEIE    = 11, /**< CPU mie CSR (11): MEIE - Machine external interrupt enable bit (r/w) */

  CSR_MIE_FIRQ0E  = 16, /**< CPU mie CSR (16): FIRQ0E - Fast interrupt channel 0 enable bit (r/w) */
  CSR_MIE_FIRQ1E  = 17, /**< CPU mie CSR (17): FIRQ1E - Fast interrupt channel 1 enable bit (r/w) */
  CSR_MIE_FIRQ2E  = 18, /**< CPU mie CSR (18): FIRQ2E - Fast interrupt channel 2 enable bit (r/w) */
  CSR_MIE_FIRQ3E  = 19, /**< CPU mie CSR (19): FIRQ3E - Fast interrupt channel 3 enable bit (r/w) */
  CSR_MIE_FIRQ4E  = 20, /**< CPU mie CSR (20): FIRQ4E - Fast interrupt channel 4 enable bit (r/w) */
  CSR_MIE_FIRQ5E  = 21, /**< CPU mie CSR (21): FIRQ5E - Fast interrupt channel 5 enable bit (r/w) */
  CSR_MIE_FIRQ6E  = 22, /**< CPU mie CSR (22): FIRQ6E - Fast interrupt channel 6 enable bit (r/w) */
  CSR_MIE_FIRQ7E  = 23, /**< CPU mie CSR (23): FIRQ7E - Fast interrupt channel 7 enable bit (r/w) */
  CSR_MIE_FIRQ8E  = 24, /**< CPU mie CSR (24): FIRQ8E - Fast interrupt channel 8 enable bit (r/w) */
  CSR_MIE_FIRQ9E  = 25, /**< CPU mie CSR (25): FIRQ9E - Fast interrupt channel 9 enable bit (r/w) */
  CSR_MIE_FIRQ10E = 26, /**< CPU mie CSR (26): FIRQ10E - Fast interrupt channel 10 enable bit (r/w) */
  CSR_MIE_FIRQ11E = 27, /**< CPU mie CSR (27): FIRQ11E - Fast interrupt channel 11 enable bit (r/w) */
  CSR_MIE_FIRQ12E = 28, /**< CPU mie CSR (28): FIRQ12E - Fast interrupt channel 12 enable bit (r/w) */
  CSR_MIE_FIRQ13E = 29, /**< CPU mie CSR (29): FIRQ13E - Fast interrupt channel 13 enable bit (r/w) */
  CSR_MIE_FIRQ14E = 30, /**< CPU mie CSR (30): FIRQ14E - Fast interrupt channel 14 enable bit (r/w) */
  CSR_MIE_FIRQ15E = 31  /**< CPU mie CSR (31): FIRQ15E - Fast interrupt channel 15 enable bit (r/w) */
};

/**********************************************************************//**
 * CPU <b>mip</b> CSR (r/c): Machine interrupt pending
 **************************************************************************/
enum NEORV32_CSR_MIP_enum {
  CSR_MIP_MSIP    =  3, /**< CPU mip CSR  (3): MSIP - Machine software interrupt pending (r/c) */
  CSR_MIP_MTIP    =  7, /**< CPU mip CSR  (7): MTIP - Machine timer interrupt pending (r/c) */
  CSR_MIP_MEIP    = 11, /**< CPU mip CSR (11): MEIP - Machine external interrupt pending (r/c) */

  /* NEORV32-specific extension */
  CSR_MIP_FIRQ0P  = 16, /**< CPU mip CSR (16): FIRQ0P - Fast interrupt channel 0 pending (r/c) */
  CSR_MIP_FIRQ1P  = 17, /**< CPU mip CSR (17): FIRQ1P - Fast interrupt channel 1 pending (r/c) */
  CSR_MIP_FIRQ2P  = 18, /**< CPU mip CSR (18): FIRQ2P - Fast interrupt channel 2 pending (r/c) */
  CSR_MIP_FIRQ3P  = 19, /**< CPU mip CSR (19): FIRQ3P - Fast interrupt channel 3 pending (r/c) */
  CSR_MIP_FIRQ4P  = 20, /**< CPU mip CSR (20): FIRQ4P - Fast interrupt channel 4 pending (r/c) */
  CSR_MIP_FIRQ5P  = 21, /**< CPU mip CSR (21): FIRQ5P - Fast interrupt channel 5 pending (r/c) */
  CSR_MIP_FIRQ6P  = 22, /**< CPU mip CSR (22): FIRQ6P - Fast interrupt channel 6 pending (r/c) */
  CSR_MIP_FIRQ7P  = 23, /**< CPU mip CSR (23): FIRQ7P - Fast interrupt channel 7 pending (r/c) */
  CSR_MIP_FIRQ8P  = 24, /**< CPU mip CSR (24): FIRQ8P - Fast interrupt channel 8 pending (r/c) */
  CSR_MIP_FIRQ9P  = 25, /**< CPU mip CSR (25): FIRQ9P - Fast interrupt channel 9 pending (r/c) */
  CSR_MIP_FIRQ10P = 26, /**< CPU mip CSR (26): FIRQ10P - Fast interrupt channel 10 pending (r/c) */
  CSR_MIP_FIRQ11P = 27, /**< CPU mip CSR (27): FIRQ11P - Fast interrupt channel 11 pending (r/c) */
  CSR_MIP_FIRQ12P = 28, /**< CPU mip CSR (28): FIRQ12P - Fast interrupt channel 12 pending (r/c) */
  CSR_MIP_FIRQ13P = 29, /**< CPU mip CSR (29): FIRQ13P - Fast interrupt channel 13 pending (r/c) */
  CSR_MIP_FIRQ14P = 30, /**< CPU mip CSR (30): FIRQ14P - Fast interrupt channel 14 pending (r/c) */
  CSR_MIP_FIRQ15P = 31  /**< CPU mip CSR (31): FIRQ15P - Fast interrupt channel 15 pending (r/c) */
};

/**********************************************************************//**
 * Available CPU Control and Status Registers (CSRs)
 **************************************************************************/
enum NEORV32_CSR_enum {
 /* machine trap control */
  CSR_MSCRATCH       = 0x340, /**< 0x340 - mscratch (r/w): Machine scratch register */
  CSR_MEPC           = 0x341, /**< 0x341 - mepc     (r/w): Machine exception program counter */
  CSR_MCAUSE         = 0x342, /**< 0x342 - mcause   (r/w): Machine trap cause */
  CSR_MTVAL          = 0x343, /**< 0x343 - mtval    (r/-): Machine bad address or instruction */
  CSR_MIP            = 0x344, /**< 0x344 - mip      (r/-): Machine interrupt pending register */
  CSR_MISA           = 0x301, /**< 0x301 - misa       (r/-): CPU ISA and extensions (read-only in NEORV32) */
  CSR_MTVEC          = 0x305, /**< 0x305 - mtvec      (r/w): Machine trap-handler base address (for ALL traps) */
  CSR_MIE            = 0x304, /**< 0x304 - mie        (r/w): Machine interrupt-enable register */
};


#define XIRQ_FIRQ_ENABLE       24    /**< MIE CSR bit (#NEORV32_CSR_MIE_enum) */
#define XIRQ_FIRQ_PENDING      24   /**< MIP CSR bit (#NEORV32_CSR_MIP_enum) */

// prototypes
int  neorv32_xirq_available(void);
int  neorv32_xirq_get_num(void);
void neorv32_xirq_clear_pending(uint8_t ch);
void neorv32_xirq_channel_enable(uint8_t ch);
void neorv32_xirq_channel_disable(uint8_t ch);
void neorv32_xirq_acknowledge(void);