/**
 * Author: Marco Negro Email: negromarc@gmail.com Descr: object that handle the
 * whole simulation
 */
debugTarget = 116;

function doesExists(thing) {
	return typeof thing !== 'undefined' && thing != null;
}

function Simulation(map, objects, requiredStatesToStart, statesDuration) {
	this.stateCache = [];
	this.pathCache = {
		cars : {}
	};
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
	this.ranOutOfStates = false;

	// callbacks
	this.readyCallback = null;
	this.emptyStateCacheCallback = null;
	this.statesAvailableCallback = null;
	this.gotStateCallback = null;

	this.lastStateTime = 0;
}

Simulation.prototype.onReady = function(callback) {
	this.readyCallback = callback;
}

Simulation.prototype.onStateReceived = function(callback) {
	this.gotStateCallback = callback;
}

Simulation.prototype.addState = function(state) {
	this.stateCache.push(state);
	this.receivedStates++;
	console.log("got state");

	if (this.gotStateCallback && (typeof this.gotStateCallback === 'function')) {
		this.gotStateCallback(this.stateCache.length);
	}

	/*
	 * var stateDelta = (new Date().getTime()) - this.lastStateTime;
	 * console.log("Got state after "+stateDelta + " ms"); this.lastStateTime =
	 * new Date().getTime(); console.log(state);
	 */
	if (!this.running && this.receivedStates == this.requiredStates
			&& (typeof this.readyCallback === 'function')) {
		console.log("i'm ready!");
		this.readyCallback();
		if (this.ranOutOfStates) {
			console.log("recovered from empty states");
			this.ranOutOfStates = false;
		}
		if (typeof this.statesAvailableCallback === 'function') {
			this.statesAvailableCallback();
		}
	}
}

