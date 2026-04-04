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

/*
** PRIVATE DEFINITIONS
*/

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

#define N_BUSES         256
#define N_SLOTS         32
#define N_FUNCS         8

/*
** PRIVATE GLOBAL VARIABLES
*/


/*
** PUBLIC GLOBAL VARIABLES
*/
pci_hdr_t *pro100_hdr;

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

uint32_t *check_device(uint8_t bus, uint8_t slot, uint8_t function) {
   
  uint16_t vendor_id = get_vendor_id(bus, slot, 0);

  if (vendor_id == 0xFFFF) {
    return NULL;
  }

  uint16_t device_id = get_device_id(bus, slot, function);
  
#ifdef DEBUG_PCI 
  char buf[128];

  sprint(buf, "PCI Device Found: bus=%d slot=%d vendorID=0x%x deviceID=0x%x\n",
         bus, slot, vendor_id, device_id);
  cio_printf(buf);

  delay( DELAY_1_SEC );

#endif
  
  // Allocate a page to store device header information
  // Should I use a slice instead of a page?      
  uint32_t *hdr_regs = (uint32_t *) km_page_alloc( 1 );
  
  // Read header information
  read_header(bus, slot, 0, hdr_regs); 

  // If it's the Pro100 NIC, make it global so we can use it in driver initialization
  // Actually good PCI scanning wouldn't do this, of course. We should use a global
  // list (queue) of device headers...
  if ( vendor_id == INTEL_VENDOR_ID && (device_id == PRO100_DEV_ID || device_id == 0x1229) ) {

    pro100_hdr = (pci_hdr_t *) hdr_regs;

#ifdef DEBUG_PCI
    for (uint8_t j = 0; j < 0x6; j++) {
      sprint( buf, "BAR[%x]=0x%08x\n", j, pro100_hdr->bar[j] );
      cio_printf( buf );
    }

    // Give enough time to see dump of all header registers
    delay( DELAY_5_SEC );
#endif

  }

  return hdr_regs;
}

// This function has many nested blocks, so using comments
// at the end of blocks for extra clarity
void pci_bus_scan(void) {

  uint32_t *hdr_regs;

  for ( uint16_t bus = 0; bus < N_BUSES; bus++ ) {

    for ( uint8_t slot = 0; slot< N_SLOTS; slot++ ) {

      hdr_regs = check_device( bus, slot, 0 );

      if ( hdr_regs == NULL ) {
         continue;
      }

      // If we have a multi-function device, we need to treat
      // each function individually 
      uint8_t header_type = hdr_regs[2] >> 16;
      if ( header_type & MULTI_FUNCTION ) {
        
        for ( uint8_t i = 1; i < N_FUNCS; i++ ) {
          
          // Each of this devices functions needs it's own entry!
          hdr_regs = check_device( bus, slot, i );
          if ( hdr_regs == NULL ) {
            continue;
          } /* if */

        } /* for funcs */

      } /* if */
      
    } /* for slots */

  } /* for buses */

} /* pci_bus_scan */

void pci_init(void) {
  
  // Nothing else here at the moment, but putting call to bus_scan in
  // a wrapper function in case we want to create a queue and store
  // device headers in the queue
  pci_bus_scan(); 

}
