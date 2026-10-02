#include <initializer_list>
#include <unity.h>
#include "keys.h"

static Keys k;
static uint32_t t;

// Hold `mask` for `ms` milliseconds, 1 ms per step; OR of all events.
static uint8_t hold(uint8_t mask, uint32_t ms) {
  uint8_t out = 0;
  for (uint32_t end = t + ms; t < end; t++) out |= k.step(mask, t);
  return out;
}

void setUp() { k = Keys(); t = 1000; k.begin(0, t); }
void tearDown() {}

void each_key_sends_once_on_press() {
  for (uint8_t key : {K1, K2, K3}) {
    TEST_ASSERT_EQUAL(key, hold(key, 50));
    TEST_ASSERT_EQUAL(0, hold(key, 500));  // holding doesn't repeat
    TEST_ASSERT_EQUAL(0, hold(0, 50));     // release sends nothing
  }
}

void second_key_while_first_held_sends() {
  TEST_ASSERT_EQUAL(K1, hold(K1, 50));
  TEST_ASSERT_EQUAL(K3, hold(K1 | K3, 50));
}

void bounce_is_ignored() {
  uint8_t out = 0;
  for (int i = 0; i < 6; i++) out |= hold(i % 2 ? K2 : 0, 3);
  TEST_ASSERT_EQUAL(0, out);
}

void keys_held_at_boot_do_not_send() {
  k = Keys(); k.begin(K1 | K3, t);
  TEST_ASSERT_EQUAL(0, hold(K1 | K3, 100));
  TEST_ASSERT_EQUAL(0, hold(0, 50));
  TEST_ASSERT_EQUAL(K1, hold(K1, 50));  // works normally afterwards
}

void wake_key_waits_for_link_then_sends_once() {
  Pending p;
  p.set(K3, 0);
  TEST_ASSERT_EQUAL(0, p.take(false, 1000));   // BLE still reconnecting
  TEST_ASSERT_EQUAL(K3, p.take(true, 2500));   // connected: send it
  TEST_ASSERT_EQUAL(0, p.take(true, 2600));    // only once
}

void wake_key_dropped_if_link_too_slow() {
  Pending p;
  p.set(K1, 0);
  TEST_ASSERT_EQUAL(0, p.take(false, WAKE_SEND_MS));
  TEST_ASSERT_EQUAL(0, p.take(true, WAKE_SEND_MS + 1));  // too late: stale approvals are worse than none
  TEST_ASSERT_EQUAL(0, p.take(true, WAKE_SEND_MS + 2));
}

void sleeps_only_when_idle_on_battery_with_no_key_held() {
  TEST_ASSERT_FALSE(shouldSleep(IDLE_MS - 1, 0, false, 0));
  TEST_ASSERT_TRUE(shouldSleep(IDLE_MS, 0, false, 0));
  TEST_ASSERT_FALSE(shouldSleep(IDLE_MS, 0, true, 0));   // on USB
  TEST_ASSERT_FALSE(shouldSleep(IDLE_MS, 0, false, K2)); // key held would wake it instantly
  TEST_ASSERT_TRUE(shouldSleep(5 + IDLE_MS, 5, false, 0));
  TEST_ASSERT_TRUE(shouldSleep(IDLE_MS - 10, 0xFFFFFFF6u, false, 0));  // millis() wraparound
}

// Keys + Chord together, as main.cpp runs them.
static Chord c;
static uint8_t press(uint8_t mask, uint32_t ms) {
  uint8_t out = 0;
  for (uint32_t end = t + ms; t < end; t++) out |= c.step(k.step(mask, t), k.down, t);
  return out;
}

void tap_sends_after_chord_window() {
  c = Chord();
  TEST_ASSERT_EQUAL(0, press(K2, CHORD_MS - 5));
  TEST_ASSERT_EQUAL(K2, press(K2, 50));
  TEST_ASSERT_EQUAL(K3, press(K3, 30) | press(0, 200));  // released before the window ends: still sent
}

void two_keys_together_send_nothing() {
  c = Chord();
  TEST_ASSERT_EQUAL(0, press(K3, 30));
  TEST_ASSERT_EQUAL(0, press(K1 | K3, 1000));  // Enter pressed first, but never leaks
  TEST_ASSERT_EQUAL(0, press(K1, 200) | press(0, 200));
  TEST_ASSERT_EQUAL(K2, press(K2, 200));       // normal afterwards
}

void no_yes_held_three_seconds_pairs_once() {
  c = Chord();
  TEST_ASSERT_EQUAL(0, press(K1 | K3, HOLD_MS - 50));
  TEST_ASSERT_EQUAL(PAIR, press(K1 | K3, 2000));  // once, however long it's held
  TEST_ASSERT_EQUAL(0, press(0, 100));
  TEST_ASSERT_EQUAL(MODE, press(K1 | K2, 5000));  // NO + ALWAYS: keymap toggle instead
  TEST_ASSERT_EQUAL(0, press(0, 100) | press(K2 | K3, 5000));  // ALWAYS + YES: nothing
}

int main() {
  UNITY_BEGIN();
  RUN_TEST(tap_sends_after_chord_window);
  RUN_TEST(two_keys_together_send_nothing);
  RUN_TEST(no_yes_held_three_seconds_pairs_once);
  RUN_TEST(wake_key_waits_for_link_then_sends_once);
  RUN_TEST(wake_key_dropped_if_link_too_slow);
  RUN_TEST(sleeps_only_when_idle_on_battery_with_no_key_held);
  RUN_TEST(each_key_sends_once_on_press);
  RUN_TEST(second_key_while_first_held_sends);
  RUN_TEST(bounce_is_ignored);
  RUN_TEST(keys_held_at_boot_do_not_send);
  return UNITY_END();
}
