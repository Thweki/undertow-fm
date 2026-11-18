"""Street dressing pass: hand-placed, district-specific objects on the shopfront plane."""
from paint import *
def pipe(a,coords,c,w=4):
    a.l(coords,'#243d46',w+2)
    a.l(coords,c,w)
    a.l([(x-1,y-1) for x,y in coords],mix(c,bone,.37))
def drum(a,x,y,c):
    a.e(x,y+13,15,5,'#2a424b');a.box(x,y+2,15,13,c);a.e(x,y,15,5,mix(c,bone,.28))
    a.box(x+2,y+7,11,1,mix(c,ink,.45));a.box(x+1,y+12,13,1,mix(c,ink,.45));a.box(x+2,y+5,2,8,mix(c,bone,.24))
def reel(a,x,y,r):
    a.e(x-r-2,y-r,2*r+4,2*r+1,'#253e47');a.e(x-r,y-r,2*r,2*r,'#9a9379')
    a.e(x-r+2,y-r+2,2*r-4,2*r-4,'#6e786b')
    for k in range(5):
        t=k*math.tau/5;X=x+r*.5*math.cos(t);Y=y+r*.5*math.sin(t)
        a.e(X-2,Y-2,4,4,'#384e50')
    a.e(x-2,y-2,4,4,'#2b434b')
def gauge(a,x,y,r):
    a.e(x-r-1,y-r-1,2*r+3,2*r+3,'#2d4146');a.e(x-r,y-r,2*r+1,2*r+1,'#c5b78e')
    a.l([(x,y),(x+r*.49,y-r*.64)],'#805e52');a.box(x,y,1,1,ink)
