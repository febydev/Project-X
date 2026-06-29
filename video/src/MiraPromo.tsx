import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
  Sequence,
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
  ink: "#2A2E2B",
  inkSoft: "#727A74",
  feed: "#E0A26B",
  feedSoft: "#F7E7D6",
  sleep: "#7C8DB5",
  sleepSoft: "#E2E7F1",
  diaper: "#6FB0A6",
  diaperSoft: "#DDEDEA",
};

const font: React.CSSProperties = { fontFamily, color: C.ink };

// Soft fade+rise helper
const useReveal = (delay: number) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame: frame - delay, fps, config: { damping: 200 } });
  return {
    opacity: interpolate(s, [0, 1], [0, 1]),
    transform: `translateY(${interpolate(s, [0, 1], [30, 0])}px)`,
  };
};

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
      boxShadow: "0 20px 50px rgba(60,87,73,0.35)",
    }}
  >
    <svg width={size * 0.5} height={size * 0.5} viewBox="0 0 24 24" fill="white">
      <path d="M12 2C7 4 4 8 4 13a8 8 0 0 0 16 0c0-5-3-9-8-11Zm0 4c2.5 1.5 4 4 4 7a4 4 0 0 1-8 0c0-3 1.5-5.5 4-7Z" />
    </svg>
  </div>
);

const PhoneFrame: React.FC<{ children: React.ReactNode; scale?: number }> = ({
  children,
  scale = 1,
}) => (
  <div
    style={{
      width: 620,
      height: 1300,
      borderRadius: 70,
      background: C.sand,
      border: "14px solid #11140F",
      overflow: "hidden",
      boxShadow: "0 40px 120px rgba(0,0,0,0.45)",
      transform: `scale(${scale})`,
    }}
  >
    {children}
  </div>
);

const Card: React.FC<{
  children: React.ReactNode;
  style?: React.CSSProperties;
}> = ({ children, style }) => (
  <div
    style={{
      background: C.surface,
      borderRadius: 30,
      padding: 26,
      boxShadow: "0 12px 30px rgba(0,0,0,0.06)",
      ...style,
    }}
  >
    {children}
  </div>
);

