program lexer_test
    use lexer_module
    implicit none

    ! Variable para almacenar el nombre del archivo de prueba
    character(len=100) :: filename

    ! Solicitar al usuario el nombre del archivo a analizar
    print *, "Ingrese el nombre del archivo a analizar (incluya la extension .LFP):"
    filename = "entrada.LFP"

    ! Llamar a la subrutina para leer y procesar el archivo
    call read_file(trim(filename))

    ! Imprimir los tokens encontrados
    call print_tokens()

end program lexer_test
