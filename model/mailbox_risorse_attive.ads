with GNATCOLL.JSON;

with remote_types;
with strade_e_incroci_common;
with data_quartiere;
with risorse_passive_data;
with snapshot_interface;

use GNATCOLL.JSON;

use remote_types;
use strade_e_incroci_common;
use data_quartiere;
use risorse_passive_data;
use snapshot_interface;

package mailbox_risorse_attive is

   type data_structures_types is (road,sidewalk);

   type list_ingressi_per_urbana is tagged private;
   type ptr_list_ingressi_per_urbana is access list_ingressi_per_urbana;

   type list_posizione_abitanti_on_road is tagged private;
   type ptr_list_posizione_abitanti_on_road is access list_posizione_abitanti_on_road;

   function calculate_bound_to_overtake(abitante: ptr_list_posizione_abitanti_on_road; polo: Boolean; id_urbana: Positive) return Float;

   function get_posizione_abitanti_from_list_posizione_abitanti(obj: list_posizione_abitanti_on_road) return posizione_abitanti_on_road'Class;
   function get_next_from_list_posizione_abitanti(obj: list_posizione_abitanti_on_road) return ptr_list_posizione_abitanti_on_road;

   type road_state is array (Boolean range <>,Positive range <>) of ptr_list_posizione_abitanti_on_road;
   type number_entity is array (Boolean range <>,Positive range <>) of Natural;
   type indici_ingressi is array (Positive range <>) of Positive;
   type ptr_indici_ingressi is access indici_ingressi;
   type ordered_indici_ingressi is array (Boolean range <>) of ptr_indici_ingressi;
   type array_traiettorie_ingressi is array (Positive range <>,traiettoria_ingressi_type range <>) of ptr_list_posizione_abitanti_on_road;

   type ingressi_type is (not_ordered,ordered_polo_true,ordered_polo_false);
   type ingressi_in_svolta is array(Positive range <>) of traiettoria_ingressi_type;
   type ptr_ingressi_in_svolta is access ingressi_in_svolta;
   type ordered_ingressi_in_svolta is array(Boolean range <>) of ptr_ingressi_in_svolta;
   type abitanti_in_transizione_incroci_urbane is array(Boolean range False..True,id_corsie range 1..2) of posizione_abitanti_on_road;

   function create_img_abitante(abitante: posizione_abitanti_on_road) return JSON_Value;
   function create_img_strada(road: road_state) return JSON_Value;
   function create_img_num_entity_strada(num_entity_strada: number_entity) return JSON_Value;
   function create_abitante_from_json(json_abitante: JSON_Value) return posizione_abitanti_on_road;
   function create_array_abitanti(json_abitanti: JSON_Array) return ptr_list_posizione_abitanti_on_road;

   protected type resource_segmento_urbana(id_risorsa: Positive; num_ingressi: Natural; num_ingressi_polo_true: Natural; num_ingressi_polo_false: Natural) is new rt_urbana and backup_interface with
      entry ingresso_wait_turno;
      procedure delta_terminate;

      entry wait_incroci;
      procedure delta_incrocio_finished;

      -- metodo usato per creare una snapshot
      procedure create_img(json_1: out JSON_Value);
      procedure recovery_resource;

      procedure set_estremi_urbana(estremi: estremi_resource_strada_urbana);
      procedure aggiungi_entità_from_ingresso(id_ingresso: Positive; type_traiettoria: traiettoria_ingressi_type; id_quartiere_abitante: Positive; id_abitante: Positive; traiettoria_on_main_strada: trajectory_to_follow);
      procedure configure(risorsa: strada_urbana_features; list_ingressi: ptr_list_ingressi_per_urbana;
                          list_ingressi_polo_true: ptr_list_ingressi_per_urbana; list_ingressi_polo_false: ptr_list_ingressi_per_urbana);
      procedure set_move_parameters_entity_on_traiettoria_ingresso(abitante: ptr_list_posizione_abitanti_on_road; index_ingresso: Positive; traiettoria: traiettoria_ingressi_type; polo_to_go: Boolean; speed: Float; step: Float);
      procedure set_move_parameters_entity_on_main_road(current_car_in_corsia: in out ptr_list_posizione_abitanti_on_road; polo: Boolean; num_corsia: id_corsie; speed: Float; step: Float);
      procedure set_car_overtaken(value_overtaken: Boolean; car: in out ptr_list_posizione_abitanti_on_road);
      procedure set_flag_car_can_overtake_to_next_corsia(car: in out ptr_list_posizione_abitanti_on_road; flag: Boolean);
      procedure update_traiettorie_ingressi(state_view_abitanti: in out JSON_Array);
      procedure update_car_on_road(state_view_abitanti: in out JSON_Array);
      procedure remove_first_element_traiettoria(index_ingresso: Positive; traiettoria: traiettoria_ingressi_type);
      procedure insert_abitante_from_incrocio(abitante: posizione_abitanti_on_road; polo: Boolean; num_corsia: id_corsie);
      -- abitanti in transizione da incroci significa abitanti in uscita dagli incroci
      procedure sposta_abitanti_in_transizione_da_incroci;
      procedure remove_abitante_in_incrocio(polo: Boolean; num_corsia: id_corsie);

      function get_ordered_ingressi_from_polo(polo: Boolean) return ptr_indici_ingressi;
      function is_index_ingresso_in_svolta(ingresso: Positive; traiettoria: traiettoria_ingressi_type) return Boolean;
      function get_ingressi_ordered_by_distance return indici_ingressi;
      function get_index_ingresso_from_key(key: Positive; ingressi_structure_type: ingressi_type) return Natural;
      function get_key_ingresso(ingresso: Positive; ingressi_structure_type: ingressi_type) return Natural;
      function get_abitante_from_ingresso(index_ingresso: Positive; traiettoria: traiettoria_ingressi_type) return ptr_list_posizione_abitanti_on_road;
      function get_distance_to_first_abitante(polo: Boolean; num_corsia: id_corsie) return Float;
      -- get_next_abitante_on_road viene usato solo da quelle macchine in traiettoria di ingresso per ottenere a che distanza si trova la macchina successiva nella corsia in cui si deve immettere
      function get_next_abitante_on_road(from_distance: Float; range_1: Boolean; range_2: id_corsie) return ptr_list_posizione_abitanti_on_road; -- l'abitante sulla strada che sta davanti data la posizione from
      function can_abitante_move(distance: Float; key_ingresso: Positive; traiettoria: traiettoria_ingressi_type; polo_ingresso: Boolean) return Boolean;
      function can_abitante_continue_move(distance: Float; num_corsia_to_check: Positive; traiettoria: traiettoria_ingressi_type; polo_ingresso: Boolean) return Boolean;
      function get_abitanti_on_road(range_1: Boolean; range_2: id_corsie) return ptr_list_posizione_abitanti_on_road;
      function get_number_entity(structure: data_structures_types; polo: Boolean; num_corsia: id_corsie) return Natural;
      function calculate_distance_ingressi_from_given_distance(polo_to_consider: Boolean; in_corsia: id_corsie; car_distance: Float) return Float;
      function calculate_distance_to_next_ingressi(polo_to_consider: Boolean; in_corsia: id_corsie; car_in_corsia: ptr_list_posizione_abitanti_on_road) return Float;
      function can_car_overtake(car: ptr_list_posizione_abitanti_on_road; polo: Boolean; to_corsia: id_corsie) return Boolean;
      function there_are_cars_moving_across_next_ingressi(car: ptr_list_posizione_abitanti_on_road; polo: Boolean) return Boolean;
      function car_can_initiate_overtaken_on_road(car: ptr_list_posizione_abitanti_on_road; polo: Boolean; num_corsia: id_corsie) return Boolean;
      function there_are_overtaken_on_ingresso(ingresso: strada_ingresso_features; polo: Boolean) return Boolean; -- se polo = (polo dell'ingresso) => senso macchine to check è indicato da polo altrimenti not polo
      function car_on_same_corsia_have_overtaked(car: ptr_list_posizione_abitanti_on_road; polo: Boolean; num_corsia: id_corsie) return Boolean;
      function get_last_abitante_ingresso(key_ingresso: Positive; traiettoria: traiettoria_ingressi_type) return ptr_list_posizione_abitanti_on_road;

      function get_distanza_percorsa_first_abitante(polo: Boolean; num_corsia: id_corsie) return Float;

      function get_num_ingressi_polo(polo: Boolean) return Natural;
      function get_num_ingressi return Natural;
   private
      function get_num_estremi_urbana return Positive;

      num_delta_incroci_finished: Natural:= 0;
      array_estremi_strada_urbana: estremi_resource_strada_urbana:= (others => null);
      index_ingressi: indici_ingressi(1..num_ingressi);
      ordered_ingressi_polo: ordered_indici_ingressi(False..True):= (False => new indici_ingressi(1..num_ingressi_polo_false),True => new indici_ingressi(1..num_ingressi_polo_true));
      ordered_ingressi_polo_svolta: ordered_ingressi_in_svolta(False..True):= (False => new ingressi_in_svolta(1..num_ingressi_polo_false),True => new ingressi_in_svolta(1..num_ingressi_polo_true));
      risorsa_features: strada_urbana_features;
      finish_delta_urbana: Boolean:= False;
      num_ingressi_ready: Natural:= 0;
      -- l'immagine va creata per i prossimi elementi
      set_traiettorie_ingressi: array_traiettorie_ingressi(1..num_ingressi,traiettoria_ingressi_type'First..traiettoria_ingressi_type'Last);
      main_strada: road_state(False..True,1..2); -- RANGE1=1 percorrenza macchine da estremo false a estremo true; VICEVERSA per RANGE1=2
      marciapiedi: road_state(False..True,1..2);
      main_strada_number_entity: number_entity(False..True,1..2):= (others => (others => 0));
      marciapiedi_num_pedoni_bici: number_entity(False..True,1..2):= (others => (others => 0));
      temp_abitanti_in_transizione: abitanti_in_transizione_incroci_urbane;
   end resource_segmento_urbana;
   type ptr_resource_segmento_urbana is access all resource_segmento_urbana;
   type resource_segmenti_urbane is array(Positive range <>) of ptr_resource_segmento_urbana;
   type ptr_resource_segmenti_urbane is access all resource_segmenti_urbane;

   protected type resource_segmento_ingresso(id_risorsa: Positive) is new rt_ingresso and backup_interface with

      -- metodo usato per creare una snapshot
      procedure create_img(json_1: out JSON_Value);
      procedure recovery_resource;

      procedure set_move_parameters_entity_on_main_strada(range_1: Boolean; num_entity: Positive;
                                                          speed: Float; step_to_advance: Float);
      procedure registra_abitante_to_move(type_structure: data_structures_types; begin_speed: Float; posix: Float);
      procedure new_abitante_to_move(id_quartiere: Positive; id_abitante: Positive; mezzo: means_of_carrying);
      procedure new_abitante_finish_route(abitante: posizione_abitanti_on_road; mezzo: means_of_carrying);
      procedure update_position_entity(state_view_abitanti: in out JSON_Array);-- type_structure: data_structures_types; range_1: Boolean; index_entity: Positive);
      procedure update_avanzamento_car_in_urbana(distance: Float);
      procedure delete_car_in_uscita;
      procedure delete_car_in_entrata;
      procedure set_flag_spostamento_from_urbana_completato;

      function get_main_strada(range_1: Boolean) return ptr_list_posizione_abitanti_on_road;
      function get_marciapiede(range_1: Boolean) return ptr_list_posizione_abitanti_on_road;
      function get_number_entity_strada(range_1: Boolean) return Natural;
      function get_number_entity_marciapiede(range_1: Boolean) return Natural;
      function get_temp_main_strada return ptr_list_posizione_abitanti_on_road;
      function get_temp_marciapiede return ptr_list_posizione_abitanti_on_road;
      function get_posix_first_entity(type_structure: data_structures_types; range_1: Boolean) return Float;
      function get_index_inizio_moto return Boolean;
      function get_first_abitante_to_exit_from_urbana return ptr_list_posizione_abitanti_on_road;
      function get_car_avanzamento return Float;
      function get_last_abitante_in_urbana return posizione_abitanti_on_road;

      procedure configure(risorsa: strada_ingresso_features; inizio_moto: Boolean);
   private
      index_inizio_moto: Boolean;
      risorsa_features: strada_ingresso_features;
      function slide_list(type_structure: data_structures_types; range_1: Boolean; index_to_slide: Positive) return ptr_list_posizione_abitanti_on_road;
      -- l'immagine va creata per i prossimi elementi
      last_abitante_in_urbana: posizione_abitanti_on_road;   -- TO DO : mettere in immagine last_abitante_in_urbana
      car_avanzamento_in_urbana: Float:= 0.0;
      main_strada: road_state(False..True,1..1); -- RANGE1=1 da polo true a polo false; RANGE1=2 da polo false a polo true
      marciapiedi: road_state(False..True,1..1);
      main_strada_temp: ptr_list_posizione_abitanti_on_road:= null;
      marciapiedi_temp: ptr_list_posizione_abitanti_on_road:= null;
      main_strada_number_entity: number_entity(False..True,1..1):= (others => (others => 0));
      marciapiedi_number_entity: number_entity(False..True,1..1):= (others => (others => 0));
   end resource_segmento_ingresso;
   type ptr_resource_segmento_ingresso is access all resource_segmento_ingresso;
   type resource_segmenti_ingressi is array(Positive range <>) of ptr_resource_segmento_ingresso;
   type ptr_resource_segmenti_ingressi is access all resource_segmenti_ingressi;

   type car_to_move_in_incroci is array(Positive range <>, id_corsie range <>) of ptr_list_posizione_abitanti_on_road;

   protected type resource_segmento_incrocio(id_risorsa: Positive; size_incrocio: Positive) is new rt_incrocio and backup_interface with
      entry wait_turno;

      -- metodo usato per creare una snapshot
      procedure create_img(json_1: out JSON_Value);
      procedure recovery_resource;

      procedure delta_terminate;
      procedure change_verso_semafori_verdi;
      procedure insert_new_car(from_id_quartiere: Positive; from_id_road: Positive; car: posizione_abitanti_on_road);
      procedure update_avanzamento_car(abitante: in out ptr_list_posizione_abitanti_on_road; new_step: Float; new_speed: Float);
      procedure update_avanzamento_cars(state_view_abitanti: in out JSON_Array);
      procedure set_car_have_passed_urbana(abitante: in out ptr_list_posizione_abitanti_on_road);

      function get_verso_semafori_verdi return Boolean;
      function get_size_incrocio return Positive;
      function get_list_car_to_move(key_incrocio: Positive; corsia: id_corsie) return ptr_list_posizione_abitanti_on_road;
      function get_posix_first_entity(from_id_quartiere_road: Positive; from_id_road: Positive; num_corsia: id_corsie) return Float;
   private
      function get_num_urbane_to_wait return Positive;
      num_urbane_ready: Natural:= 0;
      finish_delta_incrocio: Boolean:= False;
      -- l'immagine va creata per i prossimi elementi
      verso_semafori_verdi: Boolean:= True;  -- key incroci per valore True: 1 e 3
      car_to_move: car_to_move_in_incroci(1..size_incrocio,1..2):= (others => (others => null));
   end resource_segmento_incrocio;
   type ptr_resource_segmento_incrocio is access all resource_segmento_incrocio;
   type resource_segmenti_incroci is array(Positive range <>) of ptr_resource_segmento_incrocio;
   type ptr_resource_segmenti_incroci is access all resource_segmenti_incroci;

   protected type resource_segmento_rotonda(id_risorsa: Positive; max_num_auto: Positive; max_num_pedoni: Positive) is new rt_segmento with
      entry wait_turno;
      procedure delta_terminate;
   end resource_segmento_rotonda;
   type ptr_resource_segmento_rotonda is access all resource_segmento_rotonda;
   type resource_segmenti_rotonde is array(Positive range <>) of ptr_resource_segmento_rotonda;
   type ptr_resource_segmenti_rotonde is access all resource_segmenti_rotonde;

   function get_min_length_entità(entity: entità) return Float;
   function calculate_max_num_auto(len: Float) return Natural;
   function calculate_max_num_pedoni(len: Float) return Natural;

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

   type array_index_ingressi_urbana is array(Positive range <>) of ptr_list_ingressi_per_urbana;
   type array_index_ingressi_urbana_per_polo is array(Positive range <>, Boolean range <>) of ptr_list_ingressi_per_urbana;

   function get_list_ingressi_urbana(id_urbana: Positive) return ptr_list_ingressi_per_urbana;

   function create_new_list_posizione_abitante(posizione_abitante: posizione_abitanti_on_road;
                                               next: ptr_list_posizione_abitanti_on_road) return ptr_list_posizione_abitanti_on_road;

   function calulate_index_road_to_go(id_incrocio: Positive; from_index: Positive; traiettoria: traiettoria_incroci_type) return Natural;

private

   type list_posizione_abitanti_on_road is tagged record
      posizione_abitante: posizione_abitanti_on_road;
      next: ptr_list_posizione_abitanti_on_road:= null;
   end record;

   type list_ingressi_per_urbana is tagged record
      id_ingresso: Positive;
      next: ptr_list_ingressi_per_urbana:= null;
   end record;

   urbane_segmento_resources: ptr_resource_segmenti_urbane;
   ingressi_segmento_resources: ptr_resource_segmenti_ingressi;
   incroci_a_4_segmento_resources: ptr_resource_segmenti_incroci;
   incroci_a_3_segmento_resources: ptr_resource_segmenti_incroci;
   rotonde_a_4_segmento_resources: ptr_resource_segmenti_rotonde;
   rotonde_a_3_segmento_resources: ptr_resource_segmenti_rotonde;
   ingressi_urbane: ingressi_of_urbane(get_from_urbane..get_to_urbane);

   id_ingressi_per_urbana: array_index_ingressi_urbana(get_from_urbane..get_to_urbane):= (others => null);
   id_ingressi_per_urbana_per_polo: array_index_ingressi_urbana_per_polo(get_from_urbane..get_to_urbane,False..True):= (others =>(others => null));

end mailbox_risorse_attive;
