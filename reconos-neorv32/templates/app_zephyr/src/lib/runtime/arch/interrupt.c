// #################################################################################################
// # << NEORV32: neorv32_xirq.c - External Interrupt controller HW Driver >>                       #
// # ********************************************************************************************* #
// # BSD 3-Clause License                                                                          #
// #                                                                                               #
// # Copyright (c) 2022, Stephan Nolting. All rights reserved.                                     #
// #                                                                                               #
// # Redistribution and use in source and binary forms, with or without modification, are          #
// # permitted provided that the following conditions are met:                                     #
// #                                                                                               #
// # 1. Redistributions of source code must retain the above copyright notice, this list of        #
// #    conditions and the following disclaimer.                                                   #
// #                                                                                               #
// # 2. Redistributions in binary form must reproduce the above copyright notice, this list of     #
// #    conditions and the following disclaimer in the documentation and/or other materials        #
// #    provided with the distribution.                                                            #
// #                                                                                               #
// # 3. Neither the name of the copyright holder nor the names of its contributors may be used to  #
// #    endorse or promote products derived from this software without specific prior written      #
// #    permission.                                                                                #
// #                                                                                               #
// # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS   #
// # OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF               #
// # MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE    #
// # COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     #
// # EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE #
// # GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED    #
// # AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     #
// # NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED  #
// # OF THE POSSIBILITY OF SUCH DAMAGE.                                                            #
// # ********************************************************************************************* #
// # The NEORV32 Processor - https://github.com/stnolting/neorv32              (c) Stephan Nolting #
// #################################################################################################


/**********************************************************************//**
 * @file neorv32_xirq.c
 * @brief External Interrupt controller HW driver source file.
 **************************************************************************/

#include "interrupt.h"

/**********************************************************************//**
 * Install exception handler function to NEORV32 runtime environment.
 *
 * @note Interrupt sources have to be explicitly enabled by the user via the CSR.mie bits via neorv32_cpu_irq_enable(uint8_t irq_sel)
 * and the global interrupt enable bit mstatus.mie via neorv32_cpu_eint(void).
 *
 * @param[in] id Identifier (type) of the targeted exception. See #NEORV32_RTE_TRAP_enum.
 * @param[in] handler The actual handler function for the specified exception (function MUST be of type "void function(void);").
 * @return 0 if success, 1 if error (invalid id or targeted exception not supported).
 **************************************************************************/


/**********************************************************************//**
 * Check if external interrupt controller was synthesized.
 *
 * @return 0 if XIRQ was not synthesized, 1 if EXTIRQ is available.
 **************************************************************************/
int neorv32_xirq_available(void) {

  if (NEORV32_SYSINFO.SOC & (1 << SYSINFO_SOC_IO_XIRQ)) {
    return 1;
  }
  else {
    return 0;
  }
}

/**********************************************************************//**
 * Private function: Check IRQ id.
 *
 * @param[in] irq_sel CPU interrupt select. See #NEORV32_CSR_MIE_enum.
 * @return 0 if success, 1 if error (invalid irq_sel).
 **************************************************************************/
static int __neorv32_cpu_irq_id_check(uint8_t irq_sel) {

  if ((irq_sel == CSR_MIE_MSIE) || (irq_sel == CSR_MIE_MTIE) || (irq_sel == CSR_MIE_MEIE) ||
     ((irq_sel >= CSR_MIE_FIRQ0E) && (irq_sel <= CSR_MIE_FIRQ15E))) {
    return 0;
  }
  else {
    return 1;
  }
}

/**********************************************************************//**
 * Enable specific CPU interrupt.
 *
 * @note Interrupts have to be globally enabled via neorv32_cpu_eint(void), too.
 *
 * @param[in] irq_sel CPU interrupt select. See #NEORV32_CSR_MIE_enum.
 * @return 0 if success, 1 if error (invalid irq_sel).
 **************************************************************************/
int neorv32_cpu_irq_enable(uint8_t irq_sel) {

  // check IRQ id
  if (__neorv32_cpu_irq_id_check(irq_sel)) {
    return 1;
  }

  register uint32_t mask = (uint32_t)(1 << irq_sel);
  asm volatile ("csrrs zero, mie, %0" : : "r" (mask));
  return 0;
}


/**********************************************************************//**
 * Disable specific CPU interrupt.
 *
 * @param[in] irq_sel CPU interrupt select. See #NEORV32_CSR_MIE_enum.
 * @return 0 if success, 1 if error (invalid irq_sel).
 **************************************************************************/
int neorv32_cpu_irq_disable(uint8_t irq_sel) {

  // check IRQ id
  if (__neorv32_cpu_irq_id_check(irq_sel)) {
    return 1;
  }

  register uint32_t mask = (uint32_t)(1 << irq_sel);
  asm volatile ("csrrc zero, mie, %0" : : "r" (mask));
  return 0;
}
/**********************************************************************//**
 * Acknowledge XIRQ interrupt.
 *
 * @note All interrupt channels will be deactivated, all pending IRQs will be deactivated
 **************************************************************************/
void neorv32_xirq_acknowledge(void) {
  NEORV32_XIRQ.SCR = 0; // acknowledge (clear) XIRQ interrupt
  neorv32_cpu_csr_write(CSR_MIP, 0);
}


/**********************************************************************//**
 * Get number of implemented XIRQ channels
 *
 * @return Number of implemented channels (0..32).
 **************************************************************************/
int neorv32_xirq_get_num(void) {

  uint32_t enable;
  int i, cnt;

  if (neorv32_xirq_available()) {

    neorv32_cpu_irq_disable(XIRQ_FIRQ_ENABLE); // make sure XIRQ cannot fire
    NEORV32_XIRQ.IER = 0xffffffff; // try to set all enable flags
    enable = NEORV32_XIRQ.IER; // read back actually set flags

    // count set bits in enable
    cnt = 0;
    for (i=0; i<32; i++) {
      if (enable & 1) {
        cnt++;
      }
      enable >>= 1;
    }
    return cnt;
  }
  else {
    return 0;
  }
}


/**********************************************************************//**
 * Clear pending interrupt.
 *
 * @param[in] ch XIRQ interrupt channel (0..31).
 **************************************************************************/
void neorv32_xirq_clear_pending(uint8_t ch) {

  if (ch < 32) { // channel valid?
    NEORV32_XIRQ.IPR = ~(1 << ch);
  }
}


/**********************************************************************//**
 * Enable IRQ channel.
 *
 * @param[in] ch XIRQ interrupt channel (0..31).
 **************************************************************************/
void neorv32_xirq_channel_enable(uint8_t ch) {

  if (ch < 32) { // channel valid?
    NEORV32_XIRQ.IER |= 1 << ch;
  }
}


/**********************************************************************//**
 * Disable IRQ channel.
 *
 * @param[in] ch XIRQ interrupt channel (0..31).
 **************************************************************************/
void neorv32_xirq_channel_disable(uint8_t ch) {

  if (ch < 32) { // channel valid?
    NEORV32_XIRQ.IER &= ~(1 << ch);
  }
}