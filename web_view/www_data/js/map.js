/**
 *	Author: Marco Negro
 *	Email: negromarc@gmail.com
 *	Descr: Map object to handle and render the map of the simulation
 */
showTraiettorieAuto = false;
showTraiettoriePedoni = false;
pathWidth = 0.3;
bikeDash = [pathWidth, pathWidth];

lunghezza_traiettorie_ingressi = {};
lunghezza_traiettorie_incroci = {
	'pedoni': {},
	'auto': {}
};

pathsToLift = new Array();

function drawBPath(path, color1, color2, style) {
	if (showTraiettoriePedoni) {
		bike = pathOffset(path, 0.25 * style.pavementWidth);
		bike.smooth();
		ped = pathOffset(path, -0.25 * style.pavementWidth);
		ped.smooth();
		bike.strokeWidth = pathWidth;
		bike.strokeColor = color1;
		ped.strokeWidth = pathWidth;
		ped.strokeColor = color2;
	}
}


function drawPath(path, color, dash) {
	return drawPath(path, color, 0.5, dash);
}

function drawPath(path, color, thikness, dash) {
	path.strokeWidth = thikness;
	path.strokeColor = color;
	path.visible = true;
	path.dashArray = dash;
	// path.selected = true;
	pathsToLift.push(path);
	return path;
}

function liftPaths() {

	for (var i = pathsToLift.length - 1; i >= 0; i--) {
		pathsToLift[i].bringToFront();
	};
}

function sortPoints(a, b) {
	var res = a.x - b.x;
	if (res == 0) {
		res = a.y - b.y;
	}
	return res;
}

function sortCrossroadsStreets(a, b) {
	return sortPoints(a.point, b.point);
}

function doesExists(thing) {
	return typeof thing !== 'undefined' && thing != null;
}

function pathOffset(path, offset, precision, style, start, end) {
	/*
	  path: path object to be offset
	  offset: length of offset
	  precision: the amount of precision (the higher the more precise)
	*/
	start = typeof start !== 'undefined' ? start : 0;
	end = typeof end !== 'undefined' ? end : path.length;

	//recommended precision: Math.ceil(path.length)
	precision = typeof precision !== 'undefined' ? precision : Math.ceil(path.length);
	var len = end - start;
	if (end < path.length) {
		len += 1;
	}

	var copy = new Path();
	if (typeof style === 'undefined') {
		copy.strokeColor = path.strokeColor;
		copy.strokeWidth = path.strokeWidth;
		copy.dashArray = path.dashArray;
	} else if (style == 0) {
		copy.visible = false;
	} else {
		copy.strokeColor = style.strokeColor;
		copy.strokeWidth = style.strokeWidth;
		copy.dashArray = style.dashArray;
	}

	for (var i = 0; i < precision + 1; i++) {
		var pos = i / precision * len;
		var point = path.getPointAt(pos + start);
		var normal = path.getNormalAt(pos + start);
		normal.length = offset;
		copy.add(point.add(normal));
	}
	//copy.simplify();
	return copy;
}

function getPositionAtOffset(path, distance, side, offset) {
	if (typeof side === 'string') {
		side = (side === 'true');
	}

	distance = (distance < 0) ? 0 : distance;
	distance = (distance > path.length) ? path.length : distance;
	var loc = path.getLocationAt(distance);

	offset = side ? offset : -offset;

	var normal = path.getNormalAt(distance);
	normal.length = offset;

	return {
		angle: loc.tangent.angle,
		position: new Point(loc.point.x + normal.x, loc.point.y + normal.y)
	};
}

function setPathHandles(path, side) {
	var tmpLoc = path.getLocationAt(path.length / 2);
	var tmpNorm = path.getNormalAt(path.length / 2);
	tmpNorm.length = side * path.length / 2;
	var tmpP = tmpLoc.point.subtract(tmpNorm);
	path.firstSegment.handleOut = tmpP.subtract(path.firstSegment.point);
	path.lastSegment.handleIn = tmpP.subtract(path.lastSegment.point);
}

/**
 *
 *	MapStyle class
 *
 **/

function MapStyle() {
	this.lineColor = 'white';
	this.laneColor = 'grey';
	this.lineWidth = 0.15;
	this.laneWidth = 7;
	this.pavementColor = 'grey';
	this.pavementWidth = 3;
	this.dashArray = [3, 4.5];
	this.zebraDash = [0.5, 0.5];
	this.pavementMiddleDash = [1, 1.5];
	this.middlePathEntranceDashOffset = 5;
}

/**
 *
 *	Street class
 *
 **/

function Street(obj, map, designMode) {
	this.designMode = designMode !== 'undefined' ? designMode : false;
	this.map = map;

	this.id = obj.id;
	this.len = obj.lunghezza;
	this.nLanes = obj.numcorsie;
	this.from = obj.from;
	this.to = obj.to;
	this.guidingPath = new Path();
	this.guidingPath.add(new Point(obj.from[0], obj.from[1]));
	//this.guidingPath.add(new Point((obj.from[0]+obj.to[0])/2, (obj.from[1]+obj.to[1])/2));
	this.guidingPath.add(new Point(obj.to[0], obj.to[1]));
	this.sepLines = {
		true: [],
		false: []
	};
	this.guidingPath.smooth();
	this.path = null;
	this.name = obj.nome ? obj.nome : "";
	this.type = 'standard';
	this.sideStreets = {
		true: {},
		false: {}
	};
	this.sideStreetsEntrancePaths = {};
	this.pedestrianSidestreetPaths = {
		true: {},
		false: {}
	};
	this.designMode = false;
}

Street.prototype.reposition = function() {
	this.guidingPath = new Path();
	this.guidingPath.add(new Point(this.from[0], this.from[1]));
	this.guidingPath.add(new Point(this.to[0], this.to[1]));
	this.guidingPath.smooth();
}

Street.prototype.setType = function(newType) {
	this.type = newType;
}

Street.prototype.draw = function(style) {
	this.laneWidth = style.laneWidth;
	this.pavementWidth = style.pavementWidth;
	if (this.type == 'entrance') {
		var from = this.guidingPath.firstSegment.point;
		var to = this.mainStreetObj.guidingPath.getLocationAt(this.entranceDistance).point;
		this.path = new Path(from, to);
	} else {
		this.path = new Path(this.guidingPath.pathData);
	}
	this.path.strokeColor = style.laneColor;
	this.path.strokeWidth = style.laneWidth * this.nLanes * 2 + style.pavementWidth * 2;
	//this.guidingPath.strokeColor = style.lineColor;
	//this.guidingPath.strokeWidth = style.lineWidth;
	//this.guidingPath.moveAbove(this.path);
	//this.guidingPath.fullySelected = true;
	var precision = Math.ceil(this.guidingPath.length);

	if (this.id != "") {
		var signPath = pathOffset(this.guidingPath, this.nLanes + style.laneWidth + 4 * style.pavementWidth, precision, {
			strokeWidth: 0,
			strokColo: 'black',
			dashArray: null
		});
		var startPoint = signPath.getPointAt(signPath.length / 3);
		var text = new PointText(startPoint);
		text.content = this.id;
	}
	this.path.sendToBack();
}

Street.prototype.drawHorizontalLines = function(style) {
	// drawing the separation lines
	var precision = Math.ceil(this.guidingPath.length);
	var sepStyle = {
		strokeWidth: style.lineWidth,
		strokeColor: style.lineColor,
		dashArray: style.dashArray
	};
	var len = this.nLanes;
	for (var i = 1; i < len; i++) {
		this.sepLines[false][i] = pathOffset(this.guidingPath, (i) * style.laneWidth, precision, sepStyle);
		//p1.rasterize();
		//p1.remove();
		this.sepLines[true][i] = pathOffset(this.guidingPath, -(i) * style.laneWidth, precision, sepStyle);
		//p2.rasterize();
		//p2.remove();
	}

	// drawing the pedestrian lines
	var pedestrianPaths = {
		true: [{
			start: 0,
			end: this.guidingPath.length,
			type: 'pavement'
		}],
		false: [{
			start: 0,
			end: this.guidingPath.length,
			type: 'pavement'
		}]
	};
	var middlePaths = [{
		start: 0,
		end: this.guidingPath.length,
		type: 'continuous'
	}];
	//console.log(this.sideStreets);
	if ((Object.keys(this.sideStreets[false]).length + Object.keys(this.sideStreets[true]).length) > 0) {
		middlePaths = {
			true: [],
			false: []
		};
		for (var side in this.sideStreets) {
			//pedestrianPaths[side][0] = {start:0, end:this.guidingPath.length, type:'pavement'};
			//middlePaths[side][0] = {start:0, end:this.guidingPath.length, type:'continuous'};
			var prev = 0;
			for (var index in this.sideStreets[side]) {
				var curStr = this.sideStreets[side][index];
				var d = /*side ? this.guidingPath.length - curStr.entranceDistance :*/ curStr.entranceDistance;
				var crossStart = d - curStr.nLanes * style.laneWidth;
				var crossEnd = d + curStr.nLanes * style.laneWidth;
				pedestrianPaths[side][prev].end = crossStart;
				//middlePaths[side][prev].end = crossStart;
				prev++;
				pedestrianPaths[side][prev] = {
					start: crossStart,
					end: crossEnd,
					type: 'zebra',
					position: index
				};
				middlePaths[side].push({
					start: Math.max(0, crossStart - style.middlePathEntranceDashOffset),
					end: Math.min(this.guidingPath.length, crossEnd + style.middlePathEntranceDashOffset),
					type: 'dashed'
				});
				prev++;
				pedestrianPaths[side][prev] = {
					start: crossEnd,
					end: this.guidingPath.length,
					type: 'pavement'
				};
				// middlePaths[side][prev] = {start: crossEnd, end:this.guidingPath.length, type:'continuous'};
				this.sideStreets[side][index].paths = this.prepareSidestreetsAccessPaths(style, curStr, crossStart, crossEnd, side);
			}
		}
		middlePaths = this.prepareMiddleLinePaths(middlePaths);
	}

	this.drawMiddleLine(middlePaths, style, precision);
	this.drawPedestrianLines(pedestrianPaths, style, precision);
}

Street.prototype.prepareMiddleLinePaths = function(middlePaths) {
	var tmpMiddlePaths = [];
	var tmpT, tmpF;

	while (middlePaths[true].length > 0 || middlePaths[false].length > 0) {
		tmpT = tmpT == null ? middlePaths[true].shift() : tmpT;
		tmpF = tmpF == null ? middlePaths[false].shift() : tmpF;
		if (tmpT && tmpF) {
			if (tmpT.start < tmpF.start) {
				tmpMiddlePaths.push(tmpT);
				tmpT = null;
			} else {
				tmpMiddlePaths.push(tmpF);
				tmpF = null;
			}
		} else {
			if (tmpT) tmpMiddlePaths.push(tmpT);
			if (tmpF) tmpMiddlePaths.push(tmpF);
			tmpT = null;
			tmpF = null;
		}
	}

	var prevMid = tmpMiddlePaths.shift();
	middlePaths = [{
		start: 0,
		end: prevMid.start - 1,
		type: 'continuous'
	}, prevMid];

	var arrIdx = 1;
	var lastOut = null;

	while (tmpMiddlePaths.length > 0) {
		lastOut = tmpMiddlePaths.shift();
		if (prevMid.end > lastOut.start) {
			// merge the two
			prevMid.end = lastOut.end;
		} else {
			// add prev and a continuous line
			middlePaths.push({
				start: prevMid.end,
				end: lastOut.start - 1,
				type: 'continuous'
			});
			prevMid = lastOut;
			middlePaths.push(prevMid);
		}
	}

	var lastPathStart = middlePaths[middlePaths.length - 1] != null ? middlePaths[middlePaths.length - 1].end : 0;
	middlePaths.push({
		start: lastPathStart,
		end: this.guidingPath.length,
		type: 'continuous'
	});
	return middlePaths
}

