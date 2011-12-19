/*
Mathlib.ash v1.8 for KoLmafia.
written by Almighty Sapling

Handful of basic math functions for general purpose.

CHANGELOG
20110320-
vector, matrix, complex math added

20110310-
bit functions dropped
mathlibeval core body moved to mathlibevaluate, take string-heavy operations out of the recursion
mathlibeval variable body updated: variables must be alphabetic and underscores only; no operator assumes multiplication

20100122-
bit functions modified for (and deprecated in favor of) new mafia functions

20101209-
ln(float,int=8)

20101205-
flagSet(int,int)

20101128-
requires r8793 -reference to char_at
mathlibeval() all tests passed... so far
sqrt(float)
fact(int) factorial now float
throw(int,string="",boolean=false) expanded
contains_match(string,string) !!not math, but nifty anyway

20101127-
Minor changes to update function.
odd(int);

20101126-
Version 1.0
Added version control and update information.
Implemented trig functions
Overloaded trig functions with boolean for degrees
Overloaded trig functions with precision.
sin(float,boolean=false,int=8)
cos(float,boolean=false,int=8)
tan(float,boolean=false,int=8)
-cordic()

20101126-Creation
Version 0.01
throw(int,boolean=false) for errors
to_string(float,int,boolean=false)
fact(int) factorial
cordic(special) for trig
sin(float) INCOMPLETE
cos(float) sin dependant
tan(float) sin dependant
bitExpand(int)/bitCollapse(bits) for bitwise operations
bitSet(int,int) |
bitUnset(int,int)
bitToggle(int,int)
bitNot(int) ~
bitAnd(int,int) &
bitOr(int,int) |
bitXor(int,int) ^
*/
//{
string thisver="1.8";
int thread=5376;
string[string,string] mathlibvars;
file_to_map("mathlibvars.txt",mathlibvars);
//error constants
int CUST=1;
int DIV0=2;
int OVERFLOW=4;
int UNDEF=8;
int UNDEFF=16;

record complex{
 float a;
 float b;
 boolean polar;
};
typedef float[int,int] matrix;
typedef float[int] vector;
//mathematical constants
float PI=3.1415926536897932384626;
float PHI=1.6180339887498948482046;
float E=2.7182818284590452353603;
complex CONST_i;
CONST_i.a=0;
CONST_i.b=1;
CONST_i.polar=false;
//}

//extension to bits for easy flagchecking
boolean flagSet(int check, int mask){
 return (check&mask)==mask;
}

//odd. fairly self-explanatory.
boolean odd(int x){
 return (x&1)==1;
}

float abs(float x){
 if (x<0) return -x;
 return x;
}

int abs(int x){
 if (x<0) return -x;
 return x;
}

//error handling functions
void throw(int error, string c, boolean ab){
 string m="<font color=red>";
 if(flagSet(error,DIV0))m+="Division by Zero<br>";
 if(flagSet(error,OVERFLOW))m+="Value exceeded type range capabilites.<br>";
 if(flagSet(error,UNDEF))m+="Function not defined over provided range.<br>";
 if(flagSet(error,UNDEFF))m+="Function not defined.<br>";
 if(flagSet(error,CUST))m+=c+"<br>";
 m+="</font>";
 print_html(m);
 if(ab)abort();
 return;
}
void throw(int error, string c){
 throw(error,c,false);
 return;
}
void throw(int error, boolean ab){
 throw(error,"",ab);
 return;
}
void throw(int error){
 throw(error,"",false);
}

