// Extra render views. Run with -D view="port" | "lying".
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
