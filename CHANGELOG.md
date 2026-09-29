# Changelog

All notable changes to this project are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioning: [SemVer](https://semver.org/).

## [Unreleased]

### Added
- Firmware for the Seeed XIAO ESP32-S3: three keys (Esc / 2 / Enter, working in both the terminal and the desktop app), USB keyboard when a computer is
  attached, Bluetooth LE keyboard otherwise, deep sleep after 5 minutes idle on battery, wake key
  delivered once Bluetooth reconnects. Unit tests for the key, wake, and sleep logic.
- Parametric OpenSCAD case with a key well, separate switch plate, magnet-held lid, side USB-C
  port, power switch, and LED window; bevelled and square STLs; a collision check against
  stand-ins for every bought part.
- Wiring diagram.
- Clawd variant (`cad/clawd/`, CC BY-NC 4.0): the same case internals in a body shaped like the
  Claude Code mascot, with the port cluster on the back wall. Unofficial fan work.
- `make_banner.ps1 -Target nod|clawd` renders the README images from the model.
