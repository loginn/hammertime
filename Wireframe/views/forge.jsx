// Main Forge view — M001 spec
// 3 columns: Hammers rail (left) · Bench + Inventory (center) · Hero panel (right)

const M001_HAMMERS = [
  { key: 'tack',   glyph: '⬦', name: 'Tack',    verb: 'Transmute',  count: 47,  effect: 'Normal → Magic. Adds 1–2 random affixes.',       target: 'Normal' },
  { key: 'tuning', glyph: '◈', name: 'Tuning',  verb: 'Alteration', count: 142, effect: 'Rerolls all affixes on a Magic item.',            target: 'Magic' },
  { key: 'forge',  glyph: '◆', name: 'Forge',   verb: 'Augment',    count: 68,  effect: 'Adds 1 random affix to an unfull Magic item.',    target: 'Magic' },
  { key: 'grand',  glyph: '✦', name: 'Grand',   verb: 'Regal',      count: 18,  effect: 'Magic → Rare. Adds 1 affix, keeps existing.',     target: 'Magic', hot: true },
  { key: 'runic',  glyph: '⚒', name: 'Runic',   verb: 'Exalt',      count: 4,   effect: 'Adds 1 random affix to an unfull Rare item.',     target: 'Rare',  rare: true },
  { key: 'scour',  glyph: '◎', name: 'Scour',   verb: 'Scour',      count: 11,  effect: 'Strips all affixes. Back to Normal.',             target: 'Any' },
  { key: 'claw',   glyph: '✕', name: 'Claw',    verb: 'Annul',      count: 3,   effect: 'Removes 1 random affix.',                          target: 'Magic / Rare' },
];

const M001_SLOTS = ['Weapon', 'Helmet', 'Armor', 'Boots', 'Ring'];

const M001_INVENTORY = [
  { id: 'w1', slot: 'Weapon', name: 'Searing Broadsword', base: 'Broadsword',  rar: 'magic',  mat: 'Steel', tier: 3, equipped: true, affixes: [{ tone: 'pre', tier: 2, text: '+62% Physical Damage' }, { tone: 'suf', tier: 3, text: 'Adds 14 to 28 Fire Damage' }] },
  { id: 'w2', slot: 'Weapon', name: 'Bitterfang',         base: 'Longsword',   rar: 'rare',   mat: 'Steel', tier: 3, affixes: [{ tone: 'pre', tier: 2, text: '+48% Physical Damage' }, { tone: 'pre', tier: 3, text: '+64 maximum Life' }, { tone: 'suf', tier: 2, text: '+22 to Strength' }, { tone: 'suf', tier: 3, text: '+8% Attack Speed' }] },
  { id: 'w3', slot: 'Weapon', name: 'Iron Cutter',        base: 'Shortsword',  rar: 'magic',  mat: 'Iron',  tier: 1, affixes: [{ tone: 'pre', tier: 3, text: '+28% Physical Damage' }] },
  { id: 'w4', slot: 'Weapon', name: 'Steel Broadsword',   base: 'Broadsword',  rar: 'normal', mat: 'Steel', tier: 3, affixes: [] },
  { id: 'w5', slot: 'Weapon', name: 'Iron Longsword',     base: 'Longsword',   rar: 'normal', mat: 'Iron',  tier: 1, affixes: [] },
  { id: 'w6', slot: 'Weapon', name: 'Gilded Cleaver',     base: 'Cleaver',     rar: 'magic',  mat: 'Steel', tier: 2, affixes: [{ tone: 'pre', tier: 3, text: '+40% Physical Damage' }, { tone: 'suf', tier: 4, text: '+12 to Dexterity' }] },
  { id: 'w7', slot: 'Weapon', name: 'Iron Shortsword',    base: 'Shortsword',  rar: 'normal', mat: 'Iron',  tier: 1, affixes: [] },
  { id: 'w8', slot: 'Weapon', name: 'Mire-Kissed Saber',  base: 'Saber',       rar: 'magic',  mat: 'Steel', tier: 2, affixes: [{ tone: 'pre', tier: 4, text: 'Adds 6 to 12 Cold Damage' }, { tone: 'suf', tier: 3, text: '+18% Cold Resistance' }] },
];

