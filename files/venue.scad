// venue.scad — UNBURIED venue module: saucer-profile dome on a brick footing
// ring + banked soil skirt (the sliding mechanism — passive earth, not mound),
// propylon gate (2 battered piers + corbelled lintel + stomion portal),
// integral echea cavity, absorptive interior liner. NO mound — fully visible.
// Screening: cad/venue_screen.py (envelope ~2.7g, sliding-governed).
// INCHES. Brick = B_DOME [10,8,3.5]; pavers/plates as cubes.
include <params.scad>
include <parts.scad>

// ---------- saucer dome ----------
FOOT_D  = 18;          // footing depth (frost-line placeholder)
A_PLAN  = 48;          // inner plan radius (8-ft dome)
WALL_T  = 12;          // wall thickness
RISE    = 36;          // saucer rise — shallow, NOT hemisphere
RS_I    = 50;          // inner sphere radius ((A^2+h^2)/2h = 50)
Z_RIM   = FOOT_D;      // shell rim sits on footing top
Z_C     = FOOT_D + RISE - RS_I;   // sphere center z (=4)
Z_APEX  = FOOT_D + RISE;          // =54
EYE_R   = 12;          // oculus radius
COURSE_H= 3.5;
N_COURSES = 10;                        // courses reach ~z=53 (apex 54)

// ---------- footing ring (3-ft wide: brick wythes + site-soil core) ----------
// Kern ∝ outer radius buys overturning margin; sliding is bought by the
// banked soil SKIRT outside — free dirt is the cheapest lateral restraint.
// Envelope ~2.7 g at ~844 brick units (screening: venue_screen.py).
FOOT_I  = 60;          // inner radius (= wall outer at rim)
FOOT_O  = 96;          // outer radius (36" wide ring = 3 ft)
PAV     = 12;          // paver face
PAV_H   = 1.75;
// two 12" wythes (inner + outer edge) + soil core between
FOOT_ROWS = [66, 90];            // wythe row center radii
CORE_I  = 72; CORE_O = 84;       // soil core band
N_PAV_COURSES = floor(FOOT_D / PAV_H);               // 10

// ---------- soil skirt (banked earth apron — THE sliding mechanism) ----------
// Trapezoid ring against the footing's outer face: 36" wide x 30" tall,
// sheds water away from the wythes. Compacted site soil, sacrificial.
SKIRT_I = 96;          // at footing outer face
SKIRT_O = 132;         // 36" wide
SKIRT_H = 30;

// ---------- propylon gate (entry-side: 2 piers + corbelled lintel, stomion) ----------
// GATEHOUSE: the vaulted bay IS the entry — a 14-ft dromos; the mouth is a
// FULLY OPEN 14-ft arch on the entry face (no trumeau — the front arch is a
// true free-spanning arch between the rib inner faces). The bass PA moved
// INTO the rib walls: echea cavities embedded in the soil-core zone, necks +
// woofer discs on the front faces flanking the mouth.
PIER_Z0 = FOOT_D;      // footing top edge (dome Trip-2 shutter z ref)
PORTAL_W= 40;          // dome-door clear width (the shutter now seals the
                       // DOME door — Trip 2 "mute")
DOOR_A  = 270;         // dome door azimuth (down the dromos axis)
DOOR_W_A= 18;          // half-angle of door skip sector

// ---------- absorptive interior liner ----------
// Relief inner leaf + sand cavity — the venue's acoustic skin at prototype
// scale: a curved band lining the dome's interior (not a freestanding slab).
LIN_H   = 24;          // liner band height above rim (z 18..42)
LIN_GAP = 6;           // sand cavity depth
LIN_T   = 2;           // leaf thickness
CUT     = 1;
SHUTTERS = 0;          // 1 = closed mode (sound contained / rain sealed)

