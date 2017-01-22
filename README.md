# SDDKit - State Driven Development Kit
Easiest way for implementing Hierarchical State Machine (HSM) based programs in Objective-C.

## Installation
Clone or download source codes directly, or by using [CocoaPods](https://cocoapods.org/).

```
pod 'SDDKit'

```

## High Level Aspects

Classes listed below gives the major functionalities of SDDKit.

* SDDState
* SDDStateMachine
* SDDEventsPool
* SDDBuilder

![MajorClasses](https://yuml.me/diagram/class/[SDDBuilder]->[SDDEventsPool],[SDDBuilder]-*>[SDDStateMachine],[SDDStateMachine]->[SDDEventsPool],[SDDStateMachine]-*>[SDDState])

But as being a 'Client', two of them need to be cared about for you.

* SDDEventsPool
* SDDBuilder

![CallerAspect](https://yuml.me/diagram/class/[SDDBuilder]->[SDDEventsPool],[Client]->[SDDBuilder],[Client]->[SDDEventsPool])

### SDDState
SDDState contains activation and deactivation blocks, which performs the entering and exiting actions.

### SDDStateMachine
Every instance of SDDStateMachine represents a standalone statemachine object. Each of them describes state hierarchies and transitions.

### SDDEventsPool
The event dispatching class. It is important to know that a statemachine have to be added as a subscriber of eventspool before it can drive by incoming events. Some apps have more than one eventspool to avoid duplication of signal names.

### SDDBuilder
A string parsing based SDDStateMachine builder. It provides the easiest way for generating and organizing multiple statemachines.


## Examples
### Simple
```obj-c
SDDBuilder *builder = [SDDBuilder alloc] initWithLogger:nil epool:[SDDEventsPool sharedPool];

[builder addStateMachineWithContext:nil dsl:SDDOCLanguage(
	// Every statemachine can and must have one topstate
	[TopState
		// Two substates
		[A]
		[B]
	]

	// Since TopState has two descendants, a $Default transition have to be provided to avoid ambiguity.
	// Another choice is using $Initial transition from outter state [.] such as:
	// [.] -> [A]: $Initial
	[TopState] -> [A]: $Default
	
	// If [A] is the current state and signal 'E1' occurs, it will transit to state [B]
	[A]->[B]: E1
)];

[[SDDEventsPool sharedPool] scheduleEvent:SDDLiteral(E1)];
// Now we are in state [B]
```

### Activation and Deactivation
A statemachine with **nil** context helps nothing. Something has to be done that we could distinguish between one state and another. That's the reason why we are using statemachine, aren't we?
```obj-c
@interface Charles
@end

@implementation Charles
- (void)wakeup {
	NSLog(@"Good morning.")
}

- (void)sayGoodbye {
	NSLog(@"Bye, see ya.");
}

- (void)goToBed {
	NSLog(@"Good night.")
}

@end

int main() {
	Charles *charles = [[Charles alloc] init];

	SDDBuilder *builder = [SDDBuilder alloc] initWithLogger:nil epool:[SDDEventsPool sharedPool];

	[builder addStateMachineWithContext:charles dsl:SDDOCLanguage(
		[Me
			[Awake  
				e: wakeup	  // 'e' is short for entering
				x: sayGoodbye // 'x' is short for exiting
			]
			[Asleep e: goToBed]
		]
	
		[.]	     -> [Awake]  : $Initial
		[Awake]  -> [Asleep] : Sunset
		[Asleep] -> [Awake]  : Sunrise
	)];
	// Outputs 'Good morning.' for entering initial state [Awake]
	
	[[SDDEventsPool sharedPool] scheduleEvent:SDDLiteral(Sunset)];
	// Outputs 'Bye, see ya.' for exiting state [Awake]
	// Outputs 'Good night' for entering state [Asleep]
	
	[[SDDEventsPool sharedPool] scheduleEvent:SDDLiteral(Sunrise)];
	// Outputs 'Good morning.' for entering state [Awake]

	return 0;
)
```