//extension of to_string to allow for precision, and in the case that the precision exceeds the
//decimals, optionally add zeroes.
string to_string(float value, int prec, boolean zeros){
 string out=to_string(value);
 matcher m=create_matcher("E(-?\\d+)",out);
 if (m.find()){
  int place=m.group(1).to_int();
  out=replace_all(m,"");
  m=create_matcher("\\.",out);
  out=replace_all(m,"");
  if (place<0){
   boolean neg=false;
   if (value<0){
    out=substring(out,1);
    neg=true;
   }
   for j from place upto -2 out="0"+out;
   out="0."+out;
   if(neg) out="-"+out;
  }else{
   while(length(out)<(place+2))out=out+"0";
   if(length(out)>(place+1)){
    m=create_matcher("(\\d{"+to_string(place+1)+"})(\\d*)",out);
    if(m.find())out=m.group(1)+"."+m.group(2);
   }
  }
 }
 int decimal=index_of(out,".")+1;
 int len=length(out);
 if ((len-decimal)>prec){
  out=substring(out,0,decimal+prec);
 }else while (((len-decimal)<prec)&&(zeros)){
  out=out+"0";
 }
 return out;
}
string to_string(float value, int prec){
 return to_string(value, prec, false);
}
string to_string(complex c, int prec, boolean zeros){
 string x="";
 if (c.polar){
  switch (c.a){
   case 1.0: break;
   case -1.0:
    x="-";
    break;
   case 0.0: return "0";
   default: x=to_string(c.a.to_string(prec,zeros));
  }
  switch (c.b){
   case 1.0:
    x+="e^i";
    break;
   case -1.0:
    x+="e^-i";
    break;
   case 0.0: break;
   default: x+="e^"+to_string(c.b.to_string(prec,zeros))+"i";
  }
 }else{
  if (c.a!=0) x=to_string(c.a.to_string(prec,zeros));
  if ((c.b>0)&&(c.a!=0)) x+="+";
  if (c.b!=0) x+=to_string(c.b.to_string(prec,zeros))+"i";
 }
 return x;
}
string to_string(complex c, int prec){
 return c.to_string(prec,false);
}
string to_string(complex c){
 return c.to_string(2,false);
}
/*
//generalized factorial function
float gamma(float x){
 float s;
 float c=1/x;
 float d;
 float n;
 int k=1;
 repeat{
  s=c;
  n=1.0/k;
  n=n+1;
  n=n^x;
  d=x/k;
  d=d+1;
  c=c*n/d;
  k=k+1;
  //if(k>10)break;
}until(k>5000);
// }until(to_string(s,8)==to_string(c,8));
 print(k);
 return c;
}

/*
after Gamma is implemented
float fact(float x){
 return x*gamma(x);
}
*/
//factorial function. Only defined up to 13 because after that... well... big numbers
float fact(int x){
 if(x<1){
  throw(UNDEF);
  return 0;
 }
 float n=1;
 for k from 1 upto x n=n*k;
 return n;
}

//sqrt function. Included in modifier_eval but no direct access, until not
float sqrt(float x){
 if(x<0){
  throw(UNDEF);
  return 0;
 }
 string s="sqrt("+to_string(x)+")";
 return modifier_eval(s);
}
//standard mathematical trig functions
float sin(float x, boolean deg, int prec){
 if(deg) x=x*PI/180;
 while(x>(PI/2))x=x-2*PI;
 while(x<(-PI/2))x=x+2*PI;
 if(x>(PI/2))x=PI-x;
 int i=1;
 float c=0;
 float s;
 repeat{
  s=c;
  if (i>13)break;
  c=c+(x**i)/fact(i);
  i=i+2;
  if (i>13)break;
  c=c-(x**i)/fact(i);
  i=i+2;
 }until (to_string(c,prec)==to_string(s,prec));
 return c;
}
float sin(float x, boolean deg){
 return sin(x,deg,5);
}
float sin(float x, int prec){
 return sin(x,false,prec);
}
float sin(float x){
 return sin(x,false,5);
}

float cos(float x, boolean deg, int prec){
 if(mathlibvars[my_name(),"trigMode"]=="deg") return sin(90-x,deg,prec);
 return sin(PI/2-x,deg,prec);
}
float cos(float x, boolean deg){
 return cos(x,deg,5);
}
float cos(float x, int prec){
 return cos(x,false,prec);
}
float cos(float x){
 return cos(x,false,5);
}

float tan(float x,boolean deg, int prec){
 float s;
 float c=0;
 float d;
 float n;
 int di=1;
 int ni=1;
 d=cos(x,deg,6);
 if (d==0){
  throw(DIV0);
  return 0;
 }
 repeat{
  s=c;
  ni+=1;
  while(cos(x,deg,di)==0)di=di+1;
  if(ni>di)di=ni;
  n=sin(x,deg,ni);
  c=n/d;
 }until(to_string(c,prec)==to_string(s,prec));
 return c;
}
float tan(float x, boolean deg){
 return tan(x,deg,8);
}
float tan(float x, int prec){
 return tan(x,false,prec);
}
float tan(float x){
 return tan(x,false,8);
}

float atan2(float y, float x){
 float angle;
 float t;
 boolean swapped=false;
 if (abs(y)>abs(x)){
  t=y;
  y=x;
  x=t;
  swapped=true;
 }
 if (x==0) {
  throw(UNDEF);
  return 0;
 }
 if (y==0) angle=0;
//!
 if(swapped)angle=PI/2-angle;
 if(x<0)angle=PI-angle;
 if(y<0)angle=2*PI-angle;
 return angle;
}

