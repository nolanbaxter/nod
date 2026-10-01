// Bluetooth LE keyboard (NimBLE). Separate file: see usb_out.cpp.
#include <BleKeyboard.h>
#include <NimBLEDevice.h>

#ifndef DEVICE_NAME
#define DEVICE_NAME "Nod"
#endif

static BleKeyboard kb(DEVICE_NAME, "DIY", 100);  // no battery sensing, so it always reports 100%

void bleBegin() { kb.begin(); }
bool bleUp() { return kb.isConnected(); }
void bleSend(uint8_t code) { kb.write(code); }

// Forget every paired computer and drop the current one, so a new computer can pair.
// Advertising restarts by itself on disconnect (BleKeyboard::onDisconnect).
void blePair() {
  NimBLEDevice::deleteAllBonds();  // first, so the old computer's quick reconnect fails
  NimBLEServer* s = NimBLEDevice::getServer();
  for (uint16_t id : s->getPeerDevices()) s->disconnect(id);
}
