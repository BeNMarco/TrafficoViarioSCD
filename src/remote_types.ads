with strade_e_incroci_common;

use strade_e_incroci_common;

package remote_types is
   pragma Remote_Types;

   -- begin resource segmenti
   type rt_segmento is limited interface;
   type ptr_rt_segmento_strade is access all rt_segmento'Class;
   -- end resource segmenti

   type cache_abitanti_interface is limited interface;
   type ptr_cache_abitanti_interface is access all cache_abitanti_interface'Class;
   procedure registra_pedoni(from_id_quartiere: Positive) is abstract;

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

end remote_types;
