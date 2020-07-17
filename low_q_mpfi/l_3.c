#include "stdlib.h"
#include "stdio.h"
#include "gmp.h"
#include "mpfr.h"
#include "../includes/mpfi.h"
#include "../includes/mpfi_io.h"
#include "../includes/mpfi_c.h"
#include "./f_defs.h"
#include "../includes/mpfi_fft.h"


void print_usage()
{
  printf("Usage:- f_hat_terms prec outfile.\n");
  exit(1);
}

unsigned long int calc_N(unsigned long int q)
{
  unsigned long int res=1;
  double target=(ceil(QT/(10.0*q))*10.0+30.0)/one_over_A*7.5;
  //printf("Trying to get to N0=%ld\n",(int) target);
  while(res<target) res<<=1;
  //printf("FFT length set to %ld\n",res);
  return(res);
}

// results in attenuation of about 1/10 at height QT/q+30
double calc_eta(unsigned int q)
{
  return(1-7.03/(QT/q+30.0));
}

inline int gcd (unsigned int a, unsigned int b)
//Euclid algorithm gcd
{
	unsigned int c;
	while(a!=0)
	{
		c=a;
		a=b%a;
		b=c;
	};
	return(b);
};

inline int co_prime(unsigned int a, unsigned int b)
{
	return(gcd(a,b)==1);
};


inline unsigned int calc_M(double x, double log2byq, double cosetaetc)
{
  double b=log2byq+x*1.5;
  //printf("x=%e\nlog(2)-log(q)*0.75=%e\ncos(eta)=%e\n",x,log2byq,cosetaetc);
  //printf("b=%e\n",b);
  //printf("lambda=%e\n",exp(2*x)*cosetaetc);
  if(b>TARGET_ACC)
    return(1);
  return((unsigned int) sqrt((TARGET_ACC-b)/exp(2*x)/cosetaetc)+1);
}

mpfi_t b,a,r,lambda,d_small;
mpfi_c_t inner_exp,c_small;
#define MAX_LOG_N (1000)
mpfi_t log_n[MAX_LOG_N+1];

inline void F_hat_err(mpfi_ptr res, mpfi_ptr x, mpfi_ptr pi_sindelta_by_q, mpfi_ptr mlog2byq, unsigned int m)
{
  mpfi_add(lambda,x,x);
  mpfi_exp(lambda,lambda);
  mpfi_mul(lambda,lambda,pi_sindelta_by_q);
  //printf("lambda=");mpfi_print(lambda);
  mpfi_mul_d(b,x,1.5);
  mpfi_add(b,b,mlog2byq);
  //printf("1.5x+log2-0.75logq=");mpfi_print(b);
  mpfi_mul_ui(a,lambda,(m+1)*(m+1));
  //printf("(m+1)^2*lambda=");mpfi_print(a);
  mpfi_sub(a,b,a);
  mpfi_set_ui(b,m+1);
  mpfi_log(b,b);
  mpfi_add(a,a,b);
  //mpfi_exp(b,a);printf("a=");mpfi_print(b);
  mpfi_mul_d(r,lambda,(-3.0-2.0*m));
  mpfi_exp(r,r);
  mpfi_mul_d(r,r,(2.0+m)/(1.0+m));
  mpfi_sub_d(r,r,1.0);
  mpfi_neg(r,r);
  //printf("r=");mpfi_print(r);
  mpfi_log(r,r);
  mpfi_sub(res,a,r);
  if(mpfi_cmp_d(res,LN_SMALL)<0)
    mpfi_set(res,d_small);
  else
    {
      mpfi_exp(res,res);
      mpfi_neg(a,res);
      mpfi_put(res,a);
    }
}

