#!/usr/bin/python
import json
import sys



def main(num_quartieri):
	input_param_valid=False;
	if num_quartieri.isdigit():
		num_quartieri=int(num_quartieri)
		if num_quartieri>0:
			input_param_valid=True

	
	if input_param_valid:
		input_jsons={}
		num_incroci_urbana={}
		fermate_quartieri={}
		linee_autobus_is_set=False
		id_quartiere_linee_autobus=0
		for id in range(0,num_quartieri):
			with open('data/quartiere' + str(id+1) + '.json') as data_file:    
				input_jsons[id+1]=json.load(data_file)

		for id in range(0,num_quartieri):
			if len(input_jsons[id+1]["strade_urbane"])==0:
				raise Exception("Errore quartiere " + str(id+1) + ", almeno un elemento in strade_urbane deve essere inserito")
			
			hash_urbane={}
			id_prog=1		
			num_incroci_urbana[id+1]={}
			fermate_quartieri[id+1]={}	
			for elemento in input_jsons[id+1]["strade_urbane"]:
				if elemento["id"]!=id_prog:
					raise Exception("Errore quartiere " + str(id+1) + ": Gli id delle strade urbane devono essere progressivi e partire da 1, errore da id " + str(id_prog))
				hash_urbane[id_prog]=[]
				num_incroci_urbana[id+1][id_prog]=0
				id_prog=id_prog+1

			#print num_incroci_urbana[id+1]

			if len(input_jsons[id+1]["strade_ingresso"])<1:
					raise Exception("Errore quartiere " + str(id+1) + ": Necessaria almeno la presenza di un luogo e quindi di una strada d'ingresso")

			id_prog=1			
			for elemento in input_jsons[id+1]["strade_ingresso"]:
				if elemento["id"]!=id_prog:
					raise Exception("Errore quartiere " + str(id+1) + ": Gli id delle strade ingresso devono essere progressivi e partire da 1, errore da id " + str(id_prog))
				if not(elemento["strada_confinante"]>=1 and elemento["strada_confinante"]<=len(input_jsons[id+1]["strade_urbane"])):
					raise Exception("Errore quartiere " + str(id+1) + ": La strada confinante per l'ingresso " + str(id_prog) + " non esiste")
				hash_urbane[elemento["strada_confinante"]].append(id_prog)
				id_prog=id_prog+1

			#print hash_urbane
			for id_urbana in range(1,len(input_jsons[id+1]["strade_urbane"])+1):
				for id_ingresso in hash_urbane[id_urbana]:
					if hash_urbane[id_urbana].index(id_ingresso)==0:
						if input_jsons[id+1]["strade_ingresso"][id_ingresso-1]["distanza_da_from"]<60.0:
							raise Exception("Errore quartiere " + str(id+1) + ": La strada d'ingresso " + str(id_ingresso) + " e' a distanza minore di 60 rispetto a distanza_from")
						if len(hash_urbane[id_urbana])==1:
							if input_jsons[id+1]["strade_urbane"][id_urbana-1]["lunghezza"]-input_jsons[id+1]["strade_ingresso"][id_ingresso-1]["distanza_da_from"]<60.0:
								raise Exception("Errore quartiere " + str(id+1) + ": La strada d'ingresso " + str(id_ingresso) + " e' a distanza minore di 60 rispetto alla fine della strada")
					elif hash_urbane[id_urbana].index(id_ingresso)==(len(hash_urbane[id_urbana])-1):
						if input_jsons[id+1]["strade_urbane"][id_urbana-1]["lunghezza"]-input_jsons[id+1]["strade_ingresso"][id_ingresso-1]["distanza_da_from"]<60.0:
							raise Exception("Errore quartiere " + str(id+1) + ": La strada d'ingresso " + str(id_ingresso) + " e' a distanza minore di 60 rispetto alla fine della strada")
					
					if hash_urbane[id_urbana].index(id_ingresso)>0:
						prec_id_ingresso=hash_urbane[id_urbana][hash_urbane[id_urbana].index(id_ingresso)-1]
						if input_jsons[id+1]["strade_ingresso"][id_ingresso-1]["distanza_da_from"]-input_jsons[id+1]["strade_ingresso"][prec_id_ingresso-1]["distanza_da_from"]<60.0:
							raise Exception("Errore quartiere " + str(id+1) + ": La strada d'ingresso " + str(id_ingresso) + " e' a distanza minore di 60 rispetto all'ingresso precedente " + str(prec_id_ingresso))
							
					#print list_ingressi
					#for i in range(0,len(list_ingressi)+1):
					#	id_prog=1

			if len(input_jsons[id+1]["strade_ingresso"])!=len(input_jsons[id+1]["luoghi"]):
				raise Exception("Errore quartiere " + str(id+1) + ": E' stato inserito un numero di luoghi diverso rispetto al numero di ingressi")

			id_prog=1
			for luogo in input_jsons[id+1]["luoghi"]:
				if luogo["id_luogo"]!=id_prog or luogo["id_luogo"]!=id_prog:
					raise Exception("Errore quartiere " + str(id+1) + ": Inserire i luoghi con index progressivo a partire da 1")
				id_prog=id_prog+1

			for id_urbana in range(1,len(input_jsons[id+1]["strade_urbane"])+1):
				segnale=False
				for id_ingresso in hash_urbane[id_urbana]:
					if input_jsons[id+1]["luoghi"][id_ingresso-1]["tipologia"]=="fermata":
						if segnale:
							raise Exception("Errore quartiere " + str(id+1) + ": L'urbana " + str(id_urbana) + " non puo' avere piu' id un luogo adibito a tipo stazione o fermata.")
						segnale=True
						# viene inizializzato a False per indicare che la fermata non e' presente in nessuna linea
						fermate_quartieri[id+1][id_ingresso]=False
					if input_jsons[id+1]["luoghi"][id_ingresso-1]["tipologia"]=="stazione":
						if segnale:
							raise Exception("Errore quartiere " + str(id+1) + ": L'urbana " + str(id_urbana) + " non puo' avere piu' id un luogo adibito a tipo stazione o fermata.")
						segnale=True
					if input_jsons[id+1]["luoghi"][id_ingresso-1]["tipologia"]=="stazione" and len(hash_urbane[id_urbana])>1:
						raise Exception("Errore quartiere " + str(id+1) + ": L'urbana " + str(id_urbana) + " avendo gia' un luogo di tipo stazione ovvero l'ingresso " + str(id_ingresso) + " non puo' avere altri luoghi, ne abitati ne fermate.")

				if segnale==False and len(hash_urbane[id_urbana])>0:
					raise Exception("Errore quartiere " + str(id+1) + ": L'urbana " + str(id_urbana) + " non ha un luogo adibito a fermata. Tale fermata e' necessaria data la presenza di almeno un ingresso su tale strada.")

			if (len(input_jsons[id+1]["fermate_autobus"])!=0 and len(input_jsons[id+1]["autobus"])==0) or (len(input_jsons[id+1]["fermate_autobus"])==0 and len(input_jsons[id+1]["autobus"])!=0):
				raise Exception("Errore quartiere " + str(id+1) + ": Non possono esserci delle linee autobus senza gli autobus (e viceversa)")
			if (len(input_jsons[id+1]["fermate_autobus"])>0 and len(input_jsons[id+1]["autobus"])>0):
				if linee_autobus_is_set:
					raise Exception("Errore quartiere " + str(id+1) + ": Un quartiere con le fermate configurate e' gia' presente")
				linee_autobus_is_set=True
				id_quartiere_linee_autobus=id+1


		#for i in range(1,num_quartieri+1):
		#	print fermate_quartieri[i]

		if linee_autobus_is_set==False: 
			raise Exception("Errore nessun quartiere ha le linee delle fermate settate")
    
    	# qui sono state create le strade di tutti gli incroci
		type_incroci=["incroci_a_4","incroci_a_3"]
		for id in range(0,num_quartieri):
			for tipo_incrocio in type_incroci:
				for incrocio in input_jsons[id+1][tipo_incrocio]:
					for strada in incrocio["strade"]:
						if not (strada["quartiere"]>0 and strada["quartiere"]<=num_quartieri): 
							raise Exception("Errore quartiere " + str(id+1) + ": Errore in id incrocio " + incrocio["id"]+ ", strada inserita con un numero di quartiere inesistente")
						if not (strada["id_strada"]>=1 and strada["id_strada"]<=len(input_jsons[strada["quartiere"]]["strade_urbane"])):
							raise Exception("Errore quartiere " + str(id+1) + ": Errore in id incrocio " + incrocio["id"]+ ", strada inserita con un id inesistente")
						num_incroci_urbana[strada["quartiere"]][strada["id_strada"]]=num_incroci_urbana[strada["quartiere"]][strada["id_strada"]]+1
						if num_incroci_urbana[strada["quartiere"]][strada["id_strada"]]>2:
							raise Exception("Errore quartiere " + str(id+1) + ": Errore in id incrocio " + incrocio["id"]+ ", la strada " + str(strada["id_strada"]) + " ha gia' 2 estremi")
					if tipo_incrocio=="incroci_a_3":
						if not(incrocio["strada_mancante"]>=0 and incrocio["strada_mancante"]<=3):
							raise Exception("Errore quartiere " + str(id+1) + ": Errore in id incrocio " + incrocio["id"]+ ", la strada mancante non ha un indice compreso tra 0 e 3")


		type_mezzi=["bici","auto","pedoni"]
		for id in range(0,num_quartieri):
			id_prog=1
			for abitante in input_jsons[id+1]["abitanti"]:
				segnale=False
				if abitante["id_abitante"]==id_prog:
					if abitante["id_luogo_casa"]>=1 and abitante["id_luogo_casa"]<=len(input_jsons[id+1]["strade_ingresso"]):
						if input_jsons[id+1]["luoghi"][abitante["id_luogo_casa"]-1]["tipologia"]=="fermata":
							raise Exception("Errore quartiere " + str(id+1) + ": Errore id_abitante " + str(id_prog) + ": Luogo casa non puo' essere una fermata")
						if abitante["id_quartiere_luogo_lavoro"]>=1 and abitante["id_quartiere_luogo_lavoro"]<=num_quartieri:
							if abitante["id_luogo_lavoro"]>=1 and abitante["id_luogo_lavoro"]<=len(input_jsons[abitante["id_quartiere_luogo_lavoro"]]["strade_ingresso"]):
								if input_jsons[abitante["id_quartiere_luogo_lavoro"]]["luoghi"][abitante["id_luogo_lavoro"]-1]["tipologia"]=="fermata":
									raise Exception("Errore quartiere " + str(id+1) + ": Errore id_abitante " + str(id_prog) + ": Luogo lavoro non puo' essere una fermata")							
								segnale=True
							else:
								raise Exception("Errore quartiere " + str(id+1) + ": Errore id_abitante " + str(id_prog) + ": Luogo lavoro non in range del quartiere di lavoro")
						else:
							raise Exception("Errore quartiere " + str(id+1) + ": Errore id_abitante " + str(id_prog) + ": quartiere luogo lavoro non e' un quartiere valido")
					else:
						raise Exception("Errore quartiere " + str(id+1) + ": Errore id_abitante " + str(id_prog) + ": Luogo casa non in range dei luoghi del quartiere")
				else:
					raise Exception("Errore quartiere " + str(id+1) + ": Errore id_abitante " + str(id_prog) + ": numerazione progressiva errata (partendo da 1)")
				id_prog=id_prog+1


			for tipo_mezzo in type_mezzi:
				if tipo_mezzo=="auto":
					if len(input_jsons[id+1][tipo_mezzo])!=(len(input_jsons[id+1]["abitanti"])+len(input_jsons[id+1]["autobus"])):
						raise Exception("Errore quartiere " + str(id+1) + ": Errore in array " + tipo_mezzo + ": occorre inserire un numero di elementi pari alla sommatoria della dimensione dell'array di abitanti e autobus")
				else:
					if len(input_jsons[id+1][tipo_mezzo])!=len(input_jsons[id+1]["abitanti"]):
						raise Exception("Errore quartiere " + str(id+1) + ": Errore in array " + tipo_mezzo + ": occorre inserire un numero di elementi pari alla dimensione dell'array abitanti")
				id_prog=1
				for abitante in input_jsons[id+1][tipo_mezzo]:
					if abitante["id_abitante"]!=id_prog:
						raise Exception("Errore quartiere " + str(id+1) + ": Errore in array " + tipo_mezzo + ": occorre inserire gli elementi con numerazione progressiva a partire da 1. Errore rilevato da " + str(id_prog))
					id_prog=id_prog+1

			for ab_in_bus in input_jsons[id+1]["abitanti_in_bus"]:
				if not(ab_in_bus>=1 and ab_in_bus<=len(input_jsons[id+1]["abitanti"])):
					raise Exception("Errore quartiere " + str(id+1) + ": Errore in array abitanti_in_bus, indici inseriti non corrispondenti ad abitanti, indice errato: " + str(ab_in_bus))
 		
 		num_linea=1
 		linea_for_quartiere={}
 		for i in range(1,num_quartieri+1):
 			linea_for_quartiere[i]=False

 		for wrap in input_jsons[id_quartiere_linee_autobus]["fermate_autobus"]:
 			linea=wrap[0]
 			if linea["from_to"][0]!=linea["from_to"][1]:
				raise Exception("Errore quartiere " + str(id_quartiere_linee_autobus) + ": Errore in set from_to on linea. Devono essere uguali. Linea " + str(num_linea))
			if not(linea["from_to"][0]>=1 and linea["from_to"][0]<=num_quartieri):
				raise Exception("Errore quartiere " + str(id_quartiere_linee_autobus) + ": Errore in set from_to on linea. Non si riferiscono a un quartiere valido. Linea " + str(num_linea))				
			if linea_for_quartiere[linea["from_to"][0]]:
				raise Exception("Errore quartiere " + str(id_quartiere_linee_autobus) + ": Errore in set from_to on linea. Linea gia' settata, togliere duplicati")								
			linea_for_quartiere[linea["from_to"][0]]=True
			num_fermata=1
			for fermata_linea in linea["linea"]:
				if fermata_linea[0]!=linea["from_to"][0]:
					raise Exception("Errore quartiere " + str(id_quartiere_linee_autobus) + ": Errore in set quartiere fermata on linea. Deve essere sempre uguale a quello riportato in from_to. Num fermata errata " + str(num_fermata) + " linea " + str(num_linea))
				if not(fermata_linea[1]>=1 and fermata_linea[1]<=len(input_jsons[linea["from_to"][0]]["luoghi"])):
					raise Exception("Errore quartiere " + str(id_quartiere_linee_autobus) + ": Errore in set id fermata on linea: num_fermata " + str(num_fermata) + " linea " + str(num_linea))
				if input_jsons[linea["from_to"][0]]["luoghi"][fermata_linea[1]-1]["tipologia"]!="fermata":
					raise Exception("Errore quartiere " + str(id_quartiere_linee_autobus) + ": Errore in set id fermata on linea: num_fermata " + str(num_fermata) + " linea " + str(num_linea) + " l'elemento inserito e' un luogo, ma non e' una fermata")
				fermate_quartieri[linea["from_to"][0]][fermata_linea[1]]=True
				num_fermata=num_fermata+1

			jolly_to={}
			for i in range(1,num_quartieri+1):
				if i!=linea["from_to"][0]:
					jolly_to[i]=False

			for jolly in linea["jolly"]:
				if jolly_to[jolly["to"]]:
					raise Exception("Errore quartiere " + str(id_quartiere_linee_autobus) + ": Jolly to quartiere " + str(jolly["to"]) + " gia' settato in linea " + str(num_linea))
				jolly_to[jolly["to"]]=True
				if jolly["at"][0]!=jolly["to"]:
					raise Exception("Errore quartiere " + str(id_quartiere_linee_autobus) + ": La fermata a cui il jolly e' destinato non e' la stessa del campo to in linea " + str(num_linea) + " per jolly to " + str(jolly["at"][0]))
				if not(jolly["at"][1]>=1 and jolly["at"][1]<=len(input_jsons[jolly["to"]]["strade_ingresso"])):
					raise Exception("Errore quartiere " + str(id_quartiere_linee_autobus) + ": Il luogo di destinazione non e' un ingresso valido in set jolly to " + str(jolly["at"][0]) + " in linea " + str(num_linea))
				if input_jsons[jolly["at"][0]]["luoghi"][jolly["at"][1]-1]["tipologia"]!="fermata":
					raise Exception("Errore quartiere " + str(id_quartiere_linee_autobus) + ": Il luogo di destinazione non e' una fermata valida in set jolly to " + str(jolly["at"][0]) + " in linea " + str(num_linea))
					


			num_linea=num_linea+1

 		for i in range(1,num_quartieri+1):
 			if linea_for_quartiere[i]==False:
 				raise Exception("Errore quartiere " + str(id_quartiere_linee_autobus) + ": Linea for quartiere " + str(i) + " non configurata")

 		for i in range(1,num_quartieri+1):
 			for fermata in fermate_quartieri[i]:
 				if fermate_quartieri[i][fermata]==False:
 					raise Exception("Errore quartiere " + str(id_quartiere_linee_autobus) + ": Linea per quartiere " + str(i) + " non completata, mancano fermate")

 		autobus_cfg={}
 		for i in range(1,num_quartieri+1):
 			autobus_cfg[i]={}
 			autobus_cfg[i]["is_set"]=False
 			autobus_cfg[i]["jolly_to"]={}
 			for j in range(1,num_quartieri+1):
 				if i!=j:
 					autobus_cfg[i]["jolly_to"][j]=False

 		id_prog=1
 		for bus in input_jsons[id_quartiere_linee_autobus]["autobus"]:
 			if bus["id_autobus"]!=id_prog:
				raise Exception("Errore quartiere " + str(id_quartiere_linee_autobus) + ": Autobus non ha un id progressivo a partire da 1, errore da " + str(id_prog))
			if not(bus["stazione_partenza"]>=1 and bus["stazione_partenza"]<=len(input_jsons[id_quartiere_linee_autobus]["strade_ingresso"])):
				raise Exception("Errore quartiere " + str(id_quartiere_linee_autobus) + ": Autobus non ha una stazione di partenza valida")
			if input_jsons[id_quartiere_linee_autobus]["luoghi"][bus["stazione_partenza"]-1]["tipologia"]!="stazione":
				raise Exception("Errore quartiere " + str(id_quartiere_linee_autobus) + ": Autobus non ha una stazione di partenza valida")
			if not(bus["linea"]>=1 and bus["linea"]<=num_quartieri):
				raise Exception("Errore quartiere " + str(id_quartiere_linee_autobus) + ": Autobus " + str(id_prog) + " non ha una linea valida")
			if bus["jolly"]==False:
				autobus_cfg[bus["linea"]]["is_set"]=True
			if bus["jolly"]:
				if not(bus["jolly_to_quartiere"]>=1 and bus["jolly_to_quartiere"]<=num_quartieri):
					raise Exception("Errore quartiere " + str(id_quartiere_linee_autobus) + ": Autobus " + str(id_prog) + " non ha un jolly_to_quartiere valido")
				if bus["jolly_to_quartiere"]==bus["linea"]:
					raise Exception("Errore quartiere " + str(id_quartiere_linee_autobus) + ": Autobus " + str(id_prog) + " non deve avere jolly_to_quartiere uguale al numero di linea")					
				autobus_cfg[bus["linea"]]["jolly_to"][bus["jolly_to_quartiere"]]=True
			id_prog=id_prog+1

		for id_quartiere in autobus_cfg:
			cfg_bus=autobus_cfg[id_quartiere]
			if cfg_bus["is_set"]==False:
				raise Exception("Errore quartiere " + str(id_quartiere_linee_autobus) + ": Autobus per linea " + str(id_quartiere) + " non configurato")
			for jolly_to_quart in cfg_bus["jolly_to"]:
				if cfg_bus["jolly_to"][jolly_to_quart]==False:
					raise Exception("Errore quartiere " + str(id_quartiere_linee_autobus) + ": Autobus per linea " + str(id_quartiere) + " non ha configurato il jolly per " + str(jolly_to_quart))

		print "Mappa valida."
	else:
		print "Inserire come parametro un numero positivo, rappresentante il numero di quartieri"





















if __name__ == "__main__":
    main(sys.argv[1])
