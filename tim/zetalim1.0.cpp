//
// zetalim1.0.cpp
//
// DJ Platt Jan 2014
//
// Find upb on |zeta(1/2+it)|
//
#include "inttypes.h"
#include "../includes/int_double12.0.h"

//
// simple version of Euler Mac for Zeta(s) with sum of length N
//
int_complex zeta(const int_complex &s, uint64_t N)
{
  int_complex res(1);
  for(uint64_t n=2;n<=N;n++)
    res+=pow(n,-s);
  res+=pow(N,-s+1)/(s-1)-pow(N,-s)/2;
  int_complex term=s*pow(N,-s-1)/12;
  res+=term;
  term=s*(s+1)*(s+2)*pow(N,-s-3)/720;
  res-=term;
  int_double factor=mod(s+1)/(s.real+1);
  int_double error=factor*mod(term);
  error.left=error.right;
  res.real+=error;
  res.imag+=error;
  return(res);
} 

int_double theta_log_pi_2,theta_err,theta_pi8;;
//
// theta(t)=1/2(Im(lngamma(1/4+it/2)-lngamma(1/4-it/2))-tlog(pi))
// the error is simply |theta(200)-mytheta(200)|
// 
int_double theta(int_double t)
{
  //int_double res=t*0.5*log(t/d_two_pi)-0.5*t-d_pi/8 +d_one/(t*48)+d_one*7/(5760*t*t*t);
  int_double res=t*(log(sqr(t)*4+1)-0.5-theta_log_pi_2)-theta_pi8;
  return(res+theta_err);
}

int_double c0,rs_err;
//
// Riemann Siegel, a=sqrt(t/2Pi)
// sqrts[n]=1/sqrt(n)
// logs(n)=log(n)
//
// The first and only C_n term C_0=cos(2pi(p^2-p-1/16))/cos(2pi p) is replaced
// by [0.382,0.984]/sqrt(a)
// 
int_double rs(int_double t, int_double a, int_double *logs, int_double *sqrts)
{
  uint64_t N=floor(a.left);
  int_double rho=a-N;
  int_double res=0,si,co;
  for(uint64_t n=1;n<=N;n++)
    {
      sin_cos(t*logs[n]-theta(t),&si,&co); // sin is thrown away
      res+=co*sqrts[n];
    }
  res+=res;
  if(N&1)
    res+=c0/sqrt(a);
  else
    res-=c0/sqrt(a);
  int_double tp=pow(t,-1.25); // Gabcke 0.053*t^(-5/4) for t>=200
  int_double err=rs_err*tp;
  err.left=err.right;
  res+=err;
  return(sqrt(sqr(res)));
}

int main(int argc, char **argv)
{
  printf("Command Line:- %s ",argv[0]);
  for(uint64_t i=1;i<argc;i++)
    printf("%s ",argv[i]);
  printf("\n");
  if(argc!=6)
    {
      printf("Usage:- %s <start> <end> <delta num> <delta den> <outfile>.\n",argv[0]);
      exit(0);
    }

  // set up the SSE system for rounding and initialise constants
  _fpu_rndd();

  // this is how much we step by each time
  double full_delta=atof(argv[3])/atof(argv[4]);
  double ts=atof(argv[1]);
  if(ts<200.0)
    {
      printf("Gabcke's bound only works for t>=200.o. Exiting.\n");
      exit(0);
    }
  double te=atof(argv[2]);
  uint64_t MAX_N=floor(sqrt(atof(argv[2])/6.283));
  int_double *logs=(int_double *)malloc(sizeof(int_double)*(MAX_N+1));
  int_double *sqrts=(int_double *)malloc(sizeof(int_double)*(MAX_N+1));
  for(uint64_t n=1;n<=MAX_N;n++)
    {
      logs[n]=log(int_double(n));
      sqrts[n]=d_one/sqrt(int_double(n));
    }

  c0=int_double(382,924); // the c0 term in RS is always in this
  c0/=1000;
  rs_err=53;
  rs_err/=1000.0;
  theta_log_pi_2=log(d_pi_2); // log(Pi/2)
  theta_pi8=d_pi*0.125; // Pi/8
  theta_err=int_double(-21,21);
  theta_err/=100000.0;
  FILE *outfile=fopen(argv[5],"wb");
  if(!outfile)
    {
      printf("Failed to open file %s for binary output. Exiting.\n");
      exit(0);
    }

  double largest=0.0;
  while(ts<te)
    {
      int_double t,res;
      t=int_double(ts,ts+full_delta);
      //print_int_double_str("t=",t);
      int_double(a)=sqrt(t/d_two_pi);
      uint64_t N=floor(a.left);
      if(floor(-a.right)!=N)
	{
	  //print_int_double_str("a brackets an integer ",a);
	  int_double t1,t2,t3;
	  t1.left=t.left;
	  t3.right=t.right;
	  uint64_t N2=(N+1)*(N+1);
	  int_double temp=d_two_pi*N2;
	  t1.right=-temp.left;
	  t2.left=temp.left;
	  t2.right=temp.right;
	  t3.left=-temp.right;
	  a=sqrt(t1/d_two_pi);
	  res=rs(t1,a,logs,sqrts);
	  if(-res.right>largest)
	    {
	      largest=-res.right;
	      //print_int_double_str("",res);
	      fwrite(&t1.left,sizeof(double),1,outfile);
	      fwrite(&largest,sizeof(double),1,outfile);
	      printf("new largest at %60.58e =[%60.58e,%60.58e]\n",t1.left,res.left,largest);
	    }
	  res=mod(zeta(int_complex(int_double(0.5),t2),floor(t2.left)));
	  if(-res.right>largest)
	    {
	      largest=-res.right;
	      fwrite(&t2.left,sizeof(double),1,outfile);
	      fwrite(&largest,sizeof(double),1,outfile);

	      //print_int_double_str("",res);
	      printf("new largest at %60.58e =[%60.58e,%60.58e]\n",t2.left,res.left,largest);
	    }
	  a=sqrt(t3/d_two_pi);
	  res=rs(t3,a,logs,sqrts);
	  if(-res.right>largest)
	    {
	      largest=-res.right;
	      fwrite(&t3.left,sizeof(double),1,outfile);
	      fwrite(&largest,sizeof(double),1,outfile);

	      //print_int_double_str("",res);
	      printf("new largest at %60.58e =[%60.58e,%60.58e]\n",t3.left,res.left,largest);
	    }
	}
      else
	{
	  res=rs(t,a,logs,sqrts);
	  if(-res.right>largest)
	    {
	      //print_int_double_str("t=",t);
	      largest=-res.right;
	      fwrite(&t.left,sizeof(double),1,outfile);
	      fwrite(&largest,sizeof(double),1,outfile);

	      //print_int_double_str("",res);
	      printf("new largest at %60.58e =[%60.58e,%60.58e]\n",t.left,res.left,largest);
	    }
	}
      ts+=full_delta;
      //printf("ts=%30.28e\n",ts);
    }
  return(0);
}
