// Crudo - main app shell + canvas wiring
const { useState: useStateApp } = React;

const initialPrefs = {
  goal: 'Cut',
  goalKcal: 2200,
  units: 'g',
  partial: false,
  weekend: false,
  preOn: true, atOn: true, warnOn: true, eodOn: true, riskOn: true,
  preMin: 15
};

const seedLibrary = [
...seedMeals,
{ id: 'm6', time: '07:30', name: 'Oatmeal & Berries', tags: ['Breakfast'],
  ingr: [{ fid: 'f6', g: 60 }, { fid: 'f14', g: 80 }, { fid: 'f13', g: 120 }], status: 'upcoming' },
{ id: 'm7', time: '13:00', name: 'Chicken & Rice', tags: ['Lunch'],
  ingr: [{ fid: 'f1', g: 200 }, { fid: 'f5', g: 250 }, { fid: 'f9', g: 80 }], status: 'upcoming' },
{ id: 'm8', time: '20:00', name: 'Egg Scramble', tags: ['Dinner'],
  ingr: [{ fid: 'f3', g: 200 }, { fid: 'f10', g: 80 }, { fid: 'f12', g: 8 }], status: 'upcoming' }];


const seedPlans = [
{ id: 'p1', name: 'Weekday Cut', tag: 'CUT · 2200 KCAL',
  meals: 5, kcal: 2180, p: 175, c: 220, f: 70,
  days: [0, 1, 2, 3, 4], active: true, mealIds: ['m1', 'm2', 'm3', 'm4', 'm5'] },
{ id: 'p2', name: 'Weekend Refeed', tag: 'MAINTAIN · 2600 KCAL',
  meals: 4, kcal: 2580, p: 160, c: 320, f: 75,
  days: [5, 6], active: false, mealIds: ['m6', 'm7', 'm8', 'm4'] },
{ id: 'p3', name: 'Travel Days', tag: 'FLEXIBLE · 1900 KCAL',
  meals: 3, kcal: 1900, p: 140, c: 180, f: 65,
  days: [], active: false, mealIds: ['m6', 'm7', 'm8'] }];