// ---- Scene 1: Logo reveal ----
const SceneLogo: React.FC = () => {
  const a = useReveal(6);
  const b = useReveal(20);
  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(160deg, ${C.sage}, ${C.sageDark})`,
        alignItems: "center",
        justifyContent: "center",
        gap: 40,
      }}
    >
      <div style={a}>
        <Leaf size={220} />
      </div>
      <div style={{ ...b, textAlign: "center" }}>
        <div style={{ ...font, color: "white", fontSize: 110, fontWeight: 800 }}>
          Mira
        </div>
        <div
          style={{
            ...font,
            color: "rgba(255,255,255,0.85)",
            fontSize: 40,
            marginTop: 10,
          }}
        >
          your calm companion
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ---- Scene 2: Statement ----
const SceneStatement: React.FC = () => {
  const a = useReveal(4);
  const b = useReveal(22);
  return (
    <AbsoluteFill
      style={{
        background: C.sand,
        alignItems: "center",
        justifyContent: "center",
        padding: 120,
      }}
    >
      <div style={{ ...a, ...font, fontSize: 72, fontWeight: 800, lineHeight: 1.1, textAlign: "center" }}>
        Parenting is beautiful.
      </div>
      <div
        style={{
          ...b,
          ...font,
          color: C.apricot,
          fontSize: 72,
          fontWeight: 800,
          textAlign: "center",
          marginTop: 14,
        }}
      >
        And exhausting.
      </div>
    </AbsoluteFill>
  );
};

// ---- Scene 3: The tracker (phone mockup + zoom) ----
const SceneTracker: React.FC = () => {
  const frame = useCurrentFrame();
  const scale = interpolate(frame, [0, 150], [0.92, 1.04], {
    extrapolateRight: "clamp",
    easing: Easing.inOut(Easing.ease),
  });
  const reveal = useReveal(6);
  return (
    <AbsoluteFill
      style={{ background: C.sand, alignItems: "center", justifyContent: "center" }}
    >
      <div style={{ position: "absolute", top: 110, ...font, fontSize: 50, fontWeight: 700, ...reveal }}>
        One tap to log the day
      </div>
      <PhoneFrame scale={scale}>
        <div style={{ padding: 30 }}>
          <div style={{ ...font, color: C.inkSoft, fontSize: 26, marginTop: 30 }}>
            Good evening
          </div>
          <div style={{ ...font, fontSize: 46, fontWeight: 800 }}>How is Mia?</div>
          <div
            style={{
              marginTop: 24,
              borderRadius: 34,
              padding: 34,
              background: `linear-gradient(135deg, ${C.sage}, ${C.sageDark})`,
              color: "white",
            }}
          >
            <div style={{ ...font, color: "white", fontSize: 28, opacity: 0.85 }}>
              Right now
            </div>
            <div style={{ ...font, color: "white", fontSize: 60, fontWeight: 800, marginTop: 10 }}>
              Awake 2h 10m
            </div>
          </div>
          <div style={{ display: "flex", gap: 16, marginTop: 22 }}>
            {[
              ["Feed", C.feed, C.feedSoft],
              ["Sleep", C.sleep, C.sleepSoft],
              ["Diaper", C.diaper, C.diaperSoft],
            ].map(([label, c, soft]) => (
              <Card key={label} style={{ flex: 1, textAlign: "center", padding: 20 }}>
                <div
                  style={{
                    width: 70,
                    height: 70,
                    borderRadius: 40,
                    background: soft,
                    margin: "0 auto 12px",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                  }}
                >
                  <div style={{ width: 26, height: 26, borderRadius: 14, background: c }} />
                </div>
                <div style={{ ...font, fontSize: 26, fontWeight: 700 }}>{label}</div>
              </Card>
            ))}
          </div>
        </div>
      </PhoneFrame>
    </AbsoluteFill>
  );
};

// ---- Scene 4: Mira knows your baby (chat) ----
const Bubble: React.FC<{
  text: string;
  mira?: boolean;
  delay: number;
}> = ({ text, mira, delay }) => {
  const r = useReveal(delay);
  return (
    <div
      style={{
        ...r,
        alignSelf: mira ? "flex-start" : "flex-end",
        maxWidth: "82%",
        background: mira ? C.surface : `linear-gradient(135deg, ${C.sage}, ${C.sageDark})`,
        color: mira ? C.ink : "white",
        padding: "22px 26px",
        borderRadius: 30,
        borderBottomLeftRadius: mira ? 8 : 30,
        borderBottomRightRadius: mira ? 30 : 8,
        fontSize: 30,
        lineHeight: 1.4,
        fontFamily,
        boxShadow: "0 10px 24px rgba(0,0,0,0.08)",
      }}
    >
      {text}
    </div>
  );
};

const SceneChat: React.FC = () => {
  const title = useReveal(4);
  return (
    <AbsoluteFill
      style={{ background: C.sand, alignItems: "center", justifyContent: "center" }}
    >
      <div style={{ position: "absolute", top: 110, textAlign: "center", ...title }}>
        <div style={{ ...font, fontSize: 54, fontWeight: 800 }}>Mira learns</div>
        <div style={{ ...font, fontSize: 54, fontWeight: 800, color: C.apricot }}>
          your baby&rsquo;s rhythm
        </div>
      </div>
      <div
        style={{
          width: 760,
          display: "flex",
          flexDirection: "column",
          gap: 22,
          marginTop: 120,
        }}
      >
        <Bubble delay={20} text="She won't nap and I'm losing it 😭" />
        <Bubble
          delay={48}
          mira
          text="That sounds exhausting. Mia's only napped once today and woke 3h ago — she's likely overtired. Try winding down now, 20 min earlier than usual."
        />
      </div>
    </AbsoluteFill>
  );
};

// ---- Scene 5: Calm Mode ----
const SceneCalm: React.FC = () => {
  const frame = useCurrentFrame();
  const breathe = 0.85 + 0.15 * Math.sin((frame / 30) * Math.PI);
  const r = useReveal(8);
  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(160deg, ${C.sageDark}, #2c4035)`,
        alignItems: "center",
        justifyContent: "center",
        gap: 60,
      }}
    >
      <div
        style={{
          width: 420,
          height: 420,
          borderRadius: 999,
          background: "rgba(255,255,255,0.10)",
          transform: `scale(${breathe})`,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <div style={{ ...font, color: "white", fontSize: 40 }}>Breathe</div>
      </div>
      <div style={{ ...r, ...font, color: "white", fontSize: 56, fontWeight: 800, textAlign: "center" }}>
        For the hard moments,
        <br />
        Calm Mode guides you.
      </div>
    </AbsoluteFill>
  );
};

// ---- Scene 6: Privacy ----
const ScenePrivacy: React.FC = () => {
  const r = useReveal(6);
  return (
    <AbsoluteFill
      style={{ background: C.sand, alignItems: "center", justifyContent: "center", gap: 30 }}
    >
      <div style={{ ...r, textAlign: "center", padding: 100 }}>
        <div style={{ ...font, fontSize: 64, fontWeight: 800 }}>Private by design.</div>
        <div style={{ ...font, fontSize: 38, color: C.inkSoft, marginTop: 18, lineHeight: 1.4 }}>
          Your baby&rsquo;s data stays on your phone.
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ---- Scene 7: CTA ----
const SceneCTA: React.FC = () => {
  const a = useReveal(4);
  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(160deg, ${C.sage}, ${C.sageDark})`,
        alignItems: "center",
        justifyContent: "center",
        gap: 36,
      }}
    >
      <div style={a}>
        <Leaf size={160} />
      </div>
      <div style={{ ...a, ...font, color: "white", fontSize: 90, fontWeight: 800 }}>
        Meet Mira
      </div>
    </AbsoluteFill>
  );
};

export const MiraPromo: React.FC = () => {
  return (
    <AbsoluteFill style={{ backgroundColor: C.sand }}>
      <Sequence durationInFrames={110}>
        <SceneLogo />
      </Sequence>
      <Sequence from={110} durationInFrames={120}>
        <SceneStatement />
      </Sequence>
      <Sequence from={230} durationInFrames={200}>
        <SceneTracker />
      </Sequence>
      <Sequence from={430} durationInFrames={210}>
        <SceneChat />
      </Sequence>
      <Sequence from={640} durationInFrames={140}>
        <SceneCalm />
      </Sequence>
      <Sequence from={780} durationInFrames={70}>
        <ScenePrivacy />
      </Sequence>
      <Sequence from={850} durationInFrames={50}>
        <SceneCTA />
      </Sequence>
    </AbsoluteFill>
  );
};