// ---------- aperture closures (the instrument's "mute") ----------
// Earth walls block ~50 dB — the openings ARE the radiators; closing them
// mutes the venue. All closures are brick/paver + sand, zero hardware:
//   portal shutter — sliding CEB panel on a sand track across the gate
//   oculus cap — paver disc dropping into a sand-bed seat over the eye
//   vent shutters — pavers sliding over each echea neck slot
module portal_shutter(open_pos) {
  // sliding CEB panel across the DOME DOOR — rendered closed-mode only.
  // The 14-ft dromos mouth stays a fixed aperture; the mute seals the
  // interior chamber at the dome's own ~40-in corbelled door.
  if (!open_pos)
    color(PAV_C)
      translate([0, -72, PIER_Z0 + 33])
        cube([PORTAL_W - 2, 8, 66], center=true);          // ~60-brick panel
}
module oculus_cap(open) {
  if (!open)
    color(PAV_C)
      translate([0, 0, Z_APEX + 1.75])                   // drops into sand seat
        cylinder(r = EYE_R + 6, h = 3.5, $fn = 24);      // paver disc over eye
}
module vent_shutter(idx, open) {
  if (!open)
    color(PAV_C)
      translate([RIB_X[idx], BAY_Y0 - (BAY_Y0 + BAY_Y1)/2 + 1, 38])
        cube([16, 4, 16], center=true);                  // paver over rib-face neck
}
module closures(open) {
  portal_shutter(open);
  oculus_cap(open);
  for (i = [0:len(RIB_X)-1]) vent_shutter(i, open);
}

// brick colors
SOIL_C  = [0.48, 0.40, 0.27];
PAV_C   = [0.60, 0.36, 0.20];
MORTAR_C= [0.55, 0.46, 0.32];
SAND_C  = [0.72, 0.62, 0.45];

// ================= dome shell — TRUE spherical cap, tangent-laid =================
// Each brick lies on the mid-wall sphere (RS_M), tilted to the surface normal.
// Local axes after rotate: x->tangential, y->meridional, z->normal.
module shell_brick(a, beta, px, py, pz) {
  translate([px, py, pz])
    rotate([0, 0, a]) rotate([0, beta, 0]) rotate([0, 0, 90])
      brick();
}

module dome_shell() {
  RS_M = RS_I + WALL_T/2;                 // mid-wall sphere
  for (i = [0:N_COURSES-1]) {
    zj = Z_RIM + (i + 0.5) * COURSE_H;
    rho = sqrt(max(RS_M*RS_M - (zj - Z_C)*(zj - Z_C), 1));
    beta = atan2(rho, zj - Z_C);          // surface tilt from vertical
    n = floor(2*PI*rho / (BRICK.x + 0.3)); // tangential pitch ~10.3" (x->tangent)
    for (j = [0:n-1]) {
      a = j * 360 / n;
      da = abs(((a - DOOR_A + 180) % 360) - 180);   // angular distance to door
      // door sector: gap NARROWS with height — corbelled closure over the
      // opening (~3"/course each side), fully closed by z = Z_RIM + 48
      door_ha = DOOR_W_A * max(0, 1 - (zj - Z_RIM) / 48);
      // skip oculus eye + door sector
      if (!((rho < EYE_R + 3 && zj > Z_APEX - 14) ||
            (da < door_ha && zj < Z_RIM + 48))) {
        px = (rho + 1.2) * cos(a);
        py = (rho + 1.2) * sin(a);
        pz = zj + 1.2 * cos(beta);          // approx normal offset (z-comp)
        shell_brick(a, beta, px, py, pz);
      }
    }
  }
  // apex cap ring — flat-laid ring of bricks around the oculus
  color(BRICK_C)
    for (k = [0:11])
      translate([16*cos(k*30), 16*sin(k*30), Z_APEX - 4])
        rotate([0, 0, k*30]) cube([10, 8, 3.5], center=true);
}

// ================= footing ring — paver courses =================
module footing() {
  // brick wythes — inner + outer ring
  color(PAV_C)
    for (r = FOOT_ROWS)
      for (c = [0:N_PAV_COURSES-1]) {
        z = (c + 0.5) * PAV_H;
        n = floor(2*PI*r / (PAV + 0.3));
        for (j = [0:n-1]) {
          a = j * 360 / n;
          translate([r*cos(a), r*sin(a), z])
            rotate([0, 0, a + 90])
              cube([PAV, PAV, PAV_H], center=true);
        }
      }
  // site-soil core between wythes (same mass, ~1/3 the bricks)
  color([0.52, 0.44, 0.30])
    difference() {
      cylinder(r = CORE_O, h = FOOT_D - 0.4, $fn = 64);
      cylinder(r = CORE_I, h = FOOT_D + 1, $fn = 64);
    }
}

