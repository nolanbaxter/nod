// Bluetooth LE keyboard (NimBLE). Separate file: see usb_out.cpp.
#include <BleKeyboard.h>

#ifndef DEVICE_NAME
#define DEVICE_NAME "Nod"
#endif

static BleKeyboard kb(DEVICE_NAME, "DIY", 100);  // no battery sensing, so it always reports 100%

void bleBegin() { kb.begin(); }
bool bleUp() { return kb.isConnected(); }
void bleSend(uint8_t code) { kb.write(code); }
