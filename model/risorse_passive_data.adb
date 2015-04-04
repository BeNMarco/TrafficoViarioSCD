with GNATCOLL.JSON;
with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Polyorb.Parameters;
with System_error;
with Ada.Exceptions;
with Ada.Strings.Unbounded;
with System.RPC;

with absolute_path;
with risorse_mappa_utilities;
with strade_e_incroci_common;
with data_quartiere;
with remote_types;
with global_data;
with snapshot_interface;
with JSON_Helper;
with the_name_server;

use GNATCOLL.JSON;
use Ada.Text_IO;
use Polyorb.Parameters;

use System_error;
use absolute_path;
use risorse_mappa_utilities;
use strade_e_incroci_common;
use data_quartiere;
use remote_types;
use global_data;
use snapshot_interface;
use JSON_Helper;
use the_name_server;
use Ada.Exceptions;
use Ada.Strings.Unbounded;

package body risorse_passive_data is

   function get_default_value_pedoni(value: move_settings) return new_float is
   begin
      case value is
         when desired_velocity => return default_desired_velocity_pedoni;
         when time_headway => return default_time_headway_pedoni;
         when max_acceleration => return default_max_acceleration_pedoni;
         when comfortable_deceleration => return default_comfortable_deceleration_pedoni;
         when s0 => return default_s0_pedoni;
         when length => return default_length_pedoni;
         when others => return 0.0;
      end case;
   end get_default_value_pedoni;

   function get_default_value_bici(value: move_settings) return new_float is
   begin
      case value is
         when desired_velocity => return default_desired_velocity_bici;
         when time_headway => return default_time_headway_bici;
         when max_acceleration => return default_max_acceleration_bici;
         when comfortable_deceleration => return default_comfortable_deceleration_bici;
         when s0 => return default_s0_bici;
         when length => return default_length_bici;
         when others => return 0.0;
      end case;
   end get_default_value_bici;

   function get_default_value_auto(value: move_settings; is_bus: Boolean) return new_float is
   begin
      case value is
         when desired_velocity => return get_default_desired_velocity_auto(is_bus);
         when time_headway => return get_default_time_headway_auto(is_bus);
         when max_acceleration => return get_default_max_acceleration_auto(is_bus);
         when comfortable_deceleration => return get_default_comfortable_deceleration_auto(is_bus);
         when s0 => return get_default_s0_auto(is_bus);
         when length => return get_default_length_auto(is_bus);
         when num_posti => return new_float(get_default_num_posti_auto(is_bus));
      end case;
   end get_default_value_auto;

   function get_urbana_from_id(index: Positive) return strada_urbana_features is
   begin
      return urbane_features(index);
   end get_urbana_from_id;
   function get_ingresso_from_id(index: Positive) return strada_ingresso_features is
   begin
      return ingressi_features(index);
   end get_ingresso_from_id;
   function get_incrocio_a_4_from_id(index: Positive) return list_road_incrocio_a_4 is
   begin
      return incroci_a_4(index);
   end get_incrocio_a_4_from_id;
   function get_incrocio_a_3_from_id(index: Positive) return list_road_incrocio_a_3 is
   begin
      return incroci_a_3(index);
   end get_incrocio_a_3_from_id;
   --function get_rotonda_a_4_from_id(index: Positive) return list_road_incrocio_a_4 is
   --begin
   --   return rotonde_a_4(index);
   --end get_rotonda_a_4_from_id;
   --function get_rotonda_a_3_from_id(index: Positive) return list_road_incrocio_a_3 is
   --begin
   --   return rotonde_a_3(index);
   --end get_rotonda_a_3_from_id;

   function get_road_from_incrocio(index_incrocio: Positive; key_road: Positive) return road_incrocio_features is
      pragma Warnings(off);
      road: road_incrocio_features;
      pragma Warnings(on);
   begin
      if index_incrocio>=get_from_incroci_a_4 and index_incrocio<=get_to_incroci_a_4 then
         return get_incrocio_a_4_from_id(index_incrocio)(key_road);
      elsif index_incrocio>=get_from_incroci_a_3 and index_incrocio<=get_to_incroci_a_3 then
         return get_incrocio_a_3_from_id(index_incrocio)(key_road);
      end if;
      return road;
   end get_road_from_incrocio;

   function get_index_road_from_incrocio(id_quartiere_road: Positive; id_road: Positive; id_incrocio: Positive) return Natural is
      road: road_incrocio_features;
   begin
      for i in 1..get_size_incrocio(id_incrocio) loop
         road:= get_road_from_incrocio(id_incrocio,i);
         if road.get_id_quartiere_road_incrocio=id_quartiere_road and road.get_id_strada_road_incrocio=id_road then
            return i;
         end if;
      end loop;
      return 0;
   end get_index_road_from_incrocio;

   function get_urbane return strade_urbane_features is
   begin
      return urbane_features;
   end get_urbane;
   function get_ingressi return strade_ingresso_features is
   begin
      return ingressi_features;
   end get_ingressi;
   function get_incroci_a_4 return list_incroci_a_4 is
   begin
      return incroci_a_4;
   end get_incroci_a_4;
   function get_incroci_a_3 return list_incroci_a_3 is
   begin
      return incroci_a_3;
   end get_incroci_a_3;
   --function get_rotonde_a_4 return list_incroci_a_4 is
   --begin
   --   return rotonde_a_4;
   --end get_rotonde_a_4;
   --function get_rotonde_a_3 return list_incroci_a_3 is
   --begin
   --   return rotonde_a_3;
   --end get_rotonde_a_3;

   function get_distance_from_polo_percorrenza(road: strada_ingresso_features; polo: Boolean) return new_float is
   begin
      if polo then
         return get_urbana_from_id(road.get_id_main_strada_ingresso).get_lunghezza_road-road.get_distance_from_road_head_ingresso;
      else
         return road.get_distance_from_road_head_ingresso;
      end if;
   end get_distance_from_polo_percorrenza;

   function get_traiettoria_ingresso(type_traiettoria: traiettoria_ingressi_type) return traiettoria_ingresso is
   begin
      return traiettorie_ingressi(type_traiettoria);
   end get_traiettoria_ingresso;

   function get_traiettoria_cambio_corsia return traiettoria_cambio_corsia is
   begin
      return traiettorie_cambio_corsia;
   end get_traiettoria_cambio_corsia;

   protected body quartiere_utilities is

      procedure registra_cfg_quartiere(id_quartiere: Positive; abitanti: list_abitanti_quartiere; pedoni: list_pedoni_quartiere;
                                              bici: list_bici_quartiere; auto: list_auto_quartiere; location_abitanti: ptr_rt_location_abitanti) is
      begin
         rt_classi_locate_abitanti(id_quartiere):= location_abitanti;
         entità_abitanti(id_quartiere):= new list_abitanti_quartiere'(abitanti);
         entità_pedoni(id_quartiere):= new list_pedoni_quartiere'(pedoni);
         entità_bici(id_quartiere):= new list_bici_quartiere'(bici);
         entità_auto(id_quartiere):= new list_auto_quartiere'(auto);
         cache_remoti_registrati(id_quartiere):= True;
      end registra_cfg_quartiere;

      function is_configured_cache_quartiere(id_quartiere: Positive) return Boolean is
      begin
         return cache_remoti_registrati(id_quartiere);
      end is_configured_cache_quartiere;

      procedure get_cfg_incrocio(id_incrocio: Positive; from_road: tratto; to_road: tratto; key_road_from: out Natural; key_road_to: out Natural; id_road_mancante: out Natural) is
         incrocio_a_3: list_road_incrocio_a_3;
         incrocio_a_4: list_road_incrocio_a_4;

      begin
         if id_incrocio>=get_from_incroci_a_3 and id_incrocio<=get_to_incroci_a_3 then
            incrocio_a_3:= get_incrocio_a_3_from_id(id_incrocio);
            id_road_mancante:= get_mancante_incrocio_a_3(id_incrocio);
            key_road_from:= 0;
            key_road_to:= 0;
            for i in incrocio_a_3'Range loop
               if incrocio_a_3(i).get_id_quartiere_road_incrocio=from_road.get_id_quartiere_tratto and incrocio_a_3(i).get_id_strada_road_incrocio=from_road.get_id_tratto then
                  if id_road_mancante<=i then
                     key_road_from:= i+1;
                  else
                     key_road_from:= i;
                  end if;
               end if;
               if incrocio_a_3(i).get_id_quartiere_road_incrocio=to_road.get_id_quartiere_tratto and incrocio_a_3(i).get_id_strada_road_incrocio=to_road.get_id_tratto then
                  if id_road_mancante<=i then
                     key_road_to:= i+1;
                  else
                     key_road_to:= i;
                  end if;
               end if;
            end loop;
         elsif id_incrocio>=get_from_incroci_a_4 and id_incrocio<=get_to_incroci_a_4 then
            incrocio_a_4:= get_incrocio_a_4_from_id(id_incrocio);
            id_road_mancante:= 0;
            for i in incrocio_a_4'Range loop
               if incrocio_a_4(i).get_id_quartiere_road_incrocio=from_road.get_id_quartiere_tratto and incrocio_a_4(i).get_id_strada_road_incrocio=from_road.get_id_tratto then
                     key_road_from:= i;
               end if;
               if incrocio_a_4(i).get_id_quartiere_road_incrocio=to_road.get_id_quartiere_tratto and incrocio_a_4(i).get_id_strada_road_incrocio=to_road.get_id_tratto then
                     key_road_to:= i;
               end if;
            end loop;
         end if;
      end get_cfg_incrocio;

      function get_all_abitanti_quartiere return list_abitanti_quartiere is
      begin
         return entità_abitanti(get_id_quartiere).all;
      end get_all_abitanti_quartiere;
      function get_all_pedoni_quartiere return list_pedoni_quartiere is
      begin
         return entità_pedoni(get_id_quartiere).all;
      end get_all_pedoni_quartiere;
      function get_all_bici_quartiere return list_bici_quartiere is
      begin
         return entità_bici(get_id_quartiere).all;
      end get_all_bici_quartiere;
      function get_all_auto_quartiere return list_auto_quartiere is
      begin
         return entità_auto(get_id_quartiere).all;
      end get_all_auto_quartiere;
      function get_locate_abitanti_quartiere(id_quartiere: Positive) return ptr_rt_location_abitanti is
      begin
         return rt_classi_locate_abitanti(id_quartiere);
      end get_locate_abitanti_quartiere;

      function get_type_entity(id_entità: Positive) return entity_type is
      begin
         if id_entità>=get_from_urbane and id_entità<=get_to_urbane then
            return urbana;
         elsif id_entità>=get_from_ingressi and id_entità<=get_to_ingressi then
            return ingresso;
         elsif id_entità>=get_from_incroci_a_4 and id_entità<=get_to_incroci_a_4 then
            return incrocio_a_4;
         elsif id_entità>=get_from_incroci_a_3 and id_entità<=get_to_incroci_a_3 then
            return incrocio_a_3;
         else
            return empty;
         end if;
      end get_type_entity;

      function get_id_main_road_from_id_ingresso(id_ingresso: Positive) return Natural is
      begin
         if id_ingresso>=get_from_ingressi and id_ingresso<=get_to_ingressi then
            return get_ingresso_from_id(id_ingresso).get_id_main_strada_ingresso;
         else
            return 0;
         end if;
      end get_id_main_road_from_id_ingresso;

      function get_polo_ingresso(id_ingresso: Positive) return Boolean is
      begin
         return get_ingresso_from_id(id_ingresso).get_polo_ingresso;
      end get_polo_ingresso;

      function get_abitante_quartiere(id_quartiere: Positive; id_abitante: Positive) return abitante is
         entità: abitante:= entità_abitanti(id_quartiere)(id_abitante);
      begin
         return entità;
      end get_abitante_quartiere;

      function get_pedone_quartiere(id_quartiere: Positive; id_abitante: Positive) return pedone is
         entità: pedone:= entità_pedoni(id_quartiere)(id_abitante);
      begin
         return entità;
      end get_pedone_quartiere;

      function get_bici_quartiere(id_quartiere: Positive; id_abitante: Positive) return bici is
         entità: bici:= entità_bici(id_quartiere)(id_abitante);
      begin
         return entità;
      end get_bici_quartiere;

      function get_auto_quartiere(id_quartiere: Positive; id_abitante: Positive) return auto is
         entità: auto:= entità_auto(id_quartiere)(id_abitante);
      begin
         return entità;
      end get_auto_quartiere;

      function get_classe_locate_abitanti(id_quartiere: Positive) return ptr_rt_location_abitanti is
      begin
         return rt_classi_locate_abitanti(id_quartiere);
      end get_classe_locate_abitanti;

      function get_index_luogo_from_id_json(json_key: Positive) return Positive is
      begin
         return get_from_ingressi+json_key-1;
      end get_index_luogo_from_id_json;

      function get_from_type_resource_quartiere(resource: resource_type) return Natural is
      begin
         case resource is
            when urbana => return get_from_urbane;
            when ingresso => return get_from_ingressi;
            when incrocio => return get_from_incroci_a_4;
         end case;
      end get_from_type_resource_quartiere;

      function get_to_type_resource_quartiere(resource: resource_type) return Natural is
      begin
         case resource is
            when urbana => return get_to_urbane;
            when ingresso => return get_to_ingressi;
            when incrocio => return get_to_incroci_a_3;
         end case;
      end get_to_type_resource_quartiere;

      function get_from_ingressi_quartiere return Natural is
      begin
         return get_from_ingressi;
      end get_from_ingressi_quartiere;

      function is_incrocio(id_risorsa: Positive) return Boolean is
      begin
         if id_risorsa>=get_from_incroci_a_3 and id_risorsa<=get_to_incroci_a_3 then
            return True;
         elsif id_risorsa>=get_from_incroci_a_4 and id_risorsa<=get_to_incroci_a_4 then
            return True;
         else
            return False;
         end if;
      end is_incrocio;

      function get_id_fermata_id_urbana(id_urbana: Positive) return Natural is
      begin
         return get_id_fermata_from_id_urbana(id_urbana);
      end get_id_fermata_id_urbana;

      procedure set_synch_cache(registro: registro_quartieri) is
      begin
         synch_cache:= registro;
      end set_synch_cache;

      function get_saved_partitions return registro_quartieri is
      begin
         return synch_cache;
      end get_saved_partitions;

      function is_a_new_quartiere(id_quartiere: Positive) return Boolean is
      begin
         if synch_cache(id_quartiere)=null then
            return True;
         end if;
         return False;
      end is_a_new_quartiere;

      procedure set_quartieri_to_not_wait(queue: boolean_queue) is
      begin
         not_wait_quartieri:= queue;
      end set_quartieri_to_not_wait;

      function is_a_quartiere_to_wait(id_quartiere: Positive) return Boolean is
      begin
         return not not_wait_quartieri(id_quartiere);
      end is_a_quartiere_to_wait;

      procedure close_system is
      begin
         exit_partition_system:= True;
      end close_system;
      function is_system_closing return Boolean is
      begin
         return exit_partition_system;
      end is_system_closing;

      procedure all_can_be_closed is
      begin
         exit_all_system:= True;
      end all_can_be_closed;
      function all_system_can_be_closed return Boolean is
      begin
         return exit_all_system;
      end all_system_can_be_closed;

   end quartiere_utilities;

   function get_quartiere_utilities_obj return ptr_quartiere_utilities is
   begin
      return quartiere_cfg;
   end get_quartiere_utilities_obj;

   function get_gestore_bus_quartiere_obj return ptr_gestore_bus_quartiere is
   begin
      return gestore_bus_quartiere_obj;
   end get_gestore_bus_quartiere_obj;

   procedure reconfigure_estremi_urbane is
   begin
      inventory_estremi_urbane:= get_server_gps.get_estremi_strade_urbane(get_id_quartiere);
      for i in get_from_urbane..get_to_urbane loop
         if inventory_estremi_urbane(i,1).get_id_quartiere_estremo_urbana/=0 then
            inventory_estremi(i,1):= get_id_incrocio_quartiere(inventory_estremi_urbane(i,1).get_id_quartiere_estremo_urbana,inventory_estremi_urbane(i,1).get_id_incrocio_estremo_urbana);
         else
            inventory_estremi(i,1):= null;
         end if;
         if inventory_estremi_urbane(i,2).get_id_quartiere_estremo_urbana/=0 then
            inventory_estremi(i,2):= get_id_incrocio_quartiere(inventory_estremi_urbane(i,2).get_id_quartiere_estremo_urbana,inventory_estremi_urbane(i,2).get_id_incrocio_estremo_urbana);
         else
            inventory_estremi(i,2):= null;
         end if;
      end loop;
   end reconfigure_estremi_urbane;

   function get_resource_estremi_urbana(id_urbana: Positive) return estremi_resource_strada_urbana is
      estremi: estremi_resource_strada_urbana;
   begin
      estremi(1):= inventory_estremi(id_urbana,1);
      estremi(2):= inventory_estremi(id_urbana,2);
      return estremi;
   end get_resource_estremi_urbana;

   function get_estremi_urbana(id_urbana: Positive) return estremi_strada_urbana is
      estremi: estremi_strada_urbana;
   begin
      estremi(1):= inventory_estremi_urbane(id_urbana,1);
      estremi(2):= inventory_estremi_urbane(id_urbana,2);
      return estremi;
   end get_estremi_urbana;

   --function create_route_and_distance_from_json(json_percorso_abitante: JSON_Value; length: Natural) return ptr_route_and_distance is
   --   json_percorso: JSON_Array:= json_percorso_abitante.Get("percorso");
   --   route: percorso(1..length);
   --   json_tratto: JSON_Array;
   --begin
   --   if length=0 then
   --      return null;
   --   end if;
   --   for i in 1..length loop
   --      json_tratto:= Get(Get(json_percorso,i));
   --      route(i):= create_tratto(Get(Get(json_tratto,1)),Get(Get(json_tratto,2)));
   --   end loop;
   --   return new route_and_distance'(create_percorso(route,json_percorso_abitante.Get("distanza")));
   --end create_route_and_distance_from_json;

   protected body location_abitanti is

      procedure create_img(json_1: out JSON_Value) is
      --   segmento: tratto;
      --   route: JSON_Array;
      --   passo: JSON_Array;
      --   json_2: JSON_Value;
      --   json_3: JSON_Value;
      --   convert_passo: JSON_Value;
      begin
         null;
      --   begin
      --   json_1:= Create_Object;
      --   json_2:= Create_Object;
      --   for i in percorsi'Range loop
      --      if percorsi(i)/=null then
      --         route:= Empty_Array;
      --         json_3:= Create_Object;
      --         for j in percorsi(i).get_percorso_from_route_and_distance'Range loop
      --            passo:= Empty_Array;
      --            segmento:= percorsi(i).get_percorso_from_route_and_distance(j);
      --            Append(passo,Create(segmento.get_id_quartiere_tratto));
      --            Append(passo,Create(segmento.get_id_tratto));
      --            convert_passo:= Create(passo);
      --            Append(route,convert_passo);
      --         end loop;
      --         json_3.Set_Field("percorso",route);
      --         json_3.Set_Field("distanza",Create(percorsi(i).get_distance_from_route_and_distance));
      --         json_2.Set_Field(Positive'Image(i),json_3);
      --      end if;
      --   end loop;
      --   json_1.Set_Field("percorsi",json_2);

      --   json_2:= Create_Object;
      --   for i in position_abitanti'Range loop
      --      json_2.Set_Field(Positive'Image(i),position_abitanti(i));
      --   end loop;
      --   json_1.Set_Field("position_abitanti",json_2);

      --   json_2:= Create_Object;
      --   for i in abitanti_arrived'Range loop
      --      json_2.Set_Field(Positive'Image(i),abitanti_arrived(i));
      --   end loop;
      --   json_1.Set_Field("abitanti_arrived",json_2);
      --   exception
      --      when others =>
      --         Put_Line("ERROR nella creazione position_abitanti");
      --         raise set_field_json_error;
      --   end;
      end create_img;

      procedure recovery_resource is
      --   json_locate_abitanti: JSON_Value;
      --   json_percorsi: JSON_Value;
      --   json_positions: JSON_Value;
      --   json_arrivi: JSON_Value;
      --   json_percorso_abitante: JSON_Value;
      begin
         null;
      --   share_snapshot_file_quartiere.get_json_value_locate_abitanti(json_locate_abitanti);

       --  json_percorsi:= json_locate_abitanti.Get("percorsi");
       --  for i in get_from_abitanti..get_to_abitanti loop
       --     json_percorso_abitante:= json_percorsi.Get(Positive'Image(i));
            -- solo se la lunghezza è diversa da 0 cosi se arrivano
            -- nuove richieste che settano il percorso queste non vengono toccate
       --     if Length(json_percorso_abitante.Get("percorso"))/=0 then
      --         percorsi(i):= create_route_and_distance_from_json(json_percorso_abitante,Length(json_percorso_abitante.Get("percorso")));
      --      end if;
      --   end loop;

      --   json_positions:= json_locate_abitanti.Get("position_abitanti");
      --   for i in get_from_abitanti..get_to_abitanti loop
      --      position_abitanti(i):= json_positions.Get(Positive'Image(i));
      --   end loop;

      --   json_arrivi:= json_locate_abitanti.Get("abitanti_arrived");
      --   for i in get_from_abitanti..get_to_abitanti loop
      --      abitanti_arrived(i):= json_arrivi.Get(Positive'Image(i));
      --   end loop;
      end recovery_resource;

      procedure set_percorso_abitante(id_abitante: Positive; percorso: route_and_distance) is
      begin
         abitanti_arrived(id_abitante):= False;
         percorsi(id_abitante):= new route_and_distance'(percorso);
         position_abitanti(id_abitante):= 1;
      end set_percorso_abitante;

      procedure set_position_abitante_to_next(id_abitante: Positive) is
      begin
         position_abitanti(id_abitante):= position_abitanti(id_abitante)+1;
      end set_position_abitante_to_next;

      procedure set_finish_route(id_abitante: Positive) is
      begin
         abitanti_arrived(id_abitante):= True;
      end set_finish_route;

      function get_next(id_abitante: Positive) return tratto is
         route: percorso:= percorsi(id_abitante).get_percorso_from_route_and_distance;
      begin
         if position_abitanti(id_abitante)+1<=route'Last then
            return route(position_abitanti(id_abitante)+1);
         else
            return create_tratto(0,0);
         end if;
      end get_next;

      function get_next_road(id_abitante: Positive; from_ingresso: Boolean) return tratto is
         route: percorso:= percorsi(id_abitante).get_percorso_from_route_and_distance;
         slice: Positive;
      begin
         if from_ingresso then
            slice:= 2;
         else
            slice:= 3;
         end if;

         if position_abitanti(id_abitante)+slice<=route'Last then
            return route(position_abitanti(id_abitante)+slice);
         else
            return create_tratto(0,0);
         end if;
      end get_next_road;

      function get_next_incrocio(id_abitante: Positive) return tratto is
         route: percorso:= percorsi(id_abitante).get_percorso_from_route_and_distance;
      begin
         if position_abitanti(id_abitante)+2<=route'Last then
            return route(position_abitanti(id_abitante)+2);
         else
            return create_tratto(0,0);
         end if;
      end get_next_incrocio;

      function get_current_tratto(id_abitante: Positive) return tratto is
      begin
         return percorsi(id_abitante).get_percorso_from_route_and_distance(position_abitanti(id_abitante));
      end get_current_tratto;

      function get_current_position(id_abitante: Positive) return Positive is
      begin
         return position_abitanti(id_abitante);
      end get_current_position;

      function get_number_steps_to_finish_route(id_abitante: Positive) return Natural is
      begin
         return percorsi(id_abitante).get_percorso_from_route_and_distance'Last-position_abitanti(id_abitante);
      end get_number_steps_to_finish_route;

      function get_destination_abitante_in_bus(id_abitante: Positive) return tratto is
      begin
         return destination_abitanti_on_bus(id_abitante);
      end get_destination_abitante_in_bus;

      procedure set_destination_abitante_in_bus(id_abitante: Positive; destination: tratto) is
      begin
         destination_abitanti_on_bus(id_abitante):= destination;
      end set_destination_abitante_in_bus;

      --function get_ingresso_destination(id_abitante: Positive) return tratto is
      --begin
      --   return create_tratto(0,0);
      --end get_ingresso_destination;

   end location_abitanti;

   function get_locate_abitanti_quartiere return ptr_location_abitanti is
   begin
      return locate_abitanti_quartiere;
   end get_locate_abitanti_quartiere;

   function get_larghezza_marciapiede return new_float is
   begin
      return larghezza_marciapiede;
   end get_larghezza_marciapiede;
   function get_larghezza_corsia return new_float is
   begin
      return larghezza_corsia;
   end get_larghezza_corsia;

   function get_size_incrocio(id_incrocio: Positive) return Positive is
   begin
      if id_incrocio>=get_from_incroci_a_3 and id_incrocio<=get_to_incroci_a_3 then
         return 3;
      else
         return 4;
      end if;
   end get_size_incrocio;

   function create_lista_passeggeri(identificativo_ab: tratto; next: ptr_lista_passeggeri) return lista_passeggeri is
      elemento: lista_passeggeri;
   begin
      elemento.identificativo_abitante:= identificativo_ab;
      elemento.next:= next;
      return elemento;
   end create_lista_passeggeri;
   function get_identificativo_abitante(obj: lista_passeggeri) return tratto is
   begin
      return obj.identificativo_abitante;
   end get_identificativo_abitante;
   function get_next(obj: lista_passeggeri) return ptr_lista_passeggeri is
   begin
      return obj.next;
   end get_next;
   procedure set_identificativo_abitante(obj: in out lista_passeggeri; identificativo_ab: tratto) is
   begin
      obj.identificativo_abitante:= identificativo_ab;
   end set_identificativo_abitante;
   procedure set_next(obj: in out lista_passeggeri; next: ptr_lista_passeggeri) is
   begin
      obj.next:= next;
   end set_next;

   protected body gestore_bus_quartiere is
      -- configure può essere chiamata solo dopo l'avvenuto check-point
      -- in configure di resource_map_inventory

      procedure autobus_arrived_at_fermata(to_id_autobus: Positive; abitanti: set_tratti; from_fermata: tratto) is
         id_urbana_to_go: Positive;
         id_fermata: Positive;
         destination: tratto;
         overwrite_abitanti: set_tratti(1..abitanti'Last);
         index: Positive:= 1;
         autobus: abitante:= get_quartiere_utilities_obj.get_abitante_quartiere(get_id_quartiere,to_id_autobus);
         list: ptr_lista_passeggeri:= passeggeri_bus(to_id_autobus);
         prec_list: ptr_lista_passeggeri:= null;
         mailbox_fermata: ptr_rt_ingresso:= null;
         jolly_arrived: Boolean:= False;
         abitante_is_arrived: Boolean;
      begin
         -- l'abitante è arrivato alla fermata
         -- fa scendere abitanti
         mailbox_fermata:= get_id_ingresso_quartiere(from_fermata.get_id_quartiere_tratto,from_fermata.get_id_tratto);
         prec_list:= null;
         if autobus.is_a_bus_jolly and linee_autobus(autobus.get_id_luogo_lavoro_from_abitante).get_numero_fermate=stato_bus(to_id_autobus).index_fermata then
            jolly_arrived:= True;
         end if;

         while list/=null loop
            if jolly_arrived then
               mailbox_fermata.add_abitante_in_fermata(list.identificativo_abitante);
            else
               abitante_is_arrived:= False;
               destination:= get_quartiere_utilities_obj.get_classe_locate_abitanti(list.identificativo_abitante.get_id_quartiere_tratto).get_destination_abitante_in_bus(list.identificativo_abitante.get_id_tratto);
               id_urbana_to_go:= get_ref_quartiere(destination.get_id_quartiere_tratto).get_id_main_road_from_id_ingresso(destination.get_id_tratto);
               id_fermata:= get_ref_quartiere(destination.get_id_quartiere_tratto).get_id_fermata_id_urbana(id_urbana_to_go);
               if tratto(from_fermata)=create_tratto(destination.get_id_quartiere_tratto,id_fermata) then
                  abitante_is_arrived:= True;
               end if;
               if abitante_is_arrived then
                  get_quartiere_entities_life(list.identificativo_abitante.get_id_quartiere_tratto).abitante_scende_dal_bus(list.identificativo_abitante.get_id_tratto,from_fermata);
               end if;
            end if;
            if jolly_arrived or else abitante_is_arrived then
               -- rimuovere abitante dalla lista
               if prec_list=null then
                  passeggeri_bus(to_id_autobus):= passeggeri_bus(to_id_autobus).next;
                  list:= passeggeri_bus(to_id_autobus);
               else
                  prec_list.next:= list.next;
                  -- list prende prec_list
                  -- cosichè list:= list.next prende
                  -- l'elemento successivo a quello eliminato
                  list:= prec_list;
               end if;
            end if;
            prec_list:= list;
            list:= list.next;
         end loop;

         -- l'autobus non è arrivato alla posizione jolly
         if jolly_arrived=False then
            avanza_fermata(to_id_autobus);
            list:= passeggeri_bus(to_id_autobus);
            prec_list:= null;
            while list/=null loop
               prec_list:= list;
               list:= list.next;
            end loop;
            -- posizionamento all'ultimo abitante della lista
            list:= prec_list;
            for i in abitanti'Range loop
               -- destination è il luogo in cui l'abitante deve andare
               -- un autobus può nascere in qualunque quartiere
               destination:= get_quartiere_utilities_obj.get_classe_locate_abitanti(abitanti(i).get_id_quartiere_tratto).get_destination_abitante_in_bus(abitanti(i).get_id_tratto);
               id_urbana_to_go:= get_ref_quartiere(destination.get_id_quartiere_tratto).get_id_main_road_from_id_ingresso(destination.get_id_tratto);
               id_fermata:= get_ref_quartiere(destination.get_id_quartiere_tratto).get_id_fermata_id_urbana(id_urbana_to_go);
               -- fermata è la fermata in cui l'abitante deve andare
               if fermata_da_fare(to_id_autobus,create_tratto(destination.get_id_quartiere_tratto,id_fermata))or else
                 (autobus.is_a_bus_jolly and then (autobus.is_a_jolly_to_quartiere=destination.get_id_quartiere_tratto)) then
                  overwrite_abitanti(index):= abitanti(i);
                  index:= index+1;
                  if list=null then
                     passeggeri_bus(to_id_autobus):= new lista_passeggeri'(create_lista_passeggeri(abitanti(i),null));
                     list:= passeggeri_bus(to_id_autobus);
                  else
                     list.next:= new lista_passeggeri'(create_lista_passeggeri(abitanti(i),null));
                     -- list.next/=null
                     list:= list.next;
                  end if;
               end if;
               -- viene controllato se la fermata è da fare per l'autobus in questione
            end loop;

            mailbox_fermata.aggiorna_abitanti_in_fermata(overwrite_abitanti);
         end if;
      end autobus_arrived_at_fermata;

      procedure avanza_fermata(id_autobus: Positive) is
      begin
         stato_bus(id_autobus).index_fermata:= stato_bus(id_autobus).index_fermata+1;
      end avanza_fermata;

      procedure revert_percorso(id_autobus: Positive) is
      begin
         stato_bus(id_autobus).revert_percorso:= not stato_bus(id_autobus).revert_percorso;
         stato_bus(id_autobus).index_fermata:= 0;
      end revert_percorso;

      function linea_is_reverted(id_autobus: Positive) return Boolean is
      begin
         return stato_bus(id_autobus).revert_percorso;
      end linea_is_reverted;

      function fermata_da_fare(id_autobus: Positive; fermata: tratto) return Boolean is
         num_linea: Positive:= get_quartiere_utilities_obj.get_abitante_quartiere(get_id_quartiere,id_autobus).get_id_luogo_lavoro_from_abitante;
         from: Positive;
         to: Positive;
      begin
         if stato_bus(id_autobus).revert_percorso=False then
            from:= stato_bus(id_autobus).index_fermata+1;
            to:= linee_autobus(num_linea).get_numero_fermate;
         else
            from:= 1;
            to:= stato_bus(id_autobus).index_fermata-1;
         end if;
         for i in from..to loop
            if tratto(linee_autobus(num_linea).get_num_tratto(i))=tratto(fermata) then
               return True;
            end if;
         end loop;
         return False;
      end fermata_da_fare;

      function get_num_fermate_rimaste(id_autobus: Positive) return Natural is
         num_linea: Positive:= get_quartiere_utilities_obj.get_abitante_quartiere(get_id_quartiere,id_autobus).get_id_luogo_lavoro_from_abitante;
      begin
         return linee_autobus(num_linea).get_numero_fermate-stato_bus(id_autobus).index_fermata;
      end get_num_fermate_rimaste;

      function get_num_fermata_arrived(id_autobus: Positive) return Positive is
      begin
         return stato_bus(id_autobus).index_fermata;
      end get_num_fermata_arrived;

      --function get_gestore_bus_quartiere(id_quartiere: Positive) return ptr_rt_gestore_bus_quartiere is
      --begin
      --   return registro_gestori_autobus_quartieri(id_quartiere);
      --end get_gestore_bus_quartiere;

   end gestore_bus_quartiere;

   procedure configure_quartiere_obj is
      num_quartieri: Positive;
   begin
      num_quartieri:= get_num_quartieri;

      quartiere_cfg:= new quartiere_utilities(num_quartieri);
      locate_abitanti_quartiere:= new location_abitanti(get_to_abitanti-get_from_abitanti+1);
      quartiere_entities_life_obj:= new quartiere_entities_life;
      gestore_bus_quartiere_obj:= new gestore_bus_quartiere(num_quartieri,get_num_autobus);

      create_linee_fermate;

      configure_map_fermate_urbane;

   end configure_quartiere_obj;


   procedure configure_map_fermate_urbane is
      num_fermate: Natural:= 0;
   begin
      for i in get_from_ingressi..get_to_ingressi loop
         if get_ingresso_from_id(i).get_type_ingresso=fermata then
            fermate_associate_a_urbane(get_ingresso_from_id(i).get_id_main_strada_ingresso):= get_ingresso_from_id(i).get_id_road;
            num_fermate:= num_fermate+1;
         end if;
      end loop;
      Put_Line("numero fermate quartiere " & Positive'Image(get_id_quartiere) & " " & Positive'Image(num_fermate));
   end configure_map_fermate_urbane;

   procedure update_percorso_abitante_arrived(percorso: route_and_distance; residente: abitante) is
   begin
      Put_Line("request percorso " & Positive'Image(residente.get_id_abitante_from_abitante) & " " & Positive'Image(residente.get_id_quartiere_from_abitante));
      print_percorso(percorso.get_percorso_from_route_and_distance);
      Put_Line("end request percorso " & Positive'Image(residente.get_id_abitante_from_abitante) & " " & Positive'Image(residente.get_id_quartiere_from_abitante));
      get_locate_abitanti_quartiere.set_percorso_abitante(residente.get_id_abitante_from_abitante,percorso);
   end update_percorso_abitante_arrived;

   procedure abitante_is_arrived(obj: quartiere_entities_life; id_abitante: Positive) is
      resource_locate_abitanti: ptr_location_abitanti:= get_locate_abitanti_quartiere;
      arrived_tratto: tratto;
      tratto_to_go: tratto;
      residente: abitante;
      segnale: Boolean;
      mezzo: means_of_carrying;
      id_urbana: Positive;
      id_fermata: Positive;
      destination: tratto;
      error_state: Boolean:= False;
   begin
      arrived_tratto:= resource_locate_abitanti.get_next(id_abitante);
      residente:= get_quartiere_utilities_obj.get_abitante_quartiere(get_id_quartiere,id_abitante);
      -- get_id_quartiere coincide con residente.get_id_quartiere_from_abitante
      Put_Line(Positive'Image(arrived_tratto.get_id_quartiere_tratto) & " " & Positive'Image(arrived_tratto.get_id_tratto) & "id quart ab " & Positive'Image(get_id_quartiere) & " id ab " & Positive'Image(id_abitante));
      mezzo:= residente.get_mezzo_abitante;
      if is_abitante_in_bus(id_abitante) then
         mezzo:= walking;
         id_urbana:= get_ref_quartiere(arrived_tratto.get_id_quartiere_tratto).get_id_main_road_from_id_ingresso(arrived_tratto.get_id_tratto);
         id_fermata:= get_ref_quartiere(arrived_tratto.get_id_quartiere_tratto).get_id_fermata_id_urbana(id_urbana);
         destination:= get_location_abitanti_quartiere.get_destination_abitante_in_bus(residente.get_id_abitante_from_abitante);
         --residente.get_id_quartiere_from_abitante
         if residente.get_id_quartiere_from_abitante=arrived_tratto.get_id_quartiere_tratto and then arrived_tratto.get_id_tratto=residente.get_id_luogo_casa_from_abitante+get_from_ingressi-1 then
            -- il residente è arrivato a casa lo si manda a lavorare
            get_location_abitanti_quartiere.set_destination_abitante_in_bus(id_abitante,create_tratto(residente.get_id_luogo_lavoro_from_abitante,residente.get_id_luogo_lavoro_from_abitante+get_ref_quartiere(residente.get_id_quartiere_luogo_lavoro_from_abitante).get_from_type_resource_quartiere(ingresso)-1));
         else
            get_location_abitanti_quartiere.set_destination_abitante_in_bus(id_abitante,create_tratto(get_id_quartiere,residente.get_id_luogo_casa_from_abitante+get_from_ingressi-1));
         end if;
         declare
            percorso: route_and_distance:= get_server_gps.calcola_percorso(from_id_quartiere => arrived_tratto.get_id_quartiere_tratto, from_id_luogo => arrived_tratto.get_id_tratto,
                                                                              to_id_quartiere => arrived_tratto.get_id_quartiere_tratto, to_id_luogo => id_fermata,id_quartiere => get_id_quartiere,id_abitante => id_abitante);
         begin
            update_percorso_abitante_arrived(percorso,residente);
         end;
      elsif residente.is_a_bus then
         --if id_abitante=125 and then arrived_tratto.get_id_tratto=47 then
         --   error_state:= False;
         --end if;
         Put_Line("BUSSSSS " & Positive'Image(id_abitante) & " " & Positive'Image(get_id_quartiere));
         if get_gestore_bus_quartiere_obj.get_num_fermate_rimaste(id_abitante)=0 then
            segnale:= False;
            if residente.is_a_bus_jolly then
               if residente.is_a_jolly_to_quartiere=arrived_tratto.get_id_quartiere_tratto then
                  -- l'abitante è arrivato alla postazione jolly
                  segnale:= True;
               else
                  tratto_to_go:= tratto(linee_autobus(residente.get_id_luogo_lavoro_from_abitante).get_jolly_quartiere_to_go(residente.is_a_jolly_to_quartiere));
               end if;
            end if;
            if segnale or else residente.is_a_bus_jolly=False then
               get_gestore_bus_quartiere_obj.revert_percorso(id_abitante);
               if segnale=False then
                  -- non è un jolly
                  get_gestore_bus_quartiere_obj.avanza_fermata(id_abitante);
                  if get_gestore_bus_quartiere_obj.linea_is_reverted(id_abitante) then
                     tratto_to_go:= tratto(linee_autobus(residente.get_id_luogo_lavoro_from_abitante).get_num_tratto(linee_autobus(residente.get_id_luogo_lavoro_from_abitante).get_numero_fermate-1));
                  else
                     tratto_to_go:= tratto(linee_autobus(residente.get_id_luogo_lavoro_from_abitante).get_num_tratto(2));
                  end if;
               else
                  -- è un jolly
                  if get_gestore_bus_quartiere_obj.linea_is_reverted(id_abitante) then
                     tratto_to_go:= tratto(linee_autobus(residente.get_id_luogo_lavoro_from_abitante).get_num_tratto(linee_autobus(residente.get_id_luogo_lavoro_from_abitante).get_numero_fermate));
                  else
                     tratto_to_go:= tratto(linee_autobus(residente.get_id_luogo_lavoro_from_abitante).get_num_tratto(1));
                  end if;
               end if;
            end if;
         else
            if get_gestore_bus_quartiere_obj.linea_is_reverted(id_abitante) then
               tratto_to_go:= tratto(linee_autobus(residente.get_id_luogo_lavoro_from_abitante).get_num_tratto(linee_autobus(residente.get_id_luogo_lavoro_from_abitante).get_numero_fermate-(get_gestore_bus_quartiere_obj.get_num_fermata_arrived(id_abitante))));
            else
               tratto_to_go:= tratto(linee_autobus(residente.get_id_luogo_lavoro_from_abitante).get_num_tratto(get_gestore_bus_quartiere_obj.get_num_fermata_arrived(id_abitante)+1));
            end if;
         end if;
         declare
            percorso: route_and_distance:= get_server_gps.calcola_percorso(arrived_tratto.get_id_quartiere_tratto,arrived_tratto.get_id_tratto,tratto_to_go.get_id_quartiere_tratto,tratto_to_go.get_id_tratto,get_id_quartiere,id_abitante);
         begin
            update_percorso_abitante_arrived(percorso,residente);
         end;
      else
         if get_id_quartiere=arrived_tratto.get_id_quartiere_tratto and
           residente.get_id_luogo_casa_from_abitante+get_from_ingressi-1=arrived_tratto.get_id_tratto then
            -- l'abitante si trova a casa
            -- lo si manda a lavorare
            declare
               percorso: route_and_distance:= get_server_gps.calcola_percorso(arrived_tratto.get_id_quartiere_tratto,arrived_tratto.get_id_tratto,residente.get_id_quartiere_luogo_lavoro_from_abitante,residente.get_id_luogo_lavoro_from_abitante+get_ref_quartiere(residente.get_id_quartiere_luogo_lavoro_from_abitante).get_from_type_resource_quartiere(ingresso)-1,get_id_quartiere,id_abitante);
            begin
               update_percorso_abitante_arrived(percorso,residente);
            end;
         elsif residente.get_id_quartiere_luogo_lavoro_from_abitante=arrived_tratto.get_id_quartiere_tratto and
           residente.get_id_luogo_lavoro_from_abitante+get_ref_quartiere(residente.get_id_quartiere_luogo_lavoro_from_abitante).get_from_type_resource_quartiere(ingresso)-1=arrived_tratto.get_id_tratto then
            -- l'abitante è a lavoro
            -- lo si manda a casa
            declare
               percorso: route_and_distance:= get_server_gps.calcola_percorso(arrived_tratto.get_id_quartiere_tratto,arrived_tratto.get_id_tratto,get_id_quartiere,residente.get_id_luogo_casa_from_abitante+get_from_ingressi-1,get_id_quartiere,id_abitante);
            begin
               update_percorso_abitante_arrived(percorso,residente);
            end;
         else  -- lo si manda a casa cmq
            declare
               percorso: route_and_distance:= get_server_gps.calcola_percorso(arrived_tratto.get_id_quartiere_tratto,arrived_tratto.get_id_tratto,residente.get_id_quartiere_from_abitante,residente.get_id_luogo_casa_from_abitante+get_from_ingressi-1,get_id_quartiere,id_abitante);
            begin
               update_percorso_abitante_arrived(percorso,residente);
            end;
         end if;
      end if;

      -- Invio richiesta ASINCRONA
      ptr_rt_ingresso(get_id_ingresso_quartiere(arrived_tratto.get_id_quartiere_tratto,arrived_tratto.get_id_tratto)).new_abitante_to_move(get_id_quartiere,id_abitante,mezzo);
   exception
      when System.RPC.Communication_Error =>
         log_system_error.set_error(altro,error_state);
         -- se i task sono in select statement li chiudo
         Put_Line("partizione remota non raggiungibile.");
      when Error: others =>
         log_system_error.set_error(altro,error_state);
         -- se i task sono in select statement li chiudo
         Put_Line(Exception_Information(Error));
   end abitante_is_arrived;

   procedure abitante_scende_dal_bus(obj: quartiere_entities_life; id_abitante: Positive; alla_fermata: tratto) is
      tratto_to_go: tratto;
      residente: abitante;
      error_state: Boolean:= False;
   begin
      residente:= get_quartiere_utilities_obj.get_abitante_quartiere(get_id_quartiere,id_abitante);

      Put_Line(Positive'Image(alla_fermata.get_id_quartiere_tratto) & " " & Positive'Image(alla_fermata.get_id_tratto) & "id quart ab " & Positive'Image(get_id_quartiere) & " id ab " & Positive'Image(id_abitante));

      tratto_to_go:= get_location_abitanti_quartiere.get_destination_abitante_in_bus(id_abitante);

      declare
         percorso: route_and_distance:= get_server_gps.calcola_percorso(alla_fermata.get_id_quartiere_tratto,alla_fermata.get_id_tratto,tratto_to_go.get_id_quartiere_tratto,tratto_to_go.get_id_tratto,get_id_quartiere,id_abitante);
      begin
         Put_Line("request percorso abitante sceso da bus " & Positive'Image(residente.get_id_abitante_from_abitante) & " " & Positive'Image(residente.get_id_quartiere_from_abitante));
         print_percorso(percorso.get_percorso_from_route_and_distance);
         Put_Line("end request percorso abitante sceso da bus " & Positive'Image(residente.get_id_abitante_from_abitante) & " " & Positive'Image(residente.get_id_quartiere_from_abitante));
         ptr_rt_ingresso(get_id_ingresso_quartiere(alla_fermata.get_id_quartiere_tratto,alla_fermata.get_id_tratto)).new_abitante_to_move(get_id_quartiere,id_abitante,walking);
      end;
   exception
      when System.RPC.Communication_Error =>
         log_system_error.set_error(altro,error_state);
         -- se i task sono in select statement li chiudo
         Put_Line("partizione remota non raggiungibile.");
      when Error: others =>
         log_system_error.set_error(altro,error_state);
         -- se i task sono in select statement li chiudo
         Put_Line(Exception_Information(Error));
   end abitante_scende_dal_bus;

   function get_quartiere_entities_life_obj return ptr_quartiere_entities_life is
   begin
      return quartiere_entities_life_obj;
   end get_quartiere_entities_life_obj;

   function is_abitante_in_bus(id_abitante: Positive) return Boolean is
   begin
      for i in abitanti_in_bus'Range loop
         if abitanti_in_bus(i)+get_from_abitanti-1=id_abitante then
            return True;
         end if;
      end loop;
      return False;
   end is_abitante_in_bus;

   function get_linea(num_linea: Positive) return linea_bus is
   begin
      return linee_autobus(num_linea);
   end get_linea;

   function get_id_fermata_from_id_urbana(id_urbana: Positive) return Natural is
   begin
      return fermate_associate_a_urbane(id_urbana);
   end get_id_fermata_from_id_urbana;

   function get_location_abitanti_quartiere return ptr_location_abitanti is
   begin
      return locate_abitanti_quartiere;
   end get_location_abitanti_quartiere;

   procedure create_linee_fermate is
      json_fermate: JSON_Array:= get_json_fermate_autobus;
      temp1_json_value: JSON_Value;
      temp2_json_value: JSON_Value;
      temp0_json_array: JSON_Array;
      temp1_json_array: JSON_Array;
      temp2_json_array: JSON_Array;
      id_quartiere: Positive;
      id_tratto: Positive;
      linea: access tratti_fermata;
      jollys: access destination_tratti;
      jolly_to: Positive;
   begin
      for i in 1..Length(json_fermate) loop
         temp0_json_array:= Get(Get(json_fermate, i));
         temp1_json_value:= Get(temp0_json_array, 1);
         temp1_json_array:= Get(temp1_json_value,"linea");
         linea:= new tratti_fermata(1..Length(temp1_json_array));
         for j in 1..Length(temp1_json_array) loop
            temp2_json_array:= Get(Get(temp1_json_array,j));
            id_quartiere:= Get(Get(temp2_json_array,1));
            id_tratto:= Get(Get(temp2_json_array,2));
            linea(j):= create_tratto_updated(create_tratto(id_quartiere,id_tratto),False);
         end loop;
         temp1_json_array:= Get(temp1_json_value,"jolly");
         jollys:= new destination_tratti(1..Length(temp1_json_array));
         for j in 1..Length(temp1_json_array) loop
            temp2_json_value:= Get(temp1_json_array, j);
            jolly_to:= Get(Get(temp2_json_value,"to"));
            temp2_json_array:= Get(Get(temp2_json_value,"at"));
            id_quartiere:= Get(Get(temp2_json_array,1));
            id_tratto:= Get(Get(temp2_json_array,2));
            jollys(j):= create_destination(jolly_to,create_tratto(id_quartiere,id_tratto));
         end loop;
         temp1_json_array:= Get(temp1_json_value,"from_to");
         linee_autobus(i):= create_linea_bus(Get(Get(temp1_json_array,1)),Get(Get(temp1_json_array,2)),linea,jollys);
      end loop;
   end create_linee_fermate;

   procedure configure_linee_fermate is
      ref_quartieri: registro_quartieri:= get_ref_rt_quartieri;
      linea: access tratti_fermata;
      jollys: access destination_tratti;
      switch: Boolean;
   begin
      switch:= True;
      for i in linee_autobus'Range loop
         if linee_autobus(i).is_updated_linea=False then
            linea:= linee_autobus(i).get_linea_bus;
            for j in linea.all'Range loop
               if linea(j).is_tratto_updated=False then
                  if linea(j).get_tratto.get_id_quartiere_tratto=get_id_quartiere then
                     linea(j).update_tratto(create_tratto(get_id_quartiere,linea(j).get_tratto.get_id_tratto+get_from_ingressi-1));
                     linea(j).set_tratto_updated(True);
                  else
                     if ref_quartieri(linea(j).get_tratto.get_id_quartiere_tratto)/=null then
                        linea(j).update_tratto(create_tratto(linea(j).get_tratto.get_id_quartiere_tratto,ref_quartieri(linea(j).get_tratto.get_id_quartiere_tratto).get_from_type_resource_quartiere(ingresso)+linea(j).get_tratto.get_id_tratto-1));
                        linea(j).set_tratto_updated(True);
                     end if;
                  end if;
               end if;
            end loop;
            for j in linea.all'Range loop
               if linea(j).is_tratto_updated=False then
                  switch:= False;
               end if;
            end loop;
         end if;
         jollys:= linee_autobus(i).get_destination_jolly;
         for j in jollys.all'Range loop
            if jollys(j).is_updated=False then
               if jollys(j).get_quartiere_jolly_to_go=get_id_quartiere then
                  jollys(j).update_destination(create_tratto(get_id_quartiere,jollys(j).get_tratto_jolly_to_go.get_id_tratto+get_from_ingressi-1));
                  jollys(j).set_destination_updated(True);
               else
                  if ref_quartieri(jollys(j).get_quartiere_jolly_to_go)/=null then
                     jollys(j).update_destination(create_tratto(jollys(j).get_tratto_jolly_to_go.get_id_quartiere_tratto,ref_quartieri(jollys(j).get_quartiere_jolly_to_go).get_from_type_resource_quartiere(ingresso)+jollys(j).get_tratto_jolly_to_go.get_id_tratto-1));
                     jollys(j).set_destination_updated(True);
                  end if;
               end if;
            end if;
         end loop;
         for j in jollys.all'Range loop
            if jollys(j).is_updated=False then
               switch:= False;
            end if;
         end loop;
      end loop;
      if switch then
         fermate_configured:= True;
      end if;
   end configure_linee_fermate;

   function fermate_are_configured return Boolean is
   begin
      return fermate_configured;
   end fermate_are_configured;

   function get_traiettoria_incrocio(traiettoria: traiettoria_incroci_type) return traiettoria_incrocio is
   begin
      return traiettorie_incroci(traiettoria);
   end get_traiettoria_incrocio;

   function create_lista_tupla(tupla: tratto'Class; next: ptr_lista_tuple) return lista_tuple'Class is
      elemento: lista_tuple;
   begin
      elemento.identificativo_tupla:= tratto(tupla);
      elemento.next:= next;
      return elemento;
   end create_lista_tupla;

   function get_tupla(obj: lista_tuple) return tratto'Class is
   begin
      return obj.identificativo_tupla;
   end get_tupla;

   function get_next_tupla(obj: lista_tuple) return ptr_lista_tuple is
   begin
      return obj.next;
   end get_next_tupla;

   --procedure set_next_tupla(obj: in out lista_tuple; next: ptr_lista_tuple) is
   --begin
   --   obj.next:= next;
   --end set_next_tupla;

   protected body coda_abitanti_to_restart is
      procedure enqueue_abitante(entità: abitante) is
         prec_list: ptr_lista_tuple:= null;
         list: ptr_lista_tuple:= abitanti_non_partiti;
      begin
         while list/=null loop
            prec_list:= list;
            list:= list.get_next_tupla;
         end loop;
         if prec_list=null then
            abitanti_non_partiti:= new lista_tuple'(lista_tuple(create_lista_tupla(create_tratto(entità.get_id_quartiere_from_abitante,entità.get_id_abitante_from_abitante),null)));
         else
            prec_list.next:= new lista_tuple'(lista_tuple(create_lista_tupla(create_tratto(entità.get_id_quartiere_from_abitante,entità.get_id_abitante_from_abitante),null)));
         end if;
      end enqueue_abitante;

      procedure dequeue_abitante(entità: abitante; next_element_list: in out ptr_lista_tuple) is
         prec_list: ptr_lista_tuple:= null;
         list: ptr_lista_tuple:= abitanti_non_partiti;
      begin
         while list/=null loop
            if list.identificativo_tupla.get_id_quartiere_tratto=entità.get_id_quartiere_from_abitante and then
              list.identificativo_tupla.get_id_tratto=entità.get_id_abitante_from_abitante then
               if prec_list=null then
                  abitanti_non_partiti:= list.next;
               else
                  prec_list.next:= list.next;
               end if;
               next_element_list:= list.next;
               return;
            end if;
            prec_list:= list;
            list:= list.next;
         end loop;
      end dequeue_abitante;

      function get_abitanti_non_partiti return ptr_lista_tuple is
      begin
         return abitanti_non_partiti;
      end get_abitanti_non_partiti;

   end coda_abitanti_to_restart;


end risorse_passive_data;
