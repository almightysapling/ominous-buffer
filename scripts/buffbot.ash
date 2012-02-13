import <shared.ash>
import <market.ash>
import <mathlib.ash>
invokeResourceMan(__FILE__);
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
genders[count(genders)]=to_array($strings[he, him, himself, his, his, BOY|MAN|MALE|HE|HIM]);
genders[count(genders)]=to_array($strings[she, her, herself, hers, her, GIRL|WOMAN|FEMALE|SHE|HER]);
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
timestamp[int] ctimestamp;
update(ctimestamp,"timefile.txt");
timestamp ctimes=ctimestamp[0];
update(userdata,"userdata.txt");

boolean errorMsg=true;
string prefix="";
string response="";
string someoneDefined="";
string[string] chatVars;
string trueUser="";
string trueChannel="";
boolean impliedOB=false;
int TPC=25;
boolean raidlogRead=false;

void chat(){
 if((prefix=="")||(prefix.char_at(0)=="/")){
  chat_clan(prefix+response);
  return;
 }
 if(prefix.char_at(0)==":"){
  print("Something fuckered up.");
  return;
 }
 if(prefix.char_at(0)=="!")return;
 if(prefix==my_name()){
  print(response,"red");
  return;
 }
 chat_private(prefix,response);
}
void chat(string msg){
 response=msg;
 chat();
}
void chat(string u, string m){
 prefix=u;
 response=m;
 chat();
}

string genderPronoun(string who, int what, string type){
 boolean cap=false;
 if(type.contains_text("P")||type.contains_text("S"))cap=true;
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
 if(what!=1)reply=genders[what,t];
 else if(t<3)reply=who;
 else reply=who+"'s";
 if(cap)reply=reply.char_at(0).to_upper_case()+reply.substring(1);
 return reply;
}

string genderString(userinfo data){
 if(data.gender==0)data.gender=2;
 if(data.gender==1)return data.nick;
 return genders[0,data.gender];
}

void errorMessage(string who, string what){
 if(errorMsg)chat(who,what);
}

void errorMessage(string who, string what, int g){
 matcher mx=create_matcher("(?i)(\\$psub|\\$pobj|\\$pref|\\$ppos|\\&pdet)",what);
 while(mx.find()){
  what=mx.replace_first(genderPronoun(who,g,mx.group(1)));
  mx=mx.reset(what);
 }
 if(getUF(who,noFlag))chat(who,what);
}

boolean buffable(string sender){
 if(userdata[sender].userid==0)updateId(sender,true);
 if(getUF(sender,blacklist)){
  chat(sender,"We do what we must because we can. For the good of all of us. Except the ones who are blacklisted from Black Mesa.");
  return false;
 }
 if(getUF(sender,inClan)||getUF(sender,whitelist)||getUF(sender,inAssociate)){
  return true;
 }else{
  chat(sender,"We do what we must because we can. For the good of all of us. Except the ones who are not in Black Mesa.");
  return false;
 }
}

