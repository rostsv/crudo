// Crudo — Onboarding flow (redesigned, no-scroll, all 390×844)
// Order: Welcome → Awareness → Structure → VideoDemo → Transformation
//      → HeardAbout → TriedApps → Baseline → MealCount → Timing → Reminders
//      → SignUp → Verify
const { useState: useStateOB, useRef: useRefOB } = React;

// ─── tokens ──────────────────────────────────────────────────────
const C = {
  primary:  'rgb(0,77,73)',
  primary2: 'rgb(25,102,97)',
  bg:       'rgb(250,249,246)',
  text:     'rgb(26,28,26)',
  text2:    'rgb(63,73,71)',
  mut:      'rgb(111,121,119)',
  gold:     'rgb(233,185,73)',
  error:    'rgb(186,26,26)',
  surface:  'rgb(244,243,241)',
  hairline: 'rgb(227,226,224)',
};

// ─── shared chrome ───────────────────────────────────────────────
const Frame = ({ children, bg = C.bg }) => (
  <div style={{
    position: 'relative', width: 390, height: 844, background: bg,
    overflow: 'hidden', fontFamily: 'Manrope', display: 'flex', flexDirection: 'column',
  }}>
    {children}
  </div>
);

const TopBar = ({ step, total = 4 }) => (
  <div style={{
    flex: 'none', height: 90, padding: '32px 32px 16px',
    display: 'flex', alignItems: 'center', justifyContent: 'space-between',
  }}>
    <span style={{ fontWeight: 700, fontSize: 28, letterSpacing: '-0.7px', color: C.primary2, lineHeight: 1 }}>Crudo</span>
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 4 }}>
      <span style={{ fontSize: 11, letterSpacing: '0.55px', color: C.text2, fontWeight: 700 }}>STEP {step + 1} OF {total}</span>
      <div style={{ display: 'flex', gap: 6 }}>
        {Array.from({ length: total }).map((_, i) => (
          <div key={i} style={{ width: 22, height: 4, borderRadius: 2, background: i <= step ? C.primary2 : 'rgba(25,102,97,0.18)' }} />
        ))}
      </div>
    </div>
  </div>
);

const Body = ({ children, padding = '0 32px 0' }) => (
  <div style={{ flex: 1, minHeight: 0, padding, display: 'flex', flexDirection: 'column' }}>
    {children}
  </div>
);

const Sticky = ({ onBack, ctaLabel = 'Continue', onCta, ctaDisabled, ctaWide }) => (
  <div style={{
    flex: 'none', padding: '12px 32px 32px',
    display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12,
  }}>
    {onBack ? (
      <button onClick={onBack} style={{
        background: 'none', border: 'none', cursor: 'pointer', padding: '8px 4px',
        display: 'flex', alignItems: 'center', gap: 8,
        fontFamily: 'Manrope', fontSize: 13, fontWeight: 700, color: C.text, letterSpacing: '0.5px',
      }}>
        <svg width={9} height={14} viewBox="0 0 9 14" fill="none"><path d="M7 14L0 7L7 0L8.633 1.633L3.267 7L8.633 12.367L7 14Z" fill={C.text} /></svg>
        BACK
      </button>
    ) : <span />}
    <button onClick={!ctaDisabled ? onCta : undefined} disabled={ctaDisabled} style={{
      height: 56, borderRadius: 48, padding: ctaWide ? '0 56px' : '0 40px', minWidth: ctaWide ? 280 : 180,
      background: `linear-gradient(${C.primary} 0%, ${C.primary2} 100%)`,
      boxShadow: '0 12px 32px rgba(0,77,73,0.18)',
      color: '#fff', fontFamily: 'Manrope', fontSize: 17, fontWeight: 600, letterSpacing: '-0.2px',
      border: 'none', cursor: ctaDisabled ? 'default' : 'pointer',
      opacity: ctaDisabled ? 0.4 : 1,
    }}>{ctaLabel}</button>
  </div>
);

const PrimaryBtn = ({ label, onClick, disabled, style = {} }) => (
  <button onClick={!disabled ? onClick : undefined} disabled={disabled} style={{
    width: '100%', height: 64, borderRadius: 48,
    background: `linear-gradient(${C.primary} 0%, ${C.primary2} 100%)`,
    boxShadow: '0 20px 40px rgba(26,28,26,0.04)',
    color: '#fff', fontFamily: 'Manrope', fontSize: 18, fontWeight: 600, letterSpacing: '-0.2px',
    border: 'none', cursor: disabled ? 'default' : 'pointer',
    opacity: disabled ? 0.4 : 1, transition: 'opacity .15s',
    ...style,
  }}>{label}</button>
);

const TextBtn = ({ label, onClick }) => (
  <button onClick={onClick} style={{
    background: 'none', border: 'none', cursor: 'pointer',
    fontSize: 12, letterSpacing: '1px', color: C.mut, fontWeight: 700,
    fontFamily: 'Manrope', padding: '8px 0',
  }}>{label}</button>
);

const Headline = ({ kicker, title, sub }) => (
  <div style={{ marginBottom: 24, flex: 'none', paddingTop: 8 }}>
    {kicker && <div style={{ fontSize: 11, letterSpacing: '1.2px', color: C.primary2, fontWeight: 700, marginBottom: 8 }}>{kicker}</div>}
    <div style={{ fontSize: 40, fontWeight: 400, lineHeight: '44px', letterSpacing: '-0.8px', color: C.text, textWrap: 'pretty' }}>{title}</div>
    {sub && <div style={{ fontSize: 16, color: C.text2, lineHeight: '23px', marginTop: 16, textWrap: 'pretty', opacity: 0.85 }}>{sub}</div>}
  </div>
);

