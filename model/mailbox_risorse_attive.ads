with GNATCOLL.JSON;

with remote_types;
with strade_e_incroci_common;
with data_quartiere;
with risorse_passive_data;
with snapshot_interface;
with numerical_types;

use GNATCOLL.JSON;

use remote_types;
use strade_e_incroci_common;
use data_quartiere;
use risorse_passive_data;
use snapshot_interface;
use numerical_types;

package mailbox_risorse_attive is

   list_abitanti_error: exception;
   deleted_wrong_abitante: exception;
   other_error: exception;
   alcuni_elementi_non_visitati: exception;
   distanza_next_abitante_minore: exception;
   lista_abitanti_rotta: exception;
   set_field_json_error: exception;
   null_acceleration_when_next_car_is_null: exception;
   not_all_abitantI_other_corsia_have_been_considered: exception;
   index_abitante_scelto_sbagliato: exception;
   errore_traiettoria_car: exception;
   mezzo_settato_non_corretto: exception;

   type data_structures_types is (road,sidewalk);

   type list_ingressi_per_urbana is tagged private;
   type ptr_list_ingressi_per_urbana is access list_ingressi_per_urbana;

   type list_posizione_abitanti_on_road is tagged private;
   type ptr_list_posizione_abitanti_on_road is access list_posizione_abitanti_on_road;

   function calculate_bound_to_overtake(abitante: ptr_list_posizione_abitanti_on_road; polo: Boolean; id_urbana: Positive) return new_float;

   function get_posizione_abitanti_from_list_posizione_abitanti(obj: list_posizione_abitanti_on_road) return posizione_abitanti_on_road'Class;
   function get_next_from_list_posizione_abitanti(obj: list_posizione_abitanti_on_road) return ptr_list_posizione_abitanti_on_road;
   function get_prev_from_list_posizione_abitanti(obj: list_posizione_abitanti_on_road) return ptr_list_posizione_abitanti_on_road;

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

   --function create_img_abitante(abitante: posizione_abitanti_on_road; new_position_abitante: Float) return JSON_Value;
   --function create_img_strada(road: road_state; id_risorsa: Positive) return JSON_Value;
   --function create_img_num_entity_strada(num_entity_strada: number_entity) return JSON_Value;
   --function create_abitante_from_json(json_abitante: JSON_Value) return posizione_abitanti_on_road;
   --function create_array_abitanti(json_abitanti: JSON_Array) return ptr_list_posizione_abitanti_on_road;

   type abilita_attraversamenti_bipedi is array (Positive range <>) of Boolean;
   type ptr_abilita_attraversamenti_bipedi is access abilita_attraversamenti_bipedi;
   type attraversamenti_bipedi is array (Boolean range <>, Boolean range <>) of ptr_abilita_attraversamenti_bipedi;
   type attraveramento_cars is array (Boolean range <>) of ptr_abilita_attraversamenti_bipedi;

   protected type resource_segmento_urbana(id_risorsa: Positive; num_ingressi: Natural; num_ingressi_polo_true: Natural; num_ingressi_polo_false: Natural) is new rt_urbana and backup_interface with
      function get_id_risorsa return Positive;
      function get_id_quartiere_risorsa return Positive;

      entry ingresso_wait_turno;
      procedure delta_terminate;

      entry wait_incroci;
      procedure delta_incrocio_finished;

      -- metodo usato per creare una snapshot
      procedure create_img(json_1: out JSON_Value);
      procedure recovery_resource;

      procedure aggiungi_entità_from_ingresso(mezzo: means_of_carrying; id_ingresso: Positive; type_traiettoria: traiettoria_ingressi_type; id_quartiere_abitante: Positive; id_abitante: Positive; traiettoria_da_prendere: trajectory_to_follow);
      procedure configure(risorsa: strada_urbana_features; list_ingressi: ptr_list_ingressi_per_urbana;
                          list_ingressi_polo_true: ptr_list_ingressi_per_urbana; list_ingressi_polo_false: ptr_list_ingressi_per_urbana);
      procedure set_move_parameters_entity_on_traiettoria_ingresso(mezzo: means_of_carrying; abitante: ptr_list_posizione_abitanti_on_road; index_ingresso: Positive; traiettoria: traiettoria_ingressi_type; polo_to_go: Boolean; speed: new_float; step: new_float; step_is_just_calculated: Boolean:= False);
      procedure set_move_parameters_entity_on_main_road(current_car_in_corsia: in out ptr_list_posizione_abitanti_on_road; polo: Boolean; num_corsia: id_corsie; speed: new_float; step: new_float; step_is_just_calculated: Boolean:= False);
      procedure set_move_parameters_entity_on_sidewalk(mezzo: means_of_carrying; entity: in out ptr_list_posizione_abitanti_on_road; polo: Boolean; new_speed: new_float; new_step: new_float; step_is_just_calculated: Boolean);
      procedure set_car_overtaken(value_overtaken: Boolean; car: in out ptr_list_posizione_abitanti_on_road);
      procedure set_flag_abitante_can_overtake_to_next_corsia(abitante: in out ptr_list_posizione_abitanti_on_road; flag: Boolean);
      procedure update_traiettorie_ingressi(state_view_abitanti: in out JSON_Array);
      procedure update_car_on_road(state_view_abitanti: in out JSON_Array);
      procedure update_bipedi_on_sidewalk(state_view_abitanti: in out JSON_Array);
      procedure update_bipedi_on_traiettorie_ingressi(state_view_abitanti: in out JSON_Array);
      procedure remove_first_element_traiettoria(index_ingresso: Positive; traiettoria: traiettoria_ingressi_type);
      procedure insert_abitante_from_incrocio(mezzo: means_of_carrying; abitante: posizione_abitanti_on_road; polo: Boolean; num_corsia: id_corsie);
      -- abitanti in transizione da incroci significa abitanti in uscita dagli incroci
      procedure sposta_macchine_in_transizione_da_incroci;
      procedure sposta_bipedi_in_transizione_da_incroci;
      procedure azzera_spostamento_abitanti_in_incroci;

      procedure remove_abitante_in_incrocio(polo: Boolean; num_corsia: id_corsie; id_quartiere: Positive; id_abitante: Positive);
      procedure update_abitante_destination(abitante: in out ptr_list_posizione_abitanti_on_road; destination: trajectory_to_follow);

      -- metodo usato per abilitare o meno l'inserimento di bipedi che da sinistra
      -- devono essere messi nella traiettoria dritto
      procedure abilitazione_sinistra_bipedi_in_incroci(mezzo: means_of_carrying; enable: Boolean);

      -- metodi usati per abilitare attraversamenti pedoni in uscita_dritto e entrata_dritto
      procedure abilita_attraversamento_all_ingressi(from_begin: Boolean);
      procedure disabilita_attraversamento_bipedi_ingresso(polo_percorrenza: Boolean; polo_ingresso: Boolean; num_ingresso: Positive; from_begin: Boolean);
      function get_abilitazione_attraversamento_ingresso(polo_percorrenza: Boolean; polo_ingresso: Boolean; num_ingresso: Positive; from_begin: Boolean) return Boolean;

      procedure abilita_attraversamento_bipedi_in_all_entrata_ingresso;
      procedure disabilita_attraversamento_bipedi_in_entrata_ingresso(polo_ingresso: Boolean; num_ingresso: Positive);
      function get_abilitazione_attraversamento_in_entrata_ingresso(polo_ingresso: Boolean; num_ingresso: Positive) return Boolean;

      procedure abilita_attraversamento_cars_ingressi(in_uscita: Boolean);
      procedure disabilita_attraversamento_cars_ingresso(in_uscita: Boolean; polo_ingresso: Boolean; num_ingresso: Positive);
      function get_abilitazione_attraversamento_cars_ingresso(in_uscita: Boolean; polo_ingresso: Boolean; num_ingresso: Positive) return Boolean;

      function get_ordered_ingressi_from_polo(polo: Boolean) return ptr_indici_ingressi;
      function is_index_ingresso_in_svolta(ingresso: Positive; traiettoria: traiettoria_ingressi_type) return Boolean;
      function get_ingressi_ordered_by_distance return indici_ingressi;
      function get_index_ingresso_from_key(key: Positive; ingressi_structure_type: ingressi_type) return Natural;
      function get_key_ingresso(ingresso: Positive; ingressi_structure_type: ingressi_type) return Natural;
      function get_abitante_from_ingresso(index_ingresso: Positive; traiettoria: traiettoria_ingressi_type) return ptr_list_posizione_abitanti_on_road;
      function get_last_abitante_from_ingresso(index_ingresso: Positive; traiettoria: traiettoria_ingressi_type) return ptr_list_posizione_abitanti_on_road;
      -- get_next_abitante_on_road viene usato SIA DA quelle macchine in traiettoria di ingresso per ottenere a che distanza si trova la macchina successiva nella corsia in cui si deve immettere
      -- SIA dagli incroci per vedere la progressione di avanzamento delle macchine(in questo caso viene chiamato da get_distanza_percorsa_first_abitante)
      function get_next_abitante_on_road(from_distance: new_float; range_1: Boolean; range_2: id_corsie; from_ingresso: Boolean:= True) return ptr_list_posizione_abitanti_on_road; -- l'abitante sulla strada che sta davanti data la posizione from
      function can_abitante_move(distance: new_float; key_ingresso: Positive; traiettoria: traiettoria_ingressi_type; polo_ingresso: Boolean; altro_ab: ptr_list_posizione_abitanti_on_road) return Boolean;
      function can_abitante_continue_move(distance: new_float; num_corsia_to_check: Positive; traiettoria: traiettoria_ingressi_type; polo_ingresso: Boolean; abitante_altra_traiettoria: ptr_list_posizione_abitanti_on_road:= null) return Boolean;
      function get_abitanti_to_move(type_structure: data_structures_types; range_1: Boolean; range_2: id_corsie) return ptr_list_posizione_abitanti_on_road;
      function get_number_entity_on_road(polo: Boolean; num_corsia: id_corsie) return Natural;
      function calculate_distance_ingressi_from_given_distance(polo_to_consider: Boolean; in_corsia: id_corsie; car_distance: new_float) return new_float;
      function calculate_distance_to_next_ingressi(polo_to_consider: Boolean; in_corsia: id_corsie; car_in_corsia: ptr_list_posizione_abitanti_on_road) return new_float;
      function can_car_overtake(car: ptr_list_posizione_abitanti_on_road; polo: Boolean; to_corsia: id_corsie) return Boolean;

      function get_abitante_in_transizione_da_incrocio(mezzo: means_of_carrying; polo: Boolean; corsia: id_corsie) return posizione_abitanti_on_road;
      -- BEGIN metodi per gestione cambio corsia
      -- controlla se la macchina si trova nella posizione di un ingresso, lato false o true, e se in questo vi sono macchine in movimento
      function there_are_cars_moving_across_next_ingressi(car: ptr_list_posizione_abitanti_on_road; polo: Boolean) return Boolean;
      -- controlla se si hanno macchine dalla corsia opposta che intersecano la traiettoria di sorpasso
      -- della macchina che vuole sorpassare nel primo pezzo della traiettoria e nel secondo pezzo della traiettoria
      function car_can_overtake_on_first_step_trajectory(car: ptr_list_posizione_abitanti_on_road; polo: Boolean; num_corsia: id_corsie; is_bound_overtaken: Boolean:= False) return Boolean;
      function car_can_overtake_on_second_step_trajectory(car: ptr_list_posizione_abitanti_on_road; polo: Boolean; num_corsia: id_corsie) return Boolean;
      -- controlla se si hanno macchine che intersecano la traiettoria di sorpasso nella corsia corrente
      function complete_trajectory_on_same_corsia_is_free(car: ptr_list_posizione_abitanti_on_road; polo: Boolean; num_corsia: id_corsie) return Boolean;
      -- END metodi gestione cambio corsia

      -- DEPRECATED:
      function there_are_overtaken_on_ingresso(ingresso: strada_ingresso_features; polo: Boolean) return Boolean; -- se polo = (polo dell'ingresso) => senso macchine to check è indicato da polo altrimenti not polo

      --BEGIN metodi per gestione sorpassi
      function get_next_abitante_in_corsia(num_corsia: id_corsie; polo: Boolean; from_distance: new_float) return ptr_list_posizione_abitanti_on_road;
      -- END metodi per gestione sorpassi

      --function get_last_abitante_ingresso(key_ingresso: Positive; traiettoria: traiettoria_ingressi_type) return ptr_list_posizione_abitanti_on_road;
      function get_distanza_percorsa_first_abitante(polo: Boolean; num_corsia: id_corsie) return new_float;
      -- get_distanza_percorsa_first_bipede ritorna la distanza al netto della lunghezza del bipede
      function get_distanza_percorsa_first_bipede(polo: Boolean; mezzo: means_of_carrying) return new_float;
      function first_car_abitante_has_passed_incrocio(polo: Boolean; num_corsia: id_corsie) return Boolean;
      --function get_distance_to_first_abitante(polo: Boolean; num_corsia: id_corsie) return Float;

      function get_num_ingressi_polo(polo: Boolean) return Natural;
      function get_num_ingressi return Natural;

      -- metodo richiamato per vedere se è possibile inserire gli abitanti
      -- nella traiettoria per muoversi a destra
      function get_abilitazione_cambio_traiettoria_bipede(mezzo: means_of_carrying) return Boolean;

      procedure exit_system;

   private
      function get_num_estremi_urbana return Natural;
      function slide_list_road(range_1: Boolean; range_2: id_corsie; index_to_slide: Natural) return ptr_list_posizione_abitanti_on_road;

      exit_system_stato: Boolean:= False;
      num_delta_incroci_finished: Natural:= 0;
      --array_estremi_strada_urbana: estremi_resource_strada_urbana:= (others => null);
      index_ingressi: indici_ingressi(1..num_ingressi);
      ordered_ingressi_polo: ordered_indici_ingressi(False..True):= (False => new indici_ingressi(1..num_ingressi_polo_false),True => new indici_ingressi(1..num_ingressi_polo_true));
      ordered_ingressi_polo_svolta: ordered_ingressi_in_svolta(False..True):= (False => new ingressi_in_svolta(1..num_ingressi_polo_false),True => new ingressi_in_svolta(1..num_ingressi_polo_true));
      risorsa_features: strada_urbana_features;
      finish_delta_urbana: Boolean:= False;
      finish_update_view: Boolean:= False;
      num_ingressi_ready: Natural:= 0;
      -- l'immagine va creata per i prossimi elementi
      set_traiettorie_ingressi: array_traiettorie_ingressi(1..num_ingressi,traiettoria_ingressi_type'First..traiettoria_ingressi_type'Last);
      main_strada: road_state(False..True,1..2); -- RANGE1=1 percorrenza macchine da estremo false a estremo true; VICEVERSA per RANGE1=2
      marciapiedi: road_state(False..True,1..2);
      main_strada_number_entity: number_entity(False..True,1..2):= (others => (others => 0));
      --marciapiedi_num_pedoni_bici: number_entity(False..True,1..2):= (others => (others => 0));
      temp_cars_in_transizione: abitanti_in_transizione_incroci_urbane;
      temp_bipedi_in_transizione: abitanti_in_transizione_incroci_urbane;

      backup_temp_cars_in_transizione: abitanti_in_transizione_incroci_urbane;
      backup_temp_bipedi_in_transizione: abitanti_in_transizione_incroci_urbane;


      abilita_attraversamento_bipedi_from_begin: attraversamenti_bipedi(False..True,False..True):= (False => (False => new abilita_attraversamenti_bipedi(1..num_ingressi_polo_false), True => new abilita_attraversamenti_bipedi(1..num_ingressi_polo_true)), True => (False => new abilita_attraversamenti_bipedi(1..num_ingressi_polo_false), True => new abilita_attraversamenti_bipedi(1..num_ingressi_polo_true)));
      abilita_attraversamento_bipedi_from_mezzaria: attraversamenti_bipedi(False..True,False..True):= (False => (False => new abilita_attraversamenti_bipedi(1..num_ingressi_polo_false), True => new abilita_attraversamenti_bipedi(1..num_ingressi_polo_true)), True => (False => new abilita_attraversamenti_bipedi(1..num_ingressi_polo_false), True => new abilita_attraversamenti_bipedi(1..num_ingressi_polo_true)));
      abilita_attraversamento_bipedi_in_entrata_ingresso: attraveramento_cars(False..True):= (False => new abilita_attraversamenti_bipedi(1..num_ingressi_polo_false),True => new abilita_attraversamenti_bipedi(1..num_ingressi_polo_true));

      abilita_attraversameno_cars_in_uscita_ingressi: attraveramento_cars(False..True):= (False => new abilita_attraversamenti_bipedi(1..num_ingressi_polo_false),True => new abilita_attraversamenti_bipedi(1..num_ingressi_polo_true));
      abilita_attraversameno_cars_in_entrata_ingressi: attraveramento_cars(False..True):= (False => new abilita_attraversamenti_bipedi(1..num_ingressi_polo_false),True => new abilita_attraversamenti_bipedi(1..num_ingressi_polo_true));

      abilita_sinistra_pedoni_in_incroci: Boolean:= True;
      abilita_sinistra_bici_in_incroci: Boolean:= True;
   end resource_segmento_urbana;
   type ptr_resource_segmento_urbana is access all resource_segmento_urbana;
   type resource_segmenti_urbane is array(Positive range <>) of ptr_resource_segmento_urbana;
   type ptr_resource_segmenti_urbane is access all resource_segmenti_urbane;

   protected type resource_segmento_ingresso(id_risorsa: Positive) is new rt_ingresso and backup_interface with
      function get_id_risorsa return Positive;
      function get_id_quartiere_risorsa return Positive;

      -- metodo usato per creare una snapshot
      procedure create_img(json_1: out JSON_Value);
      procedure recovery_resource;

      procedure set_move_parameters_entity_on_main_strada(range_1: Boolean; num_entity: Positive;
                                                          speed: new_float; step_to_advance: new_float);
      procedure set_move_parameters_entity_on_marciapiede(range_1: Boolean; range_2: id_corsie; num_entity: Positive;
                                                          speed: new_float; step_to_advance: new_float);
      procedure registra_abitante_to_move(type_structure: data_structures_types; range_2: id_corsie);
      procedure new_abitante_to_move(id_quartiere: Positive; id_abitante: Positive; mezzo: means_of_carrying);
      procedure new_car_finish_route(abitante: posizione_abitanti_on_road);
      procedure new_bipede_finish_route(abitante: posizione_abitanti_on_road; corsia: id_corsie);
      procedure update_position_entity(state_view_abitanti: in out JSON_Array);-- type_structure: data_structures_types; range_1: Boolean; index_entity: Positive);
      procedure update_avanzamento_abitante_in_urbana(mezzo: means_of_carrying; distance: new_float);

      -- BEGIN delete procedure
      procedure delete_car_in_uscita;
      procedure delete_car_in_entrata(id_quartiere_abitante: Positive; id_abitante: Positive);
      procedure delete_bipede_in_uscita(range_2: id_corsie);
      procedure delete_bipede_in_entrata(id_quartiere_abitante: Positive; id_abitante: Positive; corsia: id_corsie);
      -- END delete procedure

      procedure set_flag_spostamento_from_urbana_completato(car: posizione_abitanti_on_road);
      procedure sposta_abitanti_in_entrata_ingresso;

      function get_main_strada(range_1: Boolean) return ptr_list_posizione_abitanti_on_road;
      function get_marciapiede(range_1: Boolean; range_2: id_corsie) return ptr_list_posizione_abitanti_on_road;
      function get_number_entity_strada(range_1: Boolean) return Natural;
      function get_number_entity_marciapiede(range_1: Boolean; range_2: id_corsie) return Natural;
      function get_temp_main_strada return ptr_list_posizione_abitanti_on_road;
      function get_temp_marciapiede(range_2: id_corsie) return ptr_list_posizione_abitanti_on_road;
      function get_temp_car_in_entrata return posizione_abitanti_on_road;
      function get_index_inizio_moto return Boolean;

      -- get_first_abitante_to_exit_from_urbana viene richiesto dall'urbana per trovare
      -- la posizione del primo abitante nella corsia di fine percorso (not index_inizio_moto)
      function get_first_abitante_to_exit_from_urbana(mezzo: means_of_carrying) return ptr_list_posizione_abitanti_on_road;
      function get_car_avanzamento return new_float;
      function get_bipede_avanzamento(range_2: id_corsie) return new_float;
      function get_last_abitante_in_urbana return posizione_abitanti_on_road;
      function get_last_abitante_in_marciapiede(range_2: id_corsie) return posizione_abitanti_on_road;

      procedure configure(risorsa: strada_ingresso_features; inizio_moto: Boolean);

      procedure add_abitante_in_fermata(identificativo_abitante: tratto);
      function create_array_abitanti_in_fermata return set_tratti;
      procedure aggiorna_abitanti_in_fermata(abitanti_saliti_in_bus: set_tratti);
   private
      index_inizio_moto: Boolean;
      risorsa_features: strada_ingresso_features;
      function slide_list(type_structure: data_structures_types; range_1: Boolean; range_2: id_corsie; index_to_slide: Positive) return ptr_list_posizione_abitanti_on_road;
      -- l'immagine va creata per i prossimi elementi
      last_abitante_in_urbana: posizione_abitanti_on_road;
      last_abitante_in_marciapiede_1: posizione_abitanti_on_road; -- abitante ciclabile
      last_abitante_in_marciapiede_2: posizione_abitanti_on_road; -- abitante marciapiede
      car_avanzamento_in_urbana: new_float:= 0.0;
      pedone_avanzamento_in_urbana: new_float:= 0.0;
      bici_avanzamento_in_urbana: new_float:= 0.0;

      temp_car_finish_route: posizione_abitanti_on_road;
      temp_bici_finish_route: posizione_abitanti_on_road;
      temp_pedone_finish_route: posizione_abitanti_on_road;

      backup_temp_car_finish_route: posizione_abitanti_on_road;
      backup_temp_bici_finish_route: posizione_abitanti_on_road;
      backup_temp_pedone_finish_route: posizione_abitanti_on_road;

      main_strada: road_state(False..True,1..1); -- RANGE1=1 da polo true a polo false; RANGE1=2 da polo false a polo true
      marciapiedi: road_state(False..True,1..2); -- RANGE2=1 sono le bici; RANGE2=1 sono i pedoni
      main_strada_temp: ptr_list_posizione_abitanti_on_road:= null;
      pedoni_temp: ptr_list_posizione_abitanti_on_road:= null;
      bici_temp: ptr_list_posizione_abitanti_on_road:= null;
      main_strada_number_entity: number_entity(False..True,1..1):= (others => (others => 0));
      marciapiedi_number_entity: number_entity(False..True,1..2):= (others => (others => 0));

      abitanti_waiting_bus: ptr_lista_passeggeri:= null;
      num_abitanti_waiting_bus: Natural:= 0;

   end resource_segmento_ingresso;
   type ptr_resource_segmento_ingresso is access all resource_segmento_ingresso;
   type resource_segmenti_ingressi is array(Positive range <>) of ptr_resource_segmento_ingresso;
   type ptr_resource_segmenti_ingressi is access all resource_segmenti_ingressi;

   type car_to_move_in_incroci is array(Positive range <>, id_corsie range <>) of ptr_list_posizione_abitanti_on_road;
   type tmp_car_to_move_in_incroci is array(Positive range <>, id_corsie range <>) of posizione_abitanti_on_road;

   type bipedi_to_move_in_incroci is array(Positive range <>, traiettoria_incroci_type range <>) of ptr_list_posizione_abitanti_on_road;
   type temp_bipedi_to_move_in_incroci is array(Positive range <>, id_corsie range <>) of ptr_list_posizione_abitanti_on_road;

   protected type resource_segmento_incrocio(id_risorsa: Positive; size_incrocio: Positive) is new rt_incrocio and backup_interface with
      function get_id_risorsa return Positive;
      function get_id_quartiere_risorsa return Positive;

      -- metodo usato per creare una snapshot
      procedure create_img(json_1: out JSON_Value);
      procedure recovery_resource;

      procedure delta_terminate;
      procedure change_verso_semafori_verdi;
      procedure change_semafori_pedoni;
      procedure insert_new_car(from_id_quartiere: Positive; from_id_road: Positive; car: posizione_abitanti_on_road);
      procedure insert_new_bipede(from_id_quartiere: Positive; from_id_road: Positive; bipede: posizione_abitanti_on_road; mezzo: means_of_carrying; traiettoria: traiettoria_incroci_type);
      procedure update_avanzamento_abitante(abitante: in out ptr_list_posizione_abitanti_on_road; new_step: new_float; new_speed: new_float; step_is_just_calculated: Boolean:= False);
      procedure update_avanzamento_cars(state_view_abitanti: in out JSON_Array);
      procedure update_avanzamento_bipedi(state_view_abitanti: in out JSON_Array);
      procedure set_car_have_passed_urbana(abitante: in out ptr_list_posizione_abitanti_on_road);
      procedure update_avanzamento_in_urbana(abitante: in out ptr_list_posizione_abitanti_on_road; avanzamento: new_float);

      procedure update_abitante_destination(abitante: in out ptr_list_posizione_abitanti_on_road; destination: trajectory_to_follow);

      procedure calcola_bound_avanzamento_in_incrocio(index_road: in out Natural; indice: Natural; traiettoria_car: traiettoria_incroci_type; corsia: id_corsie; num_car: Natural; bound_distance: in out new_float; stop_entity: in out Boolean; distance_to_next_car: in out new_float; from_id_quartiere_road: Natural:= 0; from_id_road: Natural:= 0);
      procedure sposta_bipede_da_sinistra_a_dritto(index_road: Positive; mezzo: means_of_carrying; id_quartiere: Positive; id_abitante: Positive);

      procedure remove_first_bipede_to_go_destra_from_dritto(index_road: Positive; corsia: id_corsie; list: in out ptr_list_posizione_abitanti_on_road);

      function get_verso_semafori_verdi return Boolean;
      function get_semaforo_bipedi return Boolean;
      function get_size_incrocio return Positive;
      function get_list_car_to_move(key_incrocio: Positive; corsia: id_corsie) return ptr_list_posizione_abitanti_on_road;
      function get_list_bipede_to_move(key_incrocio: Positive; traiettoria: traiettoria_incroci_type) return ptr_list_posizione_abitanti_on_road;

      -- metodo usato da un'urbana per individuare la posizione di un abitante
      function get_posix_first_entity(from_id_quartiere_road: Positive; from_id_road: Positive; num_corsia: id_corsie) return new_float;

      function get_posix_first_bipede(from_id_quartiere_road: Positive; from_id_road: Positive; mezzo: means_of_carrying; traiettoria: traiettoria_incroci_type) return new_float;

      function semaforo_is_verde_from_road(id_quartiere_road: Positive; id_road: Positive) return Boolean;

   private
      function slide_list(num_urbana: Positive; num_corsia: id_corsie; index_to_slide: Positive) return ptr_list_posizione_abitanti_on_road;
      function get_num_urbane_to_wait return Positive;

      num_urbane_ready: Natural:= 0;
      finish_delta_incrocio: Boolean:= False;
      -- l'immagine va creata per i prossimi elementi
      verso_semafori_verdi: Boolean:= False;  -- key incroci per valore True: 1 e 3
      bipedi_can_cross: Boolean:= False;  -- False nessun bipede può attraversare, True tutti su tutte le strade dell'incrocio possono attraversare
      car_to_move: car_to_move_in_incroci(1..size_incrocio,1..2):= (others => (others => null));
      temp_car_to_move: tmp_car_to_move_in_incroci(1..size_incrocio,1..2);
      bipedi_to_move: bipedi_to_move_in_incroci(1..4,destra_pedoni..sinistra_bici);
      temp_bipedi_destra_to_go: temp_bipedi_to_move_in_incroci(1..4,1..2);
   end resource_segmento_incrocio;
   type ptr_resource_segmento_incrocio is access all resource_segmento_incrocio;
   type resource_segmenti_incroci is array(Positive range <>) of ptr_resource_segmento_incrocio;
   type ptr_resource_segmenti_incroci is access all resource_segmenti_incroci;

   --protected type resource_segmento_rotonda(id_risorsa: Positive; max_num_auto: Positive; max_num_pedoni: Positive) is new rt_segmento with

   --   entry wait_turno;
   --   procedure delta_terminate;
   --end resource_segmento_rotonda;
   --type ptr_resource_segmento_rotonda is access all resource_segmento_rotonda;
   --type resource_segmenti_rotonde is array(Positive range <>) of ptr_resource_segmento_rotonda;
   --type ptr_resource_segmenti_rotonde is access all resource_segmenti_rotonde;

   function get_min_length_entità(entity: entità) return new_float;

   function get_urbane_segmento_resources(index: Positive) return ptr_resource_segmento_urbana;
   function get_ingressi_segmento_resources(index: Positive) return ptr_resource_segmento_ingresso;
   function get_incroci_segmento_resources(index: Positive) return ptr_resource_segmento_incrocio;
   function get_incroci_a_4_segmento_resources(index: Positive) return ptr_resource_segmento_incrocio;
   function get_incroci_a_3_segmento_resources(index: Positive) return ptr_resource_segmento_incrocio;
   --function get_rotonde_segmento_resources(index: Positive) return ptr_resource_segmento_rotonda;
   --function get_rotonde_a_4_segmento_resources(index: Positive) return ptr_resource_segmento_rotonda;
   --function get_rotonde_a_3_segmento_resources(index: Positive) return ptr_resource_segmento_rotonda;

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
   function calulate_index_road_to_go_incrocio_completo_from_incrocio_a_3(id_incrocio: Positive; from_index: Positive; traiettoria: traiettoria_incroci_type) return Natural;

   procedure close_mailbox;
