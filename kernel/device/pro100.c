/*
** @file: pro100.c
**
** @author: Ryan Lembo-Ehms
**
** @brief: Pro100 device code
*/

#include <pci.h>
#include <device/cb.h>
#include <device/pro100.h>
#include <kmem.h>
#include <x86/ops.h>
#include <lib.h>

/** These are for print debugging */
#include <support.h>
#include <cio.h>
#include <klib.h>
/** ====== */

/*
** Macros for values used in write/out_ functions
*/
#define BUS_MASTER      (1 << 2)
#define IO_SPACE        (1 << 0)
#define SOFTWARE_RESET  0x00
#define CU_START        0x0010
#define CU_RESUME       0x0020
#define INT_MASK        0x0100
#define CNA_INT_MASK    0x2000

/*
** Intel 8255x Control/Status Register (CSR) Macros
** Offsets from the Pro100's I/O base address
*/
#define SCB_STATUS    0x00
#define SCB_COMMAND   0x02
#define SCB_POINTER   0x04
#define PORT          0x08
#define EEPROM_CTRL   0x0E

/*
** Command Block (CB) Macros
*/
#define CB_CMD_NOP    0x0000
#define CB_CMD_IAS    0x0001
#define CB_CMD_CFG    0x0002
#define CB_CMD_TX     0x0004
#define CB_CMD_EL     0x8000  // Any cb with this bit set is the last cb
#define TXCB_EOF      0x8000
#define CMD_SUCCESS   0xA000

// Global Pro100 pointer
pro100_t *pro100;

void pro100_outl(uint32_t offset, uint32_t val) {
  outl(pro100->io_base_addr + offset, val);
}

void pro100_outw(uint32_t offset, uint16_t val) {
  outw(pro100->io_base_addr + offset, val);
}

void pro100_outb(uint32_t offset, uint8_t val) {
  outb(pro100->io_base_addr + offset, val);
}

uint32_t pro100_inl(uint32_t offset) {
  return inl(pro100->io_base_addr + offset);
}

uint16_t pro100_inw(uint32_t offset) {
  return inw(pro100->io_base_addr + offset);
}

uint8_t pro100_inb(uint32_t offset) {
  return inb(pro100->io_base_addr + offset);
}

cb_config_t *pro100_create_init_cbs(void) {
  
  cb_ias_t *cb_ias = (cb_ias_t *) km_page_alloc(1);
  cb_ias->hdr.status = 0;
  cb_ias->hdr.command = CB_CMD_IAS | CB_CMD_EL;
  cb_ias->hdr.link = 0xFFFFFFFF;
  
  // Set a random mac address
  cb_ias->mac[0] = 0xA2;
  cb_ias->mac[1] = 0xB3;
  cb_ias->mac[2] = 0xC4;
  cb_ias->mac[3] = 0xD5;
  cb_ias->mac[4] = 0xE6;
  cb_ias->mac[5] = 0xF7;

  // Copy this 6-byte mac address to the Pro100 device structure in memory
  // Might be important later for building Tx frames
  memcpy(pro100->mac, cb_ias->mac, 6);

  // Now build the Configure command and set it's link
  // to the IAS command
  cb_config_t *cb = (cb_config_t *) km_page_alloc(1);
  cb->hdr.status = 0;
  cb->hdr.command = CB_CMD_CFG; 
  cb->hdr.link = (uint32_t) cb_ias;
  
  // Set everything in the config map to 0, 
  // because many recommended values are 0 
  memset(cb->config, N_CONFIG_BYTES, 0);

  // Set the fundamental operating parameters of the Pro100
  // Uses the recommended settings from the datasheet
  cb->config[0]   = 0x16;  // 22 bytes configuration map
  cb->config[1]   = 0x08;  // FIFO Tx/Rx limits
  cb->config[3]   = 0x01;  // Read alignment
  cb->config[6]   = 0x30;  // Standard TxCB
  cb->config[7]   = 0x03;  // Retry after bad Rx
  cb->config[8]   = 0x01;  // PHY MII mode
  cb->config[10]  = 0x28;  // 7-byte preamble, NSAI
  cb->config[12]  = 0x60;  // IFS
  cb->config[14]  = 0xF2;  // For backwards compatibility
  cb->config[18]  = 0xF3;  // Padding + Stripping of frames
  cb->config[19]  = 0x80;  // Mandatory bits for 82559
  cb->config[20]  = 0x3F;  // Mandatory bits for 82559
  cb->config[21]  = 0x05;  // Disables Multicast all

  return cb;
}

void pro100_access_enable(void) {
  
  // 0x4 is the offset of the register with command 
  // Refer to the pci_dev_t struct in include/pci.h for 
  // offsets of each header register.
  uint32_t command = pci_cfgspace_read_dword(pro100->pci_dev, 0x4);

#ifdef DEBUG_PCI
  char buf[128];
  sprint(buf, "Pro100 PCI command reg=0x%x\n", command);
  cio_printf(buf);
  delay( DELAY_1_SEC );
#endif

  command = command | BUS_MASTER | IO_SPACE;

#ifdef DEBUG_PCI
  sprint(buf, "Pro100 PCI command reg=0x%x\n", command);
  cio_printf(buf);
  delay( DELAY_1_SEC );
#endif

  pci_cfgspace_write_dword(pro100->pci_dev, 0x4, command); 

#ifdef DEBUG_PCI
  command = pci_cfgspace_read_dword(pro100->pci_dev, 0x4);
  sprint(buf, "Pro100 PCI command reg=0x%x\n", command);
  cio_printf(buf);
  delay( DELAY_1_SEC );
#endif

}

