with GNATCOLL.JSON;

with risorse_mappa_utilities;
with strade_e_incroci_common;
with data_quartiere;
with remote_types;
with global_data;
with snapshot_interface;
with JSON_Helper;
with default_settings;
with numerical_types;

use GNATCOLL.JSON;
use risorse_mappa_utilities;
use strade_e_incroci_common;
use data_quartiere;
use remote_types;
use global_data;
use snapshot_interface;
use JSON_Helper;
use default_settings;
use numerical_types;

package risorse_passive_data is

   set_field_json_error: exception;
   
   function get_default_value_pedoni(value: move_settings) return new_float;
   function get_default_value_bici(value: move_settings) return new_float;
   function get_default_value_auto(value: move_settings; is_bus: Boolean) return new_float;

   function get_urbana_from_id(index: Positive) return strada_urbana_features;
   function get_ingresso_from_id(index: Positive) return strada_ingresso_features;
   function get_incrocio_a_4_from_id(index: Positive) return list_road_incrocio_a_4;
   function get_incrocio_a_3_from_id(index: Positive) return list_road_incrocio_a_3;
   function get_rotonda_a_4_from_id(index: Positive) return list_road_incrocio_a_4;
   function get_rotonda_a_3_from_id(index: Positive) return list_road_incrocio_a_3;

   function get_road_from_incrocio(index_incrocio: Positive; key_road: Positive) return road_incrocio_features;
   function get_index_road_from_incrocio(id_quartiere_road: Positive; id_road: Positive; id_incrocio: Positive) return Natural;
   function get_size_incrocio(id_incrocio: Positive) return Positive;

   function get_traiettoria_incrocio(traiettoria: traiettoria_incroci_type) return traiettoria_incrocio;

   function get_urbane return strade_urbane_features;
   function get_ingressi return strade_ingresso_features;
   function get_incroci_a_4 return list_incroci_a_4;
   function get_incroci_a_3 return list_incroci_a_3;
   function get_rotonde_a_4 return list_incroci_a_4;
   function get_rotonde_a_3 return list_incroci_a_3;

   function get_distance_from_polo_percorrenza(road: strada_ingresso_features; polo: Boolean) return new_float;

   function get_traiettoria_ingresso(type_traiettoria: traiettoria_ingressi_type) return traiettoria_ingresso;

   function get_traiettoria_cambio_corsia return traiettoria_cambio_corsia;

   protected type quartiere_utilities(num_quartieri: Positive) is new rt_quartiere_utilities with
      procedure registra_classe_locate_abitanti_quartiere(id_quartiere: Positive; location_abitanti: ptr_rt_location_abitanti);
      procedure registra_abitanti(from_id_quartiere: Positive; abitanti: list_abitanti_quartiere; pedoni: list_pedoni_quartiere;
                                  bici: list_bici_quartiere; auto: list_auto_quartiere);
      procedure registra_mappa(id_quartiere: Positive);
      procedure get_cfg_incrocio(id_incrocio: Positive; from_road: tratto; to_road: tratto; key_road_from: out Natural; key_road_to: out Natural; id_road_mancante: out Natural);

      function get_type_entity(id_entit�: Positive) return entity_type;
      function get_id_main_road_from_id_ingresso(id_ingresso: Positive) return Natural;
      function get_polo_ingresso(id_ingresso: Positive) return Boolean;

      function get_abitante_quartiere(id_quartiere: Positive; id_abitante: Positive) return abitante;
      function get_pedone_quartiere(id_quartiere: Positive; id_abitante: Positive) return pedone;
      function get_bici_quartiere(id_quartiere: Positive; id_abitante: Positive) return bici;
      function get_auto_quartiere(id_quartiere: Positive; id_abitante: Positive) return auto;
      function get_classe_locate_abitanti(id_quartiere: Positive) return ptr_rt_location_abitanti;
  
      function get_index_luogo_from_id_json(json_key: Positive) return Positive;
      function get_from_type_resource_quartiere(resource: resource_type) return Natural;
      function get_to_type_resource_quartiere(resource: resource_type) return Natural;      
      function is_incrocio(id_risorsa: Positive) return Boolean;
      function get_id_fermata_id_urbana(id_urbana: Positive) return Natural;

   private

      entit�_abitanti: list_abitanti_quartieri(1..num_quartieri);
      entit�_pedoni: list_pedoni_quartieri(1..num_quartieri);
      entit�_bici: list_bici_quartieri(1..num_quartieri);
      entit�_auto: list_auto_quartieri(1..num_quartieri);

      -- array i quali oggetti sono del tipo ptr_rt_location_abitanti per ottenere le informazioni esposte sopra per gps_abitanti
      rt_classi_locate_abitanti: gps_abitanti_quartieri(1..num_quartieri);
   end quartiere_utilities;

   type ptr_quartiere_utilities is access all quartiere_utilities;

   function get_quartiere_utilities_obj return ptr_quartiere_utilities;

   procedure wait_settings_all_quartieri;

   type estremi_resource_strada_urbana is array(Positive range 1..2) of ptr_rt_incrocio;
   type estremi_strada_urbana is array(Positive range 1..2) of estremo_urbana;

   function get_resource_estremi_urbana(id_urbana: Positive) return estremi_resource_strada_urbana;
   function get_estremi_urbana(id_urbana: Positive) return estremi_strada_urbana;

   type ptr_route_and_distance is access all route_and_distance'Class;
   type percorso_abitanti is array(Positive range <>) of ptr_route_and_distance;
   type array_position_abitanti is array(Positive range <>) of Positive;
   type array_abitanti_finish_route is array(Positive range <>) of Boolean;

   --function create_route_and_distance_from_json(json_percorso_abitante: JSON_Value; length: Natural) return ptr_route_and_distance;

   protected type location_abitanti(num_abitanti: Natural) is new rt_location_abitanti and backup_interface with

      procedure create_img(json_1: out JSON_Value);
      procedure recovery_resource;

      procedure set_percorso_abitante(id_abitante: Positive; percorso: route_and_distance);
      procedure set_position_abitante_to_next(id_abitante: Positive);
      procedure set_finish_route(id_abitante: Positive);

      function get_next(id_abitante: Positive) return tratto;
      -- next_road pu� essere a distanza 2 o distanza 3 dalla posizione della macchina
      -- a seconda che la richiesta avvenga rispettivamente
      -- da un ingresso o da un'incrocio
      function get_next_road(id_abitante: Positive; from_ingresso: Boolean) return tratto;
      function get_next_incrocio(id_abitante: Positive) return tratto;
      function get_current_tratto(id_abitante: Positive) return tratto;
      function get_current_position(id_abitante: Positive) return Positive;
      function get_number_steps_to_finish_route(id_abitante: Positive) return Natural;
      
      function get_destination_abitante_in_bus(id_abitante: Positive) return tratto;
      procedure set_destination_abitante_in_bus(id_abitante: Positive; destination: tratto);
      --function get_ingresso_destination(id_abitante: Positive) return tratto;

   private
      percorsi: percorso_abitanti(get_from_abitanti..get_to_abitanti):= (others => null);
      position_abitanti: array_position_abitanti(get_from_abitanti..get_to_abitanti):= (others => 1);
      abitanti_arrived: array_abitanti_finish_route(get_from_abitanti..get_to_abitanti):= (others => False);
      destination_abitanti_on_bus: set_tratti(get_from_abitanti..get_to_abitanti);
   end location_abitanti;

   type ptr_location_abitanti is access location_abitanti;

   function get_locate_abitanti_quartiere return ptr_location_abitanti;

   function get_larghezza_marciapiede return new_float;
   function get_larghezza_corsia return new_float;

   procedure configure_quartiere_obj;
   
   procedure configure_map_fermate_urbane;
   
   -- ATTENZIONE!!!!!11 LA SEGUENTE PROCEDURA PU� ESSERE CHIAMATA SOLO
   -- DOPO ESSERSI ACCERTATI CHE TUTTI I QUARTIERI SI SONO CONFIGURATI
   -- NECESSARIA CHIAMARLA DOPO ESSERSI MESSI IN ATTESA SU waiting_cfg.wait_cfg
   procedure configure_linee_fermate;
   
   type location_autobus is tagged private;
   type stato_avanzamento_autobus is array(Positive range <>) of location_autobus;
   type lista_passeggeri is tagged private;
   type ptr_lista_passeggeri is access lista_passeggeri;
   
   function create_lista_passeggeri(identificativo_ab: tratto; next: ptr_lista_passeggeri) return lista_passeggeri;   
   function get_identificativo_abitante(obj: lista_passeggeri) return tratto;
   function get_next(obj: lista_passeggeri) return ptr_lista_passeggeri;
   procedure set_identificativo_abitante(obj: in out lista_passeggeri; identificativo_ab: tratto);
   procedure set_next(obj: in out lista_passeggeri; next: ptr_lista_passeggeri);
     
   type passeggeri_in_bus is array(Positive range <>) of ptr_lista_passeggeri;
     
   protected type gestore_bus_quartiere(num_quartieri: Positive; num_autobus: Natural) is new rt_gestore_bus_quartiere with
      -- configure_gestori_remoti pu� essere chiamata solo dopo l'avvenuto check-point
      -- in configure di resource_map_inventory
        procedure configure_ref_gestori_bus_remoti;
      
      procedure autobus_arrived_at_fermata(to_id_autobus: Positive; abitanti: set_tratti; from_fermata: tratto);
      procedure avanza_fermata(id_autobus: Positive);
      procedure revert_percorso(id_autobus: Positive);
      function linea_is_reverted(id_autobus: Positive) return Boolean;
      function fermata_da_fare(id_autobus: Positive; fermata: tratto) return Boolean;
      function get_num_fermate_rimaste(id_autobus: Positive) return Natural; 
      function get_num_fermata_arrived(id_autobus: Positive) return Positive;
      
      function get_gestore_bus_quartiere(id_quartiere: Positive) return ptr_rt_gestore_bus_quartiere;
      
   private
      registro_gestori_autobus_quartieri: registro_gestori_bus_quartieri(1..num_quartieri);
      stato_bus: stato_avanzamento_autobus(get_to_abitanti-get_num_autobus+1..get_to_abitanti);
      passeggeri_bus: passeggeri_in_bus(get_to_abitanti-get_num_autobus+1..get_to_abitanti);
   end gestore_bus_quartiere;
   
   type ptr_gestore_bus_quartiere is access all gestore_bus_quartiere'Class;
   
   function get_gestore_bus_quartiere_obj return ptr_gestore_bus_quartiere;

   protected type type_waiting_cfg(numero_quartieri: Positive) is
      procedure incrementa_classi_locate_abitanti;
      procedure incrementa_num_quartieri_abitanti;
      procedure incrementa_resource_mappa_quartieri;
      entry wait_cfg;
   private
      num_classi_locate_abitanti: Natural:= 0;
      num_abitanti_quartieri_registrati: Natural:= 0;
      num_quartieri_resource_registrate: Natural:= 0;
      inventory_estremi_is_set: Boolean:= False;
   end type_waiting_cfg;

   type ptr_type_waiting_cfg is access type_waiting_cfg;
   
   type quartiere_entities_life is new rt_quartiere_entities_life with null record;
   type ptr_quartiere_entities_life is access all quartiere_entities_life;

   procedure abitante_is_arrived(obj: quartiere_entities_life; id_abitante: Positive);
   procedure abitante_scende_dal_bus(obj: quartiere_entities_life; id_abitante: Positive; alla_fermata: tratto);
   
   function get_quartiere_entities_life_obj return ptr_quartiere_entities_life;

   function is_abitante_in_bus(id_abitante: Positive) return Boolean;
   
   function get_linea(num_linea: Positive) return linea_bus;
   
   function get_id_fermata_from_id_urbana(id_urbana: Positive) return Natural;
   
   function get_location_abitanti_quartiere return ptr_location_abitanti;

