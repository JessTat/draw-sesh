import React, { useMemo, useState, useEffect } from 'react';

type ImageItem = {
  id: string;
  name: string;
  src: string;
  omitted: boolean;
  drawnCount: number;
};

type Screen = 'setup' | 'session' | 'summary';

type SessionState = {
  status: 'running' | 'paused';
  sequence: string[];
  index: number;
  remainingSec: number;
  completed: number;
  skipped: number;
  target: number | 'infinite';
  minutesPerImage: number;
};

const DEFAULT_FOLDER = '/Users/jess/Projects/26-01 Figure Drawing/Gestures';

const COLORS = [
  ['#ffedd5', '#fb7185'],
  ['#dcfce7', '#14b8a6'],
  ['#e0f2fe', '#f97316'],
  ['#fef3c7', '#6366f1'],
  ['#ffe4e6', '#0ea5e9'],
  ['#ecfccb', '#f43f5e'],
  ['#f1f5f9', '#22c55e'],
  ['#fae8ff', '#e11d48'],
  ['#fffbeb', '#0f766e'],
  ['#fef2f2', '#9333ea'],
  ['#ecfeff', '#f59e0b'],
  ['#f5f3ff', '#16a34a']
];

function makePlaceholder(label: string, colorA: string, colorB: string) {
  const svg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="900" height="1200" viewBox="0 0 900 1200">
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="${colorA}"/>
      <stop offset="100%" stop-color="${colorB}"/>
    </linearGradient>
  </defs>
  <rect width="900" height="1200" rx="48" fill="url(#g)"/>
  <rect x="70" y="80" width="760" height="1040" rx="36" fill="rgba(255,255,255,0.14)" stroke="rgba(0,0,0,0.08)"/>
  <text x="80" y="170" font-family="Avenir Next, Avenir, Futura, sans-serif" font-size="48" fill="rgba(0,0,0,0.6)">${label}</text>
  <text x="80" y="240" font-family="Avenir Next, Avenir, Futura, sans-serif" font-size="20" fill="rgba(0,0,0,0.55)">Gesture Reference</text>
</svg>`;
  return `data:image/svg+xml;utf8,${encodeURIComponent(svg)}`;
}

const initialImages: ImageItem[] = Array.from({ length: 12 }).map((_, index) => {
  const [colorA, colorB] = COLORS[index % COLORS.length];
  const name = `Pose ${String(index + 1).padStart(2, '0')}`;
  return {
    id: `img-${index + 1}`,
    name,
    src: makePlaceholder(name, colorA, colorB),
    omitted: false,
    drawnCount: Math.floor(Math.random() * 8)
  };
});

function formatTime(totalSec: number) {
  const minutes = Math.floor(totalSec / 60);
  const seconds = totalSec % 60;
  return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
}

function pickRandomId(ids: string[]) {
  if (!ids.length) return '';
  const idx = Math.floor(Math.random() * ids.length);
  return ids[idx];
}

function buildSequence(ids: string[], target: number) {
  const shuffled = [...ids].sort(() => Math.random() - 0.5);
  if (target <= ids.length) return shuffled.slice(0, target);
  const sequence = [...shuffled];
  while (sequence.length < target) {
    sequence.push(pickRandomId(ids));
  }
  return sequence;
}

export default function App() {
  const [screen, setScreen] = useState<Screen>('setup');
  const [folderPath, setFolderPath] = useState<string>(DEFAULT_FOLDER);
  const [images, setImages] = useState<ImageItem[]>(initialImages);
  const [minutes, setMinutes] = useState<number>(3);
  const [count, setCount] = useState<number>(8);
  const [infinite, setInfinite] = useState<boolean>(false);
  const [session, setSession] = useState<SessionState | null>(null);

  const availableImages = useMemo(() => images.filter((img) => !img.omitted), [images]);
  const availableIds = useMemo(() => availableImages.map((img) => img.id), [availableImages]);
  const totalOmitted = images.filter((img) => img.omitted).length;

  const activeImage = useMemo(() => {
    if (!session) return null;
    return images.find((img) => img.id === session.sequence[session.index]) ?? null;
  }, [images, session]);

  useEffect(() => {
    if (!session || session.status !== 'running') return;
    const timer = window.setInterval(() => {
      setSession((prev) => {
        if (!prev || prev.status !== 'running') return prev;
        if (prev.remainingSec > 1) {
          return { ...prev, remainingSec: prev.remainingSec - 1 };
        }
        return advanceSession(prev, true);
      });
    }, 1000);
    return () => window.clearInterval(timer);
  }, [session?.status]);

  function toggleOmit(id: string) {
    setImages((prev) =>
      prev.map((img) => (img.id === id ? { ...img, omitted: !img.omitted } : img))
    );
  }

  function adjustCount(newCount: number) {
    const clamped = Math.min(20, Math.max(2, newCount));
    setCount(clamped);
  }

  function startSession() {
    if (!availableIds.length) return;
    const target = infinite ? 'infinite' : count;
    const sequence = infinite
      ? [pickRandomId(availableIds)]
      : buildSequence(availableIds, count);

    setSession({
      status: 'running',
      sequence,
      index: 0,
      remainingSec: minutes * 60,
      completed: 0,
      skipped: 0,
      target,
      minutesPerImage: minutes
    });
    setScreen('session');
  }

  function advanceSession(prev: SessionState, countCurrent: boolean) {
    const currentId = prev.sequence[prev.index];
    const completed = countCurrent ? prev.completed + 1 : prev.completed;
    if (countCurrent) {
      setImages((items) =>
        items.map((img) =>
          img.id === currentId ? { ...img, drawnCount: img.drawnCount + 1 } : img
        )
      );
    }

    const reachedTarget = prev.target !== 'infinite' && completed >= prev.target;
    if (reachedTarget) {
      setScreen('summary');
      return { ...prev, completed, status: 'paused', remainingSec: 0 };
    }

    let nextIndex = prev.index + 1;
    let nextSequence = prev.sequence;

    if (nextIndex >= nextSequence.length) {
      const nextId = pickRandomId(availableIds);
      nextSequence = [...prev.sequence, nextId];
    }

    return {
      ...prev,
      sequence: nextSequence,
      index: nextIndex,
      remainingSec: prev.minutesPerImage * 60,
      completed,
      skipped: countCurrent ? prev.skipped : prev.skipped + 1
    };
  }

  function handleNext() {
    setSession((prev) => (prev ? advanceSession(prev, true) : prev));
  }

  function handleSkip() {
    setSession((prev) => (prev ? advanceSession(prev, false) : prev));
  }

  function handlePrev() {
    setSession((prev) => {
      if (!prev || prev.index === 0) return prev;
      return { ...prev, index: prev.index - 1, remainingSec: prev.minutesPerImage * 60 };
    });
  }

  function togglePause() {
    setSession((prev) => {
      if (!prev) return prev;
      return { ...prev, status: prev.status === 'running' ? 'paused' : 'running' };
    });
  }

  function stopSession() {
    setScreen('summary');
    setSession((prev) => (prev ? { ...prev, status: 'paused' } : prev));
  }

  function resetToSetup() {
    setScreen('setup');
    setSession(null);
  }

  return (
    <div className="app">
      <header className="topbar">
        <div className="brand">
          <div className="brand-mark">GD</div>
          <div>
            <div className="brand-title">Gesture Draw</div>
            <div className="brand-sub">Timed figure drawing sessions</div>
          </div>
        </div>
        <div className="topbar-actions">
          <button className="ghost" onClick={() => setScreen('setup')}>
            Setup
          </button>
          <button className="ghost" onClick={() => setScreen('session')} disabled={!session}>
            Session
          </button>
          <button className="ghost" onClick={() => setScreen('summary')} disabled={!session}>
            Summary
          </button>
        </div>
      </header>

      {screen === 'setup' && (
        <main className="layout">
          <section className="panel hero">
            <div className="panel-header">
              <h2>Source Library</h2>
              <span className="chip">{availableImages.length} active</span>
            </div>
            <div className="folder-row">
              <div className="input-wrap">
                <label>Folder</label>
                <input
                  type="text"
                  value={folderPath}
                  onChange={(e) => setFolderPath(e.target.value)}
                />
              </div>
              <button className="primary">Choose Folder</button>
            </div>
            <div className="stats">
              <div>
                <div className="stat-number">{images.length}</div>
                <div className="stat-label">Total Images</div>
              </div>
              <div>
                <div className="stat-number">{availableImages.length}</div>
                <div className="stat-label">Included</div>
              </div>
              <div>
                <div className="stat-number">{totalOmitted}</div>
                <div className="stat-label">Omitted</div>
              </div>
            </div>
            <div className="grid">
              {images.map((img) => (
                <div key={img.id} className={`thumb ${img.omitted ? 'omitted' : ''}`}>
                  <img src={img.src} alt={img.name} />
                  <div className="thumb-meta">
                    <div>
                      <div className="thumb-title">{img.name}</div>
                      <div className="thumb-sub">Drawn {img.drawnCount}x</div>
                    </div>
                    <button className="toggle" onClick={() => toggleOmit(img.id)}>
                      {img.omitted ? 'Include' : 'Omit'}
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </section>

          <aside className="panel settings">
            <div className="panel-header">
              <h2>Session Settings</h2>
              <span className="chip">Preview</span>
            </div>

            <div className="setting-block">
              <label>Time Per Image</label>
              <div className="slider-row">
                <input
                  type="range"
                  min={1}
                  max={15}
                  value={minutes}
                  onChange={(e) => setMinutes(Number(e.target.value))}
                />
                <span className="value">{minutes} min</span>
              </div>
            </div>

            <div className="setting-block">
              <label>Images Per Session</label>
              <div className="stepper">
                <button onClick={() => adjustCount(count - 1)}>-</button>
                <span>{count}</span>
                <button onClick={() => adjustCount(count + 1)}>+</button>
              </div>
              <label className="toggle-row">
                <input
                  type="checkbox"
                  checked={infinite}
                  onChange={(e) => setInfinite(e.target.checked)}
                />
                Infinite until I stop
              </label>
            </div>

            <div className="setting-block">
              <label>Session Preview</label>
              <div className="preview-card">
                <div>Active images: {availableImages.length}</div>
                <div>Target: {infinite ? 'Infinite' : `${count} images`}</div>
                <div>Timer: {minutes} min each</div>
              </div>
            </div>

            <button className="primary full" onClick={startSession}>
              Start Session
            </button>
          </aside>
        </main>
      )}

      {screen === 'session' && session && activeImage && (
        <main className="session">
          <div className="session-left">
            <div className="session-frame">
              <img src={activeImage.src} alt={activeImage.name} />
            </div>
          </div>
          <div className="session-right">
            <div className="timer-block">
              <div className="timer-label">Time Remaining</div>
              <div className="timer-value">{formatTime(session.remainingSec)}</div>
              <div className="timer-sub">{activeImage.name}</div>
            </div>

            <div className="session-progress">
              <div>
                <div className="stat-number">{session.completed}</div>
                <div className="stat-label">Completed</div>
              </div>
              <div>
                <div className="stat-number">{session.skipped}</div>
                <div className="stat-label">Skipped</div>
              </div>
              <div>
                <div className="stat-number">{session.target === 'infinite' ? '∞' : session.target}</div>
                <div className="stat-label">Target</div>
              </div>
            </div>

            <div className="controls">
              <button className="ghost" onClick={handlePrev}>
                Previous
              </button>
              <button className="primary" onClick={togglePause}>
                {session.status === 'running' ? 'Pause' : 'Resume'}
              </button>
              <button className="ghost" onClick={handleNext}>
                Next
              </button>
            </div>

            <div className="controls secondary">
              <button className="ghost" onClick={handleSkip}>
                Skip (no count)
              </button>
              <button className="danger" onClick={stopSession}>
                Stop Session
              </button>
            </div>
          </div>
        </main>
      )}

      {screen === 'session' && !session && (
        <main className="summary">
          <section className="panel summary-card">
            <h2>No Active Session</h2>
            <p>Configure your session settings and start when ready.</p>
            <button className="primary" onClick={() => setScreen('setup')}>
              Go to Setup
            </button>
          </section>
        </main>
      )}

      {screen === 'summary' && (
        <main className="summary">
          <section className="panel summary-card">
            <h2>Session Summary</h2>
            <p>Nice work. Review your totals and adjust your next session.</p>
            <div className="summary-grid">
              <div>
                <div className="stat-number">{session?.completed ?? 0}</div>
                <div className="stat-label">Completed Drawings</div>
              </div>
              <div>
                <div className="stat-number">{session?.skipped ?? 0}</div>
                <div className="stat-label">Skipped</div>
              </div>
              <div>
                <div className="stat-number">{minutes} min</div>
                <div className="stat-label">Per Image</div>
              </div>
            </div>
            <div className="summary-actions">
              <button className="ghost" onClick={resetToSetup}>
                Back to Setup
              </button>
              <button className="primary" onClick={startSession}>
                Start Another Session
              </button>
            </div>
          </section>
        </main>
      )}
    </div>
  );
}
