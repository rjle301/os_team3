/*
** @file cb.h
**
** @author Ryan Lembo-Ehms
**
** @brief command block structures used to control the Pro100
*/

#ifndef CMDBLOCK_H
#define CMDBLOCK_H

#define N_CONFIG_BYTES  22
#define ETH_FRAME_SIZE  64

/*
** Shared fields across all command blocks
*/
typedef struct __attribute__((packed)) {
  
  uint16_t status;
  uint16_t command;
  uint32_t link;

} cb_t;


/*
** Command block for a Configure command
** Sets the Pro100's operating parameters
*/
typedef struct __attribute__((packed)) {
  
  // Bytes are packed so this can't be a pointer
  cb_t hdr;

  // Contiguous 22-byte configuration map
  uint8_t config[N_CONFIG_BYTES];

} cb_config_t;

/*
** Command block for an Individual Address Setup command
** Sets the Pro100's MAC address
*/
typedef struct __attribute__((packed)) {
  
  // Bytes are packed so this can't be a pointer 
  cb_t hdr;

  // MAC addresses are 6 bytes long
  uint8_t mac[6];

} cb_ias_t;

/*
** Command block for packet transmission.
** Referred to in the datasheet as a Transmit Command Block,
** TCB, or TxCB
*/
typedef struct __attribute__((packed)) {
  
  // Bytes are packed so this can't be a pointer
  cb_t hdr; 
  
  // Address of the Transmit Buffer Descriptor array
  // This driver uses simplified mode, so this should
  // always be 0xFFFFFFFF
  uint32_t tbd_addr;
  
  // Bit  15    = EOF - Indicates if the entire frame is in this TxCB
  // Bit  14    = 0
  // Bits 13:0  = TxCB byte count
  uint16_t byte_count;

  // Number of bytes that need to be in the Pro100's transmit FIFO
  // before beginning transmission of the frame
  uint8_t tx_threshold;

  // The number of transmit buffers in the TBD array.
  // Should always be 0 in simplified mode
  uint8_t tbd_number;

  // The packet
  uint8_t packet[ETH_FRAME_SIZE];

} tx_cb_t;

#endif
