import <shared.ash>
import <market.ash>
import <mathlib.ash>
string[int] to_array(boolean[string] data){
 string[int] x;
 foreach y in data
  x[count(x)]=y;
 return x;
}
static{
 boolean[string]doubleRun;
}
string genderMatcherString="(?:I AM|I'M) (?:AN |A )?(WHO I AM|ME";
string[string,int] genders;
genders["list"]=to_array($strings[genders, third, unknown, androgynous, male, female, inanimate]);
genders["third"]=to_array($strings[*]);//WHO I AM
genders["unknown"]=to_array($strings[he, him, himself, his, his]);
genders["androgynous"]=to_array($strings[they, them, themselves, theirs, their, ANGROGYNOUS|PLURAL|HERMAPHRODITE]);
genders["male"]=to_array($strings[he, him, himself, his, his, BOY|MAN|MALE|HE|HIM|GUY|DUDE]);
genders["female"]=to_array($strings[she, her, herself, hers, her, GIRL|WOMAN|FEMALE|SHE|HER|GAL|LADY]);
genders["inanimate"]=to_array($strings[it, it, itself, its, its, IT|INANIMATE|NEUTRAL|GENDERLESS|ALIEN|(?:RO)?BOT]);
//Pronouns: subjective, objective, reflexive, possessive pronoun, possessive determiner. Optionally: Match string text
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
int caseSensitive=1;//c
int fullText=2;     //e
int mustAddress=4;  //~default, disable with i
int mustRefer=8;    //r
int repFree=16;     //f
int noPartials=32;  //p

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
checkOut(ctimestamp,"timefile.txt");
timestamp ctimes=ctimestamp[0];
checkOut(userdata,"userdata.txt");

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
boolean silent=true;

string glitch(string s){
 buffer b;
 matcher m;
 m=create_matcher("12",s);
 while(m.find()){
  if(random(100)<25){
   switch(random(5)){
    case 0: m.append_replacement(b,"TWELVE");
     break;
    case 1: m.append_replacement(b,"tWeLve");
     break;
    case 2: m.append_replacement(b,"twlv");
     break;
    case 3: m.append_replacement(b,"twelve");
     break;
    case 4: m.append_replacement(b,"XII");
     break;
   }
  }else m.append_replacement(b,"12");
 }
 m.append_tail(b);
 s=b.to_string();
 b.delete(0,length(b));
 m=create_matcher("I",s);
 while(m.find())if(random(1000)<35)m.append_replacement(b,"i");
  else m.append_replacement(b,m.group(0));
 m.append_tail(b);
 s=b.to_string();
 return s;
}

