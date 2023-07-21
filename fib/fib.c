// Calculate Fibonacci Numbers 
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <ctype.h>
#include <gmp.h>

long limit, i = 0;

int main(int argc, char *argv[])
{
	// Get User Input 
	if (argc != 2)
	{
		printf("Improper input. Exiting.\n");
		return -1; 
	}

	limit = strtol(argv[1], NULL, 10);

	// Setup GMP 
	mpz_t a, b, c;
	mpz_init_set_ui(a, 1);
    mpz_init_set_ui(b, 0);
   	mpz_init(c);

   	for (i = 0; i < limit; i++)
   	{
   		// Perform the Fibonacci Calculation
   		mpz_add(c, a, b);
   		mpz_set(a, b);
   		mpz_set(b, c);
   	}

	// Print the results to stdout
   	printf("Fibonacci Number %ld: ", i);
   	mpz_out_str(stdout, 10, b);
   	printf("\n");

	// Cleanup
   	mpz_clear(a);
   	mpz_clear(b);
   	mpz_clear(c);
	
	
	return 0;
}
