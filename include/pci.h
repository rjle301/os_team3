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

// Limit max devices to how many pointers can fit on one page of memory
//#define MAX_DEVICES     1024

//extern uint32_t *pci_header_list[MAX_DEVICES];
extern uint32_t *pro100_hdr;

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
