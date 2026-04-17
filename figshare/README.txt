# README.txt
#
# Matthew Gillman
# Queen Mary University of London
# Initial version: 9th February 2017.
# Last updated: 18th May 2017.

This describes the genesis program. GENESIS stands for GENEric SImulation System.

This is basically a system which implements a state machine based on user-supplied states and
transition probabilities. It is hoped that it will be used to model things such as disease progression.

The Perl script, genesis.pl, is supplied with a file called stt.txt, the State Transition Table,
detailed below. This is mandatory. Optionally, although almost certainly needed, will be the 
configuration file config.txt (also detailed below).

Both stt.txt and config.txt can have comments by putting a # at the start of the line. You
should not have any completely blank lines though.


Running the program
===================
It will run on Windows or Linux. You need to have the Perl interpreter and a C++ compiler
installed. Your C++ compiler must have C++11 features enabled.

Once your stt.txt and config.txt files are ready, first type:

	perl genesis.pl

This should generate 3 C++ files: myclasses.h, myclasses.cpp and simulation.cpp. You should already
have the C++ header file called state.h which comes with this distribution.

To compile and run the C++ code on Windows, type:

	cl /EHsc simulation.cpp myclasses.cpp
	simulation
	
On Linux you will need to type something like:

	g++ -std=c++11 simulation.cpp myclasses.cpp -o simulation
	./simulation

If you want to be super-strict, you might type something like:

g++ -g3 -Wall -Wextra -Wstrict-overflow=5 -std=c++11 
	-ansi -pedantic -W -Wconversion -Wshadow -Wcast-qual 
	-Wwrite-strings -Wno-unused-parameter simulation.cpp myclasses.cpp -o simulation

which produces output which can be run under Valgrind.

It should then start generating results, recorded in the results.csv file. It also outputs copious 
text to stdout, so you might wish to say:

	./simulation > /dev/null   (Linux)

	simulation > NUL			(Windows)

NOTE: every time you change your stt.txt and/or config.txt file, you must re-run the Perl and C++
compilation steps before running the simulation program. This will make sure that the generated
code matches what you have defined.


stt.txt format
==============
The idea is that a disease or similar can be modelled with this program. It is assumed that you will
have a number of states which the model can move between as the disease progresses or is treated etc.
A "source" state is any state which can have transitions to other states from it. The states to which 
it can transition are called sink states. e.g. if a state was called "normal" and it transitioned
to "occult" then normal would be the source and occult the sink.

Some states cannot be exited from. This will depend on how you define them in your stt.txt file. 
Such states are called final sink states. Once the model ends up in such a state it will stay there
until it ceases simulating that particular person.

Note that, of course, a disease can stay in the *same* state for a while, maybe even for a long time;
it is not necessary to step out of a state at each time point.

You will probably want to draw a diagram of the states and their different transition probabilities
before you start crafting your stt.txt file.

You can call the states whatever you want but must not have whitespace in the name of a state. It is
important that you use the identical name (and case) for a given state throughout the stt.txt file. e.g. a state
called normal would be classed as a different state to one called Normal. 

The following is an example of a simple stt.txt file. Lines beginning with a # are comments. You 
must not have any blank lines (if you do then weirdness and errors can result in the C++ code).

# This is a comment
occult symp 12 20 0.05
occult symp 20 40 0.06
occult treated 12 80 0.07
normal cin1 12 80 0.01
cin1 occult 12 80 0.005

In this example several states are defined for the model: occult, symp, treated. normal and cin1. There are
five items on each line, each separated by a space. 

Source states here are occult, normal and cin1. Sink states are symp, treated, cin1 and occult. Final sink states
are treated and symp.

Let's look at the first line of data, after the comment line. What this says is that the probability of moving from
state "occult" to state "symp" is 0.05 between the ages of 12 and 20 (strictly >=12 and <20, p < 0.05). Note that although
we are using years in this case that doesn't have to be so; as long as you are consistent with the interval you specify
in your config.txt file (q.v.) you can use whatever time units you want, e.g. you could use months, weeks or whatever. 

The second line is similar to the first, except that here the probability of the same transition is defined as 
0.06 for the ages 20-40. Thus, whatever age the person is will decide which transition(s) is/are relevant at that
time point. Of course if you wanted it to be the same for all ages you would just use only one data line for that
transition and define the start and end ages accordingly for the age range you wanted.

If none of the transitions fire when the model is in a particular state it will stay in that state at that point
in time. As time passes one of the transitions may fire in which case it will proceed to a different state.

