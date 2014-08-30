with Ada.Text_IO;
--with Ada.Task_Identification;
--with Ada.Dynamic_Priorities;
--with System;

with strade_e_incroci_common;

use Ada.Text_IO;
--use Ada.Task_Identification;
--use Ada.Dynamic_Priorities;
--use System;

use strade_e_incroci_common;

package body gps_utilities is

   -- begin get methods index_incrocio
   function get_id_quartiere_index_incroci(incrocio: index_incroci) return Natural is
   begin
      return incrocio.id_quartiere;
   end get_id_quartiere_index_incroci;
   function get_id_incrocio_index_incroci(incrocio: index_incroci) return Natural is
   begin
      return incrocio.id_incrocio;
   end get_id_incrocio_index_incroci;
   function get_polo_index_incroci(incrocio: index_incroci) return Boolean is
   begin
      return incrocio.polo;
   end get_polo_index_incroci;
   -- end get methods index_incrocio

      -- begin get methods adiacente
   function get_id_quartiere_strada(near: adiacente) return Natural is
   begin
      return near.id_quartiere_strada;
   end get_id_quartiere_strada;
   function get_id_strada(near: adiacente) return Natural is
   begin
      return near.id_strada;
   end get_id_strada;
   function get_id_quartiere_adiacente(near: adiacente) return Natural is
   begin
      return near.id_quartiere_adiacente;
   end get_id_quartiere_adiacente;
   function get_id_adiacente(near: adiacente) return Natural is
   begin
      return near.id_adiacente;
   end get_id_adiacente;
   -- end get methods adiacente

   function create_new_index_incrocio(val_id_quartiere: Natural; val_id_incrocio: Natural; val_polo: Boolean) return index_incroci is
      ptr_index_incrocio: index_incroci;
   begin
      ptr_index_incrocio.id_quartiere:= val_id_quartiere;
      ptr_index_incrocio.id_incrocio:= val_id_incrocio;
      ptr_index_incrocio.polo:= val_polo;
      return ptr_index_incrocio;
   end create_new_index_incrocio;

   function create_new_adiacente(val_id_quartiere_strada: Natural; val_id_strada: Natural;
                                 val_id_quartiere_adiacente: Natural; val_id_adiacente: Natural) return adiacente is
      ptr_adiacente: adiacente;
   begin
      ptr_adiacente.id_quartiere_strada:= val_id_quartiere_strada;
      ptr_adiacente.id_strada:= val_id_strada;
      ptr_adiacente.id_quartiere_adiacente:= val_id_quartiere_adiacente;
      ptr_adiacente.id_adiacente:= val_id_adiacente;
      return ptr_adiacente;
   end create_new_adiacente;

   function create_list_percorso(segmento: tratto; next_percorso: ptr_percorso) return ptr_percorso is
      percorso: ptr_percorso:= new list_percorso;
   begin
      percorso.segmento:= tratto(segmento);
      percorso.next:= next_percorso;
      return percorso;
   end create_list_percorso;

   protected body registro_strade_resource is

      function create_array_percorso(size: Natural; route: ptr_percorso) return percorso is
         array_route: percorso(1..size);
         next_route: ptr_percorso:= route;
      begin
         for i in 1..size loop
            if next_route=null then
               return array_route;
            end if;
            array_route(i):=next_route.segmento;
            next_route:= next_route.next;
         end loop;
         return array_route;
      end create_array_percorso;

      procedure print_grafo is
      begin
         for i in grafo'Range
         loop
            for j in grafo(i)'Range
            loop
               for z in 1..4
               loop
                  Put_Line("Nodo:(" & Integer'Image(i) & "," & Integer'Image(j) & "), adiacente:[quartiere_spigolo:" & Integer'Image(grafo(i)(j)(z).get_id_quartiere_strada) & ",id_spigolo:"
                           & Integer'Image(grafo(i)(j)(z).get_id_strada) & ",quartiere_adiacente:" & Integer'Image(grafo(i)(j)(z).get_id_quartiere_adiacente) & ",id_adiacente:" & Integer'Image(grafo(i)(j)(z).get_id_adiacente) & "]");
               end loop;
            end loop;
         end loop;
      end print_grafo;

      function get_estremi_strade_urbane(id_quartiere: Positive) return estremi_strade_urbane is
         estremi: estremi_incrocio;
         hash_strade: access hash_quartiere_strade:= hash_urbane_quartieri(id_quartiere);
         return_estremi: estremi_strade_urbane(hash_strade'First..hash_strade'Last,1..2);
      begin
         --Put_Line("estremi urbana" & Any_Priority'Image(Get_Priority(Ada.Task_Identification.Current_Task)));
         --Put_Line("estremi id urbana " & Positive'Image(id_urbana));

         for i in hash_strade'Range loop
            estremi:= hash_urbane_quartieri(id_quartiere)(i);
            return_estremi(i,1):= create_estremo_urbana(estremi(1).id_quartiere,estremi(1).id_incrocio);
            return_estremi(i,2):= create_estremo_urbana(estremi(2).id_quartiere,estremi(2).id_incrocio);
         end loop;

         return return_estremi;
      end get_estremi_strade_urbane;

      function calcola_percorso(from_id_quartiere: Positive; from_id_luogo: Positive;
                                to_id_quartiere: Positive; to_id_luogo: Positive) return route_and_distance is
         coda_nodi: dijkstra_nodi(1..get_num_quartieri,min_first_incroci..max_last_incroci);
         to_consider: index_to_consider(1..numero_globale_incroci);
         new_from_id_luogo: Positive;
         new_to_id_luogo: Positive;
         num_elementi_lista: Natural:= 0;
         min_index_lista: Float:= Float'Last;
         last_index_lista: Natural:= 0;
         min_ottimo: Natural:= 0;
         size_route: Natural:= 0;
         ptr_route: ptr_percorso;
         segmento: tratto;
         estremi: estremi_incrocio;
         -- entrambi i valori di default sono settati correttamente per oostruzione
         pragma Warnings(off);
         default_dijkstra_nodo: dijkstra_nodo;
         default_index_incrocio: index_incroci;
         pragma Warnings(on);
         ingresso_partenza: strada_ingresso_features;
         ingresso_arrivo: strada_ingresso_features;
         estremo_1_partenza: index_incroci;
         estremo_2_partenza: index_incroci;
         estremo_1_arrivo: index_incroci;
         estremo_2_arrivo: index_incroci;
         continue: Boolean:= True;
         segnale: Boolean:= True;
         switch: Boolean:= False;
         switch_loop_percorso: Boolean:= False;
         id_incrocio_partenza: Positive;
         id_quartiere_partenza: Positive;
         id_incrocio_minimo: Positive;
         id_quartiere_minimo: Positive;
         adiacenti: list_adiacenti;
         spigolo: strada_urbana_features;
         index: Positive:= 1;
         distanza_estremo_1: Float;
         distanza_estremo_2: Float;
         distanza: Float;
         min_distanza: Float:= Float'Last;
         change_route: Boolean:= False;
         estremo_partenza: index_incroci;
         estremo_arrivo: index_incroci;
         estremo_intermedio: index_incroci;
         penultimo_estremo: index_incroci;
         estremo: index_incroci;
         estremo_to_consider: Boolean:= False; -- True se estremo_1, False se estremo_2
      begin
         new_from_id_luogo:= cache_ingressi(from_id_quartiere).all'First +from_id_luogo-1;
         new_to_id_luogo:= cache_ingressi(to_id_quartiere).all'First  +to_id_luogo-1;
         ingresso_partenza:= cache_ingressi(from_id_quartiere)(new_from_id_luogo);
         estremi:= hash_urbane_quartieri(from_id_quartiere)(ingresso_partenza.get_id_main_strada_ingresso);
         estremo_1_partenza:= estremi(1);
         estremo_2_partenza:= estremi(2);
         loop
            exit when continue = False or index>2;
            if index = 1 then
               if estremo_1_partenza.id_quartiere/=0 then
                  id_quartiere_partenza:= estremo_1_partenza.id_quartiere;
                  id_incrocio_partenza:= estremo_1_partenza.id_incrocio;
                  estremo_partenza:= estremo_1_partenza;
               else
                  continue:= False;
               end if;
            elsif index = 2 then
               if estremo_2_partenza.id_quartiere/=0 then
                  id_quartiere_partenza:= estremo_2_partenza.id_quartiere;
                  id_incrocio_partenza:= estremo_2_partenza.id_incrocio;
                  estremo_partenza:= estremo_2_partenza;
               else
                  continue:= False;
               end if;
            end if;
            if continue then
               if index=2 then
                  coda_nodi:= (others => (others => default_dijkstra_nodo));
                  to_consider:= (others => default_index_incrocio);
               end if;
               -- setto il nodo sorgente; gli altri nodi sono tutti a distanza infinita
               to_consider(1).id_quartiere:= id_quartiere_partenza;
               to_consider(1).id_incrocio:= id_incrocio_partenza;
               coda_nodi(id_quartiere_partenza,id_incrocio_partenza).precedente.id_quartiere:= 0;
               coda_nodi(id_quartiere_partenza,id_incrocio_partenza).precedente.id_incrocio:= 0;
               coda_nodi(id_quartiere_partenza,id_incrocio_partenza).distanza:= 0.0;
               coda_nodi(id_quartiere_partenza,id_incrocio_partenza).in_coda:= True;
               num_elementi_lista:= num_elementi_lista + 1;
               last_index_lista:= 1;
               loop
                  exit when num_elementi_lista = 0;
                  -- begin trova il minimo
                  min_index_lista:= Float'Last;
                  for i in 1..last_index_lista loop
                     if to_consider(i).id_quartiere/=0 then
                        if coda_nodi(to_consider(i).id_quartiere,to_consider(i).id_incrocio).distanza<min_index_lista then
                           min_index_lista:= coda_nodi(to_consider(i).id_quartiere,to_consider(i).id_incrocio).distanza;
                           min_ottimo:= i;
                        end if;
                     end if;
                  end loop;
                  -- end trova minimo
                  id_quartiere_minimo:= to_consider(min_ottimo).id_quartiere;
                  id_incrocio_minimo:= to_consider(min_ottimo).id_incrocio;
                  -- azzero l'incrocio in modo da non considerarlo più
                  to_consider(min_ottimo).id_quartiere:= 0;
                  to_consider(min_ottimo).id_incrocio:= 0;
                  num_elementi_lista:= num_elementi_lista - 1;
                  adiacenti:= grafo(id_quartiere_minimo)(id_incrocio_minimo);
                  for i in 1..4 loop
                     if adiacenti(i).id_quartiere_adiacente/=0 then -- se c'è un incrocio adiacente
                        if coda_nodi(adiacenti(i).id_quartiere_adiacente,adiacenti(i).id_adiacente).in_coda = False then
                           coda_nodi(adiacenti(i).id_quartiere_adiacente,adiacenti(i).id_adiacente).in_coda:= True;
                           num_elementi_lista:= num_elementi_lista + 1;
                           last_index_lista:= last_index_lista + 1;
                           to_consider(last_index_lista).id_quartiere:= adiacenti(i).id_quartiere_adiacente;
                           to_consider(last_index_lista).id_incrocio:= adiacenti(i).id_adiacente;
                        end if;
                        spigolo:= cache_urbane(adiacenti(i).id_quartiere_strada)(adiacenti(i).id_strada);
                        if coda_nodi(adiacenti(i).id_quartiere_adiacente,adiacenti(i).id_adiacente).distanza> spigolo.get_lunghezza_road + coda_nodi(id_quartiere_minimo,id_incrocio_minimo).distanza then
                           coda_nodi(adiacenti(i).id_quartiere_adiacente,adiacenti(i).id_adiacente).distanza:= coda_nodi(id_quartiere_minimo,id_incrocio_minimo).distanza + spigolo.get_lunghezza_road;
                           coda_nodi(adiacenti(i).id_quartiere_adiacente,adiacenti(i).id_adiacente).precedente.id_quartiere:= id_quartiere_minimo;
                           coda_nodi(adiacenti(i).id_quartiere_adiacente,adiacenti(i).id_adiacente).precedente.id_incrocio:= id_incrocio_minimo;
                           coda_nodi(adiacenti(i).id_quartiere_adiacente,adiacenti(i).id_adiacente).id_quartiere_spigolo:= spigolo.get_id_quartiere_road;
                           coda_nodi(adiacenti(i).id_quartiere_adiacente,adiacenti(i).id_adiacente).id_spigolo:= spigolo.get_id_road;
                        end if;
                     end if;
                  end loop;
               end loop;
               ingresso_arrivo:= cache_ingressi(to_id_quartiere)(new_to_id_luogo);
               estremi:= hash_urbane_quartieri(to_id_quartiere)(ingresso_arrivo.get_id_main_strada_ingresso);
               estremo_1_arrivo:= estremi(1);
               estremo_2_arrivo:= estremi(2);
               distanza_estremo_1:= Float'Last;
               distanza_estremo_2:= Float'Last;
               distanza:= Float'Last;
               estremo_arrivo:= estremo_1_arrivo;
               for indice in 1..2 loop
                  -- calcolo distanza_estremo
                  --Put_Line(Positive'Image(Positive(coda_nodi(estremo_arrivo.id_quartiere,estremo_arrivo.id_incrocio).distanza)));
                  if estremo_arrivo.id_quartiere/=0 then -- se esiste estremo
                     if coda_nodi(estremo_arrivo.id_quartiere,estremo_arrivo.id_incrocio).id_quartiere_spigolo = 0 then -- la sorgente è già il punto di arrivo
                        -- caso 1: la destinazione è sulla stessa strada della partenza
                        if ingresso_partenza.get_id_quartiere_road = ingresso_arrivo.get_id_quartiere_road and ingresso_partenza.get_id_main_strada_ingresso = ingresso_arrivo.get_id_main_strada_ingresso then
                           distanza:= abs(ingresso_arrivo.get_distance_from_road_head_ingresso-ingresso_partenza.get_distance_from_road_head_ingresso);
                           -- caso 2: la destinzazione non è sulla stessa strada della partenza
                        else
                           -- si somma prima il pezzo di strada dall'ingresso all'estremo di partenza
                           if estremo_partenza.polo then
                              distanza:= ingresso_partenza.get_distance_from_road_head_ingresso;
                           else
                              distanza:= cache_urbane(ingresso_partenza.get_id_quartiere_road)(ingresso_partenza.get_id_main_strada_ingresso).get_lunghezza_road-ingresso_partenza.get_distance_from_road_head_ingresso;
                           end if;
                           -- poi si applica il caso 2
                           if estremo_arrivo.polo then
                              distanza:= distanza+ingresso_arrivo.get_distance_from_road_head_ingresso;
                           else
                              distanza:= distanza+cache_urbane(ingresso_arrivo.get_id_quartiere_road)(ingresso_arrivo.get_id_main_strada_ingresso).get_lunghezza_road-ingresso_arrivo.get_distance_from_road_head_ingresso;
                           end if;
                        end if;
                     -- la sorgente non è il punto di arrivo
                     -- se lo spigolo che congiunge l'estremo di arrivo e il suo precedente è lo stesso della strada principale della strada d'ingresso d'arrivo
                     elsif coda_nodi(estremo_arrivo.id_quartiere,estremo_arrivo.id_incrocio).id_quartiere_spigolo = ingresso_arrivo.get_id_quartiere_road and coda_nodi(estremo_arrivo.id_quartiere,estremo_arrivo.id_incrocio).id_spigolo = ingresso_arrivo.get_id_main_strada_ingresso then
                        -- se il precedente è proprio l'estremo di partenza
                        if coda_nodi(estremo_arrivo.id_quartiere,estremo_arrivo.id_incrocio).precedente.id_quartiere=estremo_partenza.id_quartiere and coda_nodi(estremo_arrivo.id_quartiere,estremo_arrivo.id_incrocio).precedente.id_incrocio=estremo_partenza.id_incrocio then
                           -- caso 1: già visto prima
                           if ingresso_partenza.get_id_quartiere_road = ingresso_arrivo.get_id_quartiere_road and ingresso_partenza.get_id_main_strada_ingresso = ingresso_arrivo.get_id_main_strada_ingresso then
                              distanza:= abs(ingresso_arrivo.get_distance_from_road_head_ingresso-ingresso_partenza.get_distance_from_road_head_ingresso);
                              -- caso 2: la destinzazione non è sulla stessa strada della partenza
                           else
                              -- si somma prima il pezzo di strada dall'ingresso all'estremo di partenza
                              if estremo_partenza.polo then
                                 distanza:= ingresso_partenza.get_distance_from_road_head_ingresso;
                              else
                                 distanza:= cache_urbane(ingresso_partenza.get_id_quartiere_road)(ingresso_partenza.get_id_main_strada_ingresso).get_lunghezza_road-ingresso_partenza.get_distance_from_road_head_ingresso;
                              end if;
                              -- poi si applica il caso 2 visto prima
                              if estremo_arrivo.polo then
                                 distanza:= distanza+ingresso_arrivo.get_distance_from_road_head_ingresso;
                              else
                                 distanza:= distanza+cache_urbane(ingresso_arrivo.get_id_quartiere_road)(ingresso_arrivo.get_id_main_strada_ingresso).get_lunghezza_road-ingresso_arrivo.get_distance_from_road_head_ingresso;
                              end if;
                           end if;
                           -- il precedente non è l'estremo di partenza
                        else
                           estremo_intermedio:= estremo_arrivo;
                           while coda_nodi(estremo_intermedio.id_quartiere,estremo_intermedio.id_incrocio).precedente.id_quartiere/=0 loop
                              penultimo_estremo:= estremo_intermedio;
                              estremo_intermedio:= coda_nodi(estremo_intermedio.id_quartiere,estremo_intermedio.id_incrocio).precedente;
                           end loop;
                           --grafo(estremo_intermedio.id_quartiere)(estremo_intermedio.id_incrocio)
                           switch:= False;
                           if index=1 then
                              if penultimo_estremo.id_quartiere=estremo_2_partenza.id_quartiere and penultimo_estremo.id_incrocio=estremo_2_partenza.id_incrocio then
                                 switch:= True;
                              end if;
                           else
                              if penultimo_estremo.id_quartiere=estremo_1_partenza.id_quartiere and penultimo_estremo.id_incrocio=estremo_1_partenza.id_incrocio then
                                 switch:= True;
                              end if;
                           end if;

                           -- in distanza va calcolato il pezzo di strada da aggiungere sottrarre in base al valore di switch
                           if estremo_partenza.polo then
                              distanza:= ingresso_partenza.get_distance_from_road_head_ingresso;
                           else
                              distanza:= cache_urbane(ingresso_partenza.get_id_quartiere_road)(ingresso_partenza.get_id_main_strada_ingresso).get_lunghezza_road-ingresso_partenza.get_distance_from_road_head_ingresso;
                           end if;

                           if switch then -- occorre sottrarre dalla distanza totale dato che il pezzo di strada da strada ingresso all'opposto dell'estremo di partenza
                              if estremo_arrivo.polo then
                                 distanza:= coda_nodi(estremo_arrivo.id_quartiere,estremo_arrivo.id_incrocio).distanza-ingresso_arrivo.get_distance_from_road_head_ingresso-distanza;
                              else
                                 distanza:= coda_nodi(estremo_arrivo.id_quartiere,estremo_arrivo.id_incrocio).distanza-(cache_urbane(ingresso_arrivo.get_id_quartiere_road)(ingresso_arrivo.get_id_main_strada_ingresso).get_lunghezza_road-ingresso_arrivo.get_distance_from_road_head_ingresso)-distanza;
                              end if;
                           else
                              if estremo_arrivo.polo then
                                 distanza:= coda_nodi(estremo_arrivo.id_quartiere,estremo_arrivo.id_incrocio).distanza-ingresso_arrivo.get_distance_from_road_head_ingresso+distanza;
                              else
                                 distanza:= coda_nodi(estremo_arrivo.id_quartiere,estremo_arrivo.id_incrocio).distanza-(cache_urbane(ingresso_arrivo.get_id_quartiere_road)(ingresso_arrivo.get_id_main_strada_ingresso).get_lunghezza_road-ingresso_arrivo.get_distance_from_road_head_ingresso)+distanza;
                              end if;
                           end if;
                        end if;
                     else -- lo spigolo precedente non è la strada principale della strada di ingresso di arrivo

                        estremo_intermedio:= estremo_arrivo;
                        while coda_nodi(estremo_intermedio.id_quartiere,estremo_intermedio.id_incrocio).precedente.id_quartiere/=0 loop
                           penultimo_estremo:= estremo_intermedio;
                           estremo_intermedio:= coda_nodi(estremo_intermedio.id_quartiere,estremo_intermedio.id_incrocio).precedente;
                        end loop;

                        --grafo(estremo_intermedio.id_quartiere)(estremo_intermedio.id_incrocio)
                        switch:= False;
                        if index=1 then
                           if penultimo_estremo.id_quartiere=estremo_2_partenza.id_quartiere and penultimo_estremo.id_incrocio=estremo_2_partenza.id_incrocio then
                              switch:= True;
                           end if;
                        else
                           if penultimo_estremo.id_quartiere=estremo_1_partenza.id_quartiere and penultimo_estremo.id_incrocio=estremo_1_partenza.id_incrocio then
                              switch:= True;
                           end if;
                        end if;

                        if estremo_partenza.polo then
                           distanza:= ingresso_partenza.get_distance_from_road_head_ingresso;
                        else
                           distanza:= cache_urbane(ingresso_partenza.get_id_quartiere_road)(ingresso_partenza.get_id_main_strada_ingresso).get_lunghezza_road-ingresso_partenza.get_distance_from_road_head_ingresso;
                        end if;

                        if switch then
                           if estremo_arrivo.polo then
                              distanza:= coda_nodi(estremo_arrivo.id_quartiere,estremo_arrivo.id_incrocio).distanza+ingresso_arrivo.get_distance_from_road_head_ingresso-distanza;
                           else
                              distanza:= coda_nodi(estremo_arrivo.id_quartiere,estremo_arrivo.id_incrocio).distanza+cache_urbane(ingresso_arrivo.get_id_quartiere_road)(ingresso_arrivo.get_id_main_strada_ingresso).get_lunghezza_road-ingresso_arrivo.get_distance_from_road_head_ingresso-distanza;
                           end if;
                        else
                           if estremo_arrivo.polo then
                              distanza:= coda_nodi(estremo_arrivo.id_quartiere,estremo_arrivo.id_incrocio).distanza+ingresso_arrivo.get_distance_from_road_head_ingresso+distanza;
                           else
                              distanza:= coda_nodi(estremo_arrivo.id_quartiere,estremo_arrivo.id_incrocio).distanza+cache_urbane(ingresso_arrivo.get_id_quartiere_road)(ingresso_arrivo.get_id_main_strada_ingresso).get_lunghezza_road-ingresso_arrivo.get_distance_from_road_head_ingresso+distanza;
                           end if;
                        end if;
                     end if;
                  end if;
                  Put_Line("DISTANZA:" & Float'Image(distanza));
                  if indice=1 then
                     distanza_estremo_1:=distanza;
                  else
                     distanza_estremo_2:=distanza;
                  end if;
                  estremo_arrivo:= estremo_2_arrivo;
                  distanza:= Float'Last;
               end loop;

               change_route:= False;
               if distanza_estremo_1<distanza_estremo_2 and distanza_estremo_1<min_distanza then
                  min_distanza:= distanza_estremo_1;
                  change_route:= True;
                  estremo_to_consider:= True;
               elsif distanza_estremo_2<min_distanza then
                  min_distanza:= distanza_estremo_2;
                  change_route:= True;
                  estremo_to_consider:= False;
               end if;

               if change_route then
                  if estremo_to_consider then  -- case estremo_1
                     estremo:= estremo_1_arrivo;
                  else  -- case estremo_2
                     estremo:= estremo_2_arrivo;
                  end if;

                  -- istanzio il percorso
                  ptr_route:= null;
                  -- Il percorso ritornato inizia con l'ingresso di partenza e finisce con l'ingresso di arrivo.
                  -- Non sono inserite le urbane a cui gli ingressi appoggiano, dato che si ricavano subito dagli ingressi,
                  -- Il resto del percorso è inserito prendendo incroci e urbane.
                  size_route:=0;

                  if coda_nodi(estremo.id_quartiere,estremo.id_incrocio).precedente.id_quartiere/=0 then
                     segmento:= create_tratto(id_quartiere => to_id_quartiere, id_tratto => new_to_id_luogo);
                     ptr_route:= create_list_percorso(segmento,ptr_route);
                     size_route:= size_route + 1;
                     switch_loop_percorso:= False;
                     if estremo_to_consider then
                        if coda_nodi(estremo.id_quartiere,estremo.id_incrocio).precedente.id_quartiere=estremo_2_arrivo.id_quartiere and coda_nodi(estremo.id_quartiere,estremo.id_incrocio).precedente.id_incrocio=estremo_2_arrivo.id_incrocio then
                           switch_loop_percorso:= True;
                        end if;
                     else
                        if coda_nodi(estremo.id_quartiere,estremo.id_incrocio).precedente.id_quartiere=estremo_1_arrivo.id_quartiere and coda_nodi(estremo.id_quartiere,estremo.id_incrocio).precedente.id_incrocio=estremo_1_arrivo.id_incrocio then
                           switch_loop_percorso:= True;
                        end if;
                     end if;
                     if switch_loop_percorso=False then
                        segmento:= create_tratto(id_quartiere => estremo.id_quartiere, id_tratto => estremo.id_incrocio);
                        ptr_route:= create_list_percorso(segmento,ptr_route);
                        estremo:= coda_nodi(estremo.id_quartiere,estremo.id_incrocio).precedente;
                        size_route:= size_route + 1;
                     end if;

                     loop
                        exit when coda_nodi(estremo.id_quartiere,estremo.id_incrocio).precedente.id_quartiere=0 or else coda_nodi(coda_nodi(estremo.id_quartiere,estremo.id_incrocio).precedente.id_quartiere,coda_nodi(estremo.id_quartiere,estremo.id_incrocio).precedente.id_incrocio).precedente.id_quartiere=0;
                        segmento:= create_tratto(id_quartiere => estremo.id_quartiere, id_tratto => estremo.id_incrocio);
                        ptr_route:= create_list_percorso(segmento,ptr_route);
                        segmento:= create_tratto(id_quartiere => coda_nodi(estremo.id_quartiere,estremo.id_incrocio).id_quartiere_spigolo, id_tratto => coda_nodi(estremo.id_quartiere,estremo.id_incrocio).id_spigolo);
                        ptr_route:= create_list_percorso(segmento,ptr_route);
                        size_route:= size_route + 2;
                        estremo:= coda_nodi(estremo.id_quartiere,estremo.id_incrocio).precedente;
                     end loop;
                     switch_loop_percorso:= False;
                     if index=1 then
                        if estremo.id_quartiere=estremo_2_partenza.id_quartiere and estremo.id_incrocio=estremo_2_partenza.id_incrocio then
                           switch_loop_percorso:= True;
                        end if;
                     else
                        if estremo.id_quartiere=estremo_1_partenza.id_quartiere and estremo.id_incrocio=estremo_1_partenza.id_incrocio then
                           switch_loop_percorso:= True;
                        end if;
                     end if;
                     if switch_loop_percorso=False then
                        segmento:= create_tratto(id_quartiere => estremo.id_quartiere, id_tratto => estremo.id_incrocio);
                        ptr_route:= create_list_percorso(segmento,ptr_route);
                        size_route:= size_route + 1;
                     end if;
                     segmento:= create_tratto(id_quartiere => from_id_quartiere, id_tratto => new_from_id_luogo);
                     ptr_route:= create_list_percorso(segmento,ptr_route);
                     size_route:= size_route + 1;
                  else
                     ---HAI SOLO UN ESTREMO
                     segmento:= create_tratto(id_quartiere => to_id_quartiere, id_tratto => new_to_id_luogo);
                     ptr_route:= create_list_percorso(segmento,ptr_route);
                     size_route:= size_route + 1;
                     if ingresso_partenza.get_id_main_strada_ingresso/=ingresso_arrivo.get_id_main_strada_ingresso then
                        segmento:= create_tratto(id_quartiere => estremo.id_quartiere, id_tratto => estremo.id_incrocio);
                        ptr_route:= create_list_percorso(segmento,ptr_route);
                        size_route:= size_route + 1;
                     end if;
                     segmento:= create_tratto(id_quartiere => from_id_quartiere, id_tratto => new_from_id_luogo);
                     ptr_route:= create_list_percorso(segmento,ptr_route);
                     size_route:= size_route + 1;
                  end if;
               end if;
            end if;
            index:= index + 1;
         end loop;
         -- viene creato l'array che deve essere tornato
         return create_percorso(route => create_array_percorso(size_route,ptr_route), distance => min_distanza);
      end calcola_percorso;

      procedure registra_strade_quartiere(id_quartiere: Positive; urbane: strade_urbane_features;
                                          ingressi: strade_ingresso_features) is
      begin
         cache_urbane(id_quartiere):= new strade_urbane_features'(urbane);
         hash_urbane_quartieri(id_quartiere):= new hash_quartiere_strade(urbane'Range);

         cache_ingressi(id_quartiere):= new strade_ingresso_features'(ingressi);
         num_strade_quartieri:= num_strade_quartieri+1;
      end registra_strade_quartiere;

      entry registra_incroci_quartiere(id_quartiere: Positive; incroci_a_4: list_incroci_a_4;
                                       incroci_a_3: list_incroci_a_3; rotonde_a_4: list_incroci_a_4;
                                       rotonde_a_3: list_incroci_a_3) when num_strade_quartieri=get_num_quartieri is
         incrocio_a_4: list_road_incrocio_a_4;
         incrocio_a_3: list_road_incrocio_a_3;
         rotonda_a_4: list_road_incrocio_a_4;
         rotonda_a_3: list_road_incrocio_a_3;
         incrocio_features: road_incrocio_features;
         indice_incrocio: index_incroci;
         val_id_quartiere: Positive;
         val_id_strada: Positive;
         val_polo: Boolean;

         quartiere_strade: access hash_quartiere_strade;
         val_id_quartiere_index_incrocio_estremo_1: Natural;
         val_id_incrocio_index_incrocio_estremo_1: Natural;
         val_id_quartiere_index_incrocio_estremo_2: Natural;
         val_id_incrocio_index_incrocio_estremo_2: Natural;
         estremo_1: index_incroci;
         estremo_2: index_incroci;
         adiacente_1: adiacente;
         adiacente_2: adiacente;
         adiacente_3: adiacente;
         adiacente_4: adiacente;
         index_to_place: Positive := 1;
      begin

         if num_incroci_quartieri_registrati = 0 then
            min_first_incroci:= Natural'Last;
            max_last_incroci:= Natural'First;
         end if;
         -- La numerazione è progressiva seguendo l'ordine: incroci_a_4,incroci_a_3,rotonde_a_4,rotonde_a_3
         if incroci_a_4'First<incroci_a_4'Last and incroci_a_4'First<min_first_incroci then
            min_first_incroci:= incroci_a_4'First;
         elsif incroci_a_3'First<incroci_a_3'Last and incroci_a_3'First<min_first_incroci then
            min_first_incroci:= incroci_a_3'First;
         elsif rotonde_a_4'First<rotonde_a_4'Last and rotonde_a_4'First<min_first_incroci then
            min_first_incroci:= rotonde_a_4'First;
         elsif rotonde_a_3'First<rotonde_a_3'Last and rotonde_a_3'First<min_first_incroci then
            min_first_incroci:= rotonde_a_3'First;
         end if;
         if rotonde_a_3'First<rotonde_a_3'Last and rotonde_a_3'Last>max_last_incroci then
            max_last_incroci:= rotonde_a_3'Last;
         elsif rotonde_a_4'First<rotonde_a_4'Last and rotonde_a_4'Last>max_last_incroci then
            max_last_incroci:= rotonde_a_4'Last;
         elsif incroci_a_3'First<incroci_a_3'Last and incroci_a_3'Last>max_last_incroci then
            max_last_incroci:= incroci_a_3'Last;
         elsif incroci_a_4'First<incroci_a_4'Last and incroci_a_4'Last>max_last_incroci then
            max_last_incroci:= incroci_a_4'Last;
         end if;


         -- elaborazione incroci a 4
         Put_Line("costruzione" & Positive'Image(id_quartiere));
         for incrocio in incroci_a_4'Range loop
            incrocio_a_4:= incroci_a_4(incrocio);
            for road in 1..4 loop
               incrocio_features:= incrocio_a_4(road);
               val_id_quartiere:= incrocio_features.get_id_quartiere_road_incrocio;
               val_id_strada:= incrocio_features.get_id_strada_road_incrocio;
               val_polo:= incrocio_features.get_polo_road_incrocio;
               indice_incrocio:= hash_urbane_quartieri(val_id_quartiere)(val_id_strada)(1);
               if indice_incrocio.get_id_quartiere_index_incroci = 0 then
                  hash_urbane_quartieri(val_id_quartiere)(val_id_strada)(1):=
                       create_new_index_incrocio(val_id_quartiere => id_quartiere, val_id_incrocio => incrocio, val_polo => val_polo);
               else
                  hash_urbane_quartieri(val_id_quartiere)(val_id_strada)(2):=
                       create_new_index_incrocio(val_id_quartiere => id_quartiere, val_id_incrocio => incrocio, val_polo => val_polo);
               end if;
            end loop;
         end loop;
         -- elaborazione incroci a 3
         Put_Line("costruzione" & Positive'Image(id_quartiere));
         for incrocio in incroci_a_3'Range loop
            incrocio_a_3:= incroci_a_3(incrocio);
            for road in 1..3 loop
               incrocio_features:= incrocio_a_3(road);
               val_id_quartiere:= incrocio_features.get_id_quartiere_road_incrocio;
               val_id_strada:= incrocio_features.get_id_strada_road_incrocio;
               val_polo:= incrocio_features.get_polo_road_incrocio;
               indice_incrocio:= hash_urbane_quartieri(val_id_quartiere)(val_id_strada)(1);
               if indice_incrocio.get_id_quartiere_index_incroci = 0 then
                  hash_urbane_quartieri(val_id_quartiere)(val_id_strada)(1):=
                       create_new_index_incrocio(val_id_quartiere => id_quartiere, val_id_incrocio => incrocio, val_polo => val_polo);
               else
                  hash_urbane_quartieri(val_id_quartiere)(val_id_strada)(2):=
                       create_new_index_incrocio(val_id_quartiere => id_quartiere, val_id_incrocio => incrocio, val_polo => val_polo);
               end if;
            end loop;
         end loop;
         Put_Line("costruzione" & Positive'Image(id_quartiere));
         -- elaborazione rotonde a 4
         for rotonda in rotonde_a_4'Range loop
            rotonda_a_4:= rotonde_a_4(rotonda);
            for road in 1..4 loop
               incrocio_features:= rotonda_a_4(road);
               val_id_quartiere:= incrocio_features.get_id_quartiere_road_incrocio;
               val_id_strada:= incrocio_features.get_id_strada_road_incrocio;
               val_polo:= incrocio_features.get_polo_road_incrocio;
               indice_incrocio:= hash_urbane_quartieri(val_id_quartiere)(val_id_strada)(1);
               if indice_incrocio.get_id_quartiere_index_incroci = 0 then
                  hash_urbane_quartieri(val_id_quartiere)(val_id_strada)(1):=
                       create_new_index_incrocio(val_id_quartiere => id_quartiere, val_id_incrocio => rotonda, val_polo => val_polo);
               else
                  hash_urbane_quartieri(val_id_quartiere)(val_id_strada)(2):=
                       create_new_index_incrocio(val_id_quartiere => id_quartiere, val_id_incrocio => rotonda, val_polo => val_polo);
               end if;
            end loop;
         end loop;
         -- elaborazione rotonde a 3
         for rotonda in rotonde_a_3'Range loop
            rotonda_a_3:= rotonde_a_3(rotonda);
            for road in 1..3 loop
               incrocio_features:= rotonda_a_3(road);
               val_id_quartiere:= incrocio_features.get_id_quartiere_road_incrocio;
               val_id_strada:= incrocio_features.get_id_strada_road_incrocio;
               val_polo:= incrocio_features.get_polo_road_incrocio;
               indice_incrocio:= hash_urbane_quartieri(val_id_quartiere)(val_id_strada)(1);
               if indice_incrocio.get_id_quartiere_index_incroci = 0 then
                  hash_urbane_quartieri(val_id_quartiere)(val_id_strada)(1):=
                       create_new_index_incrocio(val_id_quartiere => id_quartiere, val_id_incrocio => rotonda, val_polo => val_polo);
               else
                  hash_urbane_quartieri(val_id_quartiere)(val_id_strada)(2):=
                       create_new_index_incrocio(val_id_quartiere => id_quartiere, val_id_incrocio => rotonda, val_polo => val_polo);
               end if;
            end loop;
         end loop;
         grafo(id_quartiere):= new nodi_quartiere(incroci_a_4'First..rotonde_a_3'Last);
         numero_globale_incroci:= numero_globale_incroci + grafo(id_quartiere)'Length;

         num_incroci_quartieri_registrati:= num_incroci_quartieri_registrati + 1;
         Put_Line("incroci registrati" & Positive'Image(num_incroci_quartieri_registrati));
         if num_incroci_quartieri_registrati = get_num_quartieri then
            -- il grafo può essere costruito
            Put_Line("costruzione grafo");
            for quartiere in hash_urbane_quartieri'Range loop
               quartiere_strade:= hash_urbane_quartieri(quartiere);
               for strada in quartiere_strade'Range loop
                  estremo_1:= quartiere_strade(strada)(1);
                  estremo_2:= quartiere_strade(strada)(2);
                  val_id_quartiere_index_incrocio_estremo_1:= estremo_1.get_id_quartiere_index_incroci;
                  val_id_incrocio_index_incrocio_estremo_1:= estremo_1.get_id_incrocio_index_incroci;
                  val_id_quartiere_index_incrocio_estremo_2:= estremo_2.get_id_quartiere_index_incroci;
                  val_id_incrocio_index_incrocio_estremo_2:= estremo_2.get_id_incrocio_index_incroci;
                  if val_id_quartiere_index_incrocio_estremo_1 /= 0 then
                     if val_id_quartiere_index_incrocio_estremo_2 /= 0 then
                        -- begin sistemazione lato estremo1->estremo2
                        adiacente_1:= grafo(val_id_quartiere_index_incrocio_estremo_1)(val_id_incrocio_index_incrocio_estremo_1)(1);
                        adiacente_2:= grafo(val_id_quartiere_index_incrocio_estremo_1)(val_id_incrocio_index_incrocio_estremo_1)(2);
                        adiacente_3:= grafo(val_id_quartiere_index_incrocio_estremo_1)(val_id_incrocio_index_incrocio_estremo_1)(3);
                        adiacente_4:= grafo(val_id_quartiere_index_incrocio_estremo_1)(val_id_incrocio_index_incrocio_estremo_1)(4);
                        if adiacente_1.get_id_quartiere_strada = 0 then
                           index_to_place:= 1;
                        elsif adiacente_2.get_id_quartiere_strada = 0 then
                           index_to_place:= 2;
                        elsif adiacente_3.get_id_quartiere_strada = 0 then
                           index_to_place:= 3;
                        elsif adiacente_4.get_id_quartiere_strada = 0 then
                           index_to_place:= 4;
                        end if;
                        grafo(val_id_quartiere_index_incrocio_estremo_1)(val_id_incrocio_index_incrocio_estremo_1)(index_to_place):=
                          create_new_adiacente(val_id_quartiere_strada => quartiere, val_id_strada => strada,
                                               val_id_quartiere_adiacente => val_id_quartiere_index_incrocio_estremo_2,
                                               val_id_adiacente => val_id_incrocio_index_incrocio_estremo_2);
                        -- end sistemazione lato estremo1->estremo2
                        -- begin sistemazione lato estremo2->estremo1
                        adiacente_1:= grafo(val_id_quartiere_index_incrocio_estremo_2)(val_id_incrocio_index_incrocio_estremo_2)(1);
                        adiacente_2:= grafo(val_id_quartiere_index_incrocio_estremo_2)(val_id_incrocio_index_incrocio_estremo_2)(2);
                        adiacente_3:= grafo(val_id_quartiere_index_incrocio_estremo_2)(val_id_incrocio_index_incrocio_estremo_2)(3);
                        adiacente_4:= grafo(val_id_quartiere_index_incrocio_estremo_2)(val_id_incrocio_index_incrocio_estremo_2)(4);
                        if adiacente_1.get_id_quartiere_strada = 0 then
                           index_to_place:= 1;
                        elsif adiacente_2.get_id_quartiere_strada = 0 then
                           index_to_place:= 2;
                        elsif adiacente_3.get_id_quartiere_strada = 0 then
                           index_to_place:= 3;
                        elsif adiacente_4.get_id_quartiere_strada = 0 then
                           index_to_place:= 4;
                        end if;
                        grafo(val_id_quartiere_index_incrocio_estremo_2)(val_id_incrocio_index_incrocio_estremo_2)(index_to_place):=
                          create_new_adiacente(val_id_quartiere_strada => quartiere, val_id_strada => strada,
                                               val_id_quartiere_adiacente => val_id_quartiere_index_incrocio_estremo_1,
                                               val_id_adiacente => val_id_incrocio_index_incrocio_estremo_1);
                        -- end sistemazione lato estremo2->estremo1
                     else
                        adiacente_1:= grafo(val_id_quartiere_index_incrocio_estremo_1)(val_id_incrocio_index_incrocio_estremo_1)(1);
                        adiacente_2:= grafo(val_id_quartiere_index_incrocio_estremo_1)(val_id_incrocio_index_incrocio_estremo_1)(2);
                        adiacente_3:= grafo(val_id_quartiere_index_incrocio_estremo_1)(val_id_incrocio_index_incrocio_estremo_1)(3);
                        adiacente_4:= grafo(val_id_quartiere_index_incrocio_estremo_1)(val_id_incrocio_index_incrocio_estremo_1)(4);
                        if adiacente_1.get_id_quartiere_strada = 0 then
                           index_to_place:= 1;
                        elsif adiacente_2.get_id_quartiere_strada = 0 then
                           index_to_place:= 2;
                        elsif adiacente_3.get_id_quartiere_strada = 0 then
                           index_to_place:= 3;
                        elsif adiacente_4.get_id_quartiere_strada = 0 then
                           index_to_place:= 4;
                        end if;
                        grafo(val_id_quartiere_index_incrocio_estremo_1)(val_id_incrocio_index_incrocio_estremo_1)(index_to_place):=
                          create_new_adiacente(val_id_quartiere_strada => quartiere, val_id_strada => strada,
                                               val_id_quartiere_adiacente => 0,
                                               val_id_adiacente => 0);
                     end if;
                  else
                     -- ERRORE LA STRADA È ISOLATA, (NON È RAGGIUNGIBILE NEL GRAFO)
                     null;
                  end if;
               end loop;
            end loop;
            Put_Line("Effettuata registrazione nodi grafo");
            num_strade_quartieri:= 0;
            print_grafo;
         end if;
      end registra_incroci_quartiere;

   end registro_strade_resource;

end gps_utilities;
