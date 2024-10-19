program export_tokens_to_csv
    implicit none

    type Token
        character(len=20) :: lexeme
        character(len=20) :: type
        integer :: line
        integer :: column
        type(Token), pointer :: next
    end type Token

    type(Token), pointer :: token_list, current_token

    ! Simulación de lista enlazada (puedes reemplazar con tus datos)
    allocate(token_list)
    token_list%lexeme = 'olaolaola'
    token_list%type = 'Keyword'
    token_list%line = 1
    token_list%column = 1

    allocate(token_list%next)
    token_list%next%lexeme = 'x'
    token_list%next%type = 'Identifier'
    token_list%next%line = 1
    token_list%next%column = 4
    token_list%next%next => null()

    current_token => token_list

    ! Abrir archivo para escribir
    open(unit=10, file='tokens.csv', status='replace')

    ! Escribir cabecera
    write(10, '(A)') 'Lexeme,Type,Line,Column'

    ! Escribir tokens en el archivo
    do while (associated(current_token))
        write(10, '(A, A, I0, A, I0)') trim(current_token%lexeme) // ',', &
                                        trim(current_token%type) // ',', &
                                        current_token%line, ',', &
                                        current_token%column
        current_token => current_token%next
    end do

    ! Cerrar archivo
    close(10)

    print *, "Datos exportados a tokens.csv."

end program export_tokens_to_csv
