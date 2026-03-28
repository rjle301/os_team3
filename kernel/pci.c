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

#define PRO100_DEV_ID   0x1209

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

void check_device(uint8_t bus, uint8_t slot) {
  char buf[128];
  uint16_t function = 0;  

  uint16_t vendor_id = get_vendor_id(bus, slot, function);
  if (vendor_id == 0xFFFF) {
    return;
  }
  
  uint16_t device_id = get_device_id(bus, slot, function);
   
  sprint(buf, "PCI Device Found: bus=%d slot=%d function=%d vendorID=0x%x deviceID=0x%x\n",
         bus, slot, function, vendor_id, device_id);
  cio_printf(buf);

#ifdef DEBUG_PCI 
  delay( DELAY_2_SEC );
#endif

  // I ONLY CARE ABOUT THE ETHERNET CONTROLLER !!
  // STOP PROCESSING ALL OTHER PCI DEVICES HERE !!
  if (device_id != PRO100_DEV_ID) {
    return;
  }
 
  // Read the header registers from PCI configuration space  
  uint32_t *regs = (uint32_t *) km_page_alloc(1);

  for (int i = 0; i < N_REGS; i++) {
    regs[i] = pci_cfgspace_read_dword(bus, slot, function, i * 4);
#ifdef DEBUG_PCI
    sprint(buf, "Reg 0x%x: %08x\n", i, regs[i]);
    cio_printf(buf);
#endif
  }

#ifdef DEBUG_PCI
  // Give enough time to see dump of all header registers
  delay( DELAY_10_SEC );
#endif
  
  km_page_free(regs);
}

void pci_bus_scan(void) {
  for (uint16_t bus = 0; bus < 256; bus++) {
    for (uint8_t slot= 0; slot< 32; slot++) {
      check_device(bus, slot);
    }
  }
}
