record gameData{
 int[string] players;
 string[int] data;
 boolean gameStarted;
 int roundOver;
 int intervals;
 string host;
};
/*
About gamesavedata["."]:
 gamesavedata["."].data[0] contains the gameId of the current running game, or 0 if there isn't one.
 gamesavedata["."].players[gameId] contains the gameType of the gameId.
*/
gameData[string] gamesavedata;
file_to_map("gameMode.txt",gamesavedata);
int gameNone=0;
int gameRoulette=1;
int gameWordshot=2;
int gameLotto=4;

string startGame(int gType, int ivals, boolean started, string host){
 file_to_map("gameMode.txt",gamesavedata);
 string gId=count(gamesavedata).to_string();
 int now=now_to_string("HH").to_int()*60+now_to_string("mm").to_int();
 gamesavedata["."].players[gId]=gType;
 gamesavedata[gId].players[":SYSTEM"]=0;
 gamesavedata[gId].intervals=ivals;
 gamesavedata[gId].roundOver=now+ivals;
 gamesavedata[gId].gameStarted=started;
 gamesavedata[gId].host=host;
 gamesavedata["."].data[0]=gId;
 map_to_file(gamesavedata,"gameMode.txt");
 return gId;
}
string startGame(int gType){
 return startGame(gType,3,false,":SYSTEM");
}

gameData loadGame(string gId){
 gameData tmp;
 if (gamesavedata contains gId) return gamesavedata[gId];
 return tmp;
}
gameData loadGame(){
 string t=gamesavedata["."].data[0];
 return loadGame(t);
}

boolean saveGame(gameData game){
 file_to_map("gameMode.txt",gamesavedata);
 string t=gamesavedata["."].data[0];
 if (t=="") return false;
 gamesavedata[t]=game;
 map_to_file(gamesavedata,"gameMode.txt");
 return true;
}

int gameType(){
 file_to_map("gameMode.txt",gamesavedata);
 string t=gamesavedata["."].data[0];
 if (t=="") return 0;
 return gamesavedata["."].players[t];
}

string pauseGame(gameData game){
 file_to_map("gameMode.txt",gamesavedata);
 string t=gamesavedata["."].data[0];
 if (!saveGame(game)) t="";
 gamesavedata["."].data[0]="";
 map_to_file(gamesavedata,"gameMode.txt");
 return t;
}
string pauseGame(){
 string t=gamesavedata["."].data[0];
 if (gamesavedata contains t) return pauseGame(gamesavedata[t]);
 return "";
}

gameData resumeGame(string gId){
 file_to_map("gameMode.txt",gamesavedata);
 pauseGame();
 gameData tmp;
 if (!(gamesavedata contains gId)) return tmp;
 gamesavedata["."].data[0]=gId;
 map_to_file(gamesavedata,"gameMode.txt");
 return gamesavedata[gId];
}

void closeGame(string gId){
 file_to_map("gameMode.txt",gamesavedata);
 if(!(gamesavedata contains gId)) return;
 remove gamesavedata[gId];
 remove gamesavedata["."].players[gId];
 gamesavedata["."].data[0]="";
 map_to_file(gamesavedata,"gameMode.txt");
}
void closeGame(){
 closeGame(gamesavedata["."].data[0]);
}

void closeAllGames(){
 clear(gamesavedata);
 gamesavedata["."].data[0]="";
 gamesavedata["."].gameStarted=false;
 gamesavedata["."].intervals=0;
 map_to_file(gamesavedata,"gameMode.txt");
}

string startWordshot(int l,string h){
 gameData game=loadGame(startGame(gameWordshot,0,true,h));
 if (l==0) l=random(3)+4;
 l=min(max(4,l),10);
 string list=visit_url("http://clubefl.gr/games/wordox/"+l.to_string()+".html");
 matcher m;
 switch (l){
  case 4: m=create_matcher("</b>([\\w\\s\\r\\n]+)</br>",list);
          break;
  case 5: m=create_matcher("</b>([\\w\\s\\r\\n]+)</p>",list);
          break;
  case 6:
  case 7: m=create_matcher("<br>([\\w\\s\\r\\n]+)<br>[\\s\\r\\n]*<br>",list);
          break;
  case 8: m=create_matcher("</p>[\\s\\r\\n]*<p align=\"center\">([\\w\\s\\r\\n]+)<br>",list);
          break;
  case 9: m=create_matcher("<p align=\"left\">([\\w\\s\\r\\n]+)</p>",list);
          break;
  case 10: m=create_matcher("</b><br>([\\w\\s\\r\\n]+)<br>",list);
          break;
 }
 if (m.find()){
  list=m.group(1);
  remove game.players["SYSTEM"];
  string[int] bigList=split_string(list,"\\W");
  l=count(bigList);
  list="";
  while(list=="") list=bigList[random(l)];
  game.players[list]=1;
  game.intervals=3;
  game.roundOver=0;
  saveGame(game);
 }else{
  closeGame();
  return -1;
 }
 return gamesavedata["."].data[0];
}
string startWordshot(string host){
 return startWordshot(0,host);
}