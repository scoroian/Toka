// Tocka — icon system
// Minimal line icons + geometric task glyphs. 1.5px stroke.

const Icon = ({ d, size = 20, stroke = 'currentColor', sw = 1.5, fill = 'none', style, viewBox = '0 0 24 24' }) => (
  <svg width={size} height={size} viewBox={viewBox} fill={fill} stroke={stroke}
    strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round" style={style}>
    {d}
  </svg>
);

const ICO = {
  plus: <path d="M12 5v14M5 12h14"/>,
  check: <path d="M4 12l5 5L20 6"/>,
  close: <path d="M6 6l12 12M18 6L6 18"/>,
  chevronRight: <path d="M9 6l6 6-6 6"/>,
  chevronDown: <path d="M6 9l6 6 6-6"/>,
  chevronLeft: <path d="M15 6l-6 6 6 6"/>,
  clock: <><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></>,
  calendar: <><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18M8 3v4M16 3v4"/></>,
  bell: <path d="M6 16V11a6 6 0 1112 0v5l1.5 2h-15L6 16zM10 20a2 2 0 004 0"/>,
  home: <path d="M3 12l9-8 9 8M5 10v10h14V10"/>,
  user: <><circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 3.5-7 8-7s8 3 8 7"/></>,
  users: <><circle cx="9" cy="8" r="3.5"/><path d="M2 20c0-3.5 3-6 7-6s7 2.5 7 6"/><path d="M16 5a3 3 0 110 6M18 20c0-3-2-5.5-4-6.3"/></>,
  list: <path d="M4 6h16M4 12h16M4 18h16"/>,
  grid: <><rect x="3" y="3" width="7" height="7" rx="1.2"/><rect x="14" y="3" width="7" height="7" rx="1.2"/><rect x="3" y="14" width="7" height="7" rx="1.2"/><rect x="14" y="14" width="7" height="7" rx="1.2"/></>,
  settings: <><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 00.3 1.8l.1.1a2 2 0 11-2.8 2.8l-.1-.1a1.65 1.65 0 00-1.8-.3 1.65 1.65 0 00-1 1.5V21a2 2 0 11-4 0v-.1a1.65 1.65 0 00-1-1.5 1.65 1.65 0 00-1.8.3l-.1.1a2 2 0 11-2.8-2.8l.1-.1a1.65 1.65 0 00.3-1.8 1.65 1.65 0 00-1.5-1H3a2 2 0 110-4h.1a1.65 1.65 0 001.5-1 1.65 1.65 0 00-.3-1.8l-.1-.1a2 2 0 112.8-2.8l.1.1a1.65 1.65 0 001.8.3H9a1.65 1.65 0 001-1.5V3a2 2 0 114 0v.1a1.65 1.65 0 001 1.5 1.65 1.65 0 001.8-.3l.1-.1a2 2 0 112.8 2.8l-.1.1a1.65 1.65 0 00-.3 1.8V9a1.65 1.65 0 001.5 1H21a2 2 0 110 4h-.1a1.65 1.65 0 00-1.5 1z"/></>,
  search: <><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></>,
  filter: <path d="M3 5h18l-7 9v5l-4 2v-7L3 5z"/>,
  arrow: <path d="M5 12h14M13 6l6 6-6 6"/>,
  arrowLeft: <path d="M19 12H5M11 6l-6 6 6 6"/>,
  skip: <path d="M5 5l7 7-7 7M13 5l7 7-7 7"/>,
  sparkle: <path d="M12 3l2.2 6.2L20 12l-5.8 2.2L12 21l-2.2-6.8L4 12l5.8-2.5L12 3z"/>,
  crown: <path d="M3 18h18M4 8l4 4 4-7 4 7 4-4-1 10H5L4 8z"/>,
  shield: <path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6l8-3z"/>,
  more: <><circle cx="5" cy="12" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="19" cy="12" r="1.5"/></>,
  moreV: <><circle cx="12" cy="5" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="12" cy="19" r="1.5"/></>,
  edit: <path d="M4 20h4l11-11-4-4L4 16v4zM14 6l4 4"/>,
  trash: <path d="M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13"/>,
  flame: <path d="M12 3c1 4 5 5 5 10a5 5 0 11-10 0c0-3 2-4 2-7 2 1 3 2 3 4l0-7z"/>,
  stats: <path d="M3 20h18M6 20V10M11 20V6M16 20v-7M21 20v-3"/>,
  radar: <><circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1.5" fill="currentColor"/><path d="M12 3v18M3 12h18"/></>,
  lock: <><rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 118 0v3"/></>,
  snowflake: <path d="M12 3v18M3 12h18M6 6l12 12M18 6L6 18"/>,
  ghost: <path d="M5 20V10a7 7 0 1114 0v10l-2-1.5L15 20l-2-1.5L11 20l-2-1.5L7 20l-2 0zM9 10h.01M15 10h.01"/>,
  moon: <path d="M21 13A9 9 0 1111 3a7 7 0 0010 10z"/>,
  sun: <><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4 12H2M22 12h-2M5 5l1.5 1.5M17.5 17.5L19 19M5 19l1.5-1.5M17.5 6.5L19 5"/></>,
  mail: <><rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 7l9 7 9-7"/></>,
  apple: <path d="M16 2c-1.5.1-3 1-4 2 1 0 2.5-1 4-2zm2 7c-1 0-2.5 1-4 1-1.5 0-3-1-5-1-3 0-5 2.5-5 6 0 4 3 8 5 8 1 0 2-1 3-1s2 1 3 1c2 0 5-4 5-8 0-3-1-5-2-6z"/>,
  google: <path d="M12 11v3h5c-.3 2-2 4-5 4-3 0-5.5-2.5-5.5-6S9 6 12 6c1.5 0 2.8.6 3.8 1.5l2-2C16 4 14 3 12 3 6.5 3 3 7 3 12s3.5 9 9 9c5 0 8.5-3.5 8.5-9 0-.4 0-.7-.1-1H12z" fill="currentColor" stroke="none"/>,
  dots3: <><circle cx="5" cy="12" r="1.2" fill="currentColor" stroke="none"/><circle cx="12" cy="12" r="1.2" fill="currentColor" stroke="none"/><circle cx="19" cy="12" r="1.2" fill="currentColor" stroke="none"/></>,
  history: <><path d="M3 12a9 9 0 109-9 9 9 0 00-7 3.5L3 3v6h6"/><path d="M12 8v4l3 2"/></>,
  stopwatch: <><path d="M10 2h4M12 6v0"/><circle cx="12" cy="13" r="8"/><path d="M12 9v4l3 2"/></>,
  wave: <path d="M3 12c3 0 3-4 6-4s3 8 6 8 3-4 6-4"/>,
};

