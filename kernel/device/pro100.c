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

// Bits in header register 0x1
#define BUS_MASTER  (1 << 2)
#define IO_SPACE    (1 << 0)

/*
** Intel 8255x Control/Status Register Macros
*/
#define SCB_STATUS  0x00
#define SCB_COMMAND 0x02

#define EEPROM_CTRL 0x0E

// Global Pro100 pointer
pro100_t *pro100;

void pro100_outl(uint32_t offset, uint32_t val) {
  outl(pro100->io_base_addr + offset, val);
}

void pro100_outw(uint32_t offset, uint16_t val) {
  outw(pro100->io_base_addr + offset, val);
}

uint32_t pro100_inl(uint32_t offset) {
  return inl(pro100->io_base_addr + offset);
}

uint16_t pro100_inw(uint32_t offset) {
  return inw(pro100->io_base_addr + offset);
}

void pro100_access_enable(void) {
  
  // 0x4 is the offset of the register with command 
  // Refer to the pci_dev_t struct in include/pci.h for 
  // offsets of each header register.
  uint32_t command = pci_cfgspace_read_dword(pro100->pci_dev, 0x4);

#ifdef DEBUG_PCI
  char buf[128];
  sprint(buf, "Pro100 command reg=0x%x\n", command);
  cio_printf(buf);
  delay( DELAY_1_SEC );
#endif

  command = command | BUS_MASTER | IO_SPACE;

#ifdef DEBUG_PCI
  sprint(buf, "Pro100 command reg=0x%x\n", command);
  cio_printf(buf);
  delay( DELAY_1_SEC );
#endif

  pci_cfgspace_write_dword(pro100->pci_dev, 0x4, command); 

#ifdef DEBUG_PCI
  command = pci_cfgspace_read_dword(pro100->pci_dev, 0x4);
  sprint(buf, "Pro100 command reg=0x%x\n", command);
  cio_printf(buf);
  delay( DELAY_1_SEC );
#endif

}

// Consider changing this to return a pointer to some struct
// that represents a network device
void pro100_init(void) {
  
  // lets do some testing and see what we have here
  char buf[128];
  pro100 = (pro100_t *) km_page_alloc(1);

  // Initialize the pro100's fields
  pro100->pci_dev = pci_dev_pro100;
  pro100->io_base_addr = pci_get_bar(pro100->pci_dev->hdr, PCI_BAR_IO) & PCI_BAR_IO_MASK;

  // Enable I/O space access of the device
  pro100_access_enable();

#ifdef DEBUG_PCI
  uint16_t vendor_id = pro100->pci_dev->hdr->vendor_id;
  uint16_t device_id = pro100->pci_dev->hdr->device_id;

  sprint(buf, "Inside pro100_init: vendor_id=0x%x, device_id=0x%x\n", vendor_id, device_id); 
  cio_printf(buf);
  delay( DELAY_2_SEC );

  sprint(buf, "I/O Base Address=0x%08x\n", pro100->io_base_addr);
  cio_printf(buf);
  delay( DELAY_2_SEC );
  
  // This writes a No-Op to the command register
  pro100_outw(SCB_COMMAND, 0x0000);

  uint16_t scb_status = pro100_inw(SCB_STATUS);
  sprint(buf, "SCB Status=0x%x\n", scb_status);
  cio_printf(buf);
  delay( DELAY_1_SEC );

  uint16_t scb_command = pro100_inw(SCB_COMMAND);
  sprint(buf, "SCB Command=0x%x\n", scb_command);
  cio_printf(buf);
  delay( DELAY_1_SEC );
#endif


}
