var route1 = [
	{tipo:'strada', id_strada: 2, corsia:1, polo:true},
	{tipo:'incrocio', id_incrocio:'i1', strada_ingresso: 1, quartiere:1, direzione:'straight_1'},
]

var route2 = [
	{tipo:'strada', id_strada: 9, corsia:0, polo:false},
	{tipo:'incrocio', id_incrocio:'i6', strada_ingresso: 9, quartiere:2, direzione:'left'},
	{tipo:'strada', id_strada: 14, corsia:0, polo:false},
]

var route3 = [
	{tipo:'strada', id_strada: 14, corsia:1, polo:true, inizio: 0, fine: 0},
	{tipo:'incrocio', id_incrocio:'i6', strada_ingresso: 14, quartiere:2, direzione:'right'},
	{tipo:'strada', id_strada: 9, corsia:1, polo:true},
]

var route4 = [
	//{tipo:'strada_ingresso', id_strada: 4, corsia:0, polo: false, inizio: 0, fine: 0, speed: 10},
	//{tipo:'traiettoria_ingresso', id_strada: 28, distanza_ingresso:380, polo:true, traiettoria:'uscita_ritorno_1', inizio: 0, fine: 0, speed: 7},
	//{tipo:'strada', id_strada: 28, corsia:0, polo:false, inizio: 179.6186838185971, fine: 0, speed: 30},
	//{tipo:'incrocio', id_incrocio:'i14', strada_ingresso: 28, quartiere:1, direzione:'straight_1', speed: 7},
	{tipo:'strada', id_strada: 30, corsia:0, polo:false, inizio: 0, fine: 200, speed: 30},
	{tipo:'cambio_corsia', id_strada: 30, inizio: 200, lunghezza: 20, polo: false, corsia_inizio:0, corsia_fine:1, speed: 25},
	{tipo:'strada', id_strada: 30, corsia:1, polo:false, inizio: 220, fine: 300, speed: 30},
	{tipo:'cambio_corsia', id_strada: 30, inizio: 300, lunghezza: 20, polo: false, corsia_inizio:1, corsia_fine:0, speed: 25},
	{tipo:'strada', id_strada: 30, corsia:0, polo:false, inizio: 330, fine: 416.3897231972169, speed: 30},
	{tipo:'traiettoria_ingresso', id_strada: 30, distanza_ingresso:250, polo:true, traiettoria:'entrata_ritorno', inizio: 0, fine: 0, speed: 7},
	{tipo:'strada_ingresso', id_strada: 2, corsia:0, polo:true, inizio: 0, fine: 0, speed: 10},
]

/*
 * stateDuration in ms
 *
 */

