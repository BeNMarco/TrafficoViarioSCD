
package body strade_e_incroci_common is

   function to_string_incroci_type(obj: traiettoria_incroci_type) return String is
   begin
      case obj is
         when empty =>
            return "empty";
         when destra =>
            return "destra";
         when sinistra =>
            return "sinistra";
         when dritto_1 =>
            return "dritto_1";
         when dritto_2 =>
            return "dritto_2";
         when destra_pedoni =>
            return "destra_pedoni";
         when dritto_pedoni =>
            return "dritto_pedoni";
         when sinistra_pedoni =>
            return "sinistra_pedoni";
         when destra_bici =>
            return "destra_bici";
         when dritto_bici =>
            return "dritto_bici";
         when sinistra_bici =>
            return "sinistra_bici";
         end case;
   end to_string_incroci_type;

   function to_string_ingressi_type(obj: traiettoria_ingressi_type) return String is
   begin
      case obj is
         when empty =>
            return "empty";
         when entrata_andata =>
            return "entrata_andata";
         when uscita_andata =>
            return "uscita_andata";
         when entrata_ritorno =>
            return "entrata_ritorno";
         when uscita_ritorno =>
            return "uscita_ritorno";

         when uscita_destra_pedoni =>
            return "uscita_destra_pedoni";
         when uscita_dritto_pedoni =>
            return "uscita_dritto_pedoni";
         when uscita_destra_bici =>
            return "uscita_destra_bici";
         when uscita_dritto_bici =>
            return "uscita_dritto_bici";
         when uscita_ritorno_pedoni =>
            return "uscita_ritorno_pedoni";
         when uscita_ritorno_bici =>
            return "uscita_ritorno_bici";
         when entrata_destra_pedoni =>
            return "entrata_destra_pedoni";
         when entrata_destra_bici =>
            return "entrata_destra_bici";
         when entrata_ritorno_pedoni =>
            return "entrata_ritorno_pedoni";
         when entrata_ritorno_bici =>
            return "entrata_ritorno_bici";
         when entrata_dritto_pedoni =>
            return "entrata_dritto_pedoni";
         when entrata_dritto_bici =>
            return "entrata_dritto_bici";
      end case;
   end to_string_ingressi_type;

   function convert_to_traiettoria_incroci(obj: String) return traiettoria_incroci_type is
   begin
      if obj="destra" then
         return destra;
      elsif obj="sinistra" then
         return sinistra;
      elsif obj="dritto_1" then
         return dritto_1;
      elsif obj="dritto_2" then
         return dritto_2;
      elsif obj="destra_pedoni" then
         return destra_pedoni;
      elsif obj="dritto_pedoni" then
         return dritto_pedoni;
      elsif obj="sinistra_pedoni" then
         return sinistra_pedoni;
      elsif obj="destra_bici" then
         return destra_bici;
      elsif obj="dritto_bici" then
         return dritto_bici;
      elsif obj="sinistra_bici" then
         return sinistra_bici;
      end if;
      return empty;
   end convert_to_traiettoria_incroci;

   function convert_string_to_type_ingresso(tipo: String) return type_ingresso is
   begin
      if tipo="fermata" then
         return fermata;
      else
         return abitato;
      end if;
   end convert_string_to_type_ingresso;

   function get_lunghezza_road(road: rt_strada_features) return new_float is
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

   function get_distance_from_road_head_ingresso(road: strada_ingresso_features) return new_float is
   begin
      return road.distance_from_road_head;
   end get_distance_from_road_head_ingresso;

   function get_polo_ingresso(road: strada_ingresso_features) return Boolean is
   begin
      return road.polo;
   end get_polo_ingresso;

   function get_type_ingresso(road: strada_ingresso_features) return type_ingresso is
   begin
      return road.tipo_ingresso;
   end get_type_ingresso;
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
   function get_distance_from_route_and_distance(route: route_and_distance) return new_float is
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
   function get_desired_velocity(obj: move_parameters) return new_float is
   begin
      return obj.desired_velocity;
   end get_desired_velocity;
   function get_time_headway(obj: move_parameters) return new_float is
   begin
      return obj.time_headway;
   end get_time_headway;
   function get_max_acceleration(obj: move_parameters) return new_float is
   begin
      return obj.max_acceleration;
   end get_max_acceleration;
   function get_comfortable_deceleration(obj: move_parameters) return new_float is
   begin
      return obj.comfortable_deceleration;
   end get_comfortable_deceleration;
   function get_s0(obj: move_parameters) return new_float is
   begin
      return obj.s0;
   end get_s0;
   function get_length_entità_passiva(obj: move_parameters) return new_float is
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
   function get_mezzo_abitante(residente: abitante) return means_of_carrying is
   begin
      return residente.mezzo;
   end get_mezzo_abitante;
   function is_a_bus(residente: abitante) return Boolean is
   begin
      return residente.bus;
   end is_a_bus;
   function is_a_bus_jolly(residente: abitante) return Boolean is
   begin
      return residente.jolly;
   end is_a_bus_jolly;
   function is_a_jolly_to_quartiere(residente: abitante) return Natural is
   begin
      return residente.jolly_to_quartiere;
   end is_a_jolly_to_quartiere;
   -- end get methods
   procedure set_mezzo_abitante(residente: in out abitante; mezzo: means_of_carrying) is
   begin
      residente.mezzo:= mezzo;
   end set_mezzo_abitante;

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
                              val_lunghezza: new_float;val_num_corsie: Positive) return strada_urbana_features is
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
                                val_lunghezza: new_float;val_num_corsie: Positive;val_id_main_strada: Positive;
                                val_distance_from_road_head: new_float; polo: Boolean; val_tipo_ingresso: type_ingresso) return strada_ingresso_features is
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
      ptr_strada.tipo_ingresso:= val_tipo_ingresso;
      return ptr_strada;
   end create_new_ingresso;

   function create_tratto(id_quartiere: Natural; id_tratto: Natural) return tratto is
      ptr_tratto: tratto;
   begin
      ptr_tratto.id_quartiere:= id_quartiere;
      ptr_tratto.id_tratto:= id_tratto;
      return ptr_tratto;
   end create_tratto;

   function create_percorso(route: percorso; distance: new_float) return route_and_distance is
      ptr_percorso: route_and_distance(route'Length);
   begin
      ptr_percorso.route:= route;
      ptr_percorso.distance_from_start:= distance;
      return ptr_percorso;
   end create_percorso;

   function create_abitante(id_abitante: Natural; id_quartiere: Natural; id_luogo_casa: Natural;
                            id_quartiere_luogo_lavoro: Natural; id_luogo_lavoro: Natural; mezzo: means_of_carrying; is_a_bus: Boolean; jolly: Boolean; jolly_to_quartiere: Natural) return abitante is
      ptr_abitante: abitante;
   begin
      ptr_abitante.id_abitante:= id_abitante;
      ptr_abitante.id_quartiere:= id_quartiere;
      ptr_abitante.id_luogo_casa:= id_luogo_casa;
      ptr_abitante.id_quartiere_luogo_lavoro:= id_quartiere_luogo_lavoro;
      ptr_abitante.id_luogo_lavoro:= id_luogo_lavoro;
      ptr_abitante.mezzo:= mezzo;
      ptr_abitante.bus:= is_a_bus;
      ptr_abitante.jolly:= jolly;
      ptr_abitante.jolly_to_quartiere:= jolly_to_quartiere;
      return ptr_abitante;
   end create_abitante;

   function create_pedone(id_abitante: Natural; id_quartiere: Natural:= 0; desired_velocity: Float;
                          time_headway: Float; max_acceleration: Float; comfortable_deceleration: Float;
                          s0: Float; length: Float) return pedone is
      ptr_pedone: pedone;
   begin
      ptr_pedone.id_abitante:= id_abitante;
      ptr_pedone.id_quartiere:= id_quartiere;
      ptr_pedone.desired_velocity:= new_float(desired_velocity);
      ptr_pedone.time_headway:= new_float(time_headway);
      ptr_pedone.max_acceleration:= new_float(max_acceleration);
      ptr_pedone.comfortable_deceleration:= new_float(comfortable_deceleration);
      ptr_pedone.s0:= new_float(s0);
      ptr_pedone.length:= new_float(length);
      return ptr_pedone;
   end create_pedone;

   function create_bici(id_abitante: Natural; id_quartiere: Natural:= 0; desired_velocity: Float;
                        time_headway: Float; max_acceleration: Float; comfortable_deceleration: Float;
                        s0: Float; length: Float) return bici is
      ptr_bici: bici;
   begin
      ptr_bici.id_abitante:= id_abitante;
      ptr_bici.id_quartiere:= id_quartiere;
      ptr_bici.desired_velocity:= new_float(desired_velocity);
      ptr_bici.time_headway:= new_float(time_headway);
      ptr_bici.max_acceleration:= new_float(max_acceleration);
      ptr_bici.comfortable_deceleration:= new_float(comfortable_deceleration);
      ptr_bici.s0:= new_float(s0);
      ptr_bici.length:= new_float(length);
      return ptr_bici;
   end create_bici;

   function create_auto(id_abitante: Natural; id_quartiere: Natural:= 0; desired_velocity: Float;
                        time_headway: Float; max_acceleration: Float; comfortable_deceleration: Float;
                        s0: Float; length: Float; num_posti: Positive) return auto is
      ptr_auto: auto;
   begin
      ptr_auto.id_abitante:= id_abitante;
      ptr_auto.id_quartiere:= id_quartiere;
      ptr_auto.desired_velocity:= new_float(desired_velocity);
      ptr_auto.time_headway:= new_float(time_headway);
      ptr_auto.max_acceleration:= new_float(max_acceleration);
      ptr_auto.comfortable_deceleration:= new_float(comfortable_deceleration);
      ptr_auto.s0:= new_float(s0);
      ptr_auto.length:= new_float(length);
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

   function get_departure_corsia(obj: trajectory_to_follow) return Natural is
   begin
      return obj.departure_corsia;
   end get_departure_corsia;
   function get_corsia_to_go_trajectory(obj: trajectory_to_follow) return Natural is
   begin
      return obj.corsia_to_go;
   end get_corsia_to_go_trajectory;
   function get_ingresso_to_go_trajectory(obj: trajectory_to_follow) return Natural is
   begin
      return obj.ingresso_to_go;
   end get_ingresso_to_go_trajectory;
   function get_traiettoria_incrocio_to_follow(obj: trajectory_to_follow) return traiettoria_incroci_type is
   begin
      return obj.traiettoria_incrocio_to_follow;
   end get_traiettoria_incrocio_to_follow;
   function get_from_ingresso(obj: trajectory_to_follow) return Natural is
   begin
      return obj.from_ingresso;
   end get_from_ingresso;

   function get_id_abitante_posizione_abitanti(obj: posizione_abitanti_on_road) return Natural is
   begin
      return obj.id_abitante;
   end get_id_abitante_posizione_abitanti;
   function get_id_quartiere_posizione_abitanti(obj: posizione_abitanti_on_road) return Natural is
   begin
      return obj.id_quartiere;
   end get_id_quartiere_posizione_abitanti;
   function get_where_next_posizione_abitanti(obj: posizione_abitanti_on_road) return new_float is
   begin
      return obj.where_next;
   end get_where_next_posizione_abitanti;
   function get_where_now_posizione_abitanti(obj: posizione_abitanti_on_road) return new_float is
   begin
      return obj.where_now;
   end get_where_now_posizione_abitanti;
   function get_current_speed_abitante(obj: posizione_abitanti_on_road) return new_float is
   begin
      return obj.current_speed;
   end get_current_speed_abitante;
   function get_in_overtaken(obj: posizione_abitanti_on_road) return Boolean is
   begin
      return obj.in_overtaken;
   end get_in_overtaken;
   function get_distance_on_overtaking_trajectory(obj: posizione_abitanti_on_road) return new_float is
   begin
      return obj.distance_on_overtaking_trajectory;
   end get_distance_on_overtaking_trajectory;
    function get_destination(obj: posizione_abitanti_on_road) return trajectory_to_follow'Class is
   begin
      return obj.destination;
   end get_destination;
   function get_flag_overtake_next_corsia(obj: posizione_abitanti_on_road) return Boolean is
   begin
      return obj.can_pass_corsia;
   end get_flag_overtake_next_corsia;
   function get_came_from_ingresso(obj: posizione_abitanti_on_road) return Boolean is
   begin
      return obj.came_from_ingresso;
   end get_came_from_ingresso;
   function get_backup_corsia_to_go(obj: posizione_abitanti_on_road) return Natural is
   begin
      return obj.backup_corsia_to_go;
   end get_backup_corsia_to_go;

   procedure set_where_next_abitante(obj: in out posizione_abitanti_on_road; where_next: new_float) is
   begin
      obj.where_next:= where_next;
   end set_where_next_abitante;
   procedure set_where_now_abitante(obj: in out posizione_abitanti_on_road; where_now: new_float) is
   begin
      obj.where_now:= where_now;
   end set_where_now_abitante;
   procedure set_current_speed_abitante(obj: in out posizione_abitanti_on_road; speed: new_float) is
   begin
      obj.current_speed:= speed;
   end set_current_speed_abitante;
   procedure set_in_overtaken(obj: in out posizione_abitanti_on_road; in_overtaken: Boolean) is
   begin
      obj.in_overtaken:= in_overtaken;
   end set_in_overtaken;
   procedure set_distance_on_overtaking_trajectory(obj: in out posizione_abitanti_on_road; distance: new_float) is
   begin
      obj.distance_on_overtaking_trajectory:= distance;
   end set_distance_on_overtaking_trajectory;
   procedure set_destination(obj: in out posizione_abitanti_on_road; traiettoria: trajectory_to_follow'Class) is
   begin
      obj.destination:= trajectory_to_follow(traiettoria);
   end set_destination;
   procedure set_flag_overtake_next_corsia(obj: in out posizione_abitanti_on_road; flag: Boolean) is
   begin
      obj.can_pass_corsia:= flag;
   end set_flag_overtake_next_corsia;
   procedure set_came_from_ingresso(obj: in out posizione_abitanti_on_road; flag: Boolean) is
   begin
      obj.came_from_ingresso:= flag;
   end set_came_from_ingresso;
   procedure set_backup_corsia_to_go(obj: in out posizione_abitanti_on_road; num_corsia: Natural) is
   begin
      obj.backup_corsia_to_go:= num_corsia;
   end set_backup_corsia_to_go;

   function create_trajectory_to_follow(from_corsia: Natural; corsia_to_go: Natural; ingresso_to_go: Natural; from_ingresso: Natural; traiettoria_incrocio_to_follow: traiettoria_incroci_type) return trajectory_to_follow is
      traiettoria: trajectory_to_follow;
   begin
      traiettoria.departure_corsia:= from_corsia;
      traiettoria.corsia_to_go:= corsia_to_go;
      traiettoria.ingresso_to_go:= ingresso_to_go;
      traiettoria.from_ingresso:= from_ingresso;
      traiettoria.traiettoria_incrocio_to_follow:= traiettoria_incrocio_to_follow;
      return traiettoria;
   end create_trajectory_to_follow;

   function create_new_posizione_abitante(id_abitante: Positive; id_quartiere: Positive; where_next: new_float;
                                          where_now: new_float; current_speed: new_float; in_overtaken: Boolean;
                                          can_pass_corsia: Boolean; distance_on_overtaking_trajectory: new_float;
                                          came_from_ingresso: Boolean; destination: trajectory_to_follow; backup_corsia_to_go: Natural) return posizione_abitanti_on_road'Class is
      abitante: posizione_abitanti_on_road;
   begin
      abitante.id_abitante:= id_abitante;
      abitante.id_quartiere:= id_quartiere;
      abitante.where_next:= where_next;
      abitante.where_now:= where_now;
      abitante.current_speed:= current_speed;
      abitante.in_overtaken:= in_overtaken;
      abitante.came_from_ingresso:= came_from_ingresso;
      abitante.can_pass_corsia:= can_pass_corsia;
      abitante.distance_on_overtaking_trajectory:= distance_on_overtaking_trajectory;
      abitante.destination:= destination;
      abitante.backup_corsia_to_go:= backup_corsia_to_go;
      return abitante;
   end create_new_posizione_abitante;

   function create_new_posizione_abitante_from_copy(posizione_abitante: posizione_abitanti_on_road) return posizione_abitanti_on_road is
      abitante: posizione_abitanti_on_road;
   begin
      abitante.id_abitante:= posizione_abitante.id_abitante;
      abitante.id_quartiere:= posizione_abitante.id_quartiere;
      abitante.where_next:= posizione_abitante.where_next;
      abitante.where_now:= posizione_abitante.where_now;
      abitante.current_speed:= posizione_abitante.current_speed;
      abitante.in_overtaken:= posizione_abitante.in_overtaken;
      abitante.can_pass_corsia:= posizione_abitante.can_pass_corsia;
      abitante.came_from_ingresso:= posizione_abitante.came_from_ingresso;
      abitante.distance_on_overtaking_trajectory:= posizione_abitante.distance_on_overtaking_trajectory;
      abitante.destination:= posizione_abitante.destination;
      abitante.backup_corsia_to_go:= posizione_abitante.backup_corsia_to_go;
      return abitante;
   end create_new_posizione_abitante_from_copy;

   function convert_string_to_resource_type(tipo_risorsa: String) return resource_type is
   begin
      if tipo_risorsa="ingresso" then
         return ingresso;
      elsif tipo_risorsa="urbana" then
         return urbana;
      elsif tipo_risorsa="incrocio" then
         return incrocio;
      end if;
      raise error_in_conversione_da_stringa;
   end convert_string_to_resource_type;

   function create_destination(to_id_quartiere: Positive; to_place: tratto'Class) return destination_tratto is
      ptr_destination: destination_tratto;
   begin
      ptr_destination.to_id_quartiere:= to_id_quartiere;
      ptr_destination.to_place:= tratto(to_place);
      return ptr_destination;
   end create_destination;

   function get_quartiere_jolly_to_go(obj: destination_tratto) return Positive is
   begin
      return obj.to_id_quartiere;
   end get_quartiere_jolly_to_go;
   function get_tratto_jolly_to_go(obj: destination_tratto) return tratto'Class is
   begin
      return obj.to_place;
   end get_tratto_jolly_to_go;

   function create_linea_bus(from_id_quartiere: Positive; to_id_quartiere: Positive; linea: access tratti_fermata; jolly: access destination_tratti) return linea_bus is
      ptr_linea: linea_bus;
   begin
      ptr_linea.from_id_quartiere:= from_id_quartiere;
      ptr_linea.to_id_quartiere:= to_id_quartiere;
      ptr_linea.linea:= linea;
      ptr_linea.jolly:= jolly;
      return ptr_linea;
   end create_linea_bus;

   function get_numero_fermate(obj: linea_bus) return Natural is
   begin
      return obj.linea.all'Last;
   end get_numero_fermate;

   function get_num_tratto(obj: linea_bus; num_tratto: Positive) return tratto'Class is
   begin
      if num_tratto<=obj.linea.all'Last then
         return obj.linea(num_tratto);
      else
         return create_tratto(0,0);
      end if;
   end get_num_tratto;

   function get_jolly_quartiere_to_go(obj: linea_bus; num_jolly_quartiere_to_go: Positive) return tratto'Class is
   begin
      for i in obj.jolly.all'Range loop
         if obj.jolly(i).get_quartiere_jolly_to_go=num_jolly_quartiere_to_go then
            return obj.jolly(i).get_tratto_jolly_to_go;
         end if;
      end loop;
      return create_tratto(0,0);
   end get_jolly_quartiere_to_go;

end strade_e_incroci_common;
