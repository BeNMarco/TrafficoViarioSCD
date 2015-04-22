
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

/////////


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
}

MapPiece.prototype.draw = function(style){

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
  this.drawStreets(style);
  this.path.bringToFront();
}

MapPiece.prototype.drawStreets = function(style){
  var a = null;
  for(var i in this.data.strade_urbane) {
    var cS = this.data.strade_urbane[i];
    a = new Path();
    a.add(new Point(this.adjustPoint(cS.from)));
    a.add(new Point(this.adjustPoint(cS.to)));
    a.strokeWidth = 34;
    a.strokeColor = 'white';
    a.sendToBack();
  }
}

MapPiece.prototype.adjustPoint = function(point){
  return [point[0]+this.posizione[0], point[1]+this.posizione[1]];
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

Street.prototype.reposition = function() {
  this.guidingPath = new Path();
  this.guidingPath.add(new Point(this.from[0], this.from[1]));
  this.guidingPath.add(new Point(this.to[0], this.to[1]));
  this.guidingPath.smooth();
}

Street.prototype.draw = function(style) {
  this.laneWidth = style.laneWidth;
  this.pavementWidth = style.pavementWidth;
  this.path.strokeColor = style.laneColor;
  this.path.strokeWidth = style.laneWidth * this.nLanes * 2 + style.pavementWidth * 2;

  this.path.sendToBack();
}


Street.prototype.getPositionAtOffset = function(distance, side, offset) {
  return getPositionAtOffset(this.guidingPath, distance, side, offset);
}

Street.prototype.getStreetLength = function() {
  return this.len;
}

Street.prototype.getPositionAt = function(distance, side, drive) {
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
  
  this.trafficLights = {};
  this.crossingPaths = {};
}

/**
 *  Links the streets to the crossroad
 *  
 **/
Crossroad.prototype.linkStreets = function(streets, district) {
  var firstIn = null;
  var polo = true;
  var entr = 0;
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
    }
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
  //  console.log("streetId: "+streetId+" district:"+district+" resolved:"+toRet);
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