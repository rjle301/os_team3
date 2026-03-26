/**
** @file pci.h
**
** @author Ryan Lembo-Ehms
**
** @brief Declarations and descriptions of PCI functions
**
*/

#ifndef PCI_H
#define PCI_H

#include <types.h>

#define CONFIG_ADDRESS 	0xCF8
#define CONFIG_DATA 		0xCFC

// Read 16-bit fields from configuration space.
uint16_t pciConfigReadWord(uint8_t bus, uint8_t slot, uint8_t func, uint8_t offset);

// Brute force scan PCI devices
void pci_scan(void);

#endif
