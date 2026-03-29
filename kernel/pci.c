/**
** @file pci.c
**
** @author Ryan Lembo-Ehms
**
** @brief PCI function implmentations based on OSdev wiki
**
*/

#include <pci.h>
#include <lib.h>
#include <cio.h>
#include <x86/ops.h>
#include <klib.h>
#include <kmem.h>
#include <support.h>

// Addresses of IO ports used to acces PCI configuration space
#define CONFIG_ADDRESS 	0xCF8
#define CONFIG_DATA 		0xCFC

// A device header in PCI configuration space is 256 bytes long,
// with data split across 16 32-bit registers
#define N_REGS          16

// Location of the multi-function bit in header register 0x2
#define MULTI_FUNCTION  0x80

// IDs to identify my NIC
#define INTEL_VENDOR_ID 0x8086
#define PRO100_DEV_ID   0x1209

// Basically the same as the pseudocode on OSDev wiki, but reads all 32 bits instead of 16
uint32_t pci_cfgspace_read_dword(uint8_t bus, uint8_t slot, uint8_t func, uint8_t offset) {
  uint32_t address;
  uint32_t lbus  = (uint32_t)bus;
  uint32_t lslot = (uint32_t)slot;
  uint32_t lfunc = (uint32_t)func;

  // Create configuration address
  address = (uint32_t)((lbus << 16) | (lslot << 11) |
            (lfunc << 8) | (offset & 0xFC) | ((uint32_t)0x80000000));

  // Write out the address
  outl(CONFIG_ADDRESS, address);

  return inl(CONFIG_DATA); 
}

uint16_t get_device_id(uint8_t bus, uint8_t slot, uint8_t function) {
  return (uint16_t) ((pci_cfgspace_read_dword(bus, slot, function, 0) >> 16) & 0xFFFF);
}

uint16_t get_vendor_id(uint8_t bus, uint8_t slot, uint8_t function) {
  return (uint16_t) (pci_cfgspace_read_dword(bus, slot, function, 0) & 0xFFFF);
}

// Read the header registers from PCI configuration space  
void read_header(uint8_t bus, uint8_t slot, uint8_t function, uint32_t *hdr) { 
  
  for (uint8_t i = 0; i < N_REGS; i++) {

    hdr[i] = pci_cfgspace_read_dword(bus, slot, function, i * 4);
  
  }

}

void pci_bus_scan(void) {
  char buf[128];
  uint16_t vendor_id, device_id;
  uint32_t *hdr_regs;

  for (uint16_t bus = 0; bus < 256; bus++) {

    for (uint8_t slot = 0; slot< 32; slot++) {

      vendor_id = get_vendor_id(bus, slot, 0);

      // Not a real vendor
      if (vendor_id == 0xFFFF) {
         continue;
      }

      device_id = get_device_id(bus, slot, 0);
      
#ifdef DEBUG_PCI 
      sprint(buf, "PCI Device Found: bus=%d slot=%d vendorID=0x%x deviceID=0x%x\n",
             bus, slot, vendor_id, device_id);
      cio_printf(buf);

      delay( DELAY_1_SEC );
#endif

      // If it's not the ethernet controller, move on
      // Actually good PCI scanning wouldn't do this, of course
      // If we want to handle more PCI devices, add more if's here I guess...
      if ( vendor_id != 0x8086 || device_id != PRO100_DEV_ID ) {
         continue;
      }
      
      // Allocate a page to store device header information
      // Should I use a slice instead of a page?      
      hdr_regs = (uint32_t *) km_page_alloc( 1 );
      
      // Read header information
      read_header(bus, slot, 0, hdr_regs);
      //uint8_t header_type = (hdr_regs[2] >> 16) & MULTI_FUNCTION;
      
#ifdef DEBUG_PCI
      for (uint8_t i = 0; i < N_REGS; i++) {   

        sprint(buf, "Reg 0x%x: %08x\n", i, hdr_regs[i]);
        cio_printf(buf);
      }

      // Give enough time to see dump of all header registers
      delay( DELAY_5_SEC );
#endif
     
      // Don't forget to free! 
      km_page_free(hdr_regs);

    } /* slot */

  } /* bus */

}
