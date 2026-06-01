// Crudo - Meal Detail Screen + Add/Edit Meal + Add Ingredient
const { useState: useStateMD, useMemo: useMemoMD } = React;

// ============================================================
// MEAL DETAIL — ingredient checklist + actions
// ============================================================
const MealDetailScreen = ({ meal, foods, onBack, onUpdate, onSnooze, onSwap }) => {
  const [checked, setChecked] = useStateMD(() =>
    Object.fromEntries(meal.ingr.map(i => [i.fid, meal.status === 'done']))
  );
  const macros = mealMacros(meal, foods);
  const checkedCount = Object.values(checked).filter(Boolean).length;
  const total = meal.ingr.length;
  const pct = total ? checkedCount / total : 0;

  const computeStatus = (c) => {
    const n = Object.values(c).filter(Boolean).length;
    if (n === 0) return 'skipped';
    if (n === total) return 'done';
    return 'partial';
  };

  const toggleIngr = (fid) => setChecked(s => ({ ...s, [fid]: !s[fid] }));

  return (
    <div className="app-screen" data-screen-label="Meal detail">
      <FakeStatus />
      <ScreenHeader title={meal.name} label={`${meal.time} · ${meal.tags.join(' · ')}`} onBack={onBack}
                    action={<IconBtn><Icons.Edit size={18} /></IconBtn>} />

      <div className="scrollable" style={{paddingBottom: 200}}>
        {/* Macro summary */}
        <div style={{margin: '12px 24px 0', padding: '24px 24px',
                     background: 'var(--surface-low)', borderRadius: 'var(--r-lg)'}}>
          <div className="t-label">Total intake</div>
          <div style={{display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 8}}>
            <span style={{fontSize: 44, fontWeight: 700, letterSpacing: '-1.5px', lineHeight: 1}}>{Math.round(macros.kcal)}</span>
            <span style={{color: 'var(--on-surface-mut)', fontSize: 14}}>kcal</span>
          </div>
          <div style={{display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 14, marginTop: 20}}>
            {[
              {k:'PROTEIN', v: macros.p, c:'var(--primary)'},
              {k:'CARBS',   v: macros.c, c:'var(--gold)'},
              {k:'FATS',    v: macros.fa, c:'#9a7e4e'},
            ].map(m => (
              <div key={m.k} style={{background: 'var(--surface)', borderRadius: 'var(--r-md)', padding: '12px 14px'}}>
                <div className="t-label" style={{fontSize: 9}}>{m.k}</div>
                <div style={{fontSize: 18, fontWeight: 700, marginTop: 4, color: m.c}}>{Math.round(m.v)}<span style={{fontSize: 10, color: 'var(--on-surface-mut)', fontWeight: 500}}>g</span></div>
              </div>
            ))}
          </div>
        </div>

        {/* Ingredient checklist */}
        <div style={{margin: '32px 32px 12px', display: 'flex', alignItems: 'baseline', justifyContent: 'space-between'}}>
          <h3 style={{margin: 0, fontSize: 18, fontWeight: 700}}>Ingredients</h3>
          <span className="t-label">{checkedCount} OF {total} EATEN</span>
        </div>

        <div style={{margin: '0 24px'}}>
          <Progress value={pct} h={3} />
        </div>

        <div style={{padding: '12px 24px', display: 'flex', flexDirection: 'column', gap: 4}}>
          {meal.ingr.map((ing, idx) => {
            const f = foods.find(x => x.id === ing.fid);
            const im = ingrMacros(ing, foods);
            const on = checked[ing.fid];
            return (
              <button key={idx} onClick={() => toggleIngr(ing.fid)}
                      style={{display: 'flex', alignItems: 'center', gap: 16, padding: '14px 12px',
                              background: idx % 2 ? 'var(--surface-low)' : 'transparent',
                              borderRadius: 'var(--r-md)', textAlign: 'left'}}>
                <div className={`check ${on ? 'on' : ''}`}>
                  {on && <Icons.Check size={16} stroke={3} />}
                </div>
                <div style={{flex: 1, minWidth: 0}}>
                  <div style={{fontSize: 15, fontWeight: 600,
                               textDecoration: on ? 'line-through' : 'none',
                               opacity: on ? 0.5 : 1}}>{f?.name}</div>
                  <div style={{fontSize: 11, color: 'var(--on-surface-mut)', marginTop: 2, fontWeight: 500}}>
                    {ing.g}g · {Math.round(im.kcal)} kcal · P{Math.round(im.p)} C{Math.round(im.c)} F{Math.round(im.fa)}
                  </div>
                </div>
              </button>
            );
          })}
        </div>

        {/* Action buttons row */}
        <div style={{margin: '12px 24px 0', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12}}>
          <button onClick={onSnooze}
                  style={{padding: '16px', background: 'var(--surface-low)',
                          borderRadius: 'var(--r-md)', display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: 6}}>
            <Icons.Snooze size={20} color="var(--primary)" />
            <span style={{fontSize: 14, fontWeight: 700}}>Snooze</span>
            <span style={{fontSize: 11, color: 'var(--on-surface-mut)', textAlign: 'left'}}>15m delay, no further</span>
          </button>
          <button onClick={onSwap}
                  style={{padding: '16px', background: 'var(--surface-low)',
                          borderRadius: 'var(--r-md)', display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: 6}}>
            <Icons.Swap size={20} color="var(--primary)" />
            <span style={{fontSize: 14, fontWeight: 700}}>Swap meal</span>
            <span style={{fontSize: 11, color: 'var(--on-surface-mut)', textAlign: 'left'}}>Pick from library</span>
          </button>
        </div>
      </div>

      {/* Floating CTA */}
      <div className="fcta-bar">
        <div style={{display: 'flex', gap: 10}}>
          <button className="btn-secondary" style={{flex: 1, padding: '16px'}}
                  onClick={() => onUpdate(meal.id, 'skipped')}>Skip</button>
          <button className="btn-primary" style={{flex: 2}}
                  onClick={() => onUpdate(meal.id, computeStatus(checked))}>
            {checkedCount === total ? 'Mark Done' : checkedCount > 0 ? 'Save Partial' : 'Skip Meal'}
          </button>
        </div>
      </div>
    </div>
  );
};

