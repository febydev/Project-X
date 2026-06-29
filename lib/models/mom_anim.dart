/// The reactive states for the animated mom character. The character widget
/// maps each to a motion (code-drawn now, Lottie-ready later).
enum MomAnim {
  idleMorning, // stretch, yawn, coffee
  idleNight, // night light, sleepy
  celebrate, // fist pump / bounce (feed, milestone, activity done)
  diaper, // holds nose, then thumbs up
  shhh, // finger to lips, tiptoe (sleep start)
  wake, // surprised then smile (baby woke)
  pointClock, // points at clock (nap window near)
  calm, // hands on chest, deep breath
  hug, // arms open, warm hug (low mom streak)
  dance, // full happy dance (milestone)
  bedtime, // yawn, points to bed (after 10pm)
  leap, // holds brain icon, wondering
  idle, // neutral gentle bob
}
