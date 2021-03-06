/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * @author Jonathan Hui <jhui@archrock.com>
 * @author David Moss
 * @author Chad Metcalf
 */

#include "IEEE802154.h"
#include "message.h"
#include "CC2420.h"
#include "CC2420TimeSyncMessage.h"

module CC2420PacketP {

  provides {
    interface CC2420Packet;
    interface CC2420PacketBody;
    interface LinkPacketMetadata;
  }

}

implementation {

  /***************** CC2420Packet Commands ****************/
   int getAddressLength(int type) {
    switch (type) {
    case IEEE154_ADDR_SHORT: return 2;
    case IEEE154_ADDR_EXT: return 8;
    case IEEE154_ADDR_NONE: return 0;
    default: return -100;
    }
  }

  uint8_t * ONE getNetwork(message_t * ONE msg) {
    tossim_header_t *hdr = (tossim_header_t *)(call CC2420PacketBody.getHeader( msg ));
    int offset;
    
    offset = getAddressLength((hdr->fcf >> IEEE154_FCF_DEST_ADDR_MODE) & 0x3) +
      getAddressLength((hdr->fcf >> IEEE154_FCF_SRC_ADDR_MODE) & 0x3) + 
      offsetof(tossim_header_t, network);

    return ((uint8_t *)hdr) + offset;
  }

  async command uint8_t CC2420Packet.getNetwork( message_t* ONE p_msg ) {
#if defined(TFRAMES_ENABLED)
    return TINYOS_6LOWPAN_NETWORK_ID;
#else
    atomic 
      return *(getNetwork(p_msg));
#endif
  }

  async command void CC2420Packet.setNetwork( message_t* ONE p_msg , uint8_t networkId ) {
#if ! defined(TFRAMES_ENABLED)
    atomic 
      *(getNetwork(p_msg)) = networkId;
#endif
  }    



  async command void CC2420Packet.setPower( message_t* p_msg, uint8_t power ) { }

  async command uint8_t CC2420Packet.getPower( message_t* p_msg ) {
    return 31;
  }
   
  async command int8_t CC2420Packet.getRssi( message_t* p_msg ) {
    // The CC2420's RSSI has an offset of 45dBm. Reference: section 23
    // from the CC2420 Datasheet. 
    return (call CC2420PacketBody.getMetadata(p_msg))->strength + 45;
  }

  async command uint8_t CC2420Packet.getLqi( message_t* p_msg ) {
    return (call CC2420PacketBody.getMetadata(p_msg))->strength;
  }

  /***************** CC2420PacketBody Commands ****************/
  async command tossim_header_t *CC2420PacketBody.getHeader( message_t* msg ) {
    return (tossim_header_t *)msg->header;
  }

  async command tossim_metadata_t *CC2420PacketBody.getMetadata( message_t* msg ) {
    dbg("CC2420PacketP", "CC2420PacketP getMetadata\n");
    return (tossim_metadata_t *)msg->metadata;
  }


async command bool LinkPacketMetadata.highChannelQuality(message_t* msg) {
  return call CC2420Packet.getLqi(msg) > 105;
}

}
