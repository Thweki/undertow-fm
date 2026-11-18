"""Upper decks, maintenance galleries and roof runs of the storm harbour."""
from paint import *
from details import pipe,fan,drum,poster,brick,reel
PALS={
  1:('#263746','#bc927e'),3:('#1e3348','#86a49d'),4:('#25364c','#81918e'),
  6:('#284354','#81adad'),7:('#1a3346','#91a2a4'),9:('#323b50','#afb3a0'),
 10:('#263e4c','#8f9c91'),12:('#233449','#a49da1'),13:('#25384c','#ab98a3'),15:('#354050','#d6a68a')
}
def girder(a,x,y,w,col,ht=10):
    a.box(x,y,w,ht,col);a.box(x,y-1,w,2,mix(col,bone,.23));a.box(x,y+ht-2,w,3,mix(col,ink,.45))
    rivets(a,x+5,y+4,w-5,21,mix(col,bone,.31))
def brickwall(a,x,y,w,h,c):
    a.box(x,y,w,h,c)
    for j,Y in enumerate(range(y+8,y+h,10)):
        a.box(x,Y,w,1,mix(c,ink,.21))
        for xx in range(x+(j%2)*12,x+w-2,24):a.box(xx,Y-8,1,8,mix(c,ink,.18))
    girder(a,x-3,y-3,w+6,mix(c,ink,.15),5)
