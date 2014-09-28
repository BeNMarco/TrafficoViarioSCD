/**
*	Author: Marco Negro
*	Email: negromarc@gmail.com
*	Descr: Map object to handle and render the map of the simulation
*/

function sortPoints(a,b){
	var res = a.x-b.x;
	if (res == 0){
		res = a.y -b.y;
	}
	return res;
}

function sortCrossroadsStreets(a,b){
	return sortPoints(a.point, b.point);
}

function pathOffset(path, offset, precision, style, start, end){
	/*
	  path: path object to be offset
	  offset: length of offset
	  precision: the amount of precision (the higher the more precise)
	*/
	start = typeof start !== 'undefined' ? start : 0;
	end = typeof end !== 'undefined' ? end : path.length;
	var len = end - start;
	if (end < path.length){
		len +=1;
	}
	//len = path.length;
	var copy = new Path();
	if(typeof style !== 'undefined'){
		copy.strokeColor = style.strokeColor;
		copy.strokeWidth = style.strokeWidth;
		copy.dashArray = style.dashArray;
	} else {
		copy.strokeColor = path.strokeColor;
		copy.strokeWidth = path.strokeWidth;
		copy.dashArray = path.dashArray;
	}
	//recommended precision: Math.ceil(path.length)
	for (var i = 0; i < precision + 1; i++) {
		var pos = i / precision * len;
		var point = path.getPointAt(pos+start);
		var normal = path.getNormalAt(pos+start);
		normal.length = offset;
		copy.add(point.add(normal));
	}
	//copy.simplify();
	return copy;
}

/**
 *
 *	MapStyle class
 *
**/

function MapStyle(){
	this.lineColor = 'white';
	this.laneColor = 'grey';
	this.lineWidth = 0.3;
	this.laneWidth = 7;
	this.pavementColor = 'grey';
	this.pavementWidth = 3;
	this.dashArray = [6,4];
	this.zebraDash = [2,2];
}

/**
 *
 *	Street class
 *
**/

function Street(obj){
	this.id = obj.id;
	this.len = obj.lunghezza;
	this.nLanes = obj.numcorsie;
	this.from = obj.from;
	this.to = obj.to;
	this.guidingPath = new Path();
	this.guidingPath.add(new Point(obj.from[0],obj.from[1]));
	//this.guidingPath.add(new Point((obj.from[0]+obj.to[0])/2, (obj.from[1]+obj.to[1])/2));
	this.guidingPath.add(new Point(obj.to[0],obj.to[1]));
	this.sepLines = {true:[],false:[]};
	this.guidingPath.smooth();
	this.path = null;
	this.name = obj.nome ? obj.nome : "";
	this.type = 'standard';
	this.sideStreets = {true:{},false:{}};
	this.sideStreetsEntrancePaths = {};
}

Street.prototype.reposition = function(){
	this.guidingPath = new Path();
	this.guidingPath.add(new Point(this.from[0],this.from[1]));
	this.guidingPath.add(new Point(this.to[0],this.to[1]));
	this.guidingPath.smooth();
}

Street.prototype.setType = function(newType){
	this.type = newType;
}

Street.prototype.draw = function(style){
	this.laneWidth = style.laneWidth;
	this.pavementWidth = style.pavementWidth;
	this.path = new Path(this.guidingPath.pathData);
	this.path.strokeColor = style.laneColor;
	this.path.strokeWidth = style.laneWidth*this.nLanes*2+style.pavementWidth*2;
	this.guidingPath.strokeColor = style.lineColor;
	this.guidingPath.strokeWidth = style.lineWidth;
	this.guidingPath.moveAbove(this.path);
	//this.guidingPath.fullySelected = true;

	// drawing the separation lines
	var precision = Math.ceil(this.guidingPath.length);
	var sepStyle = {strokeWidth: style.lineWidth, strokeColor:style.lineColor, dashArray: style.dashArray};
	for(var i = 1; i < this.nLanes; i++){
		this.sepLines[false][i] = pathOffset(this.guidingPath, (i)*style.laneWidth, precision, sepStyle);
		//p1.rasterize();
		//p1.remove();
		this.sepLines[true][i] = pathOffset(this.guidingPath, -(i)*style.laneWidth, precision, sepStyle);
		//p2.rasterize();
		//p2.remove();
	}

	// drawing the pedestrian lines
	var pedestrianPaths = {true: [], false: []};
	var middlePaths = {true: [], false: []};

	for(side in this.sideStreets){
		pedestrianPaths[side][0] = {start:0, end:this.guidingPath.length, type:'pavement'};
		middlePaths[side][0] = {start:0, end:this.guidingPath.length, type:'continuous'};
		var prev = 0;
		for(index in this.sideStreets[side]){
			var curStr = this.sideStreets[side][index];
			var crossStart = curStr.entranceDistance - curStr.nLanes*style.laneWidth;
			var crossEnd = curStr.entranceDistance + curStr.nLanes*style.laneWidth;
			pedestrianPaths[side][prev].end = crossStart;
			middlePaths[side][prev].end = crossStart;
			prev++;
			pedestrianPaths[side][prev] = {start: crossStart, end:crossEnd, type:'zebra'};
			middlePaths[side][prev] = {start: crossStart, end:crossEnd, type:'dashed'};
			prev++;
			pedestrianPaths[side][prev] = {start: crossEnd, end:this.guidingPath.length, type:'pavement'};
			middlePaths[side][prev] = {start: crossEnd, end:this.guidingPath.length, type:'continuous'};
			this.sideStreets[side][index].paths = this.prepareSidestreetsAccessPaths(style, curStr, crossStart, crossEnd, side);
		}	
	}
	
	this.drawPedestrianLines(pedestrianPaths, style, precision);

	if(this.id != ""){
		var signPath = pathOffset(this.guidingPath, this.nLanes+style.laneWidth + 4*style.pavementWidth, precision, {strokeWidth:0, strokColo:'black', dashArray: null});
		var startPoint = signPath.getPointAt(signPath.length/3);
		var text = new PointText(startPoint);
		text.content = this.id;
	}
	this.path.sendToBack();
}

