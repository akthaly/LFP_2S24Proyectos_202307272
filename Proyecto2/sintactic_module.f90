module parser_module
    implicit none

    ! Estructura para almacenar tokens
    type :: Token
        character(len=:), allocatable :: lexeme
        character(len=:), allocatable :: tipo
        integer :: linea, columna
    end type Token

    type(Token), pointer :: token_list(:) => null()
    type(Token), pointer :: current_token => null()
    integer :: token_index

contains

    subroutine parse(tokens)
        type(Token), pointer :: tokens(:)
        token_list => tokens
        token_index = 1
        
        ! Iniciar el análisis
        call programa()

        ! Si se procesaron todos los tokens, el análisis fue exitoso
        if (token_index > size(token_list)) then
            print *, "Análisis completado con éxito."
        else
            print *, "Error en el análisis: Quedaron tokens sin procesar."
        end if
    end subroutine parse

    subroutine programa()
        call declaraciones()
    end subroutine programa

    recursive subroutine declaraciones()
        if (token_index <= size(token_list) .and. &
            trim(token_list(token_index)%tipo) == "Tipo") then
            call declaracion()
            call declaraciones()  ! Recursión para la siguiente declaración
        end if
    end subroutine declaraciones

    subroutine declaracion()
        ! Procesar una declaración específica
        print *, "Procesando declaración: ", token_list(token_index)%lexeme
        current_token => token_list(token_index)
        token_index = token_index + 1  ! Consumir el token actual

        ! Se espera un identificador
        if (token_index <= size(token_list) .and. &
            trim(token_list(token_index)%tipo) == "Identificador") then
            current_token => token_list(token_index)
            token_index = token_index + 1  ! Consumir el identificador
        else
            print *, "Error: Se esperaba un identificador."
        end if

        ! Se espera un punto y coma
        if (token_index <= size(token_list) .and. &
            trim(token_list(token_index)%tipo) == "Punto y Coma") then
            current_token => token_list(token_index)
            token_index = token_index + 1  ! Consumir el punto y coma
        else
            print *, "Error: Se esperaba un punto y coma."
        end if
    end subroutine declaracion

end module parser_module
