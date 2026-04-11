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

typedef struct __attribute__((packed)) {
  
  uint16_t status;
  uint16_t command;
  uint32_t link;

} cb_t;

/*
** Functions for reading from / writing to the Pro100 NIC
*/
void pro100_outl(uint32_t offset, uint32_t val);
void pro100_outw(uint32_t offset, uint16_t val);
void pro100_outb(uint32_t offset, uint8_t val);
uint32_t pro100_inl(uint32_t offset);
uint16_t pro100_inw(uint32_t offset);
uint8_t pro100_inb(uint32_t offset);

void pro100_access_enable(void);

void pro100_init(void);
