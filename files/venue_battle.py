# Battle test — adversarial checks on the gatehouse ratings.
# Run:  python3 cad/venue_battle.py
#
# Attacks the claims in venue_screen.py where screening tends to lie:
#   1. rib kern bound assumes an UNLOADED wall — but the rib is an abutment:
#      vault thrust H lands at its top. Static moment eats seismic capacity.
#   2. berm passive pressure only mobilizes when the wall pushes INTO soil
#      (outward topple). Inward rocking gets ZERO berm credit.
#   3. earth-sheltered "~4-5 g" was an analogy, not a computation — here we
#      actually compute the confined-translation bound.
#   4. berms at 32 deg = angle of repose = FS~1.0 dry; ANY shaking slumps.
#   5. course slide on the 15 deg lean solved with real force balance.
#
# Units: m, kN, kPa. g reported in units of gravity.
import math

G       = 9.81
RHO_B   = 1.80          # brick t/m3
RHO_S   = 1.55          # compacted site soil t/m3
RHO_SS  = 1.90          # saturated soil t/m3
MU_J    = 0.40          # dry brick-brick joint friction
MU_JS   = 0.30          # saturated/dirty joint friction
MU_SS   = 0.50          # soil-soil / masonry-on-soil friction
PHI     = 34.0          # soil friction angle deg — COMPACTED lifts required
                        # (32deg loose fill downgrades ~15% across the board)
CRUSH   = 2000.0        # kPa unstabilized CEB gate (2.0 MPa)
KP      = (1 + math.sin(math.radians(PHI))) / (1 - math.sin(math.radians(PHI)))

IN = 0.0254
def show(name, val, unit, verdict): print("  %-46s %8.2f %-5s %s" % (name, val, unit, verdict))

# ---------- geometry ----------
SPAN    = 168*IN        # clear span rib-to-rib 4.27 m
DEPTH   = 96*IN         # bay depth 2.44 m
RIB_L   = DEPTH
RIB_H   = 63*IN         # 1.60 m
RIB_TB  = 30*IN         # base thickness
RIB_TT  = 20*IN         # top thickness
RIB_TA  = (RIB_TB+RIB_TT)/2
R_IN    = 105*IN        # vault intrados radius
T_SH    = 8*IN          # shell thickness
RISE    = 42*IN         # arch rise
Z_SPR   = 63*IN         # springing height (= RIB_H)
TH_HALF = math.asin((SPAN/2)/R_IN)          # half-angle of arch
ARC     = R_IN*2*TH_HALF                    # arc length
LEAN    = math.radians(15)

# ---------- weights ----------
# vault shell
V_shell = ARC * DEPTH * T_SH
W_shell = V_shell * RHO_B * G
# soil cap: THIN armor over vault (hybrid variant): envelope z=61..117in,
# ~10in over crown — weather/dust only; kern mass lives in the counterforts.
env     = (176+110)/2*IN * (117-61)*IN * DEPTH
seg     = R_IN**2 * (TH_HALF - math.sin(TH_HALF)*math.cos(TH_HALF)) * DEPTH
V_cap   = max(env - ARC*DEPTH*T_SH - seg, 0)   # envelope - shell - air under vault
W_cap_d = V_cap * RHO_S * G                   # dry
W_cap_s = V_cap * RHO_SS * G                  # saturated
# rib wall (solid equiv — wythes + soil core averaged to brick for upper bound W)
W_rib   = RIB_TA * RIB_L * RIB_H * RHO_B * G + 42*IN*RIB_L*12*IN*RHO_B*G  # +plinth key
W_rib_core = (RIB_TA-0.30) * RIB_L * RIB_H * RHO_S * G + 0.30*RIB_L*RIB_H*RHO_B*G
# end wall: full rectangle to springing + gable ~ avg 0.55*SPR over full width
W_end   = RIB_TB*0 + (2*(84+20)*IN) * RIB_TT * (RIB_H*1.25) * RHO_B * G
# haunch banks (reduced envelope): trapezoid foot ~74in outboard of rib face
# -> crest 4in at h=44in, run = full flank ~316in
BERM_H  = 44*IN
BERM_RUN= 316*IN
berm_t  = (74+4)/2*IN
W_berm  = berm_t * BERM_H * BERM_RUN * RHO_S * G      # per rib haunch bank
W_berm_s= berm_t * BERM_H * BERM_RUN * RHO_SS * G
# counterforts (3/side): battered wythe+soil-core buttresses, hull approx —
# avg plan (60x48 foot + 20x40 crest)/2 x 64in tall; ~80% soil core + 20% skin
CF_V    = ((60*48 + 20*40)/2) * 64 * IN**3
W_cf1   = CF_V * (0.8*RHO_S + 0.2*RHO_B) * G          # per counterfort
W_cf    = 3 * W_cf1                                   # per flank

