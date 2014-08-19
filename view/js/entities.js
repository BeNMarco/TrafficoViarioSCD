/**
*	Author: Marco Negro
*	Email: negromarc@gmail.com
*	Descr: collection of entities to move on the map
*/

function EntitiesStyle(){
	this.carShape = {type:'Rectangle', args: {point:[0,0],size:[7,11]}}; //[new Point(0,0), new Size(11,7)]
	this.carColor = 'red';
	this.busShape = {type:'Rectangle', args: {point:[0,0],size:[8,15]}};
	this.busColor = 'blue';
	this.bikeShape = [];
	this.bikeColor = 'gree';
	this.pedestrianShape = {type:'Circle', args: {center:[0,0], radius:3}};
	this.pedestrianColor = 'pink';
}

function Car(id){
	this.id = id;
	this.driver = null;
	this.path = new Path();
	this.currentPosition = null;
}

Car.prototype.show = function(){
	this.path.visible = true;
}

Car.prototype.hide = function(){
	this.path.visible = false;
}

Car.prototype.draw = function(style){
	this.path = new Path[style.carShape.type](style.carShape.args); //style.carShape.args[0], style.carShape.args[1]
	this.path.fillColor = style.carColor;
}

Car.prototype.move = function(pos, angle){
	this.path.position = pos;
	this.path.rotation = angle;
}