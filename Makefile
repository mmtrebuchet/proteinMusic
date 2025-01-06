/dev/shm/pdbToJson: src/pdbToJson.d src/libPdbToJson.d
	gdc -o$@ $^

/dev/shm/jsonToDat: src/jsonToDat.d src/libJsonToDat.d src/libJsonToXml.d
	gdc -o$@ $^

/dev/shm/jsonToWav: src/jsonToWav.d src/libJsonToWav.d src/waved/detect.d src/waved/package.d src/waved/utils.d src/waved/wav.d
	gdc -o$@ $^

/dev/shm/jsonToXml: src/jsonToXml.d src/libJsonToXml.d
	gdc -o$@ $^

/dev/shm/datToXyz: src/datToXyz.d src/libDatToXyz.d
	gdc -o$@ $^

/dev/shm/runCsv: src/runCsv.d src/libPdbToJson.d src/libJsonToXml.d src/libJsonToWav.d  src/waved/detect.d src/waved/package.d src/waved/utils.d src/waved/wav.d src/libJsonToDat.d src/libDatToXyz.d
	gdc -o$@ $^

json:
	mkdir -p json
output:
	mkdir -p output
scores:
	mkdir -p scores
wav:
	mkdir -p wav

clean:
	rm -r json output scores wav

music: all sample.csv
	/dev/shm/runCsv sample.csv

hiv: all hiv.csv
	/dev/shm/runCsv hiv.csv

all: /dev/shm/jsonToXml /dev/shm/jsonToWav /dev/shm/pdbToJson /dev/shm/runCsv /dev/shm/jsonToDat json output scores wav /dev/shm/datToXyz