// Geometric task glyphs — small, abstract, futuristic
const TaskGlyph = ({ kind = 'ring', color = '#38BDF8', size = 20 }) => {
  const g = {
    ring: <><circle cx="12" cy="12" r="7" stroke={color} strokeWidth="1.7" fill="none"/><circle cx="12" cy="12" r="2" fill={color}/></>,
    tri: <path d="M12 4l9 16H3L12 4z" stroke={color} strokeWidth="1.7" fill="none"/>,
    hex: <path d="M12 3l8 5v8l-8 5-8-5V8l8-5z" stroke={color} strokeWidth="1.7" fill="none"/>,
    square: <rect x="5" y="5" width="14" height="14" rx="2" stroke={color} strokeWidth="1.7" fill="none"/>,
    plus: <path d="M12 4v16M4 12h16" stroke={color} strokeWidth="1.7"/>,
    diamond: <path d="M12 3l9 9-9 9-9-9 9-9z" stroke={color} strokeWidth="1.7" fill="none"/>,
    star4: <path d="M12 3l2 8 8 1-8 1-2 8-2-8-8-1 8-1 2-8z" stroke={color} strokeWidth="1.4" fill="none" strokeLinejoin="round"/>,
    arcs: <><path d="M5 12a7 7 0 0114 0" stroke={color} strokeWidth="1.7" fill="none"/><path d="M19 12a7 7 0 01-14 0" stroke={color} strokeWidth="1.7" strokeDasharray="2 3" fill="none"/></>,
    dot: <circle cx="12" cy="12" r="6" fill={color}/>,
    cross: <path d="M6 6l12 12M6 18L18 6" stroke={color} strokeWidth="1.7"/>,
  };
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      {g[kind] || g.ring}
    </svg>
  );
};

Object.assign(window, { Icon, ICO, TaskGlyph });
