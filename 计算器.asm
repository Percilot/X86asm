data segment  
num_sign dw 0     
match_sign dw 0
num dw 100h dup(0)    
op db 100h dup(0)    
index db 0
count db 0   
data ends

code segment
assume cs:code,ds:data

main:      
mov ax,data	;段寄存器初始化
mov ds,ax
lea di,num	;di=&num[0]
lea si,op		;si=&op[0]
xor ax,ax		;通用寄存器初始化
xor bx,bx
xor cx,cx
xor dx,dx

input_start:  
mov ah,01h	;读入字符
int 21h
cmp al,0dh	;判断是不是回车
je  input_label_0
 
cmp al,'('		;判断字符是否合法，不合法就会舍去，不保存到内存    	
jb  input_start     	
cmp al,'9'   	
ja  input_start

cmp al,'/'		;以/作为分界线，判断是数字还是运算符   	
jbe input_label_1	;input_label_1及以后对应对符号的处理       

call fetch_a_num
jmp input_start	;继续读入数据

input_label_0:
cmp match_sign,0	;判断输入的括号是否完成配对    
je input_label_1        
jmp mid_error	;未成功配对，跳转至ERROR

input_label_1:
cmp num_sign,0	;判断是否曾输入数字  
je  input_label_2	;无，直接跳转
add di,2		;有，di++             
mov num_sign,0	;数字判定符置0
   
input_label_2:                   
call ranking	;将运算符分级         
cmp ch,5             	;判断是不是左括号
jne input_label_3              
inc match_sign     	;是，匹配标识符自加
    
input_label_3:
cmp ch,1		;判断是不是右括号             
jne input_label_4
dec match_sign     	;是，匹配标志符自减

input_label_4:
cmp byte ptr[si],0	;判断运算符是否处理完成     
je input_label_6	;是，准备输出
cmp ch,[si]           	;比较两者的优先级
ja input_label_6	
cmp byte ptr[si],'('	;判断当前符号是不是左括号
jne input_label_5
dec si		;是，运算符数组下标自减
jmp input_start	;继续读入
 
input_label_5:
dec si		;运算符数组下标自减
mov cl,[si]	;cl=op[si]
call compute          	;计算
jmp input_label_4	;循环
    
input_label_6:
cmp ch,0		;判断是否读到回车           
je mid_output	;是，输出
cmp ch,1		;判断是否读到右括号
je input_start            ;是，继续读入
inc si		;si++
mov [si],al	;保存本次读到的符号        
inc si		;si++
cmp ch,5		;判断符号是不是左括号          
jne input_label_7
mov ch,2		;是，改变优先级为2    
    
input_label_7:
mov [si],ch	;保存优先级  
jmp input_start	;继续读入

mid_output:
jmp output

mid_error:
jmp error

fetch_a_num proc
inc num_sign	     	
sub al,30h	;将ASCII码转变为数字     	
mov ah,0		;将al拓展为ax
push ax		;ax入栈
mov ax,[di]	;将上一次的数字移入ax
mul bx		;第一次时，ax*0；此后，ax*10
mov bx,10	;bx=10
mov [di],ax	;将ax送入内存段
pop ax		;ax出栈
add [di],ax	;完成加法，数字更新
ret
fetch_a_num endp

add_com proc
sub di,2
push bx
mov bx,[di]
pop word ptr [di]
sub di,2
add [di],bx
add di,2
ret
add_com endp

sub_com proc
sub di,2
push bx
mov bx,[di]
pop word ptr [di]
sub di,2
sub [di],bx
add di,2
ret
sub_com endp

mul_com proc
sub di,2
push bx
mov bx,[di]
pop word ptr [di]
sub di,2
push ax
mov ax,[di]
pop word ptr [di]
imul bx
mov [di],ax
add di,2
ret
mul_com endp

div_com proc
sub di,2   
push bx
mov bx,[di]
pop word ptr [di]
sub di,2
push ax
mov ax,[di]
pop word ptr [di]
cwd
idiv bx
mov [di],ax
add di,2
ret
div_com endp

compute proc    
push ax		;ax入栈
xor ax,ax		;寄存器初始化
xor bx,bx

cmp cl,'+'
je add_two
cmp cl,'-'
je sub_two
cmp cl,'*'		;判断是不是*号   
je mul_two
cmp cl,'/'
je div_two
jmp finish

add_two:         	;加法运算
call add_com
jmp finish

sub_two:		;减法运算         	
call sub_com
jmp finish

mul_two:		;乘法运算
call mul_com
jmp finish


div_two:		;除法运算      
call div_com
jmp finish


finish:
pop ax
ret

compute endp

ranking proc
cmp al,'('
je is_left
cmp al,')'
je is_right
cmp al,'+'
je is_three
cmp al,'-'
je is_three
cmp al,'*'
je is_four
cmp al,'/'
je is_four
cmp al,0dh
je is_zero
 
is_left:		;左括号，赋优先级为5
mov ch,5
ret

