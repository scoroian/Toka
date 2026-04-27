// Hoy screen — 3 variants, used inside device frames

// Shared demo data
const HOME_MEMBERS = [
  { name: 'Ana', color: '#38BDF8' },
  { name: 'Marc', color: '#A78BFA' },
  { name: 'Luna', color: '#F472B6' },
  { name: 'Kai', color: '#34D399' },
];
const ME = HOME_MEMBERS[0];

// ─────────────────────────────────────────────────────────────
// HoyScreenA — "Pulso"
// Full list organized by recurrence with a hero "mi turno" at top
// ─────────────────────────────────────────────────────────────
function HoyScreenA({ dark = true, isPremium = true, platform = 'ios' }) {
  const t = getTheme(dark);
  return (
    <div style={{ background: t.bg0, color: t.fg, minHeight: '100%', position: 'relative', paddingBottom: 110 }}>
      {/* ambient gradient */}
      <div style={{ position: 'absolute', inset: 0, background: t.meshA, pointerEvents: 'none' }}/>
      <div style={{ position: 'relative' }}>
        <TockaTopBar home="Piso Raval" members={HOME_MEMBERS} dark={dark} platform={platform}/>

        {/* HERO — mi turno ahora */}
        <div style={{ padding: '4px 16px 0' }}>
          <div style={{
            position: 'relative', borderRadius: 24, padding: '16px 16px 14px',
            background: `linear-gradient(165deg, ${t.bg2}, ${t.bg1})`,
            border: `1px solid ${t.accent}30`,
            overflow: 'hidden',
          }}>
            <div style={{
              position: 'absolute', top: -60, right: -40, width: 180, height: 180,
              background: `radial-gradient(closest-side, ${t.accentGlow}, transparent)`,
              pointerEvents: 'none',
            }}/>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
              <Pill color={t.accent} dark={dark} glow>
                <span style={{ width: 6, height: 6, borderRadius: '50%', background: t.accent, boxShadow: `0 0 6px ${t.accent}` }}/>
                Te toca ahora
              </Pill>
              <div style={{ flex: 1 }}/>
              <span style={{ fontFamily: FONT_MONO, fontSize: 10.5, color: t.fgSubtle, letterSpacing: 0.4 }}>
                09:42 · MAR 15
              </span>
            </div>
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
              <div style={{
                width: 56, height: 56, borderRadius: 16,
                background: `linear-gradient(135deg, ${t.accent}22, ${t.accent}06)`,
                border: `1px solid ${t.accent}44`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                boxShadow: `inset 0 0 24px ${t.accent}22`,
              }}>
                <TaskGlyph kind="ring" color={t.accent} size={30}/>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontFamily: FONT_DISPLAY, fontSize: 22, fontWeight: 700, letterSpacing: -0.6, lineHeight: 1.15 }}>
                  Sacar basura orgánica
                </div>
                <div style={{ fontSize: 12, color: t.fgMuted, marginTop: 4, fontFamily: FONT_SANS }}>
                  Vence en <span style={{ color: t.warning, fontWeight: 700, fontFamily: FONT_MONO }}>18 min</span> · semanal · rotación
                </div>
              </div>
            </div>
            <div style={{ display: 'flex', gap: 8, marginTop: 14 }}>
              <Btn variant="glow" size="md" dark={dark} full icon={<Icon d={ICO.check} size={16} sw={2.2}/>}>
                Hecha
              </Btn>
              <Btn variant="ghost" size="md" dark={dark} icon={<Icon d={ICO.skip} size={14}/>}>
                Pasar turno
              </Btn>
            </div>
          </div>
        </div>

        {/* Banner (Free plan) */}
        {!isPremium && (
          <div style={{ padding: '12px 16px 0' }}>
            <AdBanner dark={dark}/>
          </div>
        )}

        {/* BLOQUES */}
        <div style={{ padding: '4px 16px 0' }}>
          <BlockHeader label="HOY · HORA" count={2} dark={dark}/>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            <TaskCard title="Regar plantas del salón" assignee="Marc" assigneeColor="#A78BFA"
              when="cada 6h · vence 14:00" glyph="arcs" dark={dark}/>
            <TaskCard title="Revisar lavadora" assignee="Ana" assigneeColor="#38BDF8"
              when="vence 11:30" glyph="hex" mine dark={dark}/>
          </div>

          <BlockHeader label="HOY · DÍA" count={3} dark={dark}/>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            <TaskCard title="Cocinar cena" assignee="Luna" assigneeColor="#F472B6"
              when="20:30" glyph="tri" dark={dark}/>
            <TaskCard title="Fregar platos" assignee="Kai" assigneeColor="#34D399"
              when="después cena" glyph="diamond" dark={dark}/>
            <TaskCard title="Barrer cocina" assignee="Ana" assigneeColor="#38BDF8"
              when="flexible" glyph="square" mine dark={dark}/>
          </div>

          <BlockHeader label="ESTA SEMANA" count={4} dark={dark}/>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            <TaskCard title="Limpiar baño" assignee="Marc" assigneeColor="#A78BFA"
              when="jue" glyph="star4" dark={dark}/>
            <TaskCard title="Compra semanal" assignee="Luna" assigneeColor="#F472B6"
              when="sáb" glyph="plus" dark={dark}/>
          </div>

          <BlockHeader label="HECHAS · HOY" count={2} dark={dark}/>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            <TaskCard title="Tender la ropa" assignee="Ana" assigneeColor="#38BDF8" done
              when="09:12" glyph="ring" dark={dark}/>
            <TaskCard title="Desayuno equipo" assignee="Kai" assigneeColor="#34D399" done
              when="08:30" glyph="dot" dark={dark}/>
          </div>
        </div>
      </div>
      <TabBar active="hoy" dark={dark} platform={platform}/>
    </div>
  );
}

Object.assign(window, { HoyScreenA, HOME_MEMBERS, ME });