//complex functions
complex to_complex(float r){
 complex res;
 res.a=r;
 res.b=0;
 res.polar=false;
 return res;
}
complex to_complex(string c){
 complex res;
 res.polar=false;
 matcher m;
 m=create_matcher("e\\^",c);
 if (m.find()){
  res.polar=true;
 }
 m=create_matcher("([+-]?[\\d.]*)i",c);
 if (m.find()){
  res.b=to_float(m.group(1));
  if (m.group(1)=="") res.b=1;
  if (m.group(1)=="+") res.b=1;
  if (m.group(1)=="-") res.b=-1;
  c=replace_all(m,"");
 }else res.b=0;
 m=create_matcher("([+-]?[\\d.]*)",c);
 if (m.find()){
  res.a=to_float(m.group(1));
  if ((res.polar)&&(m.group(1))=="") res.a=1;
  if ((res.polar)&&(m.group(1))=="+") res.a=1;
  if ((res.polar)&&(m.group(1))=="-") res.a=-1;
 }else res.a=0;
 return res;
}

float cMag(complex o){
 if (o.polar) return o.a;
 return (o.a**2)+(o.b**2);
}

complex to_rect(complex c){
 if(!c.polar) return c;
 complex t;
 t.polar=false;
 t.a=c.a*cos(c.b);
 t.b=c.a*sin(c.b);
 return t;
}

complex to_polar(complex c){
 if(c.polar) return c;
 complex t;
 t.polar=true;
 t.a=c.cMag();
 t.b=atan2(c.b,c.a);
 return t;
}

float real(complex c){
 if(c.polar) return c.to_rect().a;
 return c.a;
}
float to_float(complex c){
 return real(c);
}
float to_int(complex c){
 return real(c).to_int();
}

float imag(complex c){
 if(c.polar) return c.to_rect().b;
 return c.b;
}

complex cMult(complex o1, complex o2){
 complex res;
 complex t1=o1.to_rect();
 complex t2=o2.to_rect();
 res.a=(t1.a*t2.a)-(t1.b*t2.b);
 res.b=(t1.a*t2.b)+(t1.b*t2.a);
 res.polar=false;
 return res;
}
complex cMult(complex o1, float o2){
 return cMult(o1,o2.to_complex());
}

complex cAdd(complex o1, complex o2){
 complex res;
 complex t1=o1.to_rect();
 complex t2=o2.to_rect();
 res.a=t1.a+t2.a;
 res.b=t1.b+t2.b;
 return res;
}
complex cAdd(complex o1, float o2){
 return cAdd(o1,o2.to_complex());
}

complex conjugate(complex o){
 complex r=o;
 if (r.polar) r.a=-r.a;
 else r.b=-r.b;
 return r;
}

//vector/matrix maths
string to_string(vector v,int prec, boolean zero){
 string x="<";
 foreach i,f in v x+=to_string(f,prec,zero)+", ";
 if(x!="<") x=substring(x,0,length(x)-2);
 x+=">";
 return x; 
}
string to_string(vector v,int prec){
 return to_string(v,prec,false);
}
string to_string(vector v){
 return to_string(v,2,false);
}

vector to_vector(string v){
 vector vec;
 matcher m;
 m=create_matcher("(\\d+)",v);
 while(m.find()) vec[count(vec)+1]=m.group(1).to_float();
 return vec;
}

vector matrixGetRow(matrix m, int i){
 vector v;
 foreach j,f in m[i] v[j]=f;
 return v;
}

vector matrixGetCol(matrix m, int j){
 vector v;
 foreach i in m v[i]=m[i,j];
 return v;
}

matrix identityMatrix(int size){
 matrix m;
 for i from 1 to size
  for j from 1 to size
   if (i==j) m[i,j]=1;
   else m[i,j]=0;
 return m;
}

int matrixWidth(matrix m){
 int c=0;
 foreach i in m
  foreach j in m[i] if(j>c)c=j;
 return c;
}

int matrixHeight(matrix m){
 int c=0;
 foreach i in m if(i>c)c=i;
 return c;
}

void normalize(matrix m){
 int widest=m.matrixWidth();
 int tallest=m.matrixHeight();
 for i from 1 upto tallest{
  if (!(m contains i))m[i,1]=0;
  for j from 1 upto widest if(!(m[i] contains j)) m[i,j]=0;
 }
}

