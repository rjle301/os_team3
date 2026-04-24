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

  // Offset 0x00
  uint16_t vendor_id;
  uint16_t device_id;

  // Offset 0x04
  uint16_t command;
  uint16_t status;

  // Offset 0x08
  uint8_t  revision_id;
  uint8_t  prog_if;
  uint8_t  subclass;
  uint8_t  class_code;

  // Offset 0x0C
  uint8_t  cache_line_size;
  uint8_t  latency_timer;
  uint8_t  header_type;
  uint8_t  bist;

  // Offset 0x10 - 0x24 (BARs)
  uint32_t bar[6];

  // Offset 0x28
  uint32_t cardbus_cis_ptr;

  // Offset 0x2C
  uint16_t subsystem_vendor_id;
  uint16_t subsystem_id;

  // Offset 0x30
  uint32_t expansion_rom_base;

  // Offset 0x34
  uint8_t  capabilities_ptr;
  uint8_t  reserved1[3];

  // Offset 0x38
  uint32_t reserved2;

  // Offset 0x3C
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

/*
** pci_cfgspace_readl
**
** Reads 4 bytes from PCI configuration space
**
** @param pci_dev - The PCI device to read from
** @param offset - The offset from the base to read from
** 
** @return The 4 bytes read
*/
uint32_t pci_cfgspace_readl(pci_dev_t *pci_dev, uint8_t offset);

/*
** pci_cfgspace_writel
**
** Writes 4 bytes to PCI configuration space
**
** @param pci_dev - The PCI device to write
** @param offset - The offset from the base to write to
** @param val - The value to write
*/
void pci_cfgspace_writel(pci_dev_t *pci_dev, uint8_t offset, uint32_t val);


/*
** get_device_id
**
** Gets the device ID from a PCI device
**
** @param pci_dev - The PCI device
**
** @return The 2-byte PCI device ID
*/
uint16_t get_device_id(pci_dev_t *pci_dev);

/*
** get_vendor_id
**
** Gets the vendor ID from a PCI device
**
** @param pci_dev - The PCI device
**
** @return The 2-byte PCI vendor ID
*/
uint16_t get_vendor_id(pci_dev_t *pci_dev);

/*
** pci_get_bar
**
** Gets one base address register (BAR) from a PCI device
**
** @param pci_dev - The PCI device
** @param type - The type of BAR
**
** @return The 4-byte BAR read from the PCI device
*/
uint32_t pci_get_bar(pci_hdr_t *hdr, uint8_t type);

/* 
** read_header
**
** Read a PCI device's header from PCI configuration space
** The header information is stored in the block of memory pointed to by hdr
**
** @param pci_dev - The PCI device
** @param hdr - Address where the PCI device header is stored
*/
void read_header(pci_dev_t *pci_dev, uint32_t *hdr);

/*
** check_device
**
** Checks if this is a real PCI device. If it is, it then checks
** if this is the Pro100 NIC.
**
** @param pci_dev - the PCI device to check
*/
void check_device(pci_dev_t *pci_dev);

/*
** pci_bus_scan
**
** Scans all PCI buses, devices, and functions
*/
void pci_bus_scan(void);

/*
** pci_init
**
** Initializes PCI devices that we are looking for. In this project, it will
** skip anything that's not the Pro100 NIC.
*/
void pci_init(void);

#endif