private

   type list_posizione_abitanti_on_road is tagged record
      posizione_abitante: posizione_abitanti_on_road;
      next: ptr_list_posizione_abitanti_on_road:= null;
      prev: ptr_list_posizione_abitanti_on_road:= null;
   end record;

   type list_ingressi_per_urbana is tagged record
      id_ingresso: Positive;
      next: ptr_list_ingressi_per_urbana:= null;
   end record;

   urbane_segmento_resources: ptr_resource_segmenti_urbane;
   ingressi_segmento_resources: ptr_resource_segmenti_ingressi;
   incroci_a_4_segmento_resources: ptr_resource_segmenti_incroci;
   incroci_a_3_segmento_resources: ptr_resource_segmenti_incroci;
   --rotonde_a_4_segmento_resources: ptr_resource_segmenti_rotonde;
   --rotonde_a_3_segmento_resources: ptr_resource_segmenti_rotonde;
   ingressi_urbane: ingressi_of_urbane(get_from_urbane..get_to_urbane);

   id_ingressi_per_urbana: array_index_ingressi_urbana(get_from_urbane..get_to_urbane):= (others => null);
   id_ingressi_per_urbana_per_polo: array_index_ingressi_urbana_per_polo(get_from_urbane..get_to_urbane,False..True):= (others =>(others => null));

end mailbox_risorse_attive;
