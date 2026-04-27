// Tocka — Design tokens
// Futurista, atractivo, minimalista. Dark-first con light alternativo.

const TOKENS = {
  dark: {
    // surfaces
    bg0: '#07090E',        // deep space
    bg1: '#0B0F16',        // panel bg
    bg2: '#121826',        // elevated surface
    bg3: '#1A2235',        // raised card
    line: 'rgba(226,232,240,0.08)',
    lineStrong: 'rgba(226,232,240,0.16)',
    // text
    fg: '#E8EEF7',
    fgMuted: 'rgba(226,232,240,0.64)',
    fgSubtle: 'rgba(226,232,240,0.42)',
    fgFaint: 'rgba(226,232,240,0.22)',
    // brand accent
    accent: '#38BDF8',          // sky cyan
    accentSoft: 'rgba(56,189,248,0.14)',
    accentGlow: 'rgba(56,189,248,0.35)',
    // semantic
    success: '#34D399',
    warning: '#F5B544',
    danger: '#FB7185',
    premium: '#F5B544',         // gold
    // gradients
    meshA: 'radial-gradient(1200px 600px at 10% -10%, rgba(56,189,248,0.18), transparent 60%), radial-gradient(800px 400px at 110% 10%, rgba(148,163,184,0.08), transparent 60%)',
  },
  light: {
    bg0: '#F6F7FB',
    bg1: '#FFFFFF',
    bg2: '#FFFFFF',
    bg3: '#F1F3F8',
    line: 'rgba(15,23,42,0.08)',
    lineStrong: 'rgba(15,23,42,0.14)',
    fg: '#0B1220',
    fgMuted: 'rgba(11,18,32,0.62)',
    fgSubtle: 'rgba(11,18,32,0.44)',
    fgFaint: 'rgba(11,18,32,0.22)',
    accent: '#0284C7',
    accentSoft: 'rgba(2,132,199,0.10)',
    accentGlow: 'rgba(2,132,199,0.24)',
    success: '#059669',
    warning: '#B45309',
    danger: '#E11D48',
    premium: '#B45309',
    meshA: 'radial-gradient(1000px 500px at 10% -10%, rgba(2,132,199,0.10), transparent 60%)',
  },
};

const FONT_SANS = "'Satoshi', 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif";
const FONT_DISPLAY = "'Satoshi', 'Inter', -apple-system, system-ui, sans-serif";
const FONT_MONO = "'JetBrains Mono', 'SF Mono', ui-monospace, Menlo, monospace";

// Shared helpers
const getTheme = (dark) => (dark ? TOKENS.dark : TOKENS.light);

Object.assign(window, { TOKENS, FONT_SANS, FONT_DISPLAY, FONT_MONO, getTheme });