// ============================================================
// ADD / EDIT MEAL — name, tags, ingredients, time, save
// ============================================================
const ALL_TAGS = ['Breakfast','Lunch','Dinner','Snack','Pre-workout','Post-workout'];

const AddMealScreen = ({ foods, onBack, onSave, onAddIngr, initial }) => {
  const [name, setName] = useStateMD(initial?.name || '');
  const [time, setTime] = useStateMD(initial?.time || '08:00');
  const [tags, setTags] = useStateMD(initial?.tags || ['Breakfast']);
  const [ingr, setIngr] = useStateMD(initial?.ingr || []);

  const macros = useMemoMD(() => mealMacros({ ingr }, foods), [ingr, foods]);
  const toggleTag = (t) => setTags(s => s.includes(t) ? s.filter(x => x !== t) : [...s, t]);
  const removeIngr = (i) => setIngr(s => s.filter((_, idx) => idx !== i));

  return (
    <div className="app-screen" data-screen-label="Add meal">
      <FakeStatus />
      <ScreenHeader title={initial ? 'Edit meal' : 'New meal'} onBack={onBack}
                    action={<button className="btn-tertiary" onClick={() => onSave({name, time, tags, ingr})}>SAVE</button>} />

      <div className="scrollable" style={{paddingBottom: 120}}>
        {/* Name */}
        <div style={{padding: '16px 32px 0'}}>
          <div className="t-label">Meal name</div>
          <input className="input-soft" style={{fontSize: 28, fontWeight: 600, letterSpacing: '-0.5px'}}
                 placeholder="e.g. Protein Bowl" value={name} onChange={e => setName(e.target.value)} />
        </div>

        {/* Time */}
        <div style={{padding: '24px 32px 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
          <div>
            <div className="t-label">Scheduled time</div>
            <div style={{fontSize: 24, fontWeight: 700, marginTop: 4, letterSpacing: '-0.5px'}}>{time}</div>
          </div>
          <input type="time" value={time} onChange={e => setTime(e.target.value)}
                 style={{opacity: 0, width: 0, height: 0}} id="timepick" />
          <label htmlFor="timepick"
                 style={{padding: '10px 16px', background: 'var(--surface-low)',
                         borderRadius: 999, fontSize: 12, fontWeight: 700, color: 'var(--primary)',
                         letterSpacing: '1px', textTransform: 'uppercase', cursor: 'pointer'}}>
            Change
          </label>
        </div>

        {/* Tags */}
        <div style={{padding: '24px 32px 0'}}>
          <div className="t-label">Tags · select multiple</div>
          <div style={{display: 'flex', flexWrap: 'wrap', gap: 8, marginTop: 12}}>
            {ALL_TAGS.map(t => (
              <button key={t} onClick={() => toggleTag(t)}
                      style={{padding: '10px 16px', borderRadius: 999, fontSize: 12, fontWeight: 600,
                              letterSpacing: '0.3px',
                              background: tags.includes(t) ? 'var(--primary)' : 'var(--surface-low)',
                              color: tags.includes(t) ? 'white' : 'var(--on-surface-var)'}}>
                {t}
              </button>
            ))}
          </div>
        </div>

        {/* Ingredients */}
        <div style={{margin: '32px 24px 0', padding: '24px 24px',
                     background: 'var(--surface-low)', borderRadius: 'var(--r-lg)'}}>
          <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'baseline'}}>
            <h3 style={{margin: 0, fontSize: 18, fontWeight: 700}}>Ingredients</h3>
            <span className="t-label">{ingr.length} ITEMS</span>
          </div>

          <div style={{marginTop: 16, display: 'flex', flexDirection: 'column', gap: 6}}>
            {ingr.map((i, idx) => {
              const f = foods.find(x => x.id === i.fid);
              const im = ingrMacros(i, foods);
              return (
                <div key={idx} style={{display: 'flex', alignItems: 'center', gap: 12,
                                       padding: '12px 14px', background: 'var(--surface-lowest)',
                                       borderRadius: 'var(--r-md)'}}>
                  <div style={{flex: 1, minWidth: 0}}>
                    <div style={{fontSize: 14, fontWeight: 600}}>{f?.name}</div>
                    <div style={{fontSize: 11, color: 'var(--on-surface-mut)', marginTop: 2, fontWeight: 500}}>
                      {i.g}g · {Math.round(im.kcal)} kcal
                    </div>
                  </div>
                  <button onClick={() => removeIngr(idx)} style={{padding: 6, color: 'var(--on-surface-mut)'}}>
                    <Icons.X size={16} />
                  </button>
                </div>
              );
            })}
            {ingr.length === 0 && (
              <div style={{padding: '20px', textAlign: 'center', color: 'var(--on-surface-mut)', fontSize: 13}}>
                No ingredients yet
              </div>
            )}
          </div>

          <button onClick={() => onAddIngr(item => setIngr(s => [...s, item]))}
                  style={{marginTop: 14, padding: '14px', background: 'var(--surface-lowest)',
                          width: '100%', borderRadius: 'var(--r-md)',
                          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
                          fontSize: 13, fontWeight: 700, color: 'var(--primary)',
                          letterSpacing: '1px', textTransform: 'uppercase'}}>
            <Icons.Plus size={16} stroke={2} /> Add ingredient
          </button>
        </div>

        {/* Macro preview */}
        <div style={{margin: '20px 24px 0', padding: '20px 24px', borderRadius: 'var(--r-lg)',
                     background: 'linear-gradient(135deg, var(--primary), var(--primary-soft))', color: 'white'}}>
          <div className="t-label" style={{color: 'rgba(255,255,255,0.6)'}}>Auto-calculated</div>
          <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginTop: 8}}>
            <span style={{fontSize: 32, fontWeight: 700, letterSpacing: '-1px'}}>{Math.round(macros.kcal)} <span style={{fontSize: 12, fontWeight: 500, opacity: 0.7}}>kcal</span></span>
            <div style={{display: 'flex', gap: 14, fontSize: 12, fontWeight: 600}}>
              <span>P {Math.round(macros.p)}g</span>
              <span style={{opacity:.7}}>C {Math.round(macros.c)}g</span>
              <span style={{opacity:.7}}>F {Math.round(macros.fa)}g</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

