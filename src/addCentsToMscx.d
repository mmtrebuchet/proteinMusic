import std.stdio;
import std.regex;
import std.getopt;
import std.conv;
auto noteTpcRe = ctRegex!("<tpc>[0-9]*</tpc>");

void main(string[] args){
    string inXmlFname;
    string centFname;
    string outXmlFname;
    auto helpInfo = getopt(args,
            "in", "The name of the xml file to be edited.", &inXmlFname,
            "cents", "The name of the file with cents data.", &centFname,
            "out", "The name of the musescore xml file to write.", &outXmlFname);
    if(helpInfo.helpWanted){
        defaultGetoptPrinter("Take an existing musescore xml file (not musicxml) and add cent offsets to get the right microtones.",
                helpInfo.options);
        return;
    }

    int[] centOffsets;
    auto inCentFp = File(centFname, "r");
    foreach(line; inCentFp.byLine()){
        centOffsets ~= to!int(line);
    }

    auto inXmlFp = File(inXmlFname, "r");
    auto outXmlFp = File(outXmlFname, "w");
    int readHead = 0;
    foreach(line; inXmlFp.byLine()){
        outXmlFp.writeln(line);
        auto m = matchAll(line, noteTpcRe);
        if(!m.empty){
            outXmlFp.writefln("        <tuning>%s</tuning>", centOffsets[readHead++]);
        }
    }
}


/*     This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>. */
