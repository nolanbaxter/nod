// Nod case: a three-key box. Units mm.
// Coordinates: x centered, y=0 front face, y=depth back face, z=0 bottom of lid.
// Every "measure" value is a nominal guess until the real part is in hand.

part = "all"; // [all, body, lid, plate, keycaps, labels]

/* [Shape] */
W = 65;               // width; must fit 3 keys at 19.05 mm pitch
depth = 42;           // deep enough for the side USB port to fit between the corner magnets
H = 52;
wall = 2.4;
plate = 1.5;          // MX plate-mount thickness
lid_t = 2;
chamfer = 1;          // 45° bevel on outside edges; 0 = square; keep <= lid_t/2

/* [Switches] */
pitch = 19.05;
sw_hole = 14.0;       // tune +0.1 if switches won't clip in
cap_proud = 3;        // how far keycap tops stick out above the top face
well_gap = 1;         // gap around each keycap inside the key well
ledge = 1.5;          // lip the separate plate rests on
rim = 2;              // thickness of that lip

/* [XIAO ESP32-S3] measure */
xiao_l = 21;          // USB end against the right wall
xiao_w = 17.8;
pcb_t = 1.0;
xiao_lift = 2;        // clearance under board for battery-pad wires
usb_w = 8.94;         // receptacle
usb_h = 3.26;
usb_over = 1.0;       // how far the receptacle sticks past the PCB edge
usb_zc = 2.6;         // receptacle center above PCB bottom
plug_w = 12.5;        // cable overmold
plug_h = 7;

/* [Battery] 502030 LiPo, listed 20.5 x 32 x 5.3 */
bat_l = 32;
bat_t = 5.3;
bat_slack = 1;        // LiPos swell

/* [Power switch] SS12D00-G3 mini slide switch (3 mm slider), measure */
sw_l = 8.6;           // body length (slide direction)
sw_w = 3.6;
sw_h = 3.5;
knob_l = 2.0;         // slider cross-section
knob_w = 1.5;
knob_travel = 2.0;
knob_h = 3;           // slider length past the switch face: G3 = 3 mm
sw_pocket = [10, 7];  // finger pocket around the slot on the outside (along the wall, height)
sw_pocket_wall = 1.0; // wall left at the pocket floor, so the 3 mm slider stands 2 mm proud

/* [Magnets] 6 x 2 mm discs */
mag_d = 6;            // diameter
mag_h = 2;            // thickness
mag_fit = 0.2;        // pocket clearance on diameter; glue them in
lip_h = 2;            // lid lip inside the walls: magnets hold vertically, the lip stops sliding

/* [Antenna] 2.4 GHz FPC, U.FL/IPEX-1, 50 x 14 */
ant_l = 50;
ant_w = 14;
ant_z = 12.2;         // bottom edge height on the back wall

/* [Keycaps] */
cap = 18;
cap_wall = 1.2;
cap_top = 2.4;
cap_skirt = 5.6;      // skirt bottom to socket bottom
cap_rest = 6.0;       // skirt bottom height above the plate at rest (MX stem top is 11.6 above plate)
stem_d = 5.5;
cross_l = 4.2;        // tune for stem fit
cross_w = 1.35;
cross_depth = 4;
labels = ["NO", "ALWAYS", "YES"];   // left to right, matches src/main.cpp CODE[]
label_size = [5, 3.1, 5];
label_font = "Cascadia Code:style=Bold";   // free, github.com/microsoft/cascadia-code; OpenSCAD silently falls back if missing
label_depth = 1.0;   // engraving depth for key labels and the logo

/* [Logo] engraved on the top face, behind the keys */
logo = "Nod";
logo_size = 3.5;
logo_side = "left";   // [left, right]

/* [Fit] */
tol = 0.2;

