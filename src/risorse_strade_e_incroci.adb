with Ada.Text_IO;
with Ada.Numerics.Elementary_Functions;
--with Ada.Task_Identification;
--with Ada.Dynamic_Priorities;
--with System;

with strade_e_incroci_common;
with remote_types;
with resource_map_inventory;
with risorse_mappa_utilities;
with the_name_server;
with mailbox_risorse_attive;
with synchronization_task_partition;
with risorse_passive_data;
with data_quartiere;

use Ada.Text_IO;
use Ada.Numerics.Elementary_Functions;
--use Ada.Task_Identification;
--use Ada.Dynamic_Priorities;
--use System;

use strade_e_incroci_common;
use remote_types;
use resource_map_inventory;
use risorse_mappa_utilities;
use the_name_server;
use mailbox_risorse_attive;
use synchronization_task_partition;
use risorse_passive_data;
use data_quartiere;

package body risorse_strade_e_incroci is

   function calculate_acceleration(mezzo: means_of_carrying; id_abitante: Positive; id_quartiere_abitante: Positive; next_entity_distance: Float; distance_to_stop_line: Float; next_id_quartiere_abitante: Natural; next_id_abitante: Natural; abitante_velocity: Float; next_abitante_velocity: Float) return Float is
      residente: move_parameters;
      delta_speed: Float:= 0.0;
      free_road_coeff: Float;
      time_gap: Float;
      break_gap: Float;
      safe_distance: Float;
      busy_road_coeff: Float;
      safe_intersection_distance: Float;
      intersection_coeff: Float;
      coeff: Float;
   begin
      case mezzo is
         when walking | autobus =>
            residente:= move_parameters(get_quartiere_utilities_obj.all.get_pedone_quartiere(id_quartiere_abitante,id_abitante));
         when bike =>
            residente:= move_parameters(get_quartiere_utilities_obj.all.get_bici_quartiere(id_quartiere_abitante,id_abitante));
         when car =>
            residente:= move_parameters(get_quartiere_utilities_obj.all.get_auto_quartiere(id_quartiere_abitante,id_abitante));
      end case;
      if next_id_quartiere_abitante/=0 then
         delta_speed:= abitante_velocity-next_abitante_velocity;
      else
         delta_speed:= abitante_velocity;
      end if;
      free_road_coeff:= (abitante_velocity/residente.get_desired_velocity)**4;
      time_gap:= abitante_velocity*residente.get_time_headway;
      break_gap:= abitante_velocity*delta_speed/(2.0 * Sqrt(residente.get_max_acceleration*residente.get_comfortable_deceleration));
      safe_distance:= residente.get_s0 + time_gap + break_gap;
      if next_entity_distance=0.0 then
         busy_road_coeff:= 0.0;
      else
         busy_road_coeff:= (safe_distance/next_entity_distance)**2;
      end if;

      -- begin parameters not in the IDM models:
      safe_intersection_distance:= 1.0 + time_gap + (abitante_velocity**2)/(2.0*residente.get_comfortable_deceleration);
      intersection_coeff:= (safe_intersection_distance/distance_to_stop_line)**2;
      -- end parameters

      coeff:= 1.0 - free_road_coeff - busy_road_coeff - intersection_coeff;
      return residente.get_max_acceleration*coeff;
   end calculate_acceleration;

   function calculate_new_speed(current_speed: Float; acceleration: Float) return Float is
   begin
      return current_speed + acceleration * delta_value;
   end calculate_new_speed;

   function calculate_new_step(new_speed: Float; acceleration: Float) return Float is
   begin
      return new_speed * delta_value + 0.5 * acceleration * delta_value**2;
   end calculate_new_step;

   function calculate_trajectory_to_follow_on_main_strada_from_ingresso(id_quartiere_abitante: Positive; id_abitante: Positive; from_ingresso: Positive; traiettoria_type: traiettoria_ingressi_type) return trajectory_to_follow is
      next_nodo: tratto;
      next_road: tratto;
      tipo_entità: entity_type;
      id_road: Positive;
      id_road_mancante: Natural; -- se 0 => allora non ne manca neanche 1 si tratta cioè di 1 incrocio a 4
      index_road_from: Positive;
      index_road_to: Positive;
      corsia_traiettoria: Natural;
      corsia_to_go_if_dritto: Positive;
   begin
      if traiettoria_type=uscita_andata then
         corsia_traiettoria:= 1;
         corsia_to_go_if_dritto:= 2;
      elsif traiettoria_type=uscita_ritorno then
         corsia_traiettoria:= 2;
         corsia_to_go_if_dritto:= 1;
      else
         corsia_traiettoria:= 0;
      end if;
      next_nodo:= get_quartiere_utilities_obj.get_classe_locate_abitanti(id_quartiere_abitante).get_next(id_abitante);
      next_road:= get_quartiere_utilities_obj.get_classe_locate_abitanti(id_quartiere_abitante).get_next_road(id_abitante,True);
      if next_nodo.get_id_quartiere_tratto=get_id_quartiere and then (next_nodo.get_id_tratto>=get_from_ingressi and next_nodo.get_id_tratto<=get_to_ingressi) then -- forse nodo è già l'ingresso di destinazione
         if traiettoria_type=uscita_andata then
            return create_trajectory_to_follow(corsia_traiettoria,1,next_nodo.get_id_tratto,from_ingresso,empty);
         elsif traiettoria_type=uscita_ritorno then
            if get_ingresso_from_id(next_nodo.get_id_tratto).get_polo_ingresso=get_ingresso_from_id(from_ingresso).get_polo_ingresso then
               return create_trajectory_to_follow(corsia_traiettoria,2,next_nodo.get_id_tratto,from_ingresso,empty);
            else
               return create_trajectory_to_follow(corsia_traiettoria,1,next_nodo.get_id_tratto,from_ingresso,empty);
            end if;
         else
            return create_trajectory_to_follow(0,0,0,from_ingresso,empty);  --errore
         end if;
      else
         tipo_entità:= get_quartiere_cfg(next_road.get_id_quartiere_tratto).get_type_entity(next_road.get_id_tratto);
         if tipo_entità=ingresso then
            id_road:= get_quartiere_cfg(next_road.get_id_quartiere_tratto).get_id_main_road_from_id_ingresso(next_road.get_id_tratto);
         else
            id_road:= next_road.get_id_tratto;
         end if;
         -- il quartiere di id_road è sempre next_road.get_id_quartiere_tratto
         get_quartiere_cfg(next_nodo.get_id_quartiere_tratto).get_cfg_incrocio(next_nodo.get_id_tratto,create_tratto(get_ingresso_from_id(from_ingresso).get_id_quartiere_road,get_ingresso_from_id(from_ingresso).get_id_main_strada_ingresso),create_tratto(next_road.get_id_quartiere_tratto,id_road),index_road_from,index_road_to,id_road_mancante);
         -- configurazione incrocio settata
         if id_road_mancante=0 and (index_road_from=0 or index_road_to=0) then
            return create_trajectory_to_follow(0,0,0,from_ingresso,empty);  --errore
         else
            if abs(index_road_from-index_road_to)=2 then
               return create_trajectory_to_follow(corsia_traiettoria,corsia_to_go_if_dritto,0,from_ingresso,dritto);
            elsif index_road_to>index_road_from or (index_road_to=1 and index_road_from=4) then
               return create_trajectory_to_follow(corsia_traiettoria,2,0,from_ingresso,sinistra);
            else
               return create_trajectory_to_follow(corsia_traiettoria,1,0,from_ingresso,destra);
            end if;
         end if;
      end if;
   end calculate_trajectory_to_follow_on_main_strada_from_ingresso;

   function calculate_trajectory_to_follow_on_main_strada_from_incrocio(abitante: posizione_abitanti_on_road; polo: Boolean; num_corsia: id_corsie) return trajectory_to_follow is
      next_nodo: tratto;
      next_incrocio: tratto;
      next_road: tratto;
      index_road_from: Natural;
      index_road_to: Natural;
      id_road_mancante: Natural;
   begin
      -- next_nodo sarà o la strada corrente o un suo ingresso
      next_nodo:= get_quartiere_utilities_obj.get_classe_locate_abitanti(abitante.get_id_quartiere_posizione_abitanti).get_next(abitante.get_id_abitante_posizione_abitanti);
      if get_quartiere_utilities_obj.get_classe_locate_abitanti(abitante.get_id_quartiere_posizione_abitanti).get_number_steps_to_finish_route(abitante.get_id_abitante_posizione_abitanti)=1 then
         -- la macchina deve percorrere l'ultimo pezzo di strada
         if get_quartiere_cfg(next_nodo.get_id_quartiere_tratto).get_polo_ingresso(next_nodo.get_id_tratto)=polo then
            return create_trajectory_to_follow(num_corsia,1,next_nodo.get_id_tratto,0,empty);
         else
            return create_trajectory_to_follow(num_corsia,2,next_nodo.get_id_tratto,0,empty);
         end if;
      else
         -- la macchina deve percorrere tutta la strada
         -- deve percorre ancora almeno 3 entità
         next_incrocio:= get_quartiere_utilities_obj.get_classe_locate_abitanti(abitante.get_id_quartiere_posizione_abitanti).get_next_incrocio(abitante.get_id_abitante_posizione_abitanti);
         next_road:= get_quartiere_utilities_obj.get_classe_locate_abitanti(abitante.get_id_quartiere_posizione_abitanti).get_next_road(abitante.get_id_abitante_posizione_abitanti,False);
         get_quartiere_cfg(next_incrocio.get_id_quartiere_tratto).get_cfg_incrocio(next_incrocio.get_id_tratto,create_tratto(next_nodo.get_id_quartiere_tratto,next_nodo.get_id_tratto),create_tratto(next_road.get_id_quartiere_tratto,next_road.get_id_tratto),index_road_from,index_road_to,id_road_mancante);
         if id_road_mancante=0 and (index_road_from=0 or index_road_to=0) then
            return create_trajectory_to_follow(0,0,0,0,empty);  --errore
         else
            if abs(index_road_from-index_road_to)=2 then
               return create_trajectory_to_follow(0,0,0,0,dritto);
            elsif index_road_to>index_road_from or (index_road_to=1 and index_road_from=4) then
               return create_trajectory_to_follow(num_corsia,2,0,0,sinistra);
            else
               return create_trajectory_to_follow(num_corsia,1,0,0,destra);
            end if;
         end if;
      end if;
   end calculate_trajectory_to_follow_on_main_strada_from_incrocio;

   function calculate_traiettoria_to_follow_from_ingresso(id_quartiere_abitante: Positive; id_abitante: Positive; id_ingresso: Positive; ingressi: indici_ingressi) return traiettoria_ingressi_type is
      nodo: tratto;
      estremi_urbana: estremi_strada_urbana;
      ingresso: strada_ingresso_features:= get_ingresso_from_id(id_ingresso);
      found: Boolean:= False;
      which_found: Boolean:= False; -- False => esiste un ingresso più vicino rispetto a id_ingresso
      i: Positive:= 1;
      estremo: estremo_urbana;
   begin
      estremi_urbana:= get_estremi_urbana(ingresso.get_id_main_strada_ingresso);
      nodo:= get_quartiere_utilities_obj.get_classe_locate_abitanti(id_quartiere_abitante).get_next(id_abitante);
      if (nodo.get_id_tratto=estremi_urbana(1).get_id_incrocio_estremo_urbana and nodo.get_id_quartiere_tratto=estremi_urbana(1).get_id_quartiere_estremo_urbana) or
        (nodo.get_id_tratto=estremi_urbana(2).get_id_incrocio_estremo_urbana and nodo.get_id_quartiere_tratto=estremi_urbana(2).get_id_quartiere_estremo_urbana) then
         if nodo.get_id_tratto=estremi_urbana(1).get_id_incrocio_estremo_urbana and nodo.get_id_quartiere_tratto=estremi_urbana(1).get_id_quartiere_estremo_urbana then
            estremo:= estremi_urbana(1);
         else
            estremo:= estremi_urbana(2);
         end if;
         if estremo.get_polo_estremo_urbana then
            if ingresso.get_polo_ingresso then
               return uscita_andata;
            else
               return uscita_ritorno;
            end if;
         else
            if ingresso.get_polo_ingresso then
               return uscita_ritorno;
            else
               return uscita_andata;
            end if;
         end if;
      else -- l'ingresso si trova sulla medesima strada dell'ingresso di partenza
         while found=False loop
            if ingressi(i)=nodo.get_id_tratto then
               which_found:= False;
               found:= True;
            end if;
            if ingressi(i)=id_ingresso then
               which_found:= True;
               found:= True;
            end if;
            i:= i+1;
         end loop;
         if which_found then -- l'ingresso partenza precede l'ingresso destinazione
            if ingresso.get_polo_ingresso then
               return uscita_ritorno;
            else
               return uscita_andata;
            end if;
         else -- l'ingresso arrivo precede l'ingresso destinazione
            if ingresso.get_polo_ingresso then
               return uscita_andata;
            else
               return uscita_ritorno;
            end if;
         end if;
      end if;
   end calculate_traiettoria_to_follow_from_ingresso;

   -- ritorna una macchina della corsia opposta se ve ne sono in sorpasso prima della macchina successiva alla stessa corsia
   procedure calculate_distance_to_next_car_on_road(car_in_corsia: ptr_list_posizione_abitanti_on_road; next_car: ptr_list_posizione_abitanti_on_road; next_car_in_near_corsia: ptr_list_posizione_abitanti_on_road; from_corsia: id_corsie; next_car_on_road: out ptr_list_posizione_abitanti_on_road; next_car_on_road_distance: out Float) is
      switch: Boolean:= False;
      current_car_in_corsia: ptr_list_posizione_abitanti_on_road:= car_in_corsia;
      next_car_in_opposite_corsia: ptr_list_posizione_abitanti_on_road:= next_car_in_near_corsia;
      next_car_in_corsia: ptr_list_posizione_abitanti_on_road:= next_car;
      corsia_to_go: id_corsie:= car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory;
   begin
      next_car_on_road_distance:= -1.0;
      next_car_on_road:= null;

      if car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken then
         -- la macchina è in sorpasso e non ha ancora attraversato la corsia
         while next_car_in_corsia/=null and then next_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
           get_quartiere_utilities_obj.get_auto_quartiere(next_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                          next_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva
           < car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria loop
            next_car_in_corsia:= next_car_in_corsia.get_next_from_list_posizione_abitanti;
         end loop;

      end if;

      while next_car_on_road_distance=-1.0 and next_car_in_opposite_corsia/=null loop
         switch:= False;
         if next_car_in_corsia=null then  -- non è limitato da macchine della stessa corsia
            switch:= True;
         else
            if next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<next_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti then
               switch:= True;
            end if;
         end if;
         if switch and then next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken then
            if next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_departure_corsia=from_corsia then
               -- la macchina davanti alla macchina corrente è in sorpasso verso la corsia opposta
               if next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory-
                 get_quartiere_utilities_obj.get_auto_quartiere(next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<get_traiettoria_cambio_corsia.get_distanza_intersezione_linea_di_mezzo then
                  next_car_on_road_distance:= next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
               end if;
            else  -- si ha una macchina che dalla corsia opposta vuole entrare nella corsia first_corsia
               if next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory=get_traiettoria_cambio_corsia.get_distanza_intersezione_linea_di_mezzo then
                  if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken and from_corsia/=current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory then
                     -- la macchina è in sorpasso e non ha ancora attraversato la corsia
                     next_car_on_road_distance:= next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                  elsif current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken then
                     if next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria/2.0-safe_distance_to_overtake>
                       current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_traiettoria-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory then
                        next_car_on_road_distance:= next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                     end if;
                  else
                     if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria/2.0-safe_distance_to_overtake then
                        next_car_on_road_distance:= next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                     end if;
                  end if;
               end if;
            end if;
         end if;
         next_car_in_opposite_corsia:= next_car_in_opposite_corsia.get_next_from_list_posizione_abitanti;
      end loop;
      if next_car_on_road_distance=-1.0 and next_car_in_corsia/=null then  -- limite superiore dato dalla macchina nella stessa corsia se /= null
         next_car_on_road_distance:= next_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
         next_car_on_road:= next_car_in_corsia;
      end if;
   end calculate_distance_to_next_car_on_road;

   procedure calculate_parameters_car_in_uscita(list_abitanti: ptr_list_posizione_abitanti_on_road; traiettoria_rimasta_da_percorrere: Float; next_abitante: ptr_list_posizione_abitanti_on_road; distance_to_stop_line: Float; traiettoria_to_go: traiettoria_ingressi_type; distance_ingresso: Float; next_pos_abitante: in out Float; acceleration: out Float; new_step: out Float; new_speed: out Float) is
      corsia_to_go: Natural:= 0;
      next_abitante_car_length: Float;
      costante_additiva: Float;
      next_entity_distance: Float;
   begin
      if traiettoria_to_go=uscita_andata then
         corsia_to_go:= 1;
      elsif traiettoria_to_go=uscita_ritorno then
         corsia_to_go:= 2;
      end if;
      if corsia_to_go/=0 then
         if next_abitante/=null and then (next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken and next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory=corsia_to_go) then
            costante_additiva:= get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria/2.0;
         else
            costante_additiva:= 0.0;
         end if;

         if next_abitante/=null and then (next_pos_abitante=0.0 or else next_pos_abitante>next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+costante_additiva) then
            if next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken and next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory=corsia_to_go then
               next_pos_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+costante_additiva;
            else
               next_abitante_car_length:= get_quartiere_utilities_obj.get_auto_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
               if next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken=True then
                  if next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory>next_abitante_car_length then
                     next_pos_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                  else
                     next_pos_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory-next_abitante_car_length);
                  end if;
               else
                  next_pos_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-next_abitante_car_length;
               end if;
            end if;
            next_entity_distance:= traiettoria_rimasta_da_percorrere+next_pos_abitante-distance_ingresso-get_larghezza_marciapiede-get_larghezza_corsia;
            acceleration:= calculate_acceleration(mezzo => car,
                                                  id_abitante => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                  id_quartiere_abitante => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                  next_entity_distance => next_entity_distance,
                                                  distance_to_stop_line => distance_to_stop_line,
                                                  next_id_quartiere_abitante => next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                  next_id_abitante => next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                  abitante_velocity => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante,
                                                  next_abitante_velocity => next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante);
         else
            acceleration:= calculate_acceleration(mezzo => car,
                                                  id_abitante => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                  id_quartiere_abitante => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                  next_entity_distance => 0.0,
                                                  distance_to_stop_line => distance_to_stop_line,
                                                  next_id_quartiere_abitante => 0,
                                                  next_id_abitante => 0,
                                                  abitante_velocity => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante,
                                                  next_abitante_velocity =>0.0);
         end if;
         new_speed:= calculate_new_speed(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante,acceleration);
         new_step:= calculate_new_step(new_speed,acceleration);
      end if;
   end calculate_parameters_car_in_uscita;

   procedure calculate_parameters_car_in_entrata(list_abitanti: ptr_list_posizione_abitanti_on_road; traiettoria_rimasta_da_percorrere: Float; next_abitante: ptr_list_posizione_abitanti_on_road; distance_to_stop_line: Float; traiettoria_to_go: traiettoria_ingressi_type; next_pos_abitante: in out Float; acceleration: out Float; new_step: out Float; new_speed: out Float) is
      next_abitante_car_length: Float;
      next_entity_distance: Float;
   begin
      if next_abitante/=null then
         next_abitante_car_length:= get_quartiere_utilities_obj.get_auto_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
         next_pos_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
         next_entity_distance:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-next_abitante_car_length+traiettoria_rimasta_da_percorrere;
         acceleration:= calculate_acceleration(mezzo => car,
                                               id_abitante => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                               id_quartiere_abitante => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                               next_entity_distance => next_entity_distance,
                                               distance_to_stop_line => distance_to_stop_line,
                                               next_id_quartiere_abitante => next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                               next_id_abitante => next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                               abitante_velocity => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante,
                                               next_abitante_velocity => next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante);
      else
         acceleration:= calculate_acceleration(mezzo => car,
                                               id_abitante => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                               id_quartiere_abitante => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                               next_entity_distance => 0.0,
                                               distance_to_stop_line => distance_to_stop_line,
                                               next_id_quartiere_abitante => 0,
                                               next_id_abitante => 0,
                                               abitante_velocity => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante,
                                               next_abitante_velocity =>0.0);
      end if;
      new_speed:= calculate_new_speed(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante,acceleration);
      new_step:= calculate_new_step(new_speed,acceleration);
   end calculate_parameters_car_in_entrata;

   function calculate_next_entity_distance(next_car_in_ingresso_distance: Float; next_car_on_road: ptr_list_posizione_abitanti_on_road; next_car_on_road_distance: Float; id_road: Positive) return Float is
      next_entity_distance: Float:= next_car_in_ingresso_distance;
      next_car_distance: Float:= -1.0;
      quantità_avanzata_next_incrocio: Float:= 0.0;
      incrocio: tratto;
   begin
      -- next_car_on_road vale null se davanti non si hanno macchine o davanti ho una macchina in sorpasso dalla corsia opposita
      if next_car_on_road=null then
         next_car_distance:= next_car_on_road_distance;
      else
         if next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken then -- se in sorpasso
            next_car_distance:= next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
         else
            if next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_urbana_from_id(id_road).get_lunghezza_road then
               incrocio:= get_quartiere_utilities_obj.get_classe_locate_abitanti(next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_current_tratto(next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
               quantità_avanzata_next_incrocio:= ptr_rt_incrocio(get_id_risorsa_quartiere(incrocio.get_id_quartiere_tratto,incrocio.get_id_tratto)).get_posix_first_entity(get_id_quartiere,id_road,next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
            end if;
            next_car_distance:= quantità_avanzata_next_incrocio+next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
              get_quartiere_utilities_obj.get_auto_quartiere(next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                             next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
         end if;
      end if;

      if next_car_in_ingresso_distance=-1.0 and next_car_distance=-1.0 then
         next_entity_distance:= 0.0;
      elsif next_car_distance/=-1.0 and next_car_in_ingresso_distance/=-1.0 then
         if next_car_distance<next_car_in_ingresso_distance then
            next_entity_distance:= next_car_distance;
         else
            next_entity_distance:= next_car_in_ingresso_distance;
         end if;
      elsif next_car_in_ingresso_distance=-1.0 then
         next_entity_distance:= next_car_distance;
      else
         next_entity_distance:= next_car_in_ingresso_distance;
      end if;
      return next_entity_distance;
   end calculate_next_entity_distance;

   procedure configure_tasks is
   begin
      for index_strada in get_from_urbane..get_to_urbane loop
         task_urbane(index_strada).configure(id => index_strada);
      end loop;

      for index_strada in get_from_ingressi..get_to_ingressi loop
         task_ingressi(index_strada).configure(id => index_strada);
      end loop;

      for index_incrocio in get_from_incroci_a_4..get_to_incroci_a_4 loop
         task_incroci(index_incrocio).configure(id => index_incrocio);
      end loop;

      for index_incrocio in get_from_rotonde_a_4..get_to_rotonde_a_4 loop
         task_rotonde(index_incrocio).configure(id => index_incrocio);
      end loop;

      for index_incrocio in get_from_incroci_a_3..get_to_incroci_a_3 loop
         task_incroci(index_incrocio).configure(id => index_incrocio);
      end loop;

      for index_incrocio in get_from_rotonde_a_3..get_to_rotonde_a_3 loop
         task_rotonde(index_incrocio).configure(id => index_incrocio);
      end loop;
   end;

   function calculate_distance_to_stop_line_from_entity_on_road(abitante: ptr_list_posizione_abitanti_on_road; id_urbana: Positive) return Float is
      traiettoria: trajectory_to_follow:= trajectory_to_follow(abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_destination);
   begin
      if traiettoria.get_traiettoria_incrocio_to_follow=empty then
         return get_distance_from_polo_percorrenza(get_ingresso_from_id(traiettoria.get_ingresso_to_go_trajectory))-abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-10.0;
      else
         return get_urbana_from_id(id_urbana).get_lunghezza_road-abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
      end if;
   end calculate_distance_to_stop_line_from_entity_on_road;

   procedure synchronization_with_delta(id: Positive) is
      synch_obj: ptr_synchronization_tasks:= get_synchronization_tasks_partition_object;
   begin
      synch_obj.registra_task(id);
      synch_obj.wait_tasks_partitions;
   end synchronization_with_delta;

   task body core_avanzamento_urbane is
      id_task: Positive;
      mailbox: ptr_resource_segmento_urbana;
      array_estremi_strada_urbana: estremi_resource_strada_urbana:= (others => null);
      key_ingresso: Natural;
      abitante: ptr_list_posizione_abitanti_on_road;
      can_move_from_traiettoria: Boolean;

      next_pos_abitante: Float;
      next_pos_ingresso_move: Float:= 0.0;
      next_abitante: ptr_list_posizione_abitanti_on_road;
      ingresso: strada_ingresso_features;

      list_abitanti_uscita_andata: ptr_list_posizione_abitanti_on_road;
      list_abitanti_uscita_ritorno: ptr_list_posizione_abitanti_on_road;
      list_abitanti_entrata_andata: ptr_list_posizione_abitanti_on_road;
      list_abitanti_entrata_ritorno: ptr_list_posizione_abitanti_on_road;

      corsia_destra: ptr_list_posizione_abitanti_on_road;
      corsia_sinistra: ptr_list_posizione_abitanti_on_road;

      move_entity: move_parameters;

      stop_entity: Boolean:= False;

      acceleration: Float:= 0.0;
      new_speed: Float:= 0.0;
      new_step: Float:= 0.0;
      distance_to_next: Float:= 0.0;

      next_entity_distance: Float;
      distance_to_stop_line: Float;

      current_ingressi_structure_type_to_consider: ingressi_type;
      current_ingressi_structure_type_to_not_consider: ingressi_type;
      distance_ingresso: Float;
      current_polo_to_consider: Boolean:= False;
      traiettoria_rimasta_da_percorrere: Float;
      ingresso_to_consider: strada_ingresso_features;
      there_are_car_overtaking_current_polo: Boolean;
      there_are_car_overtaking_opposite_polo: Boolean;

      first_corsia: Natural;  -- range 0,1,2
      next_car_in_corsia: ptr_list_posizione_abitanti_on_road;
      next_car_in_opposite_corsia: ptr_list_posizione_abitanti_on_road;
      current_car_in_corsia: ptr_list_posizione_abitanti_on_road;
      destination: trajectory_to_follow;
      costante_additiva: Float;
      bound_to_overtake: Float;
      next_car_in_ingresso_distance: Float;
      next_car_on_road: ptr_list_posizione_abitanti_on_road;
      next_car_on_road_distance: Float;
      can_not_overtake_now: Boolean;

      tratto_incrocio: tratto;

      z: Positive;
   begin
      accept configure(id: Positive) do
         id_task:= id;
         mailbox:= get_urbane_segmento_resources(id);
      end configure;
      -- Put_Line("configurato" & Positive'Image(id_task) & "id quartiere" & Positive'Image(get_id_quartiere));

      wait_settings_all_quartieri;
      --Put_Line("task " & Positive'Image(id_task) & " of quartiere " & Positive'Image(get_id_quartiere) & " is set");
      array_estremi_strada_urbana:= get_resource_estremi_urbana(id_task);


      loop

         synchronization_with_delta(id_task);
         -- aspetta che finiscano gli incroci
         log_mio.write_task_arrived("id_task " & Positive'Image(id_task) & " id_quartiere " & Positive'Image(get_id_quartiere));

         if array_estremi_strada_urbana(1)/=null then
            array_estremi_strada_urbana(1).wait_turno;
         end if;
         if array_estremi_strada_urbana(2)/=null then
            array_estremi_strada_urbana(2).wait_turno;
         end if;
         -- fine wait; gli incroci hanno fatto l'avanzamento

         mailbox.update_traiettorie_ingressi;
         mailbox.update_car_on_road;

         current_polo_to_consider:= False;
         current_ingressi_structure_type_to_consider:= ordered_polo_false;
         current_ingressi_structure_type_to_not_consider:= ordered_polo_true;

         for h in 1..2 loop
            for i in reverse mailbox.get_ordered_ingressi_from_polo(current_polo_to_consider).all'Range loop

               ingresso:= get_ingresso_from_id(mailbox.get_index_ingresso_from_key(i,current_ingressi_structure_type_to_consider));
               distance_ingresso:= get_distance_from_polo_percorrenza(ingresso);

               -- al + puoi muovere le macchine nelle traiettorie uscita_ritorno e entrata_ritorno se le loro traiettoria sono sulla parte
               -- non occupata dalla strada

               there_are_car_overtaking_current_polo:= mailbox.there_are_overtaken_on_ingresso(ingresso,ingresso.get_polo_ingresso);
               there_are_car_overtaking_opposite_polo:= mailbox.there_are_overtaken_on_ingresso(ingresso,not ingresso.get_polo_ingresso);

               if there_are_car_overtaking_current_polo and there_are_car_overtaking_opposite_polo then
                  list_abitanti_uscita_andata:= null;
                  list_abitanti_uscita_ritorno:= null;
                  list_abitanti_entrata_andata:= null;
                  list_abitanti_entrata_ritorno:= null;
               elsif there_are_car_overtaking_current_polo=False and there_are_car_overtaking_opposite_polo=False then
                  list_abitanti_uscita_andata:= mailbox.get_abitante_from_ingresso(i,uscita_andata);
                  list_abitanti_uscita_ritorno:= mailbox.get_abitante_from_ingresso(i,uscita_ritorno);
                  list_abitanti_entrata_andata:= mailbox.get_abitante_from_ingresso(i,entrata_andata);
                  list_abitanti_entrata_ritorno:= mailbox.get_abitante_from_ingresso(i,entrata_ritorno);
               elsif there_are_car_overtaking_current_polo then
                  list_abitanti_uscita_ritorno:= mailbox.get_abitante_from_ingresso(i,uscita_ritorno);
                  list_abitanti_entrata_ritorno:= mailbox.get_abitante_from_ingresso(i,entrata_ritorno);
                  if list_abitanti_uscita_ritorno/=null and then list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                    get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<15.0 then  -- 15.0 distanza intersezione seconda linea
                     list_abitanti_uscita_ritorno:= null;
                  end if;
                  if list_abitanti_entrata_ritorno/=null and then list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<5.0 then -- 5.0 distanza intersezione linea di mezzo
                     list_abitanti_entrata_ritorno:= null;
                  end if;
               else
                  list_abitanti_uscita_andata:= mailbox.get_abitante_from_ingresso(i,uscita_andata);
                  list_abitanti_uscita_ritorno:= mailbox.get_abitante_from_ingresso(i,uscita_ritorno);
                  list_abitanti_entrata_andata:= mailbox.get_abitante_from_ingresso(i,entrata_andata);
                  list_abitanti_entrata_ritorno:= mailbox.get_abitante_from_ingresso(i,entrata_ritorno);
                  if list_abitanti_uscita_ritorno/=null and then list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<15.0 then -- 15.0 distanza intersezione linea di mezzo
                     list_abitanti_uscita_ritorno:= null;
                  end if;
                  if list_abitanti_entrata_ritorno/=null and then list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                    get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<5.0 then
                     list_abitanti_entrata_ritorno:= null;
                  end if;
               end if;

               if list_abitanti_uscita_andata/=null and then list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_ingresso(uscita_andata).get_lunghezza then
                  list_abitanti_uscita_andata:= null;
               end if;
               if list_abitanti_uscita_ritorno/=null and then list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_ingresso(uscita_ritorno).get_lunghezza then
                  list_abitanti_uscita_ritorno:= null;
               end if;
               if list_abitanti_entrata_andata/=null and then list_abitanti_entrata_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_ingresso(entrata_andata).get_lunghezza then
                  list_abitanti_entrata_andata:= null;
               end if;
               if list_abitanti_entrata_ritorno/=null and then list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_ingresso(entrata_ritorno).get_lunghezza then
                  list_abitanti_entrata_ritorno:= null;
               end if;

               -- TRAIETTORIA USCITA_ANDATA
               can_move_from_traiettoria:= True;
               next_pos_abitante:= 0.0;
               if list_abitanti_uscita_andata/=null and then list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 then
                  if list_abitanti_uscita_ritorno/=null then
                     move_entity:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                     if list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-move_entity.get_length_entità_passiva>=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then -- intersezione con linea corsia
                        can_move_from_traiettoria:= mailbox.can_abitante_move(distance_ingresso,i,uscita_andata,current_polo_to_consider);
                     else
                        can_move_from_traiettoria:= False;
                     end if;
                  end if;
               end if;
               if list_abitanti_uscita_andata/=null and can_move_from_traiettoria then -- se c è qualcuno da muovere e può muoversi
                  key_ingresso:= 0;
                  -- cerco se l'ingresso ha qualche ingresso sul lato opposto che ha macchine che vogliono svoltare a sx
                  for j in mailbox.get_ordered_ingressi_from_polo(not current_polo_to_consider).all'Range loop
                     -- abitanti uscita andata
                     if distance_ingresso<(get_urbana_from_id(id_task).get_lunghezza_road-get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(j,current_ingressi_structure_type_to_not_consider)))) then
                        abitante:= mailbox.get_abitante_from_ingresso(mailbox.get_key_ingresso(mailbox.get_index_ingresso_from_key(j,current_ingressi_structure_type_to_not_consider),not_ordered),uscita_ritorno);
                        if abitante/=null then
                           if abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                              key_ingresso:= j;
                           end if;
                        end if;
                     end if;
                  end loop;
                  if key_ingresso/=0 then
                     next_pos_abitante:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(key_ingresso,current_ingressi_structure_type_to_not_consider)));
                  end if;

                  -- cerco se ingressi successivi sullo stesso polo hanno macchine da spostare
                  next_pos_ingresso_move:= 0.0;
                  z:= i+1;
                  while next_pos_ingresso_move=0.0 and z<mailbox.get_ordered_ingressi_from_polo(current_polo_to_consider).all'Last loop
                     ingresso_to_consider:= get_ingresso_from_id(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider));
                     if mailbox.is_index_ingresso_in_svolta(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),uscita_andata) then
                        next_pos_ingresso_move:= get_distance_from_polo_percorrenza(ingresso_to_consider);
                     elsif mailbox.is_index_ingresso_in_svolta(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),uscita_ritorno) then
                        next_pos_ingresso_move:= get_distance_from_polo_percorrenza(ingresso_to_consider);
                     end if;
                     if mailbox.is_index_ingresso_in_svolta(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),entrata_ritorno) then
                        next_pos_ingresso_move:= get_distance_from_polo_percorrenza(ingresso_to_consider) - get_larghezza_corsia;
                        --   if sotto SOTTRARRE ANCHE LUNGHEZZA MACCHINA
                     elsif mailbox.is_index_ingresso_in_svolta(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),entrata_andata) then
                        next_pos_ingresso_move:= get_distance_from_polo_percorrenza(ingresso_to_consider) - get_larghezza_corsia;
                     end if;
                     z:= z+1;
                  end loop;
                  if next_pos_ingresso_move/=0.0 then
                     if next_pos_abitante=0.0 or else next_pos_abitante>next_pos_ingresso_move then
                        next_pos_abitante:= next_pos_ingresso_move;
                     end if;
                  end if;
                  traiettoria_rimasta_da_percorrere:= get_traiettoria_ingresso(uscita_andata).get_lunghezza-list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                  next_abitante:= mailbox.get_next_abitante_on_road(distance_ingresso+get_larghezza_corsia+get_larghezza_marciapiede,current_polo_to_consider,1);
                  distance_to_stop_line:= get_urbana_from_id(id_task).get_lunghezza_road-(distance_ingresso+get_larghezza_corsia+get_larghezza_marciapiede)+traiettoria_rimasta_da_percorrere;
                  calculate_parameters_car_in_uscita(list_abitanti_uscita_andata,traiettoria_rimasta_da_percorrere,next_abitante,distance_to_stop_line,uscita_andata,distance_ingresso,next_pos_abitante,acceleration,new_step,new_speed);
                  mailbox.set_move_parameters_entity_on_traiettoria_ingresso(ingresso.get_id_road,uscita_andata,new_speed,new_step);
                  Put_Line("id_abitante " & Positive'Image(list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & Float'Image(list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is traiettoria ingresso " & Positive'Image(id_task));
               end if;

               -- TRAIETTORIA USCITA_RITORNO
               stop_entity:= False;
               can_move_from_traiettoria:= True;
               next_pos_abitante:= 0.0;
               if list_abitanti_uscita_ritorno/=null and then list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 then
                  if list_abitanti_uscita_andata/=null then
                     if list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=0.0 then --or list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>0.0 then
                        can_move_from_traiettoria:= False;
                     else
                        can_move_from_traiettoria:= mailbox.can_abitante_move(distance_ingresso,i,uscita_ritorno,current_polo_to_consider);
                     end if;
                  end if;
               end if;
               stop_entity:= False;
               if list_abitanti_uscita_ritorno/=null and can_move_from_traiettoria then
                  if list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                     stop_entity:= mailbox.can_abitante_continue_move(distance_ingresso,1,uscita_ritorno,current_polo_to_consider);
                  elsif list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie-max_larghezza_veicolo then
                     -- ASSUNZIONE CHE LA MACCHINA NON SIA PIÙ LUNGA DI PEZZI DI TRAIETTORIA TRA PT INTERSEZIONE
                     if list_abitanti_entrata_ritorno/=null and then list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                       max_larghezza_veicolo+get_traiettoria_ingresso(entrata_andata).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                        stop_entity:= True;
                     else
                        stop_entity:= False;
                     end if;
                  elsif list_abitanti_entrata_ritorno=null and then list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                     stop_entity:= mailbox.can_abitante_continue_move(distance_ingresso,2,uscita_ritorno,current_polo_to_consider);
                  end if;
                  if stop_entity=False then -- non ci sono macchine nella traiettoria entrata_ritorno quindi non deve essere data la precedenza alle macchine di quella traiettoria
                     key_ingresso:= 0;
                     -- cerco se ingressi precedenti hanno delle svolte a sx

                     for j in 1..i-1 loop
                        abitante:= mailbox.get_abitante_from_ingresso(mailbox.get_key_ingresso(mailbox.get_index_ingresso_from_key(j,current_ingressi_structure_type_to_consider),not_ordered),uscita_ritorno);
                        if abitante/=null and then abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                           key_ingresso:= j;
                           costante_additiva:= get_larghezza_corsia+get_larghezza_marciapiede;
                        else
                           abitante:= mailbox.get_abitante_from_ingresso(mailbox.get_key_ingresso(mailbox.get_index_ingresso_from_key(j,current_ingressi_structure_type_to_consider),not_ordered),entrata_ritorno);
                           if abitante/=null and then (abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie and
                                                         abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                                                                                                                                                      abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                                                         get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie) then
                              key_ingresso:= j;
                              costante_additiva:= 0.0;
                           end if;
                        end if;
                     end loop;
                     if key_ingresso/=0 then
                        next_pos_abitante:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(key_ingresso,current_ingressi_structure_type_to_consider)))+costante_additiva;
                     end if;

                     -- cerco se ingressi nel polo opposto hanno svolte a sx
                     key_ingresso:= 0;
                     for j in mailbox.get_ordered_ingressi_from_polo(not current_polo_to_consider).all'Range loop
                        if distance_ingresso<get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(j,current_ingressi_structure_type_to_not_consider))) then
                           abitante:= mailbox.get_abitante_from_ingresso(mailbox.get_key_ingresso(mailbox.get_index_ingresso_from_key(j,current_ingressi_structure_type_to_not_consider),not_ordered),entrata_ritorno);
                           if abitante/=null and then (abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie and
                                                         abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                                                                                                                                                      abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                                                         get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie) then
                              key_ingresso:= j;
                              costante_additiva:= get_larghezza_corsia+get_larghezza_marciapiede;

                           else
                              abitante:= mailbox.get_abitante_from_ingresso(mailbox.get_key_ingresso(mailbox.get_index_ingresso_from_key(j,current_ingressi_structure_type_to_not_consider),not_ordered),uscita_ritorno);
                              move_entity:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                              if abitante/=null and then (abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie
                                                          and abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-move_entity.get_length_entità_passiva<get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie) then
                                 key_ingresso:= j;
                                 costante_additiva:= 0.0;
                              end if;
                           end if;
                        end if;
                     end loop;
                     if key_ingresso/=0 then
                        if next_pos_abitante=0.0 or else next_pos_abitante>get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(key_ingresso,current_ingressi_structure_type_to_not_consider))) then -- 10.0 dimensione di metà strada
                           next_pos_abitante:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(key_ingresso,current_ingressi_structure_type_to_not_consider)))+costante_additiva;
                        end if;
                     end if;

                     traiettoria_rimasta_da_percorrere:= get_traiettoria_ingresso(uscita_ritorno).get_lunghezza-list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                     next_abitante:= mailbox.get_next_abitante_on_road(get_urbana_from_id(id_task).get_lunghezza_road-(distance_ingresso-get_larghezza_marciapiede-get_larghezza_corsia),not current_polo_to_consider,2);
                     distance_to_stop_line:= distance_ingresso-get_larghezza_marciapiede-get_larghezza_corsia+traiettoria_rimasta_da_percorrere;
                     calculate_parameters_car_in_uscita(list_abitanti_uscita_ritorno,traiettoria_rimasta_da_percorrere,next_abitante,distance_to_stop_line,uscita_ritorno,distance_ingresso,next_pos_abitante,acceleration,new_step,new_speed);

                     -- scaglioni steps:
                     -- per dare precedenza a entrata_ritorno 15.0-1.5       15.0         25.0
                     if list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                        if list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                           new_step:= get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie-list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                        end if;
                     elsif list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie-max_larghezza_veicolo then
                        if list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie-max_larghezza_veicolo then
                           new_step:= get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie-max_larghezza_veicolo-list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                        end if;
                     elsif list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                        if list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                           new_step:= get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie-list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                        end if;
                     end if;

                     mailbox.set_move_parameters_entity_on_traiettoria_ingresso(ingresso.get_id_road,uscita_ritorno,new_speed,new_step);
                     Put_Line("id_abitante " & Positive'Image(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & Float'Image(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is traiettoria ingresso " & Positive'Image(id_task));
                  end if;
               end if;


               -- TRAIETTORIA ENTRATA_RITORNO
               can_move_from_traiettoria:= True;
               next_pos_abitante:= 0.0;
               stop_entity:= False;
               if list_abitanti_entrata_ritorno/=null and then list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 then
                  if list_abitanti_uscita_ritorno/=null and then list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie-max_larghezza_veicolo then
                     can_move_from_traiettoria:= True;
                  else
                     if list_abitanti_uscita_ritorno/=null and then list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva>
                       max_larghezza_veicolo+get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                        can_move_from_traiettoria:= True;
                     else
                        can_move_from_traiettoria:= False;
                     end if;
                  end if;
               end if;
               if list_abitanti_entrata_ritorno/=null and can_move_from_traiettoria then
                  if list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                     stop_entity:= mailbox.can_abitante_continue_move(distance_ingresso,2,entrata_ritorno,current_polo_to_consider);
                  end if;
                  if list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                     if list_abitanti_entrata_andata/=null and then list_abitanti_entrata_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=0.0 then
                        stop_entity:= True;
                     elsif list_abitanti_entrata_andata=null then
                        stop_entity:= mailbox.can_abitante_continue_move(distance_ingresso,1,entrata_ritorno,current_polo_to_consider);
                     end if;
                  end if;

                  if stop_entity=False then
                     traiettoria_rimasta_da_percorrere:= get_traiettoria_ingresso(entrata_ritorno).get_lunghezza-list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                     next_abitante:= get_ingressi_segmento_resources(mailbox.get_index_ingresso_from_key(i,current_ingressi_structure_type_to_consider)).get_first_abitante_to_exit_from_urbana;
                     distance_to_stop_line:= ingresso.get_lunghezza_road+traiettoria_rimasta_da_percorrere;
                     calculate_parameters_car_in_entrata(list_abitanti_entrata_ritorno,traiettoria_rimasta_da_percorrere,next_abitante,distance_to_stop_line,entrata_ritorno,next_pos_abitante,acceleration,new_step,new_speed);
                     mailbox.set_move_parameters_entity_on_traiettoria_ingresso(ingresso.get_id_road,entrata_andata,new_speed,new_step);
                     Put_Line("id_abitante " & Positive'Image(list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & Float'Image(list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is traiettoria ingresso " & Positive'Image(id_task));
                  end if;
               end if;


               -- TRAIETTORIA ENTRATA_ANDATA
               can_move_from_traiettoria:= True;
               next_pos_abitante:= 0.0;
               if list_abitanti_entrata_andata/=null and then list_abitanti_entrata_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 then
                  if current_polo_to_consider then
                     next_abitante:= mailbox.get_next_abitante_on_road(distance_ingresso,current_polo_to_consider,1);
                  else
                     next_abitante:= mailbox.get_next_abitante_on_road(distance_ingresso,current_polo_to_consider,1);
                  end if;
                  move_entity:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                  if next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-move_entity.get_length_entità_passiva<ingresso.get_distance_from_road_head_ingresso then
                     can_move_from_traiettoria:= False;
                  elsif list_abitanti_entrata_ritorno/=null and then list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                     can_move_from_traiettoria:= False;
                  else
                     can_move_from_traiettoria:= True;
                  end if;
               end if;
               if list_abitanti_entrata_andata/=null and can_move_from_traiettoria then
                  traiettoria_rimasta_da_percorrere:= get_traiettoria_ingresso(entrata_andata).get_lunghezza-list_abitanti_entrata_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                  next_abitante:= get_ingressi_segmento_resources(mailbox.get_index_ingresso_from_key(i,current_ingressi_structure_type_to_consider)).get_first_abitante_to_exit_from_urbana;
                  distance_to_stop_line:= ingresso.get_lunghezza_road+traiettoria_rimasta_da_percorrere;
                  calculate_parameters_car_in_entrata(list_abitanti_entrata_andata,traiettoria_rimasta_da_percorrere,next_abitante,distance_to_stop_line,entrata_andata,next_pos_abitante,acceleration,new_step,new_speed);
                  mailbox.set_move_parameters_entity_on_traiettoria_ingresso(ingresso.get_id_road,entrata_andata,new_speed,new_step);
                  Put_Line("id_abitante " & Positive'Image(list_abitanti_entrata_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & Float'Image(list_abitanti_entrata_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is traiettoria ingresso " & Positive'Image(id_task));
               end if;
            end loop;
            current_polo_to_consider:= True;
            current_ingressi_structure_type_to_consider:= ordered_polo_true;
            current_ingressi_structure_type_to_not_consider:= ordered_polo_false;
         end loop;

         current_polo_to_consider:= False;
         for h in 1..2 loop
            corsia_destra:= mailbox.get_abitanti_on_road(current_polo_to_consider,1);
            corsia_sinistra:= mailbox.get_abitanti_on_road(current_polo_to_consider,2);
            for i in 1..(mailbox.get_number_entity(road,current_polo_to_consider,1)+mailbox.get_number_entity(road,current_polo_to_consider,2)) loop
               -- cerco la prima macchina tra le 2 liste
               first_corsia:= 0;
               current_car_in_corsia:= null;
               next_car_in_corsia:= null;
               next_car_in_opposite_corsia:= null;
               if corsia_destra/=null and corsia_sinistra/=null then
                  if corsia_destra.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<corsia_sinistra.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti then
                     first_corsia:= 1;
                     current_car_in_corsia:= corsia_destra;
                     next_car_in_corsia:= corsia_destra.get_next_from_list_posizione_abitanti;
                     next_car_in_opposite_corsia:= corsia_sinistra.get_next_from_list_posizione_abitanti;
                     corsia_destra:= next_car_in_corsia;
                  else
                     first_corsia:= 2;
                     current_car_in_corsia:= corsia_sinistra;
                     next_car_in_corsia:= corsia_sinistra.get_next_from_list_posizione_abitanti;
                     next_car_in_opposite_corsia:= corsia_destra.get_next_from_list_posizione_abitanti;
                     corsia_sinistra:= next_car_in_corsia;
                  end if;
               else
                  if corsia_destra/=null and corsia_sinistra=null then
                     first_corsia:= 1;
                     current_car_in_corsia:= corsia_destra;
                     next_car_in_corsia:= corsia_destra.get_next_from_list_posizione_abitanti;
                     next_car_in_opposite_corsia:= null;
                     corsia_destra:= next_car_in_corsia;
                  elsif corsia_destra=null and corsia_sinistra/=null then
                     first_corsia:= 2;
                     current_car_in_corsia:= corsia_sinistra;
                     next_car_in_corsia:= corsia_sinistra.get_next_from_list_posizione_abitanti;
                     next_car_in_opposite_corsia:= null;
                     corsia_sinistra:= next_car_in_corsia;
                  else
                     null; -- NOOP
                  end if;
               end if;

               distance_to_stop_line:= 0.0;
               next_entity_distance:= 0.0;
               can_not_overtake_now:= False;

               if first_corsia/=0 then
                  -- elaborazione corsia to go;    first_corsia è la corsia in cui la macchina è situata
                  Put_Line("id_abitante " & Positive'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & Float'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is urbana " & Positive'Image(id_task));
                  Put_Line("id_abitante overtaking " & Float'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory));
                  destination:= trajectory_to_follow(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_destination);
                  if destination.get_traiettoria_incrocio_to_follow/=empty or (destination.get_corsia_to_go_trajectory/=0 and destination.get_ingresso_to_go_trajectory/=0) then
                     stop_entity:= False;
                     if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory/=first_corsia then
                        if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken=False then -- macchina non in sorpasso
                           bound_to_overtake:= calculate_bound_to_overtake(current_car_in_corsia,id_task);
                           if bound_to_overtake=0.0 then -- necessario sorpassare subito
                              stop_entity:= not mailbox.car_can_initiate_overtaken_on_road(current_car_in_corsia,current_polo_to_consider,first_corsia);
                              if stop_entity=False and mailbox.car_on_same_corsia_have_overtaked(current_car_in_corsia,current_polo_to_consider,first_corsia) then
                                 mailbox.set_car_overtaken(True,current_car_in_corsia);
                                 traiettoria_rimasta_da_percorrere:= get_traiettoria_cambio_corsia.get_lunghezza_traiettoria-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                                 distance_to_stop_line:= calculate_distance_to_stop_line_from_entity_on_road(current_car_in_corsia,id_task);
                                 next_car_in_ingresso_distance:= mailbox.calculate_distance_to_next_ingressi(current_polo_to_consider,destination.get_corsia_to_go_trajectory,current_car_in_corsia);
                                 calculate_distance_to_next_car_on_road(current_car_in_corsia,next_car_in_opposite_corsia,next_car_in_corsia,first_corsia,next_car_on_road,next_car_on_road_distance);
                                 next_entity_distance:= calculate_next_entity_distance(next_car_in_ingresso_distance,next_car_on_road,next_car_on_road_distance,id_task);
                              else
                                 stop_entity:= True;
                              end if;

                           else  -- valutare se sorpassare
                              -- FIRST: controllare se il sorpasso può essere effettuato
                              -- la macchina se si trova dentro un incrocio tra ingressi e l'ingresso non è occupato allora ok
                              --  car_can_initiate_overtaken(current_car_in_corsia,current_polo_to_consider,first_corsia)
                              stop_entity:= True;
                              if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_larghezza_corsia+get_larghezza_marciapiede then  -- ovvero per sorpassare occorre aver superato di 10.0 la distanza dall'incrocio
                                 if mailbox.there_are_cars_moving_across_next_ingressi(current_car_in_corsia,current_polo_to_consider)=False then  -- può sorpassare
                                    stop_entity:= not mailbox.car_can_initiate_overtaken_on_road(current_car_in_corsia,current_polo_to_consider,first_corsia);
                                    if stop_entity=False and mailbox.car_on_same_corsia_have_overtaked(current_car_in_corsia,current_polo_to_consider,first_corsia) then
                                       mailbox.set_car_overtaken(True,current_car_in_corsia);
                                       traiettoria_rimasta_da_percorrere:= get_traiettoria_cambio_corsia.get_lunghezza_traiettoria-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                                       distance_to_stop_line:= calculate_distance_to_stop_line_from_entity_on_road(current_car_in_corsia,id_task);
                                       next_car_in_ingresso_distance:= mailbox.calculate_distance_to_next_ingressi(current_polo_to_consider,destination.get_corsia_to_go_trajectory,current_car_in_corsia);
                                       calculate_distance_to_next_car_on_road(current_car_in_corsia,next_car_in_opposite_corsia,next_car_in_corsia,first_corsia,next_car_on_road,next_car_on_road_distance);
                                       next_entity_distance:= calculate_next_entity_distance(next_car_in_ingresso_distance,next_car_on_road,next_car_on_road_distance,id_task);
                                    end if;
                                 end if;
                              end if;
                              if stop_entity then  -- se la macchina non può sorpassare la si fa avanzare
                                 stop_entity:= False;
                                 can_not_overtake_now:= True;
                                 traiettoria_rimasta_da_percorrere:= 0.0;
                                 distance_to_stop_line:= bound_to_overtake;
                                 next_car_in_ingresso_distance:= mailbox.calculate_distance_to_next_ingressi(current_polo_to_consider,first_corsia,current_car_in_corsia);
                                 calculate_distance_to_next_car_on_road(current_car_in_corsia,next_car_in_corsia,next_car_in_opposite_corsia,first_corsia,next_car_on_road,next_car_on_road_distance);
                                 next_entity_distance:= calculate_next_entity_distance(next_car_in_ingresso_distance,next_car_on_road,next_car_on_road_distance,id_task);
                              end if;
                           end if;
                           if stop_entity=False and next_car_on_road/=null then
                              acceleration:= calculate_acceleration(mezzo => car,
                                                              id_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                              id_quartiere_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                              next_entity_distance => next_entity_distance+traiettoria_rimasta_da_percorrere,
                                                              distance_to_stop_line => distance_to_stop_line+traiettoria_rimasta_da_percorrere,
                                                              next_id_quartiere_abitante => next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                              next_id_abitante => next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                              abitante_velocity => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante,
                                                              next_abitante_velocity => next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante);
                           else
                              if next_entity_distance/=0.0 then
                                 next_entity_distance:= next_entity_distance+traiettoria_rimasta_da_percorrere;
                              end if;
                              acceleration:= calculate_acceleration(mezzo => car,
                                                              id_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                              id_quartiere_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                              next_entity_distance => next_entity_distance,
                                                              distance_to_stop_line => distance_to_stop_line+traiettoria_rimasta_da_percorrere,
                                                              next_id_quartiere_abitante => 0,
                                                              next_id_abitante => 0,
                                                              abitante_velocity => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante,
                                                              next_abitante_velocity =>0.0);
                           end if;
                        else -- macchina in sorpasso, occorre avanzarla
                           if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory=get_traiettoria_cambio_corsia.get_lunghezza_traiettoria/2.0 then
                              stop_entity:= not mailbox.can_car_overtake(current_car_in_corsia,current_polo_to_consider,destination.get_corsia_to_go_trajectory);
                              mailbox.set_flag_car_can_overtake_to_next_corsia(current_car_in_corsia,True);
                           end if;
                           if stop_entity=False then
                              traiettoria_rimasta_da_percorrere:= get_traiettoria_cambio_corsia.get_lunghezza_traiettoria-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory;
                              distance_to_stop_line:= calculate_distance_to_stop_line_from_entity_on_road(current_car_in_corsia,id_task);
                              next_car_in_ingresso_distance:= mailbox.calculate_distance_to_next_ingressi(current_polo_to_consider,destination.get_corsia_to_go_trajectory,current_car_in_corsia);
                              calculate_distance_to_next_car_on_road(current_car_in_corsia,next_car_in_opposite_corsia,next_car_in_corsia,destination.get_corsia_to_go_trajectory,next_car_on_road,next_car_on_road_distance);
                              next_entity_distance:= calculate_next_entity_distance(next_car_in_ingresso_distance,next_car_on_road,next_car_on_road_distance,id_task);
                              if next_car_on_road/=null then
                                 acceleration:= calculate_acceleration(mezzo => car,
                                                                id_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                                id_quartiere_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                next_entity_distance => next_entity_distance+traiettoria_rimasta_da_percorrere,
                                                                distance_to_stop_line => distance_to_stop_line+traiettoria_rimasta_da_percorrere,
                                                                next_id_quartiere_abitante => next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                next_id_abitante => next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                                abitante_velocity => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante,
                                                                next_abitante_velocity => next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante);
                              elsif next_entity_distance/=0.0 then
                                 acceleration:= calculate_acceleration(mezzo => car,
                                                                       id_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                                       id_quartiere_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                       next_entity_distance => next_entity_distance+traiettoria_rimasta_da_percorrere,
                                                                       distance_to_stop_line => distance_to_stop_line+traiettoria_rimasta_da_percorrere,
                                                                       next_id_quartiere_abitante => 0,
                                                                       next_id_abitante => 0,
                                                                       abitante_velocity => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante,
                                                                       next_abitante_velocity =>0.0);
                              else
                                 acceleration:= calculate_acceleration(mezzo => car,
                                                                       id_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                                       id_quartiere_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                       next_entity_distance => 0.0,
                                                                       distance_to_stop_line => distance_to_stop_line+traiettoria_rimasta_da_percorrere,
                                                                       next_id_quartiere_abitante => 0,
                                                                       next_id_abitante => 0,
                                                                       abitante_velocity => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante,
                                                                       next_abitante_velocity =>0.0);
                              end if;
                           end if;
                        end if;
                     else -- la macchina è nella corsia giusta
                        distance_to_stop_line:= calculate_distance_to_stop_line_from_entity_on_road(current_car_in_corsia,id_task);
                        next_car_in_ingresso_distance:= mailbox.calculate_distance_to_next_ingressi(current_polo_to_consider,first_corsia,current_car_in_corsia);
                        calculate_distance_to_next_car_on_road(current_car_in_corsia,next_car_in_corsia,next_car_in_opposite_corsia,first_corsia,next_car_on_road,next_car_on_road_distance);
                        next_entity_distance:= calculate_next_entity_distance(next_car_in_ingresso_distance,next_car_on_road,next_car_on_road_distance,id_task);
                        if next_car_on_road/=null and then next_entity_distance=next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti then
                           acceleration:= calculate_acceleration(mezzo => car,
                                                           id_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                           id_quartiere_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                           next_entity_distance => next_entity_distance,
                                                           distance_to_stop_line => distance_to_stop_line,
                                                           next_id_quartiere_abitante => next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                           next_id_abitante => next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                           abitante_velocity => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante,
                                                           next_abitante_velocity => next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante);
                        else
                           acceleration:= calculate_acceleration(mezzo => car,
                                                           id_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                           id_quartiere_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                           next_entity_distance => next_entity_distance,
                                                           distance_to_stop_line => distance_to_stop_line,
                                                           next_id_quartiere_abitante => 0,
                                                           next_id_abitante => 0,
                                                           abitante_velocity => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante,
                                                           next_abitante_velocity =>0.0);
                        end if;
                     end if;
                     if stop_entity=False then
                        new_speed:= calculate_new_speed(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante,acceleration);
                        new_step:= calculate_new_step(new_speed,acceleration);
                        if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken=True then -- macchina in sorpasso
                           if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory<get_traiettoria_cambio_corsia.get_lunghezza_traiettoria/2.0 then
                              if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory+new_step>=get_traiettoria_cambio_corsia.get_lunghezza_traiettoria/2.0 then
                                 new_step:= get_traiettoria_cambio_corsia.get_lunghezza_traiettoria/2.0-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory;
                              end if;
                           end if;
                        elsif can_not_overtake_now then
                           if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>bound_to_overtake then
                              new_step:= bound_to_overtake-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                           end if;
                        end if;
                     end if;
                     mailbox.set_move_parameters_entity_on_main_road(current_car_in_corsia,current_polo_to_consider,first_corsia,new_speed,new_step);
                     if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti=get_urbana_from_id(id_task).get_lunghezza_road then
                        -- aggiungi entità
                        -- all'incrocio
                        if get_quartiere_utilities_obj.get_classe_locate_abitanti(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_current_position(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti)/=1 then
                           get_quartiere_utilities_obj.get_classe_locate_abitanti(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).set_position_abitante_to_next(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                        end if;
                        tratto_incrocio:= get_quartiere_utilities_obj.get_classe_locate_abitanti(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_next(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                        ptr_rt_incrocio(get_id_risorsa_quartiere(tratto_incrocio.get_id_quartiere_tratto,tratto_incrocio.get_id_tratto)).insert_new_car(get_id_quartiere,id_task,posizione_abitanti_on_road(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti));
                     else
                        null;
                     end if;
                     --Put_Line(Boolean'Image(mailbox.get_abitanti_on_road(false,1).get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken));
                  else
                     null; -- NOOP
                  end if;
               else
                  null; -- NOOP
               end if;
            end loop;

            current_polo_to_consider:= True;
         end loop;

         -- spostamento abitanti da incrocio a strada
         mailbox.sposta_abitanti_in_transizione_da_incroci;

         mailbox.delta_terminate;
      end loop;

      --Put_Line("Fine task urbana" & Positive'Image(id_task) & ",id quartiere" & Positive'Image(get_id_quartiere));
   end core_avanzamento_urbane;

   task body core_avanzamento_ingressi is
      id_task: Positive;
      mailbox: ptr_resource_segmento_ingresso;
      resource_main_strada: ptr_resource_segmento_urbana;
      list_abitanti: ptr_list_posizione_abitanti_on_road:= null;
      acceleration: Float:= 0.0;
      new_speed: Float:= 0.0;
      new_step: Float:= 0.0;
      distance_to_next: Float:= 0.0;
      new_requests: ptr_list_posizione_abitanti_on_road:= null;
      residente: move_parameters;
      pragma Warnings(off);
      default_pos_abitanti: posizione_abitanti_on_road;
      pragma Warnings(on);
      current_posizione_abitante: posizione_abitanti_on_road'Class:= default_pos_abitanti;
      next_posizione_abitante: posizione_abitanti_on_road'Class:= default_pos_abitanti;
      traiettoria_type: traiettoria_ingressi_type;
      traiettoria_on_main_strada: trajectory_to_follow;
      distanza_percorsa: Float;
   begin
      accept configure(id: Positive) do
         id_task:= id;
         mailbox:= get_ingressi_segmento_resources(id);
         resource_main_strada:= get_urbane_segmento_resources(get_ingresso_from_id(id_task).get_id_main_strada_ingresso);
      end configure;

      wait_settings_all_quartieri;
      --Put_Line("task " & Positive'Image(id_task) & " of quartiere " & Positive'Image(get_id_quartiere) & " is set");

      -- Ora i task e le risorse di tutti i quartieri sono attivi

      loop
         synchronization_with_delta(id_task);
         log_mio.write_task_arrived("id_task " & Positive'Image(id_task) & " id_quartiere " & Positive'Image(get_id_quartiere));
         --Put_Line("wait " & Positive'Image(get_ingresso_from_id(id_task).get_id_main_strada_ingresso) & " id quartiere " & Positive'Image(get_id_quartiere));
         resource_main_strada.wait_turno;


         list_abitanti:= mailbox.get_main_strada(mailbox.get_index_inizio_moto);
         for i in 1..mailbox.get_number_entity_strada(mailbox.get_index_inizio_moto) loop
            mailbox.update_position_entity(road,mailbox.get_index_inizio_moto,i);
            current_posizione_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
            Put_Line("id_abitante " & Positive'Image(i) & " is at " & Float'Image(current_posizione_abitante.get_where_now_posizione_abitanti) & ", gestore is ingresso " & Positive'Image(id_task));
            if current_posizione_abitante.get_where_now_posizione_abitanti=get_ingresso_from_id(id_task).get_lunghezza_road then
               if mailbox.get_car_avanzamento>=move_parameters(get_quartiere_utilities_obj.all.get_auto_quartiere(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti)).get_length_entità_passiva then
                  mailbox.delete_car_in_uscita;
               end if;
            else
               if list_abitanti.all.get_next_from_list_posizione_abitanti/=null then  -- elimino la macchina davanti se ha finito la transizione da ingresso a urbana
                  next_posizione_abitante:= list_abitanti.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
                  if next_posizione_abitante.get_where_now_posizione_abitanti=get_ingresso_from_id(id_task).get_lunghezza_road then
                     distanza_percorsa:= mailbox.get_car_avanzamento;
                  else
                     distanza_percorsa:= 0.0;
                  end if;
               end if;

               if list_abitanti.all.get_next_from_list_posizione_abitanti/=null then
                  next_posizione_abitante:= list_abitanti.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
                  distance_to_next:= next_posizione_abitante.get_where_now_posizione_abitanti+distanza_percorsa-move_parameters(get_quartiere_utilities_obj.all.get_auto_quartiere(next_posizione_abitante.get_id_quartiere_posizione_abitanti,next_posizione_abitante.get_id_abitante_posizione_abitanti)).get_length_entità_passiva-current_posizione_abitante.get_where_now_posizione_abitanti;
                  if distance_to_next<=0.0 then acceleration:= 0.0;
                  else
                     acceleration:= calculate_acceleration(mezzo => car,
                                                     id_abitante => current_posizione_abitante.get_id_abitante_posizione_abitanti,
                                                     id_quartiere_abitante => current_posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                     next_entity_distance => distance_to_next,
                                                     distance_to_stop_line => get_ingresso_from_id(id_task).get_lunghezza_road-current_posizione_abitante.get_where_now_posizione_abitanti+1.0,
                                                     next_id_quartiere_abitante => next_posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                     next_id_abitante => next_posizione_abitante.get_id_abitante_posizione_abitanti,
                                                     abitante_velocity => current_posizione_abitante.get_current_speed_abitante,
                                                     next_abitante_velocity => next_posizione_abitante.get_current_speed_abitante);
                  end if;
               else
                  acceleration:= calculate_acceleration(mezzo => car,
                                                     id_abitante => current_posizione_abitante.get_id_abitante_posizione_abitanti,
                                                     id_quartiere_abitante => current_posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                     next_entity_distance => 0.0,
                                                     distance_to_stop_line => get_ingresso_from_id(id_task).get_lunghezza_road-current_posizione_abitante.get_where_now_posizione_abitanti+1.0,
                                                     next_id_quartiere_abitante => 0,
                                                     next_id_abitante => 0,
                                                     abitante_velocity => current_posizione_abitante.get_current_speed_abitante,
                                                     next_abitante_velocity =>0.0);
               end if;
               new_speed:= calculate_new_speed(current_posizione_abitante.get_current_speed_abitante,acceleration);
               new_step:= calculate_new_step(new_speed,acceleration);
               mailbox.set_move_parameters_entity_on_main_strada(range_1 => mailbox.get_index_inizio_moto,num_entity => i,speed => new_speed,step_to_advance => new_step);
               current_posizione_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
               if current_posizione_abitante.get_where_next_posizione_abitanti=get_ingresso_from_id(id_task).get_lunghezza_road then
                  traiettoria_type:= calculate_traiettoria_to_follow_from_ingresso(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti,id_task,resource_main_strada.get_ingressi_ordered_by_distance);
                  traiettoria_on_main_strada:= calculate_trajectory_to_follow_on_main_strada_from_ingresso(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti,id_task,traiettoria_type);
                  resource_main_strada.aggiungi_entità_from_ingresso(id_task,traiettoria_type,current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti,traiettoria_on_main_strada);
               end if;
            end if;
            list_abitanti:= list_abitanti.all.get_next_from_list_posizione_abitanti;
         end loop;

         new_requests:= mailbox.get_temp_main_strada;
         if new_requests/=null then
            list_abitanti:= mailbox.get_main_strada(mailbox.get_index_inizio_moto);
            current_posizione_abitante:= new_requests.all.get_posizione_abitanti_from_list_posizione_abitanti;
            if mailbox.get_number_entity_strada(mailbox.get_index_inizio_moto)/=0 then
               next_posizione_abitante:= list_abitanti.all.get_posizione_abitanti_from_list_posizione_abitanti;
               distance_to_next:= next_posizione_abitante.get_where_now_posizione_abitanti-move_parameters(get_quartiere_utilities_obj.all.get_auto_quartiere(next_posizione_abitante.get_id_quartiere_posizione_abitanti,next_posizione_abitante.get_id_abitante_posizione_abitanti)).get_length_entità_passiva-current_posizione_abitante.get_where_now_posizione_abitanti;
               if distance_to_next<=0.0 then acceleration:= 0.0;
               else
                  acceleration:= calculate_acceleration(mezzo => car,
                                                        id_abitante => current_posizione_abitante.get_id_abitante_posizione_abitanti,
                                                        id_quartiere_abitante => current_posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                        next_entity_distance => distance_to_next,
                                                        distance_to_stop_line => get_ingresso_from_id(id_task).get_lunghezza_road-current_posizione_abitante.get_where_now_posizione_abitanti+1.0,
                                                        next_id_quartiere_abitante => next_posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                        next_id_abitante => next_posizione_abitante.get_id_abitante_posizione_abitanti,
                                                        abitante_velocity => current_posizione_abitante.get_current_speed_abitante,
                                                        next_abitante_velocity => next_posizione_abitante.get_current_speed_abitante);
               end if;
            else
               acceleration:= calculate_acceleration(mezzo => car,
                                                     id_abitante => current_posizione_abitante.get_id_abitante_posizione_abitanti,
                                                     id_quartiere_abitante => current_posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                     next_entity_distance => 0.0,
                                                     distance_to_stop_line => get_ingresso_from_id(id_task).get_lunghezza_road-current_posizione_abitante.get_where_now_posizione_abitanti+1.0,
                                                     next_id_quartiere_abitante => 0,
                                                     next_id_abitante => 0,
                                                     abitante_velocity => current_posizione_abitante.get_current_speed_abitante,
                                                     next_abitante_velocity =>0.0);
            end if;
            new_speed:= calculate_new_speed(0.0,acceleration);
            new_step:= calculate_new_step(new_speed,acceleration);
            residente:= move_parameters(get_quartiere_utilities_obj.all.get_auto_quartiere(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti));
            if new_speed<0.0 then
               new_speed:= 0.0;
            end if;
            if new_step<0.0 then
               new_step:= 0.0;
            end if;
            mailbox.registra_abitante_to_move(road,new_speed,new_step);
            if new_step=get_ingresso_from_id(id_task).get_lunghezza_road then
               traiettoria_type:= calculate_traiettoria_to_follow_from_ingresso(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti,id_task,resource_main_strada.get_ingressi_ordered_by_distance);
               traiettoria_on_main_strada:= calculate_trajectory_to_follow_on_main_strada_from_ingresso(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti,id_task,traiettoria_type);
               resource_main_strada.aggiungi_entità_from_ingresso(id_task,traiettoria_type,current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti,traiettoria_on_main_strada);
            end if;
         end if;

         list_abitanti:= mailbox.get_main_strada(not mailbox.get_index_inizio_moto);
         for i in 1..mailbox.get_number_entity_strada(not mailbox.get_index_inizio_moto) loop
            mailbox.update_position_entity(road,not mailbox.get_index_inizio_moto,i);
            current_posizione_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
            -- elimino l'elemento se è fuori traiettoria
            if current_posizione_abitante.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva>=get_ingresso_from_id(id_task).get_lunghezza_road then
               mailbox.delete_car_in_entrata;
               get_quartiere_utilities_obj.get_classe_locate_abitanti(current_posizione_abitante.get_id_quartiere_posizione_abitanti).set_finish_route(current_posizione_abitante.get_id_abitante_posizione_abitanti);
               get_quartiere_entities_life(current_posizione_abitante.get_id_quartiere_posizione_abitanti).abitante_is_arrived(current_posizione_abitante.get_id_abitante_posizione_abitanti);
            else
               if i=1 and then current_posizione_abitante.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva>=0.0 then
                  if current_posizione_abitante.get_destination.get_corsia_to_go_trajectory=1 then
                     resource_main_strada.remove_first_element_traiettoria(id_task,entrata_andata);
                  else
                     resource_main_strada.remove_first_element_traiettoria(id_task,entrata_ritorno);
                  end if;
               end if;
               if list_abitanti.all.get_next_from_list_posizione_abitanti/=null then
                  next_posizione_abitante:= list_abitanti.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
                  distance_to_next:= next_posizione_abitante.get_where_now_posizione_abitanti-move_parameters(get_quartiere_utilities_obj.all.get_auto_quartiere(next_posizione_abitante.get_id_quartiere_posizione_abitanti,next_posizione_abitante.get_id_abitante_posizione_abitanti)).get_length_entità_passiva-current_posizione_abitante.get_where_now_posizione_abitanti;
                  if distance_to_next<=0.0 then acceleration:= 0.0;
                  else
                     acceleration:= calculate_acceleration(mezzo => car,
                                                     id_abitante => current_posizione_abitante.get_id_abitante_posizione_abitanti,
                                                     id_quartiere_abitante => current_posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                     next_entity_distance => distance_to_next,
                                                     distance_to_stop_line => get_ingresso_from_id(id_task).get_lunghezza_road-current_posizione_abitante.get_where_now_posizione_abitanti+1.0,
                                                     next_id_quartiere_abitante => next_posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                     next_id_abitante => next_posizione_abitante.get_id_abitante_posizione_abitanti,
                                                     abitante_velocity => current_posizione_abitante.get_current_speed_abitante,
                                                     next_abitante_velocity => next_posizione_abitante.get_current_speed_abitante);
                  end if;
               else
                  acceleration:= calculate_acceleration(mezzo => car,
                                                     id_abitante => current_posizione_abitante.get_id_abitante_posizione_abitanti,
                                                     id_quartiere_abitante => current_posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                     next_entity_distance => 0.0,
                                                     distance_to_stop_line => get_ingresso_from_id(id_task).get_lunghezza_road-current_posizione_abitante.get_where_now_posizione_abitanti+1.0,
                                                     next_id_quartiere_abitante => 0,
                                                     next_id_abitante => 0,
                                                     abitante_velocity => current_posizione_abitante.get_current_speed_abitante,
                                                        next_abitante_velocity =>0.0);
               end if;
               new_speed:= calculate_new_speed(current_posizione_abitante.get_current_speed_abitante,acceleration);
               new_step:= calculate_new_step(new_speed,acceleration);
               mailbox.set_move_parameters_entity_on_main_strada(range_1 => not mailbox.get_index_inizio_moto,num_entity => i,speed => new_speed,step_to_advance => new_step);
               current_posizione_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
               list_abitanti:= list_abitanti.all.get_next_from_list_posizione_abitanti;
            end if;
         end loop;
      end loop;

      --Put_Line("Fine task ingresso" & Positive'Image(id_task) & ",id quartiere" & Positive'Image(get_id_quartiere));
   end core_avanzamento_ingressi;

   task body core_avanzamento_incroci is
      id_task: Positive;
      mailbox: ptr_resource_segmento_incrocio;
      id_mancante: Natural:= 0;
      list_car: ptr_list_posizione_abitanti_on_road;
      list: ptr_list_posizione_abitanti_on_road;
      list_near_car: ptr_list_posizione_abitanti_on_road;
      list_near_other_car: ptr_list_posizione_abitanti_on_road;  -- altra traiettoria
      index_road: Positive;
      index_other_road: Positive;
      switch: Boolean;
      quantità_percorsa: Float:= 0.0;  --***************  TO DO communicate with other roads
      traiettoria_near_car: traiettoria_incroci_type;
      traiettoria_car: traiettoria_incroci_type;
      road: road_incrocio_features;
      tratto_road: tratto;
      id_quartiere_next_car: Positive;
      id_abitante_next_car: Positive;
      bound_distance: Float:= -1.0;
      distance_to_next_car: Float;
      distance_next_entity: Float;
      distanza_intersezione: Float;
      length_traiettoria: Float;
      new_abitante: posizione_abitanti_on_road;
      acceleration: Float;
      new_step: Float;
      new_speed: Float;
      limite: Float;
      stop_entity: Boolean;
      can_continue: Boolean;
   begin
      accept configure(id: Positive) do
         id_task:= id;
         mailbox:= get_incroci_segmento_resources(id);
         id_mancante:= get_mancante_incrocio_a_3(id_task);
      end configure;

      wait_settings_all_quartieri;
      --Put_Line("task " & Positive'Image(id_task) & " of quartiere " & Positive'Image(get_id_quartiere) & " is set");
      -- Ora i task e le risorse di tutti i quartieri sono attivi

      loop
         synchronization_with_delta(id_task);
         log_mio.write_task_arrived("id_task " & Positive'Image(id_task) & " id_quartiere " & Positive'Image(get_id_quartiere));
         mailbox.update_avanzamento_cars;
         for i in 1..mailbox.get_size_incrocio loop
            for j in id_corsie'Range loop
               list_car:= mailbox.get_list_car_to_move(i,j);
               index_road:= i;
               if id_mancante/=0 and i>=id_mancante then  -- condizione valida per incroci a 3
                  index_road:= i+1;
               end if;
               -- controlla se ci sono macchine da spostare
               while list_car/=null loop
                  traiettoria_car:= list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow;
                  length_traiettoria:= get_traiettoria_incrocio(traiettoria_car).get_lunghezza_traiettoria_incrocio;
                  if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                                                                                                                  list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva>=0.0 then
                     tratto_road:= get_quartiere_utilities_obj.get_classe_locate_abitanti(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_current_tratto(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                     -- l'incrocio sta nel quartiere in cui sta girando questo codice
                     ptr_rt_urbana(get_id_risorsa_quartiere(tratto_road.get_id_quartiere_tratto,tratto_road.get_id_tratto)).remove_abitante_in_incrocio(get_road_from_incrocio(id_task,get_index_road_from_incrocio(tratto_road.get_id_quartiere_tratto,tratto_road.get_id_tratto,id_task)).get_polo_road_incrocio,list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                  end if;
                  if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<length_traiettoria then
                     stop_entity:= False;
                     bound_distance:= -1.0;  -- to fix that bound_distance is not set
                     if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 then
                        -- begin inizializzazione di stop entity
                        if mailbox.get_verso_semafori_verdi=True and then (index_road=1 or index_road=3) then
                           stop_entity:= False;
                        elsif mailbox.get_verso_semafori_verdi=False and then (index_road=2 or index_road=4) then
                           stop_entity:= False;
                        else
                           stop_entity:= True;
                        end if;
                        -- end inizializzazione
                        switch:= True;
                        if stop_entity=False then  -- se la macchina non deve fermarsi e c'è la strada a sinistra
                           index_other_road:= index_road+1;
                           if index_road+1=5 then
                              index_other_road:= 1;
                           end if;
                           if id_mancante/=0 and then id_mancante=index_other_road then -- la strada a sx non esiste
                              switch:= False;
                           end if;
                           index_other_road:= i+1;
                           if id_mancante/=0 then
                              if i+1=4 then
                                 index_other_road:= 1;
                              end if;
                           else
                              if i+1=5 then
                                 index_other_road:= 1;
                              end if;
                           end if;
                           for z in id_corsie'Range loop
                              list_near_car:= mailbox.get_list_car_to_move(index_other_road,z);
                              can_continue:= True;
                              if traiettoria_car=destra and z=2 then
                                 can_continue:= False; -- per le macchine in svolta a dx tutti i controlli sono già stati fatti
                              end if;
                              case traiettoria_car is
                              when dritto | empty =>  -- caso non presentabile
                                 limite:= 0.0;
                              when dritto_1 | destra =>
                                 limite:= get_traiettoria_incrocio(dritto_1).get_lunghezza_traiettoria_incrocio; -- lunghezza traiettoria dritto1/2; quando necessiti di una traiettoria dritto usa dritto1
                              when dritto_2 | sinistra =>
                                 limite:= get_traiettoria_incrocio(dritto_1).get_lunghezza_traiettoria_incrocio-get_larghezza_marciapiede-get_larghezza_corsia;
                              end case;

                              while can_continue and stop_entity=False and list_near_car/=null loop
                                 traiettoria_near_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow;
                                 if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti/=0.0 then
                                    if traiettoria_near_car=dritto_1 or traiettoria_near_car=dritto_2 then
                                       if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_incrocio(dritto_1).get_lunghezza_traiettoria_incrocio then
                                          road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,index_other_road,traiettoria_near_car));
                                          quantità_percorsa:= ptr_rt_urbana(get_id_risorsa_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                                       else
                                          quantità_percorsa:= 0.0;
                                       end if;
                                       if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                                         get_quartiere_utilities_obj.get_auto_quartiere(list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva+
                                         quantità_percorsa<limite then
                                          stop_entity:= True;
                                       end if;
                                    elsif traiettoria_near_car=sinistra then -- non entrerà mai per z=1
                                       if traiettoria_car=dritto_2 then
                                          if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_incrocio(sinistra).get_lunghezza_traiettoria_incrocio then
                                             road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,index_other_road,traiettoria_near_car));
                                             quantità_percorsa:= ptr_rt_urbana(get_id_risorsa_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                                          else
                                             quantità_percorsa:= 0.0;
                                          end if;
                                          if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+quantità_percorsa-
                                            get_quartiere_utilities_obj.get_auto_quartiere(list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva>=get_traiettoria_incrocio(sinistra).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                                             bound_distance:= get_larghezza_marciapiede+get_larghezza_corsia*2.0; --  larghezza di una mezza strada
                                          else
                                             stop_entity:= True;
                                          end if;
                                       elsif traiettoria_car=sinistra then
                                          if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_incrocio(sinistra).get_lunghezza_traiettoria_incrocio then
                                             road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,index_other_road,traiettoria_near_car));
                                             quantità_percorsa:= ptr_rt_urbana(get_id_risorsa_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                                          else
                                             quantità_percorsa:= 0.0;
                                          end if;
                                          if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+quantità_percorsa-
                                            get_quartiere_utilities_obj.get_auto_quartiere(list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                                            get_traiettoria_incrocio(sinistra).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                                             stop_entity:= True;
                                          end if;
                                       end if;
                                    end if;
                                 end if;
                                 list_near_car:= list_near_car.get_next_from_list_posizione_abitanti;
                              end loop;
                           end loop;
                           can_continue:= True;
                           if traiettoria_car=destra then
                              can_continue:= False;  -- per le macchine in svolta a dx tutti i controlli sono già stati fatti
                           end if;
                           if can_continue then
                              switch:= True;
                              index_other_road:= index_road-1;
                              if index_road-1=0 then
                                 index_other_road:= 4;
                              end if;
                              if id_mancante/=0 and then id_mancante=index_other_road then -- la strada a dx non esiste
                                 switch:= False;
                              end if;
                              if stop_entity=False and then switch then  -- la macchina non deve già fermarsi
                                 -- check macchine a destra
                                 index_other_road:= i-1;
                                 if id_mancante/=0 then
                                    if i-1=0 then
                                       index_other_road:= 3;
                                    end if;
                                 else
                                    if i-1=0 then
                                       index_other_road:= 4;
                                    end if;
                                 end if;
                                 for z in id_corsie'Range loop
                                    list_near_car:= mailbox.get_list_car_to_move(index_other_road,z);
                                    case traiettoria_car is
                                    when dritto | destra | empty =>  -- caso non presentabile
                                       limite:= 0.0;
                                    when dritto_1  =>
                                       limite:= get_larghezza_marciapiede+get_larghezza_corsia; -- lunghezza mezza corsia
                                    when dritto_2  =>
                                       limite:= get_larghezza_marciapiede+get_larghezza_corsia*2.0; -- lunghezza mezza strada
                                    when sinistra =>
                                       limite:= get_traiettoria_incrocio(sinistra).get_lunghezza_traiettoria_incrocio;  -- lunghezza strada intera
                                    end case;
                                    while stop_entity=False and list_near_car/=null loop
                                       traiettoria_near_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow;
                                       if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti/=0.0 then
                                          if traiettoria_near_car=dritto_1 or traiettoria_near_car=dritto_2 then
                                             if traiettoria_car=dritto_1 or traiettoria_car=dritto_2 then
                                                if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_incrocio(dritto_1).get_lunghezza_traiettoria_incrocio then
                                                   road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,index_other_road,traiettoria_near_car));
                                                   quantità_percorsa:= ptr_rt_urbana(get_id_risorsa_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                                                else
                                                   quantità_percorsa:= 0.0;
                                                end if;
                                                if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                                                  get_quartiere_utilities_obj.get_auto_quartiere(list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva+
                                                  quantità_percorsa<limite then
                                                   stop_entity:= True;
                                                else
                                                   if traiettoria_near_car=dritto_2 then
                                                      bound_distance:= get_larghezza_marciapiede+get_larghezza_corsia; -- 1 strada
                                                   else
                                                      bound_distance:= get_larghezza_marciapiede+get_larghezza_corsia*3.0; -- 1 strada e 1/2
                                                   end if;
                                                end if;
                                             elsif traiettoria_car=sinistra then
                                                stop_entity:= True;
                                             end if;
                                          elsif traiettoria_near_car=destra and traiettoria_car=dritto_1 then -- per z=2 non entrerà mai
                                             bound_distance:= get_larghezza_marciapiede+get_larghezza_corsia*3.0; -- 1 strada e 1/2
                                          elsif traiettoria_near_car=sinistra then-- per z=1 non entrerà mai
                                             if traiettoria_car=dritto_1 then
                                                if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                                                  get_quartiere_utilities_obj.get_auto_quartiere(list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                                                 list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<get_traiettoria_incrocio(sinistra).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                                                   stop_entity:= True;
                                                else
                                                   bound_distance:= get_larghezza_marciapiede+get_larghezza_corsia*2.0;
                                                end if;
                                             elsif traiettoria_car=dritto_2 then
                                                stop_entity:= True;
                                             end if;
                                          end if;
                                       end if;
                                       list_near_car:= list_near_car.get_next_from_list_posizione_abitanti;
                                    end loop;
                                 end loop;
                              end if;
                              -- guardo se esiste la strada opposta a quella corrente
                              if index_road=1 then
                                 index_other_road:= 3;
                              elsif index_road=2 then
                                 index_other_road:= 4;
                              elsif index_road=3 then
                                 index_other_road:= 1;
                              elsif index_road=4 then
                                 index_other_road:= 2;
                              end if;
                              if id_mancante/=index_other_road and stop_entity=False then  -- è presente una strada opposta a quella corrente
                                 if id_mancante/=0 and index_other_road>id_mancante then  -- condizione valida per incroci a 3
                                    index_other_road:= index_other_road-1;
                                 end if;
                                 if traiettoria_car=dritto_1 or traiettoria_car=dritto_2 then
                                    list_near_car:= mailbox.get_list_car_to_move(index_other_road,2);
                                    while list_near_car/=null loop
                                       traiettoria_near_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow;
                                       if traiettoria_near_car=sinistra and list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 then
                                          stop_entity:= True;
                                       end if;
                                       list_near_car:= list_near_car.get_next_from_list_posizione_abitanti;
                                    end loop;
                                 elsif traiettoria_car=sinistra then
                                    for z in id_corsie'Range loop
                                       list_near_car:= mailbox.get_list_car_to_move(index_other_road,z);
                                       while list_near_car/=null loop
                                          traiettoria_near_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow;
                                          if traiettoria_near_car=dritto_1 or traiettoria_near_car=dritto_2 then
                                             if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_incrocio(sinistra).get_lunghezza_traiettoria_incrocio then
                                                road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,index_other_road,traiettoria_near_car));
                                                quantità_percorsa:= ptr_rt_urbana(get_id_risorsa_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                                             else
                                                quantità_percorsa:= 0.0;
                                             end if;
                                             if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+quantità_percorsa+get_quartiere_utilities_obj.get_auto_quartiere(list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                                                                                                                                                                     list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                                               get_traiettoria_incrocio(dritto_1).get_lunghezza_traiettoria_incrocio-get_larghezza_marciapiede-get_larghezza_corsia then  -- distanza ultima corsia
                                                stop_entity:= True;
                                             end if;
                                          end if;
                                          list_near_car:= list_near_car.get_next_from_list_posizione_abitanti;
                                       end loop;
                                    end loop;
                                 end if;
                              end if;
                           end if;
                        end if;
                     end if;
                     if stop_entity=False then
                        if index_road=1 then
                           index_other_road:= 3;
                        elsif index_road=2 then
                           index_other_road:= 4;
                        elsif index_road=3 then
                           index_other_road:= 1;
                        elsif index_road=4 then
                           index_other_road:= 2;
                        end if;
                        switch:= False;
                        if id_mancante/=index_other_road then
                           if id_mancante/=0 and index_other_road>id_mancante then  -- condizione valida per incroci a 3
                              index_other_road:= index_other_road-1;
                           end if;
                        else
                           switch:= True;
                        end if;
                        if traiettoria_car=destra then
                           list:= list_car.get_next_from_list_posizione_abitanti;
                           list_near_car:= null;
                           list_near_other_car:= null;
                           while list/=null loop
                              traiettoria_near_car:= list.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow;
                              if list_near_other_car=null and traiettoria_near_car=dritto_1 then
                                 list_near_other_car:= list;
                              end if;
                              if list_near_car/=null and traiettoria_near_car=destra then
                                 list_near_car:= list;
                              end if;
                              list:= list.get_next_from_list_posizione_abitanti;
                           end loop;
                           -- list_near_car è la macchina a destra presente
                           -- list_near_other_car è la prima macchina che si incontrerebbe procedendo diritti
                           if list_near_other_car/=null and then list_near_other_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                             get_quartiere_utilities_obj.get_auto_quartiere(list_near_other_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                            list_near_other_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<get_larghezza_corsia+get_larghezza_marciapiede then
                              stop_entity:= True;
                           end if;
                           if stop_entity=False then
                              if list_near_car/=null then  -- si ha una macchina davanti che è in svolta a dx
                                 id_quartiere_next_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                                 id_abitante_next_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                                 if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_incrocio(destra).get_lunghezza_traiettoria_incrocio then
                                    road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,i,traiettoria_car));
                                    quantità_percorsa:= ptr_rt_urbana(get_id_risorsa_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                                 else
                                    quantità_percorsa:= 0.0;
                                 end if;
                                   distance_to_next_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+quantità_percorsa-
                                   get_quartiere_utilities_obj.get_auto_quartiere(id_quartiere_next_car,id_abitante_next_car).get_length_entità_passiva;
                              else
                                 road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,i,traiettoria_car));
                                 distance_to_next_car:= ptr_rt_urbana(get_id_risorsa_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,1);
                                 if distance_to_next_car/=-1.0 then
                                    distance_to_next_car:= distance_to_next_car+get_traiettoria_incrocio(destra).get_lunghezza_traiettoria_incrocio-list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                                 end if;
                              end if;
                           end if;
                        elsif traiettoria_car=dritto_1 or traiettoria_car=dritto_2 then
                           -- primo step di fermo a intersezione traiettoria sx - 3.0
                           -- è presente la strada opposta alla strada corrente
                           -- cerca elemento della strada opposita che vuole girara a sinistra

                           -- prima viene calcolato se la macchina può avanzare in relazione alle macchine che ha davanti
                           list:= list_car.get_next_from_list_posizione_abitanti;
                           list_near_car:= null;
                           list_near_other_car:= null;
                           while list/=null and (list_near_other_car=null or list_near_car=null) loop
                              traiettoria_near_car:= list.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow;
                              if list_near_other_car=null and (traiettoria_near_car=destra or traiettoria_near_car=sinistra) then
                                 list_near_other_car:= list;
                              end if;
                              if list_near_car/=null and (traiettoria_near_car=dritto_1 or traiettoria_near_car=dritto_2) then
                                 list_near_car:= list;
                              end if;
                              list:= list.get_next_from_list_posizione_abitanti;
                           end loop;
                           if list_near_other_car/=null then
                              traiettoria_near_car:= list_near_other_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow;
                              if traiettoria_near_car=destra then
                                 stop_entity:= True;
                              else  --  =sinistra
                                 if list_near_other_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                                   get_quartiere_utilities_obj.get_auto_quartiere(list_near_other_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                                  list_near_other_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                                   get_traiettoria_incrocio(sinistra).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                                    stop_entity:= True;
                                 end if;
                              end if;
                           end if;
                           if stop_entity=False then
                              if list_near_car/=null then  -- si ha una macchina davanti che procede in direzione dritto_1/dritto_2
                                 id_quartiere_next_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                                 id_abitante_next_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                                 if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_incrocio(dritto_1).get_lunghezza_traiettoria_incrocio then
                                    road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,i,traiettoria_car));
                                    quantità_percorsa:= ptr_rt_urbana(get_id_risorsa_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                                 else
                                    quantità_percorsa:= 0.0;
                                 end if;
                                 distance_to_next_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+quantità_percorsa-
                                   get_quartiere_utilities_obj.get_auto_quartiere(id_quartiere_next_car,id_abitante_next_car).get_length_entità_passiva;
                              else
                                 road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,i,traiettoria_car));
                                 if traiettoria_car=dritto_1 then
                                    distance_to_next_car:= ptr_rt_urbana(get_id_risorsa_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,1);  -- ask next strada dovè la prox macchina + somma la traiettoria percorsa
                                 else
                                    distance_to_next_car:= ptr_rt_urbana(get_id_risorsa_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,2);  -- ask next strada dovè la prox macchina + somma la traiettoria percorsa
                                 end if;
                                 if distance_to_next_car/=-1.0 then
                                    distance_to_next_car:= distance_to_next_car+get_traiettoria_incrocio(dritto_1).get_lunghezza_traiettoria_incrocio-list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                                 end if;
                                 -- ask next strada dovè la prox macchina + somma la traiettoria percorsa
                              end if;
                              if switch=False then
                                 -- si controlla se la macchina ha delle macchine a sx che avanzano nella strada opposta

                                 distanza_intersezione:= get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(traiettoria_car).get_distanza_intersezione_incrocio;
                                 limite:= get_traiettoria_incrocio(traiettoria_car).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio;

                                 -- controlla se ho macchine che arrivano da sx solo se posso trovarmele davanti
                                 if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=limite-max_larghezza_veicolo then
                                    list_near_car:= mailbox.get_list_car_to_move(index_other_road,2);
                                    while list_near_car/=null and stop_entity=False loop
                                       traiettoria_near_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow;
                                       if traiettoria_near_car=sinistra then
                                          if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distanza_intersezione-max_larghezza_veicolo then
                                             --  distanza_intersezione-max_larghezza_veicolo indica distanza pt intersezione con traiettoria dritto_1
                                             -- si ferma sempre nel punto istanza_intersezione-max_larghezza_veicolo, la volta dopo avanza sse non si hanno macchine che vanno diritte
                                             if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_incrocio(sinistra).get_lunghezza_traiettoria_incrocio then
                                                road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,index_other_road,traiettoria_near_car));
                                                quantità_percorsa:= ptr_rt_urbana(get_id_risorsa_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                                             else
                                                quantità_percorsa:= 0.0;
                                             end if;
                                             id_quartiere_next_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                                             id_abitante_next_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                                             if quantità_percorsa+list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                                               get_quartiere_utilities_obj.get_auto_quartiere(id_quartiere_next_car,id_abitante_next_car).get_length_entità_passiva<limite then
                                                stop_entity:= True;
                                             end if;
                                          end if;
                                       end if;
                                       list_near_car:= list_near_car.get_next_from_list_posizione_abitanti;
                                    end loop;
                                 end if;
                              end if;
                           end if;
                        elsif traiettoria_car=sinistra then
                           list:= list_car.get_next_from_list_posizione_abitanti;
                           list_near_car:= null;
                           list_near_other_car:= null;
                           while list/=null and (list_near_other_car=null or list_near_car=null) loop
                              traiettoria_near_car:= list.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow;
                              if list_near_other_car=null and traiettoria_near_car=dritto_2 then
                                 list_near_other_car:= list;
                              end if;
                              if list_near_car/=null and traiettoria_near_car=sinistra then
                                 list_near_car:= list;
                              end if;
                              list:= list.get_next_from_list_posizione_abitanti;
                           end loop;
                           if list_near_other_car/=null then
                              if list_near_other_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                                get_quartiere_utilities_obj.get_auto_quartiere(list_near_other_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                            list_near_other_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<get_larghezza_marciapiede+get_larghezza_corsia*1.5 then
                                 stop_entity:= True;
                              end if;
                           end if;
                           if stop_entity=False then
                              if list_near_car/=null then  -- si ha una macchina davanti che procede in direzione dritto_1/dritto_2
                                 id_quartiere_next_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                                 id_abitante_next_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                                 if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_incrocio(sinistra).get_lunghezza_traiettoria_incrocio then
                                    road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,i,traiettoria_car));
                                    quantità_percorsa:= ptr_rt_urbana(get_id_risorsa_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                                 else
                                    quantità_percorsa:= 0.0;
                                 end if;
                                 distance_to_next_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+quantità_percorsa-
                                   get_quartiere_utilities_obj.get_auto_quartiere(id_quartiere_next_car,id_abitante_next_car).get_length_entità_passiva;
                              else
                                 road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,i,traiettoria_car));
                                 distance_to_next_car:= ptr_rt_urbana(get_id_risorsa_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,2);  -- ask next strada dovè la prox macchina + somma la traiettoria percorsa
                                 if distance_to_next_car/=-1.0 then
                                    distance_to_next_car:= distance_to_next_car+get_traiettoria_incrocio(sinistra).get_lunghezza_traiettoria_incrocio-list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                                 end if;
                              end if;
                              if switch=False then  -- esiste la strada opposta
                                 for z in reverse id_corsie'Range loop
                                    list_near_car:= mailbox.get_list_car_to_move(index_other_road,z);
                                    while stop_entity=False and list_near_car/=null loop
                                       -- cicla e guarda se ci sono macchine che vogliono andare dritto
                                       if z=2 and then list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=
                                         get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_2).get_distanza_intersezione_incrocio-max_larghezza_veicolo then
                                          -- distanza con intersezione dritto2
                                          -- si ha una macchina che vuole andare verso dritto_2 dato che list_near_car/=null
                                          if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                                            get_quartiere_utilities_obj.get_auto_quartiere(list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                                           list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                                            get_traiettoria_incrocio(dritto_2).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio+max_larghezza_veicolo then
                                             stop_entity:= True;
                                          end if;
                                       elsif z=1 and then list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=
                                         get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_1).get_distanza_intersezione_incrocio-max_larghezza_veicolo then
                                          if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                                            get_quartiere_utilities_obj.get_auto_quartiere(list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                                        list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                                            get_traiettoria_incrocio(dritto_1).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio-max_larghezza_veicolo then -- distanza dritto1 intersecata sinistra
                                             stop_entity:= True;
                                          end if;
                                       end if;
                                       list_near_car:= list_near_car.get_next_from_list_posizione_abitanti;
                                    end loop;
                                 end loop;
                              end if;
                           end if;
                        end if;
                     end if;

                     -- aggiornamento posizione macchina
                     if stop_entity=False then  -- la macchina può avanzare
                        switch:= False;
                        if bound_distance/=-1.0 then
                           -- la macchina deve fermarsi all'interno dell'incrocio
                           -- bound_distance è settato per macchine che vanno in direzione dritto_1 o dritto_2
                           -- distance_to_next_car can be -1.0 if there aren't cars in front of
                           if distance_to_next_car/=-1.0 then
                              if bound_distance<=distance_to_next_car then
                                 distance_next_entity:= bound_distance;
                              else
                                 distance_next_entity:= distance_to_next_car;
                              end if;
                           else
                              switch:= True;  -- non si ha bound per macchine che stanno davanti
                           end if;
                        else
                           if distance_to_next_car/=-1.0 then
                              distance_next_entity:= distance_to_next_car;
                           else
                              switch:= True;  -- non si ha bound per macchine che stanno davanti
                           end if;
                        end if;
                        if switch then
                           case traiettoria_car is  -- set distance next entity to length traiettoria
                           when dritto | empty => null;
                           when others =>
                              distance_next_entity:= get_traiettoria_incrocio(traiettoria_car).get_lunghezza_traiettoria_incrocio;
                           end case;
                           distance_next_entity:= get_larghezza_marciapiede+get_larghezza_corsia+distance_next_entity-list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                        end if;
                        -- distance_next_entity is set
                        acceleration:= calculate_acceleration(mezzo => car,
                                                           id_abitante => list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                           id_quartiere_abitante => list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                           next_entity_distance => 0.0,
                                                           distance_to_stop_line => distance_next_entity,
                                                           next_id_quartiere_abitante => 0,
                                                           next_id_abitante => 0,
                                                           abitante_velocity => list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante,
                                                              next_abitante_velocity =>0.0);
                        new_speed:= calculate_new_speed(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante,acceleration);
                        new_step:= calculate_new_step(new_speed,acceleration);
                        -- update scaglioni
                        if traiettoria_car=sinistra then
                           if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<
                             get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_2).get_distanza_intersezione_incrocio-max_larghezza_veicolo then
                              if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_2).get_distanza_intersezione_incrocio-max_larghezza_veicolo then
                                 new_step:= get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_2).get_distanza_intersezione_incrocio-max_larghezza_veicolo-list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                              end if;
                           elsif list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_1).get_distanza_intersezione_incrocio-max_larghezza_veicolo then
                              if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_1).get_distanza_intersezione_incrocio-max_larghezza_veicolo then
                                 new_step:= get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_1).get_distanza_intersezione_incrocio-max_larghezza_veicolo-list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                              end if;
                           end if;
                        elsif traiettoria_car=dritto_2 then
                           if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_incrocio(dritto_2).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio-max_larghezza_veicolo then
                              if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>get_traiettoria_incrocio(dritto_2).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio-max_larghezza_veicolo then
                                 new_step:= get_traiettoria_incrocio(dritto_2).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio-max_larghezza_veicolo-list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                              end if;
                           end if;
                        elsif traiettoria_car=dritto_1 then
                           if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_incrocio(dritto_1).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio-max_larghezza_veicolo then
                              if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>get_traiettoria_incrocio(dritto_1).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio-max_larghezza_veicolo then
                                 new_step:= get_traiettoria_incrocio(dritto_1).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio-max_larghezza_veicolo-list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                              end if;
                           end if;
                        end if;
                        -- end update scaglioni
                        mailbox.update_avanzamento_car(list_car,new_step,new_speed);
                        Put_Line("id_abitante " & Positive'Image(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & Float'Image(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is incrocio " & Positive'Image(id_task));
                        if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>=length_traiettoria then
                           -- passaggio della macchina all'incrocio
                           road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,i,traiettoria_car));
                           new_abitante:= posizione_abitanti_on_road(create_new_posizione_abitante_from_copy(list_car.get_posizione_abitanti_from_list_posizione_abitanti));
                           new_abitante.set_where_now_abitante(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti-length_traiettoria);
                           new_abitante.set_where_next_abitante(new_abitante.get_where_now_posizione_abitanti);
                           new_abitante.set_in_overtaken(False);
                           new_abitante.set_came_from_ingresso(False);
                           new_abitante.set_flag_overtake_next_corsia(False);
                           -- posizionamento all'incrocio corrente
                           get_quartiere_utilities_obj.get_classe_locate_abitanti(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).set_position_abitante_to_next(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                           -- calcolo della traiettoria da seguire
                           new_abitante.set_destination(calculate_trajectory_to_follow_on_main_strada_from_incrocio(posizione_abitanti_on_road(list_car.get_posizione_abitanti_from_list_posizione_abitanti),not road.get_polo_road_incrocio,list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory));
                           ptr_rt_urbana(get_id_risorsa_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).insert_abitante_from_incrocio(new_abitante,not road.get_polo_road_incrocio,list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                        end if;
                     end if;
                  end if;
                  list_car:= list_car.get_next_from_list_posizione_abitanti;
               end loop;
            end loop;
         end loop;

         mailbox.delta_terminate;
      end loop;

      --Put_Line("Fine task incrocio" & Positive'Image(id_task) & ",id quartiere" & Positive'Image(get_id_quartiere));
   end core_avanzamento_incroci;

   task body core_avanzamento_rotonde is
      id_task: Positive;
      mailbox: ptr_resource_segmento_rotonda;
   begin
      accept configure(id: Positive) do
         id_task:= id;
         mailbox:= get_rotonde_segmento_resources(id);
      end configure;

      wait_settings_all_quartieri;
      Put_Line(Positive'Image(id_task));
      -- Ora i task e le risorse di tutti i quartieri sono attivi

      -- loop
      --synchronization_with_delta(id_task);
      -- end loop;

      Put_Line("Fine task" & Positive'Image(id_task) & ",id quartiere" & Positive'Image(get_id_quartiere));
   end core_avanzamento_rotonde;

begin
   configure_tasks;
end risorse_strade_e_incroci;