// ================= soil skirt (dome only — Trip 2) =================
module skirt() {
  color([0.45, 0.38, 0.26])
    difference() {
      cylinder(r1 = SKIRT_O, r2 = SKIRT_I + 2, h = SKIRT_H, $fn = 64);
      translate([0, 0, -1]) cylinder(r = SKIRT_I, h = SKIRT_H + 2, $fn = 64);
    }
}

// ================= propylon gate (2 piers + corbelled lintel) =================
// echea cavity: hollow tuned chamber embedded in each RIB wall + neck slot
// exiting the rib's front face — the piers are gone (fully open mouth), so
// the ribs themselves are the speaker stacks. UNDAMPED = bass VENT
// (Helmholtz radiator): chamber ~16x14x24" + neck 6x6x~18" -> f_res ≈ 57 Hz
// — the kick-drum band. Interior bass pressure drives the vent, re-radiating
// low end onto the square — passive subwoofer ports, one per rib.
// (Trap variant: fill neck with sand/felt -> absorbs instead.)
// The void sits in the rib's soil-core zone low on the wall — away from
// springing — where losing brick costs least (core is fill, not wythe).
module rib_echea(sx) {
  translate([sx, BAY_Y0 - 22, 30])
    cube([16, 14, 24]);                       // chamber, straight walls
  for (k = [0:2])                             // corbelled roof: steps in 3"/side
    translate([sx, BAY_Y0 - 22 + k*2, 30 + 24 + k*3.5])
      cube([16 - k*6, 14 - k*4, 3.5]);
  translate([sx, BAY_Y0 - 9, 38])
    cube([6, 20, 6]);                         // neck -> front face (radiator)
}

// woofer face: dark disc over each vent mouth on the rib front faces — the
// gatehouse walls read as the speakers they functionally are (~56 Hz)
SPEAK_C = [0.13, 0.11, 0.10];
module rib_woofer(sx) {
  color(SPEAK_C)
    translate([sx, BAY_Y0 + 2, 38])
      rotate([-90, 0, 0]) cylinder(r = 9, h = 3, $fn = 24);
}

// ---------- vaulted bay: 14-ft span x 8-ft deep, Nubian leaning vault ----------
// Two rib walls + end wall + vault courses tilted ~10 deg back so each leans
// on the course behind — full span by arch action, NO corbel limit, NO form.
// Mouth faces -Y (the venue approach); ribs run the 8-ft depth.
BAY_XC   = 0;              // bay center — ON the entry axis (gatehouse/dromos)
BAY_HALF = 84;             // 168" clear span between rib inner faces
RIB_T    = 20;             // rib wall thickness (wythe faces + soil core in field)
RIB_X    = [-99, 99];      // rib centerlines -> inner faces at ±84 (30" base)
BAY_Y0   = -120;           // mouth — just outside the dome skirt
BAY_Y1   = -216;           // party wall plane (8-ft deep dromos)
BAY_Y2   = -296;           // rear wall face — livable back cell (~5ft deep)
SPRING_Z = 63;             // rib top / vault springing (18 courses)
VAULT_R  = 105;            // R = (84^2 + 42^2) / (2*42) — 42" rise
VAULT_T  = 8;              // shell thickness ~1 wythe + parge
VAULT_N  = 12;             // courses over the 96" depth (~8" each)
VAULT_LEAN = 15;           // deg back toward end wall — steeper lean, harder slip

module rib_wall(xc) {
  for (c = [0:17]) {
    t = RIB_T + 10 - 10*c/17;                      // deep batter 30->20 — kern gain
    translate([xc, (BAY_Y0 + BAY_Y2 - 4)/2, (c + 0.5) * 3.5])
      cube([t, BAY_Y0 - BAY_Y2 + 4, 3.6], center=true);  // keyed into both walls
  }
}

