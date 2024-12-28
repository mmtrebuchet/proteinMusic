import std.stdio;
import std.json;
import std.math;
import std.file;
import std.array;
import std.format;
import std.getopt;


int NOTE_LEN = 32;
immutable string NOTE_NAME = "32nd";
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
    bool noteStartsTie;

    this(float[] frequencies, float dynamicVal, bool tieStart, bool tieEnd){
        this.noteStartsTie = tieStart;
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

Note[] jsonToNotes(string jsonFname){
    auto fileContents = readText(jsonFname);
    auto atomsJson = parseJSON(fileContents);
    auto numAtoms = atomsJson.array().length;
    auto notesAppender = appender!(Note[]);
    foreach(i, atom; atomsJson.array()){
        float dynamic;
        try{
            dynamic = atom["dynamic"].floating;
        }catch(JSONException e){
            dynamic = 1.0 * atom["dynamic"].integer;
        }
        auto durRemaining = atom["duration"].floating;
        float[] frequencies;
        foreach(jsonFreq; atom["freq"].array()){
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
    }
    return notesAppender[];
}

string curNoteToTimeMeasure(Note[] notes, ref int readHead, int measureNumber,
        ref char curClef, ref string curDynamic){
    //How many notes in this measure?
    auto curMeasure = appender!string;
    int numNotes = 1;
    int readStart = readHead;
    while(readHead < notes.length && notes[readHead++].noteStartsTie){numNotes++;}
    curMeasure.put(format("    <measure number=\"%s\">\n", measureNumber));
    if (readStart == 0){
        //This is the first note written.
        curMeasure.put(format("
      <attributes>
        <divisions>4</divisions>
        <key>
          <fifths>0</fifths>
          </key>
        <time print-object=\"no\">
          <beats>%s</beats>
          <beat-type>%s</beat-type>
          </time>
        <clef>
          <sign>G</sign>
          <line>2</line>
          </clef>
        </attributes>\n", numNotes, NOTE_LEN));
    }else{
        curMeasure.put(format("
      <attributes>
        <time print-object=\"no\">
          <beats>%s</beats>
          <beat-type>%s</beat-type>
          </time>
        </attributes>\n", numNotes, NOTE_LEN));
    }

    for(int noteNum = 0; noteNum < numNotes; noteNum++){
        auto note = notes[readStart + noteNum];
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
    }
    curMeasure.put("      </measure>");
    return curMeasure[];
}


string[] notesToTimeMeasures(Note[] notes){
    int readHead = 0;
    int measureNumber = 1;
    char curClef = 'G';
    string curDynamic = "ppp";
    string[] ret;
    while(readHead < notes.length){
        ret ~= curNoteToTimeMeasure(notes, readHead, measureNumber++,
                curClef, curDynamic);
    }
    return ret;
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

void runToXml(string inJson, string outXml, bool autoTime){
    auto notes = jsonToNotes(inJson);
    string[] measures;
    if (autoTime){
        measures = notesToTimeMeasures(notes);
    }else{
        measures = notesToMeasures(notes);
    }
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
