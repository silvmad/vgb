/*
vgb : Gilles Bernard virtuel.
Il corrige votre pretty print lisp de manière lapidaire.

fichier : vgb.y

Analyseur syntaxique de vgb
*/

%{
#include <stdio.h>
#include <stdlib.h>

#include "vgb.tab.h"
#include "vgb.h"

void yyerror(const char*);
extern int yylex();

extern int indent;
extern int n_col;
extern int lineno;
extern int last_line_size;
extern int last_line_indent;
extern int n_ob;
extern char *yytext;

#define CHCK_N_COL_NL           \
if (last_line_size > 80)        \
{                               \
  --lineno;                     \
  yyerror("Ligne trop longue"); \
  YYERROR;                      \
}


%}
			
%glr-parser
%union
{
    int i;
    struct { int type; int indent; } a;
}

%token NL OP FP ESP TAB QUOTE
%token	<a>		ATOM

%type	<i> middle_line middle_lines last_line
%type	<i> list one_line_list_elts one_line_list_elt
%type	<i> elt one_line_list multiline_list first_line

%expect 3
%start prog
			
%%

prog : top_lists empty_lines
;

/* Ici l'indentation doit être de 0 pour chaque liste. */
top_lists :  /* Rien. */
	|  	top_lists top_list 
;

top_list : empty_lines list eol { CHCK_N_COL_NL; }
;

list : one_line_list { $$ = $1; } %dprec 2
	|	multiline_list { $$ = $1; } %dprec 2
	|	OP ATOM ESP ATOM ESP one_line_list ESP one_line_list FP
                %dprec 1
                {
                  if ($2.type != DEF)
		    {
		      yyerror("");
		      YYERROR;
		    }
                  $$ = $6;
		} 
	|	OP ATOM ESP ATOM ESP one_line_list_elt FP %dprec 1
                {
                  if ($2.type != SET)
		    {
		      yyerror("");
		      YYERROR;
		    }
                  $$ = $6;
		} 
;

one_line_list :  maybe_quote OP one_line_list_elts FP
           {
	     if (yychar == NL)
	      {
                $$ = last_line_indent;
	      }
             else
	      {
		$$ = $3;
	      }
	   }
	|  maybe_quote OP FP
           {
	     if (yychar == NL)
	      {
                $$ = last_line_indent;
	      }
             else
	      {
		$$ = indent; 
	      }
	   }
;

multiline_list :  maybe_quote OP first_line middle_lines last_line FP
	        {
		  if (($4 != -1 && $5 != -1 && $4 != $5) ||
                      ($5 != (n_ob + 1) * 2))
		    {
		      yyerror("");
		      YYERROR;
		    }
		  $$ = $3;
		}
	|	 maybe_quote OP multiline_list ESP FP { $$ = $3; }
;
		
first_line : one_line_list_elt eol
           {
	     $$ = $1;
	     CHCK_N_COL_NL
	   }
	|	multiline_list eol
           {
	     $$ = $1;
	     CHCK_N_COL_NL
	   }
	|	ATOM ESP ATOM ESP one_line_list eol
           {
             if ($1.type != DEF)
		{
                  yyerror("");
		  YYERROR;
		}
	     $$ = last_line_indent;
	     CHCK_N_COL_NL
	   }
	|	ATOM ESP ATOM eol
           {
             if ($1.type != DEF && $1.type != SET)
		{
                  yyerror("");
		  YYERROR;
		}
	     $$ = last_line_indent;
	     CHCK_N_COL_NL
	   }
;

middle_lines : /* Rien. */ { $$ = -1; }
	|	middle_lines middle_line
                {
                  if ($1 > 0 && $2 > 0 && $1 != $2)
		    {
                      yyerror("");
                      YYERROR;
		    }
                  $$ = $2;
		}
;

middle_line : eol { $$ = -1; }
	|	spaces elt eol { $$ = $2; CHCK_N_COL_NL } 
;

last_line : spaces elt ESP { $$ = $2; } 
;

elt : one_line_list_elt { $$ = $1; }
	|	multiline_list { $$ = $1; }
;

one_line_list_elts : one_line_list_elt { $$ = $1; }
	|	one_line_list_elts ESP one_line_list_elt { $$ = $3; }
;

one_line_list_elt : ATOM
           {
             $$ = $1.indent;
	   }
	|	one_line_list { $$ = $1; }
;

empty_lines : /* Rien. */
	|	empty_lines empty_line
;

empty_line : NL
	|	spaces NL
;

spaces : ESP
	|	TAB
	|	spaces ESP
	|	spaces TAB
;

eol : NL
	|	spaces NL
;

maybe_quote : /* Rien. */
	|	QUOTE
;

%%

int main(int argc, char **argv)
{
    if (argc != 2)
      {
	fprintf(stderr, "usage : %s lisp_filename\n", argv[0]);
	exit(1);
      }
    FILE *f = freopen(argv[1], "r", stdin);
    if (!f)
      {
	fprintf(stderr, "Impossible d'ouvrir le fichier %s.\n", argv[1]);
	exit(1);
      }
    int r = yyparse();
    if (r == 0)
      {
	printf("C'est juste.\n");
      }
}

void yyerror(const char * msg)
{
    printf("Ligne %i, token %s. C'est faux. %s\n", lineno, yytext, msg);
}
