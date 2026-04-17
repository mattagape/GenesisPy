// state.h
// To be used with Genesis program.
// Matthew Gillman 31/01/2017 Queen Mary University of London
#ifndef _STATE_H
#define _STATE_H
//#include <cstddef>
#include <iostream>
using namespace std;

class Machine; 
class State;

// This is the "context" class and is accessed by the client code.
class Machine {
public:
	void setNext(State *s) {
		current = s;
	}
	Machine (State* init, double myage, double initprob, string start); // defined elsewhere
	~Machine(){}
	
	void setNextStateName(string newstate) {
	  if (statename != nullptr) {
	    delete statename;
	  }
	  statename = new string(newstate);
	}
	
	State *current;

	// age is in same time units as used for the State Transition Table file.
	double age; // this could perhaps be replaced with a dynamic array of doubles
	            // for more flexibility?

	double prob;
	
	string* statename;
};


// Abstract superclass of all the state classes we wish to create dynamically.
// Based on State pattern code at https://sourcemaking.com/design_patterns/state
class State {
	
	public:
	State() {}
	virtual	~State() {}
	
	virtual void goNext(Machine* m) = 0;	
	
};

#endif // _STATE_H
