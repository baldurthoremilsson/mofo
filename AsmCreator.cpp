// AsmCreator.cpp

#include "AsmCreator.h"
#include <ostream>
#include <string>
#include <iostream>

using namespace std;

AsmCreator::AsmCreator() {
	argcount = 0;
	jumpindex = 1;
	varindex = 0;
	arindex = -1;
	upcomingStatements = false;
	hasmain = false;
	returned = false;
}

AsmCreator::~AsmCreator() {
}


void AsmCreator::registerVar(string name) {
	if(varmap.find(name) == varmap.end()) {
		nestlevels.top().varnames.push_back(name);
		varmap[name] = varindex++;
	}
}

void AsmCreator::StoreArgAcc() {
	if(functioncalls.empty())
		return;
	
	Functioncall &fcall = functioncalls.top();
	code << "(StoreArgAcc " << fcall.arvalue << " " << fcall.paramcount++ << ")" << endl;
}



ostringstream& AsmCreator::getCode() {
	return code;
}

void AsmCreator::beginProgram(string name) {
	// todo: virkar rett?
	programname = name;
	
	code << programname << " =" << endl;
	code << "!{{" << endl;
}

void AsmCreator::beginArglist() {
	this->pushNestLevel();
}

void AsmCreator::assignArg(string name) {
	argcount++;
	this->registerVar(name);
}

void AsmCreator::beginFunction(string name) {
	code << "#\"" << name << "[f" << argcount << "]\" =" << endl;
	code << "[" << endl;
	argcount = 0;
	
	if(name == "main" && argcount == 0)
		this->hasMain();
}

void AsmCreator::pushNestLevel() {
	nestlevels.push(Nestlevel(varindex));
}

void AsmCreator::popNestLevel() {
	Nestlevel &level = nestlevels.top();
	varindex = level.currvarindex;
	for(list<string>::iterator it = level.varnames.begin(); it != level.varnames.end(); it++)
		varmap.erase(*it);
	
	nestlevels.pop();
}

void AsmCreator::assignVar(string name) {
	this->registerVar(name);
	this->Store(varmap[name]);
}

void AsmCreator::beginFunctioncall(string name) {
	functioncalls.push(Functioncall(arindex--, name));
}

void AsmCreator::endFunctioncall() {
	Functioncall &fcall = functioncalls.top();
	code << "(Call #\"" << fcall.functionname << "[f" << fcall.paramcount << "]\" " << fcall.arvalue << ")" << endl;
	functioncalls.pop();
	arindex++;
	
	this->StoreArgAcc();
}

void AsmCreator::beginBinop() {
	functioncalls.push(Functioncall(arindex--,string("")));
	this->StoreArgAcc();
}

void AsmCreator::endBinop(string name) {
	Functioncall &fcall = functioncalls.top();
	code << "(Call #\"" << name << "[f" << fcall.paramcount << "]\" " << fcall.arvalue << ")" << endl;
	functioncalls.pop();
	
	this->StoreArgAcc();
}

void AsmCreator::statements() {
	upcomingStatements = false;
	
	this->GoFalse(nestlevels.top().gofalse);
	code << "_" << nestlevels.top().gotrue << ":" << endl;
	this->pushNestLevel();
}

void AsmCreator::whileStatements() {
    whilelevels.push(&(nestlevels.top()));
	this->statements();
}

void AsmCreator::startif() {
	upcomingStatements = true;
	
	Nestlevel &level = nestlevels.top();
	level.gotrue = jumpindex++;
	level.gofalse = jumpindex++;
	level.goend = jumpindex++;
}

void AsmCreator::startelseif() {
	upcomingStatements = true;
	
	Nestlevel &level = nestlevels.top();
	level.gotrue = jumpindex++;
	level.gofalse = jumpindex++;
}

void AsmCreator::endif() {
	this->popNestLevel();
	code << "(Go _" << nestlevels.top().goend << ")" << endl;
	code << "_" << nestlevels.top().gofalse << ":" << endl;
}

void AsmCreator::startelse() {
	upcomingStatements = false;
	
	this->pushNestLevel();
}

void AsmCreator::endelse() {
	this->popNestLevel();
	code << "_" << nestlevels.top().goend << ":" << endl;
}

void AsmCreator::noelse() {
    code << "_" << nestlevels.top().goend << ":" << endl;
}

void AsmCreator::startwhile() {
	upcomingStatements = true;
	
	Nestlevel &level = nestlevels.top();
	level.gocontinue = jumpindex++;
	level.gotrue = jumpindex++;
	level.gofalse = jumpindex++;
	
	code << "_" << level.gocontinue << ":" << endl;
}

void AsmCreator::endwhile() {
	this->popNestLevel();
	whilelevels.pop();
	code << "(Go _" << nestlevels.top().gocontinue << ")" << endl;
	code << "_" << nestlevels.top().gofalse << ":" << endl;
}

void AsmCreator::dobreak() {
	// todo: errors?
	code << "(Go _" << whilelevels.top()->gofalse << ")" << endl;
}

void AsmCreator::docontinue() {
	// todo: errors?
	code << "(Go _" << whilelevels.top()->gocontinue << ")" << endl;
}

void AsmCreator::pushJump() {
	if(upcomingStatements)
		return;
	jumps.push(jumpindex++);
}

void AsmCreator::popJump() {
	if(upcomingStatements)
		return;
	code << "_" << jumps.top() << ":" << endl;
	jumps.pop();
}

void AsmCreator::jumpTrue() {
	this->GoTrue(jumps.top());
}

void AsmCreator::jumpFalse() {
	this->GoFalse(jumps.top());
}

void AsmCreator::hasMain() {
	hasmain = true;
}

void AsmCreator::endFunction() {
	varindex = 0;
	if(!returned)
		this->Return();
	returned = false;
	
	code << "];" << endl;
	
	this->popNestLevel();
}

void AsmCreator::endProgram() {
	code << "}}" << endl << ";" << endl;
	code << endl;
	if(hasmain)
		code << "\"" << programname << ".mexe\" = main in " << programname << " * BASIS;" << endl;
	else
		code << "\"" << programname << ".mmod\" = " << programname << " * BASIS;" << endl;
}



void AsmCreator::MakeVal(string val) {
	returned = false;
	code << "(MakeVal " << val << ")" << endl;
	this->StoreArgAcc();
}

void AsmCreator::Store(int pos) {
	returned = false;
	code << "(Store " << pos << ")" << endl;
}

void AsmCreator::Store(int lev, int pos) {
	returned = false;
	code << "(Store " << lev << " " << pos << ")" << endl;
}

void AsmCreator::Fetch(string varname) {
	returned = false;
	// todo: errorcheck
	code << "(Fetch " << varmap[varname] << ")" << endl;
	this->StoreArgAcc();
}

void AsmCreator::StoreArgAcc(int lev, int pos) {
	returned = false;
	code << "(StoreArgAcc " << lev << " " << pos << ")" << endl;
}

void AsmCreator::Call(string target, int ar) {
	returned = false;
	code << "(Call " << target << " " << ar << ")" << endl;
}

void AsmCreator::GoFalse(int target) {
	returned = false;
	code << "(GoFalse _" << target << ")" << endl;
}

void AsmCreator::GoTrue(int target) {
	returned = false;
	code << "(GoTrue _" << target << ")" << endl;
}

void AsmCreator::Go(int target) {
	returned = false;
	code << "(Go _" << target << ")" << endl;
}

void AsmCreator::Return() {
	returned = true;
	code << "(Return 0)" << endl;
}

void AsmCreator::Not() {
	returned = false;
	code << "(Not)" << endl;
}