private

   type location_autobus is tagged record
      index_fermata: Natural:= 0;
      revert_percorso: Boolean:= False;
   end record;
   
   type lista_passeggeri is tagged record
      identificativo_abitante: tratto;
      next: ptr_lista_passeggeri:= null;
   end record;
   
   waiting_cfg: ptr_type_waiting_cfg:= null;  

   quartiere_cfg: ptr_quartiere_utilities:= null;
   
   gestore_bus_quartiere_obj: ptr_gestore_bus_quartiere:= null;
   
   quartiere_entities_life_obj: ptr_quartiere_entities_life:= null;

   urbane_features: strade_urbane_features:= create_array_urbane(json_roads => get_json_urbane, from => get_from_urbane, to => get_to_urbane);
   ingressi_features: strade_ingresso_features:= create_array_ingressi(json_roads => get_json_ingressi, from => get_from_ingressi, to => get_to_ingressi);
   incroci_a_4: list_incroci_a_4:= create_array_incroci_a_4(json_incroci => get_json_incroci_a_4, from => get_from_incroci_a_4, to => get_to_incroci_a_4);
   incroci_a_3: list_incroci_a_3:= create_array_incroci_a_3(json_incroci => get_json_incroci_a_3, from => get_from_incroci_a_3, to => get_to_incroci_a_3);
   rotonde_a_4: list_incroci_a_4:= create_array_rotonde_a_4(json_incroci => get_json_rotonde_a_4, from => get_from_rotonde_a_4, to => get_to_rotonde_a_4);
   rotonde_a_3: list_incroci_a_3:= create_array_rotonde_a_3(json_incroci => get_json_rotonde_a_3, from => get_from_rotonde_a_3, to => get_to_rotonde_a_3);

   linee_autobus: linee_bus(1..get_num_linee_fermate);
   abitanti_in_bus: set:= create_array_abitanti_in_bus;
   
   fermate_associate_a_urbane: set(1..Length(get_json_urbane)):= (others => 0);
      -- classe utilizzata per settare la posizione corrente di un abitante, per settare il percorso, per ottenere il percorso
   locate_abitanti_quartiere: ptr_location_abitanti:= null;

   traiettorie_incroci: traiettorie_incrocio:= create_traiettorie_incrocio(json_traiettorie => get_json_traiettorie_incrocio);
   traiettorie_ingressi: traiettorie_ingresso:= create_traiettorie_ingresso(json_traiettorie => get_json_traiettorie_ingresso);
   traiettorie_cambio_corsia: traiettoria_cambio_corsia:= create_traiettoria_cambio_corsia(json_traiettorie => get_json_traiettorie_cambio_corsie);

   inventory_estremi: estremi_urbane(get_from_urbane..get_to_urbane,1..2):= (others => (others => null));
   inventory_estremi_urbane: estremi_strade_urbane(get_from_urbane..get_to_urbane,1..2);

   larghezza_marciapiede: new_float:= get_default_larghezza_marciapiede;
   larghezza_corsia: new_float:= get_default_larghezza_corsia;

   -- BEGIN VALORI DI DEFAULT PER RISORSE PASSIVE
   default_desired_velocity_pedoni: new_float:= get_default_desired_velocity_pedoni;
   default_time_headway_pedoni: new_float:= get_default_desired_velocity_pedoni;
   default_max_acceleration_pedoni: new_float:= get_default_max_acceleration_pedoni;
   default_comfortable_deceleration_pedoni: new_float:= get_default_comfortable_deceleration_pedoni;
   default_s0_pedoni: new_float:= get_default_s0_pedoni;
   default_length_pedoni: new_float:= get_default_length_pedoni;

   default_desired_velocity_bici: new_float:= get_default_desired_velocity_bici;
   default_time_headway_bici: new_float:= get_default_time_headway_bici;
   default_max_acceleration_bici: new_float:= get_default_max_acceleration_bici;
   default_comfortable_deceleration_bici: new_float:= get_default_comfortable_deceleration_bici;
   default_s0_bici: new_float:= get_default_s0_bici;
   default_length_bici: new_float:= get_default_length_bici;

   --default_desired_velocity_auto: new_float:= get_default_desired_velocity_auto;
   --default_time_headway_auto: new_float:= get_default_time_headway_auto;
   --default_max_acceleration_auto: new_float:= get_default_max_acceleration_auto;
   --default_comfortable_deceleration_auto: new_float:= get_default_comfortable_deceleration_auto;
   --default_s0_auto: new_float:= get_default_s0_auto;
   --default_length_auto: new_float:= get_default_length_auto;
   --default_num_posti_auto: Positive:= get_default_num_posti_auto;

end risorse_passive_data;