// HYBRID ENVELOPE — no-machine variant: stepped COUNTERFORTS carry the
// rib's static thrust as positioned mass (feet out to +/-170in at grade —
// the lowest, widest place mass can sit), and the berms shrink to HAUNCH
// banks between them (crest ~44in, below springing). Earth moved ~45 yd3
// vs ~130 — shovel-feasible; the counterfort skins are wythe faces over
// compacted soil cores (same wythe+core trick as the walls).
// SEQUENCE MATTERS: counterforts + haunch banks go in BEFORE the vault —
// bare ribs can't abut the thrust (static FoS ~0.6 unabutted).
module counterforts() {
  color(BRICK_C)
    for (s = [-1, 1])
      for (yc = [-150, -218, -282])     // mouth, party-wall, rear-cell flanks
        hull() {
          translate([BAY_XC + s*140, yc, 1])
            cube([60, 48, 2], center=true);    // foot: x +/-110..170
          translate([BAY_XC + s*122, yc, 64])
            cube([20, 40, 2], center=true);    // crest above springing
        }
}

module bay_berms() {
  color(SOIL_C) {
    // haunch banks — low fill BETWEEN the counterforts along each flank
    // (crest ~44in: below springing; the counterforts poke through as
    // masonry teeth). Same 27deg-ish battered slope, far less volume.
    SOIL_RUN = (BAY_Y0 + 96) - (BAY_Y2 - 40);
    SOIL_YC  = (BAY_Y0 + 96 + BAY_Y2 - 40) / 2;
    for (s = [-1, 1])
      hull() {
        translate([BAY_XC + s*140, SOIL_YC, 2])
          cube([96, SOIL_RUN, 4], center=true);                // foot to +/-188
        translate([BAY_XC + s*114, SOIL_YC, 42])
          cube([4, SOIL_RUN, 4], center=true);                 // crest ~44in
      }
    // rear wrap — one wedge butting the rear LINER (the vault tails rest
    // into it; crest overlaps the liner back 1in, stays below its 63in top),
    // reaching back to overlap the side-bank feet and close the ring
    hull() {
      translate([BAY_XC, BAY_Y2 - 75, 1])
        cube([2*(BAY_HALF + RIB_T) + 34, 136, 2], center=true);  // sloped foot
      translate([BAY_XC, BAY_Y2 - 19, 29])
        cube([2*(BAY_HALF + RIB_T) + 34, 24, 58], center=true);  // crest at liner
    }
    // crown cap: THIN armor layer over the vault crown, ~10in — weather +
    // dust protection only now (kern mass lives in the counterforts), still
    // carved to the extrados so no soil face stands inside the tube.
    difference() {
      hull() {
        translate([0, BAY_Y0 - 110, SPRING_Z + 24])
          cube([176, 190, 4], center=true);                    // covers both cells
        translate([0, BAY_Y0 - 128, VAULT_R + 10])
          cube([100, 134, 4], center=true);                    // thin crest
      }
      translate([BAY_XC, -320, 0]) rotate([-90, 0, 0])
        cylinder(h = 560, r = VAULT_R + 2, $fn = 64);          // intrados + margin
    }
  }
}

// PLINTH KEYS — rib + end-wall courses continue ~12in below grade
// (trench-locked). Kills the base-sliding mode: lateral failure must ROCK,
// so the bound is kern/z_cg of the composite soil+masonry mass — that is
// what lets the mouth direction rate at all.
module plinth() {
  color(BRICK_C) {
    for (s = [-1, 1])
      translate([BAY_XC + s*99, (BAY_Y0+BAY_Y2-4)/2, -6])
        cube([42, BAY_Y0 - BAY_Y2 + 4, 12], center=true);
    // rear-wall key — inside the thin liner footprint, crosses the z=0 plane
    translate([BAY_XC, BAY_Y2 - 4, -3])
      cube([2*(BAY_HALF + RIB_T) - 8, 12, 18], center=true);
    // end-wall key — crosses the wall depth and pokes above the z=0 contact
    // plane: flush faces here corrupt the CGAL union (see bank note above)
    translate([BAY_XC, BAY_Y1 - RIB_T/2 + 8, -3])
      cube([2*(BAY_HALF + RIB_T) - 8, RIB_T + 14, 18], center=true);
    // counterfort keys — trench-locked foot under each buttress
    for (s = [-1, 1])
      for (yc = [-150, -218, -282])
        translate([BAY_XC + s*140, yc, -3])
          cube([52, 40, 18], center=true);
  }
}