$fn = 48;
cap_h = cap_skirt + cap_top;
port_z = lid_t + xiao_lift + usb_zc;          // USB center height
cav = [W - 2*wall, depth - 2*wall];           // interior footprint
mag_pd = mag_d + mag_fit;                     // pocket diameter
boss_d = mag_pd + 2.4;
mag_off = mag_pd/2 + tol + 0.4;               // magnet center from inner wall faces
mag_z = max(lid_t, mag_h + 0.6);              // where magnet faces meet
boss_top = mag_z + mag_h + 0.6 + boss_d/2;    // tip of the 45° cone above each body boss
mag_xy = [for (sx = [-1, 1], y = [wall + mag_off, depth - wall - mag_off])
          [sx * (W/2 - wall - mag_off), y]];
led_z0 = port_z + plug_h/2 + 0.5;             // LED window starts above the plug recess, never through it
led_top = led_z0 + 1.5;
well = [2*pitch + cap + 2*well_gap, cap + 2*well_gap];   // key well footprint, centered on the top
plate_top = H - (cap_rest + cap_h - cap_proud);          // switch plate sits at the bottom of the well
ceil_z = plate_top - plate - rim;                        // underside of the solid top block

// Port cluster (USB, LED window, power switch, XIAO pocket), modelled in a local frame:
// x along the wall, y = 0 at its outer face and negative going inside.
// Nod: right side wall, switch above the port (that wall is too short for both side by side).
xl0 = -wall - xiao_l;                          // PCB inner edge; the USB edge butts the wall
port_side = "right";                           // right | back
sw_lx = 0;                                     // power switch position along the port wall
sw_z = led_top + 2 + sw_w/2;
rib_z0 = sw_z - sw_w/2 - 1;                    // bottom of the switch guide ribs
module at_port() {
  if (port_side == "back") translate([0, depth, 0]) children();
  else translate([W/2, depth/2, 0]) rotate(-90) children();
}

// Hooks for variants built on this file (see cad/clawd/clawd.scad); empty for Nod.
lid_lift = 0;                                  // raise the exported lid (e.g. for legs)
module body_add() {}
module body_cut() {}
module lid_add() {}
module preview_add() {}

assert(port_z - plug_h/2 > lid_t, "cable overmold would hit the lid; raise xiao_lift");
assert(ant_z > led_top && ant_z + ant_w + 1 < ceil_z, "antenna overlaps LED window or the top block; move ant_z");
assert(well.x + 2 < W, "key well too wide for the body");
assert(ant_l + 1 < cav.x && (ant_z > boss_top || ant_l/2 + 0.5 < cav.x/2 - mag_off - boss_d/2),
       "antenna runs into a corner magnet boss");
assert(2*chamfer <= lid_t && 2*chamfer <= wall, "chamfer too big for lid/wall");

module box(p, s) translate(p) cube(s);

// box with 45° chamfers on all edges; bot/top=false leaves that face's edges square
module cbox(p, s, bot = true, top = true, c = chamfer) {
  lo = bot ? 0 : c;
  h = s.z + lo + (top ? 0 : c);
  intersection() {
    box(p, s);
    translate(p - [0, 0, lo]) hull() {
      translate([c, c, 0]) cube([s.x - 2*c, s.y - 2*c, h]);
      translate([c, 0, c]) cube([s.x - 2*c, s.y, h - 2*c]);
      translate([0, c, c]) cube([s.x, s.y - 2*c, h - 2*c]);
    }
  }
}

// logo sits in the strip between the key well and the back edge, flush with the well's left or right edge
module logo_shape() {
  right = logo_side == "right";
  translate([right ? well.x/2 : -well.x/2, depth - (depth/2 - well.y/2)/2, H - label_depth])
    linear_extrude(label_depth + 0.01)
      text(logo, size = logo_size, halign = right ? "right" : "left", valign = "center", font = label_font);
}

