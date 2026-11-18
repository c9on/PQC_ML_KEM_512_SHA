#!/usr/bin/env python3
# Independent readable reference used to debug RTL intermediate values.
# This is verification support, not part of the synthesizable hardware design.

from hashlib import sha3_512, sha3_256, shake_128, shake_256

# ML-KEM-512 constants used to every polynomial operation.
Q = 3329

def modq(x): return x%Q

def zeta(k):
    br=int(f'{k:07b}'[::-1],2)
    return pow(17,br,Q)

def ntt(a):
    # Cooley-Tukey NTT in the same coefficient order as the SystemVerilog code.
    a=list(a);k=1;l=128
    while l>=2:
        for bs in range(0,256,2*l):
            z=zeta(k);k+=1
            for j in range(bs,bs+l):
                t=z*a[j+l]%Q
                a[j+l]=(a[j]-t)%Q
                a[j]=(a[j]+t)%Q
        l//=2
    return a

def intt(a):
    a=list(a);k=127;l=2
    while l<=128:
        for bs in range(0,256,2*l):
            z=zeta(k);k-=1
            for j in range(bs,bs+l):
                t=a[j]
                a[j]=(t+a[j+l])%Q
                a[j+l]=z*(a[j+l]-t)%Q
        l*=2
    return [x*3303%Q for x in a]

def basemul(a,b):
    out=[0]*256
    for i in range(64):
        z=zeta(64+i)
        out[4*i]=(a[4*i]*b[4*i]+z*a[4*i+1]*b[4*i+1])%Q
        out[4*i+1]=(a[4*i]*b[4*i+1]+a[4*i+1]*b[4*i])%Q
        out[4*i+2]=(a[4*i+2]*b[4*i+2]-z*a[4*i+3]*b[4*i+3])%Q
        out[4*i+3]=(a[4*i+2]*b[4*i+3]+a[4*i+3]*b[4*i+2])%Q
    return out

def sample_ntt(seed):
    s=shake_128(seed).digest(1024);out=[];i=0
    while len(out)<256:
        d1=(s[i]|s[i+1]<<8)&4095;d2=(s[i+1]>>4)|(s[i+2]<<4)
        if d1<Q:out.append(d1)
        if d2<Q and len(out)<256:out.append(d2)
        i+=3
    return out

