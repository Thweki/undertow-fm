"""The five historical coast locations; original pre-flood streets and interiors."""
from paint import *
from details import pipe,drum,reel,gauge,poster,bike,brick,fan
from heights import brickwall,window,girder
N='#213537'; B='#334746'; T='#4c6860'; A='#758c77'; Y='#c9b58a'; G='#b4cf93'; L='#d3d4a0'
def lettering(a,x,y,w,h,c,title,sub):
    a.box(x-3,y-3,w+6,h+7,N);a.box(x,y,w,h,c);a.box(x+1,y+1,w-2,1,mix(c,L,.5))
    a.box(x+1,y+h-2,w-2,1,mix(c,N,.35))
    a.text(x+8,y+5,title,L,15)
    a.text(x+9,y+h-9,sub,mix(c,L,.79),7,bold=True)
    for X in [x+3,x+w-5]:a.box(X,y+3,2,1,L)
def cellar_door(a,x,y,w,h):
    a.box(x-2,y-2,w+4,h+4,N);a.box(x,y,w,h,'#657767')
    for xx in range(x+4,x+w-2,6):
        a.box(xx,y+1,1,h-3,'#435a52')
    for yy in [y+4,y+h*.64]:a.box(x+2,yy,w-4,3,'#8c9378')
    a.box(x+w-9,y+h*.45,4,2,L)
def booth(a,x,y):
    # Cast-metal green public telephone cabin. A visible receiver sits inside.
    a.box(x+1,y+10,44,89,N);a.box(x+3,y+12,40,84,'#54735e')
    a.box(x+7,y+25,28,65,'#749486');a.box(x+10,y+28,22,55,'#526d60')
    a.box(x+11,y+30,10,34,'#9aa78d');a.p([(x+6,y+88),(x+33,y+88),(x+33,y+93),(x+4,y+93)],'#9aa18a')
    a.box(x+13,y+47,16,23,'#aab297');a.box(x+15,y+50,11,8,'#536a58')
    for k in range(3):a.box(x+17+k*3,y+61,2,3,'#7f8e73')
    a.l([(x+14,y+50),(x+11,y+51),(x+11,y+62),(x+14,y+64)],N,3);a.cable(x+12,y+64,x+19,y+69,7,'#344e47')
    a.box(x+32,y+25,2,65,'#bcc1a0')
    a.box(x-2,y+1,48,12,N);a.box(x,y+3,44,8,'#a7be91')
    a.text(x+4,y+3,'TELEPHONE','#395345',7,bold=True)
    a.p([(x-4,y+1),(x+3,y-6),(x+40,y-7),(x+49,y),(x+48,y+2)],'#69826a')
    a.box(x-4,y+97,53,4,'#82917a')
def sack(a,x,y):
    a.p([(x,y),(x+5,y-8),(x+25,y-8),(x+32,y-4),(x+33,y+3),(x+29,y+5),(x+2,y+5)],'#aaa588')
    a.l([(x+3,y+3),(x+14,y+4),(x+30,y+2)],'#777e69')
    a.l([(x+8,y-5),(x+21,y-6)],'#d1c7a3');a.box(x+15,y-3,4,4,'#7e876d')
def salt_shop():
    a=Art(seed=121)
    # Original town shop, beside the old switchboard, smoking sheds and tide wall.
    for x,y,w in [(-51,116,263),(282,95,354),(720,125,272),(1056,97,260)]:
        brickwall(a,x,y,w,247-y,'#747d69')
        a.p([(x-11,y),(x+24,y-22),(x+w-36,y-26),(x+w+13,y-2),(x+w+9,y+5),(x-10,y+6)],'#4f6055')
        for xx in range(x-3,x+w-8,13):
            a.l([(xx+15,y-17),(xx,y+1)],'#76826d')
        a.l([(x-9,y+1),(x+w+10,y-2)],'#a5ac8a',2)
        cellar_door(a,x+19,183,48,61)
        a.box(x+78,y+44,w-89,96,'#40584d')
        for xx in range(x+82,x+w-23,33):window(a,xx,y+52,29,39,'#8b957a','#c2b788')
        awning(a,x+73,y+99,w-83,'#839776','#a5a183')
        a.box(x+74,229,w-83,16,'#617a63')
        for k in range(5):sack(a,x+79+k*29,231-k%2*3)
        if w>300:lettering(a,x+70,y+5,175,36,'#466955','广顺海盐行','KUANG SHUN   /   SEA SALT')
        else:lettering(a,x+70,y+5,135,35,'#556c54','海岸供销社','COASTAL SUPPLY  ·  1968')
        for i in range(3):sack(a,x+4+i*25,239)
        poster(a,x+w-24,y+50,13,20,'#b8b791')
    for x in [209,644,1000]:booth(a,x,145)
    for x in [181,592,954]:bike(a,x,246,.74)
    a.cable(-18,65,433,75,42,B,2);a.cable(433,75,854,48,38,B,2);a.cable(854,48,1310,79,51,B,2)
    return a
