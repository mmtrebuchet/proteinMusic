import waved;
import std.json;
import std.getopt;
import std.stdio;
import std.file;
import std.math;
import std.array;

struct Wave{
    int[] atomsByTime;
    float[] frequencyByAtom;
    float[] dynamicsByAtom;
    float smoothDynamics;
    float[] wave;
    int samplingRate;
    this(string inFname, int samplingRate, int freqIdx, float smoothDynamics){
        auto fileContents = readText(inFname);
        auto atomsJson = parseJSON(fileContents);
        auto numAtoms = atomsJson.array().length;
        auto appendAtomsByTime = appender!(int[]);
        this.smoothDynamics = smoothDynamics;
        this.samplingRate = samplingRate;
        this.frequencyByAtom = new float[numAtoms];
        this.dynamicsByAtom = new float[numAtoms];
        foreach(i, atom; atomsJson.array()){
            float dynamic;
            try{
                dynamic = atom["dynamic"].floating;
            }catch(JSONException e){
                dynamic = 1.0 * atom["dynamic"].integer;
            }
            if (dynamic == 0.0){
                dynamic = 0.01;
            }
            this.dynamicsByAtom[i] = dynamic;
            this.frequencyByAtom[i] = atom["freq"][freqIdx].floating;
            for(int j = 0; j < atom["duration"].floating * samplingRate; j++){
                appendAtomsByTime.put(cast(int) i);
            }
        }
        this.atomsByTime = appendAtomsByTime[];
        this.wave = new float[this.atomsByTime.length];
    }

    void applyFrequency(){
        ///Apply the frequencyByAtom to the atomsByTime to generate the base wave without dynamics.
        double φ = 0;
        double freq = this.frequencyByAtom[0];
        foreach(i, int atomIdx; this.atomsByTime){
            auto newFreq = this.frequencyByAtom[atomIdx];
            freq = this.smoothDynamics * freq + (1 - this.smoothDynamics) * newFreq;
            double Δφ = freq * 2 * PI / this.samplingRate;
            φ += Δφ;
            if (φ > 2 * PI){
                φ -= 2 * PI;
            }
            this.wave[i] = sin(φ) * 0.3;
        }
    }

    void applyDynamics(){
        double curDynamic = this.dynamicsByAtom[0];
        foreach(i, int atomIdx; this.atomsByTime){
            double newDynamic = this.dynamicsByAtom[atomIdx];
            curDynamic = this.smoothDynamics * curDynamic + (1 - this.smoothDynamics) * newDynamic;
            this.wave[i] *= curDynamic;
        }
    }

    void save(string fname){
        float[][] channels = [this.wave];
        Sound(this.samplingRate, channels).encodeWAV(fname);
    }
}

void runToWav(string inFname, string outFname, int samplingRate, float dynamicsSmoothing, int freqIdx){
    auto wave = Wave(inFname, samplingRate, freqIdx, dynamicsSmoothing);
    wave.applyFrequency();
    wave.applyDynamics();
    wave.save(outFname);
}
/*     This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>. */