void F_hat_o_term(mpfi_c_ptr res, mpfi_c_ptr outer_exp, mpfi_c_ptr exp_2_u_x, unsigned int n)
{
  //printf("F_hat_o_term called with\n");
  //printf("outer_exp=");mpfi_c_print(outer_exp);
  //printf("exp_2_u_x=");mpfi_c_print(exp_2_u_x);
  //exit(0);
  mpfi_c_mul_ui(inner_exp,exp_2_u_x,n);
  mpfi_c_mul_ui(inner_exp,inner_exp,n);
  mpfi_c_sub(inner_exp,outer_exp,inner_exp);
  //printf("Got here %d\n",__LINE__);
  if(n>MAX_LOG_N)
    {
      mpfi_set_ui(log_n[0],n);
      mpfi_log(log_n[0],log_n[0]);
      mpfi_add(inner_exp->re,inner_exp->re,log_n[0]);
    }
  else
    mpfi_add(inner_exp->re,inner_exp->re,log_n[n]);
  if(mpfi_cmp_d(inner_exp->re,LN_SMALL)<0)
    mpfi_c_set(res,c_small);
  else
    mpfi_c_exp(res,inner_exp);
  //printf("Returning- ");mpfi_c_print(res);exit(0);
}

inline unsigned int min(unsigned int x, unsigned int y)
{
  if(x<y) return(x);
  return(y);
}

