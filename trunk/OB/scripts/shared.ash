import <kmail.ash>
import <games.ash>
string NAME_=__FILE__;

string[string,string] userdata;
file_to_map("userdata.txt",userdata);

//Global variables
string sauceBot="Ominous Sauceror";
string turtleBot="Ominous Tamer";
string nightlySave="totalDaysCasting;totalCastsEver;sauceCasts;tamerCasts;books;winners;level";
string earlySave="nunsVisits;totalCastsEver;totalDaysCasting;_breakfast;_limitBuffs;_currentDeals;lottos;books;winners;admins;level";
string ignorePile="_breakfast;_limitBuffs;nunsVisits;_currentDeals;lottos;!day";
int burnTurns=100;
string meatFam="leprechaun";
string statFam="hovering sombrero";
boolean errorFree=false;

int clanid=2046994401;//Black Mesa
boolean[int] associates;
associates[21459]=true;//Hogs of Destiny
associates[67356]=true;//Piglets of Fate
associates[2046987019]=true;//Not Dead Yet
associates[2046991167]=true;//This One Time
associates[2046983684]=true;//Clan of 14 Days
associates[2046991423]=true;//Margaretting Tye
associates[76566]=true;//Imitation Plastic Death Star
associates[72876]=true;//Hyrule

aggregate checkOut(aggregate data, string resourceName){ //Load a file
 file_to_map(resourceName,data);
 return data;
}

void commit(aggregate data, string resourceName){ //Save data
 map_to_file(data,resourceName);
}

int minutesToRollover(){
 int GMT=to_int(now_to_string("HHmm"))-to_int(now_to_string("Z"));
 if(GMT<0)GMT+=2400;
 if(GMT>2399)GMT-=2400;
 string GMTs=to_string(GMT);
 while(length(GMTs)<4)GMTs="0"+GMTs;
 GMT=to_int(substring(GMTs,0,2))*60+to_int(substring(GMTs,2));
 GMT=210-GMT;
 if(GMT<0)GMT+=24*60;
 return GMT;
}

void defaultProp(string user,string prop){
 if(userdata[":"] contains prop)userdata[user,prop]=userdata[":",prop];
 else remove userdata[user,prop];
}

string defaultProp(string prop){
 return userdata[":",prop];
}

boolean getUF(string user,string flag){
 if(!(userdata[user] contains flag))defaultProp(user,flag);
 return userdata[user,flag].to_boolean();
}

boolean matchesFrom(string user,string setting,string list){
 string[int] props=split_string(list,",");
 foreach i,s in props{
  if((userdata[user,setting]==s)&&(s!=""))return true;
  if((s=="")&&(userdata[user,setting]==""))return true;//THIS MAKES SENSE, TRUST ME
 }
 return false;
}

boolean propContains(string user,string setting,string thing){
 string[int] props=split_string(userdata[user,setting],",");
 foreach i,s in props if(s==thing)return true;
 return false;
}

/*void addProp(string user,string setting,string prop){
 if(!matchesFrom(user,setting,prop))userdata[user,setting]+=","+prop;
}

void removeProp(string user,string setting,string prop){
}*/

string sysString(string user, string prop){
 if(userdata[user] contains prop)return userdata[user,prop];
 return defaultProp(prop);
}

int sysInt(string user,string prop){
 return userdata[user,prop].to_int();
}
int sysInt(string prop){
 return sysInt("*",prop);
}

void sysInc(string user,string prop,int amt){
 userdata[user,prop]=to_string(userdata[user,prop].to_int()+amt);
}
void sysInc(string prop, int amt){
 sysInc("*",prop,amt);
}
void sysInc(string user,string prop){
 sysInc(user,prop,1);
}
void sysInc(string prop){
 sysInc("*",prop,1);
}

//check clan whitelist for user if not in clan
boolean checkWhitelist(string id){
 string page=visit_url("clan_whitelist.php");
 matcher m=create_matcher("(?i)="+id+"'",page);
 if(find(m))return true;
 return false;
}

string to_playerName(int pId){
 string v=visit_url("showplayer.php?who="+pId.to_string());
 matcher m=create_matcher("<center><b>(.+?)</b>",v);
 if (m.find()){
  return m.group(1);
 }
 return ":NONE";
}

