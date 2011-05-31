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