const App = () => {
  const [tab, setTab] = useStateApp('home');
  const [view, setView] = useStateApp(null); // {type:'mealDetail', meal} | 'addMeal' | 'addIngr' | 'customFood' | 'planDetail'
  const [sheet, setSheet] = useStateApp(null);
  const [meals, setMeals] = useStateApp(seedMeals);
  const [foods, setFoods] = useStateApp(seedFoods);
  const [prefs, setPrefs] = useStateApp(initialPrefs);
  const [pendingIngrCb, setPendingIngrCb] = useStateApp(null);
  const [plans, setPlans] = useStateApp(seedPlans);
  const [editingPlan, setEditingPlan] = useStateApp(null);
  const [conflicts, setConflicts] = useStateApp(null);
  const [toast, setToast] = useStateApp(null);
  const [planDraft, setPlanDraft] = useStateApp(null);
  const emptyDraft = { name: '', goal: 'cut', days: [], pickedMealIds: [] };
  const [extraLibrary, setExtraLibrary] = useStateApp([]);

  const setPref = (k, v) => setPrefs((p) => ({ ...p, [k]: v }));

  const updateMeal = (id, status) => {
    setMeals((s) => s.map((m) => m.id === id ? { ...m, status } : m));
    setView(null);
  };

  const openMeal = (m) => setView({ type: 'mealDetail', meal: m });
  const openPlan = (p) => setView({ type: 'planDetail', plan: p });

  const onSheet = (k) => setSheet(k);
  const closeSheet = () => setSheet(null);

  // ---- Render screen by tab/view
  let screen;
  if (view?.type === 'mealDetail') {
    screen = <MealDetailScreen meal={view.meal} foods={foods}
    onBack={() => setView(null)}
    onUpdate={updateMeal}
    onSnooze={() => setSheet('snooze')}
    onSwap={() => setSheet('swap')} />;
  } else if (view?.type === 'addMeal') {
    screen = <AddMealScreen foods={foods}
    onBack={() => view.returnTo === 'createPlan' ? setView({ type: 'createPlan' }) : setView(null)}
    initial={view.initial}
    onSave={(meal) => {
      if (view.returnTo === 'createPlan') {
        const newMeal = { ...meal, id: 'm' + Date.now(), status: 'upcoming' };
        setExtraLibrary((s) => [...s, newMeal]);
        setPlanDraft((d) => ({ ...d, pickedMealIds: [...d.pickedMealIds, newMeal.id] }));
        setView({ type: 'createPlan' });
      } else {
        setView(null);
      }
    }}
    onAddIngr={(cb) => {setPendingIngrCb(() => cb);setView({ type: 'addIngr', returnTo: view.returnTo });}} />;
  } else if (view?.type === 'addIngr') {
    screen = <AddIngredientScreen foods={foods}
    onBack={() => setView({ type: 'addMeal', returnTo: view.returnTo })}
    onPick={(item) => {pendingIngrCb?.(item);setView({ type: 'addMeal', returnTo: view.returnTo });}}
    onCreateCustom={() => setView({ type: 'customFood', returnTo: view.returnTo })} />;
  } else if (view?.type === 'customFood') {
    screen = <AddCustomFoodScreen
      onBack={() => setView({ type: 'addIngr', returnTo: view.returnTo })}
      onSave={(food) => {
        const newFood = { ...food, id: 'cf' + Date.now() };
        setFoods((s) => [...s, newFood]);
        pendingIngrCb?.({ fid: newFood.id, g: 100 });
        setView({ type: 'addMeal', returnTo: view.returnTo });
      }} />;
  } else if (view?.type === 'planDetail') {
    const planMeals = view.plan.mealIds.map((id) => seedLibrary.find((m) => m.id === id)).filter(Boolean);
    screen = <PlanDetailScreen plan={view.plan} meals={planMeals} foods={foods}
    onBack={() => setView(null)}
    onAddMeal={() => setView({ type: 'addMeal' })}
    onOpenMeal={openMeal}
    onEditDays={() => setEditingPlan(view.plan)} />;
  } else if (view?.type === 'createPlan') {
    if (!planDraft) setPlanDraft(emptyDraft);
    screen = <CreatePlanScreen
      existingPlans={plans}
      library={[...seedLibrary, ...extraLibrary]}
      foods={foods}
      draft={planDraft || emptyDraft}
      setDraft={setPlanDraft}
      onBack={() => { setPlanDraft(null); setView(null); }}
      onCreateMeal={() => setView({ type: 'addMeal', returnTo: 'createPlan', initial: { name: '', time: '12:00', tags: [], ingr: [] } })}
      onSave={(payload) => {
        const newPlan = {
          id: 'p' + Date.now(),
          name: payload.name,
          tag: `${payload.goal.toUpperCase()} · ${payload.kcal} KCAL`,
          meals: payload.mealIds.length,
          kcal: payload.kcal, p: payload.p, c: payload.c, f: payload.f,
          days: payload.days, active: payload.days.length > 0,
          mealIds: payload.mealIds
        };
        setPlans((ps) => [...ps, newPlan]);
        setPlanDraft(null);
        setView(null);
        setToast({ kind: 'success', title: 'Plan created',
          body: `${newPlan.name} added to your library.` });
      }}
      onConflict={(c) => setConflicts(c)} />;
  } else if (tab === 'home') {
    screen = <TodayScreen meals={meals} foods={foods}
    streak={12}
    onOpenMeal={openMeal} onOpenSheet={onSheet} />;
  } else if (tab === 'plan') {
    screen = <PlansScreen plans={plans}
    onOpenPlan={openPlan}
    onCreate={() => setView({ type: 'createPlan' })} />;
  } else if (tab === 'history') {
    screen = <HistoryScreen />;
  } else if (tab === 'profile') {
    screen = <ProfileScreen onOpenSheet={onSheet} prefs={prefs} setPref={setPref} />;
  }

  // Hide bottom nav when in detail/edit views
  const showNav = !view;

  return (
    <div style={{ position: 'relative', width: 390, height: 844 }}>
      {screen}
      {showNav && <BottomNav tab={tab} onTab={setTab} />}

      {sheet === 'snooze' && <SnoozeSheet onClose={closeSheet} onConfirm={() => closeSheet()} />}
      {sheet === 'swap' && <SwapSheet library={seedLibrary} foods={foods} onClose={closeSheet}
      onSwap={() => closeSheet()} />}
      {sheet === 'reminders' && <RemindersSheet onClose={closeSheet} prefs={prefs} setPref={setPref} />}
      {sheet === 'paywall' && <PaywallSheet onClose={closeSheet} streak={12} mealsDone={142} />}
      {sheet === 'streak' && <StreakRiskSheet onClose={closeSheet} />}
      {sheet === 'logout' && <ConfirmSheet title="Sign out?" body="You'll need to log back in to access your plans."
      primary="Sign out" danger
      onClose={closeSheet} onConfirm={closeSheet} />}
      {sheet === 'review' && <ReviewSheet onClose={closeSheet} />}
      {sheet === 'calendar' && <CalendarSheet onClose={closeSheet} />}

      {editingPlan &&
      <PlanDaysEditorSheet
        plan={editingPlan}
        allPlans={plans}
        onClose={() => setEditingPlan(null)}
        onSave={(days) => {
          setPlans((ps) => ps.map((p) => p.id === editingPlan.id ? { ...p, days } : p));
          setEditingPlan(null);
          setToast({ kind: 'success', title: 'Schedule saved',
            body: days.length === 0 ? 'No days selected — plan is unscheduled.' : `Active on ${days.length} day${days.length > 1 ? 's' : ''}.` });
        }}
        onConflict={(c) => setConflicts(c)} />
      }
      {conflicts &&
      <ConflictSheet
        conflicts={conflicts}
        onClose={() => setConflicts(null)}
        onResolve={() => {
          // override: remove the conflict day from all OTHER plans, save current
          const conflictDays = [...new Set(conflicts.map((c) => c.day))];
          setPlans((ps) => ps.map((p) => {
            if (p.id === editingPlan.id) return p;
            return { ...p, days: p.days.filter((d) => !conflictDays.includes(d)) };
          }));
          setConflicts(null);
          setToast({ kind: 'warn', title: 'Override applied',
            body: `Removed overlap from other plans. Tap Save to confirm.` });
        }} />
      }
      {toast &&
      <Toast kind={toast.kind} title={toast.title} body={toast.body}
      onDismiss={() => setToast(null)} />
      }
    </div>);

};