void matrixAddRow(matrix m,vector v){
 int c=m.matrixHeight()+1;
 foreach j,f in v m[c,j]=f;
 m.normalize();
}

void matrixAddCol(matrix m,vector v){
 int c=m.matrixWidth()+1;
 foreach i,f in v m[i,c]=f;
 m.normalize();
}

matrix transpose(matrix m){
 matrix n;
 foreach i,j,f in m n[j,i]=f;
 return n;
}

float dot(vector u, vector v){
 float t=0;
 if (count(u)!=count(v)){
  throw(UNDEFF);
  return 0;
 }
 foreach i in u t+=u[i]*v[i];
 return t;
}

matrix matrixMult(matrix a, matrix b){
 matrix c;
 if (a.matrixWidth()!=b.matrixHeight()){
  throw(UNDEFF);
  return c;
 }
 for i from 1 to a.matrixHeight()
  for j from 1 to b.matrixWidth()
   c[i,j]=dot(a.matrixGetRow(i),b.matrixGetCol(j));
 return c;
}
matrix matrixMult(matrix a, float k){
 matrix m;
 foreach i,j in a m[i,j]=a[i,j]*k;
 return m;
}

matrix matrixAdd(matrix a, matrix b){
 matrix c;
 if ((a.matrixWidth()!=b.matrixWidth())||(a.matrixHeight()!=b.matrixHeight())){
  throw(UNDEFF);
  return a;
 }
 foreach i,j in b c[i,j]=a[i,j]+b[i,j];
 return c;
}

vector cross(vector u, vector v){
 vector c;
 c[1]=u[2]*v[3]-u[3]*v[2];
 c[2]=u[3]*v[1]-u[1]*v[3];
 c[3]=u[1]*v[2]-u[2]*v[1];
 return c;
}

//natural logarithm: returns x for y given e^x=y
float mercator(float x, int prec){//returns log(x) for x from 0 to 1
 x=x-1;
 float k=1;
 float s;
 float c=0;
 repeat{
  s=c;
  c=c+((x**k)/k);
  k=k+1;
  c=c-((x**k)/k);
  k=k+1;
 }until (to_string(c,prec)==to_string(s,prec));
 c=c+((x**k)/k);
 k=k+1;
 c=c-((x**k)/k);
 return c;
}
float ln(float x, int prec){
 if (x<=0){
  throw(UNDEF);
  return 0;
 }
 if (x==1){
  return 0;
 }
 if (x<1){
  return mercator(x,prec);
 }
 x=x/(x-1);
 float k=1;
 float s;
 float c=0;
 repeat{
  s=c;
  c=c+(1/(k*(x**k)));
  k=k+1;
 }until (to_string(c,prec)==to_string(s,prec));
 c=c+(1/(k*(x**k)));
 return c;
}
float ln(float x){
 return ln(x,8);
}

//kol-specific functions for common familiars
float famSpecFairy(float x){
 return sqrt(55*x)+x-3;
}
float famSpecJack(float x){
 return 2*famSpecFairy(x);
}
float famSpecHound(float x){
 return famSpecFairy(1.25*x);
}

float famSpecLep(float x){
 return 2*famSpecFairy(x);
}
float famSpecMonkey(float x){
 return 2*famSpecFairy(1.25*x);
}

float famSpecAnt(float x){
 int gD=modifier_eval("G").to_int();
 return (1.3-.15*gD)*famSpecFairy(x);
}

float famSpecCactus(float x){
 return 2*famSpecAnt(x);
}

//if vars are, for some reason, missing, add them back.
//may expand this to fix vars that have been set incorrectly
void checkvars(){
// if(!(mathlibvars[my_name()] contains "trigMode"))mathlibvars[my_name(),"trigMode"]="rad";
 return;
}

//not strictly math, but so much more convenient for conversion to buffers
string replace(string o, int s, int f, string n){
 buffer b;
 append(b,o);
 replace(b,s,f,n);
 return to_string(b);
}

//again not math, but rather an extension to contains_text
boolean contains_match(string s, string tom){
 matcher m=create_matcher(tom,s);
 return find(m);
}