Street.prototype.prepareSidestreetsAccessPaths = function(style, curStr, crossStart, crossEnd, side){
	var enterignPath1 = new Path();
	var exitingPath1 = new Path();
	var enterignPath2 = new Path();
	var exitingPath2_1 = new Path();
	var exitingPath2_2 = new Path();
	var enterHandlePoint = null;
	var exitHandlePoint = null;
	var sideStreetsEntrancePaths = {};
	side = side == 'true' ? true : false;
	if(side){
		enterignPath1.add(this.getPositionAt(crossStart, side, 1, false).position);
		enterignPath1.add(this.getSidestreetPositionAt(crossStart+0.5*style.laneWidth, side).position);
		exitingPath1.add(this.getSidestreetPositionAt(crossEnd-0.5*style.laneWidth, side).position);
		exitingPath1.add(this.getPositionAt(crossEnd, side, 1, false).position);

		enterignPath2.add(this.getPositionAt(crossEnd, !side, 0, false).position);
		enterignPath2.add(this.getSidestreetPositionAt(crossStart+0.5*style.laneWidth, side).position);
		exitingPath2_1.add(this.getSidestreetPositionAt(crossEnd-0.5*style.laneWidth, side).position);
		exitingPath2_1.add(this.getPositionAt(crossStart, !side, 0, false).position);
		exitingPath2_2.add(this.getSidestreetPositionAt(crossEnd-0.5*style.laneWidth, side).position);
		exitingPath2_2.add(this.getPositionAt(crossStart, !side, 1, false).position);

		enterHandlePoint1 = this.getPositionAt(crossStart+0.5*style.laneWidth, side, 1, false).position;
		exitHandlePoint1 = this.getPositionAt(crossEnd-0.5*style.laneWidth, side, 1, false).position;	

		enterHandlePoint2 = this.getPositionAt(crossStart+0.5*style.laneWidth, !side, 0, false).position;
		exitHandlePoint2_1 = this.getPositionAt(crossEnd-0.5*style.laneWidth, !side, 0, false).position;	
		exitHandlePoint2_2 = this.getPositionAt(crossEnd-0.5*style.laneWidth, !side, 1, false).position;				
	} else {
		exitingPath1.add(this.getSidestreetPositionAt(crossStart+0.5*style.laneWidth, side).position);
		exitingPath1.add(this.getPositionAt(crossStart, side, 1, false).position);
		enterignPath1.add(this.getPositionAt(crossEnd, side, 1, false).position);
		enterignPath1.add(this.getSidestreetPositionAt(crossEnd-0.5*style.laneWidth, side).position);

		exitingPath2_1.add(this.getSidestreetPositionAt(crossStart+0.5*style.laneWidth, side).position);
		exitingPath2_1.add(this.getPositionAt(crossEnd, !side, 0, false).position);
		exitingPath2_2.add(this.getSidestreetPositionAt(crossStart+0.5*style.laneWidth, side).position);
		exitingPath2_2.add(this.getPositionAt(crossEnd, !side, 1, false).position);
		enterignPath2.add(this.getPositionAt(crossStart, !side, 0, false).position);
		enterignPath2.add(this.getSidestreetPositionAt(crossEnd-0.5*style.laneWidth, side).position);

		enterHandlePoint1 = this.getPositionAt(crossEnd-0.5*style.laneWidth, side, 1, false).position;
		exitHandlePoint1 = this.getPositionAt(crossStart+0.5*style.laneWidth, side, 1, false).position;

		enterHandlePoint2 = this.getPositionAt(crossEnd-0.5*style.laneWidth, !side, 0, false).position;
		exitHandlePoint2_1 = this.getPositionAt(crossStart+0.5*style.laneWidth, !side, 0, false).position;	
		exitHandlePoint2_2 = this.getPositionAt(crossStart+0.5*style.laneWidth, !side, 1, false).position;		
	}

	enterignPath1.firstSegment.handleOut = enterHandlePoint1.subtract(enterignPath1.firstSegment.point);
	enterignPath1.firstSegment.handleOut.length = 0.8*enterignPath1.firstSegment.handleOut.length;
	enterignPath1.lastSegment.handleIn = enterHandlePoint1.subtract(enterignPath1.lastSegment.point);
	enterignPath1.lastSegment.handleIn.length = 0.5*enterignPath1.lastSegment.handleIn.length;
	enterignPath1.smooth();
	//this.sideStreetsEntrancePaths["M"+this.id+"-S"+curStr.id] = {id:"M"+this.id+"-S"+curStr.id, principale: this.id, laterale:curStr.id, verso:'entrata', path:enterignPath1, polo:true};
	sideStreetsEntrancePaths["entrata_andata"] = {id:"M"+this.id+"_go-S"+curStr.id+"_in", principale: this.id, laterale:curStr.id, verso:'entrata', path:enterignPath1, polo:true};

	exitingPath1.firstSegment.handleOut = exitHandlePoint1.subtract(exitingPath1.firstSegment.point);
	exitingPath1.firstSegment.handleOut.length = 0.5*exitingPath1.firstSegment.handleOut.length;
	exitingPath1.lastSegment.handleIn = exitHandlePoint1.subtract(exitingPath1.lastSegment.point);
	exitingPath1.lastSegment.handleIn.length = 0.8*exitingPath1.lastSegment.handleIn.length;
	exitingPath1.smooth();
	//this.sideStreetsEntrancePaths["S"+curStr.id+"-M"+this.id] = {id:"S"+curStr.id+"-M"+this.id, principale: this.id, laterale:curStr.id, verso:'uscita', path:exitingPath1, polo:true};;
	sideStreetsEntrancePaths["uscita_andata"] = {id:"M"+this.id+"_go-S"+curStr.id+"_out", principale: this.id, laterale:curStr.id, verso:'uscita', path:enterignPath1, polo:true};

	enterignPath2.firstSegment.handleOut = enterHandlePoint2.subtract(enterignPath2.firstSegment.point);
	enterignPath2.firstSegment.handleOut.length = 0.8*enterignPath2.firstSegment.handleOut.length;
	enterignPath2.lastSegment.handleIn = enterHandlePoint2.subtract(enterignPath2.lastSegment.point);
	enterignPath2.lastSegment.handleIn.length = 0.5*enterignPath2.lastSegment.handleIn.length;
	enterignPath2.smooth();
	//this.sideStreetsEntrancePaths["M"+this.id+"-S"+curStr.id] = {id:"M"+this.id+"-S"+curStr.id, principale: this.id, laterale:curStr.id, verso:'entrata', path:enterignPath2, polo:true};
	sideStreetsEntrancePaths["entrata_ritorno"] = {id:"M"+this.id+"_come-S"+curStr.id+"_in", principale: this.id, laterale:curStr.id, verso:'entrata', path:enterignPath2, polo:true};

	exitingPath2_1.firstSegment.handleOut = exitHandlePoint2_1.subtract(exitingPath2_1.firstSegment.point);
	exitingPath2_1.firstSegment.handleOut.length = 0.5*exitingPath2_1.firstSegment.handleOut.length;
	exitingPath2_1.lastSegment.handleIn = exitHandlePoint2_1.subtract(exitingPath2_1.lastSegment.point);
	exitingPath2_1.lastSegment.handleIn.length = 0.8*exitingPath2_1.lastSegment.handleIn.length;
	exitingPath2_1.smooth();
	//this.sideStreetsEntrancePaths["S"+curStr.id+"-M"+this.id] = {id:"S"+curStr.id+"-M"+this.id, principale: this.id, laterale:curStr.id, verso:'uscita', path:exitingPath1, polo:true};;
	sideStreetsEntrancePaths["uscita_ritorno_1"] = {id:"M"+this.id+"_come-S"+curStr.id+"_out_1", principale: this.id, laterale:curStr.id, verso:'uscita', path:exitingPath2_1, polo:true};

	exitingPath2_2.firstSegment.handleOut = exitHandlePoint2_2.subtract(exitingPath2_2.firstSegment.point);
	exitingPath2_2.firstSegment.handleOut.length = 0.5*exitingPath2_2.firstSegment.handleOut.length;
	exitingPath2_2.lastSegment.handleIn = exitHandlePoint2_2.subtract(exitingPath2_2.lastSegment.point);
	exitingPath2_2.lastSegment.handleIn.length = 0.8*exitingPath2_2.lastSegment.handleIn.length;
	exitingPath2_2.smooth();
	//this.sideStreetsEntrancePaths["S"+curStr.id+"-M"+this.id] = {id:"S"+curStr.id+"-M"+this.id, principale: this.id, laterale:curStr.id, verso:'uscita', path:exitingPath1, polo:true};;
	sideStreetsEntrancePaths["uscita_ritorno_2"] = {id:"M"+this.id+"_come-S"+curStr.id+"_out_2", principale: this.id, laterale:curStr.id, verso:'uscita', path:exitingPath2_2, polo:true};

	if(style.debug){
		exitingPath1.fullySelected = true;
		enterignPath1.fullySelected = true;
		exitingPath2_1.fullySelected = true;
		exitingPath2_2.fullySelected = true;
		enterignPath2.fullySelected = true;
		var c1 = new Path.Circle(exitingPath1.getPointAt(1), 0.5);
		c1.fillColor = 'blue';
		var c2 = new Path.Circle(enterignPath1.getPointAt(1), 0.5);
		c2.fillColor = 'red';
		var c3 = new Path.Circle(exitingPath2_1.getPointAt(1), 0.5);
		c3.fillColor = 'blue';
		var c4 = new Path.Circle(enterignPath2.getPointAt(1), 0.5);
		c4.fillColor = 'red';
	}
	return sideStreetsEntrancePaths;
}

