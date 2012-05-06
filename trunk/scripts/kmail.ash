record datetime{
 int year;
 int month;
 int day;
 int hour;
 int min;
 int sec;
};

string to_string(datetime d, string style){
 string s;
 int pi=0;
 string cc;
 int size;
 boolean escaped;
 while(pi<length(style)){
  cc=style.char_at(pi);
  pi+=1;
  while((pi<length(style))&&(style.char_at(pi)==cc)){
   size+=1;
   pi+=1;
  }
  if(escaped)switch(cc){
   case "'":
    while(size>1){
     s+="'";
     size-=2;
    }
    if(size==1)escaped=false;
    break;
   default:
    while(size>0){
     s+=cc;
     size-=1;
    }
    break;
  }else switch(cc){
   case "'":
    while(size>1){
     s+="'";
     size-=2;
    }
    if(size==1)escaped=true;
    break;
   case "Y":
   default:
    break;
  }
 }
 return "";
}

string to_string(datetime d){
 string s="";
 string t=d.month.to_string()+"/";
 if (t.length()<3) s+="0"+t;
 else s+=t;
 t=d.day.to_string()+"/";
 if (t.length()<3) s+="0"+t;
 else s+=t;
 t=d.year.to_string()+" ";
 if (t.length()<3) s+="0"+t+" ";
 else s+=t;
 t=d.hour.to_string()+":";
 if (t.length()<3) s+="0"+t;
 else s+=t;
 t=d.min.to_string()+":";
 if (t.length()<3) s+="0"+t;
 else s+=t;
 t=d.sec.to_string();
 if (t.length()<2) s+="0"+t;
 else s+=t;
 return s;
}

datetime to_datetime(string s){
 matcher m=create_matcher("(\\d+)/(\\d+)/(\\d+)\\s(\\d+):(\\d+):(\\d+)",s);
 datetime t;
 if (m.find()){
  t.month=m.group(1).to_int();
  t.day=m.group(2).to_int();
  t.year=m.group(3).to_int();
  t.hour=m.group(4).to_int();
  t.min=m.group(5).to_int();
  t.sec=m.group(6).to_int();
  return t;
 }
 m=create_matcher("(?i)(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|June?|July?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?) (\\d*), (\\d*), (\\d*):(\\d*)([AP]M)",s);
 if (m.find()){
  switch (m.group(1).substring(0,3)){
   case "Jan": t.month=1;break;
   case "Feb": t.month=2;break;
   case "Mar": t.month=3;break;
   case "Apr": t.month=4;break;
   case "May": t.month=5;break;
   case "Jun": t.month=6;break;
   case "Jul": t.month=7;break;
   case "Aug": t.month=8;break;
   case "Sep": t.month=9;break;
   case "Oct": t.month=10;break;
   case "Nov": t.month=11;break;
   case "Dec": t.month=12;break;
  }
  t.day=m.group(2).to_int();
  t.year=m.group(3).to_int();
  t.hour=m.group(4).to_int();
  t.min=m.group(5).to_int();
  t.sec=0;
  if (m.group(6)=="PM") t.hour+=12;
  if (t.hour>23) t.hour-=24;
  return t;
 }
 return t;
}

boolean is_newer(datetime a, datetime b){
 if (a.year>b.year)return true;
 if (a.year<b.year)return false;
 if (a.month>b.month)return true;
 if (a.month<b.month)return false;
 if (a.day>b.day)return true;
 if (a.day<b.day)return false;
 if (a.hour>b.hour)return true;
 if (a.hour<b.hour)return false;
 if (a.min>b.min)return true;
 if (a.min<b.min)return false;
 if (a.sec>b.sec)return true;
 return false;
}

record message{
	string sender;
	int senderId;
	datetime date;
	int messageId;
	string text;
	int meat;
	int[item] things;
    boolean out;
    boolean archive;
    boolean unread;
    string box;
    string fakebox;
};

int kmail(string to, string message, int meat, int[item] stuff){
 if (meat > my_meat()){
  print("Not enough meat to send.");
  return 3;
 }
 string itemstring = "";
 int j = 0;
 string[int] itemstrings;
 foreach i in stuff{
  if (is_tradeable(i)||is_giftable(i)){
   j=j+1;
   itemstring=itemstring+"&howmany"+j+"="+stuff[i]+"&whichitem"+j+"="+to_int(i);
   if (j>10){
    itemstrings[count(itemstrings)]=itemstring;
    itemstring='';
    j=0;
   }
  }
 }
 if (itemstring!="") itemstrings[count(itemstrings)]=itemstring;
 if (count(itemstrings)==0) itemstrings[0]="";
 foreach q in itemstrings{
  string url=visit_url("sendmessage.php?pwd="+my_hash()+"&action=send&towho="+to+"&message="+message+"&sendmeat="+meat+itemstrings[q]);
  if (contains_text(url,"That player cannot receive Meat or items")){
   print("Player may not receive meat/items.");
   return 2;
  }
  if (!contains_text(url,"Message sent.")){
   print("Unknown error. The message probably did not go through.");
   return -1;
  }
 }
 return 1;
}

