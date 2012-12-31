import <kmail.ash>
import <games.ash>
string NAME_=__FILE__;
record userinfo{
 int userid;
 string nick;
 boolean[string] multis;
 int gender;//see gengers[] definition comments
 int flags;//see flag bits
 string[string] aliases;
 int[int] buffs;
 float lastMath;
 string lastTime;
 string lastTrigger;
 int donated;
 int wallet;
 int defaultCasts;
 string gHobopPassword;
 string sessionVars;
};
//flag bits
int noFlag=1;//no error messages
int isAdmin=2;
int isBuffer=4;//no use, merely for OS/T
int noLimit=8;
int blacklist=16;
int whitelist=32;//for OB-use, not clan
int inClan=64;
int receivedCake=128;
int inAssociate=256;
int highAssociate=512;

userinfo[string] userdata;
file_to_map("userdata.txt",userdata);

//Global variables
string nightlySave="totalDaysCasting;totalCastsEver;books;winners";
string earlySave="nunsVisits;totalCastsEver;totalDaysCasting;_breakfast;_limitBuffs;_currentDeals;books;winners;admins";
string ignorePile="_breakfast;_limitBuffs;nunsVisits;_currentDeals";
int clanid=2046994401;//Black Mesa
boolean[int] associates;//F: 400 limit; T:in-clan limits
associates[21459]=true;//Hogs of Destiny
associates[67356]=true;//Piglets of Fate
associates[2046987019]=true;//Not Dead Yet
associates[2046991167]=true;//This One Time
associates[2046983684]=true;//Clan of 14 Days
associates[2046991423]=true;//Margaretting Tye
associates[76566]=true;//Imitation Plastic Death Star
associates[72876]=true;//Hyrule
int repValue=4;

record resource{
 string owner;
 int depth;
};

void invokeResourceMan(string newname){
 NAME_=newname;
 resource[string] resources;
 file_to_map("resources.txt",resources);
 foreach n,res in resources if((res.owner==NAME_)||(res.depth==0)) remove resources[n];
 map_to_file(resources,"resources.txt");
}

void debug(int i){
 resource[string] resources;
 file_to_map("resources.txt",resources);
 boolean out=false;
 foreach name,res in resources if(res.depth!=0){
  if((!out)&&(i>0))print("@"+i+" {");
  print((i>0?"-":"")+name+": "+res.owner+"["+res.depth+"]");
  out=true;
 }
 if((out)&&(i>0))print("}");
}

void debug(){
 debug(-1);
}

void cleanResources(){ //Remove all holds
 resource[string]blank;
 map_to_file(blank,"resources.txt");
}

void releaseResources(){ //Remove all holds of a certain script
 resource[string] resources;
 file_to_map("resources.txt",resources);
 foreach name,res in resources if(res.owner==NAME_)remove resources[name];
 map_to_file(resources,"resources.txt");
}

boolean claimResource(string resourceName){ //Lock a symbol
 resource[string] resources;
 file_to_map("resources.txt",resources);
 while((resources[resourceName].owner!="")&&(resources[resourceName].owner!=NAME_)){
  waitq(1);
  file_to_map("resources.txt",resources);
 }
 resources[resourceName].owner=NAME_;
 resources[resourceName].depth+=1;
 map_to_file(resources,"resources.txt");
 return true;
}

string freeResource(string resourceName){ //Free a symbol without saving
 resource[string] resources;
 file_to_map("resources.txt",resources);
 string owner=resources[resourceName].owner;
 if(owner==NAME_){
  resources[resourceName].depth-=1;
  if(resources[resourceName].depth==0)remove resources[resourceName];
  map_to_file(resources,"resources.txt");
 }
 return owner;
}

string commit(string resourceName){ //Free a symbol without saving
 return freeResource(resourceName);
}

aggregate checkOut(aggregate data, string resourceName){ //Lock a symbol and load its contents
 claimResource(resourceName);
 file_to_map(resourceName,data);
 return data;
}

aggregate update(aggregate data, string resourceName){ //Load a symbol, but don't get permission to save
 file_to_map(resourceName,data);
 return data;
}