function ForgeView() {
  const [activeHammer, setActiveHammer] = React.useState('grand');
  const [activeSlot, setActiveSlot] = React.useState('Weapon');
  const [selectedItem, setSelectedItem] = React.useState('w1');

  const items = M001_INVENTORY.filter(i => i.slot === activeSlot);
  const selected = items.find(i => i.id === selectedItem) || items[0];

  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: 'linear-gradient(180deg, var(--wood-deep) 0%, #0d0905 100%)',
      fontFamily: 'var(--f-ui)', color: 'var(--parch)',
      position: 'relative', overflow: 'hidden',
    }}>
      <div style={{ position: 'absolute', top: -100, left: '20%', width: 500, height: 500,
        background: 'radial-gradient(circle, rgba(255,170,90,0.08), transparent 60%)', pointerEvents: 'none' }} />
      <div style={{ position: 'absolute', bottom: -100, right: '10%', width: 400, height: 400,
        background: 'radial-gradient(circle, rgba(255,140,60,0.06), transparent 60%)', pointerEvents: 'none' }} />

      {/* Top bar — M001 screens only */}
      <div className="hm-iron-panel" style={{ display: 'flex', alignItems: 'center', gap: 16,
        padding: '8px 14px', borderBottom: '2px solid #000', position: 'relative', zIndex: 2, height: 50, boxSizing: 'border-box' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <HammerIcon size={22} />
          <span style={{ fontFamily: 'var(--f-display)', fontSize: 18, fontWeight: 700, letterSpacing: 1,
            color: 'var(--brass-hi)', textShadow: '0 1px 0 #000' }}>HAMMERTIME</span>
        </div>
        <div style={{ width: 1, height: 20, background: 'var(--iron-deep)' }} />
        <Tab active>The Forge</Tab>
        <Tab>Expeditions</Tab>
        <Tab>Prestige</Tab>
        <div style={{ flex: 1 }} />
        <Tab>Settings</Tab>
      </div>

      {/* Body: 3 columns per M001 brief */}
      <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '250px 1fr 430px', gap: 10, padding: 10, minHeight: 0 }}>

        {/* LEFT — Hammers rail: 7 canonical in tabbed section */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6, minHeight: 0 }}>
          <IronHeader right="M001">Hammers</IronHeader>

          {/* Tabs — Basic is only M001 category; others locked/placeholder for future currency */}
          <div style={{ display: 'flex', gap: 0, marginBottom: -1 }}>
            <HammerTab active>Basic</HammerTab>
            <HammerTab locked>Elemental</HammerTab>
            <HammerTab locked>Meta</HammerTab>
          </div>

          <div className="hm-wood-panel" style={{ padding: 8, position: 'relative' }}>
            <Nails />
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 4 }}>
              {M001_HAMMERS.map(h => (
                <Hammer key={h.key}
                  active={activeHammer === h.key}
                  onClick={() => setActiveHammer(h.key)}
                  {...h} />
              ))}
              <HammerEmpty />
            </div>
          </div>

          {/* Active hammer details — selected on click */}
          <IronHeader>Selected Hammer</IronHeader>
          <div className="hm-wood-panel" style={{ padding: 10, position: 'relative' }}>
            <ActiveHammerCard hammer={M001_HAMMERS.find(h => h.key === activeHammer)} />
          </div>

          {/* Currency legend / spacer */}
          <div style={{ flex: 1 }} />
          <div style={{ padding: '8px 10px', fontFamily: 'var(--f-mono)', fontSize: 9,
            color: 'var(--ink-faint)', letterSpacing: 1, lineHeight: 1.6,
            borderTop: '1px dotted rgba(196,155,92,0.15)' }}>
            <div>◆ Tap a hammer to arm it.</div>
            <div>◆ Then tap the item to strike.</div>
          </div>
        </div>

        {/* CENTER — Bench (top) + Inventory (bottom) per M001 */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10, minHeight: 0 }}>

          {/* BENCH */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 170px 1fr', gap: 10, minHeight: 0 }}>
            {/* PREFIX rail */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              <div style={{ fontFamily: 'var(--f-mono)', fontSize: 9, color: 'var(--pre)', letterSpacing: 2,
                display: 'flex', justifyContent: 'space-between', padding: '0 4px' }}>
                <span>◆ PREFIX</span>
                <span style={{ color: 'var(--ink-faint)' }}>1 / 3</span>
              </div>
              <ScrollAffix tone="pre" tier={2} text="+62% Physical Damage"      rawRoll="55–62" rawRange="40–65" pct={0.55} />
              <ScrollAffixEmpty tone="pre" />
              <ScrollAffixEmpty tone="pre" />
            </div>

            {/* Center — weapon badge + STRIKE button */}
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, paddingTop: 4 }}>
              <div style={{ fontFamily: 'var(--f-mono)', fontSize: 8, color: 'var(--ink-faint)', letterSpacing: 2 }}>ON THE BENCH</div>
              <div style={{ position: 'relative', width: 130, height: 160,
                background: 'radial-gradient(ellipse at 50% 70%, rgba(255,130,50,0.28), transparent 65%)' }}>
                <div style={{ position: 'absolute', inset: 0,
                  border: '1px solid var(--brass-lo)',
                  background: 'linear-gradient(180deg, rgba(60,40,20,0.25), rgba(20,12,8,0.4))',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  boxShadow: 'inset 0 0 20px rgba(255,140,60,0.12), inset 0 1px 0 rgba(196,155,92,0.3)' }}>
                  <img src="assets/sword2.png" alt="" style={{
                    width: 100, height: 24, objectFit: 'contain',
                    transform: 'rotate(90deg)',
                    filter: 'drop-shadow(0 0 8px rgba(255,150,70,0.4))' }} />
                </div>
                {[0,1,2,3].map(i => (
                  <span key={i} style={{ position: 'absolute',
                    ...(i === 0 ? { top: -3, left: -3 }
                      : i === 1 ? { top: -3, right: -3 }
                      : i === 2 ? { bottom: -3, left: -3 }
                      : { bottom: -3, right: -3 }),
                    width: 6, height: 6, border: '1px solid var(--brass-hi)', background: '#0d0905' }} />
                ))}
              </div>
              <div style={{ textAlign: 'center', lineHeight: 1.25, minHeight: 34 }}>
                <ItemName rarity={selected.rar} size={12}>{selected.name}</ItemName>
              </div>
              <div style={{ fontFamily: 'var(--f-mono)', fontSize: 8, color: 'var(--ink-faint)', letterSpacing: 1, textAlign: 'center', whiteSpace: 'nowrap' }}>
                {selected.mat.toUpperCase()} · {selected.base.toUpperCase()} · T{selected.tier}
              </div>

              {/* Main stat readout — DPS for weapons, defense for armor */}
              <BenchStatReadout item={selected} />

              {/* Bench actions — melt to reclaim material */}
              {!selected.equipped && (
                <button title="Melt · destroy this item, reclaim a fraction of its material" style={{
                  width: '100%', padding: '5px 6px',
                  background: 'linear-gradient(180deg, rgba(40,22,14,0.7), rgba(20,12,8,0.8))',
                  border: '1px solid var(--copper)',
                  color: 'var(--copper)',
                  fontFamily: 'var(--f-mono)', fontSize: 9, letterSpacing: 2,
                  textTransform: 'uppercase', cursor: 'pointer', marginTop: -2,
                  display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
                }}>
                  <span style={{ fontSize: 11 }}>🜂</span> Melt
                </button>
              )}
            </div>

            {/* SUFFIX rail */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              <div style={{ fontFamily: 'var(--f-mono)', fontSize: 9, color: 'var(--suf)', letterSpacing: 2,
                display: 'flex', justifyContent: 'space-between', padding: '0 4px' }}>
                <span>◆ SUFFIX</span>
                <span style={{ color: 'var(--ink-faint)' }}>1 / 3</span>
              </div>
              <ScrollAffix tone="suf" tier={3} text="Adds 14 to 28 Fire Damage" rawRoll="12–16 / 24–28" rawRange="8–18 / 20–32" pct={0.92} hot />
              <ScrollAffixEmpty tone="suf" />
              <ScrollAffixEmpty tone="suf" />
            </div>
          </div>

          {/* INVENTORY — slot selector row + grid per M001 */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6, minHeight: 0, flex: 1 }}>
            {/* Slot selector row */}
            <div style={{ display: 'flex', gap: 0, alignItems: 'stretch' }}>
              {M001_SLOTS.map(slot => (
                <SlotTab key={slot} active={activeSlot === slot} onClick={() => setActiveSlot(slot)}>
                  {slot}
                </SlotTab>
              ))}
              <div style={{ flex: 1 }} />
              <div style={{ padding: '0 10px', fontFamily: 'var(--f-mono)', fontSize: 9,
                color: 'var(--ink-faint)', letterSpacing: 1, display: 'flex', alignItems: 'center' }}>
                {items.length} / 24
              </div>
            </div>

          <div className="hm-wood-panel" style={{ padding: 8, flex: 1, minHeight: 0, overflow: 'visible', position: 'relative' }}>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(6, 1fr)', gap: 5 }}>
                <NewBaseTile slot={activeSlot} />
                {items.map(item => (
                  <InvItem key={item.id}
                    item={item}
                    selected={selectedItem === item.id}
                    onClick={() => setSelectedItem(item.id)} />
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* RIGHT — Hero panel: portrait + 5 equipped slots + aggregate stats */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6, minHeight: 0 }}>
          <IronHeader right="LVL 47">The Hero</IronHeader>

          {/* Portrait */}
          <div className="hm-wood-panel" style={{ padding: 10, position: 'relative', display: 'flex', gap: 10 }}>
            <Nails />
            <img src="assets/hero.png" alt="" style={{ width: 90, height: 120, objectFit: 'contain',
              filter: 'drop-shadow(0 4px 8px rgba(0,0,0,0.6))' }} />
            <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', gap: 4 }}>
              <div style={{ fontFamily: 'var(--f-serif)', fontSize: 18, color: 'var(--brass-hi)', fontWeight: 600 }}>Vaela</div>
              <div style={{ fontSize: 10, color: 'var(--ink-faint)', fontStyle: 'italic' }}>Level 47 · 68% to 48</div>
              <div className="hm-inset" style={{ height: 4, borderRadius: 2, overflow: 'hidden', marginTop: 2 }}>
                <div style={{ width: '68%', height: '100%', background: 'linear-gradient(90deg, var(--brass-lo), var(--brass-hi))' }} />
              </div>
              <div style={{ fontFamily: 'var(--f-mono)', fontSize: 9, color: 'var(--ink-faint)',
                letterSpacing: 1, marginTop: 4 }}>47,812 XP</div>
            </div>
          </div>

          {/* Equipped slots — 5 per M001 */}
          <IronHeader>Equipped</IronHeader>
          <div className="hm-wood-panel" style={{ padding: 8 }}>
            {M001_SLOTS.map(slot => {
              const equipped = M001_INVENTORY.find(i => i.slot === slot && i.equipped);
              return (
                <EquipSlot key={slot}
                  slot={slot}
                  item={equipped}
                  active={slot === activeSlot}
                  onClick={() => setActiveSlot(slot)} />
              );
            })}
          </div>

          {/* Aggregate stats — life, armor, resists, damage with deltas */}
          <IronHeader right="preview">Stats</IronHeader>
          <div className="hm-wood-panel" style={{ padding: 10, flex: 1, minHeight: 0, overflow: 'auto' }}>
            <DeltaStat label="Life"              a="3,200"   b="3,200"   />
            <DeltaStat label="Energy Shield"     a="420"     b="420"     />
            <DeltaStat label="Armor"             a="3,840"   b="3,840"   />
            <DeltaStat label="Evasion"           a="1,210"   b="1,210"   />
            <div className="hm-divider" style={{ margin: '6px 0' }} />
            <DeltaStat label="Phys Damage"       a="68–142"  b="86–172"  delta="+24 avg"   good />
            <DeltaStat label="Fire Damage"       a="—"       b="14–28"   delta="new"       good />
            <DeltaStat label="Attack Speed"      a="1.42/s"  b="1.35/s"  delta="−0.07"     bad />
            <DeltaStat label="Crit Chance"       a="6.2%"    b="6.2%"    />
            <div className="hm-divider" style={{ margin: '6px 0' }} />
            <DeltaStat label="Fire Resist"       a="75%"     b="75%"     />
            <DeltaStat label="Cold Resist"       a="62%"     b="62%"     />
            <DeltaStat label="Lightning Resist"  a="71%"     b="71%"     />
            <div style={{ marginTop: 8, padding: '6px 8px', background: 'rgba(232,135,74,0.1)',
              border: '1px solid rgba(232,135,74,0.3)', borderLeft: '3px solid var(--ember)',
              fontFamily: 'var(--f-mono)', fontSize: 10, color: 'var(--ember-hi)', letterSpacing: 0.5 }}>
              Est. expedition time: Iron Quarry <span className="num" style={{ fontWeight: 600 }}>10s</span> · Steel Depths <span className="num" style={{ fontWeight: 600 }}>38s</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// ───────── Pieces ─────────

function Tab({ children, active }) {
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

function HammerTab({ children, active, locked }) {
  return (
    <div style={{
      flex: 1, padding: '5px 6px', fontFamily: 'var(--f-mono)', fontSize: 9,
      letterSpacing: 1.5, textTransform: 'uppercase', textAlign: 'center',
      color: active ? 'var(--brass-hi)' : locked ? 'var(--ink-faint)' : 'var(--parch)',
      background: active
        ? 'linear-gradient(180deg, var(--wood) 0%, var(--wood-dark) 100%)'
        : 'linear-gradient(180deg, rgba(20,14,10,0.6), rgba(10,7,5,0.7))',
      border: '1px solid ' + (active ? 'var(--wood-deep)' : 'rgba(0,0,0,0.5)'),
      borderBottom: active ? '1px solid var(--wood)' : '1px solid rgba(0,0,0,0.5)',
      cursor: locked ? 'not-allowed' : 'pointer',
      opacity: locked ? 0.5 : 1,
      position: 'relative', zIndex: active ? 2 : 1,
    }}>{children}{locked && ' ·'}</div>
  );
}

function Hammer({ glyph, name, verb, count, effect, target, active, hot, rare, onClick }) {
  const glyphCol = rare ? 'var(--r-rare-hi)' : active ? 'var(--ember-hi)' : 'var(--brass-hi)';
  return (
    <div className="hm-hammer" onClick={onClick} style={{
      position: 'relative',
      aspectRatio: '1 / 1',
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      gap: 2, padding: 2,
      background: active
        ? 'radial-gradient(circle at 50% 30%, rgba(255,170,90,0.35), rgba(40,25,15,0.7))'
        : hot
          ? 'radial-gradient(circle at 50% 30%, rgba(232,135,74,0.22), rgba(20,15,10,0.4))'
          : 'linear-gradient(180deg, rgba(40,28,18,0.7), rgba(14,10,8,0.7))',
      border: '1px solid ' + (active ? 'var(--ember)' : hot ? 'rgba(232,135,74,0.55)' : 'rgba(0,0,0,0.6)'),
      boxShadow: active
        ? 'inset 0 0 12px rgba(255,180,110,0.4), 0 0 12px rgba(255,140,60,0.3)'
        : 'inset 0 1px 0 rgba(180,140,90,0.15), inset 0 -1px 0 rgba(0,0,0,0.5)',
      cursor: 'pointer',
    }}>
      <span style={{
        fontSize: 22, lineHeight: 1, color: glyphCol,
        textShadow: active ? '0 0 12px rgba(255,180,110,0.9)' : hot ? '0 0 10px rgba(255,170,90,0.7)' : '0 0 6px rgba(232,168,90,0.35)',
      }}>{glyph}</span>
      <span className="num" style={{ fontSize: 10, color: glyphCol, fontWeight: 600, lineHeight: 1 }}>×{count}</span>
      {hot && !active && (
        <span style={{ position: 'absolute', top: 2, left: 3, width: 4, height: 4, borderRadius: '50%',
          background: 'var(--ember-hi)', boxShadow: '0 0 6px var(--ember-hi)' }} />
      )}

      {/* Hover tooltip */}
      <div className="hm-hammer-tip" style={{
        position: 'absolute', left: '50%', bottom: 'calc(100% + 6px)',
        transform: 'translateX(-50%)',
        minWidth: 200, maxWidth: 240,
        padding: '8px 10px',
        background: 'linear-gradient(180deg, #1a120a, #0b0706)',
        border: '1px solid #000',
        boxShadow: '0 0 0 1px rgba(196,155,92,0.4), 0 6px 16px rgba(0,0,0,0.7)',
        fontFamily: 'var(--f-ui)', textAlign: 'left',
        pointerEvents: 'none', opacity: 0, transition: 'opacity 120ms ease',
        zIndex: 20,
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
          <span style={{ fontFamily: 'var(--f-serif)', fontSize: 13, fontWeight: 600,
            color: rare ? 'var(--r-rare-hi)' : 'var(--brass-hi)' }}>{name} Hammer</span>
          <span className="num" style={{ color: 'var(--brass-hi)', fontSize: 11, fontWeight: 600 }}>×{count}</span>
        </div>
        <div style={{ fontFamily: 'var(--f-mono)', fontSize: 9, color: 'var(--ink-faint)',
          letterSpacing: 1, textTransform: 'uppercase', marginTop: 1 }}>
          {verb} · target: {target}
        </div>
        <div style={{ fontSize: 11, color: 'var(--parch)', marginTop: 6, lineHeight: 1.4 }}>{effect}</div>
      </div>
    </div>
  );
}

function HammerEmpty() {
  return (
    <div style={{
      aspectRatio: '1 / 1',
      background: 'rgba(10,8,6,0.55)',
      border: '1px dashed rgba(90,70,45,0.25)',
      boxShadow: 'inset 0 2px 4px rgba(0,0,0,0.5)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: 'var(--f-mono)', fontSize: 9, color: 'var(--ink-faint)', letterSpacing: 1,
    }}>+</div>
  );
}

function ActiveHammerCard({ hammer }) {
  return (
    <>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 44, height: 44, display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 26, color: 'var(--ember-hi)', textShadow: '0 0 12px rgba(255,180,110,0.8)',
          background: 'radial-gradient(circle at 50% 30%, rgba(255,170,90,0.3), rgba(20,12,8,0.6))',
          border: '1px solid var(--ember)',
          boxShadow: 'inset 0 0 10px rgba(255,140,60,0.2)',
        }}>{hammer.glyph}</div>
        <div style={{ flex: 1 }}>
          <div style={{ fontFamily: 'var(--f-serif)', fontSize: 14, color: 'var(--brass-hi)', fontWeight: 600 }}>
            {hammer.name} Hammer
          </div>
          <div style={{ fontFamily: 'var(--f-mono)', fontSize: 9, color: 'var(--ember-hi)', letterSpacing: 1.5, textTransform: 'uppercase' }}>
            {hammer.verb}
          </div>
        </div>
        <div style={{ textAlign: 'right' }}>
          <div className="num" style={{ fontSize: 18, color: 'var(--brass-hi)', fontWeight: 600 }}>×{hammer.count}</div>
          <div style={{ fontFamily: 'var(--f-mono)', fontSize: 8, color: 'var(--ink-faint)', letterSpacing: 1 }}>OWNED</div>
        </div>
      </div>
      <div style={{ fontSize: 11, color: 'var(--parch)', marginTop: 8, lineHeight: 1.4 }}>
        {hammer.effect}
      </div>
      <div style={{ marginTop: 6, fontFamily: 'var(--f-mono)', fontSize: 9, color: 'var(--ink-faint)', letterSpacing: 1 }}>
        TARGET · {hammer.target.toUpperCase()}
      </div>
    </>
  );
}

function SlotTab({ children, active, onClick }) {
  return (
    <div onClick={onClick} style={{
      padding: '6px 14px', fontFamily: 'var(--f-serif)', fontSize: 12, fontWeight: 600,
      letterSpacing: 0.5, cursor: 'pointer',
      color: active ? 'var(--brass-hi)' : 'var(--ink-faint)',
      background: active
        ? 'linear-gradient(180deg, var(--wood) 0%, var(--wood-dark) 100%)'
        : 'linear-gradient(180deg, rgba(20,14,10,0.5), rgba(10,7,5,0.6))',
      border: '1px solid ' + (active ? 'var(--wood-deep)' : 'rgba(0,0,0,0.4)'),
      borderBottom: active ? 'none' : '1px solid rgba(0,0,0,0.4)',
      borderRight: 'none',
      textShadow: active ? '0 0 6px rgba(232,168,90,0.3)' : 'none',
      position: 'relative', zIndex: active ? 2 : 1,
      marginBottom: active ? -1 : 0,
    }}>{children}</div>
  );
}

const M001_STOCKPILE = {
  Weapon: [
    { mat: 'Iron',  base: 'Shortsword', tier: 1, count: 3 },
    { mat: 'Iron',  base: 'Longsword',  tier: 1, count: 1 },
    { mat: 'Steel', base: 'Saber',      tier: 2, count: 2 },
    { mat: 'Steel', base: 'Broadsword', tier: 3, count: 1 },
  ],
  Helmet: [
    { mat: 'Iron',  base: 'Cap',     tier: 1, count: 2 },
    { mat: 'Steel', base: 'Helm',    tier: 2, count: 1 },
  ],
  Armor: [
    { mat: 'Iron',  base: 'Hauberk', tier: 1, count: 4 },
    { mat: 'Steel', base: 'Cuirass', tier: 3, count: 2 },
  ],
  Boots: [
    { mat: 'Iron',  base: 'Boots',   tier: 1, count: 3 },
  ],
  Ring: [
    { mat: 'Iron',  base: 'Band',    tier: 1, count: 5 },
    { mat: 'Steel', base: 'Signet',  tier: 2, count: 1 },
  ],
};

function NewBaseTile({ slot }) {
  const bases = M001_STOCKPILE[slot] || [];
  const total = bases.reduce((s, b) => s + b.count, 0);
  const empty = total === 0;

  return (
    <div className="hm-newbase" style={{
      position: 'relative',
      padding: '5px 6px 6px',
      minHeight: 50,
      background: 'repeating-linear-gradient(45deg, rgba(40,28,18,0.35), rgba(40,28,18,0.35) 4px, rgba(14,10,8,0.5) 4px, rgba(14,10,8,0.5) 8px)',
      border: '1px dashed ' + (empty ? 'rgba(90,70,45,0.35)' : 'var(--brass-lo)'),
      color: empty ? 'var(--ink-faint)' : 'var(--copper)',
      cursor: empty ? 'not-allowed' : 'pointer',
      display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center',
      gap: 2, transition: 'border-color 120ms ease, background 120ms ease, color 120ms ease',
      opacity: empty ? 0.55 : 1,
    }}>
      <span style={{ fontSize: 18, lineHeight: 1, fontWeight: 300 }}>+</span>
      <span style={{ fontFamily: 'var(--f-mono)', fontSize: 7, letterSpacing: 1.2,
        textTransform: 'uppercase', lineHeight: 1 }}>New base</span>
      <span className="num" style={{ fontFamily: 'var(--f-mono)', fontSize: 7,
        letterSpacing: 0.8, color: 'var(--ink-faint)', marginTop: 1 }}>
        {total} in stock
      </span>

      {/* Stockpile picker — hover tooltip */}
      <div className="hm-newbase-tip" style={{
        position: 'absolute', left: '50%', bottom: 'calc(100% + 6px)',
        transform: 'translateX(-50%)',
        minWidth: 240, maxWidth: 280,
        padding: '10px 12px',
        background: 'linear-gradient(180deg, #1a120a, #0b0706)',
        border: '1px solid #000',
        boxShadow: '0 0 0 1px rgba(196,155,92,0.4), 0 6px 16px rgba(0,0,0,0.7)',
        fontFamily: 'var(--f-ui)', textAlign: 'left',
        pointerEvents: 'none', opacity: 0, transition: 'opacity 120ms ease',
        zIndex: 20,
      }}>
        <div style={{ fontFamily: 'var(--f-serif)', fontSize: 12, fontWeight: 600,
          color: 'var(--brass-hi)', marginBottom: 2 }}>Forge a new base</div>
        <div style={{ fontFamily: 'var(--f-mono)', fontSize: 8, letterSpacing: 1.2,
          color: 'var(--ink-faint)', textTransform: 'uppercase' }}>
          {slot} stockpile · from expeditions
        </div>

        {bases.length > 0 ? (
          <div style={{ marginTop: 8, paddingTop: 6, borderTop: '1px dotted rgba(196,155,92,0.25)' }}>
            {bases.map((b, i) => (
              <div key={i} style={{ display: 'flex', justifyContent: 'space-between',
                alignItems: 'baseline', padding: '3px 0',
                borderBottom: i < bases.length - 1 ? '1px dotted rgba(196,155,92,0.1)' : 'none' }}>
                <div>
                  <span style={{ fontSize: 11, color: 'var(--parch)' }}>{b.mat} {b.base}</span>
                  <span style={{ fontFamily: 'var(--f-mono)', fontSize: 8, color: 'var(--ink-faint)',
                    letterSpacing: 1, marginLeft: 6 }}>T{b.tier}</span>
                </div>
                <span className="num" style={{ fontFamily: 'var(--f-mono)', fontSize: 10,
                  color: 'var(--brass-hi)', fontWeight: 600 }}>×{b.count}</span>
              </div>
            ))}
          </div>
        ) : (
          <div style={{ marginTop: 8, fontSize: 10, color: 'var(--ink-faint)', fontStyle: 'italic' }}>
            No {slot.toLowerCase()} bases in stock · send an expedition
          </div>
        )}

        <div style={{ marginTop: 8, paddingTop: 6, borderTop: '1px dotted rgba(196,155,92,0.15)',
          fontFamily: 'var(--f-mono)', fontSize: 8, color: 'var(--ember-hi)',
          letterSpacing: 1.5, textTransform: 'uppercase' }}>
          {bases.length > 0 ? 'Click to place on bench' : 'Expedition needed'}
        </div>
      </div>
    </div>
  );
}

function InvItem({ item, selected, onClick }) {
  const borderCol = selected ? 'var(--ember)' : `var(--r-${item.rar})`;
  return (
    <div className="hm-inv" onClick={onClick} style={{
      position: 'relative',
      padding: '5px 6px 6px',
      background: selected
        ? 'radial-gradient(ellipse at 50% 0%, rgba(255,170,90,0.18), rgba(20,12,8,0.6))'
        : 'linear-gradient(180deg, rgba(40,28,18,0.55), rgba(14,10,8,0.65))',
      border: '1px solid ' + borderCol,
      borderLeft: `3px solid var(--r-${item.rar})`,
      boxShadow: selected
        ? 'inset 0 0 10px rgba(255,140,60,0.2), 0 0 8px rgba(255,140,60,0.25)'
        : 'inset 0 1px 0 rgba(180,140,90,0.08)',
      cursor: 'pointer', minHeight: 50,
    }}>
      {item.equipped && (
        <div style={{ position: 'absolute', top: 3, right: 3,
          fontFamily: 'var(--f-mono)', fontSize: 7, letterSpacing: 0.5,
          color: 'var(--ember-hi)', background: 'rgba(20,12,8,0.85)',
          border: '1px solid var(--ember-lo)', padding: '0 3px', borderRadius: 1 }}>
          EQ
        </div>
      )}
      {/* Melt icon — hover reveal, suppressed if equipped */}
      {!item.equipped && (
        <button className="hm-melt-btn" onClick={(e) => e.stopPropagation()} title="Melt · destroy for slag" style={{
          position: 'absolute', top: 2, right: 2,
          width: 14, height: 14, padding: 0,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          background: 'rgba(20,12,8,0.9)',
          border: '1px solid var(--copper)',
          color: 'var(--copper)', fontSize: 10, lineHeight: 1, cursor: 'pointer',
          opacity: 0, transition: 'opacity 120ms ease, color 120ms ease, background 120ms ease',
          fontFamily: 'var(--f-mono)',
        }}>🜂</button>
      )}
      <div className={`rar-${item.rar}`} style={{
        fontFamily: 'var(--f-serif)', fontSize: 11, fontWeight: 600, lineHeight: 1.15,
        overflow: 'hidden', textOverflow: 'ellipsis',
        display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical',
        paddingRight: item.equipped ? 14 : 0,
      }}>{item.name}</div>
      <div style={{ fontFamily: 'var(--f-mono)', fontSize: 8, color: 'var(--ink-faint)',
        letterSpacing: 1, marginTop: 3, display: 'flex', justifyContent: 'space-between' }}>
        <span>{item.mat.toUpperCase()}</span>
        <span>T{item.tier}</span>
      </div>

      {/* Hover tooltip — details */}
      <div className="hm-inv-tip" style={{
        position: 'absolute', left: '50%', bottom: 'calc(100% + 6px)',
        transform: 'translateX(-50%)',
        minWidth: 220, maxWidth: 260,
        padding: '10px 12px',
        background: 'linear-gradient(180deg, #1a120a, #0b0706)',
        border: '1px solid #000',
        boxShadow: '0 0 0 1px rgba(196,155,92,0.4), 0 6px 16px rgba(0,0,0,0.7)',
        fontFamily: 'var(--f-ui)', textAlign: 'left',
        pointerEvents: 'none', opacity: 0, transition: 'opacity 120ms ease',
        zIndex: 20,
      }}>
        <div className={`rar-${item.rar}`} style={{
          fontFamily: 'var(--f-serif)', fontSize: 13, fontWeight: 600, lineHeight: 1.2,
        }}>{item.name}</div>
        <div style={{ fontFamily: 'var(--f-mono)', fontSize: 8, color: 'var(--ink-faint)',
          letterSpacing: 1.5, marginTop: 2, textTransform: 'uppercase' }}>
          {item.rar} · {item.mat} {item.base} · Tier {item.tier}
        </div>
        {item.affixes.length > 0 ? (
          <div style={{ marginTop: 8, paddingTop: 6, borderTop: '1px dotted rgba(196,155,92,0.25)' }}>
            {item.affixes.map((a, i) => (
              <div key={i} style={{ display: 'flex', gap: 5, alignItems: 'baseline', padding: '2px 0' }}>
                <span style={{ fontFamily: 'var(--f-mono)', fontSize: 8,
                  color: a.tone === 'pre' ? 'var(--pre)' : 'var(--suf)',
                  border: `1px solid ${a.tone === 'pre' ? 'var(--pre)' : 'var(--suf)'}`,
                  padding: '0 3px', borderRadius: 2, flexShrink: 0 }}>T{a.tier}</span>
                <span style={{ fontSize: 11, color: 'var(--parch)', lineHeight: 1.3 }}>{a.text}</span>
              </div>
            ))}
          </div>
        ) : (
          <div style={{ marginTop: 8, fontSize: 10, color: 'var(--ink-faint)', fontStyle: 'italic' }}>
            No affixes · unforged base
          </div>
        )}
        {item.equipped && (
          <div style={{ marginTop: 6, fontFamily: 'var(--f-mono)', fontSize: 9,
            color: 'var(--ember-hi)', letterSpacing: 1.5, textTransform: 'uppercase' }}>
            ◆ Currently Equipped
          </div>
        )}
      </div>
    </div>
  );
}

function EquipSlot({ slot, item, active, onClick }) {
  return (
    <div onClick={onClick} style={{
      display: 'grid', gridTemplateColumns: '70px 1fr auto', gap: 8, alignItems: 'center',
      padding: '5px 8px', marginBottom: 2, cursor: 'pointer',
      background: active ? 'rgba(196,155,92,0.12)' : 'transparent',
      borderLeft: active ? '2px solid var(--brass)' : '2px solid transparent',
    }}>
      <span style={{ fontFamily: 'var(--f-mono)', fontSize: 9, color: 'var(--ink-faint)',
        letterSpacing: 1.5, textTransform: 'uppercase' }}>{slot}</span>
      {item ? (
        <>
          <span className={`rar-${item.rar}`} style={{ fontFamily: 'var(--f-serif)', fontSize: 12, fontWeight: 500,
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{item.name}</span>
          <span style={{ fontFamily: 'var(--f-mono)', fontSize: 8, color: 'var(--ink-faint)', letterSpacing: 1 }}>
            {item.mat.toUpperCase()}
          </span>
        </>
      ) : (
        <>
          <span style={{ fontFamily: 'var(--f-serif)', fontSize: 12, color: 'var(--ink-faint)', fontStyle: 'italic' }}>Empty</span>
          <span />
        </>
      )}
    </div>
  );
}

function ScrollAffix({ tone, tier, text, rawRoll, rawRange, pct, hot }) {
  const col = tone === 'pre' ? 'var(--pre)' : 'var(--suf)';
  return (
    <div style={{ position: 'relative',
      background: hot
        ? 'linear-gradient(180deg, rgba(232,135,74,0.15), rgba(30,18,10,0.7))'
        : 'linear-gradient(180deg, rgba(60,40,20,0.35), rgba(20,12,8,0.55))',
      border: '1px solid ' + (hot ? 'rgba(232,135,74,0.5)' : 'rgba(0,0,0,0.6)'),
      borderLeft: `3px solid ${col}`,
      padding: '8px 10px',
      boxShadow: hot
        ? 'inset 0 0 12px rgba(255,140,60,0.15), 0 1px 0 rgba(0,0,0,0.5)'
        : 'inset 0 1px 0 rgba(196,155,92,0.08), 0 1px 0 rgba(0,0,0,0.5)',
    }}>
      <div style={{ display: 'flex', gap: 6, alignItems: 'baseline' }}>
        <span style={{ fontFamily: 'var(--f-mono)', fontSize: 9, color: col,
          border: `1px solid ${col}`, padding: '0 4px', borderRadius: 2 }}>T{tier}</span>
        <span style={{ fontSize: 12, color: 'var(--parch)', flex: 1, fontFamily: 'var(--f-serif)', fontWeight: 500 }}>{text}</span>
        {hot && <span style={{ color: 'var(--ember-hi)', fontSize: 11, textShadow: '0 0 6px var(--ember-hi)' }}>◆</span>}
      </div>
      <div style={{ marginTop: 6, display: 'flex', gap: 8, alignItems: 'center' }}>
        <span className="num" style={{ fontSize: 10, color: 'var(--parch)', whiteSpace: 'nowrap' }}>{rawRoll}</span>
        <div style={{ flex: 1, height: 4, background: 'rgba(0,0,0,0.5)',
          border: '1px solid rgba(0,0,0,0.7)', position: 'relative', overflow: 'hidden' }}>
          <div style={{ width: `${pct * 100}%`, height: '100%',
            background: hot ? 'linear-gradient(90deg, var(--ember-lo), var(--ember-hi))' : col,
            boxShadow: hot ? '0 0 6px var(--ember-hi)' : 'none' }} />
        </div>
        <span className="num" style={{ fontSize: 9, color: 'var(--ink-faint)', whiteSpace: 'nowrap' }}>max {rawRange}</span>
      </div>
    </div>
  );
}

function ScrollAffixEmpty({ tone }) {
  const col = tone === 'pre' ? 'var(--pre)' : 'var(--suf)';
  return (
    <div style={{ padding: '10px 10px', border: `1px dashed ${col}`,
      background: 'rgba(20,12,8,0.3)',
      fontFamily: 'var(--f-mono)', fontSize: 9, color: col, letterSpacing: 2, textAlign: 'center',
      opacity: 0.55 }}>
      ✦ OPEN {tone === 'pre' ? 'PREFIX' : 'SUFFIX'} ✦
    </div>
  );
}

function DeltaStat({ label, a, b, delta, good, bad }) {
  const changed = a !== b;
  // 2-column: label | value OR value+delta pill. Value shows "b" (preview); delta carries the before/after meaning.
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: 8, fontSize: 11,
      padding: '3px 0', borderBottom: '1px dotted rgba(196,155,92,0.12)', alignItems: 'baseline' }}>
      <span style={{ color: 'var(--ink-faint)' }}>{label}</span>
      <span style={{ display: 'flex', gap: 6, alignItems: 'baseline', whiteSpace: 'nowrap' }}>
        <span className="num" style={{ color: 'var(--parch)' }}>{b}</span>
        {delta && (
          <span className="num" style={{
            color: good ? 'var(--ok)' : bad ? 'var(--danger)' : 'var(--brass-hi)',
            fontWeight: 600, fontSize: 10,
            padding: '0 5px', borderRadius: 2,
            background: good ? 'rgba(120,160,99,0.15)' : bad ? 'rgba(176,74,58,0.18)' : 'transparent',
            border: good ? '1px solid rgba(120,160,99,0.3)' : bad ? '1px solid rgba(176,74,58,0.3)' : 'none',
          }}>{delta}</span>
        )}
      </span>
    </div>
  );
}

function BenchStatReadout({ item }) {
  // Fake derived stats based on item + tier + rarity
  const tierMult = item.tier;
  const rarMult = item.rar === 'rare' ? 1.4 : item.rar === 'magic' ? 1.15 : 1.0;

  let primary, secondary;
  if (item.slot === 'Weapon') {
    const baseDmg = { 'Broadsword': [86, 172], 'Longsword': [72, 148], 'Shortsword': [58, 110],
                     'Cleaver': [112, 168], 'Saber': [64, 132] }[item.base] || [60, 120];
    const dmgLo = Math.round(baseDmg[0] * tierMult * rarMult);
    const dmgHi = Math.round(baseDmg[1] * tierMult * rarMult);
    const aps = item.base === 'Cleaver' ? 0.95 : item.base === 'Broadsword' ? 1.35 : 1.55;
    const dps = Math.round(((dmgLo + dmgHi) / 2) * aps);
    primary   = { label: 'DPS',    value: dps.toLocaleString(), unit: `${aps.toFixed(2)}/s` };
    secondary = { label: 'DAMAGE', value: `${dmgLo}–${dmgHi}` };
  } else if (item.slot === 'Armor' || item.slot === 'Helmet') {
    primary   = { label: 'ARMOR',  value: String(Math.round(220 * tierMult * rarMult)), unit: 'phys mitigation' };
    secondary = { label: 'LIFE',   value: `+${Math.round(42 * tierMult * rarMult)}` };
  } else if (item.slot === 'Boots') {
    primary   = { label: 'EVASION', value: String(Math.round(180 * tierMult * rarMult)), unit: 'move spd +12%' };
    secondary = { label: 'LIFE',    value: `+${Math.round(28 * tierMult * rarMult)}` };
  } else {
    primary   = { label: 'LIFE',    value: `+${Math.round(54 * tierMult * rarMult)}`, unit: 'ring' };
    secondary = { label: 'RESIST',  value: `+${Math.round(12 * tierMult * rarMult)}%` };
  }

  return (
    <div style={{
      width: '100%', marginTop: 4, padding: '8px 6px',
      background: 'rgba(20,12,8,0.5)', border: '1px solid rgba(0,0,0,0.5)',
      boxShadow: 'inset 0 1px 0 rgba(196,155,92,0.1)',
      fontFamily: 'var(--f-mono)', letterSpacing: 1, textAlign: 'center',
    }}>
      <div style={{ color: 'var(--ember-hi)', fontSize: 18, fontWeight: 700, lineHeight: 1,
        textShadow: '0 0 8px rgba(255,140,60,0.4)' }} className="num">{primary.value}</div>
      <div style={{ fontSize: 8, color: 'var(--ink-faint)', marginTop: 2 }}>
        {primary.label}{primary.unit ? ` · ${primary.unit}` : ''}
      </div>
      <div style={{ borderTop: '1px dotted rgba(196,155,92,0.15)', marginTop: 5, paddingTop: 4 }}>
        <span className="num" style={{ color: 'var(--parch)', fontSize: 11 }}>{secondary.value}</span>
        <div style={{ fontSize: 8, color: 'var(--ink-faint)' }}>{secondary.label}</div>
      </div>
    </div>
  );
}

Object.assign(window, { ForgeView });