import std.csv;
import std.conv;
import std.math;
import std.stdio;
import std.file;
import std.array;

struct atom{
    int idx;
    float x;
    float y;
    float z;
    string noteSeq;
    string dynamicStr;
    string noteHeads;
    float duration;
    string freqs;
    float dynamic;
}

float logToPosition(float value, float middle, float foldPerAngstrom){
    //freq = m * 2^(x * octPerAng)
    //log2(freq / m) / octPerAng = x
    return log2(value/middle) / foldPerAngstrom;
}

float dynamicToPosition(float dynamic, float cutoff){
    return dynamic * 2 * cutoff;
}


void runToXyz(string datFname, string xyzFname, float middleFrequency, float octavesPerAngstrom,
              float middleDuration, float durationFoldPerAngstrom, float coordCutoff){
    auto inText = readText(datFname);
    auto outFp = File(xyzFname, "w");
    auto records = array(csvReader!atom(inText));
    outFp.writefln("%s\n", records.length);
    foreach(r; records){
        auto z = logToPosition(to!float(r.freqs[1..$-1]), middleFrequency, octavesPerAngstrom);
        auto x = logToPosition(r.duration, middleDuration, durationFoldPerAngstrom);
        auto y = dynamicToPosition(r.dynamic, coordCutoff);

        outFp.writefln("CA %s %s %s", x, y, z);
    }
}