// ─── 1. WELCOME ──────────────────────────────────────────────────
const WelcomeScreen = ({ onNext, onSignIn }) => (
  <Frame>
    {/* Ambient glows */}
    <div style={{ position: 'absolute', left: -60, top: -80, width: 320, height: 320, borderRadius: 9999, background: 'rgba(169,239,233,0.25)', pointerEvents: 'none' }} />
    <div style={{ position: 'absolute', right: -40, top: 380, width: 280, height: 280, borderRadius: 9999, background: 'rgba(255,219,206,0.3)', pointerEvents: 'none' }} />

    {/* Wordmark */}
    <div style={{ flex: 'none', textAlign: 'center', paddingTop: 56, paddingBottom: 8 }}>
      <span style={{ fontWeight: 800, fontSize: 26, letterSpacing: '-1.2px', color: C.primary }}>Crudo</span>
    </div>

    {/* Hero cards */}
    <div style={{ flex: 'none', position: 'relative', height: 280, margin: '12px 24px 0' }}>
      {/* Morning card */}
      <div style={{ position: 'absolute', left: 14, top: 16, right: 14, height: 84, borderRadius: 28, background: '#fff', boxShadow: '0 16px 32px rgba(0,0,0,0.08)', display: 'flex', alignItems: 'center', padding: '0 18px' }}>
        <div style={{ width: 6, height: 40, borderRadius: 999, background: C.primary2 }} />
        <div style={{ marginLeft: 14, flex: 1 }}>
          <div style={{ fontSize: 10, letterSpacing: '1px', color: C.mut, fontWeight: 700 }}>08:00 AM</div>
          <div style={{ fontSize: 16, fontWeight: 700, color: C.text, marginTop: 2 }}>Protein Bowl</div>
        </div>
        <div style={{ width: 28, height: 28, borderRadius: 999, background: C.primary2, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <svg width={12} height={9} viewBox="0 0 12 9"><path d="M4.5 9L0 4.6 1.4 3.2 4.5 6.2 10.6 0 12 1.4 4.5 9Z" fill="#fff" /></svg>
        </div>
      </div>
      {/* Lunch card */}
      <div style={{ position: 'absolute', left: -2, top: 110, right: 30, height: 84, borderRadius: 28, background: '#fff', boxShadow: '0 8px 16px rgba(0,0,0,0.06)', display: 'flex', alignItems: 'center', padding: '0 18px' }}>
        <div style={{ width: 6, height: 40, borderRadius: 999, background: C.gold }} />
        <div style={{ marginLeft: 14, flex: 1 }}>
          <div style={{ fontSize: 10, letterSpacing: '1px', color: C.mut, fontWeight: 700, display: 'flex', gap: 6 }}>
            <span style={{ textDecoration: 'line-through', opacity: 0.5 }}>12:30</span>
            <span style={{ color: C.gold }}>13:15</span>
          </div>
          <div style={{ fontSize: 16, fontWeight: 700, color: C.text2, marginTop: 2 }}>Quinoa Salad</div>
        </div>
        <div style={{ width: 28, height: 28, borderRadius: 999, background: C.gold, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div style={{ width: 4, height: 12, background: '#fff', borderRadius: 2 }} />
        </div>
      </div>
      {/* Dinner card */}
      <div style={{ position: 'absolute', left: 22, top: 204, right: 6, height: 84, borderRadius: 28, background: '#fff', boxShadow: '0 4px 8px rgba(0,0,0,0.05)', display: 'flex', alignItems: 'center', padding: '0 18px' }}>
        <div style={{ width: 6, height: 40, borderRadius: 999, background: 'rgba(0,77,73,0.2)' }} />
        <div style={{ marginLeft: 14, flex: 1 }}>
          <div style={{ fontSize: 10, letterSpacing: '1px', color: C.mut, fontWeight: 700 }}>07:00 PM</div>
          <div style={{ fontSize: 16, fontWeight: 700, color: C.text2, marginTop: 2 }}>Baked Salmon</div>
        </div>
        <div style={{ width: 22, height: 22, borderRadius: 999, border: '2px solid rgba(111,121,119,0.25)' }} />
      </div>
    </div>

    {/* Copy */}
    <div style={{ flex: 1, padding: '24px 28px 0', textAlign: 'center', minHeight: 0 }}>
      <div style={{ fontSize: 30, fontWeight: 800, lineHeight: '34px', letterSpacing: '-0.8px', color: C.text, textWrap: 'pretty' }}>
        Follow your meal plan without overthinking
      </div>
      <div style={{ fontSize: 14, color: C.text2, lineHeight: '20px', marginTop: 12 }}>
        Build your meals once, get reminded on time, keep your streak alive.
      </div>
    </div>

    {/* CTAs */}
    <Sticky>
      <PrimaryBtn label="SET UP MY PLAN" onClick={onNext} />
      <TextBtn label="I ALREADY HAVE AN ACCOUNT" onClick={onSignIn} />
    </Sticky>
  </Frame>
);

// ─── 2. AWARENESS ────────────────────────────────────────────────
const AwarenessScreen = ({ onNext, onBack }) => (
  <Frame>
    <TopBar step={0} />
    <Body>
      <Headline title={<>You already<br />know the plan.</>} sub="The struggle isn't information — it's the friction of modern life." />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 10, minHeight: 0 }}>
        {[
          { title: 'Skipped Meals', sub: 'Days fly by — meals get forgotten.' },
          { title: 'Lost Momentum', sub: 'One missed meal cascades into a derailed day.' },
          { title: 'Decision Fatigue', sub: '"What should I eat now?" drains willpower.' },
        ].map((c) => (
          <div key={c.title} style={{ padding: '14px 18px', borderRadius: 20, background: '#fff', boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}>
            <div style={{ fontSize: 14, fontWeight: 700, color: C.text }}>{c.title}</div>
            <div style={{ fontSize: 12, color: C.text2, lineHeight: '17px', marginTop: 3 }}>{c.sub}</div>
          </div>
        ))}
      </div>
    </Body>
    <Sticky onBack={onBack} onCta={onNext} />
  </Frame>
);

// ─── 3. STRUCTURE (chaos vs crudo) ───────────────────────────────
const StructureScreen = ({ onNext, onBack }) => {
  const Row = ({ name, time, kind }) => {
    const isErr = kind === 'err';
    return (
      <div style={{
        padding: '10px 14px', borderRadius: 24,
        background: isErr ? C.surface : 'rgba(0,77,73,0.06)',
        display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12,
      }}>
        <div style={{ display: 'flex', gap: 12, alignItems: 'center', minWidth: 0 }}>
          <div style={{
            width: 32, height: 32, borderRadius: 999,
            background: isErr ? '#fff' : C.primary,
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
          }}>
            {isErr ? (
              <svg width={11} height={11} viewBox="0 0 11 11"><path d="M1.4 11L0 9.6 4.1 5.5 0 1.4 1.4 0 5.5 4.1 9.6 0 11 1.4 6.9 5.5 11 9.6 9.6 11 5.5 6.9 1.4 11Z" fill={C.error} /></svg>
            ) : (
              <svg width={11} height={9} viewBox="0 0 11 9"><path d="M4 9L0 4.6 1.4 3.2 4 5.8 9.6 0 11 1.4 4 9Z" fill="#fff" /></svg>
            )}
          </div>
          <div style={{ minWidth: 0 }}>
            <div style={{ fontSize: 13, color: isErr ? C.text : C.primary, fontWeight: 700 }}>{name}</div>
            <div style={{ fontSize: 11, color: C.text2, marginTop: 1 }}>{time}</div>
          </div>
        </div>
      </div>
    );
  };
  return (
    <Frame>
      <TopBar step={1} />
      <Body>
        <Headline title={<>Structure beats<br />willpower.</>} sub="Crudo holds the rhythm so you don't have to." />
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 12, minHeight: 0 }}>
          <div>
            <div style={{ fontSize: 10, letterSpacing: '1px', color: C.error, fontWeight: 700, marginBottom: 8 }}>WITHOUT STRUCTURE</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              <Row name="Skipped breakfast" time='"Too busy"' kind="err" />
              <Row name="Random snacking" time="Sugar spike" kind="err" />
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0' }}>
            <div style={{ width: 36, height: 36, borderRadius: 999, border: `1px solid ${C.hairline}`, background: C.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 10, letterSpacing: '1px', color: C.mut, fontWeight: 800 }}>VS</div>
          </div>
          <div>
            <div style={{ fontSize: 10, letterSpacing: '1px', color: C.primary, fontWeight: 700, marginBottom: 8 }}>WITH CRUDO</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              <Row name="High-protein morning" time="08:00 AM" />
              <Row name="Planned fuel" time="01:00 PM" />
            </div>
          </div>
        </div>
      </Body>
      <Sticky onBack={onBack} onCta={onNext} />
    </Frame>
  );
};

// ─── 4. VIDEO DEMO ───────────────────────────────────────────────
const VideoDemoScreen = ({ onNext, onBack, onSkip }) => (
  <Frame>
    <TopBar step={2} />
    <Body>
      <Headline kicker="60 SECOND TOUR" title="See how Crudo works" sub="Plans, reminders, snoozing — the daily loop, in under a minute." />
      {/* Video player placeholder, 9:16 ratio inside a phone-style frame */}
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: 0, padding: '4px 0 12px' }}>
        <div style={{
          width: 240, height: 426,
          borderRadius: 32, overflow: 'hidden', position: 'relative',
          background: `linear-gradient(135deg, ${C.primary} 0%, ${C.primary2} 60%, rgba(169,239,233,0.7) 100%)`,
          boxShadow: '0 24px 48px rgba(0,77,73,0.3), 0 8px 16px rgba(0,0,0,0.1)',
        }}>
          {/* Faux UI behind play button */}
          <div style={{ position: 'absolute', inset: 0, opacity: 0.45 }}>
            <div style={{ position: 'absolute', top: 28, left: 18, right: 18, height: 14, borderRadius: 999, background: 'rgba(255,255,255,0.25)' }} />
            <div style={{ position: 'absolute', top: 56, left: 18, width: 90, height: 12, borderRadius: 999, background: 'rgba(255,255,255,0.35)' }} />
            <div style={{ position: 'absolute', top: 86, left: 18, right: 18, height: 70, borderRadius: 18, background: 'rgba(255,255,255,0.18)' }} />
            <div style={{ position: 'absolute', top: 168, left: 18, right: 18, height: 70, borderRadius: 18, background: 'rgba(255,255,255,0.14)' }} />
            <div style={{ position: 'absolute', top: 250, left: 18, right: 18, height: 70, borderRadius: 18, background: 'rgba(255,255,255,0.10)' }} />
          </div>

          {/* Play button */}
          <div style={{
            position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <div style={{
              width: 80, height: 80, borderRadius: 999, background: 'rgba(255,255,255,0.92)',
              boxShadow: '0 16px 40px rgba(0,0,0,0.25)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              backdropFilter: 'blur(8px)',
            }}>
              <svg width={26} height={28} viewBox="0 0 26 28">
                <path d="M26 14L0 28V0L26 14Z" fill={C.primary} />
              </svg>
            </div>
          </div>

          {/* Duration pill */}
          <div style={{
            position: 'absolute', bottom: 16, left: '50%', transform: 'translateX(-50%)',
            padding: '6px 12px', borderRadius: 999, background: 'rgba(0,0,0,0.4)',
            fontSize: 11, color: '#fff', fontWeight: 700, letterSpacing: '0.5px',
            backdropFilter: 'blur(4px)',
          }}>0:58</div>

          {/* Caption */}
          <div style={{
            position: 'absolute', top: 16, left: 16, padding: '4px 10px', borderRadius: 8,
            background: 'rgba(0,0,0,0.3)', fontSize: 10, color: '#fff', fontWeight: 700, letterSpacing: '0.5px',
            backdropFilter: 'blur(4px)',
          }}>DEMO</div>
        </div>
      </div>
    </Body>
    <Sticky onBack={onBack} ctaLabel="Watch & Continue" onCta={onNext} ctaWide />
  </Frame>
);

// ─── 5. TRANSFORMATION ───────────────────────────────────────────
const TransformationScreen = ({ onNext, onBack }) => (
  <Frame>
    <TopBar step={3} />
    <Body>
      <Headline title={<>Turn your plan<br />into a routine.</>} sub="Ingredients, gram amounts, reminders, and quick check-ins help you stay on track every day." />
      <div style={{ flex: 'none', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8, marginBottom: 18 }}>
        {[
          { n: '3×',  label: 'Consistency', sub: 'vs no system' },
          { n: '87%', label: 'Adherence',   sub: 'avg week 2' },
          { n: '21d', label: 'Habit',       sub: 'with reminders' },
        ].map((s) => (
          <div key={s.n} style={{ padding: '14px 8px', borderRadius: 20, background: '#fff', boxShadow: '0 2px 8px rgba(0,0,0,0.04)', textAlign: 'center' }}>
            <div style={{ fontSize: 22, fontWeight: 800, color: C.primary, letterSpacing: '-0.5px', lineHeight: 1 }}>{s.n}</div>
            <div style={{ fontSize: 10, fontWeight: 700, color: C.text, marginTop: 6 }}>{s.label}</div>
            <div style={{ fontSize: 9, color: C.mut, marginTop: 2 }}>{s.sub}</div>
          </div>
        ))}
      </div>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 12, minHeight: 0 }}>
        {[
          { title: 'Smart reminders', body: 'Nudges at the right moment, not just a fixed time.' },
          { title: 'Structured plans', body: 'Assign meals to days. Crudo tracks what is next.' },
          { title: 'Flexible snoozing', body: 'Push a meal forward without losing your streak.' },
        ].map((f, i) => (
          <div key={f.title} style={{ display: 'flex', gap: 14, alignItems: 'center' }}>
            <div style={{
              width: 36, height: 36, borderRadius: 12, background: 'rgba(0,77,73,0.08)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
              fontSize: 14, fontWeight: 800, color: C.primary,
            }}>0{i + 1}</div>
            <div style={{ minWidth: 0 }}>
              <div style={{ fontSize: 14, fontWeight: 700, color: C.text }}>{f.title}</div>
              <div style={{ fontSize: 12, color: C.text2, lineHeight: '17px', marginTop: 2 }}>{f.body}</div>
            </div>
          </div>
        ))}
      </div>
    </Body>
    <Sticky onBack={onBack} ctaLabel="Build my plan" onCta={onNext} ctaWide />
  </Frame>
);

