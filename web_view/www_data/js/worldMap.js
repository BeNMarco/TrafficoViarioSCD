
///////// Utility functions

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

function adjustLength(position, actualLength, expectedLength){
  return (position*(actualLength/expectedLength));
}

/////////

function WorldMapStyle(){
  this.lineColor = 'white';
  this.laneColor = 'white';
  this.lineWidth = 0.15;
  this.laneWidth = 7;
  this.pavementColor = 'grey';
  this.pavementWidth = 3;
  this.dashArray = [3, 4.5];
  this.zebraDash = [0.5, 0.5];
  this.pavementMiddleDash = [1, 1.5];
  this.middlePathEntranceDashOffset = 5;
  this.crossroadHighlightWidth = 5;
  this.crossroadHighlightColor = 'grey';
}


function MapPieceStyle() {
  this.streetColor = 'grey';
  this.streetWidth = 10;
  this.laneWidth = 7;
  this.pavementWidth = 3;
  this.path = null();
}

function MapPiece(obj){
  this.data = obj;
  this.id = obj.info.id;
  this.dimensioni = obj.info.dimensioni;
  this.posizione = obj.info.posizione;
  this.streets = {};
  this.crossroads = {};
  this.mapStyle = new WorldMapStyle();
  this.traiettorie = null;
  this.onPieceReady = null;
}

MapPiece.prototype.setTraiettorie = function(t){
  this.traiettorie = t;
}

MapPiece.prototype.fixStreetsPosition = function(obj){
  for(var i in obj.strade_urbane){
    obj.strade_urbane[i].from = this.adjustPoint(obj.strade_urbane[i].from);
    obj.strade_urbane[i].to = this.adjustPoint(obj.strade_urbane[i].to);
  }
  return obj;
}

MapPiece.prototype.load = function(obj){

  obj = this.fixStreetsPosition(obj);

  for (var i in obj.strade_urbane) {
    this.streets[obj.strade_urbane[i].id] = new Street(obj.strade_urbane[i], this);
  }

  for (var i = 0; i < obj.incroci_a_4.length; i++) {
    var cur_inc = obj.incroci_a_4[i];
    var c = new Crossroad(cur_inc, this);
    c.linkStreets(this.streets, this.id);
    this.crossroads[cur_inc.id] = c;
  }
  for (var i in obj.incroci_a_3) {
    //obj.incroci_a_3[i].strade.splice(obj.incroci_a_3[i].strada_mancante,0,null);
    var cur_inc = obj.incroci_a_3[i];
    var c = new Crossroad(cur_inc, this);
    c.linkStreets(this.streets, this.id);
    this.crossroads[cur_inc.id] = c;
  }
}

MapPiece.prototype.draw = function(style){
  this.mapStyle = style;

  this.path = new Path.Rectangle(new Point(this.posizione), new Size(this.dimensioni));

  this.path.strokeColor = '#A7A8A7';
  this.path.strokeColor.alpha = 0.7;
  this.path.strokeWidth = 2;
  this.path.strokeScaling = false;
  this.path.dashArray = [7,7];
  this.path.fillColor = '#DD4F42';
  this.path.fillColor.alpha = 0;

  var self = this;
  this.path.onMouseDown = function(event){
    this.positionOnDown = {"x":event.event.x, "y":event.event.y};
    if(typeof self.onMapMouseDown === 'function')
      self.onMapMouseDown(event);
  }

  this.path.onMouseUp = function(event){
    if(event.event.x == this.positionOnDown.x && event.event.y == this.positionOnDown.y){
      window.open("quartiere"+self.id, "_self");
    }
    if(typeof self.onMapMouseUp === 'function')
      self.onMapMouseUp(event);
  }

  this.path.onMouseEnter = function(event){
    this.dashArray = null;
    this.strokeWidth = 2;
    this.fillColor.alpha = 0.1;
    this.strokeColor.alpha = 1;
    this.strokeColor = '#DD4F42';
    if(typeof self.onMapMouseEnter === 'function')
      self.onMapMouseEnter(event);
  }

  this.path.onMouseLeave = function(event){
    this.strokeColor = '#A7A8A7';
    this.strokeWidth = 2;
    this.fillColor.alpha = 0;
    this.strokeColor.alpha = 0.7;
    this.dashArray = [7,7];
    if(typeof self.onMapMouseLeave === 'function')
      self.onMapMouseLeave(event);
  }
  // this.drawStreets(style);

  for (var i in this.crossroads) {
    this.crossroads[i].draw(this.mapStyle);
  }

  for (var i in this.streets) {
    this.streets[i].draw(this.mapStyle);
  }

  this.path.bringToFront();

  console.log("I am ready "+this.id);
  if(typeof this.onPieceReady === 'function'){
    console.log("onPieceReady");
    this.onPieceReady();
  }
}

