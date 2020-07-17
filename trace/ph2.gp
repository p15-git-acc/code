sinc(x)=if(x==0,1,sin(x)/x)
L(s,nfz)=zetak(nfz,s)/zeta(s);
nfz4=zetakinit(x^2+4);
nfz3=zetakinit(x^2+3);
C0=zeta(3)/(16*Pi^3)-(2*L(2,nfz4)+sqrt(27)*L(2,nfz3))/(4*Pi^2)\
-(log(2)/12-1/2-Euler/8+suminf(j=2,(-1)^j*zeta(j)*2^(-j)/(j+1))/2)/(3*Pi);
B=0.2729558044747424323066650413095830368239919675;
eta0hat(t)=
{
  t=abs(t);
  if(t>=1,return(0));
	Pi^2/(4+Pi^2)*(
    2*Pi^2/3*(1-t)^3+4*(1-t)*(1-cos(Pi*t))-8/Pi*sin(Pi*t))
}
phi0hat(y)=
{
  local(S);
  y=abs(y);
  if(y>=1,return(0));
  if(y<0.001,
    return(subst(Pol(subst(p*x^2/sin(p*x)*(1+p*(1-x)/tan(p*x)),p,Pi)),x,y));
  );
  if(y>.999,
    return(subst(Pol(subst(p*(1-x)^2/sin(p*x)*(1-p*x/tan(p*x)),p,Pi)),x,1-y));
  );
  Pi*y^2/sin(Pi*y)*(1+Pi*(1-y)/tan(Pi*y))
}
phihat(t,X,d)=phi0hat(t/X)+d*t^2/(12*X^3)*\
  (2*eta0hat(t/d)+eta0hat((t+X)/d)+eta0hat((t-X)/d))
V(r,X,d)=
{
	local(Xr,dr);
	Xr=X*r; dr=d*r;
(cos(Pi*Xr)/Pi)^2/X*(
	Xr*psi'(1/2-Xr)+1-1/12/Xr^2+(
		2*sinc(Pi*dr)^2+sinc(Pi*(dr+1/2))^2+sinc(Pi*(dr-1/2))^2
	)/24/(1+4/Pi^2)/Xr^2
)
}
F(r,X,d)=V(-abs(r),X,d);
F0hat(y)=
{
  y=abs(y);
  if(y<0.001,
    return(subst(Pol(subst(
      (1-p*x^2/sin(p*x)*(1+p*(1-x)/tan(p*x)))/(2*p*x)^2,
    p,Pi)),x,y));
  );
  (1-phi0hat(y))/(2*Pi*y)^2
}
Fhat(t,X,d)=F0hat(t/X)/X^2-d/(48*Pi^2*X^3)*\
  (2*eta0hat(t/d)+eta0hat((t+X)/d)+eta0hat((t-X)/d))

glinit(X,d)=
{
  local(Seta0);
  Seta0=p^2/(4+p^2)*(2*p^2/3*(1-x)^3+4*(1-x)*(1-cos(p*x))-8/p*sin(p*x));
  SFhat=(1-p*x^2/sin(p*x)*(1+p*(1-x)/tan(p*x)))/(2*p*x)^2;
  SFhat=subst(SFhat,x,x*Xinv)*Xinv^2-Xinv^3/(24*p^2)/dinv*subst(Seta0,x,x*dinv);
  SFhat=(polcoeff(SFhat,0)-SFhat)*(
1/(12*sinh(p*x)*tanh(p*x))-1/(4*cosh(p*x))-4*cosh(p*x)/(3+6*cosh(2*p*x))
+(1-1/tanh(p*x/2))/2
  );
  SFhat=Pol(SFhat);
  SFhat=subst(SFhat,p,Pi);
  SFhat=subst(SFhat,Xinv,1/X);
  SFhat=subst(SFhat,dinv,1/d);
}

IFX(t,X,d)=
{
  if(abs(t)<.001,return(subst(SFhat,x,t)));
  (Fhat(0,X,d)-Fhat(t,X,d))*(
1/(12*sinh(Pi*t)*tanh(Pi*t))-1/(4*cosh(Pi*t))-4*cosh(Pi*t)/(3+6*cosh(2*Pi*t))
+(1-1/tanh(Pi*t/2))/2
  )
}

