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

uint16_t pciConfigReadWord(uint8_t bus, uint8_t slot, uint8_t func, uint8_t offset) {
  uint32_t address;
  uint32_t lbus  = (uint32_t)bus;
  uint32_t lslot = (uint32_t)slot;
  uint32_t lfunc = (uint32_t)func;
  uint16_t tmp = 0;

  // Create configuration address
  address = (uint32_t)((lbus << 16) | (lslot << 11) |
            (lfunc << 8) | (offset & 0xFC) | ((uint32_t)0x80000000));

  // Write out the address
  outl(CONFIG_ADDRESS, address);
  // Read in the data
  // (offset & 2) * 8) = 0 will choose the first word of the 32-bit register
  tmp = (uint16_t)((inl(CONFIG_DATA) >> ((offset & 2) * 8)) & 0xFFFF);
  return tmp;
}

void pci_scan(void) {
  char buf[128];
  uint16_t vendorID, deviceID;

  for (uint16_t bus = 0; bus < 3; bus++) {
    for (uint8_t slot = 0; slot < 4; slot++) {
      for (uint8_t function = 0; function < 8; function++) {

        if ((vendorID = pciConfigReadWord(bus, slot, 0, 0)) != 0xFFFF) {
          deviceID = pciConfigReadWord(bus, slot, 0, 2);
          sprint(buf, "PCI Device Found: bus=%d slot=%d function=%d vendor=0x%x device=0x%x\n",
                 bus, slot, function, vendorID, deviceID);
          cio_printf(buf);
        }
      }
    }
  }
}
