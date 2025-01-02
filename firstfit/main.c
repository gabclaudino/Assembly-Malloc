#include <stdio.h>
#include <stdlib.h>

#include "meuAlocador.h" 

int main() {
    printf("Iniciando testes ...\n");

    printf("Configurando brk inicial...\n");
    iniciaAlocador();

    imprimeMapa();

    printf("Alocando 50 bytes...\n");
    void* ptr1 = alocaMem(50);

    printf("Alocando 20 bytes...\n");
    void* ptr2 = alocaMem(20);

    printf("Alocando 30 bytes...\n");
    void* ptr3 = alocaMem(30);

    imprimeMapa();

    printf("Desalocando tudo...\n");
    liberaMem(ptr1);
    liberaMem(ptr2);
    liberaMem(ptr3);

    imprimeMapa();

    printf("Alocando 10 bytes...\n");
    ptr1 = alocaMem(10);
    
    imprimeMapa();

    printf("Alocando 9000 bytes...\n");
    ptr2 = alocaMem(9000);
    imprimeMapa();

    printf("Alocando 3000 bytes...\n");
    ptr3 = alocaMem(3000);
    imprimeMapa();

    printf("Desalocando tudo...\n");
    liberaMem(ptr1);
    liberaMem(ptr2);
    liberaMem(ptr3);

    printf("Restaurando brk inicial...\n");
    finalizaAlocador();

    printf("Testes concluídos.\n");
    return 0;
}