function craftStatesForCar(curState, carId, route, map, speed, stateDuration){
	var stateNum = 0;
	for(var i in route){
		var l = 0;
		var gl = 0;
		var n = 0;
		switch(route[i].tipo){
			case 'strada':
				gl = map.streets[route[i].id_strada].guidingPath.length;
				if(route[i].fine > 0){
					gl = route[i].fine;
				}
				l = gl-route[i].inizio;
				n = l / route[i].speed / (stateDuration/1000);
				var trunk = l/n;
				var done = 0;
				for(var c = 1; c < n; c++){
					done += trunk;
					addCarToState(curState, stateNum, carId, {
						id_strada: route[i].id_strada, 
						where: 'strada', 
						distanza: (done+route[i].inizio),//.toFixed(2), 
						polo: route[i].polo, 
						corsia: route[i].corsia, 
						inizio: route[i].inizio});
					stateNum++;
				}
				if(done < l){
					addCarToState(curState, stateNum, carId, {
						id_strada: route[i].id_strada, 
						where: 'strada', 
						distanza: (l+route[i].inizio),//.toFixed(2), 
						polo: route[i].polo, 
						corsia: route[i].corsia, 
						inizio: route[i].inizio});
					stateNum++;
				}
				break;
			case 'strada_ingresso':
				l = map.entranceStreets[route[i].id_strada].guidingPath.length;
				n = l / route[i].speed / (stateDuration/1000);
				var trunk = l/n;
				var done = 0;
				for(var c = 1; c < n; c++){
					done += trunk;
					addCarToState(curState, stateNum, carId, {
						id_strada: route[i].id_strada, 
						where: 'strada_ingresso', 
						distanza: done,//.toFixed(2), 
						polo: route[i].polo, 
						corsia: route[i].corsia});
					stateNum++;
				}
				if(done < l){
					addCarToState(curState, stateNum, carId, {
						id_strada: route[i].id_strada, 
						where: 'strada_ingresso', 
						distanza: l,//.toFixed(2), 
						polo: route[i].polo, 
						corsia: route[i].corsia});
					stateNum++;
				}
				break;
			case 'traiettoria_ingresso':
				l = map.streets[route[i].id_strada].sideStreets[route[i].polo][route[i].distanza_ingresso].paths[route[i].traiettoria].path.length;
				n = l / route[i].speed / (stateDuration/1000);
				var trunk = l/n;
				var done = 0;
				for(var c = 1; c < n; c++){
					done += trunk;
					addCarToState(curState, stateNum, carId, 
						{
							id_strada: route[i].id_strada, 
							where: 'traiettoria_ingresso', 
							distanza: done,//.toFixed(2), 
							lato_strada: route[i].polo, 
							polo: route[i].polo, 
							distanza_ingresso: route[i].distanza_ingresso,
							traiettoria: route[i].traiettoria
						}
						);
					stateNum++;
				}
				if(done < l){
					addCarToState(curState, stateNum, carId, 
						{
							id_strada: route[i].id_strada, 
							where: 'traiettoria_ingresso', 
							distanza: l,//.toFixed(2), 
							polo: route[i].polo, 
							distanza_ingresso: route[i].distanza_ingresso,
							traiettoria: route[i].traiettoria
						}
						);
					stateNum++;
				}
				break;
			case 'incrocio':
				l = map.crossroads[route[i].id_incrocio].getCrossingPath(route[i].strada_ingresso, route[i].quartiere, route[i].direzione).length;
				n = l / route[i].speed / (stateDuration/1000);
				var trunk = l/n;
				var done = 0;
				for(var c = 1; c < n; c++){
					done += trunk;
					addCarToState(
						curState,
						stateNum, 
						carId, 
						{
							id_incrocio: route[i].id_incrocio, 
							where: 'incrocio', 
							distanza: done,//.toFixed(2), 
							strada_ingresso: route[i].strada_ingresso, 
							quartiere:route[i].quartiere, 
							direzione:route[i].direzione,
						}
					);
					stateNum++;
				}
				if(done < l){
					addCarToState(
						curState,
						stateNum, 
						carId, 
						{
							id_incrocio: route[i].id_incrocio, 
							where: 'incrocio', 
							distanza: l,//.toFixed(2), 
							strada_ingresso: route[i].strada_ingresso, 
							quartiere:route[i].quartiere, 
							direzione:route[i].direzione,
						});
					stateNum++;
				}
				break;
			case 'cambio_corsia':
				l = map.streets[route[i].id_strada].getOvertakingPath(
					route[i].inizio, 
					route[i].polo, 
					route[i].corsia_inizio, 
					route[i].corsia_fine, 
					route[i].lunghezza).length;

				n = l / route[i].speed / (stateDuration/1000);
				var trunk = l/n;
				var done = 0;
				for(var c = 1; c < n; c++){
					done += trunk;
					addCarToState(curState, stateNum, carId, {
						id_strada: route[i].id_strada, 
						where: 'cambio_corsia', 
						distanza: done,//.toFixed(2), 
						distanza_inizio: route[i].inizio,
						polo: route[i].polo, 
						corsia_inizio: route[i].corsia_inizio, 
						corsia_fine: route[i].corsia_fine,
					});
					stateNum++;
				}
				if(done < l){
					addCarToState(curState, stateNum, carId, {
						id_strada: route[i].id_strada, 
						where: 'cambio_corsia', 
						distanza: l,//.toFixed(2), 
						distanza_inizio: route[i].inizio,
						polo: route[i].polo, 
						corsia_inizio: route[i].corsia_inizio, 
						corsia_fine:route[i].corsia_fine,
					});
					stateNum++;
				}
				break;
		}
	}
}

function addCarToState(state, n, carId, obj){
	if(state[n] == null){
		state[n] = {num: n, cars:{}};
	}
	state[n].cars[carId] = obj;
}