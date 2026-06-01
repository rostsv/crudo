// Crudo - shared primitives, icons, store
const { useState, useEffect, useRef, useMemo, createContext, useContext } = React;

// ============================================================
// ICONS - light 1.5px stroke, Manrope-friendly
// ============================================================
const Icon = ({ d, size = 22, stroke = 1.5, fill = "none", color = "currentColor", children, ...rest }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill={fill} stroke={color}
       strokeWidth={stroke} strokeLinecap="round" strokeLinejoin="round" {...rest}>
    {d ? <path d={d} /> : children}
  </svg>
);

const Icons = {
  Home: (p) => <Icon {...p}><path d="M3 11l9-8 9 8"/><path d="M5 10v10h14V10"/></Icon>,
  Plan: (p) => <Icon {...p}><rect x="4" y="5" width="16" height="16" rx="2"/><path d="M4 9h16"/><path d="M9 3v4M15 3v4"/></Icon>,
  History: (p) => <Icon {...p}><path d="M3 12a9 9 0 1 0 3-6.7"/><path d="M3 4v5h5"/><path d="M12 8v4l3 2"/></Icon>,
  Profile: (p) => <Icon {...p}><circle cx="12" cy="8" r="4"/><path d="M4 21c0-4.4 3.6-8 8-8s8 3.6 8 8"/></Icon>,
  Plus: (p) => <Icon {...p}><path d="M12 5v14M5 12h14"/></Icon>,
  Check: (p) => <Icon {...p}><path d="M5 12l5 5 9-11"/></Icon>,
  X: (p) => <Icon {...p}><path d="M6 6l12 12M18 6l-12 12"/></Icon>,
  Back: (p) => <Icon {...p}><path d="M15 6l-6 6 6 6"/></Icon>,
  Chevron: (p) => <Icon {...p}><path d="M9 6l6 6-6 6"/></Icon>,
  ChevDown: (p) => <Icon {...p}><path d="M6 9l6 6 6-6"/></Icon>,
  Clock: (p) => <Icon {...p}><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></Icon>,
  Bell: (p) => <Icon {...p}><path d="M6 16V11a6 6 0 1 1 12 0v5l1.5 2h-15z"/><path d="M10 20a2 2 0 0 0 4 0"/></Icon>,
  Flame: (p) => <Icon {...p}><path d="M12 3c0 4 4 5 4 9a4 4 0 1 1-8 0c0-2 1-3 2-4 0 2 1 3 2 3-1-2 0-5 0-8z"/></Icon>,
  Snooze: (p) => <Icon {...p}><circle cx="12" cy="12" r="9"/><path d="M9 9h6l-6 6h6"/></Icon>,
  Swap: (p) => <Icon {...p}><path d="M7 4l-3 3 3 3"/><path d="M4 7h13a3 3 0 0 1 3 3"/><path d="M17 20l3-3-3-3"/><path d="M20 17H7a3 3 0 0 1-3-3"/></Icon>,
  Edit: (p) => <Icon {...p}><path d="M4 20h4l10-10-4-4L4 16v4z"/><path d="M14 6l4 4"/></Icon>,
  Trash: (p) => <Icon {...p}><path d="M4 7h16"/><path d="M9 7V4h6v3"/><path d="M6 7l1 13h10l1-13"/></Icon>,
  Settings: (p) => <Icon {...p}><circle cx="12" cy="12" r="3"/><path d="M19.4 14a7.97 7.97 0 0 0 0-4l2-1.5-2-3.5-2.4 1a8 8 0 0 0-3.4-2L13 2h-2l-.6 2a8 8 0 0 0-3.4 2L4.6 5l-2 3.5L4.6 10a7.97 7.97 0 0 0 0 4l-2 1.5 2 3.5 2.4-1a8 8 0 0 0 3.4 2l.6 2h2l.6-2a8 8 0 0 0 3.4-2l2.4 1 2-3.5z"/></Icon>,
  LogOut: (p) => <Icon {...p}><path d="M14 8V6a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h7a2 2 0 0 0 2-2v-2"/><path d="M9 12h12l-3-3M21 12l-3 3"/></Icon>,
  Search: (p) => <Icon {...p}><circle cx="11" cy="11" r="7"/><path d="M21 21l-5-5"/></Icon>,
  Carrot: (p) => <Icon {...p}><path d="M14 6l4-4 2 2-4 4"/><path d="M3 21l11-11 3 3-11 11-5 1z"/></Icon>,
  Lock: (p) => <Icon {...p}><rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></Icon>,
  Sparkle: (p) => <Icon {...p}><path d="M12 3l1.6 4.4L18 9l-4.4 1.6L12 15l-1.6-4.4L6 9l4.4-1.6z"/><path d="M19 14l.7 1.8L21.5 16l-1.8.7L19 18l-.7-1.8L16.5 16l1.8-.7z"/></Icon>,
  Calendar: (p) => <Icon {...p}><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18"/><path d="M8 3v4M16 3v4"/></Icon>,
  Filter: (p) => <Icon {...p}><path d="M3 5h18"/><path d="M6 12h12"/><path d="M10 19h4"/></Icon>,
  Trophy: (p) => <Icon {...p}><path d="M8 4h8v6a4 4 0 0 1-8 0V4z"/><path d="M16 6h3v2a3 3 0 0 1-3 3"/><path d="M8 6H5v2a3 3 0 0 0 3 3"/><path d="M10 14h4v3l-2 1-2-1z"/><path d="M9 21h6"/></Icon>,
  Apple: (p) => <Icon {...p}><path d="M16.5 3c-1 0-2 .5-2.5 1.5"/><path d="M12 7c-3 0-5 2-5 5 0 3 2 7 5 9 1 0 1.5-.5 2.5-.5s1.5.5 2.5.5c3-2 5-6 5-9 0-3-2-5-5-5-1 0-1.5.5-2.5.5S13 7 12 7z"/></Icon>,
  Egg: (p) => <Icon {...p}><path d="M12 3c-3 0-6 5-6 10 0 4 3 8 6 8s6-4 6-8c0-5-3-10-6-10z"/></Icon>,
  Beef: (p) => <Icon {...p}><path d="M12 3c-4 0-8 4-8 8 0 4 3 6 5 7l-1 3 3-1c.5 1 1.5 2 3 2 4 0 7-5 7-9s-4-10-9-10z"/></Icon>,
  Grain: (p) => <Icon {...p}><path d="M12 3v18"/><path d="M12 6c-2-1-4 0-4 2s2 3 4 3"/><path d="M12 6c2-1 4 0 4 2s-2 3-4 3"/><path d="M12 12c-2-1-4 0-4 2s2 3 4 3"/><path d="M12 12c2-1 4 0 4 2s-2 3-4 3"/></Icon>,
  Fish: (p) => <Icon {...p}><path d="M3 12c2-3 6-5 11-5 4 0 7 2 7 5s-3 5-7 5c-5 0-9-2-11-5z"/><path d="M3 12l-2-2 0 4z"/><circle cx="17" cy="11" r=".5" fill="currentColor"/></Icon>,
  Drop: (p) => <Icon {...p}><path d="M12 3c0 4-6 8-6 13a6 6 0 0 0 12 0c0-5-6-9-6-13z"/></Icon>,
  Info: (p) => <Icon {...p}><circle cx="12" cy="12" r="9"/><path d="M12 8h.01"/><path d="M11 12h1v5h1"/></Icon>,
  Star: (p) => <Icon {...p}><path d="M12 3l2.6 6.3L21 10l-5 4.5L17.5 21 12 17.5 6.5 21 8 14.5 3 10l6.4-.7z"/></Icon>,
  Crown: (p) => <Icon {...p}><path d="M3 8l4 4 5-7 5 7 4-4-2 12H5z"/></Icon>,
  TrendUp: (p) => <Icon {...p}><path d="M3 17l6-6 4 4 8-8"/><path d="M14 7h7v7"/></Icon>,
  Dots: (p) => <Icon {...p}><circle cx="6" cy="12" r="1.5" fill="currentColor"/><circle cx="12" cy="12" r="1.5" fill="currentColor"/><circle cx="18" cy="12" r="1.5" fill="currentColor"/></Icon>,
  Partial: (p) => <Icon {...p}><circle cx="12" cy="12" r="9"/><path d="M12 3a9 9 0 0 1 0 18z" fill="currentColor" stroke="none"/></Icon>,
  Warn: (p) => <Icon {...p}><path d="M12 3l10 18H2z"/><path d="M12 10v5"/><path d="M12 18h.01"/></Icon>,
};

