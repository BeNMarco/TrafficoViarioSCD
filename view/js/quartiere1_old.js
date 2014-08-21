var quartiere1 = {
	info:{
		id: 1,
		larghezza: 2000,
		altezza: 1500,
		riferimento: null,
	},
	strade:[
		{"id": 1,"lunghezza": 250,"from":[0,300],"to":[300,0],"numcorsie":2},
		{"id": 2,"lunghezza": 50,"from":[300,0],"to":[500,0],"numcorsie":2},
		{"id": 3,"lunghezza": 50,"from":[500,0],"to":[900,0],"numcorsie":2},
		{"id": 4,"lunghezza": 50,"from":[900,0],"to":[1000,0],"numcorsie":2},
		{"id": 5,"lunghezza": 50,"from":[1000,0],"to":[1400,0],"numcorsie":2},
		{"id": 6,"lunghezza": 50,"from":[1400,0],"to":[1800,0],"numcorsie":2},
		{"id": 7,"lunghezza": 50,"from":[1800,0],"to":[2000,0],"numcorsie":2},

		{"id": 8,"lunghezza": 50,"from":[0,300],"to":[0,600],"numcorsie":2},
		{"id": 9,"lunghezza": 50,"from":[0,600],"to":[0,1100],"numcorsie":2},
		{"id": 10,"lunghezza": 50,"from":[0,1100],"to":[0,1500],"numcorsie":2},

		{"id": 11,"lunghezza": 50,"from":[2000,0],"to":[2000,300],"numcorsie":2},
		{"id": 12,"lunghezza": 50,"from":[2000,300],"to":[2000,600],"numcorsie":2},
		{"id": 13,"lunghezza": 50,"from":[2000,600],"to":[2000,1100],"numcorsie":2},

		{"id": 14,"lunghezza": 250,"from":[2000,1100],"to":[2000,1500],"numcorsie":2},

		{"id": 15,"lunghezza": 50,"from":[0,1100],"to":[500,1100],"numcorsie":2},
		{"id": 16,"lunghezza": 50,"from":[500,1100],"to":[1500,1100],"numcorsie":2},
		{"id": 17,"lunghezza": 50,"from":[500,1100],"to":[500,1500],"numcorsie":2},
		{"id": 18,"lunghezza": 50,"from":[500,1500],"to":[1500,1500],"numcorsie":2},
		{"id": 19,"lunghezza": 50,"from":[1500,1100],"to":[1500,1500],"numcorsie":2},
		{"id": 20,"lunghezza": 50,"from":[1500,600],"to":[1500,1100],"numcorsie":2},

		{"id": 21,"lunghezza": 50,"from":[1500,1100],"to":[2000,1100],"numcorsie":2},
		{"id": 22,"lunghezza": 50,"from":[1500,600],"to":[2000,600],"numcorsie":2},

		{"id": 23,"lunghezza": 50,"from":[1800,0],"to":[1650,250],"numcorsie":2},
		{"id": 24,"lunghezza": 50,"from":[1650,250],"to":[2000,300],"numcorsie":2},
		{"id": 25,"lunghezza": 50,"from":[1650,250],"to":[1500,600],"numcorsie":2},
		{"id": 26,"lunghezza": 50,"from":[1400,0],"to":[1650,250],"numcorsie":2},
		{"id": 27,"lunghezza": 50,"from":[1000,0],"to":[1500,600],"numcorsie":2},

		{"id": 28,"lunghezza": 50,"from":[900,0],"to":[700,450],"numcorsie":2},
		{"id": 29,"lunghezza": 50,"from":[500,0],"to":[700,450],"numcorsie":2},
		{"id": 30,"lunghezza": 50,"from":[300,0],"to":[700,450],"numcorsie":2},
		{"id": 31,"lunghezza": 50,"from":[400,600],"to":[700,450],"numcorsie":2},

		{"id": 32,"lunghezza": 50,"from":[0,300],"to":[400,600],"numcorsie":2},
		{"id": 33,"lunghezza": 50,"from":[0,600],"to":[400,600],"numcorsie":2},
		{"id": 34,"lunghezza": 50,"from":[400,600],"to":[500,1100],"numcorsie":2},

	],
	incroci_a_4:[
		{
			id: "i1",
			strade:[
				{"quartiere":1,"id_strada":34,"tipo_strada":"urbana","polo":false},
				{"quartiere":1,"id_strada":16,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":17,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":15,"tipo_strada":"urbana","polo":false},
			]
		},
		{
			id: "i2",
			strade:[
				{"quartiere":1,"id_strada":20,"tipo_strada":"urbana","polo":false},
				{"quartiere":1,"id_strada":21,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":19,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":16,"tipo_strada":"urbana","polo":false},
			]
		},
		{
			id: "i6",
			strade:[
				{"quartiere":1,"id_strada":25,"tipo_strada":"urbana","polo":false},
				{"quartiere":1,"id_strada":22,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":20,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":27,"tipo_strada":"urbana","polo":false},
			]
		},
		{
			id: "i7",
			strade:[
				{"quartiere":1,"id_strada":23,"tipo_strada":"urbana","polo":false},
				{"quartiere":1,"id_strada":24,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":25,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":26,"tipo_strada":"urbana","polo":false},
			]
		},
		{
			id: "i14",
			strade:[
				{"quartiere":1,"id_strada":29,"tipo_strada":"urbana","polo":false},
				{"quartiere":1,"id_strada":28,"tipo_strada":"urbana","polo":false},
				{"quartiere":1,"id_strada":31,"tipo_strada":"urbana","polo":false},
				{"quartiere":1,"id_strada":30,"tipo_strada":"urbana","polo":false},
			]
		},
		{
			id: "i18",
			strade:[
				{"quartiere":1,"id_strada":32,"tipo_strada":"urbana","polo":false},
				{"quartiere":1,"id_strada":31,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":34,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":33,"tipo_strada":"urbana","polo":false},
			]
		},
	],
	incroci_a_3:[
		{
			id: "i3",
			strade:[
				{"quartiere":1,"id_strada":13,"tipo_strada":"urbana","polo":false},
				//null,
				{"quartiere":1,"id_strada":14,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":21,"tipo_strada":"urbana","polo":false},
			],
			strada_mancante: 1,
		},
		{
			id: "i4",
			strade:[
				{"quartiere":1,"id_strada":12,"tipo_strada":"urbana","polo":false},
				//null,
				{"quartiere":1,"id_strada":13,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":22,"tipo_strada":"urbana","polo":false},
			],
			strada_mancante: 1,
		},
		{
			id: "i5",
			strade:[
				{"quartiere":1,"id_strada":11,"tipo_strada":"urbana","polo":false},
				//null,
				{"quartiere":1,"id_strada":12,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":24,"tipo_strada":"urbana","polo":false},
			],
			strada_mancante: 1,
		},
		{
			id: "i8",
			strade:[
				//null,
				{"quartiere":1,"id_strada":7,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":23,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":6,"tipo_strada":"urbana","polo":false},
			],
			strada_mancante: 0,
		},
		{
			id: "i9",
			strade:[
				//null,
				{"quartiere":1,"id_strada":6,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":26,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":5,"tipo_strada":"urbana","polo":false},
			],
			strada_mancante: 0,
		},
		{
			id: "i10",
			strade:[
				//null,
				{"quartiere":1,"id_strada":5,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":27,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":4,"tipo_strada":"urbana","polo":false},
			],
			strada_mancante: 0,
		},
		{
			id: "i11",
			strade:[
				//null,
				{"quartiere":1,"id_strada":4,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":28,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":3,"tipo_strada":"urbana","polo":false},
			],
			strada_mancante: 0,
		},
		{
			id: "i12",
			strade:[
				//null,
				{"quartiere":1,"id_strada":3,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":29,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":2,"tipo_strada":"urbana","polo":false},
			],
			strada_mancante: 0,
		},
		{
			id: "i13",
			strade:[
				//null,
				{"quartiere":1,"id_strada":2,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":30,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":1,"tipo_strada":"urbana","polo":false},
			],
			strada_mancante: 0,
		},
		{
			id: "i15",
			strade:[
				{"quartiere":1,"id_strada":1,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":32,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":8,"tipo_strada":"urbana","polo":true},
				//null,
			],
			strada_mancante: 3,
		},
		{
			id: "i16",
			strade:[
				{"quartiere":1,"id_strada":8,"tipo_strada":"urbana","polo":false},
				{"quartiere":1,"id_strada":33,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":9,"tipo_strada":"urbana","polo":true},
				//null,
			],
			strada_mancante: 3,
		},
		{
			id: "i17",
			strade:[
				{"quartiere":1,"id_strada":9,"tipo_strada":"urbana","polo":false},
				{"quartiere":1,"id_strada":15,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":10,"tipo_strada":"urbana","polo":true},
				//null,
			],
			strada_mancante: 3,
		},
		{
			id: "i19",
			strade:[
				{"quartiere":3,"id_strada":1,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":11,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":7,"tipo_strada":"urbana","polo":false},
				//null,
			],
			strada_mancante: 0,
		},
		{
			id: "i20",
			strade:[
				{"quartiere":1,"id_strada":17,"tipo_strada":"urbana","polo":false},
				{"quartiere":1,"id_strada":18,"tipo_strada":"urbana","polo":true},
				{"quartiere":2,"id_strada":3,"tipo_strada":"urbana","polo":true},
				//null,
			],
			strada_mancante: 3,
		},
		{
			id: "i21",
			strade:[
				{"quartiere":1,"id_strada":19,"tipo_strada":"urbana","polo":false},
				{"quartiere":2,"id_strada":11,"tipo_strada":"urbana","polo":true},
				{"quartiere":1,"id_strada":18,"tipo_strada":"urbana","polo":false},
				//null,
			],
			strada_mancante: 1,
		},
	],
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