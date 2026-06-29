import React from "react";
import { Composition } from "remotion";
import { MiraPromo } from "./MiraPromo";

// 30 seconds at 30fps, vertical (phone-ad) format.
export const RemotionRoot: React.FC = () => {
  return (
    <Composition
      id="MiraPromo"
      component={MiraPromo}
      durationInFrames={900}
      fps={30}
      width={1080}
      height={1920}
    />
  );
};
