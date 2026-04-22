// Item tooltip focus view + Stats/achievements view

function TooltipView() {
  return (
    <div style={{ width: '100%', height: '100%', padding: 24,
      background: 'radial-gradient(ellipse at 50% 30%, #2a1d12 0%, #0d0905 80%)',
      fontFamily: 'var(--f-ui)', color: 'var(--parch)', display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative' }}>
      <div style={{ position: 'absolute', top: 10, left: 16, fontFamily: 'var(--f-mono)', fontSize: 10,
        color: 'var(--ink-faint)', letterSpacing: 2 }}>ITEM TOOLTIP · FULL DETAIL</div>

      <div className="hm-parch" style={{ width: 380, padding: 18, position: 'relative' }}>
        <Nails inset={6} />

        {/* header strip */}
        <div style={{ textAlign: 'center', paddingBottom: 12, marginBottom: 12,
          borderBottom: '2px solid rgba(90,60,30,0.3)' }}>
          <div style={{ fontFamily: 'var(--f-mono)', fontSize: 9, color: 'var(--copper)', letterSpacing: 3, marginBottom: 4 }}>
            ⬦ UNIQUE · TWO-HANDED SWORD ⬦
          </div>
          <ItemName rarity="unique" size={20}>Cinderfang</ItemName>
          <div style={{ fontFamily: 'var(--f-serif)', fontSize: 12, color: 'var(--copper)', fontStyle: 'italic' }}>
            Slavemaker Greatsword
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 4, marginBottom: 12 }}>
          <Stat label="Item Level" value="78" />
          <Stat label="Quality" value="+20%" tone="mod" />
          <Stat label="Req Level" value="65" />
          <Stat label="Req Str" value="142" />
        </div>

        <SectionLabel>WEAPON</SectionLabel>
        <Stat label="Physical Damage" value="86–172" tone="mod" />
        <Stat label="Fire Damage" value="48–96" tone="rare" />
        <Stat label="Critical Strike" value="6.2%" />
        <Stat label="Attacks per Second" value="1.35" />
        <Stat label="Weapon Range" value="1.3m" />

        <SectionLabel>IMPLICIT</SectionLabel>
        <div style={{ color: 'var(--impl)', fontSize: 12, fontStyle: 'italic', padding: '3px 0' }}>
          +30% to Global Critical Strike Multiplier
        </div>

        <SectionLabel>AFFIXES · 3 PREFIX / 2 SUFFIX</SectionLabel>
        <Affix tone="pre" tier={1} text="Adds 48 to 96 Fire Damage" roll="[42-52 / 88-104]" hot />
        <Affix tone="pre" tier={2} text="+168% increased Physical Damage" roll="[150-169]" />
        <Affix tone="pre" tier={3} text="+88 to maximum Life" roll="[80-90]" />
        <Affix tone="suf" tier={1} text="+42% to Fire Resistance" roll="[38-45]" />
        <Affix tone="suf" tier={2} text="10% of Physical Damage as extra Fire" roll="[8-10]" hot />

        <SectionLabel>UNIQUE</SectionLabel>
        <div style={{ color: 'var(--r-unique-hi)', fontSize: 12, padding: '3px 0', lineHeight: 1.4 }}>
          ◆ Your Fire damage can Ignite even cold-immune enemies
        </div>
        <div style={{ color: 'var(--r-unique-hi)', fontSize: 12, padding: '3px 0', lineHeight: 1.4 }}>
          ◆ Ignites you inflict deal 40% more damage
        </div>
        <div style={{ color: 'var(--r-unique-hi)', fontSize: 12, padding: '3px 0', lineHeight: 1.4 }}>
          ◆ You cannot regenerate Life while moving
        </div>

        <div style={{ marginTop: 14, padding: '10px 12px', background: 'rgba(139,100,54,0.12)',
          borderLeft: '3px solid var(--copper)',
          fontFamily: 'var(--f-serif)', fontSize: 12, fontStyle: 'italic',
          color: 'var(--ink-soft)', lineHeight: 1.5 }}>
          "When the last ember cooled, the Slavemaker laid down her hammer and took up the blade. The hammer forgave. The blade would not."
        </div>

        {/* bottom strip */}
        <div className="hm-divider" style={{ margin: '12px 0 8px' }} />
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          fontFamily: 'var(--f-mono)', fontSize: 9, color: 'var(--ink-faint)', letterSpacing: 1 }}>
          <span>ACQUIRED · EMBER WASTES · T3</span>
          <span>VENDOR ⋅ 4 × Orb of Chaos</span>
        </div>
      </div>
    </div>
  );
}

