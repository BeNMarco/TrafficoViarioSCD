with the_name_server;
with risorse_mappa_utilities;

use the_name_server;
use risorse_mappa_utilities;

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

   function get_distance_from_polo_percorrenza(road: strada_ingresso_features) return Float is
   begin
      if road.get_polo_ingresso=True then
         return get_urbana_from_id(road.get_id_main_strada_ingresso).get_lunghezza_road-road.get_distance_from_road_head_ingresso;
      else
         return road.get_distance_from_road_head_ingresso;
      end if;
   end get_distance_from_polo_percorrenza;

   function get_traiettoria_ingresso(type_traiettoria: traiettoria_ingressi_type) return traiettoria_ingresso is
   begin
      return traiettorie_ingressi(type_traiettoria);
   end get_traiettoria_ingresso;

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
                  end if;
               end if;
               if incrocio_a_3(i).get_id_quartiere_road_incrocio=to_road.get_id_quartiere_tratto and incrocio_a_3(i).get_id_strada_road_incrocio=to_road.get_id_tratto then
                  if id_road_mancante<=i then
                     key_road_to:= i+1;
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

      function get_id_main_road_from_id_ingresso(id_ingresso: Positive) return Positive is
      begin
         return get_ingresso_from_id(id_ingresso).get_id_main_strada_ingresso;
      end get_id_main_road_from_id_ingresso;

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

      entry wait_cfg when num_classi_locate_abitanti=get_num_quartieri and num_abitanti_quartieri_registrati=get_num_quartieri and num_quartieri_resource_registrate=get_num_quartieri is
      begin
         if inventory_estremi_is_set=False then
            inventory_estremi_urbane:= get_server_gps.get_estremi_strade_urbane(get_id_quartiere);
            for i in get_from_urbane..get_to_urbane loop
               if inventory_estremi_urbane(i,1).get_id_quartiere_estremo_urbana/=0 then
                  inventory_estremi(i,1):= get_id_risorsa_quartiere(inventory_estremi_urbane(i,1).get_id_quartiere_estremo_urbana,inventory_estremi_urbane(i,1).get_id_incrocio_estremo_urbana);
               else
                  inventory_estremi(i,1):= null;
               end if;
               if inventory_estremi_urbane(i,2).get_id_quartiere_estremo_urbana/=0 then
                  inventory_estremi(i,2):= get_id_risorsa_quartiere(inventory_estremi_urbane(i,2).get_id_quartiere_estremo_urbana,inventory_estremi_urbane(i,2).get_id_incrocio_estremo_urbana);
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

   protected body location_abitanti is
      procedure set_percorso_abitante(id_abitante: Positive; percorso: route_and_distance) is
      begin
         percorsi(id_abitante):= new route_and_distance'(percorso);
      end set_percorso_abitante;

      procedure set_position_abitante_to_next(id_abitante: Positive) is
      begin
         null;
      end set_position_abitante_to_next;

      function get_next(id_abitante: Positive) return tratto is
         route: percorso:= percorsi(id_abitante).get_percorso_from_route_and_distance;
      begin
         if position_abitanti(id_abitante)+1<=route'Last then
            return route(position_abitanti(id_abitante)+1);
         else
            return create_tratto(0,0);
         end if;
      end get_next;

      function get_next_road(id_abitante: Positive) return tratto is
         route: percorso:= percorsi(id_abitante).get_percorso_from_route_and_distance;
      begin
         if position_abitanti(id_abitante)+2<=route'Last then
            return route(position_abitanti(id_abitante)+2);
         else
            return create_tratto(0,0);
         end if;
      end get_next_road;

      function get_current_position(id_abitante: Positive) return tratto is
      begin
         return create_tratto(0,0);
      end get_current_position;

      function get_number_steps_to_finish_route(id_abitante: Positive) return Natural is
      begin
         return 0;
      end get_number_steps_to_finish_route;

   end location_abitanti;

   function get_locate_abitanti_quartiere return ptr_location_abitanti is
   begin
      return locate_abitanti_quartiere;
   end get_locate_abitanti_quartiere;

end risorse_passive_data;
