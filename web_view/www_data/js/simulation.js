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

	this.onObjectMoved = null;

	this.lastStateTime = 0;
	this.curStateNum = 0;
}

Simulation.prototype.onReady = function(callback) {
	this.readyCallback = callback;
}

Simulation.prototype.onStateReceived = function(callback) {
	this.gotStateCallback = callback;
}

Simulation.prototype.addState = function(state) {
	console.log("got state");
	for(var i in state.abitanti)
	{
		state.abitanti[i].num = this.curStateNum;
	}
	this.stateCache.push(state);
	this.receivedStates++;
	this.curStateNum++;

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

Simulation.prototype.setCarPathLength = function(state)
{
	switch (state.where) {
		case 'strada':
			state.pathLength = this.map.streets[state.id_where].getStreetLength();
			break;
		case 'strada_ingresso':
			state.pathLength = this.map.entranceStreets[state.id_where].getStreetLength();
			break;
		case 'traiettoria_ingresso':
			state.pathLength = this.map.streets[state.id_where]
			.getEntrancePathLength(state.polo,
				state.distanza_ingresso,
				state.traiettoria);
			break;
		case 'incrocio':
			state.pathLength = this.map.crossroads[state.id_where]
			.getCrossingPathLength(state.strada_ingresso,
				state.quartiere_strada_ingresso,
				state.direzione);

			break;
		case 'cambio_corsia':
			state.pathLength = this.map.streets[state.id_where]
			.getOvertakingPathLength(state.distanza_inizio,
				state.polo, state.corsia_inizio - 1,
				state.corsia_fine - 1, 20);
			break;
	}
	return state;
}

Simulation.prototype.setPedPathLength = function(state)
{
	state.bike = (state.mezzo == "bike");

	switch (state.where) {
		case 'strada':
			state.pathLength = this.map.streets[state.id_where].getStreetLength();
			break;
		case 'strada_ingresso':
			state.pathLength = this.map.entranceStreets[state.id_where].getStreetLength();
			break;
		case 'traiettoria_ingresso':
			state.pathLength = this.map.streets[state.id_where]
			.getOnZebraPathLength(state.polo,
				state.distanza_ingresso,
				state.traiettoria, state.bike);
			break;
		case 'incrocio':
			state.pathLength = this.map.crossroads[state.id_where]
			.getPedestrianPathLength(state.strada_ingresso,
				state.quartiere_strada_ingresso,
				state.direzione);
			break;
	}

	return state;
}

Simulation.prototype.initPrevState = function(state) {
	var len = state.abitanti.length;
	var done = false;
	for (var i = 0; i < len; i++) {
		var curState = state.abitanti[i];
		var id = curState.id_quartiere_abitante + "_" + curState.id_abitante;
		var o = null;
		try{
			switch(curState.mezzo)
			{
				case 'car':
					o = this.objects.cars[id];
					curState = this.setCarPathLength(curState);
					break;
				case 'bike':
					o = this.objects.bikes[id];
					curState = this.setPedPathLength(curState);
					break;
				case 'walking':
					o = this.objects.pedestrians[id];
					curState = this.setPedPathLength(curState);
					break;
			}
			if(!done) {console.log("Before> Prev:"+o.prevState.num+" Cur:"+curState.num); }
			if (o) {
				o.prevState = curState;
			}
			if(!done) {console.log("After> Prev:"+o.prevState.num+" Cur:"+curState.num); done = true;}
		} catch (e) {
			console.log("INIT PREV STATE > Exception ++++++++++++++++++++");
			console.log("exception:");
			console.log(e);
			console.log("state:");
			console.log(curState);
			console.log("o:");
			console.log(o);
			console.log("++++++++++++++++++++++++++++++++++++++++++++++++");
			throw e;
		}
	}
}

Simulation.prototype.addNewCar = function(carState)
{
	curCar = new Car(carState.id_abitante, carState.id_quartiere_abitante);
	curCar.draw(this.objects.style);
	curCar.show();
	this.objects.cars[carState.id_quartiere_abitante+"_"+carState.id_abitante] = curCar;
}

Simulation.prototype.computeNewDistance = function(distance, prevPosition)
{
	var curDist = (distance < 0) ? 0 : distance;
	return prevPosition + ((curDist - prevPosition) * (this.currentState.stateTime / this.statesDuration));
}

Simulation.prototype.computeCurrentLength = function(length)
{
	return length * (this.currentState.stateTime / this.statesDuration);
}

function onSamePath(prevState, curState)
{
	var toRet = (curState.where == prevState.where);
	if(toRet)
	{
		switch(curState.where)
		{
			case 'incrocio':
				toRet = (toRet && 
					(curState.strada_ingresso == prevState.strada_ingresso) && 
					(curState.quartiere_strada_ingresso == prevState.quartiere_strada_ingresso) &&
					(curState.direzione == prevState.direzione));
				break;
			case 'traiettoria_ingresso':
				toRet = (toRet &&
					(curState.traiettoria == prevState.traiettoria));
				break;
			case 'strada_ingresso':
				toRet = (toRet &&
					(curState.in_uscita == prevState.in_uscita));
				break;
			case 'cambio_corsia':
				toRet = (toRet &&
					(curState.distanza_inizio == prevState.distanza_inizio));
				break;
		}
	}
	return toRet;
}

Simulation.prototype.computeNewDistanceAndState = function(prevState, curState)
{
	var newDistance = 0;
	var stateToUse = null;
	var prevPosition = 0;

	// se lo stato precedente è vuoto posizioniamo 
	// l'oggetto alla posizione indicata dallo stato attuale
	// (FALLBACK)
	if (!doesExists(this.prevState)) {
		newDistance = curState.distanza;
		stateToUse = curState;
	}
	// altrimenti calcoliamo la posizione giusta
	else {
		// se l'oggetto è passato da uno stato all'altro
		try {
			if (!onSamePath(prevState, curState)) {
				// calcolo della posizione iniziale della traiettoria dello stato successivo

				// se ci arriva dallo stato la usiamo
				var curInizio = curState.inizio;

				// se non abbiamo un riferimento di inizio traiettoria lo calcoliamo
				if(!curInizio){

					// settiamo a 0 nel caso in cui non riusciamo a risolverlo
					curInizio = 0;

					// se la traiettoria precedente era una traiettoria di ingresso
					// e quella attuale è una strada prendiamo come inzio traiettoria
					// il punto della strada di ingresso + la larghezza della corisa 
					// sommata alla larghezza del marciapiede
					if (curState.where == 'strada'
							&& prevState.where == 'traiettoria_ingresso') {
						curInizio = prevState.distanza_ingresso + this.map.mapStyle.laneWidth+this.map.mapStyle.pavementWidth;
					}
					// altrimenti, se siamo in una strada e prima eravamo in un cambio
					// corsia, prendiamo la posizione in cui abbiamo iniziato a fare 
					// il cambio corsia e ci sommiamo la lunghezza del cambio
					else if(curState.where == 'strada' && prevState.where == 'cambio_corsia' && prevPosition == 0)
					{
						curInizio = prevState.distanza_inizio + 20;
					}
				}

				var segLen1 = prevState.pathLength - prevState.distanza;
				var segLen2 = curState.distanza - curInizio;
				var segLen = segLen1+segLen2;

				// lunghezza che abbiamo percorso in questo Dt
				var doneLen = this.computeCurrentLength(segLen);

				// se abbiamo fatto più di segLen1 allora siamo sulla nuova 
				// traiettoria
				if(doneLen > segLen1)
				{
					// prendiamo come nuova distanza l'inizio della nuova traiettoria
					// più la distanza che abbiamo coperto meno la lunghezza coperta
					// nella traiettoria precedente
					newDistance = curInizio + doneLen - segLen1;
					stateToUse = curState;
				} 
				// altrimenti siamo ancora nella traiettoria precedente
				else {
					// prendiamo la distanza percorsa
					newDistance = prevState.distanza + doneLen;
					// e usiamo lo stato precedente per risolvere 
					// la posizione sulla traiettoria precedente
					stateToUse = prevState;
				}
			}
			// altrimenti prendiamo la posizione dallo stato precedente
			else {
				prevPosition = prevState.distanza;
				stateToUse = curState;
				// in questo caso un oggetto è arrivato alla fine di una strada 
				// di ingresso e vuole tornare indietro
				if (curState.where == 'strada_ingresso'
						&& (prevState.in_uscita != curState.in_uscita)) {
					prevPosition = 0;
				}
				if(prevState.distanza > curState.distanza)
				{
					console.log("Not possible!");
					console.log("prev");
					console.log(prevState);
					console.log("cur");
					console.log(curState);
					console.log("selected");
					console.log(stateToUse);
				}
				//newDistance = this.computeNewDistance(curState.distanza, prevPosition);
				newDistance = prevState.distanza + this.computeCurrentLength((curState.distanza-prevState.distanza));
			}
		} catch (err) {
			console.log("COMPUTER NEW DISTANCE > Exception ------------------------");
			console.log("exception:");
			console.log(err);
			console.log("curCar:");
			console.log(curState);
			console.log("prevState:");
			console.log(prevState);
			console.log("this.prevSate:");
			console.log(this.prevSate);
			console.log("prevPosition:");
			console.log(prevPosition);
			console.log("----------------------------------------------------------");
			throw err;
		}
	}
	return {state: stateToUse, distance: newDistance};
}

Simulation.prototype.moveCar = function(time, curCarState)
{
	var curCarID = curCarState.id_quartiere_abitante+"_"+curCarState.id_abitante;
	var s = null;
	var curCar = this.objects.cars[curCarID];
	if(curCar == null)
	{
		console.log("New car!");
		curCar = this.objects.addCar(curCarState.id_abitante, curCarState.id_quartiere_abitante, curCarState.length_abitante);
		curCar.prevState = curCarState;
	}
	try {
		var toUse = this.computeNewDistanceAndState(curCar.prevState, curCarState);
		s = toUse.state;
		var newDistance = toUse.distance;

		var newPos = null;
		switch (s.where) {
		case 'strada':
			newPos = this.map.streets[s.id_where].getPositionAt(
					newDistance, s.polo, s.corsia - 1);
			break;
		case 'strada_ingresso':
			newPos = this.map.entranceStreets[s.id_where]
					.getPositionAt(newDistance, !s.in_uscita,
							s.corsia - 1);
			break;
		case 'traiettoria_ingresso':
			newPos = this.map.streets[s.id_where]
					.getPositionAtEntrancePath(s.polo,
							s.distanza_ingresso,
							s.traiettoria, newDistance);
			break;
		case 'incrocio':
			newPos = this.map.crossroads[s.id_where]
					.getPositionAt(newDistance, s.strada_ingresso,
							s.quartiere_strada_ingresso,
							s.direzione);
			
			break;
		case 'cambio_corsia':
			var path = this.map.streets[s.id_where]
					.getOvertakingPath(s.distanza_inizio,
							s.polo, s.corsia_inizio - 1,
							s.corsia_fine - 1, 20);
			var loc = path.getLocationAt(newDistance);
			newPos = {
				position : loc.point,
				angle : loc.tangent.angle
			}
			break;
		}
		curCar.move(newPos.position, newPos.angle);
		if(typeof this.onObjectMoved === 'function')
		{
			this.onObjectMoved(curCar, s, newDistance, newPos);
		}
	} catch (e) {
		console.log("MOVE CAR > Got exception =====");
		console.log(e);
		console.log("current:");
		console.log(curCarState);
		console.log("previous:");
		console.log(curCar.prevState);
		console.log("used:");
		console.log(s);
		console.log("==============================");
	}
}

Simulation.prototype.moveBipede = function(time, curBiState)
{
	var curBiID = curBiState.id_quartiere_abitante+"_"+curBiState.id_abitante;
	var s = null;
	var curBi = (curBiState.mezzo == 'bike') ? this.objects.bikes[curBiID] : this.objects.pedestrians[curBiID];
	curBiState.bike = (curBiState.mezzo == "bike");
	if(curBi == null)
	{
		if(curBiState.bike)
		{
			curBi = this.objects.addBike(curBiState.id_abitante, curBiState.id_quartiere_abitante);
		} else {
			curBi = this.objects.addPedestrian(curBiState.id_abitante, curBiState.id_quartiere_abitante);
		}
		curBi.prevState = curBiState;
	}
	try {
		
		var toUse = this.computeNewDistanceAndState(curBi.prevState, curBiState);
		s = toUse.state;
		var newDistance = toUse.distance;

		var newPos = null;
		switch (s.where) {
		case 'strada':
			newPos = this.map.streets[s.id_where].getOnPavementPositionAt(
					newDistance, s.polo, s.bike);
			break;
		case 'strada_ingresso':
			newPos = this.map.entranceStreets[s.id_where]
					.getOnPavementPositionAt(newDistance, !s.in_uscita,
							s.bike);
			break;
		case 'traiettoria_ingresso':
			newPos = this.map.streets[s.id_where]
					.getOnZebraPositionAt(newDistance, s.polo,
							s.distanza_ingresso,
							s.traiettoria, s.bike);
			break;
		case 'incrocio':
			newPos = this.map.crossroads[s.id_where]
					.getPositionOnPedestrianPath(newDistance, s.strada_ingresso,
							s.quartiere_strada_ingresso,
							s.direzione);
			
			break;
		}
		curBi.move(newPos.position);
		if(typeof this.onObjectMoved === 'function')
		{
			this.onObjectMoved(curBi, s, newDistance, newPos);
		}
	} catch (e) {
		console.log("MOVE BIPEDE > Got exception =====");
		console.log(e);
		console.log("current:");
		console.log(curBiState);
		console.log("previous:");
		console.log(curBi.prevState);
		console.log("used:");
		console.log(s);
		console.log("=================================");
	}
}

Simulation.prototype.moveObjects = function(time) {
	this.currentState.stateTime += time;
	var len = this.currentState.abitanti.length;
	for (var c = 0; c < len; c++) {
		var s = this.currentState.abitanti[c];
		switch(s.mezzo)
		{
			case 'car':
				this.moveCar(time, s);
				break;
			case 'bike':
			case 'walking':
				this.moveBipede(time, s);
				break;
		}
	}
}

Simulation.prototype.removeOnesWhoLeft = function()
{
	for (var i = this.currentState.abitanti_uscenti.length - 1; i >= 0; i--) {
		var a = this.currentState.abitanti_uscenti[i];
		switch(a.mezzo)
		{
			case "car":
				this.objects.removeCar(a.id_abitante, a.id_quartiere_abitante);
			case "bike":
				this.objects.removeBike(a.id_abitante, a.id_quartiere_abitante);
			case "pedestrian":
				this.objects.removePedestrian(a.id_abitante, a.id_quartiere_abitante);
			default:
				break;
		}
	}
}

Simulation.prototype.setTrafficLights = function(trafficLights, idxArray, state)
{
	for(var r in idxArray)
	{
		var trl = trafficLights[idxArray[r]];
		for(tri in trl)
		{
			trl[tri].setColor(state);
		}
	}
}

Simulation.prototype.updateTrafficLightsState = function()
{
	for(var i in this.currentState.semafori)
	{
		var s = this.currentState.semafori[i];
		if(s)
		{
			var tArr = this.map.crossroads[s.id_incrocio].trafficLights;
			this.setTrafficLights(tArr, s.index_road_rossi, 'red');
			this.setTrafficLights(tArr, s.index_road_verdi ,'green');
		}
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
			this.initPrevState(this.currentState);
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

				this.removeOnesWhoLeft();
				this.updateTrafficLightsState();
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

Simulation.prototype.stop = function(){
	this.running = false;
}