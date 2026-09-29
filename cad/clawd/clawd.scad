// Clawd style of the Nod case: the pixel mascot, with the keys on its head.
// Unofficial, noncommercial fan work, licensed CC BY-NC 4.0 (see LICENSE in this folder).
// Everything inside (XIAO pocket, magnets, key well, keycaps) comes from ../case.scad;
// this file only changes the shape and moves the port cluster to the back wall.
include <../case.scad>

/* [Clawd] */
px_w = 5;             // one pixel of the sprite; 13 px wide = the Nod width
px_h = 10.5;          // px_w * 2.1: terminal half-block aspect
eye_d = 1.2;          // eye recess depth (fill with eyes.stl in black)
depth = 36;
H = 42;               // 4 px_h tall (+ 1 px_h of legs under the lid)
port_side = "back";
sw_lx = 16.1;         // power switch beside the port, sitting on the lid
sw_z = lid_t + tol + sw_w/2;
rib_z0 = lid_t;
lid_lift = 10.5;      // legs hang below the lid
logo = "";
sink = max(2*chamfer, 0.5);   // arms/legs overlap the body so their bevels are buried

module eyes() for (c = [2, 10]) box([-W/2 + c*px_w, -0.01, 2*px_h], [px_w, eye_d + 0.01, px_h]);
module body_add() for (s = [-1, 1]) cbox([s > 0 ? W/2 - sink : -W/2 - 2*px_w, 0, px_h], [2*px_w + sink, depth, px_h]);
// "Nod" engraved on the back wall above the power switch (above the port is the thin LED window).
// rotate: text stands up on the back face and reads correctly from behind; it cuts label_depth in.
module back_logo() translate([sw_lx, depth - label_depth, sw_z + 5]) rotate([90, 0, 180])
  linear_extrude(label_depth + 0.01) text("Nod", size = logo_size, halign = "center", valign = "center", font = label_font);
module body_cut() { eyes(); back_logo(); }
module lid_add() for (c = [2, 4, 8, 10]) cbox([-W/2 + c*px_w, 0, -px_h], [px_w, depth, px_h + sink], bot = false);
module preview_add() color("black") eyes();

if (part == "eyes") flip(H) eyes();

// colour groups for the README render (docs/banner/make_banner.ps1 -Target clawd)
if (part == "img_body") { body(); lid(); }
if (part == "img_eyes") eyes();
if (part == "img_accent") { keycaps_placed(); slide_dummy(); xiao_dummy(); }