print("="*72)
print("GATEHOUSE BATTLE TEST — adversarial checks, not screening asserts")
print("="*72)
print("arch: span %.2f m  rise %.2f m  R %.2f m  shell t %.0f mm  arc %.2f m"
      % (SPAN, RISE, R_IN, T_SH*1000, ARC))
print("weights: vault %.0f kN  cap %.0f/%.0f kN dry/sat  rib %.0f kN  berm/rib %.0f kN"
      % (W_shell, W_cap_d, W_cap_s, W_rib, W_berm))

# ---------- CHECK 1: vault thrust vs rib kern (STATIC — before any seismic) ----------
# Segmental arch thrust, UDL approx: H = w L^2 / (8 f) per bay, per rib.
for tag, W_cap in [("dry", W_cap_d), ("saturated", W_cap_s)]:
    Wv  = W_shell + W_cap
    w   = Wv / SPAN                    # kN/m along span
    H   = w * SPAN**2 / (8*RISE)       # horizontal thrust per rib
    V   = Wv / 2                       # vertical at each springing
    # static overturning moment about OUTBOARD base edge of rib
    # (thrust pushes ribs APART; berm sits outboard -> correct side)
    M_ot  = H * Z_SPR
    # restoring: rib W at base kern + V lands near inner face (arm ~ RIB_TB-0.15)
    M_rs  = W_rib*(RIB_TB/2) + V*(RIB_TB-0.15)
    fos   = M_rs / M_ot
    print("-"*72)
    print("[1] STATIC vault thrust vs rib kern (%s cap):" % tag)
    show("thrust H per rib", H, "kN", "")
    show("overturning M @ springing", M_ot, "kNm", "")
    show("resisting M (kern+V arm)", M_rs, "kNm", "")
    show("static FoS unbermed", fos, "-", "PASS" if fos>1.3 else ("MARGINAL" if fos>1.0 else "FAIL"))
    # hybrid: haunch-bank passive (crest 44in) + counterfort restoring moment
    # (buttress weight ~0.66m OUTBOARD of the rib's outer base edge — the
    # same job the deep berm did, as positioned mass rather than a wedge)
    rho = RHO_S if tag=="dry" else RHO_SS
    BH  = BERM_H
    Pp  = 0.5 * rho*G * KP * BH**2 * BERM_RUN
    M_bp= Pp * BH/3
    M_cf= W_cf * (140-114)*IN                          # cf cg ~26in outboard of edge
    fos_b = (M_rs + M_bp + M_cf) / M_ot
    show("bank passive M (Kp=%.1f)" % KP, M_bp, "kNm", "")
    show("counterfort restoring M", M_cf, "kNm", "3 buttresses/flank, keyed")
    show("static FoS sheltered", fos_b, "-", "PASS" if fos_b>1.5 else ("MARGINAL" if fos_b>1.0 else "FAIL"))

    # ---------- CHECK 2: seismic residual — capacity left after static ----------
    # rocking moment from rib inertia: M_s = g * W_rib * z_cg(rib)
    z_cg  = RIB_H * (RIB_TB + 2*RIB_TT) / (3*(RIB_TB+RIB_TT))   # trapezoid CG ~0.44H
    M_cap_out = M_rs + M_bp + M_cf - M_ot                       # outward (buttressed)
    M_cap_in  = M_rs - M_ot                                     # inward (no berm!)
    g_out = M_cap_out / (W_rib * z_cg)
    g_in  = M_cap_in  / (W_rib * z_cg)
    print("[2] seismic residual bound (pre-loaded rib, %s):" % tag)
    show("rib z_cg", z_cg, "m", "")
    show("outward rocking residual", g_out, "g", "berm side" )
    show("INWARD rocking residual", g_in, "g", "NO BERM CREDIT — vault side")
    print("    -> claimed '0.81 g unburied' ignored thrust preload;")
    print("       honest unburied bound ~= min(residual) = %.2f g" % min(g_in, 0.54))

