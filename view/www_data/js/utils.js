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
	{tipo:'strada', id_strada: 14, corsia:1, polo:true},
	{tipo:'incrocio', id_incrocio:'i6', strada_ingresso: 14, quartiere:2, direzione:'right'},
	{tipo:'strada', id_strada: 9, corsia:1, polo:true},
]

/*
 * stateDuration in ms
 *
 */

function craftStatesForCar(curState, carId, route, map, speed, stateDuration){
	var stateNum = 0;
	var l = 0;
	var n = 0;
	for(var i in route){
		switch(route[i].tipo){
			case 'strada':
				l = map.streets[route[i].id_strada].guidingPath.length;
				console.log(l);
				n = l / speed / (stateDuration/1000);
				var trunk = l/n;
				var done = 0;
				for(var c = 1; c < n; c++){
					done += trunk;
					addCarToState(curState, stateNum, carId, {id_strada: route[i].id_strada, where: 'strada', distanza: done, polo: route[i].polo, corsia: route[i].corsia});
					stateNum++;
				}
				if(done < l){
					addCarToState(curState, stateNum, carId, {id_strada: route[i].id_strada, where: 'strada', distanza: l, polo: route[i].polo, corsia: route[i].corsia});
					stateNum++;
				}
				break;
			case 'incrocio':
				l = map.crossroads[route[i].id_incrocio].getCrossingPath(route[i].strada_ingresso, route[i].quartiere, route[i].direzione).length;
				n = l / speed / (stateDuration/1000);
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
							distanza: done, 
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
							distanza: l, 
							strada_ingresso: route[i].strada_ingresso, 
							quartiere:route[i].quartiere, 
							direzione:route[i].direzione,
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