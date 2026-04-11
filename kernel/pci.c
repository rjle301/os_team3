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
pci_dev_t *pci_dev_pro100;

// Basically the same as the pseudocode on OSDev wiki, but reads all 32 bits instead of 16
uint32_t pci_cfgspace_read_dword(pci_dev_t *pci_dev, uint8_t offset) {

  uint32_t address;
  uint32_t lbus  = (uint32_t)pci_dev->bus;
  uint32_t lslot = (uint32_t)pci_dev->slot;
  uint32_t lfunc = (uint32_t)pci_dev->function;

  // Create configuration address
  address = (uint32_t)((lbus << 16) | (lslot << 11) |
            (lfunc << 8) | (offset & 0xFC) | ((uint32_t)0x80000000));

  // Write out the address
  outl(CONFIG_ADDRESS, address);

  return inl(CONFIG_DATA); 

}

void pci_cfgspace_write_dword(pci_dev_t *pci_dev, uint8_t offset, uint32_t val) {

  uint32_t address;
  uint32_t lbus  = (uint32_t)pci_dev->bus;
  uint32_t lslot = (uint32_t)pci_dev->slot;
  uint32_t lfunc = (uint32_t)pci_dev->function;

  // Create configuration address
  address = (uint32_t)((lbus << 16) | (lslot << 11) |
            (lfunc << 8) | (offset & 0xFC) | ((uint32_t)0x80000000));

  // Write out the address
  outl(CONFIG_ADDRESS, address);

  // Write out the data
  outl(CONFIG_DATA, val);
}

uint16_t get_device_id(pci_dev_t *pci_dev) {
  return (uint16_t) ((pci_cfgspace_read_dword(pci_dev, 0) >> 16) & 0xFFFF);
}

uint16_t get_vendor_id(pci_dev_t *pci_dev) {
  return (uint16_t) (pci_cfgspace_read_dword(pci_dev, 0) & 0xFFFF);
}

// Gets the I/O BAR
uint32_t pci_get_bar(pci_hdr_t *hdr, uint8_t bar_type) {
  
  uint32_t bar = 0;

  for (int i = 0; i < 6; i++) {
    bar = hdr->bar[i];
    if ((bar & 0x1) == bar_type) {
      return bar;
    }
  }

  return 0xFFFFFFF0;
}

// Read the device's header registers from PCI configuration space  
void read_header(pci_dev_t *pci_dev, uint32_t *hdr) { 
  
  for (uint8_t i = 0; i < N_REGS; i++) {

    hdr[i] = pci_cfgspace_read_dword(pci_dev, i * 4);
  
  }

}

void check_device(pci_dev_t *pci_dev) {
   
  uint16_t vendor_id = get_vendor_id(pci_dev);

  if (vendor_id == 0xFFFF) {
    return;
  }
  
  uint16_t device_id = get_device_id(pci_dev);
  
#ifdef DEBUG_PCI 
  char buf[128];

  sprint(buf, "PCI Device Found: bus=%d slot=%d vendorID=0x%x deviceID=0x%x\n",
         pci_dev->bus, pci_dev->slot, vendor_id, device_id);
  cio_printf(buf);

  delay( DELAY_1_SEC );

#endif
  
  // If it's the Pro100 NIC, make it global so we can use it in driver initialization
  // Actually good PCI scanning wouldn't do this, of course. We should use a global
  // list (queue) of device headers...
  if ( vendor_id == INTEL_VENDOR_ID && (device_id == PRO100_DEV_ID || device_id == 0x1229) ) {

    // Allocate a page to store device header information
    // Should I use a slice instead of a page?      
    uint32_t *hdr_regs = (uint32_t *) km_page_alloc(1);
    
    // Read header information
    read_header(pci_dev, hdr_regs); 

    pci_dev->hdr = (pci_hdr_t *) hdr_regs;
    pci_dev_pro100 = pci_dev;

#ifdef DEBUG_PCI
    for (uint8_t j = 0; j < 0x6; j++) {
      sprint( buf, "BAR[%x]=0x%08x\n", j, pci_dev_pro100->hdr->bar[j] );
      cio_printf( buf );
    }

    sprint(buf, "Interrupt PIN=0%x, Interrupt Line=0x%x\n",
                pci_dev->hdr->interrupt_pin, pci_dev->hdr->interrupt_line);
    cio_printf( buf );

    // Give enough time to see dump of all header registers
    delay( DELAY_2_SEC );
#endif

  }

}

// This function has many nested blocks, so using comments
// at the end of blocks for extra clarity
void pci_bus_scan(void) {

  pci_dev_t *pci_dev;

  for ( uint16_t bus = 0; bus < N_BUSES; bus++ ) {

    for ( uint8_t slot = 0; slot< N_SLOTS; slot++ ) {
      
      pci_dev = km_page_alloc( 1 );
      pci_dev->bus = bus;
      pci_dev->slot = slot;
      pci_dev->function = 0;
      pci_dev->hdr = NULL;

      check_device( pci_dev );
      
      // Either not a real device or not the device we are looking for
      if ( pci_dev->hdr == NULL ) {
        km_page_free( pci_dev );
        continue;
      }

      // If we have a multi-function device, we need to treat
      // each function individually 
      uint8_t header_type = pci_dev->hdr->header_type;
      if ( header_type & MULTI_FUNCTION ) {
        
        for ( uint8_t i = 1; i < N_FUNCS; i++ ) {
          
          // Each of this devices functions needs it's own entry!
          check_device( pci_dev );

          if ( pci_dev == NULL ) {
            continue;
          } /* if */

          else if ( pci_dev->hdr == NULL ) {
            km_page_free( pci_dev );
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
