#!/usr/bin/env python3
"""
brick_calc.py — CEB plant + dome calculator. Ours: trivial config
math (constants + arithmetic) — part of the <5% bespoke layer.

Usage:
    python3 brick_calc.py press                # press force / face-pressure table
    python3 brick_calc.py dome [radius_ft] [wall_in]   # brick counts, volumes, schedule
    python3 brick_calc.py production [n_bricks]        # production time estimate
    python3 brick_calc.py all                  # everything, default 6 ft radius dome
"""
import sys
import math

TONS = 25.0          # press rating (stock splitter cylinder)
SYSTEM_PSI = 3000.0  # hydraulic relief setpoint
BRICKS = {           # name: (w_in, l_in, h_in, use)
    "dome 8x10":   (8, 10, 3.5, "dome wall, header-bond, flat faces"),
    "wall 6x12":   (6, 12, 3.0, "walls, returns, tunnel"),
    "paver 10x10": (10, 10, 1.75, "floor, apron, drain lining"),
}
SOIL_LB_FT3 = 110    # compacted earth density
COMPACT = 0.5        # loose soil -> pressed brick volume ratio
RATE_LO, RATE_HI = 60, 120  # bricks/hour sustained


def press():
    print(f"Press: {TONS:.0f}T rated, {TONS*2000:,.0f} lbf, relief <= {SYSTEM_PSI:.0f} psi — stock splitter cyl")
    print(f"{'insert':<14}{'face sqin':>10}{'psi@25T':>10}  verdict")
    for name, (w, l, h, use) in BRICKS.items():
        a = w * l
        p25 = TONS * 2000 / a
        v = "in band" if 500 <= p25 <= 1500 else ("low" if p25 < 500 else "high")
        print(f"{name:<14}{a:>10.0f}{p25:>10.0f}  {v} ({use})")
    print("\nCEB compaction band ~500-1,500 psi. Bore needed for target force @3,000 psi:")
    bore = math.sqrt(TONS * 2000 / SYSTEM_PSI / math.pi) * 2
    print(f"  {bore:.1f} in diameter cylinder (area {TONS*2000/SYSTEM_PSI:.1f} sqin)")


def corbel_courses(r_ft, wall_in, h_in):
    """Yield (course_idx, radius_ft) up the hemisphere, base course = 0."""
    wall_ft = wall_in / 12
    r_mid = r_ft + wall_ft / 2          # shell midline radius
    y = h_in / 12                        # first course top
    i = 0
    while y < r_mid - 0.05:
        yield i, math.sqrt(r_mid**2 - y**2)
        i += 1
        y += h_in / 12


def dome(r_ft=6.0, wall_in=12.0):
    dome_brick = BRICKS["dome 8x10"]
    h_in = dome_brick[2]
    face = dome_brick[0] * dome_brick[1]  # sqin of bed face

    print(f"Dome: {r_ft*2:.0f} ft interior dia, {wall_in:.0f} in wall, "
          f"{dome_brick[0]}x{dome_brick[1]}x{h_in} in bricks\n")

    # Shell volume (hemisphere shell, ~8% deduction for eye+door)
    wall_ft = wall_in / 12
    v_shell = 2 * math.pi * ((r_ft + wall_ft)**3 - r_ft**3) / 3 * 0.92
    v_brick = dome_brick[0] * dome_brick[1] * dome_brick[2] / 1728
    n_wall = math.ceil(v_shell / v_brick)

    # Corbel schedule
    courses = list(corbel_courses(r_ft, wall_in, h_in))
    prev = None
    print("Corbel schedule (course: radius, inward step):")
    for i, r in courses:
        step = "" if prev is None else f", step {prev - r:.2f} ft"
        print(f"  course {i+1:>2}: r {r:5.2f} ft{step}")
        prev = r
    print(f"  -> {len(courses)} courses to eye; keystone plug ~1.5-2 ft dia + capstone\n")

    # Pavers: interior floor + ~2 ft apron ring
    floor_ft2 = math.pi * r_ft**2
    apron_ft2 = math.pi * ((r_ft + wall_ft + 2)**2 - (r_ft + wall_ft)**2)
    paver_ft2 = BRICKS["paver 12x12"][0] * BRICKS["paver 12x12"][1] / 144
    n_paver = math.ceil((floor_ft2 + apron_ft2) / paver_ft2)
    n_misc = 100  # returns, tunnel, drain lining, spares

    total = n_wall + n_paver + n_misc
    print(f"Bricks: wall {n_wall} + pavers {n_paver} "
          f"(floor {floor_ft2:.0f} sqft + apron {apron_ft2:.0f} sqft) "
          f"+ misc {n_misc} = {total} total\n")

    # Soil + berm
    soil_ft3 = total * v_brick / COMPACT
    berm_ft3 = 2 * math.pi * (r_ft + wall_ft) * 2.5 * wall_ft * 0.6  # ~2.5ft berm avg
    print(f"Soil needed: ~{soil_ft3:.0f} cuft loose "
          f"(pit at 24 in deep -> ~{soil_ft3/2/r_ft**2/math.pi:.1f}x footprint equiv)")
    print(f"Berm volume: ~{berm_ft3:.0f} cuft (excavation supplies ~{math.pi*(r_ft+wall_ft)**2*2:.0f} cuft)")
    mass_lb = total * v_brick * SOIL_LB_FT3
    print(f"Mass moved: ~{mass_lb:,.0f} lb (~{mass_lb/2000:.1f} tons)\n")

    production(total)


def production(n=1300):
    hrs_lo = n / RATE_HI
    hrs_hi = n / RATE_LO
    print(f"Production: {n} bricks @ {RATE_LO}-{RATE_HI}/hr = "
          f"{hrs_lo:.1f}-{hrs_hi:.1f} press-hours "
          f"(~{math.ceil(hrs_hi/8)}-{math.ceil(hrs_hi/5)} press-days)")
    fuel = hrs_hi * 1.0
    print(f"Fuel ~{fuel:.0f} gal @ ~1 gal/hr")


def all_():
    press()
    print("\n" + "=" * 60 + "\n")
    dome()
    print("\n" + "=" * 60 + "\n")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "all"
    if cmd == "press":
        press()
    elif cmd == "dome":
        dome(float(sys.argv[2]) if len(sys.argv) > 2 else 6.0,
             float(sys.argv[3]) if len(sys.argv) > 3 else 12.0)
    elif cmd == "production":
        production(int(sys.argv[2]) if len(sys.argv) > 2 else 1300)
    else:
        all_()
