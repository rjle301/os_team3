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

// Contains all the info for a PCI device header
// Figures can be found on https://wiki.osdev.org/PCI#Configuration_Space
//typedef struct pci_device_header {
//  union {
//    uint32_t regs[N_REGS];
//  }
//  struct {
//    
//  }
//} pci_dev_hdr_t

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

// Limit max devices to how many pointers can fit on one page of memory
//#define MAX_DEVICES     1024

//extern uint32_t *pci_header_list[MAX_DEVICES];
extern pci_hdr_t *pro100_hdr;

// Read one register from PCI configuration space.
uint32_t pci_cfgspace_read_dword(uint8_t bus, uint8_t slot, uint8_t func, uint8_t offset);

uint16_t get_device_num(uint8_t bus, uint8_t slot, uint8_t function);

uint16_t get_vendor_id(uint8_t bus, uint8_t slot, uint8_t function);

// Read a PCI device's header from PCI configuration space
// The header information is stored in the block of memory pointed to by hdr
void read_header(uint8_t bus, uint8_t slot, uint8_t function, uint32_t *hdr);

// Brute force scan PCI devices
void pci_bus_scan(void);

// Initialize PCI device list
void pci_init(void);

#endif
