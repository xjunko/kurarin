CC := clang

V_COMMIT  := a2f65c69777e5549981fd5538cf1279c4309ceaa
VC_COMMIT := f0985b08bbbe20f8998ed5145e244c3cdf14c3c1

.PHONY: all
all: v/v v/cmd/tools/vshader
	@echo bootstraped.

clean:
	rm -rf v/

v:
	rm -rf v.tmp
	git clone https://github.com/vlang/v v.tmp
	git -C v.tmp checkout -b v-2025-08-08 $(V_COMMIT)
	mv v.tmp v

v/vc: | v
	rm -rf v/vc.tmp
	git clone --filter=blob:none https://github.com/vlang/vc v/vc.tmp
	git -C v/vc.tmp fetch origin
	git -C v/vc.tmp checkout $(VC_COMMIT)
	mv v/vc.tmp v/vc

v/v: | v/vc
	sed -i '140c\ifndef local_vc' v/GNUmakefile
	local_vc=1 $(MAKE) -C v -f GNUmakefile

v/cmd/tools/vshader: | v/v
	./v/v -cc $(CC) v/cmd/tools/vshader.v

.DELETE_ON_ERROR: