/**
 * Author: Marco Negro Email: negromarc@gmail.com Descr: object that handle the
 * whole simulation
 */
debugTarget = 116;

function doesExists(thing) {
	return typeof thing !== 'undefined' && thing != null;
}

function WorldSimulation(objects, requiredStatesToStart, statesDuration){
	this.pieces = {};
	this.entities = objects;
	this.requiredStatesToStart = requiredStatesToStart;
	this.statesDuration = statesDuration;
}

WorldSimulation.prototype.addPiece = function(map){
	var toRet = new PieceSimulation(map, this.entities, this.requiredStatesToStart, this.statesDuration);
	this.pieces[map.id] = toRet;
	console.log(this.pieces);
	return toRet;
}

WorldSimulation.prototype.updateState = function(deltaTime){
	for (var i in this.pieces) {
		this.pieces[i].updateState(deltaTime);
	}
}

WorldSimulation.prototype.stop = function(){
	console.log("Stopping");
	console.log(this);
	for (var i in this.pieces) {
		this.pieces[i].socket.close();
		this.pieces[i].stop();
	}
}

WorldSimulation.prototype.fastForward = function(){
	for (var i in this.pieces) {
		this.pieces[i].fastForward();
	}
}


function PieceSimulation(map, objects, requiredStatesToStart, statesDuration) {
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

	this.onReady = null;
	this.onEmptyCache = null;
	this.onStatesAvailable = null;
	this.onStateReceived = null;
	this.onSimulationStopped = null;

	this.onObjectMoved = null;

	this.lastStateTime = 0;
	this.curStateNum = 0;
	this.traiettorie = map.traiettorie;
	this.sockets = null;

	this.world = null;
}



PieceSimulation.prototype.prepareSocket = function(target){
	this.socket = new WebSocket(target);

	var that = this;
  this.socket.onmessage = function(event) {

    var msg = JSON.parse(event.data);
    if(msg.type)
    {
      if(msg.type == "update")
      {
        that.addState(msg);
      } 
    }
  }
  return this.socket;
}

PieceSimulation.prototype.setTraiettorie = function(traiettorie){
	this.traiettorie = traiettorie;
}

PieceSimulation.prototype.addState = function(state) {
	var newState = [];
	for(var i in state.abitanti)
	{
		if(state.abitanti[i].mezzo == 'car'){
			newState.push(this.setCarPathLength(state.abitanti[i]));
		}
	}
	this.curStateNum++;
	state.abitanti = newState;
	state.num = this.curStateNum;
	this.stateCache.push(state);
	this.receivedStates++;

	if (this.onStateReceived && (typeof this.onStateReceived === 'function')) {
		this.onStateReceived(this.map.id, this.stateCache.length);
	}

	if (!this.running && this.receivedStates == this.requiredStates
			&& (typeof this.onReady === 'function')) {
		console.log("i'm ready!");
		this.onReady();
		if (this.ranOutOfStates) {
			console.log("recovered from empty states");
			this.ranOutOfStates = false;
		}
		if (typeof this.onStatesAvailable === 'function') {
			this.onStatesAvailable(this.map.id);
		}
	}
}

PieceSimulation.prototype.init = function() {
	this.prevState = null;
	this.currentState = this.stateCache.shift();
	this.currentState.stateTime = 0;
	this.running = true;

	//this.moveObjects(0);

	this.prevState = this.currentState;
	this.initPrevState(this.currentState);
	this.currentState = this.stateCache.shift();
	this.currentState.stateTime = 0;

	this.simulationTime = 0;
	this.firstStateNum = this.prevState.num;
}

PieceSimulation.prototype.setCarPathLength = function(state)
{
	switch (state.where) {
		case 'strada':
			state.pathLength = this.map.streets[state.id_where].getStreetLength();
			break;
		case 'incrocio':
			state.pathLength = this.map.crossroads[state.id_where]
			.getCrossingPathLength(state.strada_ingresso,
				state.quartiere_strada_ingresso,
				state.direzione);
			break;
		case 'traiettoria_ingresso':
			state.pathLength = this.traiettorie.traiettorie_ingresso[state.traiettoria].lunghezza;
			break;
		case 'cambio_corsia':
			state.pathLength = this.traiettorie.cambio_corsia.lunghezza_traiettoria;
			break;
	}
	return state;
}

