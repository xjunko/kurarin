CC        = gcc
VCC       = thirdparty/v/v
VCC_FLAGS = -enable-globals -cc $(CC)
OUT      = kurarin

ROOT   = .
ASSETS = assets
SHADER_LVL = glsl410

.PHONY: default
default:
	@echo "available targets: "
	@echo "    - debug            // build debug version"
	@echo "    - prod             // build production version"
	@echo "    - clean            // remove build artifacts"
	@echo "    - clean-bootstrap  // remove bootstrap artifacts"
	@echo "    - format           // format source code"
	@echo "    - run              // run the built executable"
	@echo "    - all              // build everything (bootstrap + debug)"

$(VCC):
	$(MAKE) -C thirdparty

$(ASSETS)/osu/shaders/slider.h: $(VCC)
	$(VCC) shader $(ASSETS)/osu/shaders/ -l $(SHADER_LVL)

$(OUT): $(VCC) clean format $(ASSETS)/osu/shaders/slider.h
	$(VCC) $(VCC_FLAGS) -o $(OUT) $(ROOT)

debug: $(VCC) clean format $(ASSETS)/osu/shaders/slider.h
	$(VCC) $(VCC_FLAGS) -cg -g -d trace_sokol_memory -o $(OUT) $(ROOT)

prod: $(VCC) clean format $(ASSETS)/osu/shaders/slider.h
	$(VCC) $(VCC_FLAGS) -prod -o $(OUT) $(ROOT)

clean:
	rm -f $(OUT) $(ASSETS)/osu/shaders/*.h

clean-bootstrap:
	$(MAKE) -C thirdparty clean

format:
	$(VCC) fmt -w $(ROOT)/src

run: $(OUT)
	./$(OUT)

