cc = gcc
cc_standard = -std=c99
cc_optimization = -Ofast -march=native
cc_warnings = -Werror -Wall -Wextra -Wpedantic -Wshadow -Wconversion -pedantic-errors
cc_link = -lgmp

fib: fib.c
	${cc} ${cc_standard} ${cc_optimization} ${cc_warnings} $^ -o $@ ${cc_link}

.PHONY: clean
clean:
	rm -rf fib