// ============================================================
// ADD INGREDIENT (food picker + grams) — sheet-style screen
// ============================================================
const CAT_LABELS = {
  meat:  'Meat',     fish: 'Fish',
  eggs:  'Eggs & Dairy',
  grain: 'Grains',   veg: 'Vegetables',
  fruit: 'Fruits',   oil: 'Oils & Fats',
};

const AddIngredientScreen = ({ foods, onBack, onPick, onCreateCustom }) => {
  const [q, setQ] = useStateMD('');
  const [picked, setPicked] = useStateMD(null);
  const [grams, setGrams] = useStateMD(100);

  const filtered = foods.filter(f => f.name.toLowerCase().includes(q.toLowerCase()));
  const grouped = filtered.reduce((acc, f) => {
    (acc[f.cat] ||= []).push(f); return acc;
  }, {});

  const F = picked && {
    p: picked.p * grams / 100,
    c: picked.c * grams / 100,
    fa: picked.f * grams / 100,
    kcal: picked.kcal * grams / 100,
  };

  return (
    <div className="app-screen" data-screen-label="Add ingredient">
      <FakeStatus />
      <ScreenHeader title="Add ingredient" onBack={onBack} />

      {!picked ? (
        <>
          {/* Search */}
          <div style={{padding: '8px 24px 12px'}}>
            <div style={{position: 'relative'}}>
              <Icons.Search size={18} color="var(--on-surface-mut)"
                            style={{position: 'absolute', left: 18, top: '50%', transform: 'translateY(-50%)'}} />
              <input value={q} onChange={e => setQ(e.target.value)} placeholder="Search foods…"
                     style={{width: '100%', background: 'var(--surface-low)', border: 'none',
                             borderRadius: 999, padding: '14px 16px 14px 48px', fontSize: 15, fontWeight: 500,
                             outline: 'none'}} />
            </div>
          </div>

          <div className="scrollable" style={{padding: '0 0 30px'}}>
            {/* Persistent custom food CTA */}
            <div style={{padding: '4px 24px 0'}}>
              <button onClick={onCreateCustom}
                      style={{display: 'flex', alignItems: 'center', gap: 14, width: '100%',
                              padding: '14px 18px', borderRadius: 'var(--r-md)',
                              background: 'var(--surface-low)',
                              border: '1.5px dashed var(--outline-soft, rgba(0,77,73,0.22))',
                              textAlign: 'left'}} className="tap">
                <div style={{width: 40, height: 40, borderRadius: 999,
                             background: 'var(--primary-container)',
                             display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0}}>
                  <Icons.Plus size={20} color="var(--primary)" />
                </div>
                <div style={{flex: 1, minWidth: 0}}>
                  <div style={{fontSize: 15, fontWeight: 700, color: 'var(--primary)'}}>Create custom food</div>
                  <div style={{fontSize: 11, color: 'var(--on-surface-mut)', marginTop: 2, fontWeight: 500}}>
                    Add your own with macros per 100g
                  </div>
                </div>
                <Icons.Chevron size={18} color="var(--primary)" />
              </button>
            </div>

            {Object.keys(grouped).map(cat => (
              <div key={cat} style={{marginTop: 16}}>
                <div className="t-label" style={{padding: '0 32px', color: 'var(--on-surface-mut)'}}>{CAT_LABELS[cat] || cat}</div>
                <div style={{padding: '8px 16px 0'}}>
                  {grouped[cat].map(f => {
                    const I = Icons[f.icon] || Icons.Carrot;
                    return (
                      <button key={f.id} onClick={() => setPicked(f)}
                              style={{display: 'flex', alignItems: 'center', gap: 14, width: '100%',
                                      padding: '14px 16px', borderRadius: 'var(--r-md)',
                                      textAlign: 'left'}} className="tap">
                        <div style={{width: 40, height: 40, borderRadius: 999,
                                     background: 'var(--surface-low)',
                                     display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0}}>
                          <I size={20} color="var(--primary)" />
                        </div>
                        <div style={{flex: 1, minWidth: 0}}>
                          <div style={{fontSize: 15, fontWeight: 600}}>{f.name}</div>
                          <div style={{fontSize: 11, color: 'var(--on-surface-mut)', marginTop: 2, fontWeight: 500}}>
                            {f.kcal} kcal · P{f.p} C{f.c} F{f.f} per 100g
                          </div>
                        </div>
                        <Icons.Chevron size={18} color="var(--on-surface-mut)" />
                      </button>
                    );
                  })}
                </div>
              </div>
            ))}
            {filtered.length === 0 && (
              <div style={{padding: '32px 24px 8px', textAlign: 'center', color: 'var(--on-surface-mut)'}}>
                <div style={{fontSize: 14, fontWeight: 500}}>No matches for “{q}”</div>
                <div style={{fontSize: 12, marginTop: 6}}>Use the button above to add it as a custom food.</div>
              </div>
            )}
          </div>
        </>
      ) : (
        <>
          <div className="scrollable" style={{padding: '12px 32px 120px'}}>
            <div style={{padding: '24px', background: 'var(--surface-lowest)',
                         borderRadius: 'var(--r-lg)', boxShadow: 'var(--shadow-cloud)'}}>
              <div className="t-label">Selected</div>
              <div style={{fontSize: 24, fontWeight: 700, marginTop: 4, letterSpacing: '-0.4px'}}>{picked.name}</div>
              <div style={{fontSize: 12, color: 'var(--on-surface-mut)', marginTop: 4, fontWeight: 500}}>
                Per 100g · {picked.kcal} kcal
              </div>
            </div>

            <div style={{marginTop: 24}}>
              <div className="t-label">Quantity</div>
              <div style={{display: 'flex', alignItems: 'flex-end', gap: 12, marginTop: 12}}>
                <input type="number" value={grams} onChange={e => setGrams(Number(e.target.value)||0)}
                       className="input-soft" style={{fontSize: 56, fontWeight: 700, letterSpacing: '-2px', flex: 1}} />
                <span style={{fontSize: 18, color: 'var(--on-surface-mut)', fontWeight: 600, paddingBottom: 12}}>grams</span>
              </div>

              <div style={{display: 'flex', gap: 8, marginTop: 16, flexWrap: 'wrap'}}>
                {[50, 100, 150, 200, 250].map(p => (
                  <button key={p} onClick={() => setGrams(p)}
                          style={{padding: '8px 14px', borderRadius: 999,
                                  background: grams === p ? 'var(--primary-container)' : 'var(--surface-low)',
                                  color: grams === p ? 'var(--primary)' : 'var(--on-surface-var)',
                                  fontSize: 12, fontWeight: 700}}>
                    {p}g
                  </button>
                ))}
              </div>
            </div>

            {/* Macro preview */}
            <div style={{marginTop: 28, padding: '20px 24px', borderRadius: 'var(--r-lg)',
                         background: 'var(--surface-low)'}}>
              <div className="t-label">For {grams}g</div>
              <div style={{fontSize: 32, fontWeight: 700, letterSpacing: '-1px', marginTop: 6}}>
                {Math.round(F.kcal)} <span style={{fontSize: 12, fontWeight: 500, color: 'var(--on-surface-mut)'}}>kcal</span>
              </div>
              <div style={{display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 12, marginTop: 16}}>
                <div><div className="t-label" style={{fontSize: 9}}>PROTEIN</div><div style={{fontSize: 16, fontWeight: 700, color: 'var(--primary)', marginTop: 4}}>{F.p.toFixed(1)}g</div></div>
                <div><div className="t-label" style={{fontSize: 9}}>CARBS</div><div style={{fontSize: 16, fontWeight: 700, color: 'var(--gold)', marginTop: 4}}>{F.c.toFixed(1)}g</div></div>
                <div><div className="t-label" style={{fontSize: 9}}>FATS</div><div style={{fontSize: 16, fontWeight: 700, color: '#9a7e4e', marginTop: 4}}>{F.fa.toFixed(1)}g</div></div>
              </div>
            </div>
          </div>

          <div className="fcta-bar">
            <button className="btn-primary" onClick={() => onPick({fid: picked.id, g: grams})}>
              Add to Meal
            </button>
          </div>
        </>
      )}
    </div>
  );
};

