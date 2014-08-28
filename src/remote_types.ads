with strade_e_incroci_common;

use strade_e_incroci_common;

package remote_types is
   pragma Remote_Types;

   -- tipi usati per ottenere informazioni sul percorso che un certo abitante deve intraprendere
   type rt_location_abitanti is synchronized interface;
   type ptr_rt_location_abitanti is access all rt_location_abitanti'Class;
   type gps_abitanti_quartieri is array(Positive range <>) of ptr_rt_location_abitanti;

   type rt_quartiere_utilities is synchronized interface;
   type ptr_rt_quartiere_utilitites is access all rt_quartiere_utilities'Class;
   procedure registra_classe_locate_abitanti_quartiere(obj: access rt_quartiere_utilities; id_quartiere: Positive; location_abitanti: ptr_rt_location_abitanti) is abstract;
   procedure registra_abitanti(obj: access rt_quartiere_utilities; from_id_quartiere: Positive; abitanti: list_abitanti_quartiere; pedoni: list_pedoni_quartiere;
                               bici: list_bici_quartiere; auto: list_auto_quartiere) is abstract;
   procedure registra_mappa(obj: access rt_quartiere_utilities; id_quartiere: Positive) is abstract;
   type registro_quartieri is array(Positive range <>) of ptr_rt_quartiere_utilitites;

   type rt_handler_semafori_quartiere is abstract tagged limited private;
   type ptr_rt_handler_semafori_quartiere is access all rt_handler_semafori_quartiere'Class;
   type handler_semafori is array(Positive range <>) of ptr_rt_handler_semafori_quartiere;
   procedure change_semafori(obj: rt_handler_semafori_quartiere) is abstract;

   -- begin resource segmenti
   type rt_segmento is synchronized interface;
   type ptr_rt_segmento is access all rt_segmento'Class;
   procedure wait_turno(obj: access rt_segmento) is abstract;
   procedure delta_terminate(obj: access rt_segmento) is abstract;
   function there_are_autos_to_move(obj: access rt_segmento) return Boolean is abstract;
   function there_are_pedoni_or_bici_to_move(obj: access rt_segmento) return Boolean is abstract;
   type set_resources is array(Positive range <>) of ptr_rt_segmento;
   type estremi_urbane is array(Positive range <>,Positive range <>) of ptr_rt_segmento;

   type rt_wait_all_quartieri is synchronized interface;
   type ptr_rt_wait_all_quartieri is access all rt_wait_all_quartieri'Class;
   procedure all_quartieri_set(obj: access rt_wait_all_quartieri) is abstract;

   type rt_task_synchronization is synchronized interface;
   type ptr_rt_task_synchronization is access all rt_task_synchronization'Class;
   procedure all_task_partition_are_ready(obj: access rt_task_synchronization) is abstract;

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

   type rt_quartiere_entities_life is synchronized interface;
   type ptr_rt_quartiere_entities_life is access all rt_quartiere_entities_life'Class;
   pragma Asynchronous(ptr_rt_quartiere_entities_life);
   procedure abitante_is_arrived(obj: ptr_rt_quartiere_entities_life; id_quartiere: Positive; id_abitante: Positive) is abstract;
   -- to set an asynchronus procedure you must have all IN parameter
   -- to set a synchronus procedure you must have IN-OUT parameters

private
   --type rt_server_finalize_configuration is abstract tagged limited null record;
   type rt_handler_semafori_quartiere is abstract tagged limited null record;
   type rt_q is abstract tagged limited null record;
end remote_types;