//eval function for strings containing math commands. WIP?
//Removes the text function restriction from eval.
float mathlibevaluate(string x){
 string inner;
 int open;
 int close;
 matcher mm;
 string[int] params;
 string func;
 while(x.contains_text("(")){
  open=last_index_of(x,"(");
  if(open<0) break;
  close=index_of(substring(x,open),")")+open;
  if(close>open-1){
   mm=create_matcher("\\((.+?)\\)",substring(x,open));
   if(find(mm))inner=group(mm,1);
   else inner="";
  }else{
   close=length(x)-1;
   inner=substring(x,open);
  }
  if((open>0)&&(char_at(x,open-1).contains_match("[a-zA-Z]"))){
   //print(substring(x,0,open));
   mm=create_matcher("([a-zA-Z][a-zA-Z_]*)",substring(x,0,open));
   while(mm.find()){
    open=start(mm,1);
    func=group(mm,1);
   }
   params=split_string(inner,",");
   switch(func.to_lower_case()){
    case "sin":
     if(count(params)>1) x=replace(x,open,close+1,to_string(sin(mathlibevaluate(params[0]),mathlibevaluate(params[1]).to_boolean())));
     else x=replace(x,open,close+1,to_string(sin(mathlibevaluate(params[0]))));
     break;
    case "cos":
     if(count(params)>1) x=replace(x,open,close+1,to_string(cos(mathlibevaluate(params[0]),mathlibevaluate(params[1]).to_boolean())));
     else x=replace(x,open,close+1,to_string(cos(mathlibevaluate(params[0]))));
     break;
    case "tan":
     if(count(params)>1) x=replace(x,open,close+1,to_string(tan(mathlibevaluate(params[0]),mathlibevaluate(params[1]).to_boolean())));
     else x=replace(x,open,close+1,to_string(tan(mathlibevaluate(params[0]))));
     break;
    case "ln":
    case "log":
     x=replace(x,open,close+1,to_string(ln(mathlibevaluate(params[0]))));
     break;
    case "rand":
    case "random":
     x=replace(x,open,close+1,to_string(random(mathlibevaluate(params[0]).to_int())));
     break;
    case "fact":
     x=replace(x,open,close+1,to_string(fact(mathlibevaluate(params[0]).to_int())));
     break;
    case "ceil":
     x=replace(x,open,close+1,to_string(ceil(mathlibevaluate(params[0]))));
     break;
    case "floor":
     x=replace(x,open,close+1,to_string(floor(mathlibevaluate(params[0]))));
     break;
    case "sqrt":
     x=replace(x,open,close+1,to_string(sqrt(mathlibevaluate(params[0]))));
     break;
    case "zone":
    case "loc":
     x=replace(x,open,close+1,to_string(modifier_eval("loc("+params[0]+")"))); 
     break;
    case "fam":
     x=replace(x,open,close+1,to_string(modifier_eval("fam("+params[0]+")"))); 
     break;
    case "pref":
     x=replace(x,open,close+1,to_string(modifier_eval("pref("+params[0]+")"))); 
     break;
    case "min":
     if(count(params)>1) x=replace(x,open,close+1,to_string(min(mathlibevaluate(params[0]),mathlibevaluate(params[1]))));
     else x=replace(x,open,close+1,params[0]);
     break;
    case "max":
     if(count(params)>1) x=replace(x,open,close+1,to_string(max(mathlibevaluate(params[0]),mathlibevaluate(params[1]))));
     else x=replace(x,open,close+1,params[0]);
     break;
    case "throw":
     x=replace(x,open,close+1,0);
     if(count(params)>1)throw(params[0].to_int(),params[1]);
     else throw(params[0].to_int());
     break;
    case "round":
     x=replace(x,open,close+1,to_string(mathlibevaluate(params[0]).round()));
     break;
    case "jack":
    case "jitb":
     x=replace(x,open,close+1,to_string(famSpecJack(mathlibevaluate(params[0]))));
     break;
    case "hound":
     x=replace(x,open,close+1,to_string(famSpecHound(mathlibevaluate(params[0]))));
     break;
    case "fairy":
     x=replace(x,open,close+1,to_string(famSpecFairy(mathlibevaluate(params[0]))));
     break;
    case "lep":
     x=replace(x,open,close+1,to_string(famSpecLep(mathlibevaluate(params[0]))));
     break;
    case "monkey":
     x=replace(x,open,close+1,to_string(famSpecMonkey(mathlibevaluate(params[0]))));
     break;
    case "ant":
     x=replace(x,open,close+1,to_string(famSpecAnt(mathlibevaluate(params[0]))));
     break;
    case "cactus":
     x=replace(x,open,close+1,to_string(famSpecCactus(mathlibevaluate(params[0]))));
     break;     
    default:
     throw(UNDEFF+CUST,func);
     x=replace(x,open,close+1,"0.0");
   }
  }else x=replace(x,open,close+1,modifier_eval(inner));
 }
 return modifier_eval(x);
}
float mathlibeval(string x, float[string] vars){
 vars["PI"]=PI;
 vars["PHI"]=PHI;
 vars["E"]=E;
 vars["true"]=1;
 vars["false"]=0;
 buffer b;
 string var;
 matcher m;
 m=create_matcher("(\\d)([a-zA-Z])",x);
 while(find(m)) {
  x=replace_first(m,group(m,1)+"*"+group(m,2));
  m=create_matcher("(\\d)([a-zA-Z])",x);
 }
 m=create_matcher("([a-zA-Z])(\\d)",x);
 while(find(m)) {
  x=replace_first(m,group(m,1)+"*"+group(m,2));
  m=create_matcher("([a-zA-Z])(\\d)",x);
 }
 m=create_matcher("(?i)\\b[a-z_][a-z_]*\\b",x);
 while(m.find()){
  var=m.group(0);
  if(vars contains var)m.append_replacement(b,"("+vars[var].to_string()+")");
  else m.append_replacement(b,var);
 }
 m.append_tail(b);
 b=replace_string(b,"[","(");
 b=replace_string(b,"]",")");
 x=b.to_string();
 m=create_matcher("(\\d)\\(",x);
 while(find(m)) {
  x=replace_first(m,group(m,1)+"*(");
  m=create_matcher("(\\d)\\(",x);
 }
 m=create_matcher("\\)(\\d)",x);
 while(find(m)) {
  x=replace_first(m,")*"+group(m,1));
  m=create_matcher("\\)(\\d)",x);
 }
 return mathlibevaluate(x);
}
float mathlibeval(string x){
 float[string] vars;
 return mathlibeval(x,vars);
}

