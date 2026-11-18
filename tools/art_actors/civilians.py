"""Animated harbour residents. The child, fishmonger and dockhand use individual proportions."""
from math import sin, pi
from PIL import Image
from paint import Plate, local, segment, uniforms, Design, DEST, HERE, INK, INK_L, PALE, boot

uniforms.update({
    'elder':Design(57,16,1,.9,('#534453','#76596a','#9b7786','#ccb39e'),('#353441','#534851','#72605b','#9c8678'),
                    ('#975d50','#c38a69','#e0ac81','#f2d3a1'),('#46364c','#6f4960','#a46d7c','#d69e9e'),
                    ('#3a3541','#5a4c4c','#82685c','#bc9a7a')),
    'child':Design(65,11,.7,.65,('#903f43','#c25b53','#ed8c67','#ffc194'),('#2b4050','#405b69','#647e85','#9eaba1'),
                    ('#9d5c4b','#d68d62','#f2b987','#ffdeaa'),('#227072','#3da697','#79d3b6','#bdeccb'),
                    ('#234852','#356771','#519198','#b1c3ae')),
    'worker':Design(53,20,1.21,1.10,('#895339','#b77445','#e69e59','#ffd58a'),('#263644','#3c5362','#5d7680','#8f9d9c'),
                    ('#684750','#985f53','#c28160','#e5aa7b'),('#32494d','#4f6c63','#7b9582','#b9c3a2'),
                    ('#383442','#574b4e','#7a6960','#b3a388')),
})

def leg(plate,actor,hip,x,y,lean,far):
    u=uniforms[actor];w=u.limb*(.86 if far else 1)
    knee=(hip[0]*.53+x*.47+lean,hip[1]*.48+y*.52)
    segment(plate,hip,knee,4*w,u.trousers,far)
    seg=segment(plate,knee,(x,y),3.2*w,u.trousers,far)
    if actor=='worker':
        seg.line(u.trousers[3],[(.55,-2*w),(.56,2*w)])
    if actor=='child':
        seg.poly(u.boots[1],[(.14,-2.8),(.81,-2.0),(.91,1.3),(.37,2.3),(.18,2)])
    boot(plate,actor,(x,y),u.limb,far,False)

def elder_head(p,c):
    h=local(p,c)
    u=uniforms['elder']; k=u.skin; j=u.jacket
    # Flyaway wisps against a kerchief gathered around a low bun.
    h.poly(INK,[(-8,-2),(-11,-2),(-13,-5),(-12,-8),(-9,-10),(-6,-9),(-4,-11),(0,-12),(4,-11),(7,-8),(8,-5),(7,-2),(8,0),(10,2),(10,3),(8,4),(7,7),(4,8),(1,8),(0,10),(-4,9),(-6,5),(-7,3)])
    h.poly('#827b7b',[(-8,-2),(-11,-3),(-12,-5),(-11,-7),(-9,-9),(-6,-8),(-4,-6),(-5,-3)])
    h.line('#c8bfb0',[(-11,-6),(-10,-8),(-8,-8)])
    h.poly(k[1],[(-6,-3),(-2,-7),(3,-8),(6,-6),(6,-3),(6,0),(9,2),(7,3),(6,6),(4,7),(1,7),(-1,8),(-4,6),(-4,2)])
    h.poly(k[2],[(0,-3),(3,-7),(5,-6),(6,-4),(5,-2),(5,0),(8,2),(6,3),(6,4),(3,4),(3,6),(0,4),(-1,1)])
    h.poly('#aca398',[(-7,-3),(-7,-7),(-4,-10),(0,-11),(4,-10),(7,-7),(7,-5),(4,-6),(2,-6),(0,-3),(-1,-1),(-3,-2),(-4,2),(-6,3)])
    h.poly('#e0d5bd',[(-6,-7),(-3,-10),(1,-10),(4,-9),(5,-8),(2,-9),(0,-7),(-3,-7),(-3,-5)])
    h.line('#c9bca6',[(-1,-5),(1,-7),(4,-7)])
    h.line(j[2],[(-7,-7),(-6,-9),(-3,-10)])
    h.line('#784f4b',[(0,-1),(3,-3),(6,-3)])
    h.poly('#363846',[(1,-1),(3,-2),(7,-2),(8,-1),(7,2),(4,3),(2,2)])
    h.poly('#9d9a90',[(3,-1),(6,-1),(7,0),(6,1),(4,2),(3,1)])
    h.line('#efddba',[(3,-1),(5,-1)]);h.dot('#56464a',6,0)
    h.line(k[0],[(0,2),(1,3)])
    h.line(k[0],[(5,4),(7,4)])
    h.line(k[3],[(4,6),(5,6)])
    h.dot('#dca554',-4,4)

