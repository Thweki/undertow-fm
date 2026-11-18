"""Period-specific task props for the photographic A-side."""
from paint import *
from details import gauge,reel
N='#263c3c';G='#81997a';F='#b9c59a';P='#ac9e78'
def phone(a):
    # Payphone pedestal: faded green case, hanging handset, tactile rotary dial.
    a.e(14,73,36,6,'#384f48');a.box(25,54,11,21,'#526b58');a.box(26,56,3,16,'#8e9d7f')
    box3(a,15,23,31,34,'#6c856c',5)
    a.box(17,25,27,8,N);a.text(20,26,'TEL',F,7,bold=True)
    a.e(30,36,12,12,'#c6bb91');a.e(33,39,6,6,'#60775e')
    for x,y in [(34,36),(38,38),(39,42),(34,45),(30,41)]:a.box(x,y,1,2,'#566b58')
    a.l([(23,33),(19,35),(18,37),(18,47),(21,51),(24,50)],N,3)
    a.l([(21,35),(19,37),(19,46)],'#81917a')
    a.cable(21,50,30,53,7,'#334e43',2);a.box(33,51,8,2,N)
def ledger(a):
    box3(a,15,33,32,42,'#738172',5)
    for y in [36,53]:
        a.box(17,y,28,16,'#526b5e');a.box(18,y+1,26,13,'#85947e')
        a.box(24,y+3,12,4,'#c8c4a0');a.box(26,y+4,8,1,'#617864');a.box(26,y+9,8,2,N)
    a.p([(20,38),(24,36),(43,64),(39,66)],'#c1b28a');a.e(28,47,8,8,'#a36956');a.box(30,50,4,1,'#d1af88')
def electric(a):
    box3(a,17,38,29,37,'#738874',5);a.box(20,41,23,19,'#3e5c4d')
    for i in range(3):a.e(22+7*i,43,5,5,[F,'#cea780','#80a483'][i])
    a.l([(32,55),(39,42)],N,5);a.l([(32,55),(38,43)],'#bd9c71',2);a.box(35,40,7,4,'#bf8869')
    for j in range(3):a.box(21,64+j*3,18,1,'#4d6a59')
def packet(a):
    a.p([(12,62),(38,56),(51,64),(47,73),(24,77),(11,70)],'#6e7960')
    a.p([(14,61),(38,55),(51,62),(48,70),(24,74),(12,68)],'#d0bd95')
    a.l([(14,61),(30,66),(46,59)],'#ae9c7b');a.l([(25,58),(38,71)],'#8f7760',2)
    a.e(27,61,8,7,'#a57358');a.box(29,64,4,1,'#cba17b')
def telex(a):
    a.box(13,61,39,5,N);a.box(17,64,3,11,'#657661');a.box(45,64,3,11,'#657661')
    box3(a,19,42,27,17,'#607661',4);a.box(22,42,21,4,N)
    a.p([(23,43),(22,29),(26,28),(30,29),(42,28),(42,41)],'#cfca9c')
    for j in range(3):a.box(25,32+j*3,12+j%2*2,1,'#85927a')
    a.p([(16,59),(20,49),(43,49),(49,56),(44,61),(17,61)],'#9da589')
    for j in range(2):
        for i in range(6):a.box(22+i*3-j,52+j*3,2,2,N)
    a.box(22,58,16,1,'#687962')
def capsule(a):
    box3(a,17,44,29,30,'#657e68',6)
    a.box(20,46,23,11,'#b7b68f');a.text(22,49,'POST',N,7,bold=True)
    a.box(22,59,18,3,N);a.box(20,67,10,1,'#91a389')
if __name__=='__main__':
    atlas=Image.new('RGBA',(384,80))
    for i,fn in enumerate([phone,ledger,electric,packet,telex,capsule]):
        a=Art(64,80);fn(a);atlas.paste(a.im,(64*i,0))
    atlas.save(OUT/'archive_props.png',optimize=True)
