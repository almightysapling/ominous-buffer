import <kmail.ash>
import <games.ash>

record userinfo{
 int userid;
 string nick;
 boolean[string] multis;
 int gender;//see gengers[] definition comments
 int flags;//see flag bits
 string[string] buffpacks;
 int[int] buffs;
 float lastMath;
 string lastTime;
 string lastTrigger;
 int donated;
 int wallet;
};
//flag bits
int noFlag=1;//no "cake is a lie" message
int isAdmin=2;
int isBuffer=4;//no use, merely for OS/T
int noLimit=8;
int blacklist=16;
int whitelist=32;//for OB-use, not clan
int inClan=64;
int receivedCake=128;//see login.ash
int inAssociate=256;
int highAssociate=512;

userinfo[string] userdata;
file_to_map("userdata.txt",userdata);

//Global variables
string sauc_name="ominous sauceror";
string turt_name="ominous tamer";
int clanid=2046994401;//Black Mesa
boolean[int] associates;//F: 400 limit; T:in-clan limits
associates[2046987019]=false;//Not Dead Yet
associates[2046991167]=false;//This One Time
associates[2046983684]=false;//Clan of 14 Days
associates[2046991423]=false;//Margaretting Tye
associates[76566]=false;//Imitation Plastic Death Star

void setUF(string user, int f){
 userdata[user].flags|=f;
}

void unSetUF(string user, int f){
 userdata[user].flags&=~f;
}

boolean getUF(string user, int f){
 return (userdata[user].flags&f)==f;
}

//check clan whitelist for user if not in clan
boolean checkWhitelist(int id){
 string page=visit_url("clan_whitelist.php");
 matcher m=create_matcher("(?i)="+id.to_string()+"'",page);
 if (find(m)) return true;
 return false;
}

//request unknown user's id. if (add) then place them into the users file.
int updateId(string user,boolean add){
 if (user=="") return 0;
 string searchstring=visit_url("searchplayer.php?searching=Yep.&searchstring="+user+"&hardcoreonly=0");
 matcher name_clan=create_matcher('(?i)(\\d*)">'+user+'</a></b> (?: \\(PvP\\))?(?:<br>\\(<a target=mainpane href="showclan\\.php\\?whichclan=(\\d*))?',searchstring);
 if(!find(name_clan)) return 0;
 if (!add) return group(name_clan,1).to_int();
 userdata[user].gender=2;
 userdata[user].userid=group(name_clan,1).to_int();
 unSetUF(user,inClan+inAssociate+highAssociate);
 if (group(name_clan,2).to_int()==clanid) setUF(user,inClan);
 else unSetUF(user,inClan);
 if (associates contains group(name_clan,2).to_int()){
  setUF(user,inAssociate);
  if (associates[group(name_clan,2).to_int()]==true) setUF(user,highAssociate);
 }
 if (!(getUF(user,inClan))){
  boolean wl=checkWhitelist(userdata[user].userid);
  if (wl) setUF(user,inClan);
 }
 map_to_file(userdata,"userdata.txt");
 return userdata[user].userid;
}