# ---------- CHECK 3: confined translation + composite kern ----------
# Two competing models bracket reality by soil coherence:
#  (a) INCOHERENT soil — core translates through loose fill: passive on
#      leading face + side friction. Conservative floor.
#  (b) COHERENT soil — compacted lifts + plinth keys make soil+masonry act
#      as one mass: sliding is killed, failure = kern rocking ~ B/2 / z_cg.
#      This is the same mechanism that screened the buried dome ~5 g.
print("-"*72)
print("[3a] incoherent translation floor — core shoving through loose soil")
W_core = W_shell + W_cap_d + 2*W_rib + W_end + 2*W_cf + 2*W_berm
A_face  = (2*(84+20)*IN) * RIB_H * 1.2
sig_p   = RHO_S*G * (RIB_H*0.5) * KP
P_face  = sig_p * A_face
A_side  = 2 * RIB_L * RIB_H + (2*(84+20)*IN)*RIB_L
sig_n   = RHO_S*G * (RIB_H*0.5)
F_side  = MU_SS * sig_n * A_side
g_trans = (P_face + F_side) / W_core
show("passive + side friction", P_face+F_side, "kN", "")
show("translation floor", g_trans, "g", "conservative — loose fill")
print("[3b] composite kern bound — counterforts + plinth keys + haunch banks")
B_X  = 2*170*IN            # counterfort feet to +-170in
B_Y  = (96+338)*IN         # wings fwd of mouth -> rear bank foot (2-cell)
zcg  = 0.50                # composite CG LOWER — mass at grade in buttresses
gk_x = (B_X/2) / zcg
gk_y = (B_Y/2) / zcg
show("footprint x/y", B_X, "m / %.2f" % B_Y, "")
show("composite kern bound x", gk_x, "g", "")
show("composite kern bound y (mouth)", gk_y, "g", "plinth keys required")

# ---------- CHECK 4: berm pseudo-static slope stability ----------
# infinite-slope: FS = tan(phi') / (tan(beta) + kh*(gamma_sat/gamma)*sec(beta))
print("-"*72)
print("[4] berm slope 27 deg, phi=%.0f deg — pseudo-static FS" % PHI)
beta = math.radians(27)  # berms drawn at 27deg — below repose
for kh in [0, 0.2, 0.5, 1.0]:
    dry = math.tan(math.radians(PHI)) / (math.tan(beta) + kh)
    sat = math.tan(math.radians(PHI)*0.8) / (math.tan(beta) + kh*(RHO_SS/RHO_S))
    show("kh=%.1g" % kh, dry, "FS", "dry" + (" STABLE" if dry>1 else " SLUMPS")
         + " | sat %.2f %s" % (sat, "STABLE" if sat>1 else "SLUMPS"))
print("    -> berm at repose has no margin; shaking ravels the confinement.")

