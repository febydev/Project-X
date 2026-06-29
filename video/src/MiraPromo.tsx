import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
  Sequence,
  Audio,
  staticFile,
  Easing,
} from "remotion";
import { loadFont } from "@remotion/google-fonts/PlusJakartaSans";

const { fontFamily } = loadFont();

// ---- Mira palette (matches the app) ----
const C = {
  sand: "#F6F3EE",
  surface: "#FFFFFF",
  sage: "#4E6E5D",
  sageDark: "#3C5749",
  sageContainer: "#DDE7E0",
  apricot: "#E5A878",
  apricotSoft: "#F6E6D7",
  gold: "#D9A95C",
  ink: "#2A2E2B",
  inkSoft: "#727A74",
  feed: "#E0A26B",
  feedSoft: "#F7E7D6",
  sleep: "#7C8DB5",
  sleepSoft: "#E2E7F1",
  diaper: "#6FB0A6",
  diaperSoft: "#DDEDEA",
  night1: "#0E1411",
  night2: "#1A2420",
};

const F = (s: React.CSSProperties = {}): React.CSSProperties => ({
  fontFamily,
  color: C.ink,
  ...s,
});

// ---------- timing helpers ----------
const useRise = (delay: number, distance = 40, damping = 200) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame: frame - delay, fps, config: { damping } });
  return {
    opacity: interpolate(s, [0, 1], [0, 1]),
    transform: `translateY(${interpolate(s, [0, 1], [distance, 0])}px)`,
  };
};

const usePop = (delay: number, from = 0.6) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame: frame - delay, fps, config: { damping: 12, mass: 0.7 } });
  return { transform: `scale(${interpolate(s, [0, 1], [from, 1])})`, opacity: Math.min(1, s * 1.6) };
};

