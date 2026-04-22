// Prestige view — M001 spec
// The Reforging: spend 100 Tack Hammers → receive 999 of every hammer.
// A big-moment screen. Ritual typography, centered, dramatic ember glow.

const M001_PRESTIGE_HAMMERS = [
  { key: 'tack',   glyph: '⬦', name: 'Tack',    have: 47,  get: 999 },
  { key: 'tuning', glyph: '◈', name: 'Tuning',  have: 142, get: 999 },
  { key: 'forge',  glyph: '◆', name: 'Forge',   have: 68,  get: 999 },
  { key: 'grand',  glyph: '✦', name: 'Grand',   have: 18,  get: 999 },
  { key: 'runic',  glyph: '⚒', name: 'Runic',   have: 4,   get: 999, rare: true },
  { key: 'scour',  glyph: '◎', name: 'Scour',   have: 11,  get: 999 },
  { key: 'claw',   glyph: '✕', name: 'Claw',    have: 3,   get: 999 },
];

function PrestigeView() {
  const have = 47;
  const need = 100;
  const pct = Math.min(100, Math.round(have / need * 100));
  const ready = have >= need;

  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: 'linear-gradient(180deg, #120a06 0%, #080503 100%)',
      fontFamily: 'var(--f-ui)', color: 'var(--parch)',
      position: 'relative', overflow: 'hidden',
    }}>
      {/* Atmospheric ember glows */}
      <div style={{ position: 'absolute', top: '40%', left: '50%', transform: 'translate(-50%, -50%)',
        width: 900, height: 900, pointerEvents: 'none',
        background: 'radial-gradient(circle, rgba(255,140,60,0.08) 0%, transparent 60%)' }} />
      <div style={{ position: 'absolute', top: '30%', left: '15%', width: 400, height: 400,
        background: 'radial-gradient(circle, rgba(255,170,90,0.06), transparent 60%)', pointerEvents: 'none' }} />

      {/* Top bar — same pattern as other screens */}
      <div className="hm-iron-panel" style={{ display: 'flex', alignItems: 'center', gap: 16,
        padding: '8px 14px', borderBottom: '2px solid #000', position: 'relative', zIndex: 2,
        height: 50, boxSizing: 'border-box', flexShrink: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <HammerIcon size={22} />
          <span style={{ fontFamily: 'var(--f-display)', fontSize: 18, fontWeight: 700, letterSpacing: 1,
            color: 'var(--brass-hi)', textShadow: '0 1px 0 #000' }}>HAMMERTIME</span>
        </div>
        <div style={{ width: 1, height: 20, background: 'var(--iron-deep)' }} />
        <PrTab>The Forge</PrTab>
        <PrTab>Expeditions</PrTab>
        <PrTab active>Prestige</PrTab>
        <div style={{ flex: 1 }} />
        <PrTab>Settings</PrTab>
      </div>

      {/* Body — centered ritual composition */}
      <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '1fr 580px 1fr', gap: 24,
        padding: '24px 28px', minHeight: 0, position: 'relative', zIndex: 1 }}>

        {/* LEFT — pre-reforge state (what you lose) */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10, minHeight: 0 }}>
          <IronHeader right="CURRENT RUN">You Will Sacrifice</IronHeader>
          <div className="hm-wood-panel" style={{ padding: 14, position: 'relative', flex: 1,
            display: 'flex', flexDirection: 'column', gap: 10 }}>
            <Nails />
            <SacRow label="All crafted items" value="8" sub="5 magic · 2 rare · 1 normal" />
            <SacRow label="Iron ore" value="284" sub="stockpile" />
            <SacRow label="Steel ingots" value="41" sub="stockpile" />
            <SacRow label="Expedition progress" value="—" sub="Iron Quarry runs reset" />
            <div style={{ flex: 1 }} />
            <div style={{ padding: 10, borderTop: '1px dotted rgba(196,155,92,0.18)',
              fontFamily: 'var(--f-serif)', fontSize: 11, fontStyle: 'italic',
              color: 'var(--ink-faint)', lineHeight: 1.5, textAlign: 'center' }}>
              The anvil does not remember. <br/> Only the hammer endures.
            </div>
          </div>
        </div>

        {/* CENTER — the ritual */}
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 16, minHeight: 0 }}>

          {/* Section title */}
          <div style={{ textAlign: 'center', paddingTop: 4 }}>
            <div style={{ fontFamily: 'var(--f-mono)', fontSize: 10, letterSpacing: 4,
              color: 'var(--copper)', textTransform: 'uppercase', marginBottom: 4 }}>
              ◆ The Reforging ◆
            </div>
            <div style={{ fontFamily: 'var(--f-display)', fontSize: 38, fontWeight: 700,
              color: 'var(--brass-hi)', letterSpacing: 2, lineHeight: 1,
              textShadow: '0 0 18px rgba(255,140,60,0.25), 0 2px 0 #000' }}>
              PRESTIGE
            </div>
            <div style={{ fontFamily: 'var(--f-serif)', fontSize: 12, fontStyle: 'italic',
              color: 'var(--parch)', marginTop: 6, lineHeight: 1.5, maxWidth: 440, margin: '6px auto 0' }}>
              Melt your works back to slag. The forge remembers only your craft —
              and rewards patience with a new beginning.
            </div>
          </div>

          {/* The gauge — giant Tack counter */}
          <div style={{ width: '100%', padding: '18px 22px',
            background: 'linear-gradient(180deg, rgba(30,18,10,0.6), rgba(14,8,5,0.75))',
            border: '1px solid #000',
            boxShadow: `inset 0 0 36px ${ready ? 'rgba(255,140,60,0.25)' : 'rgba(196,155,92,0.08)'},
              inset 0 1px 0 rgba(196,155,92,0.18), 0 2px 8px rgba(0,0,0,0.6)`,
            position: 'relative' }}>
            <Nails />

            <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
              fontFamily: 'var(--f-mono)', fontSize: 9, letterSpacing: 2,
              color: 'var(--ink-faint)', marginBottom: 10 }}>
              <span>TACK HAMMERS · THRESHOLD</span>
              <span>{pct}%</span>
            </div>

            <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'center',
              gap: 10, marginBottom: 12 }}>
              <span className="num" style={{
                fontFamily: 'var(--f-display)', fontSize: 72, fontWeight: 700, lineHeight: 0.9,
                color: ready ? 'var(--ember-hi)' : 'var(--brass-hi)',
                textShadow: ready
                  ? '0 0 24px rgba(255,140,60,0.55), 0 2px 0 #000'
                  : '0 2px 0 #000',
              }}>{have}</span>
              <span style={{ fontFamily: 'var(--f-serif)', fontSize: 26, fontWeight: 400,
                color: 'var(--ink-faint)' }}>/</span>
              <span className="num" style={{ fontFamily: 'var(--f-display)', fontSize: 36, fontWeight: 600,
                color: 'var(--ink-faint)' }}>{need}</span>
            </div>

            {/* progress bar — bigger than the old one */}
            <div className="hm-inset" style={{ height: 18, borderRadius: 2, overflow: 'hidden',
              position: 'relative' }}>
              <div style={{ width: `${pct}%`, height: '100%',
                background: ready
                  ? 'linear-gradient(90deg, var(--ember-lo), var(--ember-hi))'
                  : 'linear-gradient(90deg, var(--brass-lo), var(--brass-hi))',
                boxShadow: ready
                  ? 'inset 0 1px 0 rgba(255,255,255,0.3), 0 0 12px rgba(255,140,60,0.4)'
                  : 'inset 0 1px 0 rgba(255,255,255,0.2)',
                transition: 'width 300ms ease' }} />
              {/* threshold tick marks */}
              {[25, 50, 75].map(p => (
                <div key={p} style={{ position: 'absolute', left: `${p}%`, top: 0, bottom: 0,
                  width: 1, background: 'rgba(0,0,0,0.4)' }} />
              ))}
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between',
              fontFamily: 'var(--f-mono)', fontSize: 10, letterSpacing: 1,
              color: ready ? 'var(--ember-hi)' : 'var(--ink-faint)', marginTop: 8 }}>
              <span>{ready ? '◆ READY TO REFORGE' : `${need - have} MORE NEEDED`}</span>
              <span>~{Math.ceil((need - have) / 4)} EXPEDITIONS</span>
            </div>
          </div>

          {/* The button */}
          <button disabled={!ready} style={{
            width: '100%', padding: '18px 24px',
            background: ready
              ? 'linear-gradient(180deg, var(--ember-hi), var(--ember-lo))'
              : 'linear-gradient(180deg, var(--iron-mid), var(--iron))',
            color: ready ? '#1a0804' : 'var(--ink-faint)',
            fontFamily: 'var(--f-serif)', fontSize: 18, fontWeight: 700,
            letterSpacing: 4, textTransform: 'uppercase',
            border: '1px solid #000',
            cursor: ready ? 'pointer' : 'not-allowed',
            opacity: ready ? 1 : 0.7,
            boxShadow: ready
              ? 'inset 0 1px 0 rgba(255,255,255,0.35), 0 0 24px rgba(255,140,60,0.4), 0 3px 8px rgba(0,0,0,0.5)'
              : 'inset 0 1px 0 rgba(255,255,255,0.05)',
          }}>
            {ready ? 'Reforge · Claim the 999' : 'Reforge ⚒ (Locked)'}
          </button>
          <div style={{ fontFamily: 'var(--f-mono)', fontSize: 9, color: 'var(--ink-faint)',
            letterSpacing: 2, textTransform: 'uppercase', textAlign: 'center' }}>
            Prestige count · <span style={{ color: 'var(--brass-hi)' }}>0</span> · first reforge
          </div>
        </div>

        {/* RIGHT — the reward: 999 of every hammer */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10, minHeight: 0 }}>
          <IronHeader right="×7 HAMMERS">You Will Receive</IronHeader>
          <div className="hm-wood-panel" style={{ padding: 10, position: 'relative', flex: 1,
            display: 'flex', flexDirection: 'column', gap: 5, overflow: 'hidden' }}>
            <Nails />
            {M001_PRESTIGE_HAMMERS.map(h => (
              <RewardRow key={h.key} hammer={h} />
            ))}
            <div style={{ padding: '8px 4px 2px', borderTop: '1px dotted rgba(196,155,92,0.18)',
              fontFamily: 'var(--f-mono)', fontSize: 9, color: 'var(--ember-hi)',
              letterSpacing: 2, textAlign: 'center', marginTop: 'auto' }}>
              TOTAL · <span className="num" style={{ fontSize: 14, fontWeight: 700 }}>6,993</span> HAMMERS
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function SacRow({ label, value, sub }) {
  return (
    <div style={{ display: 'flex', alignItems: 'baseline', gap: 10,
      padding: '6px 0', borderBottom: '1px dotted rgba(196,155,92,0.12)' }}>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontFamily: 'var(--f-serif)', fontSize: 13, color: 'var(--parch)' }}>{label}</div>
        <div style={{ fontFamily: 'var(--f-mono)', fontSize: 9, color: 'var(--ink-faint)',
          letterSpacing: 1, marginTop: 1 }}>{sub}</div>
      </div>
      <span className="num" style={{ fontFamily: 'var(--f-display)', fontSize: 20,
        color: 'var(--ink-faint)', fontWeight: 600,
        textDecoration: value !== '—' ? 'line-through' : 'none',
        textDecorationColor: 'rgba(180,120,90,0.6)',
        textDecorationThickness: '1px' }}>{value}</span>
    </div>
  );
}

