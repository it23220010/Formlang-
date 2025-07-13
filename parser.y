%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

void yyerror(const char *s);
int yylex(void);
FILE *outfile;
int yydebug = 1;

char* current_field_name;
char* current_field_type;
char* dropdown_options[20];
char* radio_options[20];
int option_count = 0;
char attribute_buffer[512];

char* capitalize(const char* str) {
    if (!str || !*str) return strdup("");
    char* result = strdup(str);
    result[0] = toupper(result[0]);
    for (int i = 1; result[i]; ++i) {
        result[i] = tolower(result[i]);
    }
    return result;
}
%}

%union {
    int num;
    char* str;
}

%token <str> IDENTIFIER STRING_LITERAL
%token <num> NUMBER
%token FORM SECTION FIELD META VALIDATE IF ERROR
%token <str> TYPE ATTRIBUTE
%token EQUALS LT GT LBRACE RBRACE COLON SEMICOLON COMMA LBRACKET RBRACKET
%type <str> field_name

%%

program:
    meta_block_opt form_decl
;

meta_block_opt:
    /* empty */
    | meta_decl meta_block_opt
;

meta_decl:
    META IDENTIFIER EQUALS STRING_LITERAL SEMICOLON {
        fprintf(outfile, "<p>%s: %s</p>\n", $2, $4);
    }
;

form_decl:
    FORM IDENTIFIER LBRACE form_body RBRACE {
        fprintf(outfile, "<div><input type=\"submit\" value=\"Submit\"></div>\n</form>\n</body></html>\n");
    }
;

form_body:
    section_list validate_block_opt
;

section_list:
    section
    | section_list section
;

section:
    SECTION IDENTIFIER LBRACE field_list RBRACE {
        // Removed: fprintf(outfile, "<h3>Section: %s</h3>\n", $2);
    }
;

field_list:
    field
    | field_list field
;

field:
    FIELD field_name COLON TYPE  {
        current_field_name = strdup($2);
        current_field_type = strdup($4);
        option_count = 0;
    } attribute_list SEMICOLON {
        char* label_text = capitalize(current_field_name);
        if (strcmp(current_field_type, "text") == 0 || strcmp(current_field_type, "email") == 0 ||
            strcmp(current_field_type, "number") == 0 || strcmp(current_field_type, "password") == 0 ||
            strcmp(current_field_type, "date") == 0 || strcmp(current_field_type, "file") == 0) {
            fprintf(outfile, "<div><label>%s:</label><br><input type=\"%s\" name=\"%s\"%s></div>\n",
                label_text, current_field_type, current_field_name, attribute_buffer);
        } else if (strcmp(current_field_type, "textarea") == 0) {
            fprintf(outfile, "<div><label>%s:</label><br><textarea name=\"%s\"%s></textarea></div>\n",
                label_text, current_field_name, attribute_buffer);
        } else if (strcmp(current_field_type, "checkbox") == 0) {
            fprintf(outfile, "<div><label><input type=\"checkbox\" name=\"%s\"%s> %s</label></div>\n",
                current_field_name, attribute_buffer, label_text);
        } else if (strcmp(current_field_type, "radio") == 0) {
            fprintf(outfile, "<div><label>%s:</label><br>\n", label_text);
            for (int i = 0; i < option_count; i++) {
                fprintf(outfile, "<input type=\"radio\" name=\"%s\" value=\"%s\"> %s<br>\n",
                    current_field_name, radio_options[i], radio_options[i]);
            }
            fprintf(outfile, "</div>\n");
        } else if (strcmp(current_field_type, "dropdown") == 0) {
            fprintf(outfile, "<div><label>%s:</label><br><select name=\"%s\">\n",
                label_text, current_field_name);
            for (int i = 0; i < option_count; i++) {
                fprintf(outfile, "<option value=\"%s\">%s</option>\n", dropdown_options[i], dropdown_options[i]);
            }
            fprintf(outfile, "</select></div>\n");
        }
        free(label_text);
        attribute_buffer[0] = '\0';
    }
;

field_name:
    IDENTIFIER
    | TYPE
;

attribute_list:
    /* empty */
    | attribute_list attribute
;

attribute:
    ATTRIBUTE {
        if (strcmp($1, "required") == 0) {
            strcat(attribute_buffer, " required");
        }
    }
    | ATTRIBUTE EQUALS NUMBER {
        char tmp[100];
        sprintf(tmp, " %s=\"%d\"", $1, $3);
        strcat(attribute_buffer, tmp);
    }
    | ATTRIBUTE EQUALS STRING_LITERAL {
        char tmp[256];
        sprintf(tmp, " %s=\"%s\"", $1, $3);
        strcat(attribute_buffer, tmp);
    }
    | ATTRIBUTE EQUALS LBRACKET option_items RBRACKET { }
;

option_items:
    STRING_LITERAL {
        if (strcmp(current_field_type, "radio") == 0) {
            radio_options[option_count++] = strdup($1);
        } else if (strcmp(current_field_type, "dropdown") == 0) {
            dropdown_options[option_count++] = strdup($1);
        }
    }
    | option_items COMMA STRING_LITERAL {
        if (strcmp(current_field_type, "radio") == 0) {
            radio_options[option_count++] = strdup($3);
        } else if (strcmp(current_field_type, "dropdown") == 0) {
            dropdown_options[option_count++] = strdup($3);
        }
    }
;

validate_block_opt:
    /* empty */
    | validate_block
;

validate_block:
    VALIDATE LBRACE validation_rules RBRACE
;

validation_rules:
    validation_rule
    | validation_rules validation_rule
;

validation_rule:
    IF condition LBRACE error_stmt RBRACE
;

condition:
    IDENTIFIER LT NUMBER {
        fprintf(outfile, "<!-- Validation: if %s < %d -->\n", $1, $3);
    }
    | IDENTIFIER GT NUMBER {
        fprintf(outfile, "<!-- Validation: if %s > %d -->\n", $1, $3);
    }
;

error_stmt:
    ERROR STRING_LITERAL SEMICOLON {
        fprintf(outfile, "<!-- Error: %s -->\n", $2);
    }
;

%%

extern char *yytext;
void yyerror(const char *s) {
    fprintf(stderr, "Parse error: %s at '%s'\n", s, yytext);
}

int main(void) {
    outfile = fopen("output.html", "w");
    if (!outfile) {
        perror("Could not open output.html");
        return 1;
    }
    fprintf(outfile, "<html><body>\n<h1>Generated Form</h1>\n<form>\n");
    yyparse();
    fclose(outfile);
    return 0;
}