def cbd(stream,eta):
    out=[]
    for i in range(256):
        a=sum((stream[(2*eta*i+j)//8]>>((2*eta*i+j)%8))&1 for j in range(eta))
        b=sum((stream[(2*eta*i+eta+j)//8]>>((2*eta*i+eta+j)%8))&1 for j in range(eta))
        out.append((a-b)%Q)
    return out

def noise(sigma,eta,nonce):
    n=256*2*eta//8
    return cbd(shake_256(sigma+bytes([nonce])).digest(n),eta)

def bits_pack(a,bits):
    x=sum(v<<(bits*i) for i,v in enumerate(a))
    return x.to_bytes(bits*256//8,'little')

def bits_unpack(b,bits):
    x=int.from_bytes(b,'little');return [(x>>(bits*i))&((1<<bits)-1) for i in range(256)]

def keygen(d, z):
    # G(d || k) yields rho and sigma. The secret and error vectors are sampled
    # from sigma, while rho expands the public matrix A.
    g=sha3_512(d+b'\x02').digest();rho,sigma=g[:32],g[32:]
    A=[[sample_ntt(rho+bytes([j,i])) for j in range(2)] for i in range(2)]
    s=[noise(sigma,3,i) for i in range(2)];e=[noise(sigma,3,i) for i in range(2,4)]
    sh=[ntt(v) for v in s]
    t=[]
    for i in range(2):
        b=[(x+y)%Q for x,y in zip(basemul(A[i][0],sh[0]),basemul(A[i][1],sh[1]))]
        eh=ntt(e[i])
        t.append([(x+y)%Q for x,y in zip(b,eh)])
    pk=bits_pack(t[0],12)+bits_pack(t[1],12)+rho
    dk=b''.join(bits_pack(x,12) for x in sh)+pk+sha3_256(pk).digest()+z
    return pk,dk,dict(rho=rho,sigma=sigma,A=A,s=s,e=e,sh=sh,t=t)

def compress(a,bits): return [(((x<<bits)*1+Q//2)//Q)&((1<<bits)-1) for x in a]
def decompress(a,bits): return [(x*Q+(1<<(bits-1)))>>bits for x in a]
def encode_msg(m): return [1665 if (m[i//8]>>(i%8))&1 else 0 for i in range(256)]
def decode_msg(p): return bytes(sum((1 if Q//4<v<3*Q//4 else 0)<<(i%8) for i,v in enumerate(p[b:b+8])) for b in range(0,256,8))

def pke_encrypt(pk,m,coins):
    rho=pk[-32:];t=[bits_unpack(pk[:384],12),bits_unpack(pk[384:768],12)]
    A=[[sample_ntt(rho+bytes([j,i])) for j in range(2)] for i in range(2)]
    r=[ntt(noise(coins,3,i)) for i in range(2)]
    e=[noise(coins,2,i) for i in range(2,4)];e2=noise(coins,2,4)
    u=[]
    for i in range(2):
      b=[(a+c)%Q for a,c in zip(basemul(A[0][i],r[0]),basemul(A[1][i],r[1]))]
      u.append([(x+y)%Q for x,y in zip(intt(b),e[i])])
    v=intt([(a+b)%Q for a,b in zip(basemul(t[0],r[0]),basemul(t[1],r[1]))])
    v=[(a+b+c)%Q for a,b,c in zip(v,e2,encode_msg(m))]
    return bits_pack(compress(u[0],10),10)+bits_pack(compress(u[1],10),10)+bits_pack(compress(v,4),4)

def pke_decrypt(ct,dk):
    s=[bits_unpack(dk[:384],12),bits_unpack(dk[384:768],12)]
    u=[decompress(bits_unpack(ct[:320],10),10),decompress(bits_unpack(ct[320:640],10),10)]
    v=decompress(bits_unpack(ct[640:],4),4)
    w=intt([(a+b)%Q for a,b in zip(basemul(s[0],ntt(u[0])),basemul(s[1],ntt(u[1])))])
    return decode_msg([(a-b)%Q for a,b in zip(v,w)])

def encaps(ek,m):
    # The KEM derives Kbar and encryption coins from G(m || H(EK)).
    h=sha3_256(ek).digest();g=sha3_512(m+h).digest();kbar,coins=g[:32],g[32:]
    c=pke_encrypt(ek,m,coins);return c,kbar

def decaps(dk, ct):
    # Successful decapsulation returns Kbar. A ciphertext mismatch selects the
    # implicit-rejection value J(z || c), which is generated with SHAKE256.
    ek=dk[768:1568];h=dk[1568:1600];z=dk[1600:]
    m=pke_decrypt(ct,dk);g=sha3_512(m+h).digest();c2=pke_encrypt(ek,m,g[32:])
    good=g[:32]
    bad=shake_256(z+ct).digest(32)
    return good if c2==ct else bad

def randomized_reference_check(rounds=16):
    # Deterministic byte generation makes this test reproducible across runs.
    from hashlib import shake_256 as xof
    assert intt(ntt([0] * 256)) == [0] * 256

    for trial in range(rounds):
        stream=xof(b'PQC_ML_KEM_RANDOM\0'+trial.to_bytes(4,'little')).digest(32*6)
        a=[int.from_bytes(stream[2*i:2*i+2],'little')%Q for i in range(256)]
        b=[int.from_bytes(stream[512+2*i:514+2*i],'little')%Q for i in range(256)]
        assert intt(ntt(a))==a

        product=basemul(ntt(a),ntt(b))
        restored=intt(product)
        direct=[]
        for k in range(256):
            total=0
            for j in range(256):
                total = (total + (a[j]*b[k-j] if k>=j else -a[j]*b[256+k-j]))%Q
            direct.append(total)
        assert restored==direct

        assert bits_unpack(bits_pack(a,12),12)==a
        values10=[x&1023 for x in a]
        assert bits_unpack(bits_pack(values10,10),10)==values10
        values4=[x&15 for x in a]
        assert bits_unpack(bits_pack(values4,4),4)==values4

        d=stream[:32]
        z=stream[32:64]
        ek,dk,_=keygen(d,z)
        message=stream[64:96]
        ct,k=encaps(ek,message)
        assert decaps(dk,ct)==k

    return rounds

if __name__=='__main__':
 import json,urllib.request,sys
 d=bytes.fromhex(sys.argv[1]) if len(sys.argv)>1 else bytes.fromhex('47B893474672BA92E4B12EE44FB32953AF8E8503B5FB471D1614FB8A021A660A')
 z=bytes.fromhex(sys.argv[2]) if len(sys.argv)>2 else bytes.fromhex('1F8CB39E9E30BC458A0DC5408884B1187FB217018DF760FA57317703B844A0A9')
 ek,dk,x=keygen(d,z)
 print('rho',x['rho'].hex());print('ek',ek.hex().upper());print('dk',dk.hex().upper())
 randomized_reference_check()
 print('randomized reference checks: 16/16 PASS')