//return id for given username. If name not on file, request it.
int getId(string sender){
 if (sender=="") return 0;
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

void updateDC(string list){
 if (list=="useCurrent") list=get_property("_currentDeals");
 else set_property("_currentDeals",list);
 string deals="";
 matcher extra=create_matcher("\\s,\\s",list);
 list=replace_all(extra,",");
 string[int] names=split_string(list,",");
 foreach x in names deals+=names[x]+" (#"+getId(names[x]).to_int()+")\n";
 if (deals==" (#0)\n"){
//  print("No deals for DC","green");
  deals="";
 }else{
  print("Deals in DC for the following players:","green");
  print(deals,"olive");
  deals="Current deals in mall:\n"+deals+"\n";
 } 
 int served=get_property('sauceCasts').to_int()+get_property('tamerCasts').to_int()+get_property('totalCastsEver').to_int();
 int days=get_property('totalDaysCasting').to_int()+1;
 string avg=to_string(served*1.0/days);
 if (index_of(avg,'.')+3<length(avg)) avg=substring(avg,0,index_of(avg,'.')+3);
 string s="managecollection.php?action=changetext&pwd&newtext=";
 s+="Over "+to_commad(served)+" casts served since 2011!\n";
 s+="Daily Avg: "+avg+"\n\n";
 s+="More information on buffs offered can be found on the following page:\n";
 s+="http://kol.coldfront.net/thekolwiki/index.php/Buff\n\n";
 s+=deals;
 s+="Casts Remaining of limited skills listed below:\n";
 s+="Managerial Manipulation: "+to_int(3-userdata["*"].buffs[62])+"\n";
 visit_url(s);
}

void updateDC(){
 updateDC("");
}

void updateLimits(){
 string s="managecollection.php?action=modifyshelves&pwd="+my_hash()+"&newname12=";
 s+=to_string(50-userdata["*"].buffs[6026]);
 buffer n;
 if((50-userdata["*"].buffs[6026])>10) n=visit_url(s);
 s="managecollectionshelves.php?pwd&action=arrange";
 if ((50-userdata["*"].buffs[6026])<11) s+="&whichshelf4502="+to_string(51-userdata["*"].buffs[6026]);
 s+="&whichshelf4503="+to_string(6-userdata["*"].buffs[6028]);
 s+="&whichshelf4497="+to_string(11-userdata["*"].buffs[6020]);
 s+="&whichshelf4498="+to_string(11-userdata["*"].buffs[6021]);
 s+="&whichshelf4499="+to_string(11-userdata["*"].buffs[6022]);
 s+="&whichshelf4500="+to_string(11-userdata["*"].buffs[6023]);
 s+="&whichshelf4501="+to_string(11-userdata["*"].buffs[6024]);
 n=visit_url(s);
 s="62:"+to_string(userdata["*"].buffs[62])+":";
 s+="6020:"+to_string(userdata["*"].buffs[6020])+":";
 s+="6021:"+to_string(userdata["*"].buffs[6021])+":";
 s+="6022:"+to_string(userdata["*"].buffs[6022])+":";
 s+="6023:"+to_string(userdata["*"].buffs[6023])+":";
 s+="6024:"+to_string(userdata["*"].buffs[6024])+":";
 s+="6026:"+to_string(userdata["*"].buffs[6026])+":";
 s+="6028:"+to_string(userdata["*"].buffs[6028])+":";
 set_property("_limitBuffs",s);
}

int checkRep(string check){
 for i from 6 to 0 if (userdata["*"].buffpacks[i.to_string()]==check) return i;
 return -1;
}

void addRep(string s){
 for i from 0 to 5{
  userdata["*"].buffpacks[i.to_string()]=userdata["*"].buffpacks[to_string(i+1)];
 }
 userdata["*"].buffpacks["6"]=s;
 map_to_file(userdata,"userdata.txt");
}

void saveSettings(){
 visit_url("questlog.php?which=4&action=updatenotes&font=0&notes="); 
}

void loadSettings(string postRO){
 string ls=visit_url("questlog.php?which=4");
 matcher notef=create_matcher(";'\\>([\\s\\S]*)\\</text",ls);
 if(!find(notef)) return;
 string[int] setting=split_string(group(notef,1),'\\r?\\n|\\s=\\s');
 int x=count(setting)/2;
 if (x==0) return;
 int day;
 for i from 0 to count(setting)-1 if(setting[i]=="!day") day=setting[i+1].to_int();
 if (day<gameday_to_int()){
  string[int] skipsplit=split_string(postRO,';');
  int[string] skip;
  foreach toskip in skipsplit skip[skipsplit[toskip]]=1;
  for i from 0 to x-1 if (!(skip contains setting[2*i])) set_property(setting[2*i],setting[2*i+1]);
 }else
  for i from 0 to x-1 set_property(setting[2*i],setting[2*i+1]);
 saveSettings();
}
void loadSettings(){
 loadSettings("");
}

void saveSettings(string settings){
 string[int] setting=split_string(settings,';');
 string submit="";
 foreach i in setting submit+=setting[i]+" = "+get_property(setting[i])+"\n";
 submit+="!day = "+gameday_to_int().to_string();
 submit="questlog.php?which=4&action=updatenotes&font=0&notes="+submit;
 visit_url(submit);
}

void deleteAnnouncement(){
 string t=visit_url("clan_hall.php");
 matcher m=create_matcher("(\\d+)\">delete</a>\\]<b><br>From: Ominous Buffer \\(",t);
 if (m.find()) visit_url("clan_hall.php?action=delete&pwd&msgid="+m.group(1));
}

void announceClan(string message){
 deleteAnnouncement();
 string t="clan_board.php?action=postannounce&pwd&message="+message;
 visit_url(t);
}