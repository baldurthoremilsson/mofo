// AsmCreator.h

#ifndef _ASMCREATOR_H
#define _ASMCREATOR_H

#include <sstream>
#include <stack>
#include <list>
#include <string>
#include <map>

using namespace std;

class Nestlevel {
	public:
		int currvarindex;
		list<string> varnames;
		
		int gotrue;
		int gofalse;
		int goend;
		int gocontinue;
		
		Nestlevel(int varindex) {
			currvarindex = varindex;
			gotrue = 0;
			gofalse = 0;
			goend = 0;
			gocontinue = 0;
		}
};

class Functioncall {
	public:
		int paramcount;
		int arvalue;
		string functionname;
		
		Functioncall(int arindex, string name) {
			paramcount = 0;
			arvalue = arindex;
			functionname = name;
		}
};

class AsmCreator {
	private:
		ostringstream code;
		
		string programname;
		
		int argcount;
		int jumpindex;
		stack<Nestlevel> nestlevels;
		stack<Nestlevel*> whilelevels;
		
		map<string,int> varmap;
		int varindex;
		
		int arindex;
		stack<Functioncall> functioncalls;
		
		bool upcomingStatements;
		stack<int> jumps;
		
		bool hasmain;
		bool returned;
		
		
		void registerVar(string name);
		void StoreArgAcc();
		
		// todo: break statement
		
	public:
		AsmCreator();
		~AsmCreator();
		
		ostringstream& getCode();
		void beginProgram(string name);
		
		void beginArglist();
		void assignArg(string name);
		void beginFunction(string name);
		
		void pushNestLevel();
		void popNestLevel();
		
		void assignVar(string name);
		void beginFunctioncall(string name);
		void endFunctioncall();
		
		void beginBinop();
		void endBinop(string name);
		
		void statements();
		void whileStatements();
		
		void startif();
		void startelseif();
		void endif();
		void startelse();
		void endelse();
        void noelse();
		
		void startwhile();
		void endwhile();
		void dobreak();
		void docontinue();
		
		void pushJump();
		void popJump();
		void jumpTrue();
		void jumpFalse();
		
		void hasMain();
		void endFunction();
		void endProgram();
		
		void MakeVal(string val);
		void Store(int pos);
		void Store(int lev, int pos);
		void Fetch(string varname);
		void StoreArgAcc(int lev, int pos);
		void Call(string target, int ar);
		void GoFalse(int target);
		void GoTrue(int target);
		void Go(int target);
		void Return();
		void Not();
};

#endif
