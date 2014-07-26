with Text_IO;

use Text_IO;
package body server_gps_utilities is

   -- begin get methods index_incrocio
   function get_id_quartiere_index_incroci(incrocio: access index_incroci) return Positive is
   begin
      return incrocio.id_quartiere;
   end get_id_quartiere_index_incroci;
   function get_id_incrocio_index_incroci(incrocio: access index_incroci) return Positive is
   begin
      return incrocio.id_incrocio;
   end get_id_incrocio_index_incroci;
   -- end get methods index_incrocio

      -- begin get methods adiacente
   function get_id_quartiere_strada(near: access adiacente) return Natural is
   begin
      return near.id_quartiere_strada;
   end get_id_quartiere_strada;
   function get_id_strada(near: access adiacente) return Natural is
   begin
      return near.id_strada;
   end get_id_strada;
   function get_id_quartiere_adiacente(near: access adiacente) return Natural is
   begin
      return near.id_quartiere_adiacente;
   end get_id_quartiere_adiacente;
   function get_id_adiacente(near: access adiacente) return Natural is
   begin
      return near.id_adiacente;
   end get_id_adiacente;
   -- end get methods adiacente

   function create_new_index_incrocio(val_id_quartiere: Positive; val_id_incrocio: Positive) return index_incroci is
      ptr_index_incrocio: index_incroci;
   begin
      ptr_index_incrocio.id_quartiere:= val_id_quartiere;
      ptr_index_incrocio.id_incrocio:= val_id_incrocio;
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

   protected body registro_strade_resource is
      procedure registra_urbane_quartiere(id_quartiere: Positive; urbane: strade_urbane_features) is
      begin
         cache_urbane(id_quartiere):= new strade_urbane_features'(urbane);
         hash_urbane_quartieri(id_quartiere):= new hash_quartiere_strade(urbane'Range);
         num_urbane_quartieri_registrate:= num_urbane_quartieri_registrate + 1;
      end registra_urbane_quartiere;

      procedure registra_ingressi_quartiere(id_quartiere: Positive; ingressi: strade_ingresso_features) is
      begin
         cache_ingressi(id_quartiere):= new strade_ingresso_features'(ingressi);
      end registra_ingressi_quartiere;

      entry registra_incroci_quartiere(id_quartiere: Positive; incroci_a_4: list_incroci_a_4;
                                       incroci_a_3: list_incroci_a_3) when num_urbane_quartieri_registrate=num_quartieri is
         incrocio_a_4: list_road_incrocio_a_4;
         incrocio_a_3: list_road_incrocio_a_3;
         incrocio_features: aliased road_incrocio_features;
         indice_incrocio: aliased index_incroci;
         val_id_quartiere: Positive;
         val_id_strada: Positive;
         val_tipo_strada: type_strade;

         quartiere_strade: access hash_quartiere_strade;
         val_id_quartiere_index_incrocio_estremo_1: Natural;
         val_id_incrocio_index_incrocio_estremo_1: Natural;
         val_id_quartiere_index_incrocio_estremo_2: Natural;
         val_id_incrocio_index_incrocio_estremo_2: Natural;
         estremo_1: aliased index_incroci;
         estremo_2: aliased index_incroci;
         adiacente_1: aliased adiacente;
         adiacente_2: aliased adiacente;
         adiacente_3: aliased adiacente;
         adiacente_4: aliased adiacente;
         index_to_place: Positive :=1;
      begin
         -- elaborzione incroci a 4
         for incrocio in incroci_a_4'Range loop
            incrocio_a_4:= incroci_a_4(incrocio);
            for road in 1..4 loop
               incrocio_features:= incrocio_a_4(road);
               val_tipo_strada:= get_tipo_strada_road_incrocio(incrocio_features'Access);
               if val_tipo_strada = urbana then
                  val_id_quartiere:= get_id_quartiere_road_incrocio(incrocio_features'Access);
                  val_id_strada:= get_id_strada_road_incrocio(incrocio_features'Access);
                  indice_incrocio:= hash_urbane_quartieri(val_id_quartiere)(val_id_strada)(1);
                  if get_id_quartiere_index_incroci(indice_incrocio'Access) = 0 then
                     hash_urbane_quartieri(val_id_quartiere)(val_id_strada)(1):=
                       create_new_index_incrocio(val_id_quartiere => id_quartiere, val_id_incrocio => incrocio);
                  else
                     hash_urbane_quartieri(val_id_quartiere)(val_id_strada)(2):=
                       create_new_index_incrocio(val_id_quartiere => id_quartiere, val_id_incrocio => incrocio);
                  end if;
               end if;
            end loop;
         end loop;
         -- elaborazione incroci a 3
         for incrocio in incroci_a_3'Range loop
            incrocio_a_3:= incroci_a_3(incrocio);
            for road in 1..3 loop
               incrocio_features:= incrocio_a_3(road);
               val_tipo_strada:= get_tipo_strada_road_incrocio(incrocio_features'Access);
               if val_tipo_strada = urbana then
                  val_id_quartiere:= get_id_quartiere_road_incrocio(incrocio_features'Access);
                  val_id_strada:= get_id_strada_road_incrocio(incrocio_features'Access);
                  indice_incrocio:= hash_urbane_quartieri(val_id_quartiere)(val_id_strada)(1);
                  if get_id_quartiere_index_incroci(indice_incrocio'Access) = 0 then
                     hash_urbane_quartieri(val_id_quartiere)(val_id_strada)(1):=
                       create_new_index_incrocio(val_id_quartiere => id_quartiere, val_id_incrocio => incrocio);
                  else
                     hash_urbane_quartieri(val_id_quartiere)(val_id_strada)(2):=
                       create_new_index_incrocio(val_id_quartiere => id_quartiere, val_id_incrocio => incrocio);
                  end if;
               end if;
            end loop;
         end loop;

         grafo(id_quartiere):= new nodi_quartiere(incroci_a_4'First..incroci_a_3'Last);

         num_incroci_quartieri_registrati:= num_incroci_quartieri_registrati + 1;
         if num_incroci_quartieri_registrati = num_quartieri then
            -- il grafo può essere costruito
            for quartiere in hash_urbane_quartieri'Range loop
               quartiere_strade:= hash_urbane_quartieri(quartiere);
               for strada in quartiere_strade'Range loop
                  estremo_1:= quartiere_strade(strada)(1);
                  estremo_2:= quartiere_strade(strada)(2);
                  val_id_quartiere_index_incrocio_estremo_1:= get_id_quartiere_index_incroci(estremo_1'Access);
                  val_id_incrocio_index_incrocio_estremo_1:= get_id_incrocio_index_incroci(estremo_1'Access);
                  val_id_quartiere_index_incrocio_estremo_2:= get_id_quartiere_index_incroci(estremo_2'Access);
                  val_id_incrocio_index_incrocio_estremo_2:= get_id_incrocio_index_incroci(estremo_2'Access);
                  if val_id_quartiere_index_incrocio_estremo_1 /= 0 then
                     if val_id_quartiere_index_incrocio_estremo_2 /= 0 then
                        -- begin sistemazione lato estremo1->estremo2
                        adiacente_1:= grafo(val_id_quartiere_index_incrocio_estremo_1)(val_id_incrocio_index_incrocio_estremo_1)(1);
                        adiacente_2:= grafo(val_id_quartiere_index_incrocio_estremo_1)(val_id_incrocio_index_incrocio_estremo_1)(2);
                        adiacente_3:= grafo(val_id_quartiere_index_incrocio_estremo_1)(val_id_incrocio_index_incrocio_estremo_1)(3);
                        adiacente_4:= grafo(val_id_quartiere_index_incrocio_estremo_1)(val_id_incrocio_index_incrocio_estremo_1)(4);
                        if get_id_quartiere_strada(adiacente_1'Access) = 0 then
                           index_to_place:= 1;
                        elsif get_id_quartiere_strada(adiacente_2'Access) = 0 then
                           index_to_place:= 2;
                        elsif get_id_quartiere_strada(adiacente_3'Access) = 0 then
                           index_to_place:= 3;
                        elsif get_id_quartiere_strada(adiacente_4'Access) = 0 then
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
                        if get_id_quartiere_strada(adiacente_1'Access) = 0 then
                           index_to_place:= 1;
                        elsif get_id_quartiere_strada(adiacente_2'Access) = 0 then
                           index_to_place:= 2;
                        elsif get_id_quartiere_strada(adiacente_3'Access) = 0 then
                           index_to_place:= 3;
                        elsif get_id_quartiere_strada(adiacente_4'Access) = 0 then
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
                        if get_id_quartiere_strada(adiacente_1'Access) = 0 then
                           index_to_place:= 1;
                        elsif get_id_quartiere_strada(adiacente_2'Access) = 0 then
                           index_to_place:= 2;
                        elsif get_id_quartiere_strada(adiacente_3'Access) = 0 then
                           index_to_place:= 3;
                        elsif get_id_quartiere_strada(adiacente_4'Access) = 0 then
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
            hash_urbane_quartieri:= null;  -- dealloco dallo heap, attendendo l'azione del GC
         end if;
      end registra_incroci_quartiere;

   end registro_strade_resource;

end server_gps_utilities;
