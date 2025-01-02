.section .note.GNU-stack,"",@progbits
.section .data
.global brk_inicial 
.global brk_atual


gerencial: .string "################\n"         # string para o registro de 16 bytes
alocado: .string "+"                            # string para bloco alocado
desalocado: .string "-"                         # string para bloco desalocado 
buffer: .string "\n"                            # string para quebra de linha

brk_inicial: .quad 0                # variavel global para salvar o valor da brk inicial
brk_atual: .quad 0                  # variavel global para salvar o valor da brk atual

.section .text                      # funcoes                                
.global iniciaAlocador
.global finalizaAlocador
.global alocaMem
.global liberaMem
.global imprimeMapa

iniciaAlocador:
    movq $12, %rax                  # código da syscall para chamar a brk
    movq $0, %rdi                   # retorna o valor atual de brk em %rax
    syscall                         # chama a syscall 
    movq %rax, brk_inicial          # salva o começo da heap em brk_inicial (constante)
    movq %rax, brk_atual            # salva o começo da heap em brk_atual (variável)
    ret                             # retorna

finalizaAlocador:
    movq $12, %rax                  # código da syscall para chamar brk
    movq brk_inicial, %rdi          # volta a brk para o início
    syscall                         # chama a syscall
    movq brk_inicial, %rax          # salva o endereço inicial da brk em %rax
    movq %rax, brk_atual            # endereço atual da brk é o início
    ret

alocaMem:
    movq brk_inicial, %r8           # salva o início da brk em %r8
    movq brk_atual, %r9             # salva o lugar da brk atual em %r9
    movq %rdi, %r10                 # salva o tamanho da alocação em %r10
    cmpq %r8, %r9                   # compara se é a primeira alocação
    je .aloca_bloco_novo            # se é a primeira, vai para função de alocar novo bloco

.encontra_bloco_livre:
    movq %r8, %r11                  # %r11 vai salvar o endereço do primeiro bloco
    movq $0, %r14                   # %r14 vai salvar o endereço do bloco a ser alocado
    movq $100000000, %r15           # %r15 vai salvar o tamanho do bloco a ser alocado

.loop:
    cmpq $1, (%r11)                 # verifica se o bloco está ocupado
    je .proximo                     # se não está, verifica se é adequado
    cmpq 8(%r11), %r10              # verifica se o tamanho do bloco livre é suficiente
    jg .proximo                     # se não for suficiente, vai para o próximo bloco
    cmpq 8(%r11), %r15              # verifica se o tamanho é o menor possível
    jle .proximo                    # se não for menor, vai para o próximo
    movq 8(%r11), %r15              # salva o novo menor tamanho encontrado
    movq %r11, %r14                 # salva o endereço do bloco

.proximo:
    addq 8(%r11), %r11              # vai para o próximo bloco
    addq $16, %r11                  # ajusta para o próximo bloco
    cmpq %r9, %r11                  # se %r11 >= brk_atual, terminou de verificar
    jl .loop                        # se nao entao volta ao loop
    cmpq $0, %r14                   # verifica se encontrou algum bloco livre
    je .aloca_bloco_novo            # se não encontrou, aloca um novo bloco
    jmp .aloca_bloco_existente      # caso contrário, aloca no bloco existente

.aloca_bloco_novo:
    movq %r10, %r13                 # salva em %r13 o valor original
    movq $4096, %r15                # unidade de alocação múltipla de 4096

inicio_laco:
    movq %r15, %rax                 # copia o valor de %r15 para %rax
    subq $16, %rax                  # calcula %r15 - 16(tamanho do registro)
    cmpq %rax, %r10                 # compara %r10 com (%r15 - 16)
    jl continua_codigo              # Se %r10 < (%r15 - 16), salta para continua_codigo

    addq $4096, %r15                # adiciona mais 4096B para %r15
    jmp inicio_laco                 # volta para o início do laço

continua_codigo:
    movq %r13, %r10                 # %r10 volta ao valor original

    movq brk_atual, %r8             # início do novo bloco
    movq $12, %rax                  # código da syscall para brk
    addq %r15, brk_atual            # atualiza o brk_atual
    movq brk_atual, %rdi
    syscall                         # chama brk para ajustar o tamanho da heap
    movq %r8, %r14                  # salva o endereço do bloco
    movq $0, (%r14)                 # marca o bloco como livre
    subq $16, %r15                  # tamanho do bloco restante
    movq %r15, 8(%r14)              # armazena o tamanho do bloco
    jmp .aloca_bloco_existente      # agora aloca o novo bloco