void chat(){
 silent=false;
 if((prefix=="")||(prefix.char_at(0)=="/")){
  chat_clan(prefix+response.glitch());
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
 chat_private(prefix,response.glitch());
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

void maybeFact(){
 if(random(1500)==0)chat(factCore());
}

string genderPronoun(string who, int type){
 string g=sysString(who,"gender");
 string reply;
 if(g!="third")reply=genders[g,type];
 else{
  reply=(userdata[who] contains "nick"?userdata[who,"nick"]:who);
  if(type>2)reply+="'s";
 }
 return reply;
}

string genderPronoun(string who, string type){
 string reply=who;
 boolean cap=false;
 if(type.contains_text("P")||type.contains_text("S"))cap=true;
 type=substring(type,1);
 switch(type){
  case "sub":reply=genderPronoun(who,gSub);
  case "obj":reply=genderPronoun(who,gObj);
  case "ref":reply=genderPronoun(who,gRefl);
  case "pos":reply=genderPronoun(who,gPosPro);
  case "det":reply=genderPronoun(who,gPosDet);
 }
 if(cap)reply=reply.char_at(0).to_upper_case()+reply.substring(1);
 return reply;
}

string genderString(string who){
 if(userdata[who] contains "gender")return userdata[who,"gender"];
 return defaultProp("gender");
}

void errorMessage(string who, string what){
 matcher mx=create_matcher("(?i)(\\$psub|\\$pobj|\\$pref|\\$ppos|\\&pdet)",what);
 while(mx.find()){
  what=mx.replace_first(genderPronoun(who,mx.group(1)));
  mx=mx.reset(what);
 }
 if(errorMsg)chat(who,what);
}

boolean buffable(string sender){
 if(hasProp(sender,"ID#",",0"))updateId(sender,true);
 if(hasProp(sender,"membership","blacklist")){
  chat(sender,"We do what we must because we can. For the good of all of us. Except the ones who are blacklisted from Black Mesa.");
  return false;
 }
 return true;
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
 if(!getUF(sender,"admin")){
  chat(sender,"You do not have permission to use this command.");
  return;
 }
 if(options=="all"){
  chat_private(turtleBot,"logout");
  chat_private(sauceBot,"logout");
 }
 saveSettings(earlySave);
 set_property("chatbotScript","");
 cli_execute("exit");
}

void shutdown(string sender,string options){
 if(!getUF(sender,"admin")){
  chat(sender,"Haha, did you think it would be that easy?");
  return;
 }
 if(options.contains_text("all")){
  if(options.contains_text("burn")){
   chat_private(turtleBot,"burn");
   chat_private(sauceBot,"burn");
  }else{
   chat_private(turtleBot,"shutdown");
   chat_private(sauceBot,"shutdown");
  }
 }
 if(options.contains_text("burn"))set_property("_forceShutdown","burn");
 else set_property("_forceShutdown","shutdown");
}

void createAlias(string sender, string msg){
 matcher namem=create_matcher("(\\w*)\\s?(.*)",msg);
 string aliasname;
 string expansion;
 if(namem.find()){
  aliasname=namem.group(1);
  expansion=namem.group(2);
 }else{
  chat(sender,"You must supply the appropriate data for us to save that.");
  return;
 }
 int c=0;
 foreach a in userdata["*"] if(a.char_at(0)=="~")c+=1;
 if((c>36)&&(!(userdata[sender] contains ("~"+aliasname)))){
  chat(sender,"You already have 37 aliases (in a row!?), try not to make an alias on your way through the parking lot.");
  return;
 }
 checkOut(userdata,"userdata.txt");
 userdata[sender,"~"+aliasname]=expansion;
 commit(userdata,"userdata.txt");
 chat(sender,"Your alias has been saved: "+aliasname+" => "+expansion);
}

void removeAlias(string sender, string aliasname){
 checkOut(userdata,"userdata.txt");
 string s=remove userdata[sender,"~"+aliasname];
 commit(userdata,"userdata.txt");
 if(s!="")chat(sender,"Alias removed.");
}

boolean sendRecord(int skillId, string sender){
 item recording=to_item("recording of "+skillId.to_skill().to_string());
 if(item_amount(recording)<1) return false;
 cli_execute("csend 1 "+recording.to_string()+" to "+sender+" ||");
 return true;
}

void buff(string sender, string msg, int numTurns, string ding){
 //Catch incoming error messages (success in the case of Employee of the Month) from other Bots
 if((sender==turtleBot)||(sender==sauceBot)){
  string[int] failsplit = split_string(msg,"\\s");
  if(index_of("ARLNS",failsplit[0])>-1){
   sender=to_playerName(failsplit[1].to_int());
   ding=to_playerName(failsplit[2].to_int());
  }
  switch(failsplit[0]){
   case "CASTRQ":
    if(sender==turtleBot)set_property('tamerCasts',failsplit[1]);
    if(sender==sauceBot)set_property('sauceCasts',failsplit[1]);
    break;
   case "RATION":switch(failsplit[1]){
    case "ITEM":
     use_skill(12,$skill[fat leon's phat loot lyric],sender);
     break;
    case "MEAT":
     use_skill(12,$skill[the polka of plenty],sender);
     break;
    case "NONCOMBAT":
     use_skill(12,$skill[carlweather's cantata of confrontation],sender);
     break;
    }
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
   case "U":
    errorMessage(sender,"Unknown error. Must be a problem with the lesser bots.");
    break;
   case "L":
    errorMessage(failsplit[2],"I'm sorry, but you've reached your daily limit for "+failsplit[3].to_int().to_skill().to_string()+".");
    break;
   case "N":
    errorMessage(failsplit[2],"The cake is a lie. So is that thing you asked for, since it wasn't a buff.");
    break;
   case "S":
    checkOut(userdata,"userdata.txt");
    sysInc(ding,"#"+failsplit[3]);
    sysInc("#"+failsplit[3]);
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
 int max=700;
 if(userdata[ding,"membership"]=="none")max=400;
 int skillnum=to_int(messageNew);
 if(skillnum>9000){
  skillnum-=9000;
  skillnum=(skillnum/100)*1000+skillnum-((skillnum/100)*100);
 }
 switch(skillnum){
  case 1:case 3:case 12:case 15:case 19:
  case 46:case 47:case 48:case 58:case 59:case 60:
  case 7040:case 7041:case 6037:case 6040: return;
 }
 //Forward skill requests to relay bots when necessary
 string senderid=getId(sender);
 string mout;
 if(skillnum==62){
  numTurns=1;
  mout=senderid+" "+getId(ding)+" 62 1 1";
  switch(sysInt("#62")){
   case 1:
    chat_private(turtleBot,mout);
    return;
   case 2:
    chat_private(sauceBot,mout);
    return;
   case 3:
    errorMessage(sender,"I'm sorry, but I'm all out of "+messageNew+" for today.");
    return;
  }
 }
 //Assign default values if turns isn't specified.
 if(skillnum==6014)numTurns=TPC;//Ode
 if(numTurns==0){
  if(skillnum==6026)numTurns=125;//Donho
  else if(((skillnum>6019)&&(skillnum<6025))||(skillnum==6028))numTurns=25;//Limited buffs
  else if(skillnum!=6014){//Else
   if(hasProp(sender,"defaultCast",",0"))userdata[sender,"defaultCast"]=200;
   numTurns=userdata[sender,"defaultCast"].to_int();
  }
 }
 mout=senderid+" "+getId(ding)+" "+to_string(skillnum)+" "+to_string(numTurns)+" "+(getUF(ding,"buffLimit")?to_string(max):"0");
 if((skillnum>2000)&&(skillnum<3000)){
  chat_private(turtleBot,mout);
  return;
 }
 if((skillnum>4000)&&(skillnum<5000)){
  chat_private(sauceBot,mout);
  return;
 }
 casts=ceil(numTurns/(TPC*1.0));
 //Assign buff limits by clan.
 if(userdata[ding,"membership"]!="none"){
  if(((skillnum>6019) && (skillnum<6025)) || (skillnum==6028))max=1;//Limited buffs
  else if(skillnum==6014)max=5;//Ode
  else if(skillnum==6026)max=20;//Donho
  else if(skillnum>6900)max=1;//Items (arrow and the like)
  else max=28;//Else
 }else{
  if(((skillnum>6019) && (skillnum<6025)) || (skillnum==6028))max=1;
  else if(skillnum==6014)max=5;
  else if(skillnum==6026)max=10;
  else if(skillnum>6900)max=1;//Item skills
  else max=16;
 }
 casts=min(casts,max);
 //Adjust casts to be within limits
 if(getUF(ding,"buffLimit")&&(userdata[ding] contains ("#"+skillnum))
  &&(casts+sysInt(ding,"#"+skillnum))>max)casts=max-sysInt(ding,"#"+skillnum);
 if(casts==0){
  errorMessage(ding,"I'm sorry, but you've reached your daily limit for that buff.");
  return;
 }
 //Quick check to see if limited buffs still available
 int maxnum=999999;
 if((skillnum>6019)&&(skillnum<6025))maxnum=10;
 else if(skillnum==6026)maxnum=50;
 else if(skillnum==6028)maxnum=5;
 if((skillnum>6019)&&(skillnum<6029)){
  if(maxnum-sysInt("#"+skillnum)<1){
   if(sendRecord(skillnum,sender)){
    checkOut(userdata,"userdata.txt");
    sysInc(ding,"#"+skillnum);
    sysInc("#"+skillnum);
    commit(userdata,"userdata.txt");
   }else errorMessage(ding,"I'm sorry, but I'm all out of "+messageNew+" for today.");
   return;
  }//balance if not enough to meet request
  if(maxnum-sysInt("#"+skillnum)<casts) casts=maxnum-sysInt("#"+skillnum);
 }
 //This is the actual casting function.
 if(skillnum==6901){
  if(item_amount($item[time's arrow])<1)retrieve_item(1,$item[time's arrow]);
  if(item_amount($item[time's arrow])<1){
   chat(ding,"Currently out of Time's Arrows. Looks like you're out of luck.");
   return;
  }
  string t=visit_url("curse.php?action=use&pwd="+my_hash()+"&whichitem=4939&targetplayer="+sender);
  print("Throwing Time's Arrow at "+sender);
  checkOut(userdata,"userdata.txt");
  sysInc(ding,"#"+skillnum);
  commit(userdata,"userdata.txt");
  return;
 }
 checkOut(userdata,"userdata.txt");
 if(have_skill(to_skill(skillnum))){
  if(use_skill(casts,to_skill(skillnum),sender)){
   int totCastsE=get_property('totalCastsEver').to_int()+casts;
   set_property('totalCastsEver',totCastsE.to_string());
   sysInc(ding,"#"+skillnum,casts);
   sysInc("#"+skillnum,casts);
   commit(userdata,"userdata.txt");
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
   case "Selected target has the maximum number of AT buffs already.":
    errorMessage(sender,"You have too many songs in your head.");
    break;
   default:
    errorMessage(sender,"Unknown Error: '"+last_skill_message()+"'");
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
  if(item_amount($item[magical mystery juice])<1)retrieve_item(1,$item[magical mystery juice]);
  use(1,$item[magical mystery juice]);
 }
 commit(userdata,"userdata.txt");
}

int roll(string sender, string msg){
 matcher m=create_matcher("(\\d+)?[dD](\\d+)",msg);
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
 if(prefix=="")chat("/em rolls "+running+" for "+(userdata[sender,"nick"]!=""?userdata[sender,"nick"]:sender)+" ("+m.group(1)+"d"+m.group(2)+").");
 else chat("Rolling "+m.group(1)+"d"+m.group(2)+" gives "+running+".");
 return running;
}

void startGame(string sender, string msg){
 gameData game;
 if(gameType()!=gameNone){
  game=loadGame();
  if((msg=="cancel")||(msg=="stop")){
   if((sender==game.host)||getUF(sender,"admin")){
    closeGame();
    chat(sender,"Game canceled");
    chat("","You must all be orphans, not even the host of the game loved you long enough to finish. Game canceled.");
   }else chat(sender,"You don't have permission to do that.");
  }else chat(sender,"A game is already in session by "+game.host+".");
  return;
 }
 matcher m=create_matcher("(?i)(wordshot|RR|russian roulette|russianroulette|hangman)\\s?(\\d+|[A-Za-z'\\s]+)?",msg);
 if(!m.find())return;
 string t=m.group(1);
 string l="-";
 if(m.group_count()>1)l=m.group(2);
 switch(t){
  case "hangman":
   startHangman(l,sender);
   game=loadGame();
   if((l.to_int()!=0)||(l.char_at(0)=="0")){
    print("Invalid: "+l);
    closeGame();
    break;
   }
   chat(sender,"Game started.");
   chat("","Hangman time!");
   chat(game.data[1]);
   break;
  case "wordshot":
   startWordshot(l.to_int(),sender);
   game=loadGame();
   string w;
   foreach k,v in game.players if(v==1) w=k;
   if((l.to_int()==0)&&(l!="-")&&(l.length()>2)&&(l.length()<14)){
    boolean[string]list;
    checkOut(list,"wordshot/"+l.length()+".txt");
    int[string] koldict;
    checkOut(koldict,"wordshot/custom.txt");
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
 chat(factCore());
}

void mod(string sender, string msg){
 boolean adminonly=getUF(sender,"admin");
 if(sender==my_name())adminonly=true;
 matcher m=create_matcher("(.*)[., ;]*\\|\\|\\s*(.*)",msg);
 string cmd=msg;
 string user=sender;
 if(m.find()){
  cmd=m.group(1);
  user=m.group(2);
 }
 if(!adminonly)user=sender;
 m=create_matcher("[., ;]+",cmd);
 cmd=replace_all(m," ");
 string[int]cmds=split_string(cmd," ");
 checkOut(userdata,"userdata.txt");
 string val;
 foreach i,tcmd in cmds{
  m=create_matcher("(.+?)=(.*)",tcmd);
  if(m.find()){
   cmd=m.group(1);
   val=m.group(2);
  }else{
   cmd=tcmd;
   val="0";
  }
  switch(cmd){
   case "noLimit":
    if(adminonly){
     userdata[user,"buffLimit"]="false";
     chat(sender,user+" has had "+genderPronoun(user,gPosDet)+" limit lifted.");
    }else errorMessage(sender,"You do not have permissions to use "+cmd+".");
    break;
   case "limit":
    if(adminonly){
     userdata[user,"buffLimit"]="true";
     chat(sender,user+" has had "+genderPronoun(user,gPosDet)+" limit re-imposed.");
    }else errorMessage(sender,"You do not have permissions to use "+cmd+".");
    break;
   case "nowarning":
    userdata[user,"errors"]="false";
    chat(sender,user+"\'s warnings disabled.");
    break;
   case "default":
    userdata[user,"defaultCast"]=val.to_int().to_string();
    chat(sender,user+"\'s default cast amount set to "+val);
    break;
   case "warning":
    userdata[user,"errors"]="true";
    chat(sender,user+"\'s warnings enabled.");
    break;
   case "clear":
    defaultProp(user,"ID#");
    defaultProp(user,"membership");
    chat(sender,"Clan Status cleared for "+user+".");
    break;
   case "add":
    if(adminonly){
     userdata[user,"admin"]="true";
     chat(sender,user+" has been given administrative permissions.");
    }else errorMessage(sender,"You do not have permission to use "+cmd+".");
    break;
   case "remove":
    if(adminonly){
     userdata[user,"admin"]="false";
     chat(sender,user+" is no longer an administrator.");
    }else errorMessage(sender,"You do not have permission to use "+cmd+".");
    break;
   case "whitelist":case "wl":
    if(adminonly){
     updateId(user,true);
     userdata[user,"membership"]="whitelist";
     chat(sender,user+" has been whitelisted to OB.");
    }else errorMessage(sender,"You do not have permission to use "+cmd+".");
    break;
   case "blacklist":
    if(adminonly){
     updateId(user,true);
     userdata[user,"membership"]="blacklist";
     chat(sender,user+" has been blacklisted from OB.");
    }else errorMessage(sender,"You do not have permission to use "+cmd+".");
    break;
   case "reset":
    if(adminonly){
     defaultProp(user,"membership");
     defaultProp(user,"ID#");
     updateId(user,true);
     chat(sender,user+" has had "+genderPronoun(user,gPosDet)+" settings cleared.");
    }else errorMessage(sender,"You do not have permission to use "+cmd+".");
    break;
   default:
    errorMessage(sender,cmd+" seems to be an invalid command.");
    break;
  }
 }
 commit(userdata,"userdata.txt");
}

void fax(string sender, string msg){
 string[string] m;
 checkOut(m,"faxnames.txt");
 m["Hobelf"]="hobo_elf";
 m["Elf hobo"]="bathroom_elf";
 switch(msg){
  case "lfm":
   msg="lobsterfrogman";
   break;
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
 }
 string nm=m[msg.to_monster().to_string()];
 if(nm=="")foreach name in m if(name.contains_text(msg)){
  nm=m[name];
  break;
 }
 if(nm==""){
  chat(sender,"My database couldn't make a direct match for that, so I'll send it straight to faxbot as is.");
  nm=msg;
 }
 print("Requesting "+msg+" ("+nm+") from FaxBot.");
 chat_private("FaxBot",nm);
}

void updateRaidlog(){
 if(raidlogRead)return;
 string v=visit_url("clan_raidlogs.php");
 matcher mx=create_matcher("opened (a|\\d+) sewer grate",v);
 int turned=0;
 while(mx.find())if(mx.group(1)=="a")turned+=1;
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
  if(count(inClan)>2)rng=random(count(inClan)-1);
  int c=0;
  foreach clannie in inClan{
   if(clannie==sender) continue;
   someoneDefined=clannie;
   c+=1;
   if(c>rng) break;
  }
 }
 if(someoneDefined!="")someone=someoneDefined;
 if(hasProp(someone,"ID#",",0"))updateId(someone,true);
 if(hasProp(sender,"ID#",",0"))updateId(sender,true);
 if(hasProp(someone,"gender",",0,?"))defaultProp(someone,"gender");
 if(hasProp(sender,"gender",",0,?"))defaultProp(sender,"gender");
 string[string] randplayer=userdata[someone];
 string[string] thesender=userdata[sender];
 string pclass;
 string sclass;
 variable=create_matcher("(?i)class",msg);
 if(variable.find()){
  temp=visit_url("showplayer.php?who="+randplayer["ID#"]);
  variable=create_matcher("Class:</b></td><td>(.+?)<",temp);
  if(variable.find())sclass=variable.group(1);
  temp=visit_url("showplayer.php?who="+thesender["ID#"]);
  variable=create_matcher("Class:</b></td><td>(.+?)<",temp);
  if(variable.find())pclass=variable.group(1);
 }
 if(!(thesender contains "nick"))thesender["nick"]=sender;
 if(!(randplayer contains "nick"))randplayer["nick"]=someone;
 variable=create_matcher("(?<!\\\\)\\$(\\w*)(\\([\\w\\s]*\\))?",msg);
 while(variable.find()){
  switch(variable.group(1)){
   case "someone":
   case "sname":
    msg=replace_first(variable,someone);
    break;
   case "snick":
   case "sshort":
    msg=replace_first(variable,randplayer["nick"]);
    break;
   case "ssub":
   case "sobj":
   case "sref":
   case "spos":
   case "sdet":
    msg=replace_first(variable,genderPronoun(someone,variable.group(1)));
    break;
   case "sgender":
    msg=replace_first(variable,genderString(someone));
    break;
   case "strigger":
    msg=replace_first(variable,randplayer["lastTrigger"]);
    break;
   case "sresult":
   case "smath":
   case "sans":
    temp=randplayer["lastMath"];
    if(randplayer["lastMath"].to_int()==randplayer["lastMath"].to_float())temp=randplayer["lastMath"].to_int().to_string();
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
    msg=replace_first(variable,thesender["nick"]);
    break;
   case "psub":
   case "pobj":
   case "pref":
   case "ppos":
   case "pdet":
    msg=replace_first(variable,genderPronoun(sender,variable.group(1)));
    break;
   case "pgender":
    msg=replace_first(variable,genderString(sender));
    break;
   case "ptrigger":
    msg=replace_first(variable,thesender["lastTrigger"]);
    break;
   case "presult":
   case "pmath":
   case "pans":
    temp=thesender["lastMath"];
    if(thesender["lastMath"].to_int()==thesender["lastMath"].to_float())temp=thesender["lastMath"].to_int().to_string();
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
   case "ans":
    temp=userdata["*","lastMath"];
    if(userdata["*","lastMath"].to_int()==userdata["*","lastMath"].to_float())temp=userdata["*","lastMath"].to_int().to_string();
    msg=replace_first(variable,temp);
    break;
   case "trigger":
    msg=replace_first(variable,userdata["*","lastTrigger"]);
    break;
   case "lotto":
    int[string] books;
    checkOut(books,"books.txt");
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
   case "fact":
    if(sender.getUF("admin")){
     if(variable.group_count()>1)i=variable.group(2).to_int();
     msg=replace_first(variable,factCore("F",i));
     break;
    }
    msg=replace_first(variable,variable.group(1));
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

void train(string trainer, string msg){
 string[int,string] changes;
 checkOut(changes,"changes.txt");
 changes[count(changes),trainer]=msg;
 responses[string] botdata;
 checkOut(botdata,"replies.txt");
 responses newr;
 newr.flags=mustAddress;
 string trig;
 matcher ff=create_matcher("\\s?(?<!\\\\)\\[(\\w*)(?<!\\\\)]\\s?",msg);
 if(ff.find()){
  if(ff.group(1).contains_text("e"))newr.flags=fullText&(~mustAddress);
  if(ff.group(1).contains_text("r"))newr.flags=mustRefer&(~mustAddress);
  if(ff.group(1).contains_text("a"))newr.flags=(fullText|caseSensitive)&(~mustAddress);
  if(ff.group(1).contains_text("i"))newr.flags&=~mustAddress;
  if(ff.group(1).contains_text("c"))newr.flags|=caseSensitive;
  if(ff.group(1).contains_text("p"))newr.flags|=noPartials;
  if((ff.group(1).contains_text("f"))&&(getUF(trainer,"admin")))newr.flags|=repFree;
  msg=replace_first(ff,"");
 }
 ff=create_matcher("\\s?(?<!\\\\)::(.+?)=(.+?)::\\s?",msg);
 if(ff.find()){
  newr.cond1=ff.group(1);
  newr.cond2=ff.group(2);
  msg=replace_first(ff,"");
 }
 ff=create_matcher("(.+?)\\s?(?<!\\\\)<(\\w*?)(?<!\\\\)>\\s?(.*)",msg);
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
 checkOut(botdata,"replies.txt");
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
   commit(changes,"changes.txt");
   break;
 }
}

void lookup(string sender, string who){
 who=who.to_lower_case();
 string reply="";
 boolean[string] covered;
 int yetfound=0;
 string[int] alts;
 foreach user in userdata{
  yetfound=0;
  if(userdata[user,"nick"].to_lower_case().contains_text(who)){
   yetfound=2;
   reply+=user+" goes by "+userdata[user,"nick"];
  }
  if(user.to_lower_case().contains_text(who)&&(yetfound==0)){
   yetfound=1;
   reply+=user;
  }
  alts=split_string(userdata[user,"alts"],",");
  foreach i,name in alts if(name.to_lower_case().contains_text(who)){
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
 if(reply=="")reply="No matches found for "+who;
 if(length(reply)<151)chat(sender,reply);
 else{
  matcher m=create_matcher("\\. ",reply);
  reply=replace_all(m,".\n");
  cli_execute("csend to "+sender+"||"+reply);
 }
}

void multilookup(string sender, string who){
 string reply="";
 if(userdata contains who){
  if(userdata["who"] contains "alts")reply=who+" is a known alt of the following users: "+replace_string(userdata[who,"alts"],",",", ").to_string();
  else reply="No known multis for "+who+"  ";
 }else reply="No matches found for "+who+"  ";
 reply=substring(reply,0,length(reply)-2)+".";
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
  if(userdata[who] contains "alts"){
   reply+="Known Multis: "+replace_string(userdata[who,"alts"],",",", ").to_string();
   reply=substring(reply,0,length(reply)-2)+".\n";
  }
  if(!hasProp(who,"nick",","+who))reply+="Goes by: "+userdata[who,"nick"]+"\n";
  reply+="Gender: "+genderString(who)+"\n";
  if(userdata[who,"lastTime"]!="")reply+="Last Time Spoken: "+userdata[who,"lastTime"]+"\n";
  boolean f=true;
  if(who==sender)foreach a,v in userdata[who] if(a.char_at(0)=="~"){
   if(f){
    f=false;
    reply+="Aliases Defined:\n";
   }
   reply+="-"+a.substring(1)+": "+v+".\n";
  }
  if(sysInt(who,"donated")>0)reply+="Donated: "+userdata[who,"donated"]+" meat.\n";
  if(who==sender){
   if(userdata[who,"meat"].to_int()>0)reply+="Bank: "+userdata[who,"meat"]+" meat.\n";
   if(userdata[who,"defaultCast"].to_int()>0)reply+="Default Casts: "+userdata[who,"defaultCast"]+"\n";
  }
  cli_execute("csend to "+sender+"||"+reply);
 }else chat(sender,"No match found for "+who+".");
}

void userAccountEmpty(string w){
 if(sysInt(w,"meat")<1){
  errorMessage(w,"You don't have sufficient funds to withdraw.");
  return;
 }
 if(kmail(w,"Your balance in full.",sysInt(w,"meat"))!=1){
  errorMessage(w,"Error sending meat, try again later, preferably out of ronin/HC.");
  return;
 }
 checkOut(userdata,"userdata.txt");
 userdata[w,"meat"]="";
 commit(userdata,"userdata.txt");
}

string addMulti(string n1, string n2){
 string ncarry="";
 string gencarry="";
 string[int]splitter;
 print("Multi added for "+n1,"blue");
 boolean[string] bigList;
 splitter=split_string(userdata[n1,"alts"],",");
 foreach i,s in splitter if(s!="")bigList[s]=true;
 splitter=split_string(userdata[n2,"alts"],",");
 foreach i,s in splitter if(s!="")bigList[s]=true;
 biglist[n1]=true;
 biglist[n2]=true;
 foreach name in bigList{
  if(sysString(name,"gender")!="unknown")gencarry=userdata[name,"gender"];
  if(userdata[name,"nick"]!="")ncarry=userdata[name,"nick"];
 }
 foreach mult in biglist{
  if(sysString(mult,"gender")=="unknown")userdata[mult,"gender"]=gencarry;
  if(userdata[mult,"nick"]=="")userdata[mult,"nick"]=ncarry;
  userdata[mult,"alts"]="";
  foreach mult2 in bigList if(mult2!=mult)userdata[mult,"alts"]+=mult2+",";
 }
 string s=n1;
 foreach name in bigList if(name!=n1)s+=", "+name;
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
   chat(alt,sender+" is attempting to register you as "+genderPronoun(sender,gPosDet)+" multi.");
   mlist[sender,alt]=now+100;
  }else if(length(matchtxt)<length(tmatch))matchtxt=tmatch;
 }
 if(matchtxt=="")chat(sender,"Reminder sent to other accounts, you have 24 hours to register them.");
 else if(length(matchtxt)<111)chat(sender,"Multi properly registered for accounts:"+matchtxt);
 else cli_execute("csend to "+sender+"||Multi properly registered for accounts:"+matchtxt);
 commit(mlist,"tempMultis.txt");
 commit(userdata,"userdata.txt");
}

void setNick(string sender, string w){
 checkOut(userdata,"userdata.txt");
 userdata[sender,"nick"]=w;
 foreach i,alt in split_string(userdata[sender,"alts"],",")if((alt!="")&&(userdata[alt,"nick"]==""))userdata[alt,"nick"]=w;
 commit(userdata,"userdata.txt");
}

void clanTitle(string sender, string newt){
 if(!hasProp(sender,"membership","clannie")){
  chat("Only current members of the clan can have their clan title changed... idiot.");
  return;
 }
 if(!getUF(sender,"admin")){
  chat("Only admins can use this until it gets fixed for rank recognition, sorry.");
  return;
 }
 visit_url("clan_members.php?pwd&action=modify&pids[]="+userdata[sender,"ID#"]+"&title"+userdata[sender,"ID#"]+"="+newt);
}

void whitelistEdit(string oper){
 string cw=visit_url("clan_whitelist.php");
 if(!cw.contains_text("<form")){
  chat("Oh, no. A horrible, awful, irrevocable thing has happened... You broke my heart. {Core Privelage Disabled}");
  return;
 }
 matcher action=create_matcher("(-)?(\\w[\\w\\d\\s_]*)\\s*([:=]\\s*.+?)?",oper);
 string i;
 if(!action.find()){
  chat("I'm not sure what exactly you want me to do with the whitelist.");
  return;
 }
 i=getId(action.group(2));
 if(i==0){
  chat("I'm not sure who "+action.group(2)+" is.");
  return;
 }
 if(action.group(1)=="-"){
  i=getId(action.group(2));
  if(!cw.contains_text("who="+i.to_string())){
   chat(action.group(2)+" isn't currently on the whitelist.");
   return;
  }
  cw=visit_url("clan_whitelist.php?action=update&pwd&player"+i+"="+i+"&drop"+i+"=on");
  return;
 }
 i=getId(action.group(2));
 string s="clan_whitelist.php?action=add&pwd";
 if(cw.contains_text("who="+i.to_string())){
  chat(action.group(2)+" is already whitelisted.");
  return;
 }
 if(cw.contains_text("(#"+i+")")){
  s+="&clannie="+i;
  visit_url(s);
  chat(action.group(2)+" added to whitelist.");
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
}

void man(string sender, string query){
 cli_execute("kmail to "+sender+" || Thank you for your interest in my functions. I currently only buff members of Black Mesa and players on its whitelist. If you have recently joined, and are unable to receive a buff, please pm me with the phrase \"settings clear\". Please visit http://z15.invisionfree.com/Black_Mesa_Forums/index.php?showforum=14 for more information.");
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
 float last=userdata[sender,"lastMath"].to_float();
 float[string] mathvars;
 foreach i,chunk in chunks{
  if(chunk=="")continue;
  if("*+-^/".contains_text(chunk.char_at(0)))chunk=last.to_string()+chunk;
  mathvars["last"]=userdata[sender,"lastMath"].to_float();
  mathvars["ans"]=userdata["*","lastMath"].to_float();
  last=mathlibeval(chunk,mathvars);
 }
 userdata[sender,"lastMath"]=last.to_string();
 msg=last.to_string(8);
 commit(userdata,"userdata.txt");
 if(msg.to_float()==msg.to_int())msg=substring(msg,0,length(msg)-2);
 return msg;
}

void modSessionVar(string sender,string var,string val){
 checkOut(userdata,"userdata.txt");
 userdata[sender,var]=val;
 if(val=="")remove userdata[sender,var];
 commit(userdata,"userdata.txt");
}

boolean subUser(string oper){
 if(!getUF(trueUser,"admin")){
  errorMessage(trueUser,"No, don't do that!");
  return false;
 }
 switch(oper){
  case "":
   userdata[trueuser,"suser"]=".root";
   break;
  case "x":case "end":case "return":case "exit":
   remove userdata[trueuser,"suser"];
   break;
  default:
   if(userdata contains oper)userdata[trueUser,"suser"]=oper;
   else{
    errorMessage(trueUser,"Sorry, that user doesn't exist.");
    return false;
   }
 }
 commit(userdata,"userdata.txt");
 return true;
}

boolean subEnv(string oper){
 if(!getUF(trueuser,"admin")){
  errorMessage(trueUser,"No, don't do that!");
  return false;
 }
 switch(oper){
  case "hobopolis":case "hobo":case "hobop":case "h":
   userdata[trueuser,"schannel"]="hobopolis";
   chat(trueUser,"#hobopolis>");
   break;
  case "slimetube":case "s":case "slime":case "st":case "tube":
   userdata[trueuser,"schannel"]="slimetube";
   chat(trueUser,"#slimetube>");
   break;
  case "haunted house":case "haunted":case "hh":
   userdata[trueuser,"schannel"]="hauntedhouse";
   chat(trueUser,"#hauntedhouse>");
   break;
  case "return":case "exit":case "end":case "x":case "quit":
   remove userdata[trueuser,"schannel"];
   chat(trueUser,"#!>");
   break;
  case "clan":case "":
   userdata[trueuser,"schannel"]="clan";
   chat(trueUser,"#clan>");
   break;
  default:
   chat(trueUser,"#"+(userdata[trueUser,"schannel"]==""?"!":userdata[trueUser,"schannel"])+">");
   return false;
 }
 commit(userdata,"userdata.txt");
 return true;
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
   createAlias(sender,oper);
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
   if(!getUF(sender,"admin")){
    errorMessage(sender,"No, don't do that!");
    return "x";
   }
   clearData(oper);
   return "x";
  case "count":
   if(oper=="")return "x";
   if(!getUF(sender,"admin")){
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
   if(getUF(sender,"admin"))updateDC(oper);
   return "x";
  case "delpack":
   removeAlias(sender,oper);
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
   if(!hasProp(sender,"membership","clannie")){
    chat(sender,"You must be in Black Mesa to utilize its faxing rights.");
    return "x";
   }
   set_property("_lastFax",sender);
   fax(sender,oper);
   return "x";
  case "help":
  case "man":
  case "?":
   man(sender,oper);
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
   if(!analyzeMD(sender,oper))errorMessage(sender,"Analysis failed. Recheck item name and parameters.");
   return "x";
  case "math":
   oper=performMath(sender,oper);
   chat(sender,oper);
   return "x";
  case "mod":
  case "settings":
   mod(sender,oper);
   return "x";
  case "shutdown":
   shutdown(sender,oper);
   return "x";
  case "nick":
   first=create_matcher("([\\w ']*)",oper);
   if(first.find())oper=first.group(1);
   else{
    chat(sender,"Sorry, that's not a valid nickname.");
    return "x";
   }
   setNick(sender,oper);
   return "x";
  case "pack":
  case "set":
   first=create_matcher("(\\d+)\\s*:?\\s*(.*)",oper);
   pred="";
   if(first.find()){
    pred=first.group(1);
    oper=first.group(2);
   }
   string r=userdata[sender,"~"+oper];
   if((r=="")&&(!contains_text("0123456",oper)))r=userdata["*","~"+oper];
   if(r==""){
    errorMessage(sender,"That buffpack does not exist.");
    return "x";
   } 
   return pred+":"+r;
  case "ping":
   chat(turtleBot,"PING "+sender);
   chat(sauceBot,"PING "+sender);
   chat(sender,"Reply from Ominous Buffer"+(get_property("hostName")==""?".":" c/o "+get_property("hostName")));
   return "x";
  case "pull":
   if(oper=="")return "x";
   if(!getUF(sender,"admin")){
    errorMessage(sender,"No, don't do that!");
    return "x";
   }
   first=create_matcher("(\\d+)\\s?(.+)",oper);
   if(!first.find())return "x";
   i=first.group(1).to_int();
   whitem=first.group(2).to_item();
   if(first.group(2)=="meat"){
    i=ceil(i/1000.0);
    if(i>1000){
     errorMessage(sender,"More than a million seems a bit excessive, no?");
     i=1000;
    }
    take_closet(i,$item[dense meat stack]);
    cli_execute("csend "+i+" dense meat stack to "+sender+" || "+to_string(closet_amount($item[dense meat stack]))+" DMS remain.");
   }else if(whitem!=$item[none]){
    i=min(item_amount(whitem),i);
    cli_execute("csend "+i+" "+whitem.to_string()+" to "+sender+" || "+to_string(item_amount(whitem)-i)+" remain.");
   }
   return "x";
  case "recheck":
   if(!getUF(sender,"admin")){
    errorMessage(sender,"No, don't do that!");
    return "x";
   }
   chat("Looking for new test subjects and evaluating test data.");
   checkApps();
   checkMail();
   return "x";
  case "remove":
   removeAlias(sender,oper);
   return "x";
  case "roll":
   roll(sender,oper);
   return "x";
  case "search":
   search(sender,oper);
   return "x";
  case "se":
   subEnv(oper);
   return "x";
  case "su":
   subUser(oper);
   return "x";
  case "title":
   clanTitle(sender,oper);
   return "x";
  case "wang":
   if(is_online("wangbot")){
    chat_private("wangbot","target "+(oper==""?sender:oper));
   }else{
    if(item_amount($item[WANG])<1)retrieve_item(1,$item[WANG]);
    if(item_amount($item[WANG])<1)chat_private(sender,"We seem to be completely out of WANGs, sorry.");
    else visit_url("curse.php?action=use&pwd&whichitem=625&targetplayer="+(oper==""?sender:oper));
   }
   set_property("_lastWang",(oper==""?sender:oper)+'|'+sender);
   return "x";
  case "whitelist":
   if(getUF(sender,"admin"))whitelistEdit(oper);
   else chat("You must be an admin to edit the clan whitelist.");
   return "x";
  case "unwhitelist":
   if(getUF(sender,"admin"))whitelistEdit("-"+oper);
   else chat("You must be an admin to UNwhitelist (ugh) people from clan.");
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

boolean advancedFilterFail(string sender, string msg, string filter, string expected){
 switch(filter){
  case "msgHas":
    if(msg.contains_text(expected))return false;
   break;
  case "msgStarts":
    if(length(expected)>length(msg))return true;
    if(msg.substring(0,length(expected))==expected)return false;
   break;
 }
 return true;
}

void nopredpass(string sender, string msg, boolean addressed){
 responses[string] botdata;
 checkOut(botdata,"replies.txt");
 boolean foundmatch=false;
 boolean referred=addressed;
 matcher ref=create_matcher("(?i)(\\WOB\\W|\\WOminous Buffer\\W)",msg);
 if(ref.find())referred=true;
 ref=create_matcher(" $",msg);
 msg=replace_all(ref,"");
 responses r;
 string th="";
 foreach testcase,reply in botdata{
  th=testcase;
  /*print("");
  print(":"+msg+":");
  print(":"+testcase+":");
  */
//  if(((reply.flags&repFree)==0)&&(checkRep(testcase)<3)&&(checkRep(testcase)>-1))continue;
  if(((reply.flags&mustRefer)==mustRefer)&&(!referred))continue;
  if(((reply.flags&mustAddress)==mustAddress)&&(!addressed))continue;
  if(((reply.flags&fullText)==fullText)&&(msg!=testcase))continue;
  if(((reply.flags&caseSensitive)==caseSensitive)&&(!msg.contains_text(testcase)))continue;
  if(!msg.to_lower_case().contains_text(testcase.to_lower_case()))continue;
  if((reply.flags&noPartials)==noPartials){
   ref=create_matcher("\\\\E",testcase);
   testcase=replace_all(ref,"\\E\\\\E\\Q");
   ref=create_matcher(((reply.flags&caseSensitive)==caseSensitive?"":"(?i)")+"(?<!\\w)\\Q"+testcase+"\\E(?!\\w)",msg);
   if(!ref.find())continue;
  }
  foundmatch=true;
  if((replyParser(sender,reply.cond1)!=replyParser(sender,reply.cond2))&&advancedFilterFail(sender,msg,reply.cond1,reply.cond2)){
   foundmatch=false;
   continue;
  }
  r=reply;
  break;
 }
 if(foundmatch){
  checkOut(userdata,"userdata.txt");
  userdata[sender,"lastTrigger"]=th;
  userdata["*","lastTrigger"]=th;
//  addRep(th);
  commit(userdata,"userdata.txt");
  switch(r.method){
   case "say":chat(replyParser(sender,r.reply));
    break;
   case "do":chat("/em "+replyParser(sender,r.reply));
    break;
  }
 }
}

void setGender(string sender, string gender){
 string gval="unknown";
 matcher g=create_matcher("(?i)(WHO I AM|ME)",gender);
 if(g.find())gval="third";
 foreach gname in genders{
  if(gval!="unknown")break;
  if((!(genders[gname] contains 5))||(gname=="list"))continue;
  g=create_matcher("(?i)("+genders[gname,5]+")",gender);
  if(g.find())gval=gname;
 }
 checkOut(userdata,"userdata.txt");
 userdata[sender,"gender"]=gval;
 foreach i,m in split_string(userdata[sender,"alts"],",")if((m!="")&&(sysString(m,"gender")=="unknown"))userdata[m,"gender"]=gval;
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
 commit(ctimestamp,"timefile.txt");
 checkOut(userdata,"userdata.txt");
 userdata[who,"lastTime"]=now_to_string("MMMM d, yyyy 'at' hh:mm:ss a z");
 commit(userdata,"userdata.txt");
 lastM=lastM+lastH*60;
 nowM=nowM+nowH*60;
 nowM-=lastM;
 if(nowM<0)nowM+=1440;
 if(nowM==1)return 0;
 return nowM;
}

boolean isMath(string m){
 matcher fix=create_matcher("(?i)(?<![a-z])(last|ans|floor|ceil|min|max|sqrt|pi|phi|e|sin|cos|tan|ln|log|fairy|hound|jack|jitb|lep|monkey|ant|cactus)(?![a-z])",m);
 m=replace_all(fix,"+");
 fix=create_matcher("[^\\d\\s*+/.^,\\-()\\[\\]]",m);
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
 userdata[sender,"lastMath"]=tmp.to_string();
 userdata["*","lastMath"]=tmp.to_string();
 commit(userdata,"userdata.txt");
 chat(tmp.to_string(8));
 return true;
}

boolean mathDot(string data, boolean cross){
 vector u;
 vector v;
 matcher m=create_matcher("<(.+?)>,?\\s?<(.+?)>",data);
 if(!m.find())return false;
 u=m.group(1).to_vector();
 v=m.group(2).to_vector();
 string x;
 if(cross)x=u.cross(v).to_string(8);
 else x=u.dot(v).to_string(8);
 chat(x);
 return true;
}

boolean mathSTP(string data){
 vector a;
 vector b;
 vector c;
 matcher m=create_matcher("<(.+?)>\\s?<(.+?)>\\s?<(.+?)>",data);
 if(!m.find())return false;
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

void makeBackups(){
 string n=now_to_string("yyyyMMdd");
 int[string]books;
 checkOut(books,"books.txt");
 commit(books,"backup/"+n+"b.txt");
 checkOut(userdata,"userdata.txt");
 commit(userdata,"backup/"+n+"u.txt");
}

void sendMeat(string who, int amount){
 take_closet(amount,$item[dense meat stack]);
 string sender="town_sendgift.php?pwd="+my_hash()+"&towho="+who+"&note=You won the Lotto!&insidenote=A winner is you!&whichpackage=1&howmany1="+amount.to_string()+"&whichitem1="+$item[dense meat stack].to_int().to_string();
 sender+="&fromwhere=0&action=Yep.";
 visit_url(sender);
}

void checkLotto(){
 int[string] books;
 checkOut(books,"books.txt");
 int event=0;
 int time=minutesToRollover();
 if(time<books["Event1"])event=1;
 if(time<books["Event2"])event=2;
 if(time<books["Event3"])event=3;
 if(time<0)return;
 if(event<1)return;
 int num=-1;
 for i from 1 to 3 if(books["Event"+i.to_string()]>0)num+=1;
 if(num<0)num=0;
 set_property("lottos",num.to_string());
 books["Event"+event.to_string()]=0;
 books["nextLotto"]+=2;
 books["thisLotto"]+=14;
 boolean[string] inClan=who_clan();
 remove inClan["Ominous Buffer"];
 remove inClan["MesaChat"];
 remove inClan["Acoustic_shadow"];
 remove inClan["relay"];
 string[int] clannies;
 foreach name in inClan clannies[count(clannies)]=name;
 num=count(clannies);
 if(num<1){
  set_property("books",books["thisLotto"].to_string()+"::"+books["nextLotto"].to_string());
  commit(books,"books.txt");
  updateProfile();
  return;
 }
 float perc;
 if(num>7){
  perc=1.4+0.12*num;
 }else{
  perc=0.4+num*2.0/(1.0+num);
 }
 if(perc>4)perc=4;
 if(books["thisLotto"]>1500)perc=min(4.5,perc+1);
 if(books["thisLotto"]>2500)perc=min(5,perc+1);
 int d=ceil((100/perc)*num);
 d=d+random(10)-random(10);
 print("Event @ "+now_to_string("HH:mm")+" for "+books["thisLotto"].to_string()+" meat, "+num.to_string()+" players: 1d"+d.to_string(),"olive");
 chat("Time for the Lotto! Right now it's for "+books["thisLotto"].to_commad()+",000 meat! We have "+num.to_string()+(num!=1?" players":" player")+" now (d"+d.to_string()+"). Good luck!");
 d=random(d);
 waitq(10);
 chat("/em rolls "+to_string(d+1)+".");
 string endsentence="!";
 if(d<num){
  print("Event Won: "+clannies[d],"blue");
  chat_clan("A winner!");
  waitq(7);
  checkOut(userdata,"userdata.txt");
  for i from 4 downto 1 if(userdata["*"] contains ("winner"+i.to_string()))userdata["*","winner"+to_string(i+1)]=userdata["*","winner"+i.to_string()];
  userdata["*","winner1"]=clannies[d]+": "+books["thisLotto"].to_commad()+",000";
  commit(userdata,"userdata.txt");
  string wintext="";
  for i from 1 to 5 if(userdata["*"] contains ("winner"+i.to_string()))wintext+=userdata["*","winner"+i.to_string()]+"::";
  set_property("winners",wintext);
  chat(clannies[d]+" wins the lotto and takes home "+books["thisLotto"].to_commad()+",000 meat! See you again soon!");
  sendMeat(clannies[d],books["thisLotto"]);
  books["thisLotto"]=books["nextLotto"]-1;
  books["nextLotto"]=1;  
 }else{
  print("Event Lost.","blue");
  chat("Just what I thought. Everyone here is a loser. And "+insultCore()+" as well.");
 }
 set_property("books",books["thisLotto"].to_string()+"::"+books["nextLotto"].to_string());
 commit(books,"books.txt");
 updateProfile();
 saveSettings(earlySave);
}

void makeRecords(){
 print("Recording leftover music.","olive");
 checkOut(userdata,"userdata.txt");
 if(sysInt("#6026")<50){//Donho
  if(sysInt("#6026")<25){
   while(my_mp()<(25-sysInt("#6026"))*75)cli_execute("use mmj");
   visit_url("volcanoisland.php?action=tuba&pwd");
   visit_url("choice.php?whichchoice=409&option=1&pwd");
   visit_url("choice.php?whichchoice=410&option=2&pwd");
   visit_url("choice.php?whichchoice=412&option=3&pwd");
   visit_url("choice.php?whichchoice=418&option=3&pwd");
   visit_url("choice.php?whichchoice=440&whicheffect=614&times="+to_string(25-sysInt("#6026"))+"&option=1&pwd");
   userdata["*","#6026"]="25";
   visit_url("choice.php?pwd&whichchoice=440&option=2");
  }
  while(my_mp()<max(50-sysInt("#6026"),0)*75)cli_execute("use mmj");
  visit_url("volcanoisland.php?action=tuba&pwd");
  visit_url("choice.php?whichchoice=409&option=1&pwd");
  visit_url("choice.php?whichchoice=410&option=2&pwd");
  visit_url("choice.php?whichchoice=412&option=3&pwd");
  visit_url("choice.php?whichchoice=418&option=3&pwd");
  visit_url("choice.php?whichchoice=440&whicheffect=614&times="+to_string(50-sysInt("#6026"))+"&option=1&pwd");
  userdata["*","#6026"]="50";
  visit_url("choice.php?pwd&whichchoice=440&option=2");
 }
 print("Donho's recorded","blue");
 if(sysInt("#6028")<5){//Inigo
  while(my_mp()<(5-sysInt("#6028"))*100)cli_execute("use mmj");
  visit_url("volcanoisland.php?action=tuba&pwd");
  visit_url("choice.php?whichchoice=409&option=1&pwd");
  visit_url("choice.php?whichchoice=410&option=2&pwd");
  visit_url("choice.php?whichchoice=412&option=3&pwd");
  visit_url("choice.php?whichchoice=418&option=3&pwd");
  visit_url("choice.php?whichchoice=440&whicheffect=716&times="+to_string(5-sysInt("#6028"))+"&option=1&pwd");
  userdata["*","#6028"]=5;
  visit_url("choice.php?pwd&whichchoice=440&option=2");
 }
 print("Inigo's recorded","blue");
 for song from 6020 to 6024 if(sysInt("#"+song)<10){
  while(my_mp()<(10-sysInt("#"+song))*50)cli_execute("use mmj");
  visit_url("volcanoisland.php?action=tuba&pwd");
  visit_url("choice.php?whichchoice=409&option=1&pwd");
  visit_url("choice.php?whichchoice=410&option=2&pwd");
  visit_url("choice.php?whichchoice=412&option=3&pwd");
  visit_url("choice.php?whichchoice=418&option=3&pwd");
  visit_url("choice.php?whichchoice=440&whicheffect="+song.to_skill().to_effect().to_int()+"&times="+to_string(10-sysInt("#"+song))+"&option=1&pwd");
  userdata["*","#"+song]=10;
  visit_url("choice.php?pwd&whichchoice=440&option=2");
 }
 print("Hobopolis songs recorded","green");
 commit(userdata,"userdata.txt");
 updateLimits();
 updateDC("useCurrent");
}

void doBounty(){
 string bounty=visit_url("bhh.php");
 matcher m=create_matcher("(40 billy|5 burned|40 coal|5 discard|20 disint|11 non-E|5 sammich|6 bits of)",bounty);
 if(!m.find())return;
 int b;
 switch(m.group(1)){
  case "40 billy":b=2409;break;
  case "5 burned":b=2106;break;
  case "40 coal":b=2105;break;
  case "5 discard":b=2415;break;
  case "20 disint":b=2470;break;
  case "11 non-E":b=2107;break;
  case "5 sammich":b=2412;break;
  case "6 bits of":b=2471;break;
  default:return;
 }
 int oldLucre=item_amount($item[filthy lucre]);
 visit_url("bhh.php?pwd&action=takebounty&whichitem="+b.to_string());
// while((my_adventures()>burnTurns)&&(item_amount($item[filthy lucre])==oldLucre))if(adventure(1,b.to_item().bounty)){}
 visit_url("bhh.php");
}

void burn(){
 int to_burn=my_mp()-800;
 if(to_burn<0)return;
 int farmbuff=get_property("_lastFarmBuff").to_int();
 skill farmingbuff;
 switch(farmbuff){
  case 0:
   farmingbuff=$skill[fat leon's phat loot lyric];
   farmbuff+=1;
   break;
  case 1:
   farmingbuff=$skill[the polka of plenty];
   farmbuff+=1;
   break;
  default:
   farmingbuff=$skill[carlweather\'s cantata of confrontation];
   farmbuff=0;
 }
 set_property("_lastFarmBuff",farmbuff.to_string());
 int numCasts=ceil(to_float(to_burn)/(mp_cost(farmingbuff)));
 numCasts=max((numCasts/3),1);
 use_skill(numCasts,farmingbuff);
}

void publicChat(string sender, string msg){
 checkLotto();
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
 foreach i in genders if((i!="list")&&(genders[i] contains 5))genderMatcherString+="|"+genders[i,5];
 genderMatcherString+=")";
 if(!addressed)m=create_matcher(genderMatcherString,msg);
 else m=create_matcher("(?i)"+genderMatcherString,msg);
 if(m.find()){
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
  userdata["*","lastMath"]=userdata[sender,"lastMath"];
  commit(userdata,"userdata.txt");
  chat(msg);
  return;
 }
 switch(pred){
  case "choose":
  case "pick":
   if(addressed) pick(oper);
   return;
  case "cross":
   if(mathDot(oper,true))return;
   break;
  case "define":
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
   analyzeMD("!","link "+oper);
   return;
  case "mecho":
   if(addressed)chat("/em "+replyParser(sender,oper));
   return;
  case "roll":
   if(addressed)roll(sender,oper);
   return;
  case "spell":
   if(addressed)searchSpell(oper);
   return;
  case "stp":
   if(mathSTP(oper))return;
   break;
  case "sum":
   if(addressed)fancyMath(sender,oper);
   return;
  case "urban":
   if(addressed)searchUrban(oper);
   return;
 }
 nopredpass(sender,original,addressed);
 return;
}

void systemHandler(string msg){
 matcher m=create_matcher("(\\S*)\\s?(.*)",msg);
 if(!m.find())return;
 string cmd=m.group(1);
 string ops=m.group(2);
 doubleRun[cmd]=!doubleRun[cmd];
 if(doubleRun[cmd])return;
 switch(cmd){
  case "logout":
   saveSettings(nightlySave);
   cli_execute("maximize adv, -tie");
   updateDC();
   makeBackups();
   set_property("chatbotScript","");
   clearBuffs(6014);
   if(have_skill($skill[the ode to booze]))(!use_skill(1,$skill[the ode to booze]));
   overdrink(1,$item[eggnog]);
   checkApps();
   cli_execute("exit");
   break;
  case "apps":checkApps();break;
  case "check":checkApps();
  case "mail":checkMail();break;
  case "outfit":switch(ops){
    case "farm":
     cli_execute("familiar "+meatFam);
     cli_execute("maximize 2 meat, item, 100 combat, equip trikitixa, -tie");
     break;
    case "buff":
     cli_execute("familiar "+statFam);
     cli_execute("outfit birthday suit");
     cli_execute("maximize mp");
     break;
   }
   break;
  case "record":systemHandler("outfit buff"); systemHandler("outfit buff"); deMole(); makeRecords();break;
  case "adventure":
   systemHandler("outfit farm");systemHandler("outfit farm");
   deMole();
   if(my_adventures()<=burnTurns)break;
   if(adventure(5,$location[The Icy Peak])){}
   burn();
   break;
//  case "bounty":systemHandler("outfit farm");systemHandler("outfit farm"); deMole(); doBounty();break;
 }
}

boolean metaParser(string sender, string msg){
 matcher first=create_matcher("(\\S*)\\s?(.*)",msg);
 string pred;
 string oper;
 if(!first.find())return false;
 pred=first.group(1);
 oper=first.group(2);
 switch(pred){
  case "se":return subEnv(oper);
  default:return false;
 }
}

void clanHandler(string sender, string msg){
 if(sender=="relay"){
  matcher m=create_matcher("\\[([a-zA-Z][\\w ]{1,29})\\]\\s?(.*)",msg);
  if(!m.find())return;
  sender=m.group(1);
  msg=m.group(2);
 }
 if((trueChannel=="")&&(metaParser(sender,msg)))return;
 prefix="";
 switch(gameType()){
  case gameRoulette:
   russianRoulette(sender,msg);
   return;
  case gameHangman:
   if(hangman(sender,msg))return;
  default:
   publicChat(sender,msg);
   if(silent)maybeFact();
   return;
 }
}

void slimetubeHandler(string sender, string msg){
 if((trueChannel=="")&&(metaParser(sender,msg)))return;
 prefix="/slimetube ";
 if(sender=="Dungeon")return;
 publicChat(sender,msg);
}

void hobopolisHandler(string sender, string msg){
 if((trueChannel=="")&&(metaParser(sender,msg)))return;
 prefix="/hobo ";
 if(sender=="Dungeon"){
  matcher m=create_matcher("(.+?) has entered combat with (.*)",msg);
  if(m.find()){//Start fight.
   return;
  }
  m=create_matcher("(.+?) has defeated (.*)",msg);
  if(m.find()){//Win fight.
   return;
  }
  m=create_matcher("(.+?) defeated (.*)",msg);
  if(m.find()){//Lose fight.
   return;
  }
  return;
 }
 publicChat(sender,msg);
}

void hauntedhouseHandler(string sender, string msg){
 if((trueChannel=="")&&(metaParser(sender,msg)))return;
 prefix="/hauntedhouse ";
 if(sender=="Dungeon")return;
 publicChat(sender,msg);
}

void dreadHandler(string sender, string msg){
 if((trueChannel=="")&&(metaParser(sender,msg)))return;
 prefix="/dread ";
 if(sender=="Dungeon")return;
 publicChat(sender,msg);
}

void eventHandler(string msg){
 //What to do here... hmm.
}

void privateHandler(string sender, string msg){
 matcher m;
 if(sender==my_name()){
  systemHandler(msg);
  return;
 }
 if(sender=="MesaChat"){
  m=create_matcher("([a-zA-Z][\\w ]{1,29}):\\s?(.*)",msg);
  if(m.find()){
   sender=m.group(1);
   msg=m.group(2);
   clanHandler(sender,msg);
  }
  return;
 }
 if(sender=="chatbot")return;
 if(!buffable(sender))return;
 prefix=sender;
 if(msg.char_at(0)=="!"){
  errorMsg=false;
  if(length(msg)>1)msg=substring(msg,1);
 }
 errorMsg=getUF(sender,"errors");
 if(gameType()==gameWordshot)msg=wordshot(sender,msg);
 if(msg=="x")return;
 string[string] aliasList;
 foreach a,v in userdata["*"] if(a.char_at(0)=="~")aliasList[a.substring(1)]=v;
 foreach a,v in userdata[sender] if(a.char_at(0)=="~")aliasList[a.substring(1)]=v;
 m=create_matcher("\\s?(\\d+):?\\s?",msg);
 if(m.find()){
  string mult=m.group(1).to_int();
  string alias=m.replace_all("");
  if(aliasList contains alias)msg=mult+": "+aliasList[alias];
 }else if(aliasList contains msg)msg=aliasList[msg];
 msg=predicateFilter(sender,msg);
 if(msg=="x")return;
 if((sender==turtleBot)||(sender==sauceBot)){
  buff(sender,msg,0,sender);
  return;
 }
 m=create_matcher("buff ([a-zA-Z][a-zA-Z 0-9']*) with (.*)",msg.to_lower_case());
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
  m.reset(messages[i]);
  while(m.find()){
   messages[i]=m.group(2);
   m.reset(messages[i]);
  }
  m=create_matcher("(\\d+)",messages[i]);
  if(m.find()){
   if(to_float(m.group(1))>1000)turnR=1000;
   else turnR=to_int(m.group(1));
  }//why not "[a-zA-Z][\\s\\w']*[a-zA-Z]"
  m=create_matcher("[a-zA-Z\\?](?:[a-zA-Z']|(?:\\s(?=\\w)))*",messages[i]);
  if(m.find())messages[i]=m.group(0);
  if(multiplier==0)buff(sender,messages[i],turnR,co);
  else buff(sender,messages[i],multiplier,co);
 }
}

boolean preHandled(string sender, string msg, string channel){
 errorFree=true;
 if(msg==""){
  return true;
 }
 if(sender=="System Message"){
  return true;
 }
 if(get_property("_lockChat")!=""){
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
   if(item_amount($item[WANG])<1)cli_execute("stash take wang");
   matcher m=create_matcher("([^|]*)|(.*)",get_property("_lastWang"));
   if(m.find()){
    if(item_amount($item[WANG])<1)chat_private(m.group(2),"We seem to be completely out of WANGs, sorry.");
    else visit_url("curse.php?action=use&pwd&whichitem=625&targetplayer="+m.group(1));
   }
  }
  return true;
 }
 if((sender=="MesaChat")&&(channel!=""))return true;
 if((sender==my_name())&&(channel!=""))return true;
 errorFree=false;
 return false;
}

string applySUE(string sender,string channel){
 if(channel!="")return sender;
 trueUser=sender;
 if(hasProp(sender,"suser",",.root"))return sender;
 return userdata[sender,"suser"];
}

string applySUE(string channel){
 if(channel!="")return channel;
 if(trueUser!="MesaChat")impliedOB=true;
 trueChannel=channel;
 if(userdata[trueUser,"schannel"]!="")return "/"+userdata[trueUser,"schannel"];
 return "";
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
  case "/dread":
   dreadHandler(sender,msg);
   break;
  case "Events":
   eventHandler(msg);
   break;
  case "":
   privateHandler(sender,msg);
   break;
  default:
   break;
 }
 errorFree=true;
}finally{
 if(!errorFree){
  print("ERROR","red");
  print("Message: "+msg,"olive");
  print("From "+sender+" in "+channel,"olive");
 }
}}