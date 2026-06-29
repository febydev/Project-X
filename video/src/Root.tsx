import React from "react";
import { Composition } from "remotion";
import { MiraPromo } from "./MiraPromo";

// 54 seconds at 30fps, vertical (phone-ad) format — matched to the voiceover.
export const RemotionRoot: React.FC = () => {
  return (
    <Composition
      id="MiraPromo"
      component={MiraPromo}
      durationInFrames={1620}
      fps={30}
      width={1080}
      height={1920}
    />
  );
};