module body() difference() {
  union() {
    difference() {
      cbox([-W/2, 0, lid_t], [W, depth, H - lid_t], bot = false);
      box([-W/2 + wall, wall, lid_t - 1], [W - 2*wall, depth - 2*wall, ceil_z - lid_t + 1]);
    }
    // power switch guide ribs either side of the switch body (glue it in between)
    at_port() for (s = [-1, 1]) box([sw_lx + s*(sw_l/2 + tol) - (s < 0 ? 1.2 : 0), -wall - sw_h, rib_z0],
                                    [1.2, sw_h + 0.01, sw_z + sw_w/2 + 1.5 - rib_z0]);
    body_add();
    // corner magnet bosses fused to the walls; 45° cone on top so they print plate-down
    for (p = mag_xy) translate([p.x, p.y, mag_z]) {
      cylinder(d = boss_d, h = mag_h + 0.6);
      translate([0, 0, mag_h + 0.6]) cylinder(d1 = boss_d, d2 = 0, h = boss_d/2);
    }
  }
  // key well: keycaps sit in it; the separate plate drops in and rests on a ledge
  box([-well.x/2, depth/2 - well.y/2, plate_top - plate], [well.x, well.y, H]);
  box([-well.x/2 + ledge, depth/2 - well.y/2 + ledge, ceil_z - 1], [well.x - 2*ledge, well.y - 2*ledge, rim + 1.01]);
  logo_shape();
  body_cut();
  for (p = mag_xy) translate([p.x, p.y, mag_z - 1]) cylinder(d = mag_pd, h = mag_h + 1);
  // antenna sticker: 0.4 mm locating recess on the inside of the back wall
  box([-ant_l/2 - 0.5, depth - wall - 0.01, ant_z], [ant_l + 1, 0.41, ant_w + 1]);
  at_port() {
    // USB: notch open at the bottom so the board slides in with the lid; lid tab fills under it
    box([-usb_w/2 - tol, -wall - 1, lid_t - 1], [usb_w + 2*tol, wall + 2, port_z + usb_h/2 + tol - lid_t + 1]);
    box([-plug_w/2, -wall + usb_over, port_z - plug_h/2], [plug_w, wall, plug_h]);
    // power switch slider slot
    box([sw_lx - (knob_l + knob_travel)/2 - tol, -wall - 1, sw_z - knob_w/2 - tol],
        [knob_l + knob_travel + 2*tol, wall + 2, knob_w + 2*tol]);
    box([sw_lx - sw_pocket.x/2, -wall + sw_pocket_wall, sw_z - sw_pocket.y/2], [sw_pocket.x, wall, sw_pocket.y]);
    // LED window: wall thinned to 0.6 just above the plug recess
    box([-6, -wall - 0.01, led_z0], [12, wall - 0.6, led_top - led_z0]);
  }
}

// switch plate: separate flat part so it prints perfectly flat; glue it onto the ledge
module plate() difference() {
  box([-well.x/2 + tol, depth/2 - well.y/2 + tol, plate_top - plate], [well.x - 2*tol, well.y - 2*tol, plate]);
  for (i = [-1:1]) box([i*pitch - sw_hole/2, depth/2 - sw_hole/2, plate_top - plate - 1], [sw_hole, sw_hole, plate + 2]);
}