window.App = App;

// ===========================================================
// CANVAS — present all the screens side-by-side in artboards
// ===========================================================

// Static screen renderers (not tied to App state — pure for canvas)
const StaticToday = () => <TodayScreen meals={seedMeals} foods={seedFoods} streak={12} onOpenMeal={() => {}} onOpenSheet={() => {}} />;
const StaticMealDetail = () => <MealDetailScreen meal={seedMeals[2]} foods={seedFoods} onBack={() => {}} onUpdate={() => {}} onSnooze={() => {}} onSwap={() => {}} />;
const StaticAddMeal = () => <AddMealScreen foods={seedFoods} onBack={() => {}} onSave={() => {}} onAddIngr={() => {}}
initial={{ name: 'Breakfast Bowl', time: '08:00', tags: ['Breakfast', 'Pre-workout'],
  ingr: [{ fid: 'f3', g: 120 }, { fid: 'f4', g: 150 }, { fid: 'f6', g: 60 }, { fid: 'f14', g: 80 }] }} />;
const StaticAddIngr = () => <AddIngredientScreen foods={seedFoods} onBack={() => {}} onPick={() => {}} onCreateCustom={() => {}} />;
const StaticCustomFood = () => <AddCustomFoodScreen onBack={() => {}} onSave={() => {}} />;
const StaticPlans = () => <PlansScreen plans={seedPlans} onOpenPlan={() => {}} onCreate={() => {}} />;
const StaticPlanDetail = () => {
  const p = seedPlans[0];
  const planMeals = p.mealIds.map((id) => seedLibrary.find((m) => m.id === id)).filter(Boolean);
  return <PlanDetailScreen plan={p} meals={planMeals} foods={seedFoods}
  onBack={() => {}} onAddMeal={() => {}} onOpenMeal={() => {}} onEditDays={() => {}} />;
};
const StaticCreatePlan = () => <CreatePlanScreen existingPlans={seedPlans} library={seedLibrary}
foods={seedFoods} onBack={() => {}} onSave={() => {}} onConflict={() => {}} />;
const StaticHistory = () => <HistoryScreen />;
const StaticProfile = () => <ProfileScreen onOpenSheet={() => {}} prefs={initialPrefs} setPref={() => {}} />;

// Sheets shown layered on top of a base screen
const StaticSnoozeOver = () =>
<div style={{ position: 'relative', width: 390, height: 844 }}>
    <StaticMealDetail />
    <SnoozeSheet onClose={() => {}} onConfirm={() => {}} />
  </div>;

const StaticSwapOver = () =>
<div style={{ position: 'relative', width: 390, height: 844 }}>
    <StaticMealDetail />
    <SwapSheet library={seedLibrary} foods={seedFoods} onClose={() => {}} onSwap={() => {}} />
  </div>;

const StaticReminders = () =>
<div style={{ position: 'relative', width: 390, height: 844 }}>
    <StaticToday />
    <RemindersSheet onClose={() => {}} prefs={initialPrefs} setPref={() => {}} />
  </div>;

