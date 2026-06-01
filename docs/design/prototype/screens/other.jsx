// Crudo - Plans, History, Profile screens
const { useState: useStatePL, useMemo: useMemoPL } = React;

// ============================================================
// PLANS LIST
// ============================================================
const PlansScreen = ({ plans, onOpenPlan, onCreate }) => {
  return (
    <div className="app-screen" data-screen-label="Plans">
      <FakeStatus />
      <div className="appbar">
        <div>
          <div className="t-label">Library</div>
          <div style={{fontSize: 28, fontWeight: 700, letterSpacing: '-0.7px', marginTop: 4}}>Plans</div>
        </div>
        <IconBtn onClick={onCreate} size={42} surface="var(--primary-container)">
          <Icons.Plus size={20} color="var(--primary)" stroke={2} />
        </IconBtn>
      </div>

      <div className="scrollable" style={{paddingBottom: 110}}>
        <div style={{margin: '24px 24px 0', padding: '20px 24px',
                     background: 'var(--surface-low)', borderRadius: 'var(--r-lg)',
                     display: 'flex', gap: 14, alignItems: 'flex-start'}}>
          <Icons.Info size={20} color="var(--primary)" />
          <div>
            <div style={{fontSize: 13, fontWeight: 700}}>One plan repeats daily</div>
            <div className="t-body" style={{fontSize: 12, marginTop: 2}}>Assign different plans to specific days for variety.</div>
          </div>
        </div>

        <div style={{padding: '20px 16px', display: 'flex', flexDirection: 'column', gap: 12}}>
          {plans.map(p => <PlanCard key={p.id} plan={p}
                            onOpen={() => onOpenPlan(p)} />)}
        </div>
      </div>
    </div>
  );
};

const dayInitials = ['M','T','W','T','F','S','S'];
const PlanCard = ({ plan, onOpen }) => (
  <div onClick={onOpen} className="tap"
       style={{background: 'var(--surface-lowest)', borderRadius: 'var(--r-lg)',
               padding: '22px 24px', boxShadow: '0 1px 0 rgba(26,28,26,0.02)', cursor: 'pointer'}}>
    <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start'}}>
      <div style={{flex: 1, minWidth: 0}}>
        <div style={{display: 'flex', alignItems: 'center', gap: 8}}>
          <span className="t-label" style={{fontSize: 10}}>{plan.tag}</span>
          {plan.active && <span style={{fontSize: 10, fontWeight: 800, letterSpacing: '1.3px',
                                        color: 'var(--primary)'}}>· ACTIVE</span>}
        </div>
        <div style={{fontSize: 22, fontWeight: 700, letterSpacing: '-0.4px', marginTop: 6}}>{plan.name}</div>
        <div style={{fontSize: 12, color: 'var(--on-surface-mut)', marginTop: 4, fontWeight: 500}}>
          {plan.meals} meals · {plan.kcal} kcal · P{plan.p}/C{plan.c}/F{plan.f}
        </div>
      </div>
      <Icons.Chevron size={18} color="var(--on-surface-mut)" />
    </div>
    {/* Day chips — read-only on the list */}
    <div style={{display: 'flex', gap: 4, marginTop: 16}}>
      {dayInitials.map((d, i) => (
        <div key={i} style={{
          flex: 1, height: 28, borderRadius: 999,
          background: plan.days.includes(i) ? 'var(--primary)' : 'var(--surface-low)',
          color: plan.days.includes(i) ? 'white' : 'var(--on-surface-mut)',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 11, fontWeight: 700,
        }}>{d}</div>
      ))}
    </div>
    {plan.days.length === 0 && (
      <div style={{marginTop: 8, fontSize: 11, color: 'var(--on-surface-mut)', fontWeight: 600,
                    letterSpacing: '0.5px', textAlign: 'center'}}>
        Open plan to schedule
      </div>
    )}
  </div>
);

