#!/usr/bin/env python3
"""Render the original game soundtrack and effects from source (see README)."""
import argparse
import re
import subprocess
import tempfile
from pathlib import Path

import numpy as np
import soundfile as sf
from scipy import signal
from scipy.io import wavfile

from synth import RATE, drum, filtered, hz, noise, sine, sweep, timeline, voiced
from score import INTERVALS, SONGS

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / 'assets/audio'


def circular_add(bus, index, samples, gains=1.0):
    start = index % len(bus)
    first = min(len(samples), len(bus)-start)
    if bus.ndim == 2 and samples.ndim == 1:
        samples = samples[:, None]
    bus[start:start+first] += samples[:first]*gains
    if first < len(samples):
        bus[:len(samples)-first] += samples[first:]*gains


def short_room(samples, seed):
    """Stereo room with discrete reflections and a smoothly diffusing late field."""
    t = timeline(.73)
    rng = np.random.default_rng(seed)
    ir = np.zeros((len(t),2), np.float32)
    for channel, onset in ((0,.019),(1,.023)):
        texture = filtered(rng.normal(0,1,len(t)).astype(np.float32),160,4700)
        ir[:,channel] = .041*texture*np.exp(-t*9)*np.minimum(np.maximum((t-.035)*25,0),1)
        for index, gain in ((onset,.38),(onset+.017,-.21),(onset+.038,.16),(onset+.044,.1)):
            ir[round(index*RATE),channel] += gain
    result = np.empty_like(samples)
    mid = (samples[:,0]+samples[:,1])*.5
    for i in range(2):
        response = signal.oaconvolve(mid,ir[:,i])
        result[:,i] = response[:len(samples)]
        result[:len(response)-len(samples),i] += response[len(samples):]
    return result


