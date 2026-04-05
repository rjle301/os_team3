/*
** @file: pro100.h
**
** @author: Ryan Lembo-Ehms
**
** @brief:
**
*/

typedef struct pro_100 {

  // Pro100 PCI information
  pci_dev_t *pci_dev;
  
  // MAC address
  uint8_t mac[6];

  uint16_t io_base_addr; 

} pro100_t;
 
extern pro100_t *pro100;

void pro100_init(void);