window.Icons = Icons;

// ============================================================
// STATUS BAR (iOS-feel, but simpler — frame supplies its own)
// ============================================================
const FakeStatus = () => (
  <div style={{height: 44, display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                padding: '0 28px', fontSize: 15, fontWeight: 600, color: 'var(--on-surface)', flexShrink: 0}}>
    <span>9:41</span>
    <span style={{display: 'inline-flex', gap: 6, alignItems: 'center'}}>
      <svg width="18" height="11" viewBox="0 0 18 11" fill="currentColor"><path d="M1 8h2v3H1zM5 6h2v5H5zM9 4h2v7H9zM13 1h2v10h-2z"/></svg>
      <svg width="16" height="11" viewBox="0 0 16 11" fill="currentColor" opacity="0.95"><path d="M8 2.5c2.4 0 4.6.9 6.3 2.4l.7-.7C13.1 2.5 10.7 1.5 8 1.5S2.9 2.5 1 4.2l.7.7C3.4 3.4 5.6 2.5 8 2.5zm0 3a5.5 5.5 0 0 1 3.7 1.4l.7-.7A6.5 6.5 0 0 0 8 4.5c-1.7 0-3.3.6-4.4 1.7l.7.7A5.5 5.5 0 0 1 8 5.5zm2 2.4-2 2-2-2A2.8 2.8 0 0 1 8 7c.7 0 1.4.3 2 .9z"/></svg>
      <svg width="26" height="12" viewBox="0 0 26 12" fill="none">
        <rect x="0.5" y="0.5" width="22" height="11" rx="3" stroke="currentColor" opacity="0.4"/>
        <rect x="2" y="2" width="17" height="8" rx="1.5" fill="currentColor"/>
        <rect x="23" y="4" width="2" height="4" rx="1" fill="currentColor" opacity="0.4"/>
      </svg>
    </span>
  </div>
);
window.FakeStatus = FakeStatus;

