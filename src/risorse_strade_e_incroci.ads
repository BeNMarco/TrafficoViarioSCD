with remote_types;
with data_quartiere;
with strade_e_incroci_common;
with global_data;
with the_name_server;

use remote_types;
use data_quartiere;
use strade_e_incroci_common;
use global_data;
use the_name_server;

package risorse_strade_e_incroci is

   protected type wait_all_quartieri is new rt_wait_all_quartieri with
      procedure all_quartieri_set;
      entry wait_quartieri;
      entry wait_all_task_quartieri;
   private
      segnale: Boolean:= False;
      num_task_registrati: Natural:= 0;
   end wait_all_quartieri;

   type ptr_wait_all_quartieri is access wait_all_quartieri;

   type ptr_route_and_distance is access all route_and_distance'Class;
   type percorso_abitanti is array(Positive range <>) of ptr_route_and_distance;

   protected type location_abitanti(num_abitanti: Positive) is new rt_location_abitanti with
        procedure set_percorso_abitante(id_abitante: Positive; percorso: route_and_distance);
   private
      percorsi: percorso_abitanti(1..num_abitanti):= (others => null);
   end location_abitanti;

   type ptr_location_abitanti is access location_abitanti;

   type posizione_abitanti_on_road is tagged private;
   type road_state is array (Positive range <>,Positive range <>,Positive range <>) of posizione_abitanti_on_road;
   --road_state spec
   --	range1: indica i versi della strada, verso strada: 1 => verso polo true -> verso polo false; verso strada: 2 => verso polo false -> verso polo true
   --	range2: num corsie per senso di marcia
   --	range3: numero massimo di macchine che possono circolare su quel pezzo di strada
   type sidewalks_state is array (Positive range <>,Positive range <>,Positive range <>,Positive range <>) of posizione_abitanti_on_road;
   --sidewalks_state spec
   --	range1: marciapiede lato strada: verso 1: marciapiede lato polo true -> polo false; verso 2: marciapiede lato polo false -> polo true;
   --	altri range analoghi a road_state

   protected type resource_segmento_strada(num_corsie: Positive; length: Positive; max_num_auto: Positive; max_num_pedoni: Positive) is new rt_segmento with
      procedure prova;
   private
      main_strada: road_state(1..2,1..num_corsie,1..max_num_auto);
      marciapiedi: sidewalks_state(1..2,1..2,1..1,1..max_num_pedoni);
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

   function get_min_length_entità(entity: entità) return Float;
   function calculate_max_num_auto(len: Positive) return Positive;
   function calculate_max_num_pedoni(len: Positive) return Positive;

private

   type posizione_abitanti_on_road is tagged record
      id_abitante: Positive;
      id_quartiere: Positive;
      where: Natural; -- posizione nella strada corrente dal punto di entrata
   end record;

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

   -- classe utilizzata per settare la posizione corrente di un abitante, per settare il percorso, per ottenere il percorso
   locate_abitanti_quartiere: ptr_location_abitanti:= new location_abitanti(get_to_abitanti-get_from_abitanti+1);
   -- array i quali oggetti sono del tipo ptr_rt_location_abitanti per ottenere le informazioni esposte sopra per gps_abitanti
   rt_classi_locate_abitanti: gps_abitanti_quartieri(1..get_num_quartieri);
   -- server gps
   gps: ptr_gps_interface:= get_server_gps;

   min_length_pedoni: Float;
   min_length_bici: Float;
   min_length_auto: Float;

   waiting_object: ptr_wait_all_quartieri:= new wait_all_quartieri;

end risorse_strade_e_incroci;
