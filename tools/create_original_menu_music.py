"""Blok Yık için özgün, döngüsel menü müziği üretir.

Bu betik üçüncü taraf örnek, melodi veya kayıt kullanmaz; WAV dosyasını
deterministik olarak temel dalga biçimlerinden üretir.
"""

import math
import struct
import wave
from pathlib import Path


RATE = 22050
BPM = 96
BEAT = 60.0 / BPM
BARS = 8
DURATION = BARS * 4 * BEAT
OUT = Path(__file__).resolve().parents[1] / "audio" / "muzik.wav"


def hz(note: int) -> float:
    return 440.0 * 2.0 ** ((note - 69) / 12.0)


def add_tone(buffer, start, length, note, volume, kind="sine"):
    first = max(0, int(start * RATE))
    last = min(len(buffer), int((start + length) * RATE))
    attack = min(0.04, length * 0.2)
    release = min(0.18, length * 0.35)
    frequency = hz(note)
    for index in range(first, last):
        elapsed = index / RATE - start
        envelope = min(1.0, elapsed / attack)
        envelope *= min(1.0, (length - elapsed) / release)
        phase = elapsed * frequency
        if kind == "triangle":
            value = 4.0 * abs((phase % 1.0) - 0.5) - 1.0
        else:
            value = math.sin(phase * math.tau)
        buffer[index] += value * volume * envelope


def main():
    buffer = [0.0] * int(DURATION * RATE)
    chords = ([48, 52, 55], [45, 48, 52], [41, 45, 48], [43, 47, 50])
    bass = [36, 36, 33, 33, 29, 29, 31, 31]
    melody = [72, 76, 79, 76, 74, 76, 81, 79]

    for bar in range(BARS):
        bar_start = bar * 4 * BEAT
        chord = chords[bar % len(chords)]
        for note in chord:
            add_tone(buffer, bar_start, 4 * BEAT * 0.92, note, 0.08)
        for beat in range(4):
            beat_start = bar_start + beat * BEAT
            add_tone(buffer, beat_start, BEAT * 0.8, bass[(bar + beat) % len(bass)], 0.16, "triangle")
        for step in range(8):
            note = melody[(bar + step) % len(melody)]
            add_tone(buffer, bar_start + step * BEAT * 0.5, BEAT * 0.32, note, 0.095)

    peak = max(max(buffer), -min(buffer), 1.0)
    pcm = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, value / peak)) * 26000)) for value in buffer)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(pcm)


if __name__ == "__main__":
    main()