int kmail(string to, string message, int[item] stuff){
 return kmail(to,message,0,stuff);
}

int kmail(string to, string message, int meat){
 int[item] nothing;
 return kmail(to,message,meat,nothing);
}

int kmail(string to, string message){
 int[item] nothing;
 return kmail(to,message,0,nothing);
}

string findAttachments(string kmail){
 matcher kmailattachments=create_matcher("<center>(.+)",kmail);
 if(kmailattachments.find()) return kmailattachments.group(1);
 return "";
}

string adjustLinks(string start){
 matcher m;
 string[int] link;
 string c;
 string rep;
 int a;
 int i;
 m=create_matcher("<a tar.+?href=\"(.+?)\">.+?</a>",start);
 while (m.find()){
  c=m.group(1);
  link[count(link)+1]=c;
  a=length(c);
  rep="<"+count(link).to_string()+">";
  start=replace_first(m,rep);
  i=index_of(start,rep)+length(rep);
  while (a>0){
   if (char_at(start,i)!=" ") a-=1;
   start=substring(start,0,i)+substring(start,i+1);
  }
  m=m.reset(start);
 }
 foreach in,l in link {
  m=create_matcher("<"+in.to_string()+">",start);
  if (!m.find()) continue;
  start=replace_first(m,"<a target=_blank href=\""+l+"\"><font color=\"blue\">"+l+"</font></a>");
 }
 return start;
}

string substring(string source, string start, string end){
 if (start!=""){
  if (!source.contains_text(start)) return "";
  source=substring(source,index_of(source,start)+length(start));
 }
 if (end=="") return source;
 if (!source.contains_text(end)) return "";
 return substring(source,0,index_of(source,end));
}

message[int] parseMail(string box, int p){
 message[int] parsedmail;
 matcher m;
 string temp;
 int page;
 if (p==0) page=1;
 else page=p;
 repeat{
  int c=count(parsedmail)+1;
  temp=visit_url("messages.php?box="+box+"&begin="+page.to_string());
  if(index_of(temp,"checkbox name=\"")<0) return parsedmail;
  temp=substring(temp,index_of(temp,"checkbox name=\"")+15);
  string[int] km=split_string(temp,"checkbox name=\"");
  for i from 0 upto (count(km)-1){
   parsedmail[i+c].unread=(index_of(km[i],"New!</span>")>0);
   parsedmail[i+c].messageId=to_int(substring(km[i],3,index_of(km[i],"\"")));
   if (box=="Saved") parsedmail[i+1].archive=true;
   parsedmail[i+c].out=(index_of(km[i],"<b>To<")>0);
   m=create_matcher("[\\r\\n]+",substring(km[i],"<blockquote>","</blockquote>"));
   parsedmail[i+c].text=replace_all(m,"").adjustLinks();
   if (contains_text(parsedmail[i+1].text,"<center>")) parsedmail[i+c].text=substring(parsedmail[i+1].text,"","<center>");
   if(index_of(km[i],"showplayer.php")<0){
    parsedmail[i+c].sender="__";
    parsedmail[i+c].senderId=0;
   }else{
    temp=substring(km[i],index_of(km[i],"showplayer.php"));
    parsedmail[i+c].sender=substring(temp,">","</a>");
    parsedmail[i+c].senderId=to_int(substring(temp,"(#",")"));
   }
   temp=substring(km[i],index_of(km[i],"<b>Date:</b>")+12);
   parsedmail[i+c].date=temp.substring("<!--","-->").to_datetime();
   string table=findAttachments(km[i]);
   parsedmail[i+c].meat=extract_meat(table);
   parsedmail[i+c].things=extract_items(table);
   parsedmail[i+c].box=box;
   parsedmail[i+c].fakebox=box;
  }
  if (p>0) break;
  page+=1;
 }until (false);
 return parsedmail;
}
message[int] parseMail(){
 return parseMail("Inbox",1);
}

boolean deleteMail(message m){
 string del=visit_url("messages.php?the_action=delete&box="+m.box+"&pwd="+my_hash()+"&sel"+m.messageId+"=checked");
 if (contains_text(del,"1 message deleted.")){
  return true;
 }
 return false;
}

void junkMail(string dump){
 message[int] mail=parseMail();
 for i from 1 upto (count(mail)) if (mail[i].sender==dump) deleteMail(mail[i]);	
 return;
}

boolean saveMail(message m){
 string del=visit_url("messages.php?the_action=save&box="+m.box+"&pwd="+my_hash()+"&sel"+m.messageId+"=checked");
 if (contains_text(del,"1 message saved.")){
  return true;
 }
 return false;
}