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

