import <shared.ash>
invokeResourceMan(__FILE__);
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
void cycletag(){
 cycletag(tagList[count(tagList)]);
}

void update(){
 loadSettings(ignorePile);
 formProps();
 checkOut(userdata,"userdata.txt");
 matcher m;
 string name;
 string[string,string] groups;
 foreach i,s in split_string(get_property("admins"),"::") userdata[s,"admin"]="false";
 foreach var,val in fields{
  m=create_matcher("(.+?)\\.(.*)",var);
  if(!m.find())continue;
  name=m.group(2);
  switch(m.group(1)){
   case "prop":
    m=create_matcher("(.+?)\\.(.*)",name);
    if(!m.find()){
     set_property(name,val);
     break;
    }
    groups[m.group(1),m.group(2)]=val;
    break;
   case "admins":
    if(userdata contains val)userdata[val,"admin"]="true";
    break;
  }
 }
 foreach g in groups{
  name="";
  foreach i,v in groups[g] name+=v+"::";
  set_property(g,name);
 }
 commit(userdata,"userdata.txt");
 saveSettings(earlySave);
}

void manageOST(){
 boolean sburn=false,tburn=false;
 boolean slog=false,tlog=false;
 boolean sadv=false,tadv=false;
 string w;
 foreach s,v in fields{
  switch(s.char_at(0)){
   case ".":
    
    break;
   case "p":
    w=s.substring(2);
    if(v=="")break;
    set_property(w,v);
    if(w.char_at(1)=="s")chat_private("Ominous Sauceror","PROPERTY SET "+w.substring(2)+" "+v);
    else if(w.char_at(1)=="t")chat_private("Ominous Tamer","PROPERTY SET "+w.substring(2)+" "+v);
    break;
  }
 }
}

void header(){
 writeln("<!DOCTYPE html>");
// writeln("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">");
 opentag("html");
 opentag("head");
 opentag("style","type=\"text/css\"");
 writeln("#numAdmins {display: none}");
 writeln("#adder {width: 12px; height: 12px; border: 2px dotted rgb(220,220,220); text-align: center;}");
 writeln(".tmp {visibility: hidden; white-space: nowrap;}");
 writeln(".optGroup {font-weight: bold;}");
 writeln(".kolbut {border: 2px solid black; font-family:Arial,Helvetica,sans-serif; font-size:10pt; font-weight: bold; background-color: white;}");
 writeln(".righttable {text-align:right; width:50%; float:right; border:0px; background-color:white; padding: 0px; border-spacing:5px;}");
 writeln(".lefttable {text-align:left; border:0px; background-color:white; padding: 0px; border-spacing: 5px;}");
 writeln(".lefttable td {background-color:#F5E4DC;}");
 writeln(".info {background-color:#F5E4DC;}");
 writeln(".good {background-color: rgb(110,250,130);}");
 writeln(".bad {background-color: rgb(250,110,130);}");
 writeln(".okay {background-color: rgb(220,220,220);}");
 writeln(".paren {font-size:0.8em; font-weight: bold;}");
 writeln("input.unselected {background-color:#F5E4DC; border:0px; text-align:right; margin:2px 3px}");
 closetag();
 opentag("script","type=\"text/javascript\" language=\"javascript\"");
 writeln("function renderWidth(e){");
 writeln(" var tmp=document.createElement(\"span\");");
 writeln(" tmp.className=\"tmp\";");
 writeln(" tmp.innerHTML=\".\"+e.value+\".\";");
 writeln(" document.body.appendChild(tmp);");
 writeln(" var theWidth = tmp.scrollWidth;");
 writeln(" document.body.removeChild(tmp);");
 writeln(" return theWidth;");
 writeln("}");
 writeln("function resize(e){ e.style.width=Math.min(Math.max(5,renderWidth(e)),220)+'px';}");
 writeln("function convertInputs(){");
 writeln(" var allEs=document.getElementsByTagName(\"input\");");
 writeln(" for(var i=0;i<allEs.length;i++) {");
 writeln("  if(allEs[i].className.indexOf(\"unselected\")!==-1){");
 writeln("   resize(allEs[i]);");
 writeln("   allEs[i].setAttribute(\"onfocus\",\"switchIn(this)\");");
 writeln("   allEs[i].setAttribute(\"onblur\",\"switchOut(this)\");");
 writeln("   allEs[i].setAttribute(\"onkeyup\",\"resize(this)\");");
 writeln("  }");
 writeln(" }");
 writeln("}");
 writeln("function addMin(){");
 writeln(" newI=document.createElement(\"input\");");
 writeln(" numD=document.getElementById(\"numAdmins\");");
 writeln(" newI.setAttribute(\"onfocus\",\"switchIn(this)\");");
 writeln(" newI.setAttribute(\"onblur\",\"switchOut(this)\");");
 writeln(" newI.setAttribute(\"onkeyup\",\"resize(this)\");");
 writeln(" newI.type=\"text\";");
 writeln(" newI.name=\"admins.\"+numD.innerHTML;");
 writeln(" span=document.getElementById(\"adminbox\");");
 writeln(" span.appendChild(document.createTextNode(\", \"));");
 writeln(" span.appendChild(newI);");
 writeln(" numD.innerHTML=Number(numD.innerHTML)+1;");
 writeln(" resize(newI);");
 writeln(" newI.focus();");
 writeln("}");
 writeln("function freeRelease(checked, bound){");
 writeln(" elem=document.getElementById(bound);");
 writeln(" if(checked){");
 writeln("  elem.disabled=false;");
 writeln(" }else{");
 writeln("  elem.checked=false;");
 writeln("  elem.disabled=true;");
 writeln(" }");
 writeln("}");
 writeln("function switchIn(e){ e.className=\"\";}");
 writeln("function switchOut(e){ e.className=\"unselected\";}");
 closetag("head");
 opentag("body","onload=\"convertInputs()\"");
}

