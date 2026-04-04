/*
** @file: pro100.h
**
** @author: Ryan Lembo-Ehms
**
** @brief:
**
*/

typedef struct pro_100 {
  pci_hdr_t *pci_hdr;
  uint8_t mac[6];
  uint16_t io_base_addr; 
} pro100_t;
 
extern pro100_t *pro100;

void pro100_init(void);