PieceSimulation.prototype.initPrevState = function(state) {
	var done = false;
	for (var i in state.abitanti) {
		var curState = state.abitanti[i];
		curState.num = state.num;
		var id = curState.id_quartiere_abitante + "_" + curState.id_abitante;
		var v = this.objects.getOrAddVehicle(curState.id_abitante, curState.id_quartiere_abitante, curState.length_abitante, curState.is_a_bus);
		v.prevState = curState;
	}
}

PieceSimulation.prototype.addNewCar = function(carState)
{
	curCar = new Car(carState.id_abitante, carState.id_quartiere_abitante);
	curCar.draw(this.objects.style);
	curCar.show();
	this.objects.cars[carState.id_quartiere_abitante+"_"+carState.id_abitante] = curCar;
}

PieceSimulation.prototype.computeNewDistance = function(distance, prevPosition)
{
	var curDist = (distance < 0) ? 0 : distance;
	return prevPosition + ((curDist - prevPosition) * (this.currentState.stateTime / this.statesDuration));
}

PieceSimulation.prototype.computeCurrentLength = function(length)
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

PieceSimulation.prototype.computeNewDistanceAndState = function(prevState, curState)
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

					// lunghezza da percorrere nella traiettoria indicata dallo stato
					// precedente
					var segLen1 = prevState.pathLength - prevState.distanza;

					// se la traiettoria precedente era una traiettoria di ingresso
					// e quella attuale è una strada prendiamo come inzio traiettoria
					// il punto della strada di ingresso + la larghezza della corisa 
					// sommata alla larghezza del marciapiede
					if (prevState.where == 'traiettoria_ingresso' 
							&& curState.where == 'strada') {
						if(curState.polo){
							curInizio = curState.pathLength - prevState.distanza_ingresso + this.map.mapStyle.laneWidth+this.map.mapStyle.pavementWidth;
						} else {
							curInizio = prevState.distanza_ingresso + this.map.mapStyle.laneWidth+this.map.mapStyle.pavementWidth;
						}
					}
					else if (prevState.where == 'strada' 
							&& curState.where == 'traiettoria_ingresso') {
						if(prevState.polo){
							segLen1 = prevState.pathLength - curState.distanza_ingresso - this.map.mapStyle.laneWidth-this.map.mapStyle.pavementWidth - prevState.distanza;
						} else {
							segLen1 = curState.distanza_ingresso - this.map.mapStyle.laneWidth-this.map.mapStyle.pavementWidth - prevState.distanza;
						}
					}
					// altrimenti, se siamo in una strada e prima eravamo in un cambio
					// corsia, prendiamo la posizione in cui abbiamo iniziato a fare 
					// il cambio corsia e ci sommiamo la lunghezza del cambio
					else if(prevState.where == 'cambio_corsia' && curState.where == 'strada') {
						if(curState.polo){
							curInizio = curState.pathLength - prevState.distanza_inizio + this.traiettorie.cambio_corsia.lunghezza_lineare;
						} else {
							curInizio = prevState.distanza_inizio + this.traiettorie.cambio_corsia.lunghezza_lineare;
						}
					}
					// se eravamo in una strada e dobbiamo fare un cambio corsia, 
					// la lunghezza della strada che consideriamo arriva fino al punto in 
					// cui abbiamo il cambio corsia
					else if (prevState.where == 'strada' && curState.where == 'cambio_corsia'){
						segLen1 = curState.distanza_inizio - prevState.distanza;
					}
				}

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
				newDistance = prevState.distanza + this.computeCurrentLength((curState.distanza-prevState.distanza));
			}
		} catch (err) {
			throw err;
		}
	}
	return {state: stateToUse, distance: newDistance};
}

