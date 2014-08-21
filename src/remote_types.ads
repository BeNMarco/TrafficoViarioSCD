with strade_e_incroci_common;

use strade_e_incroci_common;

package remote_types is
   pragma Remote_Types;

   -- tipi usati per ottenere informazioni sul percorso che un certo abitante deve intraprendere
   type rt_location_abitanti is limited interface;
   type ptr_rt_location_abitanti is access all rt_location_abitanti'Class;
   type gps_abitanti_quartieri is array(Positive range <>) of ptr_rt_location_abitanti;

   type rt_quartiere_utilities is limited interface;
   type ptr_rt_quartiere_utilitites is access all rt_quartiere_utilities'Class;
   procedure registra_classe_locate_abitanti_quartiere(obj: access rt_quartiere_utilities; id_quartiere: Positive; location_abitanti: ptr_rt_location_abitanti) is abstract;
   procedure registra_abitanti(obj: access rt_quartiere_utilities; from_id_quartiere: Positive; abitanti: list_abitanti_quartiere; pedoni: list_pedoni_quartiere;
                               bici: list_bici_quartiere; auto: list_auto_quartiere) is abstract;
   type registro_quartieri is array(Positive range <>) of ptr_rt_quartiere_utilitites;

   -- begin resource segmenti
   type rt_segmento is limited interface;
   type ptr_rt_segmento is access all rt_segmento'Class;
   procedure wait_turno(obj: access rt_segmento) is abstract;
   procedure delta_terminate(obj: access rt_segmento) is abstract;
   function there_are_autos_to_move(obj: access rt_segmento) return Boolean is abstract;
   function there_are_pedoni_or_bici_to_move(obj: access rt_segmento) return Boolean is abstract;
   type set_resources is array(Positive range <>) of ptr_rt_segmento;

   type rt_wait_all_quartieri is limited interface;
   type ptr_rt_wait_all_quartieri is access all rt_wait_all_quartieri'Class;
   procedure all_quartieri_set(obj: access rt_wait_all_quartieri) is abstract;

   type rt_task_synchronization is limited interface;
   type ptr_rt_task_synchronization is access all rt_task_synchronization'Class;
   procedure all_task_partition_are_ready(obj: access rt_task_synchronization) is abstract;
   procedure wait_task_partitions(obj: access rt_task_synchronization) is abstract;
   procedure reset(obj: access rt_task_synchronization) is abstract;

   -- begin gps
   type gps_interface is limited interface;
   type ptr_gps_interface is access all gps_interface'Class;
   procedure registra_mappa_quartiere(obj: access gps_interface; id_quartiere: Positive; urbane: strade_urbane_features; ingressi: strade_ingresso_features; incroci_a_4: list_incroci_a_4;
                                        incroci_a_3: list_incroci_a_3; rotonde_a_4: list_incroci_a_4;
                                        rotonde_a_3: list_incroci_a_3) is abstract;
   function calcola_percorso(obj: access gps_interface; from_id_quartiere: Positive; from_id_luogo: Positive;
                             to_id_quartiere: Positive; to_id_luogo: Positive) return route_and_distance is abstract;
   function get_estremi_urbana(obj: access gps_interface; id_quartiere: Positive; id_urbana: Positive) return estremi_urbana is abstract;
   -- end gps

private
   type rt_server_finalize_configuration is abstract tagged limited null record;
end remote_types;