function Affix({ tone, tier, text, roll, hot }) {
  const col = tone === 'pre' ? 'var(--pre)' : 'var(--suf)';
  return (
    <div style={{
      display: 'grid', gridTemplateColumns: 'auto 1fr auto', gap: 6, alignItems: 'baseline',
      padding: '4px 0', borderBottom: '1px dotted rgba(90,60,30,0.2)',
      background: hot ? 'rgba(232,135,74,0.08)' : 'transparent',
      paddingLeft: hot ? 4 : 0, borderLeft: hot ? `2px solid ${col}` : 'none',
    }}>
      <span style={{
        fontFamily: 'var(--f-mono)', fontSize: 9, color: col,
        border: `1px solid ${col}`, padding: '0 4px', borderRadius: 2,
      }}>T{tier}</span>
      <span style={{ fontSize: 12, color: 'var(--ink)', fontFamily: 'var(--f-serif)' }}>
        {text}{hot && <span style={{ color: 'var(--ember-lo)', marginLeft: 6 }}>◆</span>}
      </span>
      <span className="num" style={{ fontSize: 10, color: 'var(--ink-faint)' }}>{roll}</span>
    </div>
  );
}

function SectionLabel({ children }) {
  return (
    <div style={{ fontFamily: 'var(--f-mono)', fontSize: 9, color: 'var(--ink-faint)',
      letterSpacing: 2, margin: '10px 0 4px', paddingBottom: 2,
      borderBottom: '1px dotted rgba(90,60,30,0.3)' }}>{children}</div>
  );
}

// ───────── Stats / Achievements ─────────
function StatsView() {
  return (
    <div style={{ width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: 'linear-gradient(180deg, var(--wood-deep) 0%, #0d0905 100%)',
      fontFamily: 'var(--f-ui)', color: 'var(--parch)' }}>
      <div className="hm-iron-panel" style={{ padding: '8px 14px', display: 'flex', alignItems: 'center', gap: 12,
        borderBottom: '2px solid #000' }}>
        <HammerIcon size={20} />
        <span style={{ fontFamily: 'var(--f-display)', fontSize: 16, fontWeight: 700, letterSpacing: 1, color: 'var(--brass-hi)' }}>LEDGER</span>
        <div style={{ flex: 1 }} />
        <span style={{ fontFamily: 'var(--f-mono)', fontSize: 10, color: 'var(--ink-faint)' }}>since: apprentice · 42 days</span>
      </div>

      <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, padding: 10, minHeight: 0 }}>
        {/* LEFT column — stats */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6, minHeight: 0, overflow: 'auto' }}>
          <IronHeader>Lifetime Forge</IronHeader>
          <div className="hm-wood-panel" style={{ padding: 12 }}>
            <BigStat label="Hammers struck" value="8.42M" sub="avg 200K / day" />
            <BigStat label="Items forged" value="12,840" sub="1,284 rare · 6 unique" />
            <BigStat label="Orbs consumed" value="3,912" sub="worth ~284 Chaos" />
          </div>

          <IronHeader>Combat</IronHeader>
          <div className="hm-wood-panel" style={{ padding: 10 }}>
            <Stat label="Mobs killed" value="184,220" />
            <Stat label="Bosses killed" value="38" />
            <Stat label="Deaths" value="12" />
            <Stat label="Highest DPS spike" value="18,420" tone="mod" />
            <Stat label="Largest hit taken" value="2,840" />
            <Stat label="Maps completed" value="284" />
            <Stat label="Longest run (no death)" value="4d 12h" tone="mod" />
          </div>

          <IronHeader>Crafting</IronHeader>
          <div className="hm-wood-panel" style={{ padding: 10 }}>
            <Stat label="Orbs of Alteration used" value="1,842" />
            <Stat label="Orbs of Alchemy used" value="412" />
            <Stat label="Orbs of Chaos used" value="186" />
            <Stat label="Exalted Orbs used" value="14" tone="rare" />
            <Stat label="Avg alts per T1 roll" value="212" />
            <Stat label="Best single-Chaos hit" value="3 T1 prefixes" tone="mod" />
          </div>
        </div>

        {/* RIGHT column — achievements */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6, minHeight: 0 }}>
          <IronHeader right="28 / 120">Achievements</IronHeader>
          <div className="hm-wood-panel" style={{ padding: 12, flex: 1, minHeight: 0, overflow: 'auto', position: 'relative' }}>
            <Nails />
            <Ach title="First Strike" desc="Hammer your first 100 times" done progress={100} />
            <Ach title="Decent Craftsman" desc="Forge 1,000 items" done progress={100} />
            <Ach title="Orbcounter" desc="Use 1,000 currency orbs" done progress={100} />
            <Ach title="Slag Heap" desc="Scrap 500 items" done progress={100} />
            <Ach title="Scholar of the Anvil" desc="Reach 3 T1 affixes in one item" progress={67} sub="2 / 3" />
            <Ach title="Ten Million Hammers" desc="Strike ten million hammers total" progress={84} sub="8.42M / 10M" />
            <Ach title="One Chaos Wonder" desc="Hit all T1 on a Chaos Orb" progress={0} sub="lifetime best: 2 × T1" hidden />
            <Ach title="The Forgeheart" desc="Defeat the Forgeheart of Act III" progress={0} sub="T10 map" locked />
            <Ach title="Six-Link" desc="Link all 6 sockets on any item" progress={42} sub="best: 3L" />
            <Ach title="Deathless Century" desc="100 map clears without dying" progress={34} sub="34 / 100" />
          </div>
        </div>
      </div>
    </div>
  );
}

