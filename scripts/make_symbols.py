#!/usr/bin/env python3
"""Generate the Conjugar tab-bar custom SF Symbols (dancer, bull) from Noun Project
line art, with no vector editor.

For each artwork it parses the true bounding box (sampling the Béziers), fits it to
the reference glyph's bbox in every weight/scale slot of an SF Symbols template, and
thickens it by geometric dilation — the symbol compiler honours `fill`, not `stroke`,
so weight has to come from geometry. The dilated art is defined once in <defs> and
referenced per slot via <use> to keep each symbol small (~90 KB vs ~3 MB inline).

Inputs live in scripts/symbol-sources/; outputs are written to the asset catalog.
Regenerate with:  python3 scripts/make_symbols.py

Tunables (env vars): GROW (dilation radius, template units, default 1),
DIRS (offset directions, default 8), ROUND (emitted coord decimals, default 0).

Artwork licences (CC BY 3.0, credited in the app's Info-tab credits):
  bull           — taash5studio,     https://thenounproject.com/icon/bull-8280587/
  flamenco dance — Amethyst Studio,   https://thenounproject.com/icon/flamenco-dance-4581460/
The SF Symbols template is exported from Apple's SF Symbols.app (gearshape, Static).
"""
import re, os, json, math

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "symbol-sources")
CATALOG = os.path.join(HERE, os.pardir, "Conjugar", "Assets.xcassets")

GROW = float(os.environ.get("GROW", "1"))    # dilation radius, template units (Regular-M)
DIRS = int(os.environ.get("DIRS", "8"))       # offset directions (disk approximation)
ROUND = int(os.environ.get("ROUND", "0"))     # coord decimals in emitted art
TOK = re.compile(r'[MmLlHhVvCcSsQqTtAaZz]|-?\d*\.?\d+(?:[eE][-+]?\d+)?')
NUM = re.compile(r'-?\d*\.?\d+(?:[eE][-+]?\d+)?')

def fmt(v):
    return f"{v:.4f}".rstrip('0').rstrip('.')

def round_d(d, nd):
    return NUM.sub(lambda m: fmt(round(float(m.group()), nd)), d)

def path_points(d):
    toks = TOK.findall(d); i = 0; pts = []
    cx = cy = sx = sy = 0.0; cmd = None; pc = None
    def n():
        nonlocal i; v = float(toks[i]); i += 1; return v
    def cubic(x1, y1, x2, y2, x, y):
        for t in (0, .15, .3, .45, .6, .75, .9, 1):
            m = 1 - t
            pts.append((m**3*cx+3*m*m*t*x1+3*m*t*t*x2+t**3*x,
                        m**3*cy+3*m*m*t*y1+3*m*t*t*y2+t**3*y))
    while i < len(toks):
        if re.match(r'[A-Za-z]', toks[i]):
            cmd = toks[i]; i += 1
        if cmd in ('M','m'):
            x=n(); y=n()
            if cmd=='m': x+=cx; y+=cy
            cx,cy=x,y; sx,sy=x,y; pts.append((cx,cy)); cmd='l' if cmd=='m' else 'L'; pc=None
        elif cmd in ('L','l'):
            x=n(); y=n()
            if cmd=='l': x+=cx; y+=cy
            cx,cy=x,y; pts.append((cx,cy)); pc=None
        elif cmd in ('H','h'):
            x=n(); cx = cx+x if cmd=='h' else x; pts.append((cx,cy)); pc=None
        elif cmd in ('V','v'):
            y=n(); cy = cy+y if cmd=='v' else y; pts.append((cx,cy)); pc=None
        elif cmd in ('C','c'):
            x1=n();y1=n();x2=n();y2=n();x=n();y=n()
            if cmd=='c': x1+=cx;y1+=cy;x2+=cx;y2+=cy;x+=cx;y+=cy
            cubic(x1,y1,x2,y2,x,y); pc=(x2,y2); cx,cy=x,y
        elif cmd in ('S','s'):
            x2=n();y2=n();x=n();y=n()
            if cmd=='s': x2+=cx;y2+=cy;x+=cx;y+=cy
            x1,y1 = (2*cx-pc[0],2*cy-pc[1]) if pc else (cx,cy)
            cubic(x1,y1,x2,y2,x,y); pc=(x2,y2); cx,cy=x,y
        elif cmd in ('Z','z'):
            cx,cy=sx,sy; pc=None
        else:
            i += 1
    return pts

