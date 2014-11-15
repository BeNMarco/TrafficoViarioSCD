with Ada.Text_IO;
with Ada.Numerics.Elementary_Functions;
with Ada.Exceptions;
with GNATCOLL.JSON;

with strade_e_incroci_common;
with remote_types;
with resource_map_inventory;
with risorse_mappa_utilities;
with the_name_server;
with mailbox_risorse_attive;
with synchronization_task_partition;
with risorse_passive_data;
with data_quartiere;
with snapshot_quartiere;
with model_webserver_communication_protocol_utilities;

use Ada.Text_IO;
use Ada.Numerics.Elementary_Functions;
use GNATCOLL.JSON;
use Ada.Exceptions;

use strade_e_incroci_common;
use remote_types;
use resource_map_inventory;
use risorse_mappa_utilities;
use the_name_server;
use mailbox_risorse_attive;
use synchronization_task_partition;
use risorse_passive_data;
use data_quartiere;
use snapshot_quartiere;
use model_webserver_communication_protocol_utilities;

package body risorse_strade_e_incroci is

   function calculate_acceleration(mezzo: means_of_carrying; id_abitante: Positive; id_quartiere_abitante: Positive; next_entity_distance: Float; distance_to_stop_line: Float; next_id_quartiere_abitante: Natural; next_id_abitante: Natural; abitante_velocity: in out Float; next_abitante_velocity: Float; disable_rallentamento_1: Boolean:= False; disable_rallentamento_2: Boolean:= False) return Float is
      residente: move_parameters;
      delta_speed: Float:= 0.0;
      free_road_coeff: Float;
      time_gap: Float;
      break_gap: Float;
      safe_distance: Float;
      busy_road_coeff: Float;
      --safe_intersection_distance: Float;
      next_step: Float;
      next_speed: Float;
      intersection_coeff: Float:= 0.0;
      coeff: Float;
      begin_velocity: Float:= abitante_velocity;
   begin
      case mezzo is
         when walking | autobus =>
            residente:= move_parameters(get_quartiere_utilities_obj.all.get_pedone_quartiere(id_quartiere_abitante,id_abitante));
         when bike =>
            residente:= move_parameters(get_quartiere_utilities_obj.all.get_bici_quartiere(id_quartiere_abitante,id_abitante));
         when car =>
            residente:= move_parameters(get_quartiere_utilities_obj.all.get_auto_quartiere(id_quartiere_abitante,id_abitante));
      end case;
      if distance_to_stop_line<0.0 or else next_entity_distance<0.0 then
         return 0.0;
      end if;
      while (distance_to_stop_line/=0.0 and then distance_to_stop_line<abitante_velocity) or else (next_entity_distance/=0.0 and then next_entity_distance<abitante_velocity) loop
         abitante_velocity:= abitante_velocity/2.0;
      end loop;

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
         --if next_entity_distance=0.0 then -- distance_stop_before_end_road vale True
         --   busy_road_coeff:= (safe_distance/distance_to_stop_line)**2;
         --else
         --   busy_road_coeff:= (safe_distance/next_entity_distance)**2;
         --end if;
      end if;

      -- begin parameters not in the IDM models:
      if next_entity_distance=0.0 then-- and distance_stop_before_end_road=False then
         intersection_coeff:= (abitante_velocity/distance_to_stop_line)**2;
         coeff:= 1.0 - free_road_coeff - intersection_coeff;

         if (free_road_coeff>intersection_coeff and intersection_coeff>0.0) then
            coeff:= (((residente.get_desired_velocity-abitante_velocity)/delta_value)/2.0)/residente.get_max_acceleration;
         end if;
         --if begin_velocity>distance_to_stop_line or else (disable_rallentamento=False and distance_to_stop_line<=distance_at_witch_decelarate) then
         next_speed:= calculate_new_speed(abitante_velocity,residente.get_max_acceleration*coeff);
         --next_step:= calculate_new_step(next_speed,residente.get_max_acceleration*coeff);

         if disable_rallentamento_2=False and then distance_to_stop_line>distance_at_witch_decelarate then
            while distance_to_stop_line-calculate_new_step(next_speed,residente.get_max_acceleration*coeff)<=(distance_at_witch_decelarate/2.0-1.0) loop
               coeff:= coeff/2.0;
               abitante_velocity:= abitante_velocity/2.0;
               next_step:= calculate_new_step(next_speed,residente.get_max_acceleration*coeff);
               next_speed:= calculate_new_speed(abitante_velocity,residente.get_max_acceleration*coeff);
            end loop;
         end if;

         if disable_rallentamento_1=False and distance_to_stop_line<=distance_at_witch_decelarate then
            if coeff*residente.get_max_acceleration>distance_at_witch_decelarate then
               coeff:= distance_at_witch_decelarate/residente.get_max_acceleration;
            end if;
         end if;
      else
         --safe_intersection_distance:= 1.0 + time_gap + (abitante_velocity**2)/(2.0*residente.get_comfortable_deceleration);
         --if safe_intersection_distance<distance_to_stop_line and safe_intersection_distance>abitante_velocity then
         --   intersection_coeff:= (safe_intersection_distance/distance_to_stop_line)**2;
         --else
         --   intersection_coeff:= (abitante_velocity/distance_to_stop_line)**2;
         --end if;

         --if intersection_coeff<busy_road_coeff and busy_road_coeff<1.0 then
         --   intersection_coeff:= 0.0;
         --else
         --   busy_road_coeff:= 0.0;
         --end if;


         if busy_road_coeff>=1.0 then
            busy_road_coeff:= (abitante_velocity/next_entity_distance)**2;
         end if;

         if (free_road_coeff>busy_road_coeff and busy_road_coeff>0.0) then
            coeff:= (((residente.get_desired_velocity-abitante_velocity)/delta_value)/2.0)/residente.get_max_acceleration;
         else
            coeff:= 1.0 - free_road_coeff - busy_road_coeff;-- - intersection_coeff;
         end if;

      end if;
      -- end parameters

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
         corsia_traiettoria:= 2;
         corsia_to_go_if_dritto:= 2;
      elsif traiettoria_type=uscita_ritorno then
         corsia_traiettoria:= 1;
         corsia_to_go_if_dritto:= 1;
      else
         corsia_traiettoria:= 0;
      end if;
      next_nodo:= get_quartiere_utilities_obj.get_classe_locate_abitanti(id_quartiere_abitante).get_next(id_abitante);
      next_road:= get_quartiere_utilities_obj.get_classe_locate_abitanti(id_quartiere_abitante).get_next_road(id_abitante,True);
      if next_nodo.get_id_quartiere_tratto=get_id_quartiere and then (next_nodo.get_id_tratto>=get_from_ingressi and next_nodo.get_id_tratto<=get_to_ingressi) then -- forse nodo è già l'ingresso di destinazione
         if traiettoria_type=uscita_andata then
            return create_trajectory_to_follow(corsia_traiettoria,2,next_nodo.get_id_tratto,from_ingresso,empty);
         elsif traiettoria_type=uscita_ritorno then
            if get_ingresso_from_id(next_nodo.get_id_tratto).get_polo_ingresso=get_ingresso_from_id(from_ingresso).get_polo_ingresso then
               return create_trajectory_to_follow(corsia_traiettoria,1,next_nodo.get_id_tratto,from_ingresso,empty);
            else
               return create_trajectory_to_follow(corsia_traiettoria,2,next_nodo.get_id_tratto,from_ingresso,empty);
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
               if corsia_to_go_if_dritto=1 then
                  return create_trajectory_to_follow(corsia_traiettoria,corsia_to_go_if_dritto,0,from_ingresso,dritto_1);
               else
                  return create_trajectory_to_follow(corsia_traiettoria,corsia_to_go_if_dritto,0,from_ingresso,dritto_2);
               end if;
            elsif index_road_to>index_road_from or (index_road_to=1 and index_road_from=4) then
               return create_trajectory_to_follow(corsia_traiettoria,1,0,from_ingresso,sinistra);
            else
               return create_trajectory_to_follow(corsia_traiettoria,2,0,from_ingresso,destra);
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
      id_road: Natural;
   begin
      -- next_nodo sarà o la strada corrente o un suo ingresso
      next_nodo:= get_quartiere_utilities_obj.get_classe_locate_abitanti(abitante.get_id_quartiere_posizione_abitanti).get_next(abitante.get_id_abitante_posizione_abitanti);
      Put_Line(Positive'Image(get_quartiere_utilities_obj.get_classe_locate_abitanti(abitante.get_id_quartiere_posizione_abitanti).get_number_steps_to_finish_route(abitante.get_id_abitante_posizione_abitanti)));
      if get_quartiere_utilities_obj.get_classe_locate_abitanti(abitante.get_id_quartiere_posizione_abitanti).get_number_steps_to_finish_route(abitante.get_id_abitante_posizione_abitanti)=1 then
         -- la macchina deve percorrere l'ultimo pezzo di strada
         if get_quartiere_cfg(next_nodo.get_id_quartiere_tratto).get_polo_ingresso(next_nodo.get_id_tratto)/=polo then
            return create_trajectory_to_follow(num_corsia,2,next_nodo.get_id_tratto,0,empty);
         else
            return create_trajectory_to_follow(num_corsia,1,next_nodo.get_id_tratto,0,empty);
         end if;
      else
         -- la macchina deve percorrere tutta la strada
         -- deve percorre ancora almeno 3 entità
         next_incrocio:= get_quartiere_utilities_obj.get_classe_locate_abitanti(abitante.get_id_quartiere_posizione_abitanti).get_next_incrocio(abitante.get_id_abitante_posizione_abitanti);
         next_road:= get_quartiere_utilities_obj.get_classe_locate_abitanti(abitante.get_id_quartiere_posizione_abitanti).get_next_road(abitante.get_id_abitante_posizione_abitanti,False);
         -- ATTENZIONE next_road può essere un ingresso
         id_road:= get_quartiere_cfg(next_road.get_id_quartiere_tratto).get_id_main_road_from_id_ingresso(next_road.get_id_tratto);
         if id_road/=0 then
            next_road:= create_tratto(next_road.get_id_quartiere_tratto,id_road);
         end if;
         -- eseguito update di next_road se necessario
         get_quartiere_cfg(next_incrocio.get_id_quartiere_tratto).get_cfg_incrocio(next_incrocio.get_id_tratto,create_tratto(next_nodo.get_id_quartiere_tratto,next_nodo.get_id_tratto),create_tratto(next_road.get_id_quartiere_tratto,next_road.get_id_tratto),index_road_from,index_road_to,id_road_mancante);
         if id_road_mancante=0 and (index_road_from=0 or index_road_to=0) then
            return create_trajectory_to_follow(0,0,0,0,empty);  --errore
         else
            if abs(index_road_from-index_road_to)=2 then
               if num_corsia=1 then
                  return create_trajectory_to_follow(num_corsia,1,0,0,dritto_1);
               else
                  return create_trajectory_to_follow(num_corsia,2,0,0,dritto_2);
               end if;
            elsif index_road_to>index_road_from or (index_road_to=1 and index_road_from=4) then
               return create_trajectory_to_follow(num_corsia,1,0,0,sinistra);
            else
               return create_trajectory_to_follow(num_corsia,2,0,0,destra);
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
            return uscita_andata;
         else -- l'ingresso arrivo precede l'ingresso destinazione
            return uscita_ritorno;
         end if;
         --if which_found then -- l'ingresso partenza precede l'ingresso destinazione
         --   if ingresso.get_polo_ingresso then
         --      return uscita_ritorno;
         --   else
         --      return uscita_andata;
         --   end if;
         --else -- l'ingresso arrivo precede l'ingresso destinazione
         --   if ingresso.get_polo_ingresso then
         --      return uscita_andata;
         --   else
         --      return uscita_ritorno;
         --   end if;
         --end if;
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
         -- la macchina è in sorpasso
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
               -- la macchina è in sorpasso verso la corsia opposta ma non ha ancora attraversato
               if next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory-
                 get_quartiere_utilities_obj.get_auto_quartiere(next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<get_traiettoria_cambio_corsia.get_distanza_intersezione_linea_di_mezzo then
                  next_car_on_road_distance:= next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
               end if;
            else  -- si ha una macchina che dalla corsia opposta vuole entrare nella corsia first_corsia
               -- dopo ottimizzazione:
               next_car_on_road_distance:= next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
               -- end
               -- prima dell'ottimizzazione
               --if next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory=get_traiettoria_cambio_corsia.get_distanza_intersezione_linea_di_mezzo then
                  --next_car_on_road_distance:= next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                  --if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken and from_corsia/=current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory then
                     -- la macchina è in sorpasso
                  --   next_car_on_road_distance:= next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                  --elsif current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken then
                  --   if next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria/2.0-safe_distance_to_overtake>
                  --     current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_traiettoria-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory then
                  --      next_car_on_road_distance:= next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                  --   end if;
                  --else
                  --   if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria/2.0-safe_distance_to_overtake then
                  --      next_car_on_road_distance:= next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                  --   end if;
                     --end if;
                  --if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken then
                     --if next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria/2.0-safe_distance_to_overtake>
                       --current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti then
                        --next_car_on_road_distance:= next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                     --end if;
                  --end if;
                  --end if;
                -- end prima dell'ottimizzazione
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
      speed_abitante: Float;
   begin
      speed_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
      if traiettoria_to_go=uscita_andata then
         corsia_to_go:= 2;
      elsif traiettoria_to_go=uscita_ritorno then
         corsia_to_go:= 1;
      end if;
      if corsia_to_go/=0 then
         if next_abitante/=null and then (next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken and next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory=corsia_to_go) then
            costante_additiva:= get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria/2.0;
         else
            costante_additiva:= 0.0;
         end if;

         -- next_pos_abitante è un abitante in traiettoria ingresso
         if next_abitante/=null and then (next_pos_abitante=0.0 or else next_pos_abitante>next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+costante_additiva) then
            if next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken and next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory=corsia_to_go then
               next_pos_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+costante_additiva-max_larghezza_veicolo;
            else
               next_abitante_car_length:= get_quartiere_utilities_obj.get_auto_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
               if next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken=True then
                  -- l'abitante è in sorpasso verso la corsia che non riguarda la macchina corrente
                  if next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory>next_abitante_car_length then
                     next_pos_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;  -- impone come distanza quella di inizio traiettoria di sorpasso
                  else
                     next_pos_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory-next_abitante_car_length);
                  end if;
               else
                  next_pos_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-next_abitante_car_length;
               end if;
            end if;
            next_pos_abitante:= traiettoria_rimasta_da_percorrere+next_pos_abitante-distance_ingresso-get_larghezza_marciapiede-get_larghezza_corsia;
            acceleration:= calculate_acceleration(mezzo => car,
                                                  id_abitante => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                  id_quartiere_abitante => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                  next_entity_distance => next_pos_abitante,
                                                  distance_to_stop_line => distance_to_stop_line+add_factor,
                                                  next_id_quartiere_abitante => next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                  next_id_abitante => next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                  abitante_velocity => speed_abitante,
                                                  next_abitante_velocity => next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante);
         else
            acceleration:= calculate_acceleration(mezzo => car,
                                                  id_abitante => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                  id_quartiere_abitante => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                  next_entity_distance => next_pos_abitante,
                                                  distance_to_stop_line => distance_to_stop_line+add_factor,
                                                  next_id_quartiere_abitante => 0,
                                                  next_id_abitante => 0,
                                                  abitante_velocity => speed_abitante,
                                                  next_abitante_velocity =>0.0);
         end if;
         new_speed:= calculate_new_speed(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante,acceleration);
         new_step:= calculate_new_step(new_speed,acceleration);
      end if;
   end calculate_parameters_car_in_uscita;

   procedure calculate_parameters_car_in_entrata(list_abitanti: ptr_list_posizione_abitanti_on_road; traiettoria_rimasta_da_percorrere: Float; next_abitante: ptr_list_posizione_abitanti_on_road; distance_to_stop_line: Float; traiettoria_to_go: traiettoria_ingressi_type; next_pos_abitante: in out Float; acceleration: out Float; new_step: out Float; new_speed: out Float) is
      next_abitante_car_length: Float;
      speed_abitante: Float;
   begin
      speed_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
      if next_abitante/=null then
         next_abitante_car_length:= get_quartiere_utilities_obj.get_auto_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
         --next_pos_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
         next_pos_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-next_abitante_car_length+traiettoria_rimasta_da_percorrere;
         acceleration:= calculate_acceleration(mezzo => car,
                                               id_abitante => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                               id_quartiere_abitante => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                               next_entity_distance => next_pos_abitante,
                                               distance_to_stop_line => distance_to_stop_line+add_factor,
                                               next_id_quartiere_abitante => next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                               next_id_abitante => next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                               abitante_velocity => speed_abitante,
                                               next_abitante_velocity => next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante);
      else
         acceleration:= calculate_acceleration(mezzo => car,
                                               id_abitante => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                               id_quartiere_abitante => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                               next_entity_distance => 0.0,
                                               distance_to_stop_line => distance_to_stop_line+add_factor,
                                               next_id_quartiere_abitante => 0,
                                               next_id_abitante => 0,
                                               abitante_velocity => speed_abitante,
                                               next_abitante_velocity =>0.0);
      end if;
      new_speed:= calculate_new_speed(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante,acceleration);
      new_step:= calculate_new_step(new_speed,acceleration);
   end calculate_parameters_car_in_entrata;

   procedure fix_advance_parameters(acceleration: in out Float; new_speed: in out Float; new_step: in out Float; speed_abitante: Float; distance_to_next: Float; distanza_stop_line: Float; max_acceleration: Float) is
   begin
      -- distance_to_next se =0.0 => non c'è un abitante successivo
      if acceleration>0.0 and distance_to_next>0.0 then
         if distance_to_next<=2.0 then
            acceleration:= 0.0;
            new_step:= 0.0;
            new_speed:= speed_abitante/2.0;
         else
            if new_step>distance_to_next-2.0 then
               new_step:= distance_to_next-2.0;
               new_speed:= speed_abitante/2.0;
            end if;
         end if;
      elsif acceleration/=0.0 then
         if acceleration<0.0 then
            new_speed:= speed_abitante;
            if distance_to_next>0.0 then
               new_step:= 0.0;
            --else
            --   new_step:= distanza_stop_line;
            --   Put_Line("***************yes*************************" & Float'Image(max_acceleration));
            end if;
         end if;
      --else
      --   new_speed:= 0.0;
      --   new_step:= 0.0;
      end if;
      --if new_speed>max_acceleration*3.0 then
      --   new_speed:= new_speed/3.0;
      --end if;
   end fix_advance_parameters;

   function calculate_next_entity_distance(current_car: ptr_list_posizione_abitanti_on_road; next_car_in_ingresso_distance: Float; next_car_on_road: ptr_list_posizione_abitanti_on_road; next_car_on_road_distance: Float; id_road: Positive) return Float is
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
               incrocio:= get_quartiere_utilities_obj.get_classe_locate_abitanti(next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_next(next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
               quantità_avanzata_next_incrocio:= ptr_rt_incrocio(get_id_incrocio_quartiere(incrocio.get_id_quartiere_tratto,incrocio.get_id_tratto)).get_posix_first_entity(get_id_quartiere,id_road,next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
            end if;
            next_car_distance:= quantità_avanzata_next_incrocio+next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
              get_quartiere_utilities_obj.get_auto_quartiere(next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                             next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
         end if;
      end if;

      if next_car_distance/=-1.0 then
         next_car_distance:= next_car_distance-current_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
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

   function calculate_distance_to_stop_line_from_entity_on_road(abitante: ptr_list_posizione_abitanti_on_road; polo: Boolean; id_urbana: Positive) return Float is
      traiettoria: trajectory_to_follow:= trajectory_to_follow(abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_destination);
   begin
      if traiettoria.get_traiettoria_incrocio_to_follow=empty then
         if polo then
            return get_urbana_from_id(id_urbana).get_lunghezza_road-get_ingresso_from_id(traiettoria.get_ingresso_to_go_trajectory).get_distance_from_road_head_ingresso-abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_larghezza_corsia-get_larghezza_marciapiede;
         else
            return get_ingresso_from_id(traiettoria.get_ingresso_to_go_trajectory).get_distance_from_road_head_ingresso-abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_larghezza_corsia-get_larghezza_marciapiede;
         end if;
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

   procedure crea_snapshot(num_delta: in out Natural; mailbox: ptr_backup_interface; num_task: Positive) is
      json: JSON_Value;
   begin
      num_delta:= num_delta + 1;
      if num_delta=num_delta_to_wait_to_have_system_snapshot then
         mailbox.create_img(json);
         snapshot_writer.write_img_resource(json,num_task);
         num_delta:= 0;
      end if;
   end crea_snapshot;

   -- PRE: current_corsia/=null and opposite_corsia/=null
   function calculate_next_car_in_opposite_corsia(current_corsia: ptr_list_posizione_abitanti_on_road; opposite_corsia: ptr_list_posizione_abitanti_on_road) return ptr_list_posizione_abitanti_on_road is
      opposite: ptr_list_posizione_abitanti_on_road:= opposite_corsia;
   begin
      while opposite/=null and then opposite.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<current_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti loop
         opposite:= opposite.get_next_from_list_posizione_abitanti;
      end loop;
      return opposite;
   end calculate_next_car_in_opposite_corsia;

   procedure reconfigure_resource(resource: ptr_backup_interface; id_task: Positive) is
   begin
      if get_recovery then
         if id_task=1 then
            ptr_backup_interface(get_locate_abitanti_quartiere).recovery_resource;
         end if;
         resource.recovery_resource;
      end if;
   end reconfigure_resource;

   task body core_avanzamento_urbane is
      id_task: Positive;
      mailbox: ptr_resource_segmento_urbana;
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

      acceleration_car: Float:= 0.0;
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

      state_view_abitanti: JSON_Array;

      list_abitanti_on_traiettoria_ingresso: ptr_list_posizione_abitanti_on_road;
      car_length: Float;

      num_delta: Natural:= 0;
      z: Positive;

      speed_abitante: Float;

      semaforo_is_verde: Boolean;
      disable_rallentamento: Boolean;

      bound_distance: Float;
      stop_entity_to_incrocio: Boolean:= False;
      distance_to_next_car: Float;
      index_road: Natural;

      abitante_to_transfer: posizione_abitanti_on_road;
   begin
      accept configure(id: Positive) do
         id_task:= id;
         mailbox:= get_urbane_segmento_resources(id);
      end configure;
      -- Put_Line("configurato" & Positive'Image(id_task) & "id quartiere" & Positive'Image(get_id_quartiere));

      wait_settings_all_quartieri;
      --Put_Line("task " & Positive'Image(id_task) & " of quartiere " & Positive'Image(get_id_quartiere) & " is set");
      mailbox.set_estremi_urbana(get_resource_estremi_urbana(id_task));

      reconfigure_resource(ptr_backup_interface(mailbox),id_task);

      loop

         synchronization_with_delta(id_task);
         --log_mio.write_task_arrived("id_task " & Positive'Image(id_task) & " id_quartiere " & Positive'Image(get_id_quartiere));

         state_view_abitanti:= Empty_Array;
         mailbox.update_traiettorie_ingressi(state_view_abitanti);
         mailbox.update_car_on_road(state_view_abitanti);
         state_view_quartiere.registra_aggiornamento_stato_risorsa(id_task,state_view_abitanti);

         -- crea snapshot se necessario
         crea_snapshot(num_delta,ptr_backup_interface(mailbox),id_task);

         -- aspetta che finiscano gli incroci
         mailbox.wait_incroci;
         -- fine wait; gli incroci hanno fatto l'avanzamento

         current_polo_to_consider:= False;

         for h in 1..2 loop
            --corsia_destra:= mailbox.get_abitanti_on_road(current_polo_to_consider,2);
            --corsia_sinistra:= mailbox.get_abitanti_on_road(current_polo_to_consider,1);
            corsia_destra:= mailbox.slide_list(current_polo_to_consider,2,mailbox.get_number_entity(road,current_polo_to_consider,2));
            corsia_sinistra:= mailbox.slide_list(current_polo_to_consider,1,mailbox.get_number_entity(road,current_polo_to_consider,1));
            for i in 1..(mailbox.get_number_entity(road,current_polo_to_consider,1)+mailbox.get_number_entity(road,current_polo_to_consider,2)) loop
               -- cerco la prima macchina tra le 2 liste
               first_corsia:= 0;
               current_car_in_corsia:= null;
               next_car_in_corsia:= null;
               next_car_in_opposite_corsia:= null;
               if corsia_destra/=null and corsia_sinistra/=null then
                  if corsia_destra.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=corsia_sinistra.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti then
                     first_corsia:= 2;
                     current_car_in_corsia:= corsia_destra;
                     next_car_in_corsia:= corsia_destra.get_next_from_list_posizione_abitanti;
                     --next_car_in_opposite_corsia:= corsia_sinistra.get_next_from_list_posizione_abitanti;
                     next_car_in_opposite_corsia:= calculate_next_car_in_opposite_corsia(corsia_destra,corsia_sinistra);
                     corsia_destra:= corsia_destra.get_prev_from_list_posizione_abitanti;
                  else
                     first_corsia:= 1;
                     current_car_in_corsia:= corsia_sinistra;
                     next_car_in_corsia:= corsia_sinistra.get_next_from_list_posizione_abitanti;
                     --next_car_in_opposite_corsia:= corsia_destra.get_next_from_list_posizione_abitanti;
                     next_car_in_opposite_corsia:= calculate_next_car_in_opposite_corsia(corsia_sinistra,corsia_destra);
                     corsia_sinistra:= corsia_sinistra.get_prev_from_list_posizione_abitanti;
                  end if;
               else
                  if corsia_destra/=null and corsia_sinistra=null then
                     first_corsia:= 2;
                     current_car_in_corsia:= corsia_destra;
                     next_car_in_corsia:= corsia_destra.get_next_from_list_posizione_abitanti;
                     next_car_in_opposite_corsia:= null;
                     corsia_destra:= corsia_destra.get_prev_from_list_posizione_abitanti;
                  elsif corsia_destra=null and corsia_sinistra/=null then
                     first_corsia:= 1;
                     current_car_in_corsia:= corsia_sinistra;
                     next_car_in_corsia:= corsia_sinistra.get_next_from_list_posizione_abitanti;
                     next_car_in_opposite_corsia:= null;
                     corsia_sinistra:= corsia_sinistra.get_prev_from_list_posizione_abitanti;
                  else
                     null; -- NOOP
                  end if;
               end if;

               distance_to_stop_line:= 0.0;
               next_entity_distance:= 0.0;
               can_not_overtake_now:= False;

               if first_corsia/=0 and then current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_urbana_from_id(id_task).get_lunghezza_road then
                  -- elaborazione corsia to go;    first_corsia è la corsia in cui la macchina è situata
                  Put_Line("id_abitante " & Positive'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & Float'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is urbana " & Positive'Image(id_task));
                  -- Put_Line("id_abitante overtaking " & Float'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory));

                  -- BEGIN CONTROLLO SE IL SEMAFORO È VERDE
                  semaforo_is_verde:= False;
                  if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow/=empty then
                     if get_quartiere_utilities_obj.get_classe_locate_abitanti(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_current_position(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti)=1 then
                        tratto_incrocio:= get_quartiere_utilities_obj.get_classe_locate_abitanti(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_next(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                     else
                        tratto_incrocio:= get_quartiere_utilities_obj.get_classe_locate_abitanti(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_next_incrocio(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                     end if;
                     semaforo_is_verde:= get_id_incrocio_quartiere(tratto_incrocio.get_id_quartiere_tratto,tratto_incrocio.get_id_tratto).semaforo_is_verde_from_road(get_id_quartiere,id_task);
                  else
                     semaforo_is_verde:= False;
                  end if;
                  --semaforo_is_verde:= False;
                  -- END CONTROLLO COLORE SEMAFORO

                  destination:= trajectory_to_follow(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_destination);
                  if destination.get_traiettoria_incrocio_to_follow/=empty or (destination.get_corsia_to_go_trajectory/=0 and destination.get_ingresso_to_go_trajectory/=0) then
                     stop_entity:= False;
                     acceleration_car:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti)).get_max_acceleration;
                     if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory/=first_corsia then
                        if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken=False then -- macchina non in sorpasso
                           bound_to_overtake:= calculate_bound_to_overtake(current_car_in_corsia,current_polo_to_consider,id_task);
                           if bound_to_overtake=0.0 then -- necessario sorpassare subito
                              stop_entity:= not mailbox.car_can_initiate_overtaken_on_road(current_car_in_corsia,current_polo_to_consider,first_corsia);
                              if stop_entity=False and mailbox.car_on_same_corsia_have_overtaked(current_car_in_corsia,current_polo_to_consider,first_corsia) then
                                 mailbox.set_car_overtaken(True,current_car_in_corsia);
                                 traiettoria_rimasta_da_percorrere:= get_traiettoria_cambio_corsia.get_lunghezza_traiettoria;
                                 distance_to_stop_line:= calculate_distance_to_stop_line_from_entity_on_road(current_car_in_corsia,current_polo_to_consider,id_task);
                                 next_car_in_ingresso_distance:= mailbox.calculate_distance_to_next_ingressi(current_polo_to_consider,destination.get_corsia_to_go_trajectory,current_car_in_corsia);
                                 calculate_distance_to_next_car_on_road(current_car_in_corsia,next_car_in_opposite_corsia,next_car_in_corsia,current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory,next_car_on_road,next_car_on_road_distance);
                                 next_entity_distance:= calculate_next_entity_distance(current_car_in_corsia,next_car_in_ingresso_distance,next_car_on_road,next_car_on_road_distance,id_task);
                              else
                                 stop_entity:= True;
                              end if;
                           else  -- valutare se sorpassare
                              -- FIRST: controllare se il sorpasso può essere effettuato
                              -- la macchina se si trova dentro un incrocio tra ingressi e l'ingresso non è occupato allora ok
                              -- car_can_initiate_overtaken(current_car_in_corsia,current_polo_to_consider,first_corsia)
                              stop_entity:= True;
                              if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_larghezza_corsia+get_larghezza_marciapiede then  -- ovvero per sorpassare occorre aver superato di 10.0 la distanza dall'incrocio
                                 if mailbox.there_are_cars_moving_across_next_ingressi(current_car_in_corsia,current_polo_to_consider)=False then  -- può sorpassare
                                    stop_entity:= not mailbox.car_can_initiate_overtaken_on_road(current_car_in_corsia,current_polo_to_consider,first_corsia);
                                    if stop_entity=False and mailbox.car_on_same_corsia_have_overtaked(current_car_in_corsia,current_polo_to_consider,first_corsia) then
                                       mailbox.set_car_overtaken(True,current_car_in_corsia);
                                       traiettoria_rimasta_da_percorrere:= get_traiettoria_cambio_corsia.get_lunghezza_traiettoria;
                                       distance_to_stop_line:= calculate_distance_to_stop_line_from_entity_on_road(current_car_in_corsia,current_polo_to_consider,id_task);
                                       next_car_in_ingresso_distance:= mailbox.calculate_distance_to_next_ingressi(current_polo_to_consider,destination.get_corsia_to_go_trajectory,current_car_in_corsia);
                                       calculate_distance_to_next_car_on_road(current_car_in_corsia,next_car_in_opposite_corsia,next_car_in_corsia,current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory,next_car_on_road,next_car_on_road_distance);
                                       next_entity_distance:= calculate_next_entity_distance(current_car_in_corsia,next_car_in_ingresso_distance,next_car_on_road,next_car_on_road_distance,id_task);
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
                                 next_entity_distance:= calculate_next_entity_distance(current_car_in_corsia,next_car_in_ingresso_distance,next_car_on_road,next_car_on_road_distance,id_task);
                              end if;
                           end if;
                           speed_abitante:= current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                           if stop_entity=False and (next_car_on_road/=null and next_entity_distance/=next_car_in_ingresso_distance) then
                              acceleration:= calculate_acceleration(mezzo => car,
                                                              id_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                              id_quartiere_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                              next_entity_distance => next_entity_distance+traiettoria_rimasta_da_percorrere,
                                                              distance_to_stop_line => distance_to_stop_line+traiettoria_rimasta_da_percorrere+add_factor,
                                                              next_id_quartiere_abitante => next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                              next_id_abitante => next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                              abitante_velocity => speed_abitante,
                                                              next_abitante_velocity => next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante);
                           else
                              if next_entity_distance/=0.0 then
                                 next_entity_distance:= next_entity_distance+traiettoria_rimasta_da_percorrere;
                              end if;
                              acceleration:= calculate_acceleration(mezzo => car,
                                                              id_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                              id_quartiere_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                              next_entity_distance => next_entity_distance,
                                                              distance_to_stop_line => distance_to_stop_line+traiettoria_rimasta_da_percorrere+add_factor,
                                                              next_id_quartiere_abitante => 0,
                                                              next_id_abitante => 0,
                                                              abitante_velocity => speed_abitante,
                                                              next_abitante_velocity =>0.0);
                           end if;
                        else -- macchina in sorpasso, occorre avanzarla
                           --if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory=get_traiettoria_cambio_corsia.get_lunghezza_traiettoria/2.0 then
                           --   stop_entity:= not mailbox.can_car_overtake(current_car_in_corsia,current_polo_to_consider,destination.get_corsia_to_go_trajectory);
                           --   if stop_entity=False then
                           --      mailbox.set_flag_car_can_overtake_to_next_corsia(current_car_in_corsia,True);
                           --   end if;
                           --end if;
                           if stop_entity=False then  -- è False
                              traiettoria_rimasta_da_percorrere:= get_traiettoria_cambio_corsia.get_lunghezza_traiettoria-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory;
                              distance_to_stop_line:= calculate_distance_to_stop_line_from_entity_on_road(current_car_in_corsia,current_polo_to_consider,id_task);
                              next_car_in_ingresso_distance:= mailbox.calculate_distance_to_next_ingressi(current_polo_to_consider,destination.get_corsia_to_go_trajectory,current_car_in_corsia);
                              calculate_distance_to_next_car_on_road(current_car_in_corsia,next_car_in_opposite_corsia,next_car_in_corsia,destination.get_corsia_to_go_trajectory,next_car_on_road,next_car_on_road_distance);
                              next_entity_distance:= calculate_next_entity_distance(current_car_in_corsia,next_car_in_ingresso_distance,next_car_on_road,next_car_on_road_distance,id_task);
                              speed_abitante:= current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                              if next_car_on_road/=null and next_entity_distance/=next_car_in_ingresso_distance then
                                 acceleration:= calculate_acceleration(mezzo => car,
                                                                id_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                                id_quartiere_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                next_entity_distance => next_entity_distance+traiettoria_rimasta_da_percorrere,
                                                                distance_to_stop_line => distance_to_stop_line+traiettoria_rimasta_da_percorrere+add_factor,
                                                                next_id_quartiere_abitante => next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                next_id_abitante => next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                                abitante_velocity => speed_abitante,
                                                                next_abitante_velocity => next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante);
                              else
                                 if next_entity_distance/=0.0 then
                                    next_entity_distance:= next_entity_distance+traiettoria_rimasta_da_percorrere;
                                 end if;
                                 acceleration:= calculate_acceleration(mezzo => car,
                                                                       id_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                                       id_quartiere_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                       next_entity_distance => next_entity_distance,
                                                                       distance_to_stop_line => distance_to_stop_line+traiettoria_rimasta_da_percorrere+add_factor,
                                                                       next_id_quartiere_abitante => 0,
                                                                       next_id_abitante => 0,
                                                                       abitante_velocity => speed_abitante,
                                                                       next_abitante_velocity =>0.0);
                              end if;
                           end if;
                        end if;
                     else -- la macchina è nella corsia giusta
                        distance_to_stop_line:= calculate_distance_to_stop_line_from_entity_on_road(current_car_in_corsia,current_polo_to_consider,id_task);
                        next_car_in_ingresso_distance:= mailbox.calculate_distance_to_next_ingressi(current_polo_to_consider,first_corsia,current_car_in_corsia);
                        calculate_distance_to_next_car_on_road(current_car_in_corsia,next_car_in_corsia,next_car_in_opposite_corsia,first_corsia,next_car_on_road,next_car_on_road_distance);
                        next_entity_distance:= calculate_next_entity_distance(current_car_in_corsia,next_car_in_ingresso_distance,next_car_on_road,next_car_on_road_distance,id_task);
                        speed_abitante:= current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                        if next_car_on_road/=null and then next_entity_distance/=next_car_in_ingresso_distance then
                           acceleration:= calculate_acceleration(mezzo => car,
                                                           id_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                           id_quartiere_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                           next_entity_distance => next_entity_distance,
                                                           distance_to_stop_line => distance_to_stop_line+add_factor,
                                                           next_id_quartiere_abitante => next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                           next_id_abitante => next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                           abitante_velocity => speed_abitante,
                                                           next_abitante_velocity => next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante);
                        else
                           costante_additiva:= 0.0;
                           disable_rallentamento:= False;
                           if semaforo_is_verde then
                              if distance_to_stop_line<distance_at_witch_decelarate then
                                 disable_rallentamento:= True;
                                 --tratto_incrocio:= get_quartiere_utilities_obj.get_classe_locate_abitanti(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_next(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                                 index_road:= 0;
                                 pragma warnings(off);
                                 ptr_rt_incrocio(get_id_incrocio_quartiere(tratto_incrocio.get_id_quartiere_tratto,tratto_incrocio.get_id_tratto)).calcola_bound_avanzamento_in_incrocio(index_road             => index_road,
                                                                                                                                                                                         indice                 => 0,
                                                                                                                                                                                         traiettoria_car        => destination.get_traiettoria_incrocio_to_follow,
                                                                                                                                                                                         corsia                 => destination.get_corsia_to_go_trajectory,
                                                                                                                                                                                         num_car                => 0,
                                                                                                                                                                                         bound_distance         => bound_distance,
                                                                                                                                                                                         stop_entity            => stop_entity_to_incrocio,
                                                                                                                                                                                         distance_to_next_car   => distance_to_next_car,
                                                                                                                                                                                         from_id_quartiere_road => get_id_quartiere,
                                                                                                                                                                                         from_id_road           => id_task);
                                 pragma warnings(on);
                                 if stop_entity_to_incrocio then  -- se true ferma tutto
                                    semaforo_is_verde:= False;
                                    costante_additiva:= 0.0;
                                 else
                                    if bound_distance=-1.0 and distance_to_next_car=-1.0 then
                                       costante_additiva:= get_traiettoria_incrocio(destination.get_traiettoria_incrocio_to_follow).get_lunghezza_traiettoria_incrocio;
                                    else
                                       if bound_distance=-1.0 then
                                          if distance_to_next_car>min_veicolo_distance then
                                             costante_additiva:= distance_to_next_car;
                                             semaforo_is_verde:= False;
                                          else
                                             costante_additiva:= 0.0;
                                          end if;
                                       else
                                          if distance_to_next_car=-1.0 then
                                             costante_additiva:= bound_distance;
                                          else
                                             if distance_to_next_car<bound_distance then
                                                if distance_to_next_car>min_veicolo_distance then
                                                   costante_additiva:= distance_to_next_car;
                                                   semaforo_is_verde:= False;
                                                else
                                                   costante_additiva:= 0.0;
                                                end if;
                                             else
                                                costante_additiva:= bound_distance;
                                                distance_to_next_car:= -1.0;
                                             end if;
                                          end if;
                                       end if;
                                    end if;
                                 end if;
                              end if;
                           end if;
                           acceleration:= calculate_acceleration(mezzo => car,
                                                                 id_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                                 id_quartiere_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                 next_entity_distance => next_entity_distance,
                                                                 distance_to_stop_line => costante_additiva+distance_to_stop_line+add_factor,
                                                                 next_id_quartiere_abitante => 0,
                                                                 next_id_abitante => 0,
                                                                 abitante_velocity => speed_abitante,
                                                                 next_abitante_velocity => 0.0,
                                                                 disable_rallentamento_1 => semaforo_is_verde,
                                                                 disable_rallentamento_2 => disable_rallentamento);
                        end if;
                     end if;
                     if stop_entity=False then
                        new_speed:= calculate_new_speed(speed_abitante,acceleration);
                        new_step:= calculate_new_step(new_speed,acceleration);

                        fix_advance_parameters(acceleration,new_speed,new_step,speed_abitante,next_entity_distance,distance_to_stop_line,acceleration_car);

                        -- se l'abitante non si trova già nell'altra corsia
                        --if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken=True then -- macchina in sorpasso
                        --   if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory<get_traiettoria_cambio_corsia.get_lunghezza_traiettoria/2.0 then
                        --      if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory+new_step>=get_traiettoria_cambio_corsia.get_lunghezza_traiettoria/2.0 then
                        --         new_step:= get_traiettoria_cambio_corsia.get_lunghezza_traiettoria/2.0-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory;
                        --      end if;
                        --   end if;
                        --elsif ...
                        if can_not_overtake_now then
                           -- 1.5 metri di riaccelerazione "a manina"
                           if bound_to_overtake-(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step)<1.5 then
                              new_step:= bound_to_overtake-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                           end if;
                        end if;
                     end if;
                     mailbox.set_move_parameters_entity_on_main_road(current_car_in_corsia,current_polo_to_consider,first_corsia,new_speed,new_step);
                     if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken=True and first_corsia/=current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory then -- macchina in sorpasso
                        if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory>=get_traiettoria_cambio_corsia.get_lunghezza_traiettoria/2.0 then
                           mailbox.set_flag_car_can_overtake_to_next_corsia(current_car_in_corsia,True);
                        end if;
                     end if;
                     if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_urbana_from_id(id_task).get_lunghezza_road and current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>=get_urbana_from_id(id_task).get_lunghezza_road then
                        -- aggiungi entità
                        -- all'incrocio
                        if get_quartiere_utilities_obj.get_classe_locate_abitanti(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_current_position(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti)/=1 then
                           get_quartiere_utilities_obj.get_classe_locate_abitanti(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).set_position_abitante_to_next(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                        end if;
                        tratto_incrocio:= get_quartiere_utilities_obj.get_classe_locate_abitanti(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_next(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                        abitante_to_transfer:= posizione_abitanti_on_road(create_new_posizione_abitante_from_copy(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti));

                        if distance_to_next_car/=-1.0 and then distance_to_next_car<get_traiettoria_incrocio(destination.get_traiettoria_incrocio_to_follow).get_lunghezza_traiettoria_incrocio then  -- se l'abitante ha una macchina davanti controllo sa la prossima posizione viola il vincolo min_veicolo_distance
                           if abitante_to_transfer.get_where_next_posizione_abitanti-get_urbana_from_id(id_task).get_lunghezza_road<distance_to_next_car-min_veicolo_distance then
                              abitante_to_transfer.set_where_next_abitante(get_urbana_from_id(id_task).get_lunghezza_road+distance_to_next_car-min_veicolo_distance);
                           end if;
                        end if;
                        abitante_to_transfer.set_where_next_abitante(abitante_to_transfer.get_where_next_posizione_abitanti-get_urbana_from_id(id_task).get_lunghezza_road);
                        abitante_to_transfer.set_destination(create_trajectory_to_follow(get_id_quartiere,destination.get_corsia_to_go_trajectory,0,id_task,destination.get_traiettoria_incrocio_to_follow));

                        ptr_rt_incrocio(get_id_incrocio_quartiere(tratto_incrocio.get_id_quartiere_tratto,tratto_incrocio.get_id_tratto)).insert_new_car(get_id_quartiere,id_task,posizione_abitanti_on_road(abitante_to_transfer));
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

         current_polo_to_consider:= False;
         current_ingressi_structure_type_to_consider:= ordered_polo_false;
         current_ingressi_structure_type_to_not_consider:= ordered_polo_true;

         for h in 1..2 loop
            for i in reverse mailbox.get_ordered_ingressi_from_polo(current_polo_to_consider).all'Range loop

               ingresso:= get_ingresso_from_id(mailbox.get_index_ingresso_from_key(i,current_ingressi_structure_type_to_consider));
               distance_ingresso:= get_distance_from_polo_percorrenza(ingresso,current_polo_to_consider);

               -- al + puoi muovere le macchine nelle traiettorie uscita_ritorno e entrata_ritorno se le loro traiettoria sono sulla parte
               -- non occupata dalla strada

               there_are_car_overtaking_current_polo:= mailbox.there_are_overtaken_on_ingresso(ingresso,current_polo_to_consider);
               there_are_car_overtaking_opposite_polo:= mailbox.there_are_overtaken_on_ingresso(ingresso,current_polo_to_consider);

               if there_are_car_overtaking_current_polo and there_are_car_overtaking_opposite_polo then
                  list_abitanti_uscita_andata:= null;
                  list_abitanti_uscita_ritorno:= null;
                  list_abitanti_entrata_andata:= null;
                  list_abitanti_entrata_ritorno:= null;
               elsif there_are_car_overtaking_current_polo=False and there_are_car_overtaking_opposite_polo=False then
                  list_abitanti_uscita_andata:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,uscita_andata);
                  list_abitanti_uscita_ritorno:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,uscita_ritorno);
                  list_abitanti_entrata_andata:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,entrata_andata);
                  list_abitanti_entrata_ritorno:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,entrata_ritorno);
               elsif there_are_car_overtaking_current_polo then
                  list_abitanti_uscita_ritorno:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,uscita_ritorno);
                  list_abitanti_entrata_ritorno:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,entrata_ritorno);
                  if list_abitanti_uscita_ritorno/=null and then list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                    get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<15.0 then  -- 15.0 distanza intersezione seconda linea
                     list_abitanti_uscita_ritorno:= null;
                  end if;
                  if list_abitanti_entrata_ritorno/=null and then list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<5.0 then -- 5.0 distanza intersezione linea di mezzo
                     list_abitanti_entrata_ritorno:= null;
                  end if;
               else
                  list_abitanti_uscita_andata:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,uscita_andata);
                  list_abitanti_uscita_ritorno:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,uscita_ritorno);
                  list_abitanti_entrata_andata:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,entrata_andata);
                  list_abitanti_entrata_ritorno:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,entrata_ritorno);
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
                  -- cerco se ingressi successivi sullo stesso polo hanno macchine da spostare
                  next_pos_ingresso_move:= 0.0;
                  z:= i+1;
                  while next_pos_ingresso_move=0.0 and z<mailbox.get_ordered_ingressi_from_polo(current_polo_to_consider).all'Last loop
                     ingresso_to_consider:= get_ingresso_from_id(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider));
                     if mailbox.is_index_ingresso_in_svolta(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),uscita_andata) then
                        next_pos_ingresso_move:= get_distance_from_polo_percorrenza(ingresso_to_consider,current_polo_to_consider);
                     elsif mailbox.is_index_ingresso_in_svolta(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),uscita_ritorno) then
                        next_pos_ingresso_move:= get_distance_from_polo_percorrenza(ingresso_to_consider,current_polo_to_consider);
                     end if;
                     if mailbox.is_index_ingresso_in_svolta(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),entrata_ritorno) then
                        next_pos_ingresso_move:= get_distance_from_polo_percorrenza(ingresso_to_consider,current_polo_to_consider) - get_larghezza_corsia;
                     elsif mailbox.is_index_ingresso_in_svolta(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),entrata_andata) then
                        list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(mailbox.get_key_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),not_ordered),entrata_andata);
                        if list_abitanti_on_traiettoria_ingresso.get_next_from_list_posizione_abitanti/=null then
                           car_length:= get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_on_traiettoria_ingresso.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_on_traiettoria_ingresso.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                        else
                           car_length:= get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                           if list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<car_length then
                              car_length:= car_length-list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                           else
                              car_length:= 0.0;
                           end if;
                        end if;
                        next_pos_ingresso_move:= get_distance_from_polo_percorrenza(ingresso_to_consider,current_polo_to_consider) - get_larghezza_corsia - car_length;
                     end if;
                     z:= z+1;
                  end loop;
                  if next_pos_ingresso_move/=0.0 then
                     next_pos_abitante:= next_pos_ingresso_move;
                  end if;
                  acceleration_car:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti)).get_max_acceleration;
                  traiettoria_rimasta_da_percorrere:= get_traiettoria_ingresso(uscita_andata).get_lunghezza-list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                  next_abitante:= mailbox.get_next_abitante_on_road(distance_ingresso+get_larghezza_corsia+get_larghezza_marciapiede,current_polo_to_consider,2);
                  distance_to_stop_line:= get_urbana_from_id(id_task).get_lunghezza_road-(distance_ingresso+get_larghezza_corsia+get_larghezza_marciapiede)+traiettoria_rimasta_da_percorrere;
                  calculate_parameters_car_in_uscita(list_abitanti_uscita_andata,traiettoria_rimasta_da_percorrere,next_abitante,distance_to_stop_line,uscita_andata,distance_ingresso,next_pos_abitante,acceleration,new_step,new_speed);
                  fix_advance_parameters(acceleration,new_speed,new_step,speed_abitante,next_pos_abitante,distance_to_stop_line,acceleration_car);

                  mailbox.set_move_parameters_entity_on_traiettoria_ingresso(list_abitanti_uscita_andata,ingresso.get_id_road,uscita_andata,current_polo_to_consider,new_speed,new_step);
                  Put_Line("id_abitante " & Positive'Image(list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & Float'Image(list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is traiettoria uscita andata ingresso " & Positive'Image(id_task));
               end if;

               -- TRAIETTORIA USCITA_RITORNO
               stop_entity:= False;
               can_move_from_traiettoria:= True;
               next_pos_abitante:= 0.0;
               if list_abitanti_uscita_ritorno/=null and then list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 then
                  if list_abitanti_uscita_andata/=null then
                     if list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=0.0 then
                        can_move_from_traiettoria:= False;
                     else
                        can_move_from_traiettoria:= mailbox.can_abitante_move(distance_ingresso,i,uscita_ritorno,current_polo_to_consider);
                     end if;
                  end if;
               end if;
               stop_entity:= False;
               if list_abitanti_uscita_ritorno/=null and can_move_from_traiettoria then
                  if list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                     stop_entity:= not mailbox.can_abitante_continue_move(distance_ingresso,1,uscita_ritorno,current_polo_to_consider);
                  elsif list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni.get_distanza_intersezione-max_larghezza_veicolo then
                     -- ASSUNZIONE CHE LA MACCHINA NON SIA PIÙ LUNGA DI PEZZI DI TRAIETTORIA TRA PT INTERSEZIONE
                     if list_abitanti_entrata_ritorno/=null and then list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                       max_larghezza_veicolo+get_traiettoria_ingresso(entrata_ritorno).get_intersezioni.get_distanza_intersezione then
                        stop_entity:= True;
                     else
                        stop_entity:= False;
                     end if;
                  --elsif (list_abitanti_entrata_ritorno=null or else list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                  --       get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva>max_larghezza_veicolo+get_traiettoria_ingresso(entrata_ritorno).get_intersezioni.get_distanza_intersezione)
                  --       and then list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                  --   stop_entity:= not mailbox.can_abitante_continue_move(distance_ingresso,2,uscita_ritorno,current_polo_to_consider);
                  --end if;
                  -- else seguente: se ho un abitante che è in list_abitanti_entrata_ritorno ho che l'incrocio da list_abitanti_uscita_ritorno è già stato impegnato
                  --                quindi avanza cmq list_abitanti_uscita_ritorno; altrimenti se list_abitanti_entrata_ritorno è null controllo la distanza dalle prossime macchine
                  elsif list_abitanti_entrata_ritorno=null and then list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                     stop_entity:= not mailbox.can_abitante_continue_move(distance_ingresso,2,uscita_ritorno,current_polo_to_consider);
                  end if;
                  if stop_entity=False then -- non ci sono macchine nella traiettoria entrata_ritorno quindi non deve essere data la precedenza alle macchine di quella traiettoria
                     key_ingresso:= 0;
                     -- cerco se ingressi precedenti hanno delle svolte a sx

                     for j in 1..i-1 loop
                        abitante:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(j,current_ingressi_structure_type_to_consider),uscita_ritorno);
                        if abitante/=null and then abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                           key_ingresso:= j;
                           costante_additiva:= get_larghezza_corsia+get_larghezza_marciapiede;
                        else
                           abitante:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(j,current_ingressi_structure_type_to_consider),entrata_ritorno);
                           if abitante/=null and then (abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie and
                                                         abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                                                                                                                                                      abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                                                         get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie) then
                              key_ingresso:= j;
                              if abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_quartiere_utilities_obj.get_auto_quartiere(abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva then
                                 costante_additiva:= get_quartiere_utilities_obj.get_auto_quartiere(abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva-abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+get_larghezza_corsia+get_larghezza_marciapiede;
                              else
                                 costante_additiva:= get_larghezza_corsia+get_larghezza_marciapiede;
                              end if;
                           end if;
                        end if;
                     end loop;
                     if key_ingresso/=0 then
                        next_pos_abitante:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(key_ingresso,current_ingressi_structure_type_to_consider)),not current_polo_to_consider)-costante_additiva;
                     end if;

                     -- cerco se ingressi nel polo opposto hanno svolte a sx
                     key_ingresso:= 0;
                     for j in reverse mailbox.get_ordered_ingressi_from_polo(not current_polo_to_consider).all'Range loop
                        if distance_ingresso<get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(j,current_ingressi_structure_type_to_not_consider)),current_polo_to_consider) then
                           abitante:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(j,current_ingressi_structure_type_to_not_consider),entrata_ritorno);
                           if abitante/=null and then (abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie and
                                                         abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                                                                                                                                                      abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                                                         get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie) then
                              key_ingresso:= j;
                              costante_additiva:= get_larghezza_corsia+get_larghezza_marciapiede;
                           else
                              abitante:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(j,current_ingressi_structure_type_to_not_consider),uscita_ritorno);
                              if abitante/=null then
                                 move_entity:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                                 if abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie
                                   and then abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-move_entity.get_length_entità_passiva<get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                                    key_ingresso:= j;
                                    costante_additiva:= max_larghezza_veicolo;
                                 end if;
                              end if;
                           end if;
                        end if;
                     end loop;
                     if key_ingresso/=0 then
                        if next_pos_abitante=0.0 or else next_pos_abitante>get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(key_ingresso,current_ingressi_structure_type_to_not_consider)),not current_polo_to_consider)-costante_additiva then -- 10.0 dimensione di metà strada
                           next_pos_abitante:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(key_ingresso,current_ingressi_structure_type_to_not_consider)),not current_polo_to_consider)+costante_additiva;
                        end if;
                     end if;
                     acceleration_car:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti)).get_max_acceleration;
                     traiettoria_rimasta_da_percorrere:= get_traiettoria_ingresso(uscita_ritorno).get_lunghezza-list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                     next_abitante:= mailbox.get_next_abitante_on_road(get_urbana_from_id(id_task).get_lunghezza_road-(distance_ingresso-get_larghezza_marciapiede-get_larghezza_corsia),not current_polo_to_consider,1);
                     distance_to_stop_line:= distance_ingresso-get_larghezza_marciapiede-get_larghezza_corsia+traiettoria_rimasta_da_percorrere;
                     calculate_parameters_car_in_uscita(list_abitanti_uscita_ritorno,traiettoria_rimasta_da_percorrere,next_abitante,distance_to_stop_line,uscita_ritorno,get_urbana_from_id(id_task).get_lunghezza_road-distance_ingresso,next_pos_abitante,acceleration,new_step,new_speed);
                     fix_advance_parameters(acceleration,new_speed,new_step,speed_abitante,next_pos_abitante,distance_to_stop_line,acceleration_car);

                     -- begin ottimizzazione nella percorrenza della traiettoria uscita ritorno
                     -- scaglioni steps
                     if list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                        if list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then -- se è maggiore dato che se è uguale sai già che li si ferma
                           stop_entity:= not mailbox.can_abitante_continue_move(distance_ingresso,1,uscita_ritorno,current_polo_to_consider);
                           if stop_entity then -- la macchina si deve fermare li
                              new_step:= get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie-list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                           end if;
                        end if;
                     end if;
                     if stop_entity=False and then list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(uscita_ritorno).get_intersezioni.get_distanza_intersezione-max_larghezza_veicolo then
                        if list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni.get_distanza_intersezione-max_larghezza_veicolo then
                           if list_abitanti_entrata_ritorno/=null and then list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                             max_larghezza_veicolo+get_traiettoria_ingresso(entrata_ritorno).get_intersezioni.get_distanza_intersezione then
                              stop_entity:= True;
                           else
                              stop_entity:= False;
                           end if;
                           if stop_entity then
                              new_step:= get_traiettoria_ingresso(uscita_ritorno).get_intersezioni.get_distanza_intersezione-max_larghezza_veicolo-list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                           end if;
                        end if;
                     end if;
                     if stop_entity=False and then list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                        if list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                           if list_abitanti_entrata_ritorno=null and then list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                              stop_entity:= not mailbox.can_abitante_continue_move(distance_ingresso,2,uscita_ritorno,current_polo_to_consider);
                              if stop_entity then
                                 new_step:= get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie-list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                              end if;
                           end if;
                        end if;
                     end if;
                     -- end scaglioni steps e ottimizzazione

                     mailbox.set_move_parameters_entity_on_traiettoria_ingresso(list_abitanti_uscita_ritorno,ingresso.get_id_road,uscita_ritorno,not current_polo_to_consider,new_speed,new_step);
                     Put_Line("id_abitante " & Positive'Image(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & Float'Image(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is traiettoria uscita ritorno ingresso " & Positive'Image(id_task));
                  end if;
               end if;


               -- TRAIETTORIA ENTRATA_RITORNO
               can_move_from_traiettoria:= True;
               next_pos_abitante:= 0.0;
               stop_entity:= False;
               if list_abitanti_entrata_ritorno/=null and then list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 then
                  if list_abitanti_uscita_ritorno=null then
                     can_move_from_traiettoria:= True;
                  else
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
               end if;
               if list_abitanti_entrata_ritorno/=null and can_move_from_traiettoria then
                  if list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                     stop_entity:= not mailbox.can_abitante_continue_move(get_urbana_from_id(id_task).get_lunghezza_road-distance_ingresso,1,entrata_ritorno,current_polo_to_consider);
                  end if;
                  if list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                     if list_abitanti_entrata_andata/=null then -- and then list_abitanti_entrata_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=0.0 then
                        stop_entity:= True;
                     else --list_abitanti_entrata_andata=null  --if list_abitanti_entrata_andata=null then
                        stop_entity:= not mailbox.can_abitante_continue_move(get_urbana_from_id(id_task).get_lunghezza_road-distance_ingresso,2,entrata_ritorno,current_polo_to_consider);
                     end if;
                  end if;

                  if stop_entity=False then
                     acceleration_car:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti)).get_max_acceleration;
                     traiettoria_rimasta_da_percorrere:= get_traiettoria_ingresso(entrata_ritorno).get_lunghezza-list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                     next_abitante:= get_ingressi_segmento_resources(mailbox.get_index_ingresso_from_key(i,current_ingressi_structure_type_to_consider)).get_first_abitante_to_exit_from_urbana;
                     distance_to_stop_line:= ingresso.get_lunghezza_road+traiettoria_rimasta_da_percorrere;
                     calculate_parameters_car_in_entrata(list_abitanti_entrata_ritorno,traiettoria_rimasta_da_percorrere,next_abitante,distance_to_stop_line,entrata_ritorno,next_pos_abitante,acceleration,new_step,new_speed);
                     fix_advance_parameters(acceleration,new_speed,new_step,speed_abitante,next_pos_abitante,distance_to_stop_line,acceleration_car);

                     -- begin ottimizzazione nella percorrenza della traiettoria uscita ritorno
                     -- scaglioni steps
                     if list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(entrata_ritorno).get_intersezioni.get_distanza_intersezione-max_larghezza_veicolo then
                        if list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni.get_distanza_intersezione-max_larghezza_veicolo then
                           if list_abitanti_uscita_ritorno/=null and then (list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie-max_larghezza_veicolo and then
                                                                           (list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                                                                             max_larghezza_veicolo+get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie)) then
                              stop_entity:= True;
                           end if;
                           if stop_entity then
                              new_step:= get_traiettoria_ingresso(entrata_ritorno).get_intersezioni.get_distanza_intersezione-max_larghezza_veicolo-list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                           end if;
                        end if;
                     end if;
                     if stop_entity=False and then list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                        if list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni.get_distanza_intersezione-max_larghezza_veicolo then
                           stop_entity:= not mailbox.can_abitante_continue_move(get_urbana_from_id(id_task).get_lunghezza_road-distance_ingresso,1,entrata_ritorno,current_polo_to_consider);
                           if stop_entity then
                              new_step:= get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie-list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                           end if;
                        end if;
                     end if;
                     if stop_entity=False and then list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                        if list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                           if list_abitanti_entrata_andata/=null then
                              stop_entity:= True;
                           else
                              stop_entity:= not mailbox.can_abitante_continue_move(get_urbana_from_id(id_task).get_lunghezza_road-distance_ingresso,2,entrata_ritorno,current_polo_to_consider);
                           end if;
                           if stop_entity then
                              new_step:= get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie-list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                           end if;
                        end if;
                     end if;
                     -- end scaglioni e ottimizzazioni

                     mailbox.set_move_parameters_entity_on_traiettoria_ingresso(list_abitanti_entrata_ritorno,ingresso.get_id_road,entrata_ritorno,current_polo_to_consider,new_speed,new_step);
                     Put_Line("id_abitante " & Positive'Image(list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & Float'Image(list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is traiettoria entrata ritorno ingresso " & Positive'Image(id_task));
                  end if;
               end if;

               -- TRAIETTORIA ENTRATA_ANDATA
               can_move_from_traiettoria:= True;
               next_pos_abitante:= 0.0;
               if list_abitanti_entrata_andata/=null and then list_abitanti_entrata_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 then
                  next_abitante:= mailbox.get_next_abitante_on_road(distance_ingresso,current_polo_to_consider,1);
                  if next_abitante/=null then
                     move_entity:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                     if next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-move_entity.get_length_entità_passiva<ingresso.get_distance_from_road_head_ingresso then
                        can_move_from_traiettoria:= False;
                     elsif list_abitanti_entrata_ritorno/=null and then list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then  -- > e non >= dato che se fosse uguale allora l'abitante in entrata ritorno sarebbe fermo
                        can_move_from_traiettoria:= False;
                     else
                        can_move_from_traiettoria:= True;
                     end if;
                  else
                     can_move_from_traiettoria:= True;
                  end if;
               end if;
               if list_abitanti_entrata_andata/=null and can_move_from_traiettoria then
                  acceleration_car:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_entrata_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_entrata_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti)).get_max_acceleration;
                  traiettoria_rimasta_da_percorrere:= get_traiettoria_ingresso(entrata_andata).get_lunghezza-list_abitanti_entrata_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                  next_abitante:= get_ingressi_segmento_resources(mailbox.get_index_ingresso_from_key(i,current_ingressi_structure_type_to_consider)).get_first_abitante_to_exit_from_urbana;
                  distance_to_stop_line:= ingresso.get_lunghezza_road+traiettoria_rimasta_da_percorrere;
                  calculate_parameters_car_in_entrata(list_abitanti_entrata_andata,traiettoria_rimasta_da_percorrere,next_abitante,distance_to_stop_line,entrata_andata,next_pos_abitante,acceleration,new_step,new_speed);
                  fix_advance_parameters(acceleration,new_speed,new_step,speed_abitante,next_pos_abitante,distance_to_stop_line,acceleration_car);
                  mailbox.set_move_parameters_entity_on_traiettoria_ingresso(list_abitanti_entrata_andata,ingresso.get_id_road,entrata_andata,current_polo_to_consider,new_speed,new_step);
                  Put_Line("id_abitante " & Positive'Image(list_abitanti_entrata_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & Float'Image(list_abitanti_entrata_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is traiettoria entrata andata ingresso " & Positive'Image(id_task));
               end if;
            end loop;
            current_polo_to_consider:= True;
            current_ingressi_structure_type_to_consider:= ordered_polo_true;
            current_ingressi_structure_type_to_not_consider:= ordered_polo_false;
         end loop;

         -- spostamento abitanti da incrocio a strada
         mailbox.sposta_abitanti_in_transizione_da_incroci;
         mailbox.delta_terminate;
         --log_mio.write_task_arrived("id_task " & Positive'Image(id_task) & " id_quartiere " & Positive'Image(get_id_quartiere));

      end loop;
   exception
      when Error: others =>
         Put_Line("Unexpected exception urbane: " & Positive'Image(id_task));
         Put_Line(Exception_Information(Error));
      --Put_Line("Fine task urbana" & Positive'Image(id_task) & ",id quartiere" & Positive'Image(get_id_quartiere));
   end core_avanzamento_urbane;

   task body core_avanzamento_ingressi is
      id_task: Positive;
      mailbox: ptr_resource_segmento_ingresso;
      resource_main_strada: ptr_resource_segmento_urbana;
      list_abitanti: ptr_list_posizione_abitanti_on_road:= null;
      acceleration: Float:= 0.0;
      acceleration_car: Float;
      new_speed: Float:= 0.0;
      new_step: Float:= 0.0;
      distance_to_next: Float:= 0.0;
      new_requests: ptr_list_posizione_abitanti_on_road:= null;
      --residente: move_parameters;
      pragma Warnings(off);
      default_pos_abitanti: posizione_abitanti_on_road;
      pragma Warnings(on);
      current_posizione_abitante: posizione_abitanti_on_road'Class:= default_pos_abitanti;
      next_posizione_abitante: posizione_abitanti_on_road'Class:= default_pos_abitanti;
      traiettoria_type: traiettoria_ingressi_type;
      traiettoria_on_main_strada: trajectory_to_follow;
      distanza_stop_line: Float;
      state_view_abitanti: JSON_Array;
      num_delta: Natural:= 0;
      speed_abitante: Float;
      before_distance_stop_road: Boolean;
   begin
      accept configure(id: Positive) do
         id_task:= id;
         mailbox:= get_ingressi_segmento_resources(id);
         resource_main_strada:= get_urbane_segmento_resources(get_ingresso_from_id(id_task).get_id_main_strada_ingresso);
      end configure;

      wait_settings_all_quartieri;
      --Put_Line("task " & Positive'Image(id_task) & " of quartiere " & Positive'Image(get_id_quartiere) & " is set");

      -- Ora i task e le risorse di tutti i quartieri sono attivi
      reconfigure_resource(ptr_backup_interface(mailbox),id_task);

      loop

         synchronization_with_delta(id_task);
         --Put_Line("wait " & Positive'Image(get_ingresso_from_id(id_task).get_id_main_strada_ingresso) & " id quartiere " & Positive'Image(get_id_quartiere));
         --log_mio.write_task_arrived("id_task " & Positive'Image(id_task) & " id_quartiere " & Positive'Image(get_id_quartiere));

         state_view_abitanti:= Empty_Array;
         mailbox.update_position_entity(state_view_abitanti);
         state_view_quartiere.registra_aggiornamento_stato_risorsa(id_task,state_view_abitanti);

         -- crea snapshot se necessario
         crea_snapshot(num_delta,ptr_backup_interface(mailbox),id_task);

         resource_main_strada.ingresso_wait_turno;

         list_abitanti:= mailbox.get_main_strada(mailbox.get_index_inizio_moto);
         for i in 1..mailbox.get_number_entity_strada(mailbox.get_index_inizio_moto) loop
            --mailbox.update_position_entity(state_view_abitanti,road,mailbox.get_index_inizio_moto,i);
            if list_abitanti/=null then
               current_posizione_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
               acceleration_car:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti)).get_max_acceleration;
               Put_Line("id_abitante " & Positive'Image(current_posizione_abitante.get_id_abitante_posizione_abitanti) & " is at " & Float'Image(current_posizione_abitante.get_where_now_posizione_abitanti) & ", gestore is ingresso " & Positive'Image(id_task));

               speed_abitante:= current_posizione_abitante.get_current_speed_abitante;
               before_distance_stop_road:= False;
               distanza_stop_line:= get_ingresso_from_id(id_task).get_lunghezza_road-current_posizione_abitante.get_where_now_posizione_abitanti;

               --if current_posizione_abitante.get_where_now_posizione_abitanti>35.0 and current_posizione_abitante.get_id_abitante_posizione_abitanti=62 then
               --   null;
               --else


               if list_abitanti.all.get_next_from_list_posizione_abitanti/=null then
                  next_posizione_abitante:= list_abitanti.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
                  distance_to_next:= next_posizione_abitante.get_where_now_posizione_abitanti-move_parameters(get_quartiere_utilities_obj.all.get_auto_quartiere(next_posizione_abitante.get_id_quartiere_posizione_abitanti,next_posizione_abitante.get_id_abitante_posizione_abitanti)).get_length_entità_passiva-current_posizione_abitante.get_where_now_posizione_abitanti;
                  if distance_to_next<=0.0 then acceleration:= 0.0;
                  else
                     acceleration:= calculate_acceleration(mezzo => car,
                                                     id_abitante => current_posizione_abitante.get_id_abitante_posizione_abitanti,
                                                     id_quartiere_abitante => current_posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                     next_entity_distance => distance_to_next,
                                                     distance_to_stop_line => distanza_stop_line+add_factor,
                                                     next_id_quartiere_abitante => next_posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                     next_id_abitante => next_posizione_abitante.get_id_abitante_posizione_abitanti,
                                                     abitante_velocity => speed_abitante,
                                                     next_abitante_velocity => next_posizione_abitante.get_current_speed_abitante);
                  end if;
               else
                  if mailbox.get_last_abitante_in_urbana.get_id_quartiere_posizione_abitanti/=0 then
                     -- car avanzamento=0 indica che la macchina davanti ha percorso sorpassato completamente l'ingresso
                     if mailbox.get_car_avanzamento=0.0 then
                        distance_to_next:= 0.0;---1.0;
                        --before_distance_stop_road:= False;
                        --distanza_stop_line:= get_ingresso_from_id(id_task).get_lunghezza_road-current_posizione_abitante.get_where_now_posizione_abitanti+1.0;
                     else
                        --distanza_stop_line:= get_ingresso_from_id(id_task).get_lunghezza_road-current_posizione_abitante.get_where_now_posizione_abitanti-mailbox.get_car_avanzamento;
                        --distance_to_next:= distanza_stop_line;
                        --before_distance_stop_road:= True;
                        distance_to_next:= get_ingresso_from_id(id_task).get_lunghezza_road-current_posizione_abitante.get_where_now_posizione_abitanti-mailbox.get_car_avanzamento;
                     end if;
                  else
                     distance_to_next:= 0.0;---1.0;
                     --before_distance_stop_road:= False;
                     --distanza_stop_line:= get_ingresso_from_id(id_task).get_lunghezza_road-current_posizione_abitante.get_where_now_posizione_abitanti+1.0;
                  end if;
                  acceleration:= calculate_acceleration(mezzo => car,
                                                        id_abitante => current_posizione_abitante.get_id_abitante_posizione_abitanti,
                                                        id_quartiere_abitante => current_posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                        next_entity_distance => distance_to_next,
                                                        distance_to_stop_line => distanza_stop_line+add_factor,
                                                        next_id_quartiere_abitante => 0,
                                                        next_id_abitante => 0,
                                                        abitante_velocity => speed_abitante,
                                                        next_abitante_velocity =>0.0);
                                                        --distance_stop_before_end_road => before_distance_stop_road);
               end if;
               new_speed:= calculate_new_speed(speed_abitante,acceleration);
               new_step:= calculate_new_step(new_speed,acceleration);
               fix_advance_parameters(acceleration,new_speed,new_step,speed_abitante,distance_to_next,distanza_stop_line,acceleration_car);

               --if distance_to_next>=0.0 and then new_step>distance_to_next then
               --   if distance_to_next<=min_veicolo_distance then
               --      new_step:= 0.0;
               --   else
               --      new_step:= distance_to_next;
               --   end if;
               --   new_speed:= new_speed/2.0;
               --end if;

               mailbox.set_move_parameters_entity_on_main_strada(range_1 => mailbox.get_index_inizio_moto,num_entity => i,speed => new_speed,step_to_advance => new_step);
               current_posizione_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
               if current_posizione_abitante.get_where_next_posizione_abitanti=get_ingresso_from_id(id_task).get_lunghezza_road then
                  traiettoria_type:= calculate_traiettoria_to_follow_from_ingresso(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti,id_task,resource_main_strada.get_ingressi_ordered_by_distance);
                  Put_Line(traiettoria_ingressi_type'Image(traiettoria_type));
                  traiettoria_on_main_strada:= calculate_trajectory_to_follow_on_main_strada_from_ingresso(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti,id_task,traiettoria_type);
                  resource_main_strada.aggiungi_entità_from_ingresso(id_task,traiettoria_type,current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti,traiettoria_on_main_strada);
                  mailbox.delete_car_in_uscita;
                  list_abitanti:= null;
               else
                  list_abitanti:= list_abitanti.all.get_next_from_list_posizione_abitanti;
               end if;
             --  end if;
            end if;

         end loop;

         new_requests:= mailbox.get_temp_main_strada;
         if new_requests/=null then
            list_abitanti:= mailbox.get_main_strada(mailbox.get_index_inizio_moto);
            current_posizione_abitante:= new_requests.all.get_posizione_abitanti_from_list_posizione_abitanti;
            mailbox.registra_abitante_to_move(road,0.0,0.0);
         end if;

         list_abitanti:= mailbox.get_main_strada(not mailbox.get_index_inizio_moto);
         for i in 1..mailbox.get_number_entity_strada(not mailbox.get_index_inizio_moto) loop
            current_posizione_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
            acceleration_car:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti)).get_max_acceleration;
            Put_Line("id_abitante " & Positive'Image(current_posizione_abitante.get_id_abitante_posizione_abitanti) & " is at " & Float'Image(current_posizione_abitante.get_where_now_posizione_abitanti) & ", gestore is ingresso " & Positive'Image(id_task));
            -- elimino l'elemento se è fuori traiettoria

            speed_abitante:= current_posizione_abitante.get_current_speed_abitante;

            if current_posizione_abitante.get_where_next_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva>=get_ingresso_from_id(id_task).get_lunghezza_road then
               mailbox.delete_car_in_entrata;
               get_quartiere_utilities_obj.get_classe_locate_abitanti(current_posizione_abitante.get_id_quartiere_posizione_abitanti).set_finish_route(current_posizione_abitante.get_id_abitante_posizione_abitanti);
               get_quartiere_entities_life(current_posizione_abitante.get_id_quartiere_posizione_abitanti).abitante_is_arrived(current_posizione_abitante.get_id_abitante_posizione_abitanti);
            else
               --mailbox.update_position_entity(state_view_abitanti,road,not mailbox.get_index_inizio_moto,i);
               current_posizione_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
               -- FLAG OVERTAKE NEXT CORSIA usato per indicare se l'abitante ha già attraversato l'incrocio completamente
               if i=1 and then (current_posizione_abitante.get_flag_overtake_next_corsia=False and then current_posizione_abitante.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva>=0.0) then
                  mailbox.set_flag_spostamento_from_urbana_completato;
                  if current_posizione_abitante.get_destination.get_corsia_to_go_trajectory=1 then
                     resource_main_strada.remove_first_element_traiettoria(id_task,entrata_ritorno);
                  else
                     resource_main_strada.remove_first_element_traiettoria(id_task,entrata_andata);
                  end if;
               end if;
               before_distance_stop_road:= False;
               if list_abitanti.all.get_next_from_list_posizione_abitanti/=null then
                  next_posizione_abitante:= list_abitanti.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
                  distance_to_next:= next_posizione_abitante.get_where_now_posizione_abitanti-move_parameters(get_quartiere_utilities_obj.all.get_auto_quartiere(next_posizione_abitante.get_id_quartiere_posizione_abitanti,next_posizione_abitante.get_id_abitante_posizione_abitanti)).get_length_entità_passiva-current_posizione_abitante.get_where_now_posizione_abitanti;
                  if distance_to_next<=0.0 then acceleration:= 0.0;
                  else
                     acceleration:= calculate_acceleration(mezzo => car,
                                                     id_abitante => current_posizione_abitante.get_id_abitante_posizione_abitanti,
                                                     id_quartiere_abitante => current_posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                     next_entity_distance => distance_to_next,
                                                     distance_to_stop_line => Float'Last,
                                                     next_id_quartiere_abitante => next_posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                     next_id_abitante => next_posizione_abitante.get_id_abitante_posizione_abitanti,
                                                     abitante_velocity => speed_abitante,
                                                     next_abitante_velocity => next_posizione_abitante.get_current_speed_abitante);
                  end if;
               else
                  distance_to_next:= 0.0;
                  acceleration:= calculate_acceleration(mezzo => car,
                                                     id_abitante => current_posizione_abitante.get_id_abitante_posizione_abitanti,
                                                     id_quartiere_abitante => current_posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                     next_entity_distance => 0.0,
                                                     distance_to_stop_line => Float'Last,
                                                     next_id_quartiere_abitante => 0,
                                                     next_id_abitante => 0,
                                                     abitante_velocity => speed_abitante,
                                                     next_abitante_velocity =>0.0);
               end if;
               new_speed:= calculate_new_speed(speed_abitante,acceleration);
               new_step:= calculate_new_step(new_speed,acceleration);
               fix_advance_parameters(acceleration,new_speed,new_step,speed_abitante,distance_to_next,Float'Last,acceleration_car);

               mailbox.set_move_parameters_entity_on_main_strada(range_1 => not mailbox.get_index_inizio_moto,num_entity => i,speed => new_speed,step_to_advance => new_step);
               current_posizione_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
               list_abitanti:= list_abitanti.all.get_next_from_list_posizione_abitanti;
            end if;
         end loop;

         --log_mio.write_task_arrived("id_task " & Positive'Image(id_task) & " id_quartiere " & Positive'Image(get_id_quartiere));

      end loop;
   exception
      when Error: others =>
         Put_Line("Unexpected exception ingressi: " & Positive'Image(id_task));
         Put_Line(Exception_Information(Error));


      --Put_Line("Fine task ingresso" & Positive'Image(id_task) & ",id quartiere" & Positive'Image(get_id_quartiere));
   end core_avanzamento_ingressi;

   task body core_avanzamento_incroci is
      id_task: Positive;
      mailbox: ptr_resource_segmento_incrocio;
      id_mancante: Natural:= 0;
      list_car: ptr_list_posizione_abitanti_on_road;
      --list: ptr_list_posizione_abitanti_on_road;
      list_near_car: ptr_list_posizione_abitanti_on_road;
      --list_near_other_car: ptr_list_posizione_abitanti_on_road;  -- altra traiettoria
      index_road: Positive;
      index_other_road: Natural;
      switch: Boolean;
      quantità_percorsa: Float:= 0.0;  --***************  TO DO communicate with other roads
      --traiettoria_near_car: traiettoria_incroci_type;
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
      --can_continue: Boolean;
      id_main_road: Positive;
      o: Boolean:= False;
      state_view_abitanti: JSON_Array;
      num_delta: Natural:= 0;
      acceleration_car: Float;
      speed_abitante: Float;
      num_car: Positive;
   begin
      accept configure(id: Positive) do
         id_task:= id;
         mailbox:= get_incroci_segmento_resources(id);
         id_mancante:= get_mancante_incrocio_a_3(id_task);
      end configure;

      wait_settings_all_quartieri;
      --Put_Line("task " & Positive'Image(id_task) & " of quartiere " & Positive'Image(get_id_quartiere) & " is set");
      -- Ora i task e le risorse di tutti i quartieri sono attivi

      reconfigure_resource(ptr_backup_interface(mailbox),id_task);

      loop

         synchronization_with_delta(id_task);
         --log_mio.write_task_arrived("id_task " & Positive'Image(id_task) & " id_quartiere " & Positive'Image(get_id_quartiere));

         state_view_abitanti:= Empty_Array;
         mailbox.update_avanzamento_cars(state_view_abitanti);
         state_view_quartiere.registra_aggiornamento_stato_risorsa(id_task,state_view_abitanti);

         -- crea snapshot se necessario
         crea_snapshot(num_delta,ptr_backup_interface(mailbox),id_task);

         for i in 1..mailbox.get_size_incrocio loop
            for j in id_corsie'Range loop
               list_car:= mailbox.get_list_car_to_move(i,j);
               index_road:= i;
               if id_mancante/=0 and i>=id_mancante then  -- condizione valida per incroci a 3
                  index_road:= i+1;
               end if;
               -- controlla se ci sono macchine da spostare
               num_car:= 1;
               while list_car/=null loop
                  if get_id_quartiere=1 and id_task=60 then
                     o:=True;
                  end if;
                  traiettoria_car:= list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow;

                  length_traiettoria:= get_traiettoria_incrocio(traiettoria_car).get_lunghezza_traiettoria_incrocio;
                  -- !!! QUI IL FLAG overtake_next_corsia VIENE USATO PER VEDERE SE LA MACCHINA HA ATTRAVERSATO COMPLETAMENTO L'URBANA PRECEDENTE
                  if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia=False and then
                    list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                                                                                                                 list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva>=0.0 then
                     if id_task=56 and list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti=65 then
                           o:= False;
                     end if;
                     mailbox.set_car_have_passed_urbana(list_car);
                     -- la prima volta è un ingresso quindi errore conversion
                     tratto_road:= get_quartiere_utilities_obj.get_classe_locate_abitanti(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_current_tratto(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                     -- l'incrocio sta nel quartiere in cui sta girando questo codice
                     if get_quartiere_utilities_obj.get_classe_locate_abitanti(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_current_position(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti)=1 then
                        id_main_road:= get_quartiere_cfg(tratto_road.get_id_quartiere_tratto).get_id_main_road_from_id_ingresso(tratto_road.get_id_tratto);
                     else
                        id_main_road:= tratto_road.get_id_tratto;
                     end if;
                     ptr_rt_urbana(get_id_urbana_quartiere(tratto_road.get_id_quartiere_tratto,id_main_road)).remove_abitante_in_incrocio(get_road_from_incrocio(id_task,get_index_road_from_incrocio(tratto_road.get_id_quartiere_tratto,id_main_road,id_task)).get_polo_road_incrocio,list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                  end if;
                  if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<length_traiettoria then
                     stop_entity:= False;
                     bound_distance:= -1.0;  -- to fix that bound_distance is not set
                     distance_to_next_car:= -1.0;
                     mailbox.calcola_bound_avanzamento_in_incrocio(index_road             => index_road,
                                                                   indice                 => i,
                                                                   traiettoria_car        => traiettoria_car,
                                                                   corsia                 => j,
                                                                   num_car                => num_car,
                                                                   bound_distance         => bound_distance,
                                                                   stop_entity            => stop_entity,
                                                                   distance_to_next_car => distance_to_next_car,
                                                                   from_id_quartiere_road => 0,
                                                                   from_id_road           => 0);


                     index_other_road:= 0;
                     if index_road=1 then
                        index_other_road:= 3;
                     elsif index_road=2 then
                        index_other_road:= 4;
                     elsif index_road=3 then
                        index_other_road:= 1;
                     elsif index_road=4 then
                        index_other_road:= 2;
                     end if;

                     if id_mancante/=index_other_road then
                        if id_mancante/=0 and index_other_road>id_mancante then  -- condizione valida per incroci a 3
                           index_other_road:= index_other_road-1;
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
                        acceleration_car:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti)).get_max_acceleration;
                        speed_abitante:= list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                        acceleration:= calculate_acceleration(mezzo => car,
                                                              id_abitante => list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                              id_quartiere_abitante => list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                              next_entity_distance => 0.0,
                                                              distance_to_stop_line => distance_next_entity,
                                                              next_id_quartiere_abitante => 0,
                                                              next_id_abitante => 0,
                                                              abitante_velocity => speed_abitante,
                                                              next_abitante_velocity =>0.0);
                        new_speed:= calculate_new_speed(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante,acceleration);
                        new_step:= calculate_new_step(new_speed,acceleration);
                        fix_advance_parameters(acceleration,new_speed,new_step,speed_abitante,distance_next_entity,distance_next_entity,acceleration_car);
                        -- update scaglioni
                        if traiettoria_car=sinistra and index_other_road/=0 then -- index_other_road se 0 significa che non hai la strada opposta

                           if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<
                             get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_1).get_distanza_intersezione_incrocio-max_larghezza_veicolo then
                              if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_1).get_distanza_intersezione_incrocio-max_larghezza_veicolo then
                                 -- index_other_road è rimasto quello della strada opposta
                                 list_near_car:= mailbox.get_list_car_to_move(index_other_road,1);
                                 switch:= True;
                                 while switch and list_near_car/=null loop
                                    -- cicla e guarda se ci sono macchine che vogliono andare dritto
                                    if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                                      get_quartiere_utilities_obj.get_auto_quartiere(list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                                     list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                                      get_traiettoria_incrocio(dritto_1).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio+max_larghezza_veicolo then
                                       switch:= False;
                                    end if;
                                    list_near_car:= list_near_car.get_next_from_list_posizione_abitanti;
                                 end loop;
                                 if switch=False then
                                    new_step:= get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_1).get_distanza_intersezione_incrocio-max_larghezza_veicolo-list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                                 end if;
                              end if;
                           end if;
                           if switch or else list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<
                             get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_2).get_distanza_intersezione_incrocio-max_larghezza_veicolo then
                              if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_2).get_distanza_intersezione_incrocio-max_larghezza_veicolo then
                                 list_near_car:= mailbox.get_list_car_to_move(index_other_road,2);
                                 switch:= True;
                                 while switch and list_near_car/=null loop
                                    -- cicla e guarda se ci sono macchine che vogliono andare dritto
                                    if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                                      get_quartiere_utilities_obj.get_auto_quartiere(list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                                     list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                                      get_traiettoria_incrocio(dritto_2).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio+max_larghezza_veicolo then
                                       switch:= False;
                                    end if;
                                    list_near_car:= list_near_car.get_next_from_list_posizione_abitanti;
                                 end loop;
                                 if switch=False then
                                    new_step:= get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_2).get_distanza_intersezione_incrocio-max_larghezza_veicolo-list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                                 end if;
                              end if;
                           end if;
                        elsif traiettoria_car=dritto_1 or traiettoria_car= dritto_2 then
                           -- index_other_road è rimasto quello della strada opposta
                           list_near_car:= mailbox.get_list_car_to_move(index_other_road,1);
                           distanza_intersezione:= get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(traiettoria_car).get_distanza_intersezione_incrocio;
                           limite:= get_traiettoria_incrocio(traiettoria_car).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio;
                           switch:= True;
                           while switch and list_near_car/=null loop
                              if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow=sinistra then
                                 if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distanza_intersezione-max_larghezza_veicolo then
                                    if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_incrocio(sinistra).get_lunghezza_traiettoria_incrocio then
                                       road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,index_other_road,sinistra));
                                       quantità_percorsa:= ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                                    else
                                       quantità_percorsa:= 0.0;
                                    end if;
                                    id_quartiere_next_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                                    id_abitante_next_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                                    if quantità_percorsa+list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                                      get_quartiere_utilities_obj.get_auto_quartiere(id_quartiere_next_car,id_abitante_next_car).get_length_entità_passiva<limite+max_larghezza_veicolo then
                                       switch:= False;
                                    end if;
                                 end if;
                              end if;
                              list_near_car:= list_near_car.get_next_from_list_posizione_abitanti;
                           end loop;

                           if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_incrocio(traiettoria_car).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio-max_larghezza_veicolo then
                              if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>get_traiettoria_incrocio(traiettoria_car).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio-max_larghezza_veicolo then
                                 if switch=False then
                                    new_step:= get_traiettoria_incrocio(traiettoria_car).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio-max_larghezza_veicolo-list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                                 end if;
                              end if;
                           end if;
                        end if;
                        -- end update scaglioni

                        mailbox.update_avanzamento_car(list_car,new_step,new_speed);
                        Put_Line("id_abitante " & Positive'Image(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & Float'Image(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is incrocio " & Positive'Image(id_task));
                        if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<length_traiettoria and then list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>=length_traiettoria then
                           -- passaggio della macchina all'urbana
                           if id_task=56 and list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti=65 then
                           o:= False;
                           end if;

                           road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,i,traiettoria_car));
                           new_abitante:= posizione_abitanti_on_road(create_new_posizione_abitante_from_copy(list_car.get_posizione_abitanti_from_list_posizione_abitanti));
                           new_abitante.set_where_now_abitante(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti-length_traiettoria);
                           new_abitante.set_where_next_abitante(new_abitante.get_where_now_posizione_abitanti);
                           new_abitante.set_in_overtaken(False);
                           new_abitante.set_came_from_ingresso(False);
                           new_abitante.set_flag_overtake_next_corsia(False);
                           -- calcolo della traiettoria da seguire

                           -- può succedere che se l'abitante va molto veloce e si trova immediatamente alla fine dell'incrocio
                           -- senza aver rimosso l'abitante dall'urbana precedente
                           tratto_road:= get_quartiere_utilities_obj.get_classe_locate_abitanti(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_current_tratto(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                           -- l'incrocio sta nel quartiere in cui sta girando questo codice
                           if get_quartiere_utilities_obj.get_classe_locate_abitanti(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_current_position(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti)=1 then
                              id_main_road:= get_quartiere_cfg(tratto_road.get_id_quartiere_tratto).get_id_main_road_from_id_ingresso(tratto_road.get_id_tratto);
                           else
                              id_main_road:= tratto_road.get_id_tratto;
                           end if;

                           -- posizionamento all'incrocio corrente
                           get_quartiere_utilities_obj.get_classe_locate_abitanti(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).set_position_abitante_to_next(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                           new_abitante.set_destination(calculate_trajectory_to_follow_on_main_strada_from_incrocio(posizione_abitanti_on_road(list_car.get_posizione_abitanti_from_list_posizione_abitanti),road.get_polo_road_incrocio,list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory));

                           ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).insert_abitante_from_incrocio(new_abitante,not road.get_polo_road_incrocio,list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                           mailbox.update_abitante_destination(list_car,create_trajectory_to_follow(tratto_road.get_id_quartiere_tratto,list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory,0,id_main_road,traiettoria_car));
                        end if;
                     end if;
                  end if;
                  list_car:= list_car.get_next_from_list_posizione_abitanti;
                  num_car:= num_car+1;
               end loop;
            end loop;
         end loop;

         -- wake urbane
         for r in 1..get_size_incrocio(id_task) loop
            get_id_urbana_quartiere(get_road_from_incrocio(id_task,r).get_id_quartiere_road_incrocio,get_road_from_incrocio(id_task,r).get_id_strada_road_incrocio).delta_incrocio_finished;
         end loop;

         --log_mio.write_task_arrived("id_task " & Positive'Image(id_task) & " id_quartiere " & Positive'Image(get_id_quartiere));

      end loop;
   exception
      when Error: others =>
         Put_Line("Unexpected exception incroci: " & Positive'Image(id_task));
         Put_Line(Exception_Information(Error));

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

end risorse_strade_e_incroci;