L(t)=
{
	local(d,l,Lval,ff);
	d=quaddisc(t^2-4);
	l=round(sqrt((t^2-4)/d));
	Lval=2/sqrt(d)*quadregulator(d)*qfbclassno(d);
	ff=factor(l);
	Lval *= prod(i=1,matsize(ff)[1],
		1+(ff[i,1]-kronecker(d,ff[i,1]))*(ff[i,1]^ff[i,2]-1)/(ff[i,1]-1)
	);
	Lval/l
}

printD(X,es)=
{
	local(m,logp,logm,n);
	logm=Pi*(X+es);
	m=exp(logm);
	for(t=3,m,
		write("outfile",log((t+sqrt(t^2-4))/2)/Pi", "L(t)/Pi);
	);
	forprime(myp=2,m,
		logp=log(myp);
		n=floor(logm/logp);
		for(j=1,n,
			write("outfile",j*logp/Pi", "logp/myp^j/Pi);
		);
	);
}

intkF(X,d)=
{
  glinit(X,d);
  (1/8+1/3/sqrt(3)+(log(2*Pi)+2*Euler)/(2*Pi))*Fhat(0,X,d)
  +intnum(t=0,d,IFX(t,X,d))
  +intnum(t=d,X-d,IFX(t,X,d))
  +intnum(t=X-d,X,IFX(t,X,d))
  +intnum(t=X,X+d,IFX(t,X,d))
  +intnum(t=X+d,20,IFX(t,X,d))
}

k(r)=r*tanh(Pi*r)/12+(1/8+cosh(Pi*r/3)/sqrt(27))/cosh(Pi*r)+\
(log(2*Pi)-2*real(psi(1+2*I*r)))/2/Pi
bound(T,X,d)=2*k(T)*Fhat(0,X,d)+2*intkF(X,d)-2*real(V(I/2,X,d))+log(T)/(24*Pi)+2*B+C0
coeff(T,X,d)=(bound(T,X,d)/T*(12*log(T)/Pi)^2-1)*log(T)

t0=2.;
cosm(z)=
{
	local(S);
	z=abs(z);
  if(z<.001,S=Pol((1-cos(x))/x^2);subst(S,x,z),(1-cos(z))/z^2)
}

lastcosmintx=lastcosminty=0;
cosmint(u)=
{
	if(u<lastcosmintx,lastcosmintx=lastcosminty=0);
	lastcosminty+=intnum(v=lastcosmintx,u,cosm(v));
	lastcosmintx=u;
	lastcosminty
}

h2(r,N)=
{
  local(P,C,i,u);
	r=abs(r);
	C=vector(2*N);
	i=0;
	P=(1-(1-x^2)^N)/x^2;
	while(P!=0,
		i++;
	  C[i]=subst(P,x,1);
		P=P';
	);
	u=2*Pi*r*t0;
	2/Pi^2/t0*(
	  1+sin(u)*sum(j=0,(i-1)/2,(-1)^j*C[2*j+1]/u^(2*j+1))
	   +cos(u)*sum(j=1,i/2,(-1)^(j+1)*C[2*j]/u^(2*j))
	)-2*r+4*r/Pi*cosmint(u)
}

