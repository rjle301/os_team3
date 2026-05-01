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
#define ETH_FRAME_HDR   14    // 14-byte MAC Address + Type prefix 
#define ETH_FRAME_CRC   4     // 4-byte postfix checksum
#define PAYLOAD_SIZE    1500  // maximum of 1500-byte payload
#define ETH_FRAME_SIZE  ETH_FRAME_HDR + PAYLOAD_SIZE + ETH_FRAME_CRC

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
  
  // Shared header information across command blocks
  cb_t hdr;

  // Contiguous 22-byte configuration map
  uint8_t config[N_CONFIG_BYTES];

} cb_config_t;

/*
** Command block for an Individual Address Setup command
** Sets the Pro100's MAC address
*/
typedef struct __attribute__((packed)) {
  
  // Shared header information across command blocks
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
  
  // Shared header information across command blocks
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

/*
** A recieve frame descriptor. Contains the standard command block
** header information (status, command, link), as well as information
** about the recieved frame and the payload.
**
** Page 108 of the Intel8255x datasheet has useful diagrams
** 
*/
typedef struct __attribute__((packed)) {
  
  // Shared header information across command blocks
  cb_t hdr;
  
  // The Dword immediately after the common command block header
  // is reserved in RFDs. Still need this here because command
  // block structs are packed.
  uint32_t reserved;
  
  // Bit  15   = EOF - Set by the device when payload has been copied to memory
  // Bit  14   = F - Set by the device when the actual count field is updated
  // Bits 13:0 = Actual count - The number of bytes copied to memory
  uint16_t actual_count;
  
  // Bit  15 = 0
  // Bit  14 = 0
  // Bits 13:0 = Size of the data buffer
  uint16_t size;
  
  // The sequential data buffer of this RFD
  uint8_t data[PAYLOAD_SIZE];
  
} rfd_t;

#endif
