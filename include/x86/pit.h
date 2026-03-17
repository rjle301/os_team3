/*
** @file    pit.h
**
** @author  Warren R. Carithers
** @author	K. Reek
**
** @brief	8254 PIT definitions
**
** Definitions of constants and macros for the Intel 8254
** Programmable Interval Timer.
**
*/

#ifndef X86_PIT_H_
#define X86_PIT_H_


/*
** Hardware timer (Intel 8254 Programmable Interval Timer)
**
** Control word layout:
**
**   Bit     7   6 | 5   4 | 3   2   1 | 0
**   Field  SC1 SC0|RW1 RW0|M2  M1  M0 |BCD
**
** SC  - select counter
** RW  - read/write
** M   - mode
** BCD - binary or BCD counter
*/

/* Frequency settings */
#define	PIT_DEFAULT_TICKS_PER_SECOND    18      // actually 18.2065Hz
#define	PIT_DEFAULT_MS_PER_TICK         (1000/PIT_DEFAULT_TICKS_PER_SECOND)
#define	PIT_FREQ                        1193182 // clock cycles/sec

/* Port assignments */
#define	PIT_BASE_PORT    0x40    // I/O port for the timer
#	define  PIT_0_PORT          (PIT_BASE_PORT)
#	define  PIT_1_PORT          (PIT_BASE_PORT+1)
#	define  PIT_2_PORT          (PIT_BASE_PORT+2)
#	define  PIT_CONTROL_PORT    (PIT_BASE_PORT+3)

/* Counter select (bits 7:6) */
#define	PIT_0_SELECT        0x00        // select counter 0
#define	PIT_1_SELECT        0x40        // select counter 1
#define	PIT_2_SELECT        0x80        // select counter 1
#define	PIT_READBACK        0xc0        // perform a read-back

/* Counter Read/Write modes (bits 5:4) */
#define	PIT_LATCH           0x00        // counter latch command (read)
#define	PIT_RW_LSB          0x10        // read/write LSB only
#define	PIT_RW_MSB          0x20        // read/write MSB only
#define	PIT_RW_LSB_MSB      0x30        // read/write LCB then MSB
										//
// shorthand names
#define	PIT_LOAD            PIT_RW_LSB_MSB  // read/write LSB, then MSB

/* Counter modes */
#define	PIT_MODE_0          0x00        // int on terminal count
#define	PIT_MODE_1          0x02        // one-shot
#define	PIT_MODE_2          0x04        // divide-by-N
#define	PIT_MODE_3          0x06        // square-wave
#define	PIT_MODE_4          0x08        // software strobe
#define	PIT_MODE_5          0x0a        // hardware strobe

// shorthand names
#define	PIT_TCINT           PIT_MODE_0
#define	PIT_ONESHOT         PIT_MODE_1
#define	PIT_NDIV            PIT_MODE_2
#define	PIT_SQUARE          PIT_MODE_3
#define	PIT_SW_STROBE       PIT_MODE_4
#define	PIT_HW_STROBE       PIT_MODE_5

/* BCD field */
#define	PIT_DECIMAL         0x00        // 16-bit binary counter (default)
#define	PIT_BCD             0x01        // BCD counter

/* Useful helper commands */
#define	PIT_0_ENDSIGNAL     0x00        // assert OUT at end of count

/* Read operations */
#define	PIT_RB_NOT_COUNT    0x20        // don't latch the count
#define	PIT_RB_NOT_STATUS   0x10        // don't latch the status
#define	PIT_RB_CHAN_2       0x08        // read back channel 2
#define	PIT_RB_CHAN_1       0x04        // read back channel 1
#define	PIT_RB_CHAN_0       0x02        // read back channel 0
#define	PIT_RB_ACCESS_MASK  0x30        // access mode field
#define	PIT_RB_OP_MASK      0x0e        // oper mode field
#define	PIT_RB_BCD_MASK     0x01        // BCD mode field

#endif
