$('#out').text("ciao bello!");
var json = [];
var from = 7;
var to = 16;
var namePrefix = "Casa";
var type = "casa";
var dimensions = [50,30];
var car = 2;
var people = 5;
var bike = 5;

for(var i = from; i < to+1; i++){
    var aa = {
      "id_luogo":i,
      "nome": namePrefix+" "+i,
      "tipologia":type,
      "idstrada":i,
      "dimensioni":dimensions,
      "capienza_macchine":car,
      "capienza_persone":people,
      "capienza_bici":bike,
    };
    json.push(aa);
}

console.log("prova");

$('#out').text(JSON.stringify(json, null, '\t'));