/**
*	Author: Marco Negro
*	Email: negromarc@gmail.com
*	Descr: object that handle the whole simulation
*/

state = {
	time: 340,
	cars: [
		{id: 1, where: 'strada', distanza: 200, polo: true, corsia: 2}
	],
}



function Simulation(map, objects, requiredStatesToStart, statesDuration){
	this.stateCache = [];
	this.map = map;
	this.objects = objects;
	this.simulationTime = 0;
	this.currentState = null;
	this.nextState = null;

	this.readyCallback = null;
	this.receivedStates = 0;
	this.requiredStates = requiredStatesToStart;
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

Simulation.prototype.updateState = function(deltaTime){
	this.simulationTime += deltaTime;
	if(this.simulationTime > )
}