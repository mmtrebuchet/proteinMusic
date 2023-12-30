import std.stdio;
import std.conv;
import std.json;
import std.math;
import std.algorithm.iteration;
import std.getopt;
import std.string;
import std.algorithm;

struct Pdb{
    float[] x, y, z;
    float[] durations;
    float[][] frequency;
    float[] dynamics;
    this(string inFname, char chain, bool allBackbone){
        auto atomStrings = ["CA"];
        if (allBackbone){
            atomStrings ~= ["N ", "C "];
        }
        auto fp = File(inFname, "r");
        foreach(line; fp.byLineCopy()){
            if(line.length > 4 && line[0..4] == "ATOM"){
                //We're in an atom record.
                if(line[21] == chain &&
                        atomStrings.canFind(line[13..15])){
                    //And we hit an alpha carbon on the right chain.
                    this.x ~= to!float(strip(line[30..38]));
                    this.y ~= to!float(strip(line[38..46]));
                    this.z ~= to!float(strip(line[46..54]));
                }
            }
        }
        this.durations = new float[x.length];
        this.dynamics = new float[this.x.length];
        this.frequency = new float[][this.x.length];
        auto xMean = mean(this.x);
        auto yMean = mean(this.y);
        auto zMean = mean(this.z);

        foreach(i; 0..this.x.length){
            this.durations[i] = 1;
            this.dynamics[i] = 0.5;
            this.frequency[i] ~= 440;
            this.x[i] -= xMean;
            this.y[i] -= yMean;
            this.z[i] -= zMean;
        }
        writefln("(min max)");
        writefln("X (%s %s)", minElement(this.x), maxElement(this.x));
        writefln("Y (%s %s)", minElement(this.y), maxElement(this.z));
        writefln("Z (%s %s)", minElement(this.z), maxElement(this.z));
    }

    void loadDurations(float[] data, float middleLength, float durationFoldPerAngstrom){
        foreach(i, val; data){
            auto duration = middleLength * exp2(val*durationFoldPerAngstrom);
            this.durations[i] = duration;
        }
    }

    void loadFrequency(float[] data, float middleFrequency, float octavesPerAngstrom){
        foreach(i, val; data){
            auto freq = middleFrequency * exp2(val * octavesPerAngstrom);
            this.frequency[i][0] = freq;
        }
    }

    void loadDynamics(float[] data, float coordCutoff){
        foreach(i, val; data){
            if (val < -coordCutoff) val = -coordCutoff;
            if (val > coordCutoff) val = coordCutoff;
            this.dynamics[i] = (val + coordCutoff) / (2 * coordCutoff);
        }
    }

    void scaleFrequency(float[] data, float octavesPerAngstrom){
        foreach(i, val; data){
            /*if (val < -coordCutoff) val = -coordCutoff;
            if (val > coordCutoff) val = coordCutoff;*/
            auto newFrequency = this.frequency[i][0] * exp2(val * octavesPerAngstrom);
            this.frequency[i] ~= newFrequency;
        }
    }

    float[] getAxis(char axis){
        switch (axis){
            case 'x':
                return this.x;
            case 'y':
                return this.y;
            case 'z':
                return this.z;
            default:
                throw new Exception("coordinate must be one of 'x', 'y', or 'z'.");
        }
    }

    JSONValue toJson(){
        JSONValue[] atoms;
        foreach(i; 0..this.x.length){
            auto newAtom = JSONValue(["duration" : JSONValue(this.durations[i]),
                                    "freq" : JSONValue(this.frequency[i]),
                                    "dynamic" : JSONValue(this.dynamics[i]),
                                    "x": JSONValue(this.x[i]),
                                    "y": JSONValue(this.y[i]),
                                    "z": JSONValue(this.z[i]),
            ]);
            atoms ~= newAtom;
        }
        return JSONValue(atoms);
    }
}

void runToJson(string pdbFname, char chain, bool allBackbone, char dynamicsAxis,
               char frequencyAxis, char durationAxis, char harmonicsAxis, 
               float coordCutoff,
               float middleFrequency, float octavesPerAngstrom,
               float middleLength, float durationFoldPerAngstrom,
               float harmonicsOctavesPerAngstrom, 
               string outJson){
    auto pdb = Pdb(pdbFname, chain, allBackbone);
    if (dynamicsAxis){
        pdb.loadDynamics(pdb.getAxis(dynamicsAxis), coordCutoff);
    }
    if (frequencyAxis){
        pdb.loadFrequency(pdb.getAxis(frequencyAxis), middleFrequency, octavesPerAngstrom);
    }
    if (durationAxis){
        pdb.loadDurations(pdb.getAxis(durationAxis), middleLength, durationFoldPerAngstrom);
    }
    if (harmonicsAxis){
        pdb.scaleFrequency(pdb.getAxis(harmonicsAxis), harmonicsOctavesPerAngstrom);
    }

    auto json = pdb.toJson();
    auto outFp = File(outJson, "w");
    outFp.writeln(json.toString);
    outFp.close();
}

/*     This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>. */
