/*
Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Original Author: Shay Gal-on
*/

#include "coremark.h"

#if VALIDATION_RUN
    volatile ee_s32 seed1_volatile=0x3415;
    volatile ee_s32 seed2_volatile=0x3415;
    volatile ee_s32 seed3_volatile=0x66;
#endif
#if PERFORMANCE_RUN
    volatile ee_s32 seed1_volatile=0x0;
    volatile ee_s32 seed2_volatile=0x0;
    volatile ee_s32 seed3_volatile=0x66;
#endif
#if PROFILE_RUN
    volatile ee_s32 seed1_volatile=0x8;
    volatile ee_s32 seed2_volatile=0x8;
    volatile ee_s32 seed3_volatile=0x8;
#endif
    volatile ee_s32 seed4_volatile=ITERATIONS;
    volatile ee_s32 seed5_volatile=0;

/* RISC-V specific defines */
#define RISCV_MTIME_BASE 0x10000000UL
#define RISCV_UART_BASE  0x10010000UL
#define RISCV_MCYCLE_CSR 0xB00

/* UART registers */
#define UART_THR   0x00  /* Transmit Holding Register */
#define UART_LSR   0x05  /* Line Status Register */
#define UART_LSR_THRE 0x20  /* Transmit Holding Register Empty */

static volatile unsigned char *uart_base = (volatile unsigned char *)RISCV_UART_BASE;

/* Function prototypes */
void uart_putc(char c);
void uart_puts(const char *s);
ee_u64 riscv_get_cycles(void);
ee_u64 riscv_get_time(void);

void uart_putc(char c) {
    /* Wait for transmit holding register to be empty */
    while (!(uart_base[UART_LSR] & UART_LSR_THRE));
    
    /* Write character to transmit holding register */
    uart_base[UART_THR] = c;
}

void uart_puts(const char *s) {
    while (*s) {
        if (*s == '\n') {
            uart_putc('\r');
        }
        uart_putc(*s++);
    }
}

/* Read RISC-V cycle counter using CSR instruction */
ee_u64 riscv_get_cycles(void) {
    ee_u64 cycles;
    __asm__ volatile ("csrr %0, mcycle" : "=r" (cycles));
    return cycles;
}

/* Read RISC-V time counter */
ee_u64 riscv_get_time(void) {
    volatile ee_u64 *mtime = (volatile ee_u64 *)RISCV_MTIME_BASE;
    return *mtime;
}

/* Porting layer implementation */
void start_time(void) {
    GETMYTIME(&start_time_val);
}

void stop_time(void) {
    GETMYTIME(&stop_time_val);
}

CORE_TICKS get_time(void) {
    return riscv_get_cycles();
}

/* Convert ticks to seconds */
secs_ret time_in_secs(CORE_TICKS ticks) {
    /* Assuming 100MHz clock frequency */
    /* Adjust this based on your actual clock frequency */
    return ((secs_ret)ticks) / (100000000.0);
}

ee_u32 default_num_contexts = MULTITHREAD;

/* Initialize the random number generator */
void portable_init(core_portable *p, int *argc, char *argv[]) {
    if (sizeof(ee_ptr) == 8) {
        ee_printf("Address bits : 64\n");
    } else {
        ee_printf("Address bits : 32\n");
    }
    
    if (sizeof(ee_s32) == 4) {
        ee_printf("Data bits    : 32\n");
    } else {
        ee_printf("Data bits    : %d\n", sizeof(ee_s32) * 8);
    }
    
    p->portable_id = 1;
}

void portable_fini(core_portable *p) {
    p->portable_id = 0;
}

/* Memory allocation functions */
void *portable_malloc(ee_size_t size) {
    /* Simple static memory allocator for bare metal */
    static char heap[64*1024];  /* 64KB heap */
    static ee_size_t heap_used = 0;
    
    if (heap_used + size > sizeof(heap)) {
        return NULL;  /* Out of memory */
    }
    
    void *ptr = &heap[heap_used];
    heap_used += size;
    
    /* Align to 8-byte boundary */
    heap_used = (heap_used + 7) & ~7;
    
    return ptr;
}

