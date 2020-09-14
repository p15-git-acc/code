\p100

X=10^20;
X0=X;
sw2=7056/2*2^34;
print("sqrt X0=",floor(sqrt(X0)));
pi_sqrt_X0=455052511;
lam=4628846093743418.0/2^76;
lam2=lam*lam/2;

/* from read_zeros */
T1=1.01246e8;
NT1=251297742;

/* returns G(1/2+It) */
GG(t)=-real(intnum(s=0.5,-1,exp(lam2*(s+I*t)^2)*X0^(s+I*t)/(s+I*t)));
print("G(1/2+T1)=",GG(T1));

B=X+sw2;
A=X-sw2+1;

print("X=",X);
print("A=",A);
print("B=",B);

a=intnum(t=0.5,1.0,exp(lam2*t^2)*X0^t/t);
print("a=G(1)-G(1/2)=",a);

b=real(I*intnum(t=0,14,exp(lam2*(1/2+I*t)^2)*X0^(1/2+I*t)/(1/2+I*t)));
print("b=G(1/2+14i)-G(1/2)=",b);

/* sum of zeros */
d=1.2866462520256657552628052587e7;
c=1.0354543235166883786623220910905761000e7;

print("check c=",-GG(14));
print("c=G(1/2+inf)-G(1/2+14i)=",c);
print("d= N G(1/2+inf)- sum G(rho) - G(1/2+14i)=",d);

/* sum of phi */
e=-1.350836218592e5;
print("e=sum phi(p)=",e);

phi(t,x,lam)=1/2*erfc(log(t/x)/sqrt(2)/lam);

phi1(t,x,lam)=if(t<x,1-phi(t,x,lam),-phi(t,x,lam));

n=2;
res=0;
while(2^n<=B,x=nextprime(A^(1/n));\
   while(x^n<=B,res=res+1/n*phi1(x^n,X0,lam);\
      x=nextprime(x+1););\
   n=n+1;);
f=res;
print("f=sum 1/n phi(p^n) n>1 =",f);

g=sum(m=3,n,1/m*primepi(X0^(1/m)))*1.0+pi_sqrt_X0/2.0;
print("g=sigma 1/n pi(X0^(1/n)) n>1 =",g);




/* sum of primes in X-X0 */
h=0;

/* sum of G(T1) */

k=GG(T1)*(NT1*2-3);
print("k=(2N-3)G(1/2+T1i)=",k);
print("published value=",2220819602560918840);
print("my calc        =",a-b+2*d-3*c+e+f-g+h-log(2)-k);
print("diff=",2220819602560918840-(a-b+2*d-3*c+e+f-g+h-log(2)-k));