Street.prototype.drawPedestrianLines = function(pedPath, style, precision){
	//console.log(pedPath);
	var st = {
		pavement: {
			strokeWidth: style.lineWidth,
			strokeColor: style.lineColor,
			dashArray: null,
		},
		zebra: {
			strokeWidth: style.pavementWidth,
			strokeColor: style.lineColor,
			dashArray: style.zebraDash,
		}
	}
	for(side in pedPath){
		for(seg in pedPath[side]){
			var offset = (this.nLanes*style.laneWidth + (pedPath[side][seg].type == 'zebra' ? 0.5 : 0) * style.pavementWidth)*(side == 'true' ? -1 : 1);
			var p = pathOffset(this.guidingPath, offset, precision, st[pedPath[side][seg].type],pedPath[side][seg].start, pedPath[side][seg].end);
			//p.rasterize();
			//p.remove();
		}
	}
}

/*
Street.prototype.mergeMiddlePaths = function(middlePaths){
	var middlePath = [];
	for (var i = 0; i < middlePaths[true].length; i++){

	}
}
*/

Street.prototype.drawMiddleLine = function(middlePath, style, precision){
	//console.log(pedPath);
	var st = {
		continuous: {
			strokeWidth: style.lineWidth,
			strokeColor: style.lineColor,
			dashArray: null,
		},
		dashed: {
			strokeWidth: style.lineWidth,
			strokeColor: style.lineColor,
			dashArray: style.zebraDash,
		}
	}
	for(seg in middlePath){
		pathOffset(this.guidingPath, 0, precision, st[middlePath[seg].type],middlePath[seg].start, middlePath[seg].end);
	}
}

Street.prototype.adjustCrossroadLink = function(newPoint, edge, centerPoint){
	if(edge){
		this.guidingPath.firstSegment.point.x = newPoint.x;
		this.guidingPath.firstSegment.point.y = newPoint.y;
		this.guidingPath.firstSegment.handleOut = newPoint.subtract(centerPoint);
		this.guidingPath.firstSegment.handleOut.length = (this.guidingPath.segments[1].point.subtract(this.guidingPath.segments[0].point)).length/2;
	} else {
		this.guidingPath.lastSegment.point.x = newPoint.x;
		this.guidingPath.lastSegment.point.y = newPoint.y;
		this.guidingPath.lastSegment.handleIn = newPoint.subtract(centerPoint);
		var len = this.guidingPath.segments.length;
		this.guidingPath.lastSegment.handleIn.length = (this.guidingPath.segments[len-2].point.subtract(this.guidingPath.segments[len-1].point)).length/2;
	}
}

Street.prototype.addSideStreet = function(sideStreet){
	this.sideStreets[sideStreet.entranceSide][sideStreet.entranceDistance] = sideStreet;
}

Street.prototype.getPositionAt = function(distance, side, lane, drive){
	//console.log(distance+"/"+this.guidingPath.length);
	drive = typeof drive === 'undefined' ? true : false;
	if (typeof side === 'string'){
		side = (side === 'true');
	}
	if(drive && side){
		distance = this.guidingPath.length - distance;
	}
	var loc = this.guidingPath.getLocationAt(distance);

	var offset = lane < 0 ? this.nLanes*this.laneWidth + 0.5*this.pavementWidth : (lane+0.5)*this.laneWidth;
	offset = side ? -offset : offset;

	var normal = this.guidingPath.getNormalAt(distance);
	try{
		normal.length = offset;
	} catch(err){
		console.log(distance+"/"+this.guidingPath.length);
		console.log(normal);
	}

	return {angle: loc.tangent.angle, position: new Point(loc.point.x+normal.x, loc.point.y+normal.y)};
}

Street.prototype.getPositionAtEntranceCrossing = function(distance, crossingPath){
	var loc = this.sideStreetsEntrancePaths[crossingPaths].getLocationAt(distance);

	return {angle:loc.tangent.angle, position: loc.point};
}

Street.prototype.getSidestreetPositionAt = function(distance, side){
	if (typeof side === 'string'){
		side = (side === 'true');
	}
	var loc = this.guidingPath.getLocationAt(distance);

	var offset = this.nLanes*this.laneWidth + this.pavementWidth;
	offset = side ? -offset : offset;

	var normal = this.guidingPath.getNormalAt(distance);
	normal.length = offset;

	return {angle: loc.tangent.angle-90, position: new Point(loc.point.x+normal.x, loc.point.y+normal.y)};
}

Street.prototype.getOvertakingPath = function(startPosition, side, fromLane, toLane, moveLength){
	var p1 = this.getPositionAt(startPosition, side, fromLane).position;
	var hp1 = this.getPositionAt(startPosition+0.5*moveLength, side, fromLane).position;
	var p2 = this.getPositionAt(startPosition+moveLength, side, toLane).position;
	var hp2 = this.getPositionAt(startPosition+0.5*moveLength, side, toLane).position;
	var p = new Path(p1, p2);
	p.firstSegment.handleOut = hp1.subtract(p1);
	p.firstSegment.handleOut.length = 0.5*moveLength;
	p.lastSegment.handleIn = hp2.subtract(p2);
	p.lastSegment.handleIn.length =  0.5*moveLength;
	return p;
}