def poster(a,x,y,w,h,c):
    a.p([(x,y),(x+w,y+1),(x+w-1,y+h),(x+w-6,y+h-1),(x+w-9,y+h),(x+1,y+h)],c)
    a.box(x+2,y+3,w-4,3,mix(c,ink,.48))
    a.p([(x+3,y+h-6),(x+w//2,y+8),(x+w-3,y+h-6)],mix(c,ink,.3))
    a.box(x+3,y+h-3,w-7,1,mix(c,ink,.54));a.box(x+1,y+1,2,1,mix(c,bone,.47))
def bike(a,x,y,s=.8):
    def v(X,Y):return (x+X*s,y+Y*s)
    for X in [0,29]:
        a.d.ellipse([v(X-9,-18),v(X+9,0)],outline='#243d46',width=2)
        a.d.ellipse([v(X-6,-15),v(X+6,-3)],outline='#9aa794',width=1)
    a.l([v(0,-8),v(9,-23),v(15,-9),v(0,-8),v(20,-24),v(24,-26),v(29,-8)],'#b68a6c',2)
    a.l([v(11,-25),v(6,-25)],ink,2);a.l([v(22,-26),v(24,-30),v(28,-30)],'#87938c',2)
def compressor(a,x,y):
    a.e(x,y-20,39,19,'#607e73');a.box(x+9,y-21,19,19,'#607e73')
    a.box(x+5,y-17,26,2,'#9db09a');a.box(x+7,y-5,2,6,ink);a.box(x+29,y-5,2,6,ink)
    box3(a,x+7,y-29,19,10,'#414f54',3)
    for i in range(4):a.box(x+9+i*4,y-30,1,9,'#9ba391')
    gauge(a,x+33,y-24,4)
def fan(a,x,y,r):
    a.e(x-r,y-r,2*r,2*r,'#56696b');a.e(x-r+2,y-r+2,2*r-4,2*r-4,'#283e49')
    for i in range(4):
        t=i*math.pi/2+0.1
        a.p([(x,y),(x+r*.75*math.cos(t),y+r*.75*math.sin(t)),(x+r*.83*math.cos(t+.55),y+r*.83*math.sin(t+.55)),(x+r*.3*math.cos(t+1),y+r*.3*math.sin(t+1))],'#889a8f')
    a.e(x-2,y-2,4,4,'#c1c0ac')
def brick(a,x,y,w,h,seed=22):
    # A few exposed patches of brick, peeled enamel, and one rust stain.
    r=random.Random(seed)
    for j in range(3):
        yy=y+j*4
        for i in range(4-j):
            xx=x+j*3+i*9
            a.box(xx,yy,7,2,r.choice(['#74685f','#8c7d69','#717774']))
def workshop(a):
    # Different trades share this row. The first bay is the radio technician's.
    for i,x in enumerate([93,507,963]):
        # Shadow and ceiling lip; shelf recess with tools at differing heights.
        a.box(x,174,130,12,'#635e4e');a.box(x+4,175,116,2,'#8c7d61')
        for j in range(9):
            xx=x+7+j*13;yy=179+(j%3)
            if j%3==0:
                a.l([(xx,yy+6),(xx+4,yy),(xx+2,yy-3)],'#a8a086',2)
                a.box(xx+5,yy-2,2,3,'#ad9f7f')
            elif j%3==1:
                a.l([(xx+1,yy+7),(xx+1,yy-2)],'#b9ae88');a.box(xx,yy-2,4,3,'#916e55')
            else:
                a.e(xx,yy-2,4,5,'#b2a384');a.box(xx+1,yy,2,2,'#625948');a.box(xx+1,yy+4,2,5,'#958b70')
        # Oscilloscopes, valves and illuminated pressure gauges on the benchtop.
        box3(a,x+6,202,38,15,'#58665d',4)
        a.box(x+10,205,20,9,'#283f43');a.box(x+12,206,15,6,'#89a48c')
        a.l([(x+13,209),(x+16,209),(x+17,207),(x+18,211),(x+20,208),(x+23,209),(x+26,209)],'#496b64')
        for m in [0,1,2]:a.box(x+32+m*3,205,2,3,'#c5b98a')
        for k in [0,1,2]:
            gauge(a,x+62+k*12,205,4)
            a.box(x+59+k*12,211,6,3,'#3d4d48')
        a.cable(x+4,216,x+38,215,9,'#34484c',2)
        a.box(x+99,198,18,17,'#374c4d');fan(a,x+108,206,6)
        # Loose coax runs down a pilaster and loops above a low distribution box.
        xx=x-12
        pipe(a,[(xx,173),(xx+3,176),(xx+3,203),(xx-3,209),(xx-3,222)],'#66796b',2)
        box3(a,xx-6,221,10,13,'#657369',3);a.box(xx-3,224,5,3,'#c8b47d')
    # Highlighted foreground props are limited to curb height.
    compressor(a,257,240);reel(a,307,232,10)
    reel(a,653,231,12);reel(a,677,234,9)
    bike(a,950,242,.88)
    for x in [53,487,938]:
        poster(a,x,199,13,18,'#aca584');a.box(x+1,211,9,2,'#7a6253')
    for x in [36,577,963]:
        a.box(x,50,22,23,'#364e58');fan(a,x+10,60,8)
        pipe(a,[(x+22,66),(x+33,66),(x+37,70),(x+37,77)],'#607578',3)
    # Cable reels and enamel sign distinguish the neighboring window.
    a.box(514,100,137,20,'#405451');a.text(521,103,'COASTAL WIRE','#d6c594',13,bold=True)
    a.box(987,100,138,20,'#405451');a.text(991,103,'MARINE ELECTRIC','#d9c995',13,bold=True)
def market(a):
    # A balance scale and fresh ice stand next to an improvised soup counter.
    for x,y in [(21,223),(417,223),(1042,224)]:
        a.box(x-2,y-21,3,20,'#737f72');a.l([(x-13,y-18),(x+13,y-18)],'#c5b28c',2)
        for xx in [x-9,x+9]:
            a.l([(xx,y-17),(xx-5,y-5),(xx+5,y-5),(xx,y-17)],'#859485')
            a.p([(xx-6,y-5),(xx+6,y-5),(xx+3,y-2),(xx-3,y-2)],'#c4bba0')
        a.box(x-4,y-1,8,3,'#566c65')
    for x in [172,847]:
        a.e(x,212,22,8,'#c9b899');a.box(x,215,22,10,'#828d80');a.e(x,221,22,6,'#778579')
        a.box(x+1,215,20,2,'#b9ba9d');a.e(x+2,211,18,5,'#a6a890');a.box(x+8,209,5,3,'#706f60')
        for i in range(3):
            a.e(x+26+i*8,222,7,4,'#a0ad91');a.box(x+27+i*8,225,5,1,'#657f74')
    for x in [280,681]:
        drum(a,x,225,'#7c8272');drum(a,x+16,226,'#6e8278')
        a.box(x-2,220,15,2,'#627c72');a.box(x-1,217,12,4,'#a2a685')
    bike(a,713,245,.83);bike(a,1132,245,.76)
    poster(a,535,124,14,21,'#bbb18e');poster(a,575,125,10,18,'#9a9f86')
    for x,y in [(140,67),(546,50),(803,80)]:
        box3(a,x,y,20,15,'#72837a',4);fan(a,x+10,y+7,5)
        pipe(a,[(x+19,y+10),(x+31,y+10),(x+34,y+15),(x+34,y+28)],'#627973',2)
    # Uneven grocery banners, dried kelp and rain cords under the eaves.
    for x,y in [(228,192),(628,187),(899,197)]:
        for i in range(7):
            xx=x+i*6;yy=y+(i%3)*2
            a.l([(xx,y-4),(xx,yy+4)],'#4e6157')
            a.p([(xx-1,yy+2),(xx+1,yy+1),(xx+2,yy+10),(xx-1,yy+15),(xx-2,yy+11)],['#6c7154','#89825c','#546e60'][i%3])
    # Few handwritten specials.
    for x in [69,445,1188]:
        a.box(x,211,15,10,'#e0c49a');a.box(x+1,212,13,1,'#9c7a61');a.text(x+2,214,'28','#825f51',7,bold=True)
def docks(a):
    for x in [81,397,1135]:
        a.box(x+56,219,24,15,'#909586');a.box(x+58,221,19,2,'#475e63')
        for i in [0,1,2,3]:a.box(x+58,225+i*2,14-i*2,1,'#687b76')
    for x in [9,508,1180]:
        for i in range(4):
            xx=x+i*6
            a.l([(xx,207),(xx,213+i%3*2),(xx+1,214+i%3*2)],'#8c7c68')
    # Portable work-light trailer, fire cabinet and dockside bollard drums.
    for x in [236,847]:
        box3(a,x,221,36,17,'#69796e',5)
        a.box(x+3,224,18,9,'#293f49')
        for j in range(3):a.box(x+4,225+j*3,16,1,'#899582')
        a.e(x+2,235,8,8,'#203641');a.e(x+25,235,8,8,'#203641')
        pipe(a,[(x+31,221),(x+31,191),(x+24,185)],'#657e7b',2)
        a.p([(x+16,184),(x+22,179),(x+30,183),(x+24,189)],'#2d4854')
        a.l([(x+18,184),(x+24,187)],'#d6c799',2)
    for x in [339,917]:
        reel(a,x,229,14);reel(a,x+21,234,8)
    for x in [596,1230]:
        drum(a,x,224,'#8f7061');drum(a,x+13,228,'#647d74')
def tower(a):
    for x,y in [(310,148),(777,162),(1210,148)]:
        pipe(a,[(x+4,y+49),(x+4,y+57),(x+21,y+57),(x+26,y+62),(x+26,238)],'#718781',4)
        for j in range(3):
            a.box(x+75+j*13,y+30,10,6,'#314c56');a.box(x+76+j*13,y+31,4,2,'#c5ab77')
        poster(a,x+153,y+46,14,23,'#b8ac86');brick(a,x+35,y+63,34,14)
    for x in [45,343,825]:
        drum(a,x,227,'#6c817a');a.box(x-4,218,6,22,'#4e6467');a.box(x-5,221,8,4,'#9b7c68')
    for x in [201,643,1052]:
        box3(a,x,230,20,12,'#6a8178',5);a.box(x+2,232,16,3,'#b8b28d')
        a.cable(x+5,228,x-10,205,11,'#314955',2)
    bike(a,537,244,.8)
def apply(a,kind):
    return {'workshop':workshop,'market':market,'docks':docks,'tower':tower}[kind](a)
