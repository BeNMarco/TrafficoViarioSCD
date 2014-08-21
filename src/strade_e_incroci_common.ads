
package strade_e_incroci_common is
   pragma Pure;

   type type_strade is (urbana,ingresso);

   type rt_strada_features is abstract tagged private;
   function get_lunghezza_road(road: rt_strada_features) return Natural;
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

   type abitante is tagged private;
   type move_parameters is tagged private;

   function get_length_entità_passiva(obj: move_parameters) return Float;

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

   type means_of_carrying is (walking, bike, car, autobus);
   type stato_percorso is tagged private;

   type estremo_urbana is tagged private;
   type estremi_urbana is array(Positive range 1..2) of estremo_urbana;

   function create_new_road_incrocio(val_id_quartiere: Positive;val_id_strada: Positive;val_polo: Boolean)
                                     return road_incrocio_features;

   function create_new_urbana(val_tipo: type_strade;val_id: Positive;val_id_quartiere: Positive;
                              val_lunghezza: Natural;val_num_corsie: Positive) return strada_urbana_features;

   function create_new_ingresso(val_tipo: type_strade;val_id: Positive;val_id_quartiere: Positive;
                                val_lunghezza: Natural;val_num_corsie: Positive;val_id_main_strada: Positive;
                                val_distance_from_road_head: Natural) return strada_ingresso_features;

   function create_tratto(id_quartiere: Positive; id_tratto: Positive) return tratto;

   function create_percorso(route: percorso; distance: Natural) return route_and_distance;

   function create_abitante(id_abitante: Natural; id_quartiere: Natural; id_luogo_casa: Natural;
                            id_quartiere_luogo_lavoro: Natural; id_luogo_lavoro: Natural) return abitante;

   function create_pedone(id_abitante: Natural; id_quartiere: Natural:= 0; desired_velocity: Float;
                          time_headway: Float; max_acceleration: Float; comfortable_deceleration: Float;
                          s0: Float; length: Float) return pedone;

   function create_bici(id_abitante: Natural; id_quartiere: Natural:= 0; desired_velocity: Float;
                        time_headway: Float; max_acceleration: Float; comfortable_deceleration: Float;
                        s0: Float; length: Float) return bici;

   function create_auto(id_abitante: Natural; id_quartiere: Natural:= 0; desired_velocity: Float;
                        time_headway: Float; max_acceleration: Float; comfortable_deceleration: Float;
                        s0: Float; length: Float; num_posti: Positive) return auto;

   function create_estremo_urbana(id_quartiere: Natural; id_incrocio: Natural) return estremo_urbana;

   function get_id_quartiere_estremo_urbana(obj: estremo_urbana) return Natural;
   function get_id_incrocio_estremo_urbana(obj: estremo_urbana) return Natural;

   function get_id_main_strada_ingresso(road: strada_ingresso_features) return Positive;
   function get_distance_from_road_head_ingresso(road: strada_ingresso_features) return Natural;

   -- begin get methods road_incrocio_features
   function get_id_quartiere_road_incrocio(road: road_incrocio_features) return Positive;
   function get_id_strada_road_incrocio(road: road_incrocio_features) return Positive;
   function get_polo_road_incrocio(road: road_incrocio_features) return Boolean;
   -- end get methods road_incrocio_features

   function get_id_quartiere_tratto(segmento: tratto) return Positive;
   function get_id_tratto(segmento: tratto) return Positive;

   function get_percorso_from_route_and_distance(route: route_and_distance) return percorso;
   function get_distance_from_route_and_distance(route: route_and_distance) return Natural;

private

   type estremo_urbana is tagged record
      id_quartiere: Natural;
      id_incrocio: Natural;
   end record;

   type rt_strada_features is tagged record
      tipo: type_strade;
      id: Positive;  -- id strada coincide con id della sua risorsa protetta
      id_quartiere: Positive;
      lunghezza: Natural;
      num_corsie: Positive;
   end record;

   type strada_urbana_features is new rt_strada_features with null record;

   type strada_ingresso_features is new rt_strada_features with record
      id_main_strada : Positive; 	-- strada principale dalla quale si ha la strada d'ingresso
      					-- si tratta sempre di una strada locale e non remota
      distance_from_road_head : Natural; -- distanza dalle coordinate from della strada principale
   end record;

   type road_incrocio_features is tagged record
      id_quartiere: Positive;
      id_strada: Positive;
      polo: Boolean;
   end record;

   type tratto is tagged record
      id_quartiere: Positive;
      id_tratto: Positive;
   end record;

   type route_and_distance(size_percorso:Natural) is tagged record
      route: percorso(1..size_percorso);
      distance_from_start: Natural;
   end record;

   type stato_percorso is tagged record
      percorso: access route_and_distance:= null; -- percorso che deve svolgere, null se si trova su un luogo
      move_by: means_of_carrying:=  walking;
   end record;

   type abitante is tagged record
      id_abitante: Natural:= 0;
      id_quartiere: Natural:= 0;
      id_luogo_casa: Natural:= 0; -- il quartiere della casa coincide con id_quartiere
      id_quaritere_luogo_lavoro: Natural:= 0;
      id_luogo_lavoro: Natural:= 0;
   end record;

   type move_parameters is tagged record
      id_abitante: Natural:= 0;
      id_quartiere: Natural:= 0;
      desired_velocity: Float; -- m/s
      time_headway: Float; -- s
      max_acceleration: Float; -- m/s^2
      comfortable_deceleration: Float; -- m/s^2
      s0: Float;
      length: Float;
   end record;

   type pedone is new move_parameters with null record;

   type bici is new move_parameters with null record;

   type auto is new move_parameters with record
      num_posti: Positive;
   end record;

end strade_e_incroci_common;
