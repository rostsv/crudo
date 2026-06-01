// Crudo - Today (Home) screen
const { useState: useState_t, useMemo: useMemo_t } = React;

const TodayScreen = ({ onOpenMeal, onOpenSheet, meals, foods, streak = 12 }) => {
  // calorie totals
  const totals = useMemo_t(() => {
    let plannedKcal = 0, consumedKcal = 0;
    let plannedP = 0, plannedC = 0, plannedF = 0;
    let consP = 0, consC = 0, consF = 0;
    meals.forEach(m => {
      const mm = mealMacros(m, foods);
      plannedKcal += mm.kcal; plannedP += mm.p; plannedC += mm.c; plannedF += mm.fa;
      if (m.status === 'done')    { consumedKcal += mm.kcal; consP += mm.p; consC += mm.c; consF += mm.fa; }
      if (m.status === 'partial') { consumedKcal += mm.kcal*0.6; consP += mm.p*0.6; consC += mm.c*0.6; consF += mm.fa*0.6; }
    });
    return {plannedKcal, consumedKcal, plannedP, plannedC, plannedF, consP, consC, consF};
  }, [meals, foods]);

  const done = meals.filter(m => m.status === 'done').length;
  const partial = meals.filter(m => m.status === 'partial').length;
  const total = meals.length;

  // day picker (today index 4)
  const days = [
    { d: 1, lbl: 'Mon' }, { d: 2, lbl: 'Tue' }, { d: 3, lbl: 'Wed' },
    { d: 4, lbl: 'Thu' }, { d: 6, lbl: 'Fri', active: true }, { d: 6, lbl: 'Sat' }, { d: 7, lbl: 'Sun' },
  ];

  return (
    <div className="app-screen" data-screen-label="Today">
      <FakeStatus />
      <div className="appbar">
        <div>
          <div className="t-label" style={{color: 'var(--on-surface-mut)'}}>Friday, May 8</div>
          <div style={{fontSize: 22, fontWeight: 700, letterSpacing: '-0.4px', marginTop: 2}}>Good morning, Mark</div>
        </div>
        <IconBtn onClick={() => onOpenSheet('calendar')} size={42}>
          <Icons.Calendar size={20} />
        </IconBtn>
      </div>

      <div className="scrollable" style={{paddingBottom: 110}}>
        {/* Day picker */}
        <div style={{display: 'flex', gap: 8, padding: '20px 24px 0', overflowX: 'auto'}}>
          {days.map((d, i) => (
            <div key={i} className={`day-pill ${d.active ? 'active' : ''}`}>
              <span className="day-num">{d.d + 3}</span>
              <span className="day-lbl">{d.lbl.slice(0,1)}</span>
            </div>
          ))}
        </div>

        {/* Hero summary card */}
        <div style={{margin: '24px 16px 0 24px', position: 'relative'}}>
          <div style={{borderRadius: 'var(--r-xl)', background: 'var(--surface-lowest)',
                       padding: '28px 28px 24px', boxShadow: 'var(--shadow-cloud)'}}>
            <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start'}}>
              <div>
                <div className="t-label">Today's Intake</div>
                <div style={{display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 8}}>
                  <span style={{fontSize: 56, fontWeight: 700, letterSpacing: '-2px', lineHeight: 1, color: 'var(--on-surface)'}}>
                    {Math.round(totals.consumedKcal)}
                  </span>
                  <span style={{fontSize: 16, fontWeight: 500, color: 'var(--on-surface-mut)'}}>
                    /{Math.round(totals.plannedKcal)} kcal
                  </span>
                </div>
              </div>
              <div style={{position: 'relative', width: 72, height: 72,
                           display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
                <MacroRing size={72} stroke={2.5}
                           value={totals.consumedKcal / Math.max(1, totals.plannedKcal)} />
                <Icons.Flame size={22} color="var(--primary)" stroke={1.5}
                             style={{position: 'absolute'}} />
              </div>
            </div>

            {/* Macro mini bars */}
            <div style={{display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 16, marginTop: 24}}>
              {[
                {k:'Protein', v: totals.consP, t: totals.plannedP, c: 'var(--primary)'},
                {k:'Carbs',   v: totals.consC, t: totals.plannedC, c: 'var(--gold)'},
                {k:'Fats',    v: totals.consF, t: totals.plannedF, c: '#9a7e4e'},
              ].map(m => (
                <div key={m.k}>
                  <div style={{display:'flex', justifyContent:'space-between', alignItems:'baseline', marginBottom: 6}}>
                    <span style={{fontSize: 11, fontWeight: 600, color: 'var(--on-surface-var)'}}>{m.k}</span>
                    <span style={{fontSize: 11, fontWeight: 700, color: 'var(--on-surface)'}}>{Math.round(m.v)}<span style={{color:'var(--on-surface-mut)', fontWeight:500}}>/{Math.round(m.t)}g</span></span>
                  </div>
                  <Progress value={m.v / Math.max(1, m.t)} color={m.c} h={3} />
                </div>
              ))}
            </div>
          </div>

          {/* Streak inset chip */}
          <div onClick={() => onOpenSheet('streak')}
               style={{position: 'absolute', top: -12, right: 28,
                       background: 'linear-gradient(135deg, #1a3d3a, var(--primary))',
                       color: 'white', borderRadius: 999, padding: '6px 12px 6px 8px',
                       display: 'inline-flex', alignItems: 'center', gap: 6,
                       boxShadow: 'var(--shadow-cloud)', cursor: 'pointer'}}>
            <Icons.Flame size={14} color="#e9b949" stroke={2} fill="#e9b949"/>
            <span style={{fontSize: 12, fontWeight: 700, letterSpacing: '0.3px'}}>{streak}-day streak</span>
          </div>
        </div>

        {/* Meals progress strip */}
        <div style={{margin: '32px 32px 8px', display: 'flex', justifyContent: 'space-between', alignItems: 'baseline'}}>
          <h2 style={{margin: 0, fontSize: 22, fontWeight: 700, letterSpacing: '-0.4px'}}>Meals</h2>
          <span className="t-label">{done}/{total} complete{partial > 0 ? ` · ${partial} partial` : ''}</span>
        </div>

        {/* Meal list */}
        <div style={{padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 10}}>
          {meals.map(m => <MealCard key={m.id} meal={m} foods={foods} onOpen={() => onOpenMeal(m)} />)}
        </div>

        {/* End-of-day nudge */}
        <div style={{margin: '24px 24px 0', padding: '20px 24px',
                     borderRadius: 'var(--r-lg)', background: 'var(--surface-low)',
                     display: 'flex', gap: 14, alignItems: 'center'}}>
          <div style={{width: 40, height: 40, borderRadius: 999, background: 'var(--primary-container)',
                       display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0}}>
            <Icons.Sparkle size={20} color="var(--primary)"/>
          </div>
          <div style={{flex: 1}}>
            <div style={{fontSize: 14, fontWeight: 700}}>You're 60% of the way there.</div>
            <div className="t-body" style={{fontSize: 12, marginTop: 2}}>
              Two meals remain. A done day keeps the streak.
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

const statusMeta = {
  done:     { label: 'DONE',     color: 'var(--primary)',    bar: 'var(--primary-soft)',  dot: 'var(--primary-soft)' },
  partial:  { label: 'PARTIAL',  color: '#8a6b1a',           bar: 'var(--gold)',          dot: 'var(--gold)' },
  upcoming: { label: 'UPCOMING', color: 'var(--on-surface-mut)', bar: 'rgba(0,77,73,0.18)', dot: 'rgba(111,121,119,0.4)' },
  skipped:  { label: 'SKIPPED',  color: 'var(--error)',      bar: 'rgba(186,26,26,0.4)',  dot: 'var(--error)' },
};

const MealCard = ({ meal, foods, onOpen }) => {
  const macros = mealMacros(meal, foods);
  const meta = statusMeta[meal.status];
  const ingrPreview = meal.ingr.slice(0, 3).map(i => foods.find(f => f.id === i.fid)?.name).filter(Boolean).join(' · ');
  const more = meal.ingr.length - 3;

  return (
    <div onClick={onOpen} className="tap"
         style={{background: 'var(--surface-lowest)', borderRadius: 'var(--r-lg)', padding: 18,
                 display: 'flex', alignItems: 'stretch', gap: 16,
                 boxShadow: '0 1px 0 rgba(26,28,26,0.02)'}}>
      {/* Time bar */}
      <div style={{display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: 10, paddingTop: 4}}>
        <div style={{width: 4, height: 44, borderRadius: 999, background: meta.bar}} />
      </div>
      <div style={{flex: 1, minWidth: 0}}>
        <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
          <span className="t-label" style={{fontSize: 10, color: 'var(--on-surface-mut)'}}>
            {meal.time} · {meal.tags[0]}
          </span>
          <span className="t-label" style={{fontSize: 10, color: meta.color}}>{meta.label}</span>
        </div>
        <div style={{fontSize: 18, fontWeight: 700, marginTop: 4, letterSpacing: '-0.2px',
                     color: meal.status === 'upcoming' ? 'var(--on-surface)' : meal.status === 'skipped' ? 'var(--on-surface-mut)' : 'var(--on-surface)'}}>
          {meal.name}
        </div>
        <div style={{fontSize: 12, color: 'var(--on-surface-mut)', marginTop: 4, lineHeight: '18px'}}>
          {ingrPreview}{more > 0 && ` · +${more} more`}
        </div>
        <div style={{display: 'flex', gap: 14, marginTop: 10, fontSize: 11, color: 'var(--on-surface-var)', fontWeight: 600}}>
          <span><b style={{color:'var(--on-surface)'}}>{Math.round(macros.kcal)}</b> kcal</span>
          <span style={{color:'var(--on-surface-mut)'}}>P {Math.round(macros.p)}g</span>
          <span style={{color:'var(--on-surface-mut)'}}>C {Math.round(macros.c)}g</span>
          <span style={{color:'var(--on-surface-mut)'}}>F {Math.round(macros.fa)}g</span>
        </div>
      </div>
      {/* Status circle */}
      <div style={{display: 'flex', alignItems: 'center'}}>
        {meal.status === 'done' && (
          <div style={{width: 36, height: 36, borderRadius: 999,
                       background: 'linear-gradient(135deg, var(--primary), var(--primary-soft))',
                       display: 'inline-flex', alignItems: 'center', justifyContent: 'center'}}>
            <Icons.Check size={18} color="white" stroke={2.5} />
          </div>
        )}
        {meal.status === 'partial' && (
          <div style={{width: 36, height: 36, borderRadius: 999, background: 'var(--gold)',
                       display: 'inline-flex', alignItems: 'center', justifyContent: 'center'}}>
            <Icons.Partial size={18} color="white" stroke={2.2} />
          </div>
        )}
        {meal.status === 'upcoming' && (
          <div style={{width: 36, height: 36, borderRadius: 999, background: 'transparent',
                       boxShadow: 'inset 0 0 0 1.5px rgba(111,121,119,0.3)',
                       display: 'inline-flex', alignItems: 'center', justifyContent: 'center'}}>
            <Icons.Clock size={18} color="var(--on-surface-mut)" stroke={1.5} />
          </div>
        )}
        {meal.status === 'skipped' && (
          <div style={{width: 36, height: 36, borderRadius: 999, background: 'var(--error-soft)',
                       display: 'inline-flex', alignItems: 'center', justifyContent: 'center'}}>
            <Icons.X size={18} color="var(--error)" stroke={2} />
          </div>
        )}
      </div>
    </div>
  );
};

window.TodayScreen = TodayScreen;
window.MealCard = MealCard;
window.statusMeta = statusMeta;