const fadeAt = (frame: number, inAt: number, dur = 10) =>
  interpolate(frame, [inAt, inAt + dur], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

// ---------- primitives ----------
const Leaf: React.FC<{ size: number }> = ({ size }) => (
  <div
    style={{
      width: size,
      height: size,
      borderRadius: size * 0.3,
      background: `linear-gradient(135deg, ${C.sage}, ${C.sageDark})`,
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      boxShadow: "0 24px 60px rgba(60,87,73,0.4)",
    }}
  >
    <svg width={size * 0.5} height={size * 0.5} viewBox="0 0 24 24" fill="white">
      <path d="M12 2C7 4 4 8 4 13a8 8 0 0 0 16 0c0-5-3-9-8-11Zm0 4c2.5 1.5 4 4 4 7a4 4 0 0 1-8 0c0-3 1.5-5.5 4-7Z" />
    </svg>
  </div>
);

const Card: React.FC<{ children: React.ReactNode; style?: React.CSSProperties }> = ({
  children,
  style,
}) => (
  <div
    style={{
      background: C.surface,
      borderRadius: 30,
      padding: 24,
      boxShadow: "0 16px 36px rgba(0,0,0,0.08)",
      ...style,
    }}
  >
    {children}
  </div>
);

const Dot: React.FC<{ c: string; soft: string; label: string }> = ({ c, soft, label }) => (
  <Card style={{ flex: 1, textAlign: "center", padding: 18 }}>
    <div
      style={{
        width: 64,
        height: 64,
        borderRadius: 40,
        background: soft,
        margin: "0 auto 10px",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <div style={{ width: 24, height: 24, borderRadius: 12, background: c }} />
    </div>
    <div style={F({ fontSize: 24, fontWeight: 700 })}>{label}</div>
  </Card>
);

// The app's home screen, reused in mockups
const AppHome: React.FC<{ highlightFeed?: number }> = ({ highlightFeed = 0 }) => (
  <div style={{ padding: 28, height: "100%", background: C.sand }}>
    <div style={F({ color: C.inkSoft, fontSize: 24, marginTop: 24 })}>Good evening</div>
    <div style={F({ fontSize: 44, fontWeight: 800 })}>How is Mia?</div>
    <div
      style={{
        marginTop: 22,
        borderRadius: 32,
        padding: 30,
        background: `linear-gradient(135deg, ${C.sage}, ${C.sageDark})`,
      }}
    >
      <div style={F({ color: "rgba(255,255,255,0.85)", fontSize: 24 })}>Right now</div>
      <div style={F({ color: "white", fontSize: 54, fontWeight: 800, marginTop: 8 })}>
        Awake 2h 10m
      </div>
    </div>
    <div style={{ display: "flex", gap: 14, marginTop: 20 }}>
      <div style={{ flex: 1, transform: `scale(${1 + highlightFeed * 0.06})` }}>
        <Dot c={C.feed} soft={C.feedSoft} label="Feed" />
      </div>
      <Dot c={C.sleep} soft={C.sleepSoft} label="Sleep" />
      <Dot c={C.diaper} soft={C.diaperSoft} label="Diaper" />
    </div>
  </div>
);

const PhoneShell: React.FC<{ children: React.ReactNode; style?: React.CSSProperties }> = ({
  children,
  style,
}) => (
  <div
    style={{
      width: 600,
      height: 1240,
      borderRadius: 68,
      background: C.sand,
      border: "14px solid #11140F",
      overflow: "hidden",
      boxShadow: "0 50px 130px rgba(0,0,0,0.5)",
      ...style,
    }}
  >
    {children}
  </div>
);

// ===================== SCENE 1 — HOOK =====================
const Hook: React.FC = () => {
  const frame = useCurrentFrame();
  const typed = "why won't my baby sleep?";
  const chars = Math.floor(interpolate(frame, [18, 150], [0, typed.length], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  }));
  const cryPulse = Math.max(0, Math.sin((frame - 60) / 4)) * fadeAt(frame, 60, 6) * (frame < 90 ? 1 : 0);
  const dim = interpolate(frame, [165, 185], [1, 0.25], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const better = useRise(190);
  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(circle at 50% 38%, ${C.night2}, ${C.night1})`,
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <AbsoluteFill style={{ boxShadow: "inset 0 0 400px rgba(0,0,0,0.8)", opacity: 1 }} />
      <div style={{ opacity: dim, alignItems: "center", display: "flex", flexDirection: "column" }}>
        <div style={F({ color: "rgba(255,255,255,0.5)", fontSize: 30, marginBottom: 28 })}>3:00 AM</div>
        <div
          style={{
            width: 760,
            background: "rgba(255,255,255,0.06)",
            border: "1px solid rgba(255,255,255,0.12)",
            borderRadius: 24,
            padding: "28px 32px",
            display: "flex",
            alignItems: "center",
            gap: 16,
            boxShadow: `0 0 ${40 + cryPulse * 40}px rgba(224,120,120,${0.1 + cryPulse * 0.3})`,
          }}
        >
          <svg width={34} height={34} viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.5)" strokeWidth={2}>
            <circle cx="11" cy="11" r="7" />
            <path d="M21 21l-4.3-4.3" />
          </svg>
          <div style={F({ color: "white", fontSize: 38 })}>
            {typed.slice(0, chars)}
            <span style={{ opacity: frame % 30 < 15 ? 1 : 0 }}>|</span>
          </div>
        </div>
      </div>
      <div style={{ position: "absolute", ...better }}>
        <div style={F({ color: "white", fontSize: 62, fontWeight: 800, textAlign: "center" })}>
          There has to be
        </div>
        <div style={F({ color: C.apricot, fontSize: 62, fontWeight: 800, textAlign: "center" })}>
          a better way.
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ===================== SCENE 2 — LOGO =====================
const LogoScene: React.FC = () => {
  const leaf = usePop(5, 0.4);
  const word = useRise(14, 30);
  const tag = useRise(52, 24);
  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(160deg, ${C.sage}, ${C.sageDark})`,
        alignItems: "center",
        justifyContent: "center",
        gap: 36,
      }}
    >
      <div style={leaf}>
        <Leaf size={230} />
      </div>
      <div style={{ ...word, textAlign: "center" }}>
        <div style={F({ color: "white", fontSize: 120, fontWeight: 800 })}>Mira</div>
      </div>
      <div style={{ ...tag, textAlign: "center", maxWidth: 760 }}>
        <div style={F({ color: "rgba(255,255,255,0.9)", fontSize: 42, lineHeight: 1.3 })}>
          The calm companion that actually knows your baby.
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ===================== SCENE 3 — TRACKER =====================
const Tracker: React.FC = () => {
  const frame = useCurrentFrame();
  const rise = spring({ frame, fps: 30, config: { damping: 200 } });
  const ty = interpolate(rise, [0, 1], [400, 0]);
  // push-in to the tap, then zoom out on "at a glance"
  const scale = interpolate(frame, [0, 83, 110, 150], [0.95, 1.06, 1.06, 0.82], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.inOut(Easing.ease),
  });
  const tap = frame >= 83 && frame <= 95 ? 1 : 0;
  const ripple = interpolate(frame, [83, 105], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const freePop = usePop(202, 0.3);
  const title = useRise(4, 24);
  return (
    <AbsoluteFill style={{ background: C.sand, alignItems: "center", justifyContent: "center" }}>
      <div style={{ position: "absolute", top: 120, ...title }}>
        <div style={F({ fontSize: 46, fontWeight: 800, textAlign: "center" })}>
          Log the day in one tap
        </div>
      </div>
      <div style={{ transform: `translateY(${ty}px) scale(${scale})` }}>
        <PhoneShell>
          <AppHome highlightFeed={tap} />
        </PhoneShell>
        {ripple > 0 && ripple < 1 && (
          <div
            style={{
              position: "absolute",
              left: 150,
              top: 880,
              width: 120 * ripple,
              height: 120 * ripple,
              borderRadius: 999,
              border: `3px solid ${C.feed}`,
              opacity: 1 - ripple,
              transform: "translate(-50%,-50%)",
            }}
          />
        )}
      </div>
      <div style={{ position: "absolute", ...freePop }}>
        <div
          style={{
            background: `linear-gradient(135deg, ${C.apricot}, #d98f57)`,
            color: "white",
            fontFamily,
            fontSize: 90,
            fontWeight: 800,
            padding: "18px 60px",
            borderRadius: 999,
            transform: "rotate(-8deg)",
            boxShadow: "0 24px 50px rgba(0,0,0,0.25)",
          }}
        >
          FREE
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ===================== SCENE 4 — AI KNOWS YOUR BABY =====================
const Hl: React.FC<{ children: React.ReactNode; on: number }> = ({ children, on }) => (
  <span
    style={{
      background: `rgba(229,168,120,${0.55 * on})`,
      borderRadius: 8,
      padding: "2px 6px",
      boxDecorationBreak: "clone",
    }}
  >
    {children}
  </span>
);

const AiScene: React.FC = () => {
  const frame = useCurrentFrame();
  const title = useRise(4, 20);
  const logsIn = interpolate(frame, [75, 110], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const userPop = usePop(119, 0.6);
  const miraReveal = usePop(196, 0.7);
  const hl1 = fadeAt(frame, 205, 10);
  const hl2 = fadeAt(frame, 270, 10);
  // hard zoom onto the bubble
  const zoom = interpolate(frame, [196, 206, 250, 268], [1, 1.18, 1.18, 1.0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.inOut(Easing.ease),
  });
  const notTextbook = useRise(330, 24);
  return (
    <AbsoluteFill style={{ background: C.sand, alignItems: "center", justifyContent: "flex-start" }}>
      <div style={{ position: "absolute", top: 110, ...title, textAlign: "center", width: "100%" }}>
        <div style={F({ fontSize: 46, fontWeight: 800 })}>More than a tracker.</div>
        <div style={F({ fontSize: 46, fontWeight: 800, color: C.sage })}>She reads your logs.</div>
      </div>

      {/* log chips flying into the avatar */}
      <div style={{ position: "absolute", top: 340, display: "flex", gap: 16, opacity: 1 - logsIn }}>
        {["Feed 2h ago", "1 nap today", "3 diapers"].map((t, i) => (
          <div
            key={t}
            style={{
              transform: `translateY(${(1 - logsIn) * (40 + i * 20)}px)`,
              background: "white",
              borderRadius: 18,
              padding: "12px 18px",
              fontFamily,
              fontSize: 24,
              color: C.inkSoft,
              boxShadow: "0 8px 20px rgba(0,0,0,0.06)",
            }}
          >
            {t}
          </div>
        ))}
      </div>

      <div
        style={{
          marginTop: 470,
          width: 820,
          display: "flex",
          flexDirection: "column",
          gap: 22,
          transform: `scale(${zoom})`,
          transformOrigin: "center 60%",
        }}
      >
        <div
          style={{
            ...userPop,
            alignSelf: "flex-end",
            maxWidth: "78%",
            background: `linear-gradient(135deg, ${C.sage}, ${C.sageDark})`,
            color: "white",
            padding: "22px 26px",
            borderRadius: 30,
            borderBottomRightRadius: 8,
            fontFamily,
            fontSize: 30,
          }}
        >
          Why won't she nap? I'm done.
        </div>
        <div
          style={{
            ...miraReveal,
            alignSelf: "flex-start",
            maxWidth: "88%",
            background: "white",
            color: C.ink,
            padding: "24px 28px",
            borderRadius: 30,
            borderBottomLeftRadius: 8,
            fontFamily,
            fontSize: 30,
            lineHeight: 1.45,
            boxShadow: "0 14px 30px rgba(0,0,0,0.08)",
          }}
        >
          That sounds exhausting. <Hl on={hl1}>Mia napped once today</Hl> and last fed{" "}
          <Hl on={hl2}>2 hours ago</Hl> — she's likely overtired. Try winding down now.
        </div>
      </div>

      <div style={{ position: "absolute", bottom: 150, ...notTextbook, textAlign: "center", width: "100%" }}>
        <div style={F({ fontSize: 40, fontWeight: 700 })}>
          Real answers for <span style={{ color: C.sage }}>your</span> baby.
        </div>
        <div style={F({ fontSize: 30, color: C.inkSoft, textDecoration: "line-through" })}>
          not a textbook
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ===================== SCENE 5 — PREMIUM =====================
const Premium: React.FC = () => {
  const frame = useCurrentFrame();
  const clamp = { extrapolateLeft: "clamp" as const, extrapolateRight: "clamp" as const };

  const aOp = interpolate(frame, [0, 10, 100, 115], [0, 1, 1, 0], clamp);
  const bOp = interpolate(frame, [110, 125, 210, 225], [0, 1, 1, 0], clamp);
  const cOp = interpolate(frame, [220, 235], [0, 1], clamp);

  const breathe = 0.8 + 0.2 * Math.sin((frame - 110) / 16);
  const pdfRise = interpolate(frame, [225, 250], [120, 0], clamp);
  const stamp = spring({ frame: frame - 287, fps: 30, config: { damping: 11 } });

  const pill = (
    <div
      style={{
        background: `linear-gradient(135deg, ${C.gold}, #c2913f)`,
        color: "white",
        fontFamily,
        fontWeight: 800,
        fontSize: 30,
        letterSpacing: 3,
        padding: "10px 26px",
        borderRadius: 999,
      }}
    >
      PREMIUM
    </div>
  );

  return (
    <AbsoluteFill style={{ background: `linear-gradient(160deg, #2c4035, ${C.sageDark})`, alignItems: "center", justifyContent: "center" }}>
      {/* A — advisor */}
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", gap: 34, opacity: aOp }}>
        {pill}
        <div style={F({ color: "white", fontSize: 60, fontWeight: 800, textAlign: "center", maxWidth: 800 })}>
          Your full parenting advisor
        </div>
        <Card style={{ width: 760, marginTop: 10 }}>
          <div style={F({ fontSize: 30, lineHeight: 1.4 })}>
            "Try a calmer bedtime routine tonight — a warm bath, dim lights, and the same three songs."
          </div>
        </Card>
      </AbsoluteFill>

      {/* B — calm mode */}
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", gap: 60, opacity: bOp }}>
        <div
          style={{
            width: 380,
            height: 380,
            borderRadius: 999,
            background: "rgba(255,255,255,0.10)",
            border: "2px solid rgba(255,255,255,0.25)",
            transform: `scale(${breathe})`,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <div style={F({ color: "white", fontSize: 40 })}>Breathe</div>
        </div>
        <div style={F({ color: "white", fontSize: 54, fontWeight: 800, textAlign: "center" })}>
          Calm Mode for the hard moments
        </div>
      </AbsoluteFill>

      {/* C — reports */}
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", opacity: cOp }}>
        <div style={{ transform: `translateY(${pdfRise}px)`, position: "relative" }}>
          <Card style={{ width: 620, padding: 36 }}>
            <div style={F({ fontSize: 34, fontWeight: 800 })}>Care Summary</div>
            <div style={F({ fontSize: 22, color: C.inkSoft, marginBottom: 20 })}>Mia · last 7 days</div>
            {[0.9, 0.75, 0.85, 0.6, 0.8].map((w, i) => (
              <div key={i} style={{ height: 18, width: `${w * 100}%`, background: C.sageContainer, borderRadius: 8, marginBottom: 16 }} />
            ))}
          </Card>
          <div
            style={{
              position: "absolute",
              right: -30,
              bottom: -30,
              transform: `scale(${interpolate(stamp, [0, 1], [0, 1])}) rotate(-10deg)`,
              background: C.sage,
              color: "white",
              borderRadius: 999,
              padding: "16px 28px",
              fontFamily,
              fontWeight: 800,
              fontSize: 28,
              boxShadow: "0 16px 30px rgba(0,0,0,0.3)",
            }}
          >
            Pediatrician-ready
          </div>
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

// ===================== SCENE 6 — PRIVACY =====================
const Privacy: React.FC = () => {
  const lock = usePop(2, 0.5);
  const l1 = useRise(3, 20);
  const l2 = useRise(45, 20);
  return (
    <AbsoluteFill style={{ background: C.sand, alignItems: "center", justifyContent: "center", gap: 30 }}>
      <div style={lock}>
        <div
          style={{
            width: 150,
            height: 150,
            borderRadius: 44,
            background: C.sageContainer,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <svg width={70} height={70} viewBox="0 0 24 24" fill="none" stroke={C.sageDark} strokeWidth={2}>
            <rect x="4" y="11" width="16" height="9" rx="2" />
            <path d="M8 11V8a4 4 0 0 1 8 0v3" />
          </svg>
        </div>
      </div>
      <div style={{ ...l1 }}>
        <div style={F({ fontSize: 60, fontWeight: 800 })}>Everything private.</div>
      </div>
      <div style={{ ...l2 }}>
        <div style={F({ fontSize: 40, color: C.inkSoft })}>Everything on your phone.</div>
      </div>
    </AbsoluteFill>
  );
};

// ===================== SCENE 7 — CTA =====================
const CTA: React.FC = () => {
  const frame = useCurrentFrame();
  const leaf = usePop(8, 0.4);
  const word = useRise(16, 26);
  const tag = useRise(51, 22);
  const pulse = 1 + 0.04 * Math.sin(frame / 8);
  return (
    <AbsoluteFill style={{ background: `linear-gradient(160deg, ${C.sage}, ${C.sageDark})`, alignItems: "center", justifyContent: "center", gap: 34 }}>
      <div style={leaf}>
        <Leaf size={170} />
      </div>
      <div style={{ ...word, textAlign: "center" }}>
        <div style={F({ color: "white", fontSize: 110, fontWeight: 800 })}>Mira</div>
        <div style={F({ color: "rgba(255,255,255,0.9)", fontSize: 40, marginTop: 6 })}>
          Parenting, a little lighter.
        </div>
      </div>
      <div style={{ ...tag, transform: `${tag.transform} scale(${pulse})` }}>
        <div
          style={{
            background: "white",
            color: C.sageDark,
            fontFamily,
            fontWeight: 800,
            fontSize: 36,
            padding: "20px 54px",
            borderRadius: 999,
            boxShadow: "0 20px 40px rgba(0,0,0,0.25)",
          }}
        >
          Download Mira
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ===================== ROOT =====================
const Scene: React.FC<{ from: number; dur: number; children: React.ReactNode }> = ({ from, dur, children }) => (
  <Sequence from={from} durationInFrames={dur}>
    <AbsoluteFill style={{ opacity: 1 }}>{children}</AbsoluteFill>
  </Sequence>
);

export const MiraPromo: React.FC = () => {
  return (
    <AbsoluteFill style={{ backgroundColor: C.sand }}>
      <Audio src={staticFile("vo.mp3")} />
      <Audio
        src={staticFile("music.mp3")}
        volume={(f) =>
          interpolate(f, [0, 24, 1540, 1620], [0, 0.16, 0.16, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          })
        }
      />

      <Scene from={0} dur={243}>
        <Hook />
      </Scene>
      <Scene from={243} dur={138}>
        <LogoScene />
      </Scene>
      <Scene from={381} dur={232}>
        <Tracker />
      </Scene>
      <Scene from={613} dur={425}>
        <AiScene />
      </Scene>
      <Scene from={1038} dur={360}>
        <Premium />
      </Scene>
      <Scene from={1398} dur={98}>
        <Privacy />
      </Scene>
      <Scene from={1496} dur={124}>
        <CTA />
      </Scene>
    </AbsoluteFill>
  );
};