evlist=\
[9.5336952613535575543442352359287703238212563951073,\
12.173008324679677849527951176395548123982471673100,\
13.779751351890738944243673281517712597155132568793,\
14.358509518259812779866942569037165495614385899197,\
16.138073171521030580198294285986003945631442885414,\
16.644259201899819943526274559368655701431681459972,\
17.738563381057377893217326361546546172005480053251,\
18.180917834530703860318308268193313938249924565418,\
19.423481470828255191633780357208524441585525600763,\
19.484713854741013364128526427872876218774062385345,\
20.106694682552312855993089155049655932352713497088,\
21.315795940203718743342744646492003215715164877854,\
21.479057544748544927232055328837290920017806459220,\
22.194673977572330430284137547218916555935764286039,\
22.785908494189873560452347844012286799395510010252,\
23.201396181227087485983665571807075014049232140231,\
23.263711537939638249731500701419828820860858884744,\
24.112352729840864032420597783483005167138747516375,\
24.419715442325423401333083241866537686184829816525,\
25.050854850761635193319499686560694501912310536623,\
25.826243712709158373904103214282024952768554585108,\
26.056917760666427077898290257446921023678703163401,\
26.152085449221348857121701803144878397135054844555,\
26.446996418046877537206903545413284685664922143139,\
27.284384011682250299622664676286770885331071129456,\
27.332708083149409902371978816269111193117772283676,\
27.775920701796835080229688218749025456520527011050,\
28.510277703146480676940503861976367896737412746257,\
28.530747692918320272383428667778701485753663433813,\
28.863394353922296953283980480817335073012294417822,\
29.137587557839534582987139112743548287457196494539,\
29.546388124146012739958042128531505982447637171704,\
30.279048499147499719734344230817437337757752493634,\
30.404327054043668759559540643083693441124611047373,\
30.410678804654256907211693159720141058380661211156,\
31.056533962106699927392873043649694498495371450576,\
31.526582196790269265357985489369033703221981250741,\
31.566275411753887112180547522148194341525251847892,\
31.916182470919620516144501198383379664558552213906,\
32.018406433624684480626700029234379408106883847635,\
32.508117759909000390164023154338977063575144058647,\
32.891170213510319715396759384913561316361685182219,\
32.932465568076204264648614139315295588077840272103,\
33.492331282391530955798608698330478562922090481394,\
33.570989627621656614706811431872207345544384186429,\
34.027884200100268842164756429587376820473647068841,\
34.185969933086346337934905899466737404337845324306,\
34.456271533031028365532816216514286774060460135895,\
34.695310409764593914142580005890022426846919927163,\
35.431664646347888968930727959834860998323984349739,\
35.502349771369401133754320852539702458524421272480,\
35.666396370996010556434344624914480209188329574191,\
35.841676432582839193500123932291435196859161617360,\
35.858673491697391806387740807793111185856893773682,\
36.331129047491750467572151874289804721003187044290,\
36.677552993145200582500899038265779677789911538201,\
36.856349495921549633865640335079428619561238690185,\
36.988815390543503232660753030333618674074403819074,\
37.295583199254317606166449130954252817199413730772,\
37.743924742038251261074761416237983600030302960079,\
37.825072290593027143748922420681180686302913906132,\
38.120900789584480188806464534209294016927289485361,\
38.303276152495011692473452298995411432476424093888,\
38.442003874425638138845557574913181199161173209775,\
38.869607097839971503269981457396472338069871387650,\
39.168084967927949285516761843299069880956723876656,\
39.407531861520826830005206550003482243256282967240,\
39.432477108822804640748261857247337700975749701308,\
39.773622619040114209959279123607945471954378940326,\
39.826867918407563723235871314640601834456682998511,\
40.272111257787927975581862896413073138456579300325,\
40.543351210450415912193755760532322602768720273575,\
40.688666444929176221142202824274962165020664052752,\
40.858127556258912580063875955677453202089422695626,\
40.880467302993544695719356424309366280681290293786,\
40.990436819090482884295916993231041977326397177205,\
41.555577673575225090832876066119328908522374864745,\
41.754473662711024490783148910581338491484388117867,\
41.883003285422720109158266385146638857879746502037,\
42.152732881302192096028564297880408126248549136608,\
42.485562254312347177451435792875581840811877566437,\
42.643488414663989361477185063373269932650620888711,\
42.646362878663809515826571855485273615909008136453,\
42.922227783555683048444095600935383988857180530518,\
42.978654893794910316704246145497936196971530332568,\
43.267182038788668174758981969880093783378162684370,\
43.385686923592821807739348586988213942091253647776,\
43.859382177341561257580937856311493033423516891329,\
44.077404761666639600687860818501722990582460219595,\
44.282109896006179489882122833339718558859529619096,\
44.294967253303561446891950343005598029337702856201,\
44.426348118615018353035543893734842953707104604663,\
44.777045954468768258007585497426573672150031411756,\
45.112201167794717361979601181912287790047731031354,\
45.287438442490419046338907586021391766974434745656,\
45.361613602148349472078852876323247414941711441841,\
45.398469531311428793971730095693640868982041723979,\
45.686379982465185298472678388740688886526604768792,\
45.782821060569262846475298603099362959001214973845,\
45.954419646098533535750019021635336777573627973611,\
46.101456321585624166119496721961596893202655512626,\
46.481402412316871539867206448906762669402852610823,\
46.566346241329440451626359813846802214748813664588,\
46.653318359993412056275801860399944790419409038883,\
46.839219361809931315283539678141483575050207046736,\
47.178366140285634293271974881937368738666363209538,\
47.422895898495430496446370099082310697660882037521,\
47.546230118323116611918641436154963526026909080692,\
47.823373159755598616362400851314260403034510515967,\
47.926558330596524481985611252818414573147553281365,\
48.039330905092031295540946249694302879146172534081,\
48.149809595124335340674325956760626337614950016447,\
48.355411968663200184977297999808677630543108155256,\
48.741666347643537886729484663448431292886591858577,\
48.840151886382499517594480328354013764126702208384,\
48.896682606075229316242502178783525152842150429760,\
48.998307654077235732270925250490742233139325721002,\
49.105724554655014326672528201511451785672359982525,\
49.439177765226928276141338623406009332539753957871,\
49.683520075255490182771707144270324367514062190748,\
49.961696290498945406597504174370985672646249686211,\
49.991220493000452812843619933028850743821670998531,\
50.089705472999376602599969749286631024790191975570,\
50.172973405273126843297909137221753562393563372795,\
50.257491383362818144022259932290966359073165658170,\
50.393019925881310222455127541850360553198826540693,\
50.801598633429649451811042358575204027621967965831,\
50.957511208847783993513085986172526782862150379475,\
50.971453932951378064452006409574988133758468145558,\
51.293455383439938190557176412159642338810569813213,\
51.402630485467240249881327048355692009082323213522,\
51.661094331319543046478569778639829396121527944314,\
51.955994514807047368555272464743880763724557372774,\
51.970228837788222439163902481053904746994035411114,\
51.988449836697687797649464441030103141785346352423,\
52.022186783040791488349905018165282486598862296914,\
52.373580290176754958467906626894523964055827967000,\
52.556094094809138379864072774440398005901146610259,\
52.558533272620932741936867967326901623558851003781,\
52.628620521519192128661681086261075860886694441312,\
53.115826766125098398772748452287488971294606987663,\
53.300573488754123048483473719600276588530136263880,\
53.368497568826540093759206832068827205479712422134,\
53.463752226278383498989767857322473764065104970662,\
53.476143340881955381710541844636364090982408757580,\
53.707586141952590628459447082014151682854894441135,\
53.907590001588990840216763816306095338333740020211,\
54.093874456141611684808020264298561503063275683962,\
54.453043837326475954336828637195638438599406688271,\
54.467778016571079459442729415408695345239008983350,\
54.472708436321006980818069898929339912939053840776,\
54.707384687590629476498811498442567080906538617724,\
54.810605269401484003649801672473433440870671996778,\
54.847492625932714362147145518439100442146365981891,\
54.972204208901140578792602074248891208810766413000,\
55.232299255995592137331185175518376919415550707086,\
55.374092779348906501686879040618084840824642413815,\
55.527995810592694351732954365768550222825172822578,\
55.616926338215062740429430307381298090985842747017,\
55.704518830340398345671257271538248024409864080596,\
56.065719074161992517180861340165582723991549628548,\
56.193796100506601707477350860538366434829251121569,\
56.258866378464486633550147427022158798535069227984,\
56.337483847368818969854921780125921278363446840682,\
56.628421712353777309504874447944227562831502290309,\
56.658820311639103861739069193401980643250622578734,\
56.893696892923352039732876905599916214819180562451,\
57.061452953843423630033164048429842051782308473995,\
57.065413263578531539966972535847583625786802515304,\
57.145483599359595383152989768281520697966310396422,\
57.540104304198099168637921204792294744011551512693,\
57.658744688025337370865846405399704406509872752252,\
57.795243852946578117402796838829202379652393971016,\
57.809934557118512396821470054811942874672565874983,\
57.827504550671616745414873892426310167759060659533,\
57.996431521724483709306097237183769717952734503369,\
58.170138307145943717125786895406267884919918104829,\
58.650939816245790185334829514591705096577658647879,\
58.672078318247471203498810619499408557699382156921,\
58.716414227015949111776969517532455130309147398573,\
58.780914456221381643637288912661171514698778821942,\
58.820201554536093766229813548164940871456593179990,\
59.023178733793325269187955611167270970976045037895,\
59.113244171765319495716992947259886887811438677049,\
59.291431139932092337113732899207477910643975957117,\
59.338405429877305251034511175509186573339709521493,\
59.701609121489964884531992190110767480674387736434,\
59.825016167881409119417492403583045925816868579813,\
59.846385680372635541272870834049912396585047518711,\
59.931236556753118386993222135941794694483814117812\
];