// ============================================================
// MACRO RING
// ============================================================
const MacroRing = ({ size = 72, stroke = 2, value = 0.6, color = "var(--primary)", track = "rgba(63,73,71,0.18)" }) => {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  return (
    <svg width={size} height={size} className="macro-ring">
      <circle cx={size/2} cy={size/2} r={r} stroke={track} strokeWidth={stroke} />
      <circle cx={size/2} cy={size/2} r={r} stroke={color} strokeWidth={stroke}
              strokeDasharray={`${c * value} ${c}`} strokeLinecap="round" />
    </svg>
  );
};
window.MacroRing = MacroRing;

// ============================================================
// PROGRESS BAR (slim)
// ============================================================
const Progress = ({ value = 0.5, color = "var(--primary)", track = "var(--surface-high)", h = 4 }) => (
  <div style={{height: h, background: track, borderRadius: 999, overflow: 'hidden', width: '100%'}}>
    <div style={{height: '100%', width: `${Math.min(100, Math.max(0, value*100))}%`,
                 background: color, borderRadius: 999, transition: 'width .4s ease'}} />
  </div>
);
window.Progress = Progress;

// ============================================================
// TOGGLE
// ============================================================
const Toggle = ({ on, onChange }) => (
  <button className={`toggle ${on ? 'on' : ''}`} onClick={() => onChange?.(!on)} aria-pressed={on} />
);
window.Toggle = Toggle;