string to_clanName(int cId){
 string p=visit_url("showclan.php?whichclan="+cId);
 matcher m=create_matcher("blue><b>(.+?)</b",p);
 if(!m.find())return "";
 return m.group(1);
}

//request unknown user's id. if (add) then place them into the users file.
string updateId(string user,boolean add){
 if(user=="")return 0;
 string searchstring=visit_url("searchplayer.php?searching=Yep.&searchstring="+user+"&hardcoreonly=0");
 matcher nameClan=create_matcher('(?i)(\\d*)">'+user+'</a></b> (?: \\(PvP\\))?(?:<br>\\(<a target=mainpane href="showclan\\.php\\?whichclan=(\\d*))?',searchstring);
 if(!find(nameClan))return 0;
 checkOut(userdata,"userdata.txt");
 if(!add)return group(nameClan,1).to_int();
 userdata[user,"ID#"]=group(nameClan,1);
 if(!matchesFrom(user,"membership","whitelist,blacklist"))defaultProp(user,"membership");
 if(group(nameClan,2).to_int()==clanid)userdata[user,"membership"]="clannie";
 if(associates contains group(nameClan,2).to_int())userdata[user,"membership"]="associate";
 if((!matchesFrom(user,"membership","clannie"))&&(checkWhitelist(userdata[user,"ID#"])))userdata[user,"membership"]="clannie";
 commit(userdata,"userdata.txt");
 return userdata[user,"ID#"];
}

