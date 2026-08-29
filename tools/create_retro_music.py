"""Generate the original retro main-menu loop used by the game."""

import math
import random
import struct
import wave
from pathlib import Path


RATE = 22050
BPM = 156
BEAT = 60.0 / BPM
BARS = 16
DURATION = BARS * 4 * BEAT
OUT = Path(__file__).resolve().parents[1] / "audio" / "muzik_oyun_baslangic.wav"


def midi_hz(note: int) -> float:
    return 440.0 * 2.0 ** ((note - 69) / 12.0)


def wave_sample(phase: float, kind: str) -> float:
    if kind == "square":
        return 1.0 if phase % 1.0 < 0.5 else -1.0
    if kind == "triangle":
        return 4.0 * abs((phase % 1.0) - 0.5) - 1.0
    return math.sin(phase * math.tau)


def add_tone(buffer, start, length, note, volume, kind):
    frequency = midi_hz(note)
    first = max(0, int(start * RATE))
    last = min(len(buffer), int((start + length) * RATE))
    attack = min(0.012, length * 0.18)
    release = min(0.045, length * 0.35)
    for index in range(first, last):
        elapsed = index / RATE - start
        envelope = min(1.0, elapsed / attack)
        envelope *= min(1.0, (length - elapsed) / release)
        phase = elapsed * frequency
        buffer[index] += wave_sample(phase, kind) * volume * envelope


def add_drum(buffer, start, kind):
    first = int(start * RATE)
    length = 0.13 if kind == "hat" else 0.22
    last = min(len(buffer), first + int(length * RATE))
    rng = random.Random(int(start * 1000) + (11 if kind == "hat" else 29))
    for index in range(max(0, first), last):
        elapsed = (index - first) / RATE
        decay = math.exp(-24.0 * elapsed) if kind == "hat" else math.exp(-17.0 * elapsed)
        if kind == "hat":
            value = (rng.random() * 2.0 - 1.0) * decay * 0.12
        else:
            value = math.sin(math.tau * (110.0 - 65.0 * elapsed) * elapsed) * decay * 0.32
        buffer[index] += value


def main():
    samples = int(DURATION * RATE)
    buffer = [0.0] * samples
    bass = [36, 36, 43, 31, 36, 36, 40, 31]
    lead = [72, 76, 79, 76, 74, 79, 84, 79, 77, 81, 84, 81, 76, 79, 83, 79]
    arpeggio = [60, 64, 67, 71, 67, 64, 59, 62]

    for bar in range(BARS):
        bar_start = bar * 4 * BEAT
        for beat in range(4):
            beat_start = bar_start + beat * BEAT
            add_tone(buffer, beat_start, BEAT * 0.72, bass[(bar * 4 + beat) % len(bass)], 0.18, "triangle")
            add_drum(buffer, beat_start, "kick")
            add_drum(buffer, beat_start + BEAT * 0.5, "hat")
            add_drum(buffer, beat_start + BEAT * 0.75, "hat")
        for step in range(8):
            add_tone(buffer, bar_start + step * BEAT * 0.5, BEAT * 0.38, arpeggio[(bar + step) % len(arpeggio)], 0.11, "square")
        for step in range(4):
            note = lead[(bar + step * 2) % len(lead)]
            add_tone(buffer, bar_start + step * BEAT, BEAT * 0.72, note, 0.13, "square")

    peak = max(max(buffer), -min(buffer), 1.0)
    pcm = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, value / peak)) * 28000)) for value in buffer)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(pcm)


if __name__ == "__main__":
    main()