MapPiece.prototype.adjustPoint = function(point){
  return [point[0]+this.posizione[0], point[1]+this.posizione[1]];
}

MapPiece.prototype.sendBackStreets = function(){
  for (var i = this.streets.length - 1; i >= 0; i--) {
    this.streets[i].guidingPath.sendToBack();
  }
}

MapPiece.prototype.sendBackCrossroads = function(){
  for (var i = this.crossroads.length - 1; i >= 0; i--) {
    this.crossroads[i].path.sendToBack();
  }
}

MapPiece.prototype.liftBorders = function(){
  this.path.bringToFront();
}

function WorldMap(){
  this.pieces = {};
}

WorldMap.prototype.addMapPiece = function(obj){
  var toRet = new MapPiece(obj);
  this.pieces[obj.id] = toRet;
  return toRet;
}

WorldMap.prototype.liftPiecesBorders = function(){
  for(var i in this.pieces){
    this.pieces[i].sendBackCrossroads();
  }
  for(var i in this.pieces){
    this.pieces[i].sendBackStreets();
  }
  for(var i in this.pieces){
    this.pieces[i].liftBorders();
  }
}


function Street(obj, map) {
  this.map = map;

  this.id = obj.id;
  this.len = obj.lunghezza;
  this.nLanes = obj.numcorsie;
  this.from = obj.from;
  this.to = obj.to;
  this.guidingPath = new Path();
  this.guidingPath.add(obj.from);
  //this.guidingPath.add(new Point((obj.from[0]+obj.to[0])/2, (obj.from[1]+obj.to[1])/2));
  this.guidingPath.add(obj.to);
  this.guidingPath.smooth();
  this.path = null;
  this.name = obj.nome ? obj.nome : "";
}

Street.prototype.draw = function(style) {
  this.laneWidth = style.laneWidth;
  this.pavementWidth = style.pavementWidth;
  this.guidingPath.strokeColor = style.laneColor;
  this.guidingPath.strokeWidth = style.laneWidth * this.nLanes * 2 + style.pavementWidth * 2;

  this.guidingPath.sendToBack();
}


Street.prototype.getPositionAtOffset = function(distance, side, offset) {
  return getPositionAtOffset(this.guidingPath, distance, side, offset);
}

Street.prototype.getStreetLength = function() {
  return this.len;
}

Street.prototype.getPositionAt = function(distance, side, drive) {
  drive = typeof drive === 'undefined' ? true : drive;
  distance = adjustLength(distance, this.guidingPath.length, this.len);
  if (drive && side) {
    distance = this.guidingPath.length - distance;
  }

  var offset = 0.25*this.guidingPath.strokeWidth;

  return this.getPositionAtOffset(distance, side, offset);
}

