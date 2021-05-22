CC := gcc
CFLAGS := -Wall
YFLAG := -d -v
LEX_SRC := compiler_hw2.l
YAC_SRC := compiler_hw2.y
HEADER := common.h
TARGET := myparser
v := 0

all: ${TARGET}

${TARGET}: lex.yy.c y.tab.c
	${CC} ${CFLAGS} -o $@ $^

lex.yy.c: ${LEX_SRC} ${HEADER}
	lex $<

y.tab.c: ${YAC_SRC} ${HEADER}
	yacc ${YFLAG} $<

judge: all
	@python3 judge/judge.py -v ${v} || printf "or \`make judge v=1\`"

clean:
	rm -f ${TARGET} y.tab.* y.output lex.*