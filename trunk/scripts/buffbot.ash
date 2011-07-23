import <shared.ash>
import <market.ash>
import <mathlib.ash>

string[int] to_array(boolean[string] data){
 string[int] x;
 foreach y in data
  x[count(x)]=y;
 return x;
}

string genderMatcherString="(?:I AM|I'M) (?:AN |A )?(WHO I AM|ME";
string[int,int] genders;                //0        1      2        3            4     5       6
genders[count(genders)]=to_array($strings[genders, third, unknown, androgynous, male, female, inanimate]);
genders[count(genders)]=to_array($strings[*]);//WHO I AM
genders[count(genders)]=to_array($strings[he, him, himself, his, his]);
genders[count(genders)]=to_array($strings[they, them, themselves, theirs, their, ANGROGYNOUS|PLURAL|HERMAPHRODIT]);
genders[count(genders)]=to_array($strings[he, him, himself, his, his, BOY|MAN|MALE]);
genders[count(genders)]=to_array($strings[she, her, herself, hers, her, GIRL|WOMAN|FEMALE]);
genders[count(genders)]=to_array($strings[it, it, itself, its, its, IT|INANIMATE|NEUTRAL|GENDERLESS]);
//Genders[0] lists titles for Genders[]
//Genders[1] is a place holder for third person.
//Genders[2+] are as follows: subjective, objective, reflexive, possessive pronoun, possessive determiner. Optionally: Match string text
int gSub=0;
int gObj=1;
int gRefl=2;
int gPosPro=3;
int gPosDet=4;

record responses{
 string reply;
 int flags;
 string method;
 string cond1;
 string cond2;
};
int caseSensitive=1;
int fullText=2;
int mustAddress=4;
int mustRefer=8;
int repFree=16;

record timestamp{
 boolean lastChatterA;
 string lastCA;
 string lastCB;
 int lastAh;
 int lastAm;
 int lastBh;
 int lastBm;
};
timestamp[int] ctimestemp;
file_to_map("timefile.txt",ctimestemp);
timestamp ctimes=ctimestemp[0];

boolean errorMsg=true;
string someoneDefined="";
string[string] chatVars;
int TPC=25;

string genderPronoun(string who, int what, string type){
 boolean cap=false;
 if (type.contains_text("P")||type.contains_text("S")) cap=true;
 type=substring(type,1);
 int t=5;
 string reply;
 switch(type){
  case "sub":t=0;break;
  case "obj":t=1;break;
  case "ref":t=2;break;
  case "pos":t=3;break;
  case "det":t=4;break;
 }
 if (what!=1) reply=genders[what,t];
 else if (t<3) reply=who;
 else reply=who+"'s";
 if (cap) reply=reply.char_at(0).to_upper_case()+reply.substring(1);
 return reply;
}

string genderString(userinfo data){
 if(data.gender==0)data.gender=2;
 if(data.gender==1)return data.nick;
 return genders[0,data.gender];
}

void errorMessage(string who,string what){
 if(errorMsg)chat_private(who,what);
}

void errorMessage(string who,string what,int g){
 matcher mx=create_matcher("(?i)(\\$psub|\\$pobj|\\$pref|\\$ppos|\\&pdet)",what);
 while (mx.find()){
  what=mx.replace_first(genderPronoun(who,g,mx.group(1)));
  mx=mx.reset(what);
 }
}

boolean buffable(string sender){
 if (userdata[sender].userid==0) updateId(sender,true);
 if (getUF(sender,blacklist)){
  chat_private(sender,"We do what we must because we can. For the good of all of us. Except the ones who are blacklisted from Black Mesa.");
  return false;
 }
 if (getUF(sender,inClan)||getUF(sender,whitelist)||getUF(sender,inAssociate)){
  return true;
 }else{
  chat_private(sender,"We do what we must because we can. For the good of all of us. Except the ones who are not in Black Mesa.");
  return false;
 }
}

string decodeHTML(string msg,boolean chat){
 matcher i;
 if (chat){
  i=create_matcher("<a style.+?>(.+?)</a>",msg);
  while (i.find()){
   msg=replace_first(i,i.group(1));
   i=create_matcher("<a style.+?>(.+?)</a>",msg);
  }
  i=create_matcher("<a .+?/a>",msg);
  msg=replace_all(i,"");
 }
 i=create_matcher("&quot;",msg);
 msg=replace_all(i,"\"");
 i=create_matcher("&lt;",msg);
 msg=replace_all(i,"<");
 i=create_matcher("&gt;",msg);
 msg=replace_all(i,">");
 i=create_matcher("&#39;",msg);
 msg=replace_all(i,"'"); 
 i=create_matcher("&amp;",msg);
 msg=replace_all(i,"&");
 if(chat){
  i=create_matcher(" -hic-$",msg);
  msg=replace_all(i,"");
 }
 return msg;
}

void logout(string sender, string msg){
 if ((userdata[sender].flags&isAdmin)!=isAdmin){
  chat_private(sender,"You do not have permission to use this command.");
  return;
 }
 saveSettings("nunsVisits;totalCastsEver;totalDaysCasting;_breakfast;rolladv;rollmp;_limitBuffs;_currentDeals");
 set_property("chatbotScript","off");
 cli_execute("exit");
}

void createpack(string sender, string msg){
 matcher namem=create_matcher("(\\S*)\\s?(.*)",msg);
 string packname;
 string packdata;
 if (find(namem)){
  packname=group(namem,1);
  packdata=group(namem,2);
 }else{
  chat_private(sender,"You must supply the appropriate data for us to save that.");
  return;
 }
 if ((count(userdata[sender].buffpacks)>9)&&(!(userdata[sender].buffpacks contains packname))){
  chat_private(sender,"You already have 10 buffpacks, to have more would be ridiculous; not even funny.");
  return;
 }
 chat_private(sender,"Your buffpack has been saved.");
 userdata[sender].buffpacks[packname]=packdata;
 map_to_file(userdata,"userdata.txt");
}

void delpack(string sender, string packname){
 string s=remove userdata[sender].buffpacks[packname];
 if(s!="")chat_private(sender,"Pack removed.");
 map_to_file(userdata,"userdata.txt");
}

