/**
*	Author: Marco Negro
*	Email: negromarc@gmail.com
*	Descr: collection of entities to move on the map
*/
var idCurCarDbg;

function doesExists(thing)
{
	return typeof thing !== 'undefined' && thing != null;
}

function EntitiesStyle(){
	this.carShape = {type:'Rectangle', args: {point:[0,0],size:[7,11]}}; //[new Point(0,0), new Size(11,7)]
	this.carColor = 'red';
	this.busShape = {type:'Rectangle', args: {point:[0,0],size:[8,15]}};
	this.busColor = 'blue';
	this.bikeShape = {type:'Circle', args: {center:[0,0], radius:0.5}};
	this.bikeColor = 'green';
	this.pedestrianShape = {type:'Circle', args: {center:[0,0], radius:0.5}};
	this.pedestrianColor = 'pink';
}

function Car(id, id_quartiere){
	this.id = id;
	this.id_quartiere = id_quartiere;
	this.driver = null;
	this.path = new Path();

	this.currentPosition = null;
	this.angle = 90;
	this.length = 11;
}

Car.prototype.show = function(){
	this.path.visible = true;
	//this.path.bringToFront();
}

Car.prototype.hide = function(){
	this.path.visible = false;
}

Car.prototype.onMouseEnter = function(event) {
	  // Layout the tooltip above the dot
	  var tooltipRect = new Rectangle(event.position + new Point(-20, -40), new Size(40, 28));
	  // Create tooltip from rectangle
	  tooltip = new Path.Rectangle(tooltipRect);
	  tooltip.fillColor = 'white';
	  tooltip.strokeColor = 'black';
	  // Name the tooltip so we can retrieve it later
	  tooltip.name = 'tooltip';
	  // Add the tooltip to the parent (group)
	  this.fillColor = 'green';
	  this.parent.addChild(tooltip);
	}

Car.prototype.onMouseLeave = function(event) {
	  // We retrieve the tooltip from its name in the parent node (group) then remove it
	  this.parent.children['tooltip'].remove();
	  this.fillColor = 'red';
	  console.log("out");
	}

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
}

Car.prototype.move = function(pos, angle){
	//this.path.position = new Point(pos.x, pos.y+this.length/2);
	/*
	if(doesExists(idCurCarDbg) && this.id == idCurCarDbg)
	{
		console.log(this.id+": " +angle);
	}
	else 
	{
		idCurCarDbg = this.id;
	}
*/
	var p = new Point();
	p.length = this.length/2;
	p.angle = this.angle;
	this.path.position = pos.subtract(p);
	this.path.rotate(angle-this.angle);
	this.angle=angle;
}

//function Bike(id)

function EntitiesRegistry(){
	this.cars = [];
	this.style = new EntitiesStyle();
}

EntitiesRegistry.prototype.addCar = function(id, id_quartiere_abitante)
{
	curCar = new Car(id, id_quartiere_abitante);
	curCar.draw(this.style);
	curCar.show();
	this.cars[id_quartiere_abitante+"_"+id] = curCar;
}

EntitiesRegistry.prototype.removeCar = function(id, id_quartiere_abitante)
{
	delete this.cars[id_quartiere_abitante+"_"+id];
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
}