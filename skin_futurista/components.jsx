// Tocka — shared UI primitives
// TopBar, Banner, Buttons, Chips, Sparkline, ProgressRing, Radar, TaskCard, Stats, etc.

const AdBanner = ({ dark = true, style }) => {
  const t = getTheme(dark);
  return (
    <div style={{
      height: 56, borderRadius: 14, overflow: 'hidden', position: 'relative',
      background: dark ? '#111827' : '#F4F5F9',
      border: `1px solid ${t.line}`,
      display: 'flex', alignItems: 'center', gap: 10, padding: '0 10px',
      ...style,
    }}>
      <div style={{
        width: 38, height: 38, borderRadius: 8,
        background: 'linear-gradient(135deg,#34D399,#2563EB)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: '#fff', fontWeight: 800, fontFamily: FONT_DISPLAY, fontSize: 14, letterSpacing: -0.3,
      }}>Ao</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 11, fontFamily: FONT_MONO, color: t.fgSubtle, textTransform: 'uppercase', letterSpacing: 0.6 }}>Anuncio · AdMob</div>
        <div style={{ fontSize: 13, color: t.fg, fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
          Aora — Organiza tu casa 10× más rápido
        </div>
      </div>
      <button style={{
        height: 30, padding: '0 12px', borderRadius: 8, border: 'none',
        background: '#2563EB', color: '#fff', fontSize: 12, fontWeight: 600, fontFamily: FONT_SANS,
      }}>Instalar</button>
      <div style={{
        position: 'absolute', top: 4, left: 6,
        fontSize: 8.5, fontFamily: FONT_MONO, color: t.fgFaint, letterSpacing: 0.4,
      }}>AD</div>
    </div>
  );
};

// Pill / badge
const Pill = ({ children, color, dark = true, style, glow }) => {
  const t = getTheme(dark);
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 5,
      padding: '3px 9px', borderRadius: 999,
      background: color ? `${color}22` : t.bg3,
      color: color || t.fgMuted,
      fontFamily: FONT_SANS, fontSize: 11, fontWeight: 600, letterSpacing: 0.1,
      border: `1px solid ${color ? color + '30' : t.line}`,
      boxShadow: glow ? `0 0 20px ${color}33` : 'none',
      whiteSpace: 'nowrap',
      ...style,
    }}>{children}</span>
  );
};

// Avatar
const Avatar = ({ name = 'AA', color = '#38BDF8', size = 28, ring, dark = true }) => {
  const initials = name.split(' ').map(s => s[0]).slice(0, 2).join('').toUpperCase();
  return (
    <div style={{
      width: size, height: size, borderRadius: '50%',
      background: `linear-gradient(135deg, ${color}, ${color}AA)`,
      color: '#fff',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: FONT_DISPLAY, fontSize: size * 0.38, fontWeight: 700, letterSpacing: -0.3,
      boxShadow: ring ? `0 0 0 2px ${ring}, 0 0 0 4px rgba(56,189,248,0.25)` : 'none',
      flexShrink: 0,
    }}>{initials}</div>
  );
};

// Simple button
const Btn = ({ children, variant = 'primary', size = 'md', dark = true, full, onClick, style, icon }) => {
  const t = getTheme(dark);
  const sizes = {
    sm: { h: 32, px: 12, fs: 13 },
    md: { h: 42, px: 16, fs: 14 },
    lg: { h: 52, px: 20, fs: 15 },
  };
  const s = sizes[size];
  const variants = {
    primary: { bg: t.accent, color: dark ? '#001018' : '#fff', border: 'transparent' },
    ghost: { bg: 'transparent', color: t.fg, border: t.lineStrong },
    soft: { bg: t.bg3, color: t.fg, border: t.line },
    glow: { bg: `linear-gradient(180deg, ${t.accent}, ${t.accent}DD)`, color: '#001018', border: 'transparent', shadow: `0 8px 24px ${t.accentGlow}, inset 0 1px 0 rgba(255,255,255,.3)` },
    gold: { bg: 'linear-gradient(180deg,#F5B544,#D97706)', color: '#1A1000', border: 'transparent', shadow: '0 10px 28px rgba(245,181,68,.35)' },
    danger: { bg: 'transparent', color: t.danger, border: t.danger + '55' },
  };
  const v = variants[variant];
  return (
    <button onClick={onClick} style={{
      height: s.h, padding: `0 ${s.px}px`, borderRadius: 12,
      background: v.bg, color: v.color, border: `1px solid ${v.border}`,
      fontFamily: FONT_SANS, fontSize: s.fs, fontWeight: 600, letterSpacing: -0.1,
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      width: full ? '100%' : undefined, cursor: 'pointer',
      boxShadow: v.shadow || 'none',
      ...style,
    }}>
      {icon}
      {children}
    </button>
  );
};