def window(a,x,y,w,h,c,l):
    a.box(x-2,y-2,w+4,h+4,'#2c404c');a.box(x,y,w,h,c)
    a.box(x+2,y+2,w//3,h-3,l);a.box(x+w//2,y,2,h,'#48616a');a.box(x,y+h//2,w,2,'#49606a')
    a.box(x-3,y+h,w+6,2,mix(c,bone,.48))
def sky(a,c0,c1,mode):
    haze(a,c0,c1,0,300,4);clouds(a,[mix(c0,c1,.22),mix(c0,c1,.34),mix(c0,c1,.48)])
    skyline(a,187,mix(c0,c1,.51),mix(c0,c1,.8))
    for x in [87,437,705]:derrick(a,x,204,.63,mix(c0,c1,.41),mix(c0,c1,.65))
    skyline(a,226,mix(c0,c1,.34),mix(c0,c1,.76))
    haze(a,mix(c0,c1,.43),mix(c0,ink,.5),225,360,7)
    a.dots(825,(0,229,a.w,128),[mix(c0,c1,.43),mix(c0,c1,.31),mix(c0,c1,.26)],widths=(2,5,11,21))
def roofs(a,ch):
    for i,(x,y,w) in enumerate([(-51,199,211),(176,244,130),(319,185,203),(553,230,116),(685,173,188)]):
        col='#526366' if ch==13 else '#615d5b'
        brickwall(a,x,y,w,365-y,col)
        a.p([(x-9,y),(x+22,y-12),(x+w-24,y-16),(x+w+8,y-3),(x+w+4,y+2),(x-8,y+3)],'#40515b')
        a.l([(x-9,y),(x+22,y-13),(x+w-23,y-17)],'#929388',2)
        for j in range(x+12,x+w-21,37):
            for k in range(y+19,340,41):window(a,j,k,18,25,'#778682','#a1a08c' if j%2==0 else '#89998c')
        pipe(a,[(x+w-7,340),(x+w-7,y+17),(x+w-15,y+10)],'#7a8277',3)
        if i%2: dish(a,x+w*.6,y-11,.55)
        elif ch==1:
            awning(a,x+3,y+69,w-13,'#8d7568','#9e9680')
        if i in [0,2]:a.cable(x+w-5,y-8,x+w+136,y+54,18,'#43575d')
    if ch==13:
        for x in [31,214,463]:
            a.cable(x,90,x+145,134,13,'#4c5d65')
            for k in range(4):
                xx=x+41+k*18;yy=110+k*4;a.p([(xx,yy),(xx+12,yy+3),(xx+9,yy+20),(xx-2,yy+17)],['#7c8281','#98827e','#838e86'][k%3])
    else:
        for x in range(49,720,167):
            a.l([(x,147),(x,180)],'#516768');a.e(x-5,177,11,17,'#9b7562');a.box(x-2,179,4,12,'#c89d73')
        a.cable(-20,135,800,126,26,'#455a60',2)
def train(a):
    for x in [-30,173,376,579]:
        # An elevated electric train and its lit passenger compartments.
        a.p([(x,195),(x+7,185),(x+188,185),(x+198,191),(x+198,236),(x+190,242),(x+5,242),(x,237)],'#6a7a77')
        a.box(x+2,223,194,7,'#8e7969')
        for j in range(10):window(a,x+8+j*18,196,13,16,'#899c8c','#b3ad85')
        a.box(x+4,235,192,5,'#425660');a.e(x+17,237,19,10,'#334954');a.e(x+160,237,19,10,'#334954')
    girder(a,0,246,770,'#495c60',7)
    for x in [70,304,549,743]:
        a.box(x,255,19,106,'#4c6367');a.p([(x,272),(x-22,254),(x+39,254),(x+18,272)],'#647875')
        a.box(x,129,3,54,'#435c61');a.l([(x,134),(x+51,134),(x+49,136)],'#54686a',2)
    a.cable(-50,115,328,117,17,'#566a6a');a.cable(328,117,790,112,18,'#566a6a')
def bridge(a):
    for x in [-68,146,360,574]:
        a.p([(x,20),(x+12,20),(x+213,272),(x+200,272)],'#43565e')
        a.p([(x+200,20),(x+213,20),(x+15,272),(x,272)],'#56696a')
        a.l([(x+202,20),(x+2,272)],'#7a8380')
        for j in range(3):rivets(a,x+3+j*64,106+j*42,18,6,'#758481')
    girder(a,0,56,768,'#495d62',14);girder(a,0,260,768,'#4a5f63',13)
    for x in [46,408,694]:
        a.box(x,267,22,100,'#617373');a.box(x-7,267,37,13,'#73817c')
        a.cable(x,55,x+164,55,86,'#4a6166',2)
def machinery(a,ch):
    # Open clerestories reveal portions of the night beyond the plant.
    for i,x in enumerate(range(-12,768,130)):
        brickwall(a,x,168,129,194,'#506569')
        for k in range(3):window(a,x+11+k*38,180,28,24,'#7a8f8a','#a0ab95')
        a.box(x,68,9,288,'#445961');a.box(x,68,2,280,'#7c908b')
        girder(a,x,67,132,'#4c6269',9);a.l([(x+6,99),(x+45,76)],'#5f7678',4)
        if ch==6:
            box3(a,x+11,241,95,63,'#657d7a',5);fan(a,x+37,269,20);fan(a,x+82,269,20)
            a.box(x+16,234,80,5,'#a1afa1')
            for j in range(4):a.p([(x+18+j*19,237),(x+23+j*19,237),(x+20+j*19,251-j%2*3)],'#9fb6ae')
            pipe(a,[(x+15,360),(x+15,310),(x+39,310)],'#83998b',6)
        elif ch==10:
            wheel(a,x+61,258,38,'#9b9075','#526b6c')
            for j in range(3):
                t=math.pi*j/3+.34
                a.l([(x+61+28*math.cos(t),258+28*math.sin(t)),(x+61-28*math.cos(t),258-28*math.sin(t))],'#9c9278',3)
            pipe(a,[(x-10,299),(x+6,299),(x+17,289),(x+106,289),(x+124,308),(x+124,338)],'#819083',8)
            gauge(a,x+113,271,8)
        else:
            for k in [19,53,88]:
                insulator(a,x+k,263,43);a.cable(x+k,218,x+k+34,218,10,'#42565d',2)
            box3(a,x+6,265,112,51,'#697d75',5);vents(a,x+12,271,45,33)
            stripe(a,x+73,278,35,11,'#a99872','#526466')
def shipdeck(a):
    ship(a,133,232,1.71,'#3e5864');ship(a,-220,269,1.15,'#4b626a')
    for x in [-64,506,679]:derrick(a,x,307,1.54,'#4d6871','#89958b')
    for x in range(0,768,76):container(a,x,312,74,29,'#6b736a' if x%152==0 else '#766860')
def measure(a):
    for x in [-40,193,432,679]:
        a.box(x,194,100,165,'#526a6a');a.p([(x-9,194),(x+6,182),(x+74,182),(x+108,194)],'#748782')
        window(a,x+8,207,43,30,'#738b86','#a4b49a')
        a.box(x+68,111,12,161,'#b3ad89')
        for j in range(28):a.box(x+68,115+j*5,7 if j%4==0 else 4,1,'#596e6b')
        a.p([(x+57,194),(x+65,191),(x+67,194),(x+61,197)],'#b27e69')
        girder(a,x+7,255,74,'#829184',6)
def towerfield(a):
    for x,h in [(69,277),(320,317),(611,289),(802,278)]:
        tower(a,x,340,h,'#51636c','#8c9087')
        a.cable(x,340-h*.83,x+180,275,17,'#6b7374')
        a.cable(x,340-h*.63,x-136,303,18,'#657073')
    for x in [4,246,552]:dish(a,x,311,1.2);girder(a,x-19,312,70,'#697a79',8)
def main():
    from details import gauge
    globals()['gauge']=gauge
    for ch,(c0,c1) in PALS.items():
        a=Art(768,360,1620+ch)
        sky(a,c0,c1,ch)
        if ch in [1,13]:roofs(a,ch)
        elif ch==3:train(a)
        elif ch==4:bridge(a)
        elif ch in [6,10,12]:machinery(a,ch)
        elif ch==7:shipdeck(a)
        elif ch==9:measure(a)
        else:towerfield(a)
        # Recede the entire panorama behind the sharply inked playable plane.
        veil=Image.new('RGBA',a.im.size,(*rgb('#1d3446'),75))
        a.im=Image.alpha_composite(a.im,veil)
        a.save('height_%02d'%ch)
if __name__=='__main__':main()
