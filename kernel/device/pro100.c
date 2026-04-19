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
#include <x86/pic.h>
#include <lib.h>
#include <support.h>
#include <cio.h>
#include <klib.h>

/*
** Macros for values used in write/out_ functions
*/
#define BUS_MASTER      (1 << 2)
#define IO_SPACE        (1 << 0)
#define SOFTWARE_RESET  0x00
#define RU_START        0x0001
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

#define STAT_ACK      SCB_STATUS + 0x01

/*
** Interrupt flags set by the NIC inside the
** SCB Status word. These are called the STAT/ACK
** bits and only live in the upper byte of the word
**
** Bits 7:2 and bit 0 are used. Bit 1 is reserved
*/
#define CX_TNO_INT    0x80
#define FR_INT        0x40
#define CNA_INT       0x20
#define RNR_INT       0x10
#define MDI_INT       0x08
#define SWI_INT       0x04
#define FCP_INT       0x01

/*
** Command Block (CB) Macros
*/
#define CB_CMD_NOP    0x0000
#define CB_CMD_IAS    0x0001
#define CB_CMD_CFG    0x0002
#define CB_CMD_TX     0x0004
#define CB_CMD_SF     0x0008
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

/*
** For more detailed information about the Pro100's interrupt flags, visit
** page 43 of the Intel 8255x datasheet.
*/
void pro100_isr(int vector, int code) {

  uint8_t flags = pro100_inb(STAT_ACK);
  
#ifdef DEBUG_NIC
  cio_printf("\n** Pro100 ISR! vector=0x%02x, code=%d\n",
      (unsigned int) vector, code);

  // Print the STAT/ACK bits so we can see which interrupt flag is set
  cio_printf("STAT/ACK bits=%x\n", flags);
#endif

  // We're probably in this ISR because a frame was recieved
  // Frame recieved == FR
  if (flags & FR_INT) {

    // Start by acking the interrupt
    pro100_outb(STAT_ACK, FR_INT);
    flags &= ~FR_INT;

    // Now process the recieved frame
    pro100_recieve();
  }

  // The other main interrupt flag is the CNA flag, which gets set
  // everytime the command unit (CU) leaves the active state.
  if (flags & CNA_INT) {
    pro100_outb(STAT_ACK, CNA_INT);
    flags &= ~CNA_INT;
  }

  // This will acknowledge ALL remaining interrupt flags raised by the NIC,
  // even though we aren't handling them all.
  // This driver is simple enough that nothing else besdies the RSR flag
  // should be set
  pro100_outb(STAT_ACK, flags);
  
  // Tell the PIC we're done
  outb(PIC2_CMD, PIC_EOI);
  outb(PIC1_CMD, PIC_EOI);
}

cb_config_t *pro100_create_init_cbs(void) {
  
  cb_ias_t *cb_ias = (cb_ias_t *) km_page_alloc(1);
  cb_ias->hdr.status = 0;
  cb_ias->hdr.command = CB_CMD_IAS | CB_CMD_EL;
  cb_ias->hdr.link = 0xFFFFFFFF;
  
  // Set a random mac address
#ifdef BUILD_1
  cb_ias->mac[0] = 0xA2;
  cb_ias->mac[1] = 0xB3;
  cb_ias->mac[2] = 0xC4;
  cb_ias->mac[3] = 0xD5;
  cb_ias->mac[4] = 0xE6;
  cb_ias->mac[5] = 0xF7;
#else
  cb_ias->mac[0] = 0x2A;
  cb_ias->mac[1] = 0x3B;
  cb_ias->mac[2] = 0x4C;
  cb_ias->mac[3] = 0x5D;
  cb_ias->mac[4] = 0x6E;
  cb_ias->mac[5] = 0x7F;
#endif
  

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

void pro100_rx_init(void) {
  
  // Build the RFD 
  rfd_t *rfd = (rfd_t *) km_page_alloc(1);
  rfd->hdr.status = 0;
  rfd->hdr.command = CB_CMD_SF | CB_CMD_EL; 
  rfd->hdr.link = 0xFFFFFFFF;

  // Clear four bytes where recieve frame info goes.
  // These bytes will be set by the device when a 
  // frame is recieved
  memset(&rfd->actual_count, sizeof(uint32_t), 0);
 
  // Tell device it is ready to recieve frames
  pro100_outl(SCB_POINTER, (uint32_t) rfd);
  pro100_outw(SCB_COMMAND, RU_START | CNA_INT_MASK); 

  // Copy this RFD to the logical device so we can access it later
  pro100->rfd = rfd;
}

void pro100_recieve(void) {
  // Check how many bytes were recieved
  uint32_t byte_count = pro100->rfd->actual_count;
#ifdef DEBUG_NIC
  cio_printf("\n** Recieved %d bytes!\n", byte_count);
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
  ** Begin packet construction
  */ 
  uint8_t *p = tx_cb->packet;

  // Destination MAC  
#ifdef BUILD_1
  p[0] = 0x2A;
  p[1] = 0x3B;
  p[2] = 0x4C;
  p[3] = 0x5D;
  p[4] = 0x6E;
  p[5] = 0x7F;
#else
  p[0] = 0xA2;
  p[1] = 0xB3;
  p[2] = 0xC4;
  p[3] = 0xD5;
  p[4] = 0xE6;
  p[5] = 0xF7;
#endif
  

  // Source MAC. Not inserted by NIC, per settings from config command
  memcpy(&p[6], pro100->mac, 6);

  // EtherType. 0x0800 = IPv4
  // Probably doesn't matter if ethernet cable runs computer-to-computer
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

  /*
  ** End packet construction
  */

  // Begin transmission
  pro100_outl(SCB_POINTER, (uint32_t) tx_cb);
  pro100_outw(SCB_COMMAND, CU_START);
  
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
#ifdef DEBUG_NIC
  char buf[128];
#endif
  
  pro100 = (pro100_t *) km_page_alloc(1);

  // Initialize the pro100's fields
  pro100->pci_dev = pci_dev_pro100;
  pro100->io_base_addr = pci_get_bar(pro100->pci_dev->hdr, PCI_BAR_IO) & PCI_BAR_IO_MASK;

  // Enable I/O space access of the device
  pro100_access_enable();

  // Now that we can access the device, issue a software reset
  // to prepare it for initialization
  pro100_outl(pro100->io_base_addr + PORT, SOFTWARE_RESET);

  // The device's operating parameters need initialization after a reset
  cb_config_t *cb_config = pro100_create_init_cbs();
  pro100_outl(SCB_POINTER, (uint32_t) cb_config);
  pro100_outw(SCB_COMMAND, CU_START | CNA_INT_MASK);

  // Now prepare the device for ethernet frame reception
  pro100_rx_init();

#ifdef DEBUG_NIC
  
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

  // Lastly, install the ISR that handles interrupts
  // generated by the NIC
  install_isr(VEC_NIC, &pro100_isr);
  
  // Free the command block memory
  // cast to silence compiler warnings
  km_page_free((cb_ias_t *) cb_config->hdr.link);
  km_page_free(cb_config);
}

