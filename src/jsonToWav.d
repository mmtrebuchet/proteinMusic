import std.getopt;
import std.stdio;
import libJsonToWav;

void main(string[] args){
    string inFname;
    string outFname;
    int samplingRate = 44000;
    float dynamicsSmoothing = 0;
    int freqIdx = 0;
    auto helpInfo = getopt(args,
            "in", "The json-format input file", &inFname,
            "wav", "The wav-format output file to be written", &outFname,
            "sampling-rate", "The sampling rate of the output in Hz (default: 44000)", &samplingRate,
            "dynamics-smoothing", "How much should the dynamics values be smoothed? [0-1), default=0", &dynamicsSmoothing,
            "freq-idx", "Which frequency entry should be used? (default: 0)", &freqIdx);
    if (helpInfo.helpWanted){
        defaultGetoptPrinter("Convert a json file with frequency, duration, and dynamics into a wav file.", 
                helpInfo.options);
        return;
    }
    runToWav(inFname, outFname, samplingRate, dynamicsSmoothing, freqIdx);

}

/*     This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>. */