void options(){
 int[string] books;
 update(books,"books.txt");
 opentag("form","method=\"post\" action=\""+__FILE__+"\"");
 nln("<input type=\"hidden\" name=\"cp\" value=\"save\" />");
 nln("<span class=\"optGroup\">Ominous Buffer</span>");
 ntln("Nuns Visited Today: <input class=\"unselected\" type=\"text\" name=\"prop.nunsVisits\" value=\""+get_property("nunsVisits")+"\" />");
 nln("<input type=\"hidden\" name=\"prop.books.1\" value=\""+books["Event1"]+"\" />");
 nln("<input type=\"hidden\" name=\"prop.books.2\" value=\""+books["Event2"]+"\" />");
 nln("<input type=\"hidden\" name=\"prop.books.3\" value=\""+books["Event3"]+"\" />");
 ntln("Current Lottery Amount: <input class=\"unselected\" type=\"text\" name=\"prop.books.5\" value=\""+books["thisLotto"]+"\" />");
 nln("Next Lottery Amount: <input class=\"unselected\" type=\"text\" name=\"prop.books.4\" value=\""+books["nextLotto"]+"\" />");
 string[int] admins=split_string(get_property("admins"),"::");
 n("<br/>Admins: <span id=\"adminbox\">");
 foreach i,s in admins nln("<input class=\"unselected\" type=\"text\" name=\"admins."+i+"\" value=\""+s+"\" />"+(i==count(admins)-1?"</span><span id=\"numAdmins\">"+to_string(i+1)+"</span>.":", "));
 nln("<span id=\"adder\" onclick=\"addMin();\">+</span>");
 ntln("<span class=\"optGroup\">Current Host Only</span>");
 ntln("Host Name: <input class=\"unselected changesize\" type=\"text\" name=\"prop.hostName\" value=\""+get_property("hostName")+"\" />");
 ntln("<input type=\"submit\" name=\"submit\" value=\"Save\" class=\"kolbut\" />");
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
 if(s.contains_text("<form")){
  cycletag("td","class=\"good\"");
  nln("Yes");
 }else{
  cycletag("td","class=\"bad\"");
  nln("No");
 }
 cycletag("tr");
 opentag("td","class=\"info\"");
 nln("Meat <span class=\"paren\">(including DMS)</span>");
 cycletag("td","class=\"okay\"");
 nln(to_commad(my_meat()+my_closet_meat()+(item_amount($item[dense meat stack])+closet_amount($item[dense meat stack]))*1000));
 closetag("table");
}