Street.prototype.prepareSidestreetsAccessPaths = function(style, curStr, crossStart, crossEnd, side) {
	var entrata_andata = new Path();
	var uscita_andata = new Path();
	var entrata_ritorno = new Path();
	var uscita_ritorno = new Path();
	// var exitingPath2_2 = new Path();
	var enterHandlePoint = null;
	var exitHandlePoint = null;
	var sideStreetsEntrancePaths = {};
	if (typeof side === 'string') {
		side = (side === 'true');
	}
	if (!side) {
		entrata_andata.add(this.getPositionAt(crossStart - style.pavementWidth, side, 1, false).position);
		entrata_andata.add(this.getSidestreetPositionAt(crossStart + 0.5 * style.laneWidth, side).position);
		uscita_andata.add(this.getSidestreetPositionAt(crossEnd - 0.5 * style.laneWidth, side).position);
		uscita_andata.add(this.getPositionAt(crossEnd + style.pavementWidth, side, 1, false).position);

		entrata_ritorno.add(this.getPositionAt(crossEnd + style.pavementWidth, !side, 0, false).position);
		entrata_ritorno.add(this.getSidestreetPositionAt(crossStart + 0.5 * style.laneWidth, side).position);
		uscita_ritorno.add(this.getSidestreetPositionAt(crossEnd - 0.5 * style.laneWidth, side).position);
		uscita_ritorno.add(this.getPositionAt(crossStart - style.pavementWidth, !side, 0, false).position);
		// exitingPath2_2.add(this.getSidestreetPositionAt(crossEnd-0.5*style.laneWidth, side).position);
		// exitingPath2_2.add(this.getPositionAt(crossStart, !side, 1, false).position);

		enterHandlePoint1 = this.getPositionAt(crossStart + 0.5 * style.laneWidth, side, 1, false).position;
		exitHandlePoint1 = this.getPositionAt(crossEnd - 0.5 * style.laneWidth, side, 1, false).position;

		enterHandlePoint2 = this.getPositionAt(crossStart + 0.5 * style.laneWidth, !side, 0, false).position;
		exitHandlePoint2_1 = this.getPositionAt(crossEnd - 0.5 * style.laneWidth, !side, 0, false).position;
		// exitHandlePoint2_2 = this.getPositionAt(crossEnd-0.5*style.laneWidth, !side, 1, false).position;				
	} else {
		uscita_andata.add(this.getSidestreetPositionAt(crossStart + 0.5 * style.laneWidth, side).position);
		uscita_andata.add(this.getPositionAt(crossStart - style.pavementWidth, side, 1, false).position);
		entrata_andata.add(this.getPositionAt(crossEnd + style.pavementWidth, side, 1, false).position);
		entrata_andata.add(this.getSidestreetPositionAt(crossEnd - 0.5 * style.laneWidth, side).position);

		uscita_ritorno.add(this.getSidestreetPositionAt(crossStart + 0.5 * style.laneWidth, side).position);
		uscita_ritorno.add(this.getPositionAt(crossEnd + style.pavementWidth, !side, 0, false).position);
		// exitingPath2_2.add(this.getSidestreetPositionAt(crossStart+0.5*style.laneWidth, side).position);
		// exitingPath2_2.add(this.getPositionAt(crossEnd, !side, 1, false).position);
		entrata_ritorno.add(this.getPositionAt(crossStart - style.pavementWidth, !side, 0, false).position);
		entrata_ritorno.add(this.getSidestreetPositionAt(crossEnd - 0.5 * style.laneWidth, side).position);

		enterHandlePoint1 = this.getPositionAt(crossEnd - 0.5 * style.laneWidth, side, 1, false).position;
		exitHandlePoint1 = this.getPositionAt(crossStart + 0.5 * style.laneWidth, side, 1, false).position;

		enterHandlePoint2 = this.getPositionAt(crossEnd - 0.5 * style.laneWidth, !side, 0, false).position;
		exitHandlePoint2_1 = this.getPositionAt(crossStart + 0.5 * style.laneWidth, !side, 0, false).position;
		// exitHandlePoint2_2 = this.getPositionAt(crossStart+0.5*style.laneWidth, !side, 1, false).position;		
	}

	entrata_andata.firstSegment.handleOut = enterHandlePoint1.subtract(entrata_andata.firstSegment.point);
	entrata_andata.firstSegment.handleOut.length = 0.8 * entrata_andata.firstSegment.handleOut.length;
	entrata_andata.lastSegment.handleIn = enterHandlePoint1.subtract(entrata_andata.lastSegment.point);
	entrata_andata.lastSegment.handleIn.length = 0.5 * entrata_andata.lastSegment.handleIn.length;
	entrata_andata.smooth();
	entrata_andata.visible = false;
	//this.sideStreetsEntrancePaths["M"+this.id+"-S"+curStr.id] = {id:"M"+this.id+"-S"+curStr.id, principale: this.id, laterale:curStr.id, verso:'entrata', path:entrata_andata, polo:true};
	sideStreetsEntrancePaths["entrata_andata"] = {
		id: "M" + this.id + "_go-S" + curStr.id + "_in",
		principale: this.id,
		laterale: curStr.id,
		verso: 'entrata',
		path: entrata_andata,
		polo: true
	};

	uscita_andata.firstSegment.handleOut = exitHandlePoint1.subtract(uscita_andata.firstSegment.point);
	uscita_andata.firstSegment.handleOut.length = 0.5 * uscita_andata.firstSegment.handleOut.length;
	uscita_andata.lastSegment.handleIn = exitHandlePoint1.subtract(uscita_andata.lastSegment.point);
	uscita_andata.lastSegment.handleIn.length = 0.8 * uscita_andata.lastSegment.handleIn.length;
	uscita_andata.smooth();
	uscita_andata.visible = false;
	//this.sideStreetsEntrancePaths["S"+curStr.id+"-M"+this.id] = {id:"S"+curStr.id+"-M"+this.id, principale: this.id, laterale:curStr.id, verso:'uscita', path:uscita_andata, polo:true};;
	sideStreetsEntrancePaths["uscita_andata"] = {
		id: "M" + this.id + "_go-S" + curStr.id + "_out",
		principale: this.id,
		laterale: curStr.id,
		verso: 'uscita',
		path: uscita_andata,
		polo: true
	};

	entrata_ritorno.firstSegment.handleOut = enterHandlePoint2.subtract(entrata_ritorno.firstSegment.point);
	entrata_ritorno.firstSegment.handleOut.length = 0.8 * entrata_ritorno.firstSegment.handleOut.length;
	entrata_ritorno.lastSegment.handleIn = enterHandlePoint2.subtract(entrata_ritorno.lastSegment.point);
	entrata_ritorno.lastSegment.handleIn.length = 0.5 * entrata_ritorno.lastSegment.handleIn.length;
	entrata_ritorno.smooth();
	entrata_ritorno.visible = false;
	//this.sideStreetsEntrancePaths["M"+this.id+"-S"+curStr.id] = {id:"M"+this.id+"-S"+curStr.id, principale: this.id, laterale:curStr.id, verso:'entrata', path:entrata_ritorno, polo:true};
	sideStreetsEntrancePaths["entrata_ritorno"] = {
		id: "M" + this.id + "_come-S" + curStr.id + "_in",
		principale: this.id,
		laterale: curStr.id,
		verso: 'entrata',
		path: entrata_ritorno,
		polo: true
	};

	uscita_ritorno.firstSegment.handleOut = exitHandlePoint2_1.subtract(uscita_ritorno.firstSegment.point);
	uscita_ritorno.firstSegment.handleOut.length = 0.5 * uscita_ritorno.firstSegment.handleOut.length;
	uscita_ritorno.lastSegment.handleIn = exitHandlePoint2_1.subtract(uscita_ritorno.lastSegment.point);
	uscita_ritorno.lastSegment.handleIn.length = 0.8 * uscita_ritorno.lastSegment.handleIn.length;
	uscita_ritorno.smooth();
	uscita_ritorno.visible = false;
	//this.sideStreetsEntrancePaths["S"+curStr.id+"-M"+this.id] = {id:"S"+curStr.id+"-M"+this.id, principale: this.id, laterale:curStr.id, verso:'uscita', path:uscita_andata, polo:true};;
	sideStreetsEntrancePaths["uscita_ritorno"] = {
		id: "M" + this.id + "_come-S" + curStr.id + "_out_1",
		principale: this.id,
		laterale: curStr.id,
		verso: 'uscita',
		path: uscita_ritorno,
		polo: true
	};

	// exitingPath2_2.firstSegment.handleOut = exitHandlePoint2_2.subtract(exitingPath2_2.firstSegment.point);
	// exitingPath2_2.firstSegment.handleOut.length = 0.5*exitingPath2_2.firstSegment.handleOut.length;
	// exitingPath2_2.lastSegment.handleIn = exitHandlePoint2_2.subtract(exitingPath2_2.lastSegment.point);
	// exitingPath2_2.lastSegment.handleIn.length = 0.8*exitingPath2_2.lastSegment.handleIn.length;
	// exitingPath2_2.smooth();
	// //this.sideStreetsEntrancePaths["S"+curStr.id+"-M"+this.id] = {id:"S"+curStr.id+"-M"+this.id, principale: this.id, laterale:curStr.id, verso:'uscita', path:uscita_andata, polo:true};;
	// sideStreetsEntrancePaths["uscita_ritorno_2"] = {id:"M"+this.id+"_come-S"+curStr.id+"_out_2", principale: this.id, laterale:curStr.id, verso:'uscita', path:exitingPath2_2, polo:true};

	if (showTraiettorieAuto) {
		drawPath(uscita_andata, 'yellow');
		drawPath(uscita_ritorno, 'green');
		drawPath(entrata_andata, 'red');
		drawPath(entrata_ritorno, 'blue');
	}

	if (this.designMode && !this.map.traiettorie.traiettorie_ingresso.entrata_andata) {
		this.map.traiettorie.traiettorie_ingresso.entrata_andata = {
			"lunghezza": entrata_andata.length
		};
		this.map.traiettorie.traiettorie_ingresso.uscita_andata = {
			"lunghezza": uscita_andata.length
		};
		this.map.traiettorie.traiettorie_ingresso.entrata_ritorno = {
			"lunghezza": entrata_ritorno.length
		};
		this.map.traiettorie.traiettorie_ingresso.uscita_ritorno = {
			"lunghezza": uscita_ritorno.length
		};

		this.map.path_traiettorie.traiettorie_ingresso.entrata_andata = entrata_andata;
		this.map.path_traiettorie.traiettorie_ingresso.uscita_andata = uscita_andata;
		this.map.path_traiettorie.traiettorie_ingresso.entrata_ritorno = entrata_ritorno;
		this.map.path_traiettorie.traiettorie_ingresso.uscita_ritorno = uscita_ritorno;

		this.map.path_traiettorie.traiettorie_ingresso.strada = this;

		var p1 = new Path(this.getPositionAtOffset(crossStart, true, 50).position, this.getPositionAtOffset(crossStart, false, 50).position);

		var p2 = new Path(this.getPositionAtOffset(crossEnd, true, 50).position, this.getPositionAtOffset(crossEnd, false, 50).position);
		//p1.selected = true;
		//p2.selected = true;
		//uscita_ritorno.selected = true;
		var intr = uscita_ritorno.getIntersections(p1)[0];
		if (intr == null) {
			intr = uscita_ritorno.getIntersections(p2)[0];
		}

		if (intr != null) {
			this.map.traiettorie.traiettorie_ingresso.uscita_ritorno.intersezione_bipedi = uscita_ritorno.getOffsetOf(intr.point);
		}
		// console.log("traiettorie_ingresso_auto: "+JSON.stringify(o));
		// console.log("lunghezza uscita_ritorno: "+uscita_ritorno.getOffsetOf(intr.point));
		/*
		lunghezza_traiettorie_ingressi['auto'] = {};
		lunghezza_traiettorie_ingressi['auto']['uscita_ritorno'] = {
			"intersezione": {
				"traiettoria": "attraversamento",
				"lunghezza": uscita_ritorno.getOffsetOf(intr.point)
			} 
		};
		controlloIngressoPedoni = true;*/
	}

	if (false /*style.debug*/ ) {
		uscita_andata.fullySelected = true;
		entrata_andata.fullySelected = true;
		uscita_ritorno.fullySelected = true;
		//exitingPath2_2.fullySelected = true;
		entrata_ritorno.fullySelected = true;
		var c1 = new Path.Circle(uscita_andata.getPointAt(1), 0.5);
		c1.fillColor = 'blue';
		var c2 = new Path.Circle(entrata_andata.getPointAt(1), 0.5);
		c2.fillColor = 'red';
		var c3 = new Path.Circle(uscita_ritorno.getPointAt(1), 0.5);
		c3.fillColor = 'blue';
		var c4 = new Path.Circle(entrata_ritorno.getPointAt(1), 0.5);
		c4.fillColor = 'red';
	}
	return sideStreetsEntrancePaths;
}

Street.prototype.setPathHandles = function(path, side) {
	var tmpLoc = path.getLocationAt(path.length / 2);
	var tmpNorm = path.getNormalAt(path.length / 2);
	tmpNorm.length = side * path.length / 2;
	var tmpP = tmpLoc.point.subtract(tmpNorm);
	path.firstSegment.handleOut = tmpP.subtract(path.firstSegment.point);
	path.lastSegment.handleIn = tmpP.subtract(path.lastSegment.point);
}

function getParallelOffset(path1, offsetOn1, path2) {
	var p1 = path1.getPointAt(offsetOn1);
	var p2 = getPositionAtOffset(path1, offsetOn1, true, 50).position;
	var pp = new Path(p1, p2);

	var intersection = path2.getIntersections(pp)[0];
	if (intersection == null) {

		p2 = getPositionAtOffset(path1, offsetOn1, false, 50).position;
		pp = new Path(p1, p2);

		intersection = path2.getIntersections(pp)[0];
	}
	var off = path2.getOffsetOf(intersection.point);
	delete p1, p2, pp, intersection;
	return off;
}

