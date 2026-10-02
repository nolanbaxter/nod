#include <Arduino.h>
#include <driver/rtc_io.h>
#include <esp_sleep.h>
#include <Preferences.h>
#include "keys.h"

// usb_out.cpp / ble_out.cpp
void usbBegin(); bool usbUp(); void usbSend(const uint8_t *keys, int n);
void bleBegin(); bool bleUp(); void bleSend(const uint8_t *keys, int n); void blePair();

// Switch leg -> GPIO, other leg -> GND. All RTC-capable so any key wakes from deep sleep; D2 (GPIO3, strapping) skipped.
// Power is a slide switch in the battery lead.
constexpr uint8_t PIN[3] = {1, 2, 4};              // D0, D1, D3
// Left to right: No, Always, Yes. Each row is pressed together; 0 = unused. Key codes are the same in both
// keyboard libraries: 0x80 Ctrl, 0x81 Shift, 0xB0 Enter, 0xB1 Esc. Hold NO + ALWAYS 3 s to switch keymaps.
constexpr uint8_t CODE[2][3][3] = {
  // 0, desktop app: the shortcuts shown on its prompt buttons (its number keys are positional, so not used)
  {{0xB1}, {0x80, 0x81, 0xB0}, {0x80, 0xB0}},
  // 1, terminal CLI: options are 1 Yes, 2 don't-ask-again, 3 No; Yes/No prompts have only 1 and 2,
  // so No is Esc (works on both) and '2' on a Yes/No prompt errs safe (No)
  {{0xB1}, {'2'}, {'1'}},
};
constexpr int LED = 21;                            // XIAO user LED, active low
// Battery sense: the XIAO can't read its battery by itself. Fit two equal resistors (100k-220k):
// BAT+ -> R -> D4 -> R -> GND, then set this to 5 (D4 = GPIO5). -1 = not fitted, no low-battery warning.
constexpr int BAT_PIN = -1;
constexpr uint32_t BAT_LOW_MV = 3500;              // roughly the last 10-15% of a LiPo
constexpr uint32_t PAIR_MAX_MS = 120000;           // pairing blink gives up after this

Keys keys;
Chord chord;
Pending pending;
uint32_t lastActive, flashAt, pairAt, batAt, mapAt;
uint8_t keymap;                                    // index into CODE, saved in flash
Preferences prefs;
uint8_t pairing;                                   // 0 off, 1 waiting for the old link to drop, 2 waiting for a new one
bool batLow;

bool readBatLow() {
  if (BAT_PIN < 0) return false;
  uint32_t mv = 0;
  for (int i = 0; i < 16; i++) mv += analogReadMilliVolts(BAT_PIN);
  return mv / 16 * 2 < BAT_LOW_MV;
}

uint8_t readKeys() {
  uint8_t m = 0;
  for (int i = 0; i < 3; i++) if (!digitalRead(PIN[i])) m |= 1 << i;
  return m;
}

// USB when a computer is on the cable, otherwise Bluetooth. Dropped if neither is connected.
void send(const uint8_t *code) {
  int n = 0;
  while (n < 3 && code[n]) n++;
  if (usbUp()) usbSend(code, n);
  else if (bleUp()) bleSend(code, n);
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

  prefs.begin("nod");
  keymap = prefs.getUChar("keymap", 0) % 2;
  usbBegin();
  bleBegin();
  keys.begin(readKeys(), millis());  // the wake key is still held; Pending sends it, not Keys
  lastActive = millis();
}

void loop() {
  uint32_t now = millis();
  uint8_t held = readKeys();
  bool usb = usbUp(), ble = bleUp(), linked = usb || ble;

  uint8_t ev = chord.step(keys.step(held, now), keys.down, now);
  if (chord.chord) pending.keys = 0;                 // woke by a pairing hold: don't send the wake key
  ev |= pending.take(linked, now);
  for (int i = 0; i < 3; i++) if (ev & (1 << i)) { send(CODE[keymap][i]); flashAt = now; }
  if (ev & PAIR) { blePair(); pairing = 1; pairAt = now; }
  if (ev & MODE) { keymap ^= 1; prefs.putUChar("keymap", keymap); mapAt = now; }
  if (ev || held || usb) lastActive = now;

  if (pairing == 1 && !ble) pairing = 2;
  if ((pairing == 2 && ble) || now - pairAt > PAIR_MAX_MS) pairing = 0;
  if (now - batAt >= 10000) { batAt = now; batLow = readBatLow(); }

  bool on;
  if (pairing) on = now % 200 < 100;                 // fast blink: pairing
  else if (mapAt && now - mapAt < 1000)              // keymap switched: 1 long blink = desktop, 2 = terminal
    on = (now - mapAt) % 500 < 250 && (now - mapAt) / 500 <= keymap;
  else if (now - flashAt < 60) on = true;            // a key was just sent
  else if (!linked) on = now % 1000 < 30;            // short blink every second: waiting for a connection
  else on = batLow && now % 4000 < 30;               // short blink every 4 s: battery low
  digitalWrite(LED, !on);
  if (shouldSleep(now, lastActive, usb, held)) sleepNow();
  delay(2);
}
