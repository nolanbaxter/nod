// Extra render views. Run with -D view="port" | "lying" | "banner" | "banner_body" | "banner_accent".
include <case.scad>
part = "none";
view = "port";

if (view == "port") {  // right side: USB port, LED window, power switch
  color("#DA7756") body();
  color("#C86A4C") lid();
  xiao_dummy();
  slide_dummy();
}
if (view == "lying") rotate([-90, 0, 0]) assembly();  // on its back
if (view == "banner") rotate([90, 0, 0]) assembly();  // on its front: keys face the camera, labels read upright
// banner colour groups, exported as real geometry (the preview renderer mangles shallow engravings)
if (view == "banner_body") rotate([90, 0, 0]) { body(); lid(); }
if (view == "banner_accent") rotate([90, 0, 0]) { keycaps_placed(); slide_dummy(); xiao_dummy(); }