string commit(aggregate data, string resourceName, boolean freeR){ //Save data to a symbol, optionally free the symbol
 resource[string] resources;
 file_to_map("resources.txt",resources);
 string owner=resources[resourceName].owner;
 if(owner==NAME_){
  map_to_file(data,resourceName);
  if(freeR){
   resources[resourceName].depth-=1;
   if(resources[resourceName].depth==0)remove resources[resourceName];
   map_to_file(resources,"resources.txt");
  }
 }
 return owner;
}

string commit(aggregate data, string resourceName){ //Save data to a symbol and free it
 return commit(data,resourceName,true);
}

boolean couldClaim(string resourceName){
 resource[string] resources;
 file_to_map("resources.txt",resources);
 if((resources[resourceName].owner!="")&&(resources[resourceName].owner!=NAME_))return false;
 return true;
}

int permissionDepth(string resourceName){
 resource[string] resources;
 file_to_map("resources.txt",resources);
 if(resources[resourceName].owner==NAME_)return resources[resourceName].depth;
 return -resources[resourceName].depth;
}

void setUF(string user, int f){
 userdata[user].flags|=f;
}

void unSetUF(string user, int f){
 userdata[user].flags&=~f;
}

boolean getUF(string user, int f){
 return(userdata[user].flags&f)==f;
}

//check clan whitelist for user if not in clan
boolean checkWhitelist(int id){
 claimResource("adventuring");
 string page=visit_url("clan_whitelist.php");
 freeResource("adventuring");
 matcher m=create_matcher("(?i)="+id.to_string()+"'",page);
 if(find(m))return true;
 return false;
}

string to_playerName(int pId){
 claimResource("adventuring");
 string v=visit_url("showplayer.php?who="+pId.to_string());
 freeResource("adventuring");
 matcher m=create_matcher("<center><b>(.+?)</b>",v);
 if (m.find()){
  return m.group(1);
 }
 return ":NONE";
}

string to_clanName(int cId){
 claimResource("adventuring");
 string p=visit_url("showclan.php?whichclan="+cId);
 freeResource("adventuring");
 matcher m=create_matcher("blue><b>(.+?)</b",p);
 if(!m.find())return "";
 return m.group(1);
}

//request unknown user's id. if (add) then place them into the users file.
int updateId(string user,boolean add){
 if(user=="")return 0;
 claimResource("adventuring");
 string searchstring=visit_url("searchplayer.php?searching=Yep.&searchstring="+user+"&hardcoreonly=0");
 freeResource("adventuring");
 matcher nameClan=create_matcher('(?i)(\\d*)">'+user+'</a></b> (?: \\(PvP\\))?(?:<br>\\(<a target=mainpane href="showclan\\.php\\?whichclan=(\\d*))?',searchstring);
 if(!find(nameClan))return 0;
 checkOut(userdata,"userdata.txt");
 if(!add)return group(nameClan,1).to_int();
 userdata[user].gender=2;
 userdata[user].userid=group(nameClan,1).to_int();
 unSetUF(user,inClan+inAssociate+highAssociate);
 if(group(nameClan,2).to_int()==clanid)setUF(user,inClan);
 else unSetUF(user,inClan);
 if(associates contains group(nameClan,2).to_int()){
  setUF(user,inAssociate);
  if(associates[group(nameClan,2).to_int()]==true)setUF(user,highAssociate);
 }
 if(!(getUF(user,inClan))){
  boolean wl=checkWhitelist(userdata[user].userid);
  if(wl)setUF(user,inClan);
 }
 commit(userdata,"userdata.txt");
 return userdata[user].userid;
}

//return id for given username. If name not on file, request it.
int getId(string sender){
 if(sender=="")return 0;
 int x=userdata[sender].userid;
 if(x==0)x=updateId(sender,false);
 return x;
}

string to_commad(int i){
 string s=to_string(i);
 string c;
 for l from length(s) downto 1 {
  if((l<length(s))&&((length(s)-l)%3==0))c=","+c;
  c=s.char_at(l-1)+c;
 }
 return c;
}

string factCore(string type){
 string[string,int] factList;
 update(factList,"facts.txt");
 return factList[type,random(count(factList[type]))+1];
}

string factCore(){
 return factCore("F");
}

string insultCore(){
 return factCore("I");
}

