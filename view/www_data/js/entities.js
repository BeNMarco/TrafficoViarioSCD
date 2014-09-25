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
	this.angle = 90;
}

Car.prototype.show = function(){
	this.path.visible = true;
	this.path.bringToFront();
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
	this.path.rotate(angle-this.angle);
	this.angle=angle;
}

//function Bike(id)

function EntitiesRegistry(){
	this.cars = [];
	this.style = new EntitiesStyle();
}

EntitiesRegistry.prototype.setStyle = function(style){
	this.style = style;
}

EntitiesRegistry.prototype.load = function(obj){
	console.log(obj.auto);
	for(i in obj.auto){
		var c_id = obj.auto[i].id_abitante;
		this.cars[c_id] = new Car(c_id);
	}
	console.log(this.cars);
}

EntitiesRegistry.prototype.show = function(){
	for(i in this.cars){
		this.cars[i].show();
	}
}

EntitiesRegistry.prototype.draw = function(){
	for(i in this.cars){
		this.cars[i].draw(this.style);
	}
}

EntitiesRegistry.prototype.hide = function(){
	for(i in this.cars){
		this.cars[i].hide();
	}
}