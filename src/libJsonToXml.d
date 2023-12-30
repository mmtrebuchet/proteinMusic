import std.stdio;
import std.json;
import std.math;
import std.file;
import std.array;
import std.format;
import std.getopt;


int NOTE_LEN = 64;
immutable string NOTE_NAME = "64th";
string REST_NOTE = format("
      <note>
        <rest />
        <duration>1</duration>
        <voice>1</voice>
        <type>%s</type>
        </note>", NOTE_NAME);
struct Note{
    char[] notes;
    long[] octaves;
    float[] alters;
    long[] cents;
    string tieBlock;
    string notationBlock;
    float dynamicVal;
    long noteNumber;
    bool tieEnd;
    string dynamic;

    this(float[] frequencies, float dynamicVal, bool tieStart, bool tieEnd){
        foreach(frequency; frequencies){
            this.setNote(frequency);
        }
        this.dynamicVal = dynamicVal;
        this.setTies(tieStart, tieEnd);
        this.tieEnd = tieEnd;
        this.setDynamic(dynamicVal);
    }

    void setDynamic(float dynamicVal){
        auto dynamicsStrings = ["pp", "p", "mp", "mf", "f", "ff"];
        //Reserve ppp and fff for 0 and 1, and interpolate otherwise.
        if (dynamicVal == 0) {this.dynamic = "ppp";}
        else if (dynamicVal == 1) {this.dynamic = "fff";}
        else {
            auto dynamicValue = rndtol(floor(dynamicVal * dynamicsStrings.length));
            this.dynamic = dynamicsStrings[dynamicValue];
        }
    }
    void setTies(bool start, bool end){
        string tieStart = "        <tie type=\"start\"/>";
        string tieEnd =   "        <tie type=\"stop\"/>";
        string notateStart = "<tied type=\"start\"/>";
        string notateEnd =   "<tied type=\"stop\"/>";
        string notateFmt = "<notations>
            %s
            %s
        </notations>";
        if(start && end){
            this.tieBlock = tieEnd ~ tieStart;
            this.notationBlock = format(notateFmt, notateEnd, notateStart);
        }else if (start){
            this.tieBlock = tieStart;
            this.notationBlock = format(notateFmt, "", notateStart);
        }else if(end){
            this.tieBlock = tieEnd;
            this.notationBlock = format(notateFmt, notateEnd, "");
        }else{
            this.tieBlock = "";
            this.notationBlock = "";
        }
    }

    void setNote(float frequency){
        auto notes = ["An", "As", "Bn", "Cn", "Cs", "Dn", "Ds", "En", "Fn", "Fs", "Gn", "Gs"];
        auto noteNumberPre = 12*log2(frequency/440.) + 49;
        long noteNumber = rndtol(noteNumberPre);
        if (this.noteNumber == 0){
            this.noteNumber = noteNumber;
        }
        auto centsAdjust = rndtol((noteNumberPre - noteNumber)*100);
        auto noteIdx = (noteNumber - 1) % notes.length;
        auto note = notes[noteIdx];
        this.octaves ~= (noteNumber + 8) / notes.length;
        this.notes ~= note[0];
        if(note[1] == 's'){
            this.alters ~= 1;
        }else{
            this.alters ~= 0;
        }
        auto deltaAlter = round (0.01*centsAdjust * 2) / 2;
        this.alters[$-1] += deltaAlter;
        this.cents ~= rndtol(centsAdjust - deltaAlter * 100);
        if(this.tieEnd) this.alters[$-1] = 0;
    }

    string toXml(){
        auto fmtStr =
"      <note>
        %s
        <pitch>
          <step>%s</step>
          <alter>%s</alter>
          <octave>%s</octave>
          </pitch>
        <duration>1</duration>
%s
        <voice>1</voice>
        <type>%s</type>
        %s
        </note>
";
        string chordStr = "";
        auto ret = appender!string;
        foreach(i; 0..this.notes.length){
            ret.put(format(fmtStr, chordStr, this.notes[i], this.alters[i],
                        this.octaves[i], this.tieBlock,
                        NOTE_NAME, this.notationBlock));
            chordStr = "<chord/>";
        }
        return ret[];
    }

}

string numToDur(float duration){
    char[] ret;
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
    while (duration > 1./8.){
        ret ~= "\U0001D160 ";
        duration -= 1./8.;
    }
    while (duration > 1./16.){
        ret ~= "\U0001D161 ";
        duration -= 1./16.;
    }
    while (duration > 1/32.){
        ret ~= "\U0001D162 ";
        duration -= 1./32.;
    }
    while (duration > 1./64.){
        ret ~= "\U0001D163 ";
        duration -= 1./64.;
    }
    while (duration > 1./128.){
        ret ~= "\U0001D164 ";
        duration -= 1./128.;
    }
    return ret.idup;
}

string noteToPitches(float[] freqs){
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
    }
    return format("%s", ret);
}