.aloca_bloco_existente:
    movq $1, (%r14)                 # coloca o byte de alocado no primeiro bloco
    movq %r15, %r12                 # %r12 = tamanho do bloco a ser alocado
    subq %r10, %r12                 # %r12 = tamanho do bloco total - tamanho a ser alocado
    cmpq $17, %r12                  # se o valor de %r12 >= 17, entao da pra divir em 2
    jl .aloca_inteiro               # aloca o bloco inteiro, ja que nao da pra dividir
    movq %r10, 8(%r14)              # coloca o tamanho do bloco
    addq $16, %r14                  # %r14 = inicio do bloco
    movq %r14, %r13                 # salva o endereco do primeiro bloco em %r13
    addq %r10, %r14                 # %r14 agora esta no comeco do registro do segundo bloco
    movq $0, (%r14)                 # seta o status como nao alocado
    subq $16, %r12                  # %r12 agora eh o tamanho disponivel que tem para alocacao
    movq %r12, 8(%r14)              # adiciona o tamanaho do segundo bloco
    movq %r13, %rax                 # coloca o endereco do primeiro bloco no %rax para retorno
    ret                             # retorna

.aloca_inteiro:
    addq $16, %r14                  # ajusta para o início do bloco utilizável
    movq %r14, %rax                 # retorna o endereço do bloco
    ret                             # retorna

liberaMem:
    cmpq brk_atual, %rdi            # verifica se o argumento está dentro da área da heap
    jge .fora_heap                  # se a entrada for maior que a área da heap, não tem como dar free
    cmpq brk_inicial, %rdi          # verifica se o argumento está dentro da área da heap
    jl .fora_heap                   # se a entrada for menor que a área da heap, não tem como dar free
    subq $16, %rdi                  # ajusta o endereço para apontar para o início do bloco
    movq $0, (%rdi)                 # coloca 0 no status do bloco de alocado
    ret                             # retorna

.fora_heap:
    movq $0, %rax                   # coloca 0 em %rax para retorno
    ret                             # retorna

# funcao de imprimir mapa
# rax = brk atual
# rbx = brk inicial
# rcx = 1 se ocupado e 0 se não estiver
# rdx = tamanho do bloco

imprimeMapa:                        # funcao imprimeMapa
    movq brk_inicial, %rbx          # salva brk inicial em rbx
    movq brk_atual, %rax            # salva brk atual em rax
    jmp while_imprimeMapa           # vai para o laco

while_imprimeMapa:
    cmpq %rax, %rbx                 # compara se chegou ao final da brk
    jge retorno_imprimeMapa         # se sim vai para o retorno da funcao
    movq (%rbx), %rcx               # salva ocupado
    addq $8, %rbx                   # descola para pegaro tamaho
    movq (%rbx), %rdx               # salva tamanho
    subq $8, %rbx                   # retorna para posição inicial do bloco

    pushq %rax                      # salva o valor de %rax na pilha
    pushq %rdx                      # salva o valor de %rdx na pilha
    pushq %rcx                      # salva o valor de %rcx na pilha

    # Imprime seção gerencial
    movq $1, %rax                   # serviço do syscall
    movq $1, %rdi                   # stdout
    movq $16, %rdx                  # tamanho do buffer
    movq $gerencial, %rsi           # string
    syscall                         # chama o sistema
    popq %rcx                       # retorna o valor de %rcx
    popq %rdx                       # retorna o valor de %rdx
    popq %rax                       # retorna o valor de %rax

    addq $16, %rbx                  # desloca para o inicio do bloco
    addq %rdx, %rbx                 # adiciona %rdx em %rbx
    cmpq $0, %rcx                   # if se bloco está desalocado
    je if_desalocado                # se sim vai para desalocado

if_alocado:                         # se nao fica em alocado
    movq $alocado, %rsi             # move a string para %rsi
    jmp for_imprimeMapa             # vai para o for onde sera impresso
if_desalocado:
    movq $desalocado, %rsi          # move a string para %rsi

for_imprimeMapa:                    # for para imprimir a quantidade de bytes
    cmpq $0, %rdx                   # verifica se nao eh 0
    je while_imprimeMapa            # se sim volta para o laco

    pushq %rax                      # salva o valor de %rax na pilha
    pushq %rdx                      # salva o valor de %rdx na pilha
    # Imprime se está ocupado
    movq $1, %rax                   # serviço do syscall
    movq $1, %rdi                   # stdout
    movq $1, %rdx                   # tamanho do buffer
    syscall                         # chama o sistema
    popq %rdx                       # retorna o valor de %rdx
    popq %rax                       # retorna o valor de %rax

    subq $1, %rdx                   # itera o laco
    jmp for_imprimeMapa             # volta para o inicio
    
retorno_imprimeMapa:
    # Imprime \n
    movq $1, %rax                   # serviço do syscall
    movq $1, %rdi                   # stdout
    movq $1, %rdx                   # tamanho do buffer
    movq $buffer, %rsi              # string
    syscall                         # chama o sistema
    ret                             # retorna