module lid() difference() {
  union() {
    cbox([-W/2, 0, 0], [W, depth, lid_t], top = false);
    lid_add();
    at_port() {
      // tab filling the USB notch under the receptacle
      box([-usb_w/2, -wall, lid_t - 0.01], [usb_w, wall, port_z - usb_h/2 - tol - lid_t]);
      // XIAO pocket: side rails, two ledges, inner stop (takes plug-in force)
      rail_h = xiao_lift + pcb_t + 1.5;
      for (s = [-1, 1]) box([s > 0 ? xiao_w/2 + tol : -xiao_w/2 - tol - 1.2, xl0 - 1.5, lid_t - 0.01],
                            [1.2, -wall - tol - xl0 + 1.5, rail_h]);
      box([-xiao_w/2, xl0, lid_t - 0.01], [xiao_w, 2, xiao_lift]);
      box([-xiao_w/2, -wall - tol - 2, lid_t - 0.01], [xiao_w, 2, xiao_lift]);
      box([-xiao_w/2 - tol, xl0 - tol - 1.5, lid_t - 0.01], [xiao_w + 2*tol, 1.5, xiao_lift + pcb_t + 2]);
    }
    // battery stands on its long edge against the front wall, held by this rib
    box([-bat_l/2 - 2, wall + bat_t + bat_slack, lid_t - 0.01], [bat_l + 4, 1.2, 10]);
    // magnet bosses up to the meeting plane, trimmed to fit inside the walls
    intersection() {
      box([-cav.x/2 + tol, wall + tol, lid_t - 0.01], [cav.x - 2*tol, cav.y - 2*tol, mag_z - lid_t + 0.01]);
      for (p = mag_xy) translate([p.x, p.y, 0]) cylinder(d = boss_d, h = mag_z);
    }
    // locating lip along the walls, cleared at the corners, battery, and port cluster
    difference() {
      box([-cav.x/2 + tol, wall + tol, lid_t - 0.01], [cav.x - 2*tol, cav.y - 2*tol, lip_h]);
      box([-cav.x/2 + tol + 1.2, wall + tol + 1.2, 0], [cav.x - 2*tol - 2.4, cav.y - 2*tol - 2.4, 9]);
      for (p = mag_xy) translate([p.x, p.y, 0]) cube([boss_d + 2, boss_d + 2, 20], center = true);
      box([-bat_l/2 - 2.5, 0, 0], [bat_l + 5, depth/2, 9]);
      at_port() {
        box([-xiao_w/2 - tol - 2, -25, 0], [xiao_w + 2*tol + 4, 30, 9]);
        box([sw_lx - sw_l/2 - 3, -25, 0], [sw_l + 6, 30, 9]);  // power switch, when it sits low
      }
    }
  }
  for (p = mag_xy) translate([p.x, p.y, mag_z - mag_h]) cylinder(d = mag_pd, h = mag_h + 1);
}

module label(i) linear_extrude(label_depth + 0.01)
  text(labels[i], size = label_size[i], halign = "center", valign = "center", font = label_font);

module keycap(i) difference() {
  union() {
    difference() {
      cbox([-cap/2, -cap/2, 0], [cap, cap, cap_h], bot = false);
      box([-cap/2 + cap_wall, -cap/2 + cap_wall, -1], [cap - 2*cap_wall, cap - 2*cap_wall, cap_skirt + 1]);
    }
    translate([0, 0, cap_skirt - cross_depth]) cylinder(d = stem_d, h = cross_depth + 0.01);
  }
  for (r = [0, 90]) rotate(r) box([-cross_l/2, -cross_w/2, cap_skirt - cross_depth - 1], [cross_l, cross_w, cross_depth + 1]);
  translate([0, 0, cap_h - label_depth]) label(i);
}
module label_at(i) translate([0, 0, cap_h - label_depth]) label(i);

// print orientations: body plate-down, caps top-down, lid flat (or on its legs)
module flip(h) translate([0, depth, h]) rotate([180, 0, 0]) children();
module caps_row() for (i = [0:2]) translate([(i - 1) * (cap + 4), 0, cap_h]) rotate([180, 0, 0]) children(i);

if (part == "body") flip(H) body();
if (part == "lid") translate([0, 0, lid_lift]) lid();
if (part == "plate") translate([0, 0, plate - plate_top]) plate();
if (part == "keycaps") caps_row() { keycap(0); keycap(1); keycap(2); }
if (part == "labels") caps_row() { label_at(0); label_at(1); label_at(2); }

// ---- Debug: stand-ins for bought parts (preview + clash check, never exported) ----
bat_h = 20.5;         // battery stands on its long edge

