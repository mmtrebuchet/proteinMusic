import std.stdio;
import std.getopt;
import libJsonToXml;


void main(string[] args){
    string outXml;
    string outCents;
    string inJson;
    string noteFname;
    auto helpInfo = getopt(
        args,
        "in", "The json-format input file", &inJson,
        "xml", "The name of the musicxml file to write", &outXml,
        "cents", "The name of the plain text file containing the cent offset for each note.", &outCents,
        "notes", "The name of the plain text file to write containing note values.", &noteFname);
    if (helpInfo.helpWanted){
        defaultGetoptPrinter("Convert a json file containing atom frequency, duration, dynamics, and chord data into a musicxml file",
                helpInfo.options);
        return;
    }
    runToXml(inJson, outXml, outCents, noteFname);
}
/*     This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>. */