function adjustCurSeg(curSeg, guidingPath, parallelPath) {
	var newSeg = {
		type: curSeg.type
	};
	var len = curSeg.end - curSeg.start;
	var mid = curSeg.start + len / 2;
	var newMid = getParallelOffset(guidingPath, mid, parallelPath);
	if (curSeg.start == 0) {
		newSeg.start = 0;
	} else {
		newSeg.start = newMid - len / 2;
	}
	if (curSeg.end == guidingPath.length) {
		newSeg.end = parallelPath.length;
	} else {
		newSeg.end = newMid + len / 2;
	}
	return newSeg;
}

Street.prototype.drawPedestrianLines = function(pedPath, style, precision) {
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
		},
		middle: {
			strokeWidth: style.lineWidth / 2,
			strokeColor: style.lineColor,
			dashArray: style.pavementMiddleDash,
		}
	}

	var pOffset = this.nLanes * style.laneWidth + 0.5 * style.pavementWidth;
	var parallelPaths = {
		true: pathOffset(this.guidingPath, pOffset, undefined, 0),
		false: pathOffset(this.guidingPath, -pOffset, undefined, 0)
	};

	for (var side in pedPath) {
		if (typeof side === 'string') {
			sideB = (side === 'true');
		}
		for (var seg in pedPath[side]) {
			var curSeg = pedPath[side][seg];
			//var newSeg = adjustCurSeg(curSeg, this.guidingPath, parallelPath);
			var offset = (this.nLanes * style.laneWidth + (curSeg.type == 'zebra' ? 0.5 : 0) * style.pavementWidth) * (side == 'true' ? 1 : -1);
			var p;
			//var offset = ((curSeg.type == 'zebra' ? 0 : 0.5) * style.pavementWidth)*(side == 'true' ? 1 : -1);
			// var p = pathOffset(parallelPath, 0, precision, st[newSeg.type],newSeg.start, newSeg.end);
			if (curSeg.type == 'pavement') {
				// if the path is a pavement we draw the middle line to separate
				// bikes from pedestrians
				p = pathOffset(this.guidingPath, offset, precision, st[curSeg.type], curSeg.start, curSeg.end);
				var o = (this.nLanes * style.laneWidth + 0.5 * style.pavementWidth) * (side == 'true' ? 1 : -1);
				var pMiddle = pathOffset(this.guidingPath, o, precision, st['middle'], curSeg.start, curSeg.end);
			} else {
				var newSeg = {};
				newSeg[sideB] = adjustCurSeg(curSeg, this.guidingPath, parallelPaths[sideB]);
				newSeg[!sideB] = adjustCurSeg(curSeg, this.guidingPath, parallelPaths[!sideB]);
				p = pathOffset(parallelPaths[sideB], 0, precision, st[newSeg[sideB].type], newSeg[sideB].start, newSeg[sideB].end);
				// otherwise we have a crossing zebra so we need to add more zebras to cross the street
				// var offset = this.nLanes*this.laneWidth;
				// var c1 = new Path(this.getPositionAtOffset(curSeg.start-0.5*style.pavementWidth, true, offset).position, this.getPositionAtOffset(curSeg.start-0.5*style.pavementWidth, false, offset).position);
				// var c2 = new Path(this.getPositionAtOffset(curSeg.end+0.5*style.pavementWidth, false, offset).position, this.getPositionAtOffset(curSeg.end+0.5*style.pavementWidth, true, offset).position);

				var offset = 0.5 * style.pavementWidth;

				var entrata, uscita;
				var c = 1;
				if (!sideB) {
					var tmp = newSeg[sideB].start;
					newSeg[sideB].start = newSeg[sideB].end;
					newSeg[sideB].end = tmp;
					var tmp = newSeg[!sideB].start;
					newSeg[!sideB].start = newSeg[!sideB].end;
					newSeg[!sideB].end = tmp;
					c = -1;
				}

				uscita = new Path(
					getPositionAtOffset(
						parallelPaths[sideB],
						newSeg[sideB].start - 0.5 * c * style.pavementWidth, !sideB,
						offset
					).position,
					getPositionAtOffset(
						parallelPaths[!sideB],
						newSeg[!sideB].start - 0.5 * c * style.pavementWidth,
						sideB,
						offset
					).position
				);
				entrata = new Path(
					getPositionAtOffset(
						parallelPaths[!sideB],
						newSeg[!sideB].end + 0.5 * c * style.pavementWidth,
						sideB,
						offset
					).position,
					getPositionAtOffset(
						parallelPaths[sideB],
						newSeg[sideB].end + 0.5 * c * style.pavementWidth, !sideB,
						offset
					).position
				);

				entrata.strokeWidth = style.pavementWidth;
				// c1.strokeColor = style.lineColor;
				entrata.strokeColor = style.lineColor;
				entrata.dashArray = style.zebraDash;
				//Path.Circle(c1.lastSegment.point, 1).fillColor = 'red';
				uscita.strokeWidth = style.pavementWidth;
				uscita.strokeColor = style.lineColor;
				uscita.dashArray = style.zebraDash;
				// var entrata, uscita, corr=1;
				var bside = true;
				if (side === 'true') {
					//entrata = c2;
					// uscita = c1;
				} else {
					bside = false;
					// entrata = c1;
					// uscita = c2;
					var tmp = curSeg.start;
					curSeg.start = curSeg.end;
					curSeg.end = tmp;
					corr = -1;
				}

				// var entrata_dritto = new Path(entrata.lastSegment.point, this.getPositionAtOffset(curSeg.end+0.5*corr*style.pavementWidth, side === 'true', offset+style.pavementWidth).position);
				// entrata_dritto.fullySelected = true;

				var curSStr = this.sideStreets[side][curSeg.position];
				var sideS_in_point = curSStr.getPositionAtOffset(curSStr.guidingPath.length, true, style.laneWidth + 0.5 * style.pavementWidth).position;
				var sideS_in_bike = curSStr.getPositionAtOffset(curSStr.guidingPath.length, true, style.laneWidth + 0.25 * style.pavementWidth).position;
				var sideS_in_ped = curSStr.getPositionAtOffset(curSStr.guidingPath.length, true, style.laneWidth + 0.75 * style.pavementWidth).position;
				var sideS_out_point = curSStr.getPositionAtOffset(curSStr.guidingPath.length, false, style.laneWidth + 0.5 * style.pavementWidth).position;
				var sideS_out_bike = curSStr.getPositionAtOffset(curSStr.guidingPath.length, false, style.laneWidth + 0.25 * style.pavementWidth).position;
				var sideS_out_ped = curSStr.getPositionAtOffset(curSStr.guidingPath.length, false, style.laneWidth + 0.75 * style.pavementWidth).position;
				var tmpNorm, tmpLoc, tmpP;


				var entrata_dritto = new Path(entrata.lastSegment.point, sideS_in_point);
				entrata_dritto.visible = false;


				var entrata_dritto_bici = new Path(getPositionAtOffset(entrata, 0, true, 0.25 * style.pavementWidth).position, sideS_in_bike);
				var entrata_dritto_pedoni = new Path(getPositionAtOffset(entrata, 0, false, 0.25 * style.pavementWidth).position, sideS_in_ped);
				entrata_dritto_bici.visible = false;
				entrata_dritto_pedoni.visible = false;

				// var entrata_destra = new Path(this.getPositionAtOffset(curSeg.end+(bside ? 1 : -1)*style.pavementWidth, bside, offset+0.5*style.pavementWidth).position, sideS_in_point);
				// entrata_destra.visible = false;

				// var entrata_destra_bici = new Path(this.getPositionAtOffset(curSeg.end+(bside ? 1 : -1)*style.pavementWidth, bside, offset+0.25*style.pavementWidth).position, sideS_in_bike);
				var entrata_destra_bici = new Path(
					getPositionAtOffset(
						parallelPaths[sideB],
						newSeg[sideB].end + (sideB ? 1 : -1) * style.pavementWidth, !sideB,
						0.25 * style.pavementWidth
					).position,
					sideS_in_bike
				);
				var entrata_destra_pedoni = new Path(
					getPositionAtOffset(
						parallelPaths[sideB],
						newSeg[sideB].end + (bside ? 1 : -1) * style.pavementWidth,
						sideB,
						0.25 * style.pavementWidth
					).position,
					sideS_in_ped
				);

				entrata_destra_bici.visible = false;
				entrata_destra_pedoni.visible = false;
				setPathHandles(entrata_destra_bici, -1);
				setPathHandles(entrata_destra_pedoni, -1);

				var entrata_ritorno = new Path(this.getPositionAtOffset(curSeg.end, !bside, offset + 0.5 * style.pavementWidth).position, entrata.firstSegment.point);
				setPathHandles(entrata_ritorno, 1);
				entrata_ritorno.visible = false;

				var entrata_ritorno_bici = new Path(
					getPositionAtOffset(
						parallelPaths[!sideB],
						newSeg[!sideB].end,
						sideB,
						0.25 * style.pavementWidth
					).position,
					getPositionAtOffset(
						entrata,
						0,
						true,
						0.25 * style.pavementWidth
					).position
				);
				var entrata_ritorno_pedoni = new Path(
					getPositionAtOffset(
						parallelPaths[!sideB],
						newSeg[!sideB].end, !sideB,
						0.25 * style.pavementWidth
					).position,
					getPositionAtOffset(
						entrata,
						0,
						false,
						0.25 * style.pavementWidth
					).position
				);
				setPathHandles(entrata_ritorno_bici, 1);
				setPathHandles(entrata_ritorno_pedoni, 1);
				entrata_ritorno_bici.visible = false;
				entrata_ritorno_pedoni.visible = false;

				var uscita_dritto = new Path(sideS_out_point, uscita.firstSegment.point);
				uscita_dritto.visible = false;

				var uscita_dritto_bici = new Path(
					sideS_out_bike,
					getPositionAtOffset(
						uscita,
						uscita.length,
						true,
						0.25 * style.pavementWidth
					).position
				);
				var uscita_dritto_pedoni = new Path(
					sideS_out_ped,
					getPositionAtOffset(
						uscita,
						uscita.length,
						false,
						0.25 * style.pavementWidth
					).position
				);
				uscita_dritto_bici.visible = false;
				uscita_dritto_pedoni.visible = false;

				var uscita_destra = new Path(sideS_out_point, this.getPositionAtOffset(curSeg.start + (bside ? -1 : 1) * style.pavementWidth, bside, offset + 0.5 * style.pavementWidth).position);
				setPathHandles(uscita_destra, -1);
				uscita_destra.visible = false;

				var uscita_destra_bici = new Path(
					sideS_out_bike,
					getPositionAtOffset(
						parallelPaths[sideB],
						newSeg[sideB].start - (sideB ? 1 : -1) * style.pavementWidth, !sideB,
						0.25 * style.pavementWidth
					).position
				);
				var uscita_destra_pedoni = new Path(
					sideS_out_ped,
					getPositionAtOffset(
						parallelPaths[sideB],
						newSeg[sideB].start - (sideB ? 1 : -1) * style.pavementWidth,
						sideB,
						0.25 * style.pavementWidth
					).position
				);
				uscita_destra_bici.visible = false;
				uscita_destra_pedoni.visible = false;
				setPathHandles(uscita_destra_bici, -1);
				setPathHandles(uscita_destra_pedoni, -1);


				var uscita_ritorno = new Path(uscita.lastSegment.point, this.getPositionAtOffset(curSeg.start, !bside, offset + 0.5 * style.pavementWidth).position);
				setPathHandles(uscita_ritorno, 1);
				uscita_ritorno.visible = false;

				var uscita_ritorno_bici = new Path(
					getPositionAtOffset(
						uscita,
						uscita.length,
						true,
						0.25 * style.pavementWidth
					).position,
					getPositionAtOffset(
						parallelPaths[!sideB],
						newSeg[!sideB].start,
						sideB,
						0.25 * style.pavementWidth
					).position
				);
				var uscita_ritorno_pedoni = new Path(
					getPositionAtOffset(
						uscita,
						uscita.length,
						false,
						0.25 * style.pavementWidth
					).position,
					getPositionAtOffset(
						parallelPaths[!sideB],
						newSeg[!sideB].start, !sideB,
						0.25 * style.pavementWidth
					).position
				);
				setPathHandles(uscita_ritorno_bici, 1);
				setPathHandles(uscita_ritorno_pedoni, 1);
				uscita_ritorno_bici.visible = false;
				uscita_ritorno_pedoni.visible = false;

				if (showTraiettoriePedoni) {
					drawPath(entrata_destra_pedoni, 'orange', pathWidth);
					drawPath(entrata_destra_bici, 'orange', pathWidth, bikeDash);
					drawPath(entrata_ritorno_pedoni, 'blue', pathWidth);
					drawPath(entrata_ritorno_bici, 'blue', pathWidth, bikeDash);
					drawPath(uscita_destra_pedoni, 'cyan', pathWidth);
					drawPath(uscita_destra_bici, 'cyan', pathWidth, bikeDash);
					drawPath(uscita_ritorno_pedoni, 'green', pathWidth);
					drawPath(uscita_ritorno_bici, 'green', pathWidth, bikeDash);
					drawPath(entrata_dritto_pedoni, 'red', pathWidth);
					drawPath(entrata_dritto_bici, 'red', pathWidth, bikeDash);
					drawPath(uscita_dritto_pedoni, 'violet', pathWidth);
					drawPath(uscita_dritto_bici, 'violet', pathWidth, bikeDash);
				}

				this.pedestrianSidestreetPaths[side][curSeg.position] = {
					"entrata": entrata,
					"uscita": uscita,
					"attraversamento": p,
					"entrata_destra_pedoni": entrata_destra_pedoni,
					"entrata_destra_bici": entrata_destra_bici,
					"entrata_ritorno_pedoni": entrata_ritorno_pedoni,
					"entrata_ritorno_bici": entrata_ritorno_bici,
					"uscita_destra_pedoni": uscita_destra_pedoni,
					"uscita_destra_bici": uscita_destra_bici,
					"uscita_ritorno_pedoni": uscita_ritorno_pedoni,
					"uscita_ritorno_bici": uscita_ritorno_bici,
					"entrata_dritto_pedoni": entrata_dritto_pedoni,
					"entrata_dritto_bici": entrata_dritto_bici,
					"uscita_dritto_pedoni": uscita_dritto_pedoni,
					"uscita_dritto_bici": uscita_dritto_bici
				};

				if (this.designMode && !this.map.traiettorie.traiettorie_ingresso.attraversamento) {
					for (index in this.pedestrianSidestreetPaths[side][curSeg.position]) {
						this.map.traiettorie.traiettorie_ingresso[index] = {
							"lunghezza": this.pedestrianSidestreetPaths[side][curSeg.position][index].length
						};
					}
				}

				if (this.designMode && !this.map.path_traiettorie.traiettorie_ingresso.attraversamento) {
					for (index in this.pedestrianSidestreetPaths[side][curSeg.position]) {
						this.map.path_traiettorie.traiettorie_ingresso[index] = this.pedestrianSidestreetPaths[side][curSeg.position][index];
					}
					this.map.path_traiettorie.traiettorie_ingresso.strada_traiettorie_ingresso = this;
					this.map.path_traiettorie.traiettorie_ingresso.side_traiettorie_ingresso = side;
					this.map.path_traiettorie.traiettorie_ingresso.distance_traiettorie_ingresso = curSeg.position;

				}
			}
		}
	}
}

