/**
** @file pci.h
**
** @author Ryan Lembo-Ehms
**
** @brief Declarations and descriptions of PCI functions
**
** Refer to https://wiki.osdev.org/PCI#Common_Header_Fields
** for detailed explanations of PCI concepts
*/

#ifndef PCI_H
#define PCI_H

#include <types.h>

#define PCI_BAR_MEM 0x0
#define PCI_BAR_IO  0x1

// For the I/O BAR, bit 0 is always 1, and bit 1 is reserved,
// so mask off the lower to bits to get the actual base address.
#define PCI_BAR_IO_MASK 0xFFFFFFC

// Contains all the info for a PCI device header
// for header type 0x0.
typedef struct __attribute__((packed)) {
  // 0x00
  uint16_t vendor_id;
  uint16_t device_id;

  // 0x04
  uint16_t command;
  uint16_t status;

  // 0x08
  uint8_t  revision_id;
  uint8_t  prog_if;
  uint8_t  subclass;
  uint8_t  class_code;

  // 0x0C
  uint8_t  cache_line_size;
  uint8_t  latency_timer;
  uint8_t  header_type;
  uint8_t  bist;

  // 0x10 - 0x24 (BARs)
  uint32_t bar[6];

  // 0x28
  uint32_t cardbus_cis_ptr;

  // 0x2C
  uint16_t subsystem_vendor_id;
  uint16_t subsystem_id;

  // 0x30
  uint32_t expansion_rom_base;

  // 0x34
  uint8_t  capabilities_ptr;
  uint8_t  reserved1[3];

  // 0x38
  uint32_t reserved2;

  // 0x3C
  uint8_t  interrupt_line;
  uint8_t  interrupt_pin;
  uint8_t  min_grant;
  uint8_t  max_latency;

} pci_hdr_t;

// A generic PCI device struct, so I don't have to pass bus, slot, and function
// as arguments to the pci_cfgspace_read/write functions
typedef struct {

  // The bus, slot, and function of the PCI device
  uint8_t bus;
  uint8_t slot;
  uint8_t function;

  // Header registers
  pci_hdr_t *hdr;

} pci_dev_t;

extern pci_dev_t *pci_dev_pro100;

// Read one register from PCI configuration space.
uint32_t pci_cfgspace_read_dword(pci_dev_t *pci_dev, uint8_t offset);

void pci_cfgspace_write_dword(pci_dev_t *pci_dev, uint8_t offset, uint32_t val);

uint16_t get_device_id(pci_dev_t *pci_dev);

uint16_t get_vendor_id(pci_dev_t *pci_dev);

uint32_t pci_get_bar(pci_hdr_t *hdr, uint8_t type);

/* 
** Read a PCI device's header from PCI configuration space
** The header information is stored in the block of memory pointed to by hdr
*/
void read_header(pci_dev_t *pci_dev, uint32_t *hdr);

void check_device(pci_dev_t *pci_dev);

// Brute force scan PCI devices
void pci_bus_scan(void);

// Initialize PCI device list
void pci_init(void);

#endif
