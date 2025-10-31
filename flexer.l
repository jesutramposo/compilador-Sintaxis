%option noyywrap yylineno

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"   /* generado por: bison -d parser.y */

extern int errores_lexicos;
extern int yylineno;
int cadena_sin_cerrar_flag = 0;
char *ultima_cadena_sin_cerrar = NULL;
%}

/* definiciones simples y portables */
WS      [ \t\r]+

NL      \n
ID      [A-Za-z][A-Za-z0-9_-]*
NUM     (-?[1-9][0-9]{0,4}|0)
FLOAT   [0-9]{1,8}\,[0-9]{1,8}
STR     \"([^\"\\\n]*)\"

%%

{WS}               { /* ignorar espacios y tabs */ }
{NL}               { yylineno++; }

"utn"              { return COMIENZO; }
"finutn"           { return FIN_PROGRAMA; }
\n                  { yylineno++;}
"leer"              { return LEER; }
"LEER"              { return LEER; }
"escribir"          { return ESCRIBIR; }
"ESCRIBIR"          { return ESCRIBIR; }
"repetir"           { return REPETIR; }
"REPETIR"           { return REPETIR; }
"veces"             { return VECES; }
"VECES"             { return VECES; }
"entonces"          { return ENTONCES; }
"ENTONCES"          { return ENTONCES; }
"si"                { return SI; }
"SI"                { return SI; }
"finsi"             { return FINSI; }
"FINSI"             { return FINSI; }

":="               { return ASIGNACION; }
"\."               { return FIN_SENTENCIA; }

">="               { return COMP_MAYOR_IGUAL; }
"<="               { return COMP_MENOR_IGUAL; }
"=="               { return COMP_IGUAL; }
"!="               { return COMP_DISTINTO; }
">"                { return COMP_MAYOR; }
"<"                { return COMP_MENOR; }

"("                { return '('; }
")"                { return ')'; }
"{"                { return '{'; }
"}"                { return '}'; }
"+"                { return '+'; }
"-"                { return '-'; }
"*"                { return '*'; }
"/"                { return '/'; }

{NUM}              {
                      yylval.ival = atoi(yytext);
                      return CONST_ENTERO;
                   }

{FLOAT}            {
                      yylval.sval = strdup(yytext);
                      return CONST_FLOTANTE;
                   }

{STR}              {
                      yylval.sval = strdup(yytext);
                      return CONST_CADENA;
                   }

\"[^\"\n]*         {
                      const char *contenido = yytext + 1;
                      cadena_sin_cerrar_flag = 1;
                      if (ultima_cadena_sin_cerrar) { free(ultima_cadena_sin_cerrar); ultima_cadena_sin_cerrar = NULL; }
                      ultima_cadena_sin_cerrar = strdup(contenido);
                      fprintf(stderr, "Error Lexico: cadena sin cerrar\n");
                      errores_lexicos++;
                      yylval.sval = strdup("");
                      return CONST_CADENA;
                   }

{ID}               {
                      yylval.sval = strdup(yytext);
                      return IDENTIFICADOR;
                   }

.                  {
                      fprintf(stderr, "Error Lexico: %c es un caracter invalido\n", yytext[0]);
                      errores_lexicos++;
                   }

%%

/* no hace falta yywrap porque usamos %option noyywrap */