void updateDC(string list){
 if(list=="useCurrent")list=get_property("_currentDeals");
 else set_property("_currentDeals",list);
 string deals="";
 matcher extra=create_matcher("\\s,\\s",list);
 list=replace_all(extra,",");
 string[int] names=split_string(list,",");
 foreach x in names deals+=names[x]+" (#"+getId(names[x]).to_int()+")\n";
 if(deals==" (#0)\n"){
//  print("No deals for DC","green");
  deals="";
 }else{
  print("Deals in DC for the following players:","green");
  print(deals,"olive");
  deals="Current deals in mall:\n"+deals+"\n";
 } 
 int served=get_property('totalCastsEver').to_int();
 int days=get_property('totalDaysCasting').to_int()+1;
 string avg=to_string(served*1.0/days);
 if(index_of(avg,'.')+3<length(avg))avg=substring(avg,0,index_of(avg,'.')+3);
 string s="managecollection.php?action=changetext&pwd&newtext=";
 s+="Over "+to_commad(served)+" casts served since 2013!\n";
 s+="Daily Avg: "+avg+"\n\n";
 s+="More information on buffs offered can be found on the following page:\n";
 s+="http://kol.coldfront.net/thekolwiki/index.php/Buff\n\n";
 s+=deals;
 s+="Casts Remaining of limited skills listed below:\n";
 s+="Managerial Manipulation: "+to_int(1-userdata["*"].buffs[62])+"\n";
 claimResource("adventuring");
 visit_url(s);
 freeResource("adventuring");
}

void updateDC(){
 updateDC("");
}

void updateLimits(){
 string s;
 buffer n;
 claimResource("adventuring");
 if((50-userdata["*"].buffs[6026])>10){
  s="managecollection.php?action=modifyshelves&pwd&newname12=";
  s+=to_string(50-userdata["*"].buffs[6026]);
  n=visit_url(s);
 }else{
  s="managecollection.php?action=modifyshelves&pwd&newname12=50";
  n=visit_url(s); 
 }
 s="managecollectionshelves.php?pwd&action=arrange";
 if ((50-userdata["*"].buffs[6026])<11) s+="&whichshelf4502="+to_string(max(51-userdata["*"].buffs[6026],1));
 else s+="&whichshelf4502=12";
 s+="&whichshelf4503="+to_string(max(6-userdata["*"].buffs[6028],1));
 s+="&whichshelf4497="+to_string(max(11-userdata["*"].buffs[6020],1));
 s+="&whichshelf4498="+to_string(max(11-userdata["*"].buffs[6021],1));
 s+="&whichshelf4499="+to_string(max(11-userdata["*"].buffs[6022],1));
 s+="&whichshelf4500="+to_string(max(11-userdata["*"].buffs[6023],1));
 s+="&whichshelf4501="+to_string(max(11-userdata["*"].buffs[6024],1));
 n=visit_url(s);
 s=to_string(userdata["*"].buffs[62]);
 set_property("_limitBuffs",s);
 freeResource("adventuring");
}

int checkRep(string check){
// for i from 0 to repValue if(userdata["*"].aliases[i.to_string()]==check)return i;
 return -1;
}

void addRep(string s){
/* for i from 10 to 1{
  userdata["*"].aliases[i.to_string()]=userdata["*"].aliases[to_string(i-1)];
 }
 userdata["*"].aliases["0"]=s;
 map_to_file(userdata,"userdata.txt");*/
}

void saveSettings(){
 claimResource("adventuring");
 visit_url("questlog.php?which=4&action=updatenotes&font=0&notes=");
 freeResource("adventuring");
}

boolean loadSettings(string postRO){
 claimResource("adventuring");
 boolean rollpassed=false;
 string ls=visit_url("questlog.php?which=4");
 freeResource("adventuring");
 matcher notef=create_matcher(";'\\>([\\s\\S]*)\\</text",ls);
 if(!find(notef))return false;
 string[int] setting=split_string(group(notef,1),'\\r?\\n|\\s=\\s');
 int x=count(setting)/2;
 if(x==0)return false;
 int day=-1;
 for i from 0 to count(setting)-1 if(setting[i]=="!day")day=setting[i+1].to_int();
 if(day!=gameday_to_int()){
  rollpassed=true;
  string[int] skipsplit=split_string(postRO,';');
  int[string] skip;
  foreach toskip in skipsplit skip[skipsplit[toskip]]=1;
  for i from 0 to x-1 if(!(skip contains setting[2*i]))set_property(setting[2*i],setting[2*i+1]);
 }else for i from 0 to x-1 set_property(setting[2*i],setting[2*i+1]);
 saveSettings();
 return rollpassed;
}
boolean loadSettings(){
 return loadSettings("");
}