Note[] jsonToNotes(string jsonFname, string noteFname){
    auto fileContents = readText(jsonFname);
    auto atomsJson = parseJSON(fileContents);
    auto numAtoms = atomsJson.get!(JSONValue[]).length;
    auto notesAppender = appender!(Note[]);
    File outNotes;
    if(noteFname.length){
        //We want to write notes.
        outNotes = File(noteFname, "w");
    }
    foreach(i, atom; atomsJson.get!(JSONValue[])){
        float dynamic;
        try{
            dynamic = atom["dynamic"].floating;
        }catch(JSONException e){
            dynamic = 1.0 * atom["dynamic"].integer;
        }
        auto durRemaining = atom["duration"].floating;
        float[] frequencies;
        foreach(jsonFreq; atom["freq"].get!(JSONValue[])){
            frequencies ~= jsonFreq.floating;
        }
        notesAppender.put(Note(frequencies, dynamic, true, false));
        durRemaining -= 1./ NOTE_LEN;
        while(durRemaining > 1./NOTE_LEN){
            notesAppender.put(Note(frequencies, dynamic, true, true));
            durRemaining -= 1./NOTE_LEN;
        }
        auto lastNote = Note(frequencies, dynamic, false, true);
        notesAppender.put(lastNote);
        if(noteFname.length){
            //We want to write an entry to the note file.
            outNotes.writefln("%5s %8.3f %8.3f %8.3f %15s %3s %14s", i,
                    atom["x"].floating, atom["y"].floating, atom["z"].floating, 
                    noteToPitches(frequencies), lastNote.dynamic,
                     numToDur(atom["duration"].floating));
        }
            
    }
    return notesAppender[];
}

string[] notesToMeasures(Note[] notes){
    string[] measures;
    int readHead = 0;
    char curClef = 'G';
    string curDynamic = "ppp";
    for(int measureNumber = 1; measureNumber <= notes.length / NOTE_LEN+1; measureNumber++){
        auto curMeasure = appender!string;
        curMeasure.put(format("    <measure number=\"%s\">\n", measureNumber));
        if (measureNumber == 1){
            //We're in the first measure - put in a time signature and key signature.
            curMeasure.put("
      <attributes>
        <divisions>4</divisions>
        <key>
          <fifths>0</fifths>
          </key>
        <time>
          <beats>4</beats>
          <beat-type>4</beat-type>
          </time>
        <clef>
          <sign>G</sign>
          <line>2</line>
          </clef>
        </attributes>\n");
        }

        for(int noteNum = 0; noteNum < NOTE_LEN; noteNum++){
            if (readHead < notes.length){
                auto note = notes[readHead++];
                if (note.dynamic != curDynamic){
                    curMeasure.put(format("
            <direction placement=\"below\">
              <direction-type>
                <dynamics>
                  <%s/>
                  </dynamics>
                </direction-type>
              <sound dynamics=\"%s\"/>
              </direction>", note.dynamic, note.dynamicVal*50+75));
                    curDynamic = note.dynamic;
                }
                if (note.noteNumber < 40 && curClef == 'G'){
                    curMeasure.put("<attributes> <clef> <sign>F</sign><line>4</line></clef></attributes>");
                    curClef = 'F';
                }else if (note.noteNumber > 45 && curClef == 'F'){
                    curMeasure.put("<attributes> <clef> <sign>G</sign><line>2</line></clef></attributes>");
                    curClef = 'G';
                }
                curMeasure.put(note.toXml());
            }else{
                curMeasure.put(REST_NOTE);
            }
        }
        curMeasure.put("      </measure>");
        measures ~= curMeasure[];
    }
    return measures;
}

void runToXml(string inJson, string outXml, string outCents, string noteFname){
    auto notes = jsonToNotes(inJson, noteFname);
    if(outCents.length){
        auto outCentsFp = File(outCents, "w");
        foreach(note; notes){
            outCentsFp.writeln(note.cents);
        }
        outCentsFp.close();
    }
    auto measures = notesToMeasures(notes);
    auto header = readText("src/header.xml");
    auto outFp = File(outXml, "w");
    outFp.writeln(header);
    foreach(m; measures){
        outFp.writeln(m);
    }
    outFp.writeln("    </part>\n  </score-partwise>");
    outFp.close();
}
/*     This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>. */