// ============================================================
// PLAN DETAIL — meal slots, macro overview
// ============================================================
const PlanDetailScreen = ({ plan, meals, foods, onBack, onAddMeal, onOpenMeal, onEditDays, onRename }) => {
  const totals = meals.reduce((acc, m) => {
    const mm = mealMacros(m, foods);
    return {kcal: acc.kcal + mm.kcal, p: acc.p + mm.p, c: acc.c + mm.c, fa: acc.fa + mm.fa};
  }, {kcal:0,p:0,c:0,fa:0});

  return (
    <div className="app-screen" data-screen-label="Plan detail">
      <FakeStatus />
      <ScreenHeader title={plan.name} label="PLAN" onBack={onBack}
                    action={<IconBtn><Icons.Dots size={20} /></IconBtn>} />

      <div className="scrollable" style={{paddingBottom: 120}}>
        {/* Macro hero */}
        <div style={{margin: '12px 24px 0', padding: '28px 28px 24px',
                     background: 'linear-gradient(135deg, var(--primary), var(--primary-soft))',
                     color: 'white', borderRadius: 'var(--r-xl)'}}>
          <div className="t-label" style={{color: 'rgba(255,255,255,0.6)'}}>Daily target</div>
          <div style={{display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 6}}>
            <span style={{fontSize: 56, fontWeight: 700, letterSpacing: '-2px', lineHeight: 1}}>{Math.round(totals.kcal)}</span>
            <span style={{fontSize: 14, opacity: 0.7}}>kcal</span>
          </div>
          <div style={{display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 12, marginTop: 28}}>
            {[
              {k:'PROTEIN', v: totals.p, ratio: 0.4},
              {k:'CARBS',   v: totals.c, ratio: 0.45},
              {k:'FATS',    v: totals.fa, ratio: 0.7},
            ].map(m => (
              <div key={m.k}>
                <div style={{fontSize: 9, letterSpacing: '1.5px', fontWeight: 700, opacity: 0.6}}>{m.k}</div>
                <div style={{fontSize: 18, fontWeight: 700, marginTop: 4}}>{Math.round(m.v)}<span style={{fontSize: 10, opacity: 0.7, fontWeight: 500}}>g</span></div>
                <div style={{height: 2, background: 'rgba(255,255,255,0.18)', borderRadius: 999, marginTop: 8}}>
                  <div style={{height: '100%', width: `${m.ratio*100}%`, background: 'rgba(255,255,255,0.9)', borderRadius: 999}} />
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Day assignment — tappable, opens editor */}
        <div style={{margin: '24px 32px 0'}}>
          <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'baseline'}}>
            <div className="t-label">Repeats on</div>
            <button onClick={onEditDays}
                    style={{fontSize: 11, fontWeight: 700, letterSpacing: '1.2px',
                             textTransform: 'uppercase', color: 'var(--primary)'}}>
              Edit
            </button>
          </div>
          <button onClick={onEditDays} className="tap"
                  style={{display: 'flex', gap: 4, marginTop: 10, width: '100%',
                          padding: 0, background: 'transparent', textAlign: 'left'}}>
            {dayInitials.map((d, i) => (
              <div key={i} style={{
                flex: 1, height: 36, borderRadius: 999,
                background: plan.days.includes(i) ? 'var(--primary)' : 'var(--surface-low)',
                color: plan.days.includes(i) ? 'white' : 'var(--on-surface-mut)',
                display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 13, fontWeight: 700,
              }}>{d}</div>
            ))}
          </button>
        </div>

        {/* Meal slots */}
        <div style={{margin: '32px 32px 12px', display: 'flex', justifyContent: 'space-between', alignItems: 'baseline'}}>
          <h3 style={{margin: 0, fontSize: 18, fontWeight: 700}}>Meal slots</h3>
          <span className="t-label">{meals.length} SLOTS</span>
        </div>

        <div style={{padding: '0 16px'}}>
          {meals.map((m, idx) => {
            const mm = mealMacros(m, foods);
            return (
              <button key={m.id} onClick={() => onOpenMeal(m)}
                      style={{display: 'flex', alignItems: 'center', gap: 16, padding: '16px',
                              width: '100%', borderRadius: 'var(--r-md)', textAlign: 'left',
                              background: idx % 2 ? 'var(--surface-low)' : 'transparent'}}>
                <div style={{minWidth: 56}}>
                  <div style={{fontSize: 16, fontWeight: 700, color: 'var(--primary)'}}>{m.time}</div>
                </div>
                <div style={{flex: 1, minWidth: 0}}>
                  <div style={{fontSize: 15, fontWeight: 600}}>{m.name}</div>
                  <div style={{fontSize: 11, color: 'var(--on-surface-mut)', marginTop: 2, fontWeight: 500}}>
                    {m.tags.join(' · ')} · {Math.round(mm.kcal)} kcal
                  </div>
                </div>
                <Icons.Chevron size={16} color="var(--on-surface-mut)" />
              </button>
            );
          })}
        </div>

        <button onClick={onAddMeal}
                style={{margin: '16px 24px 0', padding: '16px',
                        background: 'var(--surface-low)', width: 'calc(100% - 48px)',
                        borderRadius: 'var(--r-md)', display: 'flex', alignItems: 'center',
                        justifyContent: 'center', gap: 8, fontSize: 13, fontWeight: 700,
                        color: 'var(--primary)', letterSpacing: '1px', textTransform: 'uppercase'}}>
          <Icons.Plus size={16} stroke={2} /> Add meal slot
        </button>
      </div>
    </div>
  );
};

