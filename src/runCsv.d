import std.csv;
import libPdbToJson;
import libJsonToXml;
import libJsonToWav;
import libJsonToDat;
import libDatToXyz;
import std.file;
import std.stdio;
import std.conv;
import std.regex;
import std.format;
import std.array;
struct csvRow{
    string baseName;
    string pdbFname;
    string jsonFname;
    char chain;
    float middleFrequency;
    float octavesPerAngstrom;
    float middleLength;
    float durationFoldPerAngstrom;
    float coordCutoff;
    float harmonicsOctavesPerAngstrom;
    string dynamicsAxis;
    string frequencyAxis;
    string durationAxis;
    string harmonicsAxis;
    bool allBackbone;
    string xmlFname;
    string noteFname;
    string wavFname;
    int samplingRate;
    float dynamicsSmoothing;
    int freqIdx;
    string xyzFname;
    bool autoTime;
}

char toChr(string s){
    if(s.length){
        return s[0];
    }else{
        return '\0';
    }
}

void printFields(T)(T args)
{
    auto values = args.tupleof;

    size_t max;
    size_t temp;
    foreach (index, value; values){
        temp = T.tupleof[index].stringof.length;
        if (max < temp) max = temp;
    }
    max += 1;
    foreach (index, value; values){
        writefln("%-" ~ to!string(max) ~ "s %s", T.tupleof[index].stringof, value);
    }
}

string normString(string arg, char chainChar, string baseName){
    string chain = format("%s", chainChar);
    string retBase = replaceAll(arg, regex("BASE"), baseName);
    string retChain = replaceAll(retBase, regex("CHAIN"), chain);
    return retChain;
}

void runRender(File outFp, string pdbFname, char chain, string jsonFname){
    auto outName = jsonFname.split("/")[$-1][0..$-5];
    outFp.writefln("vmd -e src/makeRender.vmd -args %s %s %s", pdbFname, chain, outName);
    outFp.writefln("convert -trim render/%s.tga render/%s.png", outName, outName);
}



void runRecord(csvRow r, File renderFile){
    r.pdbFname = normString(r.pdbFname, r.chain, r.baseName);
    r.jsonFname = normString(r.jsonFname, r.chain, r.baseName);
    r.xmlFname = normString(r.xmlFname, r.chain, r.baseName);
    r.noteFname = normString(r.noteFname, r.chain, r.baseName);
    r.wavFname = normString(r.wavFname, r.chain, r.baseName);
    r.xyzFname = normString(r.xyzFname, r.chain, r.baseName);

    /* printFields(r); */
    writefln("Score name: %s", r.xmlFname);

    runToJson(r.pdbFname, r.chain, r.allBackbone, toChr(r.dynamicsAxis),
            toChr(r.frequencyAxis), toChr(r.durationAxis), toChr(r.harmonicsAxis),
            r.coordCutoff, r.middleFrequency, r.octavesPerAngstrom,
            r.middleLength, r.durationFoldPerAngstrom,
            r.harmonicsOctavesPerAngstrom, r.jsonFname);

    runToXml(r.jsonFname, r.xmlFname, r.autoTime);

    jsonToNotes(r.jsonFname, r.noteFname);

    runToWav(r.jsonFname, r.wavFname, r.samplingRate, r.dynamicsSmoothing,
            r.freqIdx);

    runRender(renderFile, r.pdbFname, r.chain, r.jsonFname);
    if(r.harmonicsAxis == ""){
        runToXyz(r.noteFname, r.xyzFname, r.middleFrequency, r.octavesPerAngstrom,
                 r.middleLength, r.durationFoldPerAngstrom, r.coordCutoff);
    }
}


void main(string[] args){
    //The name of the csv file is always the first argument.
    if (args.length < 2){
        writeln("Usage: runToCsv settings.csv");
        return;
    }
    auto header = ["baseName", "pdbFname", "jsonFname", "chain", "middleFrequency",
         "octavesPerAngstrom", "middleLength", "durationFoldPerAngstrom",
         "coordCutoff", "harmonicsOctavesPerAngstrom", "dynamicsAxis",
         "frequencyAxis", "durationAxis", "harmonicsAxis", "allBackbone",
         "xmlFname", "noteFname", "wavFname", "samplingRate", "dynamicsSmoothing",
         "freqIdx", "xyzFname", "autoTime"];
    auto csvContents = readText(args[1]);
    auto records = array(csvReader!csvRow(csvContents, header));
    auto renderFile = File("render.sh", "w");
    foreach(i, record; records){
        writefln("");
        runRecord(record, renderFile);
    }
}
/*     This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>. */