PieceSimulation.prototype.moveCar = function(time, curCarState)
{
	var curCarID = curCarState.id_quartiere_abitante+"_"+curCarState.id_abitante;
	var s = null;
	var newDistance = 0;
	
	var curCar = this.objects.getVehicle(curCarState.id_abitante, curCarState.id_quartiere_abitante, curCarState.length_abitante, curCarState.is_a_bus);
	if(!curCar)
	{
		console.log("New car!");
		curCar = this.objects.addVehicle(curCarState.id_abitante, curCarState.id_quartiere_abitante, curCarState.length_abitante, curCarState.is_a_bus);
		curCar.prevState = curCarState;
	}
	try {
		var toUse = this.computeNewDistanceAndState(curCar.prevState, curCarState);
		s = toUse.state;
		newDistance = toUse.distance;
		var newPos = null;
		switch (s.where) {
		case 'strada':
			newPos = this.map.streets[s.id_where].getPositionAt(newDistance, s.polo);
			curCar.show();
			break;
		case 'strada_ingresso':
			curCar.hide();
			break;
		case 'traiettoria_ingresso':
			curCar.hide();
			break;
		case 'incrocio':
			newPos = this.map.crossroads[s.id_where]
					.getPositionAt(newDistance, s.strada_ingresso,
							s.quartiere_strada_ingresso,
							s.direzione);
			curCar.show();
			break;
		case 'cambio_corsia':
			var newPos = this.map.streets[s.id_where]
					.getPositionAtOvertaking(newDistance, s.polo, s.distanza_inizio);

			curCar.show();
			break;
		}
		if(newPos != null){
			curCar.move(newPos.position, newPos.angle);
			if(typeof this.onObjectMoved === 'function')
			{
				this.onObjectMoved(curCar, s, newDistance, newPos);
			}
		}
	} catch (e) {
		console.log("MOVE CAR > Got exception =====");
		console.log("MAP: "+this.map.id);
		console.log(this.map);
		console.log("New distance: "+newDistance);
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

PieceSimulation.prototype.moveObjects = function(time) {
	this.currentState.stateTime += time;
	var len = this.currentState.abitanti.length;
	for (var c = 0; c < len; c++) {
		var s = this.currentState.abitanti[c];
		this.moveCar(time, s);
	}
}


PieceSimulation.prototype.updateState2 = function(deltaTime) {
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
				if (typeof this.onEmptyCache === 'function') {
					console.log("calling callback");
					this.onEmptyCache(this.map.id);
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

PieceSimulation.prototype.updateState = function(deltaTime) {
	if (deltaTime != 0 && this.currentState != null) {
		var id = this.map.id;
		this.simulationTime += deltaTime;

		var remainingTime = 0;

		// controllo se il delta copre più di uno stato
		if ((this.currentState.stateTime + deltaTime) > this.statesDuration) {
			// calcoliamo l'eccesso di tempo
			remainingTime = deltaTime
					- (this.statesDuration - this.currentState.stateTime);

			// calcoliamo il numero di stati che questo eccesso copre
			// aggiungiamo 1 perché abbiamo già superato il tempo dello stato
			// corrente quindi passiamo al prossimo
			var numStatesSkip = (remainingTime/this.statesDuration>>0) + 1;

			for(var i = 0; i < numStatesSkip; i++){
				this.prevState = this.currentState;
				this.initPrevState(this.currentState);
				this.currentState = this.stateCache.shift();
				if(typeof this.onStateConsumed === 'function'){
					this.onStateConsumed(this.map.id, this.stateCache.length);
				}
				if (this.currentState === undefined) {
					if (typeof this.onEmptyCache === 'function') {
						console.log("calling callback");
						this.onEmptyCache(this.map.id);
					}
					console.log("no more states");
					this.ranOutOfStates = true;
					this.running = false;
					this.receivedStates = 0;
				} else {
					this.currentState.stateTime = 0;
				}
			}
			deltaTime = remainingTime - this.statesDuration*(numStatesSkip - 1);
		}

		if(this.running)
			this.moveObjects(deltaTime);
	}
}

PieceSimulation.prototype.fastForward = function() {
	console.log("Called fastForward");
	if (this.running && this.stateCache.length >= this.requiredStates) {
		var tmpArr = this.stateCache.slice(this.stateCache.length
				- this.requiredStates);
		this.stateCache = tmpArr;
		this.init();
	}
}

PieceSimulation.prototype.stop = function(){
	this.running = false;
	if(typeof this.onSimulationStopped === 'function')
		this.onSimulationStopped(this.map.id);
}