void OST(boolean show){
 opentag("form","action=\""+__FILE__+"\" method=\"post\"");
 nln("<input type=\"hidden\" name=\"cp\" value=\"control\"/>");
 opentag("table","class=\"lefttable\"");
 opentag("tr");
 opentag("th");
 cycletag();
 nln("OS");
 cycletag();
 nln("OT");
 if(show){
  cycletag("tr");
  opentag("td");
  cycletag();
  nln("Sauce Shit!");
  cycletag();
  nln("Turtle Shit!");
 }else{
  cycletag("tr");
  opentag("td","colspan=\"3\"");
 // nln("<a href=\""+__FILE__+"?load=true\">Load OS/T information.</a><span class=\"paren\">(Takes time to load)</span>");
  nln("Loading OS/T info currently unsupported.");
  cycletag("tr");
  opentag("td","colspan=\"3\"");
  nln("<span class=\"paren\">Data here may be out of date.</span>");
 }
 cycletag("tr");
 opentag("td");
 nln("Burn");
 cycletag();
 nln("<input type=\"checkbox\" name=\".sb\" />");
 cycletag();
 nln("<input type=\"checkbox\" name=\".tb\" />");
 cycletag("tr");
 opentag("td");
 nln("Logout");
 cycletag();
 nln("<input type=\"checkbox\" name=\".sl\" onClick=\"freeRelease(this.checked,'.sa');\" />");
 cycletag();
 nln("<input type=\"checkbox\" name=\".tl\" onClick=\"freeRelease(this.checked,'.ta');\" />");
 cycletag("tr");
 opentag("td");
 nln("Max Adv");
 cycletag();
 nln("<input type=\"checkbox\" name=\".sa\" id=\".sa\" disabled=\"disabled\" />");
 cycletag();
 nln("<input type=\"checkbox\" name=\".ta\" id=\".ta\" disabled=\"disabled\" />");
 cycletag("tr");
 opentag("td");
 nln("Nuns");
 cycletag();
 nln("<input type=\"text\" class=\"unselected\" name=\"p.os.nunsVisits\" value=\""+get_property("os.nunsVisits")+"\" />");
 cycletag();
 nln("<input type=\"text\" class=\"unselected\" name=\"p.ot.nunsVisits\" value=\""+get_property("ot.nunsVisits")+"\" />");
 cycletag("tr");
 opentag("td","colspan=\"3\"");
 nln("<input type=\"submit\" name=\"submit\" value=\"Execute\" class=\"kolbut\" />");
 closetag("form");
 //"burn" run turns early.
 //"halt" disable scripts, stay logged in.
 //"logout" disable scripts, put on adv gear, log out.[Early end of night, use with burn]
 //"abort" stop running script, leave chatbot running.
 //"sleep" halt scripts, log out.
}

void footer(){
 closetag("html");
}

void topMenu(){
 print("topping");
 string tm=visit_url();
 int i=tm.index_of("&nbsp;</div>");
 write(tm.substring(0,i+6)+"<a target=mainpane href=\"topmenu.php?cp=1\">control panel</a>"+tm.substring(i));
}

void main(){
 switch(fields["cp"]){
  case "":topMenu();return;
  case "save":update();break;
  case "control":manageOST();break;
 }
 header();
 options();
 info();
 if(fields contains "load")OST(true);
 else OST(false);
 footer();
}