// ─── 6. HEARD ABOUT US ───────────────────────────────────────────
const HeardAboutScreen = ({ onNext, onBack, source, setSource }) => {
  const opts = [
    { id: 'tiktok',     label: 'TikTok',          glyph: 'T' },
    { id: 'instagram',  label: 'Instagram',       glyph: 'I' },
    { id: 'youtube',    label: 'YouTube',         glyph: 'Y' },
    { id: 'reddit',     label: 'Reddit',          glyph: 'R' },
    { id: 'friend',     label: 'Friend / family', glyph: 'F' },
    { id: 'search',     label: 'App store / search', glyph: 'S' },
    { id: 'press',      label: 'Press / blog',    glyph: 'P' },
    { id: 'other',      label: 'Somewhere else',  glyph: '·' },
  ];
  return (
    <Frame>
      <TopBar step={4} />
      <Body>
        <Headline kicker="QUICK ONE" title="Where did you hear about Crudo?" sub="Helps us know what's working. Pick one." />
        <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '1fr 1fr', gridAutoRows: '64px', gap: 10, minHeight: 0 }}>
          {opts.map((o) => {
            const on = source === o.id;
            return (
              <button key={o.id} onClick={() => setSource(o.id)} style={{
                borderRadius: 20, border: `2px solid ${on ? C.primary2 : 'transparent'}`,
                background: on ? 'rgba(0,77,73,0.07)' : '#fff',
                boxShadow: '0 2px 8px rgba(0,0,0,0.04)', cursor: 'pointer',
                display: 'flex', alignItems: 'center', gap: 10, padding: '0 14px',
                textAlign: 'left', fontFamily: 'Manrope', transition: 'all .15s',
              }}>
                <div style={{
                  width: 32, height: 32, borderRadius: 999,
                  background: on ? C.primary : 'rgba(0,77,73,0.08)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 13, fontWeight: 800, color: on ? '#fff' : C.primary,
                }}>{o.glyph}</div>
                <span style={{ fontSize: 13, fontWeight: 700, color: C.text, lineHeight: '16px' }}>{o.label}</span>
              </button>
            );
          })}
        </div>
      </Body>
      <Sticky onBack={onBack} onCta={onNext} ctaDisabled={!source} />
    </Frame>
  );
};

