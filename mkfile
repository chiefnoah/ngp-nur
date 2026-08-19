MKSHELL=rc

update:V:
	./pkgs/celld/update.rc &
	./pkgs/fx/update.rc &
	./pkgs/janet-lsp/update.rc &
	./pkgs/prime-agent/update.rc &
	./pkgs/rcsh-language-server/update.rc &
	./pkgs/tree-sitter-mk/update.rc &
	./pkgs/tree-sitter-rcsh/update.rc &
	wait