void portable_free(void *p) {
    /* Static allocator - no free operation */
    (void)p;
}

/* Basic printf implementation using UART */
int ee_printf(const char *fmt, ...) {
    va_list args;
    static char buffer[1024];
    int result;
    
    va_start(args, fmt);
    result = vsnprintf(buffer, sizeof(buffer), fmt, args);
    va_end(args);
    
    uart_puts(buffer);
    return result;
}

/* Seed the random number generator */
ee_u32 portable_fini(core_portable *p) {
    p->portable_id=0;
}

/* Platform specific validation */
#if (MAIN_HAS_NOARGC && (SEED_METHOD == SEED_ARG))
ee_s32 get_seed_args(int i) {
    ee_s32 retval;
    switch (i) {
        case 1 : retval=seed1_volatile; break;
        case 2 : retval=seed2_volatile; break;
        case 3 : retval=seed3_volatile; break;
        case 4 : retval=seed4_volatile; break;
        case 5 : retval=seed5_volatile; break;
        default: retval=0; break;
    }
    return retval;
}
#endif

/* Performance measurement setup */
#define NSECS_PER_SEC CLOCKS_PER_SEC
#define CORETIMETYPE CORE_TICKS
#define GETMYTIME(_t) (*_t=get_time())
#define MYTIMEDIFF(fin,ini) ((fin)-(ini))
#define TIMER_RES_DIVIDER 1
#define SAMPLE_TIME_IMPLEMENTATION 1
#define EE_TICKS_PER_SEC (100000000)  /* 100MHz */

/* CoreMark specific memory settings */
#ifndef TOTAL_DATA_SIZE 
#define TOTAL_DATA_SIZE 2*1000
#endif

#ifndef MAIN_HAS_NOARGC
#define MAIN_HAS_NOARGC 1
#endif

#ifndef MAIN_HAS_NORETURN
#define MAIN_HAS_NORETURN 0
#endif

/* Cache control functions */
void flush_cache(void) {
    /* RISC-V fence instructions for cache coherency */
    __asm__ volatile ("fence");
    __asm__ volatile ("fence.i");
}

/* Error handling */
void barebones_clock(void) {
    ee_printf("ERROR! Please define how to measure time in your system!\n");
}

/* Hardware performance monitoring */
void enable_performance_counters(void) {
    /* Enable cycle counter */
    __asm__ volatile ("csrwi mcounteren, 0x7");  /* Enable cycle, time, instret */
}

/* Benchmark result reporting */
void report_benchmark_results(ee_u32 iterations, ee_u64 total_cycles, double time_secs) {
    double coremark_score = iterations / time_secs;
    double cycles_per_iteration = (double)total_cycles / iterations;
    
    ee_printf("\n==== CoreMark Results ====\n");
    ee_printf("Total iterations: %d\n", iterations);
    ee_printf("Total cycles: %llu\n", total_cycles);
    ee_printf("Total time: %.6f seconds\n", time_secs);
    ee_printf("CoreMark Score: %.2f\n", coremark_score);
    ee_printf("Cycles per iteration: %.2f\n", cycles_per_iteration);
    ee_printf("==========================\n");
}

/* Main entry point for bare metal */
int main(void) {
    ee_printf("Starting CoreMark benchmark on RISC-V processor...\n");
    
    /* Enable performance counters */
    enable_performance_counters();
    
    /* Run CoreMark */
    int result = core_main();
    
    ee_printf("CoreMark benchmark completed with result: %d\n", result);
    
    /* Infinite loop to prevent processor from exiting */
    while(1) {
        __asm__ volatile ("wfi");  /* Wait for interrupt */
    }
    
    return result;
} 