const StaticPaywall = () =>
<div style={{ position: 'relative', width: 390, height: 844 }}>
    <StaticProfile />
    <PaywallSheet onClose={() => {}} streak={12} mealsDone={142} />
  </div>;

const StaticStreakRisk = () =>
<div style={{ position: 'relative', width: 390, height: 844 }}>
    <StaticToday />
    <StreakRiskSheet onClose={() => {}} />
  </div>;

const StaticReview = () =>
<div style={{ position: 'relative', width: 390, height: 844 }}>
    <StaticToday />
    <ReviewSheet onClose={() => {}} />
  </div>;

const StaticCalendar = () =>
<div style={{ position: 'relative', width: 390, height: 844 }}>
    <StaticToday />
    <CalendarSheet onClose={() => {}} />
  </div>;

const StaticPlanDays = () =>
<div style={{ position: 'relative', width: 390, height: 844 }}>
    <StaticPlans />
    <PlanDaysEditorSheet plan={seedPlans[1]} allPlans={seedPlans}
  onClose={() => {}} onSave={() => {}} onConflict={() => {}} />
  </div>;

const StaticConflict = () => {
  // Synthesize a conflict: weekend refeed wanting Wednesday
  const fakeConflicts = [
  { day: 2, plan: seedPlans[0] },
  { day: 3, plan: seedPlans[0] }];

  return (
    <div style={{ position: 'relative', width: 390, height: 844 }}>
      <StaticPlans />
      <ConflictSheet conflicts={fakeConflicts} onClose={() => {}} onResolve={() => {}} />
    </div>);

};
const StaticToast = () =>
<div style={{ position: 'relative', width: 390, height: 844 }}>
    <StaticPlans />
    <Toast kind="error" title="Schedule conflict" body="Wednesday is already covered by Weekday Cut." />
  </div>;


// Wrap each in an iOS-feel rounded device frame.
const Device = ({ children }) =>
<div style={{
  width: 414, height: 868,
  borderRadius: 56, padding: 12,
  background: '#1a1c1a',
  boxShadow: '0 30px 80px rgba(26,28,26,0.18), 0 8px 24px rgba(26,28,26,0.06)'
}}>
    <div style={{
    width: 390, height: 844,
    borderRadius: 46,
    overflow: 'hidden',
    background: 'var(--surface)',
    position: 'relative'
  }}>
      {children}
    </div>
  </div>;