Ih2(t,N)=
{
  local(S);
  if(t<.001,
    S=(1-(1-x^2)^N)/x^2-N;
    S=subst(S,x,x/t0)/(Pi*t0)^2*(
1/(12*sinh(Pi*x)*tanh(Pi*x))+(2-1/tanh(Pi*x)-3/2/tanh(Pi*x/2)+tanh(Pi*x/2)/2)/4
-1/(4*cosh(Pi*x))-4*cosh(Pi*x)/(3+6*cosh(2*Pi*x))
    );
    S=Pol(S);
    return(subst(S,x,t));
  );
  if(t<t0,
    S=(1-(1-x^2)^N)/x^2-N;
    S=subst(S,x,t/t0)/(Pi*t0)^2*(
1/(12*sinh(Pi*t)*tanh(Pi*t))+(2-1/tanh(Pi*t)-3/2/tanh(Pi*t/2)+tanh(Pi*t/2)/2)/4
-1/(4*cosh(Pi*t))-4*cosh(Pi*t)/(3+6*cosh(2*Pi*t))
    );
    return(S);
  );
  S=(1/t^2-N/t0^2)/Pi^2*(
1/(12*sinh(Pi*t)*tanh(Pi*t))+(2-1/tanh(Pi*t)-3/2/tanh(Pi*t/2)+tanh(Pi*t/2)/2)/4
-1/(4*cosh(Pi*t))-4*cosh(Pi*t)/(3+6*cosh(2*Pi*t))
  );
  return(S);
}
h2hat(u,N)=if(abs(u)<t0,(1-(u/t0)^2)^N/(Pi*u)^2,0)