// ============================================================
// STEPPER
// ============================================================
const Stepper = ({ value, onChange, min = 0, max = 99, step = 1, suffix = '' }) => (
  <div className="stepper">
    <button onClick={() => onChange(Math.max(min, value - step))}>−</button>
    <span className="stepper-val">{value}{suffix}</span>
    <button onClick={() => onChange(Math.min(max, value + step))}>+</button>
  </div>
);
window.Stepper = Stepper;

// ============================================================
// APP STORE — minimal mock state
// ============================================================
const seedFoods = [
  { id: 'f1', name: 'Chicken Breast',     cat: 'meat',   p: 31, c: 0,  f: 3.6, kcal: 165, icon: 'Beef' },
  { id: 'f2', name: 'Salmon',             cat: 'fish',   p: 25, c: 0,  f: 13,  kcal: 208, icon: 'Fish' },
  { id: 'f3', name: 'Egg, whole',         cat: 'eggs',   p: 13, c: 1,  f: 11,  kcal: 155, icon: 'Egg' },
  { id: 'f4', name: 'Greek Yogurt',       cat: 'eggs',   p: 10, c: 4,  f: 0.4, kcal: 59,  icon: 'Egg' },
  { id: 'f5', name: 'Rice, white cooked', cat: 'grain',  p: 2.7,c: 28, f: 0.3, kcal: 130, icon: 'Grain' },
  { id: 'f6', name: 'Oats, dry',          cat: 'grain',  p: 17, c: 66, f: 7,   kcal: 389, icon: 'Grain' },
  { id: 'f7', name: 'Quinoa, cooked',     cat: 'grain',  p: 4.4,c: 21, f: 1.9, kcal: 120, icon: 'Grain' },
  { id: 'f8', name: 'Sweet Potato',       cat: 'veg',    p: 1.6,c: 20, f: 0.1, kcal: 86,  icon: 'Carrot' },
  { id: 'f9', name: 'Spinach',            cat: 'veg',    p: 2.9,c: 3.6,f: 0.4, kcal: 23,  icon: 'Carrot' },
  { id: 'f10',name: 'Avocado',            cat: 'fruit',  p: 2,  c: 9,  f: 15,  kcal: 160, icon: 'Apple' },
  { id: 'f11',name: 'Almonds',            cat: 'oil',    p: 21, c: 22, f: 50,  kcal: 579, icon: 'Drop' },
  { id: 'f12',name: 'Olive Oil',          cat: 'oil',    p: 0,  c: 0,  f: 100, kcal: 884, icon: 'Drop' },
  { id: 'f13',name: 'Banana',             cat: 'fruit',  p: 1.1,c: 23, f: 0.3, kcal: 89,  icon: 'Apple' },
  { id: 'f14',name: 'Blueberries',        cat: 'fruit',  p: 0.7,c: 14, f: 0.3, kcal: 57,  icon: 'Apple' },
];
window.seedFoods = seedFoods;

