
all:
	bison -d parser.y
	flex lexer.l
	gcc -o formlang parser.tab.c lex.yy.c -lfl

run:
	./formlang < example.form > output.html

clean:
	rm -f formlang parser.tab.* lex.yy.c output.html