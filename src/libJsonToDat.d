import std.stdio;
import std.json;
import std.math;
import std.math.rounding;
import std.file;
import std.array;
import std.format;
import std.getopt;
import libJsonToXml; // : NOTE_LEN;


string numToDynamic(float dynamicVal, out float reversed){
    auto dynamicsStrings = ["pp", "p", "mp", "mf", "f", "ff"];
    //Reserve ppp and fff for 0 and 1, and interpolate otherwise.
    reversed = round(dynamicVal * (dynamicsStrings.length + 2)) / 
                     (1.0 * (dynamicsStrings.length + 2));
    if (dynamicVal == 0) {return "ppp";}
    else if (dynamicVal == 1) {return "fff";}
    else {
        auto dynamicValue = rndtol(floor(dynamicVal * dynamicsStrings.length));
        return dynamicsStrings[dynamicValue];
    }
}

string numToDur(float inDuration, out float roundedDuration){
    char[] ret;
    float duration = inDuration;
    while (duration > 1){
        ret ~= "\U0001D15D ";
        duration -= 1;
    }
    while (duration > 0.5){
        ret ~= "\U0001D15E ";
        duration -= 0.5;
    }
    while (duration > 1./4.){
        ret ~= "\U0001D15F ";
        duration -= 1./4.;
    }
    while (NOTE_LEN >= 8 && duration > 1./8.){
        ret ~= "\U0001D160 ";
        duration -= 1./8.;
    }
    while (NOTE_LEN >= 16 && duration > 1./16.){
        ret ~= "\U0001D161 ";
        duration -= 1./16.;
    }
    while (NOTE_LEN >= 32 && duration > 1/32.){
        ret ~= "\U0001D162 ";
        duration -= 1./32.;
    }
    while (NOTE_LEN >= 64 && duration > 1./64.){
        ret ~= "\U0001D163 ";
        duration -= 1./64.;
    }
    while (NOTE_LEN >= 128 && duration > 1./128.){
        ret ~= "\U0001D164 ";
        duration -= 1./128.;
    }
    roundedDuration = inDuration - duration;
    return ret.idup;
}

string noteToPitches(float[] freqs, out float[] outFreqs){
    string[] ret;
    auto notes = ["A", "A\u266F", "B", "C", "C\u266F",
         "D", "D\u266F", "E", "F", "F\u266F", "G", "G\u266F"];
    foreach(freq; freqs){
        float note_number_pre = 12 * log2(freq / 440) + 49;
        auto note_number = rndtol(note_number_pre);
        //print(note_number)
        auto cents = rndtol((note_number_pre - note_number)*100);
        auto note = (note_number - 1 ) % notes.length;
        string noteStr = notes[note];

        auto octave = (note_number + 8 ) / notes.length;
        ret ~= format("%s%d %+d", noteStr, octave, cents);
        //Now we reverse the calculation. 
        //We have microtones available. Microtones are rounded to the nearest quarter-tone
        //for presentation. 
        // note = 12 log2 (f/440) + 49
        // (note - 49)/12 = log2 (f/440)
        // f = 440 * 2^(n-49/12)
        auto alter = round(0.01 * cents * 2) / 2;
        float reverseNoteNumber = note_number + alter;
        auto reconstructedFrequency = 440. * exp2((reverseNoteNumber - 49.) / 12.);
        outFreqs ~= reconstructedFrequency;
    }
    return format("%s", ret);
}

void jsonToNotes(string jsonFname, string noteFname){
    auto fileContents = readText(jsonFname);
    auto atomsJson = parseJSON(fileContents);
    auto numAtoms = atomsJson.array().length;
    auto outNotes = File(noteFname, "w");
    float minFreq = 1000000;
    float maxFreq = 0;
    float totalDuration = 0;
    foreach(i, atom; atomsJson.array()){
        float dynamic;
        try{
            dynamic = atom["dynamic"].floating;
        }catch(JSONException e){
            dynamic = 1.0 * atom["dynamic"].integer;
        }
        float[] frequencies;
        foreach(jsonFreq; atom["freq"].array()){
            float curFreq = jsonFreq.floating;
            if (curFreq > maxFreq){
                maxFreq = curFreq;
            }
            if (curFreq < minFreq){
                minFreq = curFreq;
            }
            frequencies ~= curFreq;
        }
        float roundDuration;
        float[] freqReversed;
        auto dur = numToDur(atom["duration"].floating, roundDuration);
        totalDuration += roundDuration;
        auto pitches = noteToPitches(frequencies, freqReversed);
        //We want to write an entry to the note file.
        auto freqList = format("%s", pitches)[1..$-1];
        float reverseDynamic;
        auto dynamicStr = numToDynamic(dynamic, reverseDynamic);
        outNotes.writefln("%s,%.3f,%.3f,%.3f,%s,%s,%s,%s,%s,%s", i,
                atom["x"].floating, atom["y"].floating, atom["z"].floating,
                freqList, dynamicStr, dur,
                roundDuration, freqReversed, reverseDynamic);
    }
    float[] unused;
    auto noteRange = noteToPitches([minFreq, maxFreq], unused);
    auto minPitch = noteRange.split(" ")[0][2..$];
    auto maxPitch = noteRange.split(" ")[2][1..$];
    writefln("Range: %s - %s", minPitch, maxPitch);
    writefln("Measures at 4/4: %s", ceil(totalDuration));
}


/*     This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>. */