Street.prototype.drawMiddleLine = function(middlePath, style, precision) {
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
	for (var seg in middlePath) {
		pathOffset(this.guidingPath, 0, precision, st[middlePath[seg].type], middlePath[seg].start, middlePath[seg].end);
	}
}

Street.prototype.adjustCrossroadLink = function(newPoint, edge, centerPoint) {
	if (edge) {
		this.guidingPath.firstSegment.point.x = newPoint.x;
		this.guidingPath.firstSegment.point.y = newPoint.y;
		this.guidingPath.firstSegment.handleOut = newPoint.subtract(centerPoint);
		this.guidingPath.firstSegment.handleOut.length = (this.guidingPath.segments[1].point.subtract(this.guidingPath.segments[0].point)).length / 2;
	} else {
		this.guidingPath.lastSegment.point.x = newPoint.x;
		this.guidingPath.lastSegment.point.y = newPoint.y;
		this.guidingPath.lastSegment.handleIn = newPoint.subtract(centerPoint);
		var len = this.guidingPath.segments.length;
		this.guidingPath.lastSegment.handleIn.length = (this.guidingPath.segments[len - 2].point.subtract(this.guidingPath.segments[len - 1].point)).length / 2;
	}
}

Street.prototype.addSideStreet = function(sideStreet) {
	this.sideStreets[sideStreet.entranceSide][sideStreet.entranceDistance] = sideStreet;
}

Street.prototype.getPositionAtOffset = function(distance, side, offset) {
	return getPositionAtOffset(this.guidingPath, distance, side, offset);
}

Street.prototype.getStreetLength = function() {
	return this.len;
}

Street.prototype.getPositionAt = function(distance, side, lane, drive) {
	drive = typeof drive === 'undefined' ? true : drive;

	if (drive && side) {
		distance = this.guidingPath.length - distance;
	}


	var offset = lane < 0 ? this.nLanes * this.laneWidth + 0.5 * this.pavementWidth : (lane + 0.5) * this.laneWidth;

	return this.getPositionAtOffset(distance, side, offset);
}

Street.prototype.getOnPavementPositionAt = function(distance, side, bike, drive) {
	drive = typeof drive === 'undefined' ? true : drive;
	if (drive && side) {
		distance = this.guidingPath.length - distance;
	}

	var offsetOnPavement = (bike ? 0.25 : 0.75) * this.pavementWidth;
	var offset = this.nLanes * this.laneWidth + offsetOnPavement;

	return this.getPositionAtOffset(distance, side, offset);
}

Street.prototype.getOnZebraPositionAt = function(distance, side, entranceDistance, way, bike) {
	if (typeof side === 'string') {
		side = (side === 'true');
	}

	var path = this.pedestrianSidestreetPaths[side][entranceDistance][way];

	if (!path) {
		console.log("==== WTF!!! ====");
		console.log(this.pedestrianSidestreetPaths);
		console.log(side);
		console.log(this.pedestrianSidestreetPaths[side]);
		console.log(entranceDistance);
		console.log(this.pedestrianSidestreetPaths[side][entranceDistance]);
		console.log(way);
		console.log(this.pedestrianSidestreetPaths[side][entranceDistance][way]);
	}
	return getPositionAtOffset(path, distance, 1, 0);
}

Street.prototype.getOnZebraPathLength = function(side, entrance, way) {
	return this.pedestrianSidestreetPaths[side][entrance][way].length;
}

Street.prototype.getPositionAtEntrancePath = function(side, entranceDistance, crossingPath, distance) {

	try {
		var curPath = this.sideStreets[side][entranceDistance].paths[crossingPath].path;
		var newDistance = (distance < 0) ? 0 : distance;
		newDistance = (distance > curPath.length) ? curPath.length : distance;
		var loc = curPath.getLocationAt(newDistance);
	} catch (err) {
		console.log(side);
		console.log(entranceDistance);
		console.log(crossingPath);
		console.log(distance);
		//console.log(this.sideStreets[side][entranceDistance].paths[crossingPath]);
		console.log("BOOM!");
		var errSideStreet = this.sideStreets[side][entranceDistance];
		if (!doesExists(errSideStreet)) {
			throw "ENTRANCE_STREET_NOT_FOUND: La strada di ingresso al metro " + entranceDistance + " nel lato " + side + " della strada " + this.id + " non esiste";
		}
		var curPath = errSideStreet.paths[crossingPath];
		if (!doesExists(curPath)) {
			throw "ENTRANCE_PATH_NOT_FOUND: La traiettoria di ingresso " + crossingPath + " al metro " + entranceDistance + " nel lato " + side + " della strada " + this.id + " non esiste";
		}
		console.log(loc);
		console.log(err);

		if (!doesExists(loc)) {
			console.log(curPath);
			throw "ENTRANCE_PATH_TOO_LONG: Spostamento su traiettoria di ingresso della strada " + this.id + " al metro " + distance + " di " + curPath.path.length + " (traiettoria " + crossingPath + ", lato " + side + ", distanza ingresso: " + entranceDistance + ")";
		}
		throw err;
	}
	return {
		angle: loc.tangent.angle,
		position: loc.point
	};
}

Street.prototype.getEntrancePathLength = function(side, entranceDistance, crossingPath) {
	return this.sideStreets[side][entranceDistance].paths[crossingPath].path.length;
}

Street.prototype.getSidestreetPositionAt = function(distance, side) {
	var offset = this.nLanes * this.laneWidth + this.pavementWidth;
	return this.getPositionAtOffset(distance, side, offset);
}

Street.prototype.getOvertakingPath = function(startPosition, side, fromLane, toLane, moveLength) {
	var p1 = this.getPositionAt(startPosition, side, fromLane).position;
	var hp1 = this.getPositionAt(startPosition + 0.5 * moveLength, side, fromLane).position;
	var p2 = this.getPositionAt(startPosition + moveLength, side, toLane).position;
	var hp2 = this.getPositionAt(startPosition + 0.5 * moveLength, side, toLane).position;

	var p = new Path(p1, p2);
	p.firstSegment.handleOut = hp1.subtract(p1);
	p.firstSegment.handleOut.length = 0.5 * moveLength;
	p.lastSegment.handleIn = hp2.subtract(p2);
	p.lastSegment.handleIn.length = 0.5 * moveLength;
	p.visible = false;
	return p;
}

Street.prototype.getOvertakingPathLength = function(startPosition, side, fromLane, toLane, moveLength) {
	return this.getOvertakingPath(startPosition, side, fromLane, toLane, moveLength).length;
}



/**
 *
 *	Crossroad class
 *
 **/

function Crossroad(obj, map, designMode) {
	this.designMode = designMode !== 'undefined' ? designMode : false;

	this.map = map;

	this.id = obj.id;
	this.streetsRef = obj.strade.slice();
	this.streetsMap = {};
	this.lanesNumber = [2, 2];
	this.streets = [];
	this.center = null;
	this.angle = obj.angolo ? obj.angolo : 0;
	this.pedestrian = null;
	this.firstEntrance = 1;
	this.group = new Group();
	this.trafficLights = {};
	this.pedestrianPaths = [];
	this.crossingPaths = {};
	if ("strada_mancante" in obj) {
		this.streetsRef.splice(obj.strada_mancante, 0, null);
	}
}

/**
 *	Links the streets to the crossroad
 * 	
 **/
