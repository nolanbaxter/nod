// USB keyboard. Separate file because USBHIDKeyboard.h and BleKeyboard.h both define KeyReport/KEY_* and
// can't be included together.
#include <USB.h>
#include <USBHIDKeyboard.h>

static USBHIDKeyboard kb;
static volatile bool mounted = false, suspended = false;

// The XIAO has no VBUS sense pin, so "up" = a host enumerated us and the bus isn't suspended.
// Unplugging (on battery) or the PC sleeping both show up as suspend -> BLE takes over.
static void onUsb(void *, esp_event_base_t base, int32_t id, void *) {
  if (base != ARDUINO_USB_EVENTS) return;
  switch (id) {
    case ARDUINO_USB_STARTED_EVENT: mounted = true; suspended = false; break;
    case ARDUINO_USB_STOPPED_EVENT: mounted = false; break;
    case ARDUINO_USB_SUSPEND_EVENT: suspended = true; break;
    case ARDUINO_USB_RESUME_EVENT: suspended = false; break;
  }
}

void usbBegin() {
  USB.onEvent(onUsb);
  kb.begin();
  USB.begin();
}
bool usbUp() { return mounted && !suspended; }
void usbSend(const uint8_t *keys, int n) {  // pressed together, then released: one shortcut
  for (int i = 0; i < n; i++) kb.press(keys[i]);
  kb.releaseAll();
}
