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
  cb_t hdr;                       // Shared header information across command blocks
  uint8_t config[N_CONFIG_BYTES]; // Contiguous 22-byte configuration map
} cb_config_t;

/*
** Command block for an Individual Address Setup command
** Sets the Pro100's MAC address
*/
typedef struct __attribute__((packed)) { 
  cb_t hdr;       // Shared header information across command blocks 
  uint8_t mac[6]; // MAC addresses
} cb_ias_t;

/*
** Command block for packet transmission.
** Referred to in the datasheet as a Transmit Command Block,
** TCB, or TxCB
*/
typedef struct __attribute__((packed)) { 
  cb_t hdr;                       // Shared header information across command blocks 
  uint32_t tbd_addr;              // Address of the Transmit Buffer Descriptor array 
  uint16_t byte_count;            // Number of bytes in the payload
  uint8_t tx_threshold;           // Bytes needed in transmit FIFO to begin transmission
  uint8_t tbd_number;             // Number of transmit buffers in TBD array
  uint8_t packet[ETH_FRAME_SIZE]; // The payload
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
  cb_t hdr;                   // Shared header information across command blocks 
  uint32_t reserved; 
  uint16_t actual_count;      // Number of bytes received. Set by hardware
  uint16_t size;              // Size of the data buffer. Set by software
  uint8_t data[PAYLOAD_SIZE]; // The sequential data buffer of this RFD 
} rfd_t;

#endif