function BigStat({ label, value, sub }) {
  return (
    <div style={{ padding: '8px 0', borderBottom: '1px dotted rgba(196,155,92,0.18)' }}>
      <div style={{ fontFamily: 'var(--f-mono)', fontSize: 9, color: 'var(--ink-faint)', letterSpacing: 1.5 }}>{label.toUpperCase()}</div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 10, marginTop: 2 }}>
        <span className="num" style={{ fontSize: 24, color: 'var(--brass-hi)', fontWeight: 600 }}>{value}</span>
        <span style={{ fontSize: 10, color: 'var(--ink-faint)', fontStyle: 'italic' }}>{sub}</span>
      </div>
    </div>
  );
}

function Ach({ title, desc, progress, sub, done, locked, hidden }) {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '32px 1fr', gap: 10, padding: '8px 6px',
      borderBottom: '1px dotted rgba(196,155,92,0.15)', opacity: locked ? 0.4 : 1 }}>
      <div style={{
        width: 32, height: 32, border: '1px solid ' + (done ? 'var(--brass)' : 'var(--wood-mid)'),
        background: done ? 'linear-gradient(180deg, var(--brass-hi), var(--brass-lo))' : 'var(--wood-deep)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: done ? '#1a1008' : 'var(--ink-faint)',
        fontFamily: 'var(--f-serif)', fontSize: 16, fontWeight: 700,
        boxShadow: done ? 'inset 0 1px 0 rgba(255,255,255,0.3), 0 0 8px rgba(196,155,92,0.3)' : undefined,
      }}>{locked ? '?' : hidden ? '✦' : done ? '✓' : '◆'}</div>
      <div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
          <span style={{ fontFamily: 'var(--f-serif)', fontSize: 13,
            color: done ? 'var(--brass-hi)' : hidden ? 'var(--r-magic)' : 'var(--parch)' }}>{title}</span>
          {sub && <span className="num" style={{ fontSize: 9, color: 'var(--ink-faint)' }}>{sub}</span>}
        </div>
        <div style={{ fontSize: 10, color: 'var(--ink-faint)', marginTop: 1 }}>{desc}</div>
        {!done && progress > 0 && (
          <div className="hm-inset" style={{ height: 3, marginTop: 4, borderRadius: 1, overflow: 'hidden' }}>
            <div style={{ width: `${progress}%`, height: '100%',
              background: hidden ? 'var(--r-magic)' : 'var(--brass)' }} />
          </div>
        )}
      </div>
    </div>
  );
}

Object.assign(window, { TooltipView, StatsView });
