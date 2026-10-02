# Changelog

All notable changes to this project are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioning: [SemVer](https://semver.org/).

## [Unreleased]

### Added
- Firmware for the Seeed XIAO ESP32-S3: three keys with two keymaps, switched by holding NO + ALWAYS: the Claude desktop app's prompt shortcuts (Esc / Ctrl+Shift+Enter / Ctrl+Enter) and the terminal's (Esc / 2 / 1), USB keyboard when a computer is
  attached, Bluetooth LE keyboard otherwise, deep sleep after 2 minutes idle on battery, wake key
  delivered once Bluetooth reconnects. Unit tests for the key, wake, and sleep logic.
- Parametric OpenSCAD case with a key well, separate switch plate, magnet-held lid, side USB-C
  port, power switch (SS12D00-G3, in a finger pocket), and LED holes beside the port; bevelled and square STLs; a collision check against
  stand-ins for every bought part.
- LED flashes on every key press; hold NO + YES for 3 s to forget paired computers and pair a new
  one (keys pressed together never send); optional low-battery blink with a two-resistor divider.
- Wiring diagram.
- Clawd variant (`cad/clawd/`, CC BY-NC 4.0): the same case internals in a body shaped like the
  Claude Code mascot, with the port cluster on the back wall. Unofficial fan work.
- `make_banner.ps1 -Target nod|clawd` renders the README images from the model.
