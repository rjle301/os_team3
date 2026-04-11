/*
** @file: pro100.c
**
** @author: Ryan Lembo-Ehms
**
** @brief: Pro100 device code
*/

#include <pci.h>
#include <device/pro100.h>
#include <kmem.h>
#include <x86/ops.h>

/** These are for print debugging */
#include <support.h>
#include <lib.h>
#include <cio.h>
#include <klib.h>
/** ====== */

/*
** Macros for values used in write/out_ functions
*/
#define BUS_MASTER      (1 << 2)
#define IO_SPACE        (1 << 0)
#define SOFTWARE_RESET  0x00
#define CU_START        0x0010
#define CU_RESUME       0x0020
#define INT_MASK        0x0100

/*
** Intel 8255x Control/Status Register (CSR) Macros
** Offsets from the Pro100's I/O base address
*/
#define SCB_STATUS    0x00
#define SCB_COMMAND   0x02
#define SCB_POINTER   0x04
#define PORT          0x08
#define EEPROM_CTRL   0x0E

/*
** Command Block (CB) Macros
*/
#define CB_CMD_NOP   0x0000
#define CB_CMD_EL    (1 << 15)  // End of list

// Global Pro100 pointer
pro100_t *pro100;

void pro100_outl(uint32_t offset, uint32_t val) {
  outl(pro100->io_base_addr + offset, val);
}

void pro100_outw(uint32_t offset, uint16_t val) {
  outw(pro100->io_base_addr + offset, val);
}

void pro100_outb(uint32_t offset, uint8_t val) {
  outb(pro100->io_base_addr + offset, val);
}

uint32_t pro100_inl(uint32_t offset) {
  return inl(pro100->io_base_addr + offset);
}

uint16_t pro100_inw(uint32_t offset) {
  return inw(pro100->io_base_addr + offset);
}

uint8_t pro100_inb(uint32_t offset) {
  return inb(pro100->io_base_addr + offset);
}

void pro100_access_enable(void) {
  
  // 0x4 is the offset of the register with command 
  // Refer to the pci_dev_t struct in include/pci.h for 
  // offsets of each header register.
  uint32_t command = pci_cfgspace_read_dword(pro100->pci_dev, 0x4);

#ifdef DEBUG_PCI
  char buf[128];
  sprint(buf, "Pro100 PCI command reg=0x%x\n", command);
  cio_printf(buf);
  delay( DELAY_1_SEC );
#endif

  command = command | BUS_MASTER | IO_SPACE;

#ifdef DEBUG_PCI
  sprint(buf, "Pro100 PCI command reg=0x%x\n", command);
  cio_printf(buf);
  delay( DELAY_1_SEC );
#endif

  pci_cfgspace_write_dword(pro100->pci_dev, 0x4, command); 

#ifdef DEBUG_PCI
  command = pci_cfgspace_read_dword(pro100->pci_dev, 0x4);
  sprint(buf, "Pro100 PCI command reg=0x%x\n", command);
  cio_printf(buf);
  delay( DELAY_1_SEC );
#endif

}

// Consider changing this to return a pointer to some struct
// that represents a network device
void pro100_init(void) {
  
  pro100 = (pro100_t *) km_page_alloc(1);

  // Initialize the pro100's fields
  pro100->pci_dev = pci_dev_pro100;
  pro100->io_base_addr = pci_get_bar(pro100->pci_dev->hdr, PCI_BAR_IO) & PCI_BAR_IO_MASK;

  // Enable I/O space access of the device
  pro100_access_enable();

  // Now that we can access the device, issue a software reset
  // to prepare it for initialization
  pro100_outl(pro100->io_base_addr + PORT, SOFTWARE_RESET);
  
  // Recommended delay after software reset is 15us.
  // With 1 KHz clock frequency, no delay should be needed
  // Time for a CB No-Op command
  cb_t *cb_noop = (cb_t *) km_page_alloc(1);
  cb_noop->status = 0;
  cb_noop->command = CB_CMD_NOP | CB_CMD_EL; 
  cb_noop->link = 0xFFFFFFFF; // end of list
  
  // Load the No-Op command block into the SCB 
  pro100_outl(SCB_POINTER, (uint32_t) cb_noop);

  // This generates an interrupt I'm not handling yet, so mask for now
  pro100_outw(SCB_COMMAND, CU_START | 0x2000);

#ifdef DEBUG_PCI
  
  char buf[128];

  // lets do some testing and see what we have here
  sprint(buf, "Command block Status=0x%04x\n", cb_noop->status);
  cio_printf(buf);
  delay( DELAY_1_SEC );
  
  // Read scb status and ack any interrupt bits set
  uint16_t scb_status = pro100_inw(SCB_STATUS);
  pro100_outw(SCB_STATUS, scb_status);

  sprint(buf, "SCB Status=0x%04x\n", scb_status);
  cio_printf(buf);
  delay( DELAY_1_SEC );

  uint16_t scb_command = pro100_inw(SCB_COMMAND);
  sprint(buf, "SCB Command=0x%04x\n", scb_command);
  cio_printf(buf);
  delay( DELAY_1_SEC );
#endif

}