/**
 *
 *	Crossroad class
 *
**/

function Crossroad(obj){
	this.id = obj.id;
	this.streetsRef = obj.strade.slice();
	this.streetsMap = {};
	this.lanesNumber = [2,2];
	this.streets = [];
	this.center = null;
	this.angle = obj.angolo ? obj.angolo : 0;
	this.pedestrian = null;
	this.firstEntrance = 1;
	this.group = new Group();
	this.trafficLights = {};
	this.pedestrianPaths = {};
	this.crossingPaths = {};
	if("strada_mancante" in obj){
		this.streetsRef.splice(obj.strada_mancante,0,null);
	}
}

/**
*	Links the streets to the crossroad
* 	
**/
Crossroad.prototype.linkStreets = function(streets, district){
	var firstIn = null;
	var polo = true;
	var entr = 0;
	for (var i = 0; i < this.streetsRef.length; i ++) {
		entr++;
		if (this.streetsRef[i] != null){
			var tmpStreet = null;
			if (this.streetsRef[i].quartiere == district){
				tmpStreet = streets[this.streetsRef[i].id_strada];
			}
			this.streets[i] = tmpStreet;

			if(firstIn == null && tmpStreet != null){
				this.firstEntrance = entr;
				firstIn = tmpStreet;
				polo = this.streetsRef[i].polo;	
			}

			// getting the number of lanes per direction
			/*
			if (tmpStreet != null && tmpStreet.nLanes > this.lanesNumber[i%2]){
				this.lanesNumber[i%2] = tmpStreet.nLanes;
			}
			*/

		} else {
			this.streets[i] = null;
		}
	}
	
	// calculating the center and rotation of the crossroad
	if(polo){
		this.center = new Point(firstIn.from[0],firstIn.from[1]);
		//tmpHandle = firstIn.guidingPath.firstSegment.handleOut;
		//this.angle = (firstIn.guidingPath.segments[1].point.subtract(firstIn.guidingPath.segments[0].point)).angle;
	} else {
		this.center = new Point(firstIn.to[0],firstIn.to[1]);
		//tmpHandle = firstIn.guidingPath.lastSegment.handleIn;
		//var len = firstIn.guidingPath.segments.length;
		//this.angle = (firstIn.guidingPath.segments[len-1].point.subtract(firstIn.guidingPath.segments[len-2].point)).angle;
	}
}

