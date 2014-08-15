with strade_e_incroci_common;

use strade_e_incroci_common;

package remote_types is
   pragma Remote_Types;

   -- begin resource segmenti
   type rt_segmento is limited interface;
   type ptr_rt_segmento_strade is access all rt_segmento'Class;
   -- end resource segmenti

   -- tipi usati per ottenere informazioni sul percorso che un certo abitante deve intraprendere
   type rt_location_abitanti is limited interface;
   type ptr_rt_location_abitanti is access all rt_location_abitanti'Class;
   type gps_abitanti_quartieri is array(Positive range <>) of ptr_rt_location_abitanti;

   type rt_wait_all_quartieri is limited interface;
   type ptr_rt_wait_all_quartieri is access all rt_wait_all_quartieri'Class;
   procedure all_quartieri_set(obj: access rt_wait_all_quartieri) is abstract;
   -- end tipi

   -- begin gps
   type gps_interface is limited interface;
   type ptr_gps_interface is access all gps_interface'Class;
   procedure registra_urbane_quartiere(obj: access gps_interface; id_quartiere: Positive; urbane: strade_urbane_features) is abstract;
   procedure registra_ingressi_quartiere(obj: access gps_interface; id_quartiere: Positive; ingressi: strade_ingresso_features) is abstract;
   procedure registra_incroci_quartiere(obj: access gps_interface; id_quartiere: Positive; incroci_a_4: list_incroci_a_4;
                                        incroci_a_3: list_incroci_a_3; rotonde_a_4: list_incroci_a_4;
                                        rotonde_a_3: list_incroci_a_3) is abstract;
   function calcola_percorso(obj: access gps_interface; from_id_quartiere: Positive; from_id_luogo: Positive;
                             to_id_quartiere: Positive; to_id_luogo: Positive) return route_and_distance is abstract;
   -- end gps

private
   type rt_server_finalize_configuration is abstract tagged limited null record;
end remote_types;
