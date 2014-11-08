with strade_e_incroci_common;

use strade_e_incroci_common;

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
   type gps_abitanti_quartieri is array(Positive range <>) of ptr_rt_location_abitanti;

   type rt_quartiere_utilities is synchronized interface;
   type ptr_rt_quartiere_utilitites is access all rt_quartiere_utilities'Class;
   procedure registra_classe_locate_abitanti_quartiere(obj: access rt_quartiere_utilities; id_quartiere: Positive; location_abitanti: ptr_rt_location_abitanti) is abstract;
   procedure registra_abitanti(obj: access rt_quartiere_utilities; from_id_quartiere: Positive; abitanti: list_abitanti_quartiere; pedoni: list_pedoni_quartiere;
                               bici: list_bici_quartiere; auto: list_auto_quartiere) is abstract;
   procedure registra_mappa(obj: access rt_quartiere_utilities; id_quartiere: Positive) is abstract;
   procedure get_cfg_incrocio(obj: access rt_quartiere_utilities; id_incrocio: Positive; from_road: tratto; to_road: tratto; key_road_from: out Natural; key_road_to: out Natural; id_road_mancante: out Natural) is abstract;
   function get_polo_ingresso(obj: access rt_quartiere_utilities; id_ingresso: Positive) return Boolean is abstract;
   function get_type_entity(obj: access rt_quartiere_utilities; id_entità: Positive) return entity_type is abstract;
   function get_id_main_road_from_id_ingresso(obj: access rt_quartiere_utilities; id_ingresso: Positive) return Natural is abstract;
   function get_index_luogo_from_id_json(obj: access rt_quartiere_utilities; json_key: Positive) return Positive is abstract;
   function get_from_ingressi_quartiere(obj: access rt_quartiere_utilities) return Natural is abstract;
   type registro_quartieri is array(Positive range <>) of ptr_rt_quartiere_utilitites;

   type rt_handler_semafori_quartiere is abstract tagged limited private;
   type ptr_rt_handler_semafori_quartiere is access all rt_handler_semafori_quartiere'Class;
   type handler_semafori is array(Positive range <>) of ptr_rt_handler_semafori_quartiere;
   procedure change_semafori(obj: rt_handler_semafori_quartiere) is abstract;

      -- begin resource segmenti
   type rt_segmento is synchronized interface;
   type ptr_rt_segmento is access all rt_segmento'Class;

   --procedure wait_turno(obj: access rt_segmento) is abstract;
   --procedure delta_terminate(obj: access rt_segmento) is abstract;

   type rt_incrocio is synchronized interface and rt_segmento;
   type ptr_rt_incrocio is access all rt_incrocio'Class;

   type rt_urbana is synchronized interface and rt_segmento;
   type ptr_rt_urbana is access all rt_urbana'Class;

   type rt_ingresso is synchronized interface and rt_segmento;
   type ptr_rt_ingresso is access all rt_ingresso'Class;

   procedure insert_abitante_from_incrocio(obj: access rt_urbana; abitante: posizione_abitanti_on_road; polo: Boolean; num_corsia: id_corsie) is abstract;
   procedure remove_abitante_in_incrocio(obj: access rt_urbana; polo: Boolean; num_corsia: id_corsie) is abstract;
   procedure delta_incrocio_finished(obj: access rt_urbana) is abstract;
   function get_distanza_percorsa_first_abitante(obj: access rt_urbana; polo: Boolean; num_corsia: id_corsie) return Float is abstract;

   procedure insert_new_car(obj: access rt_incrocio; from_id_quartiere: Positive; from_id_road: Positive; car: posizione_abitanti_on_road) is abstract;
   --procedure change_verso_semafori_verdi(obj: access rt_incrocio) is abstract;
   function get_posix_first_entity(obj: access rt_incrocio; from_id_quartiere_road: Positive; from_id_road: Positive; num_corsia: id_corsie) return Float is abstract;

   procedure new_abitante_to_move(obj: access rt_ingresso; id_quartiere: Positive; id_abitante: Positive; mezzo: means_of_carrying) is abstract;

   type set_resources_ingressi is array(Positive range <>) of ptr_rt_ingresso;
   type set_resources_urbane is array(Positive range <>) of ptr_rt_urbana;
   type set_resources_incroci is array(Positive range <>) of ptr_rt_incrocio;
   type estremi_urbane is array(Positive range <>,Positive range <>) of ptr_rt_incrocio;

   type rt_wait_all_quartieri is synchronized interface;
   type ptr_rt_wait_all_quartieri is access all rt_wait_all_quartieri'Class;
   --pragma Asynchronous(ptr_rt_wait_all_quartieri);
   procedure all_quartieri_set(obj: access rt_wait_all_quartieri) is abstract;

   type rt_task_synchronization is synchronized interface;
   type ptr_rt_task_synchronization is access all rt_task_synchronization'Class;
   procedure all_task_partition_are_ready(obj: access rt_task_synchronization; id: Positive) is abstract;
   --procedure wait_awake_all_partitions(obj: access rt_task_synchronization) is abstract;
   --procedure last_task_partition_ready(obj: access rt_task_synchronization) is abstract;

   type rt_synchronization_tasks is synchronized interface;
   type ptr_rt_synchronization_tasks is access all rt_synchronization_tasks'Class;
   pragma Asynchronous(ptr_rt_synchronization_tasks);
   procedure wake(obj: access rt_synchronization_tasks) is abstract;
   type registro_local_synchronized_obj is array(Positive range <>) of ptr_rt_synchronization_tasks;

   -- begin gps
   type gps_interface is synchronized interface;
   type ptr_gps_interface is access all gps_interface'Class;
   function get_estremi_strade_urbane(obj: access gps_interface; id_quartiere: Positive) return estremi_strade_urbane is abstract;
   procedure registra_strade_quartiere(obj: access gps_interface; id_quartiere: Positive; urbane: strade_urbane_features;
                                       ingressi: strade_ingresso_features) is abstract;
   procedure registra_incroci_quartiere(obj: access gps_interface; id_quartiere: Positive; incroci_a_4: list_incroci_a_4;
                                        incroci_a_3: list_incroci_a_3; rotonde_a_4: list_incroci_a_4;
                                        rotonde_a_3: list_incroci_a_3) is abstract;
   function calcola_percorso(obj: access gps_interface; from_id_quartiere: Positive; from_id_luogo: Positive;
                             to_id_quartiere: Positive; to_id_luogo: Positive) return route_and_distance is abstract;
   --function get_estremi_urbana(obj: access gps_interface; id_quartiere: Positive; id_urbana: Positive) return estremi_urbana is abstract;
   -- end gps

   type rt_quartiere_entities_life is abstract tagged limited private;
   type ptr_rt_quartiere_entities_life is access all rt_quartiere_entities_life'Class;
   --pragma Asynchronous(ptr_rt_quartiere_entities_life);
   procedure abitante_is_arrived(obj: rt_quartiere_entities_life; id_abitante: Positive) is abstract;
   -- to set an asynchronus procedure you must have all IN parameter
   -- to set a synchronus procedure you must have IN-OUT parameters


   --BEGIN REMOTE TYPES WEB SERVER
   type WebServer_Remote_Interface is limited interface;
   type Access_WebServer_Remote_Interface is access all WebServer_Remote_Interface'Class;

   procedure registra_mappa_quartiere(This: access WebServer_Remote_Interface; data: String; quartiere : Natural) is abstract;
   procedure invia_aggiornamento(This: access WebServer_Remote_Interface; data: String; quartiere : Natural) is abstract;
   pragma Asynchronous(Access_WebServer_Remote_Interface);
   --END REMOTE TYPES WEB SERVER

private

   type rt_handler_semafori_quartiere is abstract tagged limited null record;
   type rt_quartiere_entities_life is abstract tagged limited null record;

end remote_types;