Simulation.prototype.init = function() {
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

Simulation.prototype.initPrevState = function(state) {
	var len = state.cars.length;
	for (var i = 0; i < len; i++) {
		var id = state.cars[i].id_quartiere_abitante + "_" + state.cars[i].id_abitante;
		if (this.objects.cars[id]) {
			this.objects.cars[id].prevState = state.cars[i];
		}
	}
}

Simulation.prototype.getNewDistacnce = function(distance, prevPosition)
{
	var curDist = (distance < 0) ? 0 : distance;
	return prevPosition + ((curDist - prevPosition) * (this.currentState.stateTime / this.statesDuration));
}

Simulation.prototype.addNewCar = function(carState)
{
	curCar = new Car(carState.id_abitante, carState.id_quartiere_abitante);
	curCar.draw(this.objects.style);
	curCar.show();
	this.objects.cars[carState.id_quartiere_abitante+"_"+carState.id_abitante] = curCar;
}

Simulation.prototype.moveCar = function(time, c)
{
	var curCarState = this.currentState.cars[c];
	var curCarID = curCarState.id_quartiere_abitante+"_"+curCarState.id_abitante;
	var curCar = this.objects.cars[curCarID];
	if(curCar == null)
	{
		console.log("New car!");
		this.addNewCar(curCarState);
	}
	try {
		var newDistance = 0;
		var prevPosition = 0;

		// if the previous state is empty (simulation just initiated) we
		// put
		// the object at the position given by the state
		if (!doesExists(this.prevState)) {
			newDistance = curCarState.distanza;
		}
		// otherwise we compute the correct position
		else {
			var prevState = curCar.prevState;
			// if the object switched from a place to another
			try {
				if (curCarState.where != prevState.where) {
					// if the initial position in the current state is
					// set we use it, otherwise we use 0
					prevPosition = curCarState.inizio !== undefined ? curCarState.inizio
							: 0;
					if (curCarState.where == 'strada'
							&& prevState.where == 'traiettoria_ingresso') {
						prevPosition = prevState.distanza_ingresso + 10;
					/*
						if(curCarState.id_where == 29){
							console.log("("+curCarState.id_abitante+") now: " + curCarState.where + " before:"
								+ prevState.where + " prevPosition:"
								+ prevPosition);
						}
					*/
					}

					if(curCarState.where == 'strada' && prevState.where == 'cambio_corsia' && prevPosition == 0)
					{
						prevPosition = prevState.distanza_inizio + 20;
					}
				}
				// otherwise simply take the position from the previous
				// state
				else {
					prevPosition = prevState.distanza;
					if (curCarState.where == 'strada_ingresso'
							&& (prevState.in_uscita != curCarState.in_uscita)) {
						prevPosition = 0;
					}
				}
			} catch (err) {
				console.log("curCar:");
				console.log(curCarState);
				console.log("prevState:");
				console.log(prevState);
				console.log("this.prevSate:");
				console.log(this.prevSate);
				console.log(err);
				throw err;
			}
			var curDist = (curCarState.distanza < 0) ? 0 : curCarState.distanza;
			newDistance = 1
					* prevPosition
					+ 1
					* ((curDist - prevPosition) * (this.currentState.stateTime / this.statesDuration));
		}

		var newPos = null;
		switch (curCarState.where) {
		case 'strada':
			newPos = this.map.streets[curCarState.id_where].getPositionAt(
					newDistance, curCarState.polo, curCarState.corsia - 1);
			break;
		case 'strada_ingresso':
			newPos = this.map.entranceStreets[curCarState.id_where]
					.getPositionAt(newDistance, !curCarState.in_uscita,
							curCarState.corsia - 1);
			break;
		case 'traiettoria_ingresso':
			newPos = this.map.streets[curCarState.id_where]
					.getPositionAtEntrancePath(curCarState.polo,
							curCarState.distanza_ingresso,
							curCarState.traiettoria, newDistance);
			break;
		case 'incrocio':
			newPos = this.map.crossroads[curCarState.id_where]
					.getPositionAt(newDistance, curCarState.strada_ingresso,
							curCarState.quartiere_strada_ingresso,
							curCarState.direzione);
			
			break;
		case 'cambio_corsia':
			var path = this.map.streets[curCarState.id_where]
					.getOvertakingPath(curCarState.distanza_inizio,
							curCarState.polo, curCarState.corsia_inizio - 1,
							curCarState.corsia_fine - 1, 20);
			var loc = path.getLocationAt(newDistance);
			newPos = {
				position : loc.point,
				angle : loc.tangent.angle
			}
			break;
		}
		curCar.move(newPos.position, newPos.angle);
	} catch (e) {
		console.log("Got exception");
		console.log(e);
		console.log(curCarState);
	}
}

Simulation.prototype.moveObjects = function(time) {
	this.currentState.stateTime += time;
	var len = this.currentState.cars.length
	for (var c = 0; c < len; c++) {
		// for(var c in this.currentState.cars){
		this.moveCar(time, c);
	}
}

Simulation.prototype.updateState = function(deltaTime) {
	if (deltaTime != 0 && this.currentState != null) {
		this.simulationTime += deltaTime;

		var remainingTime = 0;

		if ((this.currentState.stateTime + deltaTime) > this.statesDuration) {
			remainingTime = deltaTime
					- (this.statesDuration - this.currentState.stateTime);
			deltaTime = this.statesDuration - this.currentState.stateTime;
		}

		this.moveObjects(deltaTime);

		// if the current state is finished we pass to the next
		if (this.currentState.stateTime >= this.statesDuration) {
			this.prevState = this.currentState;
			this.initPrevState(this.prevState);
			this.currentState = this.stateCache.shift();
			if (this.currentState === undefined) {
				if (typeof this.emptyStateCacheCallback === 'function') {
					console.log("calling callback");
					this.emptyStateCacheCallback();
				}
				console.log("no more states");
				this.ranOutOfStates = true;
				this.running = false;
				this.receivedStates = 0;
			} else {
				this.currentState.stateTime = 0;
			}
		}

		// if there is still time to render we perform the rendering on the next
		// status
		if (this.running && remainingTime > 0) {
			this.moveObjects(remainingTime);
		}
	}
}

Simulation.prototype.fastForward = function() {
	console.log("Called fastForward");
	if (this.running && this.stateCache.length >= this.requiredStates) {
		var tmpArr = this.stateCache.slice(this.stateCache.length
				- this.requiredStates);
		console.log("keeping the following..");
		console.log(tmpArr);
		this.stateCache = tmpArr;
		this.init();
	}
}