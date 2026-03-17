/**
** @file	kbd.h
**
** @author	Warren R. Carithers
** @author	K. Reek
**
** Definitions of constants and macros related to the legacy keyboard
** controller. For more details, see the IBM 8042 Keyboard Controller
** manual, or https://wiki.osdev.org/I8042_PS/2_Controller
*/

#ifndef X86_KBD_H_
#define X86_KBD_H_

/*
** I/O ports used by the bootstrap code
*/

// keyboard controller
#define	KBD_DATA        0x60
#define	KBD_CMD         0x64
#define	KBD_STATUS      0x64

// status register bits
//
// the "output buffer" is data coming from the keyboard to the cpu
// the "input buffer" is data going to the keyboard from the cpu
#define	KBD_OBSTAT      0x01   // 0 = empty, 1 = full
#	define KBD_IN_READY    KBD_OBSTAT
#define	KBD_IBSTAT      0x02   // 0 = empty, 1 = full
#define	KBD_SYSFLAG     0x04   // cleared on reset, set when POST passes
#define	KBD_CMDDAT      0x08   // data dest.: 0 = ps/2 dev, 1 = ps/2 ctrl
#define	KBD_UNK         0x10   // chipset-specific
#define	KBD_UNK2        0x20   // chipset-specific
#define	KBD_TIMEOUT     0x40   // 0 = no error, 1 = time-out error
#define	KBD_PARITY      0x80   // 0 = no error, 1 = parity error

/*
** Controller commands (written to KBD_CMD)
*/

// read/write internal RAM bytes
// 0x20 - 0x3f: read byte N, 0x60 - 0x7f write byte N, N == cmd & 0x1f (0..31)
// write: data to be written is the next byte sent to KBD_DATA
// byte 0 is the controller configuration byte
#define KBD_RD_BYTE0    0x20   // read from internal RAM byte 0
#define KBD_WT_BYTE0    0x60   // write to internal RAM byte 0

// ps/2 port enable/disable
#define	KBD_P2_DISABLE  0xa7   // disable second port (if there is one)
#define	KBD_P2_ENABLE   0xa8   // enable second port (if there is one)
#define	KBD_P1_DISABLE  0xad   // disable first port
#define	KBD_P1_ENABLE   0xae   // enable first port

// test commands
#define	KBD_TEST_P2     0xa9   // test ps/2 second port
#define	KBD_TEST_CTRL   0xaa   // test ps/2 controller
#define KBD_TEST_P1     0xab   // test ps/2 first port

// controller output port commands
#define	KBD_RD_OPORT    0xd0   // read ctrl output port
#define	KBD_WT_OPORT    0xd1   // write next byte to ctrl output port

// controller configuration byte (byte 0 in internal RAM)
#define	KBD_CCB_P1_INT  0x01   // port 1 ints, 0 = disabled, 1 = enabled
#define	KBD_CCB_P2_INT  0x02   // port 2 ints, 0 = disabled, 1 = enabled
#define	KBD_CCB_SYSFLG  0x04   // 0 = POST failed, 1 = POST passed
#define	KBD_CCB_SBZ     0x08   // should be zero
#define	KBD_CCB_P1_CLK  0x10   // port 1 clock, 0 = enabled, 1 = disabled
#define	KBD_CCB_P2_CLK  0x20   // port 2 clock, 0 = enabled, 1 = disabled
#define	KBD_CCB_P1_XLT  0x40   // port 1 xlate, 0 = disabled, 1 = enabled
#define	KBD_CCB_MBZ     0x80   // must be zero

#endif
