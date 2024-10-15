program lexer_test
    use lexer_module
    implicit none

    character(len=1000) :: input_line
    integer :: ios, line_number

    ! Inicializar número de línea
    line_number = 1

    ! Mostrar mensaje inicial
    print *, "Análisis Léxico Iniciado..."

    ! Leer entrada estándar línea por línea
    do
        read(*, '(A)', iostat=ios) input_line
        if (ios /= 0) exit  ! Salir si no hay más líneas de entrada

        ! Procesar cada línea leída de la entrada estándar, usando `line_number`
        call process_line(trim(input_line), line_number)

        ! Incrementar número de línea para la próxima iteración
        line_number = line_number + 1
    end do

    ! Imprimir los tokens encontrados
    call print_tokens()

end program lexer_test