Crossroad.prototype.draw = function(style){
	delete this.group;
	this.group = new Group();
	var totalWidth = this.lanesNumber[0]*style.laneWidth+style.pavementWidth;
	var totalHeight = this.lanesNumber[1]*style.laneWidth+style.pavementWidth;
	var startP = new Point(this.center.x-totalWidth, this.center.y-totalHeight);

	if(style.debug){
		this.label = new PointText(this.center);
		this.label.content = this.id;
	}
	var path = new Path.Rectangle(startP, new Size(totalWidth*2, totalHeight*2));
	path.fillColor = style.laneColor;
	
	this.group.addChild(path);

	var poleMap = {true: 'firstSegment', false: 'lastSegment'};

	for (var i = 0; i < this.streetsRef.length; i++) {
		var st = {color: style.lineColor, width: style.pavementWidth, dash: style.zebraDash};
		var ped = style.pavementWidth/2;

		// creating the pedestrian paths to move the peolple
		var pP = new Path();
		pP.add(new Point(
			(path.position.x-this.lanesNumber[i%2]*style.laneWidth-0.5*style.pavementWidth),
			(path.position.y-this.lanesNumber[(i+1)%2]*style.laneWidth-ped)
			));
		pP.add(new Point(
			(path.position.x+this.lanesNumber[i%2]*style.laneWidth+0.5*style.pavementWidth),
			(path.position.y-this.lanesNumber[(i+1)%2]*style.laneWidth-ped)
			));
		this.pedestrianPaths[i] = pP;

		var g = new Group();

		this.crossingPaths[i] = {};	

		if(this.streetsRef[i] == null){
			// if there is no street we draw the pavement

			ped = 0;
			st.dash = [];
			st.width = style.lineWidth;
			this.crossingPaths[i] = null;
		} else {
			// otherwise we draw the zebra crossing (it is the defaul so no need to customize the style)
			// but we draw the traffic lights and the cross trajectors

			// paths that leads to the other side of the crossroad
			var debgArr = []
			// creating the path that turns left
			if(this.streetsRef[(i+1)%4] != null){
				var crossPath = new Path();
				crossPath.add(new Point(this.center.x-style.laneWidth*0.5, this.center.y-(style.laneWidth*2+style.pavementWidth)));
				crossPath.add(new Point(this.center.x+(style.laneWidth*2+style.pavementWidth), this.center.y+style.laneWidth*0.5));
				var handlePoint = new Point(this.center.x-style.laneWidth*0.5, this.center.y+style.laneWidth*0.5);
				crossPath.firstSegment.handleOut = handlePoint.subtract(crossPath.firstSegment.point);
				crossPath.firstSegment.handleOut.length = crossPath.firstSegment.handleOut.length*0.60;
				crossPath.lastSegment.handleIn = handlePoint.subtract(crossPath.lastSegment.point);
				crossPath.lastSegment.handleIn.length = crossPath.lastSegment.handleIn.length*0.60;
				this.crossingPaths[i]['left'] = {
					path:crossPath, 
					id:this.id+"_s"+this.streetsRef[i].id_strada+".l"+2+"-"+"s"+this.streetsRef[(i+1)%4].id_strada+".l"+2,
					start: {street:this.streetsRef[i].id_strada, lane: 2, index: i},
					end: {street:this.streetsRef[(i+1)%4].id_strada, lane: 2, index: (i+1)%4},
				};
				//this.crossingPaths[this.id+"_s"+this.streetsRef[i].id_strada+".l"+2+"-"+"s"+this.streetsRef[(i+1)%4].id_strada+".l"+2] = crossPath;
				g.addChild(crossPath);

				debgArr.push(crossPath);
			}
			// creating the paths that goes straight through the crossroad
			if(this.streetsRef[(i+2)%4] != null){
				var crossPath1 = new Path();
				crossPath1.add(new Point(this.center.x-style.laneWidth*0.5, this.center.y-(style.laneWidth*2+style.pavementWidth)));
				crossPath1.add(new Point(this.center.x-style.laneWidth*0.5, this.center.y+(style.laneWidth*2+style.pavementWidth)));
				this.crossingPaths[i]['straight_1']={
					path: crossPath1, 
					id: this.id+"_s"+this.streetsRef[i].id_strada+".l"+1+"-"+"s"+this.streetsRef[(i+2)%4].id_strada+".l"+1,
					start: {street: this.streetsRef[i].id_strada, lane: 1, index: i},
					end: {street: this.streetsRef[(i+2)%4].id_strada, lane: 1, index: (i+2)%4},
				};
				//this.crossingPaths[this.id+"_s"+this.streetsRef[i].id_strada+".l"+1+"-"+"s"+this.streetsRef[(i+2)%4].id_strada+".l"+1] = crossPath1;
				var crossPath2 = new Path();
				crossPath2.add(new Point(this.center.x-style.laneWidth*1.5, this.center.y-(style.laneWidth*2+style.pavementWidth)));
				crossPath2.add(new Point(this.center.x-style.laneWidth*1.5, this.center.y+(style.laneWidth*2+style.pavementWidth)));
				this.crossingPaths[i]['straight_2']={
					path: crossPath2, 
					id: this.id+"_s"+this.streetsRef[i].id_strada+".l"+2+"-"+"s"+this.streetsRef[(i+2)%4].id_strada+".l"+2,
					start: {street: this.streetsRef[i].id_strada, lane: 2, index: i},
					end: {street: this.streetsRef[(i+2)%4].id_strada, lane: 2, index: (i+2)%4},
				};
				//this.crossingPaths[this.id+"_s"+this.streetsRef[i].id_strada+".l"+2+"-"+"s"+this.streetsRef[(i+2)%4].id_strada+".l"+2] = crossPath2;
				g.addChild(crossPath1);
				g.addChild(crossPath2);

				debgArr.push(crossPath1);
				debgArr.push(crossPath2);
				/*
				if(style.debug){
					var check1 = new Path.Circle(crossPath1.getPointAt(1), 1);
					check1.fillColor = 'blue';
					var check2 = new Path.Circle(crossPath2.getPointAt(1), 1);
					check2.fillColor = 'blue';
					g.addChild(check1);
					g.addChild(check2);
				}*/
			}
			// creating the path that turns right
			if(this.streetsRef[(i+3)%4] != null){
				var crossPath = new Path();
				crossPath.add(new Point(this.center.x-style.laneWidth*1.5, this.center.y-(style.laneWidth*2+style.pavementWidth)));
				crossPath.add(new Point(this.center.x-(style.laneWidth*2+style.pavementWidth), this.center.y-style.laneWidth*1.5));
				var handlePoint = new Point(this.center.x-style.laneWidth*1.5, this.center.y-style.laneWidth*1.5);
				crossPath.firstSegment.handleOut = handlePoint.subtract(crossPath.firstSegment.point);
				crossPath.lastSegment.handleIn = handlePoint.subtract(crossPath.lastSegment.point);
				this.crossingPaths[i]['right'] = {
					path: crossPath,
					id:this.id+"_s"+this.streetsRef[i].id_strada+".l"+1+"-"+"s"+this.streetsRef[(i+3)%4].id_strada+".l"+1,
					start: {street: this.streetsRef[i].id_strada, lane: 1, index: i},
					end: {street: this.streetsRef[(i+3)%4].id_strada, lane: 1, index: (i+3)%4},
				};
				//this.crossingPaths[this.id+"_s"+this.streetsRef[i].id_strada+".l"+1+"-"+"s"+this.streetsRef[(i+3)%4].id_strada+".l"+1] = crossPath;
				g.addChild(crossPath);

				debgArr.push(crossPath);
			}
			if(style.debug){
				for(var dI in debgArr){
					debgArr[dI].fullySelected = true;
					//debgArr[dI].strokeColor = 'green';
					//debgArr[dI].strokeWidth = 0.2;
				}
			}

			//if(this.streets[i] != null){
				for(var a = 0; a < this.lanesNumber[i%2]; a++){
					var tc = new Point(
							(path.position.x+(-this.lanesNumber[i%2]+0.5+(a%4))*style.laneWidth),
							(path.position.y-(this.lanesNumber[(i+1)%2]+1)*style.laneWidth)
							);
					var t = new TrafficLight(
						(((i%2) == 0) ? true : false),
						tc,
						style,
						2000
					);
					this.trafficLights[this.streetsRef[i].id+"s"+i+"l"+(a)] = t;
					g.addChild(t.path);
				}
			//}
		}

		var p = new Path();
		p.add(new Point(
			(path.position.x-this.lanesNumber[i%2]*style.laneWidth),
			(path.position.y-this.lanesNumber[(i+1)%2]*style.laneWidth-ped)
			));
		p.add(new Point(
			(path.position.x+this.lanesNumber[i%2]*style.laneWidth),
			(path.position.y-this.lanesNumber[(i+1)%2]*style.laneWidth-ped)
			));

		p.strokeColor = st.color;
		p.strokeWidth = st.width;
		p.dashArray = st.dash;
		g.addChild(p);
		g.rotate(90*(i%4),path.position);
		pP.rotate(90*(i%4),path.position);
		this.group.addChild(g);
	}
	this.group.rotate(this.angle%90); 

	// adjusting the streets
	for (var i = 0; i < this.streets.length; i++) {
		if(this.streets[i]!= null){
			var newPoint = new Point(
				(path.segments[(i+1)%4].point.x + path.segments[(i+2)%4].point.x)/2,
				(path.segments[(i+1)%4].point.y + path.segments[(i+2)%4].point.y)/2
				);
			this.streets[i].adjustCrossroadLink(newPoint, this.streetsRef[i].polo, this.center);
		}
	}
}

Crossroad.prototype.getEntranceStreetNumber = function(streetId, district){
	//console.log("asking to crossroad "+this.id+" street "+streetId+" form district "+district);
	for (var i = 0; i < this.streetsRef.length; i ++){
		if(this.streetsRef[i] != null && streetId == this.streetsRef[i].id_strada && district == this.streetsRef[i].quartiere){
			return i;
		}
	}
	return null;
}

Crossroad.prototype.getCrossingPath = function(enteringStreet, streetDistrict, direction){
	return this.crossingPaths[this.getEntranceStreetNumber(enteringStreet, streetDistrict)][direction].path;
}

Crossroad.prototype.getPositionAt = function(distance, enteringStreet, streetDistrict, direction){
	try{
		var loc = this.crossingPaths[this.getEntranceStreetNumber(enteringStreet, streetDistrict)][direction].path.getLocationAt(distance);
	}catch(err){
		throw "The crossroad "+this.id+" does not have the street "+enteringStreet+" form the district "+streetDistrict;
	}
	return {angle: loc.tangent.angle, position: loc.point};
}

Crossroad.prototype.switchTrafficLights = function(){
	for(i in this.trafficLights){
		this.trafficLights[i].switchState();
	}
}

Crossroad.prototype.bringTrafficLightsToFront = function(){
	for(i in this.trafficLights){
		this.trafficLights[i].path.bringToFront();
	}
}

function TrafficLight(state, position, style, yellowDelay){
	this.state = state ? 'green' : 'red';
	this.yellowDelay = yellowDelay;
	this.path = new Path.Circle(position, ((style.laneWidth/2)-2));
	this.path.fillColor = this.state;
	this.path.strokeColor = 'black';
	this.path.strokeWidth = style.lineWidth;
}