Dh2(N)=
{
	local(s,m,logp,logm,n);
	logm=Pi*t0;
	m=floor(exp(logm));
	s=0;
	for(t=3,m,
		s+=L(t)/Pi*h2hat(log((t+sqrt(t^2-4))/2)/Pi,N);
	);
	forprime(myp=2,m,
		logp=log(myp);
		n=floor(logm/logp);
		for(j=1,n,
			s+=logp/myp^j/Pi*h2hat(j*logp/Pi,N);
		);
	);
	s
}

computeB(N)=
{
  local(B1,P);
  B1=sum(i=1,length(evlist),h2(evlist[i],N));
  B1-=(
(1/8+1/3/sqrt(3)+(log(2*Pi)+2*Euler)/(2*Pi))*N/(Pi*t0)^2
-intnum(t=0,t0,Ih2(t,N))-intnum(t=t0,40,Ih2(t,N))
  );
  P=(1-(1-x^2)^N)/x^2;
  B1+=(1+sum(j=0,poldegree(P),polcoeff(P,j)/(j+1)))*2/(Pi^2*t0);
  print("B is now ",B1/2);
  B1-=2*intnum(t=0,t0,c(t)*(1-(t/t0)^2)^N);
	B1+=Dh2(N);
  B1/2
}

khat(x)=cosh(Pi*x)/24/sinh(Pi*x)^2-1/8/cosh(Pi*x)-2*cosh(Pi*x)/(3+6*cosh(2*Pi*x))+(1-1/tanh(Pi*abs(x)/2))/4
M(T)=2*intnum(r=0,T,(T-r)*k(r))-T
R(T)=M(T)-(T^3/36-T^2*log(T)/Pi+(3+log(Pi/2))/2/Pi*T^2+log(T)/24/Pi-131/144*T+C0)

D(T,X,d)=2*k(T)*Fhat(0,X,d)+B+C0+log(T)/24/Pi-(6.59125/log(T)+1)*T/(12*log(T)/Pi)^2
intN(T)=sum(i=1,length(evlist),max(T-evlist[i],0))
intS(T)=intN(T)-(T^3/36-T^2*log(T)/Pi+(3+log(Pi/2))/2/Pi*T^2-131/144*T)
co2(T)=((12*log(T)/Pi)^2*intS(T)/T-1)*log(T);
