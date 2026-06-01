// Crudo - Sheets / Popups / Modals
const { useState: useStateSH, useEffect: useEffectSH, useMemo: useMemoSH } = React;

// ============================================================
// SNOOZE SHEET
// ============================================================
const SnoozeSheet = ({ onClose, onConfirm }) => {
  const [val, setVal] = useStateSH(15);
  const opts = [10, 15, 20, 30];
  return (
    <div className="sheet-backdrop" onClick={onClose}>
      <div className="sheet" onClick={(e) => e.stopPropagation()}>
        <div className="sheet-grabber" />
        <div style={{ padding: '4px 4px 8px' }}>
          <div className="t-label">Commitment</div>
          <h2 style={{ margin: '6px 0 8px', fontSize: 28, fontWeight: 700, letterSpacing: '-0.6px' }}>Snooze, then eat.</h2>
          <p className="t-body" style={{ margin: 0 }}>Short delay only — can't push past your next meal.</p>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr', gap: 10, marginTop: 24 }}>
          {opts.map((m) =>
          <button key={m} onClick={() => setVal(m)}
          style={{ padding: '20px 0', borderRadius: 'var(--r-md)',
            background: val === m ? 'var(--primary)' : 'var(--surface-low)',
            color: val === m ? 'white' : 'var(--on-surface)',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
              <span style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.6px' }}>{m}</span>
              <span style={{ fontSize: 10, letterSpacing: '1.2px', textTransform: 'uppercase', fontWeight: 700, opacity: 0.7 }}>min</span>
            </button>
          )}
        </div>

        <div style={{ marginTop: 24, display: 'flex', gap: 10 }}>
          <button className="btn-secondary" style={{ flex: 1 }} onClick={onClose}>Cancel</button>
          <button className="btn-primary" style={{ flex: 2 }} onClick={() => onConfirm(val)}>Snooze {val}m</button>
        </div>
      </div>
    </div>);

};

// ============================================================
// SWAP MEAL SHEET — pick from library
// ============================================================
const SwapSheet = ({ library, foods, onClose, onSwap }) =>
<div className="sheet-backdrop" onClick={onClose}>
    <div className="sheet" onClick={(e) => e.stopPropagation()} style={{ maxHeight: '80%' }}>
      <div className="sheet-grabber" />
      <div style={{ padding: '4px 4px 16px' }}>
        <div className="t-label">From your library</div>
        <h2 style={{ margin: '6px 0', fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px' }}>Swap meal</h2>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
        {library.map((m) => {
        const mm = mealMacros(m, foods);
        return (
          <button key={m.id} onClick={() => onSwap(m)}
          style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '14px 16px',
            background: 'var(--surface-lowest)', borderRadius: 'var(--r-md)',
            textAlign: 'left' }}>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 15, fontWeight: 600 }}>{m.name}</div>
                <div style={{ fontSize: 11, color: 'var(--on-surface-mut)', marginTop: 2, fontWeight: 500 }}>
                  {m.tags.join(' · ')} · {Math.round(mm.kcal)} kcal · {m.ingr.length} ingredients
                </div>
              </div>
              <Icons.Swap size={18} color="var(--primary)" />
            </button>);

      })}
      </div>
    </div>
  </div>;