TrafficLight.prototype.switchState = function(){
	if(this.state == 'green'){
		this.state = 'yellow';
		this.path.fillColor = this.state;
		setTimeout(setTrafficLight, this.yellowDelay, this, 'red');
	} else {
		setTimeout(setTrafficLight, this.yellowDelay, this, 'green');
	}
}

function setTrafficLight(tl, state){
	tl.state = state;
	tl.path.fillColor = tl.state;
	//tl.path.view.draw();
}

/**
 *
 *	Place class
 *
**/
function Place(obj){
	this.entranceStreetId = obj.idstrada;
	this.id = obj.id_luogo;
	this.maxCars = obj.capienza_macchine;
	this.maxPeople = obj.capienza_persone;
	this.maxBikes = obj.capienza_bici;
	this.placeName = obj.nome;
	this.palceType = obj.tipologia;
	this.entranceStreet = null;
	this.angle = obj.angolo ? obj.angolo : 0;
	this.placeWidth = obj.dimensioni[0];
	this.placeHeight = obj.dimensioni[1];

	this._curCars = 0;
	this._curPeople = 0;
	this._curBikes = 0;

	var tmpPoint = new Point(0,0);
	this.nameLabel = new PointText(tmpPoint);;
	this.nameLabel.justification = 'center';
	this.nameLabel.visible = false
	this.carsLabel = new PointText(tmpPoint);
	this.carsLabel.visible = false;
	this.peopleLabel = new PointText(tmpPoint);
	this.peopleLabel.visible = false;
	this.bikesLabel = new PointText(tmpPoint);
	this.bikesLabel.visible = false;

	Object.defineProperty(this, "currentCars", {
		get: function() {return this._curCar;},
		set: function(v) {
			this._curCars = v; 
			this.carsLabel.content = "C: "+v+"/"+this.maxCars;
			this.carsLabel.justification = 'left';
		}
	});

	Object.defineProperty(this, "currentPeople", {
		get: function() {return this._curPeople;},
		set: function(v) {
			this._curPeople = v; 
			this.peopleLabel.content = "P: "+v+"/"+this.maxPeople;
			this.peopleLabel.justification = 'left';
		}
	});
	
	Object.defineProperty(this, "currentBikes", {
		get: function() {return this._curBikes;},
		set: function(v) {
			this._curBikes = v; 
			this.bikesLabel.content = "B: "+v+"/"+this.maxBikes;
			this.bikesLabel.justification = 'left';
		}
	});
}

Place.prototype.setEnteringStreet = function(street){
	this.entranceStreet = street;
}

Place.prototype.draw = function(style){
	var center = this.entranceStreet.guidingPath.lastSegment.point;
	var angle = (center.subtract(this.entranceStreet.guidingPath.firstSegment.point)).angle+90;

	var placePath = new Path.Rectangle(new Point(), new Size(this.placeWidth, this.placeHeight));
	placePath.strokeWidth = 1;
	placePath.strokeColor = 'grey';
	placePath.fillColor = 'white';
	placePath.position = center;
	placePath.rotate(angle);

	var startPoint = new Point(center.x, center.y-(this.placeHeight/2)-7);
	this.nameLabel.position = startPoint;
	this.nameLabel.content = this.placeName;
	this.nameLabel.visible = true;

	this.currentPeople = this._curPeople;
	startPoint.y += this.placeHeight + 7 + this.peopleLabel.bounds.height;
	this.peopleLabel.position = startPoint;
	this.peopleLabel.visible = true;

	this.currentCars = this._curCars;
	startPoint.y += this.carsLabel.bounds.height + 2;
	this.carsLabel.position = startPoint;
	this.carsLabel.visible = true;

	this.currentBikes = this._curBikes;
	startPoint.y += this.bikesLabel.bounds.height + 2;
	this.bikesLabel.position = startPoint;
	this.bikesLabel.visible = true;
}

/**
 *
 *	Map class
 *
**/
function Map(){
	this.streets = {};
	this.entranceStreets = {};
	this.crossroads = {};
	this.pavements = {};
	this.places = {};
	this.mapStyle = new MapStyle();
	this.startDrawingCallback = null;
	this.finishDrawingCallback = null;
	this.startLoadingCallback = null;
	this.finishLoadingCallback = null;
	this.loadingProgressNotifier = null;
	this.mapReadyCallback = null;
}

Map.prototype.getCrossroads = function(){
	return this.crossroads;
}

Map.prototype.onStartDrawing = function(callback){
	this.startDrawingCallback = callback;
}

Map.prototype.onFinishDrawing = function(callback){
	this.finishDrawingCallback = callback;
}

Map.prototype.onStartLoading = function(callback){
	this.startLoadingCallback = callback;
}

Map.prototype.onFinishLoading = function(callback){
	this.finishLoadingCallback = callback;
}

Map.prototype.onMapReady = function(callback){
	this.mapReadyCallback = callback;
}

Map.prototype.setStyle = function(newStyle){
	this.mapStyle = newStyle;
}

Map.prototype.setProgressNotifier = function(fun){
	this.loadingProgressNotifier = fun;
}

Map.prototype.resetData = function(){
	delete this.objData;
	this.objData = null;
	delete this.streets;
	//this.streets = null;
	this.streets = {};
	delete this.crossroads;
	//this.crossroads = null;
	this.crossroads = {};
	delete this.pavements
	//this.pavements = null;
	this.pavements = {};
	delete this.places;
	//this.places = null;
	this.places = {};
	delete this.entranceStreets;
	//this.entranceStreets = null;
	this.entranceStreets = {};
}

Map.prototype.load = function(obj){
	if(typeof this.startLoadingCallback === 'function'){
		this.startLoadingCallback();
	}
	this.resetData();
	this.objData = obj;
	this.id = obj.info.id;
	//for (var i = 0; i < obj.strade.length; i++) {

	if(typeof this.loadingProgressNotifier === 'function'){
		this.loadingProgressNotifier("Loading streets");
	}

	for(var i in obj.strade){
		this.streets[obj.strade[i].id] = new Street(obj.strade[i]);
	}

	if(typeof this.loadingProgressNotifier === 'function'){
		this.loadingProgressNotifier("Loading crossroads");
	}

	for (var i = 0; i < obj.incroci_a_4.length; i++) {
		var c = new Crossroad(obj.incroci_a_4[i]);
		c.linkStreets(this.streets, this.id);
		this.crossroads[obj.incroci_a_4[i].id] = c;
	}
	for (var i in obj.incroci_a_3){
		//obj.incroci_a_3[i].strade.splice(obj.incroci_a_3[i].strada_mancante,0,null);
		var c = new Crossroad(obj.incroci_a_3[i]);
		c.linkStreets(this.streets, this.id);
		this.crossroads[obj.incroci_a_3[i].id] = c;
	}
	//for(var i = 0; i < obj.strade_ingresso.length; i++){

	if(typeof this.loadingProgressNotifier === 'function'){
		this.loadingProgressNotifier("Loading sidestreets");
	}

	for(var i in obj.strade_ingresso){
		obj.strade_ingresso[i]['from'] = 0;
		obj.strade_ingresso[i]['to'] = 0;
		var str = new Street(obj.strade_ingresso[i]);
		str.mainStreet = obj.strade_ingresso[i].strada_confinante;
		str.entranceSide = obj.strade_ingresso[i].polo;
		str.entranceDistance = obj.strade_ingresso[i].distanza_da_from;
		str.setType('entrance');
		this.entranceStreets[str.id] = str;
		this.streets[str.mainStreet].addSideStreet(str);
	}

	if(typeof this.loadingProgressNotifier === 'function'){
		this.loadingProgressNotifier("Loading places");
	}

	for(var i = 0; i < obj.luoghi.length; i++){
		var p = new Place(obj.luoghi[i]);
		this.places[p.id] = p;
	}
	if(typeof this.finishLoadingCallback === 'function'){
		this.finishLoadingCallback();
	}
}

