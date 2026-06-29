"""Transcribe the VO with word-level timestamps so the video can be synced
frame-perfectly. Uses the already-installed faster-whisper. Outputs sync.json."""
import json
from faster_whisper import WhisperModel

AUDIO = "public/vo.mp3"

model = WhisperModel("base", device="cpu", compute_type="int8")
segments, info = model.transcribe(AUDIO, word_timestamps=True, beam_size=5)

words = []
full = []
for seg in segments:
    full.append(seg.text.strip())
    if seg.words:
        for w in seg.words:
            words.append({"start": round(w.start, 3), "end": round(w.end, 3),
                          "word": w.word.strip()})

out = {"duration": round(info.duration, 3), "text": " ".join(full), "words": words}
with open("sync.json", "w", encoding="utf-8") as f:
    json.dump(out, f, indent=2, ensure_ascii=False)

print("DURATION:", out["duration"])
print("TEXT:", out["text"])
print("WORD COUNT:", len(words))