const seedMeals = [
  { id: 'm1', time: '08:00', name: 'Protein Bowl',   tags: ['Breakfast'],
    ingr: [{fid:'f3', g:120}, {fid:'f4', g:150}, {fid:'f6', g:60}, {fid:'f14', g:80}],
    status: 'done' },
  { id: 'm2', time: '12:30', name: 'Quinoa Salad',   tags: ['Lunch'],
    ingr: [{fid:'f7', g:200}, {fid:'f1', g:150}, {fid:'f9', g:80}, {fid:'f12', g:10}],
    status: 'partial' },
  { id: 'm3', time: '16:00', name: 'Pre-Workout',    tags: ['Snack','Pre-workout'],
    ingr: [{fid:'f13', g:120}, {fid:'f11', g:25}],
    status: 'upcoming' },
  { id: 'm4', time: '19:00', name: 'Baked Salmon',   tags: ['Dinner'],
    ingr: [{fid:'f2', g:180}, {fid:'f8', g:200}, {fid:'f9', g:100}, {fid:'f12', g:8}],
    status: 'upcoming' },
  { id: 'm5', time: '21:30', name: 'Casein Snack',   tags: ['Snack'],
    ingr: [{fid:'f4', g:200}, {fid:'f11', g:20}],
    status: 'upcoming' },
];
window.seedMeals = seedMeals;

// macro calculators
const ingrMacros = (i, foods) => {
  const f = foods.find(x => x.id === i.fid);
  if (!f) return {p:0,c:0,fa:0,kcal:0};
  const k = i.g / 100;
  return { p: f.p*k, c: f.c*k, fa: f.f*k, kcal: f.kcal*k };
};
const mealMacros = (m, foods) => m.ingr.reduce((acc,i) => {
  const x = ingrMacros(i, foods);
  return {p:acc.p+x.p, c:acc.c+x.c, fa:acc.fa+x.fa, kcal:acc.kcal+x.kcal};
}, {p:0,c:0,fa:0,kcal:0});
window.ingrMacros = ingrMacros;
window.mealMacros = mealMacros;

// ============================================================
// BOTTOM NAV
// ============================================================
const BottomNav = ({ tab, onTab }) => {
  const items = [
    { k: 'home',    label: 'Today',   I: Icons.Home },
    { k: 'plan',    label: 'Plans',   I: Icons.Plan },
    { k: 'history', label: 'History', I: Icons.History },
    { k: 'profile', label: 'Profile', I: Icons.Profile },
  ];
  return (
    <nav className="bottom-nav">
      {items.map(it => (
        <button key={it.k} className={`nav-item ${tab === it.k ? 'active' : ''}`} onClick={() => onTab(it.k)}>
          <it.I size={22} stroke={tab === it.k ? 2 : 1.5} />
          {it.label}
        </button>
      ))}
    </nav>
  );
};
window.BottomNav = BottomNav;

// ============================================================
// SCREEN HEADER (back + title + action)
// ============================================================
const ScreenHeader = ({ title, onBack, action, label }) => (
  <div style={{padding: '64px 24px 8px 24px', display: 'flex', alignItems: 'center',
                justifyContent: 'space-between', flexShrink: 0}}>
    <div style={{display: 'flex', alignItems: 'center', gap: 8}}>
      {onBack && (
        <button onClick={onBack} style={{width: 40, height: 40, borderRadius: 999,
                  display: 'inline-flex', alignItems: 'center', justifyContent: 'center'}}>
          <Icons.Back size={22} />
        </button>
      )}
      <div>
        {label && <div className="t-label" style={{marginBottom: 2}}>{label}</div>}
        <div style={{fontSize: 18, fontWeight: 700, letterSpacing: '-0.3px'}}>{title}</div>
      </div>
    </div>
    {action || <div style={{width: 40}} />}
  </div>
);
window.ScreenHeader = ScreenHeader;

// ============================================================
// ROUND BUTTON
// ============================================================
const IconBtn = ({ children, onClick, surface = 'var(--surface-low)', size = 40 }) => (
  <button onClick={onClick}
          style={{width: size, height: size, borderRadius: 999, background: surface,
                  display: 'inline-flex', alignItems: 'center', justifyContent: 'center'}}>
    {children}
  </button>
);
window.IconBtn = IconBtn;

Object.assign(window, {
  Icon, Icons, FakeStatus, MacroRing, Progress, Toggle, Stepper,
  BottomNav, ScreenHeader, IconBtn,
  seedFoods, seedMeals, ingrMacros, mealMacros,
});
