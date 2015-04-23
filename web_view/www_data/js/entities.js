/**
*	Author: Marco Negro
*	Email: negromarc@gmail.com
*	Descr: collection of entities to move on the map
*/
var idCurCarDbg;

function doesExists(thing)
{
	return typeof thing !== 'undefined' && thing !== null;
}

function EntitiesStyle(){
	this.carShape = {type:'Rectangle', args: {point:[0,0],size:[3.5,5]}}; //[new Point(0,0), new Size(11,7)]
	this.carColor = 'red';
	this.busShape = {type:'Rectangle', args: {point:[0,0],size:[8,15]}};
	this.busColor = 'blue';
	this.bikeShape = {type:'Circle', args: {center:[0,0], radius:0.5}};
	this.bikeColor = 'green';
	this.pedestrianShape = {type:'Circle', args: {center:[0,0], radius:0.5}};
	this.pedestrianColor = 'pink';

	this.car = {
		shape: {type:'Rectangle', args: {point:[0,0],size:[2,3]}},
		color: 'red'
	};
	this.bus = {
		shape: {type:'Rectangle', args: {point:[0,0],size:[2,3]}},
		color: 'blue'
	};
	this.bike = {
		shape: {type:'Circle', args: {center:[0,0], radius:0.5}},
		color: 'green'
	};
	this.pedestrian = {
		shape: {type:'Circle', args: {center:[0,0], radius:0.25}},
		color: 'pink'
	};
}

function WorldEntitiesStyle(){

	this.car = {
		shape: {type:'Circle', args: {center:[0,0], radius:7}},
		color: 'red'
	};
	this.bus = {
		shape: {type:'Circle', args: {center:[0,0], radius:7}},
		color: 'blue'
	};
}

function Entity()
{
}

Entity.prototype.show = function(){
	this.path.visible = true;
	//this.path.bringToFront();
}

Entity.prototype.hide = function(){
	this.path.visible = false;
}

Entity.prototype.draw = function(style){
	this.path = new Path[style.shape.type](style.shape.args); //style.carShape.args[0], style.carShape.args[1]
	this.path.fillColor = style.color;
	this.path.myData = this;

	this.path.onMouseEnter = this.myOnMouseEnter;
	/*function(event) {
	  // Layout the tooltip above the dot
	  //var tooltipRect = new Rectangle(this.position + new Point(40, 40), new Size(100, 100));
	  // Create tooltip from rectangle
	  this.tooltipLabel = new PointText(this.position.subtract(new Point(-5,-5)));
	  this.tooltipLabel.fillColor = 'white';
	  this.tooltipLabel.textColor = 'blue';
	  this.tooltipLabel.strokeColor = 'black';
	  // Name the tooltip so we can retrieve it later
	  this.tooltipLabel.content = this.myData.id;
	  this.tooltipLabel.bringToFront();
	  // Add the tooltip to the parent (group)
	  this.fillColor = 'green';
	}*/


	// Create onMouseLeave event for dot
	this.path.onMouseLeave = this.myOnMouseLeave;
	/*function(event) {
	  // We retrieve the tooltip from its name in the parent node (group) then remove it
	  this.tooltipLabel.remove();
	  this.fillColor = 'red';
	  console.log("out");
	}*/
}

Entity.prototype.myOnMouseEnter = function(event) {
  // Layout the tooltip above the dot
  //var tooltipRect = new Rectangle(this.position + new Point(40, 40), new Size(100, 100));
  // Create tooltip from rectangle
  this.tooltipLabel = new PointText(this.position.subtract(new Point(-5,-5)));
  this.tooltipLabel.fillColor = 'white';
  this.tooltipLabel.textColor = 'blue';
  this.tooltipLabel.strokeColor = 'black';
  // Name the tooltip so we can retrieve it later
  this.tooltipLabel.content = this.myData.id;
  this.tooltipLabel.bringToFront();
  // Add the tooltip to the parent (group)
  this.fillColor = 'green';
}

Entity.prototype.myOnMouseLeave = function(event) {
  // We retrieve the tooltip from its name in the parent node (group) then remove it
  this.tooltipLabel.remove();
  this.fillColor = 'red';
}

Entity.prototype.remove = function()
{
	if(this.path)
		this.path.remove();
}

