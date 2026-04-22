// Expeditions view — M001 spec
// 2 expedition cards + in-progress bar + prestige section

function ExpeditionsView() {
  const [active, setActive] = React.useState('iron'); // 'iron' | 'steel' | null
  const progress = 0.62;

  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: 'linear-gradient(180deg, var(--wood-deep) 0%, #0d0905 100%)',
      fontFamily: 'var(--f-ui)', color: 'var(--parch)',
      position: 'relative', overflow: 'hidden',
    }}>
      <div style={{ position: 'absolute', top: -100, left: '20%', width: 500, height: 500,
        background: 'radial-gradient(circle, rgba(255,170,90,0.08), transparent 60%)', pointerEvents: 'none' }} />

      {/* Top bar */}
      <div className="hm-iron-panel" style={{ display: 'flex', alignItems: 'center', gap: 16,
        padding: '8px 14px', borderBottom: '2px solid #000', position: 'relative', zIndex: 2, height: 50, boxSizing: 'border-box' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <HammerIcon size={22} />
          <span style={{ fontFamily: 'var(--f-display)', fontSize: 18, fontWeight: 700, letterSpacing: 1,
            color: 'var(--brass-hi)', textShadow: '0 1px 0 #000' }}>HAMMERTIME</span>
        </div>
        <div style={{ width: 1, height: 20, background: 'var(--iron-deep)' }} />
        <ExTab>The Forge</ExTab>
        <ExTab active>Expeditions</ExTab>
        <ExTab>Prestige</ExTab>
        <div style={{ flex: 1 }} />
        <ExTab>Settings</ExTab>
      </div>

      <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, padding: 20, minHeight: 0, alignContent: 'start' }}>

        {/* Expedition 1 — Iron Quarry */}
        <ExpeditionCard
          name="Iron Quarry"
          flavor="A collapsed surface mine. The veins run shallow but the ore is plentiful."
          difficulty={1}
          material="Iron"
          etaSec={10}
          rewards={[
            { label: 'Iron item bases',  detail: '1–2 per run' },
            { label: 'Tack · Tuning',    detail: 'basic hammers' },
            { label: 'Scour',            detail: 'uncommon' },
          ]}
          active={active === 'iron'}
          disabled={active === 'steel'}
          progress={active === 'iron' ? progress : 0}
          onSend={() => setActive('iron')}
          onCancel={() => setActive(null)}
        />

        {/* Expedition 2 — Steel Depths */}
        <ExpeditionCard
          name="Steel Depths"
          flavor="The old forge-masters sunk shafts three hundred feet. Something still breathes down there."
          difficulty={3}
          material="Steel"
          etaSec={38}
          rewards={[
            { label: 'Steel item bases', detail: '1–3 per run' },
            { label: 'Forge · Grand',    detail: 'uncommon hammers' },
            { label: 'Runic · Claw',     detail: 'rare drop' },
          ]}
          active={active === 'steel'}
          disabled={active === 'iron'}
          progress={active === 'steel' ? progress : 0}
          onSend={() => setActive('steel')}
          onCancel={() => setActive(null)}
        />

        {/* Prestige moved to its own tab — see views/prestige.jsx */}
      </div>
    </div>
  );
}