void pro100_transmit(char *data) {
 
  // Build the TxCB
  tx_cb_t *tx_cb = (tx_cb_t *) km_page_alloc(1);
  tx_cb->hdr.status = 0;
  tx_cb->hdr.command = CB_CMD_TX | CB_CMD_EL;
  tx_cb->hdr.link = 0xFFFFFFFF;

  tx_cb->tbd_addr = 0xFFFFFFFF;
  tx_cb->tx_threshold = 0x01;
  tx_cb->tbd_number = 0;
 
  /*
  ** Begin packet building
  */ 
  uint8_t *p = tx_cb->packet;
  
  // Destination MAC arbitrary
  p[0] = 0x11;
  p[1] = 0x22;
  p[2] = 0x33;
  p[3] = 0x44;
  p[4] = 0x55;
  p[5] = 0x66;

  // Source MAC. Not inserted by NIC
  memcpy(&p[6], pro100->mac, 6);

  // EtherType. 0x0800 = IPv4
  p[12] = 0x08;
  p[13] = 0x00;
  
  // Payload
  // config map byte 18 bits 1:0 means NIC should handle packet
  // padding and stripping, so SHOULD be fine if data is shorter
  // than minimum required ethernet frame length 
  uint32_t len_data = strlen(data);
  memcpy(&p[14], data, len_data);
  
  // 14 = 2 * 6-byte MAC addresses, 2-byte Length/Type field
  tx_cb->byte_count = 14 + len_data;

  // Begin transmission
  pro100_outl(SCB_POINTER, (uint32_t) tx_cb);
  pro100_outw(SCB_COMMAND, CU_START | CNA_INT_MASK);
  
  // Poll to see if entire frame has been sent to NIC's transmit FIFO
  while(!(tx_cb->hdr.status & CMD_SUCCESS)) {
    // wait
  }

  // Once the entire frame is given to the NIC, we can free this memory
  km_page_free(tx_cb);
}

// Consider changing this to return a pointer to some struct
// that represents a network device
void pro100_init() {
  
  pro100 = (pro100_t *) km_page_alloc(1);

  // Initialize the pro100's fields
  pro100->pci_dev = pci_dev_pro100;
  pro100->io_base_addr = pci_get_bar(pro100->pci_dev->hdr, PCI_BAR_IO) & PCI_BAR_IO_MASK;

  // Enable I/O space access of the device
  pro100_access_enable();

  // Now that we can access the device, issue a software reset
  // to prepare it for initialization
  pro100_outl(pro100->io_base_addr + PORT, SOFTWARE_RESET);
  
  // Recommended delay after software reset is 15us.
  // With 1 KHz clock frequency, no delay should be needed
  // Time for a CB No-Op command
  //cb_t *cb_noop = (cb_t *) km_page_alloc(1);
  //cb_noop->status = 0;
  //cb_noop->command = CB_CMD_NOP | CB_CMD_EL; 
  //cb_noop->link = 0xFFFFFFFF; // end of list
  
  // Load the No-Op command block into the SCB 
  //pro100_outl(SCB_POINTER, (uint32_t) cb_noop);

  // This generates an interrupt I'm not handling yet, so mask for now
  //pro100_outw(SCB_COMMAND, CU_START | CNA_INT_MASK);

  // The device's operating parameters need initialization after a reset
  cb_config_t *cb_config = pro100_create_init_cbs();
  pro100_outl(SCB_POINTER, (uint32_t) cb_config);
  pro100_outw(SCB_COMMAND, CU_START | CNA_INT_MASK);



  /*
  ** Here lies the transmit milestone
  ** packet construction and transmission will be moved to it's
  ** own function and called via a syscall from a user program
  **
  ** Syscall should call packet send function, check the result
  ** of the trasmit, and print a message based on that result
  */
  // Null terminated and word aligned
  char *msg = "Hello, World! RLE\0";
  pro100_transmit(msg);


#ifdef DEBUG_PCI
  
  char buf[128];

  // lets do some testing and see what we have here
  sprint(buf, "Command block Status=0x%04x\n", cb_config->hdr.status);
  cio_printf(buf);
  delay( DELAY_1_SEC );
  
  // Read scb status and ack any interrupt bits set
  uint16_t scb_status = pro100_inw(SCB_STATUS);
  sprint(buf, "SCB Status=0x%04x\n", scb_status);
  cio_printf(buf);
  delay( DELAY_1_SEC );

  uint16_t scb_command = pro100_inw(SCB_COMMAND);
  sprint(buf, "SCB Command=0x%04x\n", scb_command);
  cio_printf(buf);
  delay( DELAY_1_SEC );

#endif
  
  // Free the command block memory
  // cast to silence compiler warnings
  km_page_free((cb_ias_t *) cb_config->hdr.link);
  km_page_free(cb_config);
}