/*
Car.prototype.draw = function(style){
	this.path = new Path[style.carShape.type](style.carShape.args); //style.carShape.args[0], style.carShape.args[1]
	this.path.fillColor = style.carColor;
	this.length = style.carShape.args.size[1];
	this.path.carData = this;

	this.path.onMouseEnter = function(event) {
	  // Layout the tooltip above the dot
	  //var tooltipRect = new Rectangle(this.position + new Point(40, 40), new Size(100, 100));
	  // Create tooltip from rectangle
	  this.tooltipLabel = new PointText(this.position.subtract(new Point(-5,-5)));
	  this.tooltipLabel.fillColor = 'white';
	  this.tooltipLabel.textColor = 'blue';
	  this.tooltipLabel.strokeColor = 'black';
	  // Name the tooltip so we can retrieve it later
	  this.tooltipLabel.content = this.carData.id;
	  this.tooltipLabel.bringToFront();
	  // Add the tooltip to the parent (group)
	  this.fillColor = 'green';
	}


	// Create onMouseLeave event for dot
	this.path.onMouseLeave =  function(event) {
	  // We retrieve the tooltip from its name in the parent node (group) then remove it
	  this.tooltipLabel.remove();
	  this.fillColor = 'red';
	  console.log("out");
	}
	//this.path.bringToFront();
}*/

Car.prototype = new Entity();
Car.prototype.constructor = Car;

function Car(id, id_quartiere, length){
	this.id = id;
	this.id_quartiere = id_quartiere;
	this.driver = null;
	this.path = new Path();

	this.currentPosition = null;
	this.angle = 90;
	this.length = length;
}

Car.prototype.move = function(pos, angle){
	var rotate = (typeof angle === 'undefined') ? false : true;
	var p = new Point();
	p.length = this.length/2;
	if(rotate) p.angle = this.angle;
	this.path.position = pos.subtract(p);
	if(rotate){
		this.path.rotate(angle-this.angle);
		this.angle=angle;
	}
}

Car.prototype.draw = function(style)
{
	// calling the "super" method
	var tmpSt = style;
	if(tmpSt.shape.args.size)
		tmpSt.shape.args.size[1] = this.length;
	Entity.prototype.draw.call(this, tmpSt);
}

Bipede.prototype = new Entity();
Bipede.prototype.constructor = Bipede;

function Bipede(id, id_quartiere)
{
	this.id = id;
	this.id_quartiere = id_quartiere;
	this.path = new Path();

	this.currentPosition = null;
}

Bipede.prototype.move = function(pos){
	var p = new Point();

	p.length = this.length/2;
	p.angle = 0;
	this.path.position = pos.subtract(p);
}

Bipede.prototype.draw = function(style)
{
	// calling the "super" method
	Entity.prototype.draw.call(this, style);
	this.length = style.shape.args.radius;
}


function EntitiesRegistry(){
	this.cars = [];
	this.bikes = [];
	this.pedestrians = [];
	this.buses = [];
	this.style = new EntitiesStyle();

	this.onCarsChange = null;
	this.onBikesChange = null;
	this.onPedestriansChange = null;
}

EntitiesRegistry.prototype.addCar = function(id, id_quartiere_abitante, length)
{
	var curCar = new Car(id, id_quartiere_abitante, length);
	curCar.draw(this.style.car);
	curCar.show();
	this.cars[id_quartiere_abitante+"_"+id] = curCar;
	if(typeof this.onCarsChange === 'function')
	{
		this.onCarsChange(this.cars);
	}
	return curCar;
}

EntitiesRegistry.prototype.addBus = function(id, id_quartiere_abitante, length)
{
	var curBus = new Car(id, id_quartiere_abitante, length);
	curBus.draw(this.style.bus);
	curBus.show();
	this.buses[id_quartiere_abitante+"_"+id] = curBus;
	if(typeof this.onBusesChange === 'function')
	{
		this.onBusesChange(this.buses);
	}
	return curBus;
}

EntitiesRegistry.prototype.addVehicle = function(id, id_quartiere_abitante, length, isBus){
	var isBus = typeof isBus === 'undefined' ? false : isBus;
	if(isBus){
		return this.addBus(id, id_quartiere_abitante, length);
	} else {
		return this.addCar(id, id_quartiere_abitante, length);
	}
}

