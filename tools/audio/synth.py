"""Original Undertow FM synthesis racks. All oscillators and noises start here."""
from functools import lru_cache

import numpy as np
from scipy import signal

RATE = 44100
TAU = 2 * np.pi


@lru_cache(maxsize=96)
def clock(count):
    return np.arange(count, dtype=np.float32) / RATE


def timeline(seconds):
    return clock(max(2, int(round(seconds * RATE))))


def hz(pitch):
    return 440.0 * 2.0 ** ((pitch - 69.0) / 12.0)


def sine(phase):
    return np.sin(TAU * phase)


def filtered(samples, lo, hi=None, order=2):
    band = [lo, hi] if hi else lo
    sos = signal.butter(order, band, btype='bandpass' if hi else 'lowpass',
                        fs=RATE, output='sos').astype(np.float32)
    return signal.sosfilt(sos, samples).astype(np.float32)


def noise(t, seed):
    return np.random.default_rng(seed).normal(0.0, 1.0, len(t)).astype(np.float32)


def edge(t, attack, hold, release):
    return np.minimum(t / max(attack, .0002), 1) * np.exp(-np.maximum(t - hold, 0) * 6 / release)


def voiced(name, midi, length, seed):
    release = {'pad': .77, 'choir': .83, 'keys': .39, 'glass': .55,
               'marimba': .27, 'guitar': .15, 'bass': .08, 'fuzz': .12,
               'pluck': .16, 'lead': .19, 'reed': .23, 'brass': .20, 'tape': .46, 'pipe': .25}[name]
    t = timeline(length + release)
    freq = hz(midi)
    phase = freq * t
    start = (seed % 743) / 743
    if name in ('bass', 'fuzz'):
        # Resonant, velocity-like fret attack over a mostly sinusoidal bass.
        p = phase + .006 * sine(t * 5 + start)
        sub = .79 * sine(p) + (.26 + .2 * np.exp(-t * 12)) * sine(2 * p)
        upper = (.19 * sine(3*p) + .13 * sine(4*p) + .09*sine(7*p)) * (.40 + np.exp(-12*t))
        if name == 'fuzz':
            upper += .32*np.tanh(2.2*(sine(3*p)+.26*sine(4*p)))
        wave = np.tanh(1.22 * (sub + upper)) * (.8 + .2*np.exp(-t*5))
        attack = .006
    elif name == 'tape':
        # Magnetic keyboard: a felted FM tine under a softly unstable reed stop.
        slow = .038*sine(t*.72 + start) + .012*sine(t*4.1 + start)
        p = phase + slow
        attack_tone = .15*np.exp(-t*7)*sine(phase*2.003)
        wave = .72*sine(p + attack_tone) + .21*sine(2*p+.015*sine(3*t))
        wave += .13*sine(3*phase*1.001 + start)*np.exp(-t*2.5)
        wave += .045*sine(5.04*p)*np.exp(-t*16)
        wave *= (.43 + .57*np.exp(-1.8*t))*(.95+.05*sine(3.1*t+start))
        attack = .012
    elif name == 'pipe':
        # A small hybrid flute on the gantries, with a blown attack and light vibrato.
        p = phase + .072*sine(5.4*t)*np.minimum(t*3,1)
        wave = (.83*sine(p)+.18*sine(2.003*p)+.12*sine(3*p)
                + .09*sine(4.001*p)*np.exp(-t*6))
        wave += .085*filtered(noise(t,seed),1300,4900)*np.exp(-t*22)
        attack = .026
    elif name == 'keys':
        # Tine and warm body have separate decay rates; slow tremolo after attack.
        tone = sine(phase + (.005 + .26*np.exp(-t * 8))*sine(phase*2))
        wave = (.83*tone + .19*np.exp(-t*5)*sine(phase*3.005)
                + .09*np.exp(-t*28)*sine(phase*7.01))
        wave *= (.60*np.exp(-1.4*t) + .40*np.exp(-t*6))*(.95 + .05*sine(4.2*t+start))
        attack = .004
    elif name in ('marimba', 'glass'):
        bright = name == 'glass'
        ratios = (1, 2.003, 2.995, 4.22, 6.83) if bright else (1, 2.006, 3.91, 8.12)
        amps = (1, .27, .18, .17, .085) if bright else (1, .21, .39, .11)
        decay = (2.0, 3.4, 5.7, 8, 16) if bright else (3.6, 5.8, 11, 29)
        wave = sum(a*sine(phase*r)*np.exp(-t*d) for r,a,d in zip(ratios,amps,decay) if freq*r < 14500)
        attack = .003
    elif name in ('pluck', 'guitar'):
        # Damped string with a pick-position notch and decaying upper partials.
        wave = np.zeros_like(t)
        pick = .19 if name == 'guitar' else .27
        for h in range(1, min(14, int(14000/freq))+1):
            amp = np.sin(np.pi*h*pick) / h**1.18
            p = phase*h*(1+.00003*h*h)
            wave += amp*sine(p)*np.exp(-t*(2.3+.72*h))
        wave += .055*filtered(noise(t,seed), 800,4800)*np.exp(-t*125)
        if name == 'guitar':
            wave = np.tanh(1.55*wave)
        attack = .003
    elif name in ('pad', 'choir'):
        breath = .008*sine(4.6*t + start)
        a = phase + breath + start
        b = phase*1.003 + .012*sine(3.7*t+start) + .29 + start
        if name == 'pad':
            wave = .43*sine(a)+.35*sine(b)+.16*sine(2*a)+.11*sine(3*b)+.07*sine(4*a)
        else:
            wave = (.4*sine(a)+.3*sine(b)+ .15*sine(2*a)+.19*sine(3*b)
                    + .10*sine(5*a)+.07*sine(6*b)) * (.91+.09*sine(.83*t+start))
        attack = .165 if name == 'pad' else .24
    else:
        # Breath/pressure vibrato opens late; pitches remain legible on small speakers.
        p = phase + .066*sine(4.9*t + .1*start)*np.minimum(t*3.4,1)
        strike = np.exp(-t*10)
        if name == 'lead':
            wave = .79*sine(p)+.27*sine(2*p)+(.19+.1*strike)*sine(3*p)+.08*sine(5*p)
            attack = .016
        elif name == 'reed':
            wave = .84*sine(p)+.21*sine(3*p)+.105*sine(5*p)+.09*strike*sine(2*p)
            attack = .030
        else:
            wave = .62*sine(p)+.35*sine(2*p)+.25*sine(3*p)+.13*sine(4*p)+.11*sine(5*p)
            wave = np.tanh(1.3*wave)*(.8+.2*np.minimum(t*9,1))
            attack = .024
    wave *= edge(t, attack, length, release)
    wave[-min(len(wave),80):] *= np.linspace(1,0,min(len(wave),80))
    return wave.astype(np.float32)


