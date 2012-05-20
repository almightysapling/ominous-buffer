import<shared.ash>
string[string] fields=form_fields();
//html properties
boolean spaced=false;
int newline=0;
string[int]tagList;

//Add text to the file, adding proper padding for new lines.
void n(string text){
 if (!spaced){
  for i from 1 upto newLine write(" ");
  spaced=true;
 }
 write(text);
 return;
}
//Add text to file, including a hard return.
void nln(string text){
 n(text+"\n");
 spaced=false;
}
void nln(){
 n("\n");
 spaced=false;
}
void ntln(string text){
 n("<br/>");
 nln(text);
}

void opentag(string tag,string options){
 n("<"+tag);
 if (options!="") n(" "+options);
 nln(">");
 tagList[count(tagList)+1]=tag;
 newLine+=1;
}
void opentag(string tag){
 opentag(tag,"");
}

string closetag(){
 newline-=1;
 if (spaced) nln();
 if (count(tagList)==0) return "html";
 string result=remove tagList[count(tagList)];
 nln("</"+result+">");
 return result;
}
string closetag(string totag){
 string r=closetag();
 while ((r!="html")&&(r!=totag)) r=closetag();
 return r;
}
void cycletag(string tag,string options){
 boolean found=false;
 foreach i in tagList if(tagList[i]==tag)found=true;
 if(found)closetag(tag);
 opentag(tag,options);
}
void cycletag(string tag){
 cycletag(tag,"");
}

void update(){
 loadSettings(ignorePile);
 matcher m;
 foreach var,val in fields{
  m=create_matcher("(.+?)\\.(.+?)$",var);
  if(!m.find())continue;
  switch(m.group(1)){
   case "prop":set_property(m.group(2),val);break;
  }
 }
 saveSettings(earlySave);
}

void header(){
 writeln("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">");
 opentag("html");
 opentag("head");
 opentag("style","type=\"text/css\"");
 writeln(".optGroup {font-weight: bold;}");
 writeln(".kolbut {border: 2px solid black; font-family:Arial,Helvetica,sans-serif; font-size:10pt; font-weight: bold; background-color: white;}");
 writeln(".righttable {text-align:right; width:80%; float:right; border:0px; background-color:white; padding: 0px; border-spacing:5px;}");
 writeln(".info {background-color:#F5E4DC;}");
 writeln(".good {background-color: rgb(110,250,130);}");
 writeln(".bad {background-color: rgb(250,110,130);}");
 writeln("input.unselected {background-color:#F5E4DC; border:0px; text-align:right; margin:2px}");
 closetag();
 opentag("script","type=\"text/javascript\" language=\"javascript\"");
 writeln("function convertInputs(){");
 writeln(" var allEs=document.getElementsByTagName(\"input\");");
 writeln(" for(var i=0;i<allEs.length;i++) if(allEs[i].className==\"unselected\"){");
 writeln(" }");
 writlen("}");
 writeln("function switchIn(e){ e.className=\"\";}");
 writeln("function switchOut(e){ e.className=\"unselected\";}");
 closetag();
 opentag("body","onload=\"convertInputs()\"");
}

void options(){
 opentag("form","method=\"post\" action=\""+__FILE__+"\"");
 nln("<input type=\"hidden\" name=\"save\" value=\"yes\">");
 nln("<span class=\"optGroup\">Ominous Buffer</span>");
 ntln("Nuns Visited Today: <input class=\"unselected\" type=\"text\" name=\"prop.nunsVisits\" value=\""+get_property("nunsVisits")+"\">");
 ntln("Stuff to put here: admins, lotto values");
 ntln("<span class=\"optGroup\">Current Host Only</span>");
 ntln("Host Name: <input type=\"text\" name=\"prop.hostName\" value=\""+get_property("hostName")+"\">");
 ntln("<input type=\"submit\" name=\"submit\" value=\"Save\" class=\"kolbut\">");
 closetag("form");
}

void info(){
 matcher m;
 string s;
 opentag("table","class=\"righttable\"");
 opentag("tr");
 opentag("td","class=\"info\"");
 nln("Application Processing");
 s=visit_url("clan_office.php");
 if(s.contains_text("clan_applications.php")){
  cycletag("td","class=\"good\"");
  nln("Allowed");
 }else{
  cycletag("td","class=\"bad\"");
  nln("Disabled");
 }
 cycletag("tr");
 opentag("td","class=\"info\"");
 nln("Whitelist Access");
 s=visit_url("clan_whitelist.php");
 if(s.contains_text("<form>")){
  cycletag("td","class=\"good\"");
  nln("Yes");
 }else{
  cycletag("td","class=\"bad\"");
  nln("No");
 }
}

void footer(){
 closetag("html");
}

void main(){
 if(fields contains "save") update();
 header();
 options();
 info();
 footer();
}