"""Original, deterministic pixel artwork for Undertow FM. Rebuild with Pillow."""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
import math, random

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/"assets/world"
HERE=Path(__file__).parent
W,H=1280,360
ink="#0e1b2b"; deep="#142737"; steel="#365262"; wet="#365866"; jade="#6caba7"; ice="#add7c5"
amber="#e8a65f"; gold="#f5cd81"; coral="#d46d54"; rust="#9b5651"; bone="#dcd9b0"
def rgb(c):return tuple(bytes.fromhex(c.lstrip("#")))
def mix(a,b,t):
    if isinstance(a,str):a=rgb(a)
    if isinstance(b,str):b=rgb(b)
    return tuple(int(x+(y-x)*t) for x,y in zip(a,b))
class Art:
    def __init__(self,w=W,h=H,seed=0,bg=None):
        self.im=Image.new("RGBA",(w,h),bg);self.d=ImageDraw.Draw(self.im);self.r=random.Random(seed);self.w=w;self.h=h
    def p(self,pts,c):self.d.polygon([(round(x),round(y)) for x,y in pts],fill=c)
    def l(self,pts,c,w=1):self.d.line([(round(x),round(y)) for x,y in pts],fill=c,width=w)
    def box(self,x,y,w,h,c):
        if w>0 and h>0:self.d.rectangle((int(x),int(y),int(x+w-1),int(y+h-1)),fill=c)
    def e(self,x,y,w,h,c):self.d.ellipse((int(x),int(y),int(x+w-1),int(y+h-1)),fill=c)
    def dots(self,n,area,colors,widths=(1,2,3),heights=(1,)):
        x,y,w,h=area
        for _ in range(n):self.box(self.r.randrange(x,x+w),self.r.randrange(y,y+h),self.r.choice(widths),self.r.choice(heights),self.r.choice(colors))
    def text(self,x,y,s,color,size=10,bold=False):
        path=ROOT/'assets/fonts/FusionPixel.ttf'
        face=ImageFont.truetype(str(path),size)
        mask=Image.new('L',(max(1,int(face.getlength(s))+5),size*2))
        ImageDraw.Draw(mask).text((1,0),s,font=face,fill=255,anchor="lt")
        mask=mask.point(lambda a:255 if a>=92 else 0)
        self.im.paste(color,(x,y,x+mask.width,y+mask.height),mask)
    def cable(self,x,y,x2,y2,sag,col=ink,w=1):
        self.l([(x+(x2-x)*i/72,y+(y2-y)*i/72+4*sag*(i/72)*(1-i/72)) for i in range(73)],col,w)
    def save(self,name):self.im.save(OUT/(name+".png"),optimize=True)
def haze(a,c0,c1,y0,y1,band=6):
    for y in range(y0,y1,band):a.box(0,y,a.w,band,mix(c0,c1,(y-y0)/(y1-y0)))

def clouds(a,cols):
    for k,c in enumerate(cols):
        for j in range(11):
            x=a.r.randrange(-240,a.w+30); y=a.r.randrange(-5,112)+k*2
            n=a.r.randrange(8,19)
            shape=[(x,y)]
            for i in range(n):
                x+=a.r.randrange(6,27);y-=a.r.randrange(-1,4);shape.extend([(x-3,y+2),(x,y)])
            shape.extend([(x+21,y+2),(x+7,y+4),(x+14,y+5)])
            for i in range(n):
                x-=a.r.randrange(6,22);y+=a.r.randrange(-2,4);shape.extend([(x,y+12),(x-5,y+12)])
            a.p(shape,c)
def skyline(a,ybase,c,light,scale=1):
    x=-20
    while x<a.w:
        w=a.r.randrange(10,49)*scale;h=a.r.randrange(13,53)*scale;y=ybase-h
        a.box(x,y,w,h,c);a.box(x+3*scale,y-3*scale,w-6*scale,4*scale,c)
        if a.r.random()<.45:a.box(x+w//3,y-8*scale,w//3,7*scale,c);a.l([(x+w//3+2,y-8*scale),(x+w//3+2,y-14*scale)],c)
        for i in range(x+4,x+w-1,6*scale):
            for j in range(y+6,ybase-2,7*scale):
                if a.r.random()<.16:a.box(i,j,2*scale,scale,light)
        x+=w+a.r.randrange(1,8)

def derrick(a,x,y,size,col,glint=None):
    def v(i,j):return x+i*size,y+j*size
    def draws(points,c,w=1):a.l([v(*p) for p in points],c,max(1,int(size*w)))
    draws([(0,0),(4,-122),(18,-122),(25,0)],col,4)
    for i in range(5):draws([(2,-i*23),(19-(i%2),-i*23-20),(3,-i*23-23)],col,2)
    draws([(-16,-96),(78,-142),(101,-153),(111,-147),(7,-89),(-16,-90),(-16,-96)],col,3)
    for i in range(8):draws([(-10+14*i,-96-7*i),(4+14*i,-95-7*i),(4+14*i,-103-7*i)],col)
    draws([(11,-120),(110,-148)],col)
    draws([(100,-143),(100,-65),(96,-63)],col)
    a.p([v(*p) for p in [(-9,-111),(7,-111),(7,-96),(-10,-96)]],col)
    if glint:draws([(7,-123),(12,-123)],glint,2)

def tower(a,x,bottom,height,col,highlight,beacon=True):
    base=height*.255
    def xat(t):return (1-t)**1.75*base*.51+1
    levels=[i/12 for i in range(13)]
    for t,T in zip(levels,levels[1:]):
        l=xat(t);u=xat(T);y=bottom-height*t;Y=bottom-height*T
        a.l([(x-l,y),(x-u,Y),(x+u,Y),(x+l,y)],col,max(1,round(3*height/220)))
        a.l([(x-l,y),(x+u,Y),(x+l,y)],col,max(1,round(height/160)))
        a.l([(x+l,y),(x-u,Y)],col,max(1,round(height/180)))
        if round(12*t)%2==0:a.l([(x-u,Y),(x+u,Y)],highlight)
    for t in [.34,.65,.8]:
        y=bottom-height*t;r=xat(t)+3;a.box(x-r,y,2*r+1,3,col)
    a.l([(x,bottom-height+2),(x,bottom-height-height*.08)],col,2)
    if beacon:a.box(x-1,bottom-height-height*.08,3,2,coral)
def city(kind):
    cfg={'workshop':('#17263d','#54797c'), 'market':('#32354a','#b38a78'),'docks':('#142e43','#70999a'),'tower':('#232e44','#a38a85')}[kind]
    a=Art(seed=111+list(stages).index(kind));haze(a,*cfg,0,235,5)
    clouds(a,[mix(*cfg,.21),mix(*cfg,.33),mix(*cfg,.52)])
    # Distant sea and skyline recede through the rain.
    skyline(a,177,mix(*cfg,.56),mix(*cfg,.91))
    for x in [82,349,700,1109]:derrick(a,x,186,a.r.uniform(.32,.65),mix(*cfg,.40),mix(*cfg,.94))
    for x,s in [(188,135),(920,124)]:tower(a,x,179,s,mix(*cfg,.36),mix(*cfg,.61))
    skyline(a,211,mix(*cfg,.28),mix(*cfg,.80))
    haze(a,mix(*cfg,.51),mix(*cfg,.19),208,360,4)
    a.dots(1100,(0,210,W,95),[mix(*cfg,.61),mix(*cfg,.42),mix(*cfg,.31)],widths=(2,5,9,18,25))
    return a

def box3(a,x,y,w,h,c,side=6):
    a.box(x,y,w,h,c);a.p([(x+w,y),(x+w+side,y-side*.6),(x+w+side,y+h-side*.6),(x+w,y+h)],mix(c,ink,.38))
    a.p([(x,y),(x+side,y-side*.6),(x+w+side,y-side*.6),(x+w,y)],mix(c,bone,.18))
    a.box(x,y,w,1,mix(c,bone,.29))
def vents(a,x,y,w,h):
    a.box(x-1,y-1,w+2,h+2,'#192c38');a.box(x,y,w,h,'#425a61')
    for j in range(y+3,y+h-2,4):
        a.box(x+3,j,w-6,2,'#203341');a.box(x+4,j+2,w-8,1,'#5f7470')
def rivets(a,x,y,w,spacing=21,c='#89a09b'):
    for i in range(x,x+w,spacing):a.box(i,y,2,1,c)
def stripe(a,x,y,w,h,light='#b88c55',dark='#28363b',step=13):
    a.box(x,y,w,h,dark)
    for i in range(x,x+w-h,step):a.p([(i,y+h-1),(i+5,y+h-1),(i+5+h,y),(i+h,y)],light)
def railing(a,x,y,w,style='#293d48'):
    for i in range(x,x+w+1,28):a.box(i,y,2,24,style)
    a.box(x,y,w,2,style);a.box(x,y+9,w,1,style)
def lamp(a,x,y,cone=True):
    if cone:
        a.p([(x-4,y),(x+4,y),(x+23,y+67),(x-28,y+67)],'#374741')
        a.p([(x-2,y),(x+2,y),(x+14,y+45),(x-15,y+45)],'#454f45')
    a.p([(x-4,y-7),(x+4,y-7),(x+10,y),(x-9,y)],ink);a.box(x-7,y,15,2,gold);a.box(x-4,y,8,1,'#ffe7ad')
def bollard(a,x,y):
    a.e(x-7,y-3,19,7,'#202c36');a.box(x-3,y-19,7,18,'#33454b');a.box(x-3,y-16,2,13,'#83958a')
    a.box(x-5,y-19,11,3,'#263b44');a.box(x-6,y-20,13,2,'#a5a899')
def wheel(a,x,y,r,col,inner):
    a.e(x-r,y-r,2*r,2*r,col);a.e(x-r+2,y-r+2,2*r-4,2*r-4,inner)
    for i in range(4):
        q=i*math.pi/2+.3;a.l([(x,y),(x+(r-2)*math.cos(q),y+(r-2)*math.sin(q))],col,2)
    a.e(x-2,y-2,5,5,col)
def sign(a,x,y,w,h,base,msg,sub=None,c=bone):
    a.box(x-3,y-3,w+6,h+7,ink);a.box(x-1,y-1,w+2,h+2,mix(base,c,.43));a.box(x,y,w,h,base)
    a.box(x+3,y+3,1,h-6,mix(base,c,.54));a.text(x+7,y+5,msg,c,h//2 if not sub else h//2-1,bold=True)
    if sub:a.text(x+8,y+h-8,sub,mix(base,c,.72),6)
    for i in (x+1,x+w-2):a.box(i,y+1,1,1,c)
def workshop():
    a=Art(seed=8)
    # Warehouse facade interspersed with glimpses of the city through loading gaps.
    for x,w in [(-50,368),(364,407),(820,399),(1263,240)]:
        a.box(x,86,w,159,'#30444b');a.box(x+4,101,w-8,24,'#516663')
        for i in range(x+5,x+w-3,14):
            a.box(i,97,1,145,'#273b43');a.box(i+1,98,1,145,'#455b5a')
        for y in [106,134,201]:a.box(x,y,w,1,'#72827a')
        a.box(x-4,77,w+8,11,'#20363f');a.box(x-7,74,w+14,3,'#80918a');a.box(x-7,77,w+14,2,'#445b5d')
        for i in range(x+10,x+w-24,41):
            a.box(i,59,32,15,'#344b56');a.p([(i,58),(i+22,49),(i+31,49),(i+31,59)],'#62797a')
            a.l([(i+1,58),(i+22,49),(i+30,49)],'#87988b');a.l([(i+16,52),(i+16,59)],'#3e535a')
        # Two different bays: shutter and glowing workshop interior.
        sx=x+23; a.box(sx,140,96,103,ink);a.box(sx+3,143,90,99,'#576463')
        for j in range(145,237,6):
            a.box(sx+3,j,90,2,'#38494c');a.box(sx+3,j+2,90,1,'#68736c')
        a.text(sx+18,161,"R / 07",'#8a939f',16,bold=True)
        stripe(a,sx,238,99,6)
        bx=x+143;bw=w-163
        a.box(bx-5,129,bw+10,113,'#20333e');a.box(bx,133,bw,109,'#70624e')
        # interior beams and windows against a backlit wall
        for i in range(bx+6,bx+bw-7,23):
            a.box(i,138,20,36,'#ac8a62');a.box(i+1,140,18,16,'#d1a873');a.box(i+2,141,3,13,'#eed09a');a.box(i,158,21,2,'#695849')
        a.box(bx,189,bw,4,'#443f39');a.box(bx,193,bw,1,'#a18a68')
        for i in range(bx+8,bx+bw-8,13):
            hh=a.r.randrange(9,23);a.box(i,189-hh,3,hh,'#3b4140');a.box(i-1,189-hh,6,4,'#34403e')
        a.box(bx,216,bw,6,'#283c43')
        for i in range(bx+7,bx+bw-12,37):
            a.box(i,203,24,12,'#38484a');a.box(i+3,206,12,6,'#678882');a.box(i+17,206,3,2,amber)
            a.box(i,221,3,22,'#293941')
        for i in [bx+8,bx+bw-23]:
            a.l([(i,132),(i,143)],ink);lamp(a,i,147,False)
        sign(a,bx-2,99,min(180,bw+5),26,'#404c48',"RELAY REPAIR","HARBOUR  /  SERVICE  07",gold)
        for i in [x+3,x+w-9]:
            a.box(i,90,7,153,'#1d353e');a.box(i,90,2,150,'#82918a');stripe(a,i-1,214,10,13)
        vents(a,x+20,113,70,15)
        # High pressure lines bending around the bay.
        a.l([(x+127,238),(x+127,134),(x+117,125),(x+117,92)],'#19323c',5)
        a.l([(x+125,238),(x+125,134),(x+115,125),(x+115,92)],'#82938a',2)
        wheel(a,x+126,194,8,'#b96b51','#344b4e')
        a.box(x-6,245,w+12,6,'#263b43');a.box(x-6,243,w+12,2,'#88938b')
    for x in [317,770,1218]:
        railing(a,x,217,48);bollard(a,x+18,249)
        a.cable(x-47,81,x+83,78,14,ink,2)
    a.cable(-10,4,397,61,46,ink,2);a.cable(397,61,841,15,52,ink,2);a.cable(841,15,1284,57,42,ink,2)
    for x in [74,360,742,1124]:
        box3(a,x,225,33,20,'#525f56');a.l([(x+2,242),(x+29,227)],'#8d9279',2)
        a.box(x+3,231,14,4,'#b9ab7d')
    return a
def awning(a,x,y,w,c1,c2):
    a.box(x-5,y+21,w+12,8,ink)
    a.p([(x+7,y),(x+w-6,y),(x+w+8,y+19),(x-8,y+19)],c1)
    n=max(4,w//19)
    for i in range(n):
        x1=(x+7)+(w-13)*i/n; x2=(x+7)+(w-13)*(i+1)/n
        X1=x-8+(w+16)*i/n; X2=x-8+(w+16)*(i+1)/n
        c=[c1,c2][i%2]
        a.p([(x1,y),(x2,y),(X2,y+19),(X2,y+24),((X2+X1)/2,y+27),(X1,y+24),(X1,y+19)],c)
        a.p([(X1,y+20),(X2,y+20),(X2,y+24),((X2+X1)/2,y+27),(X1,y+24)],mix(c,ink,.32))
        a.l([(x1+1,y+1),(X1+1,y+19)],mix(c,bone,.16))
    a.box(x+6,y-2,w-12,3,mix(c1,bone,.36))
def fish(a,x,y,s,c):
    a.p([(x,y+3*s),(x+6*s,y),(x+13*s,y+s),(x+17*s,y+3*s),(x+21*s,y),(x+20*s,y+4*s),(x+21*s,y+8*s),(x+16*s,y+5*s),(x+8*s,y+8*s),(x+2*s,y+6*s)],c)
    a.box(x+3*s,y+3*s,max(1,s),max(1,s),ink)
def market():
    a=Art(seed=28)
    for k,(x,w,ht) in enumerate([(-31,140,114),(125,200,83),(392,120,113),(538,182,66),(790,181,96),(1011,132,111),(1171,179,74)]):
        c=['#5c6861','#68605a','#495d5c'][k%3];a.box(x,ht,w,243-ht,c)
        # Weather-beaten upper storey and tall apartment windows.
        a.p([(x,ht),(x+w-20,ht-6),(x+w+1,ht-4),(x+w+1,ht),(x,ht+5)],'#2b3740')
        a.box(x,ht+3,w,3,'#9b9984')
        for xx in range(x+8,x+w-19,27):
            a.box(xx-2,ht+14,21,27,'#2d4046');a.box(xx,ht+16,17,21,'#786f59')
            a.box(xx+2,ht+17,7,17,a.r.choice(['#e1af71','#5a7774','#d0976c']))
            a.box(xx+12,ht+17,3,17,'#929580');a.box(xx-3,ht+40,22,2,'#ab9e84')
        a.dots(60,(x,ht+42,w,22),[mix(c,bone,.12),mix(c,ink,.12)],widths=(1,2,5))
        # little leaning signs high up interrupt the rooftops
        if k%2:
            a.box(x+w-27,ht+8,2,45,ink);a.box(x+w-36,ht+12,24,52,'#273840')
            a.box(x+w-34,ht+14,20,48,'#a9554e')
            a.text(x+w-31,ht+17,'港','#ffcb94',15);a.text(x+w-31,ht+37,'市','#ffcb94',15)
        y=164+k%3*5
        a.box(x,y,w,76,'#2e4549');a.box(x+4,y+16,w-8,44,'#776c54')
        for xx in range(x+12,x+w-7,25):
            a.box(xx,y+20,1,20,ink)
            a.e(xx-3,y+37,8,15,'#36555b');a.box(xx-2,y+40,2,7,'#9ca896')
        if k%2:
            sign(a,x+9,y-32,min(w-20,140),29,'#82544b','NIGHT MARKET','TIDE   /   SEAFOOD',gold)
        else:
            a.p([(x+14,y-15),(x+47,y-26),(x+78,y-27),(x+98,y-14),(x+113,y-26),(x+110,y-12),(x+119,y-4),(x+99,y-8),(x+63,y-2),(x+27,y-5)],'#d2a778')
            a.box(x+29,y-14,4,4,'#4f5450');a.l([(x+45,y-20),(x+41,y-14),(x+45,y-8)],'#865f50',2)
        awning(a,x,y,w,['#a96459','#4f857c','#a38b68'][k%3],['#c0a282','#96a18a','#595f61'][k%3])
        a.box(x+4,226,w-8,19,'#3d5554')
        for xx in range(x+6,x+w-26,28):
            box3(a,xx,222,23,11,'#9b8c6b',3)
            for j in range(3):fish(a,xx+3+j*4,221-j,a.r.choice([.39,.47]),'#8ea9a0')
        a.box(x+5,236,w-9,2,'#879485')
        for xx in [x+2,x+w-4]:
            a.box(xx,y+20,3,245-y-20,'#1a303b');a.box(xx,y+20,1,245-y-20,'#a5a08b')
    # Outdoor festival string, lanterns illuminate the lane.
    for i in range(4):
        x=i*350-50;a.cable(x,60,x+350,71,24,'#303740',2)
        for j in range(1,6):
            t=j/6;X=x+350*t;Y=60+11*t+96*t*(1-t)
            a.l([(X,Y),(X,Y+4)],ink);a.e(X-4,Y+4,9,13,'#a86651')
            a.box(X-2,Y+5,4,9,'#f0b675');a.box(X-2,Y+4,4,1,'#5c5149');a.box(X-2,Y+16,4,2,'#3f4244')
    return a
def container(a,x,y,w,h,c,tag=''):
    box3(a,x,y,w,h,c,7)
    for i in range(x+6,x+w-5,7):
        a.box(i,y+4,2,h-10,mix(c,ink,.33));a.box(i+2,y+4,1,h-10,mix(c,bone,.18))
    a.box(x+2,y+2,w-4,1,mix(c,bone,.36));a.box(x+2,y+h-4,w-4,2,mix(c,ink,.37))
    for i in [x+1,x+w-5]:
        for j in [y+1,y+h-5]:a.box(i,j,4,4,mix(c,ink,.65));a.box(i+1,j+1,1,1,mix(c,bone,.46))
    if tag:a.box(x+10,y+9,53,15,mix(c,ink,.22));a.text(x+12,y+11,tag,mix(c,bone,.69),9,bold=True)
def ship(a,x,y,s,c):
    def pts(pts):return [(x+i*s,y+j*s) for i,j in pts]
    def rect(i,j,w,h,col):a.box(x+i*s,y+j*s,w*s,h*s,col)
    a.p(pts([(0,0),(201,-6),(272,-22),(251,9),(228,24),(54,28),(18,19)]),c)
    a.l(pts([(0,0),(201,-6),(272,-22)]),mix(c,bone,.6),max(1,round(s*2)))
    a.p(pts([(20,15),(181,12),(252,1),(230,20),(50,26)]),mix(c,rust,.55))
    rect(35,-54,66,50,'#8a9388');rect(44,-71,56,18,'#a2a69a');rect(55,-82,34,10,'#6a7c7a')
    for i in range(50,94,9):rect(i,-67,7,7,'#2d4853')
    for i in range(42,96,11):rect(i,-42,6,6,'#485b5c');rect(i,-23,5,5,'#576660')
    rect(49,-95,3,23,'#3d5761');rect(39,-88,22,2,'#798e8c')
    for i in range(110,201,11):rect(i,-3,4,2,'#a0a59a')
    a.cable(x+50*s,y-91*s,x+170*s,y-12*s,8*s,'#54696e')
def docks():
    a=Art(seed=481)
    for x,y,s in [(-18,206,1.14),(212,200,.76),(529,207,1.25),(790,201,.75),(1042,214,1.12)]:derrick(a,x,y,s,'#385963','#718784')
    for x,y,s in [(120,206,.94),(755,206,1.17)]:ship(a,x,y,s,'#334c56')
    for i,x in enumerate([-42,81,391,503,615,956,1069,1182]):
        c=['#58706a','#925f50','#596a71','#756c5c'][i%4]
        container(a,x,203,109,39,c,['NR 09','TIDE','K/L','PORT'][i%4])
        if i in [0,3,4,6,7]:container(a,x+5,160,110,38,['#53666a','#856859'][i%2],'E / 12')
    # Stacks of rope and guide rails.
    for x in range(-10,1300,131):
        railing(a,x,222,92);bollard(a,x+115,246)
        for j in range(3):a.e(x+50-j,242-3*j,25,6,'#283d44');a.l([(x+53,243-3*j),(x+68,242-3*j)],'#8d9280')
    for x in [343,866]:
        a.box(x,84,6,159,'#273c49');a.box(x+1,84,1,155,'#8a9891')
        a.l([(x,84),(x+13,72),(x+32,72)],'#334750',3);lamp(a,x+32,77,False)
    return a
def insulator(a,x,y,ht=40):
    a.box(x-2,y-ht,5,ht,'#394653')
    for j in range(y-ht+3,y-3,5):a.e(x-7,j,14,4,'#7e8b85');a.box(x-6,j+1,9,1,'#b1b49b')
    a.box(x-6,y-2,12,3,ink)
def dish(a,x,y,s):
    def pt(i,j):return x+s*i,y+s*j
    def poly(coords,c):a.p([pt(i,j) for i,j in coords],c)
    poly([(-5,0),(7,0),(1,-33),(-2,-33)],'#51666b')
    a.l([pt(-13,0),pt(-4,-26),pt(11,0)],'#3a4b58',max(1,round(s*3)))
    poly([(-35,-52),(-22,-50),(-6,-43),(11,-31),(25,-17),(18,-17),(4,-20),(-12,-27),(-26,-40)],'#7f908b')
    a.l([pt(-35,-52),pt(-21,-49),pt(-2,-39),pt(14,-27),pt(25,-17)],'#c3c6af',max(1,round(2*s)))
    a.l([pt(-27,-47),pt(6,-62),pt(19,-23)],'#658082',max(1,round(s)))
    a.l([pt(-6,-34),pt(6,-62),pt(9,-65)],'#bec2ac',max(1,round(s*2)))
    for i in range(3):
        a.l([pt(-28+12*i,-46+i*6),pt(-14+12*i,-30+i*5)],'#697d7c')
def tower_env():
    a=Art(seed=109)
    for x,h in [(127,235),(609,275),(1147,226)]:
        tower(a,x,234,h,'#344c59','#7f8e89')
        a.cable(x,234-h*.76,x+186,204,20,'#47575e')
        a.cable(x,234-h*.53,x-165,208,18,'#4e5d63')
    for k,x in enumerate([-72,302,768,1201]):
        y=162-14*(k%2);w=227
        box3(a,x,y,w,242-y,'#516168',10)
        a.box(x-6,y-5,w+18,6,'#293e4a');a.box(x-5,y-7,w+17,2,'#939c8f')
        dish(a,x+55,y-7,1.20);dish(a,x+146,y-7,.85)
        for i in range(x+13,x+w-61,52):vents(a,i,y+15,44,25)
        a.box(x+13,y+48,132,20,'#46545a');a.text(x+20,y+53,'RF SUBSTATION','#afb4a2',12,bold=True)
        a.box(x+w-49,y+8,37,241-(y+8),'#263945');a.box(x+w-46,y+11,31,241-(y+11),'#62716f');a.box(x+w-39,y+21,18,12,'#99b6a8');a.box(x+w-24,y+42,4,2,bone)
        a.box(x,240,w+6,4,'#79867f')
    for x in [169,583,1016]:
        a.box(x+6,215,90,26,'#465b61');a.box(x,210,103,6,'#a5a89a')
        for i in range(4):insulator(a,x+13+i*24,210,41-i%2*6)
        for i in range(3):a.cable(x+13+i*24,169+i%2*6,x+37+i*24,169+(i+1)%2*6,7,'#334551',2)
        a.cable(x+13,169,x-23,129,17,'#43565f',2)
        railing(a,x-9,219,125)
    return a
def ground(kind):
    a=Art(seed=43+list(stages).index(kind)); c={'workshop':'#3d5358','market':'#56555a','docks':'#3b4c5a','tower':'#494e59'}[kind]
    # Silhouette-clearing wet ground with hand-clustered reflections and slabs.
    haze(a,mix(c,ink,.24),mix(c,ink,.48),247,360,8)
    a.box(0,246,W,3,mix(c,bone,.29));a.box(0,250,W,2,mix(c,ink,.45))
    for x in range(-128,W+128,128):
        a.l([(x+64,247),(x-30,360)],mix(c,ink,.39))
    for y in [260,278,308,348]:
        a.box(0,y,W,1,mix(c,ink,.43));a.box(0,y+1,W,1,mix(c,bone,.02))
    primary={'workshop':'#baa674','market':'#b47f68','docks':'#7e9fa0','tower':'#b09c88'}[kind]
    for j,x in enumerate(range(-21,1360,80)):
        x+=a.r.randint(-15,16);r=a.r;mx=r.randint(28,76);h=r.randint(33,98)
        col=r.choice([jade,primary,primary,'#87948c'])
        for _ in range(72 if j%2==0 else 47):
            t=r.random();Y=249+int(h*t);dx=int(r.gauss(0,mx*(.14+.39*t)))
            if abs(dx)>mx:continue
            width=max(1,int((1-t*.4)*r.uniform(2,15)))
            tint=max(.04,r.uniform(.15,.47)*(1-t*.78)*(1-abs(dx)/mx))
            a.box(x+dx,Y,width,1,mix(c,col,tint))
    # irregular pools with dark reflections and chipped silver water edges
    for _ in range(53):
        x=a.r.randint(-30,W);y=a.r.randint(256,355);width=a.r.randrange(8,67);d=a.r.randrange(2,6)
        a.p([(x,y),(x+width*.3,y-1),(x+width,y),(x+width*.76,y+1),(x+width*.84,y+2),(x+width*.4,y+d),(x+4,y+d-1),(x+7,y+1)],mix(c,ink,.53))
        a.box(x+3,y+d-1,max(2,int(width*.25)),1,mix(c,bone,.21));a.box(x+width*.48,y,width*.27,1,mix(c,jade,.24))
    for x in range(29,W,133):
        a.box(x,258,43,2,mix(c,bone,.37));a.box(x+5,259,7,1,mix(c,ink,.3))
    # Objects stay at the curb / lower frame and don't cover the combat plane.
    for i,x in enumerate(range(27,W,197)):
        y=320+(i%3)*13
        if i%2==0:
            a.p([(x,y),(x+39,y),(x+44,y+8),(x-5,y+8)],mix(c,ink,.46))
            for j in range(9):a.l([(x+3+j*4,y+1),(x+1+j*4,y+6)],mix(c,bone,.15))
            a.l([(x-4,y+8),(x+43,y+8)],mix(c,bone,.18))
        else:
            a.l([(x-5,y+3),(x+3,y+2),(x+7,y-1),(x+13,y-2),(x+16,y-5),(x+21,y-6)],mix(c,ink,.58))
    return a

def title():
    a=Art(640,360,821);haze(a,'#162438','#758682',0,220,4)
    # A screen-printed, partly occluded sodium moon.
    a.e(420,16,163,162,'#d8a475');a.e(427,21,149,146,'#e7b580')
    for j in range(25,168,6):
        dy=(j-97)/79
        if abs(dy)>1:continue
        dx=int(77*math.sqrt(1-dy*dy));a.box(501-dx,j,2*dx,1,'#dda979')
    clouds(a,['#324653','#40545d','#5a6c6b'])
    # Calm pocket to the left reserved for the live title and menu.
    skyline(a,203,'#415b62','#9a9e8a')
    for x,y,s in [(26,217,.68),(155,208,.55),(338,223,1.04)]:derrick(a,x,y,s,'#334c58','#658081')
    tower(a,558,230,204,'#394c57','#92988b')
    a.cable(558,52,636,187,12,'#56616a');a.cable(558,49,424,203,9,'#56616a')
    a.box(0,213,640,147,'#3e5961');a.dots(1050,(0,214,640,116),['#526c70','#67807b','#344d59'],widths=(2,3,7,16,24))
    ship(a,150,246,.56,'#2d424d')
    # Foreground waterfront wall and rope.
    a.p([(0,263),(640,224),(640,360),(0,360)],'#263b47')
    a.p([(0,263),(640,224),(640,229),(0,269)],'#617574')
    a.cable(-28,207,223,224,31,'#263b47',2);a.cable(223,224,432,206,24,'#263b47',2)
    # Hand-authored portrait. Courier looks right along the breakwater.
    def poly(points,color):a.p(points,color)
    dark='#182a38'; hair='#24424e'; teal='#3c6669'; hi='#61837a'; skin='#c98965'; skinlit='#efbc82'; shade='#a96c55'
    # Long scarf ends stream in separate folded planes, pinned to her hood.
    poly([(462,182),(440,201),(406,208),(381,206),(353,194),(328,193),(309,199),(327,187),(356,184),(389,195),(412,193),(442,174)],dark)
    poly([(457,182),(438,195),(412,203),(390,202),(358,191),(334,189),(318,194),(334,185),(357,186),(390,197),(412,195),(441,177)],'#477974')
    poly([(448,191),(433,205),(404,215),(389,224),(376,237),(372,236),(379,219),(388,210),(419,198)],'#345a5f')
    poly([(450,204),(435,217),(414,239),(408,260),(396,286),(386,316),(377,360),(571,360),(565,327),(554,288),(539,257),(520,236),(507,212),(489,205)],dark)
    # raincoat shoulder, cropped coarsely for close-up
    poly([(451,208),(434,223),(418,245),(413,264),(398,294),(387,330),(385,360),(553,360),(551,318),(539,279),(522,248),(510,219),(486,211)],'#a56e46')
    poly([(455,213),(438,226),(423,248),(423,261),(413,278),(410,299),(399,316),(394,351),(408,344),(419,315),(428,288),(444,268),(463,251),(477,231)],'#d39b59')
    poly([(465,219),(448,236),(429,263),(435,261),(447,251),(435,273),(421,299),(412,326),(421,321),(440,290),(459,273),(483,260),(498,239)],'#e6b768')
    poly([(500,235),(488,249),(492,263),(512,272),(525,286),(537,308),(547,332),(545,297),(533,268),(513,245)],'#755943')
    poly([(482,255),(462,269),(449,288),(440,321),(437,360),(521,360),(526,338),(520,317),(515,288),(499,263)],'#ba814a')
    poly([(494,271),(506,281),(518,307),(519,325),(495,307),(483,287),(469,278)],'#d29a56')
    poly([(469,282),(458,287),(447,309),(448,325),(458,311),(467,296)],'#e5ac61')
    # sleeve seams and reflective stripes
    a.l([(465,276),(480,271),(494,272),(509,282),(520,302)],'#6e5645',2)
    poly([(447,313),(451,307),(464,302),(481,303),(493,307),(499,317),(482,312),(469,311),(454,317),(446,325)],'#797f69')
    poly([(447,316),(457,309),(470,305),(482,306),(495,312),(497,315),(479,309),(468,309),(451,317)],'#d9cd92')
    a.l([(440,342),(450,333),(463,330),(485,334)],'#8e6546',2)
    # Rear shoulder bag with metal runners, seam stripes and shoulder radio.
    poly([(427,247),(439,252),(414,300),(402,332),(398,360),(379,360),(382,335),(393,302)],'#213741')
    a.l([(430,252),(414,278),(401,309),(387,350)],'#63756d',3)
    poly([(395,286),(410,290),(415,301),(399,346),(393,360),(348,360),(360,323),(377,296)],'#1c3441')
    poly([(386,294),(406,296),(392,338),(375,347),(356,345),(367,314)],'#3e5a5d')
    a.l([(365,318),(377,306),(394,300)],'#78918a',2)
    a.l([(355,347),(375,350),(391,342)],'#708078',2)
    # Neck and dark windswept undercut, clean angular facial silhouette
    poly([(456,114),(463,94),(480,84),(500,77),(524,80),(540,91),(547,112),(544,128),(550,142),(555,150),(548,153),(545,161),(539,164),(537,174),(528,181),(512,179),(503,189),(509,207),(493,221),(466,209),(452,185),(463,171),(457,151)],dark)
    poly([(482,109),(514,94),(532,99),(539,111),(536,128),(540,137),(548,147),(548,149),(540,151),(538,158),(533,159),(531,169),(524,174),(511,171),(497,181),(496,198),(480,201),(464,187),(473,166),(472,147)],skin)
    poly([(528,108),(535,114),(532,127),(534,134),(539,140),(546,148),(537,148),(535,153),(528,152),(532,157),(530,162),(524,169),(516,169),(512,164),(517,156),(521,154),(522,144),(517,137),(514,128)],skinlit)
    poly([(495,147),(508,153),(513,163),(508,169),(507,176),(497,182),(492,196),(481,196),(471,188),(478,174)],shade)
    poly([(537,125),(536,128),(529,129),(523,128),(526,126)],dark)
    a.l([(529,132),(534,131)],'#764d4a',2);a.box(533,131,2,2,'#293b43')
    a.l([(534,157),(538,156)],'#814f45')
    # Large hair mass; sharp locks follow the coastal wind.
    poly([(539,108),(538,99),(532,90),(520,84),(504,80),(489,82),(479,77),(456,77),(468,82),(448,82),(432,92),(416,96),(431,97),(416,104),(405,117),(419,113),(410,125),(399,131),(418,131),(402,143),(391,147),(407,151),(420,147),(413,158),(427,155),(422,168),(436,160),(435,171),(445,165),(451,180),(465,175),(474,162),(479,143),(493,139),(505,125),(518,118),(531,113),(539,112)],dark)
    poly([(528,91),(512,85),(490,85),(475,82),(484,89),(462,88),(442,94),(433,100),(449,97),(429,107),(419,117),(437,110),(420,125),(415,131),(433,124),(421,139),(410,145),(429,141),(447,127),(431,150),(446,145),(449,153),(459,145),(463,133),(469,126),(473,135),(487,123),(506,116),(518,107),(536,106)],hair)
    poly([(529,95),(510,88),(495,90),(476,92),(455,96),(449,100),(466,98),(450,105),(439,111),(454,108),(442,117),(466,107),(480,100),(476,105),(489,102),(501,96),(512,96),(521,101),(535,105)],teal)
    poly([(502,88),(486,88),(470,91),(461,96),(478,93),(486,94)],hi)
    poly([(457,113),(445,119),(433,131),(446,125),(454,122),(469,108)],'#3d6269')
    a.l([(420,145),(440,135),(456,124)],'#527773')
    # dark turquoise scarf / padded collar
    poly([(446,170),(458,163),(478,168),(493,178),(509,181),(510,195),(518,205),(508,214),(502,230),(485,234),(471,228),(455,218),(439,205),(434,193)],dark)
    poly([(447,173),(460,169),(479,174),(495,183),(506,184),(507,195),(497,204),(477,208),(458,199),(441,188)],'#37636a')
    poly([(442,187),(453,192),(469,201),(489,205),(506,196),(511,202),(502,213),(482,223),(457,209),(442,200)],'#437579')
    poly([(445,176),(459,171),(479,177),(492,185),(478,182),(459,177)],'#698b81')
    a.l([(448,200),(463,209),(480,215),(491,212)],'#76a39a',2)
    # Emergency portable receiver, protruding antenna and enamel signal badge.
    a.l([(422,241),(419,194)],'#152d37',4);a.l([(419,197),(418,189)],'#91a59a',2)
    poly([(419,223),(433,226),(436,233),(431,257),(415,254),(413,247)],ink)
    poly([(419,226),(432,228),(429,252),(416,250)],'#5b6d67')
    poly([(420,228),(430,230),(429,235),(419,234)],'#93af9e')
    for i in range(4):a.l([(418,239+i*2),(427,240+i*2)],'#273e46')
    poly([(461,291),(468,286),(477,289),(478,296),(470,301),(460,298)],'#684f43')
    a.l([(463,295),(466,292),(468,294),(470,290),(473,293),(476,291)],'#f1cf89')
    # rim light on major silhouette edges
    a.l([(532,91),(539,100),(540,106)],'#d0bc8e',2)
    a.l([(541,137),(548,146),(551,149)],'#f6cc90',2)
    a.l([(511,206),(520,233),(530,247)],'#d4ad76',2)
    # Screen-printed rain clusters on clothing/sea. Fade scene naturally leftward.
    for _ in range(130):
        x=a.r.randrange(284,638);y=a.r.randrange(17,355)
        if 410<x<552 and 75<y<224:continue
        if a.r.random()<.48:a.l([(x,y),(x-2,y+4)],'#718686')
    px=a.im.load()
    for x in range(385):
        amount=max(0,1-x/385)*.55
        for y in range(360):
            t=amount*(.76+(.24*y/360))
            v=px[x,y][:3];px[x,y]=(*mix(v,'#122030',t),255)
    return a
stages={'workshop':workshop,'market':market,'docks':docks,'tower':tower_env}
def main():
    OUT.mkdir(exist_ok=True,parents=True)
    for kind,fn in stages.items():
        far=city(kind);mid=fn();gr=ground(kind)
        import details
        details.apply(mid,kind)
        far.save(kind+'_far');mid.save(kind+'_mid');gr.save(kind+'_ground')
    title().save('title')
if __name__=='__main__':main()
