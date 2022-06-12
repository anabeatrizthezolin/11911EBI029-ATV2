Este repositório contém as atividades realizadas na primeira atividade da disciplina de Sistemas Embarcados I. 

Como o todas as instalações foram realizadas na distribuição Linux Mint 20.3 Cinnamon, não foi necessária a instalação do WSL.

Para utilizar o compilador GCC-GNU C Compiler e Git, eram necessários as instalações de algumas ferramentas, porém já estavam instaladas essas ferramentas. Com os comandos

```sh
gcc --version
git --version 
```

foi possível verificar as versões instaladas.
O git é necessário já que todas as atividades serão disponibilizadas em repositórios do git.

Para criar uma pasta com o nome "semb1-workspace" para armazenar as atividades pode-se utilizar o comando

```sh
mkdir semb1-workspace
```
A pasta foi criada na minha pasta pessoal. Para abrir a pasta usa-se

```sh
cd semb1-workspace
```

Em seguida foi clonado na pasta um repositório disponibilizado no git sobre a primeira aula no laboratório

```sh
git clone https://github.com/daniel-p-carvalho/ufu-semb1-lab-01.git lab-01
```

Em seguida, foi necessária a instalação do GCC ARM Toolchain na pasta pessoal, compilador necessário para a arquitetura ARM Cortex-M que será utilizada nas aulas, através dos comandos

```sh
cd
wget \ https://developer.arm.com/-/media/Files/downloads/gnu-rm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2
sudo tar xjf gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2 -C /usr/share/
sudo ln -s /usr/share/gcc-arm-none-eabi-10.3-2021.10/bin/* /usr/bin/
sudo apt install libncurses-dev libtinfo-dev
sudo ln -s /usr/lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5
sudo ln -s /usr/lib/x86_64-linux-gnu/libtinfo.so.6 /usr/lib/x86_64-linux-gnu/libtinfo.so.5
```
Para verificar se a instalação foi concluida corretamente 

```sh
arm-none-eabi-gcc --version
arm-none-eabi-g++ --version
arm-none-eabi-gdb --version
```
Em seguida foi instalado o OpenCD que possui suporte os dispositivos STM32 e ao ST-LINK. Para utilizá-lo são necessário os pacotes make, libtool, pkg-config, autoconf, automake, texinfo e libusb-1.0. Todos os pacotes podem ser instalados com o comando

```sh
sudo apt install libtool pkg-config autoconf automake texinfo libusb-1.0-0-dev
```
depois foi clonado o código fonte do OpenOCD do git

```sh
git clone https://git.code.sf.net/p/openocd/code openocd-code
```
Após a clonagem, deseja-se a versão v0.11.0

```sh
cd openocd-code
git tag
git switch -c v0.11.0
```
Para compilá-lo executamos os comandos

```sh
./bootstrap
./configure --enable-stlinkf
make
sudo make install
```
Para utilizar as ferramentas de código aberto ST-LINK para gravar e deputar os programas para o STM32 devemos instalá-las. Para compilar essas ferramentas, são necessários os pacotes git, gcc, build-essential, cmake, libusb-1.0, libusb-1.0-0-dev,, libgtk-3-dev e pandoc, alguns já estão instalados. Os comandos para as instalações são 

```sh
cd
git clone https://github.com/stlink-org/stlink stlink-tools
sudo apt install git build-essential cmake libusb-1.0-0 libusb-1.0-0-dev
```
para utilizar a versão mais recente

```sh
cd stlink-tools
git tag
git switch -c v1.7.0
```
Para compilar as ferramentas

```sh
make clean
make release
sudo make install
```
Para verificar se todas as ferramentas foram instaladas corretamente
```sh
st-flash --version
st-info --version
st-trace --version
st-util --version
```
A IDE utilizada será a Visual Studio Code, que já tenho instalada. Foi necessário apenas instalar o pacote Cortex-Debug no próprio VS Code.

Tem-se agora todos os arquivos iniciais para um sistema Cortex-M.

Para conectar o **ST-LINK** ao USB é necessário um suporte ao USB/IP. Para isso, verificamos primeiro a versão de kernel instalada com o comando
```sh
uname -a
```
São necessários alguns pacotes para a conexão
```sh
sudo apt install linux-tools-generic hwdata
apt list -a linux-tools-generic
sudo update-alternatives --install /usr/local/bin/usbip usbip \ /usr/lib/linux-tools/5.4.0-113-generic/usbip 20
man update-alternatives
```

Foi criado o arquivo **main.c** com o código para fazer o LED piscar. No STM32F411 Blackpill o led está conectado no pino PC13 e o pino deve ser configurado para operar como um pino de saída em push-pull e os resistores de pull-up e pull-down desligados. Para utilizar a porta C precisamos configurar o *clock* da porta através do periférico **Reset and Clock Control (RCC)**.
O endereço dos registradores deve ser definido no código através das linhas 
```sh
\#define STM32_RCC_BASE              0x40023800
\#define STM32_RCC_AHB1ENR_OFFSET    0x0030
\#define STM32_RCC_AHB1ENR           (STM32_RCC_BASE+STM32_RCC_AHB1ENR_OFFSET)
\#define RCC_AHB1ENR_GPIOCEN        (1 << 2)
``` 
e na função **main()** o clock GPIOCEN foi habilitado.

