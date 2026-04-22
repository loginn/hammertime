// Shared Hammertime primitives — panels, placeholders, labels, icons.

// ─── Placeholder box (for art we don't have) ───
function Ph({ label, w, h, style }) {
  return (
    <div className="hm-placeholder" style={{ width: w, height: h, ...style }}>
      {label}
    </div>
  );
}

// ─── Rarity-colored item name ───
function ItemName({ rarity = 'normal', children, size = 14 }) {
  return (
    <div className={`rar-${rarity}`} style={{
      fontFamily: 'var(--f-serif)', fontWeight: 600, fontSize: size,
      letterSpacing: 0.2, textShadow: '0 1px 0 rgba(0,0,0,.6)',
    }}>{children}</div>
  );
}

// ─── Stat row (label · value) ───
function Stat({ label, value, tone = 'normal' }) {
  const tones = {
    normal: { l: 'var(--ink-mid)', v: 'var(--ink)' },
    magic: { l: 'var(--ink-mid)', v: 'var(--r-magic)' },
    rare: { l: 'var(--ink-mid)', v: 'var(--r-unique)' },
    mod: { l: 'var(--ink-mid)', v: 'var(--r-magic)' },
  };
  const t = tones[tone] || tones.normal;
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline',
      padding: '3px 0', borderBottom: '1px dotted rgba(90,60,30,0.18)', fontSize: 12 }}>
      <span style={{ color: t.l, fontFamily: 'var(--f-ui)' }}>{label}</span>
      <span className="num" style={{ color: t.v, fontSize: 12, fontWeight: 500 }}>{value}</span>
    </div>
  );
}

// ─── Section header with hammered-iron plate ───
function IronHeader({ children, right, size = 13 }) {
  return (
    <div className="hm-iron-panel" style={{
      padding: '6px 10px', display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      color: 'var(--parch)', fontFamily: 'var(--f-serif)', fontWeight: 600, fontSize: size,
      letterSpacing: 0.8, textTransform: 'uppercase',
      textShadow: '0 1px 0 rgba(0,0,0,.8)',
    }}>
      <span>{children}</span>
      {right && <span style={{ fontFamily: 'var(--f-mono)', fontSize: 10, color: 'var(--brass-hi)', textTransform: 'none', letterSpacing: 0 }}>{right}</span>}
    </div>
  );
}

// ─── Corner nails for panels ───
function Nails({ inset = 6 }) {
  return (
    <>
      <div className="hm-nail" style={{ position: 'absolute', top: inset, left: inset }} />
      <div className="hm-nail" style={{ position: 'absolute', top: inset, right: inset }} />
      <div className="hm-nail" style={{ position: 'absolute', bottom: inset, left: inset }} />
      <div className="hm-nail" style={{ position: 'absolute', bottom: inset, right: inset }} />
    </>
  );
}

// ─── Hammer SVG icon (simple, geometric) ───
function HammerIcon({ size = 28, tone = '#c4a574', handle = '#6b4c32' }) {
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" fill="none">
      {/* handle */}
      <rect x="14.5" y="13" width="3" height="17" rx="1" fill={handle} stroke="#000" strokeWidth="0.7"/>
      {/* head */}
      <rect x="6" y="6" width="20" height="8" rx="1" fill={tone} stroke="#000" strokeWidth="0.8"/>
      <rect x="6" y="6" width="20" height="2" fill="rgba(255,255,255,0.18)"/>
      <rect x="6" y="12" width="20" height="2" fill="rgba(0,0,0,0.35)"/>
      {/* pommel */}
      <circle cx="16" cy="30" r="1.5" fill={handle} stroke="#000" strokeWidth="0.5"/>
    </svg>
  );
}

// ─── Currency orb (round, glossy) ───
function Orb({ size = 28, hue = 35, chroma = 0.14, L = 0.6 }) {
  const base = `oklch(${L} ${chroma} ${hue})`;
  const hi = `oklch(${L + 0.18} ${chroma} ${hue})`;
  const lo = `oklch(${L - 0.15} ${chroma + 0.02} ${hue})`;
  return (
    <svg width={size} height={size} viewBox="0 0 32 32">
      <defs>
        <radialGradient id={`orb-${hue}-${L}`} cx="35%" cy="32%" r="70%">
          <stop offset="0%" stopColor={hi} />
          <stop offset="55%" stopColor={base} />
          <stop offset="100%" stopColor={lo} />
        </radialGradient>
      </defs>
      <circle cx="16" cy="16" r="13" fill={`url(#orb-${hue}-${L})`} stroke="#000" strokeWidth="1" />
      <ellipse cx="12" cy="11" rx="3.5" ry="2" fill="rgba(255,255,255,0.45)" />
      <circle cx="16" cy="16" r="13" fill="none" stroke="rgba(0,0,0,0.25)" strokeWidth="0.6" />
    </svg>
  );
}

// ─── Socket (small gem slot) ───
function Socket({ color = 'r', linked = false }) {
  const colors = { r: '#c44a3a', g: '#5a9256', b: '#4a6aa0', w: '#d6c8a6' };
  return (
    <div style={{
      width: 14, height: 14, borderRadius: '50%',
      background: `radial-gradient(circle at 30% 30%, ${colors[color]}, #1a1008)`,
      border: '1px solid #000', boxShadow: 'inset 0 1px 2px rgba(0,0,0,.6)',
      position: 'relative',
    }}>
      {linked && <div style={{ position: 'absolute', left: '100%', top: '50%',
        width: 6, height: 2, background: 'var(--iron-hi)', transform: 'translateY(-50%)' }} />}
    </div>
  );
}

Object.assign(window, { Ph, ItemName, Stat, IronHeader, Nails, HammerIcon, Orb, Socket });