function ExTab({ children, active }) {
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

function ExpeditionCard({ name, flavor, difficulty, material, etaSec, rewards, active, disabled, progress, onSend, onCancel }) {
  const etaStr = etaSec >= 60 ? `${Math.floor(etaSec / 60)}m ${etaSec % 60}s` : `${etaSec}s`;
  return (
    <div className="hm-wood-panel" style={{
      padding: 18, position: 'relative',
      border: active ? '1px solid var(--ember)' : undefined,
      boxShadow: active
        ? 'inset 0 0 30px rgba(255,140,60,0.12), 0 0 16px rgba(255,140,60,0.2), inset 0 1px 0 rgba(255,220,170,0.08), inset 0 -1px 0 rgba(0,0,0,0.4)'
        : undefined,
      opacity: disabled ? 0.55 : 1,
    }}>
      <Nails />

      {/* Header strip */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 6 }}>
        <span style={{ fontFamily: 'var(--f-mono)', fontSize: 9, color: 'var(--copper)',
          letterSpacing: 3, textTransform: 'uppercase' }}>
          {difficulty === 1 ? 'Expedition I' : 'Expedition II'}
        </span>
        <span style={{ display: 'flex', gap: 2 }}>
          {[1,2,3].map(i => (
            <span key={i} style={{
              fontSize: 14,
              color: i <= difficulty ? 'var(--ember)' : 'rgba(90,70,45,0.35)',
              textShadow: i <= difficulty ? '0 0 4px rgba(232,135,74,0.5)' : 'none',
            }}>★</span>
          ))}
        </span>
      </div>

      <div style={{ fontFamily: 'var(--f-display)', fontSize: 26, fontWeight: 600,
        color: 'var(--brass-hi)', letterSpacing: 0.3, textShadow: '0 1px 0 rgba(0,0,0,0.6)',
        marginBottom: 4 }}>
        {name}
      </div>
      <div style={{ fontFamily: 'var(--f-serif)', fontSize: 12, color: 'var(--ink-faint)',
        fontStyle: 'italic', lineHeight: 1.5, marginBottom: 14 }}>
        {flavor}
      </div>

      {/* Key facts row */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 6, marginBottom: 14 }}>
        <MetaBox label="Material" value={material} accent />
        <MetaBox label="Est. Time" value={etaStr} accent={active} num />
      </div>

      {/* Rewards */}
      <div style={{ marginBottom: 14 }}>
        <div style={{ fontFamily: 'var(--f-mono)', fontSize: 9, color: 'var(--ink-faint)',
          letterSpacing: 2, marginBottom: 6 }}>REWARDS</div>
        {rewards.map((r, i) => (
          <div key={i} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline',
            padding: '3px 0', borderBottom: '1px dotted rgba(196,155,92,0.15)', fontSize: 11 }}>
            <span style={{ color: 'var(--parch)' }}>· {r.label}</span>
            <span style={{ color: 'var(--ink-faint)', fontStyle: 'italic', fontSize: 10 }}>{r.detail}</span>
          </div>
        ))}
      </div>

      {/* Action / progress */}
      {active ? (
        <>
          <div className="hm-inset" style={{ height: 14, borderRadius: 2, overflow: 'hidden', marginBottom: 6, position: 'relative' }}>
            <div style={{ width: `${progress * 100}%`, height: '100%',
              background: 'linear-gradient(90deg, var(--ember-lo), var(--ember-hi))',
              boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.25), 0 0 8px rgba(255,140,60,0.3)',
              transition: 'width 200ms ease' }} />
            <span style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)',
              fontFamily: 'var(--f-mono)', fontSize: 10, fontWeight: 600, color: '#1a0804',
              letterSpacing: 1.5, textShadow: '0 0 4px rgba(255,200,150,0.6)' }}>
              {Math.round(progress * 100)}%
            </span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between',
            fontFamily: 'var(--f-mono)', fontSize: 10, color: 'var(--ember-hi)', letterSpacing: 1, marginBottom: 10 }}>
            <span>IN PROGRESS</span>
            <span className="num">ETA {Math.ceil(etaSec * (1 - progress))}s</span>
          </div>
          <button onClick={onCancel} style={{
            width: '100%', padding: '10px', background: 'linear-gradient(180deg, var(--iron-mid), var(--iron))',
            color: '#c48070', fontFamily: 'var(--f-serif)', fontSize: 13, fontWeight: 600,
            letterSpacing: 2, textTransform: 'uppercase', border: '1px solid #000', cursor: 'pointer',
          }}>
            Recall Hero
          </button>
        </>
      ) : (
        <button onClick={onSend} disabled={disabled} style={{
          width: '100%', padding: '12px',
          background: disabled
            ? 'linear-gradient(180deg, var(--iron-mid), var(--iron))'
            : 'linear-gradient(180deg, var(--ember-hi), var(--ember-lo))',
          color: disabled ? 'var(--ink-faint)' : '#1a0804',
          fontFamily: 'var(--f-serif)', fontSize: 14, fontWeight: 700,
          letterSpacing: 2, textTransform: 'uppercase', border: '1px solid #000',
          cursor: disabled ? 'not-allowed' : 'pointer',
          boxShadow: disabled ? 'none' : 'inset 0 1px 0 rgba(255,255,255,0.3), 0 2px 6px rgba(255,140,60,0.3)',
        }}>
          {disabled ? 'Hero Busy' : 'Send Hero ⚒'}
        </button>
      )}
    </div>
  );
}

function MetaBox({ label, value, accent, num }) {
  return (
    <div style={{
      padding: '6px 10px',
      background: 'rgba(20,12,8,0.5)',
      border: '1px solid rgba(0,0,0,0.5)',
      borderLeft: accent ? '3px solid var(--brass)' : '1px solid rgba(0,0,0,0.5)',
    }}>
      <div style={{ fontFamily: 'var(--f-mono)', fontSize: 8, color: 'var(--ink-faint)',
        letterSpacing: 1.5, textTransform: 'uppercase' }}>{label}</div>
      <div className={num ? 'num' : ''} style={{ fontFamily: num ? undefined : 'var(--f-serif)',
        fontSize: 14, color: 'var(--brass-hi)', fontWeight: 600, marginTop: 2 }}>{value}</div>
    </div>
  );
}

Object.assign(window, { ExpeditionsView });