A configuração **GPIOC_MODER** configura o PC13 como pino de saída quando o bit está em 0. A **GPIOC_OTYPER** faz a saída tipo push-pull ao ajustar o bit OT13 para 0. A **GPIOC_PUPDR** desconecta os resistores de pull-up e pull-down.
O responsável por alterar o estado do pino será o registrador **GPIOx_BSRR - GPIO port bit set/reset register**.


O compilador utilizado é **arm-none-eabi-gcc** e a arquitetura é **-mcpu=cortex-m4** e para gerar o conjunto de instruções reduzidos de 16-bits (Thumb) **-mthumb**. Assim, o comando ficou da forma

```sh
arm-none-eabi-gcc -c -mcpu=cortex-m4 -mthumb main.c -o main.o
```

Uma vez que na linguagem C são passados muitos parâmetros e outras informações para a compilação, além de serem executados mais de um arquivo no processo, foi criado o arquivo **Makefile** para automatizar a compilação. O Makefile possui comandos que irão gerar arquivos objetos realocáveis e linkar eles pra gerar um arquivo executável. 

O arquivo **startup.c** foi criado para executar algumas atividades. Nele
- declaramos e inicializamos o *Stack*, uma pilha que armazena dados temporários e aponta para o último elemento inserido nele. Ele foi inicializado apontando para o fim da memória SRAM;
- declaramos e inicializamos a Tabela de Vetores de Interrupção. Na arquitetura Cortex-M estão reservados  vetores de interrupções indexados de 1-15. São suportados também linhas de interrupção externas ao núcleo da CPU;
- criamos o código do *Reset handler*. O primeiro vetor de interrupção presente no endereço **0x0000 00004**. No endereço **0x0000 00000** tem-se o valor do *Stack Pointer*;
- declaramos os códigos de *exception handler*.

Para reservar os 408 bytes necessários para a tabela de vetores de interrupção usa-se um **array** de **uint32_t**.
A função **reset_handler()** é responsável por copiar o conteúdo da seção .data da memória FLASH na SRAM, preencher a seção .bss com zero e chamar a função **main()**.
A função **default_handler()** cria uma rotina de tratamento padrão para as System Exceptions e IRQs sem utilização, através do atributo **alias** é possível não criar uma função de tratamento para cada System Exceptions e IRQs e do atributo **weak** faz com que o endereço na tabela de vetores de interrupçãp seja o enredeço da nova função.

Para combinar os arquivos objetos em um único arquivo executável, utilizamos o processo de linkedição. O arquivo de linkedição é denominado **stm32f411-rom.ld**, ele descreve o mapeamento das seções dos arquivos de entrada e controlao layout da memória no arquivo de saída.
O comando **ENTRY** informa o endereço do ponto de entrada, nesse caso, a função **reset_handler()**.
O comando **MEMORY** é respponsável pelo layout de memória do dispositivo e é onde serão atribuidos os endereços de memória das seções.
O comando **SECTION** cria as seções no arquivo executável e controla a ordem em que ela aparecerão. Ao utilizá-la, é preciso determinar qual a região de memória onde a seção será alocada. 
Cada seção possui **name**, que é o nome da região de memória, **origin**, que é o endereço inicial da região de memória e o **length**, que é o tamanho da região. 
Definimos os endereços e tamanho da região de memória através do *datasheet* do STM32F411.
A seção **FLASH** armazena o código do programa com atributos **rx**.
A seção **SRAM** pode armazenar código executável e alterá-lo, assim, seus atributos são **rwx**.
Para que não fosse realizada nenhuma otimização nas seções **.isr_vetors** utilizamos o comando **KEEP()**. 
A seção **.text** foi armazenada na **FLASH**, a **.data** foi gravada na **FLASH** e na **SRAM** por possuir valores de inicialização e por suas variáveis voláteis e a **.bss** foi armazenada apenas na **SRAM**.
A variável **_.text** armazena o endereço do término da seção **.text**. A variável **.sdata** guarda o início da seção **.data** enquanto a variável **_edata** salva o endereço do fim da seção. 
Para evitar o acesso não alinhado na memória, utilizou-se o comando **. = ALIGN(4)**.

Para facilitar a compilação, utilizou-se o arquivo **Makefile** que guarda todas as intruções para a compilação dos arquivos
A fim de simplificar a implementação:
- utilizamos algumas variáveis, *PROG = binky*, *CC = arm-none-eabi-gcc*, *LD = arm-none-eabi-gcc*, *CP = arm-none-eabi-objcopy*, *CFLAGS = -c -mcpu=cortex-m4 -mthumb* e *LFLAGS = -nostdlib -T stm32f411-rom.ld*, além das variáveis automáticas  $< (representa o primeiro pré-requisito), $^ (representa todos os pré-requisitos) e $@ (repesenta o alvo da regra);
- definimos um target **all** com todos os arquivos a serem executados;
- construímos o **target-pattern %.o** e o **prereq-patterns %.c** para substituir os nomes dos arquivos **.o** e **.c**, respectivamente.

O Makefile é executado com o comando

```sh
make
```
Quando o comando
```sh
make clean
```
é executado, todos os arquivos objetos são excluídos da pasta. O comando existe para que os arquivos sejam atualizados ao executar o comando **make**.