// Settings view — M001 minimal spec
// Centered vertical stack of buttons

function SettingsView() {
  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: 'linear-gradient(180deg, var(--wood-deep) 0%, #0d0905 100%)',
      fontFamily: 'var(--f-ui)', color: 'var(--parch)',
      position: 'relative', overflow: 'hidden',
    }}>
      <div style={{ position: 'absolute', top: -100, left: '30%', width: 400, height: 400,
        background: 'radial-gradient(circle, rgba(255,170,90,0.06), transparent 60%)', pointerEvents: 'none' }} />

      {/* Top bar */}
      <div className="hm-iron-panel" style={{ display: 'flex', alignItems: 'center', gap: 16,
        padding: '8px 14px', borderBottom: '2px solid #000', position: 'relative', zIndex: 2, height: 50, boxSizing: 'border-box' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <HammerIcon size={22} />
          <span style={{ fontFamily: 'var(--f-display)', fontSize: 18, fontWeight: 700, letterSpacing: 1,
            color: 'var(--brass-hi)', textShadow: '0 1px 0 #000' }}>HAMMERTIME</span>
        </div>
        <div style={{ width: 1, height: 20, background: 'var(--iron-deep)' }} />
        <SetTab>The Forge</SetTab>
        <SetTab>Expeditions</SetTab>
        <SetTab>Prestige</SetTab>
        <div style={{ flex: 1 }} />
        <SetTab active>Settings</SetTab>
      </div>

      {/* Centered stack */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column',
        alignItems: 'center', justifyContent: 'center', padding: 20, gap: 12 }}>

        <div style={{ textAlign: 'center', marginBottom: 12 }}>
          <div style={{ fontFamily: 'var(--f-display)', fontSize: 24, fontWeight: 700, color: 'var(--brass-hi)', letterSpacing: 2 }}>
            SETTINGS
          </div>
          <div style={{ fontFamily: 'var(--f-serif)', fontSize: 12, color: 'var(--ink-faint)',
            fontStyle: 'italic', marginTop: 4 }}>
            All save data is stored locally.
          </div>
        </div>

        <div style={{ width: 380, display: 'flex', flexDirection: 'column', gap: 8 }}>
          <SetButton primary>Save Game</SetButton>
          <SetButton>New Game…</SetButton>
          <SetButton>Export Save <span style={{ fontSize: 10, color: 'var(--ink-faint)', marginLeft: 6 }}>(copies to clipboard)</span></SetButton>

          <div style={{ marginTop: 4 }}>
            <div style={{ fontFamily: 'var(--f-mono)', fontSize: 9, color: 'var(--ink-faint)',
              letterSpacing: 1.5, marginBottom: 4, paddingLeft: 2 }}>IMPORT SAVE</div>
            <div style={{ display: 'flex', gap: 6 }}>
              <input type="text" placeholder="Paste save code…" style={{
                flex: 1, padding: '10px 12px',
                background: 'var(--wood-deep)', border: '1px solid #000',
                boxShadow: 'inset 0 2px 4px rgba(0,0,0,0.5)',
                color: 'var(--parch)', fontFamily: 'var(--f-mono)', fontSize: 11, outline: 'none',
              }} />
              <button style={{
                padding: '10px 16px', background: 'linear-gradient(180deg, var(--iron-mid), var(--iron))',
                color: 'var(--parch)', fontFamily: 'var(--f-serif)', fontSize: 12, fontWeight: 600,
                letterSpacing: 1.5, textTransform: 'uppercase', border: '1px solid #000', cursor: 'pointer',
              }}>
                Import
              </button>
            </div>
          </div>
        </div>

        <div style={{ flex: 1 }} />
        <div style={{ fontFamily: 'var(--f-mono)', fontSize: 9, color: 'var(--ink-faint)',
          letterSpacing: 2, opacity: 0.6 }}>
          HAMMERTIME · v0.1.0-M001 · BUILD 2024.03.18
        </div>
      </div>
    </div>
  );
}

function SetTab({ children, active }) {
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

function SetButton({ children, primary }) {
  return (
    <button style={{
      padding: '12px 16px',
      background: primary
        ? 'linear-gradient(180deg, var(--ember-hi), var(--ember-lo))'
        : 'linear-gradient(180deg, var(--wood) 0%, var(--wood-dark) 100%)',
      color: primary ? '#1a0804' : 'var(--parch)',
      fontFamily: 'var(--f-serif)', fontSize: 14, fontWeight: 600,
      letterSpacing: 1.5, border: '1px solid ' + (primary ? '#000' : 'var(--wood-deep)'),
      cursor: 'pointer', textAlign: 'left',
      boxShadow: primary
        ? 'inset 0 1px 0 rgba(255,255,255,0.3), 0 2px 4px rgba(255,140,60,0.2)'
        : 'inset 0 1px 0 rgba(255,220,170,0.08), inset 0 -1px 0 rgba(0,0,0,0.4)',
    }}>
      {children}
    </button>
  );
}

Object.assign(window, { SettingsView });
