section .code

global _start

_start:
            mov r10, rsp
          
          
            push 127d
            push '!'
            push 100d
            push 3802d
            push string2
            push 127d
            push '!'
            push 100d
            push 3802d
            push string2
            push format_string2
            
            
            call printf
            
            mov rsp, r10
            
            mov rax, 1  
            xor rbx, rbx
            int 0x80
         
              
;----------------------------------------
;Does format output.
;IN: r10 - pointer on 1st arguement pushed in stack, arguments pushed in stack according to cdecl. First must be const char* - format string.
;RETURN: rax - count of written symbols.
;DESTR: rax, rbx, rcx, rdx, rsi, rdi, r8, r9, r10, r11
;-----------------------------------------     
printf:     
            pop rbp
            xor rbx, rbx
            xor rdx, rdx
            xor r11, r11
            pop r8
     printf_loop:
            cmp byte [r8 + rbx], '%'
            je format_call
            mov al, byte [r8 + rbx]
            mov byte [buffer + rdx], al
            inc rdx
            inc rbx
    
     percent_ret:
            cmp  rdx, DROP_LIMIT
            jb drop_ret
            call drop
     
     
     drop_ret:
            cmp byte [r8 + rbx], 0h
            jne printf_loop
          
            call drop
            
            mov rax, r11
            push rbp
            ret
            

format_call:
            inc rbx
            xor eax, eax
            mov al, byte [r8 + rbx]
            
            cmp al, '%'
            je printf_percent
       
            cmp al, 'b'
            jb printf_err
            
            cmp al, 'x'
            ja printf_err
            
            sub al, 'b'
            
            jmp [percent_jmp_table + eax * 8]
                        
             
    printf_string:
            call drop
            
            
            pop rsi
            
            call strlen
            add r11, rdx
            mov rdi, 1
            mov rax, 1
            
            syscall
            
            xor rdx, rdx
            inc rbx
            jmp drop_ret 
                   
                   
                  
    printf_decimal:
            pop rax
            
            push rbx
            push rdx
                
            xor rcx, rcx
            
            xor rbx, rbx
                
            mov rbx, 10d    
                
          division_loop:  
            xor rdx, rdx    
            div rbx
            mov bh, byte [alph + rdx]
            mov byte [integer_buff + rcx], bh
            xor bh, bh
            inc rcx
            cmp rax, 0
            ja division_loop
                
            pop rdx
            
          put_dec_to_buff:      
            dec rcx
            mov al, byte [integer_buff + rcx]
            mov byte [buffer + rdx], al
            inc rdx
            cmp rcx, 0
            jne put_dec_to_buff 
             
            pop rbx
            inc rbx
            jmp percent_ret
            
                           
                            
       printf_binary:
            mov byte [buffer + rdx], '0'
            inc rdx
            mov byte [buffer + rdx], 'b'
            inc rdx
            
            mov cl, 1
            call bin_print
            jmp percent_ret
            
       printf_octa:
            mov byte [buffer + rdx], '0'
            inc rdx
            mov byte [buffer + rdx], 'o'
            inc rdx
            
            mov cl, 3
            call bin_print
            jmp percent_ret
            
       printf_hex:
            mov byte [buffer + rdx], '0'
            inc rdx
            mov byte [buffer + rdx], 'x'
            inc rdx
             
            mov cl, 4
            call bin_print
            jmp percent_ret
            
            
            
       printf_char:
            pop rax
            mov byte [buffer + rdx], al
            inc rdx
            inc rbx
            jmp percent_ret

            
                                    
       printf_percent:
            mov byte [buffer + rdx], '%'
            inc rdx
            inc rbx
            jmp percent_ret
            
            
            
       printf_err:
            call drop
            mov rsi, err_str
            mov rdx, err_str_len - 1
            mov cl, byte [r8 + rbx]
            mov byte [err_str + err_str_len - 3], cl
            mov rdi, 1
            mov rax, 1
            
            syscall
            mov rax, 1  
           
            xor rbx, rbx
            int 0x80      
            
            
           
;----------------------------------------
;Drops printf buffer to console.
;IN: rdx - size of buffer
;OUT: rdx = 0
;DESTR: rdi = 1, rax = 1
;-----------------------------------------      
drop:  
            cmp rdx, 0
            jbe drop_end
            add r11, rdx
            
            mov rsi, buffer
            
            mov rdi, 1
            mov rax, 1
            
            syscall

            xor rdx,rdx
            
     drop_end:
           ret
           
           
      
;----------------------------------------
;Prints integer in some binary format.(2^n-format)
;IN: cl - power of 2
;OUT: rbp - correct current position in stack.
;DESTR: rax, rcx
;-----------------------------------------
bin_print: 
            pop r9
            
            mov ch, 1
            shl ch, cl
            sub ch, 1
            
            
            pop rax            
            push rbx
            push rdx
            
            
            xor rdx, rdx
            xor rbx, rbx
            
      bin_print_loop:
            mov bl, al
            and bl, ch            
            shr rax, cl   
            
            mov bh, byte [alph + rbx]       
            mov byte [integer_buff + rdx], bh
            xor bh, bh
            
            inc rdx
            cmp rax, 0h
            ja bin_print_loop
            
            mov rcx, rdx
            pop rdx
            
      put_to_buff:
            dec rcx
            mov bh, byte [integer_buff + rcx]
            mov byte [buffer + rdx], bh 
            inc rdx   
            cmp rcx, 0h
            jne put_to_buff
            
            pop rbx
            inc rbx
            push r9
            ret   
         

;----------------------------------------
;Find length of string.
;IN: rsi - string pointer.
;OUT: rdx - strlen.
;DESTR: no
;-----------------------------------------
strlen:
            xor rdx, rdx          
   strlen_loop:
            cmp byte [rsi + rdx], 0h
            je strlen_end
            inc rdx
            jmp strlen_loop
            
    strlen_end:
            ret
                     
            
                                                            

section     .data
percent_jmp_table     dq printf_binary                                  ;%b
                      times ('c' - 'b' - 1) dq printf_err                        
                      printf_char,                                      ;%c
                      times ('d' - 'c' - 1) dq printf_err
                      printf_decimal                                    ;%d
                      times ('o' - 'd' - 1) dq printf_err
                      dq printf_octa                                    ;%o
                      times ('s' - 'o' - 1) dq printf_err
                      dq printf_string                                  ;%s
                      times ('x' - 's' - 1) dq printf_err
                      dq printf_hex                                     ;%x
                      
                   
BUFFER_LEN            equ 100h
DROP_LIMIT            equ BUFFER_LEN / 2
buffer                times BUFFER_LEN db 'a'

integer_buff          times 64 db '0'
alph                  db "0123456789ABCDEF", 0h
         

format_string         db 'I believe that %s I have tested it %d times, this number in other number systems: binary %b, octa %o, hex %x, testing 1 char: %c, here must be percent: %%, and after that must be error with symbol g:%g', 0h
fs_len                equ $ - format_string


err_str               db 0ah, 0ah, "Error: unknown character after %: ", 34d, "c", 34d, 0ah
err_str_len           equ $ - err_str

string                db "it is working!", 0h

format_string2        db "I %s %x. %d%%%c%b I %s %x. %d%%%c%b", 0
string2               db "love", 0
EDA                   equ 0edah

format_string3        db "hello %b"
