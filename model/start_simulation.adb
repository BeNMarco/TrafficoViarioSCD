with Ada.Text_IO;
with GNATCOLL.JSON;
with Polyorb.Parameters;

with absolute_path;
with mailbox_risorse_attive;
with resource_map_inventory;
with data_quartiere;
with strade_e_incroci_common;
with the_name_server;
with remote_types;
with risorse_passive_data;
with risorse_mappa_utilities;
with snapshot_interface;
with JSON_Helper;
with System_error;
with System.RPC;
with Ada.Exceptions;
with Ada.Strings.Unbounded;

use Ada.Text_IO;
use GNATCOLL.JSON;
use Polyorb.Parameters;

use absolute_path;
use mailbox_risorse_attive;
use resource_map_inventory;
use data_quartiere;
use strade_e_incroci_common;
use the_name_server;
use remote_types;
use risorse_passive_data;
use risorse_mappa_utilities;
use snapshot_interface;
use JSON_Helper;
use System_error;
use Ada.Exceptions;
use Ada.Strings.Unbounded;

package body start_simulation is

   procedure update_percorso(percorso: route_and_distance; residente: abitante; add_abitante: Boolean; percorso_calcolato: in out Boolean) is
   begin
      if percorso.get_size_percorso=0 then
         percorso_calcolato:= False;
         if add_abitante=True then
            coda_abitanti_to_restart.enqueue_abitante(residente);
         end if;
      else
         print_percorso(percorso.get_percorso_from_route_and_distance);
         Put_Line("end request percorso " & Positive'Image(residente.get_id_abitante_from_abitante) & " " & Positive'Image(residente.get_id_quartiere_from_abitante));
         get_locate_abitanti_quartiere.set_percorso_abitante(id_abitante => residente.get_id_abitante_from_abitante, percorso => percorso);
         percorso_calcolato:= True;
      end if;
   end update_percorso;

   procedure start_entity_to_move is
      residente: abitante;
      switch: Boolean;
      continue: Boolean;
      mezzo: means_of_carrying;
      empty_route: percorso(1..0);
      percorso_calcolato: Boolean:= False;
      error_flag: Boolean:= False;
      to_luogo: Positive;
   begin
      Put_Line("avvia entità " & Positive'Image(get_from_abitanti) & " " & Positive'Image(get_to_abitanti));
      -- cicla su ogni abitante e invia richiesta all'ingresso

      for i in get_from_abitanti..get_to_abitanti-get_num_autobus loop
         switch:= True;
         residente:= get_quartiere_utilities_obj.get_abitante_quartiere(get_id_quartiere,i);
         -- controllare se l'abitante parte o va in una fermata TO DO
         if is_abitante_in_bus(i) then
            if residente.get_id_quartiere_luogo_lavoro_from_abitante=get_id_quartiere then
               if get_ingresso_from_id(residente.get_id_luogo_casa_from_abitante+get_from_ingressi-1).get_id_main_strada_ingresso=
                 get_ingresso_from_id(residente.get_id_luogo_lavoro_from_abitante+get_from_ingressi-1).get_id_main_strada_ingresso then
                  -- se gli ingressi sono sulla stessa strada l'abitante non va in autobus
                  Put_Line("abitante can NOT GO VIA AUTOBUS, GLI INGRESSI SONO SULLA STESSA STRADA, IDENTIFICATIVO abitante: " & Positive'Image(residente.get_id_quartiere_from_abitante) & " " & Positive'Image(residente.get_id_abitante_from_abitante));
                  switch:= False;
               end if;
            end if;
         end if;

         --calcola percorso e prendi il riferimento a locate del quartiere abitante e setta percorso
         Put_Line("request percorso " & Positive'Image(residente.get_id_abitante_from_abitante) & " " & Positive'Image(residente.get_id_quartiere_from_abitante));
         if is_abitante_in_bus(i) and then switch then
            mezzo:= walking;
            if get_id_fermata_from_id_urbana(get_ingresso_from_id(residente.get_id_luogo_casa_from_abitante+get_from_ingressi-1).get_id_main_strada_ingresso)=0 then
               log_system_error.set_error(altro,error_flag);
               Put_Line("L'urbana " & Positive'Image(get_ingresso_from_id(residente.get_id_luogo_casa_from_abitante+get_from_ingressi-1).get_id_main_strada_ingresso) & " non ha la fermata.");
               return;
            end if;
            continue:= True;
            begin
               get_location_abitanti_quartiere.set_destination_abitante_in_bus(residente.get_id_abitante_from_abitante,create_tratto(residente.get_id_quartiere_luogo_lavoro_from_abitante,residente.get_id_luogo_lavoro_from_abitante+get_ref_quartiere(residente.get_id_quartiere_luogo_lavoro_from_abitante).get_from_type_resource_quartiere(ingresso)-1));
            exception
               when others =>
                  continue:= False;
                  update_percorso(create_percorso(empty_route,0.0),residente,True,percorso_calcolato);
            end;
            if continue then
               declare
                  percorso: route_and_distance:= get_server_gps.calcola_percorso(from_id_quartiere => residente.get_id_quartiere_from_abitante, from_id_luogo => residente.get_id_luogo_casa_from_abitante+get_from_ingressi-1,
                                                                              to_id_quartiere => residente.get_id_quartiere_from_abitante, to_id_luogo => get_id_fermata_from_id_urbana(get_ingresso_from_id(residente.get_id_luogo_casa_from_abitante+get_from_ingressi-1).get_id_main_strada_ingresso),id_quartiere => get_id_quartiere,id_abitante => i);
               begin
                  update_percorso(percorso,residente,True,percorso_calcolato);
               end;
            end if;
            else
            mezzo:= residente.get_mezzo_abitante;
            continue:= True;
            begin
               to_luogo:= get_ref_quartiere(residente.get_id_quartiere_luogo_lavoro_from_abitante).get_from_type_resource_quartiere(ingresso)-1;
            exception
               when others =>
                  continue:= False;
                  update_percorso(create_percorso(empty_route,0.0),residente,True,percorso_calcolato);
            end;
            if continue then
               declare
                  percorso: route_and_distance:= get_server_gps.calcola_percorso(from_id_quartiere => residente.get_id_quartiere_from_abitante, from_id_luogo => residente.get_id_luogo_casa_from_abitante+get_from_ingressi-1,
                                                                               to_id_quartiere => residente.get_id_quartiere_luogo_lavoro_from_abitante, to_id_luogo => residente.get_id_luogo_lavoro_from_abitante+to_luogo,id_quartiere => get_id_quartiere,id_abitante => i);
               begin
                  update_percorso(percorso,residente,True,percorso_calcolato);
               end;
            end if;
         end if;
         if percorso_calcolato then
            get_ingressi_segmento_resources(get_from_ingressi+residente.get_id_luogo_casa_from_abitante-1).new_abitante_to_move(residente.get_id_quartiere_from_abitante,residente.get_id_abitante_from_abitante,mezzo);
         end if;
      end loop;

      Put_Line("before conf fermate");
      configure_linee_fermate;
      Put_Line("after conf fermate");

      start_autobus_to_move;
   end start_entity_to_move;

   procedure start_autobus_to_move is
      autobus: abitante;
      first_fermata: tratto;
      linea: linea_bus;
      stop_entity: Boolean;
      percorso_calcolato: Boolean:= False;
   begin
      for i in get_to_abitanti-get_num_autobus+1..get_to_abitanti loop
         autobus:= get_quartiere_utilities_obj.get_abitante_quartiere(get_id_quartiere,i);
         linea:= get_linea(autobus.get_id_luogo_lavoro_from_abitante);
         stop_entity:= False;
         if linea.is_updated_linea then
            if autobus.is_a_bus_jolly then
               if linea.is_updated_jolly(autobus.is_a_jolly_to_quartiere)=False then
                  stop_entity:= True;
               end if;
            end if;
         else
            stop_entity:= True;
         end if;
         if stop_entity then
            coda_abitanti_to_restart.enqueue_abitante(autobus);
         else
            first_fermata:= tratto(linea.get_num_tratto(1));
            --calcola percorso e prendi il riferimento a locate del quartiere abitante e setta percorso
            Put_Line("request percorso BUS " & Positive'Image(autobus.get_id_abitante_from_abitante) & " " & Positive'Image(autobus.get_id_quartiere_from_abitante));
            declare
               percorso: route_and_distance:= get_server_gps.calcola_percorso(from_id_quartiere => autobus.get_id_quartiere_from_abitante, from_id_luogo => autobus.get_id_luogo_casa_from_abitante+get_from_ingressi-1,
                                                                           to_id_quartiere => first_fermata.get_id_quartiere_tratto, to_id_luogo => first_fermata.get_id_tratto,id_quartiere => get_id_quartiere,id_abitante => i);
            begin
               update_percorso(percorso,autobus,True,percorso_calcolato);
            end;
            if percorso_calcolato then
               get_ingressi_segmento_resources(get_from_ingressi+autobus.get_id_luogo_casa_from_abitante-1).new_abitante_to_move(autobus.get_id_quartiere_from_abitante,autobus.get_id_abitante_from_abitante,autobus.get_mezzo_abitante);
            end if;
         end if;
      end loop;
   end start_autobus_to_move;

   procedure recovery_start_entity_to_move is
      list: ptr_lista_tuple;
      residente: abitante;
      stop_entity: Boolean:= False;
      percorso_calcolato: Boolean:= False;
      linea: linea_bus;
      first_fermata: tratto;
      mezzo: means_of_carrying;
      empty_route: percorso(1..0);
      continue: Boolean;
      to_luogo: Positive;
   begin
      loop
         delay 5.0;
         if fermate_are_configured=False then
            configure_linee_fermate;
         end if;

         list:= coda_abitanti_to_restart.get_abitanti_non_partiti;
         while list/=null loop
            -- si controlla se l'abitante può partire
            percorso_calcolato:= False;
            residente:= get_quartiere_utilities_obj.get_abitante_quartiere(get_id_quartiere,list.get_tupla.get_id_tratto);

            --calcola percorso e prendi il riferimento a locate del quartiere abitante e setta percorso
            Put_Line("request percorso " & Positive'Image(residente.get_id_abitante_from_abitante) & " " & Positive'Image(residente.get_id_quartiere_from_abitante));
            if is_abitante_in_bus(residente.get_id_abitante_from_abitante) then
               mezzo:= walking;
               continue:= True;
               begin
                  get_location_abitanti_quartiere.set_destination_abitante_in_bus(residente.get_id_abitante_from_abitante,create_tratto(residente.get_id_quartiere_luogo_lavoro_from_abitante,residente.get_id_luogo_lavoro_from_abitante+get_ref_quartiere(residente.get_id_quartiere_luogo_lavoro_from_abitante).get_from_type_resource_quartiere(ingresso)-1));
               exception
                  when others =>
                     continue:= False;
                     update_percorso(create_percorso(empty_route,0.0),residente,False,percorso_calcolato);
               end;
               if continue then
                  declare
                     percorso: route_and_distance:= get_server_gps.calcola_percorso(from_id_quartiere => residente.get_id_quartiere_from_abitante, from_id_luogo => residente.get_id_luogo_casa_from_abitante+get_from_ingressi-1,
                                                                              to_id_quartiere => residente.get_id_quartiere_from_abitante, to_id_luogo => get_id_fermata_from_id_urbana(get_ingresso_from_id(residente.get_id_luogo_casa_from_abitante+get_from_ingressi-1).get_id_main_strada_ingresso),id_quartiere => get_id_quartiere,id_abitante => residente.get_id_abitante_from_abitante);
                  begin
                     update_percorso(percorso,residente,False,percorso_calcolato);
                  end;
               end if;
            elsif residente.is_a_bus=False then
               mezzo:= residente.get_mezzo_abitante;
               continue:= True;
               begin
                  to_luogo:= get_ref_quartiere(residente.get_id_quartiere_luogo_lavoro_from_abitante).get_from_type_resource_quartiere(ingresso)-1;
               exception
                  when others =>
                     continue:= False;
                     update_percorso(create_percorso(empty_route,0.0),residente,False,percorso_calcolato);
               end;
               if continue then
                  declare
                     percorso: route_and_distance:= get_server_gps.calcola_percorso(from_id_quartiere => residente.get_id_quartiere_from_abitante, from_id_luogo => residente.get_id_luogo_casa_from_abitante+get_from_ingressi-1,
                                                                               to_id_quartiere => residente.get_id_quartiere_luogo_lavoro_from_abitante, to_id_luogo => residente.get_id_luogo_lavoro_from_abitante+to_luogo,id_quartiere => get_id_quartiere,id_abitante => residente.get_id_abitante_from_abitante);
                  begin
                     update_percorso(percorso,residente,False,percorso_calcolato);
                  end;
               end if;
            else
               mezzo:= residente.get_mezzo_abitante;
               linea:= get_linea(residente.get_id_luogo_lavoro_from_abitante);
               stop_entity:= False;
               if linea.is_updated_linea then
                  if residente.is_a_bus_jolly then
                     if linea.is_updated_jolly(residente.is_a_jolly_to_quartiere)=False then
                        stop_entity:= True;
                     end if;
                  end if;
               else
                  stop_entity:= True;
               end if;
               if stop_entity=False then
                  first_fermata:= tratto(linea.get_num_tratto(1));
                  --calcola percorso e prendi il riferimento a locate del quartiere abitante e setta percorso
                  Put_Line("request percorso BUS " & Positive'Image(residente.get_id_abitante_from_abitante) & " " & Positive'Image(residente.get_id_quartiere_from_abitante));
                  declare
                     percorso: route_and_distance:= get_server_gps.calcola_percorso(from_id_quartiere => residente.get_id_quartiere_from_abitante, from_id_luogo => residente.get_id_luogo_casa_from_abitante+get_from_ingressi-1,
                                                                           to_id_quartiere => first_fermata.get_id_quartiere_tratto, to_id_luogo => first_fermata.get_id_tratto,id_quartiere => get_id_quartiere,id_abitante => residente.get_id_abitante_from_abitante);
                  begin
                     update_percorso(percorso,residente,False,percorso_calcolato);
                  end;
               end if;
            end if;
            if percorso_calcolato then
               get_ingressi_segmento_resources(get_from_ingressi+residente.get_id_luogo_casa_from_abitante-1).new_abitante_to_move(residente.get_id_quartiere_from_abitante,residente.get_id_abitante_from_abitante,mezzo);
               --Put_Line("INSERITTTTTTTTTTTTTTTTTTOOOOOOOOOOOOOOOOOOOOOO ABITANTE MANCANTEEEEEEEE************************");
            end if;

            if percorso_calcolato then
               coda_abitanti_to_restart.dequeue_abitante(residente,list);
            else
               list:= list.get_next_tupla;
            end if;
         end loop;

         exit when log_system_error.is_in_error; -- INTANTO CONDIZIONE DI USCITA A FALSE
      end loop;
   end recovery_start_entity_to_move;


end start_simulation;
