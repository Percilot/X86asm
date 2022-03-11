data segment
s db 100 dup(0)	;定义两个数组，s负责输入部分，t负责输出部分
t db 100 dup(0)	
data ends

code segment
assume cs:code,ds:data
main:
    mov ax,data	;初始化ds段寄存器
    mov ds,ax
    mov bx,0
    mov si,0	;初始化s数组下标
    mov di,0	;初始化t数组下标
    mov ax,0	;初始化ax寄存器
    jmp printin	;无条件跳转，开始输入

printin:
    mov ah,01	;调用int21，实现输入
    int 21h
    cmp al,13	;判断是否是回车
    je EOF		;若是，跳转至回车处理段
    mov s[si],al	;将读入的字符存入s数组
    add si,1	;s数组下标+1
    jmp printin	;无条件跳转，再次输入字符

EOF:
    mov al,00h	;将回车转换为00h
    mov s[si],al	;将读入的字符存入s数组
    mov si,0	;初始化s数组下标
    mov di,0	;初始化t数组下标	
    jmp read	;无条件跳转，开始处理字符

read:
    mov al,s[si]	;将s数组中字符移入al寄存器
    cmp al,32	;判断是否是空格
    je blank	;若是，跳转到空格处理段
    cmp al,00h	;判断是否是结尾
    je ending	;若是，跳转到结尾处理段
    cmp al,97	;判断ASCII码是否大于'a'
    jge bigger_than_a	;若是，跳转到疑似小写字母处理段
    jmp normal	;均否，跳转到一般字符处理段

blank:
    add si,1	;是空格，忽略，不保存至t数组中
    jmp read	;无条件跳转，处理s中下一个字符

ending:
    mov t[di],al	;是结尾，存入t数组
    mov di,0	;t数组下标初始化
    jmp printout	;无条件跳转，开始输出

bigger_than_a:
    cmp al,122	;判断是否是小写字母
    jle smaller_than_z		;若是，跳转到小写字母处理段
    jmp normal	;若否，跳转到一般字符处理段

smaller_than_z:
    sub al,32	;ASCII码减32，变换为大写字母
    mov t[di],al	;存入t数组
    add di,1	;两数组下标+1
    add si,1
    jmp read	;无条件跳转，处理s中下一个字符

normal:
    mov t[di],al	;存入t数组
    add di,1	;两数组下标+1
    add si,1
    jmp read	;无条件跳转，处理s中下一个字符

printout:
    mov dl,t[di]	;将t数组中字符存入dl寄存器
    cmp dl,0	;判断是否是结尾
    je exit		;若是，跳转至结尾输出处理段
    mov ah,2	;调用int21输出字符
    int 21h
    add di,1	;t数组下标+1
    jmp printout	;无条件跳转，输出下一个字符

exit:
    mov ah,2	;调用int21输出字符
    int 21h

code ends	;结束
end main