// ─── 7. TRIED OTHER APPS ─────────────────────────────────────────
const TriedAppsScreen = ({ onNext, onBack, tried, setTried }) => {
  const opts = [
    { id: 'mfp',     label: 'MyFitnessPal',     sub: 'Calorie & macro logger' },
    { id: 'noom',    label: 'Noom',             sub: 'Behavioural coaching' },
    { id: 'lose',    label: 'Lose It! / Cronometer', sub: 'Calorie tracking' },
    { id: 'chronic', label: 'Mealime / Eat This Much', sub: 'Recipe planners' },
    { id: 'multi',   label: 'A few of these',   sub: 'And kept switching' },
    { id: 'none',    label: 'No, this is my first', sub: 'Fresh start' },
  ];
  return (
    <Frame>
      <TopBar step={5} />
      <Body>
        <Headline kicker="ONE MORE" title="Tried something like this before?" sub="No judgement — most of us have a graveyard of nutrition apps. Pick the closest." />
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 8, minHeight: 0 }}>
          {opts.map((o) => {
            const on = tried === o.id;
            return (
              <button key={o.id} onClick={() => setTried(o.id)} style={{
                width: '100%', padding: '12px 16px', borderRadius: 20,
                background: on ? 'rgba(0,77,73,0.07)' : '#fff',
                border: `2px solid ${on ? C.primary2 : 'transparent'}`,
                boxShadow: '0 2px 8px rgba(0,0,0,0.04)', cursor: 'pointer',
                display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                textAlign: 'left', fontFamily: 'Manrope', transition: 'all .15s',
              }}>
                <div style={{ minWidth: 0 }}>
                  <div style={{ fontSize: 14, fontWeight: 700, color: C.text }}>{o.label}</div>
                  <div style={{ fontSize: 11, color: C.mut, marginTop: 2 }}>{o.sub}</div>
                </div>
                <div style={{
                  width: 22, height: 22, borderRadius: 999,
                  border: `2px solid ${on ? C.primary2 : 'rgba(0,77,73,0.25)'}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                }}>
                  {on && <div style={{ width: 10, height: 10, borderRadius: 999, background: C.primary2 }} />}
                </div>
              </button>
            );
          })}
        </div>
      </Body>
      <Sticky onBack={onBack} onCta={onNext} ctaDisabled={!tried} />
    </Frame>
  );
};

// ─── 8. BASELINE (goal) ──────────────────────────────────────────
const BaselineScreen = ({ onNext, onBack, goal, setGoal }) => {
  const goals = [
    { id: 'cut',      label: 'Cut',      body: 'Reduce body fat while preserving lean muscle mass.' },
    { id: 'maintain', label: 'Maintain', body: 'Sustain your current body composition and optimize daily energy levels.' },
    { id: 'bulk',     label: 'Bulk',     body: 'Focus on progressive muscle hypertrophy with a calculated caloric surplus.' },
  ];
  return (
    <Frame>
      <TopBar step={0} />
      <Body>
        <Headline title={<>Define your<br />baseline.</>} sub="Choose your primary goal — fine-tune later." />
        <div style={{ fontSize: 11, letterSpacing: '0.55px', color: C.text2, fontWeight: 600, marginBottom: 12 }}>PRIMARY GOAL</div>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 10, minHeight: 0 }}>
          {goals.map((g) => {
            const on = goal === g.id;
            return (
              <button key={g.id} onClick={() => setGoal(g.id)} style={{
                width: '100%', padding: '16px 20px', borderRadius: 24, textAlign: 'left',
                background: on ? C.primary : '#fff',
                boxShadow: on ? '0 12px 28px rgba(0,77,73,0.22)' : '0 2px 8px rgba(0,0,0,0.04)',
                border: 'none', cursor: 'pointer', fontFamily: 'Manrope', transition: 'all .15s',
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
                  <span style={{ fontSize: 16, fontWeight: 700, color: on ? '#fff' : C.text }}>{g.label}</span>
                  <div style={{
                    width: 22, height: 22, borderRadius: 999,
                    border: `2px solid ${on ? '#fff' : 'rgba(0,77,73,0.3)'}`,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}>
                    {on && <div style={{ width: 10, height: 10, borderRadius: 999, background: '#fff' }} />}
                  </div>
                </div>
                <div style={{ fontSize: 12, color: on ? 'rgba(255,255,255,0.85)' : C.text2, lineHeight: '17px' }}>{g.body}</div>
              </button>
            );
          })}
        </div>
      </Body>
      <Sticky onBack={onBack} onCta={onNext} />
    </Frame>
  );
};

// ─── 9. DAILY STRUCTURE (meal count) ─────────────────────────────
const DailyStructureScreen = ({ onNext, onBack, mealCount, setMealCount }) => {
  const opts = [
    { n: 2, label: 'Two meals', sub: 'OMAD adjacent' },
    { n: 3, label: 'Three meals', sub: 'Classic rhythm' },
    { n: 4, label: 'Four meals', sub: 'With a snack' },
    { n: 5, label: 'Five meals', sub: 'Smaller portions' },
  ];
  return (
    <Frame>
      <TopBar step={1} />
      <Body>
        <Headline title={<>How many meals<br />do you eat in a day?</>} sub="We'll space your reminders accordingly." />
        <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, minHeight: 0 }}>
          {opts.map((o) => {
            const on = mealCount === o.n;
            return (
              <button key={o.n} onClick={() => setMealCount(o.n)} style={{
                borderRadius: 28, border: 'none', cursor: 'pointer',
                background: on ? C.primary : '#fff',
                boxShadow: on ? '0 12px 28px rgba(0,77,73,0.22)' : '0 4px 12px rgba(26,28,26,0.05)',
                display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 4,
                fontFamily: 'Manrope', transition: 'all .15s',
              }}>
                <span style={{ fontSize: 36, fontWeight: 800, letterSpacing: '-1.5px', lineHeight: 1, color: on ? '#fff' : C.text }}>0{o.n}</span>
                <span style={{ fontSize: 12, fontWeight: 700, color: on ? 'rgba(255,255,255,0.9)' : C.text }}>{o.label}</span>
                <span style={{ fontSize: 10, color: on ? 'rgba(255,255,255,0.7)' : C.mut }}>{o.sub}</span>
              </button>
            );
          })}
        </div>
      </Body>
      <Sticky onBack={onBack} onCta={onNext} />
    </Frame>
  );
};

// ─── 10. MEAL TIMING ─────────────────────────────────────────────
const MealTimingScreen = ({ onNext, onBack, timing, setTiming }) => {
  const opts = [
    { id: 'fixed', title: 'Fixed meal times',   sub: 'Specific times for every meal.' },
    { id: 'flex',  title: 'Flexible intervals', sub: 'Eat when your body signals hunger naturally.' },
  ];
  return (
    <Frame>
      <TopBar step={2} />
      <Body>
        <Headline title={<>How should your<br />plan work?</>} sub="Choose how you want to structure your daily eating." />
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 12, minHeight: 0 }}>
          {opts.map((o) => {
            const on = timing === o.id;
            return (
              <button key={o.id} onClick={() => setTiming(o.id)} style={{
                width: '100%', padding: '20px 22px', borderRadius: 28, textAlign: 'left',
                background: '#fff', border: `2px solid ${on ? C.primary2 : 'transparent'}`,
                boxShadow: '0 2px 8px rgba(0,0,0,0.04)', cursor: 'pointer',
                display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 14,
                fontFamily: 'Manrope', transition: 'all .15s',
              }}>
                <div style={{ minWidth: 0 }}>
                  <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.3px', color: on ? C.primary2 : C.text }}>{o.title}</div>
                  <div style={{ fontSize: 12, color: C.text2, marginTop: 4, lineHeight: '17px' }}>{o.sub}</div>
                </div>
                <div style={{
                  width: 22, height: 22, borderRadius: 999, flexShrink: 0,
                  border: `2px solid ${on ? C.primary2 : 'rgba(0,77,73,0.3)'}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  {on && <div style={{ width: 10, height: 10, borderRadius: 999, background: C.primary2 }} />}
                </div>
              </button>
            );
          })}
        </div>
      </Body>
      <Sticky onBack={onBack} onCta={onNext} />
    </Frame>
  );
};

