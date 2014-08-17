with GNATCOLL.JSON;

with strade_e_incroci_common;
with data_quartiere;
with remote_types;

use GNATCOLL.JSON;

use strade_e_incroci_common;
use data_quartiere;
use remote_types;

package risorse_mappa_utilities is

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

   type resource_segmenti_strade is array(Positive range <>) of ptr_resource_segmento_strada;
   type ptr_resource_segmenti_strade is access all resource_segmenti_strade;

   function get_min_length_entità(entity: entità) return Float;
   function calculate_max_num_auto(len: Positive) return Positive;
   function calculate_max_num_pedoni(len: Positive) return Positive;

   function create_array_urbane(json_roads: JSON_array; from: Natural; to: Natural) return strade_urbane_features;

   function create_array_ingressi(json_roads: JSON_array; from: Natural; to: Natural) return strade_ingresso_features;

   function create_array_incroci_a_4(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_4;

   function create_array_incroci_a_3(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_3;

   function create_array_rotonde_a_4(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_4;

   function create_array_rotonde_a_3(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_3;

   procedure print_percorso(route: percorso);

   urbane_segmento_resources: ptr_resource_segmenti_strade;
   ingressi_segmento_resources: ptr_resource_segmenti_strade;
   incroci_a_4_segmento_resources: ptr_resource_segmenti_strade;
   incroci_a_3_segmento_resources: ptr_resource_segmenti_strade;
   rotonde_a_4_segmento_resources: ptr_resource_segmenti_strade;
   rotonde_a_3_segmento_resources: ptr_resource_segmenti_strade;
private

   type posizione_abitanti_on_road is tagged record
      id_abitante: Positive;
      id_quartiere: Positive;
      where: Natural; -- posizione nella strada corrente dal punto di entrata
   end record;
end risorse_mappa_utilities;
