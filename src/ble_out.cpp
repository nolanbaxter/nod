// Bluetooth LE keyboard (NimBLE). Separate file: see usb_out.cpp.
#include <BleKeyboard.h>
#include <NimBLEDevice.h>

#ifndef DEVICE_NAME
#define DEVICE_NAME "Nod"
#endif

static BleKeyboard kb(DEVICE_NAME, "DIY", 100);  // no battery sensing, so it always reports 100%

void bleBegin() { kb.begin(); }
bool bleUp() { return kb.isConnected(); }
void bleSend(const uint8_t *keys, int n) {
  for (int i = 0; i < n; i++) kb.press(keys[i]);
  kb.releaseAll();
}

// Forget every paired computer and drop the current one, so a new computer can pair.
// Advertising restarts by itself on disconnect (BleKeyboard::onDisconnect).
void blePair() {
  NimBLEDevice::deleteAllBonds();  // first, so the old computer's quick reconnect fails
  NimBLEServer* s = NimBLEDevice::getServer();
  for (uint16_t id : s->getPeerDevices()) s->disconnect(id);
}
