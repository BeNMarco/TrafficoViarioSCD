
package body strade_e_incroci_common is

   function get_lunghezza_road(road: rt_strada_features) return Float is
   begin
      return road.lunghezza;
   end get_lunghezza_road;
   function get_id_quartiere_road(road: rt_strada_features) return Positive is
   begin
      return road.id_quartiere;
   end get_id_quartiere_road;
   function get_id_road(road: rt_strada_features) return Positive is
   begin
      return road.id;
   end get_id_road;

   function get_id_main_strada_ingresso(road: strada_ingresso_features) return Positive is
   begin
      return road.id_main_strada;
   end get_id_main_strada_ingresso;

   function get_distance_from_road_head_ingresso(road: strada_ingresso_features) return Float is
   begin
      return road.distance_from_road_head;
   end get_distance_from_road_head_ingresso;

   function get_polo_ingresso(road: strada_ingresso_features) return Boolean is
   begin
      return road.polo;
   end get_polo_ingresso;

      -- begin get methods
   function get_id_quartiere_road_incrocio(road: road_incrocio_features) return Positive is
   begin
      return road.id_quartiere;
   end get_id_quartiere_road_incrocio;
   function get_id_strada_road_incrocio(road: road_incrocio_features) return Positive is
   begin
      return road.id_strada;
   end get_id_strada_road_incrocio;
   function get_polo_road_incrocio(road: road_incrocio_features) return Boolean is
   begin
      return road.polo;
   end get_polo_road_incrocio;
   function get_id_quartiere_tratto(segmento: tratto) return Natural is
   begin
      return segmento.id_quartiere;
   end get_id_quartiere_tratto;
   function get_id_tratto(segmento: tratto) return Natural is
   begin
      return segmento.id_tratto;
   end get_id_tratto;
   function get_percorso_from_route_and_distance(route: route_and_distance) return percorso is
   begin
      return route.route;
   end get_percorso_from_route_and_distance;
   function get_distance_from_route_and_distance(route: route_and_distance) return Float is
   begin
      return route.distance_from_start;
   end get_distance_from_route_and_distance;
   function get_id_abitante_entità_passiva(obj: move_parameters) return Positive is
   begin
      return obj.id_abitante;
   end get_id_abitante_entità_passiva;
   function get_id_quartiere_abitante_entità_passiva(obj: move_parameters) return Positive is
   begin
      return obj.id_quartiere;
   end get_id_quartiere_abitante_entità_passiva;
   function get_desired_velocity(obj: move_parameters) return Float is
   begin
      return obj.desired_velocity;
   end get_desired_velocity;
   function get_time_headway(obj: move_parameters) return Float is
   begin
      return obj.time_headway;
   end get_time_headway;
   function get_max_acceleration(obj: move_parameters) return Float is
   begin
      return obj.max_acceleration;
   end get_max_acceleration;
   function get_comfortable_deceleration(obj: move_parameters) return Float is
   begin
      return obj.comfortable_deceleration;
   end get_comfortable_deceleration;
   function get_s0(obj: move_parameters) return Float is
   begin
      return obj.s0;
   end get_s0;
   function get_length_entità_passiva(obj: move_parameters) return Float is
   begin
      return obj.length;
   end get_length_entità_passiva;
   function get_id_abitante_from_abitante(residente: abitante) return Natural is
   begin
      return residente.id_abitante;
   end get_id_abitante_from_abitante;
   function get_id_quartiere_from_abitante(residente: abitante) return Natural is
   begin
      return residente.id_quartiere;
   end get_id_quartiere_from_abitante;
   function get_id_luogo_casa_from_abitante(residente: abitante) return Natural is
   begin
      return residente.id_luogo_casa;
   end get_id_luogo_casa_from_abitante;
   function get_id_quartiere_luogo_lavoro_from_abitante(residente: abitante) return Natural is
   begin
      return residente.id_quartiere_luogo_lavoro;
   end get_id_quartiere_luogo_lavoro_from_abitante;
   function get_id_luogo_lavoro_from_abitante(residente: abitante) return Natural is
   begin
      return residente.id_luogo_lavoro;
   end get_id_luogo_lavoro_from_abitante;
   -- end get methods

   function create_new_road_incrocio(val_id_quartiere: Positive;val_id_strada: Positive;val_polo: Boolean)
                                     return road_incrocio_features is
      road_incrocio: road_incrocio_features;
   begin
      road_incrocio.id_quartiere:= val_id_quartiere;
      road_incrocio.id_strada:= val_id_strada;
      road_incrocio.polo:= val_polo;
      return road_incrocio;
   end create_new_road_incrocio;

   function create_new_urbana(val_tipo: type_strade;val_id: Positive;val_id_quartiere: Positive;
                              val_lunghezza: Float;val_num_corsie: Positive) return strada_urbana_features is
      ptr_strada: strada_urbana_features;
   begin
      ptr_strada.id:= val_id;
      ptr_strada.tipo:= val_tipo;
      ptr_strada.id_quartiere:= val_id_quartiere;
      ptr_strada.lunghezza:= val_lunghezza;
      ptr_strada.num_corsie:= val_num_corsie;
      return ptr_strada;
   end create_new_urbana;

   function create_new_ingresso(val_tipo: type_strade;val_id: Positive;val_id_quartiere: Positive;
                                val_lunghezza: Float;val_num_corsie: Positive;val_id_main_strada: Positive;
                                val_distance_from_road_head: Float; polo: Boolean) return strada_ingresso_features is
      ptr_strada: strada_ingresso_features;
   begin
      ptr_strada.id:= val_id;
      ptr_strada.tipo:= val_tipo;
      ptr_strada.id_quartiere:= val_id_quartiere;
      ptr_strada.lunghezza:= val_lunghezza;
      ptr_strada.num_corsie:= val_num_corsie;
      ptr_strada.id_main_strada:= val_id_main_strada;
      ptr_strada.distance_from_road_head:= val_distance_from_road_head;
      ptr_strada.polo:= polo;
      return ptr_strada;
   end create_new_ingresso;

   function create_tratto(id_quartiere: Natural; id_tratto: Natural) return tratto is
      ptr_tratto: tratto;
   begin
      ptr_tratto.id_quartiere:= id_quartiere;
      ptr_tratto.id_tratto:= id_tratto;
      return ptr_tratto;
   end create_tratto;

   function create_percorso(route: percorso; distance: Float) return route_and_distance is
      ptr_percorso: route_and_distance(route'Length);
   begin
      ptr_percorso.route:= route;
      ptr_percorso.distance_from_start:= distance;
      return ptr_percorso;
   end create_percorso;

   function create_abitante(id_abitante: Natural; id_quartiere: Natural; id_luogo_casa: Natural;
                            id_quartiere_luogo_lavoro: Natural; id_luogo_lavoro: Natural) return abitante is
      ptr_abitante: abitante;
   begin
      ptr_abitante.id_abitante:= id_abitante;
      ptr_abitante.id_quartiere:= id_quartiere;
      ptr_abitante.id_luogo_casa:= id_luogo_casa;
      ptr_abitante.id_quartiere_luogo_lavoro:= id_quartiere_luogo_lavoro;
      ptr_abitante.id_luogo_lavoro:= id_luogo_lavoro;
      return ptr_abitante;
   end create_abitante;

   function create_pedone(id_abitante: Natural; id_quartiere: Natural:= 0; desired_velocity: Float;
                          time_headway: Float; max_acceleration: Float; comfortable_deceleration: Float;
                          s0: Float; length: Float) return pedone is
      ptr_pedone: pedone;
   begin
      ptr_pedone.id_abitante:= id_abitante;
      ptr_pedone.id_quartiere:= id_quartiere;
      ptr_pedone.desired_velocity:= desired_velocity;
      ptr_pedone.time_headway:= time_headway;
      ptr_pedone.max_acceleration:= max_acceleration;
      ptr_pedone.comfortable_deceleration:= comfortable_deceleration;
      ptr_pedone.s0:= s0;
      ptr_pedone.length:= length;
      return ptr_pedone;
   end create_pedone;

   function create_bici(id_abitante: Natural; id_quartiere: Natural:= 0; desired_velocity: Float;
                        time_headway: Float; max_acceleration: Float; comfortable_deceleration: Float;
                        s0: Float; length: Float) return bici is
      ptr_bici: bici;
   begin
      ptr_bici.id_abitante:= id_abitante;
      ptr_bici.id_quartiere:= id_quartiere;
      ptr_bici.desired_velocity:= desired_velocity;
      ptr_bici.time_headway:= time_headway;
      ptr_bici.max_acceleration:= max_acceleration;
      ptr_bici.comfortable_deceleration:= comfortable_deceleration;
      ptr_bici.s0:= s0;
      ptr_bici.length:= length;
      return ptr_bici;
   end create_bici;

   function create_auto(id_abitante: Natural; id_quartiere: Natural:= 0; desired_velocity: Float;
                        time_headway: Float; max_acceleration: Float; comfortable_deceleration: Float;
                        s0: Float; length: Float; num_posti: Positive) return auto is
      ptr_auto: auto;
   begin
      ptr_auto.id_abitante:= id_abitante;
      ptr_auto.id_quartiere:= id_quartiere;
      ptr_auto.desired_velocity:= desired_velocity;
      ptr_auto.time_headway:= time_headway;
      ptr_auto.max_acceleration:= max_acceleration;
      ptr_auto.comfortable_deceleration:= comfortable_deceleration;
      ptr_auto.s0:= s0;
      ptr_auto.length:= length;
      ptr_auto.num_posti:= num_posti;
      return ptr_auto;
   end create_auto;

   function create_estremo_urbana(id_quartiere: Natural; id_incrocio: Natural; polo: Boolean) return estremo_urbana is
      estremo: estremo_urbana;
   begin
      estremo.id_quartiere:= id_quartiere;
      estremo.id_incrocio:= id_incrocio;
      estremo.polo:= polo;
      return estremo;
   end create_estremo_urbana;

   function get_id_quartiere_estremo_urbana(obj: estremo_urbana) return Natural is
   begin
      return obj.id_quartiere;
   end get_id_quartiere_estremo_urbana;
   function get_id_incrocio_estremo_urbana(obj: estremo_urbana) return Natural is
   begin
      return obj.id_incrocio;
   end get_id_incrocio_estremo_urbana;
   function get_polo_estremo_urbana(obj: estremo_urbana) return Boolean is
   begin
      return obj.polo;
   end get_polo_estremo_urbana;

end strade_e_incroci_common;
