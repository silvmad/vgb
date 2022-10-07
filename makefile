all : vgb

vgb : lex.yy.c vgb.tab.c vgb.tab.h
	gcc -Wall lex.yy.c vgb.tab.c -o vgb

vgb.tab.c : vgb.y
	bison --defines vgb.y

lex.yy.c : vgb.l
	flex vgb.l

install : all
	install vgb ~/.local/bin/vgb

.PHONY : clean

recompile : clean all

clean :
	-rm lex.yy.c vgb.tab.c vgb.tab.h