//return id for given username. If name not on file, request it.
string getId(string sender){
 if(sender=="")return 0;
 string x=userdata[sender,"ID#"];
 if(x=="")x=updateId(sender,false);
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

string factCore(string type,int i){
 string[string,int] factList;
 checkOut(factList,"facts.txt");
 if((i<0)||(i>=count(factList[type])))return factList[type,random(count(factList[type]))];
 return factList[type,i];
}

string factCore(){
 return factCore("F",-1);
}

string insultCore(){
 return factCore("I",-1);
}

void deMole(){
 if(have_effect($effect[Shape of...Mole!])>0){
  while(have_effect($effect[Shape of...Mole!])>0)(!adventure(1,$location[Mt. Molehill]));
  if(!adventure(1,$location[Mt. Molehill])){}
  visit_url("choice.php?pwd="+my_hash()+"&whichchoice=277&option=1");
 }
}

void clearBuffs(int skip){
 for i from 6000 to 6030{
  if((i==6006)||(i==6010)||(i==skip))continue;
  if(i.to_skill().to_effect().have_effect()>0)cli_execute("uneffect "+i.to_skill().to_effect().to_string());
 }
}
void clearBuffs(){
 clearBuffs(0);
}

void updateDC(string list){
 if(list=="useCurrent")list=get_property("_currentDeals");
 else set_property("_currentDeals",list);
 string deals="";
 matcher extra=create_matcher("\\s,\\s",list);
 list=replace_all(extra,",");
 string[int] names=split_string(list,",");
 foreach x in names deals+=names[x]+" (#"+getId(names[x])+")\n";
 if(deals==" (#0)\n")deals="";
 else deals="Current deals in mall:\n"+deals+"\n";
 int served=get_property('sauceCasts').to_int()+get_property('tamerCasts').to_int()+get_property('totalCastsEver').to_int();
 int days=get_property('totalDaysCasting').to_int()+1;
 string avg=to_string(served*1.0/days);
 if(index_of(avg,'.')+3<length(avg))avg=substring(avg,0,index_of(avg,'.')+3);
 string s="managecollection.php?action=changetext&pwd&newtext=";
 s+="Over "+to_commad(served)+" casts served since 2011!\n";
 s+="Daily Avg: "+avg+"\n\n";
 s+="More information on buffs offered can be found on the following page:\n";
 s+="http://kol.coldfront.net/thekolwiki/index.php/Buff\n\n";
 s+=deals;
 s+="Casts Remaining of limited skills listed below:\n";
 s+="Managerial Manipulation: "+to_int(3-sysInt("#62"))+"\n";
 visit_url(s);
}
void updateDC(){
 updateDC("");
}

void updateProfile(){
 int[string]books;
 checkOut(books,"books.txt");
 string buf="account.php?action=Update&tab=profile&pwd="+my_hash()+"&actions[]=quote&quote=Black Mesa Buffbot. Serving all your AT, TT, and S needs.";
 buf+="\n\nCheck DC for casts remaining of limited use skills.\n\nCurrent Lotto for "+to_commad(14+books["thisLotto"])+",000 meat!\nLast Five Lotto Winners:";
 string wintext=get_property("winners");
 string[int] winners=split_string(wintext,"::");
 for i from 0 upto count(winners)-1 buf+="\n"+winners[i];
 visit_url(buf);
}

void updateLimits(){
 string s;
 buffer n;
 if((50-sysInt("#6026"))>10){
  s="managecollection.php?action=modifyshelves&pwd&newname12=";
  s+=to_string(50-sysInt("#6026"));
  n=visit_url(s);
 }else{
  s="managecollection.php?action=modifyshelves&pwd&newname12=50";
  n=visit_url(s); 
 }
 s="managecollectionshelves.php?pwd&action=arrange";
 if((50-sysInt("#6026"))<11)s+="&whichshelf4502="+to_string(max(51-sysInt("#6026"),1));
 else s+="&whichshelf4502=12";
 s+="&whichshelf4503="+to_string(max(6-sysInt("#6028"),1));
 s+="&whichshelf4497="+to_string(max(11-sysInt("#6020"),1));
 s+="&whichshelf4498="+to_string(max(11-sysInt("#6021"),1));
 s+="&whichshelf4499="+to_string(max(11-sysInt("#6022"),1));
 s+="&whichshelf4500="+to_string(max(11-sysInt("#6023"),1));
 s+="&whichshelf4501="+to_string(max(11-sysInt("#6024"),1));
 n=visit_url(s);
 set_property("_limitBuffs",userdata["*","#62"]);
}

void saveSettings(){
 visit_url("questlog.php?which=4&action=updatenotes&font=0&notes=");
}

boolean loadSettings(string postRO){
 boolean rollpassed=false;
 string ls=visit_url("questlog.php?which=4");
 matcher notef=create_matcher(";'\\>([\\s\\S]*)\\</text",ls);
 if(!find(notef))return false;
 string[int] setting=split_string(group(notef,1),'\\r?\\n|\\s=\\s');
 int x=count(setting)/2;
 if(x==0)return false;
 int day=-1;
 for i from 0 to count(setting)-1 if(setting[i]=="!day")day=setting[i+1].to_int();
 print("Quest Save Data: "+day+"; Today: "+gameday_to_int());
 if(day!=gameday_to_int()){
  rollpassed=true;
  string[int] skipsplit=split_string(postRO,';');
  int[string] skip;
  foreach num,toskip in skipsplit skip[toskip]=1;
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
 foreach u in userdata if(getUF(u,"admin"))prop+=u+"::";
 set_property("admins",prop);
 int[string] books;
 checkOut(books,"books.txt");
 string[int]split=split_string(get_property("books"),"::");
 books["thisLotto"]=split[0].to_int();
 books["nextLotto"]=split[1].to_int();
 commit(books,"books.txt");
}

void saveSettings(string settings){
 formProps();
 string[int] setting=split_string(settings,';');
 string submit="";
 foreach i in setting submit+=setting[i]+" = "+get_property(setting[i])+"\n";
 submit+="!day = "+gameday_to_int();
 submit="questlog.php?which=4&action=updatenotes&font=0&notes="+submit;
 visit_url(submit);
}

void deleteAnnouncement(){
 string t=visit_url("clan_hall.php");
 matcher m=create_matcher("(\\d+)\">delete</a>\\]<b><br>From: Ominous Buffer \\(",t);
 if(m.find())visit_url("clan_hall.php?action=delete&pwd&msgid="+m.group(1));
}

void announceClan(string message){
 deleteAnnouncement();
 string t="clan_board.php?action=postannounce&pwd&message="+message;
 visit_url(t);
}

void checkApps(){
 int[item] gift;
 gift[$item[black forest cake]]=1;
// gift[$item[bulky buddy box]]=1;
 boolean acceptall=true;
 matcher appcheck=create_matcher("y <b>(\\d+)</b> p", visit_url("clan_office.php"));
 if((appcheck.find())&&(acceptall)){
  matcher applicants=create_matcher("who=(\\d+)\">(.+?)<",visit_url("clan_applications.php"));
  while(applicants.find()){
   if(matchesFrom(applicants.group(2),"membership","blacklist")){
    print("blacklist "+applicants.group(2)+" wants in");
    continue;
   }
   print("Accepting "+applicants.group(2)+" into the clan.");
   visit_url("clan_applications.php?request"+applicants.group(1)+"=1&action=process");
   visit_url("clan_members.php?pwd="+my_hash()+"&action=modify&level"+applicants.group(1)+"=7&title"+applicants.group(1)+"=Cake&pids[]="+applicants.group(1));
   if(getUF(applicants.group(2),"hasCake"))continue;
   retrieve_item(1,$item[black forest cake]);
   retrieve_item(1,$item[bulky buddy box]);
   /**/kmail(applicants.group(1),"Welcome to Black Mesa! I'm the clan's multi-purpose bot. When you get a chance, please hop into chat to say \"hello.\" If you're new to the game and don't know how to do this, please send a message to Sentrion or Twinkertoes, and they will get back to you as quickly as possible. Otherwise, if you have any questions, just ask in chat, and someone should be able to answer. Enjoy!",0,gift);
   chat_clan(applicants.group(2)+" has just been accepted into Black Mesa. If you see them around chat, be sure to give them a warm welcome!");
   checkOut(userdata,"userdata.txt");
   userdata[applicants.group(2),"ID#"]=applicants.group(1);
   if(!matchesFrom(applicants.group(2),"membership","whitelist"))userdata[applicants.group(2),"membership"]="clannie";
   userdata[applicants.group(2),"hasCake"]="true";
   commit(userdata,"userdata.txt");
  }
 }
}

/*void checkData(){
 checkOut(userdata,"userdata.txt");
 if(!(userdata["*"] contains "~boss")){
  checkOut(userdata,"userdata.txt");
  userdata["*","~boss"]="25 phat loot, 25 thingfinder, 25 chorale";
  userdata["*","~s"]="100 elemental, 100 jalape, 100 jaba, 100 scarysauce";
  userdata["*","~tt"]="100 astral, 100 ghostly, 100 tenacity, 100 empathy, 100 reptilian, 100 jingle";
  commit(userdata,"userdata.txt");
  chat_private("Sentrion","I am error.");
  chat_private("Almighty Sapling","I am error.");
  chat_clan("I am error.");
 }
}*/

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
  userdata[g.data[numtix],"meat"]=to_string(userdata[g.data[numtix],"meat"]+g.players[":meat"]);
 }
 remove gamesavedata["raffle"];
 commit(gamesavedata,"gameMode.txt");
 commit(userdata,"userdata.txt");
}

