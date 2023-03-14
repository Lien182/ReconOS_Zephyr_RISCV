/*
 *                                                        ____  _____
 *                            ________  _________  ____  / __ \/ ___/
 *                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
 *                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
 *                         /_/   \___/\___/\____/_/ /_/\____//____/
 *
 * ======================================================================
 *
 *   title:        Architecture specific code
 *
 *   project:      ReconOS
 *   author:       Christoph Rüthing, University of Paderborn
 *   description:  Functions needed for ReconOS which are architecure
 *                 specific and are implemented here.
 *
 * ======================================================================
 */

#include "timer.h"
#include <stdint.h>
#include <stdio.h>

#define TIMER_BASE_ADDR 0x864a0000
#define CLK_FREQ 100000000

volatile uint32_t *ptr = 0;


/* == Timer functions ================================================== */

/*
 * @see header
 */
void timer_init() {
	ptr = (uint32_t *)TIMER_BASE_ADDR;
	if (ptr == NULL) {
		printf("ERROR: Could not allocate memory\n");
		return;
	}

	timer_reset();
	timer_setstep(0);
}

/*
 * @see header
 */
void timer_reset() {
	if (ptr) {
		ptr[0] = 0;
	}
}

/*
 * @see header
 */
void timer_setstep(unsigned int step) {
	if (ptr) {
		ptr[1] = step;
	}
}

/*
 * @see header
 */
unsigned int timer_get() {
	if (ptr) {
		return *ptr;
	} else {
		return 0;
	}
}

/*
 * @see header
 */
void timer_cleanup() {
	k_free(ptr);
	ptr = 0;
}

float timer_toms(unsigned int t) {
	return t / (CLK_FREQ / 1000.0);
}