string decodeHTML(string msg, boolean chat){
 matcher i;
 if(chat){
  i=create_matcher("<a style.+?>(.+?)</a>",msg);
  while(i.find()){
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

void logout(string sender,string options){
 if((userdata[sender].flags&isAdmin)!=isAdmin){
  chat(sender,"You do not have permission to use this command.");
  return;
 }
 saveSettings(earlySave);
 if(options!="all")set_property("_bufferOnly","1");
 cli_execute("exit");
}

void createpack(string sender, string msg){
 matcher namem=create_matcher("(\\S*)\\s?(.*)",msg);
 string packname;
 string packdata;
 if(namem.find()){
  packname=namem.group(1);
  packdata=namem.group(2);
 }else{
  chat(sender,"You must supply the appropriate data for us to save that.");
  return;
 }
 if((count(userdata[sender].buffpacks)>9)&&(!(userdata[sender].buffpacks contains packname))){
  chat(sender,"You already have 10 buffpacks, to have more would be ridiculous; not even funny.");
  return;
 }
 chat(sender,"Your buffpack has been saved.");
 checkOut(userdata,"userdata.txt");
 userdata[sender].buffpacks[packname]=packdata;
 commit(userdata,"userdata.txt");
}

void delpack(string sender, string packname){
 checkOut(userdata,"userdata.txt");
 string s=remove userdata[sender].buffpacks[packname];
 if(s!="")chat(sender,"Pack removed.");
 commit(userdata,"userdata.txt");
}

boolean sendRecord(int skillId, string sender){
 item recording=to_item("recording of "+skillId.to_skill().to_string());
 if(item_amount(recording)<1) return false;
 claimResource("adventuring");
 cli_execute("csend 1 "+recording.to_string()+" to "+sender+" ||");
 freeResource("adventuring");
 return true;
}

void buff(string sender, string msg, int numTurns, string ding){
 //Catch incoming error messages (success in the case of Employee of the Month) from other Bots
 if((to_lower_case(sender)==turt_name)||(to_lower_case(sender)==sauc_name)){
  string[int] failsplit = split_string(msg,"\\s");
  if(index_of("ARLNS",failsplit[0])>-1){
   sender=to_playerName(failsplit[1].to_int());
   ding=to_playerName(failsplit[2].to_int());
  }
  switch(failsplit[0]){
   case "CASTRQ":
    if(sender==turt_name)set_property('tamerCasts',failsplit[1]);
    if(sender==sauc_name)set_property('sauceCasts',failsplit[1]);
    break;
   case "RATION ITEM":
    use_skill(12,$skill[Fat Leon's Phat Loot Lyric],sender);
    break;
   case "RATION MEAT":
    use_skill(12,$skill[Polka of Plenty],sender);
    break;
   case "RATION NONCOMBAT":
    use_skill(12,$skill[Carlweather's Cantata of Confrontation],sender);
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
    errorMessage(failsplit[2],"I'm sorry, but you've reached your daily limit for "+failsplit[3].to_int().to_skill().to_string()+".");
    break;
   case "N":
    errorMessage(failsplit[2],"The cake is a lie. So is that thing you asked for, since it wasn't a buff.");
    break;
   case "S":
    checkOut(userdata,"userdata.txt");
    userdata[ding].buffs[failsplit[3].to_int()]+=1;
    userdata["*"].buffs[failsplit[3].to_int()]+=1;
    commit(userdata,"userdata.txt");
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
 if(skillnum>9000){
  skillnum-=9000;
  skillnum=(skillnum/100)*1000+skillnum-((skillnum/100)*100);
 }
 switch(skillnum){
  case 1:case 3:case 12:case 15:case 19:
  case 46:case 47:case 48:case 58:case 59:case 60: return;
  case 7008: skillnum=6004; break;//Correct for Moxious Maneuver
  case 7040:case 7041: return;
 }
 //Forward skill requests to relay bots when necessary
 if(getUF(ding,inAssociate))max=400;
 if((max==400)&&(getUF(ding,highAssociate)))max=700;
 if(getUF(ding,inClan)||getUF(ding,whitelist))max=700;
 int senderid=getId(sender);
 string mout;
 if(skillnum==62){
  numTurns=TPC;
  switch(userdata["*"].buffs[skillnum]){
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
 if((skillnum>2000)&&(skillnum<3000)){
  mout=to_string(senderid)+" "+to_string(getId(ding))+" "+to_string(skillnum)+" "+to_string(numTurns)+" "+(getUF(ding,noLimit)?"0":to_string(max));
  chat_private(turt_name,mout);
  return;
 }
 if((skillnum>4000)&&(skillnum<5000)){
  mout=to_string(senderid)+" "+to_string(getId(ding))+" "+to_string(skillnum)+" "+to_string(numTurns)+" "+(getUF(ding,noLimit)?"0":to_string(max));
  chat_private(sauc_name,mout);
  return;
 }
 //Assign default values if turns isn't specified.
 if(skillnum==6014) numTurns=TPC;//Ode
 if(numTurns==0){
  if(skillnum==6026) numTurns=125;//Donho
  else if(((skillnum>6019)&&(skillnum<6025))||(skillnum==6028)) numTurns=25;//Limited buffs
  else if(skillnum!=6014) numTurns=200;//Else
 }
 casts=ceil(numTurns/(TPC*1.0));
 //Assign buff limits by clan.
 if(getUF(ding,inClan)||getUF(ding,whitelist)||(getUF(ding,inAssociate)&&getUF(ding,highAssociate))){
  if(((skillnum>6019) && (skillnum<6025)) || (skillnum==6028)) max=1;//Limited buffs
  else if(skillnum==6014) max=5;//Ode
  else if(skillnum==6026) max=20;//Donho
  else if(skillnum==6901) max=1;//Time's Arrow
  else max=28;//Else
 }else if(getUF(ding,inAssociate)){
  if(((skillnum>6019) && (skillnum<6025)) || (skillnum==6028)) max=1;
  else if(skillnum==6014) max=3;
  else if(skillnum==6026) max=10;
  else if(skillnum==6901) max=0;
  else max=16;
 }
 casts=min(casts,max);
 //Adjust casts to be within limits
 if(((userdata[sender].flags&noLimit)!=noLimit)&&(userdata[ding].buffs contains skillnum)){
  if((casts+userdata[ding].buffs[skillnum])>max) casts=max-userdata[ding].buffs[skillnum];
 }
 if(casts==0){
  errorMessage(ding,"I'm sorry, but you've reached your daily limit for that buff.");
  return;
 }
 //Quick check to see if limited buffs still available
 int maxnum = 999999;
 if((skillnum>6019)&&(skillnum<6025)) maxnum=10;
 else if(skillnum==6026) maxnum=50;
 else if(skillnum==6028) maxnum=5;
 if((skillnum>6019)&&(skillnum<6029)){
  if(maxnum-userdata["*"].buffs[skillnum]<1){
   if(sendRecord(skillnum,sender)){
    checkOut(userdata,"userdata.txt");
    userdata[ding].buffs[skillnum]+=1;
    userdata["*"].buffs[skillnum]+=1;
    commit(userdata,"userdata.txt");
   }else errorMessage(ding,"I'm sorry, but I'm all out of "+messageNew+" for today.");
   return;
  }//balance if not enough to meet request
  if(maxnum-userdata["*"].buffs[skillnum]<casts) casts=maxnum-userdata["*"].buffs[skillnum];
 }
 //This is the actual casting function.
 if(skillnum==6901){
  if(item_amount($item[time's arrow])<1)retrieve_item(1,$item[time's arrow]);
  if(item_amount($item[time's arrow])<1){
   chat(ding,"Currently out of Time's Arrows. Looks like you're out of luck.");
   return;
  }
  claimResource("adventuring");
  string t=visit_url("curse.php?action=use&pwd="+my_hash()+"&whichitem=4939&targetplayer="+sender);
  print("Throwing Time's Arrow at "+sender);
  freeResource("adventuring");
  checkOut(userdata,"userdata.txt");
  userdata[ding].buffs[skillnum]+=1;
  commit(userdata,"userdata.txt");
  return;
 }
 claimResource("adventuring");
 checkOut(userdata,"userdata.txt");
 if(have_skill(to_skill(skillnum))){
  if(use_skill(casts,to_skill(skillnum),sender)){
   int totCastsE=get_property('totalCastsEver').to_int()+casts;
   set_property('totalCastsEver',totCastsE.to_string());
   userdata[ding].buffs[skillnum]+=casts;
   userdata["*"].buffs[skillnum]+=casts;
   commit(userdata,"userdata.txt",false);
   if(((skillnum>6019)&&(skillnum<6029))||(skillnum==62)){
    updateDC("useCurrent");
    updateLimits();
   }
  }else switch(last_skill_message()){
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
 if(((my_maxmp()-my_mp())>=300)&&(!to_boolean(get_property("oscusSodaUsed"))))use(1,$item[oscus's neverending soda]);
 if(((my_maxmp()-my_mp())>=1000)&&(get_property("nunsVisits")<3))cli_execute("nuns");
 if((my_mp()<900)&&(my_fullness()<15)){
  retrieve_item(1,$item[Jumbo Dr. Lucifer]);
  eatsilent(1,$item[Jumbo Dr. Lucifer]);
  retrieve_item(1,$item[scroll of drastic healing]);
  use(1,$item[scroll of drastic healing]);
 }
 while(my_mp()<952){
  if(item_amount($item[magical mystery juice])<1) retrieve_item(1,$item[magical mystery juice]);
  use(1,$item[magical mystery juice]);
 }
 commit(userdata,"userdata.txt");
 freeResource("adventuring");
}

int roll(string sender, string msg){
 matcher m=create_matcher("(\\d+)[dD](\\d+)",msg);
 if(!m.find()){
  errorMessage(sender,"You're doing it wrong. Typical.");
  return 0;
 }
 int running;
 if((m.group(1).to_int()<1)||(m.group(1).to_int()>1000000)||(m.group(2).to_int()<2)||(m.group(2).to_int()>1000000)){
  errorMessage(sender,"That's an invalid range.");
  return 0;
 }
 for die from 1 to m.group(1).to_int() running+=(1+random(m.group(2).to_int()));
 if(prefix=="")chat("/em rolls "+running+" for "+sender+" ("+m.group(1)+"d"+m.group(2)+").");
 else chat("Rolling "+m.group(1)+"d"+m.group(2)+" gives "+running+".");
 return running;
}

void startGame(string sender, string msg){
 gameData game;
 if(gameType()!=gameNone){
  game=loadGame();
  if((msg=="cancel")||(msg=="stop")){
   if((sender==game.host)||getUF(sender,isAdmin)){
    closeGame();
    chat(sender,"Game canceled");
    chat("","You must all be orphans, not even the host of the game loved you long enough to finish. Game canceled.");
   }else chat(sender,"You don't have permission to do that.");
  }else chat(sender,"A game is already in session by "+game.host+".");
  return;
 }
 matcher m=create_matcher("(?i)(wordshot|RR|russian roulette|russianroulette)\\s?(\\d+|\\w+)?",msg);
 if(!m.find())return;
 string t=m.group(1);
 string l="-";
 if(m.group_count()>1)l=m.group(2);
 switch(t){
  case "wordshot":
   startWordshot(l.to_int(),sender);
   game=loadGame();
   string w;
   foreach k,v in game.players if(v==1) w=k;
   if((l.to_int()==0)&&(l!="-")&&(l.length()>2)&&(l.length()<14)){
    boolean[string]list;
    update(list,"wordshot/"+l.length()+".txt");
    int[string] koldict;
    update(koldict,"wordshot/custom.txt");
    if((list contains l)||(koldict contains l)){
     remove game.players[w];
     game.players[l]=1;
     print("Actually: "+l);
     w=l;
     saveGame(game);
    }else{
     closeGame();
     chat(sender,"Word not found");
     return;
    }
   }
   chat(sender,"Game started.");
   chat("",w.length().to_string()+"-letter Wordshot! Send guesses to me!");
   break;
  case "rr":case "russianroulette":
  case "russian roulette":
   //startRussianRoulette;
   break;
 }
}

void pick(string options){
 string[int] list=split_string(options,"(\\s?,\\s?or\\s|,\\s?|\\sor\\s)");
 if(count(list)<2)return;
 int d=random(count(list));
 chat("/em picks "+list[d]+".");
}

void fact(){
 string[int] list;
 file_to_map("facts.txt",list);
 int d=random(count(list));
 chat(list[d]);
}

void mod(string sender, string msg){
 boolean adminonly=getUF(sender,isAdmin);
 if(sender==my_name())adminonly=true;
 matcher m=create_matcher("(.*)[., ;]*\\|\\|\\s*(.*)",msg);
 string cmdlist=msg;
 string user=sender;
 if(m.find()){
  cmdlist=m.group(1);
  user=m.group(2);
 }
 if(!adminonly) user=sender;
 m=create_matcher("[., ;]+",cmdlist);
 cmdlist=replace_all(m," ");
 string[int]cmds=split_string(cmdlist," ");
 checkOut(userdata,"userdata.txt");
 foreach i,cmd in cmds
  switch(cmd){
   case "noLimit":
    if(adminonly){
     setUF(user,noLimit);
     chat(sender,user+" has had "+genders[userdata[user].gender,gPosDet]+" limit lifted.");
    }else errorMessage(sender,"You do not have permissions to use "+cmd+".");
    break;
   case "limit":
    if(adminonly){
     unSetUF(user,noLimit);
     chat(sender,user+" has had "+genders[userdata[user].gender,gPosDet]+" limit re-imposed.");
    }else errorMessage(sender,"You do not have permissions to use "+cmd+".");
    break;
   case "nowarning":
    setUF(user,noFlag);
    chat(sender,user+"\'s warnings disabled.");
    break;
   case "warning":
    unSetUF(user,noFlag);
    chat(sender,user+"\'s warnings enabled.");
    break;
   case "clear":
    userdata[user].userId=0;
    chat(sender,"Clan Status cleared for "+user+".");
    break;
   case "add":
    if(adminonly){
     setUF(user,isAdmin);
     chat(sender,user+" has been given administrative permissions.");
    }else errorMessage(sender,"You do not have permission to use "+cmd+".");
    break;
   case "remove":
    if(adminonly){
     unSetUF(user,isAdmin);
     chat(sender,user+" is no longer an administrator.");
    }else errorMessage(sender,"You do not have permission to use "+cmd+".");
    break;
   case "whitelist":case "wl":
    if(adminonly){
     updateId(user,true);
     setUF(user,whitelist);
     chat(sender,user+" has been whitelisted to OB.");
    }else errorMessage(sender,"You do not have permission to use "+cmd+".");
    break;
   case "blacklist":
    if(adminonly){
     updateId(user,true);
     setUF(user,blacklist);
     chat(sender,user+" has been blacklisted from OB.");
    }else errorMessage(sender,"You do not have permission to use "+cmd+".");
    break;
   case "reset":
    if(adminonly){
     updateId(user,true);
     unSetUF(user,whitelist+blacklist+inClan);
     userdata[user].userid=0;
     chat(sender,user+" has had $ppos settings cleared.");
    }else errorMessage(sender,"You do not have permission to use "+cmd+".");
    break;
   default:
    errorMessage(sender,cmd+" seems to be an invalid command.");
    break;
  }
 commit(userdata,"userdata.txt");
}

void fax(string sender, string msg){
 string[monster]m;
 update(m,"faxnames.txt");
 switch(msg){
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
 if(nm==""){
  chat(sender,"My database couldn't make a direct match for that, so I'll send it straight to faxbot as is.");
  nm=msg;
 }
 print("Requesting "+msg+" ("+nm+") from FaxBot.");
 chat_private("FaxBot",nm);
}

void updateRaidlog(){
 if(raidlogRead)return;
 claimResource("adventuring");
 string v=visit_url("clan_raidlogs.php");
 freeResource("adventuring");
 matcher mx=create_matcher("opened (a|\\d+) sewer grate",v);
 int turned=0;
 while(mx.find())if(mx.group(1)=="a") turned+=1;
 else turned+=mx.group(1).to_int();
 set_property("sewerGrates",turned);
 mx=create_matcher("lowered the water level.+?\\((\\d+) turn",v);
 turned=0;
 while(mx.find())turned+=mx.group(1).to_int();
 set_property("sewerValves",turned);
}

string replyParser(string sender, string msg){
 string temp;
 string someone=sender;
 string createOnce="";
 matcher variable=create_matcher("(?i)\\$s",msg);
 if(variable.find()&&(someoneDefined=="")){
  boolean[string] inClan=who_clan();
  int rng=0;
  if(count(inClan)>2) rng=random(count(inClan)-1);
  int c=0;
  foreach clannie in inClan{
   if(clannie==sender) continue;
   someoneDefined=clannie;
   c+=1;
   if(c>rng) break;
  }
 }
 if(someoneDefined!="")someone=someoneDefined;
 if(userdata[someone].userid==0)updateId(someone,true);
 if(userdata[sender].userid==0)updateId(sender,true);
 if(userdata[someone].gender==0)userdata[someone].gender=2;
 if(userdata[sender].gender==0)userdata[sender].gender=2;
 userinfo randplayer=userdata[someone];
 userinfo thesender=userdata[sender];
 string pclass;
 string sclass;
 variable=create_matcher("(?i)class",msg);
 if(variable.find()){
  temp=visit_url("showplayer.php?who="+randplayer.userid.to_string());
  variable=create_matcher("Class:</b></td><td>(.+?)<",temp);
  if(variable.find())sclass=variable.group(1);
  temp=visit_url("showplayer.php?who="+thesender.userid.to_string());
  variable=create_matcher("Class:</b></td><td>(.+?)<",temp);
  if(variable.find())pclass=variable.group(1);
 }
 if(thesender.nick=="") thesender.nick=sender;
 if(randplayer.nick=="") randplayer.nick=someone;
 variable=create_matcher("(?<!\\\\)\\$(\\w*)(\\([\\w\\s]*\\))?",msg);
 while (variable.find()){
  switch(variable.group(1)){
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
    msg=replace_first(variable,genderPronoun(randplayer.nick,randplayer.gender,variable.group(1)));
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
    if(randplayer.lastMath.to_int()==randplayer.lastMath)temp=randplayer.lastMath.to_int().to_string();
    msg=replace_first(variable,temp);
    break;
   case "sclass":
    msg=replace_first(variable,sclass);
    break;
   case "sstat":
    switch(sclass){
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
    msg=replace_first(variable,genderPronoun(thesender.nick,thesender.gender,variable.group(1)));
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
    if(thesender.lastMath.to_int()==thesender.lastMath)temp=thesender.lastMath.to_int().to_string();
    msg=replace_first(variable,temp);
    break;
   case "pclass":
    msg=replace_first(variable,pclass);
    break;
   case "pstat":
    switch(pclass){
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
    if(temp=="none")temp="nothing";
    msg=replace_first(variable,temp);
    break;
   case "statdaytomorrow":
    temp=stat_bonus_tomorrow().to_string();
    if(temp=="none")temp="nothing";
    msg=replace_first(variable,temp);
    break;
   case "math":
   case "result":
    temp=userdata["*"].lastMath.to_string();
    if(userdata["*"].lastMath.to_int()==userdata["*"].lastMath)temp=userdata["*"].lastMath.to_int().to_string();
    msg=replace_first(variable,temp);
    break;
   case "trigger":
    msg=replace_first(variable,userdata["*"].lastTrigger);
    break;
   case "lotto":
    int[string] books;
    update(books,"books.txt");
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
   case "grates":
    if(!createOnce.contains_text(".grates")){
     updateRaidlog();
     createOnce+=".grates";
    }
    msg=replace_first(variable,get_property("sewerGrates"));
    break;
   case "valves":
    if(!createOnce.contains_text(".valves")){
     updateRaidlog();
     createOnce+=".valves";
    }
    msg=replace_first(variable,get_property("sewerValves"));
    break;
   case "rand":
    int i=100;
    if(variable.group_count()>1)i=variable.group(2).to_int();
    i=random(i);
    msg=replace_first(variable,i.to_string());
    break;
   default:
    if(chatVars contains variable.group(1))msg=replace_first(variable,chatVars[variable.group(1)]);
    else msg=replace_first(variable,variable.group(1));
    break;
  }
  variable.reset(msg);
 }
 variable=create_matcher("\\\\\\$",msg);
 msg=replace_all(variable,"$");
 return msg;
}

string chatFilter(string sender, string msg){
 if(msg.contains_text("fuck")){
  chat(sender,"Try again, fuckwad.");
  return "x";
 }
 return msg;
}

void train(string trainer, string msg){
 string[int,string] changes;
 checkOut(changes,"changes.txt");
 changes[count(changes),trainer]=msg;
 responses[string] botdata;
 checkOut(botdata,"replies.txt");
 responses newr;
 newr.flags=mustAddress;
 string trig;
 matcher ff=create_matcher("(?<!\\\\)\\[(\\w*)(?<!\\\\)]\\s?",msg);
 if(ff.find()){
  if(ff.group(1).contains_text("r")) newr.flags=mustRefer;
  if(ff.group(1).contains_text("c")) newr.flags|=caseSensitive;
  if(ff.group(1).contains_text("n")) newr.flags&=~mustAddress;
  if(ff.group(1).contains_text("o")) newr.flags|=fullText;
  if(ff.group(1).contains_text("a")) newr.flags=(fullText|caseSensitive)&(~mustAddress);
  if((ff.group(1).contains_text("f"))&&((userdata[trainer].flags&isAdmin)==isAdmin)) newr.flags|=repFree;
  msg=replace_first(ff,"");
 }
 ff=create_matcher("(?<!\\\\)::(.+?)=(.+?)::",msg);
 if(ff.find()){
  newr.cond1=ff.group(1);
  newr.cond2=ff.group(2);
  msg=replace_first(ff,"");
 }
 ff=create_matcher("(.*)\\s?(?<!\\\\)<(\\w*?)(?<!\\\\)>\\s?(.*)",msg);
 if(ff.find()){
  newr.reply=ff.group(3);
  newr.method=ff.group(2).to_lower_case();
  trig=ff.group(1);
  boolean knownmethod=false;
  switch(newr.method){
   case "say":
   case "do":
    knownmethod=true;
  }
  if(!knownmethod){
   errorMessage(trainer,"Training failed: Unknown method: "+newr.method);
   freeResource("changes.txt");
   freeResource("replies.txt");
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
  if((newr.flags&caseSensitive)==0)botdata[t.to_lower_case()]=newr;
  else botdata[t]=newr;
 }
 chat(trainer,"Training complete: "+newr.reply);
 commit(botdata,"replies.txt");
 commit(changes,"changes.txt");
}

void untrain(string trainer, string msg){
 string[int,string] changes;
 checkOut(changes,"changes.txt");
 changes[count(changes),trainer]="drop "+msg;
 responses[string] botdata;
 checkOut(botdata,"replies.txt");
 responses fix=remove botdata[msg];
 chat(trainer,"Training removed: "+fix.reply);
 commit(botdata,"replies.txt");
 commit(changes,"changes.txt");
}

void search(string sender, string msg){
 msg=msg.to_lower_case();
 string trigm,replm;
 responses[string] botdata;
 update(botdata,"replies.txt");
 foreach trig,re in botdata{
  if(re.reply.to_lower_case().contains_text(msg)){
   replm+="T: "+trig+"\n";
   if(re.cond1!=re.cond2)replm+="If: \""+re.cond1+"\" = \""+re.cond2+"\"\n";
   replm+="M: "+re.method+"\n";
   replm+="R: "+re.reply+"\n\n";
   continue;
  }
  if(trig.to_lower_case().contains_text(msg)){
   replm+="T: "+trig+"\n";
   if(re.cond1!=re.cond2)replm+="If: \""+re.cond1+"\" = \""+re.cond2+"\"\n";
   replm+="M: "+re.method+"\n";
   replm+="R: "+re.reply+"\n\n";
   continue;
  }
  if(msg=="*"){
   replm+="T: "+trig+"\n";
   if(re.cond1!=re.cond2)replm+="If: \""+re.cond1+"\" = \""+re.cond2+"\"\n";
   replm+="M: "+re.method+"\n";
   replm+="R: "+re.reply+"\n\n";
  }
 }
 string send=trigm+"\n"+replm;
 if(send=="\n")send="No matches found for "+msg;
 cli_execute("csend to "+sender+"||"+send);
}

void clearData(string what){
 print("ClearRQ:"+what);
 switch(what){
  case "changelog":
   string[int,string] changes;
   claimResource("changes.txt");
   commit(changes,"changes.txt");
   break;
  case "filter":
   checkOut(userdata,"userdata.txt");
   for i from 0 to 6 userdata["*"].buffpacks[i.to_string()]="";
   commit(userdata,"userdata.txt");
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
  if(userdata[user].nick.to_lower_case().contains_text(who)){
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
 if(reply=="") reply="No matches found for "+who;
 if(length(reply)<151) chat(sender,reply);
 else{
  matcher m=create_matcher("\\. ",reply);
  reply=replace_all(m,".\n");
  cli_execute("csend to "+sender+"||"+reply);
 }
}

void multilookup(string sender, string who){
 string reply="";
 if(userdata contains who) {
  reply=who+" is a known multi of the following users: ";
  foreach name in userdata[who].multis
   reply+=name+", ";
  if(count(userdata[who].multis)<1) reply="No known multis for "+who+"...";
 }else reply="No matches found for "+who+"...";
 reply=substring(reply,0,length(reply)-2);
 if(length(reply)<151) chat(sender,reply);
 else cli_execute("csend to "+sender+"||"+reply);
}

void userDetails(string sender, string who){
 if(who=="")who=sender;
 string reply;
 string t;
 if((who=="ob")||(who=="ominous buffer")){
  reply="User: Ominous Buffer\n";
  reply+="Known Multis: Ominous Tamer, Ominous Sauceror\nGoes by: OB\n";
  reply+="Gender neutral.\n\n";
  reply+="Currently casting for the following clans: Black Mesa";
  foreach pId in associates{
   t=pId.to_clanName();
   if(t!="")reply+=", "+t;
  }
  reply+=".";
  cli_execute("csend to "+sender+"||"+reply);
  return;
 }
 if(userdata contains who){
  reply="User "+who+":\n";
  if(count(userdata[who].multis)>0){
   reply+="Known Multis: ";
   foreach name in userdata[who].multis reply+=name+", ";
   reply=substring(reply,0,length(reply)-2)+".\n";
  }
  if((userdata[who].nick!=who)&&(userdata[who].nick!="")) reply+="Goes by: "+userdata[who].nick+"\n";
  reply+="Gender: "+genderString(userdata[who])+"\n";
  if(userdata[who].lastTime!="") reply+="Last Time Spoken: "+userdata[who].lastTime+"\n";
  if((who==sender)&&(count(userdata[who].buffpacks)>0)){
   reply+="Buffpacks Defined:\n";
   foreach pack, innards in userdata[who].buffpacks reply+="-"+pack+": "+innards+".\n";
  }
  if(userdata[who].donated>0) reply+="Donated: "+userdata[who].donated.to_string()+" meat.\n";
  if(who==sender) reply+="Bank: "+userdata[who].wallet.to_string()+" meat.\n";
  cli_execute("csend to "+sender+"||"+reply);
 }else chat(sender,"No match found for "+who+".");
}

void userAccountEmpty(string w){
 if(userdata[w].wallet<1){
  errorMessage(w,"You don't have sufficient funds to withdraw.");
  return;
 }
 if(kmail(w,"Your balance in full.",userdata[w].wallet)!=1){
  errorMessage(w,"Error sending meat, try again later, preferably out of ronin/HC.");
  return;
 }
 checkOut(userdata,"userdata.txt");
 userdata[w].wallet=0;
 commit(userdata,"userdata.txt");
}

string addMulti(string n1, string n2){
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
  if(userdata[name].gender!=0) gencarry=userdata[name].gender;
  if(userdata[name].nick!="") ncarry=userdata[name].nick;
 }
 boolean[string] cpy=biglist;
 foreach mult in biglist{
  if(userdata[mult].nick=="") userdata[mult].nick=ncarry;
  if(userdata[mult].gender==0) userdata[mult].gender=gencarry;
  foreach mult2 in cpy if(mult2!=mult) userdata[mult].multis[mult2]=true;
 }
 string s=n1;
 foreach name in biglist if(name!=n1) s+=", "+name;
 return s;
}

void setMulti(string sender, string newaltlist){
 int[string,string] mlist;
 checkOut(mlist,"tempMultis.txt");
 checkOut(userdata,"userdata.txt");
 boolean match=false;
 string[int]alts=split_string(newaltlist,",\\s?");
 int now=now_to_string("yDDDHH").to_int();
 string matchtxt="";
 string tmatch="";
 foreach i, alt in alts{
  foreach name1,name2 in mlist{
   if(now_to_string("yDDDHH").to_int()<now) remove mlist[name1,name2];
   if((name1==alt)&&(name2==sender)){
    tmatch=addMulti(sender,alt);
    remove mlist[name1,name2];
   }
  }
  if(tmatch==""){
   chat(alt,sender+" is attempting to register you as "+genders[userdata[sender].gender,gPosDet]+" multi.");
   mlist[sender,alt]=now+100;
  }else if(length(matchtxt)<length(tmatch)) matchtxt=tmatch;
 }
 if(matchtxt=="") chat(sender,"Reminder sent to other accounts, you have 24 hours to register them.");
 else if(length(matchtxt)<111) chat(sender,"Multi properly registered for accounts:"+matchtxt);
 else cli_execute("csend to "+sender+"||Multi properly registered for accounts:"+matchtxt);
 commit(mlist,"tempMultis.txt");
 commit(userdata,"userdata.txt");
}

void setNick(string sender, string w){
 print("Nick set for "+sender,"blue");
 checkOut(userdata,"userdata.txt");
 userdata[sender].nick=w;
 foreach alt in userdata[sender].multis userdata[alt].nick=w;
 commit(userdata,"userdata.txt");
}

void clanTitle(string sender, string newt){
 if(!getUF(sender,inClan)){
  chat("Only current members of the clan can have their clan title changed... idiot.");
  return;
 }
 if(!getUF(sender,isAdmin)){
  chat("Only admins can use this until it gets fixed for rank recognition, sorry.");
  return;
 }
 claimResource("adventuring");
 visit_url("clan_members.php?pwd&action=modify&pids[]="+userdata[sender].userid+"&title"+userdata[sender].userid+"="+newt);
 freeResource("adventuring");
}

void whitelistEdit(string oper){
 claimResource("adventuring");
 string cw=visit_url("clan_whitelist.php");
 matcher action=create_matcher("(-)?(\\w[\\w\\d\\s_]*)\\s*([:=]\\s*.+?)?",oper);
 int i;
 if(!action.find()){
  chat("I'm not sure what exactly you want me to do with the whitelist.");
  freeResource("adventuring");
  return;
 }
 i=getId(action.group(2));
 if(i==0){
  chat("I'm not sure who "+action.group(2)+" is.");
  freeResource("adventuring");
  return;
 }
 if(action.group(1)=="-"){
  i=getId(action.group(2));
  if(!cw.contains_text("who="+i.to_string())){
   chat(action.group(2)+" isn't currently on the whitelist.");
   freeResource("adventuring");
   return;
  }
  cw=visit_url("clan_whitelist.php?action=update&pwd&player"+i+"="+i+"&drop"+i+"=on");
  freeResource("adventuring");
  return;
 }
 i=getId(action.group(2));
 string s="clan_whitelist.php?action=add&pwd";
 if(cw.contains_text("who="+i.to_string())){
  chat(action.group(2)+" is already whitelisted.");
  freeResource("adventuring");
  return;
 }
 if(cw.contains_text("(#"+i+")")){
  s+="&clannie="+i;
  visit_url(s);
  chat(action.group(2)+" added to whitelist.");
  freeResource("adventuring");
  return;
 }
 s+="&addwho="+action.group(2);
 switch(action.group(3)){
  case "Weighted Companion Cube":case "WCC":case "Cube": s+="&level=4"; break;
  case "Research Assistant":case "Research":case "Assistant":case "RA": s+="&level=14"; break;
  case "Subject": s+="&level=6"; break;
  case "Head Crab":case "HC":case "Head":case "Crab": s+="&level=3";
  case "Exploding Lemons":case "Exploding":case "Lemon":case "EL": s+="&level=17";
  default: s+="&level=7";
 }
 visit_url(s);
 chat(action.group(2)+" added to whitelist.");
 freeResource("adventuring");
}

void sendLink(string sender, string i){
 string base="https://sites.google.com/site/kolclanmesa/";
 string link;
 string t;
 matcher m=create_matcher("\\s",i);
 i=m.replace_all("-");
 if(i==""){
  chat(sender,base+"ominous-buffer");
  return;
 }
 t=visit_url(base+"ominous-buffer/functions");
 string[int] site=split_string(t,"\\r?\\n");
 int cLine=1;
 boolean found=false;
 while ((!found)&&(cLine<count(site))){
  cLine+=1;
  if(site[cLine].contains_text("\"sites-page-title\"")) found=true;
 }
 found=false;
 t="";
 while ((!found)&&(cLine<count(site)-1)){
  cLine+=1;
  m=create_matcher("^(?:\\w|<a)",site[cLine]);
  if(m.find()){
   t+=site[cLine];
   continue;
  }
  m=create_matcher("(?:^|>)"+i+"<",t);
  if(m.find()){
   found=true;
   break;
  }
  t="";
  continue;
 }
 m=create_matcher("href=\"(.+?)\"",t);
 if(m.find()){
  chat(sender,m.group(1));
  return;
 }
 link=base+"ominous-buffer/functions/"+i;
 if(length(visit_url(link))!=0){
  chat(sender,link);
  return;
 }
 link=base+"ominous-buffer/"+i;
 if(length(visit_url(link))!=0){
  chat(sender,link);
  return;
 }
 link=base+i;
 if(length(visit_url(link))!=0){
  chat(sender,link);
  return;
 }
 link=base+"mesachat/functions/"+i;
 if(length(visit_url(link))!=0){
  chat(sender,link);
  return;
 }
 chat(sender,base);
}

string performMath(string sender, string msg){
 if(msg=="")msg="0";
 matcher m=create_matcher("\\s*",msg);
 msg=replace_all(m,"");
 string[int] chunks=split_string(msg,",");
 checkOut(userdata,"userdata.txt");
 float last=userdata[sender].lastMath;
 float[string] mathvars;
 foreach i,chunk in chunks{
  if(chunk=="")continue;
  if("*+-^/".contains_text(chunk.char_at(0)))chunk=last.to_string()+chunk;
  mathvars["last"]=userdata[sender].lastMath;
  mathvars["ans"]=userdata["*"].lastMath;
  last=mathlibeval(chunk,mathvars);
 }
 userdata[sender].lastMath=last;
 msg=last.to_string(8);
 commit(userdata,"userdata.txt");
 if(msg.to_float()==msg.to_int())msg=substring(msg,0,length(msg)-2);
 return msg;
}

void modSessionVar(string sender,string var,string val){
 checkOut(userdata,"userdata.txt");
 string[int] varslist=userdata[sender].sessionVars.split_string(":");
 string[string] vars;
 foreach i in varslist if((!i.odd())&&(varslist contains (i+1))) vars[varslist[i]]=varslist[i+1];
 vars[var]=val;
 if(val=="")remove vars[var];
 string save="";
 foreach vari,valu in vars save+=vari+":"+valu+":";
 userdata[sender].sessionVars=save;
 commit(userdata,"userdata.txt");
}

string getSessionVar(string sender,string var){
 update(userdata,"userdata.txt");
 string[int] varslist=userdata[sender].sessionVars.split_string(":");
 string[string] vars;
 foreach i in varslist if((!i.odd())&&(varslist contains (i+1))) vars[varslist[i]]=varslist[i+1];
 return vars[var];
}

string predicateFilter(string sender, string msg){
 matcher first=create_matcher("(\\S*)\\s?(.*)",msg);
 string pred;
 string oper;
 item whitem;
 int i;
 if(first.find()){
  pred=first.group(1);
  oper=first.group(2);
 }else return msg;
 switch(pred){
  case "alias":
  case "createpack":
   createpack(sender,oper);
   return "x";
  case "alt":
  case "multi":
   setMulti(sender,oper);
   return "x";
  case "alts":
  case "multis":
   multilookup(sender,oper);
   return "x";
  case "clear":
   if(oper=="")return "x";
   if((userdata[sender].flags&isAdmin)!=isAdmin){
    errorMessage(sender,"No, don't do that!");
    return "x";
   }
   clearData(oper);
   return "x";
  case "count":
   if(oper=="")return "x";
   if((userdata[sender].flags&isAdmin)!=isAdmin){
    errorMessage(sender,"No, don't do that!");
    return "x";
   }
   whitem=to_item(oper);
   if(oper=="meat"){
    string r="Meat: "+to_string(my_meat()+my_closet_meat())+". DMS:";
    r+=to_string(item_amount($item[dense meat stack])+closet_amount($item[dense meat stack]));
    chat(r);
   }else if(whitem!=$item[none]){
    string r=whitem.to_string()+": "+item_amount(whitem).to_string();
    chat(r);
   }
   return "x";
  case "deals":
   if((userdata[sender].flags&isAdmin)==isAdmin)updateDC(oper);
   return "x";
  case "delpack":
   delpack(sender,oper);
   return "x";
  case "details":
   userDetails(sender,oper);
   return "x";
  case "drop":
  case "untrain":
   untrain(sender,oper);
   return "x";
  case "fax":
  case "get":
   if(!getUF(sender,inClan)){
    chat(sender,"You must be in Black Mesa to utilize its faxing rights.");
    return "x";
   }
   set_property("_lastFax",sender);
   fax(sender,oper);
   return "x";
  case "help":
  case "?":
   cli_execute("kmail to "+sender+" || Thank you for your interest in my functions. I currently only buff members of Black Mesa and players on its whitelist. If you have recently joined, and are unable to receive a buff, please pm me with the phrase \"settings clear\". Please visit http://z15.invisionfree.com/Black_Mesa_Forums/index.php?showforum=14 for more information.");
   return "x";
  case "host":
   startGame(sender,oper);
   return "x";
  case "learn":
  case "teach":
  case "train":
   train(sender,oper);
   return "x";
  case "logout":
   logout(sender,oper);
   return "x";
  case "market":
   if(!analyze_md(sender,oper))errorMessage(sender,"Analysis failed. Recheck item name and parameters.");
   return "x";
  case "math":
   oper=performMath(sender,oper);
   chat(sender,oper);
   return "x";
  case "mod":
  case "settings":
   mod(sender,oper);
   return "x";
  case "nick":
   first=create_matcher("([\\w ']*)",oper);
   if(first.find()) oper=first.group(1);
   else{
    chat(sender,"Sorry, that's not a valid nickname.");
    return "x";
   }
   setNick(sender,oper);
   return "x";
  case "pack":
  case "set":
   first=create_matcher("(\\d+)\\s*:\\s*(.*)",oper);
   pred="";
   if(first.find()){
    pred=first.group(1);
    oper=first.group(2);
   }
   string r=userdata[sender].buffpacks[oper];
   if((r=="")&&(!contains_text("0123456",oper)))r=userdata["*"].buffpacks[oper];
   if(r==""){
    errorMessage(sender,"That buffpack does not exist.");
    return "x";
   } 
   return pred+":"+r;
  case "ping":
   chat(turt_name,"PING "+sender);
   chat(sauc_name,"PING "+sender);
   chat(sender,"Reply from Ominous Buffer"+(get_property("hostName")==""?".":" c/o "+get_property("hostName")));
   return "x";
  case "pull":
   if(oper=="")return "x";
   if((userdata[sender].flags&isAdmin)!=isAdmin){
    errorMessage(sender,"No, don't do that!");
    return "x";
   }
   first=create_matcher("(\\d+)\\s?(.+)",oper);
   if(!first.find())return "x";
   i=first.group(1).to_int();
   whitem=first.group(2).to_item();
   if(first.group(2)=="meat"){
    if(i>250000){
     errorMessage(sender,"Please contact bot Admin");
     return "x";
    }
    cli_execute("csend "+i+" to "+sender+" || "+to_string(my_meat()+my_closet_meat()-i)+" meat remains.");
   }else if(whitem!=$item[none]){
    i=min(item_amount(whitem),i);
    cli_execute("csend "+i+" "+whitem.to_string()+" to "+sender+" || "+to_string(item_amount(whitem)-i)+" remain.");
   }
   return "x";
  case "recheck":
   if((userdata[sender].flags&isAdmin)!=isAdmin){
    errorMessage(sender,"No, don't do that!");
    return "x";
   }
   chat("Looking for new test subjects and evaluating test data.");
   checkApps();
   checkMail();
   checkData();
   return "x";   
  case "roll":
   roll(sender,oper);
   return "x";
  case "search":
   search(sender,oper);
   return "x";
  case "su":
   if((userdata[trueUser].flags&isAdmin)!=isAdmin){
    errorMessage(trueUser,"No, don't do that!");
    return "x";
   }
   switch(oper){
    case "":
     modSessionVar(trueUser,"suser",".root");
     break;
    case "x":case "end":case "return":case "exit":
     modSessionVar(trueUser,"suser","");
     break;
    default:
     modSessionVar(trueUser,"suser",oper);    
   }
   return "x";
  case "sue":
   if((userdata[trueUser].flags&isAdmin)!=isAdmin){
    errorMessage(trueUser,"No, don't do that!");
    return "x";
   }
   switch(oper){
    case "hobopolis":case "hobo":case "hobop":case "h":
     modSessionVar(trueUser,"schannel","/hobopolis");
     break;
    case "slimetube":case "s":case "slime":case "st":case "tube":
     modSessionVar(trueUser,"schannel","/slimetube");
     break;
    case "haunted house":case "haunted":case "hh":
     modSessionVar(trueUser,"schannel","/hauntedhouse");
     break;
    case "return":case "exit":case "end":case "x":
     modSessionVar(trueUser,"schannel","");
     break;
    default:
     modSessionVar(trueUser,"schannel","/clan");
   }
   return "x";
  case "title":
   clanTitle(sender,oper);
   return "x";
  case "unwhitelist":
   if(getUF(sender,isAdmin))whitelistEdit("-"+oper);
   else chat("You must be an admin to UNwhitelist (ugh) people from clan.");
   return "x";
  case "wang":
   if(oper=="")oper=sender;
   if(is_online("wangbot")){
    chat("wangbot","target "+oper);
   }else{
    claimResource("adventuring");
    if(item_amount($item["WANG"])<1)cli_execute("stash take wang");
    string t=visit_url("curse.php?action=use&pwd&whichitem=625&targetplayer="+oper);
    freeResource("adventuring");
   }
   set_property("_lastWang",oper);
   return "x";
  case "whitelist":
   if(getUF(sender,isAdmin))whitelistEdit(oper);
   else chat("You must be an admin to whitelist people to clan.");
   return "x";
  case "whois":
   lookup(sender,oper);
   return "x";
  case "wiki":
   sendLink(sender,oper);
   return "x";
  case "withdraw":
   userAccountEmpty(sender);
   return "x";
 }
 return msg;
}

void nopredpass(string sender, string msg, boolean addressed){
 //print("yo");
 responses[string] botdata;
 update(botdata,"replies.txt");
 boolean foundmatch=false;
 boolean referred=addressed;
 matcher ref=create_matcher("(?i)(\\WOB\\W|\\WOminous Buffer\\W)",msg);
 if(ref.find())referred=true;
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
  if(((reply.flags&repFree)==0)&&(checkRep(testcase)<3)&&(checkRep(testcase)>-1))continue;
  if(((reply.flags&mustRefer)==mustRefer)&&(!referred))continue;
  if(((reply.flags&mustAddress)==mustAddress)&&(!addressed))continue;
  if(((reply.flags&fullText)==fullText)&&(msg!=testcase))continue;
  if(((reply.flags&caseSensitive)==caseSensitive)&&(!msg.contains_text(testcase)))continue;
  if(!msg.to_lower_case().contains_text(testcase.to_lower_case()))continue;
  foundmatch=true;
  if(replyParser(sender,reply.cond1)!=replyParser(sender,reply.cond2)){
   foundmatch=false;
   continue;
  }
  the_one=reply;
  break;
 }
 if(foundmatch){
  checkOut(userdata,"userdata.txt");
  userdata[sender].lastTrigger=th;
  userdata["*"].lastTrigger=th;
  addRep(th);
  commit(userdata,"userdata.txt");
  switch(the_one.method){
   case "say":chat(replyParser(sender,the_one.reply));
    break;
   case "do":chat("/em "+replyParser(sender,the_one.reply));
    break;
  }
 }
}

void setGender(string sender, string gender){
 int gval=2;
 matcher g=create_matcher("(?i)(WHO I AM|ME)",gender);
 if(g.find())gval=1;
 int tc=2;
 while(gval==2){
  tc+=1;
  if(tc>=count(genders)) break;
  if(!(genders[tc] contains 5)) continue;
  g=create_matcher("(?i)("+genders[tc,5]+")",gender);
  if(g.find()) gval=tc;
 }
 checkOut(userdata,"userdata.txt");
 userdata[sender].gender=gval;
 foreach m in userdata[sender].multis userdata[m].gender=gval;
 commit(userdata,"userdata.txt");
}

int timeSinceLastChat(string who){
 boolean useA=true;
 string lastSpeaker;
 if((ctimes.lastCA==who)||(ctimes.lastCB==who)){
  if(ctimes.lastCB==who)useA=false;
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
 if(ctimes.lastChatterA){
  ctimes.lastAh=nowH;
  ctimes.lastAm=nowM;
  ctimes.lastCA=who;
 }else{
  ctimes.lastBh=nowH;
  ctimes.lastBm=nowM;
  ctimes.lastCB=who;
 }
 ctimestamp[0]=ctimes;
 claimResource("timefile.txt");
 commit(ctimestamp,"timefile.txt");
 checkOut(userdata,"userdata.txt");
 userdata[who].lastTime=now_to_string("MMMM d, yyyy 'at' hh:mm:ss a z");
 commit(userdata,"userdata.txt");
 lastM=lastM+lastH*60;
 nowM=nowM+nowH*60;
 nowM-=lastM;
 if(nowM<0)nowM+=1440;
 if(nowM==1)return 0;
 return nowM;
}

boolean isMath(string m){
 matcher fix=create_matcher("(?i)(last|ans|floor|ceil|min|max|sqrt|pi|phi|e|sin|cos|tan|ln|log|fairy|hound|jack|jitb|lep|monkey|ant|cactus)",m);
 m=replace_all(fix,"+");
 fix=create_matcher("[^\\d\\s*+/.^,\\-()\\[\\]\\$]",m);
 if(fix.find())return false;
 return true;
}

boolean fancyMath(string sender, string equation){
 matcher dm=create_matcher("\\[(\\d*),(\\d*)\\]\\s?(.*)",equation);
 if(!dm.find())return false;
 float tmp=0;
 string mod;
 int low=dm.group(1).to_int();
 int high=dm.group(2).to_int();
 equation=dm.group(3);
 if(low>high){
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
 checkOut(userdata,"userdata.txt");
 userdata[sender].lastMath=tmp;
 userdata["*"].lastMath=tmp;
 commit(userdata,"userdata.txt");
 chat(tmp.to_string(8));
 return true;
}

boolean mathDot(string data, boolean cross){
 vector u;
 vector v;
 matcher m=create_matcher("<(.+?)>,?\\s?<(.+?)>",data);
 if(!m.find()) return false;
 u=m.group(1).to_vector();
 v=m.group(2).to_vector();
 string x;
 if(cross) x=u.cross(v).to_string(8);
 else x=u.dot(v).to_string(8);
 chat(x);
 return true;
}

boolean mathSTP(string data){
 vector a;
 vector b;
 vector c;
 matcher m=create_matcher("<(.+?)>\\s?<(.+?)>\\s?<(.+?)>",data);
 if(!m.find()) return false;
 a=m.group(1).to_vector();
 b=m.group(2).to_vector();
 c=m.group(3).to_vector();
 string x=a.dot(b.cross(c)).to_string(8);
 chat(x);
 return true;
}

void searchDefine(string word){
 matcher m=create_matcher("^([a-zA-Z ]+).?$",word);
 if(!m.find())return;
 word=m.group(1);
 string result=visit_url("http://dictionary.reference.com/browse/"+word.url_encode(),false,true);
 if(result.contains_text("- no dictionary results")||result.contains_text("because there's not a match on Dictionary.com")){
  chat("No definitions were found for "+word+".");
  return;
 }
 matcher temp;
 boolean[string] wts=$strings[noun,adjective,verb \\(used without object\\),verb \\(used with object\\),adverb,conjunction,preposition,pronoun];
 string[string,int] defn;
 foreach wordtype in wts{
  m=create_matcher("<div class=\"pbk\"><span class=\"pg\">?"+wordtype+" </span>[\\w\\W]+?</div></div>(</div>|<a class=\"less\">)",result);
  if(!m.find())continue;
  m=create_matcher("<div class=\"dndata\">(.+?)</div>",m.group(0));
  while(m.find()){
   temp=create_matcher("<div class=\"dndata\">(.+?)<",m.group(1));
   if(temp.find()) defn[wordtype,count(defn[wordtype])+1]=temp.group(1);
   else defn[wordtype,count(defn[wordtype])+1]=m.group(1);
  }
 }
print(count(defn));
 int totalitems=0;
 string bigjar;
 int c=0;
 int maxn=min(max(3,count(defn)),6);
 foreach wordtype in wts totalitems+=count(defn[wordtype]);
 while(totalitems>maxn){
  foreach wordtype in wts if(count(defn[wordtype])>=c){
   c=count(defn[wordtype]);
   bigjar=wordtype;
  }
  if(c==1)break;
  remove defn[bigjar,count(defn[bigjar])];
  c-=1;
  totalitems-=1;
 }
 foreach t,n,d in defn{
  m=create_matcher(": <span.+?</span>",d);
  d=m.replace_all(".");
  while(true){
   m=create_matcher("<span class=\"ital-inline\">(.+?)</span>",d);
   if(!m.find())break;
   d=m.replace_first("\""+m.group(1)+"\"");
  }
  while(true){
   m=create_matcher("<.+?>",d);
   if(!m.find())break;
   d=m.replace_first("");
  }
  m=create_matcher("[]",d);
  d=m.replace_all("\"");
  m=create_matcher("^\\((.+?)\\)\\.?$",d);
  if(m.find())d=m.group(1)+".";
  switch(t){
   case "noun":d="n- "+d;
    break;
   case "adjective":d="adj- "+d;
    break;
   case "verb \\(used without object\\)":
   case "verb \\(used with object\\)":d="v- "+d;
    break;
   case "adverb":d="adv- "+d;
    break;
   case "conjunction":d="conj- "+d;
    break;
   case "preposition":d="prep- "+d;
    break;
   case "pronoun":d="pro- "+d;
  }
  defn[t,n]=d;
 }
 foreach t,n,d in defn chat(d);
//foreach t,n,d in defn print(d);
}

void searchSpell(string word){
 matcher m=create_matcher("^([a-zA-Z ]+).?$",word);
 if(!m.find())return;
 word=m.group(1);
 string result=visit_url("http://dictionary.reference.com/browse/"+word.url_encode(),false,true);
 if(!(result.contains_text("- no dictionary results"))||(result.contains_text("because there's not a match on Dictionary.com"))){
  chat("Dictionary seems to think "+word+" is correct.");
  return;
 }
 m=create_matcher("Did you mean <a.+?>(.+?)</a>",result);
 if(!m.find()){
  chat("That's so far off, I don't even know what you're -trying- to spell.");
  return;
 }
 result=m.group(1);
 chat("Dictionary suggests \""+result+"\".");
}

void searchUrban(string word){
 matcher m;
 string result=visit_url("http://www.urbandictionary.com/define.php?term="+word.url_encode(),false,true);
 m=create_matcher("class=\"definition\">(.+?)</?[db]",result);
 if(!m.find()){
  chat("No definitions were found for "+word);
  return;
 }
 result=m.group(1);
 m=create_matcher("<a .+?>(.+?)</a>",result);
 while(m.find()){
  result=replace_all(m,m.group(1));
  m=create_matcher("<a .+?>(.+?)</a>",result);   
 }
 chat(result.decodeHTML(false));
}

void publicChat(string sender, string msg){
 matcher m;
 string original=msg;
 chatVars["timedif"]=timeSinceLastChat(sender).to_string();
 chatVars["time"]=now_to_string("HH:mm:ss z");
 boolean addressed=false;
 boolean referred=false;
 m=create_matcher("(?i)(^|\\. ?)(ominous buffer|ob)[:,]\\s?",msg);
 if(m.find()){
  addressed=true;
  msg=substring(msg,end(m));
 }
 m=create_matcher("(?i)(ominous buffer|\\Wob\\W)",msg);
 if(m.find())referred=true;
 if(impliedOB)addressed=true;
 m=create_matcher("([\\w\\d]*):?\\s?(.*)",msg);
 string pred;
 string oper;
 if(m.find()){
  pred=m.group(1);
  oper=m.group(2);
 }
 for i from 2 upto count(genders)-1 if(genders[i] contains 5)genderMatcherString+="|"+genders[i,5];
 genderMatcherString+=")";
 if(!addressed) m=create_matcher(genderMatcherString,msg);
 else m=create_matcher("(?i)"+genderMatcherString,msg);
 if(m.find()){
  print("Gender set for "+sender,"blue");
  setGender(sender,m.group(1));
  return;
 }
 m=create_matcher("(?i)(call me|am also known as|i go by)\\s([\\w ']*)",msg);
 if(m.find()&&(referred||addressed)){
  setNick(sender,m.group(2));
  return;
 }
 if(addressed&&isMath(msg)){
  msg=performMath(sender,msg);
  checkOut(userdata,"userdata.txt");
  userdata["*"].lastMath=userdata[sender].lastMath;
  commit(userdata,"userdata.txt");
  chat(msg);
  return;
 }
 switch(pred){
  case "choose":
  case "pick":
   if(checkRep(pred+oper)>-1)return;
   addRep(pred+":"+oper);
   if(addressed) pick(oper);
   return;
  case "cross":
   if(mathDot(oper,true))return;
   break;
  case "define":
   if(checkRep(pred+oper)>-1)return;
   addRep(pred+":"+oper);
   searchDefine(oper);
   return;
  case "dot":
   if(mathDot(oper,false))return;
   break;
  case "echo":
   if(addressed)chat(replyParser(sender,oper));
   return;
  case "fact":
   if(addressed)fact();
   return;
  case "market":
   analyze_md("!","link "+oper);
   return;
  case "roll":
   if(addressed)roll(sender,oper);
   return;
  case "spell":
   if(checkRep(pred+oper)>-1)return;
   addRep(pred+":"+oper);
   if(addressed)searchSpell(oper);
   return;
  case "stp":
   if(mathSTP(oper))return;
   break;
  case "sum":
   if(addressed)fancyMath(sender,oper);
   return;
  case "urban":
   if(checkRep(pred+oper)>-1)return;
   addRep(pred+":"+oper);
   if(addressed)searchUrban(oper);
   return;
 }
 nopredpass(sender,original,addressed);
 return;
}

void systemHandler(string msg){
 prefix=":";
}

void clanHandler(string sender, string msg){
 prefix="";
 switch(gameType()){
  case gameRoulette:
   russianRoulette(sender,msg);
   return;
  default:
   publicChat(sender,msg);
   return;
 }
}

void slimetubeHandler(string sender, string msg){
 if(sender=="Dungeon")return;
 prefix="/slimetube ";
 publicChat(sender,msg);
}

void hobopolisHandler(string sender, string msg){
 if(sender=="Dungeon")return;
 prefix="/hobo ";
 publicChat(sender,msg);
}

void hauntedhouseHandler(string sender, string msg){
 if(sender=="Dungeon")return;
 prefix="/hauntedhouse ";
 publicChat(sender,msg);
}

void privateHandler(string sender, string msg){
 if(sender=="Ominous Buffer")systemHandler(msg);
 if(sender=="MesaChat"){
  matcher m=create_matcher("([a-zA-Z][\\w ]{1,29}):\\s?(.*)",msg);
  if(m.find()){
   sender=m.group(1);
   msg=m.group(2);
   clanHandler(sender,msg);
  }
  return;
 }
 if(!buffable(sender))return;
 prefix=sender;
 if(msg.char_at(0)=="!"){
  errorMsg=false;
  if(length(msg)>1)msg=substring(msg,1);
 }
 if(getUF(sender,noFlag))errorMsg=false;
 if(gameType()==gameWordshot)msg=wordshot(sender,msg);
 if(msg=="x")return;
 msg=chatFilter(sender,msg);
 if(msg=="x")return;
 msg=predicateFilter(sender,msg);
 if(msg=="x")return;
 if((sender==turt_name)||(sender==sauc_name)){
  buff(sender,msg,0,sender);
  return;
 }
 if((sender=="chatbot")||(sender==my_name()))return;
 matcher m=create_matcher("buff ([a-zA-Z][a-zA-Z 0-9']*) with (.*)",msg.to_lower_case());
 string co=sender;
 if(m.find()){
  sender=m.group(1);
  msg=m.group(2);
 }
 int turnR=0;
 m=create_matcher("[\;,]+",msg);
 msg=replace_all(m,"\;");
 string[int] messages=split_string(msg,"\;");
 int multiplier=0;
 foreach i in messages{
  turnR=0;
  m=create_matcher("(\\d+):(.*)",messages[i]);
  if(m.find()){
   multiplier=m.group(1).to_int();
   messages[i]=m.group(2);
  }
  m=create_matcher("(\\d+)",messages[i]);
  if(m.find()){
   if(to_float(m.group(1))>1000)turnR=1000;
   else turnR=to_int(m.group(1));
  }//why not "[a-zA-Z][\\s\\w']*[a-zA-Z]"
  m=create_matcher("[a-zA-Z\\?](?:[a-zA-Z']|(?:\\s(?=\\w)))*",messages[i]);
  if(m.find())messages[i]=m.group(0);
  if(multiplier==0)buff(sender,messages[i],turnR,co);
  else if(turnR==0)buff(sender,messages[i],multiplier,co);
  else buff(sender,messages[i],multiplier*turnR,co);
 }
}

boolean preHandled(string sender, string msg, string channel){
 if(!couldClaim("science")){
  if(channel=="")chat(sender,"You've got no use chatting, I've got science to do.");
  return true;
 }
 if(sender=="faxbot"){
  if(msg.contains_text("help"))chat(get_property("_lastFax"),"Faxbot doesn't have that monster.");
  else chat(get_property("_lastFax"),msg);
  return true;
 }
 if(sender=="wangbot"){
  if(msg.contains_text("dried out")){
   claimResource("adventuring");
   if(item_amount($item["WANG"])<1)cli_execute("stash take wang");
   string t=visit_url("curse.php?action=use&pwd&whichitem=625&targetplayer="+get_property("_lastWang"));
   freeResource("adventuring");
  }
  return true;
 }
 if((sender=="MesaChat")&&(channel!=""))return true;
 if((sender==my_name())&&(channel!=""))return true;
 return false;
}

string applySUE(string sender,string channel){
 if(channel!="")return sender;
 trueUser=sender;
 string s=getSessionVar(sender,"suser");
 if(s=="")return sender;
 else if(s==".root")return sender;
 return s;
}

string applySUE(string channel){
 if(channel!="")return channel;
 impliedOB=true;
 trueChannel=channel;
 string s=getSessionVar(trueUser,"schannel");
 if(s=="")return channel;
 return s;
}

//CHANNELS: private,    clan,   DUNGEON
//IN:       ""          "/clan" "/DUNGEON"
//OUT:      name        ""      "/DUNGEON "
void main(string sender, string msg, string channel){try{
 if(preHandled(sender,msg,channel))return;
 sender=sender.applySUE(channel);
 msg=msg.decodeHTML(true);
 channel=channel.applySUE();
 switch(channel){
  case "/clan":
   clanHandler(sender,msg);
   break;
  case "/slimetube":
   slimetubeHandler(sender,msg);
   break;
  case "/hobopolis":
   hobopolisHandler(sender,msg);
   break;
  case "/hauntedhouse":
   hauntedhouseHandler(sender,msg);
   break;
  default:
   privateHandler(sender,msg);
   break;
 }
}finally{
 releaseResources();
}}