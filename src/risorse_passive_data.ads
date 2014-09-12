with risorse_mappa_utilities;
with strade_e_incroci_common;
with data_quartiere;
with remote_types;
with global_data;

use risorse_mappa_utilities;
use strade_e_incroci_common;
use data_quartiere;
use remote_types;
use global_data;

package risorse_passive_data is

   function get_urbana_from_id(index: Positive) return strada_urbana_features;
   function get_ingresso_from_id(index: Positive) return strada_ingresso_features;
   function get_incrocio_a_4_from_id(index: Positive) return list_road_incrocio_a_4;
   function get_incrocio_a_3_from_id(index: Positive) return list_road_incrocio_a_3;
   function get_rotonda_a_4_from_id(index: Positive) return list_road_incrocio_a_4;
   function get_rotonda_a_3_from_id(index: Positive) return list_road_incrocio_a_3;

   function get_urbane return strade_urbane_features;
   function get_ingressi return strade_ingresso_features;
   function get_incroci_a_4 return list_incroci_a_4;
   function get_incroci_a_3 return list_incroci_a_3;
   function get_rotonde_a_4 return list_incroci_a_4;
   function get_rotonde_a_3 return list_incroci_a_3;

   function get_traiettoria_ingresso(type_traiettoria: traiettoria_ingressi_type) return traiettoria_ingresso;

   protected type quartiere_utilities is new rt_quartiere_utilities with
      procedure registra_classe_locate_abitanti_quartiere(id_quartiere: Positive; location_abitanti: ptr_rt_location_abitanti);
      procedure registra_abitanti(from_id_quartiere: Positive; abitanti: list_abitanti_quartiere; pedoni: list_pedoni_quartiere;
                                  bici: list_bici_quartiere; auto: list_auto_quartiere);
      procedure registra_mappa(id_quartiere: Positive);
      procedure get_cfg_incrocio(id_incrocio: Positive; from_road: tratto; to_road: tratto; key_road_from: out Natural; key_road_to: out Natural; id_road_mancante: out Natural);

      function get_type_entity(id_entità: Positive) return entity_type;
      function get_id_main_road_from_id_ingresso(id_ingresso: Positive) return Positive;

      function get_abitante_quartiere(id_quartiere: Positive; id_abitante: Positive) return abitante;
      function get_pedone_quartiere(id_quartiere: Positive; id_abitante: Positive) return pedone;
      function get_bici_quartiere(id_quartiere: Positive; id_abitante: Positive) return bici;
      function get_auto_quartiere(id_quartiere: Positive; id_abitante: Positive) return auto;
      function get_classe_locate_abitanti(id_quartiere: Positive) return ptr_rt_location_abitanti;
   private

      entità_abitanti: list_abitanti_quartieri(1..get_num_quartieri);
      entità_pedoni: list_pedoni_quartieri(1..get_num_quartieri);
      entità_bici: list_bici_quartieri(1..get_num_quartieri);
      entità_auto: list_auto_quartieri(1..get_num_quartieri);

      -- array i quali oggetti sono del tipo ptr_rt_location_abitanti per ottenere le informazioni esposte sopra per gps_abitanti
      rt_classi_locate_abitanti: gps_abitanti_quartieri(1..get_num_quartieri);
   end quartiere_utilities;

   type ptr_quartiere_utilities is access all quartiere_utilities;

   function get_quartiere_utilities_obj return ptr_quartiere_utilities;

   procedure wait_settings_all_quartieri;

   type estremi_resource_strada_urbana is array(Positive range 1..2) of ptr_rt_segmento;
   type estremi_strada_urbana is array(Positive range 1..2) of estremo_urbana;

   function get_resource_estremi_urbana(id_urbana: Positive) return estremi_resource_strada_urbana;
   function get_estremi_urbana(id_urbana: Positive) return estremi_strada_urbana;

   type ptr_route_and_distance is access all route_and_distance'Class;
   type percorso_abitanti is array(Positive range <>) of ptr_route_and_distance;
   type array_position_abitanti is array(Positive range <>) of Positive;

   protected type location_abitanti(num_abitanti: Positive) is new rt_location_abitanti with

        procedure set_percorso_abitante(id_abitante: Positive; percorso: route_and_distance);
        procedure set_position_abitante_to_next(id_abitante: Positive);

      function get_next(id_abitante: Positive) return tratto;
      function get_next_road(id_abitante: Positive) return tratto;
      function get_current_position(id_abitante: Positive) return tratto;
      function get_number_steps_to_finish_route(id_abitante: Positive) return Natural;

   private
      percorsi: percorso_abitanti(get_from_abitanti..get_to_abitanti):= (others => null);
      position_abitanti: array_position_abitanti(get_from_abitanti..get_to_abitanti):= (others => 1);
   end location_abitanti;

   type ptr_location_abitanti is access location_abitanti;

   function get_locate_abitanti_quartiere return ptr_location_abitanti;

private

   protected waiting_cfg is
      procedure incrementa_classi_locate_abitanti;
      procedure incrementa_num_quartieri_abitanti;
      procedure incrementa_resource_mappa_quartieri;
      entry wait_cfg;
   private
      num_classi_locate_abitanti: Natural:= 0;
      num_abitanti_quartieri_registrati: Natural:= 0;
      num_quartieri_resource_registrate: Natural:= 0;
      inventory_estremi_is_set: Boolean:= False;
   end waiting_cfg;

   quartiere_cfg: ptr_quartiere_utilities:= new quartiere_utilities;

   urbane_features: strade_urbane_features:= create_array_urbane(json_roads => get_json_urbane, from => get_from_urbane, to => get_to_urbane);
   ingressi_features: strade_ingresso_features:= create_array_ingressi(json_roads => get_json_ingressi, from => get_from_ingressi, to => get_to_ingressi);
   incroci_a_4: list_incroci_a_4:= create_array_incroci_a_4(json_incroci => get_json_incroci_a_4, from => get_from_incroci_a_4, to => get_to_incroci_a_4);
   incroci_a_3: list_incroci_a_3:= create_array_incroci_a_3(json_incroci => get_json_incroci_a_3, from => get_from_incroci_a_3, to => get_to_incroci_a_3);
   rotonde_a_4: list_incroci_a_4:= create_array_rotonde_a_4(json_incroci => get_json_rotonde_a_4, from => get_from_rotonde_a_4, to => get_to_rotonde_a_4);
   rotonde_a_3: list_incroci_a_3:= create_array_rotonde_a_3(json_incroci => get_json_rotonde_a_3, from => get_from_rotonde_a_3, to => get_to_rotonde_a_3);

      -- classe utilizzata per settare la posizione corrente di un abitante, per settare il percorso, per ottenere il percorso
   locate_abitanti_quartiere: ptr_location_abitanti:= new location_abitanti(get_to_abitanti-get_from_abitanti+1);

   traiettorie_incroci: traiettorie_incrocio:= create_traiettorie_incrocio(json_traiettorie => get_json_traiettorie_incrocio);
   traiettorie_ingressi: traiettorie_ingresso:= create_traiettorie_ingresso(json_traiettorie => get_json_traiettorie_ingresso);

   inventory_estremi: estremi_urbane(get_from_urbane..get_to_urbane,1..2):= (others => (others => null));
   inventory_estremi_urbane: estremi_strade_urbane(get_from_urbane..get_to_urbane,1..2);

end risorse_passive_data;
