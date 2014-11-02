/**
*	Author: Marco Negro
*	Email: negromarc@gmail.com
*	Descr: object that handle the whole simulation
*/

function Simulation(map, objects, requiredStatesToStart, statesDuration){
	this.stateCache = [];
	this.pathCache = {cars:{}};
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
	//console.log("got state");
	//console.log(state);
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
	this.initPrevState(this.currentState);
	this.currentState = this.stateCache.shift();
	this.currentState.stateTime = 0;

	this.simulationTime = 0;
	this.firstStateNum = this.prevState.num;

}

Simulation.prototype.initPrevState = function(state){
	var len = state.cars.length;
	for(var i = 0; i < len; i++){
		if(this.objects.cars[state.cars[i].id_abitante]){
			this.objects.cars[state.cars[i].id_abitante].prevState = state.cars[i];
		}
	}
}

Simulation.prototype.moveObjects = function(time){
	this.currentState.stateTime += time;
	var len = this.currentState.cars.length
	for(var c = 0; c < len; c++){
	//for(var c in this.currentState.cars){
		var curCar = this.currentState.cars[c];
		if(this.objects.cars[curCar.id_abitante]){
		var newDistance = 0;
		var prevPosition = 0;

		// if the previous state is empty (simulation just initiated) we put the object at the position given by the state
		if(this.prevState == null){
			newDistance = curCar.distanza;
			console.log("previous state is null");
			console.log(curCar);
		} 
		// otherwise we compute the correct position
		else {
			// if the object switched from a place to another 
			// if(curCar.where != this.prevState.cars[curCar.id_abitante].where){
			if(curCar.where != this.objects.cars[curCar.id_abitante].prevState.where){
				// if the initial position in the current state is set we use it, otherwise we use 0
				prevPosition = curCar.inizio !== undefined ? curCar.inizio : 0;

			}
			// otherwise simply take the position from the previous state
			else {
				// prevPosition = this.prevState.cars[curCar.id_abitante].distanza;
				prevPosition = this.objects.cars[curCar.id_abitante].prevState.distanza;
			}
			newDistance = 1*prevPosition + 1*((curCar.distanza - prevPosition) * (this.currentState.stateTime / this.statesDuration));
		}
		//console.log("new distance: "+newDistance);
		var newPos = null;
		switch(curCar.where){
			case 'strada':
				newPos = this.map.streets[curCar.id_where].getPositionAt(newDistance, curCar.polo, curCar.corsia-1);
				break;
			case 'strada_ingresso':
				newPos = this.map.entranceStreets[curCar.id_where].getPositionAt(newDistance, curCar.polo, curCar.corsia-1);
				break;
			case 'traiettoria_ingresso':
				newPos = this.map.streets[curCar.id_where].getPositionAtEntrancePath(
					curCar.polo, 
					curCar.distanza_ingresso, 
					curCar.traiettoria,
					newDistance
					);
				break;
			case 'incrocio':
			//try{
				newPos = this.map.crossroads[curCar.id_where].getPositionAt(
					newDistance, 
					curCar.strada_ingresso, 
					curCar.quartiere_strada_ingresso, 
					curCar.direzione);
			/*} catch(err){

				console.log(err);
				console.log(curCar);
				console.log("BOOM!");
			}*/
				break;
			case 'cambio_corsia':
			/*
				if(this.pathCache.cars[c] === undefined || (this.pathCache.cars[c] !== undefined && this.pathCache.cars[c].idp != this.currentState.num)){
					this.pathCache.cars[c] = this.map.streets[curCar.id_where].getOvertakingPath(
						curCar.distanza_inizio, 
						curCar.polo, 
						curCar.corsia_inizio, 
						curCar.corsia_fine, 
						20
						);
					this.pathCache.cars[c].idp = this.currentState.num;
				}
				var loc = this.pathCache.cars[c].getLocationAt(newDistance); 
				*/
				var path = this.map.streets[curCar.id_where].getOvertakingPath(
						curCar.distanza_inizio, 
						curCar.polo, 
						curCar.corsia_inizio-1, 
						curCar.corsia_fine-1, 
						20
						);
				var loc = path.getLocationAt(newDistance); 
				newPos = {
					position: loc.point,
					angle: loc.tangent.angle
				}
				break;
		}
		//try{
			//console.log("movign "+curCar.id_abitante+" here:");
			//console.log(newPos.position);
			this.objects.cars[curCar.id_abitante].move(newPos.position, newPos.angle);
		/*} catch(err){
			console.log(err);
			console.log(curCar);
			console.log(newPos);
		}*/
	}
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
			this.initPrevState(this.prevState);
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