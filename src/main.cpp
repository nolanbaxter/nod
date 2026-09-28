#include <Arduino.h>
#include <driver/rtc_io.h>
#include <esp_sleep.h>
#include "keys.h"

// usb_out.cpp / ble_out.cpp
void usbBegin(); bool usbUp(); void usbSend(uint8_t code);
void bleBegin(); bool bleUp(); void bleSend(uint8_t code);

// Switch leg -> GPIO, other leg -> GND. All RTC-capable so any key wakes from deep sleep; D2 (GPIO3, strapping) skipped.
// Power is a slide switch in the battery lead.
constexpr uint8_t PIN[3] = {1, 2, 4};              // D0, D1, D3
constexpr uint8_t CODE[3] = {0xB1, '2', '1'};      // left to right: No (Esc), Always, Yes -- matches the desktop app
constexpr int LED = 21;                            // XIAO user LED, active low

Keys keys;
Pending pending;
uint32_t lastActive;

uint8_t readKeys() {
  uint8_t m = 0;
  for (int i = 0; i < 3; i++) if (!digitalRead(PIN[i])) m |= 1 << i;
  return m;
}

// USB when a computer is on the cable, otherwise Bluetooth. Dropped if neither is connected.
void send(uint8_t code) {
  if (usbUp()) usbSend(code);
  else if (bleUp()) bleSend(code);
}

void sleepNow() {
  digitalWrite(LED, HIGH);
  uint64_t mask = 0;
  for (auto p : PIN) {
    rtc_gpio_pullup_en((gpio_num_t)p);
    rtc_gpio_pulldown_dis((gpio_num_t)p);
    mask |= 1ULL << p;
  }
  esp_sleep_pd_config(ESP_PD_DOMAIN_RTC_PERIPH, ESP_PD_OPTION_ON);  // keep the pull-ups alive
  esp_sleep_enable_ext1_wakeup(mask, ESP_EXT1_WAKEUP_ANY_LOW);
  esp_deep_sleep_start();  // wakes as a fresh boot
}

void setup() {
  // ponytail: 80 MHz is plenty and saves power; if USB ever misbehaves, delete this line first
  setCpuFrequencyMhz(80);
  for (auto p : PIN) { rtc_gpio_deinit((gpio_num_t)p); pinMode(p, INPUT_PULLUP); }  // undo sleep's RTC mux
  pinMode(LED, OUTPUT);
  digitalWrite(LED, HIGH);

  if (esp_sleep_get_wakeup_cause() == ESP_SLEEP_WAKEUP_EXT1) {
    uint64_t st = esp_sleep_get_ext1_wakeup_status();
    uint8_t k = 0;
    for (int i = 0; i < 3; i++) if (st & (1ULL << PIN[i])) k |= 1 << i;
    pending.set(k, millis());
  }

  usbBegin();
  bleBegin();
  keys.begin(readKeys(), millis());  // the wake key is still held; Pending sends it, not Keys
  lastActive = millis();
}

void loop() {
  uint32_t now = millis();
  uint8_t held = readKeys();
  bool usb = usbUp(), linked = usb || bleUp();

  uint8_t ev = keys.step(held, now) | pending.take(linked, now);
  for (int i = 0; i < 3; i++) if (ev & (1 << i)) send(CODE[i]);
  if (ev || usb) lastActive = now;

  digitalWrite(LED, linked || now % 1000 >= 30);  // short blink every second = waiting for a connection
  if (shouldSleep(now, lastActive, usb, held)) sleepNow();
  delay(2);
}
