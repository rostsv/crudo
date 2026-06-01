// Crudo - Create / Edit Plan screen
const { useState: useStateCP, useMemo: useMemoCP } = React;

const dayInitialsCP = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const dayNamesCP = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

const goalOptions = [
{ id: 'cut', label: 'Cut', sub: 'Calorie deficit' },
{ id: 'maintain', label: 'Maintain', sub: 'Hold weight' },
{ id: 'bulk', label: 'Bulk', sub: 'Lean gain' }];


const CreatePlanScreen = ({ existingPlans = [], library = [], foods, onBack, onSave, onConflict, onCreateMeal, draft, setDraft }) => {
  const ctrl = !!setDraft;
  const [nameU, setNameU] = useStateCP('');
  const [goalU, setGoalU] = useStateCP('cut');
  const [daysU, setDaysU] = useStateCP([]);
  const [pickedU, setPickedU] = useStateCP([]);
  const name = ctrl ? draft.name : nameU;
  const goal = ctrl ? draft.goal : goalU;
  const days = ctrl ? draft.days : daysU;
  const pickedMealIds = ctrl ? draft.pickedMealIds : pickedU;
  const setName = (v) => ctrl ? setDraft((d) => ({ ...d, name: v })) : setNameU(v);
  const setGoal = (v) => ctrl ? setDraft((d) => ({ ...d, goal: v })) : setGoalU(v);
  const setDays = (fn) => ctrl ? setDraft((d) => ({ ...d, days: typeof fn === 'function' ? fn(d.days) : fn })) : setDaysU(fn);
  const setPickedMealIds = (fn) => ctrl ? setDraft((d) => ({ ...d, pickedMealIds: typeof fn === 'function' ? fn(d.pickedMealIds) : fn })) : setPickedU(fn);
  const [showLibrary, setShowLibrary] = useStateCP(false);

  // overlap detection
  const conflicts = useMemoCP(() => {
    const out = [];
    days.forEach((d) => {
      existingPlans.forEach((p) => {
        if (p.days.includes(d)) out.push({ day: d, plan: p });
      });
    });
    return out;
  }, [days, existingPlans]);

  const toggleDay = (i) => {
    setDays((d) => d.includes(i) ? d.filter((x) => x !== i) : [...d, i].sort());
  };

  const pickedMeals = pickedMealIds.map((id) => library.find((m) => m.id === id)).filter(Boolean);
  const totals = pickedMeals.reduce((acc, m) => {
    const mm = mealMacros(m, foods);
    return { kcal: acc.kcal + mm.kcal, p: acc.p + mm.p, c: acc.c + mm.c, f: acc.f + mm.fa };
  }, { kcal: 0, p: 0, c: 0, f: 0 });

  const canSave = name.trim().length > 0 && pickedMealIds.length > 0;

  const submit = () => {
    if (!canSave) return;
    if (conflicts.length > 0) {
      onConflict(conflicts);
      return;
    }
    onSave({
      name: name.trim(),
      goal,
      days,
      mealIds: pickedMealIds,
      kcal: Math.round(totals.kcal),
      p: Math.round(totals.p),
      c: Math.round(totals.c),
      f: Math.round(totals.f)
    });
  };

  return (
    <div className="app-screen" data-screen-label="Create plan">
      <FakeStatus />
      <ScreenHeader title="New Plan" label="LIBRARY" onBack={onBack} />

      <div className="scrollable" style={{ paddingBottom: 140 }}>
        {/* Name */}
        <div style={{ padding: '16px 32px 0' }}>
          <div className="t-label" style={{ marginBottom: 4 }}>Plan name</div>
          <input className="input-soft" placeholder="e.g. Weekday Cut"
          value={name} onChange={(e) => setName(e.target.value)} />
        </div>

        {/* Goal */}
        <div style={{ padding: '28px 24px 0' }}>
          <div className="t-label" style={{ paddingLeft: 8, marginBottom: 10 }}>Goal</div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
            {goalOptions.map((g) =>
            <button key={g.id} onClick={() => setGoal(g.id)}
            style={{ padding: '14px 8px', borderRadius: 'var(--r-md)',
              background: goal === g.id ? 'var(--primary)' : 'var(--surface-lowest)',
              color: goal === g.id ? 'white' : 'var(--on-surface)',
              boxShadow: goal === g.id ? 'none' : '0 1px 0 rgba(26,28,26,0.02)',
              display: 'flex', flexDirection: 'column', gap: 4, alignItems: 'center' }}>
                <span style={{ fontSize: 14, fontWeight: 700 }}>{g.label}</span>
                <span style={{ fontSize: 10, opacity: goal === g.id ? 0.85 : 0.6, fontWeight: 500 }}>{g.sub}</span>
              </button>
            )}
          </div>
        </div>

        {/* Days */}
        <div style={{ padding: '28px 24px 0' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', paddingLeft: 8, marginBottom: 10 }}>
            <span className="t-label">Repeats on</span>
            <span style={{ fontSize: 11, color: 'var(--on-surface-mut)', fontWeight: 600 }}>
              {days.length === 0 ? 'No days yet' : `${days.length} day${days.length > 1 ? 's' : ''}`}
            </span>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 6 }}>
            {dayInitialsCP.map((d, i) => {
              const on = days.includes(i);
              const conflictDay = conflicts.some((c) => c.day === i);
              return (
                <button key={i} onClick={() => toggleDay(i)}
                style={{ height: 52, borderRadius: 14, fontSize: 16, fontWeight: 700,
                  background: on ? 'var(--primary)' : 'var(--surface-lowest)',
                  color: on ? 'white' : 'var(--on-surface-mut)',
                  boxShadow: conflictDay ? 'inset 0 0 0 2px var(--error)' : '0 1px 0 rgba(26,28,26,0.02)',
                  transition: 'all .15s ease' }}>
                  {d}
                </button>);

            })}
          </div>
          {conflicts.length > 0 &&
          <div style={{ marginTop: 12, padding: '12px 14px', background: 'var(--error-soft)',
            borderRadius: 'var(--r-md)', display: 'flex', gap: 10, alignItems: 'flex-start' }}>
              <Icons.Warn size={18} color="var(--error)" stroke={2} />
              <div>
                <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--error)' }}>
                  {conflicts.length === 1 ?
                `${dayNamesCP[conflicts[0].day]} overlaps ${conflicts[0].plan.name}` :
                `${conflicts.length} day overlaps`}
                </div>
                <div style={{ fontSize: 11, color: 'var(--on-surface-var)', marginTop: 2, fontWeight: 500 }}>
                  Pick different days or override existing plan{conflicts.length > 1 ? 's' : ''}.
                </div>
              </div>
            </div>
          }
        </div>

        {/* Meals */}
        <div style={{ padding: '28px 24px 0' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', paddingLeft: 8, marginBottom: 10 }}>
            <span className="t-label">Meals</span>
            <span style={{ fontSize: 11, color: 'var(--on-surface-mut)', fontWeight: 600 }}>
              {pickedMealIds.length === 0 ? 'None added' : `${pickedMealIds.length} meal${pickedMealIds.length > 1 ? 's' : ''}`}
            </span>
          </div>

          {pickedMeals.length > 0 &&
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 12 }}>
              {pickedMeals.map((m) => {
              const mm = mealMacros(m, foods);
              return (
                <div key={m.id} style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '14px 16px',
                  background: 'var(--surface-lowest)', borderRadius: 'var(--r-md)' }}>
                    <div style={{ minWidth: 50 }}>
                      <div style={{ fontSize: 14, fontWeight: 700, color: 'var(--primary)' }}>{m.time}</div>
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 14, fontWeight: 600 }}>{m.name}</div>
                      <div style={{ fontSize: 11, color: 'var(--on-surface-mut)', marginTop: 2, fontWeight: 500 }}>
                        {Math.round(mm.kcal)} kcal · {m.tags[0]}
                      </div>
                    </div>
                    <button onClick={() => setPickedMealIds((ids) => ids.filter((x) => x !== m.id))}
                  style={{ width: 28, height: 28, borderRadius: 999, background: 'var(--surface-low)',
                    display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Icons.X size={14} color="var(--on-surface-var)" />
                    </button>
                  </div>);

            })}
            </div>
          }

          <button onClick={() => setShowLibrary(true)}
          style={{ width: '100%', padding: '16px', background: 'var(--surface-low)',
            borderRadius: 'var(--r-md)', display: 'inline-flex', alignItems: 'center',
            justifyContent: 'center', gap: 8, fontSize: 13, fontWeight: 700,
            color: 'var(--primary)', letterSpacing: '1px', textTransform: 'uppercase' }}>
            <Icons.Plus size={16} stroke={2} /> Add meal from library
          </button>
        </div>

        {/* Macro summary */}
        {pickedMeals.length > 0 &&
        <div style={{ margin: '28px 24px 0', padding: '24px',
          background: 'linear-gradient(135deg, var(--primary), var(--primary-soft))',
          borderRadius: 'var(--r-xl)', color: 'white' }}>
            <div className="t-label" style={{ color: 'rgba(255,255,255,0.6)' }}>Daily target</div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 6 }}>
              <span style={{ fontSize: 44, fontWeight: 700, letterSpacing: '-1.5px', lineHeight: 1 }}>{Math.round(totals.kcal)}</span>
              <span style={{ fontSize: 13, opacity: 0.7 }}>kcal</span>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 12, marginTop: 18 }}>
              {[
            { k: 'PROTEIN', v: totals.p },
            { k: 'CARBS', v: totals.c },
            { k: 'FATS', v: totals.f }].
            map((m) =>
            <div key={m.k}>
                  <div style={{ fontSize: 9, letterSpacing: '1.5px', fontWeight: 700, opacity: 0.6 }}>{m.k}</div>
                  <div style={{ fontSize: 16, fontWeight: 700, marginTop: 4 }}>{Math.round(m.v)}<span style={{ fontSize: 10, opacity: 0.7, fontWeight: 500 }}>g</span></div>
                </div>
            )}
            </div>
          </div>
        }
      </div>

      {/* Floating CTA */}
      <div className="fcta-bar">
        <button className="btn-primary" onClick={submit} disabled={!canSave}>
          {pickedMealIds.length === 0 ? 'Add meals to continue' :
          name.trim().length === 0 ? 'Name your plan' : 'Create plan'}
        </button>
      </div>

      {/* Library picker sheet */}
      {showLibrary &&
      <div className="sheet-backdrop" onClick={() => setShowLibrary(false)}>
          <div className="sheet" onClick={(e) => e.stopPropagation()} style={{ maxHeight: '80%' }} data-comment-anchor="f8fdb7c1bf-div-216-11">
            <div className="sheet-grabber" />
            <div style={{ padding: '4px 4px 16px' }}>
              <div className="t-label">Pick from library</div>
              <h2 style={{ margin: '6px 0', fontSize: 22, fontWeight: 700, letterSpacing: '-0.5px' }}>Add meals</h2>
            </div>

            {/* Create new meal CTA */}
            {onCreateMeal &&
            <button onClick={() => { setShowLibrary(false); onCreateMeal(); }}
            style={{ display: 'flex', alignItems: 'center', gap: 14, width: '100%',
              padding: '14px 16px', marginBottom: 10,
              background: 'var(--surface-low)',
              border: '1.5px dashed rgba(0,77,73,0.22)',
              borderRadius: 'var(--r-md)', textAlign: 'left' }}>
                <div style={{ width: 40, height: 40, borderRadius: 999,
              background: 'var(--primary-container)',
              display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <Icons.Plus size={20} color="var(--primary)" stroke={2} />
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 14, fontWeight: 700, color: 'var(--primary)' }}>Create new meal</div>
                  <div style={{ fontSize: 11, color: 'var(--on-surface-mut)', marginTop: 2, fontWeight: 500 }}>
                    Build from ingredients · saves to library
                  </div>
                </div>
                <Icons.Chevron size={18} color="var(--primary)" />
              </button>
            }

            <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
              {library.map((m) => {
              const mm = mealMacros(m, foods);
              const picked = pickedMealIds.includes(m.id);
              return (
                <button key={m.id}
                onClick={() => setPickedMealIds((ids) =>
                picked ? ids.filter((x) => x !== m.id) : [...ids, m.id])}
                style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '14px 16px',
                  background: picked ? 'var(--primary-container)' : 'var(--surface-lowest)',
                  borderRadius: 'var(--r-md)', textAlign: 'left' }}>
                    <div style={{ minWidth: 50 }}>
                      <div style={{ fontSize: 14, fontWeight: 700, color: 'var(--primary)' }}>{m.time}</div>
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 14, fontWeight: 600 }}>{m.name}</div>
                      <div style={{ fontSize: 11, color: 'var(--on-surface-mut)', marginTop: 2, fontWeight: 500 }}>
                        {m.tags.join(' · ')} · {Math.round(mm.kcal)} kcal
                      </div>
                    </div>
                    <div className={`check ${picked ? 'on' : ''}`} style={{ width: 24, height: 24 }}>
                      {picked && <Icons.Check size={14} stroke={3} />}
                    </div>
                  </button>);

            })}
            </div>
            <div style={{ marginTop: 16 }}>
              <button className="btn-primary" onClick={() => setShowLibrary(false)}>
                Done · {pickedMealIds.length} selected
              </button>
            </div>
          </div>
        </div>
      }
    </div>);

};

window.CreatePlanScreen = CreatePlanScreen;