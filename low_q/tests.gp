Q=7
A=64/5.0
q=10^8*A
B=q/A
eta_=1-2^(-20)
E_e(t)=zeta(3/2)*Pi^(-1/4)*abs(gamma(1/4+(t/2)*I))*exp(Pi/4*eta_*t)*sqrt(Q/2/Pi*abs(1/2+t))
u(x)=Pi/4*eta_*I+x
delta_=Pi/2*(1-abs(eta_))
X(x)=Pi*delta_*exp(2*x-delta_)/Q
epsilon_=1
Fhat_e(x)=2*epsilon_*exp(u(x)/2)*Q^(-1/4)*exp(-Pi*exp(2*u(x))/Q)
log_Fhat_e(x)=log(2)+log(epsilon_)+u(x)/2-1/4*log(Q)-Pi*exp(2*u(x))/Q
beta_e(t)=Pi/4-1/2*atan(1/(2*t))-4/Pi^2/abs(t^2-1/4)