Map.prototype.draw = function(){
	if(typeof this.startDrawingCallback === 'function'){
		this.startDrawingCallback();
	}

	if(typeof this.loadingProgressNotifier === 'function'){
		this.loadingProgressNotifier("Drawing crossroads");
	}

	for (var i in this.crossroads) {
		this.crossroads[i].draw(this.mapStyle);
	}

	if(typeof this.loadingProgressNotifier === 'function'){
		this.loadingProgressNotifier("Drawing streets");
	}

	for (var i in this.streets) {
		this.streets[i].draw(this.mapStyle);
	}

	if(typeof this.loadingProgressNotifier === 'function'){
		this.loadingProgressNotifier("Drawing sidestreets");
	}

	for (var i in this.entranceStreets){

		var mainStreet = this.streets[this.entranceStreets[i].mainStreet];
		var side = this.entranceStreets[i].entranceSide ? -1 : 1;

		var refPoint = mainStreet.guidingPath.getPointAt(this.entranceStreets[i].entranceDistance);
		var normalFrom = mainStreet.guidingPath.getNormalAt(this.entranceStreets[i].entranceDistance);
		normalFrom.length = side*(mainStreet.nLanes*this.mapStyle.laneWidth + this.mapStyle.pavementWidth);
		
		var normalTo = mainStreet.guidingPath.getNormalAt(this.entranceStreets[i].entranceDistance);
		normalTo.length = side*(mainStreet.nLanes*this.mapStyle.laneWidth + this.mapStyle.pavementWidth + this.entranceStreets[i].len);	
		
		this.entranceStreets[i].from = [(refPoint.x + normalFrom.x), (refPoint.y + normalFrom.y)];
		this.entranceStreets[i].to = [(refPoint.x + normalTo.x), (refPoint.y + normalTo.y)];
		this.entranceStreets[i].reposition();
		this.entranceStreets[i].draw(this.mapStyle);
	}

	if(typeof this.loadingProgressNotifier === 'function'){
		this.loadingProgressNotifier("Drawing places");
	}

	for (var i in this.places){
		this.places[i].setEnteringStreet(this.entranceStreets[this.places[i].entranceStreetId]);
		this.places[i].draw(this.mapStyle);
	}

	if(typeof this.finishDrawingCallback === 'function'){
		this.finishDrawingCallback();
	}

	if(typeof this.mapReadyCallback === 'function'){
		this.mapReadyCallback();
	}
}

Map.prototype.getUpdatedData = function(){
	var l = this.objData.strade.length;
	var i = 0;
	// for(var i = 0; i < l; i++){ 
	var enteringPaths = null
	for(var i in this.objData.strade){ 	
		this.objData.strade[i].lunghezza = this.streets[this.objData.strade[i].id].guidingPath.length;
		var sE = this.streets[this.objData.strade[i].id].sideStreetsEntrancePaths;
		for(var c in sE){
			var toAdd = {
				id : sE[c].id,
				principale : sE[c].principale,
				laterale : sE[c].laterale,
				verso : sE[c].verso,
				lunghezza : sE[c].path.length,
			}
			//this.objData.strade[i].traiettorie_ingresso.push(toAdd);
		}
		delete this.objData.strade[i].traiettorie_ingresso;
		var sStreets = this.streets[this.objData.strade[i].id].sideStreets;
		if(enteringPaths == null && (Object.keys(sStreets[false]).length > 0 || Object.keys(sStreets[true]).length > 0)){
			if(i ==0){
				i++;
			} else {
				enteringPaths = this.calcEntrancePathIntersections(this.streets[this.objData.strade[i].id]);
			}
		}
	}
	this.objData['traiettorie_incrocio_a_3'] = this.calcCrossroadsCrossingPathsIntersections(this.objData.incroci_a_3[Object.keys(this.objData.incroci_a_3)[0]]);
	//console.log(this.objData['traiettorie_incrocio_a_3']);
	this.objData['traiettorie_incrocio_a_4'] = this.calcCrossroadsCrossingPathsIntersections(this.objData.incroci_a_4[Object.keys(this.objData.incroci_a_4)[0]]);
	this.objData['traiettorie_ingresso'] = enteringPaths;
	this.objData['larghezza_marciapiede'] = this.mapStyle.pavementWidth;
	/*
	for(var i in this.objData.incroci_a_4){
		this.calcCrossroadsCrossingPathsIntersections(this.objData.incroci_a_4[i]);
	}*/
	this.objData.dimensioni_incrocio = 2*(this.mapStyle.pavementWidth + this.mapStyle.laneWidth*2)
	return this.objData;
}