// FRONT GABLE — stepped ARCH ring at the mouth: the facade's outer
// silhouette follows the vault's own arc (radius VAULT_R + 26) instead of
// a rectangle, so the face IS the arch — matching the shell's profile, not
// a square wall in front of it. Still fills the spandrel + retains the cap.
module front_gable() {
  RO = VAULT_R + 26;
  for (c = [18:36]) {
    z = (c + 0.5) * 3.5;
    hw  = sqrt(max(VAULT_R*VAULT_R - z*z, 0));      // intrados half-width
    hwo = min(sqrt(max(RO*RO - z*z, 0)), BAY_HALF + RIB_T);  // outer arc
    if (hwo > 0)
      if (hw > 0)                                  // ring cheeks flanking arch
        for (s = [-1, 1])
          translate([BAY_XC + s*(hw + (hwo - hw)/2),
                     BAY_Y0 - 2.5, z])
            cube([hwo - hw, 12, 3.6], center=true);
      else                                         // solid band above crown
        translate([BAY_XC, BAY_Y0 - 2.5, z])
          cube([2*hwo, 12, 3.6], center=true);
  }
}

// party wall: full rectangle to springing, then stepped gable following the
// arc. A ~40in doorway is corbelled through its center — the dromos is a
// REAL GATE (mouth -> hall -> door -> back cell). BUILD NOTE: the lower
// rectangle lays as WYTHE + SOIL CORE (two 6in faces + ~24in compacted
// core, like the ribs) — the gable above springing stays solid; that's
// what carries the vault lean. ~60% of the rectangle's brick saved.
module end_wall() {
  difference() {
    union() {
      translate([BAY_XC, BAY_Y1 - RIB_T/2 + 8, SPRING_Z/2])
        cube([2*(BAY_HALF + RIB_T), RIB_T + 16, SPRING_Z], center=true);
      for (c = [18:29]) {
        z = (c + 0.5) * 3.5;
        hw = sqrt(max(VAULT_R*VAULT_R - z*z, 0));  // arc half-width at course
        if (hw > 0)
          translate([BAY_XC, BAY_Y1 - RIB_T/2 + 8, z])
            cube([2*(hw + RIB_T), RIB_T + 16, 3.6], center=true);
      }
    }
    translate([BAY_XC, BAY_Y1 - RIB_T/2 + 8, 28])
      cube([40, RIB_T + 20, 56], center=true);     // door void, corbel head
  }
}

// vault courses: course 0 is the VERTICAL front arch (the gatehouse face —
// its crown springs rib-to-rib — no trumeau); courses 1+ lean ~15deg back. That is
// how real Nubian vaults frame an opening: face arch first, lean after.
module vault() {
  for (k = [0:VAULT_N-1])
    let(y = BAY_Y0 - 4 - k*8, lean = k == 0 ? 0 : VAULT_LEAN)
    translate([0, y, 40]) rotate([lean, 0, 0]) translate([0, -y, -40])
      intersection() {
        difference() {
          translate([BAY_XC, -300, 0]) rotate([-90, 0, 0])
            cylinder(h = 500, r = VAULT_R + VAULT_T, $fn = 64);
          translate([BAY_XC, -300, 0]) rotate([-90, 0, 0])
            cylinder(h = 500, r = VAULT_R, $fn = 64);
        }
        translate([BAY_XC - BAY_HALF - RIB_T, y - 4.5, 0])
          cube([2*(BAY_HALF + RIB_T), 9, 140]);
        // embed band ends INSIDE the end wall (clip 6in behind its front
        // face at local -200): any surface crossing the face plane makes
        // CGAL drop faces — a hole that showed the soil bank through the mouth
        translate([-200, -206, -1])
          cube([400, 400, 300]);
      }
  // crown-slot closure — masonry wedge filling the lean-transition slot
  // between the vertical face arch (back face y=-128.5) and course 1's
  // tilted front face. Without it the slot opens the vault interior to
  // the soil cap above (and shows as a tan mass cutting the arch).
  intersection() {
    hull() {
      translate([0, -128.6, 76])
        cube([2*(BAY_HALF + RIB_T), 0.5, 84], center=true);
      translate([0, -132, 40]) rotate([VAULT_LEAN, 0, 0])
        translate([0, 132, -40])
          translate([0, -127.4, 76])
            cube([2*(BAY_HALF + RIB_T), 0.5, 84], center=true);
    }
    difference() {
      translate([BAY_XC, -300, 0]) rotate([-90, 0, 0])
        cylinder(h = 500, r = VAULT_R + VAULT_T + 0.5, $fn = 64);
      translate([BAY_XC, -300, 0]) rotate([-90, 0, 0])
        cylinder(h = 500, r = VAULT_R - 0.5, $fn = 64);
    }
  }
}

