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

package body start_simulation is

   procedure start_entity_to_move is
      residente: abitante;
      percorso: access route_and_distance;
      --json_snap: JSON_Value;
      switch: Boolean;
      mezzo: means_of_carrying;
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

         --if get_recovery then
            --share_snapshot_file_quartiere.get_json_value_locate_abitanti(json_snap);
            --if Length(json_snap.Get("percorsi").Get(Positive'Image(i)).Get("percorso"))/=0 then
            --   switch:= False;
            --end if;
         --end if;
         --if switch then
            --calcola percorso e prendi il riferimento a locate del quartiere abitante e setta percorso
         Put_Line("request percorso " & Positive'Image(residente.get_id_abitante_from_abitante) & " " & Positive'Image(residente.get_id_quartiere_from_abitante));
         if is_abitante_in_bus(i) and then switch then
            mezzo:= walking;
            if get_id_fermata_from_id_urbana(get_ingresso_from_id(residente.get_id_luogo_casa_from_abitante+get_from_ingressi-1).get_id_main_strada_ingresso)=0 then
               raise fermata_inesistente;
            end if;
            get_location_abitanti_quartiere.set_destination_abitante_in_bus(residente.get_id_abitante_from_abitante,create_tratto(residente.get_id_quartiere_luogo_lavoro_from_abitante,residente.get_id_luogo_lavoro_from_abitante+get_quartiere_cfg(residente.get_id_quartiere_luogo_lavoro_from_abitante).get_from_type_resource_quartiere(ingresso)-1));
            percorso:= new route_and_distance'(get_server_gps.calcola_percorso(from_id_quartiere => residente.get_id_quartiere_from_abitante, from_id_luogo => residente.get_id_luogo_casa_from_abitante+get_from_ingressi-1,
                                                                               to_id_quartiere => residente.get_id_quartiere_from_abitante, to_id_luogo => get_id_fermata_from_id_urbana(get_ingresso_from_id(residente.get_id_luogo_casa_from_abitante+get_from_ingressi-1).get_id_main_strada_ingresso),id_quartiere => get_id_quartiere,id_abitante => i));


         else
            mezzo:= residente.get_mezzo_abitante;
            percorso:= new route_and_distance'(get_server_gps.calcola_percorso(from_id_quartiere => residente.get_id_quartiere_from_abitante, from_id_luogo => residente.get_id_luogo_casa_from_abitante+get_from_ingressi-1,
                                                                               to_id_quartiere => residente.get_id_quartiere_luogo_lavoro_from_abitante, to_id_luogo => residente.get_id_luogo_lavoro_from_abitante+get_quartiere_cfg(residente.get_id_quartiere_luogo_lavoro_from_abitante).get_from_type_resource_quartiere(ingresso)-1,id_quartiere => get_id_quartiere,id_abitante => i));

         end if;
         print_percorso(percorso.get_percorso_from_route_and_distance);
         Put_Line("end request percorso " & Positive'Image(residente.get_id_abitante_from_abitante) & " " & Positive'Image(residente.get_id_quartiere_from_abitante));

         get_locate_abitanti_quartiere.set_percorso_abitante(id_abitante => i, percorso => percorso.all);
         get_ingressi_segmento_resources(get_from_ingressi+residente.get_id_luogo_casa_from_abitante-1).new_abitante_to_move(residente.get_id_quartiere_from_abitante,residente.get_id_abitante_from_abitante,mezzo);
      end loop;

      configure_linee_fermate;

   end start_entity_to_move;

   procedure start_autobus_to_move is
      autobus: abitante;
      percorso: access route_and_distance;
      first_fermata: tratto;
      linea: linea_bus;
   begin
      for i in get_to_abitanti-get_num_autobus+1..get_to_abitanti loop
         autobus:= get_quartiere_utilities_obj.get_abitante_quartiere(get_id_quartiere,i);
         linea:= get_linea(autobus.get_id_luogo_lavoro_from_abitante);
         first_fermata:= tratto(linea.get_num_tratto(1));
         --calcola percorso e prendi il riferimento a locate del quartiere abitante e setta percorso
         Put_Line("request percorso BUS " & Positive'Image(autobus.get_id_abitante_from_abitante) & " " & Positive'Image(autobus.get_id_quartiere_from_abitante));
         percorso:= new route_and_distance'(get_server_gps.calcola_percorso(from_id_quartiere => autobus.get_id_quartiere_from_abitante, from_id_luogo => autobus.get_id_luogo_casa_from_abitante+get_from_ingressi-1,
                                                                            to_id_quartiere => first_fermata.get_id_quartiere_tratto, to_id_luogo => first_fermata.get_id_tratto,id_quartiere => get_id_quartiere,id_abitante => i));
         print_percorso(percorso.get_percorso_from_route_and_distance);
         Put_Line("end request percorso BUS " & Positive'Image(autobus.get_id_abitante_from_abitante) & " " & Positive'Image(autobus.get_id_quartiere_from_abitante));

         get_locate_abitanti_quartiere.set_percorso_abitante(id_abitante => i, percorso => percorso.all);
         get_ingressi_segmento_resources(get_from_ingressi+autobus.get_id_luogo_casa_from_abitante-1).new_abitante_to_move(autobus.get_id_quartiere_from_abitante,autobus.get_id_abitante_from_abitante,autobus.get_mezzo_abitante);

      end loop;
   end start_autobus_to_move;


end start_simulation;