def sweep(t, f0, f1, speed):
    return f1*t + (f0-f1)*(1-np.exp(-speed*t))/speed


def drum(name, seed=1):
    duration = {'kick':.34,'snare':.28,'rim':.13,'hat':.15,'open':.32,'clap':.27,
                'tom':.39,'metal':.28,'shaker':.15,'ride':.41,'crash':.96,'stick':.14}[name]
    t = timeline(duration)
    n = noise(t, seed)
    if name == 'kick':
        wave = sine(sweep(t,155,46,36))*np.exp(-t*13.5) + .09*filtered(n,1200,4200)*np.exp(-220*t)
    elif name == 'snare':
        body = .69*sine(sweep(t,254,166,29))*np.exp(-t*26) + .24*sine(327*t)*np.exp(-t*38)
        wave = body + .84*filtered(n,920,6900)*np.exp(-t*20)
    elif name == 'rim':
        wave = (.69*sine(810*t)+.43*sine(1347*t)+.36*sine(549*t))*np.exp(-t*83)
        wave += .23*filtered(n,1600,6400)*np.exp(-t*50)
    elif name == 'clap':
        bursts = np.zeros_like(t)
        for onset, level, fall in [(0,.8,190),(.012,.71,165),(.025,.94,190),(.035,.8,22)]:
            bursts += level*np.where(t>=onset,np.exp(-fall*np.maximum(0,t-onset)),0)
        wave = 1.5*filtered(n,690,6900)*bursts
    elif name in ('hat','open','ride','crash'):
        metal = np.sign(sine(t*5461))*np.sign(sine(t*4607)) + .4*sine(t*6751+.36*sine(t*993))
        wave = filtered(.9*n + .24*metal, 4300, 13100)
        fall = {'hat':49,'open':13,'ride':10,'crash':5}[name]
        wave *= np.exp(-t*fall)
        if name == 'ride':
            wave += .19*sine(3119*t+.34*sine(730*t))*np.exp(-t*11)
    elif name == 'tom':
        wave = (.84*sine(sweep(t,182,87,17))+.22*sine(sweep(t,286,134,23)))*np.exp(-t*12)
    elif name == 'metal':
        wave = sum(a*sine(f*t)*np.exp(-t*d) for f,a,d in ((548,.5,28),(1424,.36,29),(2281,.2,42),(497,.35,19)))
        wave += .14*filtered(n,1100,7200)*np.exp(-65*t)
    elif name == 'stick':
        wave = (.68*sine(1072*t)+.31*sine(1577*t)+.28*filtered(n,300,7200))*np.exp(-t*83)
    else:
        wave = filtered(n,4800,11200)*np.minimum(t*158,1)*np.exp(-t*29)
    return (wave * np.minimum(t*1500,1) * np.minimum((duration-t)*150,1)).astype(np.float32)