Crossroad.prototype.linkStreets = function(streets, district) {
	var firstIn = null;
	var polo = true;
	var entr = 1;
	for (var i = 0; i < this.streetsRef.length; i++) {
		entr++;
		if (this.streetsRef[i] != null) {
			var tmpStreet = null;
			if (this.streetsRef[i].quartiere == district) {
				tmpStreet = streets[this.streetsRef[i].id_strada];
			}
			this.streets[i] = tmpStreet;

			if (firstIn == null && tmpStreet != null) {
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

	if (polo) {
		this.center = new Point(firstIn.from[0], firstIn.from[1]);
		//tmpHandle = firstIn.guidingPath.firstSegment.handleOut;
		//this.angle = (firstIn.guidingPath.segments[1].point.subtract(firstIn.guidingPath.segments[0].point)).angle;
	} else {
		this.center = new Point(firstIn.to[0], firstIn.to[1]);
		//tmpHandle = firstIn.guidingPath.lastSegment.handleIn;
		//var len = firstIn.guidingPath.segments.length;
		//this.angle = (firstIn.guidingPath.segments[len-1].point.subtract(firstIn.guidingPath.segments[len-2].point)).angle;
	}
}

Crossroad.prototype.draw = function(style) {
	delete this.group;
	this.group = new Group();
	this.pedestrianPaths = [];
	var totalWidth = this.lanesNumber[0] * style.laneWidth + style.pavementWidth;
	var totalHeight = this.lanesNumber[1] * style.laneWidth + style.pavementWidth;
	var startP = new Point(this.center.x - totalWidth, this.center.y - totalHeight);

	if (true) {
		this.label = new PointText(this.center);
		this.label.content = this.id;
	}
	var path = new Path.Rectangle(startP, new Size(totalWidth * 2, totalHeight * 2));
	path.fillColor = style.laneColor;

	this.group.addChild(path);

	var poleMap = {
		true: 'firstSegment',
		false: 'lastSegment'
	};
	this.pedestrianPaths[-1] = {};

	for (var i = 0; i < this.streetsRef.length; i++) {
		var g = new Group();
		var st = {
			color: style.lineColor,
			width: style.pavementWidth,
			dash: style.zebraDash
		};
		var ped = style.pavementWidth / 2;
		var pedOffset = 0;

		// creating the pedestrian paths to move the people
		var pP = new Path();
		pP.add(new Point(
			(path.position.x - this.lanesNumber[i % 2] * style.laneWidth - 0.5 * style.pavementWidth), (path.position.y - this.lanesNumber[(i + 1) % 2] * style.laneWidth - ped)
		));
		pP.add(new Point(
			(path.position.x + this.lanesNumber[i % 2] * style.laneWidth + 0.5 * style.pavementWidth), (path.position.y - this.lanesNumber[(i + 1) % 2] * style.laneWidth - ped)
		));
		//this.pedestrianPaths[i] = pP;
		//pP.selected = true;

		// creating the path that cross the crossroad

		var p = new Path();
		g.addChild(p);

		var pedP = new Path();
		var bikeP = new Path();



		this.crossingPaths[i] = {};
		this.pedestrianPaths[i] = {};

		if (this.streetsRef[i] == null) {
			// if there is no street we draw the middle line

			pedOffset = style.pavementWidth;
			st.dash = style.pavementMiddleDash;
			st.width = style.lineWidth / 2;
			this.crossingPaths[i] = null;

			// and the pavement
			var pav = new Path();
			pav.add(new Point(
				(path.position.x - this.lanesNumber[i % 2] * style.laneWidth), (path.position.y - this.lanesNumber[(i + 1) % 2] * style.laneWidth)
			));
			pav.add(new Point(
				(path.position.x + this.lanesNumber[i % 2] * style.laneWidth), (path.position.y - this.lanesNumber[(i + 1) % 2] * style.laneWidth)
			));
			pav.strokeWidth = style.lineWidth;
			pav.strokeColor = style.lineColor;

			g.addChild(pav);

		} else {
			// otherwise we draw the zebra crossing (it is the defaul so no need to customize the style)
			// but we draw the traffic lights and the cross trajectors

			// paths that leads to the other side of the crossroad
			var debgArr = []
				// creating the path that turns left
			if (this.streetsRef[(i + 1) % 4] != null) {
				var crossPath = new Path();
				crossPath.add(new Point(this.center.x - style.laneWidth * 0.5, this.center.y - (style.laneWidth * 2 + style.pavementWidth)));
				crossPath.add(new Point(this.center.x + (style.laneWidth * 2 + style.pavementWidth), this.center.y + style.laneWidth * 0.5));
				var handlePoint = new Point(this.center.x - style.laneWidth * 0.5, this.center.y + style.laneWidth * 0.5);
				crossPath.firstSegment.handleOut = handlePoint.subtract(crossPath.firstSegment.point);
				crossPath.firstSegment.handleOut.length = crossPath.firstSegment.handleOut.length * 0.60;
				crossPath.lastSegment.handleIn = handlePoint.subtract(crossPath.lastSegment.point);
				crossPath.lastSegment.handleIn.length = crossPath.lastSegment.handleIn.length * 0.60;
				crossPath.visible = false;

				if (i == 2 && showTraiettorieAuto) {
					drawPath(crossPath, 'yellow').fullySelected = true;
				}

				this.crossingPaths[i]['sinistra'] = {
					path: crossPath,
					id: this.id + "_s" + this.streetsRef[i].id_strada + ".l" + 2 + "-" + "s" + this.streetsRef[(i + 1) % 4].id_strada + ".l" + 2,
					start: {
						street: this.streetsRef[i].id_strada,
						lane: 2,
						index: i
					},
					end: {
						street: this.streetsRef[(i + 1) % 4].id_strada,
						lane: 2,
						index: (i + 1) % 4
					},
				};
				//this.crossingPaths[this.id+"_s"+this.streetsRef[i].id_strada+".l"+2+"-"+"s"+this.streetsRef[(i+1)%4].id_strada+".l"+2] = crossPath;
				g.addChild(crossPath);

				if (this.designMode && !this.map.traiettorie.traiettorie_incrocio.sinistra.intersezione_bipedi) {
					controllo_sinistra = crossPath;
					var ii = i + 1;
					var cc = new Path();
					cc.add(new Point(
						(path.position.x - this.lanesNumber[ii % 2] * style.laneWidth), (path.position.y - this.lanesNumber[(ii + 1) % 2] * style.laneWidth)
					));
					cc.add(new Point(
						(path.position.x + this.lanesNumber[ii % 2] * style.laneWidth), (path.position.y - this.lanesNumber[(ii + 1) % 2] * style.laneWidth)
					));
					//cc.selected = true;
					var intr = crossPath.getIntersections(cc)[0];
					if (intr != null) {
						this.map.traiettorie.traiettorie_incrocio.sinistra.intersezione_bipedi = controllo_sinistra.getOffsetOf(intr.point)
					};
					g.addChild(cc);
				}

				debgArr.push(crossPath);
			}
			// creating the paths that go straight through the crossroad
			if (this.streetsRef[(i + 2) % 4] != null) {
				var crossPath1 = new Path();
				crossPath1.add(new Point(this.center.x - style.laneWidth * 0.5, this.center.y - (style.laneWidth * 2 + style.pavementWidth)));
				crossPath1.add(new Point(this.center.x - style.laneWidth * 0.5, this.center.y + (style.laneWidth * 2 + style.pavementWidth)));
				this.crossingPaths[i]['dritto_1'] = {
					path: crossPath1,
					id: this.id + "_s" + this.streetsRef[i].id_strada + ".l" + 1 + "-" + "s" + this.streetsRef[(i + 2) % 4].id_strada + ".l" + 1,
					start: {
						street: this.streetsRef[i].id_strada,
						lane: 1,
						index: i
					},
					end: {
						street: this.streetsRef[(i + 2) % 4].id_strada,
						lane: 1,
						index: (i + 2) % 4
					},
				};
				crossPath1.visible = false;
				//this.crossingPaths[this.id+"_s"+this.streetsRef[i].id_strada+".l"+1+"-"+"s"+this.streetsRef[(i+2)%4].id_strada+".l"+1] = crossPath1;
				var crossPath2 = new Path();
				crossPath2.add(new Point(this.center.x - style.laneWidth * 1.5, this.center.y - (style.laneWidth * 2 + style.pavementWidth)));
				crossPath2.add(new Point(this.center.x - style.laneWidth * 1.5, this.center.y + (style.laneWidth * 2 + style.pavementWidth)));
				this.crossingPaths[i]['dritto_2'] = {
					path: crossPath2,
					id: this.id + "_s" + this.streetsRef[i].id_strada + ".l" + 2 + "-" + "s" + this.streetsRef[(i + 2) % 4].id_strada + ".l" + 2,
					start: {
						street: this.streetsRef[i].id_strada,
						lane: 2,
						index: i
					},
					end: {
						street: this.streetsRef[(i + 2) % 4].id_strada,
						lane: 2,
						index: (i + 2) % 4
					},
				};
				crossPath2.visible = false;
				//this.crossingPaths[this.id+"_s"+this.streetsRef[i].id_strada+".l"+2+"-"+"s"+this.streetsRef[(i+2)%4].id_strada+".l"+2] = crossPath2;
				g.addChild(crossPath1);
				g.addChild(crossPath2);

				if (i == 2 && showTraiettorieAuto) {
					drawPath(crossPath1, 'red');
					drawPath(crossPath2, 'blue');
				}

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
			if (this.streetsRef[(i + 3) % 4] != null) {
				var crossPath = new Path();
				crossPath.add(new Point(this.center.x - style.laneWidth * 1.5, this.center.y - (style.laneWidth * 2 + style.pavementWidth)));
				crossPath.add(new Point(this.center.x - (style.laneWidth * 2 + style.pavementWidth), this.center.y - style.laneWidth * 1.5));
				var handlePoint = new Point(this.center.x - style.laneWidth * 1.5, this.center.y - style.laneWidth * 1.5);
				crossPath.firstSegment.handleOut = handlePoint.subtract(crossPath.firstSegment.point);
				crossPath.lastSegment.handleIn = handlePoint.subtract(crossPath.lastSegment.point);
				this.crossingPaths[i]['destra'] = {
					path: crossPath,
					id: this.id + "_s" + this.streetsRef[i].id_strada + ".l" + 1 + "-" + "s" + this.streetsRef[(i + 3) % 4].id_strada + ".l" + 1,
					start: {
						street: this.streetsRef[i].id_strada,
						lane: 1,
						index: i
					},
					end: {
						street: this.streetsRef[(i + 3) % 4].id_strada,
						lane: 1,
						index: (i + 3) % 4
					},
				};
				crossPath.visible = false;
				//this.crossingPaths[this.id+"_s"+this.streetsRef[i].id_strada+".l"+1+"-"+"s"+this.streetsRef[(i+3)%4].id_strada+".l"+1] = crossPath;
				g.addChild(crossPath);

				if (i == 2 && showTraiettorieAuto) {
					drawPath(crossPath, 'green');
				}

				if (this.designMode && !this.map.traiettorie.traiettorie_incrocio.destra.intersezione_bipedi) {
					controllo_destra = crossPath;
					var ii = i - 1;
					var cc = new Path();
					cc.add(new Point(
						(path.position.x - this.lanesNumber[ii % 2] * style.laneWidth), (path.position.y - this.lanesNumber[(ii + 1) % 2] * style.laneWidth)
					));
					cc.add(new Point(
						(path.position.x + this.lanesNumber[ii % 2] * style.laneWidth), (path.position.y - this.lanesNumber[(ii + 1) % 2] * style.laneWidth)
					));
					//cc.selected = true;

					var intr = crossPath.getIntersections(cc)[0];
					if (intr != null) {
						this.map.traiettorie.traiettorie_incrocio.destra.intersezione_bipedi = controllo_destra.getOffsetOf(intr.point)
					};
					g.addChild(cc);
				}
			}

			// creating the pedestrian paths that goes right
			var pedPD = new Path();
			pedPD.add(new Point(
				(path.position.x - this.lanesNumber[i % 2] * style.laneWidth - 0.75 * style.pavementWidth), (path.position.y - this.lanesNumber[(i + 1) % 2] * style.laneWidth - style.pavementWidth)
			));
			pedPD.add(new Point(
				(path.position.x - this.lanesNumber[i % 2] * style.laneWidth - style.pavementWidth), (path.position.y - this.lanesNumber[(i + 1) % 2] * style.laneWidth - 0.75 * style.pavementWidth)
			));
			pedPD.visible = false;
			setPathHandles(pedPD, -1);


			var bikePD = new Path();
			bikePD.add(new Point(
				(path.position.x - this.lanesNumber[i % 2] * style.laneWidth - 0.25 * style.pavementWidth), (path.position.y - this.lanesNumber[(i + 1) % 2] * style.laneWidth - style.pavementWidth)
			));
			bikePD.add(new Point(
				(path.position.x - this.lanesNumber[i % 2] * style.laneWidth - style.pavementWidth), (path.position.y - this.lanesNumber[(i + 1) % 2] * style.laneWidth - 0.25 * style.pavementWidth)
			));
			bikePD.visible = false;
			setPathHandles(bikePD, -1);

			if (showTraiettoriePedoni) {
				drawPath(pedPD, 'orange', pathWidth);
				drawPath(bikePD, 'orange', pathWidth, [pathWidth, pathWidth]);
				console.log("Traiettorie di " + i);
				console.log("lunghezza pedoni destra: " + pedPD.length);
				console.log("lunghezza bici destra: " + bikePD.length);
			}

			if (!lunghezza_traiettorie_incroci['pedoni']['destra_pedoni'])
				lunghezza_traiettorie_incroci['pedoni']['destra_pedoni'] = pedPD.length;

			if (!lunghezza_traiettorie_incroci['pedoni']['destra_bici'])
				lunghezza_traiettorie_incroci['pedoni']['destra_bici'] = bikePD.length;

			this.pedestrianPaths[i].destra_pedoni = pedPD;
			this.pedestrianPaths[i].destra_bici = bikePD;

			g.addChild(pedPD);
			g.addChild(bikePD);


			debgArr.push(crossPath);
			
			if (style.debug) {
				for (var dI in debgArr) {
					debgArr[dI].fullySelected = true;
					//debgArr[dI].strokeColor = 'green';
					//debgArr[dI].strokeWidth = 0.2;
				}
			}

			this.trafficLights[i] = [];
			for (var a = 0; a < this.lanesNumber[i % 2]; a++) {
				var tc = new Point(
					(path.position.x + (-this.lanesNumber[i % 2] + 0.5 + (a % 4)) * style.laneWidth), (path.position.y - (this.lanesNumber[(i + 1) % 2] + 1) * style.laneWidth)
				);
				var t = new TrafficLight(
					(((i % 2) == 0) ? true : false),
					tc,
					style,
					2000
				);
				this.trafficLights[i][a] = t;
				g.addChild(t.path);
			}

		}
		p.add(new Point(
			(path.position.x - this.lanesNumber[i % 2] * style.laneWidth - pedOffset), (path.position.y - this.lanesNumber[(i + 1) % 2] * style.laneWidth - ped)
		));
		p.add(new Point(
			(path.position.x + this.lanesNumber[i % 2] * style.laneWidth + pedOffset), (path.position.y - this.lanesNumber[(i + 1) % 2] * style.laneWidth - ped)
		));

		p.strokeColor = st.color;
		p.strokeWidth = st.width;
		p.dashArray = st.dash;
		p.sendToBack();

		var l = 1;
		// drawing the path for the pedestrians
		if (this.streetsRef[(i + 3) % 4] != null) {
			// if the street on the right exists, we make a short path	
			l = 0;
		}

		pedP.add(new Point(
			(path.position.x - this.lanesNumber[i % 2] * style.laneWidth - 0.75 * style.pavementWidth), (path.position.y - this.lanesNumber[(i + 1) % 2] * style.laneWidth - style.pavementWidth)
		));
		pedP.add(new Point(
			(path.position.x - this.lanesNumber[i % 2] * style.laneWidth - 0.75 * style.pavementWidth), (path.position.y + this.lanesNumber[(i + 1) % 2] * style.laneWidth + l * style.pavementWidth)
		));

		bikeP.add(new Point(
			(path.position.x - this.lanesNumber[i % 2] * style.laneWidth - 0.25 * style.pavementWidth), (path.position.y - this.lanesNumber[(i + 1) % 2] * style.laneWidth - style.pavementWidth)
		));
		bikeP.add(new Point(
			(path.position.x - this.lanesNumber[i % 2] * style.laneWidth - 0.25 * style.pavementWidth), (path.position.y + this.lanesNumber[(i + 1) % 2] * style.laneWidth + l * style.pavementWidth)
		));

		pedP.visible = false;
		bikeP.visible = false;
		//setPathHandles(bikeP,1);

		if (showTraiettoriePedoni) {
			drawPath(pedP, 'green', pathWidth);
			drawPath(bikeP, 'green', pathWidth, [pathWidth, pathWidth]);
			console.log("lunghezza pedoni dritto: " + pedP.length);
			console.log("lunghezza bici dritto: " + bikeP.length);
		}

		var idx = (this.streetsRef[i] != null) ? i : -1;
		this.pedestrianPaths[idx].dritto_pedoni = pedP;
		this.pedestrianPaths[idx].dritto_bici = bikeP;

		g.addChild(pedP);
		g.addChild(bikeP);

		if (!lunghezza_traiettorie_incroci['pedoni']['dritto_pedoni'])
			lunghezza_traiettorie_incroci['pedoni']['dritto_pedoni'] = pedP.length;

		if (!lunghezza_traiettorie_incroci['pedoni']['dritto_bici'])
			lunghezza_traiettorie_incroci['pedoni']['dritto_bici'] = bikeP.length;


		g.rotate(90 * (i % 4), path.position);
		pP.rotate(90 * (i % 4), path.position);
		this.group.addChild(g);


	} // END FOR

	this.group.rotate(this.angle % 90);

	// adjusting the streets
	for (var i = 0; i < this.streets.length; i++) {
		if (this.streets[i] != null) {
			var newPoint = new Point(
				(path.segments[(i + 1) % 4].point.x + path.segments[(i + 2) % 4].point.x) / 2, (path.segments[(i + 1) % 4].point.y + path.segments[(i + 2) % 4].point.y) / 2
			);
			this.streets[i].adjustCrossroadLink(newPoint, this.streetsRef[i].polo, this.center);
		}
	}
}

Crossroad.prototype.getEntranceStreetNumber = function(streetId, district) {
	//console.log("asking to crossroad "+this.id+" street "+streetId+" form district "+district);
	var toRet = null;
	
	for (var i = 0; i < this.streetsRef.length; i++) {
		if (this.streetsRef[i] != null && streetId == this.streetsRef[i].id_strada && district == this.streetsRef[i].quartiere) {
			return i;
		}
	}
	//	console.log("streetId: "+streetId+" district:"+district+" resolved:"+toRet);
	//console.log(this);
	return toRet;
}

Crossroad.prototype.getPedestrianPathStreetNumber = function(streetId, district) {
	//console.log("asking to crossroad "+this.id+" street "+streetId+" form district "+district);
	var i;
	var toRet = null;
	if (streetId == 0 && district == 0) {
		toRet = -1;
	} else {
		for (i = 0; i < this.streetsRef.length; i++) {
			if (this.streetsRef[i] != null && streetId == this.streetsRef[i].id_strada && district == this.streetsRef[i].quartiere) {
				return i;
			}
		}
	}
	//	console.log("streetId: "+streetId+" district:"+district+" resolved:"+toRet);
	//console.log(this);
	return toRet;
}

Crossroad.prototype.getCrossingPath = function(enteringStreet, streetDistrict, direction) {
	return this.crossingPaths[this.getEntranceStreetNumber(enteringStreet, streetDistrict)][direction].path;
}

Crossroad.prototype.getCrossingPathLength = function(enteringStreet, streetDistrict, direction) {
	return this.getCrossingPath(enteringStreet, streetDistrict, direction).length;
}

Crossroad.prototype.getPositionAt = function(distance, enteringStreet, streetDistrict, direction) {
	var toRet = {
		angle: null,
		position: null
	};
	try {
		var loc = this.crossingPaths[this.getEntranceStreetNumber(enteringStreet, streetDistrict)][direction].path.getLocationAt(distance);
		toRet = {
			angle: loc.tangent.angle,
			position: loc.point
		};
	} catch (err) {
		console.log("ID entrance street: " + this.getEntranceStreetNumber(enteringStreet, streetDistrict));
		console.log(this.crossingPaths[this.getEntranceStreetNumber(enteringStreet, streetDistrict)])
		console.log("Going " + direction);
		if (!doesExists(this.getEntranceStreetNumber(enteringStreet, streetDistrict))) {
			throw "CROSSROAD_SREET_NOT_FOUND: L'incrocio " + this.id + " non ha la strada " + enteringStreet + " proveniente dal distretto " + streetDistrict;
		} else if (!doesExists(this.crossingPaths[this.getEntranceStreetNumber(enteringStreet, streetDistrict)][direction])) {
			throw "CROSSROAD_PATH_NOT_FOUND: L'incrocio " + this.id + " non ha la traiettoria " + direction + " a partire dalla strada " + enteringStreet + " del quartiere " + streetDistrict;
		} else if (!doesExists(loc)) {
			throw "CROSSROAD_PATH_TOO_LONG: Spostamento sulla traiettoria " + direction + " dell'incrocio " + this.id + " a partire dalla strada " + enteringStreet + " del quartiere " + streetDistrict + " al metro " + distance + " di " + this.crossingPaths[this.getEntranceStreetNumber(enteringStreet, streetDistrict)][direction].path.length;
		} else {
			throw "WTF_IS_IT_I_DUNNO: Spostamento sulla traiettoria " + direction + " dell'incrocio " + this.id + " a partire dalla strada " + enteringStreet + " del quartiere " + streetDistrict + " al metro " + distance + " di " + this.crossingPaths[this.getEntranceStreetNumber(enteringStreet, streetDistrict)][direction].path.length;
		}
	}
	return toRet;
}

Crossroad.prototype.getPositionOnPedestrianPath = function(distance, enteringStreet, streetDistrict, direction) {
	var num = -1;
	if (enteringStreet != 0 && streetDistrict != 0) {
		num = this.getPedestrianPathStreetNumber(enteringStreet, streetDistrict);
	}

	var path = this.pedestrianPaths[num][direction];
	if (path == null) {
		console.log("streetId: " + enteringStreet + " district:" + streetDistrict + " resolved:" + num + " direction: " + direction);
		console.log(this);
	}
	if (distance > path.length) distance = path.length;
	if (distance < 0) distance = 0;

	var loc = path.getLocationAt(distance);
	return {
		angle: loc.tangent.angle,
		position: loc.point
	};
}

Crossroad.prototype.getPedestrianPathLength = function(enteringStreet, streetDistrict, direction) {
	var num = this.getPedestrianPathStreetNumber(enteringStreet, streetDistrict);
	if(!this.pedestrianPaths[num])
	{
		console.log("GET PEDESTRIAN PATH LENGTH > Exception incoming ^^^^^^^^^^^^^^^^^^");
		console.log("the this:");
		console.log(this);
		console.log("enteringStreet:");
		console.log(enteringStreet);
		console.log("streetDistrict:");
		console.log(streetDistrict);
		console.log("direction:");
		console.log(direction);
		console.log("num:");
		console.log(num);
		console.log("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
	}
	return this.pedestrianPaths[num][direction].length;
}

Crossroad.prototype.switchTrafficLights = function() {
	for (var i in this.trafficLights) {
		this.trafficLights[i].switchState();
	}
}

Crossroad.prototype.bringTrafficLightsToFront = function() {
	for (var i in this.trafficLights) {
		for (var j in this.trafficLights[i]) {
			this.trafficLights[i][j].path.bringToFront();
		}
	}
}

function TrafficLight(state, position, style, yellowDelay) {
	this.state = state ? 'green' : 'red';
	this.yellowDelay = yellowDelay;
	this.path = new Path.Circle(position, ((style.laneWidth / 2) - 2));
	this.path.fillColor = this.state;
	this.path.strokeColor = 'black';
	this.path.strokeWidth = style.lineWidth;
}

TrafficLight.prototype.switchState = function() {
	if (this.state == 'green') {
		this.state = 'yellow';
		this.path.fillColor = this.state;
		setTimeout(setTrafficLight, this.yellowDelay, this, 'red');
	} else {
		setTimeout(setTrafficLight, this.yellowDelay, this, 'green');
	}
}

TrafficLight.prototype.setGreen = function() {
	setTrafficLight(this, 'green');
}

TrafficLight.prototype.setRed = function() {
	setTrafficLight(this, 'red');
}

TrafficLight.prototype.setColor = function(color) {
	setTrafficLight(this, color);
}

function setTrafficLight(tl, state) {
	tl.state = state;
	tl.path.fillColor = tl.state;
	//tl.path.view.draw();
}

/**
 *
 *	Place class
 *
 **/
function Place(obj, map, designMode) {
	this.designMode = designMode !== 'undefined' ? designMode : false;

	this.map = map;

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

	var tmpPoint = new Point(0, 0);
	this.nameLabel = new PointText(tmpPoint);
	this.nameLabel.justification = 'center';
	this.nameLabel.visible = false
	this.carsLabel = new PointText(tmpPoint);
	this.carsLabel.visible = false;
	this.peopleLabel = new PointText(tmpPoint);
	this.peopleLabel.visible = false;
	this.bikesLabel = new PointText(tmpPoint);
	this.bikesLabel.visible = false;

	Object.defineProperty(this, "currentCars", {
		get: function() {
			return this._curCar;
		},
		set: function(v) {
			this._curCars = v;
			this.carsLabel.content = "C: " + v + "/" + this.maxCars;
			this.carsLabel.justification = 'left';
		}
	});

	Object.defineProperty(this, "currentPeople", {
		get: function() {
			return this._curPeople;
		},
		set: function(v) {
			this._curPeople = v;
			this.peopleLabel.content = "P: " + v + "/" + this.maxPeople;
			this.peopleLabel.justification = 'left';
		}
	});

	Object.defineProperty(this, "currentBikes", {
		get: function() {
			return this._curBikes;
		},
		set: function(v) {
			this._curBikes = v;
			this.bikesLabel.content = "B: " + v + "/" + this.maxBikes;
			this.bikesLabel.justification = 'left';
		}
	});
}

Place.prototype.setEnteringStreet = function(street) {
	this.entranceStreet = street;
}

Place.prototype.draw = function(style) {
	var placePosition = new Point();
	placePosition.length = this.placeHeight / 2;
	placePosition.angle = this.entranceStreet.guidingPath.firstSegment.point.subtract(this.entranceStreet.guidingPath.lastSegment.point).angle;
	placePosition = this.entranceStreet.guidingPath.firstSegment.point.add(placePosition);
	var center = this.entranceStreet.guidingPath.firstSegment.point;
	// center = center.add(new Point(0, this.placeHeight));
	//var center = this.entranceStreet.guidingPath.lastSegment.point.subtract(this.entranceStreet.guidingPath.firstSegment.point);
	//center.length = this.placeHeight;
	var angle = (center.subtract(this.entranceStreet.guidingPath.lastSegment.point)).angle + 90;

	var placePath = new Path.Rectangle(new Point(), new Size(this.placeWidth, this.placeHeight));
	placePath.strokeWidth = 1;
	placePath.strokeColor = 'grey';
	placePath.fillColor = 'white';
	placePath.position = placePosition;
	//placePath.rotate(placePosition.angle);
	//placePath.position = center;
	placePath.rotate(angle);

	var startPoint = new Point(placePosition.x, placePosition.y - (this.placeHeight / 2) - 7);
	this.nameLabel.position = startPoint;
	this.nameLabel.content = this.placeName;
	this.nameLabel.visible = true;

	/*
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
		*/
}

/**
 *
 *	Map class
 *
 **/
function Map(designMode) {
	this.designMode = designMode !== 'undefined' ? designMode : false;
	this.streets = {};
	this.entranceStreets = {};
	this.crossroads = {};
	this.pavements = {};
	this.places = {};
	this.mapStyle = new MapStyle();

	// callbacks
	this.onStartDrawing = null;
	this.onFinishDrawing = null;
	this.onStartLoading = null;
	this.onFinishLoading = null;
	this.onMapReady = null;
	this.onLoadingError = null;
	this.onDrawingError = null;

	this.loadingProgressNotifier = null;

	this.lunghezza_traiettorie_ingressi = {};
	this.lunghezza_traiettorie_incroci = {
		'pedoni': {},
		'auto': {}
	};
	this.traiettorie = {
		'cambio_corsia': {},
		'traiettorie_incrocio': {
			'sinistra': {},
			'destra': {}
		},
		'traiettorie_ingresso': {}
	};
	this.path_traiettorie = {
		'cambio_corsia': {},
		'traiettorie_incrocio': {},
		'traiettorie_ingresso': {}
	};
}


Map.prototype.setTraiettorie = function(obj) {
	return this.traiettorie = obj;
}

Map.prototype.getCrossroads = function() {
	return this.crossroads;
}

Map.prototype.setStyle = function(newStyle) {
	this.mapStyle = newStyle;
}

Map.prototype.setProgressNotifier = function(fun) {
	this.loadingProgressNotifier = fun;
}

Map.prototype.resetData = function() {
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

Map.prototype.asyncLoad = function(obj) {
	//console.log(obj);
	//for (var i = 0; i < obj.strade.length; i++) {
	var myController = {
		init: function(This, obj, next) {
			try{
				if (typeof This.onStartLoading === 'function') {
					This.onStartLoading();
				}

				This.resetData();
				This.objData = obj;
				This.id = This.objData.info.id;
				if (typeof This.loadingProgressNotifier === 'function') {
					This.loadingProgressNotifier("strade", 20);
				}
				setTimeout(next, 100);
			} catch(e) {
				if (typeof This.onLoadingError === 'function') {
					This.onLoadingError(e);
				}
			}
		},
		loadStreets: function(This, next) {
			try{
				for (var i in This.objData.strade_urbane) {
					This.streets[This.objData.strade_urbane[i].id] = new Street(This.objData.strade_urbane[i], This, This.designMode);
				}

				if (typeof This.loadingProgressNotifier === 'function') {
					This.loadingProgressNotifier("incroci", 40);
				}
				setTimeout(next, 100);
			} catch(e) {
				if (typeof This.onLoadingError === 'function') {
					This.onLoadingError(e);
				}
			}
		},
		loadCrossroads: function(This, next) {
			try{
				for (var i = 0; i < This.objData.incroci_a_4.length; i++) {
					var cur_inc = This.objData.incroci_a_4[i];
					var c = new Crossroad(cur_inc, This, This.designMode);
					c.linkStreets(This.streets, This.id);
					This.crossroads[cur_inc.id] = c;
				}
				for (var i in This.objData.incroci_a_3) {
					//This.objData.incroci_a_3[i].strade.splice(This.objData.incroci_a_3[i].strada_mancante,0,null);
					var cur_inc = This.objData.incroci_a_3[i];
					var c = new Crossroad(cur_inc, This, This.designMode);
					c.linkStreets(This.streets, This.id);
					This.crossroads[cur_inc.id] = c;
				}
				//for(var i = 0; i < This.objData.strade_ingresso.length; i++){

				if (typeof This.loadingProgressNotifier === 'function') {
					This.loadingProgressNotifier("strade ingresso", 60);
				}
				setTimeout(next, 100);
			} catch(e) {
				if (typeof This.onLoadingError === 'function') {
					This.onLoadingError(e);
				}
			}
		},
		loadEntranceStreets: function(This, next) {
			try{
				for (var i in This.objData.strade_ingresso) {
					This.objData.strade_ingresso[i]['from'] = 0;
					This.objData.strade_ingresso[i]['to'] = 0;
					var str = new Street(This.objData.strade_ingresso[i], This, This.designMode);
					str.mainStreet = This.objData.strade_ingresso[i].strada_confinante;
					str.mainStreetObj = This.streets[str.mainStreet];
					str.entranceSide = This.objData.strade_ingresso[i].polo;
					str.entranceDistance = This.objData.strade_ingresso[i].distanza_da_from;
					str.setType('entrance');
					This.entranceStreets[str.id] = str;
					This.streets[str.mainStreet].addSideStreet(str);
				}

				if (typeof This.loadingProgressNotifier === 'function') {
					This.loadingProgressNotifier("luoghi", 80);
				}

				setTimeout(next, 100);
			} catch(e) {
				if (typeof This.onLoadingError === 'function') {
					This.onLoadingError(e);
				}
			}
		},
		loadPlaces: function(This, next) {
			try{
				for (var i = 0; i < This.objData.luoghi.length; i++) {
					var p = new Place(This.objData.luoghi[i], This, This.designMode);
					This.places[p.id] = p;
				}

				if (typeof This.loadingProgressNotifier === 'function') {
					This.loadingProgressNotifier("Caricamento completato", 100);
				}

				if (typeof This.onFinishLoading === 'function') {
					This.onFinishLoading();
				}
			} catch(e) {
				if (typeof This.onLoadingError === 'function') {
					This.onLoadingError(e);
				}
			}
		}
	};

	new JSChain(myController).init(this, obj).loadStreets(this).loadCrossroads(this).loadEntranceStreets(this).loadPlaces(this);
}

Map.prototype.load = function(obj) {
	//console.log(obj);
	if (typeof this.onStartLoading === 'function') {
		this.onStartLoading();
	}
	this.resetData();
	this.objData = obj;
	this.id = obj.info.id;
	//for (var i = 0; i < obj.strade.length; i++) {

	if (typeof this.loadingProgressNotifier === 'function') {
		this.loadingProgressNotifier("Loading streets");
	}

	for (var i in obj.strade_urbane) {
		this.streets[obj.strade_urbane[i].id] = new Street(obj.strade_urbane[i], this, this.designMode);
	}


	if (typeof this.loadingProgressNotifier === 'function') {
		this.loadingProgressNotifier("Loading crossroads");
	}

	for (var i = 0; i < obj.incroci_a_4.length; i++) {
		var cur_inc = obj.incroci_a_4[i];
		var c = new Crossroad(cur_inc, this, this.designMode);
		c.linkStreets(this.streets, this.id);
		this.crossroads[cur_inc.id] = c;
	}
	for (var i in obj.incroci_a_3) {
		//obj.incroci_a_3[i].strade.splice(obj.incroci_a_3[i].strada_mancante,0,null);
		var cur_inc = obj.incroci_a_3[i];
		var c = new Crossroad(cur_inc, this, this.designMode);
		c.linkStreets(this.streets, this.id);
		this.crossroads[cur_inc.id] = c;
	}
	//for(var i = 0; i < obj.strade_ingresso.length; i++){

	if (typeof this.loadingProgressNotifier === 'function') {
		this.loadingProgressNotifier("Loading sidestreets");
	}

	for (var i in obj.strade_ingresso) {
		obj.strade_ingresso[i]['from'] = 0;
		obj.strade_ingresso[i]['to'] = 0;
		var str = new Street(obj.strade_ingresso[i], this, this.designMode);
		str.mainStreet = obj.strade_ingresso[i].strada_confinante;
		str.mainStreetObj = this.streets[str.mainStreet];
		str.entranceSide = obj.strade_ingresso[i].polo;
		str.entranceDistance = obj.strade_ingresso[i].distanza_da_from;
		str.setType('entrance');
		this.entranceStreets[str.id] = str;
		this.streets[str.mainStreet].addSideStreet(str);
	}

	if (typeof this.loadingProgressNotifier === 'function') {
		this.loadingProgressNotifier("Loading places");
	}

	for (var i = 0; i < obj.luoghi.length; i++) {
		var p = new Place(obj.luoghi[i], this, this.designMode);
		this.places[p.id] = p;
	}
	if (typeof this.onFinishLoading === 'function') {
		this.onFinishLoading();
	}
}

Map.prototype.draw = function() {
	if (typeof this.onStartDrawing === 'function') {
		this.onStartDrawing();
	}

	if (typeof this.loadingProgressNotifier === 'function') {
		this.loadingProgressNotifier("Drawing crossroads");
	}

	for (var i in this.crossroads) {
		this.crossroads[i].draw(this.mapStyle);
	}

	if (typeof this.loadingProgressNotifier === 'function') {
		this.loadingProgressNotifier("Drawing streets");
	}

	for (var i in this.streets) {
		this.streets[i].draw(this.mapStyle);
	}

	if (typeof this.loadingProgressNotifier === 'function') {
		this.loadingProgressNotifier("Drawing sidestreets");
	}

	for (var i in this.entranceStreets) {

		var curStr = this.entranceStreets[i];

		var mainStreet = this.streets[curStr.mainStreet];
		var side = curStr.entranceSide ? 1 : -1;

		var entrDist = /*(side == 1) ? mainStreet.guidingPath.length - curStr.entranceDistance :*/ curStr.entranceDistance;
		var refPoint = mainStreet.guidingPath.getPointAt(entrDist);
		var normalFrom = mainStreet.guidingPath.getNormalAt(entrDist);
		normalFrom.length = side * (mainStreet.nLanes * this.mapStyle.laneWidth + this.mapStyle.pavementWidth);

		var normalTo = mainStreet.guidingPath.getNormalAt(entrDist);
		normalTo.length = side * (mainStreet.nLanes * this.mapStyle.laneWidth + this.mapStyle.pavementWidth + curStr.len);

		curStr.from = [(refPoint.x + normalTo.x), (refPoint.y + normalTo.y)];
		curStr.to = [(refPoint.x + normalFrom.x), (refPoint.y + normalFrom.y)];
		curStr.reposition();
		curStr.draw(this.mapStyle);
		curStr.drawHorizontalLines(this.mapStyle);
	}

	for (var i in this.streets) {
		this.streets[i].drawHorizontalLines(this.mapStyle);
	}

	if (typeof this.loadingProgressNotifier === 'function') {
		this.loadingProgressNotifier("Drawing places");
	}

	for (var i in this.places) {
		this.places[i].setEnteringStreet(this.entranceStreets[this.places[i].entranceStreetId]);
		if (this.entranceStreets[this.places[i].entranceStreetId] != null)
			this.places[i].draw(this.mapStyle);
	}

	if (typeof this.onFinishDrawing === 'function') {
		this.onFinishDrawing();
	}

	if (typeof this.onMapReady === 'function') {
		this.onMapReady();
	}

	liftPaths();
}

Map.prototype.asyncDraw = function() {

	var myController = {
		init: function(This, next) {
			try{
				if (typeof This.onStartDrawing === 'function') {
					This.onStartDrawing();
				}

				if (typeof This.loadingProgressNotifier === 'function') {
					This.loadingProgressNotifier("incroci", 25);
				}
				setTimeout(next, 100);
			} catch(e) {
				if (typeof This.onDrawingError === 'function') {
					This.onDrawingError(e);
				}
			}
		},
		drawCrossroads: function(This, next) {
			try{
				for (var i in This.crossroads) {
					This.crossroads[i].draw(This.mapStyle);
				}

				if (typeof This.loadingProgressNotifier === 'function') {
					This.loadingProgressNotifier("strade", 50);
				}
				setTimeout(next, 100);
			} catch(e) {
				if (typeof This.onDrawingError === 'function') {
					This.onDrawingError(e);
				}
			}
		},
		drawStreets: function(This, next) {
			try{
				for (var i in This.streets) {
					This.streets[i].draw(This.mapStyle);
				}

				for (var i in This.entranceStreets) {

					var curStr = This.entranceStreets[i];

					var mainStreet = This.streets[curStr.mainStreet];
					var side = curStr.entranceSide ? 1 : -1;

					var entrDist = /*(side == 1) ? mainStreet.guidingPath.length - curStr.entranceDistance :*/ curStr.entranceDistance;
					var refPoint = mainStreet.guidingPath.getPointAt(entrDist);
					var normalFrom = mainStreet.guidingPath.getNormalAt(entrDist);
					normalFrom.length = side * (mainStreet.nLanes * This.mapStyle.laneWidth + This.mapStyle.pavementWidth);

					var normalTo = mainStreet.guidingPath.getNormalAt(entrDist);
					normalTo.length = side * (mainStreet.nLanes * This.mapStyle.laneWidth + This.mapStyle.pavementWidth + curStr.len);

					curStr.from = [(refPoint.x + normalTo.x), (refPoint.y + normalTo.y)];
					curStr.to = [(refPoint.x + normalFrom.x), (refPoint.y + normalFrom.y)];
					curStr.reposition();
					curStr.draw(This.mapStyle);
					curStr.drawHorizontalLines(This.mapStyle);
				}

				for (var i in This.streets) {
					This.streets[i].drawHorizontalLines(This.mapStyle);
				}

				if (typeof This.loadingProgressNotifier === 'function') {
					This.loadingProgressNotifier("luoghi", 75);
				}
				setTimeout(next, 100);
			} catch(e) {
				if (typeof This.onDrawingError === 'function') {
					This.onDrawingError(e);
				}
			}
		},
		drawPlaces: function(This, next) {
			try{
				for (var i in This.places) {
					This.places[i].setEnteringStreet(This.entranceStreets[This.places[i].entranceStreetId]);
					if (This.entranceStreets[This.places[i].entranceStreetId] != null)
						This.places[i].draw(This.mapStyle);
				}

				liftPaths();

				if (typeof This.loadingProgressNotifier === 'function') {
					This.loadingProgressNotifier("Disegno completato", 100);
				}

				if (typeof This.onFinishDrawing === 'function') {
					This.onFinishDrawing();
				}

				if (typeof This.onMapReady === 'function') {
					This.onMapReady();
				}
				setTimeout(next, 100);
			} catch(e) {
				if (typeof This.onDrawingError === 'function') {
					This.onDrawingError(e);
				}
			}
		}
	};

	new JSChain(myController).init(this).drawCrossroads(this).drawStreets(this).drawPlaces(this);
}

Map.prototype.bringTrafficLightsToFront = function() {
	for (var c in this.crossroads) {
		this.crossroads[c].bringTrafficLightsToFront();
	}
}

Map.prototype.getUpdatedData = function() {
	var l = this.objData.strade_urbane.length;
	var i = 0;
	for (var i = 0; i < l; i++) {
		for (var i in this.objData.strade_urbane) {
			this.objData.strade_urbane[i].lunghezza = this.streets[this.objData.strade_urbane[i].id].guidingPath.length;
		}
	}
	return this.objData;
}

Map.prototype.getUpdatedDataAndPaths = function() {
	var l = this.objData.strade_urbane.length;
	var i = 0;
	for (var i = 0; i < l; i++) {
		var enteringPaths = null
		for (var i in this.objData.strade_urbane) {
			this.objData.strade_urbane[i].lunghezza = this.streets[this.objData.strade_urbane[i].id].guidingPath.length;
			var sE = this.streets[this.objData.strade_urbane[i].id].sideStreetsEntrancePaths;
			for (var c in sE) {
				var toAdd = {
						id: sE[c].id,
						principale: sE[c].principale,
						laterale: sE[c].laterale,
						verso: sE[c].verso,
						lunghezza: sE[c].path.length,
					}
					//this.objData.strade_urbane[i].traiettorie_ingresso.push(toAdd);
			}
			delete this.objData.strade_urbane[i].traiettorie_ingresso;
			var sStreets = this.streets[this.objData.strade_urbane[i].id].sideStreets;
			if (enteringPaths == null && (Object.keys(sStreets[false]).length > 0 || Object.keys(sStreets[true]).length > 0)) {
				if (i == 0) {
					i++;
				} else {
					enteringPaths = this.calcEntrancePathIntersections(this.streets[this.objData.strade_urbane[i].id]);
				}
			}
		}
	}
	var toRet = {};
	//toRet['traiettorie_incrocio_a_3'] = this.calcCrossroadsCrossingPathsIntersections(this.objData.incroci_a_3[Object.keys(this.objData.incroci_a_3)[0]]);
	//console.log(this.objData['traiettorie_incrocio_a_3']);
	toRet['traiettorie_incroci'] = {};
	var tmp = this.calcCrossroadsCrossingPathsIntersections(this.objData.incroci_a_4[Object.keys(this.objData.incroci_a_4)[0]]);
	for (idx in tmp) {
		for (idx2 in tmp[idx]) {
			if (!toRet['traiettorie_incroci'][idx2]) {
				toRet['traiettorie_incroci'][idx2] = tmp[idx][idx2];
			}
		}
	}
	toRet['traiettorie_ingresso'] = enteringPaths;
	//this.objData['larghezza_marciapiede'] = this.mapStyle.pavementWidth;
	/*
	for(var i in this.objData.incroci_a_4){
		this.calcCrossroadsCrossingPathsIntersections(this.objData.incroci_a_4[i]);
	}*/
	toRet.dimensioni_incrocio = 2 * (this.mapStyle.pavementWidth + this.mapStyle.laneWidth * 2);
	toRet['map'] = this.objData;
	return toRet;
}

Map.prototype.calcEntrancePathIntersections = function(street) {
	var enteringPaths = null;
	var side = false;
	if (Object.keys(street.sideStreets[false]).length > 0) {
		enteringPaths = street.sideStreets[false][Object.keys(street.sideStreets[false])[0]].paths;
	} else {
		enteringPaths = street.sideStreets[true][Object.keys(street.sideStreets[true])[0]].paths;
		side = true;
	}
	// street.guidingPath.fullySelected = true;
	var uRAdd = null;
	if (lunghezza_traiettorie_ingressi['auto'] && lunghezza_traiettorie_ingressi['auto']['uscita_ritorno']) {
		uRAdd = lunghezza_traiettorie_ingressi['auto']['uscita_ritorno']['intersezione'];
	}
	var toRet = {
		entrata_andata: {
			lunghezza: enteringPaths['entrata_andata'].path.length
		},
		uscita_andata: {
			lunghezza: enteringPaths['uscita_andata'].path.length
		},
		entrata_ritorno: {
			lunghezza: enteringPaths['entrata_ritorno'].path.length,
			intersezioni: [{
				traiettoria: 'uscita_ritorno',
				distanza: enteringPaths['entrata_ritorno'].path.getOffsetOf(enteringPaths['entrata_ritorno'].path.getIntersections(enteringPaths['uscita_ritorno'].path)[0].point),
			}, {
				traiettoria: 'linea_corsia',
				distanza: enteringPaths['entrata_ritorno'].path.getOffsetOf(enteringPaths['entrata_ritorno'].path.getIntersections(street.sepLines[!side][1])[0].point),
			}, {
				traiettoria: 'linea_mezzaria',
				distanza: enteringPaths['entrata_ritorno'].path.getOffsetOf(enteringPaths['entrata_ritorno'].path.getIntersections(street.guidingPath)[0].point),
			}]
		},
		uscita_ritorno: {
			lunghezza: enteringPaths['uscita_ritorno'].path.length,
			intersezioni: [{
					traiettoria: 'entrata_ritorno',
					distanza: enteringPaths['uscita_ritorno'].path.getOffsetOf(enteringPaths['uscita_ritorno'].path.getIntersections(enteringPaths['entrata_ritorno'].path)[0].point),
				}, {
					traiettoria: 'linea_corsia',
					distanza: enteringPaths['uscita_ritorno'].path.getOffsetOf(enteringPaths['uscita_ritorno'].path.getIntersections(street.sepLines[!side][1])[0].point),
				}, {
					traiettoria: 'linea_mezzaria',
					distanza: enteringPaths['uscita_ritorno'].path.getOffsetOf(enteringPaths['uscita_ritorno'].path.getIntersections(street.guidingPath)[0].point),
				},
				uRAdd
			]
		}
	};
	if (lunghezza_traiettorie_ingressi['pedoni']) {
		for (idx in lunghezza_traiettorie_ingressi['pedoni']) {
			toRet[idx] = {
				"lunghezza": lunghezza_traiettorie_ingressi['pedoni'][idx]
			};
		}
	}
	return toRet;
}

Map.prototype.calcCrossroadsCrossingPathsIntersections = function(crossroad_ref) {
	var c = this.crossroads[crossroad_ref.id];
	var traiettorie = {};
	for (var p in c.crossingPaths) {
		var np = parseInt(p);
		traiettorie[np] = {};

		if (c.crossingPaths[p] != null && c.crossingPaths[p].destra) {
			traiettorie[np]['destra'] = makeCPData(c.crossingPaths[p].destra);
			traiettorie[np]['destra']['intersezione_bipedi'] = lunghezza_traiettorie_incroci['auto']['destra']['intersezione_bipedi'];
		}
		if (c.crossingPaths[p] != null && c.crossingPaths[p].sinistra) {
			var cLeft = makeCPData(c.crossingPaths[p].sinistra);
			var eN = (np + 2) % 4;
			if (c.crossingPaths[eN] != null && c.crossingPaths[eN].dritto_1 && c.crossingPaths[eN].dritto_2) {
				var refPath = c.crossingPaths[eN].dritto_1.path;
				var halfLane = this.mapStyle.laneWidth / 2;
				var p1 = refPath.getPointAt(0);
				var p2 = refPath.getPointAt(refPath.length);
				var mezzaria = new Path();
				mezzaria.add(new Point(p1.x + halfLane, p1.y + halfLane));
				mezzaria.add(new Point(p2.x + halfLane, p2.y + halfLane));
				var corsia = new Path();
				corsia.add(new Point(p1.x - halfLane, p1.y - halfLane));
				corsia.add(new Point(p2.x - halfLane, p2.y - halfLane));
				cLeft.intersezioni = [{
					//traiettoria: c.crossingPaths[eN].dritto_1.id,
					traiettoria: 'dritto_1',
					distanza: c.crossingPaths[p].sinistra.path.getOffsetOf(c.crossingPaths[p].sinistra.path.getIntersections(c.crossingPaths[eN].dritto_1.path)[0].point),
				}, {
					//traiettoria: c.crossingPaths[eN].dritto_2.id,
					traiettoria: 'dritto_2',
					distanza: c.crossingPaths[p].sinistra.path.getOffsetOf(c.crossingPaths[p].sinistra.path.getIntersections(c.crossingPaths[eN].dritto_2.path)[0].point),
				}, ];
				cLeft.intersezione_corsie = [{
					//traiettoria: c.crossingPaths[eN].dritto_2.id,
					traiettoria: 'linea_mezzaria',
					distanza: c.crossingPaths[p].sinistra.path.getOffsetOf(c.crossingPaths[p].sinistra.path.getIntersections(mezzaria)[0].point),
				}, {
					//traiettoria: c.crossingPaths[eN].dritto_2.id,
					traiettoria: 'linea_corsia',
					distanza: c.crossingPaths[p].sinistra.path.getOffsetOf(c.crossingPaths[p].sinistra.path.getIntersections(corsia)[0].point),
				}, ];
				cLeft.intersezione_bipedi = lunghezza_traiettorie_incroci['auto']['sinistra']['intersezione_bipedi'];
				/*
				c.crossingPaths[p].sinistra.path.fullySelected = true;
				c.crossingPaths[eN].dritto_1.path.fullySelected = true;
				c.crossingPaths[eN].dritto_2.path.fullySelected = true;
				corsia.fullySelected = true;
				mezzaria.fullySelected = true;
				*/
			}
			//traiettorie[c.crossingPaths[p].sinistra.id] = cLeft;
			traiettorie[np]['sinistra'] = cLeft;
		}
		if (c.crossingPaths[p] != null && c.crossingPaths[p].dritto_1 && c.crossingPaths[p].dritto_2) {
			var s1 = makeCPData(c.crossingPaths[p].dritto_1);
			var s2 = makeCPData(c.crossingPaths[p].dritto_2);
			var eN = (np + 2) % 4;
			if (c.crossingPaths[eN] && c.crossingPaths[eN].sinistra) {
				s1.intersezioni = [{
					//traiettoria: c.crossingPaths[eN].left.id,
					traiettoria: 'sinistra',
					distanza: c.crossingPaths[p].dritto_1.path.getOffsetOf(c.crossingPaths[p].dritto_1.path.getIntersections(c.crossingPaths[eN].sinistra.path)[0].point),
				}];
				s1.intersezione_bipedi = 31.0;
				s2.intersezioni = [{
					//traiettoria: c.crossingPaths[eN].left.id,
					traiettoria: 'sinistra',
					distanza: c.crossingPaths[p].dritto_2.path.getOffsetOf(c.crossingPaths[p].dritto_2.path.getIntersections(c.crossingPaths[eN].sinistra.path)[0].point),
				}];
				s2.intersezione_bipedi = 31.0;
			}
			traiettorie[np]['dritto_1'] = s1;
			traiettorie[np]['dritto_2'] = s2;
		}
	}

	if (lunghezza_traiettorie_incroci['pedoni']) {
		for (idx in lunghezza_traiettorie_incroci['pedoni']) {
			traiettorie[0][idx] = lunghezza_traiettorie_incroci['pedoni'][idx];
		}
	}
	return traiettorie;
}

function makeCPData(cP) {
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
Map.alignHandleAvg = function(h1, h2) {
	var h2Bis = new Point(-h1.x, -h1.y);
	var h1Bis = new Point(-h2.x, -h2.y);
	h1.x = (h1.x + h1Bis.x) / 2;
	h1.y = (h1.y + h1Bis.y) / 2;
	h2.x = (h2.x + h2Bis.x) / 2;
	h2.y = (h2.y + h2Bis.y) / 2;
}

/*
	Aligns the first handle to the second
*/
Map.alignHandle = function(h1, h2) {
	var h1Bis = new Point(-h2.x, -h2.y);
	h1.x = (h1Bis.x);
	h1.y = (h1Bis.y);
}

Map.prototype.switchTrafficLights = function() {
	for (var i in this.crossroads) {
		this.crossroads[i].switchTrafficLights();
	}
}


/**
 * WorldMap class
 * Used to draw alle the zones
 **/

function WorldMap() {
	Map.call(this);
}

WorldMap.prototype = Object.create(Map.prototype);
WorldMap.prototype.constructor = WorldMap;