const Canvas = () =>
<DesignCanvas>
    <DCSection id="core" title="Core flow"
  subtitle="The primary daily-use screens — Today, meal detail, plans, history, profile.">
      <DCArtboard id="ab-today" label="Today (Home)" width={414} height={868}>
        <Device><App initialTab="home" /></Device>
      </DCArtboard>
      <DCArtboard id="ab-meal" label="Meal detail" width={414} height={868}>
        <Device><StaticMealDetail /></Device>
      </DCArtboard>
      <DCArtboard id="ab-plans" label="Plans library" width={414} height={868}>
        <Device><StaticPlans /></Device>
      </DCArtboard>
      <DCArtboard id="ab-plan" label="Plan detail" width={414} height={868}>
        <Device><StaticPlanDetail /></Device>
      </DCArtboard>
      <DCArtboard id="ab-createplan" label="Create plan" width={414} height={868}>
        <Device><StaticCreatePlan /></Device>
      </DCArtboard>
      <DCArtboard id="ab-history" label="History" width={414} height={868}>
        <Device><StaticHistory /></Device>
      </DCArtboard>
      <DCArtboard id="ab-profile" label="Profile" width={414} height={868}>
        <Device><StaticProfile /></Device>
      </DCArtboard>
    </DCSection>

    <DCSection id="creation" title="Adding & editing"
  subtitle="Building meals, picking ingredients, and creating custom foods.">
      <DCArtboard id="ab-addmeal" label="Add / edit meal" width={414} height={868}>
        <Device><StaticAddMeal /></Device>
      </DCArtboard>
      <DCArtboard id="ab-addingr" label="Add ingredient" width={414} height={868}>
        <Device><StaticAddIngr /></Device>
      </DCArtboard>
      <DCArtboard id="ab-custom" label="Custom food" width={414} height={868}>
        <Device data-comment-anchor="43806d9d87-div-288-3"><StaticCustomFood /></Device>
      </DCArtboard>
    </DCSection>

    <DCSection id="popups" title="Popups & sheets"
  subtitle="Bottom sheets and modals layered on top of their host screens.">
      <DCArtboard id="ab-snooze" label="Snooze" width={414} height={868}>
        <Device><StaticSnoozeOver /></Device>
      </DCArtboard>
      <DCArtboard id="ab-swap" label="Swap meal" width={414} height={868}>
        <Device><StaticSwapOver /></Device>
      </DCArtboard>
      <DCArtboard id="ab-reminders" label="Reminders" width={414} height={868}>
        <Device><StaticReminders /></Device>
      </DCArtboard>
      <DCArtboard id="ab-paywall" label="Paywall" width={414} height={868}>
        <Device><StaticPaywall /></Device>
      </DCArtboard>
      <DCArtboard id="ab-risk" label="Streak at risk" width={414} height={868}>
        <Device><StaticStreakRisk /></Device>
      </DCArtboard>
      <DCArtboard id="ab-review" label="Review prompt" width={414} height={868}>
        <Device><StaticReview /></Device>
      </DCArtboard>
      <DCArtboard id="ab-calendar" label="Calendar · stats" width={414} height={868}>
        <Device><StaticCalendar /></Device>
      </DCArtboard>
      <DCArtboard id="ab-plandays" label="Plan days editor" width={414} height={868}>
        <Device><StaticPlanDays /></Device>
      </DCArtboard>
      <DCArtboard id="ab-conflict" label="Schedule conflict" width={414} height={868}>
        <Device><StaticConflict /></Device>
      </DCArtboard>
      <DCArtboard id="ab-toast" label="Toast · error" width={414} height={868}>
        <Device><StaticToast /></Device>
      </DCArtboard>
    </DCSection>

    <DCSection id="onboarding" title="Onboarding"
  subtitle="13-screen flow: welcome → awareness → structure → video → transformation → survey × 2 → goal/meals/timing/reminders → sign up → verify. Every screen fits the viewport.">
      <DCArtboard id="ab-ob-welcome" label="1 · Welcome" width={414} height={868}>
        <Device><StaticWelcome /></Device>
      </DCArtboard>
      <DCArtboard id="ab-ob-awareness" label="2 · Awareness" width={414} height={868}>
        <Device><StaticAwareness /></Device>
      </DCArtboard>
      <DCArtboard id="ab-ob-structure" label="3 · Structure" width={414} height={868}>
        <Device><StaticStructure /></Device>
      </DCArtboard>
      <DCArtboard id="ab-ob-video" label="4 · Video demo" width={414} height={868}>
        <Device><StaticVideoDemo /></Device>
      </DCArtboard>
      <DCArtboard id="ab-ob-transformation" label="5 · Transformation" width={414} height={868}>
        <Device><StaticTransformation /></Device>
      </DCArtboard>
      <DCArtboard id="ab-ob-heard" label="6 · Heard about us" width={414} height={868}>
        <Device><StaticHeardAbout /></Device>
      </DCArtboard>
      <DCArtboard id="ab-ob-tried" label="7 · Tried other apps" width={414} height={868}>
        <Device><StaticTriedApps /></Device>
      </DCArtboard>
      <DCArtboard id="ab-ob-baseline" label="8 · Baseline (goal)" width={414} height={868}>
        <Device><StaticBaseline /></Device>
      </DCArtboard>
      <DCArtboard id="ab-ob-daily" label="9 · Meal count" width={414} height={868}>
        <Device><StaticDailyStructure /></Device>
      </DCArtboard>
      <DCArtboard id="ab-ob-timing" label="10 · Meal timing" width={414} height={868}>
        <Device><StaticMealTiming /></Device>
      </DCArtboard>
      <DCArtboard id="ab-ob-reminders" label="11 · Smart reminders" width={414} height={868}>
        <Device><StaticRemindersOB /></Device>
      </DCArtboard>
      <DCArtboard id="ab-ob-signup" label="12 · Sign up" width={414} height={868}>
        <Device><StaticSignUp /></Device>
      </DCArtboard>
      <DCArtboard id="ab-ob-verify" label="13 · Verify" width={414} height={868}>
        <Device><StaticVerify /></Device>
      </DCArtboard>
      <DCArtboard id="ab-ob-live" label="Onboarding · interactive" width={414} height={868}>
        <Device><OnboardingFlow onDone={() => {}} /></Device>
      </DCArtboard>
    </DCSection>

    <DCSection id="live" title="Live prototype"
  subtitle="Tap around — meal cards, bottom nav, popups, the lot. Fully interactive.">
      <DCArtboard id="ab-live" label="Crudo · interactive" width={414} height={868}>
        <Device><App /></Device>
      </DCArtboard>
    </DCSection>
  </DesignCanvas>;


window.Canvas = Canvas;

// Mount
const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<Canvas />);