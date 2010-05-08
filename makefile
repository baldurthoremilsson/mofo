mofo :	mofo.tab.o mofolex.o AsmCreator.o
	g++ -o mofo mofo.tab.o mofolex.o AsmCreator.o -lfl
clean :
	rm -f *.bak mofo mofo.tab.cpp mofolex.cpp mofo.tab.o mofolex.o mofo.tab.hpp AsmCreator.o
mofo.tab.cpp mofo.tab.h :	mofo.y
	bison -d mofo.y -o mofo.tab.cpp
mofo.tab.o :	mofo.tab.cpp
	g++ -c mofo.tab.cpp
mofolex.cpp : mofo.l
	flex -o mofolex.cpp mofo.l 
mofolex.o : mofolex.cpp mofo.tab.h
	g++ -c mofolex.cpp
AsmCreator.o:
	g++ -c AsmCreator.cpp