Street.prototype.getPositionAtOvertaking = function(distance, side, startPoint){
  distance = adjustLength(distance, this.map.traiettorie.cambio_corsia.lunghezza_lineare, this.map.traiettorie.cambio_corsia.lunghezza_traiettoria);
  return this.getPositionAt((startPoint+distance), side, true);
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


/**
 *
 *  Crossroad class
 *
 **/

function Crossroad(obj, map) {

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
  this.path = null;
  this.trafficLights = {};
  this.crossingPaths = {};

  if ("strada_mancante" in obj) {
    this.streetsRef.splice(obj.strada_mancante, 0, null);
  }
}

/**
 *  Links the streets to the crossroad
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

  var totalWidth = this.lanesNumber[0] * style.laneWidth + style.pavementWidth;
  var totalHeight = this.lanesNumber[1] * style.laneWidth + style.pavementWidth;
  var startP = new Point(this.center.x - totalWidth, this.center.y - totalHeight);

  if (style.debug) {
    this.label = new PointText(this.center);
    this.label.content = this.id;
  }
  var path = new Path.Rectangle(startP, new Size(totalWidth * 2, totalHeight * 2));
  path.fillColor = style.laneColor;
  path.strokeWidth = style.crossroadHighlightWidth;
  path.strokeColor = style.crossroadHighlightColor;

  this.path = path;

  this.group.addChild(path);

  var poleMap = {
    true: 'firstSegment',
    false: 'lastSegment'
  };

  for (var i = 0; i < this.streetsRef.length; i++) {
    var g = new Group();
    
    this.crossingPaths[i] = {};

    if (this.streetsRef[i] == null) {
      // if there is no street we draw the middle line
      this.crossingPaths[i] = null;
    } else {
      // otherwise we draw the zebra crossing (it is the defaul so no need to customize the style)
      // but we draw the traffic lights and the cross trajectors

      // paths that leads to the other side of the crossroad
      var debgArr = []
        // creating the path that turns left
      if (this.streetsRef[(i + 1) % 4] != null) {
        var crossPath = new Path();
        crossPath.add(new Point(this.center.x - style.laneWidth, this.center.y - (style.laneWidth * 2 + style.pavementWidth)));
        crossPath.add(new Point(this.center.x + (style.laneWidth * 2 + style.pavementWidth), this.center.y + style.laneWidth));
        var handlePoint = new Point(this.center.x - style.laneWidth, this.center.y + style.laneWidth);
        crossPath.firstSegment.handleOut = handlePoint.subtract(crossPath.firstSegment.point);
        crossPath.firstSegment.handleOut.length = crossPath.firstSegment.handleOut.length * 0.60;
        crossPath.lastSegment.handleIn = handlePoint.subtract(crossPath.lastSegment.point);
        crossPath.lastSegment.handleIn.length = crossPath.lastSegment.handleIn.length * 0.60;
        crossPath.visible = false;

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

      }
      // creating the paths that go straight through the crossroad
      if (this.streetsRef[(i + 2) % 4] != null) {
        var crossPath = new Path();
        crossPath.add(new Point(this.center.x - style.laneWidth, this.center.y - (style.laneWidth * 2 + style.pavementWidth)));
        crossPath.add(new Point(this.center.x - style.laneWidth, this.center.y + (style.laneWidth * 2 + style.pavementWidth)));
        this.crossingPaths[i]['dritto_1'] = {
          path: crossPath,
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
        crossPath.visible = false;
        //this.crossingPaths[this.id+"_s"+this.streetsRef[i].id_strada+".l"+1+"-"+"s"+this.streetsRef[(i+2)%4].id_strada+".l"+1] = crossPath1;
  
        this.crossingPaths[i]['dritto_2'] = {
          path: crossPath,
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
        //this.crossingPaths[this.id+"_s"+this.streetsRef[i].id_strada+".l"+2+"-"+"s"+this.streetsRef[(i+2)%4].id_strada+".l"+2] = crossPath2;
        g.addChild(crossPath);

      }

      // creating the path that turns right
      if (this.streetsRef[(i + 3) % 4] != null) {
        var crossPath = new Path();
        crossPath.add(new Point(this.center.x - style.laneWidth * 1, this.center.y - (style.laneWidth * 2 + style.pavementWidth)));
        crossPath.add(new Point(this.center.x - (style.laneWidth * 2 + style.pavementWidth), this.center.y - style.laneWidth * 1));
        var handlePoint = new Point(this.center.x - style.laneWidth * 1, this.center.y - style.laneWidth * 1);
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

      
      //debgArr.push(crossPath);
    }
    if (style.debug) {
      for (var dI in debgArr) {
        debgArr[dI].fullySelected = true;
        //debgArr[dI].strokeColor = 'green';
        //debgArr[dI].strokeWidth = 0.2;
      }
    }

    g.rotate(90 * (i % 4), path.position);
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
  //  console.log("streetId: "+streetId+" district:"+district+" resolved:"+toRet);
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
    var path =this.crossingPaths[this.getEntranceStreetNumber(enteringStreet, streetDistrict)][direction].path;
    distance = adjustLength(distance, this.map.traiettorie.traiettorie_incrocio[direction].lunghezza, path.length);
    var loc = path.getLocationAt(distance);
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