Data line 3 means there is a 0.07 prob of moving from occult to treated between the ages of 12 and 80.

The C++ logic for the occult state, specified by these first 3 data lines, will be like the following. A random number
generator is used and here R is a random number (i.e. a probability) between 0 and 1 for this time point.

if (age is between 12 and 20) {
	if (R < 0.05) go to symp state
	else if (R >= 0.05 and R < (0.05 + 0.07)) go to treated state
	else stay in occult state // Implicit probability of this happening is 1 - (0.05+0.07)
}
else if (age is between 20 and 40) {
	if (R < 0.06) go to symp state
	else if (R >= 0.06 and R < (0.06 + 0.07)) go to treated state
	else stay in occult state // Implicit probability of this happening is 1 - (0.06+0.07)
}
else if (age is between 40 and 80) {
	if (R < 0.07) go to treated state
	else stay in occult state // Implicit probability of this happening is 1 - 0.07
}
else {
	stay in occult state // All other ages.
}

The logic for the state transitions defined by the final two lines will be similar to this but simpler.

Note the implicit probabilities of staying in the occult state, in this example. If you wish you can explicitly state
this probability in the STT file. For example, if you wished to explictly state all transitions from a state which
you have called "normal" - including the probability of remaining in that state - you could say:

normal cin1 20 80 0.3
normal occult 20 80 0.1
normal normal 20 80 0.6

Note that the sum of the transition probabilities in this case is 1 (as expected). (This example only addresses 
transition in the age range 20-80).

Note that the cumulative probability of exiting from a particular source state in a particular age range must not exceed 1.
An error will result if it does. So if you explcitly specified the probability of remaining in a state, rather than leaving
it as an implicit (possibly wrong) value, you would benefit from this check.

You may find different results, even with the same seed, between the "implicit" and "explicit" scenarios. See "subtle difference"
section below.

You can have as many different states and transitions as you want. You can also be as fine grained as you like.
e.g. if you had a function, perhaps an exponential function, which defined the probability of a person moving from
state A to state B as age increased, you could work out the probability for each age and then have a rule at each age.
e.g. if you were working with intervals of 1 time unit you might have:

A B 21 22 0.08
A B 22 23 0.081
A B 23 24 0.085
etc.
(Disclaimer: I just made those transition probability values up. I haven't calculated them from an exponential distribution.)

Note that there is no point in having more fine-grained (shorter) time intervals in your stt.txt file than your config.txt
file. e.g. if you were going to use an interval of 5 time units between stages (so you might e.g. look at ages 20, 25, 30...)
you might not want the stt.txt file to be as fine grained in this example. It doesn't matter if you do, though, and maybe you would
like to use the same stt.txt file and test it with various values of time interval.


config.txt format
=================
The format of this is different. Each line has the form:

parameter:value

If you do not specify a particular value then a default value will be used.
The following is the set of parameters used by the program and the default values used.

startage:12
stopage:80
interval:1
initialstate:normal
number:1
seedstring:this is another test

As their names suggest, startage and stopage are the start and beginning ages (in arbitrary time units) that you wish
to model over. You can use whatever units you want as long as you are consistent with both .txt files. interval is the 
time interval between time points looked at in the simulation. That is, if you had a startage of 30 and interval 2, the
model would look at the following ages: 30,32,34,...

Note that interval can be less than 1. So you might like to use 0.5 for half of one time unit. But note that rounding can occur,
e.g. if you wanted to model 1/3 of a year you could set interval to 0.3333, but this would not be exact. In that case it may be
better to model in months rather than years, and to define the interval as 4 months (= 1/3 year). It is better to use integer
values if you can.

initialstate is the state that you wish each person being modelled to start off in. Note that this must be a state listed in your
stt.txt file.

number is the number of people you wish to model. This can be very large if you wish.

seedstring is used to generate the initial seed for the random number generator (RNG = a Mersenne Twister). If you wish to have reproducible
results then you will want to keep this the same each time you run the program. Note that this initial seed is only used as the initial
seed for the first person modelled; after that point random number values are generetaed by the RNG.

There is a special value if you want more random behaviour. If you say:

seedstring:USE_SYSTEM_CLOCK

then the program will generate a unique seed based on your computer's current system clock time.

Here is an example config.txt file:

# This is a comment
interval:1
initialstate:cin1
seedstring:USE_SYSTEM_CLOCK
number:20000

Note that default values will be used in this case for startage and stopage as they have not been specified in config.txt.


Disease screening
=================
It is hoped that the model can be used to investigate the effect of disease screening. This would be done in the following
series of steps:

1.	Define the states and transition probabilities for a set of people who are NOT screened.
2.	Run the program and generate results. This will be a set of default natural histories.
3.	Now adjust the transition probabilities to take account of screening, e.g. someone is more likely to go
	into the treated state. You would have to define probabilities which took account of the screening test effectiveness etc.
4.	Re-run the program.
5.	Compare results.

Alternatively, you could follow steps 1 and 2 to generate natural histories for the unscreened population, including how many
people arrive in a diseased state; then, if you know the sensitivity of a screening test, you cold apply it to the number of
people with preclinical conditions to see how many would be picked up.



Technical note
==============
The C++ generated by the model uses the State design pattern. It is based on the example on the Source Making website
(see https://sourcemaking.com/design_patterns/state). Basically every model state listed in stt.txt causes a C++ class
to be generated with the same name. Each class is a child of the abstract class State, defined in the supplied file
state.h, and implements the goNext() function which determines which state the program should go to next (this could be
the same state it is already in); this is based on the current age, transition probabilities and a value from the random number
generator. Dynamic binding causes the "child of State" object to be an instance of the appropriate class.

There is a wrapper class around the states called Machine. This is what client code (simulation.cpp) uses to access the state
transition model.

The RNG used is a Mersenne Twister Engine as defined in the C++ <random> header file. It is assumed that probabilities are
required in the range 0..1.


Markov property
===============
The models generated by genesis have the Markov property. For example, suppose you define a simple two-state system, with states
cancer and normal. Someone could develop cancer but be successfully treated, so their states would be normal->cancer->normal. In this
case the probability of then developing cancer again is independent of the fact that they have already had cancer. This might not be what 
you want. in such a case, you might want to have additional states such as "in_remission" or "treated", which could have a different probability
of moving to the cancer state than that of someone in the intiial, normal state.




Subtle difference
=================
Earlier it was mentioned that you have a choice of whether to specify the probability of remaining in the current state explicitly,
or of leaving it implicit. In theory, it should make no difference - certainly not over many iterations and average results. In practice,
differences can be seen in the results, even if you use the same (fixed) seed each time.

The reason for this is that, although the transition probabilties for that state will be the same, the C++ code will be slightly different,
and if you are using the same (fixed) seed such that you have a reproducible sequence of "random" numbers in the simulation, different
branches of the code will fire. This is best demonstrated by an example.

Explicit case:
-------------
normal cin1 20 80 0.3
normal occult 20 80 0.1
normal normal 20 80 0.6

might give C++ code like:

void normal :: goNext(Machine* m) {
        if (m->age >= 20 && m->age < 80) {
                if (m->prob >= 0 && m->prob < 0.3) {
                        m->setNextStateName("cin1");
                        m->setNext(new cin1());
                        delete this;
                        return;
                }
                if (m->prob >= 0.3 && m->prob < 0.9) {
                        m->setNextStateName("normal");
                        m->setNext(new normal());
                        delete this;
                        return;
                }
                if (m->prob >= 0.9 && m->prob < 1) {
                        m->setNextStateName("occult");
                        m->setNext(new occult());
                        delete this;
                        return;
                }
        } // End if (age in interval)

        cout << "Still in normal state." << endl;
        return;

} // End of goNext() for class normal.


whereas:

Implict case
------------
normal cin1 20 80 0.3
normal occult 20 80 0.1

might give C++ code like:

void normal :: goNext(Machine* m) {
        if (m->age >= 20 && m->age < 80) {
                if (m->prob >= 0 && m->prob < 0.3) {
                        m->setNextStateName("cin1");
                        m->setNext(new cin1());
                        delete this;
                        return;
                }
                if (m->prob >= 0.3 && m->prob < 0.4) {
                        m->setNextStateName("occult");
                        m->setNext(new occult());
                        delete this;
                        return;
                }
        } // End if (age in interval)

        cout << "Still in normal state." << endl;
        return;

} // End of goNext() for class normal.


Note that, in both the implicit and explicit cases, the probability of moving, say, to the occult state is 0.1.
But in the first case this will only fire if the random number is in the range 0.9 to 1, and in the second if
it is in the range 0.3 to 0.4. Both these intervals equate to a probability of 0.1. But the two pieces of
C++ code will give different results if the random number provided is (say) 0.35 - only the second will fire. This
means that the nth individual you are simulating will likely (although not necessarily) have a different sequence
of state transitions in the output files generated by these two different examples.

You could, of course, modify the C++ code so that both situations were exactly equivalent.


