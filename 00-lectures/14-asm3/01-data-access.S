/*
        Разные случаи доступа к данным в глобальных переменных
        Рассматривается архитектура x86 (32 бита)
*/

// === глобальная переменная-указатель ===
// char *ptr;
        .global ptr
ptr:    .int    0               // резервируем 4 байта для хранения указателя

// *ptr = '0';
        movl    ptr, %eax       // загружаем указатель из памяти на регистр eax
        movb    '0', (%eax)     // записываем в память по указателю в %eax

// ptr[i] = 'b'; // индексация, предполагаем, что ptr и i - глобальные переменные
        movl    ptr, %eax
        movl    i, %ebx
        movb    'b', (%eax, %ebx) // используем режим адресации eax + ebx * 1

        movb    'b', (%ebx, %eax) // поскольку размер одного элемента - 1, поэтому все равно, в каком порядке записаны регистры!

// работа с указателем int*
// int *ptr2;
// x = ptr2[j];
        movl    ptr2, %eax
        movl    j, %ebx
        movl    (%eax, %ebx, 4), %eax // %eax - базовый адрес (адрес начала массива), %ebx - индекс, 4 - масштабный множитель
        movl    %eax, x

// в случае, если индекс - константа, компилятор, как правило, вычислит смещение к элементу массива при компиляции
// x = ptr2[3];
        movl    ptr2, %eax
        movl    12(%eax), %eax  // 12 = 3 * 4, это значение вычислено при компиляции
        movl    %eax, x

// === глобальный массив ===
// unsigned short arr1[32];
        .global arr1
arr1:   .skip   64, 0

// x = arr1[j]
        movl    j, %eax
        movzwl  arr1(,%eax,2), %eax // arr1 - базовый адрес (адрес начала массива), movzwl - загрузить 16-битное значение без знака в 32-битный регистр
        movw    %ax, x              // %ax - младшая половина регистра %eax

// в случае, если индекс - константа, адрес в памяти может быть вычислен при компиляции
// x = arr1[9]
        movw    arr1 + 18, %ax  // запись arr1 + 18 - это адрес в памяти на 18 больше адреса arr1
        movw    %ax, x

// внимание, это синтаксис Intel!
// в синтаксисе Intel используются квадратные скобки        
        mov     ax, word ptr [arr1 + 18]

// === глобальный многомерный массив ===
// int arr3[8][10];
        
// x = arr3[i][j];
// вычисление адреса: arr3 + i * 40 + j * 4
// вычисляем адрес в лоб, с помощью инструкции умножения        
        movl    i, %eax
        movl    $40, %edx
        mull    %edx, %eax      // в регистре %eax будет адрес arr3 + i * 40
        movl    j, %ebx
        movl    arr3(%eax, %ebx, 4)

// вариант, как это вычисление может быть оптимизировано
// arr3 + (i * 10 + j) * 4
// i * 10 = i * 5 * 2 = (i * 5) << 1 = (i * 4 + i) << 1
        movl    i, %eax
        leal    (%eax, %eax, 4), %eax
        shll    %eax
        addl    j, %eax
        movl    arr3(,%eax,4), %eax
        ...


// === глобальные переменные структурного типа ====
/*
struct str1
{
    char f1;           // 0 - смещение от начала структуры
    unsigned int f2;   // 4
};
*/

// struct str1 v1;
// y = v1.f2;

        .global v1
v1:     .skip   8, 0
y:      .int    0

        movl v1 + 4, %eax       // v1 + 4 - адрес в памяти, по которому размещается поле f2
        movl %eax, y

// === глобальная переменная-указатель на структуру ===
// struct str1 *pv;
// y = pv->f2;

        movl   pv, %eax
        movl   4(%eax), %eax
        movl   %eax, y

// === сложные структуры данных ===
/*
struct s1
{
    char f1;
    int  f2;
};

struct s2
{
    int        ff2;
    struct s1 *ff1[16];
};

struct s2 *ppp;

// переменная ppp может быть использована двумя способами ниже
ppp->ff1[i]->f2;
ppp->ff1[i][j].f2;
*/

// пример
// ppp->ff1[i]->f2;
        movl    ppp, %eax
        movl    i, %ebx
        movl    4(%eax, %ebx, 4), %eax
        movl    4(%eax), %eax

// ===  отличие x86_64 ===
// 1) указатель имеет размер 8, поэтому смещения в структуре изменяются
// 2) для доступа к глобальным переменным можно использовать PC-relative метод адресации: VAR(%rip)        

/*
struct s1
{
    char f1;
    int  f2;
};

struct s2
{
    int        ff2;
    struct s1 *ff1[16];
};

struct s2 *ppp;

ppp->ff1[i]->f2;
*/

        movq    ppp(%rip), %rax
        movl    i(%rip), %ebx
        movq    8(%rax, %rbx, 8), %rax