void buff(string sender, string msg, int numTurns, string ding){
 //Catch incoming error messages (success in the case of Employee of the Month) from other Bots
 if ((to_lower_case(sender)==turt_name) || (to_lower_case(sender)==sauc_name)){
  string[int] failsplit = split_string(msg,"\\s");
  if (index_of("ARLNS",failsplit[0])>-1) foreach name in userdata
   if (userdata[name].userid==to_int(failsplit[1])){
    sender=name;
    break;
   }
  switch (failsplit[0]){
   case "CASTRQ":
    if (sender==turt_name) set_property('tamerCasts',failsplit[1]);
    if (sender==sauc_name) set_property('sauceCasts',failsplit[1]);
    break;
   case "FUNDS":
    chat_private("Almighty Sapling","low funds on "+sender+".");
    break;
   case "A":
    errorMessage(sender,"I can't buff you while you're adventuring!");
    break;
   case "R":
    errorMessage(sender,"I can't buff you if you're in Hardcore or Ronin!");
    break;
   case "L":
    errorMessage(failsplit[2],"I'm sorry, but you've reached your daily limit for that buff.");
    break;
   case "N":
    errorMessage(failsplit[2],"The cake is a lie. So is that thing you asked for, since it wasn't a buff.");
    break;
   case "S":
    userdata[failsplit[2]].buffs[failsplit[3].to_int()]+=1;
    userdata["*"].buffs[failsplit[3].to_int()]+=1;
    map_to_file(userdata,"userdata.txt");
    updateDC("useCurrent");
    updateLimits();
    break;
  }
  return;
 }

 skill messageNew;
 messageNew=to_skill(msg);
 int casts;
 int max;
 int skillnum=to_int(messageNew);
 if (skillnum>9000){
  skillnum-=9000;
  skillnum=(skillnum/100)*1000+skillnum-((skillnum/100)*100);
 }
 switch (skillnum){
  case 1:case 3:case 12:case 15:case 19:
  case 46:case 47:case 48:case 58:case 59:case 60: return;
  case 7008: skillnum=6004; break;//Correct for Moxious Maneuver
  case 7040:case 7041: return;
 }
 //Forward skill requests to relay bots when necessary
 if (getUF(ding,inAssociate)) max=400;
 if ((max==400)&&(getUF(ding,highAssociate))) max=700;
 if (getUF(ding,inClan)||getUF(ding,whitelist)) max=700;
 int senderid=getId(sender);
 string mout;
 if (skillnum==62){
  numTurns=TPC;
  switch (userdata["*"].buffs[skillnum]){
   case 1:
    mout=to_string(senderid)+" "+to_string(getId(ding))+" "+to_string(skillnum)+" "+to_string(numTurns)+" 1";
    chat_private(turt_name,mout);
    return;
   case 2:
    mout=to_string(senderid)+" "+to_string(getId(ding))+" "+to_string(skillnum)+" "+to_string(numTurns)+" 1";
    chat_private(sauc_name,mout);
    return;
   case 3:
    errorMessage(sender,"I'm sorry, but I'm all out of "+messageNew+" for today.");
    return;
  }
 }
 if ((skillnum>2000)&&(skillnum<3000)){
  mout=to_string(senderid)+" "+to_string(getId(ding))+" "+to_string(skillnum)+" "+to_string(numTurns)+" "+to_string(max);
  chat_private(turt_name,mout);
  return;
 }
 if ((skillnum>4000)&&(skillnum<5000)){
  mout=to_string(senderid)+" "+to_string(getId(ding))+" "+to_string(skillnum)+" "+to_string(numTurns)+" "+to_string(max);
  chat_private(sauc_name,mout);
  return;
 }
 //Assign default values if turns isn't specified.
 if (skillnum==6014) numTurns=TPC;//Ode
 if (numTurns==0){
  if (skillnum==6026) numTurns=125;//Donho
  else if (((skillnum>6019)&&(skillnum<6025))||(skillnum==6028)) numTurns=25;//Limited buffs
  else if (skillnum!=6014) numTurns=200;//Else
 }
 casts=ceil(numTurns/(TPC*1.0));
 //Assign buff limits by clan.
 if(getUF(ding,inClan)||getUF(ding,whitelist)||(getUF(ding,inAssociate)&&getUF(ding,highAssociate))){
  if (((skillnum>6019) && (skillnum<6025)) || (skillnum==6028)) max=1;//Limited buffs
  else if (skillnum==6014) max=5;//Ode
  else if (skillnum==6026) max=20;//Donho
  else if (skillnum==6901) max=1;//Time's Arrow
  else max=28;//Else
 }else if (getUF(ding,inAssociate)){
  if (((skillnum>6019) && (skillnum<6025)) || (skillnum==6028)) max=1;
  else if (skillnum==6014) max=3;
  else if (skillnum==6026) max=10;
  else if (skillnum==6901) max=0;
  else max=16;
 }
 casts=min(casts,max);
 //Adjust casts to be within limits
 if (((userdata[sender].flags&noLimit)!=noLimit)&&(userdata[ding].buffs contains skillnum)){
  if ((casts+userdata[ding].buffs[skillnum])>max) casts=max-userdata[ding].buffs[skillnum];
 }

 if (casts==0){
  errorMessage(ding,"I'm sorry, but you've reached your daily limit for that buff.");
  return;
 }

 //Quick check to see if limited buffs still available
 int maxnum = 999999;
 if ((skillnum>6019)&&(skillnum<6025)) maxnum=10;
 else if (skillnum==6026) maxnum=50;
 else if (skillnum==6028) maxnum=5;
 if ((skillnum>6019)&&(skillnum<6029)){
  if (maxnum-userdata["*"].buffs[skillnum]<1){
   errorMessage(ding,"I'm sorry, but I'm all out of "+messageNew+" for today.");
   return;
  }//balance if not enough to meet request
  if (maxnum-userdata["*"].buffs[skillnum]<casts) casts=maxnum-userdata["*"].buffs[skillnum];
 }
 //This is the actual casting function.
 claimResource("adventuring");
 if (skillnum==6901){
  if (item_amount($item[time's arrow])<1) cli_execute("stash take time's arrow");  
  if (item_amount($item[time's arrow])<1){
   chat_private(ding,"Currently out of Time's Arrows. Looks like you're out of luck.");
   print("Out of Time's Arrows.");
   freeResource("adventuring");
   return;
  }
  string t=visit_url("curse.php?action=use&pwd="+my_hash()+"&whichitem=4939&targetplayer="+sender);
  print("Throwing Time's Arrow at "+sender);
  freeResource("adventuring");
  userdata[ding].buffs[skillnum]+=1;
  map_to_file(userdata,"userdata.txt");
  return;
 }
 if (have_skill(to_skill(skillnum))){
  if (use_skill(casts,to_skill(skillnum),sender)){
   int totCastsE=get_property('totalCastsEver').to_int()+casts;
   set_property('totalCastsEver',totCastsE.to_string());
   userdata[ding].buffs[skillnum]+=casts;
   userdata["*"].buffs[skillnum]+=casts;
   map_to_file(userdata,"userdata.txt");
   if (((skillnum>6019)&&(skillnum<6029)) || (skillnum==62)){
    updateDC("useCurrent");
    updateLimits();
   }
  }else switch (last_skill_message()){
   case "Selected target is too low level.":
    errorMessage(sender,"You have to be level 15 to receive that buff.");
    break;
   case "Selected target cannot receive buffs.":
    errorMessage(sender,"I can't buff you if you're under Ronin restrictions.");
    break;
   case "Selected target is busy fighting.":
    errorMessage(sender,"I can't buff you while you're adventuring.");
    break;
   default:
    errorMessage(sender,"You have too many songs in your head.");
  }
 }else{
  errorMessage(sender,"The cake is a lie. So is "+msg+", since I don't have that buff.");
 }
 if (((my_maxmp()-my_mp())>=300)&&(!to_boolean(get_property("oscusSodaUsed")))) use(1,$item[oscus's neverending soda]);
 if (((my_maxmp()-my_mp())>=1000)&&(get_property("nunsVisits")!=3)) cli_execute("nuns");
 if ((my_mp()<900)&&(my_fullness()<15)){
  retrieve_item(1,$item[Jumbo Dr. Lucifer]);
  eatsilent(1,$item[Jumbo Dr. Lucifer]);
  retrieve_item(1,$item[scroll of drastic healing]);
  use(1,$item[scroll of drastic healing]);
 }
 while(my_mp()<952){
  if (item_amount($item[magical mystery juice])<1) retrieve_item(1,$item[magical mystery juice]);
  use(1,$item[magical mystery juice]);
 }
 map_to_file(userdata,"userdata.txt");
 freeResource("adventuring");
}

string roll(string sender, string msg, string method){
 string[int] rolling;
 int running;
 rolling=split_string(msg,"d|D");
 if ((to_int(rolling[0])<1) || (to_int(rolling[0])>1000000) || (to_int(rolling[1])<2) || (to_int(rolling[1])>1000000)){
  errorMessage(sender,"That's an invalid range.");
  return "";
 }
 for die from 1 to to_int(rolling[0])
  running+=(1+random(to_int(rolling[1])));
 //The following is to try to avoid the repetition filter, in case that becomes an issue.
 string endsentence=".";
 boolean good=false;
 while (!good){
  good=(checkRep("roll"+endsentence)==-1);
  if (!good) switch (endsentence){
   case ".":
    endsentence="!";
    break;
   case "!":
    endsentence="...";
    break;
   case "...":
    endsentence="";
    break;
   case "":
    endsentence="..";
    break;
   case "..":
    endsentence="!!";
    break;
   default:
    endsentence="!!!";
    break;   
  }
 }
 switch (method) {
  case "public":
   chat_clan("Rolling "+rolling[0]+"d"+rolling[1]+" for "+sender+" gives "+running+endsentence);
   addRep("roll"+endsentence);
   break;
  case "pm":
   chat_private(sender,"Rolling "+rolling[0]+"d"+rolling[1]+" gives "+running+".");
   break;
 }
 return running.to_string();
}

void russianRoulette(string sender, string msg){
print("RR");
 matcher m;
 int now=now_to_string("HH").to_int()*60+now_to_string("mm").to_int();
 gameData game=loadGame();
 int v=-1;
 if (!game.gameStarted&&(sender!=":SYSTEM")){//Get contestants, until time is up.
  m=create_matcher("(?i)(i am|\\Win\\W|i'll play)",msg);
  if((!find(m))||(game.roundOver<now))return;
  game.players[sender]=0;
  saveGame(game);
 }else if(sender!=":SYSTEM"){
  m=create_matcher("(\\d+)",msg);
  if(find(m)) v=group(m,1).to_int();
  foreach p,val in game.players if(val==v){
   chat_clan(p+" has "+val+".");
   return;
  }
 }
print("Players: "+count(game.players).to_string());
 if(!(game.players contains sender))return;
 if((sender!=":SYSTEM")&&(v>0)&&(v<=(count(game.players)-1))&&(game.players[sender]==0)) game.players[sender]=v;
 if(sender!=":SYSTEM"){
  saveGame(game);
  return;
 }
 v=count(game.players)-1;
 switch(msg){
  case "START":
   chat_clan("Okay, looks like we are starting with "+v.to_string()+" players.");
   wait(5);
   chat_clan("Everybody: 1-"+v.to_string()+"!");
   game.gameStarted=true;
   game.roundOver=now+game.intervals+1;
   foreach p in game.players game.players[p]=0;
   saveGame(game);
   break;
  case "MORE":
   if (game.gameStarted) chat_clan("1 more minute guys. Make your choices.");
   else chat_clan("Anybody else?");
   game.roundOver=now+2;
   saveGame(game);
   break;
  case "MOVE":
   chat_clan("Okay, times up.");
   string t;
   int nextn=1;
   boolean f;
   foreach pn,num in game.players if (num==0) {
    f=false;
    while (!f){
     f=true;
     foreach pn2,num2 in game.players if (num2==nextn) f=false;
     if (!f) nextn+=1;
    }
    game.players[pn]=nextn;
    chat_clan(pn+" is "+nextn.to_int()+".");
   } //fall through
  case "NEXT":
   chat_clan("Let's roll...");
   wait(3);
   int l=random(v)+1;
   string loser;
   foreach pn,num in game.players if (num==v) loser=pn;
   chat_clan("Rolling 1d"+v.to_string()+" for myself gives "+l.to_string()+". "+loser+" is out!");
   remove game.players[loser];
   foreach pn in game.players game.players[pn]=0;
   saveGame(game);
   break;
  default:
   
   break;
 }
 saveGame(game);
}

string wordshot(string sender, string guess){
 gameData game=loadGame();
 if(game.intervals==-1)return guess;
 string word;
 foreach k,v in game.players if (v==1) word=k;
 if(guess.contains_text(" ")||(guess.length()!=word.length())){
  return guess;
 }
 string wordList=visit_url("http://clubefl.gr/games/wordox/"+word.length().to_string()+".html");
 if (!wordList.contains_text(guess.to_lower_case())) {
  chat_private(sender,guess+" isn't a valid word.");
  return "x";
 }
 if (guess==word){
  game.players[sender]=2;
  game.intervals=-1;
  saveGame(game);
  return "x";
 }
 int[string] breakW;
 int[string] breakG;
 for x from 1 to length(word) breakW[char_at(word,x-1)]+=1;
 for x from 1 to length(word) breakG[char_at(guess,x-1)]+=1;
 int m=0;
 foreach k,v in breakW if (breakG contains k) m+=min(breakG[k],v);
 chat_private(sender,m.to_string());
 if (m>game.intervals) {
  game.intervals=m;
  chat_clan("We have a"+(m==8?"n ":" ")+m.to_string()+"!");
 }
 if (m==0){
  if(game.roundOver==0) chat_clan("First 0!");
  game.roundOver+=1;
 }
 saveGame(game);
 return "x";
}

void startGame(string sender, string msg){
 gameData game;
 if (gameType()!=gameNone){
  game=loadGame();
  if((msg=="cancel")||(msg=="stop")){
   if((sender==game.host)||getUF(sender,isAdmin)){
    closeGame();
    chat_private(sender,"Game canceled");
    chat_clan("You must all be orphans, not even the host of the game loved you long enough to finish. Game canceled.");
   }else chat_private(sender,"You don't have permission to do that.");
  }else chat_private(sender,"A game is already in session by "+game.host+".");
  return;
 }
 matcher m=create_matcher("(?i)(wordshot|RR|russian roulette|russianroulette)\\s?(\\d+|\\w+)?",msg);
 if (!m.find()) return;
 string t=m.group(1);
 string l="-";
 if(m.group_count()>1) l=m.group(2);
 switch(t){
  case "wordshot":
   startWordshot(l.to_int(),sender);
   game=loadGame();
   string w;
   foreach k,v in game.players if(v==1) w=k;
   if((l.to_int()==0)&&(l!="-")&&(l.length()>2)&&(l.length()<14)){
    string list=visit_url("http://clubefl.gr/games/wordox/"+l.length().to_string()+".html");
    if (list.contains_text(l.to_lower_case())){
     remove game.players[w];
     game.players[l]=1;
     print("Actually: "+l);
     w=l;
    }else{
     closeGame();
     chat_private(sender,"Word not found");
     return;
    }
   }
   chat_private(sender,"Game started.");
   chat_clan(w.length().to_string()+"-letter Wordshot! Send guesses to me!");
   break;
  case "rr":case "russianroulette":
  case "russian roulette":
   //startRussianRoulette;
   break;
 }
}

void pick(string options){
 string[int] list=split_string(options,"(\\s?,\\s?or\\s|,\\s?|\\sor\\s)");
 if (count(list)<2) return;
 int d=random(count(list));
 chat_clan("/em picks "+list[d]+".");
}

void reviselist(string sender, string msg, string command){
 if(!getUF(sender,isAdmin)){
  errorMessage(sender,"You do not have permission to use "+command+".");
  return;
 }
 int newuserid=updateId(msg,true);
 switch (command){
  case "whitelist":
   setUF(msg,whitelist);
   chat_private(sender,msg+" has been whitelisted.");
   break;
  case "blacklist":
   if (getUF(msg,isAdmin)) return;
   setUF(msg,blacklist);
   chat_private(sender,msg+" has been blacklisted.");
   break;
  case "reset":
   unSetUF(msg,whitelist+blacklist+inClan);
   userdata[msg].userid=0;
   chat_private(sender,msg+" has been reset.");
   break;
 }
 map_to_file(userdata,"userdata.txt");
}

void mod(string sender,string msg){
 boolean adminonly=getUF(sender,isAdmin);
 matcher m=create_matcher("(.*)[., ;]*\\|\\|\\s*(.*)",msg);
 string cmdlist=msg;
 string user=sender;
 if (find(m)){
  cmdlist=group(m,1);
  user=group(m,2);
 }
 if (!adminonly) user=sender;
 m=create_matcher("[., ;]+",cmdlist);
 cmdlist=replace_all(m," ");
 string[int]cmds=split_string(cmdlist," ");
 foreach i,cmd in cmds
  switch (cmd){
   case "noLimit":
    if(adminonly){
     setUF(user,noLimit);
     chat_private(sender,user+" has had "+genders[userdata[user].gender,gPosDet]+" limit lifted.");
    }else errorMessage(sender,"You do not have permissions to use "+cmd+".");
    break;
   case "limit":
    if(adminonly){
     unSetUF(user,noLimit);
     chat_private(sender,user+" has had "+genders[userdata[user].gender,gPosDet]+" limit re-imposed.");
    }else errorMessage(sender,"You do not have permissions to use "+cmd+".");
    break;
   case "nowarning":
    setUF(user,noFlag);
    chat_private(sender,user+"\'s warnings disabled.");
    break;
   case "warning":
    unSetUF(user,noFlag);
    chat_private(sender,user+",s warnings enabled.");
    break;
   case "clear":
    userdata[user].userId=0;
    chat_private(sender,"Clan Status cleared for "+user+".");
    break;
   case "add":
    if(adminonly){
     setUF(user,isAdmin);
     chat_private(sender,user+" has been given administrative permissions.");
    }else errorMessage(sender,"You do not have permission to use "+cmd+".");
    break;
   case "remove":
    if(adminonly){
     unSetUF(user,isAdmin);
     chat_private(sender,user+" has been removed as an administrator.");
    }else errorMessage(sender,"You do not have permission to use "+cmd+".");
    break;
   case "whitelist":
   case "blacklist":
   case "reset":
    reviselist(sender,user,cmd);
   default:
    errorMessage(sender,cmd+" seems to be an invalid command.");
    break;
  }
 map_to_file(userdata,"userdata.txt");
}

void fax(string sender, string msg){
 string[monster]m;
 file_to_map("faxnames.txt",m);
 switch (msg){
  case "hipster":
   msg="peeved roomate";
   break;
  case "wine":
   msg="skeletal sommelier";
   break;
  case "beer lens":
   msg="unemployed knob goblin";
   break;
  case "firecracker":
   msg="sub-assistant knob mad scientist";
   break;
  case "pron":
   msg="pr0n";
   break;
  case "chum":
   msg="chieftain";
   break;
  case "bronzed locust":
   msg="locust";
   break;
  case "cursed pirate":
   msg="scary pirate";
   break;
  case "slime":
   msg="slime1";
 }
 string nm=m[to_monster(msg)];
 if (nm==""){
  chat_private(sender,"My database couldn't make a direct match for that, so I'll send it straight to faxbot as is.");
  nm=msg;
 }
 print("Requesting "+msg+" ("+nm+") from FaxBot.");
 chat_private("FaxBot",nm);
}

string replyParser(string sender,string msg){
 string temp;
 string someone=sender;
 matcher variable=create_matcher("(?i)\\$s",msg);
 if(find(variable)&&(someoneDefined=="")){
  boolean[string] inClan=who_clan();
  int rng=0;
  if(count(inClan)>2) rng=random(count(inClan)-1);
  int c=0;
  foreach clannie in inClan{
   if (clannie==sender) continue;
   someoneDefined=clannie;
   c+=1;
   if (c>rng) break;
  }
 }
 if(someoneDefined!="")someone=someoneDefined;
 if (userdata[someone].userid==0) updateId(someone,true);
 if (userdata[sender].userid==0) updateId(sender,true);
 if (userdata[someone].gender==0) userdata[someone].gender=2;
 if (userdata[sender].gender==0) userdata[sender].gender=2;
 map_to_file(userdata,"userdata.txt");
 userinfo randplayer=userdata[someone];
 userinfo thesender=userdata[sender];
 string pclass;
 string sclass;
 variable=create_matcher("(?i)class",msg);
 if(find(variable)){
  temp=visit_url("showplayer.php?who="+randplayer.userid.to_string());
  variable=create_matcher("Class:</b></td><td>(.+?)<",temp);
  if(find(variable))sclass=group(variable,1);
  temp=visit_url("showplayer.php?who="+thesender.userid.to_string());
  variable=create_matcher("Class:</b></td><td>(.+?)<",temp);
  if(find(variable))pclass=group(variable,1);
 }
 if (thesender.nick=="") thesender.nick=sender;
 if (randplayer.nick=="") randplayer.nick=someone;
 variable=create_matcher("(?<!\\\\)\\$(\\w*)",msg);
 while (find(variable)){
  switch (group(variable,1)) {
   case "someone":
   case "sname":
    msg=replace_first(variable,someone);
    break;
   case "snick":
   case "sshort":
    msg=replace_first(variable,randplayer.nick);
    break;
   case "ssub":
   case "sobj":
   case "sref":
   case "spos":
   case "sdet":
    msg=replace_first(variable,genderPronoun(randplayer.nick,randplayer.gender,group(variable,1)));
    break;
   case "sgender":
    msg=replace_first(variable,genderString(randplayer));
    break;
   case "strigger":
    msg=replace_first(variable,randplayer.lastTrigger);
    break;
   case "sresult":
   case "smath":
    temp=randplayer.lastMath.to_string();
    if(randplayer.lastMath.to_int()==randplayer.lastMath) temp=randplayer.lastMath.to_int().to_string();
    msg=replace_first(variable,temp);
    break;
   case "sclass":
    msg=replace_first(variable,sclass);
    break;
   case "sstat":
    switch (sclass){
     case "Seal Clubber":
     case "Turtle Tamer":
      temp="Muscle";
      break;
     case "Pastamancer":
     case "Sauceror":
      temp="Mysticality";
      break;
     case "Disco Bandit":
     case "Accordion Thief":
      temp="Moxie";
      break;
    }
    msg=replace_first(variable,temp);
    break;
   case "player":
   case "pname":
    msg=replace_first(variable,sender);
    break;
   case "pnick":
   case "pshort":
    msg=replace_first(variable,thesender.nick);
    break;
   case "psub":
   case "pobj":
   case "pref":
   case "ppos":
   case "pdet":
    msg=replace_first(variable,genderPronoun(thesender.nick,thesender.gender,group(variable,1)));
    break;
   case "pgender":
    msg=replace_first(variable,genderString(thesender));
    break;
   case "ptrigger":
    msg=replace_first(variable,thesender.lastTrigger);
    break;
   case "presult":
   case "pmath":
    temp=thesender.lastMath.to_string();
    if(thesender.lastMath.to_int()==thesender.lastMath) temp=thesender.lastMath.to_int().to_string();
    msg=replace_first(variable,temp);
    break;
   case "pclass":
    msg=replace_first(variable,pclass);
    break;
   case "pstat":
    switch (pclass){
     case "Seal Clubber":
     case "Turtle Tamer":
      temp="Muscle";
      break;
     case "Pastamancer":
     case "Sauceror":
      temp="Mysticality";
      break;
     case "Disco Bandit":
     case "Accordion Thief":
      temp="Moxie";
      break;
    }
    msg=replace_first(variable,temp);
    break;
   case "statday":
    temp=stat_bonus_today().to_string();
    if (temp=="none")temp="nothing";
    msg=replace_first(variable,temp);
    break;
   case "statdaytomorrow":
    temp=stat_bonus_tomorrow().to_string();
    if (temp=="none")temp="nothing";
    msg=replace_first(variable,temp);
    break;
   case "math":
   case "result":
    temp=userdata["*"].lastMath.to_string();
    if(userdata["*"].lastMath.to_int()==userdata["*"].lastMath) temp=userdata["*"].lastMath.to_int().to_string();
    msg=replace_first(variable,temp);
    break;
   case "trigger":
    msg=replace_first(variable,userdata["*"].lastTrigger);
    break;
   case "lotto":
    int[string] books;
    file_to_map("books.txt",books);
    temp=books["thisLotto"].to_string()+"k";
    msg=replace_first(variable,temp);
    break;
   case "item":
    temp="none";
    item[int] allItems;
    foreach it in $items[] allItems[count(allItems)]=it;
    temp=allItems[random(count(allItems))].to_string();
    msg=replace_first(variable,temp);
    break;
   default:
    if(chatVars contains group(variable,1)) msg=replace_first(variable,chatVars[group(variable,1)]);
    else msg=replace_first(variable,group(variable,1));
    break;
  }
  variable=create_matcher("(?<!\\\\)\\$(\\w*)",msg);
 }
 variable=create_matcher("\\\\\\$",msg);
 msg=replace_all(variable,"$");
 return msg;
}

string chatFilter(string sender, string msg){
 if (msg.contains_text("fuck")){
  chat_private(sender,"Try again, fuckwad.");
  return "x";
 }
 return msg;
}

void train(string trainer,string msg){
 string[int,string] changes;
 file_to_map("changes.txt",changes);
 changes[count(changes),trainer]=msg;
 responses[string] botdata;
 file_to_map("replies.txt",botdata);
 responses newr;
 newr.flags=mustAddress;
 string trig;
 matcher ff=create_matcher("(?<!\\\\)\\[(\\w*)(?<!\\\\)]\\s?",msg);
 if (find(ff)){
  if (group(ff,1).contains_text("r")) newr.flags=mustRefer;
  if (group(ff,1).contains_text("c")) newr.flags|=caseSensitive;
  if (group(ff,1).contains_text("n")) newr.flags&=~mustAddress;
  if (group(ff,1).contains_text("o")) newr.flags|=fullText;
  if (group(ff,1).contains_text("a")) newr.flags=(fullText|caseSensitive)&(~mustAddress);
  if ((group(ff,1).contains_text("f"))&&((userdata[trainer].flags&isAdmin)==isAdmin)) newr.flags|=repFree;
  msg=replace_first(ff,"");
 }
 ff=create_matcher("(?<!\\\\)::(.+?)=(.+?)::",msg);
 if (find(ff)){
  newr.cond1=group(ff,1);
  newr.cond2=group(ff,2);
  msg=replace_first(ff,"");
 }
 ff=create_matcher("(.*)\\s?(?<!\\\\)<(\\w*?)(?<!\\\\)>\\s?(.*)",msg);
 if (find(ff)){
  newr.reply=group(ff,3);
  newr.method=group(ff,2).to_lower_case();
  trig=group(ff,1);
  boolean knownmethod=false;
  switch (newr.method){
   case "say":
   case "do":
    knownmethod=true;
  }
  if (!knownmethod){
   errorMessage(trainer,"Training failed: Unknown method: "+newr.method);
   return;
  }
  string t=newr.reply;
  ff=create_matcher("\\\\\\[",t);
  t=replace_all(ff,"[");
  ff=create_matcher("\\\\\\]",t);
  t=replace_all(ff,"]");
  ff=create_matcher("\\\\<",t);
  t=replace_all(ff,"<");
  ff=create_matcher("\\\\>",t);
  t=replace_all(ff,">");
  ff=create_matcher("\\\\::",t);
  t=replace_all(ff,"::");
  ff=create_matcher(" $",t);
  t=replace_all(ff,"");
  newr.reply=t;
  t=trig;
  ff=create_matcher("\\\\\\[",t);
  t=replace_all(ff,"[");
  ff=create_matcher("\\\\\\]",t);
  t=replace_all(ff,"]");
  ff=create_matcher("\\\\<",t);
  t=replace_all(ff,"<");
  ff=create_matcher("\\\\>",t);
  t=replace_all(ff,">");
  ff=create_matcher("\\\\::",t);
  t=replace_all(ff,"::");
  ff=create_matcher(" $",t);
  t=replace_all(ff,"");
  if ((newr.flags&caseSensitive)==0)botdata[t.to_lower_case()]=newr;
  else botdata[t]=newr;
 }
 chat_private(trainer,"Training complete: "+newr.reply);
 map_to_file(botdata,"replies.txt");
 map_to_file(changes,"changes.txt");
}

void untrain(string trainer, string msg){
 string[int,string] changes;
 file_to_map("changes.txt",changes);
 changes[count(changes),trainer]="drop "+msg;
 responses[string] botdata;
 file_to_map("replies.txt",botdata);
 responses fix=remove botdata[msg];
 chat_private(trainer,"Training removed: "+fix.reply);
 map_to_file(botdata,"replies.txt");
 map_to_file(changes,"changes.txt");
}

void search(string sender, string msg){
 msg=msg.to_lower_case();
 string trigm,replm;
 responses[string] botdata;
 file_to_map("replies.txt",botdata);
 foreach trig,re in botdata{
  if(re.reply.to_lower_case().contains_text(msg)){
   replm+="Trigger: "+trig+"\n";
   if(re.cond1!=re.cond2)replm+="If: \""+re.cond1+"\" = \""+re.cond2+"\"\n";
   replm+="Method: "+re.method+"\n";
   replm+="Response: "+re.reply+"\n\n";
   continue;
  }
  if(trig.to_lower_case().contains_text(msg)){
   replm+="Trigger: "+trig+"\n";
   if(re.cond1!=re.cond2)replm+="If: \""+re.cond1+"\" = \""+re.cond2+"\"\n";
   replm+="Method: "+re.method+"\n";
   replm+="Response: "+re.reply+"\n\n";
   continue;
  }
  if(msg=="*"){
   replm+="Trigger: "+trig+"\n";
   if(re.cond1!=re.cond2)replm+="If: \""+re.cond1+"\" = \""+re.cond2+"\"\n";
   replm+="Method: "+re.method+"\n";
   replm+="Response: "+re.reply+"\n\n";
  }
 }
 string send=trigm+"\n"+replm;
 if (send=="\n")send="No matches found for "+msg;
 cli_execute("csend to "+sender+"||"+send);
}

void clearData(string what){
 print("ClearRQ:"+what);
 switch (what){
  case "changelog":
   string[int,string] changes;
   map_to_file(changes,"changes.txt");
   break;
  case "filter":
   for i from 0 to 6 userdata["*"].buffpacks[i.to_string()]="";
   map_to_file(userdata,"userdata.txt");
   break;
 }
}

void lookup(string sender, string who){
 who=who.to_lower_case();
 string reply="";
 boolean[string] covered;
 int yetfound=0;
 foreach user in userdata{
  yetfound=0;
  if (userdata[user].nick.to_lower_case().contains_text(who)){
   yetfound=2;
   reply+=user+"goes by "+userdata[user].nick;
  }
  if(user.to_lower_case().contains_text(who)&&(yetfound==0)){
   yetfound=1;
   reply+=user;
  }
  foreach name in userdata[user].multis if(name.to_lower_case().contains_text(who)){
   switch(yetfound){
    case 0: reply+=user+" goes by ";break;
    case 1: reply+=" goes by ";break;
    case 2: reply+=", ";break;
   }
   yetfound=2;
   reply+=name;
  }
  if(yetfound>0)reply+=". ";
 }
 if (reply=="") reply="No matches found for "+who;
 if (length(reply)<151) chat_private(sender,reply);
 else{
  matcher m=create_matcher("\\. ",reply);
  reply=replace_all(m,".\n");
  cli_execute("csend to "+sender+"||"+reply);
 }
}

void multilookup(string sender, string who){
 string reply="";
 if (userdata contains who) {
  reply=who+" is a known multi of the following users: ";
  foreach name in userdata[who].multis
   reply+=name+", ";
  if (count(userdata[who].multis)<1) reply="No known multis for "+who+"...";
 }else reply="No matches found for "+who+"...";
 reply=substring(reply,0,length(reply)-2);
 if (length(reply)<151) chat_private(sender,reply);
 else cli_execute("csend to "+sender+"||"+reply);
}

void userDetails(string sender, string who){
 if (who=="")who=sender;
 string reply;
 if ((who=="ob")||(who=="ominous buffer")){
  reply="User: Ominous Buffer\n";
  reply+="Known Multis: Ominous Tamer, Ominous Sauceror\nGoes by: OB\n";
  reply+="Gender neutral.\n\n";
  reply+="Currently casting for the following clans: ";
  reply+="Black Mesa, Not Dead Yet, This One Time, Imitation Plastic Death Star, and Clan of 14 Days.";
  cli_execute("csend to "+sender+"||"+reply);
  return;
 }
 if (userdata contains who){
  reply="User "+who+":\n";
  if (count(userdata[who].multis)>0){
   reply+="Known Multis: ";
   foreach name in userdata[who].multis reply+=name+", ";
   reply=substring(reply,0,length(reply)-2)+".\n";
  }
  if ((userdata[who].nick!=who)&&(userdata[who].nick!="")) reply+="Goes by: "+userdata[who].nick+"\n";
  reply+="Gender: "+genderString(userdata[who])+"\n";
  if(userdata[who].lastTime!="") reply+="Last Time Spoken: "+userdata[who].lastTime+"\n";
  if((who==sender)&&(count(userdata[who].buffpacks)>0)){
   reply+="Buffpacks Defined:\n";
   foreach pack, innards in userdata[who].buffpacks reply+="-"+pack+": "+innards+".\n";
  }
  if(userdata[who].donated>0) reply+="Donated: "+userdata[who].donated.to_string()+" meat.\n";
  if(who==sender) reply+="Bank: "+userdata[who].wallet.to_string()+" meat.\n";
  cli_execute("csend to "+sender+"||"+reply);
 }else chat_private(sender,"No match found for "+who+".");
}

void userAccountEmpty(string w){
 if (userdata[w].wallet<1){
  errorMessage(w,"You don't have sufficient funds to withdraw.");
  return;
 }
 if (!kmail(w,"Your balance in full.",userdata[w].wallet)){
  errorMessage(w,"Error sending meat, try again later, preferably out of ronin/HC.");
  return;
 }
 userdata[w].wallet=0;
 map_to_file(userdata,"userdata.txt");
}

string addMulti(string n1,string n2){
 string ncarry="";
 int gencarry=0;
 print("Multi added for "+n1,"blue");
 boolean[string] ml=userdata[n1].multis;
 boolean[string] biglist;
 foreach mult in userdata[n1].multis biglist[mult]=true;
 foreach mult in userdata[n2].multis biglist[mult]=true;
 biglist[n1]=true;
 biglist[n2]=true;
 foreach name in biglist{
  if (userdata[name].gender!=0) gencarry=userdata[name].gender;
  if (userdata[name].nick!="") ncarry=userdata[name].nick;
 }
 boolean[string] cpy=biglist;
 foreach mult in biglist{
  if (userdata[mult].nick=="") userdata[mult].nick=ncarry;
  if (userdata[mult].gender==0) userdata[mult].gender=gencarry;
  foreach mult2 in cpy if (mult2!=mult) userdata[mult].multis[mult2]=true;
 }
 string s=n1;
 foreach name in biglist if(name!=n1) s+=", "+name;
 return s;
}

void setMulti(string sender, string newaltlist){
 int[string,string] mlist;
 file_to_map("tempMultis.txt",mlist);
 boolean match=false;
 string[int]alts=split_string(newaltlist,",\\s?");
 int now=now_to_string("yDDDHH").to_int();
 string matchtxt="";
 string tmatch="";
 foreach i, alt in alts{
  foreach name1,name2 in mlist{
   if (now_to_string("yDDDHH").to_int()<now) remove mlist[name1,name2];
   if ((name1==alt)&&(name2==sender)){
    tmatch=addMulti(sender,alt);
    remove mlist[name1,name2];
   }
  }
  if(tmatch==""){
   chat_private(alt,sender+" is attempting to register you as "+genders[userdata[sender].gender,gPosDet]+" multi.");
   mlist[sender,alt]=now+100;
  }else if(length(matchtxt)<length(tmatch)) matchtxt=tmatch;
 }
 if (matchtxt=="") chat_private(sender,"Reminder sent to other accounts, you have 24 hours to register them.");
 else if(length(matchtxt)<111) chat_private(sender,"Multi properly registered for accounts:"+matchtxt);
 else cli_execute("csend to "+sender+"||Multi properly registered for accounts:"+matchtxt);
 map_to_file(mlist,"tempMultis.txt");
 map_to_file(userdata,"userdata.txt");
}

string predicateFilter(string sender, string msg){
 matcher first=create_matcher("(\\S*)\\s?(.*)",msg);
 string pred;
 string oper;
 if (find(first)){
  pred=group(first,1);
  oper=group(first,2);
 }else return msg;
 switch (pred){
  case "set":
  case "pack":
   string r=userdata[sender].buffpacks[oper];
   if((r=="")&&(!contains_text("0123456",oper))) r=userdata["*"].buffpacks[oper];
   if(r==""){
    errorMessage(sender,"That buffpack does not exist.");
    return "x";
   }
   return r;
  case "mod":
  case "settings":
   mod(sender,oper);
   return "x";
  case "market":
   if (!analyze_md(sender,oper)) errorMessage(sender,"Analysis failed. Recheck item name and parameters.");
   return "x";
  case "logout":
   logout(sender,msg);
   return "x";
  case "wang":
   if (oper=="")oper=sender;
   if (is_online("wangbot")){
    chat_private("wangbot","target "+oper);
   }else{
    if (item_amount($item["WANG"])<1) cli_execute("stash take wang");
    string t=visit_url("curse.php?action=use&pwd&whichitem=625&targetplayer="+oper);
   }
   return "x";
  case "clear":
   if (oper=="")return "x";
   if((userdata[sender].flags&isAdmin)!=isAdmin){
    errorMessage(sender,"No, don't do that!");
    return "x";
   }
   clearData(oper);
   return "x";
  case "count":
   if (oper=="")return "x";
   if((userdata[sender].flags&isAdmin)!=isAdmin){
    errorMessage(sender,"No, don't do that!");
    return "x";
   }
   item whitem=to_item(oper);
   if (oper=="meat"){
    string r="Meat: "+to_string(my_meat()+my_closet_meat())+". DMS:";
    r+=to_string(item_amount($item[dense meat stack])+closet_amount($item[dense meat stack]));
    chat_private(sender,r);
   }else if(whitem!=$item[none]){
    string r=whitem.to_string()+": "+item_amount(whitem).to_string();
    chat_private(sender,r);
   }
   return "x";
  case "deals":
   if ((userdata[sender].flags&isAdmin)==isAdmin) updateDC(oper);
   return "x";
  case "ping":
   chat_private(turt_name,"PING "+sender);
   chat_private(sauc_name,"PING "+sender);
   chat_private(sender,"Reply from Ominous Buffer.");
   return "x";
  case "math":
   matcher spaces=create_matcher("\\s*",oper);
   oper=replace_all(spaces,"");
   float ans=modifier_eval(oper);
   userdata[sender].lastmath=ans;
   map_to_file(userdata,"userdata.txt");
   chat_private(sender,modifier_eval(oper).to_string());
   return "x";
  case "help":
  case "?":
   cli_execute("kmail to "+sender+" || Thank you for your interest in my functions. I currently only buff members of Black Mesa and players on its whitelist. If you have recently joined, and are unable to receive a buff, please pm me with the phrase \"settings clear\". Please visit http://z15.invisionfree.com/Black_Mesa_Forums/index.php?showforum=14 for more information.");
   return "x";
  case "blacklist":
  case "whitelist":
  case "reset":
   reviselist(sender,oper,pred);
   return "x";
  case "roll":
   roll(sender, oper, "pm");
   return "x";
  case "get":
  case "fax":
   if (!getUF(sender,inClan)){
    chat_private(sender,"You must be in Black Mesa to utilize its faxing rights.");
    return "x";
   }
   set_property("_lastFax",sender);
   fax(sender,oper);
   return "x";
  case "alias":
  case "createpack":
   createpack(sender,oper);
   return "x";
  case "delpack":
   delpack(sender,oper);
   return "x";
  case "teach":
  case "learn":
  case "train":
   train(sender,oper);
   return "x";
  case "untrain":
  case "drop":
   untrain(sender,oper);
   return "x";
  case "search":
   search(sender,oper);
   return "x";
  case "whois":
   lookup(sender,oper);
   return "x";
  case "alts":
  case "multis":
   multilookup(sender,oper);
   return "x";
  case "alt":
  case "multi":
   setMulti(sender,oper);
   return "x";
  case "details":
   userDetails(sender,oper);
   return "x";
  case "withdraw":
   userAccountEmpty(sender);
   return "x";
  case "host":
   startGame(sender,oper);
   return "x";
 }
 return msg;
}

void nopredpass(string sender, string msg, boolean addressed){
 //print("yo");
 responses[string] botdata;
 file_to_map("replies.txt",botdata);
 boolean foundmatch=false;
 boolean referred=addressed;
 matcher ref=create_matcher("(?i)(\\WOB\\W|\\WOminous Buffer\\W)",msg);
 if (find(ref)) referred=true;
 ref=create_matcher(" $",msg);
 msg=replace_all(ref,"");
 responses the_one;
 string th="";
 foreach testcase,reply in botdata{
  th=testcase;
  /*print("");
  print(":"+msg+":");
  print(":"+testcase+":");
  */
  //if(((reply.flags&repFree)==0)&&(checkRep(testcase)>3))continue;
  if(((reply.flags&mustRefer)==mustRefer)&&(!referred))continue;
  if(((reply.flags&mustAddress)==mustAddress)&&(!addressed))continue;
  if(((reply.flags&fullText)==fullText)&&(msg!=testcase))continue;
  if(((reply.flags&caseSensitive)==caseSensitive)&&(!msg.contains_text(testcase)))continue;
  if(!msg.to_lower_case().contains_text(testcase.to_lower_case()))continue;
  foundmatch=true;
  if (replyParser(sender,reply.cond1)!=replyParser(sender,reply.cond2)){
   foundmatch=false;
   continue;
  }
  the_one=reply;
  break;
 }
 if(foundmatch){
  userdata[sender].lastTrigger=th;
  userdata["*"].lastTrigger=th;
  addRep(th);
  map_to_file(userdata,"userdata.txt");
  switch (the_one.method){
   case "say":chat_clan(replyParser(sender,the_one.reply));
    break;
   case "do":chat_clan("/em "+replyParser(sender,the_one.reply));
    break;
  }
 }
}

void setGender(string sender,string gender){
 int gval=2;
 matcher g=create_matcher("(?i)(WHO I AM|ME)",gender);
 if (g.find()) gval=1;
 int tc=2;
 while(gval==2){
  tc+=1;
  if (tc>=count(genders)) break;
  if (!(genders[tc] contains 5)) continue;
  g=create_matcher("(?i)("+genders[tc,5]+")",gender);
  if(g.find()) gval=tc;
 }
 userdata[sender].gender=gval;
 foreach m in userdata[sender].multis userdata[m].gender=gval;
 map_to_file(userdata,"userdata.txt");
}

int timeSinceLastChat(string who){
 boolean useA=true;
 string lastSpeaker;
 if ((ctimes.lastCA==who)||(ctimes.lastCB==who)){
  if(ctimes.lastCB==who) useA=false;
  ctimes.lastChatterA=~useA;
 }else{
  useA=~ctimes.lastChatterA;
 }
 int lastH;
 int lastM;
 if(ctimes.lastChatterA){
  lastH=ctimes.lastAh;
  lastM=ctimes.lastAm;
  lastSpeaker=ctimes.lastCA;
 }else{
  lastH=ctimes.lastBh;
  lastM=ctimes.lastBm;
  lastSpeaker=ctimes.lastCB;
 }
 chatVars["lastchatter"]=lastSpeaker;
 int nowH=now_to_string("HH").to_int();
 int nowM=now_to_string("mm").to_int();
 ctimes.lastChatterA=useA;
 if (ctimes.lastChatterA){
  ctimes.lastAh=nowH;
  ctimes.lastAm=nowM;
  ctimes.lastCA=who;
 }else{
  ctimes.lastBh=nowH;
  ctimes.lastBm=nowM;
  ctimes.lastCB=who;
 }
 ctimestemp[0]=ctimes;
 map_to_file(ctimestemp,"timefile.txt");
 userdata[who].lastTime=now_to_string("MMMM d, yyyy 'at' hh:mm:ss a z");
 map_to_file(userdata,"userdata.txt");
 lastM=lastM+lastH*60;
 nowM=nowM+nowH*60;
 nowM-=lastM;
 if (nowM<0) nowM+=1440;
 if (nowM==1) return 0;
 return nowM;
}

boolean isMath(string m){
 matcher fix=create_matcher("(?i)(last|floor|ceil|min|max|sqrt|pi|phi|e|sin|cos|tan|ln|log|fairy|hound|jack|jitb|lep|monkey|ant|cactus)",m);
 m=replace_all(fix,"+");
 fix=create_matcher("[^\\d\\s*+/.^,\\-\\(\\)\\[\\]\\$]",m);
 if (find(fix)) return false;
 return true;
}

boolean fancyMath(string sender,string equation){
 matcher dm=create_matcher("\\[(\\d*),(\\d*)\\]\\s?(.*)",equation);
 if (!find(dm)) return false;
 float tmp=0;
 string mod;
 int low=group(dm,1).to_int();
 int high=group(dm,2).to_int();
 equation=group(dm,3);
 if (low>high){
  tmp=low;
  low=high;
  high=tmp.to_int();
 }
 tmp=0;
 for i from low to high{
  dm=create_matcher("k",equation);
  mod=replace_all(dm,i.to_string());
  tmp+=mathlibeval(mod);
 }
 userdata[sender].lastMath=tmp;
 userdata["*"].lastMath=tmp;
 map_to_file(userdata,"userdata.txt");
 chat_clan(tmp.to_string());
 return true;
}

boolean mathDot(string data, boolean cross){
 vector u;
 vector v;
 matcher m=create_matcher("<(.+?)>\\s?<(.+?)>",data);
 if (!m.find()) return false;
 u=m.group(1).to_vector();
 v=m.group(2).to_vector();
 string x;
 if (cross) x=to_string(u.cross(v));
 else x=to_string(u.dot(v));
 chat_clan(x);
 return true;
}

boolean mathSTP(string data){
 vector a;
 vector b;
 vector c;
 matcher m=create_matcher("<(.+?)>\\s?<(.+?)>\\s?<(.+?)>",data);
 if (!m.find()) return false;
 a=m.group(1).to_vector();
 b=m.group(2).to_vector();
 c=m.group(3).to_vector();
 string x=a.dot(b.cross(c)).to_string();
 chat_clan(x);
 return true;
}

boolean googleSearch(string details){
 matcher methodm=create_matcher("(?:\\.|\\||\\s)(\\w+):\\s?(.*)",details);
 if(!find(methodm)) return false;
 string method=methodm.group(1);
 string data=methodm.group(2);
 string result;
 matcher t;
 switch (method){
  case "define":
   result=visit_url("http://www.google.com/dictionary?aq=f&langpair=en|en&q="+data.url_encode(),false,true);
   if (result.contains_text("No dictionary definitions")){
    chat_clan("No definitions were found for "+data);
    return true;
   }
   methodm=create_matcher("div\\s*class=\"dct-em\">\\r?\\n?<span class=\"dct-tt\">(.+?)</span>",result);
   while(methodm.find()){
    data=methodm.group(1).decodeHTML(false);
    t=create_matcher("\".*\"",data);
    if(find(t))data=replace_all(t,"");
    chat_clan(data);
   }
   break;
  case "spell":
   result=visit_url("http://www.google.com/dictionary?aq=f&langpair=en|en&q="+data.url_encode(),false,true);
   if (!result.contains_text("Did you mean:")){
    chat_clan("Google seems to think "+data+" is correct.");
    return true;
   }
   result=result.substring(result.index_of("Did you mean:"));
   methodm=create_matcher("<b><i>(.+?)</i></b>",result);
   if(!find(methodm)) return true;
   result=methodm.group(1);
   chat_clan("Google suggests \""+result+"\".");
   break;
  case "urban":
   result=visit_url("http://www.urbandictionary.com/define.php?term="+data.url_encode(),false,true);
   methodm=create_matcher("class=\"definition\">(.+?)</?[db]",result);
   if(!find(methodm)){
    chat_clan("No definitions were found for "+data);
    return true;
   }
   result=methodm.group(1);
   methodm=create_matcher("<a .+?>(.+?)</a>",result);
   while (find(methodm)){
    result=replace_all(methodm,methodm.group(1));
    methodm=create_matcher("<a .+?>(.+?)</a>",result);   
   }
   chat_clan(result.decodeHTML(false));
   break;
   case "market":
    analyze_md("!","link "+data);
   break;
  } 
 return true;
}

void publicChat(string sender, string msg){
 matcher m;
 if (sender=="mesachat"){
  m=create_matcher("([a-zA-Z][\\w ]{1,29}):\\s?(.*)",msg);
  if (find(m)){
   sender=group(m,1);
   msg=group(m,2);
  }else return;
 }
 string original=msg;
 chatVars["timedif"]=timeSinceLastChat(sender).to_string();
 chatVars["time"]=now_to_string("HH:mm:ss z");
 boolean addressed=false;
 boolean referred=false;
 m=create_matcher("(?i)(ominous buffer|ob)[:,]\\s?",msg);
 if (find(m)){
  addressed=true;
  msg=substring(msg,end(m));
 }
 m=create_matcher("(?i)(ominous buffer|\\Wob\\W)",msg);
 if (find(m)) referred=true;
 m=create_matcher("([\\w\\d]*)\\s?(.*)",msg);
 string pred;
 string oper;
 if (find(m)){
  pred=group(m,1);
  oper=group(m,2);
 }
 for i from 2 upto count(genders)-1 if (genders[i] contains 5) genderMatcherString+="|"+genders[i,5];
 genderMatcherString+=")";
 if (!addressed) m=create_matcher(genderMatcherString,msg);
 else m=create_matcher("(?i)"+genderMatcherString,msg);
 if (find(m)){
  print("Gender set for "+sender,"blue");
  setGender(sender,group(m,1));
  return;
 }
 m=create_matcher("(?i)(call me|am also known as|i go by)\\s([\\w ']*).?",msg);
 if (find(m)&&(referred||addressed)){
  print("Nick set for "+sender,"blue");
  userdata[sender].nick=group(m,2);
  foreach alt in userdata[sender].multis userdata[alt].nick=group(m,2);
  map_to_file(userdata,"userdata.txt");
  return;
 }
 if (addressed&&isMath(msg)){
  if("*+-^/".contains_text(msg.char_at(0))) msg=userdata[sender].lastMath.to_string()+msg;
  m=create_matcher("\\s*",msg);
  msg=replace_all(m,"");
  float[string] mathvars;
  mathvars["last"]=userdata[sender].lastMath;
  mathvars["ans"]=userdata["*"].lastMath;
  userdata[sender].lastMath=mathlibeval(msg,mathvars);
  msg=userdata[sender].lastMath.to_string();
  userdata["*"].lastMath=userdata[sender].lastMath;
  map_to_file(userdata,"userdata.txt");
  if (msg.to_float()==msg.to_int()) msg=substring(msg,0,length(msg)-2);
  chat_clan(msg);
  return;
 }
 switch (pred){
  case "roll":
   if (addressed) roll(sender,oper,"public");
   return;
  case "pick":
  case "choose":
   if (addressed) pick(oper);
   return;
  case "echo":
   if (addressed) chat_clan(replyParser(sender,oper));
   return;
  case "sum":
   if (addressed) fancyMath(sender,oper);
   return;
  case "google":
   if (googleSearch(oper)) return;
   break;
  case "dot":
   if (mathDot(oper,false)) return;
   break;
  case "cross":
   if (mathDot(oper,true)) return;
   break;
  case "stp":
   if (mathSTP(oper)) return;
   break;
 }
 nopredpass(sender,original,addressed);
 return;
}

void main(string sender, string msg, string channel){
 if (sender=="faxbot") {
  if (msg.contains_text("help")) chat_private(get_property("_lastFax"),"Faxbot doesn't have that monster.");
  else chat_private(get_property("_lastFax"),msg);
  return;
 }
 if (sender=="wangbot") return;
 msg=decodeHTML(msg,true);
 if ((channel=="")&&(sender=="Ominous Buffer")){
  channel="/clan";
  sender=":SYSTEM";
 }
 if ((channel=="/clan")&&(sender=="MesaChat")) return;
 if (sender=="MesaChat") channel="/clan";
 if (channel=="/clan"){
  switch (gameType()){
   case gameRoulette:
    russianRoulette(sender,msg);
    return;
   default:
    if (sender==":SYSTEM") return;
    publicChat(sender,msg);
    return;
  }  
 }
 if (!buffable(sender)) return;
 if(msg.char_at(0)=="!"){
  errorMsg=false;
  if(length(msg)>1) msg=substring(msg,1);
 }
 if(getUF(sender,noFlag)) errorMsg=false;
 if(gameType()==gameWordshot) msg=wordshot(sender,msg);
 if(msg=="x")return;
 msg=chatFilter(sender,msg);
 if(msg=="x")return;
 msg=predicateFilter(sender,msg);
 if(msg=="x")return;
 if ((sender==turt_name) || (sender==sauc_name)){
  buff(sender, msg, 0, sender);
  return;
 }
 if ((sender=="chatbot")||(sender==my_name())) return;
 matcher m=create_matcher("buff ([a-zA-Z][a-zA-Z 0-9']*) with (.*)",msg.to_lower_case());
 string co=sender;
 if (find(m)){
  sender=group(m,1);
  msg=group(m,2);
 }
 int turnR=0;
 m=create_matcher("[\;,]+",msg);
 msg=replace_all(m,"\;");
 string[int] messages = split_string(msg,"\;");
 foreach i in messages{
  turnR=0;
  m=create_matcher("(\\d+)",messages[i]);
  if (find(m)){
   if(to_float(group(m,1))>1000) turnR=1000;
   else turnR=to_int(group(m,1));
  }// why not "[a-zA-Z][\\s\\w']*[a-zA-Z]"
  m=create_matcher("[a-zA-Z\\?](?:[a-zA-Z']|(?:\\s(?=\\w)))*",messages[i]);
  if (find(m)) messages[i]=group(m,0);
  buff(sender,messages[i],turnR,co);
 }
}