module xiao_dummy() at_port() {
  color("#2E7D32") box([-xiao_w/2, xl0, lid_t + xiao_lift], [xiao_w, xiao_l, pcb_t]);
  color(two_tone ? accent_col : "#B0B0B0") box([-usb_w/2, -wall - 7, port_z - usb_h/2], [usb_w, 7 + usb_over, usb_h]);
  color("#9E9E9E") box([-6, xl0 + 3, lid_t + xiao_lift + pcb_t], [12, 11, 2.2]);  // shield can
}
module battery_dummy() color("#607D8B") box([-bat_l/2, wall + tol, lid_t], [bat_l, bat_t, bat_h]);
module antenna_dummy() color("#212121") box([-ant_l/2, depth - wall - 0.3, ant_z + 0.5], [ant_l, 0.3, ant_w]);
// slide switch lying against the port wall: slider out through the wall, pins pointing inward
module slide_dummy() color(two_tone ? accent_col : "#424242") at_port() translate([sw_lx, -wall, sw_z]) {
  box([-sw_l/2, -sw_h, -sw_w/2], [sw_l, sw_h, sw_w]);
  box([-knob_l/2 - knob_travel/2, 0, -knob_w/2], [knob_l, knob_h, knob_w]);  // slider, one end of travel
  for (dx = [-2.54, 0, 2.54]) translate([dx, -sw_h, 0]) rotate([90, 0, 0]) cylinder(d = 0.8, h = 3);
}
module magnets_dummy() color("#CFD8DC") for (p = mag_xy, z = [mag_z - mag_h, mag_z])
  translate([p.x, p.y, z]) cylinder(d = mag_d, h = mag_h);
// MX switch: housing through the plate, pins, tapered top housing, stem cross
module switches_dummy() color("#FFF59D") for (i = [-1:1]) translate([i*pitch, depth/2, plate_top]) {
  box([-6.95, -6.95, -plate - 3.5], [13.9, 13.9, plate + 3.5]);
  translate([0, 0, -plate - 6.8]) cylinder(d = 4, h = 3.4);
  for (q = [[-3.81, 2.54], [2.54, 5.08]]) translate([q.x, q.y, -plate - 6.8]) cylinder(d = 1.5, h = 3.4);
  hull() { box([-7.8, -7.8, 0], [15.6, 15.6, 0.01]); box([-5.8, -5.8, 6.59], [11.6, 11.6, 0.01]); }
  for (r = [0, 90]) rotate(r) box([-2.05, -0.65, 6.6], [4.1, 1.3, 5]);
}
module keycaps_placed() for (i = [0:2]) translate([(i - 1) * pitch, depth/2, plate_top + cap_rest]) {
  color(accent_col) keycap(i);
  if (fill_labels) color("black") label_at(i);
}

module thing(n) {
  if (n == "body") body();
  if (n == "lid") lid();
  if (n == "plate") plate();
  if (n == "xiao") xiao_dummy();
  if (n == "battery") battery_dummy();
  if (n == "antenna") antenna_dummy();
  if (n == "magnets") magnets_dummy();
  if (n == "slide") slide_dummy();
  if (n == "switches") switches_dummy();
  if (n == "keycaps") keycaps_placed();
}

// all: whole build. xray = hide the body to see inside; cut = section at x=0; explode = pull lid/caps apart
xray = false;
fill_labels = false;  // preview only: show keycap labels filled (labels.stl) or as plain engraving
two_tone = false;     // preview only: every visible part in the body or keycap colour (banner)
body_col = "#DA7756";
accent_col = "#EEE";
cut = false;
explode = 0;
module assembly() {
  if (!xray) { color(body_col) body(); preview_add(); }
  translate([0, 0, -explode]) { color(two_tone ? body_col : "#C86A4C") lid(); xiao_dummy(); battery_dummy(); }
  slide_dummy();
  magnets_dummy();
  antenna_dummy();
  translate([0, 0, explode/2]) { color("#B9654A") plate(); switches_dummy(); }
  translate([0, 0, explode]) keycaps_placed();
}
if (part == "all") {
  if (cut) intersection() { assembly(); box([-W/2 - 1, -1, -1], [W/2 + 1, depth + 2, H + 30]); }
  else assembly();
}

// clash: renders the overlap of two things; an empty result means they don't collide
a = "body";
b = "lid";
if (part == "clash") intersection() { thing(a); thing(b); }