// ============================================================
// HISTORY SCREEN
// ============================================================
const HistoryScreen = () => {
  const week = [
    {d:'Mon', pct: 100, status: 'done'},
    {d:'Tue', pct: 100, status: 'done'},
    {d:'Wed', pct: 80,  status: 'done'},
    {d:'Thu', pct: 60,  status: 'red'},
    {d:'Fri', pct: 100, status: 'done'},
    {d:'Sat', pct: 90,  status: 'done'},
    {d:'Sun', pct: 60,  status: 'today'},
  ];
  const months = [
    {d:'Apr 30', pct: 100, meals: '5/5'},
    {d:'Apr 29', pct: 80,  meals: '4/5'},
    {d:'Apr 28', pct: 100, meals: '5/5'},
    {d:'Apr 27', pct: 60,  meals: '3/5'},
    {d:'Apr 26', pct: 100, meals: '5/5'},
  ];

  return (
    <div className="app-screen" data-screen-label="History">
      <FakeStatus />
      <div className="appbar">
        <div>
          <div className="t-label">Tracking</div>
          <div style={{fontSize: 28, fontWeight: 700, letterSpacing: '-0.7px', marginTop: 4}}>History</div>
        </div>
        <IconBtn size={42}><Icons.Calendar size={20} /></IconBtn>
      </div>

      <div className="scrollable" style={{paddingBottom: 110}}>
        {/* Streak hero */}
        <div style={{margin: '24px 24px 0', padding: '28px 28px',
                     background: 'var(--surface-lowest)', borderRadius: 'var(--r-xl)',
                     boxShadow: 'var(--shadow-cloud)'}}>
          <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start'}}>
            <div>
              <div className="t-label">Current Streak</div>
              <div style={{display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 6}}>
                <span style={{fontSize: 64, fontWeight: 700, letterSpacing: '-2.5px', lineHeight: 1}}>12</span>
                <span style={{fontSize: 14, color: 'var(--on-surface-mut)', fontWeight: 600}}>days</span>
              </div>
              <div className="pill pill-primary" style={{marginTop: 12}}>
                <Icons.TrendUp size={12} stroke={2} /> Personal best: 21
              </div>
            </div>
            <div style={{position: 'relative', width: 64, height: 64, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
              <Icons.Flame size={48} color="var(--primary)" stroke={1.5} />
            </div>
          </div>

          {/* Week strip */}
          <div style={{display: 'flex', gap: 6, marginTop: 24}}>
            {week.map((w, i) => (
              <div key={i} style={{flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6}}>
                <div style={{height: 64, width: '100%', borderRadius: 8, background: 'var(--surface-low)',
                              display: 'flex', alignItems: 'flex-end', overflow: 'hidden', position: 'relative'}}>
                  <div style={{width: '100%', height: `${w.pct}%`,
                                background: w.status === 'red' ? 'var(--error)' :
                                            w.status === 'today' ? 'repeating-linear-gradient(45deg, var(--primary-container) 0 6px, var(--surface-low) 6px 12px)' :
                                            'linear-gradient(180deg, var(--primary-soft), var(--primary))',
                                borderRadius: 8, transition: 'height .4s'}} />
                </div>
                <span style={{fontSize: 10, color: 'var(--on-surface-mut)', fontWeight: 700, letterSpacing: '0.5px', textTransform: 'uppercase'}}>{w.d.slice(0,1)}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Stat grid */}
        <div style={{padding: '24px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12}}>
          {[
            {k: 'ADHERENCE',  v: '87%',  sub: 'last 30 days', c: 'var(--primary)'},
            {k: 'MEALS DONE', v: '142', sub: 'last 30 days', c: 'var(--on-surface)'},
            {k: 'AVG KCAL',   v: '2,180', sub: 'per day',    c: 'var(--on-surface)'},
            {k: 'SKIPPED',    v: '7',     sub: 'last 30 days', c: 'var(--error)'},
          ].map(s => (
            <div key={s.k} style={{padding: '20px', background: 'var(--surface-lowest)',
                                   borderRadius: 'var(--r-md)'}}>
              <div className="t-label" style={{fontSize: 9}}>{s.k}</div>
              <div style={{fontSize: 26, fontWeight: 700, letterSpacing: '-0.7px', marginTop: 6, color: s.c}}>{s.v}</div>
              <div style={{fontSize: 11, color: 'var(--on-surface-mut)', marginTop: 2, fontWeight: 500}}>{s.sub}</div>
            </div>
          ))}
        </div>

        {/* Last days */}
        <div style={{margin: '8px 32px 12px', display: 'flex', justifyContent: 'space-between', alignItems: 'baseline'}}>
          <h3 style={{margin: 0, fontSize: 18, fontWeight: 700}}>Last 5 days</h3>
        </div>
        <div style={{padding: '0 16px'}}>
          {months.map((m, idx) => (
            <div key={idx} style={{display: 'flex', alignItems: 'center', gap: 16,
                                   padding: '16px', borderRadius: 'var(--r-md)',
                                   background: idx % 2 ? 'var(--surface-low)' : 'transparent'}}>
              <div style={{minWidth: 64}}>
                <div style={{fontSize: 14, fontWeight: 700}}>{m.d}</div>
                <div style={{fontSize: 11, color: 'var(--on-surface-mut)', marginTop: 2, fontWeight: 500}}>{m.meals} meals</div>
              </div>
              <div style={{flex: 1}}>
                <Progress value={m.pct/100}
                          color={m.pct >= 80 ? 'var(--primary)' : 'var(--error)'}
                          h={6} />
              </div>
              <span style={{fontSize: 13, fontWeight: 700,
                            color: m.pct >= 80 ? 'var(--primary)' : 'var(--error)',
                            minWidth: 40, textAlign: 'right'}}>{m.pct}%</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

// ============================================================
// PROFILE SCREEN
// ============================================================
const ProfileScreen = ({ onOpenSheet, prefs, setPref }) => {
  return (
    <div className="app-screen" data-screen-label="Profile">
      <FakeStatus />
      <div className="appbar">
        <div>
          <div className="t-label">Account</div>
          <div style={{fontSize: 28, fontWeight: 700, letterSpacing: '-0.7px', marginTop: 4}}>Profile</div>
        </div>
        <IconBtn size={42}><Icons.Settings size={20} /></IconBtn>
      </div>

      <div className="scrollable" style={{paddingBottom: 110}}>
        {/* Avatar block */}
        <div style={{padding: '32px 24px 0', display: 'flex', flexDirection: 'column', alignItems: 'center'}}>
          <div className="avatar">
            MK
            <div className="avatar-badge">7</div>
          </div>
          <div style={{fontSize: 22, fontWeight: 700, letterSpacing: '-0.4px', marginTop: 14}}>Mark Kovac</div>
          <div style={{fontSize: 13, color: 'var(--on-surface-mut)', fontWeight: 500, marginTop: 2}}>mark@posam.sk</div>
        </div>

        {/* Subscription banner */}
        <div onClick={() => onOpenSheet('paywall')} className="tap"
             style={{margin: '24px 24px 0', padding: '20px 24px',
                     background: 'var(--surface-lowest)',
                     borderRadius: 'var(--r-lg)', color: 'var(--on-surface)',
                     boxShadow: 'var(--shadow-cloud)',
                     display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
          <div>
            <div className="t-label">Free Trial</div>
            <div style={{fontSize: 17, fontWeight: 700, marginTop: 4}}>5 days remaining</div>
            <div style={{fontSize: 12, color: 'var(--on-surface-mut)', marginTop: 2, fontWeight: 500}}>Upgrade to keep your streak.</div>
          </div>
          <Icons.Crown size={36} color="#e9b949" stroke={1.8} fill="#e9b949" />
        </div>

        {/* Sections */}
        <Section title="Streak preferences">
          <Row label="Count partial as complete"
               sub="A day with all-partial meals keeps your streak"
               right={<Toggle on={prefs.partial} onChange={(v) => setPref('partial', v)} />} />
          <Row label="Skip weekends"
               sub="Sat & Sun won't count toward streak loss"
               right={<Toggle on={prefs.weekend} onChange={(v) => setPref('weekend', v)} />} />
        </Section>

        <Section title="Settings">
          <Row label="Notifications"
               sub="Pre-meal pings, end-of-day summary"
               right={<Icons.Chevron size={16} color="var(--on-surface-mut)"/>}
               onClick={() => onOpenSheet('reminders')} />
          <Row label="Goals"
               sub={`${prefs.goal} · ${prefs.goalKcal} kcal/day`}
               right={<Icons.Chevron size={16} color="var(--on-surface-mut)" />} />
          <Row label="Units" sub={prefs.units === 'g' ? 'Grams' : 'Ounces'}
               right={<Icons.Chevron size={16} color="var(--on-surface-mut)" />} />
        </Section>

        <Section title="Badges">
          <div style={{display: 'flex', gap: 10, padding: '14px 0', flexWrap: 'wrap'}}>
            {[
              {n: 7,  earned: true},
              {n: 30, earned: false},
              {n: 100, earned: false},
            ].map(b => (
              <div key={b.n} style={{flex: 1, padding: '20px 12px', background: b.earned ? 'rgba(233,185,73,0.12)' : 'var(--surface-low)',
                                     borderRadius: 'var(--r-md)', textAlign: 'center'}}>
                <div style={{margin: '0 auto', width: 44, height: 44, borderRadius: 999,
                              background: b.earned ? 'var(--gold)' : 'var(--surface-high)',
                              display: 'inline-flex', alignItems: 'center', justifyContent: 'center'}}>
                  <Icons.Trophy size={22} color="white" stroke={1.5} />
                </div>
                <div style={{fontSize: 16, fontWeight: 800, marginTop: 8, color: b.earned ? '#8a6b1a' : 'var(--on-surface-mut)'}}>{b.n}</div>
                <div style={{fontSize: 10, color: 'var(--on-surface-mut)', textTransform: 'uppercase', letterSpacing: '1px', fontWeight: 700}}>days</div>
              </div>
            ))}
          </div>
        </Section>

        <div style={{padding: '0 24px 8px'}}>
          <button onClick={() => onOpenSheet('logout')}
                  style={{width: '100%', padding: '16px', background: 'var(--surface-low)',
                          borderRadius: 'var(--r-full)', display: 'inline-flex', alignItems: 'center',
                          justifyContent: 'center', gap: 8, fontSize: 13, fontWeight: 700,
                          color: 'var(--on-surface-var)', letterSpacing: '1px', textTransform: 'uppercase'}}>
            <Icons.LogOut size={16} /> Sign out
          </button>
        </div>
      </div>
    </div>
  );
};

const Section = ({ title, children }) => (
  <div style={{marginTop: 28, padding: '0 24px'}}>
    <div className="t-label" style={{paddingLeft: 8, marginBottom: 8}}>{title}</div>
    <div style={{background: 'var(--surface-lowest)', borderRadius: 'var(--r-lg)', padding: '4px 8px'}}>
      {children}
    </div>
  </div>
);
const Row = ({ label, sub, right, onClick }) => (
  <div onClick={onClick}
       style={{display: 'flex', alignItems: 'center', gap: 12, padding: '16px 12px',
               width: '100%', textAlign: 'left', cursor: onClick ? 'pointer' : 'default',
               boxSizing: 'border-box'}}>
    <div style={{flex: 1, minWidth: 0}}>
      <div style={{fontSize: 14, fontWeight: 600}}>{label}</div>
      {sub && <div style={{fontSize: 12, color: 'var(--on-surface-mut)', marginTop: 2, fontWeight: 500}}>{sub}</div>}
    </div>
    {right}
  </div>
);

window.PlansScreen = PlansScreen;
window.PlanDetailScreen = PlanDetailScreen;
window.HistoryScreen = HistoryScreen;
window.ProfileScreen = ProfileScreen;