def yard():
    a=Art(seed=122)
    # A corrugated open shed with a wooden vessel suspended between cradle frames.
    for x in [-40,480,1000]:
        a.p([(x-18,85),(x+82,58),(x+382,53),(x+475,79),(x+471,85),(x-18,93)],'#697969')
        for xx in range(x+7,x+443,17):
            a.l([(xx+33,65),(xx,85)],'#83917a')
        a.l([(x-17,91),(x+466,82)],'#a0a487',2)
        girder(a,x-8,90,487,'#405951',8)
        for xx in [x+9,x+188,x+446]:
            a.box(xx,94,9,152,'#425c51');a.box(xx,96,2,147,'#8e9a7e')
            a.l([(xx+2,122),(xx+40,98)],'#6b8168',5)
        a.box(x+58,99,2,31,'#465b51');lamp(a,x+59,136,False)
        a.box(x+310,98,2,28,'#465b51');lamp(a,x+311,131,False)
        # Hull under repair: planked strakes, ribs, propeller, scaffolds.
        points=[(x+55,167),(x+153,179),(x+251,175),(x+349,164),(x+413,139),(x+396,177),(x+358,197),(x+290,213),(x+151,213),(x+78,190)]
        a.p(points,'#786f58')
        a.l(points[:5],'#b6ac83',3)
        for k in range(4):
            a.l([(x+73+k*4,176+k*4),(x+144,187+k*6),(x+259,185+k*6),(x+353,173+k*5),(x+396-k*5,151+k*6)],'#a29571')
        for xx in range(x+93,x+377,39):a.l([(xx,181),(xx+4,199)],'#4c5c4e',2)
        for xx in [x+117,x+303]:
            a.l([(xx-14,243),(xx,208),(xx+17,243)],'#465848',6);a.box(xx-11,211,24,3,'#8e9478')
        for xx in [x+48,x+238]:
            railing(a,xx,193,78,'#637b68');girder(a,xx-3,216,84,'#657b68',4)
            a.l([(xx+4,220),(xx+54,243)],T,3);a.l([(xx+75,219),(xx+21,243)],T,3)
        reel(a,x+378,233,11)
        a.l([(x+181,95),(x+181,139),(x+175,145)],'#7b8b73',2)
        a.l([(x+176,146),(x+171,149),(x+176,151),(x+181,147)],'#b5aa7e',2)
    lettering(a,194,88,132,34,'#526e59','合丰船舶修造','WOOD HULL   /   SLIPWAY')
    lettering(a,826,83,124,34,'#64735b','轮机工场','SHIPYARD  /  WEST')
    return a