function RewardRow({ hammer }) {
  const glyphCol = hammer.rare ? 'var(--r-rare-hi)' : 'var(--brass-hi)';
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10,
      padding: '5px 6px',
      background: 'linear-gradient(180deg, rgba(40,26,16,0.5), rgba(14,9,6,0.6))',
      border: '1px solid rgba(196,155,92,0.15)',
      borderLeft: '2px solid var(--ember-lo)' }}>
      {/* Glyph placeholder — matches Forge hammer rail */}
      <div style={{
        width: 32, height: 32, flexShrink: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: 'radial-gradient(circle at 50% 30%, rgba(232,135,74,0.22), rgba(20,15,10,0.4))',
        border: '1px solid rgba(232,135,74,0.4)',
        boxShadow: 'inset 0 1px 0 rgba(180,140,90,0.18), inset 0 -1px 0 rgba(0,0,0,0.5)',
      }}>
        <span style={{
          fontSize: 18, lineHeight: 1, color: glyphCol,
          textShadow: '0 0 8px rgba(255,170,90,0.6)',
        }}>{hammer.glyph}</span>
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontFamily: 'var(--f-serif)', fontSize: 12, fontWeight: 600,
          color: hammer.rare ? 'var(--r-rare-hi)' : 'var(--parch)', lineHeight: 1.1 }}>{hammer.name} Hammer</div>
        <div style={{ fontFamily: 'var(--f-mono)', fontSize: 8, color: 'var(--ink-faint)',
          letterSpacing: 1, marginTop: 2 }}>
          HAVE <span className="num" style={{ color: 'var(--brass-hi)' }}>{hammer.have}</span>
          <span style={{ padding: '0 4px', color: 'var(--ember-hi)' }}>→</span>
          <span className="num" style={{ color: 'var(--ember-hi)' }}>{hammer.get}</span>
        </div>
      </div>
      <span className="num" style={{ fontFamily: 'var(--f-display)', fontSize: 18, fontWeight: 700,
        color: 'var(--ember-hi)', textShadow: '0 0 6px rgba(255,140,60,0.4)' }}>+{hammer.get - hammer.have}</span>
    </div>
  );
}

function PrTab({ children, active }) {
  return (
    <div style={{
      padding: '4px 10px', fontFamily: 'var(--f-serif)', fontSize: 13, letterSpacing: 0.5,
      color: active ? 'var(--brass-hi)' : 'var(--ink-faint)',
      borderBottom: active ? '2px solid var(--brass)' : '2px solid transparent',
      textShadow: active ? '0 0 8px rgba(232,168,90,0.3)' : 'none',
      cursor: 'pointer',
    }}>{children}</div>
  );
}

Object.assign(window, { PrestigeView });
