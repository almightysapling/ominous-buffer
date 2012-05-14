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
 nln("<br/>"+text);
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

void update(){
 matcher m;
 foreach var,val in fields{
  m=create_matcher("(.+?)\\.(.+?)$",var);
  if(!m.find())continue;
  switch(m.group(1)){
   case "prop":set_property(m.group(2),val);break;
  }
 }
}

void header(){
 writeln("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">");
 opentag("html");
 opentag("head");
 opentag("style","type=\"text/css\"");
 writeln(".optGroup {font-weight: bold;}");
 writeln(".kolbut {border: 2px solid black; font-family:Arial,Helvetica,sans-serif; font-size:10pt; font-weight: bold; background-color: white;}");
 closetag();
 closetag();
 opentag("body");
}

void options(){
 opentag("form","method=\"post\" action=\""+__FILE__+"\"");
 nln("<input type=\"hidden\" name=\"save\" value=\"yes\">");
 nln("<span class=\"optGroup\">Ominous Buffer</span>");
 ntln("Stuff to put here: admins, lotto values, NUNS VISITS!, idk, whatever");
 ntln("<span class=\"optGroup\">Current Host Only</span>");
 ntln("Host Name: <input type=\"text\" name=\"prop.hostName\" value=\""+get_property("hostName")+"\">");
 ntln("Stuff to put here: not much else?");
 ntln("<input type=\"submit\" name=\"submit\" value=\"Save\" class=\"kolbut\">");
 closetag("form");
}

void footer(){
 closetag("html");
}

void main(){
 if(fields contains "save") update();
 header();
 options();
 footer();
}