// REAR CELL — the livable back room: the party wall's door opens into a
// second vaulted cell. Its courses lean FORWARD (-15deg) — tops resting on
// the shared party wall's back face, so both bays lean into the same
// abutment (opposing thrust partially cancels — the multi-bay Nubian
// trick, and exactly how the Sand Dunes basilica chains cells).
module rear_vault() {
  for (k = [0:6])
    let(y = -244 - k*8)
    translate([0, y, 40]) rotate([-VAULT_LEAN, 0, 0]) translate([0, -y, -40])
      intersection() {
        difference() {
          translate([BAY_XC, -300, 0]) rotate([-90, 0, 0])
            cylinder(h = 500, r = VAULT_R + VAULT_T, $fn = 64);
          translate([BAY_XC, -300, 0]) rotate([-90, 0, 0])
            cylinder(h = 500, r = VAULT_R, $fn = 64);
        }
        translate([BAY_XC - BAY_HALF - RIB_T, y - 4.5, 0])
          cube([2*(BAY_HALF + RIB_T), 9, 140]);
        // tops embed 6in into the party wall's back face (-236 -> -230);
        // tails pass through the thin rear liner into the soil bank (-302)
        translate([-200, -302, -1]) cube([400, 72, 300]);
      }
}

// rear wall — THIN WYTHE LINER (8in) + stepped gable following the arc:
// the rear vault leans FORWARD onto the party wall, so this wall carries
// no lean — but its top must still CLOSE the room: the last band's tail
// drops low at the rear face and a thin liner alone leaves a dead wedge
// open to the sky behind it. The stepped gable meets the shell; the soil
// bank backs it. ~450 units saved vs a full gable wall.
module rear_wall() {
  difference() {
    union() {
      translate([BAY_XC, BAY_Y2 - 4, SPRING_Z/2])
        cube([2*(BAY_HALF + RIB_T), 8, SPRING_Z], center=true);
      for (c = [18:33]) {                     // stepped gable above springing
        z = (c + 0.5) * 3.5;
        hw = sqrt(max(VAULT_R*VAULT_R - z*z, 0));  // arc half-width at course
        if (hw > 0)
          translate([BAY_XC, BAY_Y2 - 4, z])
            cube([2*(hw + 4), 8, 3.6], center=true);
      }
    }
    translate([BAY_XC, BAY_Y2 - 14, 44])
      cube([16, 30, 14], center=true);           // duct: room -> vent stack
  }
}

// VENT STACK — masonry-lined shaft up the rear wall's back, through the
// bank + cap to ~12ft: the back cell's air path (the wall's back face is
// banked — a slit would be buried). Top exits face SIDEWAYS under a lid:
// sheds rain + driven dust (downturned).
module vent_stack() {
  color(BRICK_C) {
    difference() {
      translate([BAY_XC, BAY_Y2 - 22, 74])
        cube([30, 26, 148], center=true);        // column just behind liner
      translate([BAY_XC, BAY_Y2 - 22, 76])
        cube([14, 14, 150], center=true);        // shaft void
      for (s = [-1, 1])                          // top exits, side-facing
        translate([BAY_XC + s*10, BAY_Y2 - 22, 132])
          cube([12, 12, 10], center=true);
    }
    translate([BAY_XC, BAY_Y2 - 22, 150])
      cube([36, 32, 4], center=true);            // lid course, overhangs
  }
}

