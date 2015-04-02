with numerical_types;

use numerical_types;

package strade_e_incroci_common is
   pragma Pure;

   error_in_conversione_da_stringa: exception;

   type type_strade is (urbana,ingresso);
   type type_ingresso is (abitato,fermata);
   type entity_type is (empty,urbana,ingresso,incrocio_a_4,incrocio_a_3,rotonda_a_4);

   subtype id_corsie is Positive range 1..2;

   type traiettoria_incroci_type is (empty,        destra,sinistra,dritto_1,dritto_2,     destra_pedoni,dritto_pedoni,sinistra_pedoni,destra_bici,dritto_bici,sinistra_bici);
   type traiettorie_intersezioni_linee_corsie is (linea_corsia,linea_mezzaria);
   type traiettoria_ingressi_type is (empty,      entrata_andata,uscita_andata,entrata_ritorno,uscita_ritorno,     uscita_destra_pedoni,uscita_dritto_pedoni,uscita_destra_bici,uscita_dritto_bici,uscita_ritorno_pedoni,uscita_ritorno_bici,            entrata_destra_pedoni,entrata_destra_bici,entrata_ritorno_pedoni,entrata_ritorno_bici,entrata_dritto_pedoni,entrata_dritto_bici);

   function to_string_incroci_type(obj: traiettoria_incroci_type) return String;
   function to_string_ingressi_type(obj: traiettoria_ingressi_type) return String;
   function convert_to_traiettoria_incroci(obj: String) return traiettoria_incroci_type;
   function convert_string_to_type_ingresso(tipo: String) return type_ingresso;

   type rt_strada_features is abstract tagged private;
   function get_lunghezza_road(road: rt_strada_features) return new_float;
   function get_id_quartiere_road(road: rt_strada_features) return Positive;
   function get_id_road(road: rt_strada_features) return Positive;

   type strada_urbana_features is new rt_strada_features with private;
   type strada_ingresso_features is new rt_strada_features with private;

   type road_incrocio_features is tagged private;

   -- begin tipi incroci
   type list_road_incrocio_a_4 is array(Positive range 1..4) of road_incrocio_features;
   type list_road_incrocio_a_3 is array(Positive range 1..3) of road_incrocio_features;
   -- end tipo incroci

   -- begin incroci
   type list_incroci_a_4 is array(Positive range <>) of list_road_incrocio_a_4;
   type list_incroci_a_3 is array(Positive range <>) of list_road_incrocio_a_3;
   -- end incroci

   type move_settings is (desired_velocity,time_headway,max_acceleration,comfortable_deceleration,s0,length,num_posti);

   type means_of_carrying is (walking, bike, car);

   type abitante is tagged private;

   function get_id_abitante_from_abitante(residente: abitante) return Natural;
   function get_id_quartiere_from_abitante(residente: abitante) return Natural;
   function get_id_luogo_casa_from_abitante(residente: abitante) return Natural;
   function get_id_quartiere_luogo_lavoro_from_abitante(residente: abitante) return Natural;
   function get_id_luogo_lavoro_from_abitante(residente: abitante) return Natural;
   function get_mezzo_abitante(residente: abitante) return means_of_carrying;
   function is_a_bus(residente: abitante) return Boolean;
   function is_a_bus_jolly(residente: abitante) return Boolean;
   function is_a_jolly_to_quartiere(residente: abitante) return Natural;

   type move_parameters is tagged private;

   function get_id_abitante_entità_passiva(obj: move_parameters) return Positive;
   function get_id_quartiere_abitante_entità_passiva(obj: move_parameters) return Positive;
   function get_desired_velocity(obj: move_parameters) return new_float;
   function get_time_headway(obj: move_parameters) return new_float;
   function get_max_acceleration(obj: move_parameters) return new_float;
   function get_comfortable_deceleration(obj: move_parameters) return new_float;
   function get_s0(obj: move_parameters) return new_float;
   function get_length_entità_passiva(obj: move_parameters) return new_float;

   type pedone is new move_parameters with private;
   type bici is new move_parameters with private;
   type auto is new move_parameters with private;

   type entità is (pedone_entity,bici_entity,auto_entity);

   type list_abitanti_temp is array(Positive range <>,Positive range <>) of abitante; -- cache entità quartiere per quartiere
   type list_pedoni_temp is array(Positive range <>,Positive range <>) of pedone;
   type list_bici_temp is array(Positive range <>,Positive range <>) of bici;
   type list_auto_temp is array(Positive range <>,Positive range <>) of auto;
   type list_abitanti_quartiere is array(Positive range <>) of abitante; -- cache entità quartiere per quartiere
   type list_pedoni_quartiere is array(Positive range <>) of pedone;
   type list_bici_quartiere is array(Positive range <>) of bici;
   type list_auto_quartiere is array(Positive range <>) of auto;
   type list_abitanti_quartieri is array(Positive range <>) of access list_abitanti_quartiere; -- cache entità quartiere per quartiere
   type list_pedoni_quartieri is array(Positive range <>) of access list_pedoni_quartiere;
   type list_bici_quartieri is array(Positive range <>) of access list_bici_quartiere;
   type list_auto_quartieri is array(Positive range <>) of access list_auto_quartiere;

   type strade_urbane_features is array(Positive range <>) of strada_urbana_features;
   type urbane_quartiere is array(Positive range <>) of access strade_urbane_features;

   type strade_ingresso_features is array(Positive range <>) of strada_ingresso_features;
   type ingressi_quartiere is array(Positive range <>) of access strade_ingresso_features;

   type tratto is tagged private;
   type percorso is array(Positive range <>) of tratto;
   type route_and_distance(size_percorso: Natural) is tagged private; -- tipo usato per rappresentare il percorso minimo da una certo luogo di partenza


   type stato_percorso is tagged private;

   type estremo_urbana is tagged private;
   type estremi_strade_urbane is array(Positive range <>,Positive range <>) of estremo_urbana;

   function create_new_road_incrocio(val_id_quartiere: Positive;val_id_strada: Positive;val_polo: Boolean)
                                     return road_incrocio_features;

   function create_new_urbana(val_tipo: type_strade;val_id: Positive;val_id_quartiere: Positive;
                              val_lunghezza: new_float;val_num_corsie: Positive) return strada_urbana_features;

   function create_new_ingresso(val_tipo: type_strade;val_id: Positive;val_id_quartiere: Positive;
                                val_lunghezza: new_float;val_num_corsie: Positive;val_id_main_strada: Positive;
                                val_distance_from_road_head: new_float; polo: Boolean; val_tipo_ingresso: type_ingresso) return strada_ingresso_features;

   function create_tratto(id_quartiere: Natural; id_tratto: Natural) return tratto;

   function create_percorso(route: percorso; distance: new_float) return route_and_distance;

   function create_abitante(id_abitante: Natural; id_quartiere: Natural; id_luogo_casa: Natural;
                            id_quartiere_luogo_lavoro: Natural; id_luogo_lavoro: Natural; mezzo: means_of_carrying; is_a_bus: Boolean; jolly: Boolean; jolly_to_quartiere: Natural) return abitante;

   function create_pedone(id_abitante: Natural; id_quartiere: Natural:= 0; desired_velocity: Float;
                          time_headway: Float; max_acceleration: Float; comfortable_deceleration: Float;
                          s0: Float; length: Float) return pedone;

   function create_bici(id_abitante: Natural; id_quartiere: Natural:= 0; desired_velocity: Float;
                        time_headway: Float; max_acceleration: Float; comfortable_deceleration: Float;
                        s0: Float; length: Float) return bici;

   function create_auto(id_abitante: Natural; id_quartiere: Natural:= 0; desired_velocity: Float;
                        time_headway: Float; max_acceleration: Float; comfortable_deceleration: Float;
                        s0: Float; length: Float; num_posti: Positive) return auto;

   function create_estremo_urbana(id_quartiere: Natural; id_incrocio: Natural; polo: Boolean) return estremo_urbana;

   function get_id_quartiere_estremo_urbana(obj: estremo_urbana) return Natural;
   function get_id_incrocio_estremo_urbana(obj: estremo_urbana) return Natural;
   function get_polo_estremo_urbana(obj: estremo_urbana) return Boolean;

   function get_id_main_strada_ingresso(road: strada_ingresso_features) return Positive;
   function get_distance_from_road_head_ingresso(road: strada_ingresso_features) return new_float;
   function get_polo_ingresso(road: strada_ingresso_features) return Boolean;
   function get_type_ingresso(road: strada_ingresso_features) return type_ingresso;

   -- begin get methods road_incrocio_features
   function get_id_quartiere_road_incrocio(road: road_incrocio_features) return Positive;
   function get_id_strada_road_incrocio(road: road_incrocio_features) return Positive;
   function get_polo_road_incrocio(road: road_incrocio_features) return Boolean;
   -- end get methods road_incrocio_features


   procedure set_mezzo_abitante(residente: in out abitante; mezzo: means_of_carrying);

   function get_id_quartiere_tratto(segmento: tratto) return Natural;
   function get_id_tratto(segmento: tratto) return Natural;

   function get_percorso_from_route_and_distance(route: route_and_distance) return percorso;
   function get_distance_from_route_and_distance(route: route_and_distance) return new_float;
   function get_size_percorso(route: route_and_distance) return Natural;

   type trajectory_to_follow is tagged private;
   type posizione_abitanti_on_road is tagged private;

   function get_departure_corsia(obj: trajectory_to_follow) return Natural;
   function get_corsia_to_go_trajectory(obj: trajectory_to_follow) return Natural;
   function get_ingresso_to_go_trajectory(obj: trajectory_to_follow) return Natural;
   function get_traiettoria_incrocio_to_follow(obj: trajectory_to_follow) return traiettoria_incroci_type;
   function get_from_ingresso(obj: trajectory_to_follow) return Natural;

   function get_id_abitante_posizione_abitanti(obj: posizione_abitanti_on_road) return Natural;
   function get_id_quartiere_posizione_abitanti(obj: posizione_abitanti_on_road) return Natural;
   function get_where_next_posizione_abitanti(obj: posizione_abitanti_on_road) return new_float;
   function get_where_now_posizione_abitanti(obj: posizione_abitanti_on_road) return new_float;
   function get_current_speed_abitante(obj: posizione_abitanti_on_road) return new_float;
   function get_in_overtaken(obj: posizione_abitanti_on_road) return Boolean;
   function get_distance_on_overtaking_trajectory(obj: posizione_abitanti_on_road) return new_float;
   function get_destination(obj: posizione_abitanti_on_road) return trajectory_to_follow'Class;
   function get_flag_overtake_next_corsia(obj: posizione_abitanti_on_road) return Boolean;
   function get_came_from_ingresso(obj: posizione_abitanti_on_road) return Boolean;
   function get_backup_corsia_to_go(obj: posizione_abitanti_on_road) return Natural;

   procedure set_where_next_abitante(obj: in out posizione_abitanti_on_road; where_next: new_float);
   procedure set_where_now_abitante(obj: in out posizione_abitanti_on_road; where_now: new_float);
   procedure set_current_speed_abitante(obj: in out posizione_abitanti_on_road; speed: new_float);
   procedure set_in_overtaken(obj: in out posizione_abitanti_on_road; in_overtaken: Boolean);
   procedure set_distance_on_overtaking_trajectory(obj: in out posizione_abitanti_on_road; distance: new_float);
   procedure set_destination(obj: in out posizione_abitanti_on_road; traiettoria: trajectory_to_follow'Class);
   procedure set_flag_overtake_next_corsia(obj: in out posizione_abitanti_on_road; flag: Boolean);
   procedure set_came_from_ingresso(obj: in out posizione_abitanti_on_road; flag: Boolean);
   procedure set_backup_corsia_to_go(obj: in out posizione_abitanti_on_road; num_corsia: Natural);

   function create_trajectory_to_follow(from_corsia: Natural; corsia_to_go: Natural; ingresso_to_go: Natural; from_ingresso: Natural; traiettoria_incrocio_to_follow: traiettoria_incroci_type) return trajectory_to_follow;

   function create_new_posizione_abitante(id_abitante: Positive; id_quartiere: Positive; where_next: new_float;
                                          where_now: new_float; current_speed: new_float; in_overtaken: Boolean;
                                          can_pass_corsia: Boolean; distance_on_overtaking_trajectory: new_float;
                                          came_from_ingresso: Boolean; destination: trajectory_to_follow; backup_corsia_to_go: Natural) return posizione_abitanti_on_road'Class;

   function create_new_posizione_abitante_from_copy(posizione_abitante: posizione_abitanti_on_road) return posizione_abitanti_on_road;

   type resource_type is (urbana,incrocio,ingresso);

   function convert_string_to_resource_type(tipo_risorsa: String) return resource_type;

   type tratto_updated is tagged private;
   function create_tratto_updated(pezzo: tratto'Class; updated: Boolean) return tratto_updated;
   function get_tratto(obj: tratto_updated) return tratto'Class;
   function is_tratto_updated(obj: tratto_updated) return Boolean;
   procedure update_tratto(obj: in out tratto_updated; new_tratto: tratto'Class);
   procedure set_tratto_updated(obj: in out tratto_updated; val: Boolean);

   type tratti_fermata is array(Positive range <>) of tratto_updated;
   type destination_tratto is tagged private;

   function get_quartiere_jolly_to_go(obj: destination_tratto) return Positive;
   function get_tratto_jolly_to_go(obj: destination_tratto) return tratto'Class;
   function is_updated(obj: destination_tratto) return Boolean;
   procedure update_destination(obj: in out destination_tratto; new_destination: tratto'Class);
   procedure set_destination_updated(obj: in out destination_tratto; val: Boolean);

   function create_destination(to_id_quartiere: Positive; to_place: tratto'Class) return destination_tratto;

   type destination_tratti is array(Positive range <>) of destination_tratto;
   type linea_bus is tagged private;

   type set_tratti is array(Positive range <>) of tratto;

   function get_numero_fermate(obj: linea_bus) return Natural;
   function get_num_tratto(obj: linea_bus; num_tratto: Positive) return tratto'Class;
   function get_jolly_quartiere_to_go(obj: linea_bus; num_jolly_quartiere_to_go: Positive) return tratto'Class;
   function get_linea_bus(obj: linea_bus) return access tratti_fermata;
   function get_destination_jolly(obj: linea_bus) return access destination_tratti;
   function is_updated_linea(obj: linea_bus) return Boolean;
   function is_updated_jolly(obj: linea_bus; id_quartiere: Positive) return Boolean;

   function create_linea_bus(from_id_quartiere: Positive; to_id_quartiere: Positive; linea: access tratti_fermata; jolly: access destination_tratti) return linea_bus;

   type linee_bus is array(Positive range <>) of linea_bus;

   type tuple_abitanti is array(Positive range <>) of tratto;

   type set is array(Positive range <>) of Natural;
   type boolean_queue is array(Positive range <>) of Boolean;
private

   type estremo_urbana is tagged record
      id_quartiere: Natural;
      id_incrocio: Natural;
      polo: Boolean;
   end record;

   type rt_strada_features is tagged record
      tipo: type_strade;
      id: Positive;  -- id strada coincide con id della sua risorsa protetta
      id_quartiere: Positive;
      lunghezza: new_float;
      num_corsie: Positive;
   end record;

   type strada_urbana_features is new rt_strada_features with null record;

   type strada_ingresso_features is new rt_strada_features with record
      id_main_strada : Positive; 	-- strada principale dalla quale si ha la strada d'ingresso
      					-- si tratta sempre di una strada locale e non remota
      distance_from_road_head : new_float; -- distanza dalle coordinate from della strada principale
      polo: Boolean;
      tipo_ingresso: type_ingresso;
   end record;

   type road_incrocio_features is tagged record
      id_quartiere: Positive;
      id_strada: Positive;
      polo: Boolean;
   end record;

   type tratto is tagged record
      id_quartiere: Natural;
      id_tratto: Natural;
   end record;

   type route_and_distance(size_percorso:Natural) is tagged record
      route: percorso(1..size_percorso);
      distance_from_start: new_float;
   end record;

   type stato_percorso is tagged record
      percorso: access route_and_distance:= null; -- percorso che deve svolgere, null se si trova su un luogo
      move_by: means_of_carrying:=  walking;
   end record;

   -- NOTA type abitante per gli autobus:
   -- id_luogo_casa => stazione_partenza
   -- id_quartiere_luogo_lavoro => jolly
   -- id_luogo_lavoro => linea_da_percorrere;
   type abitante is tagged record
      id_abitante: Natural:= 0;
      id_quartiere: Natural:= 0;
      id_luogo_casa: Natural:= 0; -- il quartiere della casa coincide con id_quartiere
      id_quartiere_luogo_lavoro: Natural:= 0;
      id_luogo_lavoro: Natural:= 0;
      mezzo: means_of_carrying;
      bus: Boolean:= False;
      jolly: Boolean:= False;
      jolly_to_quartiere: Natural:= 0;
   end record;

   type move_parameters is tagged record
      id_abitante: Natural:= 0;
      id_quartiere: Natural:= 0;
      desired_velocity: new_float; -- m/s
      time_headway: new_float; -- s
      max_acceleration: new_float; -- m/s^2
      comfortable_deceleration: new_float; -- m/s^2
      s0: new_float;
      length: new_float;
   end record;

   type pedone is new move_parameters with null record;

   type bici is new move_parameters with null record;

   type auto is new move_parameters with record
      num_posti: Positive;
   end record;

   type trajectory_to_follow is tagged record
      departure_corsia: Natural:= 0;
      corsia_to_go: Natural:= 0;
      ingresso_to_go: Natural:= 0;
      from_ingresso: Natural:= 0;
      traiettoria_incrocio_to_follow: traiettoria_incroci_type:= empty;
   end record;

   type posizione_abitanti_on_road is tagged record
      id_abitante: Natural:= 0;
      id_quartiere: Natural:= 0;
      where_next: new_float:= 0.0; -- posizione nella strada corrente dal punto di entrata
      where_now: new_float:= 0.0;
      current_speed: new_float:= 0.0;
      in_overtaken: Boolean:= False;
      can_pass_corsia: Boolean:= False;
      came_from_ingresso: Boolean:= False;
      distance_on_overtaking_trajectory: new_float:= 0.0;
      destination: trajectory_to_follow;
      backup_corsia_to_go: Natural;
   end record;

   type destination_tratto is tagged record
      to_id_quartiere: Positive;
      to_place: tratto;
      updated: Boolean:= False;
   end record;

   type tratto_updated is tagged record
      pezzo: tratto;
      updated: Boolean:= False;
   end record;

   type linea_bus is tagged record
      from_id_quartiere: Positive;
      to_id_quartiere: Positive;
      linea: access tratti_fermata;
      jolly: access destination_tratti;
   end record;

end strade_e_incroci_common;
