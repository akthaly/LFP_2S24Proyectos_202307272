program lexer_test
    use lexer_module
    implicit none

    character(len=1000) :: input_line
    character(len=10) :: line_str  ! Variable para convertir el número de línea a string
    integer :: ios, line_number

    ! Inicializar número de línea
    line_number = 1

    ! Mostrar mensaje inicial
    print *, "Análisis Lexico Iniciado..."

    ! Leer entrada estándar línea por línea
    do
        read(*, '(A)', iostat=ios) input_line
        if (ios /= 0) exit  ! Salir si no hay más líneas de entrada

        ! Procesar cada línea leída de la entrada estándar
        call process_line(trim(input_line), line_number)

        ! Incrementar número de línea para la próxima iteración
        line_number = line_number + 1
    end do

    ! Verificar si al final del archivo seguimos en un comentario multilínea
    if (in_multi_comment) then
        ! Convertir el número de línea a cadena
        write(line_str, '(I0)') multi_comment_start_line  ! Convertir el número de línea a cadena

        ! Mostrar el error indicando la línea donde comenzó el comentario sin cierre
        call add_error("Comentario multilinea sin cierre. Comenzo en la linea: " // trim(line_str), "Falta /* o */", multi_comment_start_line, 1)

        ! Reiniciar el estado del comentario
        in_multi_comment = .false.
    end if

    ! Imprimir los tokens encontrados
    call print_tokens()
    call parser()
    call create_html()
    call csv_table_error_tokens()

end program lexer_test
