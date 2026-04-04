/*
** @file: pro100.c
**
** @author: Ryan Lembo-Ehms
**
** @brief: Pro100 device code
*/

#include <pci.h>
/** These are for print debugging */
#include <support.h>
#include <lib.h>
#include <cio.h>
#include <klib.h>
/** ====== */

// Should probably change this to return a pointer to some struct
// that represents a network device
void pro100_init(void) {
  // lets do some testing and see what we have here
  char buf[128];
  uint16_t vendor_id = pro100_hdr->vendor_id;
  uint16_t device_id = pro100_hdr->device_id;

  sprint(buf, "Inside pro100_init: vendor_id=0x%x, device_id=0x%x\n", vendor_id, device_id); 
  cio_printf(buf);
  delay( DELAY_2_SEC );
}
