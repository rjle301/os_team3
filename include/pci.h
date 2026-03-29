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


// Read one register from PCI configuration space.
uint32_t pci_cfgspace_read_dword(uint8_t bus, uint8_t slot, uint8_t func, uint8_t offset);

uint16_t get_device_num(uint8_t bus, uint8_t slot, uint8_t function);

uint16_t get_vendor_id(uint8_t bus, uint8_t slot, uint8_t function);

// Read a PCI device's header from PCI configuration space
// The header information is stored in the block of memory pointed to by hdr
void read_header(uint8_t bus, uint8_t slot, uint8_t function, uint32_t *hdr);

// Brute force scan PCI devices
void pci_bus_scan(void);

#endif
