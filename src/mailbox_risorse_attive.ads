with remote_types;
with strade_e_incroci_common;
with data_quartiere;

use remote_types;
use strade_e_incroci_common;
use data_quartiere;

package mailbox_risorse_attive is

   type posizione_abitanti_on_road is tagged private;
   type data_structures_types is (road,sidewalk);

   function get_id_abitante_posizione_abitanti(obj: posizione_abitanti_on_road) return Positive;
   function get_id_quartiere_posizione_abitanti(obj: posizione_abitanti_on_road) return Positive;
   function get_where_next_posizione_abitanti(obj: posizione_abitanti_on_road) return Float;
   function get_where_now_posizione_abitanti(obj: posizione_abitanti_on_road) return Float;
   function get_current_speed_abitante(obj: posizione_abitanti_on_road) return Float;
   function get_to_move_in_delta_posizione_abitanti(obj: posizione_abitanti_on_road) return Boolean;
   procedure set_current_speed_abitante(obj: in out posizione_abitanti_on_road; speed: Float);
   procedure set_where_next_abitante(obj: in out posizione_abitanti_on_road; where_next: Float);
   procedure set_where_now_abitante(obj: in out posizione_abitanti_on_road; where_now: Float);
   procedure set_to_move_in_delta(obj: in out posizione_abitanti_on_road; to_move_in_delta: Boolean);

   type list_posizione_abitanti_on_road is tagged private;
   type ptr_list_posizione_abitanti_on_road is access list_posizione_abitanti_on_road;

   function get_posizione_abitanti_from_list_posizione_abitanti(obj: list_posizione_abitanti_on_road) return posizione_abitanti_on_road'Class;
   function get_next_from_list_posizione_abitanti(obj: list_posizione_abitanti_on_road) return ptr_list_posizione_abitanti_on_road;

   type road_state is array (Positive range <>,Positive range <>) of ptr_list_posizione_abitanti_on_road;
   --road_state spec
   --	range1: indica i versi della strada, verso strada: 1 => verso polo true -> verso polo false; verso strada: 2 => verso polo false -> verso polo true
   --	range2: num corsie per senso di marcia
   --type sidewalks_state is array (Positive range <>,Positive range <>,Positive range <>,Positive range <>) of posizione_abitanti_on_road;
   --sidewalks_state spec
   --	range1: marciapiede lato strada: verso 1: marciapiede lato polo true -> polo false; verso 2: marciapiede lato polo false -> polo true;
   --	altri range analoghi a road_state
   type number_entity is array (Positive range <>,Positive range <>) of Natural;

   protected type resource_segmento_urbana(id_risorsa: Positive; num_ingressi: Natural; max_num_auto: Positive; max_num_pedoni: Positive) is new rt_segmento with
      entry wait_turno;
      procedure delta_terminate;
      function there_are_autos_to_move return Boolean;
      function there_are_pedoni_or_bici_to_move return Boolean;

      procedure configure(risorsa: strada_urbana_features);
   private
      risorsa_features: strada_urbana_features;
      finish_delta_urbana: Boolean:= False;
      num_ingressi_ready: Natural:= 0;
      main_strada: road_state(1..2,1..2);
      marciapiedi: road_state(1..2,1..2);
      main_strada_number_entity: number_entity(1..2,1..2):= (others => (others => 0));
      marciapiedi_num_pedoni_bici: number_entity(1..2,1..2):= (others => (others => 0));
   end resource_segmento_urbana;
   type ptr_resource_segmento_urbana is access all resource_segmento_urbana;
   type resource_segmenti_urbane is array(Positive range <>) of ptr_resource_segmento_urbana;
   type ptr_resource_segmenti_urbane is access all resource_segmenti_urbane;

   protected type resource_segmento_ingresso(id_risorsa: Positive; max_num_auto: Positive; max_num_pedoni: Positive) is new rt_segmento with
      entry wait_turno;
      procedure delta_terminate;

      procedure set_move_parameters_entity_on_main_strada(range_1: Positive; num_entity: Positive;
                                                          speed: Float; step_to_advance: Float);
      procedure registra_abitante_to_move(type_structure: data_structures_types; begin_speed: Float; posix: Float);
      procedure new_abitante_to_move(id_quartiere: Positive; id_abitante: Positive; mezzo: means_of_carrying);
      procedure update_position_entity(type_structure: data_structures_types; range_1: Positive; index_entity: Positive);

      function there_are_autos_to_move return Boolean;
      function there_are_pedoni_or_bici_to_move return Boolean;

      function get_main_strada(range_1: Positive) return ptr_list_posizione_abitanti_on_road;
      function get_marciapiede(range_1: Positive) return ptr_list_posizione_abitanti_on_road;
      function get_number_entity_strada(range_1: Positive) return Natural;
      function get_number_entity_marciapiede(range_1: Positive) return Natural;
      function get_temp_main_strada return ptr_list_posizione_abitanti_on_road;
      function get_temp_marciapiede return ptr_list_posizione_abitanti_on_road;
      function get_posix_first_entity(type_structure: data_structures_types; range_1: Positive) return Float;

      procedure configure(risorsa: strada_ingresso_features);
   private
      risorsa_features: strada_ingresso_features;
      function slide_list(type_structure: data_structures_types; range_1: Positive; index_to_slide: Positive) return ptr_list_posizione_abitanti_on_road;
      main_strada: road_state(1..2,1..1);
      marciapiedi: road_state(1..2,1..1);
      main_strada_temp: ptr_list_posizione_abitanti_on_road:= null;
      marciapiedi_temp: ptr_list_posizione_abitanti_on_road:= null;
      main_strada_number_entity: number_entity(1..2,1..1):= (others => (others => 0));
      marciapiedi_number_entity: number_entity(1..2,1..1):= (others => (others => 0));
   end resource_segmento_ingresso;
   type ptr_resource_segmento_ingresso is access all resource_segmento_ingresso;
   type resource_segmenti_ingressi is array(Positive range <>) of ptr_resource_segmento_ingresso;
   type ptr_resource_segmenti_ingressi is access all resource_segmenti_ingressi;

   protected type resource_segmento_incrocio(id_risorsa: Positive; max_num_auto: Positive; max_num_pedoni: Positive) is new rt_segmento with
      entry wait_turno;
      procedure delta_terminate;
      procedure change_verso_semafori_verdi;
      function there_are_autos_to_move return Boolean;
      function there_are_pedoni_or_bici_to_move return Boolean;
   private
      function get_num_urbane_to_wait return Positive;
      num_urbane_ready: Natural:= 0;
      finish_delta_incrocio: Boolean:= False;
      verso_semafori_verdi: Boolean:= True;
   end resource_segmento_incrocio;
   type ptr_resource_segmento_incrocio is access all resource_segmento_incrocio;
   type resource_segmenti_incroci is array(Positive range <>) of ptr_resource_segmento_incrocio;
   type ptr_resource_segmenti_incroci is access all resource_segmenti_incroci;

   protected type resource_segmento_rotonda(id_risorsa: Positive; max_num_auto: Positive; max_num_pedoni: Positive) is new rt_segmento with
      entry wait_turno;
      procedure delta_terminate;
      function there_are_autos_to_move return Boolean;
      function there_are_pedoni_or_bici_to_move return Boolean;
   end resource_segmento_rotonda;
   type ptr_resource_segmento_rotonda is access all resource_segmento_rotonda;
   type resource_segmenti_rotonde is array(Positive range <>) of ptr_resource_segmento_rotonda;
   type ptr_resource_segmenti_rotonde is access all resource_segmenti_rotonde;

   function get_min_length_entità(entity: entità) return Float;
   function calculate_max_num_auto(len: Float) return Positive;
   function calculate_max_num_pedoni(len: Float) return Positive;

   function get_urbane_segmento_resources(index: Positive) return ptr_resource_segmento_urbana;
   function get_ingressi_segmento_resources(index: Positive) return ptr_resource_segmento_ingresso;
   function get_incroci_segmento_resources(index: Positive) return ptr_resource_segmento_incrocio;
   function get_incroci_a_4_segmento_resources(index: Positive) return ptr_resource_segmento_incrocio;
   function get_incroci_a_3_segmento_resources(index: Positive) return ptr_resource_segmento_incrocio;
   function get_rotonde_segmento_resources(index: Positive) return ptr_resource_segmento_rotonda;
   function get_rotonde_a_4_segmento_resources(index: Positive) return ptr_resource_segmento_rotonda;
   function get_rotonde_a_3_segmento_resources(index: Positive) return ptr_resource_segmento_rotonda;

   type id_ingressi_urbane is array(Positive range <>) of Positive;
   type ptr_id_ingressi_urbane is access all id_ingressi_urbane;
   type ingressi_of_urbane is array(Positive range <>) of ptr_id_ingressi_urbane;
   function get_ingressi_urbana(id_urbana: Positive) return ptr_id_ingressi_urbane;

   procedure create_mailbox_entità(urbane: strade_urbane_features; ingressi: strade_ingresso_features;
                                   incroci_a_4: list_incroci_a_4; incroci_a_3: list_incroci_a_3;
                                    rotonde_a_4: list_incroci_a_4; rotonde_a_3: list_incroci_a_3);

   function get_id_abitante_from_posizione(obj: posizione_abitanti_on_road) return Positive;
   function get_id_quartiere_from_posizione(obj: posizione_abitanti_on_road) return Positive;
   function get_new_posizione(obj: posizione_abitanti_on_road) return Float;
   function get_old_posizione(obj: posizione_abitanti_on_road) return Float;
   function get_to_move_in_delta(obj: posizione_abitanti_on_road) return Boolean;

private

   type posizione_abitanti_on_road is tagged record
      id_abitante: Positive;
      id_quartiere: Positive;
      where_next: Float:= 0.0; -- posizione nella strada corrente dal punto di entrata
      where_now: Float:= 0.0;
      current_speed: Float:= 0.0;
      to_move_in_delta: Boolean:= True;
   end record;

   type list_posizione_abitanti_on_road is tagged record
      posizione_abitante: posizione_abitanti_on_road;
      next: ptr_list_posizione_abitanti_on_road:= null;
   end record;

   urbane_segmento_resources: ptr_resource_segmenti_urbane;
   ingressi_segmento_resources: ptr_resource_segmenti_ingressi;
   incroci_a_4_segmento_resources: ptr_resource_segmenti_incroci;
   incroci_a_3_segmento_resources: ptr_resource_segmenti_incroci;
   rotonde_a_4_segmento_resources: ptr_resource_segmenti_rotonde;
   rotonde_a_3_segmento_resources: ptr_resource_segmenti_rotonde;
   ingressi_urbane: ingressi_of_urbane(get_from_urbane..get_to_urbane);

end mailbox_risorse_attive;