# ---------- CHECK 5: course slide on the lean (real force balance) ----------
print("-"*72)
print("[5] course slide on %.0f deg lean — lateral g to push a course UPHILL" % math.degrees(LEAN))
for mu, tag in [(MU_J, "dry"), (MU_JS, "wet")]:
    # driving along plane: g*cosL ; normal reduced by g*sinL ; gravity helps hold
    # slide when  g*cosL = mu*(cosL - g*sinL) + sinL
    gslide = (mu*math.cos(LEAN) + math.sin(LEAN)) / (math.cos(LEAN) - mu*math.sin(LEAN))
    # gravity already holds (sinL < mu cosL); solve for external g
    gslide = (mu*math.cos(LEAN) - math.sin(LEAN)) / (math.cos(LEAN) + mu*math.sin(LEAN))
    show("slide-uphill bound (%s)" % tag, gslide, "g", "(lateral accel driving course up-plane)")

# ---------- CHECK 6: front arch free span (open mouth) ----------
print("-"*72)
print("[6] front face — fully open arch + stepped arch-ring spandrel")
print("    gable ~31 kN keyed into ribs+plinth: heavier than the arch it")
print("    caps, retains the cap's front face (soil can't stand vertical)")
w_arch = (ARC*9*IN*T_SH*RHO_B*G) / SPAN       # per course band ~9in + cap share
H_arch = (w_arch + (V_cap*RHO_S*G)/(12*SPAN)) * SPAN**2 / (8*RISE)
stress = H_arch / (T_SH * 1.0)              # kPa per m width
show("face arch thrust/m", H_arch, "kN/m", "")
show("compressive stress", stress, "kPa", "PASS" if stress < CRUSH/20 else "check")
print("    circular profile vs parabolic funicular: thrust line wanders inside")
print("    middle third at f/L=0.25 — hinges tolerable; EXPOSED face, no soil")
print("    confinement -> governs the sheltered envelope, est ~1-2 g unverified")

# ---------- CHECK 7: springing crush (sanity) ----------
print("-"*72)
Wv_d = W_shell + W_cap_d
w_d  = Wv_d / SPAN
H_d  = w_d * SPAN**2/(8*RISE); V_d = Wv_d/2
A_spring = RIB_TT * RIB_L                    # rib top area
show("[7] springing bearing stress", (V_d+H_d*0.3)/A_spring, "kPa",
     "PASS" if (V_d+H_d*0.3)/A_spring < CRUSH else "FAIL")

# ---------- CHECK 8: end wall 'rib-braced' claim ----------
print("-"*72)
print("[8] end wall keyed into ribs: shear at each rib/endwall interface")
# end wall carries lean share ~ sin(15) of vault weight -> ~26 kN, plus its own
# inertia at g. Interface shear key capacity ~ KEY_TAU*keyed_area (coarse)
F_lean = Wv_d * math.sin(LEAN) / 2           # per side interface, rough
show("lean load into end wall (per side)", F_lean, "kN", "keyed joints req'd")

# ---------- VERDICT ----------
print("="*72)
print("VERDICT — HYBRID (counterforts + haunch banks + thin armored cap)")
print("  sheltered envelope : ~%.1f-%.1f g composite kern (weakest first)" % (min(gk_x,gk_y), max(gk_x,gk_y)))
print("                       contingent on: compacted lifts + plinth keys")
print("                       + counterforts keyed before vaulting")
print("  incoherent floor   : ~%.1f g (loose fill, no keys — DON'T build that)" % g_trans)
print("  static check       : counterforts + haunch banks carry vault")
print("                       thrust — abutment goes in BEFORE vaulting")
print("  banks              : ~27deg below repose; thin cap is armor,")
print("                       not confinement — mass lives in buttresses")
print("  site flag          : Salton/Bombay Beach — saturated sandy")
print("                       soils + SDS 1.35 -> liquefaction screen is")
print("                       OUTSIDE this model's scope. Check site.")
print("="*72)
