%{
#include "parser.tab.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>


char* strip_quotes(char* str) {
    int len = strlen(str);
    if (len >= 2 && str[0] == '"' && str[len - 1] == '"') {
        char* new_str = malloc(len - 1);
        strncpy(new_str, str + 1, len - 2);
        new_str[len - 2] = '\0';
        return new_str;
    }
    return strdup(str);
}
%}

%%

"meta"              { return META; }
"form"              { return FORM; }
"section"           { return SECTION; }
"field"             { return FIELD; }
"validate"          { return VALIDATE; }
"if"                { return IF; }
"error"             { return ERROR; }

"text"|"textarea"|"number"|"email"|"date"|"checkbox"|"dropdown"|"radio"|"password"|"file" {
    yylval.str = strdup(yytext); return TYPE;
}

(required|min|max|default|pattern|rows|cols|options|accept) {
    yylval.str = strdup(yytext); return ATTRIBUTE;
}

[a-zA-Z_][a-zA-Z0-9_]* {
    yylval.str = strdup(yytext); return IDENTIFIER;
}

\"[^\"]*\" {
    yylval.str = strip_quotes(yytext); return STRING_LITERAL;
}

[0-9]+              { yylval.num = atoi(yytext); return NUMBER; }

"="                 { return EQUALS; }
"<"                 { return LT; }
">"                 { return GT; }
"{"                 { return LBRACE; }
"}"                 { return RBRACE; }
":"                 { return COLON; }
";"                 { return SEMICOLON; }
","                 { return COMMA; }
"["                 { return LBRACKET; }
"]"                 { return RBRACKET; }

[ \t\r]+            { /* skip whitespace */ }
\n                  { yylineno++; }

.                   { return *yytext; }

%%

int yywrap() { return 1; }