void checkMail(){
 checkOut(userdata,"userdata.txt");
 message[int] mail=parseMail();
 matcher mx;
 string build;
 while(item_amount($item[plain brown wrapper])>0){
  break;
 }
 foreach i,m in mail{
  if((m.sender=="smashbot")||(m.sender=="ominous tamer")||(m.sender=="ominous sauceror")){
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
   userdata[m.sender,"donated"]=to_string(userdata[m.sender,"donated"]+m.meat);
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
  mx=create_matcher("(?i)(start|stop|cancel|add|\\+)?\\s?raffle\\s?(start|stop|cancel|add|\\+)?",m.text);
  if(mx.find())build=mx.group(1)==""?mx.group(2).to_lower_case():mx.group(1).to_lower_case();
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
       userdata[m.sender,"meat"]=to_string(userdata[m.sender,"meat"].to_int()+m.meat);
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
      gamesavedata["raffle"]=game;
      raffleAnnounce(game); //LEAVE OUT UNTIL READY TO ROLL
      break;
     case "stop":case "end":
      if(getUF(m.sender,"admin"))chat_private(m.sender,"There is no raffle in play.");
      else chat_private(m.sender,"You don't have that privelage.");
      break;
     case "cancel":
      if(getUF(m.sender,"admin"))chat_private(m.sender,"There is no raffle in play.");
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
}