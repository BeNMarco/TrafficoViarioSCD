var quartiere3 = {
	info:{
		id: 3,
		larghezza: 2000,
		altezza: 3000,
		riferimento: {quartiere: 1, angolo:0},
	},
	strade:[
		{"id": 1,"lunghezza": 250,"from":[0,0],"to":[500,0],"numcorsie":2},
		{"id": 2,"lunghezza": 50,"from":[0,1500],"to":[500,1500],"numcorsie":2},		
		{"id": 3,"lunghezza": 50,"from":[0,2300],"to":[500,2300],"numcorsie":2},
		{"id": 4,"lunghezza": 50,"from":[0,3000],"to":[500,3000],"numcorsie":2},
		{"id": 5,"lunghezza": 50,"from":[500,0],"to":[500,750],"numcorsie":2},
		{"id": 6,"lunghezza": 50,"from":[500,750],"to":[500,1500],"numcorsie":2},
		{"id": 7,"lunghezza": 50,"from":[500,1500],"to":[500,2300],"numcorsie":2},
		{"id": 8,"lunghezza": 50,"from":[500,2300],"to":[500,3000],"numcorsie":2},
		{"id": 9,"lunghezza": 50,"from":[500,0],"to":[2000,1500],"numcorsie":2},
		{"id": 10,"lunghezza": 50,"from":[500,750],"to":[1500,750],"numcorsie":2},
		{"id": 11,"lunghezza": 50,"from":[500,1500],"to":[2000,1500],"numcorsie":2},
		{"id": 12,"lunghezza": 50,"from":[500,2300],"to":[1200,2300],"numcorsie":2},
		{"id": 13,"lunghezza": 50,"from":[2000,1500],"to":[1200,2300],"numcorsie":2},
		{"id": 14,"lunghezza": 50,"from":[500,3000],"to":[1200,2300],"numcorsie":2},
	],
	incroci_a_4:[
		{
			id: "i1",
			strade:[
				{"quartiere":3,"id_strada":6,"tipo_strada":"urbana","polo":false},
				{"quartiere":3,"id_strada":11,"tipo_strada":"urbana","polo":true},
				{"quartiere":3,"id_strada":7,"tipo_strada":"urbana","polo":true},
				{"quartiere":3,"id_strada":2,"tipo_strada":"urbana","polo":false},
			]
		},
		{
			id: "i2",
			strade:[
				{"quartiere":3,"id_strada":7,"tipo_strada":"urbana","polo":false},
				{"quartiere":3,"id_strada":12,"tipo_strada":"urbana","polo":true},
				{"quartiere":3,"id_strada":8,"tipo_strada":"urbana","polo":true},
				{"quartiere":3,"id_strada":3,"tipo_strada":"urbana","polo":false},
			]
		},
	],
	incroci_a_3:[
		{
			id: "i3",
			strade:[
				{"quartiere":3,"id_strada":9,"tipo_strada":"urbana","polo":true},
				{"quartiere":3,"id_strada":5,"tipo_strada":"urbana","polo":true},
				{"quartiere":3,"id_strada":1,"tipo_strada":"urbana","polo":false},
			],
			strada_mancante:0,
		},
		{
			id: "i4",
			strade:[
				{"quartiere":3,"id_strada":5,"tipo_strada":"urbana","polo":false},
				{"quartiere":3,"id_strada":10,"tipo_strada":"urbana","polo":true},
				{"quartiere":3,"id_strada":6,"tipo_strada":"urbana","polo":true},
			],
			strada_mancante: 3,
		},
		{
			id: "i5",
			strade:[
				{"quartiere":3,"id_strada":9,"tipo_strada":"urbana","polo":false},
				{"quartiere":3,"id_strada":13,"tipo_strada":"urbana","polo":true},
				{"quartiere":3,"id_strada":11,"tipo_strada":"urbana","polo":false},
			],
			strada_mancante:1,
		},
		{
			id: "i6",
			strade:[
				{"quartiere":3,"id_strada":13,"tipo_strada":"urbana","polo":false},
				{"quartiere":3,"id_strada":14,"tipo_strada":"urbana","polo":false},
				{"quartiere":3,"id_strada":12,"tipo_strada":"urbana","polo":false},
			],
			strada_mancante:0,
		},
		{
			id: "i7",
			strade:[
				{"quartiere":3,"id_strada":8,"tipo_strada":"urbana","polo":false},
				{"quartiere":3,"id_strada":14,"tipo_strada":"urbana","polo":true},
				{"quartiere":3,"id_strada":4,"tipo_strada":"urbana","polo":false},
			],
			strada_mancante:2,
		},
	],/*
	strade_ingresso:[
		{"id": 1,"lunghezza": 50,"numcorsie":1,"strada_confinante":1,"polo":true,"distanza_da_from":200},
		{"id": 2,"lunghezza": 100,"numcorsie":1,"strada_confinante":4,"polo":true,"distanza_da_from":150},
		{"id": 4,"lunghezza": 50,"numcorsie":1,"strada_confinante":4,"polo":true,"distanza_da_from":320},
		{"id": 3,"lunghezza": 50,"numcorsie":1,"strada_confinante":4,"polo":false,"distanza_da_from":200},
	],*/
	luoghi:[/*
		{
			id_luogo: 1,
			nome: "UniPD",
			tipologia: "lavoro",
			idstrada: 1,
			dimensioni: [50,30],
			capienza_macchine: 70,
			capienza_persone: 1000,
			capienza_bici: 100,
		},
		{
			id: 2,
			nome: "Parcheggio",
			tipologia: "parcheggio",
			idstrada: 2,
			dimensioni: [50,30],
			capienza_macchine: 100,
			capienza_persone: 1000,
			capienza_bici: 0,
		},
		{
			id: 3,
			nome: "Ospedale",
			tipologia: "lavoro",
			idstrada: 3,
			dimensioni: [50,30],
			capienza_macchine: 500,
			capienza_persone: 5000,
			capienza_bici: 500,
		},
	*/]
}