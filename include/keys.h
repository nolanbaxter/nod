#pragma once
#include <stdint.h>

// Pure logic (no Arduino) so it runs in the native test.

constexpr uint32_t DEBOUNCE_MS = 10;          // tune if switches chatter
constexpr uint32_t IDLE_MS = 5 * 60 * 1000;   // on battery: deep sleep after this long without a press
constexpr uint32_t WAKE_SEND_MS = 5000;       // how long a wake press waits for BLE to reconnect

enum : uint8_t { K1 = 1, K2 = 2, K3 = 4 };

// Input: bitmask of keys physically down. Output: bitmask of keys newly pressed.
struct Keys {
  uint8_t raw = 0, down = 0;
  uint32_t rawAt = 0;

  // Keys already held at boot never send.
  void begin(uint8_t pressed, uint32_t now) { raw = down = pressed; rawAt = now; }

  uint8_t step(uint8_t pressed, uint32_t now) {
    if (pressed != raw) { raw = pressed; rawAt = now; }
    if (raw == down || now - rawAt < DEBOUNCE_MS) return 0;
    uint8_t pressedNow = raw & ~down;
    down = raw;
    return pressedNow;
  }
};

constexpr uint32_t CHORD_MS = 80;             // a press waits this long in case a second key joins it
constexpr uint32_t PAIR_HOLD_MS = 3000;       // NO + YES held this long = Bluetooth pairing
constexpr uint8_t PAIR = 0x80;                // bit in Chord::step's result

// Sits after Keys: input is Keys' newly-pressed bits and its debounced held mask. Holds each press for
// CHORD_MS, so two keys pressed together send nothing (pairing must never leak an Enter or a '2').
// Output: keys to send, plus PAIR once NO + YES have been held PAIR_HOLD_MS.
struct Chord {
  uint8_t wait = 0;
  uint32_t at = 0, chordAt = 0;
  bool chord = false, paired = false;

  uint8_t step(uint8_t pressed, uint8_t down, uint32_t now) {
    if (down & (down - 1)) {               // two or more held: a chord, never sends keys
      if (!chord) { chord = true; chordAt = now; wait = 0; }
      if (down == (K1 | K3) && !paired && now - chordAt >= PAIR_HOLD_MS) { paired = true; return PAIR; }
      return 0;
    }
    if (chord) {                           // stays a chord until every key is up
      if (!down) chord = paired = false;
      return 0;
    }
    if (pressed) { if (!wait) at = now; wait |= pressed; }
    if (wait && now - at >= CHORD_MS) { uint8_t k = wait; wait = 0; return k; }
    return 0;
  }
};

// The key that woke the board from deep sleep: sent once a link is up, dropped if that takes too long
// (a stale "Yes" arriving late is worse than none).
struct Pending {
  uint8_t keys = 0;
  uint32_t since = 0;

  void set(uint8_t k, uint32_t now) { keys = k; since = now; }

  uint8_t take(bool linked, uint32_t now) {
    if (!keys) return 0;
    if (now - since > WAKE_SEND_MS) { keys = 0; return 0; }
    if (!linked) return 0;
    uint8_t k = keys;
    keys = 0;
    return k;
  }
};

// Never sleep on USB (it's powered) or with a key held (it would wake instantly).
inline bool shouldSleep(uint32_t now, uint32_t lastActive, bool usbUp, uint8_t held) {
  return !usbUp && !held && now - lastActive >= IDLE_MS;
}