// ─── 11. SMART REMINDERS ─────────────────────────────────────────
const RemindersOBScreen = ({ onNext, onBack, reminders, setReminders }) => {
  const opts = [
    { id: 'pre',  label: 'Before meals',     sub: '15 min prep nudge' },
    { id: 'at',   label: 'At meal time',     sub: 'Time to eat' },
    { id: 'warn', label: 'If running late',  sub: 'Overdue alert' },
    { id: 'eod',  label: 'End of day',       sub: 'Streak check-in' },
  ];
  const toggle = (id) => setReminders((r) => r.includes(id) ? r.filter((x) => x !== id) : [...r, id]);
  return (
    <Frame>
      <TopBar step={3} />
      <Body>
        <Headline title={<>Don't let a busy<br />day break your plan.</>} sub="Stay on track with gentle, perfectly timed nudges tailored to your lifestyle." />
        {/* Mock notification */}
        <div style={{ flex: 'none', borderRadius: 28, background: '#fff', boxShadow: '0 12px 28px rgba(26,28,26,0.06)', padding: 16, marginBottom: 14 }}>
          <div style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
            <div style={{ width: 36, height: 36, borderRadius: 999, background: C.primary2, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <svg width={14} height={14} viewBox="0 0 18 18"><path d="M9 0a9 9 0 100 18A9 9 0 009 0zm1 13H8V8h2v5zm0-7H8V4h2v2z" fill="#fff"/></svg>
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 2 }}>
                <span style={{ fontSize: 10, letterSpacing: '0.5px', color: C.mut, fontWeight: 700 }}>CRUDO</span>
                <span style={{ fontSize: 10, color: C.mut }}>Just now</span>
              </div>
              <div style={{ fontSize: 13, fontWeight: 700, color: C.text }}>Meal 3 is due</div>
              <div style={{ fontSize: 11, color: C.text2, marginTop: 2, lineHeight: '15px' }}>Time to fuel up! Your Grilled Chicken Salad is waiting.</div>
            </div>
          </div>
        </div>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 8, minHeight: 0 }}>
          {opts.map((o) => {
            const on = reminders.includes(o.id);
            return (
              <button key={o.id} onClick={() => toggle(o.id)} style={{
                width: '100%', padding: '12px 16px', borderRadius: 20, textAlign: 'left',
                background: on ? 'rgba(0,77,73,0.07)' : '#fff',
                border: `2px solid ${on ? C.primary2 : 'transparent'}`,
                boxShadow: '0 2px 8px rgba(0,0,0,0.04)', cursor: 'pointer',
                display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                fontFamily: 'Manrope', transition: 'all .15s',
              }}>
                <div>
                  <div style={{ fontSize: 13, fontWeight: 700, color: C.text }}>{o.label}</div>
                  <div style={{ fontSize: 11, color: C.mut, marginTop: 1 }}>{o.sub}</div>
                </div>
                <div style={{
                  width: 22, height: 22, borderRadius: 5,
                  background: on ? C.primary : '#fff',
                  border: `2px solid ${on ? C.primary : 'rgba(0,77,73,0.25)'}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                }}>
                  {on && <svg width={11} height={9} viewBox="0 0 13 10"><path d="M4.5 10L0 5.5l1.4-1.4L4.5 7.1 11.6 0 13 1.4 4.5 10Z" fill="#fff"/></svg>}
                </div>
              </button>
            );
          })}
        </div>
      </Body>
      <Sticky onBack={onBack} onCta={onNext} />
    </Frame>
  );
};

// ─── 12. SIGN UP ─────────────────────────────────────────────────
const SignUpScreen = ({ onNext, onBack }) => {
  const [name, setName] = useStateOB('');
  const [email, setEmail] = useStateOB('');
  const [pass, setPass] = useStateOB('');
  const valid = name.trim() && email.includes('@') && pass.length >= 6;
  const inputStyle = {
    width: '100%', height: 46, borderRadius: 12, border: `1px solid ${C.hairline}`,
    padding: '0 16px', fontSize: 14, fontFamily: 'Manrope', color: C.text,
    background: '#fff', outline: 'none', boxSizing: 'border-box',
  };
  return (
    <div style={{ position: 'relative', width: 390, height: 844, overflow: 'hidden', fontFamily: 'Manrope' }}>
      <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 320, background: C.primary }} />
      <div style={{ position: 'absolute', top: 320, left: 0, right: 0, bottom: 0, background: 'rgb(248,249,251)' }} />
      <div style={{ position: 'absolute', top: 56, left: 0, right: 0, textAlign: 'center' }}>
        <span style={{ fontWeight: 800, fontSize: 26, letterSpacing: '-1.2px', color: '#fff' }}>Crudo</span>
      </div>
      <button onClick={onBack} style={{
        position: 'absolute', top: 48, left: 16, width: 40, height: 40,
        background: 'transparent', border: 'none', cursor: 'pointer',
        display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 0,
      }}>
        <svg width={9} height={14} viewBox="0 0 9 14"><path d="M7 14L0 7L7 0L8.633 1.633L3.267 7L8.633 12.367L7 14Z" fill="rgba(255,255,255,0.85)" /></svg>
      </button>
      <div style={{ position: 'absolute', top: 132, left: 24, right: 24, borderRadius: 32, background: '#fff', boxShadow: '0 16px 40px rgba(0,0,0,0.06)', padding: '32px 28px' }}>
        <div style={{ textAlign: 'center', marginBottom: 24 }}>
          <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: '-0.4px', color: C.text }}>Your plan starts here</div>
          <div style={{ fontSize: 13, color: C.text2, marginTop: 6, lineHeight: '18px' }}>Create an account to keep your progress safe.</div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <input style={inputStyle} placeholder="Name" value={name} onChange={(e) => setName(e.target.value)} />
          <input style={inputStyle} placeholder="Email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
          <input style={inputStyle} placeholder="Password (6+ chars)" type="password" value={pass} onChange={(e) => setPass(e.target.value)} />
        </div>
        <div style={{ marginTop: 20 }}>
          <PrimaryBtn label="CREATE ACCOUNT" onClick={() => onNext(email)} disabled={!valid} />
        </div>
        <div style={{ marginTop: 16, fontSize: 11, color: C.mut, textAlign: 'center', lineHeight: '15px' }}>
          By creating an account you agree to our Terms and Privacy Policy.
        </div>
      </div>
    </div>
  );
};

// ─── 13. VERIFY ──────────────────────────────────────────────────
const VerifyScreen = ({ onNext, onBack, email }) => {
  const [code, setCode] = useStateOB(['', '', '', '', '', '']);
  const refs = Array.from({ length: 6 }, () => useRefOB(null));
  const update = (i, val) => {
    const v = val.replace(/\D/, '');
    const next = [...code]; next[i] = v; setCode(next);
    if (v && i < 5) refs[i + 1].current?.focus();
  };
  const full = code.every((c) => c !== '');
  return (
    <div style={{ position: 'relative', width: 390, height: 844, overflow: 'hidden', fontFamily: 'Manrope' }}>
      <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 320, background: C.primary }} />
      <div style={{ position: 'absolute', top: 320, left: 0, right: 0, bottom: 0, background: 'rgb(248,249,251)' }} />
      <div style={{ position: 'absolute', top: 56, left: 0, right: 0, textAlign: 'center' }}>
        <span style={{ fontWeight: 800, fontSize: 26, letterSpacing: '-1.2px', color: '#fff' }}>Crudo</span>
      </div>
      <button onClick={onBack} style={{
        position: 'absolute', top: 48, left: 16, width: 40, height: 40,
        background: 'transparent', border: 'none', cursor: 'pointer',
        display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 0,
      }}>
        <svg width={9} height={14} viewBox="0 0 9 14"><path d="M7 14L0 7L7 0L8.633 1.633L3.267 7L8.633 12.367L7 14Z" fill="rgba(255,255,255,0.85)" /></svg>
      </button>
      <div style={{ position: 'absolute', top: 132, left: 24, right: 24, borderRadius: 32, background: '#fff', boxShadow: '0 16px 40px rgba(0,0,0,0.06)', padding: '32px 28px' }}>
        <div style={{ textAlign: 'center', marginBottom: 20 }}>
          <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: '-0.4px', color: C.text }}>Verify your account</div>
          <div style={{ fontSize: 13, color: C.text2, marginTop: 6, lineHeight: '18px' }}>Enter the security code sent to your email.</div>
        </div>
        <div style={{ padding: '12px 16px', borderRadius: 14, background: C.surface, border: `1px solid rgba(227,226,224,0.5)`, textAlign: 'center', marginBottom: 20, fontSize: 12, color: C.text2, fontWeight: 500 }}>
          {email || 'you@example.com'}
        </div>
        <div style={{ display: 'flex', gap: 6, justifyContent: 'center', marginBottom: 20 }}>
          {code.map((c, i) => (
            <input key={i} ref={refs[i]} maxLength={1} value={c}
              onChange={(e) => update(i, e.target.value)}
              onKeyDown={(e) => e.key === 'Backspace' && !c && i > 0 && refs[i - 1].current?.focus()}
              style={{
                width: 40, height: 52, borderRadius: 12, border: `2px solid ${c ? C.primary2 : C.hairline}`,
                textAlign: 'center', fontSize: 20, fontWeight: 700, fontFamily: 'Manrope',
                color: C.primary, outline: 'none', background: '#fff', transition: 'border .15s',
              }} />
          ))}
        </div>
        <PrimaryBtn label="VERIFY" onClick={onNext} disabled={!full} />
        <div style={{ textAlign: 'center', marginTop: 8 }}>
          <TextBtn label="RESEND CODE" />
        </div>
      </div>
    </div>
  );
};

// ─── FULL ONBOARDING FLOW ────────────────────────────────────────
const OnboardingFlow = ({ onDone }) => {
  const [step, setStep] = useStateOB(0);
  const [goal, setGoal] = useStateOB('cut');
  const [mealCount, setMealCount] = useStateOB(3);
  const [timing, setTiming] = useStateOB('fixed');
  const [reminders, setReminders] = useStateOB(['pre', 'at']);
  const [source, setSource] = useStateOB('');
  const [tried, setTried] = useStateOB('');
  const [email, setEmail] = useStateOB('');

  const next = () => setStep((s) => s + 1);
  const back = () => setStep((s) => Math.max(0, s - 1));

  const screens = [
    <WelcomeScreen onNext={next} onSignIn={() => setStep(11)} />,
    <AwarenessScreen onNext={next} onBack={back} />,
    <StructureScreen onNext={next} onBack={back} />,
    <VideoDemoScreen onNext={next} onBack={back} />,
    <TransformationScreen onNext={next} onBack={back} />,
    <HeardAboutScreen onNext={next} onBack={back} source={source} setSource={setSource} />,
    <TriedAppsScreen onNext={next} onBack={back} tried={tried} setTried={setTried} />,
    <BaselineScreen onNext={next} onBack={back} goal={goal} setGoal={setGoal} />,
    <DailyStructureScreen onNext={next} onBack={back} mealCount={mealCount} setMealCount={setMealCount} />,
    <MealTimingScreen onNext={next} onBack={back} timing={timing} setTiming={setTiming} />,
    <RemindersOBScreen onNext={next} onBack={back} reminders={reminders} setReminders={setReminders} />,
    <SignUpScreen onNext={(e) => { setEmail(e); next(); }} onBack={back} />,
    <VerifyScreen onNext={onDone || next} onBack={back} email={email} />,
  ];

  return (
    <div style={{ width: 390, height: 844, overflow: 'hidden', position: 'relative' }}>
      <div style={{
        display: 'flex', width: `${screens.length * 390}px`,
        transform: `translateX(-${step * 390}px)`,
        transition: 'transform .35s cubic-bezier(0.4,0,0.2,1)',
      }}>
        {screens.map((s, i) => (
          <div key={i} style={{ width: 390, flexShrink: 0 }}>{s}</div>
        ))}
      </div>
    </div>
  );
};

// ─── Static snapshots ────────────────────────────────────────────
const StaticWelcome = () => <WelcomeScreen onNext={() => {}} onSignIn={() => {}} />;
const StaticAwareness = () => <AwarenessScreen onNext={() => {}} onBack={() => {}} />;
const StaticStructure = () => <StructureScreen onNext={() => {}} onBack={() => {}} />;
const StaticVideoDemo = () => <VideoDemoScreen onNext={() => {}} onBack={() => {}} />;
const StaticTransformation = () => <TransformationScreen onNext={() => {}} onBack={() => {}} />;
const StaticHeardAbout = () => <HeardAboutScreen onNext={() => {}} onBack={() => {}} source="tiktok" setSource={() => {}} />;
const StaticTriedApps = () => <TriedAppsScreen onNext={() => {}} onBack={() => {}} tried="multi" setTried={() => {}} />;
const StaticBaseline = () => <BaselineScreen onNext={() => {}} onBack={() => {}} goal="cut" setGoal={() => {}} />;
const StaticDailyStructure = () => <DailyStructureScreen onNext={() => {}} onBack={() => {}} mealCount={3} setMealCount={() => {}} />;
const StaticMealTiming = () => <MealTimingScreen onNext={() => {}} onBack={() => {}} timing="fixed" setTiming={() => {}} />;
const StaticRemindersOB = () => <RemindersOBScreen onNext={() => {}} onBack={() => {}} reminders={['pre', 'at']} setReminders={() => {}} />;
const StaticSignUp = () => <SignUpScreen onNext={() => {}} onBack={() => {}} />;
const StaticVerify = () => <VerifyScreen onNext={() => {}} onBack={() => {}} email="you@example.com" />;

Object.assign(window, {
  OnboardingFlow,
  StaticWelcome, StaticAwareness, StaticStructure, StaticVideoDemo,
  StaticTransformation, StaticHeardAbout, StaticTriedApps,
  StaticBaseline, StaticDailyStructure, StaticMealTiming,
  StaticRemindersOB, StaticSignUp, StaticVerify,
});