int main(int argc, char **argv)
{
  long int q1,n01,n11,prec,N1,num_files,num_file;
  unsigned long int q,n0,n1,M,n,i,k,N;
  double eta,log2byq,cosetaetc,B;
  mpfi_t x,delta,logdelta,pi_sindelta_by_q,err,log2,logq;
  mpfi_t two_pi_by_B,eta_pi_by_4,mlog2byq,logpi,pibyq,pi;
  mpfi_c_t res,term,outer_exp,exp_2_u_x,u_x,*Fft_vec,*ws;
  FILE *outfile;


  if(argc!=3)
    print_usage();

  prec=atoi(argv[1]);
  if((prec<MPFR_PREC_MIN)||(prec>MPFR_PREC_MAX))
    print_usage();
  
  mpfi_c_setup(prec);

  q=3;

  eta=calc_eta(q);
  printf("eta set to %e\n",eta);

  N=calc_N(q);
  printf("N=%lu\n",N);

  Fft_vec=(mpfi_c_t *)malloc(sizeof(mpfi_c_t)*N);
  if(!Fft_vec)
    {
      printf("Failed to allocate memory for Fft_vec. Exiting.\n");
      exit(0);
    }
  ws=(mpfi_c_t *)malloc(sizeof(mpfi_c_t)*N/2);
  if(!ws)
    {
      printf("Failed to allocate memory for ws. Exiting.\n");
      exit(0);
    }
  for(n=0;n<N/2;n++)
    {
      mpfi_c_init(Fft_vec[n]);
      mpfi_c_init(ws[n]);
    }
  for(;n<N;n++)
    mpfi_c_init(Fft_vec[n]);
  printf("Initialising Fft Vectors....");
  initfft(N,ws);
  printf(" Done\n");

  B=N*one_over_A;

  outfile=fopen(argv[2],"wb");
  if(!outfile)
    {
      printf("Failed to open %s for binary output. Exiting.\n",argv[5]);
      exit(1);
    }
  fwrite(&q,sizeof(unsigned int),1,outfile);
  mpfi_init(a);
  mpfi_init(r);
  mpfi_init(lambda);
  mpfi_init(b);
  mpfi_init(x);
  mpfi_init(two_pi_by_B);
  mpfi_init(delta);
  mpfi_init(pi);
  mpfi_init(eta_pi_by_4);
  mpfi_const_pi(pi);
  mpfi_div_d(two_pi_by_B,pi,B/2.0);
  //mpfi_write_bin(outfile,two_pi_by_B);
  mpfi_init(pibyq);
  mpfi_div_ui(pibyq,pi,q);
  mpfi_init(logpi);
  mpfi_log(logpi,pi);
  mpfi_mul_d(delta,pi,(1.0-fabs(eta))/2.0);
  //mpfi_write_bin(outfile,delta);
  mpfi_init(logdelta);
  mpfi_log(logdelta,delta);
  //mpfi_write_bin(outfile,logdelta);
  mpfi_mul_d(eta_pi_by_4,mpfi_pi_by_4,eta);
  //mpfi_write_bin(outfile,eta_pi_by_4);
  mpfi_init(pi_sindelta_by_q);
  mpfi_sin(pi_sindelta_by_q,delta);
  mpfi_mul(pi_sindelta_by_q,pi_sindelta_by_q,pi);
  mpfi_div_ui(pi_sindelta_by_q,pi_sindelta_by_q,q);
  //mpfi_write_bin(outfile,pi_sindelta_by_q);
  //printf("Pi*sin(delta)/q=");mpfi_print(pi_sindelta_by_q);
  mpfi_init(err);
  mpfi_c_init(term);
  mpfi_init(d_small);
  mpfi_set_d(d_small,LN_SMALL);
  mpfi_exp(d_small,d_small);
  mpfi_neg(err,d_small);
  mpfi_put(d_small,err);
  mpfi_c_init(c_small);
  mpfi_set(c_small->re,d_small);
  mpfi_set(c_small->im,d_small);
  mpfi_c_init(res);
  mpfi_c_init(outer_exp);
  mpfi_c_init(inner_exp);
  mpfi_c_init(u_x);
  mpfi_c_init(exp_2_u_x);
  mpfi_init(log_n[0]);
  mpfi_init(log_n[1]);
  mpfi_set_ui(log_n[1],0);
  for(n=1;n<=MAX_LOG_N;n++)
    {
      mpfi_init(log_n[n]);
      mpfi_set_ui(log_n[n],n);
      mpfi_log(log_n[n],log_n[n]);
    }
  mpfi_init(log2);
  mpfi_init(logq);
  mpfi_set_d(log2,2.0);
  mpfi_log(log2,log2);
  //mpfi_write_bin(outfile,log2);
  mpfi_set_ui(logq,q);
  mpfi_log(logq,logq);
  //mpfi_write_bin(outfile,logq);
  mpfi_mul_d(logq,logq,0.75);
  mpfi_init(mlog2byq);
  mpfi_sub(mlog2byq,log2,logq);
  cosetaetc=cos(M_PI*eta/2.0)*M_PI/q;
  log2byq=log((double) 2.0)-log((double) q)*0.75;
  mpfi_set(u_x->im,eta_pi_by_4);
  for(n=0;n<=N/2;n++)
    {
      mpfi_mul_ui(x,two_pi_by_B,n);
      mpfi_set(u_x->re,x);
      mpfi_c_mul_d(exp_2_u_x,u_x,2.0);
      mpfi_c_exp(exp_2_u_x,exp_2_u_x);
      mpfi_c_mul_i(exp_2_u_x,exp_2_u_x,pibyq);
      //printf("exp(2U(x))*pi/q=");mpfi_c_print(exp_2_u_x);
      mpfi_c_mul_d(outer_exp,u_x,1.5);
      mpfi_add(outer_exp->re,outer_exp->re,log2);
      mpfi_sub(outer_exp->re,outer_exp->re,logq);
      M=calc_M(2.0*n*M_PI/B,log2byq,cosetaetc);
      //if((n%1000)==0) {printf("n=%ld\n",n);printf("M=%d\n",M);}
      //fwrite(&M,sizeof(unsigned int),1,outfile);
      
      //F_hat_err(Fft_vec[n]->re,x,pi_sindelta_by_q,mlog2byq,M);
      mpfi_set_ui(Fft_vec[n]->re,0);mpfi_set_ui(Fft_vec[n]->im,0);
      //mpfi_write_bin(outfile,err);
      //printf("err=");mpfi_print(err);

      mpfi_set_ui(res->re,0);
      mpfi_set_ui(res->im,0);
      for(k=1;k<=M;k+=q)
	{
	  F_hat_o_term(term,outer_exp,exp_2_u_x,k);
	  mpfi_c_inc(res,term);
	}
      mpfi_c_add(Fft_vec[n],Fft_vec[n],res);

      mpfi_set_ui(res->re,0);
      mpfi_set_ui(res->im,0);
      for(k=2;k<=M;k+=q)
	{
	  F_hat_o_term(term,outer_exp,exp_2_u_x,k);
	  mpfi_c_inc(res,term);
	}
      mpfi_c_sub(Fft_vec[n],Fft_vec[n],res);
    }
  for(n=N/2+1;n<N;n++)
    mpfi_c_conj(Fft_vec[n],Fft_vec[N-n]);

  fft(Fft_vec,N,ws);
  for(n=0;n<N;n++)
    {
      mpfi_mul(term->re,Fft_vec[n]->re,two_pi_by_B);
      
  mpfi_write_bin(outfile,term->re);
}
