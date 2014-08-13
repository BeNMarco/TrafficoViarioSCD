with remote_types;
with data_quartiere;
with strade_e_incroci_common;
with global_data;

use remote_types;
use data_quartiere;
use strade_e_incroci_common;
use global_data;

package risorse_strade_e_incroci is

   type ptr_route_and_distance is access all route_and_distance'Class;
   type percorso_abitanti is array(Positive range <>) of ptr_route_and_distance;

   protected type location_abitanti(num_abitanti: Positive) is new rt_location_abitanti with
        procedure set_percorso_abitante(id_abitante: Positive; percorso: route_and_distance);
   private
      percorsi: percorso_abitanti(1..num_abitanti):= (others => null);
   end location_abitanti;

   type ptr_location_abitanti is access location_abitanti;

   protected type resource_segmento_strada is new rt_segmento with
      procedure prova;
   private
      l: Positive:=1;
   end resource_segmento_strada;

   type ptr_resource_segmento_strada is access all resource_segmento_strada;

   type core_avanzamento is limited interface;

   procedure configure(entity: access core_avanzamento; id: Positive; resource: ptr_resource_segmento_strada) is abstract;

   task type core_avanzamento_urbane is new core_avanzamento with
      entry configure(id: Positive; resource: ptr_resource_segmento_strada);
   end core_avanzamento_urbane;

   type task_container_urbane is array(Positive range <>) of core_avanzamento_urbane;
   type task_container_ingressi is array(Positive range <>) of core_avanzamento_urbane;
   type task_container_rotonde is array(Positive range <>) of core_avanzamento_urbane;
   type task_container_incroci is array(Positive range <>) of core_avanzamento_urbane;

   type resource_segmenti_strade is array(Positive range <>) of ptr_resource_segmento_strada;
   type ptr_resource_segmenti_strade is access all resource_segmenti_strade;

private

   urbane_features: strade_urbane_features(get_from_urbane..get_to_urbane);
   ingressi_features: strade_ingresso_features(get_from_ingressi..get_to_ingressi);
   incroci_a_4: list_incroci_a_4(get_from_incroci_a_4..get_to_incroci_a_4);
   incroci_a_3: list_incroci_a_3(get_from_incroci_a_3..get_to_incroci_a_3);
   rotonde_a_4: list_incroci_a_4(get_from_rotonde_a_4..get_to_rotonde_a_4);
   rotonde_a_3: list_incroci_a_3(get_from_rotonde_a_3..get_to_rotonde_a_3);

   entità_abitanti: list_abitanti_quartieri(1..get_num_quartieri);
   entità_pedoni: list_pedoni_quartieri(1..get_num_quartieri);
   entità_bici: list_bici_quartieri(1..get_num_quartieri);
   entità_auto: list_auto_quartieri(1..get_num_quartieri);

   -- server utilizzati per aspettare che tutti i quartieri facciano le oonfigurazioni
   server_cache: ptr_cache_abitanti_interface:= null;
   server_gps_abitanti: ptr_rt_posizione_abitanti_quartieri:= null;
   -- end server

   -- classe utilizzata per settare la posizione corrente di un abitante, per settare il percorso, per ottenere il percorso
   gps_abitanti: ptr_location_abitanti:= new location_abitanti(get_to_abitanti-get_from_abitanti+1);
   -- array i quali oggetti sono del tipo ptr_rt_location_abitanti per ottenere le informazioni esposte sopra per gps_abitanti
   rt_gps_abitanti_quartieri: gps_abitanti_quartieri(1..get_num_quartieri);

end risorse_strade_e_incroci;
