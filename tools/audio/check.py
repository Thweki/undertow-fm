"""Decode the shipped assets and verify format, musical timing, loudness and seams."""
import sys

import numpy as np
import soundfile as sf
from scipy import signal

from render import EFFECTS, OUTPUT, RATE, SONGS, integrated


def true_peak(samples):
    # Fourfold intersample check, channel by channel.
    return max(float(np.max(np.abs(signal.resample_poly(samples[:,c],4,1))))
               for c in range(samples.shape[1]))


def db(value):
    return 20*np.log10(max(value,1e-12))


def check():
    failures = []
    total = 0
    print('Track     Length    LUFS     dBTP    seam jump    stereo r')
    for name,song in SONGS.items():
        path = OUTPUT/(name+'.ogg')
        samples,rate = sf.read(path,dtype='float32',always_2d=True)
        total += len(samples)/rate
        length = round(60/song.bpm*4*8*len(song.form)*rate)
        peak = true_peak(samples)
        level = integrated(path)
        seam = np.max(np.abs(samples[0]-samples[-1]))
        corr = np.corrcoef(samples[::6].T)[0,1]
        if samples.shape!=(length,2) or rate!=RATE or sf.info(path).subtype!='VORBIS':
            failures.append(name+' timing/format')
        target = {'title':-19.3,'workshop':-18.3,'ending':-19.3,'past':-18.8,'boss':-17.5}.get(name,-18)
        if abs(level-target)>.45 or peak>.88:
            failures.append(name+' mastering')
        if corr<=0 or not np.isfinite(samples).all() or seam>.061:
            failures.append(name+' stereo/seam')
        print(f'{name:9s} {length/rate:6.2f}   {level:5.1f}   {db(peak):6.2f}   '
              f'{db(seam):7.1f} dB   {corr:.3f}')
    print(f'Duration: {total:.2f}s')
    for name,(duration,intended) in EFFECTS.items():
        path = OUTPUT/(name+'.wav')
        samples,rate = sf.read(path,dtype='float32',always_2d=True)
        expected = round(duration*RATE)
        if sf.info(path).subtype != 'PCM_16' or rate!=RATE or samples.shape!=(expected,1):
            failures.append(name+' sample format')
        peak = np.max(np.abs(samples))
        if abs(peak-intended)>.002 or abs(samples[0,0])>.001 or abs(samples[-1,0])>.005:
            failures.append(name+' contour')
    print(f'{len(EFFECTS)} mono action effects and radio cues checked')
    if failures:
        sys.exit('Failed: '+', '.join(failures))


if __name__=='__main__':
    check()