is_right:
mov ch,1		;右括号，赋优先级为1
ret

is_three:
mov ch,3		;+和-，赋优先级为3
ret

is_four:
mov ch,4		;*和/，赋优先级为4
ret

is_zero:
mov ch,0		;回车，赋优先级为0
ret

ranking endp

error:
mov ah,02h	;输入括号未匹配，输入ERROR
mov dl,'E'
int 21h
mov ah,02h
mov dl,'R'
int 21h
mov ah,02h
mov dl,'R'
int 21h
mov ah,02h
mov dl,'O'
int 21h
mov ah,02h
mov dl,'R'
int 21h
jmp exit

output:
sub di,2             
call show_in_10	;10进制输出
call exchange	;换行
call show_in_16	;16进制输出
call exchange	;换行
call show_in_2	;2进制输出

mov ah,01h	;暂停一下
int 21h
jmp exit

exit:	
mov ah,4ch	;程序终止
int 21h

exchange proc
mov ah,02h	;换行
mov dl,0dh
int 21h
mov ah,02h
mov dl,0ah
int 21h
ret
exchange endp

show_in_10 proc
push di		;di入栈
push word ptr[di]	;最终结果入栈
cmp word ptr[di],0	;判断是不是正数
jge d1		
neg word ptr[di] 	;否，取补 
mov dl,'-'		;输出负号
mov ah,2
int 21h

d1:
mov bx,10000	;bx=10000
mov cx,5		;cx=5，运算结果在10进制下最多有5位
mov si,0		;si=0

d2:
mov ax,[di]	;ax=num[di]
cwd		;扩展
div bx		;除法运算
mov [di],dx	;保留余数
cmp al,0		;判断商是不是0
jne d3		;非零，输出
cmp si,0		;是否已输出字符
jne d3		;已输出，继续输出
cmp cx,1		;判断是否一位都未输出
je d3		;是，输出
jmp d4		;结尾处理

d3:
mov dl,al	
add dl,30h	;将数字转换为ASCII码
mov ah,2		;输出
int 21h
mov si,1		;si=1

d4:            	;这一段主要实现对除数bx的调整
mov ax,bx	;ax=bx
xor dx,dx		;dx=0
mov bx,10	;bx=10
div bx		;ax=bx/10
mov bx,ax	;bx=ax
loop d2		;循环

pop word ptr [di]	;出栈
pop di
ret
show_in_10 endp

show_in_16 proc	
push di		;di入栈
mov cx,4	

push word ptr [di]	;结果入栈
cmp word ptr[di],0	;是否是正数
jge h_print_0

neg word ptr[di]	;负数取补  
mov dl,'-'		;输出负号
mov ah,2
int 21h

h_print_0:		;循环补0
mov dl,'0'
mov ah,2
int 21h
loop h_print_0

h1:
mov bx,4096	;bx=4096
mov cx,4		;cx=4，运算结果在16进制下最多有4位
mov si,0


h2:
mov ax,[di]	;ax=num[di]
cwd		;扩展
div bx		;除法运算
mov [di],dx	;保留余数
mov dl,al		
cmp dl,10		;判断即将输出的这一位是否大于10
jge over_10 
add dl,30h	;将小于10的数字转换为对应数字的ASCII码
jmp print_16

over_10:
sub dl,10		;将大于等于10的数字转换为对应大写字母的ASCII码
add dl,41h

print_16:		;输出
mov ah,2
int 21h
mov si,1

h4:		;与10进制部分类似，此略            
mov ax,bx
xor dx,dx
mov bx,16
div bx
mov bx,ax
loop h2

mov dl,'h'		;输出末尾的h
mov ah,2
int 21h
pop word ptr [di]
pop di
ret
show_in_16 endp

b_print_blank proc	;输出二进制结果中的空格
add index,1	;index作为判断指标
cmp index,4
jne fun_ending
cmp count,7	;判断空格是否输出完成
jge fun_ending
mov dl,' '		;index=4时输出空格
mov ah,2
int 21h
inc count		;count++
mov index,0	;index置0

fun_ending:
ret
b_print_blank endp

show_in_2 proc
push di		;di入栈
mov cx,16

push word ptr[di]
cmp word ptr[di],0
jge b_print_0
neg word ptr[di]  
mov dl,'-'
mov ah,2
int 21h

b_print_0:		;循环补0
mov dl,'0'
mov ah,2
int 21h
call b_print_blank	;每输出一个字符，都调用一次输出空格函数
loop b_print_0

b1:
mov bx,32768
mov cx,16
mov si,0

b2:
mov ax,[di]
cwd
div bx
mov [di],dx
mov dl,al
add dl,30h
mov ah,2
int 21h
call b_print_blank
mov si,1

b4:            
mov ax,bx
xor dx,dx
mov bx,2
div bx
mov bx,ax
loop b2

mov dl,'B'		;输出结尾的B
mov ah,2
int 21h

pop word ptr [di]
pop di
ret
show_in_2 endp

code ends
end main
