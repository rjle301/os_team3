/*
** @file: pro100.h
**
** @author: Ryan Lembo-Ehms
**
** @brief: Pro100 driver function definitions
**
*/

#ifndef PRO_100_H
#define PRO_100_H

#include <pci.h>
#include <device/cb.h>

// Other interrupt vectors are in include/x86/arch.h
#define VEC_NIC 0x2b

typedef struct pro_100 {

  // Pro100 PCI information
  pci_dev_t *pci_dev;
  
  // MAC address
  uint8_t mac[6];
 
  // Beginning of the I/O communication space 
  uint16_t io_base_addr;

  // The device's Recieve Frame Descriptor
  // Recieved ethernet frames are copied here by the device
  rfd_t *rfd;

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
** End read/write functions
*/

void pro100_isr(int vector, int code);

/*
** Creates a individual address setup command block, gives it to the NIC,
** and issues a CU_START command to process the command block
*/
void pro100_address_setup(void);

/*
** Creates a configure command block, gives it to the NIC,
** and issues a CU_START command to process the command block
*/
void pro100_configure(void);

/*
** Enables I/O communication from the host CPU to the NIC
*/
void pro100_access_enable(void);

/*
** Creates the first (and only) RFD, gives it to the NIC
** and issues an RU_START command to the NIC
*/
void pro100_rx_init(void);

/*
** Parses a recieved ethernet frame and prints the data.
**
** Called in pro100_isr
*/
void pro100_recieve(void);

/*
** Builds a TxCB, constructs an ethernet packet, and
** issues a transmit command to the NIC
*/
void pro100_transmit(char *data);

/*
** Initialization routine for the Pro100 NIC.
** Performs a software reset, then configures
** the NIC. Once this routine returns, the
** NIC should be ready to transmit and recieve
** ethernet frames
*/
void pro100_init(void);

#endif