def bbox(pts):
    xs=[p[0] for p in pts]; ys=[p[1] for p in pts]
    return min(xs),min(ys),max(xs),max(ys)

def slot_fit(ref_d, aw, ah, acx, acy, scale):
    tx0,ty0,tx1,ty1 = bbox(path_points(ref_d))
    s = min((tx1-tx0)/aw, (ty1-ty0)/ah) * scale     # `contain`, then per-symbol scale
    tcx,tcy = (tx0+tx1)/2, (ty0+ty1)/2
    return s, tcx - s*acx, tcy - s*acy               # re-centre on the reference bbox

def main(artwork, out_name, scale=1.0):
    tpl = open(os.path.join(SRC, "gearshape-template.svg"), encoding="utf-8").read()
    art = open(os.path.join(SRC, artwork), encoding="utf-8").read()
    art_ds = re.findall(r'\sd="([^"]+)"', art)
    ax0,ay0,ax1,ay1 = bbox([p for d in art_ds for p in path_points(d)])
    aw,ah,acx,acy = ax1-ax0, ay1-ay0, (ax0+ax1)/2, (ay0+ay1)/2

    slot_re = re.compile(r'(<g id="([A-Za-z]+)-([SML])" transform="[^"]*">)(.*?)(</g>)', re.DOTALL)

    # Regular-M scale (includes the per-symbol scale) → bake the dilation radius in art
    # units so the final growth is GROW template units regardless of the symbol scale.
    sreg = None
    for m in slot_re.finditer(tpl):
        if m.group(2)=="Regular" and m.group(3)=="M":
            sreg,_,_ = slot_fit(re.search(r'd="([^"]+)"', m.group(4)).group(1), aw, ah, acx, acy, scale)
    r = GROW / sreg

    core = "".join(f'<path d="{round_d(d, ROUND)}"/>' for d in art_ds)
    copies = [core]
    for k in range(DIRS):
        a = 2*math.pi*k/DIRS
        copies.append(f'<g transform="translate({fmt(r*math.cos(a))} {fmt(r*math.sin(a))})">{core}</g>')
    aid = f"{out_name}_art"
    defs = f'<defs><g id="{aid}" fill="#000000">{"".join(copies)}</g></defs>'

    def repl(m):
        head, w, sc, inner, tail = m.groups()
        ref = re.search(r'd="([^"]+)"', inner)
        if not ref:
            return m.group(0)
        s, mx, my = slot_fit(ref.group(1), aw, ah, acx, acy, scale)
        use = f'<use xlink:href="#{aid}" transform="matrix({fmt(s)} 0 0 {fmt(s)} {fmt(mx)} {fmt(my)})"/>'
        return f'{head}\n   {use}\n  {tail}'
    new, n = slot_re.subn(repl, tpl)
    new = new.replace("</style>", "</style>\n " + defs, 1)

    out_dir = os.path.join(CATALOG, f"{out_name}.symbolset")
    os.makedirs(out_dir, exist_ok=True)
    open(os.path.join(out_dir, f"{out_name}.svg"), "w", encoding="utf-8").write(new)
    json.dump({"info":{"author":"xcode","version":1},
               "symbols":[{"filename":f"{out_name}.svg","idiom":"universal"}]},
              open(os.path.join(out_dir,"Contents.json"),"w"), indent=2)
    print(f"[{out_name}] {n} slots, scale={scale}, GROW={GROW}, sreg={fmt(sreg)} -> {out_dir}")

if __name__ == "__main__":
    main("noun-flamenco-dance-4581460.svg", "dancer", scale=1.0)
    main("noun-bull-8280587.svg",           "bull",   scale=1.2)  # 20% larger for legibility
