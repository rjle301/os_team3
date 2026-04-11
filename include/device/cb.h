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
** Command block for configuring Pro100 parameters
*/
typedef struct __attribute__((packed)) {
  
  // Bytes are packed so this can't be a pointer
  cb_t hdr;
  uint8_t config[N_CONFIG_BYTES];

} cb_config_t;

#endif