// STORM THRESHOLD — two courses across the mouth lip: wind-driven sand
// travels mostly by SALTATION in the bottom ~12in — the lip blocks the
// bulk of it; steps over easily.
module threshold() {
  color(BRICK_C)
    for (c = [0:1])
      translate([BAY_XC, BAY_Y0 - 2, (c + 0.5) * 3.5])
        cube([2*BAY_HALF + 2, 8, 3.6], center=true);  // ends embed 1in into ribs
}

// PAVER ARMOR — dry-laid paver skin over the cap crest: wind deflates
// loose fines off the envelope; pavers hold it through dust season.
module crest_armor() {
  color(BRICK_C)
    translate([0, BAY_Y0 - 125, VAULT_R + 13])
      cube([100, 130, 1.8], center=true);
}

module bay() {
  color(BRICK_C) {
    difference() { rib_wall(RIB_X[0]); rib_echea(RIB_X[0]); }
    difference() { rib_wall(RIB_X[1]); rib_echea(RIB_X[1]); }
    end_wall(); vault(); front_gable(); rear_vault(); rear_wall(); plinth();
    vent_stack(); threshold(); crest_armor(); counterforts();
  }
  rib_woofer(RIB_X[0]); rib_woofer(RIB_X[1]);
  bay_berms();
}

// ================= absorptive interior liner =================
// Curved double-skin band lining the dome interior: sand-packed cavity between
// the wall's inner face and a 2" relief leaf — the venue acoustic skin at
// prototype scale. Band runs rim (z=18) to z=42; gaps at the door azimuth.
module panel() {
  LIN_Z1 = Z_RIM + LIN_H;
  // sand cavity: spherical shell segment r=44..50 (against wall inner face 50)
  color(SAND_C)
    difference() {
      sphere(r = RS_I - 0, $fn = 48, center = [0, 0, Z_C]);
      sphere(r = RS_I - LIN_GAP - 1, $fn = 48, center = [0, 0, Z_C]);
      translate([-200, -200, LIN_Z1]) cube([400, 400, 200]);       // top clip
      translate([-200, -200, -200 - 1]) cube([400, 400, Z_RIM + 200 + 1]); // bottom clip
      // door gap
      rotate([0, 0, DOOR_A - 90])
        translate([-8, -60, -2]) cube([16, 60, LIN_Z1 + 4]);
    }
  // inner relief leaf: r = 42..44, same z band, same door gap
  color(BRICK_C)
    difference() {
      sphere(r = RS_I - LIN_GAP - 1, $fn = 48, center = [0, 0, Z_C]);
      sphere(r = RS_I - LIN_GAP - LIN_T - 1, $fn = 48, center = [0, 0, Z_C]);
      translate([-200, -200, LIN_Z1]) cube([400, 400, 200]);
      translate([-200, -200, -200 - 1]) cube([400, 400, Z_RIM + 200 + 1]);
      rotate([0, 0, DOOR_A - 90])
        translate([-10, -60, -2]) cube([20, 60, LIN_Z1 + 4]);
    }
}

// ================= ground =================
module ground() {
  color(SOIL_C)
    translate([-320, -320, -6]) cube([640, 640, 6]);   // square centered on origin
}

SHOW = 0;    // 0=all, 1=dome, 2=footing, 3=bay, 4=panel, 5=closures
ONLY_BAY = 1; // 1 = gatehouse-only build (dome/footing/liner deferred)
difference() {
  union() {
    if (SHOW == 0) ground();
    if (!ONLY_BAY && (SHOW == 0 || SHOW == 1)) dome_shell();
    if (!ONLY_BAY && (SHOW == 0 || SHOW == 2)) { footing(); skirt(); }
    if (SHOW == 0 || SHOW == 3)
      translate([0, -(BAY_Y0 + BAY_Y2)/2, 0]) bay();  // centered on the square
    if (!ONLY_BAY && (SHOW == 0 || SHOW == 4)) panel();
    if (SHOW == 0 || SHOW == 5) {
      for (i = [0:len(RIB_X)-1]) vent_shutter(i, !SHUTTERS);
      if (!ONLY_BAY) { portal_shutter(!SHUTTERS); oculus_cap(!SHUTTERS); }
    }
  }
  if (CUT)
    translate([-200, 0, -20]) cube([500, 200, 300]);  // remove y>0 half -> section
}
