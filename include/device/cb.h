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

#endif
