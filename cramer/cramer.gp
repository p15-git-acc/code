\p200

h(B,t)=(t-B-g1)/(B*t*(al*(t-g1))^3)+(t+B+g1)/(B*t*(al*(t+g1))^3);

g1=14.1347251417346937904572519835624;

al=log(2)/6;

T0=446000;

g(t)=h(10.876,t)*(log(t/(2*Pi))+0.28/t);

print(intnum(t=T0,1e10,h(10.876,t)*(log(t/(2*Pi))+0.28/t))+0.56*h(10.876,T0)*log(T0));

print(intnum(w=0,1/T0,g(1/w)/w^2)+0.56*h(10.876,T0)*log(T0));