// ============================================================
// ADD CUSTOM FOOD — name + macros, with calorie validation
// ============================================================
const CUSTOM_CATS = [
  {id: 'meat',   label: 'Meat',         icon: 'Beef'},
  {id: 'fish',   label: 'Fish',         icon: 'Fish'},
  {id: 'eggs',   label: 'Eggs & Dairy', icon: 'Egg'},
  {id: 'grain',  label: 'Grains',       icon: 'Grain'},
  {id: 'veg',    label: 'Vegetables',   icon: 'Carrot'},
  {id: 'fruit',  label: 'Fruits',       icon: 'Apple'},
  {id: 'oil',    label: 'Oils & Fats',  icon: 'Drop'},
];

const AddCustomFoodScreen = ({ onBack, onSave }) => {
  const [name, setName] = useStateMD('');
  const [cat, setCat] = useStateMD('');
  const [p, setP] = useStateMD(0);
  const [c, setC] = useStateMD(0);
  const [f, setF] = useStateMD(0);
  const [kcal, setKcal] = useStateMD('');
  const calc = p*4 + c*4 + f*9;
  const userKcal = kcal === '' ? calc : Number(kcal);
  const dev = calc > 0 ? Math.abs(userKcal - calc)/calc : 0;
  const valid = name && (p>0 || c>0 || f>0) && (kcal === '' || dev <= 0.1);

  return (
    <div className="app-screen" data-screen-label="Add custom food">
      <FakeStatus />
      <ScreenHeader title="Custom food" onBack={onBack}
                    action={<button className="btn-tertiary" disabled={!valid}
                                    style={{opacity: valid ? 1 : 0.4}}
                                    onClick={() => valid && onSave({name, p, c, f, kcal: Math.round(userKcal), cat: cat || 'custom'})}>SAVE</button>} />
      <div className="scrollable" style={{padding: '8px 32px 40px'}}>
        <div style={{marginTop: 8}}>
          <div className="t-label">Name</div>
          <input className="input-soft" style={{fontSize: 24, fontWeight: 600, letterSpacing: '-0.4px'}}
                 placeholder="e.g. My protein blend" value={name} onChange={e => setName(e.target.value)} />
        </div>

        {/* Optional category */}
        <div style={{marginTop: 28}}>
          <div style={{display: 'flex', alignItems: 'baseline', justifyContent: 'space-between'}}>
            <div className="t-label">Category</div>
            <div style={{fontSize: 10, color: 'var(--on-surface-mut)', fontWeight: 600, letterSpacing: '0.04em'}}>OPTIONAL</div>
          </div>
          <div style={{display: 'flex', gap: 8, marginTop: 12, flexWrap: 'wrap'}}>
            {CUSTOM_CATS.map(opt => {
              const I = Icons[opt.icon] || Icons.Carrot;
              const on = cat === opt.id;
              return (
                <button key={opt.id} onClick={() => setCat(on ? '' : opt.id)} className="tap"
                        style={{display: 'inline-flex', alignItems: 'center', gap: 8,
                                padding: '10px 14px', borderRadius: 999,
                                background: on ? 'var(--primary-container)' : 'var(--surface-low)',
                                color: on ? 'var(--primary)' : 'var(--on-surface-var)',
                                fontSize: 12, fontWeight: 700, letterSpacing: '0.01em'}}>
                  <I size={14} color={on ? 'var(--primary)' : 'var(--on-surface-mut)'} />
                  {opt.label}
                </button>
              );
            })}
          </div>
        </div>

        <div style={{marginTop: 28}}>
          <div className="t-label">Macros per 100g · all required</div>
          <div style={{display: 'flex', flexDirection: 'column', gap: 16, marginTop: 16}}>
            {[
              {k:'Protein', v:p, set:setP, c:'var(--primary)'},
              {k:'Carbs',   v:c, set:setC, c:'var(--gold)'},
              {k:'Fats',    v:f, set:setF, c:'#9a7e4e'},
            ].map(row => (
              <div key={row.k} style={{display: 'flex', alignItems: 'center', gap: 14}}>
                <div style={{width: 8, height: 36, borderRadius: 999, background: row.c}} />
                <div style={{flex: 1}}>
                  <div className="t-label" style={{fontSize: 9}}>{row.k.toUpperCase()}</div>
                  <input type="number" value={row.v} onChange={e => row.set(Number(e.target.value)||0)}
                         className="input-soft" style={{fontSize: 22, fontWeight: 700, padding: '4px 0'}} />
                </div>
                <span style={{fontSize: 14, color: 'var(--on-surface-mut)', fontWeight: 600, paddingTop: 14}}>g</span>
              </div>
            ))}
          </div>
        </div>

        <div style={{marginTop: 28, padding: '20px 24px', background: 'var(--surface-low)',
                     borderRadius: 'var(--r-lg)'}}>
          <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
            <div>
              <div className="t-label">Calculated kcal</div>
              <div style={{fontSize: 28, fontWeight: 700, letterSpacing: '-0.7px', marginTop: 4}}>{Math.round(calc)}</div>
            </div>
            <div style={{textAlign: 'right'}}>
              <div className="t-label">Override (optional)</div>
              <input type="number" placeholder="auto" value={kcal} onChange={e => setKcal(e.target.value)}
                     style={{background: 'transparent', border: 'none', outline: 'none',
                             textAlign: 'right', fontSize: 28, fontWeight: 700, letterSpacing: '-0.7px',
                             width: 100, color: 'var(--on-surface)'}} />
            </div>
          </div>
          {kcal !== '' && dev > 0.1 && (
            <div style={{marginTop: 12, padding: '10px 14px', background: 'var(--error-soft)',
                         borderRadius: 'var(--r-md)', display: 'flex', gap: 10, alignItems: 'flex-start'}}>
              <Icons.Info size={18} color="var(--error)" />
              <div>
                <div style={{fontSize: 12, fontWeight: 700, color: 'var(--error)'}}>Mismatch</div>
                <div style={{fontSize: 12, color: 'var(--on-surface-var)', marginTop: 2, lineHeight: '18px'}}>
                  Override differs by {Math.round(dev*100)}% from macros. Max allowed is 10%.
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

window.MealDetailScreen = MealDetailScreen;
window.AddMealScreen = AddMealScreen;
window.AddIngredientScreen = AddIngredientScreen;
window.AddCustomFoodScreen = AddCustomFoodScreen;
