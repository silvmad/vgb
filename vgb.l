/*
vgb : Gilles Bernard virtuel.
Il corrige votre pretty print lisp de manière lapidaire.

fichier : vgb.l

Analyseur lexical de vgb
*/

%{
#include <stdbool.h>
#include <string.h>

#include "vgb.tab.h"
#include "vgb.h"

bool indent_end = false;
int last_line_size= 0;
int last_line_indent = 0; 
int indent = 0;
int n_col = 0;
int n_ob = 0;
int lineno = 1;

%}
%option noyywrap
%option noinput
%option nounput

%%
;.*\n      {
             last_line_indent = indent;
             indent = 0;
             indent_end = false;
             n_col += strlen(yytext) - 1;
	     last_line_size = n_col;
             n_col = 0;
	     lineno++;
             return NL;
           }
"\n"       {
             last_line_indent = indent;
             indent = 0;
             indent_end = false;
	     last_line_size = n_col;
             n_col = 0;
	     lineno++;
             return NL;
           }
" "        {
             ++n_col;
             if (!indent_end)
               {
                 ++indent;
	       }
             return ESP;
           }
\t         {
             int n_sp = 8 - (indent % 8);
             n_col += n_sp;
             if (!indent_end)
               {
		   indent += n_sp;
	       }
             return TAB;
           }
"'"        { indent_end = true; ++n_col; return QUOTE; }
"("        { indent_end = true; ++n_col; ++n_ob; return OP; }
")"        { indent_end = true; ++n_col; --n_ob; return FP; }
(defun)|(defmacro) { indent_end = true;
                     n_col += strlen(yytext);
		     yylval.i = DEF;
                     return ATOM; }
(setq)|(set) { indent_end = true;
               n_col += strlen(yytext);
               yylval.a.type = SET;
               yylval.a.indent = indent;
               return ATOM; }
\"[^\"]*\"  { indent_end = true;
              n_col += strlen(yytext);
              yylval.a.type = STR;
	      yylval.a.indent = indent;
              return ATOM; } 
[^ \"\n\t()]+  { indent_end = true;
                 n_col += strlen(yytext);
                 yylval.a.type = MISC;
		 yylval.a.indent = indent;
                 return ATOM; }
%%