class Studio:
    def __init__(self, bpm, bars, seed):
        self.step = 60/bpm/4
        self.bars = bars
        self.rng = np.random.default_rng(seed)
        count = round(self.step*bars*16*RATE)
        self.mix = np.zeros((count,2),np.float32)
        self.room = np.zeros_like(self.mix)
        self.delay = np.zeros_like(self.mix)
        self.seed = seed
        self.seq = 0

    def stamp(self, pos, audio, volume, pan, room, echo):
        index = round(pos*self.step*RATE)
        gains = volume*np.sqrt(np.array([.5-.5*pan,.5+.5*pan],np.float32))
        circular_add(self.mix,index,audio,gains)
        if room:
            circular_add(self.room,index,audio,gains*room)
        if echo:
            circular_add(self.delay,index,audio,gains*echo)

    def tone(self, timbre, pos, note, steps, volume, pan=0, room=.15, echo=0):
        self.seq += 1
        wave = voiced(timbre,note,steps*self.step,self.seed+self.seq*29)
        self.stamp(pos,wave,volume,pan,room,echo)

    def kit(self, name, pos, amp, pan=0, room=.08):
        self.seq += 1
        wave = drum(name,self.seed+self.seq%13)
        self.stamp(pos,wave,amp,pan,room,0)

    def finish(self, ambience, name):
        # Feed-forward tempo delay carries tails over the exact downbeat.
        for steps, level in ((3,.64),(6,.31),(9,.16),(12,.08)):
            delayed = np.roll(self.delay[:,::-1] if steps in (3,9) else self.delay,
                              round(steps*self.step*RATE),axis=0)
            self.mix += delayed*level
        self.mix += short_room(self.room,self.seed)
        # The rain slowly shifts in stereo; no sampled media.
        t = np.arange(len(self.mix),dtype=np.float32)/RATE
        cycle = t/(len(self.mix)/RATE)
        for channel in range(2):
            hiss = filtered(self.rng.normal(0,1,len(t)).astype(np.float32),700,4700)
            self.mix[:,channel] += ambience*hiss*(.75+.25*sine(2*cycle+.27*channel))
        if name in ('title','docks','ending','past'):
            # A low ferry motor down the quay, tuned to the track.
            drone = .014*sine(hz(SONGS[name].key-24)*t)
            window = np.sin(np.pi*cycle)**2*(.55+.45*sine(3*cycle))
            self.mix += (drone*window)[:,None]
        sos = signal.butter(2,26,fs=RATE,btype='highpass',output='sos').astype(np.float32)
        warm = np.concatenate((self.mix[-RATE//3:],self.mix),axis=0)
        mix = signal.sosfilt(sos,warm,axis=0)[RATE//3:]
        if name=='past':
            # Periodic wow/flutter and the reduced bandwidth of the surviving reel.
            base = np.arange(len(mix),dtype=np.float64)
            normalized = base/len(mix)
            displacement = 16*sine(43*normalized) + 2*sine(229*normalized)
            for c in range(2):
                mix[:,c] = np.interp((base+displacement)%len(mix),base,mix[:,c],period=len(mix))
            tape_filter = signal.butter(2,7600,fs=RATE,output='sos').astype(np.float32)
            mix = signal.sosfilt(tape_filter,np.concatenate((mix[-(RATE//8):],mix)),axis=0)[RATE//8:]
        return np.tanh(mix*1.1).astype(np.float32)


# Each groove gets its own kick placement, backbeat, ornament and swing.
GROOVE = {
    'title':    ((0,10),(4,12),'rim',.045),
    'workshop': ((0,7,10),(4,12),'rim',.13),
    'market':   ((0,6,8,14),(4,12),'clap',.04),
    'docks':    ((0,7,11),(8,),'snare',.17),
    'tower':    ((0,4,8,12),(4,12),'clap',.01),
    'boss':     ((0,7,10),(4,12),'snare',.035),
    'ending':   ((0,10),(4,12),'rim',.11),
    'past':     ((0,9),(4,12),'rim',.15),
    'catwalk':  ((0,7,10,14),(4,12),'snare',.065),
}

BASS = {
    'title':    ((0,0,5),(8,7,2),(13,12,2)),
    'workshop': ((0,0,2.5),(3,0,1.2),(6,7,1.8),(10,12,2),(14,7,1.5)),
    'market':   ((0,0,2),(3,12,1),(6,7,1.6),(8,0,2.5),(12,12,1.5),(15,7,.8)),
    'docks':    ((0,0,5.2),(7,0,1),(10,7,2.2),(14,0,1.4)),
    'tower':    ((0,0,2.8),(4,12,2.8),(8,0,2.8),(12,7,1.8),(15,12,.75)),
    'boss':     ((0,0,2),(3,0,1),(6,0,1.7),(9,7,2),(12,12,1.5),(15,0,.75)),
    'ending':   ((0,0,5.5),(8,7,2.5),(13,12,2)),
    'past':     ((0,0,6),(9,7,2),(13,12,1.6)),
    'catwalk':  ((0,0,2),(3,7,1),(6,12,1.5),(10,0,2.5),(14,7,1.3)),
}
CHORD_HITS = {
    'title': ((2,7),(11,3)), 'workshop': ((2,1.9),(7,2.1),(12,2.4)),
    'market': ((2,1.1),(6,1.3),(10,1.2),(14,1.3)), 'docks': ((3,1.4),(11,2)),
    'tower': ((2,2),(6,2),(10,2),(14,2)), 'boss': ((0,2),(6,1.7),(11,1.4)),
    'ending': ((0,5.5),(8,5.5)),
    'past': ((0,6.1),(9,4.8)), 'catwalk': ((2,1.7),(7,1.1),(10,2.0),(14,1.1)),
}


def beat(studio, name, bar, section):
    start = bar*16
    k, back, snare, swing = GROOVE[name]
    soft = name in ('title','ending','past')
    if soft and section==0 and bar<3:
        if bar in (1,2):
            studio.kit('stick',start+12,.10,.24,.40)
        return
    if name=='tower' and bar%8==7:
        k = (0,4,8)
    if name=='market' and bar%4==2:
        k = (0,6,10,13)
    if name=='boss' and bar%4 in (1,3):
        k = (0,3,8,11) if bar%4==1 else (0,6,10,14)
    if name=='docks' and bar%2:
        k = (0,6,10,14)
    if bar==16 and name not in ('title','ending','workshop'):
        back = ()
        k = (0,)
    level = (.65 if soft else .89) * (.85 if bar%8==6 else 1)
    for i,p in enumerate(k):
        studio.kit('kick',start+p,level*(1 if i==0 else .79+.14*(i%2)),room=.035)
    for p in back:
        studio.kit(snare,start+p+.025,.63 if not soft else .38,.02,.19)
        if name in ('market','tower','boss'):
            studio.kit('snare' if snare=='clap' else 'clap',start+p+.055,.21,-.13,.16)
    if bar%4 in (1,3) and not soft:
        studio.kit('rim',start+(14.96 if bar%4==1 else 6.95),.15,-.24,.26)
    every = 4 if soft and (section==0 or bar%4==3) else 2
    for p in range(0,16,every):
        if (bar%8==7 or bar==16) and p>=12:
            continue
        v = .17 if p%4==2 else .10
        hat = 'shaker' if soft or name=='workshop' else 'hat'
        if p in (6,14) and (bar%2==0 or section%2) and not soft:
            hat = 'open' if name!='boss' else 'ride'
        studio.kit(hat,start+p+(swing if p%4==2 else 0),v*studio.rng.uniform(.8,1.18),
                   -.34 if p%4<2 else .22,.13)
    if name in ('docks','workshop','market','boss','catwalk') and bar%2==0:
        studio.kit('metal' if name=='docks' else 'stick',start+3+swing,.16,.50,.27)
        studio.kit('rim',start+9+swing,.13,-.40,.22)
    if bar%4==3:
        for p,v in ((11,.14),(14,.24),(15,.32)):
            if soft and p!=15:
                continue
            hit = 'tom' if bar%8==7 else ('snare' if name=='boss' else 'stick')
            studio.kit(hit,start+p+swing,v*(.6 if soft else 1),.33-(p-11)*.16,.24)
    if bar%8==0 and bar>0 and not soft:
        studio.kit('crash',start,.23,.24,.45)


def chord_info(song, section, bar):
    label = song.progressions[section].split()[bar%8]
    root, kind = re.fullmatch(r'(\d+)(.+)',label).groups()
    root = int(root)
    ints = INTERVALS[kind]
    # Close-position upper voicing, retaining colour tones and a clean low register.
    notes = sorted({(song.key+root+i-52)%12+52 for i in (ints if kind=='p' else ints[1:])})
    if len(notes)==2 and kind=='p':
        notes.append(notes[0]+12)
    return root, notes


def render_song(name):
    song = SONGS[name]
    seed = 707+list(SONGS).index(name)*1000
    studio = Studio(song.bpm,len(song.form)*8,seed)
    for bar in range(studio.bars):
        block = bar//8
        section = 'ab'.index(song.form[block])
        start = 16*bar
        root, notes = chord_info(song,section,bar)
        # Different scoring and dynamics on the return; small holes for the stage SFX.
        soft = name in ('title','ending','past')
        sparse = (bar < 2 and soft) or (bar==16 and not soft)
        bass = song.key-24+root
        if bass>47:
            bass -= 12
        bass_notes = BASS[name]
        if sparse:
            bass_notes = ((0,0,10),)
        elif bar%4==3:
            bass_notes = bass_notes[:-1]
        beat(studio,name,bar,block)
        for p,i,d in bass_notes:
            studio.tone('fuzz' if name=='boss' else 'bass',start+p,bass+i,d,
                        (.42 if soft else .61)*(.78 if i else 1),room=.025)
        if bar%4==3 and not sparse:
            next_block = ((bar+1)%studio.bars)//8
            next_section = 'ab'.index(song.form[next_block])
            next_root,_ = chord_info(song,next_section,(bar+1)%8)
            target = song.key-24+next_root
            if target>47:
                target -= 12
            studio.tone('bass',start+14.2,target-1 if bar%8==7 else target+2,1.25,.32,room=.03)
        # Sustained two/three-voice bed, separated from the more percussive chord instrument.
        if name not in ('boss','market') or block%2 or bar%4==0:
            for k,n in enumerate(notes[::max(1,len(notes)-2)]):
                studio.tone('choir' if name in ('docks','ending') else 'pad',
                            start+k*.10,n+(12 if k==0 and name=='ending' else 0),
                            13.8,.126 if soft else .13,(-.63,.45,.63,-.4)[k%4],.37)
        for p,d in CHORD_HITS[name]:
            if (sparse and p>3) or (bar%8==7 and p>10):
                continue
            if name=='ending' and p==0 and bar%2:
                p += .7
            for k,n in enumerate(notes):
                v = .23 if song.chord in ('guitar','pluck') else .18
                studio.tone(song.chord,start+p+k*.045,n,d,v*(.82 if k%2 else 1),
                            (-.49,-.22,.17,.42)[k%4],.24,.09 if name=='docks' else 0)
        # Relay arpeggiator crosses the stereo field; active only in selected passages.
        if (name in ('tower','catwalk') and not sparse) or (block%2 and name in ('market','boss','title')):
            arp = [0,2,1,2,0,1,2,1]
            for j,k in enumerate(arp):
                if name not in ('tower','catwalk') and j%2==0:
                    continue
                n = notes[k%len(notes)]+12
                studio.tone('glass' if name=='title' else 'pluck',start+2*j+.04,n,1.2,.14,
                            .52 if j%2 else -.48,.20,.10)
        melody = song.phrases[section][bar%8]
        for j,cell in enumerate(melody.split()):
            p,i,d = map(float,cell.split(':'))
            voice = song.lead
            if soft and block==2 and bar%4 in (2,3):
                voice = 'glass' if name in ('ending','past') else 'keys'
            note = song.key+i+(12 if name=='workshop' else 0)
            amp = .54 if voice in ('glass','marimba','keys','tape') else .43
            if name=='boss':
                amp = .45
            studio.tone(voice,start+p,note,d,amp*(.89 if d<2.5 else 1),-.055,.31,.25)
        # Antiphonal reply occupies the gaps between the lead's longer notes.
        if not sparse and (bar%4 in (1,3) or block in (1,3)):
            if bar%2:
                p1,p2 = 0,10
            else:
                p1,p2 = 4.1,13
            for j,p in enumerate((p1,p2)):
                n = notes[(bar+j)%len(notes)] + (12 if block%2 else 0)
                studio.tone(song.answer,start+p,n,1.6 if j else 2.5,.20 if block%2 else .16,
                            .43,.37,.23)
    return studio.finish(.028 if soft else .012,name)


EFFECTS = {
    'jab': (.16,.65), 'heavy': (.31,.77), 'hit': (.25,.83), 'guard': (.34,.78),
    'dodge': (.26,.60), 'skill': (.83,.76), 'hurt': (.34,.73), 'ko': (.74,.76),
    'select': (.11,.37), 'confirm': (.31,.48), 'radio': (.43,.42),
    'alarm': (.77,.59), 'clear': (1.06,.61), 'step': (.16,.34),
}


# Tuned return idents for the five field patch bays. Note offsets are seconds.
STATION_CALLS = {
    'return_theatre': ('glass',((74,.018,.12),(78,.118,.16),(81,.292,.28))),
    'return_salt': ('marimba',((62,.018,.07),(62,.113,.07),(69,.237,.19),(72,.412,.20))),
    'return_customs': ('pluck',((70,.025,.08),(75,.110,.10),(70,.270,.07),(77,.357,.22))),
    'return_ridge': ('pipe',((69,.017,.10),(76,.126,.10),(79,.236,.13),(83,.376,.22))),
    'return_breakwater': ('reed',((57,.020,.18),(64,.240,.10),(67,.389,.27)))
}
EFFECTS.update({name:(.91,.59) for name in STATION_CALLS})


def effect(name):
    dur,peak = EFFECTS[name]
    t = timeline(dur)
    rng_seed = 12001+list(EFFECTS).index(name)*11
    n = noise(t,rng_seed)
    result = np.zeros_like(t)
    def add(sound,onset=0,gain=1):
        k = round(onset*RATE)
        size = min(len(result)-k,len(sound))
        result[k:k+size] += sound[:size]*gain
    def burst(lo,hi,rate,attack=.002):
        return filtered(n,lo,hi)*np.minimum(t/attack,1)*np.exp(-t*rate)
    def note(pitch,duration,onset,gain,voice='glass'):
        add(voiced(voice,pitch,duration,rng_seed),onset,gain)
    if name=='jab':
        # Short cloth snap trails behind a dry, rising cuff sound.
        add(burst(900,4500,24,.015),gain=.83)
        add(burst(290,1080,36,.003),.036,.70)
        add(sine(sweep(t,330,160,34))*np.exp(-t*69),.046,.30)
    elif name=='heavy':
        add(burst(180,1500,16,.039),gain=.90)
        add(burst(650,5200,23,.029),.024,.60)
        add(sine(sweep(t,152,50,19))*np.exp(-t*15),.091,.72)
        add(burst(980,4300,73),.09,.42)
    elif name=='hit':
        add(sine(sweep(t,238,54,35))*np.exp(-t*22),gain=.94)
        add(burst(380,3000,52),gain=1.18)
        add(burst(2100,7000,85),.008,.91)
        add(sine(sweep(t,401,167,39))*np.exp(-t*46),.012,.36)
    elif name=='guard':
        add(burst(600,4600,54),gain=.88)
        for f,a,r in ((689,.70,18),(1001,.37,16),(2041,.24,23),(3027,.14,34)):
            add(sine(f*t)*np.exp(-t*r),gain=a)
        add(burst(140,970,53),.024,.9)
    elif name=='dodge':
        add(burst(480,3400,17,.053),gain=.83)
        add(burst(2400,6800,26,.037),.037,.51)
        add(burst(150,720,38,.013),.112,.63)
    elif name=='skill':
        add(burst(620,4700,15,.037),gain=.49)
        add(sine(120*t+330*t*t)*np.exp(-t*27),gain=.47)
        for p,start in ((57,.015),(64,.045),(67,.083),(69,.127),(76,.170)):
            note(p,.077,start,.34,'lead')
        add(sine(sweep(t,188,49,20))*np.exp(-t*11),.146,.96)
        add(burst(1000,6300,12,.004),.14,.72)
        for f,a in ((646,.20),(978,.17),(1293,.12)):
            add(sine(f*t+.1*sine(20*t))*np.exp(-t*8),.177,a)
    elif name=='hurt':
        add(burst(280,2860,28),gain=.88)
        # Vocal-like formants made from an oscillator, not a recorded voice.
        pulse = np.tanh(2.1*(sine(sweep(t,157,83,8))+.40*sine(sweep(t,310,166,8))))
        add(filtered(pulse,280,1120)*np.exp(-t*15),.016,.92)
        add(sine(sweep(t,144,57,23))*np.exp(-t*18),gain=.47)
    elif name=='ko':
        for onset,level in ((0,.89),(.105,.51),(.221,.72),(.31,.27)):
            add(sine(sweep(t,143,43,27))*np.exp(-t*16),onset,level)
            add(burst(280,2700,41),onset,level*.80)
        add(burst(1260,4200,19,.018),.31,.44)
    elif name in ('select','confirm','clear'):
        notes = {
            'select': ((76,.00,.035,.65),),
            'confirm': ((69,0,.045,.5),(76,.062,.08,.55),(81,.112,.11,.45)),
            'clear': ((62,0,.12,.43),(69,.094,.12,.50),(74,.191,.13,.52),
                      (78,.303,.16,.44),(81,.416,.24,.58)),
        }[name]
        for p,start,span,level in notes:
            note(p,span,start,level)
            note(p-12,span,start+.003,.21*level,'keys')
        if name=='clear':
            for p in (62,69,73,78):
                note(p,.28,.48,.17,'keys')
    elif name in STATION_CALLS:
        voice,score = STATION_CALLS[name]
        add(burst(850,4200,48),gain=.31)
        for pitch,onset,length in score:
            source = voiced(voice,pitch,length,rng_seed)
            # The receiving set's narrow speaker, with a short slap from the shelter.
            body = filtered(source,280,3600)
            add(body,onset,.69)
            add(body,onset+.058,.12)
        add(burst(1300,5200,22),.64,.19)
        add(sine(sweep(t,1130,890,6))*np.exp(-t*35),.012,.19)
    elif name=='radio':
        add(burst(900,4200,25),gain=.4)
        # A rhythmic three-pulse call sign, tuned like a shortwave receiver.
        for f,start,length in ((880,.013,.04),(1174,.082,.04),(988,.158,.114)):
            env = np.minimum(t*250,1)*np.exp(-np.maximum(t-length,0)*140)
            add((sine(f*t)+.16*sine(f*2*t)) * env,start,.41)
        add(burst(700,5500,22),.255,.44)
    elif name=='alarm':
        for start in (0,.35):
            env = np.minimum(t/.015,1)*np.exp(-np.maximum(t-.19,0)*31)
            add((sine(523*t+90*t*t)+.25*sine(1046*t+180*t*t))*env,start,.47)
        add(burst(300,2400,13),gain=.15)
    else:
        add(sine(sweep(t,121,58,27))*np.exp(-t*51),gain=.53)
        add(burst(170,1400,42),gain=.67)
        add(burst(1450,4500,75),.024,.48)
    ramp = np.minimum(t*1300,1)*np.minimum((dur-t)/min(.025,dur*.18),1)
    result = np.tanh(result*ramp)
    return result*(peak/max(1e-5,np.max(np.abs(result))))


def integrated(filename):
    result = subprocess.run(['ffmpeg','-nostats','-hide_banner','-i',str(filename),
                             '-af','ebur128=peak=true','-f','null','-'],
                            stdout=subprocess.DEVNULL,stderr=subprocess.PIPE,text=True,check=True)
    matches = re.findall(r'I:\s+(-?[\d.]+) LUFS',result.stderr)
    return float(matches[-1])


def pcm(audio):
    return np.round(np.clip(audio,-1,1)*32767).astype('<i2')


def produce_music(name,tmp):
    print('Composing', name, flush=True)
    audio = render_song(name)
    wav = tmp/(name+'.wav')
    wavfile.write(wav,RATE,pcm(audio))
    initial = integrated(wav)
    target = {'title':-19.3,'workshop':-18.3,'ending':-19.3,'past':-18.8,'boss':-17.5}.get(name,-18)
    gain = min(10**((target-initial)/20),.84/np.max(np.abs(audio)))
    ogg = tmp/(name+'.ogg')
    sf.write(ogg,audio*gain,RATE,format='OGG',subtype='VORBIS',compression_level=.42)
    final,rate = sf.read(ogg,dtype='float32',always_2d=True)
    measured = integrated(ogg)
    if rate!=RATE or final.shape!=audio.shape or abs(measured-target)>.4:
        raise RuntimeError(f'{name}: codec output failed timing or gain check')
    ogg.replace(OUTPUT/ogg.name)
    print(f'{name}: {len(final)/RATE:.2f}s, {measured:.1f} LUFS, '
          f'{20*np.log10(np.max(np.abs(final))):.1f} dBFS decoded sample peak',flush=True)



def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument('items',nargs='*',help='Song names or sfx; default is everything')
    args = parser.parse_args()
    names = args.items or ['sfx',*SONGS]
    OUTPUT.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='.undertow-fm-',dir=OUTPUT) as temp:
        for n in names:
            if n=='sfx':
                for name in EFFECTS:
                    wavfile.write(OUTPUT/(name+'.wav'),RATE,pcm(effect(name)))
                print(f'Printed {len(EFFECTS)} action effects and radio cues',flush=True)
            elif n in SONGS:
                produce_music(n,Path(temp))
            else:
                parser.error(f'Unknown track {n}')


if __name__ == '__main__':
    main()
