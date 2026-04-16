/*
** @file: pro100.h
**
** @author: Ryan Lembo-Ehms
**
** @brief:
**
*/

#ifndef PRO_100_H
#define PRO_100_H

#include <pci.h>
#include <device/cb.h>

typedef struct pro_100 {

  // Pro100 PCI information
  pci_dev_t *pci_dev;
  
  // MAC address
  uint8_t mac[6];
 
  // Beginning of the I/O communication space 
  uint16_t io_base_addr; 

} pro100_t;
 
extern pro100_t *pro100;


/*
** Functions for reading from / writing to the Pro100 NIC
*/
void pro100_outl(uint32_t offset, uint32_t val);
void pro100_outw(uint32_t offset, uint16_t val);
void pro100_outb(uint32_t offset, uint8_t val);
uint32_t pro100_inl(uint32_t offset);
uint16_t pro100_inw(uint32_t offset);
uint8_t pro100_inb(uint32_t offset);


/*
** Creates the necessary command blocks to initialize the Pro100.
** In particular, creates a Configure CB and an IAS CB and links
** them together. These commands will be run after a software
** reset is issued.
*/
cb_config_t *pro100_create_init_cbs(void);

/*
** Enables I/O communication from the CPU to the NIC
*/
void pro100_access_enable(void);

/*
** Builds a TxCB, constructs an ethernet packet, and
** begins the transmit action command
*/
void pro100_transmit(char *data);

/*
** Sets the Pro100 NIC up for Transmit/Recieve
*/
void pro100_init(void);

#endif
