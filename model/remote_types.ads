with strade_e_incroci_common;
with numerical_types;

use strade_e_incroci_common;
use numerical_types;

package remote_types is
   pragma Remote_Types;

   -- tipi usati per ottenere informazioni sul percorso che un certo abitante deve intraprendere
   type rt_location_abitanti is synchronized interface;
   type ptr_rt_location_abitanti is access all rt_location_abitanti'Class;
   procedure set_percorso_abitante(obj: access rt_location_abitanti; id_abitante: Positive; percorso: route_and_distance) is abstract;
   procedure set_position_abitante_to_next(obj: access rt_location_abitanti; id_abitante: Positive) is abstract;
   procedure set_finish_route(obj: access rt_location_abitanti; id_abitante: Positive) is abstract;
   function get_next(obj: access rt_location_abitanti; id_abitante: Positive) return tratto is abstract;
   function get_next_incrocio(obj: access rt_location_abitanti; id_abitante: Positive) return tratto is abstract;
   function get_next_road(obj: access rt_location_abitanti; id_abitante: Positive; from_ingresso: Boolean) return tratto is abstract;
   function get_current_tratto(obj: access rt_location_abitanti; id_abitante: Positive) return tratto is abstract;
   function get_number_steps_to_finish_route(obj: access rt_location_abitanti; id_abitante: Positive) return Natural is abstract;
   function get_current_position(obj: access rt_location_abitanti; id_abitante: Positive) return Positive is abstract;
   function get_destination_abitante_in_bus(obj: access rt_location_abitanti; id_abitante: Positive) return tratto is abstract;
   procedure set_destination_abitante_in_bus(obj: access rt_location_abitanti; id_abitante: Positive; destination: tratto) is abstract;
   type gps_abitanti_quartieri is array(Positive range <>) of ptr_rt_location_abitanti;

   type rt_quartiere_utilities is synchronized interface;
   type ptr_rt_quartiere_utilitites is access all rt_quartiere_utilities'Class;
   type registro_quartieri is array(Positive range <>) of ptr_rt_quartiere_utilitites;

   --procedure registra_classe_locate_abitanti_quartiere(obj: access rt_quartiere_utilities; id_quartiere: Positive; location_abitanti: ptr_rt_location_abitanti) is abstract;
   --procedure registra_abitanti(obj: access rt_quartiere_utilities; from_id_quartiere: Positive; abitanti: list_abitanti_quartiere; pedoni: list_pedoni_quartiere;
   --                            bici: list_bici_quartiere; auto: list_auto_quartiere) is abstract;
   --procedure registra_mappa(obj: access rt_quartiere_utilities; id_quartiere: Positive) is abstract;
   procedure get_cfg_incrocio(obj: access rt_quartiere_utilities; id_incrocio: Positive; from_road: tratto; to_road: tratto; key_road_from: out Natural; key_road_to: out Natural; id_road_mancante: out Natural) is abstract;
   function get_polo_ingresso(obj: access rt_quartiere_utilities; id_ingresso: Positive) return Boolean is abstract;
   function get_type_entity(obj: access rt_quartiere_utilities; id_entità: Positive) return entity_type is abstract;
   function get_id_main_road_from_id_ingresso(obj: access rt_quartiere_utilities; id_ingresso: Positive) return Natural is abstract;
   function get_index_luogo_from_id_json(obj: access rt_quartiere_utilities; json_key: Positive) return Positive is abstract;
   --function get_from_ingressi_quartiere(obj: access rt_quartiere_utilities) return Natural is abstract;
   function is_incrocio(obj: access rt_quartiere_utilities; id_risorsa: Positive) return Boolean is abstract;
   function get_from_type_resource_quartiere(obj: access rt_quartiere_utilities; resource: resource_type) return Natural is abstract;
   function get_to_type_resource_quartiere(obj: access rt_quartiere_utilities; resource: resource_type) return Natural is abstract;
   function get_id_fermata_id_urbana(obj: access rt_quartiere_utilities; id_urbana: Positive) return Natural is abstract;
   function get_all_abitanti_quartiere(obj: access rt_quartiere_utilities) return list_abitanti_quartiere is abstract;
   function get_all_pedoni_quartiere(obj: access rt_quartiere_utilities) return list_pedoni_quartiere is abstract;
   function get_all_bici_quartiere(obj: access rt_quartiere_utilities) return list_bici_quartiere is abstract;
   function get_all_auto_quartiere(obj: access rt_quartiere_utilities) return list_auto_quartiere is abstract;
   function get_locate_abitanti_quartiere(obj: access rt_quartiere_utilities; id_quartiere: Positive) return ptr_rt_location_abitanti is abstract;
   function get_saved_partitions(obj: access rt_quartiere_utilities) return registro_quartieri is abstract;
   function is_a_new_quartiere(obj: access rt_quartiere_utilities; id_quartiere: Positive) return Boolean is abstract;
   procedure close_system(obj: access rt_quartiere_utilities) is abstract;
   procedure all_can_be_closed(obj: access rt_quartiere_utilities) is abstract;

   type rt_gestore_bus_quartiere is synchronized interface;
   type ptr_rt_gestore_bus_quartiere is access all rt_gestore_bus_quartiere'Class;
   procedure autobus_arrived_at_fermata(obj: access rt_gestore_bus_quartiere; to_id_autobus: Positive; abitanti: set_tratti; from_fermata: tratto) is abstract;
   function get_num_fermate_rimaste(obj: access rt_gestore_bus_quartiere; id_autobus: Positive) return Natural is abstract;
   function get_num_fermata_arrived(id_autobus: Positive) return Positive is abstract;

   type registro_gestori_bus_quartieri is array(Positive range <>) of ptr_rt_gestore_bus_quartiere;

      -- begin resource segmenti
   type rt_segmento is synchronized interface;
   type ptr_rt_segmento is access all rt_segmento'Class;

   function get_id_risorsa(obj: access rt_segmento) return Positive is abstract;
   function get_id_quartiere_risorsa(obj: access rt_segmento) return Positive is abstract;

   type rt_incrocio is synchronized interface and rt_segmento;
   type ptr_rt_incrocio is access all rt_incrocio'Class;

   type rt_urbana is synchronized interface and rt_segmento;
   type ptr_rt_urbana is access all rt_urbana'Class;

   type rt_ingresso is synchronized interface and rt_segmento;
   type ptr_rt_ingresso is access all rt_ingresso'Class;

   procedure insert_abitante_from_incrocio(obj: access rt_urbana; mezzo: means_of_carrying; abitante: posizione_abitanti_on_road; polo: Boolean; num_corsia: id_corsie) is abstract;
   procedure remove_abitante_in_incrocio(obj: access rt_urbana; polo: Boolean; num_corsia: id_corsie; id_quartiere: Positive; id_abitante: Positive) is abstract;
   procedure delta_incrocio_finished(obj: access rt_urbana) is abstract;
   function get_distanza_percorsa_first_abitante(obj: access rt_urbana; polo: Boolean; num_corsia: id_corsie) return new_float is abstract;
   function get_distanza_percorsa_first_bipede(obj: access rt_urbana; polo: Boolean; mezzo: means_of_carrying) return new_float is abstract;
   function first_car_abitante_has_passed_incrocio(obj: access rt_urbana; polo: Boolean; num_corsia: id_corsie) return Boolean is abstract;
   function get_abilitazione_cambio_traiettoria_bipede(obj: access rt_urbana; mezzo: means_of_carrying) return Boolean is abstract;

   procedure insert_new_car(obj: access rt_incrocio; from_id_quartiere: Positive; from_id_road: Positive; car: posizione_abitanti_on_road) is abstract;
   procedure insert_new_bipede(obj: access rt_incrocio; from_id_quartiere: Positive; from_id_road: Positive; bipede: posizione_abitanti_on_road; mezzo: means_of_carrying; traiettoria: traiettoria_incroci_type) is abstract;
   --procedure change_verso_semafori_verdi(obj: access rt_incrocio) is abstract;
   function get_posix_first_entity(obj: access rt_incrocio; from_id_quartiere_road: Positive; from_id_road: Positive; num_corsia: id_corsie) return new_float is abstract;
   function get_posix_first_bipede(obj: access rt_incrocio; from_id_quartiere_road: Positive; from_id_road: Positive; mezzo: means_of_carrying; traiettoria: traiettoria_incroci_type) return new_float is abstract;
   function semaforo_is_verde_from_road(obj: access rt_incrocio; id_quartiere_road: Positive; id_road: Positive) return Boolean is abstract;
   procedure calcola_bound_avanzamento_in_incrocio(obj: access rt_incrocio; index_road: in out Natural; indice: Natural; traiettoria_car: traiettoria_incroci_type; corsia: id_corsie; num_car: Natural; bound_distance: in out new_float; stop_entity: in out Boolean; distance_to_next_car: in out new_float; from_id_quartiere_road: Natural:= 0; from_id_road: Natural:= 0) is abstract;

   procedure new_abitante_to_move(obj: access rt_ingresso; id_quartiere: Positive; id_abitante: Positive; mezzo: means_of_carrying) is abstract;
   procedure add_abitante_in_fermata(obj: access rt_ingresso; identificativo_abitante: tratto) is abstract;
   procedure aggiorna_abitanti_in_fermata(obj: access rt_ingresso; abitanti_saliti_in_bus: set_tratti) is abstract;

   type set_resources_ingressi is array(Positive range <>) of ptr_rt_ingresso;
   type set_resources_urbane is array(Positive range <>) of ptr_rt_urbana;
   type set_resources_incroci is array(Positive range <>) of ptr_rt_incrocio;
   type estremi_urbane is array(Positive range <>,Positive range <>) of ptr_rt_incrocio;

   --type rt_wait_all_quartieri is synchronized interface;
   --type ptr_rt_wait_all_quartieri is access all rt_wait_all_quartieri'Class;
   --pragma Asynchronous(ptr_rt_wait_all_quartieri);
   --procedure all_quartieri_set(obj: access rt_wait_all_quartieri) is abstract;

   type rt_synchronization_partitions_type is synchronized interface;
   type ptr_rt_synchronization_partitions_type is access all rt_synchronization_partitions_type'Class;
   procedure partition_is_ready(obj: access rt_synchronization_partitions_type; id: Positive; registro_q_remoto: registro_quartieri) is abstract;
   procedure wait_synch_quartiere(obj: access rt_synchronization_partitions_type; from_quartiere: Positive) is abstract;
   procedure clean_new_partition(obj: access rt_synchronization_partitions_type; clean_registry: registro_quartieri) is abstract;
   --procedure partition_is_synchronized(obj: access rt_synchronization_partitions_type; send_by_id_quartiere: Positive; synch: Boolean) is abstract;


   -- begin gps
   type gps_interface is synchronized interface;
   type ptr_gps_interface is access all gps_interface'Class;
   function get_estremi_strade_urbane(obj: access gps_interface; id_quartiere: Positive) return estremi_strade_urbane is abstract;
   function is_alive(obj: access gps_interface) return Boolean is abstract;
   procedure close_gps(obj: access gps_interface) is abstract;
   procedure registra_mappa_quartiere(obj: access gps_interface; id_quartiere: Positive; urbane: strade_urbane_features;
                                           ingressi: strade_ingresso_features; incroci_a_4: list_incroci_a_4;
                                            incroci_a_3: list_incroci_a_3) is abstract;
   function calcola_percorso(obj: access gps_interface; from_id_quartiere: Positive; from_id_luogo: Positive;
                             to_id_quartiere: Positive; to_id_luogo: Positive; id_quartiere: Positive; id_abitante: Positive) return route_and_distance is abstract;
   -- end gps

   type rt_quartiere_entities_life is abstract tagged limited private;
   type ptr_rt_quartiere_entities_life is access all rt_quartiere_entities_life'Class;
   pragma Asynchronous(ptr_rt_quartiere_entities_life);
   procedure abitante_is_arrived(obj: rt_quartiere_entities_life; id_abitante: Positive) is abstract;
   procedure abitante_scende_dal_bus(obj: rt_quartiere_entities_life; id_abitante: Positive; alla_fermata: tratto) is abstract;
   -- to set an asynchronus procedure you must have all IN parameter
   -- to set a synchronus procedure you must have IN-OUT parameters


   --BEGIN REMOTE TYPES WEB SERVER
   type WebServer_Remote_Interface is limited interface;
   type Access_WebServer_Remote_Interface is access all WebServer_Remote_Interface'Class;

   procedure registra_mappa_quartiere(This: access WebServer_Remote_Interface; data: String; quartiere : Natural) is abstract;
   function is_alive(This: access WebServer_Remote_Interface) return Boolean is abstract;
   procedure close_webserver(This: access WebServer_Remote_Interface) is abstract;
   pragma Asynchronous(Access_WebServer_Remote_Interface);
   procedure invia_aggiornamento(This: access WebServer_Remote_Interface; data: String; quartiere : Natural) is abstract;

   --END REMOTE TYPES WEB SERVER


   type rt_report_log is synchronized interface;
   type ptr_rt_report_log is access all rt_report_log'Class;
   procedure finish(id_quartiere: Positive) is abstract;
   pragma Asynchronous(ptr_rt_report_log);
   procedure write_state_stallo(obj: access rt_report_log; id_quartiere: Positive; id_abitante: Positive; reset: Boolean) is abstract;

private

   type rt_handler_semafori_quartiere is abstract tagged limited null record;
   type rt_quartiere_entities_life is abstract tagged limited null record;

end remote_types;