void formProps(){
 //admins
 string prop="";
 foreach u in userdata if(getUF(u,isAdmin))prop+=u+"::";
 set_property("admins",prop);
}

void saveSettings(string settings){
 formProps();
 string[int] setting=split_string(settings,';');
 string submit="";
 foreach i in setting submit+=setting[i]+" = "+get_property(setting[i])+"\n";
 submit+="!day = "+gameday_to_int();
 submit="questlog.php?which=4&action=updatenotes&font=0&notes="+submit;
 claimResource("adventuring");
 visit_url(submit);
 freeResource("adventuring");
}

void deleteAnnouncement(){
 claimResource("adventuring");
 string t=visit_url("clan_hall.php");
 matcher m=create_matcher("(\\d+)\">delete</a>\\]<b><br>From: Ominous Buffer \\(",t);
 if(m.find())visit_url("clan_hall.php?action=delete&pwd&msgid="+m.group(1));
 freeResource("adventuring");
}

void announceClan(string message){
 claimResource("adventuring");
 deleteAnnouncement();
 string t="clan_board.php?action=postannounce&pwd&message="+message;
 visit_url(t);
 freeResource("adventuring");
}

void checkApps(){
 int[item] gift;
 gift[$item[black forest cake]]=1;
 gift[$item[bulky buddy box]]=1;
 claimResource("adventuring");
 boolean acceptall=true;
 matcher appcheck=create_matcher("y <b>(\\d+)</b> p", visit_url("clan_office.php"));	
 if((appcheck.find())&&(acceptall)){
  matcher applicants=create_matcher("who=(\\d+)\">(.+?)<",visit_url("clan_applications.php"));
  while(applicants.find()){
   print("Accepting "+applicants.group(2)+" into the clan.");
   visit_url("clan_applications.php?request"+applicants.group(1)+"=1&action=process");
   visit_url("clan_members.php?pwd="+my_hash()+"&action=modify&level"+applicants.group(1)+"=7&title"+applicants.group(1)+"=Cake&pids[]="+applicants.group(1));
   if(getUF(applicants.group(2),receivedCake))continue;
   retrieve_item(1,$item[black forest cake]);
   retrieve_item(1,$item[bulky buddy box]);
   /**/kmail(applicants.group(1),"Welcome to Black Mesa! I'm the clan's multi-purpose bot. When you get a chance, please hop into chat to say \"hello.\" If you're new to the game and don't know how to do this, please send a message to Sentrion or Twinkertoes, and they will get back to you as quickly as possible. Otherwise, if you have any questions, just ask in chat, and someone should be able to answer. Enjoy!",0,gift);
   chat_clan(applicants.group(2)+" has just been accepted into Black Mesa. If you see them around chat, be sure to give them a warm welcome!");
   checkOut(userdata,"userdata.txt");
   userdata[group(applicants,2)].userid=group(applicants,1).to_int();
   userdata[group(applicants,2)].flags|=(inClan|receivedCake);
   commit(userdata,"userdata.txt");
  }
 }
 freeResource("adventuring");
}

void checkData(){
 update(userdata,"userdata.txt");
 if(!(userdata["*"].aliases contains "boss")){
  checkOut(userdata,"userdata.txt");
  userdata["*"].aliases["boss"]="25 phat loot, 25 thingfinder, 25 chorale";
  commit(userdata,"userdata.txt");
  chat_private("Sentrion","I am error.");
  chat_private("Almighty Sapling","I am error.");
  chat_clan("I am error.");
 }
}

void raffleAnnounce(gameData g){
 string s="RAFFLE!\n";
 s+=g.host+" is raffling away the following prizes!\n";
 foreach i,a in g.players if(i.char_at(0)!=":")s+=i.to_string()+" ("+a.to_string()+")\n";
 if(g.players[":meat"]>0)s+="And "+g.players[":meat"].to_commad()+" meat!\n";
 s+="Tickets cost "+g.intervals.to_string()+" meat each and ";
 if(g.players[":end"]==1)s+="today is your last day to buy!";
  else s+="the raffle ends in "+g.players[":end"].to_string()+" days.";
 s+=g.data[0];
 announceClan(s);
}

