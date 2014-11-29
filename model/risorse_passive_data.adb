with GNATCOLL.JSON;
with Ada.Text_IO;
with Polyorb.Parameters;

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

use absolute_path;
use risorse_mappa_utilities;
use strade_e_incroci_common;
use data_quartiere;
use remote_types;
use global_data;
use snapshot_interface;
use JSON_Helper;
use the_name_server;

package body risorse_passive_data is

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
   function get_rotonda_a_4_from_id(index: Positive) return list_road_incrocio_a_4 is
   begin
      return rotonde_a_4(index);
   end get_rotonda_a_4_from_id;
   function get_rotonda_a_3_from_id(index: Positive) return list_road_incrocio_a_3 is
   begin
      return rotonde_a_3(index);
   end get_rotonda_a_3_from_id;

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
   function get_rotonde_a_4 return list_incroci_a_4 is
   begin
      return rotonde_a_4;
   end get_rotonde_a_4;
   function get_rotonde_a_3 return list_incroci_a_3 is
   begin
      return rotonde_a_3;
   end get_rotonde_a_3;

   function get_distance_from_polo_percorrenza(road: strada_ingresso_features; polo: Boolean) return Float is
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
      procedure registra_classe_locate_abitanti_quartiere(id_quartiere: Positive; location_abitanti: ptr_rt_location_abitanti) is
      begin
         rt_classi_locate_abitanti(id_quartiere):= location_abitanti;
         waiting_cfg.incrementa_classi_locate_abitanti;
      end registra_classe_locate_abitanti_quartiere;

      procedure registra_abitanti(from_id_quartiere: Positive; abitanti: list_abitanti_quartiere; pedoni: list_pedoni_quartiere;
                                  bici: list_bici_quartiere; auto: list_auto_quartiere) is
      begin

         entità_abitanti(from_id_quartiere):= new list_abitanti_quartiere'(abitanti);
         entità_pedoni(from_id_quartiere):= new list_pedoni_quartiere'(pedoni);
         entità_bici(from_id_quartiere):= new list_bici_quartiere'(bici);
         entità_auto(from_id_quartiere):= new list_auto_quartiere'(auto);

         waiting_cfg.incrementa_num_quartieri_abitanti;
      end registra_abitanti;

      procedure registra_mappa(id_quartiere: Positive) is
      begin
         waiting_cfg.incrementa_resource_mappa_quartieri;
      end registra_mappa;

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

   end quartiere_utilities;

   function get_quartiere_utilities_obj return ptr_quartiere_utilities is
   begin
      return quartiere_cfg;
   end get_quartiere_utilities_obj;

   protected body waiting_cfg is
      procedure incrementa_classi_locate_abitanti is
      begin
         num_classi_locate_abitanti:= num_classi_locate_abitanti+1;
      end incrementa_classi_locate_abitanti;

      procedure incrementa_num_quartieri_abitanti is
      begin
         num_abitanti_quartieri_registrati:= num_abitanti_quartieri_registrati+1;
      end incrementa_num_quartieri_abitanti;

      procedure incrementa_resource_mappa_quartieri is
      begin
         num_quartieri_resource_registrate:= num_quartieri_resource_registrate+1;
      end incrementa_resource_mappa_quartieri;

      entry wait_cfg when num_classi_locate_abitanti=num_quartieri and num_abitanti_quartieri_registrati=num_quartieri and num_quartieri_resource_registrate=num_quartieri is
      begin
         if inventory_estremi_is_set=False then
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
            inventory_estremi_is_set:= True;
         end if;
      end wait_cfg;

   end waiting_cfg;

   procedure wait_settings_all_quartieri is
   begin
      waiting_cfg.wait_cfg;
   end wait_settings_all_quartieri;

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

   function create_route_and_distance_from_json(json_percorso_abitante: JSON_Value; length: Natural) return ptr_route_and_distance is
      json_percorso: JSON_Array:= json_percorso_abitante.Get("percorso");
      route: percorso(1..length);
      json_tratto: JSON_Array;
   begin
      if length=0 then
         return null;
      end if;
      for i in 1..length loop
         json_tratto:= Get(Get(json_percorso,i));
         route(i):= create_tratto(Get(Get(json_tratto,1)),Get(Get(json_tratto,2)));
      end loop;
      return new route_and_distance'(create_percorso(route,json_percorso_abitante.Get("distanza")));
   end create_route_and_distance_from_json;

   protected body location_abitanti is

      procedure create_img(json_1: out JSON_Value) is
         segmento: tratto;
         route: JSON_Array;
         passo: JSON_Array;
         json_2: JSON_Value;
         json_3: JSON_Value;
         convert_passo: JSON_Value;
      begin
         json_1:= Create_Object;
         json_2:= Create_Object;
         for i in percorsi'Range loop
            if percorsi(i)/=null then
               route:= Empty_Array;
               json_3:= Create_Object;
               for j in percorsi(i).get_percorso_from_route_and_distance'Range loop
                  passo:= Empty_Array;
                  segmento:= percorsi(i).get_percorso_from_route_and_distance(j);
                  Append(passo,Create(segmento.get_id_quartiere_tratto));
                  Append(passo,Create(segmento.get_id_tratto));
                  convert_passo:= Create(passo);
                  Append(route,convert_passo);
               end loop;
               json_3.Set_Field("percorso",route);
               json_3.Set_Field("distanza",Create(percorsi(i).get_distance_from_route_and_distance));
               json_2.Set_Field(Positive'Image(i),json_3);
            end if;
         end loop;
         json_1.Set_Field("percorsi",json_2);

         json_2:= Create_Object;
         for i in position_abitanti'Range loop
            json_2.Set_Field(Positive'Image(i),position_abitanti(i));
         end loop;
         json_1.Set_Field("position_abitanti",json_2);

         json_2:= Create_Object;
         for i in abitanti_arrived'Range loop
            json_2.Set_Field(Positive'Image(i),abitanti_arrived(i));
         end loop;
         json_1.Set_Field("abitanti_arrived",json_2);

      end create_img;

      procedure recovery_resource is
         json_locate_abitanti: JSON_Value;
         json_percorsi: JSON_Value;
         json_positions: JSON_Value;
         json_arrivi: JSON_Value;
         json_percorso_abitante: JSON_Value;
      begin
         share_snapshot_file_quartiere.get_json_value_locate_abitanti(json_locate_abitanti);

         json_percorsi:= json_locate_abitanti.Get("percorsi");
         for i in get_from_abitanti..get_to_abitanti loop
            json_percorso_abitante:= json_percorsi.Get(Positive'Image(i));
            -- solo se la lunghezza è diversa da 0 cosi se arrivano
            -- nuove richieste che settano il percorso queste non vengono toccate
            if Length(json_percorso_abitante.Get("percorso"))/=0 then
               percorsi(i):= create_route_and_distance_from_json(json_percorso_abitante,Length(json_percorso_abitante.Get("percorso")));
            end if;
         end loop;

         json_positions:= json_locate_abitanti.Get("position_abitanti");
         for i in get_from_abitanti..get_to_abitanti loop
            position_abitanti(i):= json_positions.Get(Positive'Image(i));
         end loop;

         json_arrivi:= json_locate_abitanti.Get("abitanti_arrived");
         for i in get_from_abitanti..get_to_abitanti loop
            abitanti_arrived(i):= json_arrivi.Get(Positive'Image(i));
         end loop;
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
         return percorsi(id_abitante).get_percorso_from_route_and_distance'Length-position_abitanti(id_abitante);
      end get_number_steps_to_finish_route;

   end location_abitanti;

   function get_locate_abitanti_quartiere return ptr_location_abitanti is
   begin
      return locate_abitanti_quartiere;
   end get_locate_abitanti_quartiere;

   function get_larghezza_marciapiede return Float is
   begin
      return larghezza_marciapiede;
   end get_larghezza_marciapiede;
   function get_larghezza_corsia return Float is
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

   procedure configure_quartiere_obj is
   begin
      quartiere_cfg:= new quartiere_utilities;
      locate_abitanti_quartiere:= new location_abitanti(get_to_abitanti-get_from_abitanti+1);
   end configure_quartiere_obj;

   function get_traiettoria_incrocio(traiettoria: traiettoria_incroci_type) return traiettoria_incrocio is
   begin
      return traiettorie_incroci(traiettoria);
   end get_traiettoria_incrocio;

end risorse_passive_data;
