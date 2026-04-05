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

/** These are for print debugging */
#include <support.h>
#include <lib.h>
#include <cio.h>
#include <klib.h>
/** ====== */

pro100_t *pro100;

// Consider changing this to return a pointer to some struct
// that represents a network device
void pro100_init(void) {
  
  // lets do some testing and see what we have here
  char buf[128];
  pro100 = (pro100_t *) km_page_alloc(1);

  // Initialize the pro100's fields
  pro100->pci_dev = pci_dev_pro100;
  pro100->io_base_addr = pci_get_bar(pro100->pci_dev->hdr, PCI_BAR_IO) & PCI_BAR_IO_MASK;

#ifdef DEBUG_PCI
  uint16_t vendor_id = pro100->pci_dev->hdr->vendor_id;
  uint16_t device_id = pro100->pci_dev->hdr->device_id;

  sprint(buf, "Inside pro100_init: vendor_id=0x%x, device_id=0x%x\n", vendor_id, device_id); 
  cio_printf(buf);
  delay( DELAY_2_SEC );

  sprint(buf, "I/O Base Address=0x%08x\n", pro100->io_base_addr);
  cio_printf(buf);
  delay( DELAY_2_SEC );
#endif
  
}