def arch_window(a,x,y,w,h):
    # Underground water-level well visible behind a glass window.
    a.box(x-4,y-4,w+8,h+8,N);a.box(x,y,w,h,'#7ea396')
    for j in range(0,h,5):a.box(x,y+j,w,5,mix('#adb6a1','#4d8982',j/h))
    level=y+int(h*.48)
    a.box(x,level,w,h-(level-y),'#447770')
    for j in range(42):
        xx=a.r.randrange(x+2,x+w-6);yy=a.r.randrange(level+1,y+h);a.box(xx,yy,min(a.r.randrange(2,13),x+w-xx),1,a.r.choice(['#709387','#63897e']))
    a.box(x+9,y+3,10,h-6,'#c4bf94')
    for i in range((h-7)//4):a.box(x+10,y+5+i*4,6 if i%5==0 else 3,1,'#576e61')
    a.l([(x+1,level),(x+w-1,level)],'#c1ccb2',2)
    a.l([(x+33,y+2),(x+7,y+34)],'#c2cbbb',2);a.l([(x+w-4,y+8),(x+w-22,y+29)],'#98b7a6',2)
    a.box(x+w//2,y,4,h,'#546e64');a.box(x+w//2,y,1,h,'#a7b198')
def basement(a,mode):
    for x in [-15,201,417,633,849,1065]:
        brickwall(a,x,53,217,193,'#667669' if mode==2 else '#747b6b')
        # Masonry extends up to an open grated roof. The thin unpainted strip lets
        # the horizon's weather through vents, while the room reads as an interior.
        a.p([(x-3,53),(x+11,27),(x+36,21),(x+191,20),(x+215,34),(x+223,55)],'#55695c')
        girder(a,x-2,48,220,'#41574e',7)
        for i in range(7):a.box(x+22+i*23,35,17,5,'#7e8b72')
        a.box(x+4,54,8,193,'#405950');a.box(x+4,54,2,193,'#919d7e')
        a.box(x+9,55,3,8,'#536658');a.box(x+11,61,20,3,'#637565')
        a.box(x+37,64,130,2,'#3f574e');a.box(x+39,66,126,2,'#bbcd9e')
def tide_well():
    a=Art(seed=123);basement(a,2)
    for k,x in enumerate([23,246,466,677,896,1116]):
        arch_window(a,x,87,116,105)
        box3(a,x+130,110,35,77,'#627c68');gauge(a,x+149,132,12)
        for j in range(6):a.box(x+137,153+j*4,14+j%3,1,'#9bab8b')
        pipe(a,[(x-12,201),(x+62,201),(x+68,207),(x+121,207),(x+125,212),(x+125,242)],'#89a18c',4)
        if k%2==0:
            lettering(a,x+9,204,108,32,'#456d60','潮井观测室','WATER TABLE  ·  No. 3')
        else:wheel(a,x+156,209,13,'#b29671','#577365')
        railing(a,x-2,219,118,'#526d60')
    return a
def controls():
    a=Art(seed=124);basement(a,3)
    for k,x in enumerate([-6,257,520,783,1046]):
        box3(a,x+9,90,234,151,'#728573',7)
        a.box(x+13,95,226,16,'#496756');a.text(x+19,99,['TURBINE  /  No. 2','COAST GRID   ·   110','MAIN BUS   /   A'][k%3],'#d2d1a2',9,bold=True)
        for j in range(4):
            xx=x+17+j*53
            a.box(xx,116,46,42,'#415b50');gauge(a,xx+23,135,14)
            a.box(xx+10,152,26,2,'#bdc097');a.box(xx+5,163,35,14,'#384f47')
            for n in range(4):a.box(xx+8+n*8,166,5,5,['#a58a67','#b4be8a','#759e83','#bea37e'][(j+n+k)%4])
            a.box(xx+8,173,24,1,'#80927b')
        # Battered U-shaped console with individual faders and handwritten strips.
        a.p([(x+7,199),(x+18,181),(x+230,181),(x+246,199)],'#a2a78a')
        a.box(x+7,200,240,8,'#567061');a.box(x+15,208,222,30,'#647c69')
        for j in range(25):
            xx=x+20+j*8;yy=187+(j%3);a.l([(xx,185),(xx-2,196)],'#516457');a.box(xx-3,yy,5,2,'#d0c9a1')
        for j in range(6):a.box(x+22+j*34,216,19,8,'#4b6658')
        if k%2:lamp(a,x+116,84,False)
    return a
def radio_house():
    a=Art(seed=125)
    for k,(x,y,w) in enumerate([(-58,126,319),(311,102,379),(771,129,249),(1086,96,272)]):
        brickwall(a,x,y,w,247-y,'#657b68')
        a.p([(x-11,y),(x+14,y-15),(x+w-27,y-22),(x+w+9,y-4),(x+w+10,y+2),(x-10,y+7)],'#465e52')
        for xx in range(x+4,x+w-16,14):a.l([(xx+12,y-13),(xx,y+2)],'#81927b')
        girder(a,x-8,y+2,w+15,'#60785f',4)
        cellar_door(a,x+15,167,43,77)
        a.box(x+70,y+38,w-83,80,N)
        for xx in range(x+75,x+w-37,35):window(a,xx,y+42,29,51,'#829780','#bcc19a')
        # Studio master clock, reel-to-reel tape recorders and microphones in window.
        box3(a,x+88,215,41,26,'#596f5e',4)
        for xx in [x+97,x+117]:reel(a,xx,223,6)
        pipe(a,[(x+153,233),(x+153,216),(x+161,207)],'#687e69',2)
        a.e(x+159,200,7,13,'#9eaa90');a.box(x+158,232,15,2,'#3e574d')
        lettering(a,x+74,y+6,min(w-97,171),32,'#426d55',['渔港公共广播','滨海中波台','渔汛值班室','海岸总机房'][k],'PUBLIC  /  COAST RADIO')
        for xx in [x+31,x+w-39]:
            a.box(xx,y-55,3,52,'#465e55')
            for j in [0,1,2]:a.l([(xx-12+j*2,y-48+j*10),(xx+13-j*2,y-50+j*10)],'#829580',2)
    for x,h in [(77,118),(451,135),(855,104),(1224,125)]:
        a.box(x,63,6,183,'#607562')
        for j in [0,1]:
            a.box(x-20,59+j*12,46,4,'#687b65')
            for xx in [x-15,x+16]:a.box(xx,54+j*12,5,6,'#999e81')
        a.cable(x+18,55,x+375,67,23,'#526859',2);a.cable(x-11,66,x+352,57,32,'#5e7261')
    return a
if __name__=='__main__':
    for i,fn in enumerate([salt_shop,yard,tide_well,controls,radio_house]):
        art=fn();art.save('past_%d'%i)