//Typically unused, library functions
//check_version, many many thanks to Zarqon.
void mathlibversion(){
 int w;
 string page;
 switch (get_property("_mathlibVersion")) {
  case thisver:
   return;
   break;
  case "":
   print("Checking for Mathlib updates (Current  ver. "+thisver+")");
   page=visit_url("http://kolmafia.us/showthread.php?t="+thread);
   matcher find_ver = create_matcher("<b>mathlib:(.+?)</b>",page);
   if (!find_ver.find()) {
    print("Unable to load current version info.");
    set_property("_mathlibVersion",thisver);
    return;
   }
   w=20;
   set_property("_mathlibVersion",find_ver.group(1));
   if (find_ver.group(1) == thisver) {
    print("Mathlib up to date.");
    return;
   }
  default:
   string msg = "<big><font color=red><b>Mathlib Update Available: "+get_property("_mathlibVersion")+"</b></font></big>";
   msg+="<br><font color=blue>Upgrade mathlib from "+thisver+" to "+get_property("_mathlibVersion")+" ";
   msg+="<a href='http://kolmafia.us/showthread.php?t="+thread+"' target='_blank'>here: ";
   msg+="http://kolmafia.us/showthread.php?t="+thread+"</a></font>";
   print_html(msg); 
   wait(w);
   return;
  }
 return;
}

void main(string option){
 mathlibversion();
 checkvars();
 map_to_file(mathlibvars,"mathlibvars.txt");
 if((option=="")||(option=="vars")){
  print("Mathlib Variables");
  foreach s in mathlibvars[my_name()] print(s+"=>"+mathlibvars[my_name(),s]);
  print_html("<br>\"mathlib set variable_name=value\" to change a field.<br>\"mathlib default\" to restore defaults.");
  return;
 }
 if(option=="default"){
  map_to_file(mathlibvars,"mathlibvars.txt");
  return;
 }
 matcher setf=create_matcher("(?i)(set|force) ([\\s\\w]*)=([\\s\\w]*)",option);
 if(!(find(setf))){
  print("Correct usage is \"set variable_name=value\".");
  return;
 }
 if((mathlibvars[my_name()] contains group(setf,2))||(group(setf,1).to_lower_case()=="force")){
  mathlibvars[my_name(),group(setf,2)]=group(setf,3);
  map_to_file(mathlibvars,"mathlibvars.txt");
 }else{
  print("Unknown variable name.");
  return;
 }
}