def child_head(p,c,phase):
    u=uniforms['child']; k=u.skin; j=u.jacket
    h=local(p,c)
    h.poly(INK,[(-8,-2),(-9,-4),(-7,-7),(-4,-9),(1,-10),(5,-8),(7,-5),(7,-2),(8,0),(9,1),(8,3),(6,5),(3,7),(1,7),(-1,9),(-4,8),(-5,5),(-7,5),(-9,2)])
    h.poly(k[1],[(-6,-4),(-2,-7),(2,-7),(6,-5),(6,-2),(7,0),(8,1),(7,3),(5,5),(2,6),(-2,5),(-4,3),(-6,2)])
    h.poly(k[2],[(-1,-3),(3,-5),(6,-4),(5,-2),(6,0),(8,1),(6,2),(6,4),(3,5),(0,4),(-1,2),(-3,1)])
    h.line(k[0],[(5,3),(6,3)])
    h.line(INK,[(2,-2),(4,-3),(5,-2)])
    h.box(PALE,2,-1,4,2);h.box(INK,4,-1,2,2)
    h.line('#d68d77',[(0,2),(2,2)])
    # Bubble pigtails with satiny red ties and asymmetric choppy fringe.
    shift=int(round(phase))
    h.poly(INK,[(-6,-6),(-8,-6),(-10,-4+shift),(-11,-1+shift),(-10,1+shift),(-12,3+shift),(-9,5+shift),(-6,4+shift),(-5,1)])
    h.poly('#5e404b',[(-7,-5),(-9,-3+shift),(-10,-1+shift),(-9,1+shift),(-10,3+shift),(-8,4+shift),(-6,2)])
    h.poly('#7c5454',[(-8,-3+shift),(-9,-1+shift),(-8,2+shift),(-7,0)])
    h.poly(INK,[(-8,-3),(-8,-6),(-6,-8),(-3,-10),(1,-10),(4,-9),(7,-6),(7,-4),(4,-3),(2,-4),(0,-1),(-2,-1),(-4,2),(-5,0),(-7,2)])
    h.poly('#734d50',[(-7,-5),(-5,-7),(-2,-9),(1,-9),(4,-8),(6,-6),(6,-5),(4,-5),(3,-6),(1,-4),(-1,-2),(-2,-3),(-4,0),(-4,-3),(-6,-1)])
    h.poly('#a36d59',[(-5,-6),(-2,-8),(1,-8),(3,-7),(0,-7),(-2,-4),(-3,-5)])
    h.line('#cf9471',[(-2,-8),(0,-8)])
    h.line(j[3],[(-7,-5),(-6,-4),(-6,-3)])
    h.box('#f4d157',0,-5,3,1)

def worker_head(p,c):
    u=uniforms['worker']; k=u.skin;t=u.trim
    h=local(p,c)
    h.poly(INK,[(-8,-7),(-6,-10),(-2,-11),(4,-10),(6,-8),(7,-5),(7,-1),(10,1),(10,3),(8,3),(7,6),(5,8),(1,8),(0,11),(-5,10),(-6,6),(-6,3),(-8,1)])
    h.poly(k[1],[(-7,-5),(-3,-8),(2,-9),(5,-7),(6,-4),(6,-1),(9,1),(8,2),(7,2),(6,5),(4,7),(1,7),(-1,8),(-4,7),(-4,2),(-6,1)])
    h.poly(k[2],[(0,-4),(4,-6),(6,-4),(5,-2),(4,-1),(6,0),(8,1),(6,2),(6,4),(4,6),(1,5),(-1,3),(-1,0)])
    h.line(INK,[(1,-2),(3,-3),(5,-3)])
    h.line('#f0d7b1',[(2,-1),(5,-1)]);h.dot(INK,4,-1)
    h.poly('#443b46',[(-5,0),(-3,1),(-3,4),(-1,5),(1,5),(2,3),(5,3),(7,2),(7,4),(5,4),(4,5),(5,6),(7,5),(5,8),(1,9),(-2,8),(-4,6)])
    h.line(k[0],[(0,6),(2,7)])
    h.poly(INK,[(-9,-2),(-9,-6),(-8,-9),(-5,-11),(-1,-12),(2,-11),(5,-10),(7,-8),(8,-5),(8,-3),(2,-3),(-5,-1)])
    h.poly(t[1],[(-8,-4),(-7,-8),(-4,-10),(-1,-11),(3,-10),(5,-9),(7,-6),(7,-4),(1,-4),(-5,-2)])
    h.poly(t[2],[(-7,-7),(-5,-9),(-1,-10),(3,-9),(4,-8),(0,-8),(-3,-6)])
    h.poly('#3e5b59',[(-8,-5),(-2,-7),(5,-7),(7,-6),(7,-4),(1,-4),(-7,-2)])
    for x in (-6,-3,0,3,5):
        y=-3 if x < -3 else -5
        h.line(t[2],[(x,y-1),(x+1,y)])
    h.dot(t[3],0,-10)

