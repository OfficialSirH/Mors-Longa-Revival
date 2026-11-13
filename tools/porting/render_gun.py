import re, sys, matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from vox import read_vox
voxpath, xmlpath, out = sys.argv[1], sys.argv[2], sys.argv[3]
hide = set(sys.argv[4].split(',')) if len(sys.argv) > 4 and sys.argv[4] else set()
objs, pal = read_vox(voxpath)
xml = open(xmlpath, encoding='utf-8').read()
parts = re.findall(r'<vox pos="([^"]+)"[^>]*object="([^"]+)" scale="([^"]+)"', xml)
fig, axes = plt.subplots(2, 1, figsize=(16, 14))
for ax, view in zip(axes, ['side', 'top']):
    for pos, name, scale in parts:
        if name in hide: continue
        (size, vox), t, r = objs[name]
        px, py, pz = map(float, pos.split()); s = 0.1 * float(scale)
        xs, ys, cs = [], [], []
        for (vx, vy, vz, ci) in vox:
            # MagicaVoxel z-up -> Teardown y-up; centred in x/z, bottom at pos.y
            X = px + (vx - size[0] / 2 + 0.5) * s
            Y = py + (vz + 0.5) * s
            Z = pz - (vy - size[1] / 2 + 0.5) * s
            if view == 'side': xs.append(-Z); ys.append(Y)
            else: xs.append(-Z); ys.append(X)
            c = pal[ci - 1]; cs.append((c[0]/255, c[1]/255, c[2]/255))
        ax.scatter(xs, ys, c=cs, s=6, marker='s', linewidths=0)
        ax.text(sum(xs)/len(xs), sum(ys)/len(ys), name, fontsize=7, color='blue')
    ax.set_aspect('equal'); ax.set_title(view + ' view (forward = right)'); ax.grid(alpha=.3)
plt.tight_layout(); plt.savefig(out, dpi=90)
