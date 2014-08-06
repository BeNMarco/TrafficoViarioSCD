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
	len = path.length;
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
		if(pos > path.length){
			console.log("wtf!");
		}
		if(pos+start > path.length){
			console.log("wtf start!");
		}
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
	this.lineWidth = 1;
	this.laneWidth = 10;
	this.pavementColor = 'grey';
	this.pavementWidth = 5;
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
	this.guidingPath.smooth();
	this.path = null;
	this.name = obj.nome ? obj.nome : "";
}

Street.prototype.draw = function(style){
	this.path = new Path(this.guidingPath.pathData);
	this.path.strokeColor = style.laneColor;
	this.path.strokeWidth = style.laneWidth*this.nLanes*2+style.pavementWidth*2;
	this.guidingPath.strokeColor = style.lineColor;
	this.guidingPath.strokeWidth = style.lineWidth;
	this.guidingPath.moveAbove(this.path);
	//this.guidingPath.fullySelected = true;
	console.log("lunghezza strada "+this.id+": "+this.guidingPath.length);

	// drawing the separation lines
	var precision = Math.ceil(this.guidingPath.length);
	var sepStyle = {strokeWidth: style.lineWidth, strokeColor:style.lineColor, dashArray: style.dashArray};
	for(var i = 1; i < this.nLanes; i++){
		pathOffset(this.guidingPath, (i)*style.laneWidth, precision, sepStyle);
		pathOffset(this.guidingPath, -(i)*style.laneWidth, precision, sepStyle);
	}

	// drawing the pedestrian lines
	pathOffset(this.guidingPath, this.nLanes*style.laneWidth, precision);
	pathOffset(this.guidingPath, -this.nLanes*style.laneWidth, precision);
	if(this.id != ""){
		var signPath = pathOffset(this.guidingPath, this.nLanes+style.laneWidth + 4*style.pavementWidth, precision, {strokeWidth:0, strokColo:'black', dashArray: null});
		var startPoint = signPath.getPointAt(signPath.length/3);
		var text = new PointText(startPoint);
		text.content = this.id;
	}
	this.path.sendToBack();

	if(this.id == 11){
		console.log(this.path.lastSegment);
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



/**
 *
 *	Crossroad class
 *
**/

function Crossroad(obj){
	this.id = obj.id;
	this.streetsRef = obj.strade;
	this.lanesNumber = [0,0];
	this.streets = [];
	this.center = null;
	this.angle = obj.angolo ? obj.angolo : 0;
	this.pedestrian = null;
	this.firstEntrance = 1;
	this.group = new Group();
	this.trafficLights = {};
}

/**
*	Links the streets to the crossroad
* 	
**/
Crossroad.prototype.linkStreets = function(streets){
	var firstIn = null;
	var polo = true;
	var entr = 0;
	for (var i = 0; i < this.streetsRef.length; i ++) {
		entr++;
		if (this.streetsRef[i] != null){
			var tmpStreet = streets[this.streetsRef[i].id_strada];
			this.streets[i] = tmpStreet;

			if(firstIn == null){
				this.firstEntrance = entr;
				firstIn = tmpStreet;
				polo = this.streetsRef[i].polo;	
			}
			// getting the number of lanes per direction
			if (tmpStreet.nLanes > this.lanesNumber[i%2]){
				this.lanesNumber[i%2] = tmpStreet.nLanes;
			}

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
	var totalWidth = this.lanesNumber[0]*style.laneWidth+style.pavementWidth;
	var totalHeight = this.lanesNumber[1]*style.laneWidth+style.pavementWidth;
	var startP = new Point(this.center.x-totalWidth, this.center.y-totalHeight);

	var path = new Path.Rectangle(startP, new Size(totalWidth*2, totalHeight*2));
	path.fillColor = style.laneColor;
	
	this.group.addChild(path);

	var halfW = 0.5*style.pavementWidth;	
	for (var i = 0; i < this.streets.length; i++) {
		var st = {color: style.lineColor, width: style.pavementWidth, dash: style.zebraDash};
		var ped = style.pavementWidth/2;

		var g = new Group();

		if(this.streets[i] == null){
			// if there is no street we draw the pavement

			ped = 0;
			st.dash = [];
			st.width = style.lineWidth;
		} else {
			// otherwise we draw the zebra crossing (it is the defaul so no need to customize the style)
			// but we draw the traffic lights

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
				this.trafficLights[this.streets[i].id+"s"+i+"l"+(a)] = t;
				g.addChild(t.path);
			}
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
	this.path.strokeWidth = 1;
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
	this.entranceStreetPole = obj.latostrada;
	this.id = obj.id;
	this.maxCar = obj.capienza_macchine;
	this.maxPerson = obj.capienza_persone;
	this.maxBike = obj.capienza_bici;
	this.placeName = obj.nome;
	this.palceType = obj.tipologia;
	this.entranceStreet = null;
	this.angle = obj.angolo ? obj.angolo : 0;
	this.placeWidth = obj.dimensioni[0];
	this.placeHeight = obj.dimensioni[1];
}

Place.prototype.setEnteringStreet = function(street){
	this.entranceStreet = street;
}

Place.prototype.draw = function(style){
	var center = this.entranceStreetPole ? this.entranceStreet.guidingPath.firstSegment.point : this.entranceStreet.guidingPath.lastSegment.point;

	var placePath = new Path.Rectangle(new Point(), new Size(this.placeWidth, this.placeHeight));
	placePath.strokeWidth = 1;
	placePath.strokeColor = 'grey';
	placePath.fillColor = 'white';
	placePath.position = center;
	/*
	var pathCenter = new Point(this.placeWidth/2,this.placeHeight/2);

	this.path = new Path.RegularPolygon(center, 4, 10);
	var i = this.path.getIntersections(this.entranceStreet.guidingPath)[0];
	var newCenter = center.add(center.subtract(i.point));
	this.path = new Path.RegularPolygon(newCenter,4,10);
	this.path.strokeColor = 'black';
	this.path.strokeWidth = 1;
	*/
}

/**
 *
 *	Map class
 *
**/
function Map(){
	this.streets = {},
	this.crossroads = {},
	this.pavements = {},
	this.places = {},
	this.mapStyle = new MapStyle();
}

Map.prototype.setStyle = function(newStyle){
	this.mapStyle = newStyle;
}

Map.prototype.load = function(obj){
	this.streets = {};
	this.crossroads = {};
	for (var i = 0; i < obj.strade.length; i++) {
		this.streets[obj.strade[i].id] = new Street(obj.strade[i]);
	}
	for (var i = 0; i < obj.incroci.length; i++) {
		var c = new Crossroad(obj.incroci[i]);
		c.linkStreets(this.streets);
		this.crossroads[obj.incroci[i].id] = c;
	}
	for(var i = 0; i < obj.luoghi.length; i++){
		var p = new Place(obj.luoghi[i]);
		p.setEnteringStreet(this.streets[p.entranceStreetId]);
		this.places[obj.luoghi[i].id] = p;
	}
}

Map.prototype.draw = function(){
	for (var i in this.crossroads) {
		this.crossroads[i].draw(this.mapStyle);
	}
	for (var i in this.streets) {
		this.streets[i].draw(this.mapStyle);
	}
	for (var i in this.places){
		this.places[i].draw(this.mapStyle);
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