void issueTickets(gameData g,string w,int amount){
 int lastTicket=count(g.data);
 for i from lastTicket+1 upto lastTicket+amount g.data[i]=w;
 string r="Thank you for your interest in the raffle. You have purchased the following tickets:\n";
 r+=to_string(lastTicket+1);
 if(amount>1)r+="-"+to_string(lastTicket+amount);
 r+="\nGood luck!";
 kmail(w,r);
 g.players[":meat"]+=(g.intervals/20)*amount;
}

void endRaffle(gameData g){
 deleteAnnouncement();
 checkOut(userdata,"userdata.txt");
 chat_clan("A Raffle House is Us!");
 int numtix=count(g.data);
 wait(5);
 chat_clan("We managed to sell "+numtix.to_commad()+" tickets for a total of "+to_commad(numtix*g.intervals)+" meat!");
 chat_clan("And the winner is...");
 if (numtix>1) numtix=random(numtix)+1;
  else numtix=1;
 wait(10);
 chat_clan(g.data[numtix]+" with ticket number "+numtix.to_commad()+".");
 chat_clan("Well, that's all folks, have fun and better luck next time!");
 int[item] reward;
 foreach it,amt in g.players if(it.char_at(0)!=":")reward[it.to_item()]=amt;
 int toPull=ceil(g.players[":meat"]*1.0/1000);
 cli_execute("closet take "+toPull.to_string()+" dense meat stack");
 cli_execute("autosell * dense meat stack");
 if(kmail(g.data[numtix],"Congratulations, you've got the golden ticket!",g.players[":meat"],reward)!=1){
  g.players[":meat"]=max(0,g.players[":meat"]-50*count(reward));
  string send;
  foreach it,amt in reward{
   send="town_sendgift.php?pwd="+my_hash()+"&towho="+g.data[numtix]+"&note=You won the Raffle!&insidenote=A winner is you! Collect your meat from OB's Wallet!&whichpackage=1&howmany1="+amt.to_string()+"&whichitem1="+it.to_int().to_string();
   send+="&fromwhere=0&action=Yep.";
   visit_url(send);
  }
  userdata[g.data[numtix]].wallet+=g.players[":meat"];
 }
 remove gamesavedata["raffle"];
 commit(gamesavedata,"gameMode.txt");
 commit(userdata,"userdata.txt");
}

