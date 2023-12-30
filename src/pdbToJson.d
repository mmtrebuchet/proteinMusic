import std.stdio;
import std.getopt;
import libPdbToJson;

void main(string[] args){
    float middleFrequency = 440;
    float octavesPerAngstrom = 0.1;
    float harmonicsOctavesPerAngstrom = 0.03;
    float middleLength = 1.0;
    float coordCutoff = 20;
    float durationFoldPerAngstrom = 0.1;
    string pdbFname, outJson;
    char chain;
    bool allBackbone = false;
    //If these axes aren't set, then the default parameters will be used.
    char dynamicsAxis, frequencyAxis, durationAxis, harmonicsAxis;
    dynamicsAxis = frequencyAxis = durationAxis = harmonicsAxis = 0;
    

    auto helpInfo = getopt(args,
        "pdb-file", "The name of the pdb file to load", &pdbFname,
        "json-file", "The name of the output json file to generate", &outJson,
        "chain", "The chain in the PDB file to use", &chain,
        "middle-frequency", "The frequency for an atom at the origin. (default: 440)", &middleFrequency,
        "octaves-per-angstrom", "How many octaves are included in one angstrom? (default: 0.1)", &octavesPerAngstrom,
        "duration-fold-per-angstrom", "How many times longer should a note get per angstrom? (default: 0.1)", &durationFoldPerAngstrom,
        "middle-length", "How long should an atom at the origin last, in seconds? (default: 1.0)", &middleLength,
        "coord-cutoff", "What is the maximal coordinate that should be used for harmonics and dynamics? (default: 20)", &coordCutoff,
        "harmonics-octaves-per-angstrom", "How many octaves per angstrom for calculating harmonics? (default 0.02)", &harmonicsOctavesPerAngstrom,
        "dynamics", "What axis should be used for dynamics?", &dynamicsAxis,
        "frequency", "What axis should be used for frequency?", &frequencyAxis,
        "duration", "What axis should be used for duration?", &durationAxis,
        "harmonics", "What axis should be used to generate harmonics?", &harmonicsAxis,
        "all-backbone", "Instead of just CA atoms, use all backbone atoms", &allBackbone);
    if (helpInfo.helpWanted){
        defaultGetoptPrinter("Converts a pdb file into a json that can be converted into audio or notation.",
                helpInfo.options);
        return;
    }

    runToJson(pdbFname, chain, allBackbone, dynamicsAxis,
               frequencyAxis, durationAxis, harmonicsAxis, 
               coordCutoff,
               middleFrequency, octavesPerAngstrom,
               middleLength, durationFoldPerAngstrom,
               harmonicsOctavesPerAngstrom, 
               outJson);
}