// ============================================================
// REMINDERS SHEET
// ============================================================
const RemindersSheet = ({ onClose, prefs, setPref }) => {
  const [pre, setPre] = useStateSH(prefs.preMin || 15);
  return (
    <div className="sheet-backdrop" onClick={onClose}>
      <div className="sheet" onClick={(e) => e.stopPropagation()}>
        <div className="sheet-grabber" />
        <div style={{ padding: '4px 4px 16px' }}>
          <div className="t-label">Notifications</div>
          <h2 style={{ margin: '6px 0', fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px' }}>How we ping you</h2>
        </div>

        <div style={{ background: 'var(--surface-lowest)', borderRadius: 'var(--r-lg)', padding: '4px 8px' }}>
          <ToggleRow label="Pre-meal heads up" sub={`${pre} minutes before each meal`}
          on={prefs.preOn} onChange={(v) => setPref('preOn', v)} />
          <ToggleRow label="At meal time" sub="Time to eat [meal name]"
          on={prefs.atOn} onChange={(v) => setPref('atOn', v)} />
          <ToggleRow label="No-action warning" sub="Before auto-skip kicks in"
          on={prefs.warnOn} onChange={(v) => setPref('warnOn', v)} />
          <ToggleRow label="End of day summary" sub="9:30 PM recap & streak status"
          on={prefs.eodOn} onChange={(v) => setPref('eodOn', v)} />
          <ToggleRow label="Streak at risk" sub="If falling behind mid-day"
          on={prefs.riskOn} onChange={(v) => setPref('riskOn', v)} />
        </div>

        <div style={{ marginTop: 16, padding: '20px 24px', background: 'var(--surface-low)', borderRadius: 'var(--r-lg)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <div style={{ fontSize: 14, fontWeight: 600 }}>Pre-meal lead</div>
              <div style={{ fontSize: 12, color: 'var(--on-surface-mut)', marginTop: 2 }}>How many minutes ahead</div>
            </div>
            <Stepper value={pre} onChange={setPre} min={5} max={60} step={5} suffix="m" />
          </div>
        </div>

        <div style={{ marginTop: 20 }}>
          <button className="btn-primary" onClick={() => {setPref('preMin', pre);onClose();}}>Save</button>
        </div>
      </div>
    </div>);

};
const ToggleRow = ({ label, sub, on, onChange }) =>
<div style={{ padding: '14px 12px', display: 'flex', alignItems: 'center', gap: 12 }}>
    <div style={{ flex: 1, minWidth: 0 }}>
      <div style={{ fontSize: 14, fontWeight: 600 }}>{label}</div>
      {sub && <div style={{ fontSize: 12, color: 'var(--on-surface-mut)', marginTop: 2, fontWeight: 500 }}>{sub}</div>}
    </div>
    <Toggle on={on} onChange={onChange} />
  </div>;


// ============================================================
// PAYWALL SHEET
// ============================================================
const PaywallSheet = ({ onClose, streak = 12, mealsDone = 142 }) => {
  const [plan, setPlan] = useStateSH('annual');
  return (
    <div className="sheet-modal-backdrop" onClick={onClose}>
      <div className="sheet-modal" onClick={(e) => e.stopPropagation()}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <div style={{ width: 48, height: 48, borderRadius: 999,
            background: 'linear-gradient(135deg, var(--primary), var(--primary-soft))',
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }} data-comment-anchor="1a09b9ecb8-div-139-11">
            <Icons.Crown size={24} color="#e9b949" stroke={1.5} />
          </div>
          <button onClick={onClose}><Icons.X size={20} color="var(--on-surface-mut)" /></button>
        </div>

        <h2 style={{ margin: '20px 0 8px', fontSize: 30, fontWeight: 700, letterSpacing: '-0.8px', lineHeight: '34px' }}>
          You completed {mealsDone} meals and built a {streak}-day streak.
        </h2>
        <p className="t-body" style={{ margin: 0 }}>Don't let it stop here.</p>

        <div style={{ marginTop: 24, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <PlanOpt id="annual" label="Annual" price="€39.99" sub="€3.33/mo · save 50%"
          selected={plan === 'annual'} onSelect={() => setPlan('annual')} badge="BEST VALUE" />
          <PlanOpt id="monthly" label="Monthly" price="€6.99" sub="billed every month"
          selected={plan === 'monthly'} onSelect={() => setPlan('monthly')} />
        </div>

        <button className="btn-primary" style={{ marginTop: 20 }}>
          {plan === 'annual' ? 'Continue with Annual' : 'Continue with Monthly'}
        </button>
        <p style={{ fontSize: 11, color: 'var(--on-surface-mut)', textAlign: 'center', marginTop: 12, fontWeight: 500 }}>
          5-day free trial. Cancel anytime.
        </p>
      </div>
    </div>);

};
const PlanOpt = ({ label, price, sub, selected, onSelect, badge }) =>
<button onClick={onSelect}
style={{ padding: '18px 20px', borderRadius: 'var(--r-md)', textAlign: 'left',
  background: selected ? 'var(--surface-lowest)' : 'var(--surface-low)',
  boxShadow: selected ? 'inset 0 0 0 2px var(--primary)' : 'none',
  display: 'flex', alignItems: 'center', gap: 14, position: 'relative' }}>
    <div style={{ width: 22, height: 22, borderRadius: 999,
    background: selected ? 'var(--primary)' : 'transparent',
    boxShadow: selected ? 'none' : 'inset 0 0 0 2px var(--surface-high)',
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
      {selected && <Icons.Check size={14} color="white" stroke={3} />}
    </div>
    <div style={{ flex: 1, minWidth: 0 }}>
      <div style={{ fontSize: 15, fontWeight: 700 }}>{label}</div>
      <div style={{ fontSize: 12, color: 'var(--on-surface-mut)', marginTop: 2, fontWeight: 500 }}>{sub}</div>
    </div>
    <div style={{ textAlign: 'right' }}>
      <div style={{ fontSize: 18, fontWeight: 700, letterSpacing: '-0.3px' }}>{price}</div>
    </div>
    {badge && <div style={{ position: 'absolute', top: -10, right: 16,
    background: 'var(--gold)', color: 'white',
    fontSize: 9, fontWeight: 800, letterSpacing: '1px',
    padding: '4px 8px', borderRadius: 999 }}>{badge}</div>}
  </button>;


// ============================================================
// STREAK AT RISK ALERT
// ============================================================
const StreakRiskSheet = ({ onClose }) =>
<div className="sheet-modal-backdrop" onClick={onClose}>
    <div className="sheet-modal" onClick={(e) => e.stopPropagation()} style={{ textAlign: 'center' }}>
      <div style={{ margin: '0 auto', width: 80, height: 80, borderRadius: 999,
      background: 'rgba(233,185,73,0.15)',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
        <Icons.Flame size={40} color="var(--gold)" stroke={2} />
      </div>
      <div className="t-label" style={{ color: 'var(--gold)', marginTop: 16 }}>Streak at risk</div>
      <h2 style={{ margin: '6px 16px 8px', fontSize: 26, fontWeight: 700, letterSpacing: '-0.6px', lineHeight: '32px' }}>
        Two meals left to keep 12 days alive.
      </h2>
      <p className="t-body" style={{ margin: '0 8px' }}>Pre-Workout at 4:00 PM — 32 minutes from now.</p>
      <button className="btn-primary" style={{ marginTop: 24 }} onClick={onClose}>Got it</button>
      <button onClick={onClose} style={{ marginTop: 8, padding: 12, fontSize: 12,
      letterSpacing: '1.2px', textTransform: 'uppercase',
      fontWeight: 700, color: 'var(--on-surface-mut)', width: '100%' }}>
        Mute today
      </button>
    </div>
  </div>;


// ============================================================
// CONFIRM (logout etc.)
// ============================================================
const ConfirmSheet = ({ title, body, primary, onClose, onConfirm, danger }) =>
<div className="sheet-modal-backdrop" onClick={onClose}>
    <div className="sheet-modal" onClick={(e) => e.stopPropagation()}>
      <h2 style={{ margin: 0, fontSize: 22, fontWeight: 700, letterSpacing: '-0.4px' }}>{title}</h2>
      <p className="t-body" style={{ marginTop: 8 }}>{body}</p>
      <div style={{ marginTop: 20, display: 'flex', gap: 10 }}>
        <button className="btn-secondary" style={{ flex: 1 }} onClick={onClose}>Cancel</button>
        <button className="btn-primary" style={{ flex: 1,
        background: danger ? 'linear-gradient(135deg, #8a1414, var(--error))' : undefined }}
      onClick={onConfirm}>{primary}</button>
      </div>
    </div>
  </div>;


// ============================================================
// REVIEW PROMPT
// ============================================================
const ReviewSheet = ({ onClose }) => {
  const [stars, setStars] = useStateSH(0);
  return (
    <div className="sheet-modal-backdrop" onClick={onClose}>
      <div className="sheet-modal" onClick={(e) => e.stopPropagation()} style={{ textAlign: 'center' }}>
        <div style={{ display: 'flex', justifyContent: 'center', gap: 4, marginBottom: 16 }}>
          {[1, 2, 3, 4, 5].map((n) =>
          <button key={n} onClick={() => setStars(n)}>
              <Icons.Star size={36} color={n <= stars ? 'var(--gold)' : 'var(--surface-high)'}
            fill={n <= stars ? 'var(--gold)' : 'transparent'} />
            </button>
          )}
        </div>
        <h2 style={{ margin: '0 16px 8px', fontSize: 22, fontWeight: 700, letterSpacing: '-0.4px' }}>
          Enjoying Crudo?
        </h2>
        <p className="t-body" style={{ margin: '0 8px' }}>You finished your first full day. Mind sharing how it's going?</p>
        <button className="btn-primary" style={{ marginTop: 20 }} disabled={stars === 0} onClick={onClose}>Submit</button>
        <button onClick={onClose} style={{ marginTop: 8, padding: 12, fontSize: 12,
          letterSpacing: '1.2px', textTransform: 'uppercase', fontWeight: 700,
          color: 'var(--on-surface-mut)', width: '100%' }}>Not now</button>
      </div>
    </div>);

};

// ============================================================
// CALENDAR SHEET — month grid with per-day stats
// ============================================================
const CalendarSheet = ({ onClose }) => {
  // Build a deterministic 30-day stat history ending "today" (May 8, Fri)
  const today = { y: 2025, m: 4, d: 8 }; // month 0-indexed: May
  const monthLabel = 'May 2025';
  const daysInMonth = 31;
  const firstDow = 4; // May 1, 2025 is Thursday → 0=Mon → 3
  const startCol = (firstDow + 6) % 7; // shift Sun→last; we use Mon-first

  // Seeded pseudo-data per day
  const stats = useMemoSH(() => {
    const out = {};
    for (let d = 1; d <= daysInMonth; d++) {
      if (d > today.d) {out[d] = null;continue;}
      // deterministic
      const seed = (d * 9301 + 49297) % 233280;
      const rand = seed / 233280;
      const meals = 5;
      let done;
      if (d === today.d) done = 2;else
      if (rand > 0.85) done = 2;else
      if (rand > 0.7) done = 3;else
      if (rand > 0.45) done = 4;else
      done = 5;
      const pct = done / meals;
      out[d] = {
        meals, done, pct,
        kcal: 1800 + Math.round(rand * 600),
        status: pct === 1 ? 'done' : pct >= 0.6 ? 'partial' : 'red'
      };
    }
    return out;
  }, []);

  const [selected, setSelected] = useStateSH(today.d);
  const sel = stats[selected];

  // Monthly aggregates
  const agg = useMemoSH(() => {
    let kept = 0,missed = 0,partial = 0,totalKcal = 0,count = 0;
    Object.values(stats).forEach((s) => {
      if (!s) return;
      count++;
      totalKcal += s.kcal;
      if (s.status === 'done') kept++;else
      if (s.status === 'partial') partial++;else
      missed++;
    });
    return { kept, missed, partial, avgKcal: count ? Math.round(totalKcal / count) : 0, count };
  }, [stats]);

  const cells = [];
  for (let i = 0; i < startCol; i++) cells.push(null);
  for (let d = 1; d <= daysInMonth; d++) cells.push(d);

  return (
    <div className="sheet-backdrop" onClick={onClose}>
      <div className="sheet" onClick={(e) => e.stopPropagation()} style={{ maxHeight: '92%' }}>
        <div className="sheet-grabber" />
        <div style={{ padding: '4px 4px 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <div className="t-label">Last 30 days</div>
            <h2 style={{ margin: '6px 0 0', fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px' }}>{monthLabel}</h2>
          </div>
          <button onClick={onClose} style={{ width: 36, height: 36, borderRadius: 999, background: 'var(--surface-low)',
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
            <Icons.X size={18} color="var(--on-surface-var)" />
          </button>
        </div>

        {/* Day-of-week header */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 4, marginTop: 4, marginBottom: 6 }}>
          {['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d, i) =>
          <div key={i} className="t-label" style={{ fontSize: 9, textAlign: 'center', opacity: 0.6 }}>{d}</div>
          )}
        </div>

        {/* Calendar grid */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 4 }}>
          {cells.map((d, i) => {
            if (!d) return <div key={i} style={{ aspectRatio: '1' }} />;
            const s = stats[d];
            const isSel = d === selected;
            const isToday = d === today.d;
            const future = !s;
            const bg = future ? 'transparent' :
            s.status === 'done' ? 'var(--primary)' :
            s.status === 'partial' ? 'var(--gold)' :
            'var(--error-soft)';
            const fg = future ? 'var(--on-surface-mut)' :
            s.status === 'red' ? 'var(--error)' :
            'white';
            return (
              <button key={i} onClick={() => !future && setSelected(d)}
              style={{ aspectRatio: '1', borderRadius: 12,
                background: bg,
                color: fg,
                boxShadow: isSel ? '0 0 0 2px var(--on-surface)' : isToday ? 'inset 0 0 0 2px var(--on-surface)' : 'none',
                fontSize: 13, fontWeight: 700,
                opacity: future ? 0.35 : 1,
                display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 2 }}>
                <span>{d}</span>
                {s && <span style={{ width: 4, height: 4, borderRadius: 999,
                  background: s.status === 'red' ? 'var(--error)' : 'rgba(255,255,255,0.7)' }} />}
              </button>);

          })}
        </div>

        {/* Selected-day detail */}
        {sel &&
        <div style={{ marginTop: 20, padding: '20px 22px', background: 'var(--surface-lowest)',
          borderRadius: 'var(--r-lg)', boxShadow: 'var(--shadow-cloud)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <div>
                <div className="t-label">May {selected}</div>
                <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: '-0.4px', marginTop: 4 }}>
                  {sel.done}/{sel.meals} meals
                </div>
              </div>
              <span className="t-label" style={{
              color: sel.status === 'done' ? 'var(--primary)' : sel.status === 'partial' ? '#8a6b1a' : 'var(--error)'
            }}>{sel.status === 'done' ? 'COMPLETE' : sel.status === 'partial' ? 'PARTIAL' : 'MISSED'}</span>
            </div>
            <div style={{ marginTop: 14 }}>
              <Progress value={sel.pct}
            color={sel.status === 'done' ? 'var(--primary)' : sel.status === 'partial' ? 'var(--gold)' : 'var(--error)'}
            h={6} />
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginTop: 16 }}>
              <div>
                <div className="t-label" style={{ fontSize: 9 }}>Calories</div>
                <div style={{ fontSize: 18, fontWeight: 700, marginTop: 2 }}>{sel.kcal}<span style={{ fontSize: 11, color: 'var(--on-surface-mut)', fontWeight: 500 }}> kcal</span></div>
              </div>
              <div>
                <div className="t-label" style={{ fontSize: 9 }}>Adherence</div>
                <div style={{ fontSize: 18, fontWeight: 700, marginTop: 2 }}>{Math.round(sel.pct * 100)}%</div>
              </div>
            </div>
          </div>
        }

        {/* Monthly summary */}
        <div style={{ marginTop: 16, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
          <SmallStat k="KEPT" v={agg.kept} c="var(--primary)" />
          <SmallStat k="PARTIAL" v={agg.partial} c="#8a6b1a" />
          <SmallStat k="MISSED" v={agg.missed} c="var(--error)" />
        </div>

        {/* Legend */}
        <div style={{ marginTop: 16, padding: '12px 16px', display: 'flex', gap: 16, justifyContent: 'center',
          fontSize: 10, fontWeight: 700, letterSpacing: '0.5px', color: 'var(--on-surface-mut)' }}>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
            <span style={{ width: 10, height: 10, borderRadius: 3, background: 'var(--primary)' }} /> KEPT
          </span>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
            <span style={{ width: 10, height: 10, borderRadius: 3, background: 'var(--gold)' }} /> PARTIAL
          </span>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
            <span style={{ width: 10, height: 10, borderRadius: 3, background: 'var(--error-soft)', boxShadow: 'inset 0 0 0 1px var(--error)' }} /> MISSED
          </span>
        </div>
      </div>
    </div>);

};
const SmallStat = ({ k, v, c }) =>
<div style={{ padding: '14px 12px', background: 'var(--surface-low)', borderRadius: 'var(--r-md)', textAlign: 'center' }}>
    <div className="t-label" style={{ fontSize: 9 }}>{k}</div>
    <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: '-0.4px', marginTop: 4, color: c }}>{v}</div>
  </div>;


// ============================================================
// PLAN DAYS EDITOR — pick days, validate overlap with other plans
// ============================================================
const dayInitialsPE = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const dayNamesPE = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

const PlanDaysEditorSheet = ({ plan, allPlans, onClose, onSave, onConflict }) => {
  const [days, setDays] = useStateSH(plan.days || []);

  // overlap detection: for each day in `days`, find other ACTIVE plans that include it
  const conflicts = useMemoSH(() => {
    const out = [];
    days.forEach((d) => {
      allPlans.forEach((p) => {
        if (p.id === plan.id) return;
        if (p.days.includes(d)) out.push({ day: d, plan: p });
      });
    });
    return out;
  }, [days, allPlans, plan.id]);

  const toggleDay = (i) => {
    setDays((d) => d.includes(i) ? d.filter((x) => x !== i) : [...d, i].sort());
  };

  const handleSave = () => {
    if (conflicts.length > 0) {
      onConflict(conflicts);
      return;
    }
    onSave(days);
  };

  return (
    <div className="sheet-backdrop" onClick={onClose}>
      <div className="sheet" onClick={(e) => e.stopPropagation()}>
        <div className="sheet-grabber" />
        <div style={{ padding: '4px 4px 16px' }}>
          <div className="t-label">Schedule</div>
          <h2 style={{ margin: '6px 0 4px', fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px' }}>Repeats on</h2>
          <p className="t-body" style={{ margin: 0 }}>Tap days to assign this plan.</p>
        </div>

        {/* Day grid */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 6, marginTop: 8 }}>
          {dayInitialsPE.map((d, i) => {
            const on = days.includes(i);
            const conflictDay = conflicts.some((c) => c.day === i);
            return (
              <button key={i} onClick={() => toggleDay(i)}
              style={{ height: 56, borderRadius: 16, fontSize: 16, fontWeight: 700,
                background: on ? 'var(--primary)' : 'var(--surface-low)',
                color: on ? 'white' : 'var(--on-surface-mut)',
                boxShadow: conflictDay ? 'inset 0 0 0 2px var(--error)' : 'none',
                transition: 'all .15s ease' }}>
                {d}
              </button>);

          })}
        </div>

        {/* Conflict warning inline */}
        {conflicts.length > 0 &&
        <div style={{ marginTop: 16, padding: '14px 16px', background: 'var(--error-soft)',
          borderRadius: 'var(--r-md)', display: 'flex', gap: 12, alignItems: 'flex-start' }}>
            <Icons.Warn size={20} color="var(--error)" stroke={2} />
            <div>
              <div style={{ fontSize: 13, fontWeight: 700, color: 'var(--error)' }}>
                Overlap on {conflicts.length === 1 ? dayNamesPE[conflicts[0].day] : `${conflicts.length} days`}
              </div>
              <div style={{ fontSize: 12, color: 'var(--on-surface-var)', marginTop: 2, fontWeight: 500 }}>
                {[...new Set(conflicts.map((c) => c.plan.name))].join(', ')} already covers {conflicts.length === 1 ? 'this day' : 'these'}.
              </div>
            </div>
          </div>
        }

        <div style={{ marginTop: 20, display: 'flex', gap: 10 }}>
          <button className="btn-secondary" style={{ flex: 1 }} onClick={onClose}>Cancel</button>
          <button className="btn-primary" style={{ flex: 2 }} onClick={handleSave}>
            Save{days.length > 0 && ` · ${days.length} day${days.length > 1 ? 's' : ''}`}
          </button>
        </div>
      </div>
    </div>);

};

// ============================================================
// TOAST / ERROR — bottom-of-screen banner
// ============================================================
const Toast = ({ kind = 'error', title, body, onDismiss }) => {
  useEffectSH(() => {
    if (!onDismiss) return;
    const t = setTimeout(onDismiss, 4500);
    return () => clearTimeout(t);
  }, [onDismiss]);
  const palette = {
    error: { bg: '#1a1c1a', accent: 'var(--error)', icon: <Icons.Warn size={20} color="white" stroke={2} /> },
    warn: { bg: '#1a1c1a', accent: 'var(--gold)', icon: <Icons.Warn size={20} color="white" stroke={2} /> },
    success: { bg: '#1a1c1a', accent: 'var(--primary-soft)', icon: <Icons.Check size={20} color="white" stroke={2.5} /> }
  }[kind];
  return (
    <div style={{ position: 'absolute', left: 16, right: 16, bottom: 100, zIndex: 50,
      animation: 'slideUp .25s cubic-bezier(.2,.9,.3,1)' }}>
      <div style={{ background: palette.bg, color: 'white', borderRadius: 'var(--r-md)',
        padding: '14px 16px', display: 'flex', gap: 12, alignItems: 'flex-start',
        boxShadow: '0 20px 40px rgba(26,28,26,0.25)',
        borderLeft: `3px solid ${palette.accent}` }} data-comment-anchor="49126755fa-div-548-7">
        {palette.icon}
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 13, fontWeight: 700 }}>{title}</div>
          {body && <div style={{ fontSize: 12, opacity: 0.75, marginTop: 2, fontWeight: 500, lineHeight: '17px' }}>{body}</div>}
        </div>
        {onDismiss &&
        <button onClick={onDismiss} style={{ padding: 2 }}>
            <Icons.X size={16} color="rgba(255,255,255,0.7)" />
          </button>
        }
      </div>
    </div>);

};

// ============================================================
// CONFLICT MODAL — formal blocking error for overlap
// ============================================================
const ConflictSheet = ({ conflicts, onClose, onResolve }) =>
<div className="sheet-modal-backdrop" onClick={onClose}>
    <div className="sheet-modal" onClick={(e) => e.stopPropagation()}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
        <div style={{ width: 48, height: 48, borderRadius: 999, background: 'var(--error-soft)',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
          <Icons.Warn size={24} color="var(--error)" stroke={2} />
        </div>
        <div style={{ flex: 1 }}>
          <div className="t-label" style={{ color: 'var(--error)' }}>Schedule conflict</div>
          <div style={{ fontSize: 18, fontWeight: 700, marginTop: 2, letterSpacing: '-0.3px' }}>
            Two plans on the same day
          </div>
        </div>
      </div>
      <p className="t-body" style={{ marginTop: 16 }}>
        Each day can only run one plan. Resolve the overlap before saving:
      </p>
      <div style={{ marginTop: 14, display: 'flex', flexDirection: 'column', gap: 6 }}>
        {[...new Set(conflicts.map((c) => `${dayNamesPE[c.day]}|${c.plan.name}`))].map((s, i) => {
        const [day, planName] = s.split('|');
        return (
          <div key={i} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center',
            padding: '12px 14px', background: 'var(--surface-low)', borderRadius: 'var(--r-sm)' }}>
              <span style={{ fontSize: 13, fontWeight: 700 }}>{day}</span>
              <span style={{ fontSize: 12, color: 'var(--on-surface-mut)', fontWeight: 600 }}>covered by {planName}</span>
            </div>);

      })}
      </div>
      <div style={{ marginTop: 20, display: 'flex', gap: 10 }}>
        <button className="btn-secondary" style={{ flex: 1 }} onClick={onClose}>Go back</button>
        <button className="btn-primary" style={{ flex: 1 }} onClick={onResolve}>Override</button>
      </div>
    </div>
  </div>;


window.SnoozeSheet = SnoozeSheet;
window.SwapSheet = SwapSheet;
window.RemindersSheet = RemindersSheet;
window.PaywallSheet = PaywallSheet;
window.StreakRiskSheet = StreakRiskSheet;
window.ConfirmSheet = ConfirmSheet;
window.ReviewSheet = ReviewSheet;
window.CalendarSheet = CalendarSheet;
window.PlanDaysEditorSheet = PlanDaysEditorSheet;
window.ConflictSheet = ConflictSheet;
window.Toast = Toast;