Map.prototype.calcEntrancePathIntersections = function(street){
	var enteringPaths = null;
	var side = false;
	console.log(street.sideStreets);
	if(Object.keys(street.sideStreets[false]).length > 0){
		console.log(street.sideStreets[false]);
		console.log(Object.keys(street.sideStreets[false]));
		enteringPaths = street.sideStreets[false][Object.keys(street.sideStreets[false])[0]].paths;
	} else {
		console.log(street.sideStreets[true]);
		console.log(Object.keys(street.sideStreets[true]));
		enteringPaths = street.sideStreets[true][Object.keys(street.sideStreets[true])[0]].paths;
		side = true;
	}
	enteringPaths['entrata_ritorno'].path.fullySelected = true;
	street.guidingPath.fullySelected = true;
	console.log(street.id);
	console.log(side);
	console.log(street.guidingPath);
	console.log(enteringPaths['entrata_ritorno'].path);
	console.log(enteringPaths['entrata_ritorno'].path.getIntersections(street.guidingPath));
	console.log(enteringPaths['entrata_ritorno'].path.getOffsetOf(enteringPaths['entrata_ritorno'].path.getIntersections(street.sepLines[side][1])[0].point));
	return {
		entrata_andata: {
			lunghezza: enteringPaths['entrata_andata'].path.length
		},
		uscita_andata: {
			lunghezza: enteringPaths['uscita_andata'].path.length
		},
		entrata_ritorno: {
			lunghezza: enteringPaths['entrata_ritorno'].path.length,
			intersezioni:[
				{
					traiettoria: 'uscita_ritorno_1',
					distanza: enteringPaths['entrata_ritorno'].path.getOffsetOf(enteringPaths['entrata_ritorno'].path.getIntersections(enteringPaths['uscita_ritorno_1'].path)[0].point),
				},
				{
					traiettoria: 'uscita_ritorno_2',
					distanza: enteringPaths['entrata_ritorno'].path.getOffsetOf(enteringPaths['entrata_ritorno'].path.getIntersections(enteringPaths['uscita_ritorno_2'].path)[0].point),
				},
				{
					traiettoria: 'linea_corsia',
					distanza: enteringPaths['entrata_ritorno'].path.getOffsetOf(enteringPaths['entrata_ritorno'].path.getIntersections(street.sepLines[side][1])[0].point),
				},
				{
					traiettoria: 'linea_mezzaria',
					distanza:  enteringPaths['entrata_ritorno'].path.getOffsetOf(enteringPaths['entrata_ritorno'].path.getIntersections(street.guidingPath)[0].point),
				}
			]
		},
		uscita_ritorno_1: {
			lunghezza: enteringPaths['uscita_ritorno_1'].path.length,
			intersezioni: [
				{
					traiettoria: 'entrata_ritorno',
					distanza: enteringPaths['uscita_ritorno_1'].path.getOffsetOf(enteringPaths['uscita_ritorno_1'].path.getIntersections(enteringPaths['entrata_ritorno'].path)[0].point),
				},
				{
					traiettoria: 'linea_corsia',
					distanza: enteringPaths['uscita_ritorno_1'].path.getOffsetOf(enteringPaths['uscita_ritorno_1'].path.getIntersections(street.sepLines[side][1])[0].point),
				},
				{
					traiettoria: 'linea_mezzaria',
					distanza: enteringPaths['uscita_ritorno_1'].path.getOffsetOf(enteringPaths['uscita_ritorno_1'].path.getIntersections(street.guidingPath)[0].point),
				}
			]
		},
		uscita_ritorno_2: {
			lunghezza: enteringPaths['uscita_ritorno_2'].path.length,
			intersezioni: [
				{
					traiettoria: 'entrata_ritorno',
					distanza: enteringPaths['uscita_ritorno_2'].path.getOffsetOf(enteringPaths['uscita_ritorno_2'].path.getIntersections(enteringPaths['entrata_ritorno'].path)[0].point),
				}
			]
		},
	}
}

Map.prototype.calcCrossroadsCrossingPathsIntersections = function(crossroad_ref){
	var c = this.crossroads[crossroad_ref.id];
	traiettorie = {};
	for(var p in c.crossingPaths){
		var np = parseInt(p);
		traiettorie[np] = {};

		if(c.crossingPaths[p] != null && c.crossingPaths[p].right){
			traiettorie[np]['destra'] = makeCPData(c.crossingPaths[p].right);
		}
		if(c.crossingPaths[p] != null && c.crossingPaths[p].left){
			var cLeft = makeCPData(c.crossingPaths[p].left);
			if(c.crossingPaths[(np+2)%4] != null && c.crossingPaths[(np+2)%4].straight_1 && c.crossingPaths[(np+2)%4].straight_2){

				cLeft.intersezioni = [
					{
						//traiettoria: c.crossingPaths[(np+2)%4].straight_1.id,
						traiettoria: 'ditto_1',
						distanza: c.crossingPaths[p].left.path.getOffsetOf(c.crossingPaths[p].left.path.getIntersections(c.crossingPaths[(np+2)%4].straight_1.path)[0].point),
					},
					{
						//traiettoria: c.crossingPaths[(np+2)%4].straight_2.id,
						traiettoria: 'dritto_2',
						distanza: c.crossingPaths[p].left.path.getOffsetOf(c.crossingPaths[p].left.path.getIntersections(c.crossingPaths[(np+2)%4].straight_2.path)[0].point),
					},
				];
			}
			//traiettorie[c.crossingPaths[p].left.id] = cLeft;
			traiettorie[np]['sinistra'] = cLeft;
		}
		if(c.crossingPaths[p] != null && c.crossingPaths[p].straight_1 && c.crossingPaths[p].straight_2){
			var s1 = makeCPData(c.crossingPaths[p].straight_1);
			var s2 = makeCPData(c.crossingPaths[p].straight_2);
			if(c.crossingPaths[(np+2)%4] && c.crossingPaths[(np+2)%4].left){
				s1.intersezioni = [
					{
						//traiettoria: c.crossingPaths[(np+2)%4].left.id,
						traiettoria: 'sinistra',
						distanza: c.crossingPaths[p].straight_1.path.getOffsetOf(c.crossingPaths[p].straight_1.path.getIntersections(c.crossingPaths[(np+2)%4].left.path)[0].point),
					}
				];
				s2.intersezioni = [
					{
						//traiettoria: c.crossingPaths[(np+2)%4].left.id,
						traiettoria: 'sinistra',
						distanza: c.crossingPaths[p].straight_2.path.getOffsetOf(c.crossingPaths[p].straight_2.path.getIntersections(c.crossingPaths[(np+2)%4].left.path)[0].point),
					}
				];
			}
			traiettorie[np]['dritto_1'] = s1;
			traiettorie[np]['dritto_2'] = s2;
		}
	}
	return traiettorie;
}

function makeCPData(cP){
	return {
		//id: cP.id,
		lunghezza: cP.path.length,
		strada_partenza: {
			strada: cP.start.index,
			corsia: cP.start.lane,
		},
		strada_arrivo: {
			strada: cP.end.index,
			corsia: cP.end.lane,
		}
	}
}

/*
	Aligns both handlers to an average of the coordinates
*/
Map.alignHandleAvg = function(h1, h2){
	var h2Bis = new Point(-h1.x,-h1.y);
	var h1Bis = new Point(-h2.x,-h2.y);
	h1.x = (h1.x+h1Bis.x)/2;
	h1.y = (h1.y+h1Bis.y)/2;
	h2.x = (h2.x+h2Bis.x)/2;
	h2.y = (h2.y+h2Bis.y)/2;
}

/*
	Aligns the first handle to the second
*/
Map.alignHandle = function(h1, h2){
	var h1Bis = new Point(-h2.x,-h2.y);
	h1.x = (h1Bis.x);
	h1.y = (h1Bis.y);
}

Map.prototype.switchTrafficLights = function(){
	for(i in this.crossroads){
		this.crossroads[i].switchTrafficLights();
	}
}


/**
 * WorldMap class
 * Used to draw alle the zones
**/

function WorldMap(){
	Map.call(this);
}

WorldMap.prototype = Object.create(Map.prototype);
WorldMap.prototype.constructor = WorldMap;

