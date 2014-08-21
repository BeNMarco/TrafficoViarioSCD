with remote_types;
with strade_e_incroci_common;

use remote_types;
use strade_e_incroci_common;

package mailbox_risorse_attive is

   type posizione_abitanti_on_road is tagged private;
   type road_state is array (Positive range <>,Positive range <>,Positive range <>) of posizione_abitanti_on_road;
   --road_state spec
   --	range1: indica i versi della strada, verso strada: 1 => verso polo true -> verso polo false; verso strada: 2 => verso polo false -> verso polo true
   --	range2: num corsie per senso di marcia
   --	range3: numero massimo di macchine che possono circolare su quel pezzo di strada
   --type sidewalks_state is array (Positive range <>,Positive range <>,Positive range <>,Positive range <>) of posizione_abitanti_on_road;
   --sidewalks_state spec
   --	range1: marciapiede lato strada: verso 1: marciapiede lato polo true -> polo false; verso 2: marciapiede lato polo false -> polo true;
   --	altri range analoghi a road_state
   type number_entity is array (Positive range <>,Positive range <>) of Natural;

   protected type resource_segmento_urbana(id_risorsa: Positive; length: Positive; num_ingressi: Natural; max_num_auto: Positive; max_num_pedoni: Positive) is new rt_segmento with
      entry wait_turno;
      procedure delta_terminate;
      function there_are_autos_to_move return Boolean;
      function there_are_pedoni_or_bici_to_move return Boolean;
   private
      finish_delta_urbana: Boolean:= False;
      num_ingressi_ready: Natural:= 0;
      main_strada: road_state(1..2,1..2,1..max_num_auto);
      marciapiedi: road_state(1..2,1..2,1..max_num_pedoni);
      main_strada_number_entity: number_entity(1..2,1..2):= (others => (others => 0));
      marciapiedi_num_pedoni_bici: number_entity(1..2,1..2):= (others => (others => 0));
   end resource_segmento_urbana;
   type ptr_resource_segmento_urbana is access all resource_segmento_urbana;
   type resource_segmenti_urbane is array(Positive range <>) of ptr_resource_segmento_urbana;
   type ptr_resource_segmenti_urbane is access all resource_segmenti_urbane;

   protected type resource_segmento_ingresso(id_risorsa: Positive; length: Positive; max_num_auto: Positive; max_num_pedoni: Positive) is new rt_segmento with
      entry wait_turno;
      procedure delta_terminate;
      function there_are_autos_to_move return Boolean;
      function there_are_pedoni_or_bici_to_move return Boolean;
   end resource_segmento_ingresso;
   type ptr_resource_segmento_ingresso is access all resource_segmento_ingresso;
   type resource_segmenti_ingressi is array(Positive range <>) of ptr_resource_segmento_ingresso;
   type ptr_resource_segmenti_ingressi is access all resource_segmenti_ingressi;

   protected type resource_segmento_incrocio(id_risorsa: Positive; length: Positive; max_num_auto: Positive; max_num_pedoni: Positive) is new rt_segmento with
      entry wait_turno;
      procedure delta_terminate;
      function there_are_autos_to_move return Boolean;
      function there_are_pedoni_or_bici_to_move return Boolean;
   private
      function get_num_urbane_to_wait return Positive;
      num_urbane_ready: Natural:= 0;
      finish_delta_incrocio: Boolean:= False;
   end resource_segmento_incrocio;
   type ptr_resource_segmento_incrocio is access all resource_segmento_incrocio;
   type resource_segmenti_incroci is array(Positive range <>) of ptr_resource_segmento_incrocio;
   type ptr_resource_segmenti_incroci is access all resource_segmenti_incroci;

   protected type resource_segmento_rotonda(id_risorsa: Positive; length: Positive; max_num_auto: Positive; max_num_pedoni: Positive) is new rt_segmento with
      entry wait_turno;
      procedure delta_terminate;
      function there_are_autos_to_move return Boolean;
      function there_are_pedoni_or_bici_to_move return Boolean;
   end resource_segmento_rotonda;
   type ptr_resource_segmento_rotonda is access all resource_segmento_rotonda;
   type resource_segmenti_rotonde is array(Positive range <>) of ptr_resource_segmento_rotonda;
   type ptr_resource_segmenti_rotonde is access all resource_segmenti_rotonde;

   function get_min_length_entità(entity: entità) return Float;
   function calculate_max_num_auto(len: Positive) return Positive;
   function calculate_max_num_pedoni(len: Positive) return Positive;

   function get_urbane_segmento_resources(index: Positive) return ptr_resource_segmento_urbana;
   function get_ingressi_segmento_resources(index: Positive) return ptr_resource_segmento_ingresso;
   function get_incroci_segmento_resources(index: Positive) return ptr_resource_segmento_incrocio;
   function get_incroci_a_4_segmento_resources(index: Positive) return ptr_resource_segmento_incrocio;
   function get_incroci_a_3_segmento_resources(index: Positive) return ptr_resource_segmento_incrocio;
   function get_rotonde_segmento_resources(index: Positive) return ptr_resource_segmento_rotonda;
   function get_rotonde_a_4_segmento_resources(index: Positive) return ptr_resource_segmento_rotonda;
   function get_rotonde_a_3_segmento_resources(index: Positive) return ptr_resource_segmento_rotonda;

   procedure create_mailbox_entità(urbane: strade_urbane_features; ingressi: strade_ingresso_features;
                                   incroci_a_4: list_incroci_a_4; incroci_a_3: list_incroci_a_3;
                                    rotonde_a_4: list_incroci_a_4; rotonde_a_3: list_incroci_a_3);

   function get_id_abitante_from_posizione(obj: posizione_abitanti_on_road) return Positive;
   function get_id_quartiere_from_posizione(obj: posizione_abitanti_on_road) return Positive;
   function get_where_from_posizione(obj: posizione_abitanti_on_road) return Float;
   function get_to_move_in_delta(obj: posizione_abitanti_on_road) return Boolean;

private

   type posizione_abitanti_on_road is tagged record
      id_abitante: Positive;
      id_quartiere: Positive;
      where: Float; -- posizione nella strada corrente dal punto di entrata
      to_move_in_delta: Boolean:= True;
   end record;

   urbane_segmento_resources: ptr_resource_segmenti_urbane;
   ingressi_segmento_resources: ptr_resource_segmenti_ingressi;
   incroci_a_4_segmento_resources: ptr_resource_segmenti_incroci;
   incroci_a_3_segmento_resources: ptr_resource_segmenti_incroci;
   rotonde_a_4_segmento_resources: ptr_resource_segmenti_rotonde;
   rotonde_a_3_segmento_resources: ptr_resource_segmenti_rotonde;
end mailbox_risorse_attive;