EntitiesRegistry.prototype.getVehicle = function(id, id_quartiere_abitante, length, isBus){
	var isBus = typeof isBus === 'undefined' ? false : isBus;
	var id = id_quartiere_abitante+"_"+id;
	if(isBus){
		return this.buses[id];
	} else {
		return this.cars[id];
	}
}

EntitiesRegistry.prototype.getOrAddVehicle = function(id, id_quartiere_abitante, length, isBus){
	var v = this.getVehicle(id, id_quartiere_abitante, length, isBus);
	if(!v)
		v = this.addVehicle(id, id_quartiere_abitante, length, isBus);
	return v;
}

EntitiesRegistry.prototype.removeCar = function(id, id_quartiere_abitante)
{
	var toDel = this.cars[id_quartiere_abitante+"_"+id];
	if(toDel){
		toDel.remove();
		delete this.cars[id_quartiere_abitante+"_"+id];
		if(typeof this.onCarsChange === 'function')
		{
			this.onCarsChange(this.cars);
		}
	}
}

EntitiesRegistry.prototype.addBike = function(id, id_quartiere_abitante)
{
	var cur = new Bipede(id, id_quartiere_abitante);
	cur.draw(this.style.bike);
	cur.show();
	this.bikes[id_quartiere_abitante+"_"+id] = cur;
	if(typeof this.onCarsChange === 'function')
	{
		this.onBikesChange(this.bikes);
	}
	return cur;
}

EntitiesRegistry.prototype.removeBike = function(id, id_quartiere_abitante)
{
	var toDel = this.bikes[id_quartiere_abitante+"_"+id];
	if(toDel)
	{
		toDel.remove();
		delete this.bikes[id_quartiere_abitante+"_"+id];
		if(typeof this.onCarsChange === 'function')
		{
			this.onCarsChange(this.bikes);
		}
	}
}

EntitiesRegistry.prototype.addPedestrian = function(id, id_quartiere_abitante)
{
	var cur = new Bipede(id, id_quartiere_abitante);
	cur.draw(this.style.pedestrian);
	cur.show();
	this.pedestrians[id_quartiere_abitante+"_"+id] = cur;
	if(typeof this.onCarsChange === 'function')
	{
		this.onPedestriansChange(this.pedestrians);
	}
	return cur;
}

EntitiesRegistry.prototype.removePedestrian = function(id, id_quartiere_abitante)
{
	var toDel = this.pedestrians[id_quartiere_abitante+"_"+id];
	if(toDel)
	{
		toDel.remove();
		delete this.pedestrians[id_quartiere_abitante+"_"+id];
		if(typeof this.onCarsChange === 'function')
		{
			this.onPedestriansChange(this.pedestrians);
		}
	}
}

EntitiesRegistry.prototype.setStyle = function(style){
	this.style = style;
}

EntitiesRegistry.prototype.load = function(obj){
	var c_id_q = obj.info.id;
	for(var i in obj.auto){
		var c_id = obj.auto[i].id_abitante;
		var idx = c_id_q+"_"+c_id
		this.cars[idx] = new Car(c_id, c_id_q);
		this.cars[idx].hide();
	}
}

EntitiesRegistry.prototype.show = function(){
	for(var i in this.cars){
		this.cars[i].show();
	}
}

EntitiesRegistry.prototype.draw = function(){
	for(var i in this.cars){
		this.cars[i].draw(this.style);
	}
}

EntitiesRegistry.prototype.hide = function(){
	for(var i in this.cars){
		this.cars[i].hide();
	}
}

EntitiesRegistry.prototype.clear = function(){
	for(var i in this.cars){
		this.cars[i].remove();
		delete this.cars[i];
	}

	if(typeof this.onCarsChange === 'function')
	{
		this.onCarsChange(this.cars);
	}

	for(var i in this.bikes){
		this.bikes[i].remove();
		delete this.bikes[i];
	}

	if(typeof this.onBikesChange === 'function')
	{
		this.onBikesChange(this.cars);
	}

	for(var i in this.pedestrians){
		this.pedestrians[i].remove();
		delete this.pedestrians[i];
	}

	if(typeof this.onPedestriansChange === 'function')
	{
		this.onPedestriansChange(this.cars);
	}
}