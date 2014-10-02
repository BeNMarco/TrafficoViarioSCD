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

	this.running = false;

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
	if(!this.running && this.receivedStates == this.requiredStates && (typeof this.readyCallback === 'function')){
		console.log("i'm ready!");
		this.readyCallback();
	}
}

Simulation.prototype.init = function(){
	this.prevState = null;
	this.currentState = this.stateCache.shift();
	this.currentState.stateTime = 0;
	this.running = true;

	this.moveObjects(0);
	this.objects.show();

	this.prevState = this.currentState;
	this.currentState = this.stateCache.shift();
	this.currentState.stateTime = 0;

	this.simulationTime = 0;
	this.firstStateNum = this.prevState.num;

}

Simulation.prototype.moveObjects = function(time){
	this.currentState.stateTime += time;
	for(var c in this.currentState.cars){

		var newDistance = 0;
		var prevPosition = 0;

		// if the previous state is empty (simulation just initiated) we put the object at the position given by the state
		if(this.prevState == null){
			newDistance = this.currentState.cars[c].distanza;
			console.log("previous state is null");
			console.log(this.currentState.cars[c]);
		} 
		// otherwise we compute the correct position
		else {
			// if the object switched from a place to another 
			if(this.currentState.cars[c].where != this.prevState.cars[c].where){
				// if the initial position in the current state is set we use it, otherwise we use 0
				prevPosition = this.currentState.cars[c].inizio !== undefined ? this.currentState.cars[c].inizio : 0;
				//console.log("switched to another track");
				//console.log(this.currentState.cars[c]);
			}
			// otherwise simply take the position from the previous state
			else {
				prevPosition = this.prevState.cars[c].distanza;
				//console.log("keep going");
				//console.log(this.prevState.cars[c]);
			}
			//console.log(prevPosition);
			newDistance = 1*prevPosition + 1*((this.currentState.cars[c].distanza - prevPosition) * (this.currentState.stateTime / this.statesDuration));
		}

		/*
		console.log(this.currentState.cars[c].distanza);
		console.log(curElapsed+"/"+this.statesDuration+"="+(curElapsed/this.statesDuration));
		//console.log("delta_dist: "+dd);
		*/
		//console.log("time: "+time+ " curStateTime: "+this.currentState.stateTime);
		//console.log("newDistance: "+newDistance);
		var newPos = null;
		switch(this.currentState.cars[c].where){
			case 'strada':
				newPos = this.map.streets[this.currentState.cars[c].id_strada].getPositionAt(newDistance, this.currentState.cars[c].polo, this.currentState.cars[c].corsia);
				break;
			case 'strada_ingresso':
				newPos = this.map.entranceStreets[this.currentState.cars[c].id_strada].getPositionAt(newDistance, this.currentState.cars[c].polo, this.currentState.cars[c].corsia);
				break;
			case 'traiettoria_ingresso':
				//console.log(this.currentState.cars[c]);
				newPos = this.map.streets[this.currentState.cars[c].id_strada].getPositionAtEntrancePath(
					this.currentState.cars[c].polo, 
					this.currentState.cars[c].distanza_ingresso, 
					this.currentState.cars[c].traiettoria,
					newDistance
					);
				break;
			case 'incrocio':
				newPos = this.map.crossroads[this.currentState.cars[c].id_incrocio].getPositionAt(
					newDistance, 
					this.currentState.cars[c].strada_ingresso, 
					this.currentState.cars[c].quartiere, 
					this.currentState.cars[c].direzione);
				break;
		}
		/*
		console.log(c);
		console.log(this.objects.cars);
		console.log(this.objects.cars[c]);
		*/
		this.objects.cars[c].move(newPos.position, newPos.angle);
	}
}

Simulation.prototype.updateState = function(deltaTime){
	if(deltaTime != 0 && this.currentState != null){
		this.simulationTime += deltaTime;

		var remainingTime = 0;

		if((this.currentState.stateTime+deltaTime) > this.statesDuration){
			remainingTime = deltaTime - (this.statesDuration - this.currentState.stateTime);
			deltaTime = this.statesDuration - this.currentState.stateTime;
		}

		this.moveObjects(deltaTime);

		// if the current state is finished we pass to the next
		if(this.currentState.stateTime >= this.statesDuration){
			this.prevState = this.currentState;
			this.currentState = this.stateCache.shift();
			if(this.currentState === undefined){
				if(typeof this.emptyStateCacheCallback === 'function'){
					this.emptyStateCacheCallback();
				}
				this.running = false;
			} else {
				this.currentState.stateTime = 0;
			}
		}

		// if there is still time to render we perform the rendering on the next status
		if(this.running && remainingTime > 0){
			this.moveObjects(remainingTime);
		}
	}
}