/**
*	Author: Marco Negro
*	Email: negromarc@gmail.com
*	Descr: object that handle the whole simulation
*/

state = [
	{
		num: 1,
		cars: {
			1: {id_strada: 1, where: 'strada', distanza: 200, polo: true, corsia: 2}
		},
	},
	{
		num: 2,
		cars: {
			1: {id_incrocio: 'i1', where: 'incrocio', distanza: 200, strada_ingresso: 1, quartiere:1, direzione:'straight_1'}
		},
	},
]



function Simulation(map, objects, requiredStatesToStart, statesDuration){
	this.stateCache = [];
	this.map = map;
	this.objects = objects;
	this.simulationTime = 0;
	this.prevState = null;
	this.statesDuration = statesDuration;
	this.currentState = null;

	this.receivedStates = 0;
	this.requiredStates = requiredStatesToStart;
	this.prevStateRemainingTime = 0;

	// callbacks
	this.readyCallback = null;
	this.finishCallbal = null;
	this.emptyStateCacheCallback = null;
}

Simulation.prototype.onReady = function(callback){
	this.readyCallback = callback;
}

Simulation.prototype.addState = function(state){
	this.stateCache.push(state);
	this.receivedStates++;
	if(this.receivedStates == this.requiredStates && (typeof this.readyCallback === 'function')){
		this.readyCallback();
	}
}

Simulation.prototype.init = function(){
	this.prevState = this.stateCache.shift();
	this.currentState = this.stateCache.shift();
}

Simulation.prototype.updateState = function(deltaTime){
	if(deltaTime != 0 && this.currentState != null){
		var remainingTime = 0;

		// checking if the time elapsed from the last update overflow the current status
		if((this.simulationTime + deltaTime) > (this.currentState.num * this.statesDuration)){
			remainingTime = deltaTime - ((this.currentState.num * this.statesDuration) - this.simulationTime);
			deltaTime = deltaTime - remainingTime;
		}


		this.simulationTime += deltaTime;
		/*
		console.log("delta: "+deltaTime);
		console.log("remainingTime: "+remainingTime);
		console.log("simulationTime: "+this.simulationTime);
*/	
		var curElapsed = this.simulationTime - this.prevState.num*this.statesDuration;
		for(var c in this.prevState.cars){
			var newDistance = 0;
			if(this.currentState.cars[c].where != this.prevState.cars[c].where){
				newDistance = ((this.currentState.cars[c].distanza)*(curElapsed/this.statesDuration));
			} else {
				newDistance = this.prevState.cars[c].distanza + ((this.currentState.cars[c].distanza - this.prevState.cars[c].distanza)*(curElapsed/this.statesDuration));
			}
			//console.log("delta_dist: "+dd);
			var newPos = null;
			switch(this.currentState.cars[c].where){
				case 'strada':
					newPos = this.map.streets[this.currentState.cars[c].id_strada].getPositionAt(newDistance, this.currentState.cars[c].polo, this.currentState.cars[c].corsia);
					break;
				case 'incrocio':
					newPos = this.map.crossroads[this.currentState.cars[c].id_incrocio].getPositionAt(
						newDistance, 
						this.currentState.cars[c].strada_ingresso, 
						this.currentState.cars[c].quartiere, 
						this.currentState.cars[c].direzione);
					break;
			}
			//console.log(newPos);
			this.objects.cars[c].move(newPos.position, newPos.angle);
		}

		// if the current state is finished we pass to the next
		if(this.simulationTime == this.currentState.num * this.statesDuration){
			this.prevState = this.currentState;
			this.currentState = this.stateCache.shift();
			if(this.currentState == null && typeof this.emptyStateCacheCallback === 'function'){
				this.emptyStateCacheCallback();
			}
		}

		// if there is still time to render we perform the rendering on the next status
		if(remainingTime > 0){
			this.updateState(remainingTime);
		}
	}
}