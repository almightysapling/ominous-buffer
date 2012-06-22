int[int,int,int] DATA;

string humanNum(string num){
 int decimal=index_of(num,'.');
 if (decimal==-1)decimal=length(num);
 int p=decimal-3;
 while (p>0){
  num=substring(num,0,p)+","+substring(num,p);
  p=p-3;
 }
 return num;
}

boolean harvestMD(string itemname, int hours, int endtime){
 string url="http://kol.coldfront.net/newmarket/export_csv.php?";
 if (hours>0){
  url+="start="+to_string(endtime-hours*3600)+"&";
  }
 url+="end="+to_string(endtime)+"&itemid=";
 url+=itemname.to_item().to_int().to_string();
 if (itemname.to_item()==$item[none]) return false;
 string details=visit_url(url);
 matcher parse=create_matcher("(\\d*),(\\d*),(\\d*),([\\de\\+\\.]*),(\\d*)",details);
 float x;
 matcher floatm;
 while (find(parse)){
  floatm=create_matcher("([\\d\\.]*)e\\+(\\d*)",group(parse,4));
  if(find(floatm)){
   x=group(floatm,1).to_float();
   x=x*(10^group(floatm,2).to_int());
  }else{
   x=group(parse,4).to_float();
  }
  data[itemname.to_item().to_int(),group(parse,5).to_int(),group(parse,3).to_int()]=x.to_int();
 }
 return true;
}

int unixTime(){
 string n=visit_url("http://www.unixtimestamp.com/index.php");
 string e='<font color="#CC0000">';
 n=substring(n,index_of(n,e)+length(e));
 n=substring(n,0,index_of(n,"<"));
 return n.to_int();
}

boolean marketDetails(string e, string req, int hours){
 string thed="Market Data: ";
 if(hours>0) thed+="Last "+hours.to_string()+" Hours.\n";
 else thed+="All available data.\n";
 float avg;
 int gain, min, max, total, first, last, this;
 foreach itemn in data{
  avg=0;
  min=0;
  max=0;
  total=0;
  first=0;
  last=0;
  thed+=itemn.to_item().to_string()+":\n";
  
  foreach cnt,amount in data[itemn]{
   this=data[itemn,cnt,amount];
   if(min==0)min=this;
   if(max==0)max=this;
   total+=amount;
   avg+=amount*this;
   if(min>this)min=this;
   if(max<this)max=this;
   if(first==0)first=this;
   last=this;
  }
  avg=avg*1.0/total;
  gain=last-first;
  thed+="Total Volume This Timeframe: "+total.to_string().humanNum()+"\n";
  thed+="Average price: "+avg.to_string().humanNum()+"\n";
  thed+="High/Low: "+max.to_string().humanNum()+"/"+min.to_string().humanNum()+"\n";
  thed+="Net ";
  if(gain<0){
   gain=-1*gain;
   thed+="Loss: ";
  }else{
   thed+="Gain: ";
  }
  thed+=gain.to_string().humanNum()+"\n";
 }
 cli_execute("kmail to "+req+" || "+thed);
 return true;
}

boolean marketCompare(string e, string req, int hours){
 return true;
}

boolean marketLink(string req, int hours, string itemname, int endtime){
 string url="http://kol.coldfront.net/newmarket/itemgraph.php?";
 if (hours>0){
  url+="starttime="+to_string(endtime-hours*3600)+"&";
 }else url+="starttime=1277924400&";
 url+="endtime="+to_string(endtime)+"&itemid=";
 url+=itemname.to_item().to_int().to_string();
 if (itemname.to_item()==$item[none]) return false;
 if (req=="!") chat_clan(url);
 else chat_private(req,url);
 return true;
}

boolean analyzeMD(string requestee,string request){
 int timeNow=unixTime();
 string error="";
 request=to_lower_case(request);
 matcher parse=create_matcher("(det|cmp|link)(\\s*\\d*\\s*)(hours?|days?|all)? ?([\\s\\S]*)",request);
 if (!find(parse))return false;
 if (group(parse)=="link"){
  if (requestee=="!") chat_clan("http://kol.coldfront.net/index.php/content/view/1903/146/");
  else chat_private(requestee,"http://kol.coldfront.net/index.php/content/view/1903/146/");
  return true;
 }
 int hours=group(parse,2).to_int();
 if ((group(parse,2)==" ")||(group(parse,2)=="")) hours=1;
 if ((group(parse,3)=="days")||(group(parse,3)=="day")) hours=hours*24;
 if (group(parse,3)=="all") hours=0;
 request=group(parse,4);
 string[int] items=split_string(request,"\\s*[|,;]\\s*");
// print("Report Type: "+group(parse,1));
// print("Time Frame (in hours): "+hours.to_string());
 if (group(parse,1)=="link") return marketLink(requestee,hours,items[0],timeNow);
 foreach i in items {
 // print(items[i]);
  if (!harvestMD(items[i],hours,timeNow))
   error+=items[i]+" not found.\n";
 }
 if (group(parse,1)=="det") return marketDetails(error,requestee,hours);
 else return marketCompare(error,requestee,hours);
 return true;
}