MKSHELL=rc

update:V:
	./pkgs/celld/update.rc &
	./pkgs/dir2opds/update.rc &
	./pkgs/fx/update.rc &
	./pkgs/janet-lsp/update.rc &
	./pkgs/rcsh-language-server/update.rc &
	./pkgs/rust-glancer/update.rc &
	./pkgs/tree-sitter-mk/update.rc &
	./pkgs/tree-sitter-rcsh/update.rc &
	./pkgs/opencode-v2/update.sh &
	wait