def civilian(actor,action,i):
    u=uniforms[actor]
    f=i*pi/4 if action=='walk' else 0
    bob=round(cosine(i*pi/3)) if action=='idle' else [0,1,0,-1,0,1,0,-1][i]
    stride={'elder':6,'worker':11,'child':8}[actor]
    im=Image.new('RGBA',(96,88));p=Plate(im)
    hx=46; hy=u.hip+bob
    lean={'elder':5,'worker':1,'child':2}[actor]
    sh=(hx+lean,hy-u.spine)
    far=((hx+2,hy),(48+round(sin(f)*stride),77-round(max(0,-sin(f+pi/2))*4)))
    near=((hx-2,hy),(44-round(sin(f)*stride),77-round(max(0,sin(f+pi/2))*4)))
    if action=='idle':
        far=((hx+2,hy),(51,77));near=((hx-2,hy),(42,77))
    leg(p,actor,*[far[0],*far[1]],3,True)
    leg(p,actor,*[near[0],*near[1]],3,False)
    uarm=4*u.limb
    arms=[]
    for far_side in (True,False):
        sgn=1 if far_side else -1
        hint=round(sin(f)*6*sgn)
        anchor=(sh[0]+sgn*4*u.limb,sh[1]+2)
        elbow=(anchor[0]+hint,anchor[1]+round(10*u.limb))
        hand=(anchor[0]+hint*1.6+3,elbow[1]+round(9*u.limb))
        if actor=='elder' and not far_side:
            hand=(sh[0]+12+hint*.6,sh[1]+13)
            elbow=(sh[0]-1,sh[1]+15)
            cx=hand[0]+1;cy=hand[1]
            p.line(INK,[(cx-2,cy-1),(cx,cy-2),(cx+2,cy),(cx+2,cy+4),(cx+4,78)],3)
            p.line('#b8996e',[(cx-1,cy-1),(cx+1,cy-1),(cx+2,cy+3),(cx+4,77)])
        if actor=='child' and not far_side:
            hand=(anchor[0]+5+hint,sh[1]+10)
            elbow=(anchor[0]-1+hint*.6,sh[1]+11)
        arms.append((anchor,elbow,hand,far_side))
    def arm(a):
        anchor,elbow,hand,far_side=a
        ramp=u.skin if actor=='worker' else u.jacket
        segment(p,anchor,elbow,uarm,ramp,far_side)
        segment(p,elbow,hand,uarm*.78,ramp,far_side)
        h=local(p,hand,u.limb*.86,u.limb)
        h.poly(INK,[(-3,-2),(-1,-3),(2,-2),(3,0),(3,3),(1,5),(-2,4),(-3,2)])
        h.poly(u.skin[1],[(-2,-1),(0,-2),(2,-1),(2,2),(1,4),(-1,3)])
        h.line(u.skin[2 if far_side else 3],[(0,-1),(1,-1),(2,0)])
    arm(arms[0])
    b=local(p,(hx,hy),u.width,u.spine/18,lean/u.spine)
    j=u.jacket;t=u.trim
    if actor=='elder':
        b.poly(INK,[(-8,-16),(-3,-20),(3,-19),(6,-16),(8,-12),(7,-4),(8,6),(10,11),(8,15),(0,16),(-8,14),(-11,12),(-9,2),(-10,-6)])
        b.poly(j[1],[(-7,-15),(-3,-18),(2,-18),(5,-15),(7,-12),(6,-2),(7,7),(8,12),(6,14),(1,15),(-7,13),(-10,12),(-8,2),(-9,-5)])
        b.poly('#5b4248',[(-4,-6),(6,-10),(5,-1),(6,6),(8,13),(2,15),(-5,13),(-5,6)])
        b.poly('#8d635a',[(-2,-5),(5,-8),(4,0),(6,9),(6,13),(2,14),(-2,12)])
        b.line('#bd9480',[(-3,-3),(4,-6)])
        b.poly(j[2],[(-8,-14),(-4,-18),(1,-18),(5,-16),(6,-11),(1,-9),(-5,-5),(-8,-2),(-9,-7)])
        b.line(j[3],[(-8,-6),(-5,-8),(1,-11),(5,-12)])
        b.line(j[0],[(-8,-10),(-5,-12),(-2,-13)])
        b.poly(t[1],[(-3,-18),(2,-18),(5,-15),(5,-13),(2,-14),(0,-15),(-2,-14)])
        elder_head(p,(sh[0]+3,sh[1]-6))
    elif actor=='child':
        # Flared coral rain slicker, glazed shell buttons and fish-shaped schoolbag.
        b.poly(INK,[(-7,-17),(-3,-20),(3,-20),(6,-16),(7,-12),(6,-8),(9,6),(7,8),(-2,9),(-9,7),(-8,1),(-9,-11)])
        b.poly(j[1],[(-6,-16),(-2,-18),(2,-18),(5,-15),(6,-12),(5,-8),(8,5),(6,7),(-2,8),(-8,6),(-7,0),(-8,-10)])
        b.poly(j[2],[(-3,-15),(2,-17),(4,-13),(3,-9),(7,5),(4,6),(-2,7),(-3,3)])
        b.poly(j[0],[(-7,-16),(-2,-18),(3,-17),(5,-14),(1,-13),(-4,-12),(-8,-10)])
        b.line(j[3],[(-5,-17),(-1,-17),(3,-15)])
        b.line(j[3],[(2,5),(5,5)])
        for y in (-10,-4,1): b.dot('#ffe3a0',2,y)
        bag=local(p,(hx-5,sh[1]+4))
        bag.poly(INK,[(-4,-3),(-1,-4),(2,-2),(3,2),(2,6),(-1,8),(-5,8),(-6,6),(-6,2),(-8,-1),(-5,-1)])
        bag.poly('#d7ab54',[(-4,-2),(-1,-3),(1,-1),(2,2),(1,5),(-1,7),(-4,7),(-5,5),(-5,2),(-6,0),(-4,0)])
        bag.line('#ffe09a',[(-3,-2),(-1,-2),(0,-1)])
        bag.dot(INK,-1,0)
        child_head(p,(sh[0]+1,sh[1]-6),sin(f))
    else:
        b.poly(INK,[(-8,-18),(-4,-21),(1,-20),(7,-18),(9,-15),(9,-8),(6,-2),(6,2),(-7,3),(-9,1),(-8,-8),(-10,-12)])
        b.poly(j[1],[(-7,-17),(-4,-20),(1,-19),(6,-17),(8,-14),(8,-9),(5,-3),(5,1),(-6,2),(-8,0),(-7,-7),(-9,-12)])
        b.poly('#829896',[(-4,-19),(-1,-20),(3,-18),(6,-16),(4,-13),(3,-7),(4,0),(-2,1),(-3,-6),(-6,-14)])
        b.poly('#cfcead',[(-3,-18),(0,-18),(2,-17),(5,-16),(3,-13),(2,-8),(0,-8),(-2,-12)])
        b.poly(j[2],[(3,-18),(6,-17),(8,-15),(8,-11),(6,-8),(5,-1),(4,1),(2,1),(3,-6),(4,-13)])
        b.poly(j[2],[(-6,-18),(-4,-18),(-2,-14),(-1,-7),(0,0),(-4,1),(-6,-1),(-6,-6),(-8,-12)])
        b.line('#f0d89e',[(-6,-10),(-3,-11),(-2,-11)])
        b.line('#f0d89e',[(4,-11),(6,-12),(8,-12)])
        b.line(j[0],[(-7,-1),(-1,0)])
        b.box(t[0],-5,1,9,2);b.box(t[3],1,1,2,2)
        worker_head(p,(sh[0]+2,sh[1]-7))
    arm(arms[1])
    return im

def cosine(value):
    return sin(value+pi/2)

def main():
    sheet=Image.new('RGB',(96*8,88*3),'#34394b')
    for row,actor in enumerate(('elder','child','worker')):
        for action,count in [('idle',6),('walk',8)]:
            strip=Image.new('RGBA',(96*count,88))
            for i in range(count):
                image=civilian(actor,action,i)
                l,t,r,b=image.getbbox()
                assert 0<l<r<96 and 0<t<b<=81,(actor,action,i,(l,t,r,b))
                strip.alpha_composite(image,(i*96,0))
                if action=='walk': sheet.paste(image,(i*96,row*88),image)
            strip.save(DEST/(actor+'_'+action+'.png'),optimize=True)
    sheet.resize((sheet.width*2,sheet.height*2),Image.Resampling.NEAREST).save(HERE/'residents.png')

if __name__=='__main__':
    main()