void checkMail(){
 claimResource("adventuring");
 checkOut(userdata,"userdata.txt");
 message[int] mail=parseMail();
 matcher mx;
 string build;
 while(item_amount($item[plain brown wrapper])>0){
  break;
 }
 foreach i,m in mail{
  if(m.sender=="smashbot"){
   deleteMail(m);
   continue;
  }
  mx=create_matcher("(?i)donat(?:e|ation)",m.text);
  if(mx.find()){
   deleteMail(m);
   if(m.things[$item[dense meat stack]]>0){
    cli_execute("autosell "+m.things[$item[dense meat stack]].to_string()+" dense meat stack");
    m.meat+=m.things[$item[dense meat stack]]*1000;
    remove m.things[$item[dense meat stack]];
   }
   userdata[m.sender].donated+=m.meat;
   build="";
   foreach it,amount in m.things if((it.to_int()>4496)&&(it.to_int()<4504))continue;
    else build+=amount+" "+it+", ";
   cli_execute("display put "+build);
   print("Arranging items");
   build="managecollectionshelves.php?pwd&action=arrange";
   foreach it in m.things if ((it.to_int()>4496)&&(it.to_int()<4504))continue;
    else build+="&whichshelf"+it.to_int().to_string()+"=13";
   visit_url(build);
   print("Donation accepted.");
   continue;
  }
  build="-";
  mx=create_matcher("(?i)raffle\\s?(start|stop|cancel|add|\\+)?",m.text);
  if(mx.find()){
   build=mx.group(1)==""?"start":mx.group(1).to_lower_case();
  }
  mx=create_matcher("(?i)(start|stop|cancel|add|\\+)?\\s?raffle",m.text);
  if(mx.find()){
   build=mx.group(1)==""?"start":mx.group(1).to_lower_case();
  }
  if(build!="-"){
   deleteMail(m);
   checkOut(gamesavedata,"gameMode.txt");
   gameData game;
   if(gamesavedata contains "raffle"){
    game=gamesavedata["raffle"];
    switch(build){
     case "start":
      build="Sorry, but there is already a raffle in play. It ends in ";
      build+=game.players[":end"].to_string()+(game.players[":end"]==1?" day.\n":" days.\n");
      build+="Wait until the current raffle is over, or, if you'd like to add to the current raffle, send the items back with the message \"Raffle +\"";
      kmail(m.sender,build,m.meat,m.things);
      break;
     case "stop":case "end":
      game.endRaffle();
      break;
     case "cancel":
      //CANCEL RAFFLE
      break;
     case "add":case "+":
      build="Added the following items to "+game.host+"'s raffle:\n";
      foreach it,amt in m.things{
       game.players[it.to_string()]+=amt;
       build+=it.to_string()+" ("+amt.to_string()+")\n";
      }
      game.players[":meat"]+=m.meat;
      build+="meat ("+m.meat.to_string()+")\n";
      kmail(m.sender,build);
      break;
     default:
      if(m.sender==game.host){
       game.players[":meat"]+=m.meat;
       build+="Meat added to raffle value. ("+m.meat.to_string()+")\n";
       kmail(m.sender,build);
       break;
      }
      if(m.things contains $item[plain brown wrapper])break;
      if(m.meat==0)break;
      int numt=m.meat/game.intervals;
      m.meat=m.meat-(numt*game.intervals);
      if(m.meat>0)if(kmail(m.sender,"Considering the cost of tickets, this is what was left over.",m.meat)!=1){
       userdata[m.sender].wallet+=m.meat;
       kmail(m.sender,"Your refund failed to send, so I'll hold it for you for now: "+m.meat.to_string()+" meat.");
      }
      game.issueTickets(m.sender,numt);
      break;
    }
   }else{
/*
raffle gameData{
 int[string] players; [item name]=amount for winner;
                      [":end"]=days remaining;
                      [":meat"]=meat portion of prize;
 string[int] data; [ticketnumber]=playername
 boolean gameStarted; UNUSED;
 int roundOver; TICKETS SOLD
 int intervals; COST
 string host; HOST
};
*/
    switch(build){
     case "start":
      game.host=m.sender;
      game.roundOver=0;
      mx=create_matcher("(?i)(?:price|cost):\\s?(\\d+)",m.text);
      game.intervals=100;
      if(mx.find())game.intervals=min(max(floor(mx.group(1).to_int()/100)*100,100),5000);
      mx=create_matcher("(?i)(?:time|duration|length):\\s?(\\d+)\\s?days?",m.text);
      game.players[":end"]=7;
      if(mx.find())game.players[":end"]=min(max(mx.group(1).to_int(),2),14);
      foreach thing,amt in m.things game.players[thing.to_string()]=amt;
      game.players[":meat"]=m.meat;
      mx=create_matcher("(?i)(?:message|text|quote):\\s\"(.+?)\"",m.text);
      if(mx.find())game.data[0]=mx.group(1);
/*      gamesavedata["raffle"]=game;
      raffleAnnounce(game); LEAVE OUT UNTIL READY TO ROLL*/
      break;
     case "stop":case "end":
      if(getUF(m.sender,isAdmin))chat_private(m.sender,"There is no raffle in play.");
      else chat_private(m.sender,"You don't have that privelage.");
      break;
     case "cancel":
      if(getUF(m.sender,isAdmin))chat_private(m.sender,"There is no raffle in play.");
      else chat_private(m.sender,"You don't have that privelage.");
      break;
     case "add":case "+":
      kmail(m.sender,"There is no raffle in play; therefore, you can't add to it.",m.meat,m.things);
      break;
     default:
      if(m.meat>0)kmail(m.sender,"You sent me this?",m.meat);
      break;
    }
   }
   commit(gamesavedata,"gameMode.txt");
   continue;
  }
 }
 commit(userdata,"userdata.txt");
 freeResource("adventuring");
}