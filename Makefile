CC        = gcc
VCC       = v
VCC_FLAGS = -enable-globals -cc $(CC)
OUT      = kurarin

ROOT   = ./src
ASSETS = assets
SHADER_LVL = glsl410

all: $(OUT) 

$(ASSETS)/osu/shaders/slider.h:
	$(VCC) shader $(ASSETS)/osu/shaders/ -l $(SHADER_LVL)

$(OUT): clean format $(ASSETS)/osu/shaders/slider.h
	$(VCC) $(VCC_FLAGS) -o $(OUT) $(ROOT)

debug: clean format $(ASSETS)/osu/shaders/slider.h
	$(VCC) $(VCC_FLAGS) -cg -g -d trace_sokol_memory -o $(OUT) -show-c-output $(ROOT)

prod: clean format $(ASSETS)/osu/shaders/slider.h
	$(VCC) $(VCC_FLAGS) -prod -o $(OUT) $(ROOT)

release: $(OUT)
	wget https://hatsune-miku.has.rocks/r/hikari.zip 
	mkdir assets/osu/maps/hikari -p
	unzip hikari.zip -d assets/osu/maps/hikari 

	mkdir build -p
	mkdir build/assets -p
	mkdir build/assets/osu -p
	mkdir build/assets/osu/maps/hikari -p

	cp kurarin build/ -r
	cp assets/common build/assets/ -r
	cp assets/osu/shaders build/assets/osu/shaders -r
	cp assets/osu/skins build/assets/osu/skins -r
	cp assets/osu/maps/hikari build/assets/osu/maps -r

	cd build
	zip -r ../linux_x64.zip .
	cd ..
	rm -rf build/

clean: $(OUT)
	echo "CLEAN"
	# rm -f $(OUT) $(ASSETS)/osu/shaders/*.h

format:
	$(VCC) fmt -w $(ROOT)

run: $(OUT)
	./$(OUT)

