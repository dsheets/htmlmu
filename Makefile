.PHONY: build install uninstall reinstall clean

FINDLIB_NAME=htmlmu
LIB_NAME=htmlmu
BUILD=_build

HAS_CMDLINER := $(shell ocamlfind query cmdliner > /dev/null; echo $$?)

COMMON_MLI=lib/*.mli $(BUILD)/lib/*.cmi
COMMON_PKGS=uri,xmlmu.cmdliner
COMMON_TGTS=lib/$(LIB_NAME).cma lib/$(LIB_NAME).cmxa lib/$(LIB_NAME).a
COMMON_INCS=-I lib

ifneq ($(HAS_CMDLINER),0)
MLI=$(COMMON_MLI)
INCS=$(COMMON_INCS)
PKGS=$(COMMON_PKGS)
TGTS=$(COMMON_TGTS)
EXTRA_META=
else
MLI=$(COMMON_MLI) ui/*.mli $(BUILD)/ui/*.cmi
INCS=$(COMMON_INCS) -I ui
PKGS=$(COMMON_PKGS),cmdliner
TGTS=$(COMMON_TGTS) ui/htmlmuCommand.native
EXTRA_META=
endif

INSTALL= $(addprefix $(BUILD)/,$(TGTS))
FLAGS=-cflags -w,@f@p@u@40 -pkgs $(PKGS) $(INCS) -tags "debug"
OCAMLBUILD=ocamlbuild -use-ocamlfind $(FLAGS)

build: META
	$(OCAMLBUILD) $(TGTS)

install:
	ocamlfind install $(FINDLIB_NAME) META $(MLI) $(INSTALL)

META: META.in $(EXTRA_META)
	cat META.in $(EXTRA_META) > META

uninstall:
	ocamlfind remove $(FINDLIB_NAME)

reinstall: uninstall install

clean:
	rm -rf $(BUILD)
	rm -f lib/$(LIB_NAME).cm? META