// Chip (for filter rows)
const Chip = ({ children, active, dark = true, onClick }) => {
  const t = getTheme(dark);
  return (
    <button onClick={onClick} style={{
      height: 32, padding: '0 12px', borderRadius: 999,
      background: active ? t.accentSoft : 'transparent',
      color: active ? t.accent : t.fgMuted,
      border: `1px solid ${active ? t.accent + '55' : t.line}`,
      fontFamily: FONT_SANS, fontSize: 12.5, fontWeight: 600, letterSpacing: -0.05,
      display: 'inline-flex', alignItems: 'center', gap: 6, cursor: 'pointer',
      whiteSpace: 'nowrap',
    }}>{children}</button>
  );
};

// Tocka logo wordmark
const TockaMark = ({ size = 22, color = '#E8EEF7' }) => (
  <svg width={size * 1.2} height={size} viewBox="0 0 120 100" fill="none">
    <defs>
      <linearGradient id="tm" x1="0" x2="1"><stop offset="0" stopColor="#38BDF8"/><stop offset="1" stopColor="#A78BFA"/></linearGradient>
    </defs>
    <circle cx="50" cy="50" r="30" stroke="url(#tm)" strokeWidth="6" fill="none"/>
    <circle cx="82" cy="50" r="10" fill="url(#tm)"/>
  </svg>
);

const TockaWordmark = ({ color = '#E8EEF7', size = 17 }) => (
  <span style={{
    fontFamily: FONT_DISPLAY, fontSize: size, fontWeight: 800, color,
    letterSpacing: -0.8, display: 'inline-flex', alignItems: 'center', gap: 7,
  }}>
    <TockaMark size={size * 0.95}/> tocka
  </span>
);

// Task card used in Hoy
const TaskCard = ({
  title, assignee, assigneeColor = '#38BDF8', when, done, glyph = 'ring', glyphColor,
  urgent, overdue, mine, dark = true, compact,
}) => {
  const t = getTheme(dark);
  const gc = glyphColor || (urgent ? t.warning : (mine ? t.accent : t.fgMuted));
  return (
    <div style={{
      position: 'relative',
      background: done ? 'transparent' : t.bg2,
      border: `1px solid ${done ? t.line : (mine ? t.accent + '40' : t.line)}`,
      borderRadius: 16, padding: compact ? '10px 12px' : '14px 14px',
      display: 'flex', alignItems: 'center', gap: 12,
      boxShadow: mine && !done ? `0 0 0 1px ${t.accent}25, 0 16px 40px -20px ${t.accentGlow}` : 'none',
      opacity: done ? 0.7 : 1,
    }}>
      <div style={{
        width: 44, height: 44, borderRadius: 12, flexShrink: 0,
        background: done ? 'transparent' : `${gc}12`,
        border: `1px solid ${gc}30`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        position: 'relative',
      }}>
        {done
          ? <Icon d={ICO.check} size={20} stroke={t.success}/>
          : <TaskGlyph kind={glyph} color={gc} size={22}/>
        }
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontFamily: FONT_SANS, fontSize: 14.5, fontWeight: 600, color: t.fg,
          letterSpacing: -0.15,
          textDecoration: done ? 'line-through' : 'none',
          textDecorationColor: t.fgFaint,
        }}>{title}</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 3 }}>
          <span style={{ fontSize: 11.5, color: t.fgMuted, fontFamily: FONT_SANS }}>
            {done ? 'Hecho por' : 'Toca a'}
          </span>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 5 }}>
            <Avatar name={assignee} color={assigneeColor} size={16}/>
            <span style={{ fontSize: 12, fontWeight: 600, color: t.fg, fontFamily: FONT_SANS }}>{assignee}</span>
          </span>
          {when && (
            <span style={{
              fontSize: 11, color: overdue ? t.danger : t.fgSubtle, fontFamily: FONT_MONO, letterSpacing: 0.2,
            }}>· {when}</span>
          )}
        </div>
      </div>
      {mine && !done && (
        <button style={{
          width: 38, height: 38, borderRadius: 10, border: 'none', flexShrink: 0,
          background: `linear-gradient(180deg, ${t.accent}, ${t.accent}DD)`,
          color: '#001018',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: `0 6px 18px -6px ${t.accentGlow}, inset 0 1px 0 rgba(255,255,255,.3)`,
        }}>
          <Icon d={ICO.check} size={20} sw={2.2}/>
        </button>
      )}
      {!mine && !done && (
        <div style={{
          width: 38, height: 38, borderRadius: 10, flexShrink: 0,
          border: `1px solid ${t.line}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: t.fgFaint,
        }}>
          <Icon d={ICO.lock} size={14}/>
        </div>
      )}
    </div>
  );
};

// Bottom tab bar (iOS / Android-agnostic — looks native-ish)
const TabBar = ({ active = 'hoy', dark = true, platform = 'ios' }) => {
  const t = getTheme(dark);
  const items = [
    { k: 'hoy', label: 'Hoy', icon: ICO.home },
    { k: 'tareas', label: 'Tareas', icon: ICO.list },
    { k: 'hist', label: 'Historial', icon: ICO.history },
    { k: 'mem', label: 'Hogar', icon: ICO.users },
    { k: 'me', label: 'Yo', icon: ICO.user },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: platform === 'ios' ? 20 : 30, left: 10, right: 10,
      height: 64, borderRadius: 24, background: dark ? 'rgba(18,24,38,0.85)' : 'rgba(255,255,255,0.85)',
      backdropFilter: 'blur(24px) saturate(180%)', WebkitBackdropFilter: 'blur(24px) saturate(180%)',
      border: `1px solid ${t.lineStrong}`,
      display: 'flex', alignItems: 'center', justifyContent: 'space-around',
      padding: '0 10px',
      boxShadow: '0 20px 40px -10px rgba(0,0,0,.4), inset 0 1px 0 rgba(255,255,255,.06)',
      zIndex: 30,
    }}>
      {items.map(it => {
        const isA = it.k === active;
        return (
          <div key={it.k} style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
            color: isA ? t.accent : t.fgSubtle, position: 'relative',
          }}>
            {isA && <div style={{
              position: 'absolute', top: -6, width: 28, height: 3, borderRadius: 2,
              background: t.accent, boxShadow: `0 0 12px ${t.accentGlow}`,
            }}/>}
            <Icon d={it.icon} size={20} sw={isA ? 2 : 1.5}/>
            <span style={{ fontFamily: FONT_SANS, fontSize: 10.5, fontWeight: isA ? 700 : 500 }}>{it.label}</span>
          </div>
        );
      })}
    </div>
  );
};

// Section header (Hora, Día, etc.)
const BlockHeader = ({ label, count, dark = true }) => {
  const t = getTheme(dark);
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 10,
      padding: '18px 0 10px 2px',
    }}>
      <span style={{
        fontFamily: FONT_MONO, fontSize: 10.5, color: t.fgSubtle,
        textTransform: 'uppercase', letterSpacing: 2, fontWeight: 600,
      }}>{label}</span>
      <div style={{ flex: 1, height: 1, background: `linear-gradient(90deg, ${t.lineStrong}, transparent)` }}/>
      {count !== undefined && (
        <span style={{
          fontFamily: FONT_MONO, fontSize: 10.5, color: t.fgSubtle, letterSpacing: 0.4,
        }}>{String(count).padStart(2, '0')}</span>
      )}
    </div>
  );
};

// Progress ring
const Ring = ({ value = 0.8, size = 48, stroke = 4, color = '#38BDF8', track, dark = true, children }) => {
  const t = getTheme(dark);
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  return (
    <div style={{ width: size, height: size, position: 'relative' }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
        <circle cx={size/2} cy={size/2} r={r} stroke={track || t.bg3} strokeWidth={stroke} fill="none"/>
        <circle cx={size/2} cy={size/2} r={r} stroke={color} strokeWidth={stroke} fill="none"
          strokeDasharray={c} strokeDashoffset={c * (1 - value)} strokeLinecap="round"/>
      </svg>
      <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', color: t.fg, fontFamily: FONT_MONO, fontSize: size * 0.24, fontWeight: 700 }}>
        {children}
      </div>
    </div>
  );
};

// TopBar for inside-frame screens
const TockaTopBar = ({ home = 'Casa Barrio', members = [], dark = true, onMenu, extra, platform = 'ios' }) => {
  const t = getTheme(dark);
  return (
    <div style={{
      padding: platform === 'ios' ? '52px 16px 10px' : '14px 16px 10px',
      display: 'flex', alignItems: 'center', gap: 10, position: 'relative', zIndex: 20,
    }}>
      <button style={{
        display: 'flex', alignItems: 'center', gap: 8,
        padding: '8px 12px 8px 10px', borderRadius: 12,
        background: t.bg2, border: `1px solid ${t.line}`,
        color: t.fg, fontFamily: FONT_SANS, fontSize: 13, fontWeight: 700, letterSpacing: -0.1,
      }}>
        <span style={{ width: 8, height: 8, borderRadius: '50%', background: t.accent, boxShadow: `0 0 8px ${t.accent}` }}/>
        {home}
        <Icon d={ICO.chevronDown} size={14} stroke={t.fgMuted}/>
      </button>
      <div style={{ flex: 1 }}/>
      <div style={{ display: 'flex', marginRight: 4 }}>
        {members.slice(0, 3).map((m, i) => (
          <div key={i} style={{ marginLeft: i ? -8 : 0, outline: `2px solid ${t.bg0}`, borderRadius: '50%' }}>
            <Avatar name={m.name} color={m.color} size={26}/>
          </div>
        ))}
      </div>
      {extra}
    </div>
  );
};

Object.assign(window, {
  AdBanner, Pill, Avatar, Btn, Chip, TockaMark, TockaWordmark,
  TaskCard, TabBar, BlockHeader, Ring, TockaTopBar,
});
