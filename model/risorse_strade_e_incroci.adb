with Ada.Text_IO;
with Ada.Numerics.Elementary_Functions;
with Ada.Exceptions;
with GNATCOLL.JSON;
with System_error;
with synchronization_partitions;

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
with numerical_types;
with default_settings;
with System.RPC;

use Ada.Text_IO;
use Ada.Numerics.Elementary_Functions;
use GNATCOLL.JSON;
use Ada.Exceptions;
use System_error;

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
use numerical_types;
use default_settings;
use synchronization_partitions;

package body risorse_strade_e_incroci is

   function calculate_acceleration(mezzo: means_of_carrying; id_abitante: Positive; id_quartiere_abitante: Positive; next_entity_distance: new_float; distance_to_stop_line: new_float; next_id_quartiere_abitante: Natural; next_id_abitante: Natural; abitante_velocity: in out new_float; next_abitante_velocity: new_float; disable_rallentamento_1: Boolean:= False; disable_rallentamento_2: Boolean:= False; request_by_incrocio: Boolean:= False) return new_float is
      residente: move_parameters;
      delta_speed: Float:= 0.0;
      free_road_coeff: Float;
      time_gap: Float;
      break_gap: Float;
      safe_distance: Float;
      busy_road_coeff: Float;
      --safe_intersection_distance: Float;
      next_step: new_float;
      next_speed: new_float;
      intersection_coeff: Float:= 0.0;
      coeff: new_float;
      begin_velocity: Float:= Float(abitante_velocity);
   begin
      case mezzo is
         when walking =>
            if request_by_incrocio then
               residente:= move_parameters(get_quartiere_utilities_obj.all.get_bici_quartiere(id_quartiere_abitante,id_abitante));
            else
               residente:= move_parameters(get_quartiere_utilities_obj.all.get_pedone_quartiere(id_quartiere_abitante,id_abitante));
            end if;
         when bike =>
            residente:= move_parameters(get_quartiere_utilities_obj.all.get_bici_quartiere(id_quartiere_abitante,id_abitante));
         when car =>
            residente:= move_parameters(get_quartiere_utilities_obj.all.get_auto_quartiere(id_quartiere_abitante,id_abitante));
      end case;
      if distance_to_stop_line<=0.0 or else next_entity_distance<0.0 then
         return 0.0;
      end if;
      while (distance_to_stop_line/=0.0 and then distance_to_stop_line<abitante_velocity) or else (next_entity_distance/=0.0 and then next_entity_distance<abitante_velocity) loop
         abitante_velocity:= abitante_velocity/2.0;
      end loop;

      if next_id_quartiere_abitante/=0 then
         delta_speed:= Float(abitante_velocity-next_abitante_velocity);
      else
         delta_speed:= Float(abitante_velocity);
      end if;

      free_road_coeff:= (Float(abitante_velocity/residente.get_desired_velocity))**4;

      time_gap:= Float(abitante_velocity*residente.get_time_headway);
      break_gap:= Float(abitante_velocity)*delta_speed/(2.0 * Sqrt(Float(residente.get_max_acceleration*residente.get_comfortable_deceleration)));

      safe_distance:= Float(residente.get_s0) + time_gap + break_gap;

      if next_entity_distance=0.0 then
         busy_road_coeff:= 0.0;
      else
         busy_road_coeff:= (safe_distance/Float(next_entity_distance))**2;
      end if;

      -- begin parameters not in the IDM models:
      if next_entity_distance=0.0 then
         intersection_coeff:= (Float(abitante_velocity/distance_to_stop_line))**2;
         coeff:= 1.0 - new_float(free_road_coeff) - new_float(intersection_coeff);


         if (free_road_coeff>intersection_coeff and intersection_coeff>0.0) or else (1.0 - free_road_coeff - intersection_coeff<=0.0) then
            coeff:= ((residente.get_desired_velocity-abitante_velocity)/delta_value)/(2.0*residente.get_max_acceleration);
         end if;

         if mezzo=car then
            next_speed:= calculate_new_speed(abitante_velocity,residente.get_max_acceleration*coeff);

            if disable_rallentamento_2=False and then distance_to_stop_line>distance_at_witch_decelarate then
               while distance_to_stop_line-calculate_new_step(next_speed,residente.get_max_acceleration*coeff)<=distance_at_witch_decelarate/2.0-1.0 loop
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
         end if;
      else
         if busy_road_coeff>=1.0 then
            busy_road_coeff:= (Float(abitante_velocity/next_entity_distance)**2);
         end if;

         if (free_road_coeff>busy_road_coeff and busy_road_coeff>0.0) or else (1.0 - free_road_coeff - busy_road_coeff<=0.0)  then
            coeff:= ((residente.get_desired_velocity-abitante_velocity)/delta_value)/(2.0*residente.get_max_acceleration);
         else
            coeff:= 1.0 - new_float(free_road_coeff) - new_float(busy_road_coeff);
         end if;

      end if;
      -- end parameters

      return residente.get_max_acceleration*coeff;
   end calculate_acceleration;

   function calculate_new_speed(current_speed: new_float; acceleration: new_float) return new_float is
   begin
      return current_speed + acceleration * delta_value;
   end calculate_new_speed;

   function calculate_new_step(new_speed: new_float; acceleration: new_float) return new_float is
   begin
      return new_speed * delta_value + new_float(0.5 * Float(acceleration) * Float(delta_value)**2);
   end calculate_new_step;

   function calculate_trajectory_to_follow_on_main_strada_from_ingresso(mezzo: means_of_carrying; id_quartiere_abitante: Positive; id_abitante: Positive; from_ingresso: Positive; traiettoria_type: traiettoria_ingressi_type) return trajectory_to_follow is
      next_nodo: tratto;
      next_road: tratto;
      tipo_entità: entity_type;
      id_road: Positive;
      id_road_mancante: Natural; -- se 0 => allora non ne manca neanche 1 si tratta cioè di 1 incrocio a 4
      index_road_from: Positive;
      index_road_to: Positive;
      corsia_traiettoria: Natural;
      corsia_to_go_if_dritto: Positive;
      other_corsia: id_corsie;
   begin
      if traiettoria_type=uscita_andata then
         corsia_traiettoria:= 2;
         corsia_to_go_if_dritto:= 2;
      elsif traiettoria_type=uscita_ritorno then
         corsia_traiettoria:= 1;
         corsia_to_go_if_dritto:= 1;
      elsif traiettoria_type=uscita_destra_pedoni or traiettoria_type=uscita_dritto_pedoni then
         corsia_traiettoria:= 2;
         corsia_to_go_if_dritto:= 2;
      elsif traiettoria_type=uscita_destra_bici or traiettoria_type=uscita_dritto_bici then
         corsia_traiettoria:= 1;
         corsia_to_go_if_dritto:= 1;
      else
         corsia_traiettoria:= 0;
      end if;
      Put_Line("next nodo inigresso request by " & Positive'Image(id_abitante));
      next_nodo:= get_quartiere_utilities_obj.get_classe_locate_abitanti(id_quartiere_abitante).get_next(id_abitante);
      if next_nodo.get_id_quartiere_tratto=get_id_quartiere and then (next_nodo.get_id_tratto>=get_from_ingressi and next_nodo.get_id_tratto<=get_to_ingressi) then
         if get_ingresso_from_id(from_ingresso).get_polo_ingresso=get_ingresso_from_id(next_nodo.get_id_tratto).get_polo_ingresso then
            return create_trajectory_to_follow(corsia_traiettoria,corsia_traiettoria,next_nodo.get_id_tratto,from_ingresso,empty);
         else
            if mezzo=car then
               if corsia_traiettoria=1 then
                  other_corsia:= 2;
               else
                  other_corsia:= 1;
               end if;
            else
               other_corsia:= corsia_traiettoria;
            end if;
            return create_trajectory_to_follow(corsia_traiettoria,other_corsia,next_nodo.get_id_tratto,from_ingresso,empty);
         end if;
      else
         next_road:= get_quartiere_utilities_obj.get_classe_locate_abitanti(id_quartiere_abitante).get_next_road(id_abitante,True);
         tipo_entità:= get_ref_quartiere(next_road.get_id_quartiere_tratto).get_type_entity(next_road.get_id_tratto);
         if tipo_entità=ingresso then
            id_road:= get_ref_quartiere(next_road.get_id_quartiere_tratto).get_id_main_road_from_id_ingresso(next_road.get_id_tratto);
         else
            id_road:= next_road.get_id_tratto;
         end if;
         -- il quartiere di id_road è sempre next_road.get_id_quartiere_tratto
         get_ref_quartiere(next_nodo.get_id_quartiere_tratto).get_cfg_incrocio(next_nodo.get_id_tratto,create_tratto(get_ingresso_from_id(from_ingresso).get_id_quartiere_road,get_ingresso_from_id(from_ingresso).get_id_main_strada_ingresso),create_tratto(next_road.get_id_quartiere_tratto,id_road),index_road_from,index_road_to,id_road_mancante);
         -- configurazione incrocio settata
         if id_road_mancante=0 and (index_road_from=0 or index_road_to=0) then
            return create_trajectory_to_follow(0,0,0,from_ingresso,empty);  --errore
         else
            if abs(index_road_from-index_road_to)=2 then
               case mezzo is
                  when car =>
                     if corsia_to_go_if_dritto=1 then
                        return create_trajectory_to_follow(corsia_traiettoria,corsia_to_go_if_dritto,0,from_ingresso,dritto_1);
                     else
                        return create_trajectory_to_follow(corsia_traiettoria,corsia_to_go_if_dritto,0,from_ingresso,dritto_2);
                     end if;
                  when walking =>
                     return create_trajectory_to_follow(corsia_traiettoria,corsia_to_go_if_dritto,0,from_ingresso,dritto_pedoni);
                  when bike =>
                     return create_trajectory_to_follow(corsia_traiettoria,corsia_to_go_if_dritto,0,from_ingresso,dritto_bici);
               end case;
            elsif (index_road_from=1 and index_road_to=4) or else (index_road_from=2 and index_road_to=1) or else
              (index_road_from=3 and index_road_to=2) or else (index_road_from=4 and index_road_to=3) then
               case mezzo is
                  when car =>
                     return create_trajectory_to_follow(corsia_traiettoria,2,0,from_ingresso,destra);
                  when walking =>
                     return create_trajectory_to_follow(corsia_traiettoria,corsia_traiettoria,0,from_ingresso,destra_pedoni);
                  when bike =>
                     return create_trajectory_to_follow(corsia_traiettoria,corsia_traiettoria,0,from_ingresso,destra_bici);
               end case;
            else
               case mezzo is
                  when car =>
                     return create_trajectory_to_follow(corsia_traiettoria,1,0,from_ingresso,sinistra);
                  when walking =>
                     return create_trajectory_to_follow(corsia_traiettoria,corsia_traiettoria,0,from_ingresso,sinistra_pedoni);
                  when bike =>
                     return create_trajectory_to_follow(corsia_traiettoria,corsia_traiettoria,0,from_ingresso,sinistra_bici);
               end case;
            end if;
         end if;
      end if;
   end calculate_trajectory_to_follow_on_main_strada_from_ingresso;

   function calculate_trajectory_to_follow_from_incrocio(mezzo: means_of_carrying; abitante: posizione_abitanti_on_road; polo: Boolean; num_corsia: id_corsie) return trajectory_to_follow is
      next_nodo: tratto;
      next_incrocio: tratto;
      next_road: tratto;
      index_road_from: Natural;
      index_road_to: Natural;
      id_road_mancante: Natural;
      id_road: Natural;
   begin
      -- next_nodo sarà o la strada corrente o un suo ingresso
      Put_Line("next nodo request by " & Positive'Image(abitante.get_id_abitante_posizione_abitanti));
      next_nodo:= get_quartiere_utilities_obj.get_classe_locate_abitanti(abitante.get_id_quartiere_posizione_abitanti).get_next(abitante.get_id_abitante_posizione_abitanti);
      Put_Line(Positive'Image(get_quartiere_utilities_obj.get_classe_locate_abitanti(abitante.get_id_quartiere_posizione_abitanti).get_number_steps_to_finish_route(abitante.get_id_abitante_posizione_abitanti)));
      if get_quartiere_utilities_obj.get_classe_locate_abitanti(abitante.get_id_quartiere_posizione_abitanti).get_number_steps_to_finish_route(abitante.get_id_abitante_posizione_abitanti)<1 then
         Put_Line("numero step rimasti per abitante " & Positive'Image(abitante.get_id_abitante_posizione_abitanti) & " è 0");
         raise other_error;
      end if;
      if get_quartiere_utilities_obj.get_classe_locate_abitanti(abitante.get_id_quartiere_posizione_abitanti).get_number_steps_to_finish_route(abitante.get_id_abitante_posizione_abitanti)=1 then
         -- la macchina deve percorrere l'ultimo pezzo di strada
         if get_ref_quartiere(next_nodo.get_id_quartiere_tratto).get_polo_ingresso(next_nodo.get_id_tratto)/=polo then
            case mezzo is
               when car =>
                  return create_trajectory_to_follow(num_corsia,2,next_nodo.get_id_tratto,0,empty);
               when others =>
                  return create_trajectory_to_follow(num_corsia,0,next_nodo.get_id_tratto,0,empty);
            end case;
         else
            case mezzo is
               when car =>
                  return create_trajectory_to_follow(num_corsia,1,next_nodo.get_id_tratto,0,empty);
               when others =>
                  return create_trajectory_to_follow(num_corsia,0,next_nodo.get_id_tratto,0,empty);
            end case;
         end if;
      else
         -- la macchina deve percorrere tutta la strada
         -- deve percorre ancora almeno 3 entità
         next_incrocio:= get_quartiere_utilities_obj.get_classe_locate_abitanti(abitante.get_id_quartiere_posizione_abitanti).get_next_incrocio(abitante.get_id_abitante_posizione_abitanti);
         next_road:= get_quartiere_utilities_obj.get_classe_locate_abitanti(abitante.get_id_quartiere_posizione_abitanti).get_next_road(abitante.get_id_abitante_posizione_abitanti,False);
         -- ATTENZIONE next_road può essere un ingresso
         id_road:= get_ref_quartiere(next_road.get_id_quartiere_tratto).get_id_main_road_from_id_ingresso(next_road.get_id_tratto);
         if id_road/=0 then
            next_road:= create_tratto(next_road.get_id_quartiere_tratto,id_road);
         end if;
         -- eseguito update di next_road se necessario
         get_ref_quartiere(next_incrocio.get_id_quartiere_tratto).get_cfg_incrocio(next_incrocio.get_id_tratto,create_tratto(next_nodo.get_id_quartiere_tratto,next_nodo.get_id_tratto),create_tratto(next_road.get_id_quartiere_tratto,next_road.get_id_tratto),index_road_from,index_road_to,id_road_mancante);
         if id_road_mancante=0 and (index_road_from=0 or index_road_to=0) then
            return create_trajectory_to_follow(0,0,0,0,empty);  --errore
         else
            if abs(index_road_from-index_road_to)=2 then
               if num_corsia=1 then
                  case mezzo is
                  when car =>
                     return create_trajectory_to_follow(num_corsia,1,0,0,dritto_1);
                  when bike =>
                     return create_trajectory_to_follow(num_corsia,0,0,0,dritto_bici);
                  when walking =>
                     return create_trajectory_to_follow(num_corsia,0,0,0,dritto_pedoni);
                  end case;
               else
                  case mezzo is
                  when car =>
                     return create_trajectory_to_follow(num_corsia,2,0,0,dritto_2);
                  when bike =>
                     return create_trajectory_to_follow(num_corsia,0,0,0,dritto_bici);
                  when walking =>
                     return create_trajectory_to_follow(num_corsia,0,0,0,dritto_pedoni);
                  end case;
               end if;
            else
               if (index_road_from=1 and index_road_to=4) or else (index_road_from=2 and index_road_to=1) or else
                 (index_road_from=3 and index_road_to=2) or else (index_road_from=4 and index_road_to=3) then
                  case mezzo is
                  when car =>
                     return create_trajectory_to_follow(num_corsia,2,0,0,destra);
                  when bike =>
                     return create_trajectory_to_follow(num_corsia,0,0,0,destra_bici);
                  when walking =>
                     return create_trajectory_to_follow(num_corsia,0,0,0,destra_pedoni);
                  end case;
               else
                  case mezzo is
                  when car =>
                     return create_trajectory_to_follow(num_corsia,1,0,0,sinistra);
                  when bike =>
                     return create_trajectory_to_follow(num_corsia,0,0,0,sinistra_bici);
                  when walking =>
                     return create_trajectory_to_follow(num_corsia,0,0,0,sinistra_pedoni);
                  end case;
               end if;
            end if;
         end if;
      end if;
   end calculate_trajectory_to_follow_from_incrocio;

   function calculate_traiettoria_to_follow_from_ingresso(mezzo: means_of_carrying; id_quartiere_abitante: Positive; id_abitante: Positive; id_ingresso: Positive; ingressi: indici_ingressi) return traiettoria_ingressi_type is
      nodo: tratto;
      estremi_urbana: estremi_strada_urbana;
      ingresso: strada_ingresso_features:= get_ingresso_from_id(id_ingresso);
      found: Boolean:= False;
      which_found: Boolean:= False; -- False => esiste un ingresso più vicino rispetto a id_ingresso
      i: Positive:= 1;
      estremo: estremo_urbana;
   begin
      nodo:= get_quartiere_utilities_obj.get_classe_locate_abitanti(id_quartiere_abitante).get_next(id_abitante);
      if nodo.get_id_quartiere_tratto=get_id_quartiere and then (nodo.get_id_tratto>=get_from_ingressi and nodo.get_id_tratto<=get_to_ingressi) then
         if get_ingresso_from_id(id_ingresso).get_polo_ingresso=False then
            if get_ingresso_from_id(nodo.get_id_tratto).get_distance_from_road_head_ingresso<get_ingresso_from_id(id_ingresso).get_distance_from_road_head_ingresso then
               case mezzo is
                  when car =>
                     return uscita_ritorno;
                  when walking =>
                     return uscita_dritto_pedoni;
                  when bike =>
                     return uscita_dritto_bici;
               end case;
            else
               case mezzo is
               when car =>
                  return uscita_andata;
               when walking =>
                  return uscita_destra_pedoni;
               when bike =>
                  return uscita_destra_bici;
               end case;
            end if;
         else
            if get_ingresso_from_id(nodo.get_id_tratto).get_distance_from_road_head_ingresso<get_ingresso_from_id(id_ingresso).get_distance_from_road_head_ingresso then
               case mezzo is
               when car =>
                  return uscita_andata;
               when walking =>
                  return uscita_destra_pedoni;
               when bike =>
                  return uscita_destra_bici;
               end case;
            else
               case mezzo is
               when car =>
                  return uscita_ritorno;
               when walking =>
                  return uscita_dritto_pedoni;
               when bike =>
                  return uscita_dritto_bici;
               end case;
            end if;
         end if;
      else
         estremi_urbana:= get_estremi_urbana(ingresso.get_id_main_strada_ingresso);
         if (nodo.get_id_tratto=estremi_urbana(1).get_id_incrocio_estremo_urbana and nodo.get_id_quartiere_tratto=estremi_urbana(1).get_id_quartiere_estremo_urbana) or
           (nodo.get_id_tratto=estremi_urbana(2).get_id_incrocio_estremo_urbana and nodo.get_id_quartiere_tratto=estremi_urbana(2).get_id_quartiere_estremo_urbana) then
            if nodo.get_id_tratto=estremi_urbana(1).get_id_incrocio_estremo_urbana and nodo.get_id_quartiere_tratto=estremi_urbana(1).get_id_quartiere_estremo_urbana then
               estremo:= estremi_urbana(1);
            else
               estremo:= estremi_urbana(2);
            end if;
            if estremo.get_polo_estremo_urbana then
               if ingresso.get_polo_ingresso then
                  case mezzo is
                  when car =>
                     return uscita_andata;
                  when walking =>
                     return uscita_destra_pedoni;
                  when bike =>
                     return uscita_destra_bici;
                  end case;
               else
                  case mezzo is
                  when car =>
                     return uscita_ritorno;
                  when walking =>
                     return uscita_dritto_pedoni;
                  when bike =>
                     return uscita_dritto_bici;
                  end case;
               end if;
            else
               if ingresso.get_polo_ingresso then
                  case mezzo is
                  when car =>
                     return uscita_ritorno;
                  when walking =>
                     return uscita_dritto_pedoni;
                  when bike =>
                     return uscita_dritto_bici;
                  end case;
               else
                  case mezzo is
                  when car =>
                     return uscita_andata;
                  when walking =>
                     return uscita_destra_pedoni;
                  when bike =>
                     return uscita_destra_bici;
                  end case;
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
               case mezzo is
               when car =>
                  return uscita_andata;
               when walking =>
                  return uscita_destra_pedoni;
               when bike =>
                  return uscita_destra_bici;
               end case;
            else -- l'ingresso arrivo precede l'ingresso destinazione
               case mezzo is
               when car =>
                  return uscita_ritorno;
               when walking =>
                  return uscita_dritto_pedoni;
               when bike =>
                  return uscita_dritto_bici;
               end case;
            end if;
         end if;
      end if;
   end calculate_traiettoria_to_follow_from_ingresso;

   -- ritorna una macchina della corsia opposta se ve ne sono in sorpasso prima della macchina successiva alla stessa corsia

   procedure calculate_distance_to_next_car_on_road(car_in_corsia: ptr_list_posizione_abitanti_on_road; next_car: ptr_list_posizione_abitanti_on_road; next_car_in_near_corsia: ptr_list_posizione_abitanti_on_road; from_corsia: id_corsie; next_car_on_road: out ptr_list_posizione_abitanti_on_road; next_car_on_road_distance: out new_float) is
      switch: Boolean:= False;
      current_car_in_corsia: ptr_list_posizione_abitanti_on_road:= car_in_corsia;
      next_car_in_opposite_corsia: ptr_list_posizione_abitanti_on_road:= next_car_in_near_corsia;
      next_car_in_corsia: ptr_list_posizione_abitanti_on_road:= next_car;
      entity_length: new_float;
      corsia_to_go: id_corsie:= car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory;
   begin
      next_car_on_road_distance:= -1.0;
      next_car_on_road:= null;

      if car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken then
         -- la macchina è in sorpasso
         while next_car_in_corsia/=null and then (next_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
           get_quartiere_utilities_obj.get_auto_quartiere(next_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                          next_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva
           <car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria) loop
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
            next_car_on_road_distance:= next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
            -- COMMENTATO LA SEGUENTE OTTIMIZZAZIONE
            --if next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_departure_corsia=from_corsia then
               -- la macchina è in sorpasso verso la corsia opposta ma non ha ancora attraversato
            --   if next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory-
            --     get_quartiere_utilities_obj.get_auto_quartiere(next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<get_traiettoria_cambio_corsia.get_distanza_intersezione_linea_di_mezzo then
            --      next_car_on_road_distance:= next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
            --   end if;
            --else  -- si ha una macchina che dalla corsia opposta vuole entrare nella corsia first_corsia
            --   next_car_on_road_distance:= next_car_in_opposite_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
            --end if;
         end if;
         next_car_in_opposite_corsia:= next_car_in_opposite_corsia.get_next_from_list_posizione_abitanti;
      end loop;
      if next_car_on_road_distance=-1.0 and next_car_in_corsia/=null then  -- limite superiore dato dalla macchina nella stessa corsia se /= null
         entity_length:= 0.0;
         if next_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken and then next_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_departure_corsia=from_corsia then
            if next_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory-get_quartiere_utilities_obj.get_auto_quartiere(next_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<0.0 then
               entity_length:= get_quartiere_utilities_obj.get_auto_quartiere(next_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva-next_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory;
            end if;
         end if;
         next_car_on_road_distance:= next_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length;
         next_car_on_road:= next_car_in_corsia;
         Put_Line("next car in corsia of " & Positive'Image(car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is " & Positive'Image(next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
      end if;
   end calculate_distance_to_next_car_on_road;

   procedure calculate_parameters_car_in_uscita(list_abitanti: ptr_list_posizione_abitanti_on_road; traiettoria_rimasta_da_percorrere: new_float; next_abitante: ptr_list_posizione_abitanti_on_road; distance_to_stop_line: new_float; traiettoria_to_go: traiettoria_ingressi_type; distance_ingresso: new_float; next_pos_abitante: in out new_float; acceleration: out new_float; new_step: out new_float; new_speed: out new_float) is
      corsia_to_go: Natural:= 0;
      next_abitante_car_length: new_float;
      costante_additiva: new_float;
      speed_abitante: new_float;
   begin
      speed_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
      if traiettoria_to_go=uscita_andata then
         corsia_to_go:= 2;
      elsif traiettoria_to_go=uscita_ritorno then
         corsia_to_go:= 1;
      end if;
      if corsia_to_go/=0 then
         --if next_abitante/=null and then (next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken and next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory=corsia_to_go) then
         --   costante_additiva:= get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria/2.0;
         --else
         --   costante_additiva:= 0.0;
         --end if;

         costante_additiva:= 0.0;

         -- next_pos_abitante è un abitante in traiettoria ingresso
         if next_abitante/=null and then (next_pos_abitante=0.0 or else next_pos_abitante>=next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) then -- +costante_additiva) then
            next_abitante_car_length:= get_quartiere_utilities_obj.get_auto_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
            if next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken and then next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory=corsia_to_go then
               -- l'abitante sta entrando nella corsia corsia_to_go; quindi
               -- dato che partiva dalla corsia opposta non viene sottratta
               -- la lunghezza della macchina
               next_pos_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;-- +costante_additiva-max_larghezza_veicolo;
            else
               if next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken=True then
                  -- l'abitante è in sorpasso verso la corsia che non riguarda la macchina corrente
                  -- sostituito il blocco if sotto in commento con la seguente riga di codice
                  next_pos_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-next_abitante_car_length;
                  --if next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory>next_abitante_car_length then
                  --   next_pos_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;  -- impone come distanza quella di inizio traiettoria di sorpasso
                  --else
                  --   next_pos_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-(next_abitante_car_length-next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory);
                  --end if;
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
            if next_pos_abitante/=0.0 then
               next_pos_abitante:= traiettoria_rimasta_da_percorrere+next_pos_abitante-distance_ingresso-get_larghezza_marciapiede-get_larghezza_corsia;
            else
               raise other_error;
            end if;
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

   procedure calculate_parameters_car_in_entrata(id_ingresso: Positive; list_abitanti: ptr_list_posizione_abitanti_on_road; traiettoria_rimasta_da_percorrere: new_float; next_abitante: ptr_list_posizione_abitanti_on_road; distance_to_stop_line: new_float; traiettoria_to_go: traiettoria_ingressi_type; next_pos_abitante: in out new_float; acceleration: out new_float; new_step: out new_float; new_speed: out new_float) is
      next_abitante_car_length: new_float;
      speed_abitante: new_float;
      abitante: posizione_abitanti_on_road;
   begin
      speed_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
      abitante:= get_ingressi_segmento_resources(id_ingresso).get_temp_car_in_entrata;
      if abitante.get_id_quartiere_posizione_abitanti/=0 then
         next_abitante_car_length:= get_quartiere_utilities_obj.get_auto_quartiere(abitante.get_id_quartiere_posizione_abitanti,abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
         --next_pos_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
         next_pos_abitante:= abitante.get_where_now_posizione_abitanti-next_abitante_car_length+traiettoria_rimasta_da_percorrere;
         acceleration:= calculate_acceleration(mezzo => car,
                                               id_abitante => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                               id_quartiere_abitante => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                               next_entity_distance => next_pos_abitante,
                                               distance_to_stop_line => distance_to_stop_line+add_factor,
                                               next_id_quartiere_abitante => abitante.get_id_quartiere_posizione_abitanti,
                                               next_id_abitante => abitante.get_id_abitante_posizione_abitanti,
                                               abitante_velocity => speed_abitante,
                                               next_abitante_velocity => abitante.get_current_speed_abitante);
      elsif next_abitante/=null then
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

   procedure fix_advance_parameters(mezzo: means_of_carrying; acceleration: in out new_float; new_speed: in out new_float; new_step: in out new_float; speed_abitante: new_float; distance_to_next: new_float; distanza_stop_line: new_float) is
      min_distance: new_float;
   begin
      -- distance_to_next se =0.0 => non c'è un abitante successivo
      case mezzo is
         when car =>
            min_distance:= min_veicolo_distance;
         when bike =>
            min_distance:= min_bici_distance;
         when walking =>
            min_distance:= min_pedone_distance;
      end case;
      if distance_to_next>0.0 then
         if distance_to_next<=min_distance then
            acceleration:= 0.0;
            new_step:= 0.0;
            new_speed:= speed_abitante/2.0;
         else
            if new_step>distance_to_next-min_distance then
               new_step:= distance_to_next-min_distance;
               new_speed:= speed_abitante/2.0;
            end if;
         end if;
      elsif acceleration<0.0 then
            new_speed:= speed_abitante;
            if distance_to_next>0.0 then
               new_step:= 0.0;
            end if;
      end if;
   end fix_advance_parameters;

   function can_abitante_on_uscita_ritorno_overtake_bipedi(mailbox: ptr_resource_segmento_urbana; index_ingresso: Positive) return Boolean is
      list_abitanti_on_traiettoria_ingresso: ptr_list_posizione_abitanti_on_road;
      --entity_length: new_float;
   begin
      for h in 1..2 loop
         if h=1 then
            list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(index_ingresso,entrata_ritorno_bici);
         else
            list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(index_ingresso,entrata_ritorno_pedoni);
         end if;
         while list_abitanti_on_traiettoria_ingresso/=null loop
            if list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 or else
              list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia then
               return False;
            end if;
            list_abitanti_on_traiettoria_ingresso:= list_abitanti_on_traiettoria_ingresso.get_next_from_list_posizione_abitanti;
         end loop;
      end loop;

      for h in 1..2 loop
         if h=1 then
            list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(index_ingresso,entrata_dritto_bici);
         else
            list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(index_ingresso,entrata_dritto_pedoni);
         end if;
         while list_abitanti_on_traiettoria_ingresso/=null loop
            if list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 and then
              list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_larghezza_corsia*2.0 then
               return False;
            end if;
            list_abitanti_on_traiettoria_ingresso:= list_abitanti_on_traiettoria_ingresso.get_next_from_list_posizione_abitanti;
         end loop;
      end loop;
      return True;
   end can_abitante_on_uscita_ritorno_overtake_bipedi;

   procedure set_condizioni_per_abilitare_spostamento_bipedi(mailbox: ptr_resource_segmento_urbana; distance_last_ingresso: in out Boolean; index_ingresso_same_direction: in out Natural; index_ingresso_opposite_direction: in out Natural; current_polo_to_consider: Boolean; current_car_in_corsia: ptr_list_posizione_abitanti_on_road; distance_ingresso_same_direction: in out new_float; distance_ingresso_opposite_direction: in out new_float; corsia: id_corsie) is
      list_abitanti_on_traiettoria_ingresso: ptr_list_posizione_abitanti_on_road;
      --list_abitanti_on_car: ptr_list_posizione_abitanti_on_road;
      z: Positive;
      index_ingresso: Positive;
      segnale: Boolean;
      segnale_1: Boolean;
      segnale_2: Boolean;
      switch: Boolean;
      entity_length: new_float;
      not_consider: Boolean:= False;
   begin
      -- nel primo blocco if viene controllato se:
      -- per distance_last_ingresso=True => se abilitare o meno l'uscita dei bipedi dall'ingresso
      -- per distance_last_ingresso=False => se abilitare o meno l'entrata_ritorno dei bipedi ingresso

      if distance_last_ingresso then
         if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_same_direction+get_larghezza_corsia+get_larghezza_marciapiede then
            if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<distance_ingresso_same_direction+get_larghezza_corsia+get_larghezza_marciapiede then
               mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,current_polo_to_consider,index_ingresso_same_direction,True);
               mailbox.disabilita_att_bipedi_per_intersezione_cars(current_polo_to_consider,current_polo_to_consider,index_ingresso_same_direction,True);
            end if;
            return;
         end if;
      else
         if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_opposite_direction+get_larghezza_corsia+get_larghezza_marciapiede then
            if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<distance_ingresso_opposite_direction+get_larghezza_corsia+get_larghezza_marciapiede then
               mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,not current_polo_to_consider,index_ingresso_opposite_direction,True);
               mailbox.disabilita_att_bipedi_per_intersezione_cars(current_polo_to_consider,not current_polo_to_consider,index_ingresso_opposite_direction,True);
            end if;
            return;
         end if;
      end if;

      switch:= False;
      segnale_1:= False;
      segnale_2:= False;
      while switch=False loop
         if distance_last_ingresso then
            if current_polo_to_consider then
               index_ingresso:= mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,ordered_polo_true);
            else
               index_ingresso:= mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,ordered_polo_false);
            end if;

            segnale:= False;
            z:= 1;
            --controllare se ci sono abitanti in entrata_dritto per l'ingresso index_ingresso_same_direction
            while not segnale and then z<=2 loop
               if z=1 then
                  list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(index_ingresso,entrata_dritto_bici);
               else
                  list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(index_ingresso,entrata_dritto_pedoni);
               end if;
               while list_abitanti_on_traiettoria_ingresso/=null loop
                  if (list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_larghezza_corsia and then (list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_larghezza_corsia*2.0 and then
                                                                                                                                                                                list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia)) then
                     segnale:= True;
                  end if;
                  if z=1 then
                     entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                  else
                     entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                  end if;
                  if (list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_larghezza_corsia*2.0 and list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length<get_larghezza_corsia*3.0) then
                     segnale:= True;
                  end if;

                  list_abitanti_on_traiettoria_ingresso:= list_abitanti_on_traiettoria_ingresso.get_next_from_list_posizione_abitanti;
               end loop;
               z:= z+1;
            end loop;

            -- begin set configurazione per uscite bipedi da ingresso
            if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia*4.0-get_larghezza_marciapiede then
               if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede then
                  if segnale then
                     null;
                  else               -- la disabilitazione avviene
                     mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,current_polo_to_consider,index_ingresso_same_direction,True);
                  end if;
               else
                  mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,current_polo_to_consider,index_ingresso_same_direction,True);
               end if;
            end if;


            if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia*4.0-get_larghezza_marciapiede then
               if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti<=distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede then
                  if segnale then
                     null;
                  else               -- la disabilitazione avviene
                     mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,current_polo_to_consider,index_ingresso_same_direction,True);
                  end if;
               else
                  mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,current_polo_to_consider,index_ingresso_same_direction,True);
               end if;
            end if;

            -- guardare there_are_cars_moving_across_next_ingressi per capire come bipedi
            -- in uscita_dritto non si intersecano con le macchine in sorpasso
            if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken then
               if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory>distance_ingresso_same_direction-get_larghezza_corsia*4.0-get_larghezza_marciapiede then
                  if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory<=distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede then
                     if segnale then
                        null;
                     else
                        mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,current_polo_to_consider,index_ingresso_same_direction,True);
                     end if;
                  end if;
               else
                  mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,current_polo_to_consider,index_ingresso_same_direction,True);
               end if;
            end if;
            if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken then
               if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria>distance_ingresso_same_direction-get_larghezza_corsia*4.0-get_larghezza_marciapiede then
                  if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria<=distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede then
                     if segnale then
                        null;
                     else
                        mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,current_polo_to_consider,index_ingresso_same_direction,True);
                     end if;
                  end if;
               else
                  mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,current_polo_to_consider,index_ingresso_same_direction,True);
               end if;
            end if;

            -- end

            -- begin set configurazione per entrata bipedi in ingresso da get_larghezza_corsia*2.0
            if (current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede and then
                current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva>=distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede) then
               null;
            else
               if (current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia*5.0-get_larghezza_marciapiede or else
                  current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia*5.0-get_larghezza_marciapiede) then
                  -- la disabilitazione avviene
                  mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,current_polo_to_consider,index_ingresso_same_direction,False);
               end if;
            end if;

            if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken and then current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede then
               if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory>distance_ingresso_same_direction-get_larghezza_corsia*5.0-get_larghezza_marciapiede then
                  mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,current_polo_to_consider,index_ingresso_same_direction,False);
               end if;
            end if;
            -- end

            if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede then
               index_ingresso_same_direction:= index_ingresso_same_direction-1;
            else
               -- l'abitante si trova in posizione maggiore_uguale di distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede
               segnale_1:= True;
            end if;
         else
            -- controllare se entrata_dritto per quest ingresso ha superato la mezzaria
            if current_polo_to_consider then
               index_ingresso:= mailbox.get_index_ingresso_from_key(index_ingresso_opposite_direction,ordered_polo_false);
            else
               index_ingresso:= mailbox.get_index_ingresso_from_key(index_ingresso_opposite_direction,ordered_polo_true);
            end if;

            --for h in 1..2 loop
            --   if h=1 then
            --      list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(index_ingresso,entrata_dritto_bici);
            --   else
            --      list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(index_ingresso,entrata_dritto_pedoni);
            --   end if;
            --   while list_abitanti_on_traiettoria_ingresso/=null loop
            --      if list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 and then (list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_larghezza_corsia or else
            --        (list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
            --                                                                                                                                                                                   list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<get_larghezza_corsia)) then
            --         segnale:= True;
            --      end if;
            --      list_abitanti_on_traiettoria_ingresso:= list_abitanti_on_traiettoria_ingresso.get_next_from_list_posizione_abitanti;
            --   end loop;
            --end loop;

            -----------------if segnale=False then
            z:= 1;
            segnale:= False;
            while not segnale and then z<=2 loop
               if z=1 then
                  list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(index_ingresso,uscita_dritto_bici);
               else
                  list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(index_ingresso,uscita_dritto_pedoni);
               end if;
               while list_abitanti_on_traiettoria_ingresso/=null loop
                  if (list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_larghezza_corsia+get_larghezza_marciapiede and then (list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_larghezza_corsia*2.0+get_larghezza_marciapiede and then
                                                                                                                                                                                list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia)) then
                     segnale:= True;
                  end if;
                  if z=1 then
                     entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                  else
                     entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                  end if;
                  if (list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_larghezza_corsia*2.0+get_larghezza_marciapiede and list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length<get_larghezza_corsia*3.0+get_larghezza_marciapiede) then
                     segnale:= True;
                  end if;

                  list_abitanti_on_traiettoria_ingresso:= list_abitanti_on_traiettoria_ingresso.get_next_from_list_posizione_abitanti;
               end loop;
               z:= z+1;
            end loop;

            if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_opposite_direction-get_larghezza_corsia*4.0-get_larghezza_marciapiede then
               if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=distance_ingresso_opposite_direction-get_larghezza_corsia-get_larghezza_marciapiede then
                  if segnale then
                     null;
                  else
                     mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,not current_polo_to_consider,index_ingresso_opposite_direction,True);
                  end if;
               else
                  mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,not current_polo_to_consider,index_ingresso_opposite_direction,True);
               end if;
            end if;

            if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>distance_ingresso_opposite_direction-get_larghezza_corsia*4.0-get_larghezza_marciapiede then
               if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti<=distance_ingresso_opposite_direction-get_larghezza_corsia-get_larghezza_marciapiede then
                  if segnale then
                     null;
                  else
                     mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,not current_polo_to_consider,index_ingresso_opposite_direction,True);
                  end if;
               else
                  mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,not current_polo_to_consider,index_ingresso_opposite_direction,True);
               end if;
            end if;

            if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken then
               if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria>distance_ingresso_opposite_direction-get_larghezza_corsia*4.0-get_larghezza_marciapiede then
                  if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria<=distance_ingresso_opposite_direction-get_larghezza_corsia-get_larghezza_marciapiede then
                     if segnale then
                        null;
                     else
                        mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,not current_polo_to_consider,index_ingresso_opposite_direction,True);
                     end if;
                  else
                     mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,not current_polo_to_consider,index_ingresso_opposite_direction,True);
                  end if;
               end if;
            end if;
            if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken then
               if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory>distance_ingresso_opposite_direction-get_larghezza_corsia*4.0-get_larghezza_marciapiede then
                  if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory<=distance_ingresso_opposite_direction-get_larghezza_corsia-get_larghezza_marciapiede then
                     if segnale then
                        null;
                     else
                        mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,not current_polo_to_consider,index_ingresso_opposite_direction,True);
                     end if;
                  else
                     mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,not current_polo_to_consider,index_ingresso_opposite_direction,True);
                  end if;
               end if;
            end if;
            ------------------------------end if;

            if (current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_opposite_direction-get_larghezza_corsia-get_larghezza_marciapiede and then
                current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva>=distance_ingresso_opposite_direction-get_larghezza_corsia-get_larghezza_marciapiede) then
               null;
            else
               if (current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_opposite_direction-get_larghezza_corsia*5.0-get_larghezza_marciapiede or else
                  current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>distance_ingresso_opposite_direction-get_larghezza_corsia*5.0-get_larghezza_marciapiede) then
                  -- la disabilitazione avviene
                  mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,not current_polo_to_consider,index_ingresso_opposite_direction,False);
               end if;
            end if;

            if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken and then current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=distance_ingresso_opposite_direction-get_larghezza_corsia-get_larghezza_marciapiede then
               if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria>distance_ingresso_opposite_direction-get_larghezza_corsia*5.0-get_larghezza_marciapiede then
                  mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,not current_polo_to_consider,index_ingresso_opposite_direction,False);
               end if;
            end if;

            if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<distance_ingresso_opposite_direction-get_larghezza_corsia-get_larghezza_marciapiede then
               index_ingresso_opposite_direction:= index_ingresso_opposite_direction+1;
            else
               segnale_2:= True;
            end if;

         end if;

         if distance_last_ingresso then
            if index_ingresso_same_direction>0 then
               if current_polo_to_consider then
                  distance_ingresso_same_direction:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,ordered_polo_true)),current_polo_to_consider);
               else
                  distance_ingresso_same_direction:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,ordered_polo_false)),current_polo_to_consider);
               end if;
            end if;
         else
            if index_ingresso_opposite_direction<=mailbox.get_num_ingressi_polo(not current_polo_to_consider) then
               if current_polo_to_consider then
                  distance_ingresso_opposite_direction:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(index_ingresso_opposite_direction,ordered_polo_false)),current_polo_to_consider);
               else
                  distance_ingresso_opposite_direction:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(index_ingresso_opposite_direction,ordered_polo_true)),current_polo_to_consider);
               end if;
            end if;
         end if;

         if segnale_1 or else segnale_2 then
            switch:= True;
         end if;

         if index_ingresso_same_direction=0 and then index_ingresso_opposite_direction>mailbox.get_num_ingressi_polo(not current_polo_to_consider) then
            switch:= True;
         elsif index_ingresso_same_direction>0 and then (index_ingresso_opposite_direction>0 and then index_ingresso_opposite_direction<=mailbox.get_num_ingressi_polo(not current_polo_to_consider)) then
            if distance_ingresso_same_direction>distance_ingresso_opposite_direction then
               distance_last_ingresso:= True;
               if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_same_direction+get_larghezza_corsia+get_larghezza_marciapiede then
                  switch:= True;
               end if;
            else
               if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_opposite_direction+get_larghezza_corsia+get_larghezza_marciapiede then
                  switch:= True;
               end if;
               distance_last_ingresso:= False;
            end if;
         elsif index_ingresso_same_direction>0 then
            distance_last_ingresso:= True;
            if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_same_direction+get_larghezza_corsia+get_larghezza_marciapiede then
               switch:= True;
            end if;
         elsif (index_ingresso_opposite_direction>0 and then index_ingresso_opposite_direction<=mailbox.get_num_ingressi_polo(not current_polo_to_consider)) then
            -- index_ingresso_opposite_direction<=mailbox.get_num_ingressi_polo(not current_polo_to_consider)
            distance_last_ingresso:= False;
            if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_opposite_direction+get_larghezza_corsia+get_larghezza_marciapiede then
               switch:= True;
            end if;
         else
            switch:= True;
            not_consider:= True;
         end if;

      end loop;

      if not_consider=False then
         if distance_last_ingresso then
            if index_ingresso_same_direction>0 then
               if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<distance_ingresso_same_direction-get_larghezza_corsia then
                  mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,current_polo_to_consider,index_ingresso_same_direction,False);
                  mailbox.disabilita_att_bipedi_per_intersezione_cars(current_polo_to_consider,current_polo_to_consider,index_ingresso_same_direction,False);
               end if;
               if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<distance_ingresso_same_direction+get_larghezza_corsia+get_larghezza_marciapiede then
                  mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,current_polo_to_consider,index_ingresso_same_direction,True);
                  mailbox.disabilita_att_bipedi_per_intersezione_cars(current_polo_to_consider,current_polo_to_consider,index_ingresso_same_direction,True);
               end if;
            end if;
         else
            if index_ingresso_opposite_direction>0 and then index_ingresso_opposite_direction<=mailbox.get_num_ingressi_polo(not current_polo_to_consider) then
               if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<distance_ingresso_opposite_direction-get_larghezza_corsia then
                  mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,not current_polo_to_consider,index_ingresso_opposite_direction,False);
                  mailbox.disabilita_att_bipedi_per_intersezione_cars(current_polo_to_consider,not current_polo_to_consider,index_ingresso_opposite_direction,False);
               end if;
               if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<distance_ingresso_opposite_direction+get_larghezza_corsia+get_larghezza_marciapiede then
                  mailbox.disabilita_attraversamento_bipedi_ingresso(current_polo_to_consider,not current_polo_to_consider,index_ingresso_opposite_direction,True);
                  mailbox.disabilita_att_bipedi_per_intersezione_cars(current_polo_to_consider,not current_polo_to_consider,index_ingresso_opposite_direction,True);
               end if;
            end if;
         end if;
      end if;

   end set_condizioni_per_abilitare_spostamento_bipedi;

   function calculate_next_entity_distance(current_car: ptr_list_posizione_abitanti_on_road; next_car_in_ingresso_distance: new_float; next_car_on_road: ptr_list_posizione_abitanti_on_road; next_car_on_road_distance: new_float; id_road: Positive; next_entity_is_ingresso: out Boolean; tmp_next_car_distance: in out new_float) return new_float is
      next_entity_distance: new_float:= next_car_in_ingresso_distance;
      next_car_distance: new_float:= -1.0;
      quantità_avanzata_next_incrocio: new_float:= 0.0;
      incrocio: tratto;
      estremi: estremi_strada_urbana;
      costante: new_float:= current_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
   begin
      -- next_car_on_road vale null se davanti non si hanno macchine o davanti ho una macchina in sorpasso dalla corsia opposta
      if next_car_on_road=null then
         next_car_distance:= next_car_on_road_distance;
      else
         if next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken then -- se in sorpasso
            next_car_distance:= next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
         else
            if next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_urbana_from_id(id_road).get_lunghezza_road then
               -- se il calcolo di incrocio da problemi ricavatelo dagli estremi
               incrocio:= get_quartiere_utilities_obj.get_classe_locate_abitanti(next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_next(next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
               if get_ref_quartiere(incrocio.get_id_quartiere_tratto).is_incrocio(incrocio.get_id_tratto)=False then
                  incrocio:= get_quartiere_utilities_obj.get_classe_locate_abitanti(next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_current_tratto(next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
               end if;
               estremi:= get_estremi_urbana(id_road);
               Put_Line("quartiere:" & Positive'Image(incrocio.get_id_quartiere_tratto) & " tratto " & Positive'Image(incrocio.get_id_tratto) & " quartiere ab " & Positive'Image(current_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " id ab " & Positive'Image(current_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " altro ab: quartiere" & Positive'Image(next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " id abitante " & Positive'Image(next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
               quantità_avanzata_next_incrocio:= ptr_rt_incrocio(get_id_incrocio_quartiere(incrocio.get_id_quartiere_tratto,incrocio.get_id_tratto)).get_posix_first_entity(get_id_quartiere,id_road,next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
               if quantità_avanzata_next_incrocio=-1.0 then -- l'abitante ha attraversato completamente l'incrocio
                  next_car_distance:= -1.0;
               else
                  next_car_distance:= quantità_avanzata_next_incrocio+get_urbana_from_id(id_road).get_lunghezza_road;
               end if;
            else
               next_car_distance:= next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
            end if;
            if next_car_distance/=-1.0 then
               next_car_distance:= next_car_distance-get_quartiere_utilities_obj.get_auto_quartiere(next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                                                    next_car_on_road.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
            end if;
         end if;
         -- spostato if seguente fuori dal precedente end if;

      end if;

      tmp_next_car_distance:= next_car_distance;

      --if next_car_distance/=-1.0 then
      --   next_car_distance:= next_car_distance-costante;
      --end if;

      if next_car_in_ingresso_distance=-1.0 and next_car_distance=-1.0 then
         next_entity_distance:= 0.0;
         next_entity_is_ingresso:= False;
      elsif next_car_distance/=-1.0 and next_car_in_ingresso_distance/=-1.0 then
         if next_car_distance<next_car_in_ingresso_distance then
            next_entity_distance:= next_car_distance-costante;
            next_entity_is_ingresso:= False;
         else
            next_entity_distance:= next_car_in_ingresso_distance-costante;
            next_entity_is_ingresso:= True;
         end if;
      elsif next_car_in_ingresso_distance=-1.0 then
         next_entity_distance:= next_car_distance-costante;
         next_entity_is_ingresso:= False;
      else
         next_entity_distance:= next_car_in_ingresso_distance-costante;
         next_entity_is_ingresso:= True;
      end if;

      --if next_entity_distance<0.0 then
      --   raise other_error;
      --end if;

      return next_entity_distance;
   end calculate_next_entity_distance;

   function there_are_conditions_to_overtake(next_abitante: ptr_list_posizione_abitanti_on_road; next_abitante_other_corsia: ptr_list_posizione_abitanti_on_road; position_abitante: new_float; has_to_come_back: Boolean) return Boolean is
      can_overtake: Boolean:= True;
      --temp_list: ptr_list_posizione_abitanti_on_road;
      --num_next_cars: Natural;
      --num_other_cars: Natural;
      next_abitante_current_speed: new_float;
      next_other_abitante_current_speed: new_float;
      --next_abitante_desidered_speed: Float;
      --next_other_abitante_desidered_speed: Float;
      --percentage_avanzamento_next_abitante: Float;
      --percentage_avanzamento_next_other_abitante: Float;
   begin
      if next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<next_abitante_other_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti then
         -- si contano le macchine che si hanno davanti sia nella stessa corsia
         -- sia nella corsia opposta
         --next_abitante_desidered_speed:= get_quartiere_utilities_obj.get_auto_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_desired_velocity;
         --next_other_abitante_desidered_speed:= get_quartiere_utilities_obj.get_auto_quartiere(next_abitante_other_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante_other_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_desired_velocity;
         next_abitante_current_speed:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
         next_other_abitante_current_speed:= next_abitante_other_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
         if next_abitante_current_speed>next_other_abitante_current_speed then
            can_overtake:= False;
         end if;
         if can_overtake=False then
            if next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-position_abitante>=bound_to_change_corsia*3.0 then
               can_overtake:= True;
            end if;
         end if;
      end if;

         --temp_list:= next_abitante;
         --num_next_cars:= 0;
         --while temp_list/=null loop
            --num_next_cars:= num_next_cars+1;
            --temp_list:= temp_list.get_next_from_list_posizione_abitanti;
         --end loop;
         --temp_list:= next_abitante_other_corsia;
         --num_other_cars:= 0;
         --while temp_list/=null loop
            --num_other_cars:= num_other_cars+1;
            --temp_list:= temp_list.get_next_from_list_posizione_abitanti;
         --end loop;
         --if num_other_cars<=num_next_cars then
            --next_abitante_current_speed:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
            --next_other_abitante_current_speed:= next_abitante_other_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
            --next_abitante_desidered_speed:= get_quartiere_utilities_obj.get_auto_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_desired_velocity;
            --next_other_abitante_desidered_speed:= get_quartiere_utilities_obj.get_auto_quartiere(next_abitante_other_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante_other_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_desired_velocity;
            --percentage_avanzamento_next_abitante:= next_abitante_current_speed/next_abitante_desidered_speed;
            --percentage_avanzamento_next_other_abitante:= next_other_abitante_current_speed/next_other_abitante_desidered_speed;
            -- se la percentuale di avanzamento dell' abitante nella corsia opposta è maggiore sorpassi altrimenti no
            --if percentage_avanzamento_next_other_abitante<percentage_avanzamento_next_abitante then
               --can_overtake:= False;
            --end if;
         --else
            --can_overtake:= False;
         --end if;
      return can_overtake;
   end there_are_conditions_to_overtake;

   procedure configure_tasks is
   begin
      for index_strada in get_from_urbane..get_to_urbane loop
         if log_system_error.is_in_error then
            task_urbane(index_strada).kill;
         else
            task_urbane(index_strada).configure(id => index_strada);
         end if;
      end loop;

      for index_strada in get_from_ingressi..get_to_ingressi loop
         if log_system_error.is_in_error then
            task_ingressi(index_strada).kill;
         else
            task_ingressi(index_strada).configure(id => index_strada);
         end if;
      end loop;

      for index_incrocio in get_from_incroci_a_4..get_to_incroci_a_4 loop
         if log_system_error.is_in_error then
            task_incroci(index_incrocio).kill;
         else
            task_incroci(index_incrocio).configure(id => index_incrocio);
         end if;
      end loop;

      for index_incrocio in get_from_incroci_a_3..get_to_incroci_a_3 loop
         if log_system_error.is_in_error then
            task_incroci(index_incrocio).kill;
         else
            task_incroci(index_incrocio).configure(id => index_incrocio);
         end if;
      end loop;

   end;

   function calculate_distance_to_stop_line_from_entity_on_road(abitante: ptr_list_posizione_abitanti_on_road; polo: Boolean; id_urbana: Positive) return new_float is
      traiettoria: trajectory_to_follow:= trajectory_to_follow(abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_destination);
   begin
      if traiettoria.get_traiettoria_incrocio_to_follow=empty then
         if polo then
            return get_urbana_from_id(id_urbana).get_lunghezza_road-get_ingresso_from_id(traiettoria.get_ingresso_to_go_trajectory).get_distance_from_road_head_ingresso-abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;---get_larghezza_corsia-get_larghezza_marciapiede;
         else
            return get_ingresso_from_id(traiettoria.get_ingresso_to_go_trajectory).get_distance_from_road_head_ingresso-abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;---get_larghezza_corsia-get_larghezza_marciapiede;
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

   procedure update_avanzamento_bipedi_in_uscita_ritorno(mailbox: ptr_resource_segmento_urbana; list_abitanti_sidewalk_pedoni: ptr_list_posizione_abitanti_on_road; list_abitanti_sidewalk_bici: ptr_list_posizione_abitanti_on_road; prec_list_abitanti_sidewalk_pedoni: ptr_list_posizione_abitanti_on_road; prec_list_abitanti_sidewalk_bici: ptr_list_posizione_abitanti_on_road; mezzo: means_of_carrying; index_ingresso_opposite_direction: Positive; current_ingressi_structure_type_to_not_consider: ingressi_type; polo: Boolean; id_road: Positive; init_list_abitanti_sidewalk_bici: ptr_list_posizione_abitanti_on_road; init_list_abitanti_sidewalk_pedoni: ptr_list_posizione_abitanti_on_road) is
      list_pedoni: ptr_list_posizione_abitanti_on_road;
      list_bici: ptr_list_posizione_abitanti_on_road;
      list_abitanti: ptr_list_posizione_abitanti_on_road;
      distance_ingresso: new_float;
      stop_entity: Boolean;
      next_abitante: ptr_list_posizione_abitanti_on_road;
      entity_distance: new_float;
      next_entity_distance: new_float;
      next_id_quartiere_abitante: Natural;
      next_id_abitante: Natural;
      next_abitante_velocity: new_float;
      traiettoria_da_percorrere: traiettoria_ingressi_type;
      distance_to_stop_line: new_float;
      speed_abitante: new_float;
      acceleration: new_float;
      new_speed: new_float;
      new_step: new_float;
      step_is_just_calculated: Boolean;
      means: means_of_carrying;
      entity_length: new_float;
   begin
      list_pedoni:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(index_ingresso_opposite_direction,current_ingressi_structure_type_to_not_consider),uscita_ritorno_pedoni);
      list_bici:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(index_ingresso_opposite_direction,current_ingressi_structure_type_to_not_consider),uscita_ritorno_bici);
      distance_ingresso:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(index_ingresso_opposite_direction,current_ingressi_structure_type_to_not_consider)),polo);
      stop_entity:= False;

      for h in 1..2 loop

         entity_distance:= 0.0;

         if h=1 then
            list_abitanti:= list_bici;
            entity_distance:= min_bici_distance;
            traiettoria_da_percorrere:= uscita_ritorno_bici;
            means:= bike;
         else
            list_abitanti:= list_pedoni;
            entity_distance:= min_pedone_distance;
            traiettoria_da_percorrere:= uscita_ritorno_pedoni;
            means:= walking;
         end if;

         next_entity_distance:= 0.0;
         next_id_quartiere_abitante:= 0;
         next_id_abitante:= 0;
         next_abitante_velocity:= 0.0;

         if list_abitanti/=null and then (list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0
                                          and list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia=False) then


            next_abitante:= list_abitanti.get_next_from_list_posizione_abitanti;

            mailbox.increase_num_stalli_for_bipede_in_ingresso(traiettoria_da_percorrere,mailbox.get_key_ingresso(mailbox.get_index_ingresso_from_key(index_ingresso_opposite_direction,current_ingressi_structure_type_to_not_consider),not_ordered),False,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);

            if h=1 and then next_abitante/=null then
               -- la bici viene fermata
               stop_entity:= True;
            end if;

            if h=2 and then next_abitante/=null then
               if next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_pedone_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva-min_pedone_distance<0.0 then
                  stop_entity:= True;
               end if;
            end if;

            if stop_entity=False then
               if h=1 then
                  if mezzo=walking then
                     if prec_list_abitanti_sidewalk_bici/=null and then prec_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>=distance_ingresso-get_larghezza_corsia*2.0-get_larghezza_marciapiede then
                        stop_entity:= True;
                     end if;
                     if list_abitanti_sidewalk_bici/=null then
                        if list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                          get_quartiere_utilities_obj.get_bici_quartiere(list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<distance_ingresso-get_larghezza_corsia then
                           stop_entity:= True;
                        end if;
                     else
                        if init_list_abitanti_sidewalk_bici/=null and then (list_abitanti_sidewalk_pedoni/=null and then init_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) then
                           if init_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                             get_quartiere_utilities_obj.get_bici_quartiere(init_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,init_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<distance_ingresso-get_larghezza_corsia then
                              stop_entity:= True;
                           end if;
                        end if;
                     end if;
                  else
                     if prec_list_abitanti_sidewalk_bici/=null and then prec_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>=distance_ingresso-get_larghezza_corsia*2.0-get_larghezza_marciapiede then
                        stop_entity:= True;
                     end if;
                     if list_abitanti_sidewalk_bici/=null and then list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                       get_quartiere_utilities_obj.get_bici_quartiere(list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<distance_ingresso-get_larghezza_corsia then
                        stop_entity:= True;
                     end if;
                  end if;
               else
                  if mezzo=walking then
                     if prec_list_abitanti_sidewalk_bici/=null and then prec_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>=distance_ingresso-get_larghezza_corsia*2.0-get_larghezza_marciapiede then
                        stop_entity:= True;
                     end if;
                     if prec_list_abitanti_sidewalk_pedoni/=null and then prec_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>=distance_ingresso-get_larghezza_corsia*2.0-get_larghezza_marciapiede then
                        stop_entity:= True;
                     end if;
                     if list_abitanti_sidewalk_bici/=null and then list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                       get_quartiere_utilities_obj.get_bici_quartiere(list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<distance_ingresso-get_larghezza_corsia then
                        stop_entity:= True;
                     end if;
                     if list_abitanti_sidewalk_pedoni/=null and then list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                       get_quartiere_utilities_obj.get_pedone_quartiere(list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<distance_ingresso-get_larghezza_corsia then
                        stop_entity:= True;
                     end if;
                  else
                     if prec_list_abitanti_sidewalk_bici/=null and then prec_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>=distance_ingresso-get_larghezza_corsia*2.0-get_larghezza_marciapiede then
                        stop_entity:= True;
                     end if;
                     if prec_list_abitanti_sidewalk_pedoni/=null and then prec_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>=distance_ingresso-get_larghezza_corsia*2.0-get_larghezza_marciapiede then
                        stop_entity:= True;
                     end if;
                     if list_abitanti_sidewalk_bici/=null and then list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                       get_quartiere_utilities_obj.get_bici_quartiere(list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<distance_ingresso-get_larghezza_corsia then
                        stop_entity:= True;
                     end if;
                     if list_abitanti_sidewalk_pedoni/=null and then list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                       get_quartiere_utilities_obj.get_pedone_quartiere(list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<distance_ingresso-get_larghezza_corsia then
                        stop_entity:= True;
                     else
                        if init_list_abitanti_sidewalk_pedoni/=null and then (list_abitanti_sidewalk_bici/=null and then init_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) then
                           if init_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                             get_quartiere_utilities_obj.get_pedone_quartiere(init_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,init_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<distance_ingresso-get_larghezza_corsia then
                              stop_entity:= True;
                           end if;
                        end if;
                     end if;
                  end if;
               end if;
            end if;

            if stop_entity=False then
               mailbox.set_flag_abitante_can_overtake_to_next_corsia(list_abitanti,True);
               -- calcola la posizione del prossimo abitante
               if next_abitante/=null then
                  -- list_abitanti si trova in posizione 0.0
                  if h=1 then
                     entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                  else
                     entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                  end if;
                  next_entity_distance:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                  next_id_quartiere_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                  next_id_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                  next_abitante_velocity:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
               else
                  if h=1 then
                     if mezzo=walking then
                        if list_abitanti_sidewalk_bici/=null then
                           entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                           next_entity_distance:= list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-(distance_ingresso-get_larghezza_corsia)+get_traiettoria_ingresso(uscita_ritorno_bici).get_lunghezza-entity_length-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                           next_id_quartiere_abitante:= list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                           next_id_abitante:= list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                           next_abitante_velocity:= list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                        else
                           if init_list_abitanti_sidewalk_bici/=null and then (list_abitanti_sidewalk_pedoni/=null and then init_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) then
                              entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(init_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,init_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                              next_entity_distance:= init_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-(distance_ingresso-get_larghezza_corsia)+get_traiettoria_ingresso(uscita_ritorno_bici).get_lunghezza-entity_length-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                              next_id_quartiere_abitante:= init_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                              next_id_abitante:= init_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                              next_abitante_velocity:= init_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                           end if;
                        end if;
                     else
                        if list_abitanti_sidewalk_bici/=null then
                           entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                           next_entity_distance:= list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-(distance_ingresso-get_larghezza_corsia)+get_traiettoria_ingresso(uscita_ritorno_bici).get_lunghezza-entity_length-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                           next_id_quartiere_abitante:= list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                           next_id_abitante:= list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                           next_abitante_velocity:= list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                        end if;
                     end if;
                  else
                     if mezzo=walking then
                        if list_abitanti_sidewalk_pedoni/=null then
                           entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                           next_entity_distance:= list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-(distance_ingresso-get_larghezza_corsia)+get_traiettoria_ingresso(uscita_ritorno_pedoni).get_lunghezza-entity_length-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                           next_id_quartiere_abitante:= list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                           next_id_abitante:= list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                           next_abitante_velocity:= list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                        end if;
                     else
                        if list_abitanti_sidewalk_pedoni/=null then
                           entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                           next_entity_distance:= list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-(distance_ingresso-get_larghezza_corsia)+get_traiettoria_ingresso(uscita_ritorno_pedoni).get_lunghezza-entity_length-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                           next_id_quartiere_abitante:= list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                           next_id_abitante:= list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                           next_abitante_velocity:= list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                        else
                           if init_list_abitanti_sidewalk_pedoni/=null and then (list_abitanti_sidewalk_bici/=null and then init_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) then
                              entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(init_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,init_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                              next_entity_distance:= init_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-(distance_ingresso-get_larghezza_corsia)+get_traiettoria_ingresso(uscita_ritorno_bici).get_lunghezza-entity_length-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                              next_id_quartiere_abitante:= init_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                              next_id_abitante:= init_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                              next_abitante_velocity:= init_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                           end if;
                        end if;
                     end if;
                  end if;
                  if next_entity_distance=0.0 or else next_entity_distance>get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza+get_larghezza_corsia then
                     next_entity_distance:= get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza+get_larghezza_corsia;
                     next_id_quartiere_abitante:= 0;
                     next_id_abitante:= 0;
                     next_abitante_velocity:= 0.0;
                  end if;
               end if;

               distance_to_stop_line:= get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza+get_urbana_from_id(id_road).get_lunghezza_road-(distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede);
               speed_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
               acceleration:= calculate_acceleration(mezzo                      => mezzo,
                                                  id_abitante                => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                  id_quartiere_abitante      => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                  next_entity_distance       => next_entity_distance,
                                                  distance_to_stop_line      => distance_to_stop_line,
                                                  next_id_quartiere_abitante => next_id_quartiere_abitante,
                                                  next_id_abitante           => next_id_abitante,
                                                  abitante_velocity          => speed_abitante,
                                                  next_abitante_velocity     => next_abitante_velocity,
                                                  disable_rallentamento_1    => True,
                                                  disable_rallentamento_2    => True,
                                                              request_by_incrocio => True);

               new_speed:= calculate_new_speed(speed_abitante,acceleration);
               new_step:= calculate_new_step(new_speed,acceleration);

               fix_advance_parameters(means,acceleration,new_speed,new_step,speed_abitante,next_entity_distance,distance_to_stop_line);
               step_is_just_calculated:= False;

               mailbox.set_move_parameters_entity_on_traiettoria_ingresso(means,list_abitanti,mailbox.get_index_ingresso_from_key(index_ingresso_opposite_direction,current_ingressi_structure_type_to_not_consider),traiettoria_da_percorrere,polo,new_speed,new_step,step_is_just_calculated);
            end if;

            if means=bike then
               list_bici:= list_bici.get_next_from_list_posizione_abitanti;
            else
               list_pedoni:= list_pedoni.get_next_from_list_posizione_abitanti;
            end if;
         end if;
      end loop;

      -- spostamento primi abitanti negli ingressi interessati fatto
      for h in 1..2 loop
         if h=1 then
            list_abitanti:= list_bici;
            means:= bike;
            traiettoria_da_percorrere:= uscita_ritorno_bici;
         else
            list_abitanti:= list_pedoni;
            means:= walking;
            traiettoria_da_percorrere:= uscita_ritorno_pedoni;
         end if;

         while list_abitanti/=null loop

            next_abitante:= list_abitanti.get_next_from_list_posizione_abitanti;
            next_entity_distance:= 0.0;
            next_id_quartiere_abitante:= 0;
            next_id_abitante:= 0;
            next_abitante_velocity:= 0.0;

            if next_abitante=null then
               if h=1 then
                  if mezzo=bike then
                     if list_abitanti_sidewalk_bici/=null then
                        next_abitante:= list_abitanti_sidewalk_bici;
                     end if;
                  else
                     if list_abitanti_sidewalk_bici/=null then
                        next_abitante:= list_abitanti_sidewalk_bici.get_next_from_list_posizione_abitanti;
                     else
                        if init_list_abitanti_sidewalk_bici/=null and then (list_abitanti_sidewalk_pedoni/=null and then init_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) then
                           next_abitante:= init_list_abitanti_sidewalk_bici;
                        end if;
                     end if;
                  end if;
                  if next_abitante/=null then
                     next_entity_distance:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_bici_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva-(distance_ingresso-get_larghezza_corsia)+get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                     next_id_quartiere_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                     next_id_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                     next_abitante_velocity:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                  end if;
               else
                  if mezzo=walking then
                     if list_abitanti_sidewalk_pedoni/=null then
                        next_abitante:= list_abitanti_sidewalk_pedoni;
                     end if;
                  else
                     if list_abitanti_sidewalk_pedoni/=null then
                        next_abitante:= list_abitanti_sidewalk_pedoni;
                     else
                        if init_list_abitanti_sidewalk_pedoni/=null and then (list_abitanti_sidewalk_bici/=null and then init_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) then
                           next_abitante:= init_list_abitanti_sidewalk_pedoni;
                        end if;
                     end if;
                  end if;
                  if next_abitante/=null then
                     next_entity_distance:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_pedone_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva-(distance_ingresso-get_larghezza_corsia)+get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                     next_id_quartiere_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                     next_id_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                     next_abitante_velocity:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                  end if;
               end if;
            else
               if means=walking then
                  next_entity_distance:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_pedone_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
               else
                  next_entity_distance:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_bici_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
               end if;
               next_id_quartiere_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
               next_id_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
               next_abitante_velocity:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
            end if;

            distance_to_stop_line:= get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza+get_urbana_from_id(id_road).get_lunghezza_road-(distance_ingresso-get_larghezza_corsia)-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
            speed_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
            acceleration:= calculate_acceleration(mezzo                      => mezzo,
                                                  id_abitante                => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                  id_quartiere_abitante      => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                  next_entity_distance       => next_entity_distance,
                                                  distance_to_stop_line      => distance_to_stop_line,
                                                  next_id_quartiere_abitante => next_id_quartiere_abitante,
                                                  next_id_abitante           => next_id_abitante,
                                                  abitante_velocity          => speed_abitante,
                                                  next_abitante_velocity     => next_abitante_velocity,
                                                  disable_rallentamento_1    => True,
                                                  disable_rallentamento_2    => True,
                                                  request_by_incrocio => True);

            new_speed:= calculate_new_speed(speed_abitante,acceleration);
            new_step:= calculate_new_step(new_speed,acceleration);

            fix_advance_parameters(means,acceleration,new_speed,new_step,speed_abitante,next_entity_distance,distance_to_stop_line);
            step_is_just_calculated:= False;

            mailbox.set_move_parameters_entity_on_traiettoria_ingresso(means,list_abitanti,mailbox.get_index_ingresso_from_key(index_ingresso_opposite_direction,current_ingressi_structure_type_to_not_consider),traiettoria_da_percorrere,polo,new_speed,new_step,step_is_just_calculated);

            list_abitanti:= list_abitanti.get_next_from_list_posizione_abitanti;
         end loop;
      end loop;
   end update_avanzamento_bipedi_in_uscita_ritorno;

   procedure exit_task is
   begin
      get_synchronization_tasks_partition_object.exit_system;
   end exit_task;

   task body core_avanzamento_urbane is
      id_task: Positive;
      mailbox: ptr_resource_segmento_urbana;
      --key_ingresso: Natural;
      --abitante: ptr_list_posizione_abitanti_on_road;
      can_move_from_traiettoria: Boolean;

      next_pos_abitante: new_float;
      --temp_next_pos_abitante: new_float;
      next_pos_ingresso_move: new_float:= 0.0;
      next_abitante: ptr_list_posizione_abitanti_on_road;
      ingresso: strada_ingresso_features;

      list_abitanti_uscita_andata: ptr_list_posizione_abitanti_on_road;
      list_abitanti_uscita_ritorno: ptr_list_posizione_abitanti_on_road;
      list_abitanti_entrata_andata: ptr_list_posizione_abitanti_on_road;
      list_abitanti_entrata_ritorno: ptr_list_posizione_abitanti_on_road;
      current_list_abitanti_traiettoria: ptr_list_posizione_abitanti_on_road;

      corsia_destra: ptr_list_posizione_abitanti_on_road;
      corsia_sinistra: ptr_list_posizione_abitanti_on_road;

      move_entity: move_parameters;

      stop_entity: Boolean:= False;
      there_are_bipedi_in_movement_in_entrata: Boolean;
      there_are_bipedi_in_movement_in_uscita: Boolean;

      acceleration_car: new_float:= 0.0;
      acceleration: new_float:= 0.0;
      new_speed: new_float:= 0.0;
      new_step: new_float:= 0.0;
      distance_to_next: new_float:= 0.0;

      next_entity_distance: new_float;
      distance_to_stop_line: new_float;

      current_ingressi_structure_type_to_consider: ingressi_type;
      current_ingressi_structure_type_to_not_consider: ingressi_type;
      --tmp_current_ingressi_structure_to_consider: ingressi_type;
      distance_ingresso: new_float;
      current_polo_to_consider: Boolean:= False;
      --tmp_polo_to_consider: Boolean;
      traiettoria_rimasta_da_percorrere: new_float;
      --ingresso_to_consider: strada_ingresso_features;

      first_corsia: Natural;
      other_corsia: Natural;
      next_car_in_corsia: ptr_list_posizione_abitanti_on_road;
      next_car_in_opposite_corsia: ptr_list_posizione_abitanti_on_road;
      current_car_in_corsia: ptr_list_posizione_abitanti_on_road;
      destination: trajectory_to_follow;
      costante_additiva: new_float;
      bound_to_overtake: new_float;
      next_car_in_ingresso_distance: new_float;
      next_car_on_road: ptr_list_posizione_abitanti_on_road;
      next_car_on_road_distance: new_float;
      can_not_overtake_now: Boolean;

      tratto_incrocio: tratto;

      state_view_abitanti: JSON_Array;

      list_abitanti_on_traiettoria_ingresso: ptr_list_posizione_abitanti_on_road;
      --car_length: new_float;

      num_delta: Natural:= 0;
      --z: Positive;

      speed_abitante: new_float;

      semaforo_is_verde: Boolean;
      disable_rallentamento: Boolean;

      bound_distance: new_float;
      stop_entity_to_incrocio: Boolean:= False;
      distance_to_next_car: new_float;
      index_road: Natural;

      abitante_to_transfer: posizione_abitanti_on_road;
      --prec_abitante: ptr_list_posizione_abitanti_on_road;
      length_car_on_road: new_float;

      prec_abitante_other_corsia: ptr_list_posizione_abitanti_on_road;
      next_abitante_other_corsia: ptr_list_posizione_abitanti_on_road;
      can_overtake: Boolean;
      abilita_limite_overtaken: Boolean;
      limite_in_overtaken: constant new_float:= get_traiettoria_cambio_corsia.get_lunghezza_traiettoria/2.0;
      next_entity_is_ingresso: Boolean;

      --abitante_in_transizione: posizione_abitanti_on_road;

      minus: new_float;
      ab: posizione_abitanti_on_road;
      step_is_just_calculated: Boolean;
      new_distance: new_float;

      list_abitanti: ptr_list_posizione_abitanti_on_road;
      list_abitanti_pedoni: ptr_list_posizione_abitanti_on_road;
      list_abitanti_bici: ptr_list_posizione_abitanti_on_road;
      other_list_abitanti: ptr_list_posizione_abitanti_on_road;
      prec_other_list_abitanti: ptr_list_posizione_abitanti_on_road;
      --other_list_abitanti_bici: ptr_list_posizione_abitanti_on_road;
      other_list: ptr_list_posizione_abitanti_on_road;
      init_list_abitanti_sidewalk_pedoni: ptr_list_posizione_abitanti_on_road;
      init_list_abitanti_sidewalk_bici: ptr_list_posizione_abitanti_on_road;
      list_abitanti_sidewalk_pedoni: ptr_list_posizione_abitanti_on_road;
      list_abitanti_sidewalk_bici: ptr_list_posizione_abitanti_on_road;
      list_abitanti_sidewalk_pedoni_is_set: Boolean;
      list_abitanti_sidewalk_bici_is_set: Boolean;
      prec_list_abitanti_sidewalk_pedoni: ptr_list_posizione_abitanti_on_road;
      prec_list_abitanti_sidewalk_bici: ptr_list_posizione_abitanti_on_road;
      next_abitante_length: new_float;

      --location_velocipede: tratto_velocipedi_location;
      switch: Boolean;
      segnale: Boolean;
      signal: Boolean;

      --index_ingresso: Natural;

      traiettoria_da_percorrere: traiettoria_ingressi_type;
      traiettoria_incrocio_uno: traiettoria_incroci_type;
      next_id_quartiere_abitante: Natural;
      next_id_abitante: Natural;
      next_abitante_velocity: new_float;
      mezzo: means_of_carrying;

      entity_length: new_float;

      indice: Positive;

      index_ingresso_same_direction: Natural;
      index_ingresso_opposite_direction: Integer;
      distance_ingresso_same_direction: new_float;
      distance_ingresso_opposite_direction: new_float;
      distance_last_ingresso: Boolean;
      validity_ingresso_same_direction: Boolean;
      validity_ingresso_opposite_direction: Boolean;
      temp_next_entity_distance_1: new_float;
      temp_next_entity_distance_2: new_float;
      best_temp_next_entity_distance: new_float;

      precedenze_bici_bipedi_su_tratto: Boolean;
      precedenze_bici_bipedi_su_tratto_uscita: array (1..2) of Boolean;

      num_ingressi: Natural;

      --index_ingresso_same_polo: Natural;
      --index_ingresso_opposite_polo: Natural;
      error_flag: Boolean:= False;

      new_abitante: posizione_abitanti_on_road;

      tmp_next_entity_distance: new_float:= -1.0;

      variabile_nat: Natural:= 0;

      dare_precedenza_to_uscite: Boolean;
   begin
      select
         accept configure(id: Positive) do
            id_task:= id;
            mailbox:= get_urbane_segmento_resources(id);
         end configure;
      or
         accept kill do
            null;
            --raise system_error_exc;
         end kill;
      end select;

      if log_system_error.is_in_error then
         raise system_error_exc;
      end if;
      -- Put_Line("configurato" & Positive'Image(id_task) & "id quartiere" & Positive'Image(get_id_quartiere));
      --wait_settings_all_quartieri;
      --Put_Line("task " & Positive'Image(id_task) & " of quartiere " & Positive'Image(get_id_quartiere) & " is set");

      reconfigure_resource(ptr_backup_interface(mailbox),id_task);

      loop
      --for p in 1..100 loop

         synchronization_with_delta(id_task);
         if get_synchronization_tasks_partition_object.is_regular_closure then
            raise regular_exit_system;
         end if;
         if log_system_error.is_in_error then
            raise propaga_error;
         end if;

         --log_mio.write_task_arrived("id_task " & Positive'Image(id_task) & " id_quartiere " & Positive'Image(get_id_quartiere));

         state_view_abitanti:= Empty_Array;
         -- prima update_car_on_road  poi  update_traiettorie_ingressi  cosi  update_traiettorie_ingressi inserisce
         -- le macchine nella posizione corretta della main_strada rispetto alla posizione now delle macchine
         mailbox.update_car_on_road(state_view_abitanti);
         mailbox.update_traiettorie_ingressi(state_view_abitanti);

         mailbox.update_bipedi_on_sidewalk(state_view_abitanti);
         mailbox.update_bipedi_on_traiettorie_ingressi(state_view_abitanti);

         --mailbox.view_updated(True);

         state_view_quartiere.registra_aggiornamento_stato_risorsa(id_task,state_view_abitanti,JSON_Null,mailbox.get_entità_in_out_quartiere);
         mailbox.reset_entità_in_out_quartiere;

         mailbox.wait_incroci;
         if log_system_error.is_in_error then
            raise propaga_error;
         end if;
         -- fine wait; gli incroci hanno fatto l'avanzamento

         mailbox.abilitazione_sinistra_bipedi_in_incroci(False,walking,True);
         mailbox.abilitazione_sinistra_bipedi_in_incroci(True,walking,True);
         mailbox.abilitazione_sinistra_bipedi_in_incroci(False,bike,True);
         mailbox.abilitazione_sinistra_bipedi_in_incroci(True,bike,True);

         mailbox.abilita_attraversamento_cars_ingressi;
         mailbox.abilita_attraversamento_bipedi_in_all_entrata_ingresso;
         mailbox.abilita_attraversamento_all_ingressi;

         -- BEGIN SPOSTAMENTO BICI/PEDONI
         for range_1 in False..True loop
            if range_1 then
               current_ingressi_structure_type_to_consider:= ordered_polo_true;
               current_ingressi_structure_type_to_not_consider:= ordered_polo_false;
            else
               current_ingressi_structure_type_to_consider:= ordered_polo_false;
               current_ingressi_structure_type_to_not_consider:= ordered_polo_true;
            end if;

            init_list_abitanti_sidewalk_bici:= mailbox.get_abitanti_to_move(sidewalk,range_1,1);
            init_list_abitanti_sidewalk_pedoni:= mailbox.get_abitanti_to_move(sidewalk,range_1,2);

            list_abitanti_sidewalk_bici:= init_list_abitanti_sidewalk_bici;
            list_abitanti_sidewalk_pedoni:= init_list_abitanti_sidewalk_pedoni;

            if list_abitanti_sidewalk_bici/=null and list_abitanti_sidewalk_pedoni/=null then
               if list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti then
                  list_abitanti:= list_abitanti_sidewalk_bici;
                  list_abitanti_sidewalk_pedoni:= null;
                  mezzo:= bike;
               else
                  list_abitanti:= list_abitanti_sidewalk_pedoni;
                  list_abitanti_sidewalk_bici:= null;
                  mezzo:= walking;
               end if;
            elsif list_abitanti_sidewalk_bici/=null then
               list_abitanti:= list_abitanti_sidewalk_bici;
               list_abitanti_sidewalk_pedoni:= null;
               mezzo:= bike;
            elsif list_abitanti_sidewalk_pedoni/=null then
               list_abitanti:= list_abitanti_sidewalk_pedoni;
               list_abitanti_sidewalk_bici:= null;
               mezzo:= walking;
            else
               list_abitanti:= null;
            end if;

            if list_abitanti_sidewalk_pedoni=null then
               list_abitanti_sidewalk_pedoni_is_set:= False;
            else
               list_abitanti_sidewalk_pedoni_is_set:= True;
            end if;
            if list_abitanti_sidewalk_bici=null then
               list_abitanti_sidewalk_bici_is_set:= False;
            else
               list_abitanti_sidewalk_bici_is_set:= True;
            end if;

            switch:= True;
            index_ingresso_same_direction:= 1;
            if mailbox.get_ordered_ingressi_from_polo(not range_1)/=null then
               index_ingresso_opposite_direction:= mailbox.get_ordered_ingressi_from_polo(not range_1).all'Last;
            else
               index_ingresso_opposite_direction:= 0;
            end if;
            distance_ingresso_opposite_direction:= -1.0;
            distance_ingresso_same_direction:= -1.0;
            prec_list_abitanti_sidewalk_pedoni:= null;
            prec_list_abitanti_sidewalk_bici:= null;
            while switch loop

               stop_entity:= False;
               next_entity_distance:= 0.0;
               temp_next_entity_distance_1:= 0.0;
               temp_next_entity_distance_2:= 0.0;
               next_id_quartiere_abitante:= 0;
               next_id_abitante:= 0;
               next_abitante_velocity:= 0.0;
               step_is_just_calculated:= False;

               validity_ingresso_same_direction:= False;
               validity_ingresso_opposite_direction:= False;
               if mailbox.get_ordered_ingressi_from_polo(range_1)/=null and then index_ingresso_same_direction<=mailbox.get_ordered_ingressi_from_polo(range_1).all'Last then
                  validity_ingresso_same_direction:= True;
               end if;
               if index_ingresso_opposite_direction>0 then
                  validity_ingresso_opposite_direction:= True;
               end if;

               if list_abitanti_sidewalk_bici/=null and list_abitanti_sidewalk_pedoni/=null then
                  if list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti then
                     list_abitanti:= list_abitanti_sidewalk_bici;
                     mezzo:= bike;
                  else
                     list_abitanti:= list_abitanti_sidewalk_pedoni;
                     mezzo:= walking;
                  end if;
               elsif list_abitanti_sidewalk_bici/=null then
                  list_abitanti:= list_abitanti_sidewalk_bici;
                  mezzo:= bike;
               elsif list_abitanti_sidewalk_pedoni/=null then
                  list_abitanti:= list_abitanti_sidewalk_pedoni;
                  mezzo:= walking;
               else
                  list_abitanti:= null;
               end if;

               if validity_ingresso_opposite_direction then
                  distance_ingresso_opposite_direction:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(index_ingresso_opposite_direction,current_ingressi_structure_type_to_not_consider)),range_1);
               end if;
               if validity_ingresso_same_direction then
                  distance_ingresso_same_direction:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,current_ingressi_structure_type_to_consider)),range_1);
               end if;

               if list_abitanti/=null then
                  if (list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti=204 and (list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>500.0 and id_task=16)) and range_1 then
                     stop_entity:= False;
                  end if;
                  if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow=empty then
                     --if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_from_ingresso=0 then
                        if get_ingresso_from_id(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_ingresso_to_go_trajectory).get_polo_ingresso=range_1 then
                           distance_to_stop_line:= get_distance_from_polo_percorrenza(get_ingresso_from_id(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_ingresso_to_go_trajectory),range_1)-get_larghezza_corsia-get_larghezza_marciapiede;
                        else
                           distance_to_stop_line:= get_distance_from_polo_percorrenza(get_ingresso_from_id(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_ingresso_to_go_trajectory),range_1)+get_larghezza_corsia;
                        end if;
                     --else
                     --   if get_ingresso_from_id(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_from_ingresso).get_polo_ingresso=get_ingresso_from_id(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_ingresso_to_go_trajectory).get_polo_ingresso then
                     --      if get_distance_from_polo_percorrenza(get_ingresso_from_id(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_from_ingresso),range_1)<get_distance_from_polo_percorrenza(get_ingresso_from_id(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_ingresso_to_go_trajectory),range_1) then
                              -- uscita_destra
                     --         distance_to_stop_line:= get_distance_from_polo_percorrenza(get_ingresso_from_id(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_ingresso_to_go_trajectory),range_1)-get_larghezza_corsia-get_larghezza_marciapiede;
                     --      else
                              -- uscita_dritto
                     --         distance_to_stop_line:= get_distance_from_polo_percorrenza(get_ingresso_from_id(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_ingresso_to_go_trajectory),range_1)+get_larghezza_corsia;
                     --      end if;
                     --   else
                     --      if get_distance_from_polo_percorrenza(get_ingresso_from_id(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_from_ingresso),range_1)<get_distance_from_polo_percorrenza(get_ingresso_from_id(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_ingresso_to_go_trajectory),range_1) then
                              -- uscita_destra
                     --         distance_to_stop_line:= get_distance_from_polo_percorrenza(get_ingresso_from_id(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_ingresso_to_go_trajectory),range_1)+get_larghezza_corsia;
                     --      else
                              -- uscita_dritto
                     --         distance_to_stop_line:= get_distance_from_polo_percorrenza(get_ingresso_from_id(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_ingresso_to_go_trajectory),range_1)-get_larghezza_corsia-get_larghezza_marciapiede;
                     --      end if;
                     --   end if;
                     --end if;
                  else
                     distance_to_stop_line:= get_urbana_from_id(id_task).get_lunghezza_road;
                  end if;
                  distance_to_stop_line:= distance_to_stop_line-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;

                  -- aggiornamento indici ingressi
                  signal:= False;
                  if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=distance_ingresso_opposite_direction+get_larghezza_corsia then
                     if mezzo=walking then
                        if (prec_list_abitanti_sidewalk_pedoni/=null and then prec_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_opposite_direction-get_larghezza_corsia-get_larghezza_marciapiede) or else
                          (prec_list_abitanti_sidewalk_bici/=null and then prec_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_opposite_direction-get_larghezza_corsia-get_larghezza_marciapiede) then
                           signal:= True;
                        end if;
                     else
                        if (prec_list_abitanti_sidewalk_bici/=null and then prec_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_opposite_direction-get_larghezza_corsia-get_larghezza_marciapiede) or else
                          (prec_list_abitanti_sidewalk_pedoni/=null and then prec_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_opposite_direction-get_larghezza_corsia-get_larghezza_marciapiede) then
                           signal:= True;
                        end if;
                     end if;
                  else
                     if mezzo=walking then
                        if (prec_list_abitanti_sidewalk_pedoni/=null and then prec_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_opposite_direction-get_larghezza_corsia-get_larghezza_marciapiede) or else
                          (prec_list_abitanti_sidewalk_bici/=null and then prec_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_opposite_direction-get_larghezza_corsia-get_larghezza_marciapiede) then
                           signal:= True;
                        end if;
                     else
                        if (prec_list_abitanti_sidewalk_bici/=null and then prec_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_opposite_direction-get_larghezza_corsia-get_larghezza_marciapiede) or else
                          (prec_list_abitanti_sidewalk_pedoni/=null and then prec_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_opposite_direction-get_larghezza_corsia-get_larghezza_marciapiede) then
                           signal:= True;
                        end if;
                     end if;
                     if signal then
                        signal:= False;
                        index_ingresso_opposite_direction:= index_ingresso_opposite_direction-1;
                        validity_ingresso_opposite_direction:= False;
                        if index_ingresso_opposite_direction>0 then
                           validity_ingresso_opposite_direction:= True;
                           distance_ingresso_opposite_direction:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(index_ingresso_opposite_direction,current_ingressi_structure_type_to_not_consider)),range_1);
                        end if;
                     end if;
                  end if;

                  while signal=False and then (validity_ingresso_opposite_direction and then distance_ingresso_opposite_direction-get_larghezza_corsia-get_larghezza_marciapiede<list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) loop
                     update_avanzamento_bipedi_in_uscita_ritorno(mailbox,list_abitanti_sidewalk_pedoni,list_abitanti_sidewalk_bici,prec_list_abitanti_sidewalk_pedoni,prec_list_abitanti_sidewalk_bici,mezzo,index_ingresso_opposite_direction,current_ingressi_structure_type_to_not_consider,range_1,id_task,init_list_abitanti_sidewalk_bici,init_list_abitanti_sidewalk_pedoni);
                     if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_opposite_direction+get_larghezza_corsia then
                        index_ingresso_opposite_direction:= index_ingresso_opposite_direction-1;
                        validity_ingresso_opposite_direction:= False;
                        if index_ingresso_opposite_direction>0 then
                           validity_ingresso_opposite_direction:= True;
                           distance_ingresso_opposite_direction:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(index_ingresso_opposite_direction,current_ingressi_structure_type_to_not_consider)),range_1);
                        end if;
                     else
                        validity_ingresso_opposite_direction:= False;
                     end if;
                  end loop;
                  if index_ingresso_opposite_direction>0 then
                     validity_ingresso_opposite_direction:= True;
                  end if;

                  -- aggiornamento indici ingressi
                  signal:= False;
                  --if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=distance_ingresso_same_direction+get_larghezza_corsia then
                  --   if mezzo=walking then
                  --      if (prec_list_abitanti_sidewalk_pedoni/=null and then prec_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede) or else
                  --        (list_abitanti_sidewalk_bici/=null and then list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede) then
                  --         signal:= True;
                  --      end if;
                  --   else
                  --      if (prec_list_abitanti_sidewalk_bici/=null and then prec_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede) or else
                  --        (list_abitanti_sidewalk_pedoni/=null and then list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede) then
                  --         signal:= True;
                  --      end if;
                  --   end if;
                  --end if;

                  while signal=False and then (validity_ingresso_same_direction and then distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede<list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) loop
                     if range_1 then
                        current_ingressi_structure_type_to_consider:= ordered_polo_true;
                     else
                        current_ingressi_structure_type_to_consider:= ordered_polo_false;
                     end if;
                     if mezzo=walking then
                        entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                     else
                        entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                     end if;
                     if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length<distance_ingresso_same_direction then
                        mailbox.disabilita_attraversamento_cars_ingresso(False,range_1,index_ingresso_same_direction);
                        mailbox.disabilita_att_cars_ingressi_per_intersezione(False,mailbox.get_key_ingresso(mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,current_ingressi_structure_type_to_consider),not_ordered));
                     end if;
                     if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<distance_ingresso_same_direction+get_larghezza_corsia or else
                       list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length<distance_ingresso_same_direction+get_larghezza_corsia then
                        mailbox.disabilita_attraversamento_cars_ingresso(True,range_1,index_ingresso_same_direction);
                        mailbox.disabilita_att_cars_ingressi_per_intersezione(True,mailbox.get_key_ingresso(mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,current_ingressi_structure_type_to_consider),not_ordered));
                     end if;

                     segnale:= True;
                     if mezzo=walking then
                        if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_pedone_quartiere(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<distance_ingresso_same_direction-get_larghezza_corsia then
                           segnale:= False;
                        end if;
                        if prec_list_abitanti_sidewalk_pedoni/=null and then (prec_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede and then prec_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia*2.0-get_larghezza_marciapiede) then
                           segnale:= False;
                        end if;
                        if prec_list_abitanti_sidewalk_bici/=null and then (prec_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede and then prec_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia*2.0-get_larghezza_marciapiede) then
                           segnale:= False;
                        end if;
                        --if (prec_list_abitanti_sidewalk_bici/=null and then (prec_list_abitanti_sidewalk_bici.get_next_from_list_posizione_abitanti/=null and then (prec_list_abitanti_sidewalk_bici.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia*2.5-get_larghezza_marciapiede and then prec_list_abitanti_sidewalk_bici.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_bici_quartiere(prec_list_abitanti_sidewalk_bici.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,prec_list_abitanti_sidewalk_bici.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<distance_ingresso_same_direction-get_larghezza_corsia))) then
                        --   segnale:= False;
                        --end if;
                     else
                        if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_bici_quartiere(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<distance_ingresso_same_direction then
                           segnale:= False;
                        end if;
                        if prec_list_abitanti_sidewalk_bici/=null and then (prec_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede and then prec_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia*2.0-get_larghezza_marciapiede) then
                           segnale:= False;
                        end if;
                        if prec_list_abitanti_sidewalk_pedoni/=null and then (prec_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede and then prec_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia*2.0-get_larghezza_marciapiede) then
                           segnale:= False;
                        end if;
                        --if (prec_list_abitanti_sidewalk_pedoni/=null and then (prec_list_abitanti_sidewalk_pedoni.get_next_from_list_posizione_abitanti/=null and then (prec_list_abitanti_sidewalk_pedoni.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia*2.5+get_larghezza_marciapiede and then prec_list_abitanti_sidewalk_pedoni.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_pedone_quartiere(prec_list_abitanti_sidewalk_pedoni.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,prec_list_abitanti_sidewalk_pedoni.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<distance_ingresso_same_direction-get_larghezza_corsia))) then
                        --   segnale:= False;
                        --end if;
                     end if;
                     if segnale=False then
                        mailbox.disabilita_attraversamento_bipedi_in_entrata_ingresso(range_1,index_ingresso_same_direction);
                     end if;

                     if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_same_direction+get_larghezza_corsia then
                        index_ingresso_same_direction:= index_ingresso_same_direction+1;
                        validity_ingresso_same_direction:= False;
                        if index_ingresso_same_direction<=mailbox.get_ordered_ingressi_from_polo(range_1).all'Last then
                           validity_ingresso_same_direction:= True;
                           distance_ingresso_same_direction:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,current_ingressi_structure_type_to_consider)),range_1);
                        end if;
                     else
                        signal:= True;
                     end if;
                  end loop;

                  next_abitante:= list_abitanti.get_next_from_list_posizione_abitanti;
                  traiettoria_incrocio_uno:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow;
                  if mezzo=walking then
                     if traiettoria_incrocio_uno=sinistra_pedoni then
                        traiettoria_incrocio_uno:= dritto_pedoni;
                     end if;
                  else
                     if traiettoria_incrocio_uno=sinistra_bici then
                        traiettoria_incrocio_uno:= dritto_bici;
                     end if;
                  end if;
                  if next_abitante=null then
                     if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow/=empty then
                        if get_quartiere_utilities_obj.get_classe_locate_abitanti(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_current_position(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti)=1 then
                           tratto_incrocio:= get_quartiere_utilities_obj.get_classe_locate_abitanti(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_next(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                        else
                           tratto_incrocio:= get_quartiere_utilities_obj.get_classe_locate_abitanti(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_next_incrocio(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                        end if;
                        costante_additiva:= ptr_rt_incrocio(get_id_incrocio_quartiere(tratto_incrocio.get_id_quartiere_tratto,tratto_incrocio.get_id_tratto)).get_posix_first_bipede(get_id_quartiere,id_task,mezzo,traiettoria_incrocio_uno);
                        if costante_additiva<0.0 then
                           next_entity_distance:= get_urbana_from_id(id_task).get_lunghezza_road+costante_additiva-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                        else
                           null; -- prevale distance to stop line
                        end if;
                     else
                        null;
                     end if;
                  else
                     if mezzo=bike then
                        entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                     else
                        entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                     end if;
                     next_entity_distance:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                     next_id_quartiere_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                     next_id_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                     next_abitante_velocity:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                  end if;

                  -- controllo delle traiettorie sugli ingressi
                  -- trovare a che distanza si trova il prossimo abitante
                  if validity_ingresso_same_direction then
                     temp_next_entity_distance_1:= 0.0;
                     best_temp_next_entity_distance:= new_float'Last;
                     signal:= False;
                     for h in reverse index_ingresso_same_direction..mailbox.get_ordered_ingressi_from_polo(range_1).all'Last loop
                        entity_length:= 0.0;
                        if temp_next_entity_distance_1=0.0 then
                           if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider)),range_1)-get_larghezza_corsia-get_larghezza_marciapiede then
                              if mezzo=walking then
                                 other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider),entrata_destra_pedoni);
                                 if other_list_abitanti/=null then
                                    entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                 end if;
                              else
                                 other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider),entrata_destra_bici);
                                 if other_list_abitanti/=null then
                                    entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                 end if;
                              end if;

                              if other_list_abitanti/=null then
                                 if other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length<0.0 then
                                    temp_next_entity_distance_1:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider)),range_1)-get_larghezza_corsia-get_larghezza_marciapiede-entity_length;
                                 else
                                    temp_next_entity_distance_1:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider)),range_1)-get_larghezza_marciapiede-get_larghezza_corsia;
                                 end if;
                              elsif mezzo=walking then
                                 other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider),entrata_destra_bici);
                                 if other_list_abitanti/=null and then other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 then
                                    temp_next_entity_distance_1:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider)),range_1)-get_larghezza_marciapiede-get_larghezza_corsia;
                                 end if;
                              end if;

                              for s in 1..2 loop
                                 if s=1 then
                                    other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider),entrata_dritto_bici);
                                 else
                                    other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider),entrata_dritto_pedoni);
                                 end if;
                                 segnale:= False;
                                 while other_list_abitanti/=null loop
                                    if other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_larghezza_corsia*4.0 and other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia then
                                       segnale:= True;
                                    end if;
                                    if other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_larghezza_corsia*4.0 then
                                       segnale:= True;
                                    end if;
                                    if segnale then
                                       temp_next_entity_distance_1:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider)),range_1)-get_larghezza_marciapiede-get_larghezza_corsia;
                                    end if;
                                    other_list_abitanti:= other_list_abitanti.get_next_from_list_posizione_abitanti;
                                 end loop;
                              end loop;

                           end if;

                           if temp_next_entity_distance_1=0.0 then
                              other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider),entrata_andata);
                              if other_list_abitanti/=null and then other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 then
                                 temp_next_entity_distance_1:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider)),range_1)-get_larghezza_corsia;
                              end if;
                              if temp_next_entity_distance_1=0.0 then
                                 other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider),entrata_ritorno);
                                 if other_list_abitanti/=null and then other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie+max_larghezza_veicolo*2.0 then
                                    temp_next_entity_distance_1:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider)),range_1)-get_larghezza_corsia;
                                 end if;
                              end if;
                              if temp_next_entity_distance_1=0.0 then
                                 other_list_abitanti:= get_ingressi_segmento_resources(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider)).get_first_abitante_to_exit_from_urbana(car);
                                 if other_list_abitanti/=null and then other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<0.0 then
                                    temp_next_entity_distance_1:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider)),range_1)-get_larghezza_corsia;
                                 end if;
                              end if;
                              if temp_next_entity_distance_1=0.0 then
                                 other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider),uscita_andata);
                                 if other_list_abitanti/=null and then other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 then
                                    temp_next_entity_distance_1:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider)),range_1);
                                 end if;
                              end if;
                              if temp_next_entity_distance_1=0.0 then
                                 other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider),uscita_ritorno);
                                 if other_list_abitanti/=null and then other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 then
                                    entity_length:= get_quartiere_utilities_obj.get_auto_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                    if other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length<max_length_veicolo then
                                       temp_next_entity_distance_1:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider)),range_1);
                                    end if;
                                 end if;
                              end if;
                           end if;

                           if temp_next_entity_distance_1=0.0 then
                              -- GUARDA USCITA DESTRA
                              if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider)),range_1)+get_larghezza_corsia then
                                 if mezzo=walking then
                                    other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider),uscita_destra_bici);
                                    if other_list_abitanti/=null and then (other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 or else other_list_abitanti.get_next_from_list_posizione_abitanti/=null) then
                                       temp_next_entity_distance_1:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider)),range_1)+get_larghezza_corsia;
                                    else
                                       other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider),uscita_destra_pedoni);
                                       if other_list_abitanti/=null and then (other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 or else other_list_abitanti.get_next_from_list_posizione_abitanti/=null) then
                                          temp_next_entity_distance_1:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider)),range_1)+get_larghezza_corsia;
                                       end if;
                                    end if;
                                 else
                                    other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider),uscita_destra_bici);
                                    if other_list_abitanti/=null and then (other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 or else other_list_abitanti.get_next_from_list_posizione_abitanti/=null) then
                                       temp_next_entity_distance_1:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider)),range_1)+get_larghezza_corsia;
                                    end if;
                                 end if;
                              end if;
                              -- GUARDA USCITA DRITTO
                              if temp_next_entity_distance_1=0.0 and then list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider)),range_1)+get_larghezza_corsia then
                                 segnale:= False;
                                 for s in 1..2 loop
                                    segnale:= False;
                                    if s=1 then
                                       other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider),uscita_dritto_bici);
                                    else
                                       other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider),uscita_dritto_pedoni);
                                    end if;
                                    if other_list_abitanti/=null then
                                       if other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 or else other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia then
                                          if s=2 then
                                             costante_additiva:= get_quartiere_utilities_obj.get_pedone_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                          else
                                             costante_additiva:= get_quartiere_utilities_obj.get_bici_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                          end if;
                                          if other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_larghezza_marciapiede or else
                                            other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-costante_additiva<get_larghezza_marciapiede then
                                             segnale:= True;
                                          end if;
                                       end if;
                                       if other_list_abitanti.get_next_from_list_posizione_abitanti/=null then
                                          other_list_abitanti:= other_list_abitanti.get_next_from_list_posizione_abitanti;
                                          if s=2 then
                                             costante_additiva:= get_quartiere_utilities_obj.get_pedone_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                          else
                                             costante_additiva:= get_quartiere_utilities_obj.get_bici_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                          end if;
                                          if other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_larghezza_marciapiede or else
                                            other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-costante_additiva<get_larghezza_marciapiede then
                                             segnale:= True;
                                          end if;
                                       end if;
                                       if segnale then
                                          temp_next_entity_distance_1:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_consider)),range_1)+get_larghezza_corsia;
                                       end if;
                                    end if;
                                 end loop;
                              end if;
                           end if;
                        end if;
                        if temp_next_entity_distance_1>0.0 and then temp_next_entity_distance_1<best_temp_next_entity_distance then
                           best_temp_next_entity_distance:= temp_next_entity_distance_1;
                           signal:= True;
                        end if;
                        temp_next_entity_distance_1:= 0.0;
                     end loop;
                     if signal then
                        temp_next_entity_distance_1:= best_temp_next_entity_distance;
                     else
                        temp_next_entity_distance_1:= 0.0;
                     end if;
                     if temp_next_entity_distance_1/=0.0 then
                        temp_next_entity_distance_1:= temp_next_entity_distance_1-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                     end if;

                  end if;

                  if validity_ingresso_opposite_direction then
                     temp_next_entity_distance_2:= 0.0;
                     best_temp_next_entity_distance:= new_float'Last;
                     signal:= False;
                     for h in 1..index_ingresso_opposite_direction loop
                        entity_length:= 0.0;
                        if temp_next_entity_distance_2=0.0 then
                           if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_not_consider)),range_1)-get_larghezza_corsia-get_larghezza_marciapiede then
                              if mezzo=walking then
                                 other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_not_consider),uscita_ritorno_pedoni);
                              else
                                 other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_not_consider),uscita_ritorno_pedoni);
                                 if other_list_abitanti/=null and then ((other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 or else
                                                                        other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia) or else other_list_abitanti.get_next_from_list_posizione_abitanti/=null) then
                                    temp_next_entity_distance_2:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_not_consider)),range_1)-get_larghezza_corsia-get_larghezza_marciapiede;
                                 end if;
                                 other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_not_consider),uscita_ritorno_bici);
                              end if;

                              if other_list_abitanti/=null and then ((other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 or else
                                                                     other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia) or else other_list_abitanti.get_next_from_list_posizione_abitanti/=null) then
                                 temp_next_entity_distance_2:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_not_consider)),range_1)-get_larghezza_corsia-get_larghezza_marciapiede;
                              end if;
                           end if;

                           --if temp_next_entity_distance_2=0.0 then
                              --if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_not_consider)),range_1)+get_larghezza_corsia then
                              --   if mezzo=walking then
                              --      other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_not_consider),entrata_ritorno_pedoni);
                              --      if other_list_abitanti/=null then
                              --         entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                              --      end if;
                              --   else
                              --      other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_not_consider),entrata_ritorno_bici);
                              --      if other_list_abitanti/=null then
                              --         entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                              --      end if;
                              --   end if;

                              --   if other_list_abitanti/=null then
                              --      if other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length<0.0 then
                              --         temp_next_entity_distance_2:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_not_consider)),range_1)+get_larghezza_corsia-entity_length;
                              --      else
                              --         temp_next_entity_distance_2:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_not_consider)),range_1)+get_larghezza_corsia;
                              --      end if;
                              --   end if;

                              --   if mezzo=bike and temp_next_entity_distance_2=0.0 then
                              --      other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_not_consider),entrata_ritorno_pedoni);
                              --      if other_list_abitanti/=null then
                              --         temp_next_entity_distance_2:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(h,current_ingressi_structure_type_to_not_consider)),range_1)+get_larghezza_corsia;
                              --      end if;
                              --   end if;

                              --end if;
                           --end if;
                        end if;
                        if temp_next_entity_distance_2>0.0 and then temp_next_entity_distance_2<best_temp_next_entity_distance then
                           best_temp_next_entity_distance:= temp_next_entity_distance_2;
                           signal:= True;
                        end if;
                        temp_next_entity_distance_2:= 0.0;
                     end loop;
                     if signal then
                        temp_next_entity_distance_2:= best_temp_next_entity_distance;
                     else
                        temp_next_entity_distance_2:= 0.0;
                     end if;
                     if temp_next_entity_distance_2/=0.0 then
                        temp_next_entity_distance_2:= temp_next_entity_distance_2-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                     end if;
                  end if;

                  if temp_next_entity_distance_1/=0.0 and temp_next_entity_distance_2/=0.0 then
                     if temp_next_entity_distance_1<=temp_next_entity_distance_2 then
                        costante_additiva:= temp_next_entity_distance_1;
                     else
                        costante_additiva:= temp_next_entity_distance_2;
                     end if;
                  elsif temp_next_entity_distance_1/=0.0 and temp_next_entity_distance_2=0.0 then
                     costante_additiva:= temp_next_entity_distance_1;
                  elsif temp_next_entity_distance_2/=0.0 and temp_next_entity_distance_1=0.0 then
                     costante_additiva:= temp_next_entity_distance_2;
                  else
                     costante_additiva:= 0.0;
                  end if;

                  if next_entity_distance/=0.0 and costante_additiva/=0.0 then
                     if next_entity_distance>costante_additiva then
                        next_entity_distance:= costante_additiva;
                        next_id_quartiere_abitante:= 0;
                        next_id_abitante:= 0;
                        next_abitante_velocity:= 0.0;
                     end if;
                  elsif next_entity_distance=0.0 and costante_additiva/=0.0 then
                     next_entity_distance:= costante_additiva;
                     next_id_quartiere_abitante:= 0;
                     next_id_abitante:= 0;
                     next_abitante_velocity:= 0.0;
                  end if;

                  speed_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                  acceleration:= calculate_acceleration(mezzo                      => mezzo,
                                                        id_abitante                => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                        id_quartiere_abitante      => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                        next_entity_distance       => next_entity_distance,
                                                        distance_to_stop_line      => distance_to_stop_line,
                                                        next_id_quartiere_abitante => next_id_quartiere_abitante,
                                                        next_id_abitante           => next_id_abitante,
                                                        abitante_velocity          => speed_abitante,
                                                        next_abitante_velocity     => next_abitante_velocity,
                                                        disable_rallentamento_1    => True,
                                                        disable_rallentamento_2    => True);

                  new_speed:= calculate_new_speed(speed_abitante,acceleration);
                  new_step:= calculate_new_step(new_speed,acceleration);


                  fix_advance_parameters(mezzo,acceleration,new_speed,new_step,speed_abitante,next_entity_distance,distance_to_stop_line);

                  -- configurare la destinazione dell'abitante
                  if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow=empty then
                     if get_ingresso_from_id(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_ingresso_to_go_trajectory).get_polo_ingresso=range_1 then
                        if new_step+list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_distance_from_polo_percorrenza(get_ingresso_from_id(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_ingresso_to_go_trajectory),range_1)-get_larghezza_corsia-get_larghezza_marciapiede then
                           new_step:= get_distance_from_polo_percorrenza(get_ingresso_from_id(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_ingresso_to_go_trajectory),range_1)-get_larghezza_corsia-get_larghezza_marciapiede-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                        end if;
                     else
                        if new_step+list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_distance_from_polo_percorrenza(get_ingresso_from_id(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_ingresso_to_go_trajectory),range_1)+get_larghezza_corsia then
                           new_step:= get_distance_from_polo_percorrenza(get_ingresso_from_id(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_ingresso_to_go_trajectory),range_1)+get_larghezza_corsia-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                        end if;
                     end if;
                  else
                     if new_step+list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_urbana_from_id(id_task).get_lunghezza_road then
                        new_step:= get_urbana_from_id(id_task).get_lunghezza_road-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                     end if;
                  end if;

                  step_is_just_calculated:= False;

                  -- CONTROLLO per SALVAGUARDARSI DA POTENZIALI STALLI

                  dare_precedenza_to_uscite:= False;

                  new_distance:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step;

                  if validity_ingresso_same_direction then
                     -- costante_additiva modificata SOLO DAL SEGUENTE IF
                     if mezzo=bike then
                        costante_additiva:= min_bici_distance;
                     else
                        costante_additiva:= min_pedone_distance;
                     end if;

                     if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=distance_ingresso_same_direction-get_larghezza_corsia*2.0-get_larghezza_marciapiede-costante_additiva and
                       new_distance>=distance_ingresso_same_direction-get_larghezza_corsia*2.0-get_larghezza_marciapiede-costante_additiva then
                        declare
                           tmp_num_stalli_1: Natural:= 0;
                           trajectory: traiettoria_ingressi_type;
                           cur_from_begin: Boolean;
                           cur_int_bipedi: Boolean;
                           cur_int_corsie: traiettorie_intersezioni_linee_corsie;
                           ind_ingresso: Positive:= mailbox.get_key_ingresso(mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,current_ingressi_structure_type_to_consider),not_ordered);
                           how_wait: Positive;
                           must_stop: Boolean:= False;
                           lista_ab: ptr_list_posizione_abitanti_on_road;
                        begin
                           for j in 1..3 loop
                              if j=1 then
                                 trajectory:= entrata_andata;
                                 cur_from_begin:= True;
                                 cur_int_bipedi:= False;
                                 cur_int_corsie:= linea_corsia;
                                 how_wait:= max_num_stalli_entrata_cars_int_bipedi;
                              elsif j=2 then
                                 trajectory:= entrata_ritorno;
                                 cur_from_begin:= False;
                                 cur_int_bipedi:= True;
                                 cur_int_corsie:= linea_corsia;
                                 how_wait:= max_num_stalli_entrata_cars_int_bipedi;
                              else
                                 trajectory:= entrata_dritto_bici;
                                 cur_from_begin:= False;
                                 how_wait:= max_num_stalli_entrata_dritto_bipedi_from_fine;
                              end if;
                              if j=1 or j=2 then
                                 tmp_num_stalli_1:= mailbox.get_num_stalli_for_car_in_ingresso(trajectory,ind_ingresso,cur_from_begin,cur_int_bipedi,cur_int_corsie,False);
                              else
                                 tmp_num_stalli_1:= mailbox.get_num_stalli_for_bipedi_in_ingresso(trajectory,ind_ingresso,cur_from_begin);
                              end if;
                              if tmp_num_stalli_1>how_wait then
                                 must_stop:= True;
                              end if;
                           end loop;
                           if must_stop then
                              lista_ab:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,current_ingressi_structure_type_to_consider),entrata_andata);
                              if lista_ab/=null then
                                 mailbox.set_car_overtaken(True,lista_ab);
                              end if;
                              lista_ab:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,current_ingressi_structure_type_to_consider),entrata_ritorno);
                              if lista_ab/=null and then lista_ab.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_ingresso(entrata_ritorno).get_intersezione_bipedi then
                                 mailbox.set_car_overtaken(True,lista_ab);
                              end if;
                              for j in 1..2 loop
                                 if j=1 then
                                    lista_ab:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,current_ingressi_structure_type_to_consider),entrata_dritto_bici);
                                 else
                                    lista_ab:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,current_ingressi_structure_type_to_consider),entrata_dritto_pedoni);
                                 end if;
                                 while lista_ab/=null loop
                                    if (lista_ab.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_larghezza_corsia*4.0 and
                                          lista_ab.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia=False) and
                                      (lista_ab.get_next_from_list_posizione_abitanti=null) then
                                       -- SET_car in realtà sarebbe set_bipede
                                       mailbox.set_car_overtaken(True,lista_ab);
                                    end if;
                                    lista_ab:= lista_ab.get_next_from_list_posizione_abitanti;
                                 end loop;
                              end loop;
                              new_step:= distance_ingresso_same_direction-get_larghezza_corsia*2.0-get_larghezza_marciapiede-costante_additiva;
                              step_is_just_calculated:= True;
                              new_distance:= new_step;
                           end if;
                        end;
                     end if;

                     if (list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=distance_ingresso_same_direction-get_larghezza_corsia*2.0-get_larghezza_marciapiede and
                           list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede-costante_additiva) and
                       new_distance>=distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede-costante_additiva then
                        declare
                           ind_ingresso: Positive:= mailbox.get_key_ingresso(mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,current_ingressi_structure_type_to_consider),not_ordered);
                           must_stop: Boolean:= False;
                           lista_ab: ptr_list_posizione_abitanti_on_road;
                           tmp_num_stalli_1: Natural:= 0;
                           tmp_num_stalli_2: Natural:= 0;
                        begin
                           lista_ab:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,current_ingressi_structure_type_to_consider),uscita_andata);
                           tmp_num_stalli_1:= mailbox.get_num_stalli_for_car_in_ingresso(uscita_andata,ind_ingresso,True,False,linea_corsia,False);
                           if lista_ab/=null and then (lista_ab.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia or tmp_num_stalli_1>max_num_stalli_uscite_cars) then
                              must_stop:= True;
                           end if;
                           lista_ab:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,current_ingressi_structure_type_to_consider),uscita_ritorno);
                           tmp_num_stalli_1:= mailbox.get_num_stalli_for_car_in_ingresso(uscita_ritorno,ind_ingresso,True,False,linea_corsia,False);
                           if lista_ab/=null and then ((lista_ab.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia and lista_ab.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie) or tmp_num_stalli_1>max_num_stalli_uscite_cars) then
                              must_stop:= True;
                           end if;
                           tmp_num_stalli_1:= mailbox.get_num_stalli_for_bipedi_in_ingresso(uscita_destra_bici,ind_ingresso,False); -- or uscita_destra_pedoni
                           tmp_num_stalli_2:= mailbox.get_num_stalli_for_bipedi_in_ingresso(uscita_dritto_bici,ind_ingresso,True); -- or uscita_dritto_pedoni
                           if tmp_num_stalli_1>max_num_stalli_uscite_bipedi_from_begin or tmp_num_stalli_2>max_num_stalli_uscite_bipedi_from_begin then
                              must_stop:= True;
                           end if;
                           if must_stop then
                              new_step:= distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede-costante_additiva;
                              step_is_just_calculated:= True;
                              new_distance:= new_step;
                              dare_precedenza_to_uscite:= True; -- !!!!!!!!!!!!!!!!!!!!!!!!111
                           end if;
                        end;

                     end if;

                  end if;

                  if validity_ingresso_opposite_direction then
                     -- costante_additiva modificata SOLO DAL SEGUENTE IF
                     if mezzo=bike then
                        costante_additiva:= min_bici_distance;
                     else
                        costante_additiva:= min_pedone_distance;
                     end if;

                     if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=distance_ingresso_opposite_direction-get_larghezza_corsia*2.0-get_larghezza_marciapiede-costante_additiva and
                       new_distance>=distance_ingresso_opposite_direction-get_larghezza_corsia*2.0-get_larghezza_marciapiede-costante_additiva then
                        declare
                           ind_ingresso: Positive:= mailbox.get_key_ingresso(mailbox.get_index_ingresso_from_key(index_ingresso_opposite_direction,current_ingressi_structure_type_to_not_consider),not_ordered);
                           must_stop: Boolean:= False;
                           tmp_num_stalli_1: Natural:= 0;
                           tmp_num_stalli_2: Natural:= 0;
                        begin
                           tmp_num_stalli_1:= mailbox.get_num_stalli_for_bipedi_in_ingresso(uscita_ritorno_pedoni,ind_ingresso,False);
                           tmp_num_stalli_2:= mailbox.get_num_stalli_for_bipedi_in_ingresso(uscita_ritorno_bici,ind_ingresso,False);
                           if tmp_num_stalli_1>max_num_stalli_uscite_ritorno_bipedi then
                              must_stop:= True;
                           end if;
                           if tmp_num_stalli_2>max_num_stalli_uscite_ritorno_bipedi then
                              if mezzo=bike then
                                 must_stop:= True;
                              end if;
                           end if;
                           if must_stop then
                              new_step:= distance_ingresso_opposite_direction-get_larghezza_corsia*2.0-get_larghezza_marciapiede-costante_additiva;
                              new_distance:= new_step;
                              step_is_just_calculated:= True;
                           end if;
                        end;
                     end if;
                  end if;

                  mailbox.set_move_parameters_entity_on_sidewalk(mezzo,list_abitanti,range_1,new_speed,new_step,step_is_just_calculated);

                  if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti=list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti then
                     Put_Line("SAME POSITION ABITANTE id quartiere: " & Positive'Image(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                     get_log_stallo_quartiere.write_state_stallo(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,True);
                  else
                     get_log_stallo_quartiere.write_state_stallo(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,False);
                  end if;

                  if validity_ingresso_same_direction then
                     if range_1 then
                        current_ingressi_structure_type_to_consider:= ordered_polo_true;
                     else
                        current_ingressi_structure_type_to_consider:= ordered_polo_false;
                     end if;
                     if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow/=empty or else
                       list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_ingresso_to_go_trajectory/=mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,current_ingressi_structure_type_to_consider) then
                        list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,current_ingressi_structure_type_to_consider),entrata_ritorno);
                        if list_abitanti_on_traiettoria_ingresso=null or else list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_traiettoria_ingresso(entrata_ritorno).get_intersezione_bipedi then
                           if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<distance_ingresso_same_direction and (list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia*2.0-get_larghezza_marciapiede or else
                             list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia*2.0-get_larghezza_marciapiede) then
                              other_list:= null;
                              if mezzo=bike then
                                 other_list:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,current_ingressi_structure_type_to_consider),entrata_destra_bici);
                              else
                                 other_list:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,current_ingressi_structure_type_to_consider),entrata_destra_pedoni);
                              end if;
                              if other_list=null then
                                 if dare_precedenza_to_uscite then
                                    mailbox.abilita_attraversamento_cars_ingresso(False,range_1,index_ingresso_same_direction);
                                 else
                                    mailbox.disabilita_attraversamento_cars_ingresso(False,range_1,index_ingresso_same_direction);
                                 end if;
                              end if;
                           end if;
                        end if;
                        if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede then
                           mailbox.disabilita_attraversamento_cars_ingresso(True,range_1,index_ingresso_same_direction);
                        end if;
                     end if;
                  end if;

                  if mezzo=walking then
                     entity_length:= max_length_pedoni;
                  else
                     entity_length:= max_length_bici;
                  end if;

                  -- controllo se abitanti in traiettoria sinistra da incroci
                  -- possono essere inseriti in traiettoria bipedi
                  if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>get_urbana_from_id(id_task).get_lunghezza_road-entity_length*5.0 then
                     mailbox.abilitazione_sinistra_bipedi_in_incroci(range_1,mezzo,False);
                  end if;

                  if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti=get_urbana_from_id(id_task).get_lunghezza_road then
                     if get_quartiere_utilities_obj.get_classe_locate_abitanti(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_current_position(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti)/=1 then
                        get_quartiere_utilities_obj.get_classe_locate_abitanti(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).set_position_abitante_to_next(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                     end if;
                     tratto_incrocio:= get_quartiere_utilities_obj.get_classe_locate_abitanti(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_next(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                     ptr_rt_incrocio(get_id_incrocio_quartiere(tratto_incrocio.get_id_quartiere_tratto,tratto_incrocio.get_id_tratto)).insert_new_bipede(get_id_quartiere,id_task,posizione_abitanti_on_road(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti),mezzo,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow);

                     if tratto_incrocio.get_id_quartiere_tratto/=get_id_quartiere then
                        if mezzo=bike then
                           mailbox.add_entità_in_out_quartiere(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,mezzo,get_id_quartiere,id_task,1);
                        else
                           mailbox.add_entità_in_out_quartiere(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,mezzo,get_id_quartiere,id_task,2);
                        end if;
                     end if;

                  end if;

               else
                  -- eseguire spostamento degli abitanti dalle uscite degli ingressi
                  -- disabilita la validità
                  -- aggiornamento indici ingressi

                  if validity_ingresso_same_direction then
                     if mezzo=walking then
                        if prec_list_abitanti_sidewalk_pedoni/=null and then (prec_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede and then
                          prec_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=distance_ingresso_same_direction+get_larghezza_corsia) then
                           index_ingresso_same_direction:= index_ingresso_same_direction+1;
                        end if;
                     else
                        if prec_list_abitanti_sidewalk_bici/=null and then (prec_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede and then
                          prec_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=distance_ingresso_same_direction+get_larghezza_corsia) then
                           index_ingresso_same_direction:= index_ingresso_same_direction+1;
                        end if;
                     end if;

                     if index_ingresso_same_direction<=mailbox.get_ordered_ingressi_from_polo(range_1).all'Last then
                        validity_ingresso_same_direction:= True;
                        distance_ingresso_same_direction:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,current_ingressi_structure_type_to_consider)),range_1);
                     else
                        validity_ingresso_same_direction:= False;
                     end if;

                     while validity_ingresso_same_direction loop
                        if mezzo=walking then
                           if prec_list_abitanti_sidewalk_pedoni/=null then
                              if prec_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow/=empty or else
                                prec_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_ingresso_to_go_trajectory/=mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,current_ingressi_structure_type_to_consider) then
                                 list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,current_ingressi_structure_type_to_consider),entrata_ritorno);
                                 if list_abitanti_on_traiettoria_ingresso=null or else list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie+max_larghezza_veicolo*2.0 then
                                    if prec_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia*2.0-get_larghezza_marciapiede or else
                                      prec_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia*2.0-get_larghezza_marciapiede then
                                       mailbox.disabilita_attraversamento_cars_ingresso(False,range_1,index_ingresso_same_direction);
                                    end if;
                                 end if;
                                 if prec_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede then
                                    mailbox.disabilita_attraversamento_cars_ingresso(True,range_1,index_ingresso_same_direction);
                                 end if;
                              end if;
                           end if;
                        else
                           if prec_list_abitanti_sidewalk_bici/=null then
                              if prec_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow/=empty or else
                                prec_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_ingresso_to_go_trajectory/=mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,current_ingressi_structure_type_to_consider) then
                                 list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,current_ingressi_structure_type_to_consider),entrata_ritorno);
                                 if list_abitanti_on_traiettoria_ingresso=null or else list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie+max_larghezza_veicolo*2.0 then
                                    if prec_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia*2.0-get_larghezza_marciapiede or else
                                      prec_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia*2.0-get_larghezza_marciapiede then
                                       mailbox.disabilita_attraversamento_cars_ingresso(False,range_1,index_ingresso_same_direction);
                                    end if;
                                 end if;
                                 if prec_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia-get_larghezza_marciapiede then
                                    mailbox.disabilita_attraversamento_cars_ingresso(True,range_1,index_ingresso_same_direction);
                                 end if;
                              end if;
                           end if;
                        end if;

                        segnale:= True;
                        if mezzo=walking then
                           if prec_list_abitanti_sidewalk_pedoni/=null and then prec_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia*2.0-get_larghezza_marciapiede then
                              segnale:= False;
                           end if;
                           if prec_list_abitanti_sidewalk_bici/=null and then prec_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia*2.0-get_larghezza_marciapiede then
                              segnale:= False;
                           end if;
                        else
                           if prec_list_abitanti_sidewalk_bici/=null and then prec_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia*2.0-get_larghezza_marciapiede then
                              segnale:= False;
                           end if;
                           if prec_list_abitanti_sidewalk_pedoni/=null and then prec_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>distance_ingresso_same_direction-get_larghezza_corsia*2.0-get_larghezza_marciapiede then
                              segnale:= False;
                           end if;
                        end if;
                        if segnale=False then
                           mailbox.disabilita_attraversamento_bipedi_in_entrata_ingresso(range_1,index_ingresso_same_direction);
                        end if;

                        index_ingresso_same_direction:= index_ingresso_same_direction+1;
                        validity_ingresso_same_direction:= False;
                        if index_ingresso_same_direction<=mailbox.get_ordered_ingressi_from_polo(range_1).all'Last then
                           validity_ingresso_same_direction:= True;
                           distance_ingresso_same_direction:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,current_ingressi_structure_type_to_consider)),range_1);
                        end if;
                     end loop;

                  end if;

                  -- spostare eventualmente gli abitanti
                  -- mezzo contiene l'ultimo abitante della lista che è stato spostato
                  if validity_ingresso_opposite_direction then
                     if mezzo=walking then
                        if prec_list_abitanti_sidewalk_pedoni/=null and then (prec_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_opposite_direction-get_larghezza_corsia-get_larghezza_marciapiede and then
                          prec_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=distance_ingresso_opposite_direction+get_larghezza_corsia) then
                           index_ingresso_opposite_direction:= index_ingresso_opposite_direction-1;
                        end if;
                     else
                        if prec_list_abitanti_sidewalk_bici/=null and then (prec_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso_opposite_direction-get_larghezza_corsia-get_larghezza_marciapiede and then
                          prec_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=distance_ingresso_opposite_direction+get_larghezza_corsia) then
                           index_ingresso_opposite_direction:= index_ingresso_opposite_direction-1;
                        end if;
                     end if;

                     if index_ingresso_opposite_direction>0 then
                        validity_ingresso_opposite_direction:= True;
                     else
                        validity_ingresso_opposite_direction:= False;
                     end if;

                     -- aggiornamento indici ingressi
                     while validity_ingresso_opposite_direction loop
                        -- spostamento abitanti in uscita_ritorno_(bici/pedoni) TO DO
                        update_avanzamento_bipedi_in_uscita_ritorno(mailbox,list_abitanti_sidewalk_pedoni,list_abitanti_sidewalk_bici,prec_list_abitanti_sidewalk_pedoni,prec_list_abitanti_sidewalk_bici,mezzo,index_ingresso_opposite_direction,current_ingressi_structure_type_to_not_consider,range_1,id_task,null,null);
                        index_ingresso_opposite_direction:= index_ingresso_opposite_direction-1;
                        validity_ingresso_opposite_direction:= False;
                        if index_ingresso_opposite_direction>0 then
                           validity_ingresso_opposite_direction:= True;
                           distance_ingresso_opposite_direction:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(index_ingresso_opposite_direction,current_ingressi_structure_type_to_not_consider)),range_1);
                        end if;
                     end loop;
                  end if;
               end if;

               if list_abitanti/=null then
                  if mezzo=walking then
                     prec_list_abitanti_sidewalk_pedoni:= list_abitanti_sidewalk_pedoni;
                     list_abitanti_sidewalk_pedoni:= list_abitanti_sidewalk_pedoni.get_next_from_list_posizione_abitanti;
                     if list_abitanti_sidewalk_bici_is_set=False and then (init_list_abitanti_sidewalk_bici/=null and list_abitanti_sidewalk_bici=null) then
                        if list_abitanti_sidewalk_pedoni/=null and then list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<init_list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti then
                           null;
                        else
                           list_abitanti_sidewalk_bici:= init_list_abitanti_sidewalk_bici;
                           list_abitanti_sidewalk_bici_is_set:= True;
                        end if;
                     end if;
                  else
                     prec_list_abitanti_sidewalk_bici:= list_abitanti_sidewalk_bici;
                     list_abitanti_sidewalk_bici:= list_abitanti_sidewalk_bici.get_next_from_list_posizione_abitanti;
                     if list_abitanti_sidewalk_pedoni_is_set=False and then (init_list_abitanti_sidewalk_pedoni/=null and list_abitanti_sidewalk_pedoni=null) then
                        if list_abitanti_sidewalk_bici/=null and then list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<init_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti then
                           null;
                        else
                           list_abitanti_sidewalk_pedoni:= init_list_abitanti_sidewalk_pedoni;
                           list_abitanti_sidewalk_pedoni_is_set:= True;
                        end if;
                     end if;
                  end if;
               end if;

               if (validity_ingresso_opposite_direction=False and validity_ingresso_same_direction=False) and (list_abitanti_sidewalk_pedoni=null and list_abitanti_sidewalk_bici=null) then
                  switch:= False;
               end if;

            end loop;
         end loop;

         -- set flag overtake a True per i bipedi che da
         -- traiettoria uscita_dritto devono immettersi in uscita_ritorno

         -- il seguente pezzo di codice è stato commentato perchè già eseguito dal metodo update_avanzamento_bipedi_in_uscita_ritorno

         --for range_1 in False..True loop
         --   if range_1 then
         --      current_ingressi_structure_type_to_consider:= ordered_polo_false;
         --   else
         --      current_ingressi_structure_type_to_consider:= ordered_polo_true;
         --   end if;
         --   list_abitanti_sidewalk_bici:= mailbox.get_abitanti_to_move(sidewalk,range_1,1);
         --   list_abitanti_sidewalk_pedoni:= mailbox.get_abitanti_to_move(sidewalk,range_1,2);
         --   prec_list_abitanti_sidewalk_bici:= null;
         --   prec_list_abitanti_sidewalk_pedoni:= null;
         --   for k in reverse mailbox.get_ordered_ingressi_from_polo(not range_1).all'Range loop
         --      distance_ingresso_opposite_direction:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(k,current_ingressi_structure_type_to_consider)),range_1);
         --      while list_abitanti_sidewalk_bici/=null and then list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<distance_ingresso_opposite_direction-get_larghezza_corsia-get_larghezza_marciapiede loop
         --         prec_list_abitanti_sidewalk_bici:= list_abitanti_sidewalk_bici;
         --         list_abitanti_sidewalk_bici:= list_abitanti_sidewalk_bici.get_next_from_list_posizione_abitanti;
         --      end loop;

         --      while list_abitanti_sidewalk_pedoni/=null and then list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<distance_ingresso_opposite_direction-get_larghezza_corsia-get_larghezza_marciapiede loop
         --         prec_list_abitanti_sidewalk_pedoni:= list_abitanti_sidewalk_pedoni;
         --         list_abitanti_sidewalk_pedoni:= list_abitanti_sidewalk_pedoni.get_next_from_list_posizione_abitanti;
         --      end loop;

         --      segnale:= True; -- per le bici
         --      signal:= True; -- per i pedoni
         --      for j in 1..2 loop
         --         if j=1 then
         --            list_abitanti:= list_abitanti_sidewalk_bici;
         --            prec_abitante:= prec_list_abitanti_sidewalk_bici;
         --         else
         --            list_abitanti:= list_abitanti_sidewalk_pedoni;
         --            prec_abitante:= prec_list_abitanti_sidewalk_pedoni;
         --         end if;
         --         if list_abitanti/=null then
         --            if j=1 then
         --               entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
         --               costante_additiva:= min_bici_distance;
         --            else
         --               entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
         --               costante_additiva:= min_pedone_distance;
         --            end if;
         --         end if;
         --         if list_abitanti/=null and then list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length<distance_ingresso_opposite_direction-get_larghezza_corsia-costante_additiva then
         --            if j=1 then
         --               segnale:= False;
         --               signal:= False;
         --            else
         --               signal:= False;
         --            end if;
         --         end if;
         --         if prec_abitante/=null and then prec_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>distance_ingresso_opposite_direction-get_larghezza_corsia*2.5-get_larghezza_marciapiede then
         --            if j=1 then
         --               segnale:= False;
         --               signal:= False;
         --            else
         --               signal:= False;
         --            end if;
         --         end if;
         --      end loop;

         --      for j in 1..2 loop
         --         list_abitanti_on_traiettoria_ingresso:= null;
         --         if j=1 and signal then
         --            list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(k,current_ingressi_structure_type_to_consider),uscita_dritto_bici);
         --         elsif j=2 and segnale then
         --            list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(k,current_ingressi_structure_type_to_consider),uscita_dritto_pedoni);
         --         end if;
         --         while list_abitanti_on_traiettoria_ingresso/=null loop
         --            -- può essere scelta come traiettoria: uscita_dritto_bici o uscita_dritto_pedoni indifferentemente
         --            if list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(uscita_dritto_bici).get_lunghezza then
         --               mailbox.set_flag_abitante_can_overtake_to_next_corsia(list_abitanti_on_traiettoria_ingresso,True);
         --            end if;
         --            list_abitanti_on_traiettoria_ingresso:= list_abitanti_on_traiettoria_ingresso.get_next_from_list_posizione_abitanti;
         --         end loop;
         --      end loop;
         --         -- la flag può essere settata a True se si ha un abitante
         --   end loop;
         --end loop;


         for range_1 in False..True loop
            num_ingressi:= mailbox.get_num_ingressi_polo(range_1);
            if range_1 then
               current_ingressi_structure_type_to_consider:= ordered_polo_true;
            else
               current_ingressi_structure_type_to_consider:= ordered_polo_false;
            end if;
            for k in 1..num_ingressi loop
               if mailbox.get_abilitazione_attraversamento_in_entrata_ingresso(range_1,k) then
                  for h in 1..2 loop
                     stop_entity:= False;
                     if h=1 then
                        list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(k,current_ingressi_structure_type_to_consider),entrata_dritto_bici);
                        other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(k,current_ingressi_structure_type_to_consider),entrata_destra_bici);
                     else
                        list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(k,current_ingressi_structure_type_to_consider),entrata_dritto_pedoni);
                        other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(k,current_ingressi_structure_type_to_consider),entrata_destra_bici);
                        other_list:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(k,current_ingressi_structure_type_to_consider),entrata_destra_pedoni);
                     end if;
                     if h=1 and then other_list_abitanti/=null then
                        stop_entity:= True;
                     end if;
                     if h=2 and then (other_list_abitanti/=null or else other_list/=null) then
                        stop_entity:= True;
                     end if;
                     if stop_entity=False then
                        while list_abitanti_on_traiettoria_ingresso/=null loop
                           if list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_larghezza_corsia*4.0 then
                              if list_abitanti_on_traiettoria_ingresso.get_next_from_list_posizione_abitanti=null or else list_abitanti_on_traiettoria_ingresso.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_larghezza_corsia*4.0 then
                                 mailbox.set_flag_abitante_can_overtake_to_next_corsia(list_abitanti_on_traiettoria_ingresso,True);
                              end if;
                           end if;
                           list_abitanti_on_traiettoria_ingresso:= list_abitanti_on_traiettoria_ingresso.get_next_from_list_posizione_abitanti;
                        end loop;
                     end if;
                  end loop;
               end if;
            end loop;
         end loop;

         current_polo_to_consider:= False;

         for h in 1..2 loop
            --corsia_destra:= mailbox.get_abitanti_on_road(current_polo_to_consider,2);
            --corsia_sinistra:= mailbox.get_abitanti_on_road(current_polo_to_consider,1);

            corsia_destra:= mailbox.slide_list_road(current_polo_to_consider,2,mailbox.get_number_entity_on_road(current_polo_to_consider,2));
            if mailbox.get_number_entity_on_road(current_polo_to_consider,2)>0 and (corsia_destra=null or else corsia_destra.get_next_from_list_posizione_abitanti/=null) then
               Put_Line("numero elementi: " & Positive'Image(mailbox.get_number_entity_on_road(current_polo_to_consider,2)));
               list_abitanti:= mailbox.get_abitanti_to_move(road,current_polo_to_consider,2);
               next_id_abitante:= 0;
               while list_abitanti/=null loop
                  ab:= posizione_abitanti_on_road(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti);
                  next_id_abitante:= next_id_abitante+1;
                  list_abitanti:= list_abitanti.get_next_from_list_posizione_abitanti;
               end loop;
               Put_Line("numero abitanti in lista: " & Positive'Image(next_id_abitante));
               raise other_error;
            end if;
            corsia_sinistra:= mailbox.slide_list_road(current_polo_to_consider,1,mailbox.get_number_entity_on_road(current_polo_to_consider,1));
            if mailbox.get_number_entity_on_road(current_polo_to_consider,1)>0 and (corsia_sinistra=null or else corsia_sinistra.get_next_from_list_posizione_abitanti/=null) then
               Put_Line("numero elementi: " & Positive'Image(mailbox.get_number_entity_on_road(current_polo_to_consider,1)));
               list_abitanti:= mailbox.get_abitanti_to_move(road,current_polo_to_consider,1);
               next_id_abitante:= 0;
               while list_abitanti/=null loop
                  ab:= posizione_abitanti_on_road(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti);
                  next_id_abitante:= next_id_abitante+1;
                  list_abitanti:= list_abitanti.get_next_from_list_posizione_abitanti;
               end loop;
               Put_Line("numero abitanti in lista: " & Positive'Image(next_id_abitante));
               raise other_error;
            end if;

            index_ingresso_same_direction:= mailbox.get_num_ingressi_polo(current_polo_to_consider);
            index_ingresso_opposite_direction:= 0;

            if current_polo_to_consider then
               current_ingressi_structure_type_to_consider:= ordered_polo_true;
               current_ingressi_structure_type_to_not_consider:= ordered_polo_false;
            else
               current_ingressi_structure_type_to_consider:= ordered_polo_false;
               current_ingressi_structure_type_to_not_consider:= ordered_polo_true;
            end if;

            if mailbox.get_num_ingressi_polo(not current_polo_to_consider)>0 then
               index_ingresso_opposite_direction:= 1;
            end if;

            for i in 1..(mailbox.get_number_entity_on_road(current_polo_to_consider,1)+mailbox.get_number_entity_on_road(current_polo_to_consider,2)) loop
               -- cerco la prima macchina tra le 2 liste


               first_corsia:= 0;
               other_corsia:= 0;
               current_car_in_corsia:= null;
               next_car_in_corsia:= null;
               next_car_in_opposite_corsia:= null;
               if corsia_destra/=null and corsia_sinistra/=null then
                  if corsia_destra.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=corsia_sinistra.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti then
                     first_corsia:= 2;
                     other_corsia:= 1;
                     current_car_in_corsia:= corsia_destra;
                     next_car_in_corsia:= corsia_destra.get_next_from_list_posizione_abitanti;
                     next_car_in_opposite_corsia:= calculate_next_car_in_opposite_corsia(corsia_destra,mailbox.get_abitanti_to_move(road,current_polo_to_consider,1));
                     corsia_destra:= corsia_destra.get_prev_from_list_posizione_abitanti;
                  else
                     first_corsia:= 1;
                     other_corsia:= 2;
                     current_car_in_corsia:= corsia_sinistra;
                     next_car_in_corsia:= corsia_sinistra.get_next_from_list_posizione_abitanti;
                     next_car_in_opposite_corsia:= calculate_next_car_in_opposite_corsia(corsia_sinistra,mailbox.get_abitanti_to_move(road,current_polo_to_consider,2));
                     corsia_sinistra:= corsia_sinistra.get_prev_from_list_posizione_abitanti;
                  end if;
               else
                  if corsia_destra/=null and corsia_sinistra=null then
                     first_corsia:= 2;
                     other_corsia:= 1;
                     current_car_in_corsia:= corsia_destra;
                     next_car_in_corsia:= corsia_destra.get_next_from_list_posizione_abitanti;
                     next_car_in_opposite_corsia:= calculate_next_car_in_opposite_corsia(corsia_destra,mailbox.get_abitanti_to_move(road,current_polo_to_consider,1));
                     corsia_destra:= corsia_destra.get_prev_from_list_posizione_abitanti;
                  elsif corsia_destra=null and corsia_sinistra/=null then
                     first_corsia:= 1;
                     other_corsia:= 2;
                     current_car_in_corsia:= corsia_sinistra;
                     next_car_in_corsia:= corsia_sinistra.get_next_from_list_posizione_abitanti;
                     next_car_in_opposite_corsia:= calculate_next_car_in_opposite_corsia(corsia_sinistra,mailbox.get_abitanti_to_move(road,current_polo_to_consider,2));
                     corsia_sinistra:= corsia_sinistra.get_prev_from_list_posizione_abitanti;
                  else
                     null; -- NOOP
                  end if;
               end if;

               distance_to_stop_line:= 0.0;
               next_entity_distance:= 0.0;
               can_not_overtake_now:= False;
               abilita_limite_overtaken:= False;
               step_is_just_calculated:= False;

               distance_ingresso_same_direction:= -1.0;
               distance_ingresso_opposite_direction:= -1.0;
               validity_ingresso_same_direction:= False;
               validity_ingresso_opposite_direction:= False;

               if index_ingresso_same_direction>0 then
                  distance_ingresso_same_direction:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(index_ingresso_same_direction,current_ingressi_structure_type_to_consider)),current_polo_to_consider);
                  validity_ingresso_same_direction:= True;
               end if;
               if index_ingresso_opposite_direction>0 and then index_ingresso_opposite_direction<=mailbox.get_num_ingressi_polo(not current_polo_to_consider) then
                  distance_ingresso_opposite_direction:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(index_ingresso_opposite_direction,current_ingressi_structure_type_to_not_consider)),current_polo_to_consider);
                  validity_ingresso_opposite_direction:= True;
               end if;

               -- distance_last_ingresso vale True se l'ingresso più in fondo è nello stesso polo
               --                        vale False altrimenti
               if validity_ingresso_same_direction and validity_ingresso_opposite_direction then
                  if distance_ingresso_same_direction>distance_ingresso_opposite_direction then
                     distance_last_ingresso:= True;
                  else
                     distance_last_ingresso:= False;
                  end if;
               elsif validity_ingresso_same_direction then
                  distance_last_ingresso:= True;
               elsif validity_ingresso_opposite_direction then
                  distance_last_ingresso:= False;
               end if;

               --abitante_in_transizione:= mailbox.get_abitante_in_transizione_da_incrocio(car,current_polo_to_consider,first_corsia);

               if first_corsia/=0 and then current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_urbana_from_id(id_task).get_lunghezza_road then --and then (abitante_in_transizione.get_id_abitante_posizione_abitanti/=current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti and abitante_in_transizione.get_id_quartiere_posizione_abitanti/=current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti)) then
                  -- elaborazione corsia to go;    first_corsia è la corsia in cui la macchina è situata
                  Put_Line("id_abitante " & Positive'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & new_float'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is urbana " & Positive'Image(id_task) & " corsia" & Positive'Image(first_corsia) & " polo " & Boolean'Image(current_polo_to_consider) & " quartiere" & Positive'Image(get_id_quartiere));
                  -- Put_Line("id_abitante overtaking " & Float'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory));
                  if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=629.0 and (current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti=180) then
                     stop_entity:= False;
                  end if;
                  --if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti=168 and (current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=646.0 and (id_task=16 and (current_polo_to_consider=True and (first_corsia=2 and (True))))) then
                  --   stop_entity:= False;
                  --end if;

                  length_car_on_road:= get_quartiere_utilities_obj.get_auto_quartiere(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;

                  -- BEGIN CONTROLLO SE IL SEMAFORO È VERDE
                  semaforo_is_verde:= False;
                  if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow/=empty then
                     if get_quartiere_utilities_obj.get_classe_locate_abitanti(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_current_position(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti)=1 then
                        tratto_incrocio:= get_quartiere_utilities_obj.get_classe_locate_abitanti(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_next(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                     else
                        tratto_incrocio:= get_quartiere_utilities_obj.get_classe_locate_abitanti(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_next_incrocio(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                     end if;
                     Put_Line("quartiere:" & Positive'Image(tratto_incrocio.get_id_quartiere_tratto) & " tratto " & Positive'Image(tratto_incrocio.get_id_tratto) & " quartiere ab " & Positive'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " id ab " & Positive'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
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
                     minus:= get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                     if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory/=first_corsia then
                        if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken=False then -- macchina non in sorpasso
                           bound_to_overtake:= calculate_bound_to_overtake(current_car_in_corsia,current_polo_to_consider,id_task);
                           if bound_to_overtake=0.0 then -- necessario sorpassare subito
                              Put_Line("buond to overtake: " & Positive'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                              stop_entity:= not mailbox.car_can_overtake_on_first_step_trajectory(current_car_in_corsia,current_polo_to_consider,first_corsia,True);
                              --stop_entity:= not mailbox.car_can_initiate_overtaken_on_road(current_car_in_corsia,current_polo_to_consider,first_corsia,True);
                              mailbox.set_car_overtaken(True,current_car_in_corsia);
                              if stop_entity=False and mailbox.complete_trajectory_on_same_corsia_is_free(current_car_in_corsia,current_polo_to_consider,first_corsia) then
                                 abilita_limite_overtaken:= not mailbox.car_can_overtake_on_second_step_trajectory(current_car_in_corsia,current_polo_to_consider,first_corsia);
                                 -- COMMENTED:
                                 --mailbox.set_car_overtaken(True,current_car_in_corsia);
                                 traiettoria_rimasta_da_percorrere:= get_traiettoria_cambio_corsia.get_lunghezza_traiettoria;
                                 distance_to_stop_line:= calculate_distance_to_stop_line_from_entity_on_road(current_car_in_corsia,current_polo_to_consider,id_task);
                                 distance_to_stop_line:= distance_to_stop_line+traiettoria_rimasta_da_percorrere-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                                 next_car_in_ingresso_distance:= mailbox.calculate_distance_to_next_ingressi(current_polo_to_consider,destination.get_corsia_to_go_trajectory,current_car_in_corsia);
                                 calculate_distance_to_next_car_on_road(current_car_in_corsia,next_car_in_opposite_corsia,next_car_in_corsia,current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory,next_car_on_road,next_car_on_road_distance);
                                 next_entity_distance:= calculate_next_entity_distance(current_car_in_corsia,next_car_in_ingresso_distance,next_car_on_road,next_car_on_road_distance,id_task,next_entity_is_ingresso,tmp_next_entity_distance);
                                 if next_entity_distance/=0.0 then
                                    next_entity_distance:= next_entity_distance+traiettoria_rimasta_da_percorrere-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                                 end if;
                              else
                                 stop_entity:= True;
                              end if;
                           else  -- valutare se sorpassare
                                 -- FIRST: controllare se il sorpasso può essere effettuato
                                 -- la macchina se si trova dentro un incrocio tra ingressi e l'ingresso non è occupato allora ok
                                 -- car_can_initiate_overtaken(current_car_in_corsia,current_polo_to_consider,first_corsia)
                              can_overtake:= True;
                              if first_corsia=2 then
                                 prec_abitante_other_corsia:= corsia_sinistra;
                              else
                                 prec_abitante_other_corsia:= corsia_destra;
                              end if;
                              if prec_abitante_other_corsia=null or else ((prec_abitante_other_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken and then (prec_abitante_other_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory=other_corsia and then (prec_abitante_other_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-safe_distance_to_overtake)))
                                                                          or else (prec_abitante_other_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken=False and then (current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-length_car_on_road>=prec_abitante_other_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+safe_distance_to_overtake))) then
                                 -- l'abitante precedente se cè è a distanza maggiore di safe_distance_to_overtake
                                 next_abitante:= current_car_in_corsia.get_next_from_list_posizione_abitanti;
                                 while next_abitante/=null and then (next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken and next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory=other_corsia) loop
                                    -- l'abitante successivo sta andando verso other_corsia
                                    next_abitante:= next_abitante.get_next_from_list_posizione_abitanti;
                                 end loop;

                                 next_abitante_other_corsia:= mailbox.get_next_abitante_in_corsia(other_corsia,current_polo_to_consider,current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti);
                                 -- se next_abitante_other_corsia=null l'abitante può sorpassare
                                 if next_abitante_other_corsia/=null then
                                    if next_abitante=null then
                                       -- davanti non hai nessuno, cambi corsia per bound_overtaken
                                       if bound_to_overtake>bound_to_change_corsia*3.0 then
                                          can_overtake:= False;
                                       end if;
                                    else
                                       -- esiste una macchina sia davanti che nella corsia opposta
                                       if bound_to_overtake>bound_to_change_corsia*3.0 then
                                          can_overtake:= there_are_conditions_to_overtake(next_abitante,next_abitante_other_corsia,current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti,False);
                                       end if;
                                    end if;
                                 end if;
                              else
                                 if prec_abitante_other_corsia/=null then
                                    can_overtake:= False;
                                 end if;
                              end if;
                              stop_entity:= True;
                              if can_overtake and then current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-length_car_on_road>get_larghezza_corsia+get_larghezza_marciapiede then  -- ovvero per sorpassare occorre aver superato di 10.0 la distanza dall'incrocio
                                 if mailbox.there_are_cars_moving_across_next_ingressi(current_car_in_corsia,current_polo_to_consider)=False then  -- può sorpassare
                                    stop_entity:= not mailbox.car_can_overtake_on_first_step_trajectory(current_car_in_corsia,current_polo_to_consider,first_corsia,False);
                                    if stop_entity=False then
                                       stop_entity:= not mailbox.car_can_overtake_on_second_step_trajectory(current_car_in_corsia,current_polo_to_consider,first_corsia);
                                    end if;
                                    if stop_entity=False and mailbox.complete_trajectory_on_same_corsia_is_free(current_car_in_corsia,current_polo_to_consider,first_corsia) then
                                       mailbox.set_car_overtaken(True,current_car_in_corsia);
                                       traiettoria_rimasta_da_percorrere:= get_traiettoria_cambio_corsia.get_lunghezza_traiettoria;
                                       distance_to_stop_line:= calculate_distance_to_stop_line_from_entity_on_road(current_car_in_corsia,current_polo_to_consider,id_task);
                                       distance_to_stop_line:= distance_to_stop_line+traiettoria_rimasta_da_percorrere-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                                       next_car_in_ingresso_distance:= mailbox.calculate_distance_to_next_ingressi(current_polo_to_consider,destination.get_corsia_to_go_trajectory,current_car_in_corsia);
                                       calculate_distance_to_next_car_on_road(current_car_in_corsia,next_car_in_opposite_corsia,next_car_in_corsia,current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory,next_car_on_road,next_car_on_road_distance);
                                       next_entity_distance:= calculate_next_entity_distance(current_car_in_corsia,next_car_in_ingresso_distance,next_car_on_road,next_car_on_road_distance,id_task,next_entity_is_ingresso,tmp_next_entity_distance);
                                       if next_entity_distance/=0.0 then
                                          next_entity_distance:= next_entity_distance+traiettoria_rimasta_da_percorrere-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                                       end if;
                                    else
                                       stop_entity:= True;
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
                                 next_entity_distance:= calculate_next_entity_distance(current_car_in_corsia,next_car_in_ingresso_distance,next_car_on_road,next_car_on_road_distance,id_task,next_entity_is_ingresso,tmp_next_entity_distance);
                              end if;
                           end if;
                           speed_abitante:= current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                           if stop_entity=False then
                              if (next_car_on_road/=null and (next_car_in_ingresso_distance=-1.0 or else next_entity_is_ingresso=False)) then
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
                                 acceleration:= calculate_acceleration(mezzo => car,
                                                              id_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                              id_quartiere_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                              next_entity_distance => next_entity_distance,
                                                              distance_to_stop_line => distance_to_stop_line+add_factor,
                                                              next_id_quartiere_abitante => 0,
                                                              next_id_abitante => 0,
                                                              abitante_velocity => speed_abitante,
                                                              next_abitante_velocity =>0.0);
                              end if;
                           end if;
                        else -- macchina in sorpasso, occorre avanzarla
                           bound_to_overtake:= calculate_bound_to_overtake(current_car_in_corsia,current_polo_to_consider,id_task);
                           if bound_to_overtake=0.0 then
                              if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory=0.0 then
                                 stop_entity:= not mailbox.car_can_overtake_on_first_step_trajectory(current_car_in_corsia,current_polo_to_consider,first_corsia,True) and mailbox.complete_trajectory_on_same_corsia_is_free(current_car_in_corsia,current_polo_to_consider,first_corsia);
                              end if;
                              abilita_limite_overtaken:= not mailbox.car_can_overtake_on_second_step_trajectory(current_car_in_corsia,current_polo_to_consider,first_corsia);
                           end if;
                           if stop_entity=False then
                              traiettoria_rimasta_da_percorrere:= get_traiettoria_cambio_corsia.get_lunghezza_traiettoria-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory;
                              if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_backup_corsia_to_go/=destination.get_corsia_to_go_trajectory then
                                 distance_to_stop_line:= bound_to_overtake;
                                 can_not_overtake_now:= True;
                              else
                                 distance_to_stop_line:= calculate_distance_to_stop_line_from_entity_on_road(current_car_in_corsia,current_polo_to_consider,id_task);
                              end if;
                              distance_to_stop_line:= distance_to_stop_line+traiettoria_rimasta_da_percorrere-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                              next_car_in_ingresso_distance:= mailbox.calculate_distance_to_next_ingressi(current_polo_to_consider,destination.get_corsia_to_go_trajectory,current_car_in_corsia);
                              calculate_distance_to_next_car_on_road(current_car_in_corsia,next_car_in_opposite_corsia,next_car_in_corsia,destination.get_corsia_to_go_trajectory,next_car_on_road,next_car_on_road_distance);
                              next_entity_distance:= calculate_next_entity_distance(current_car_in_corsia,next_car_in_ingresso_distance,next_car_on_road,next_car_on_road_distance,id_task,next_entity_is_ingresso,tmp_next_entity_distance);
                              if next_entity_distance/=0.0 then
                                 next_entity_distance:= next_entity_distance+traiettoria_rimasta_da_percorrere-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                              end if;
                              speed_abitante:= current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                              if next_car_on_road/=null and (next_car_in_ingresso_distance=-1.0 or else next_entity_is_ingresso=False) then
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
                                 acceleration:= calculate_acceleration(mezzo => car,
                                                                       id_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                                       id_quartiere_abitante => current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                       next_entity_distance => next_entity_distance,
                                                                       distance_to_stop_line => distance_to_stop_line+add_factor,
                                                                       next_id_quartiere_abitante => 0,
                                                                       next_id_abitante => 0,
                                                                       abitante_velocity => speed_abitante,
                                                                       next_abitante_velocity => 0.0);
                              end if;
                           end if;
                        end if;
                     else -- la macchina è nella corsia giusta
                        if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken=True then -- macchina in sorpasso
                           traiettoria_rimasta_da_percorrere:= get_traiettoria_cambio_corsia.get_lunghezza_traiettoria-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory;
                           if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_backup_corsia_to_go/=destination.get_corsia_to_go_trajectory then
                              distance_to_stop_line:= calculate_bound_to_overtake(current_car_in_corsia,current_polo_to_consider,id_task);
                              semaforo_is_verde:= False;
                              can_not_overtake_now:= True;
                           else
                              distance_to_stop_line:= calculate_distance_to_stop_line_from_entity_on_road(current_car_in_corsia,current_polo_to_consider,id_task);
                           end if;
                           distance_to_stop_line:= distance_to_stop_line+traiettoria_rimasta_da_percorrere-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                           next_car_in_ingresso_distance:= mailbox.calculate_distance_to_next_ingressi(current_polo_to_consider,first_corsia,current_car_in_corsia);
                           calculate_distance_to_next_car_on_road(current_car_in_corsia,next_car_in_corsia,next_car_in_opposite_corsia,destination.get_corsia_to_go_trajectory,next_car_on_road,next_car_on_road_distance);
                           next_entity_distance:= calculate_next_entity_distance(current_car_in_corsia,next_car_in_ingresso_distance,next_car_on_road,next_car_on_road_distance,id_task,next_entity_is_ingresso,tmp_next_entity_distance);
                           if next_entity_distance/=0.0 then
                              next_entity_distance:= next_entity_distance+traiettoria_rimasta_da_percorrere-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                           end if;
                           speed_abitante:= current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                        else
                           distance_to_stop_line:= calculate_distance_to_stop_line_from_entity_on_road(current_car_in_corsia,current_polo_to_consider,id_task);
                           next_car_in_ingresso_distance:= mailbox.calculate_distance_to_next_ingressi(current_polo_to_consider,first_corsia,current_car_in_corsia);
                           calculate_distance_to_next_car_on_road(current_car_in_corsia,next_car_in_corsia,next_car_in_opposite_corsia,first_corsia,next_car_on_road,next_car_on_road_distance);
                           next_entity_distance:= calculate_next_entity_distance(current_car_in_corsia,next_car_in_ingresso_distance,next_car_on_road,next_car_on_road_distance,id_task,next_entity_is_ingresso,tmp_next_entity_distance);
                           traiettoria_rimasta_da_percorrere:= 0.0;
                           if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_backup_corsia_to_go/=first_corsia then
                              -- l'abitante è in "fase di sorpasso" ovvero deve rientrare nella corsia giusta
                              bound_to_overtake:= calculate_bound_to_overtake(current_car_in_corsia,current_polo_to_consider,id_task);
                              if bound_to_overtake=0.0 then -- necessario sorpassare subito
                                 Put_Line("buond to overtake: " & Positive'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                                 stop_entity:= not mailbox.car_can_overtake_on_first_step_trajectory(current_car_in_corsia,current_polo_to_consider,first_corsia,True);
                                 --stop_entity:= not mailbox.car_can_initiate_overtaken_on_road(current_car_in_corsia,current_polo_to_consider,first_corsia,True);
                                 -- ADDED:
                                 mailbox.set_car_overtaken(True,current_car_in_corsia);
                                 mailbox.update_abitante_destination(current_car_in_corsia,create_trajectory_to_follow(first_corsia,other_corsia,destination.get_ingresso_to_go_trajectory,destination.get_from_ingresso,destination.get_traiettoria_incrocio_to_follow));
                                 if stop_entity=False and mailbox.complete_trajectory_on_same_corsia_is_free(current_car_in_corsia,current_polo_to_consider,first_corsia) then
                                    abilita_limite_overtaken:= not mailbox.car_can_overtake_on_second_step_trajectory(current_car_in_corsia,current_polo_to_consider,first_corsia);
                                    -- COMMENTED:
                                    --mailbox.set_car_overtaken(True,current_car_in_corsia);
                                    --mailbox.update_abitante_destination(current_car_in_corsia,create_trajectory_to_follow(first_corsia,other_corsia,destination.get_ingresso_to_go_trajectory,destination.get_from_ingresso,destination.get_traiettoria_incrocio_to_follow));
                                    traiettoria_rimasta_da_percorrere:= get_traiettoria_cambio_corsia.get_lunghezza_traiettoria;
                                    distance_to_stop_line:= distance_to_stop_line+traiettoria_rimasta_da_percorrere-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                                    next_car_in_ingresso_distance:= mailbox.calculate_distance_to_next_ingressi(current_polo_to_consider,other_corsia,current_car_in_corsia);
                                    calculate_distance_to_next_car_on_road(current_car_in_corsia,next_car_in_opposite_corsia,next_car_in_corsia,other_corsia,next_car_on_road,next_car_on_road_distance);
                                    next_entity_distance:= calculate_next_entity_distance(current_car_in_corsia,next_car_in_ingresso_distance,next_car_on_road,next_car_on_road_distance,id_task,next_entity_is_ingresso,tmp_next_entity_distance);
                                    if next_entity_distance/=0.0 then
                                       next_entity_distance:= next_entity_distance+traiettoria_rimasta_da_percorrere-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                                    end if;
                                 else
                                    stop_entity:= True;
                                 end if;
                              else  -- valutare se sorpassare
                                 -- SEMAFORO_IS_VERDE:= FALSE per disabilitare i controlli all'incrocio dato che non ci arriverà
                                 -- dalla corsia in cui ora è stato messo
                                 semaforo_is_verde:= False;
                                 distance_to_stop_line:= bound_to_overtake;
                                 -- viene settato per assicurarsi che il bound overtake non venga superato
                                 can_not_overtake_now:= True;
                                 next_abitante_other_corsia:= mailbox.get_next_abitante_in_corsia(other_corsia,current_polo_to_consider,current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti);
                                 if first_corsia=2 then
                                    prec_abitante_other_corsia:= corsia_sinistra;
                                 else
                                    prec_abitante_other_corsia:= corsia_destra;
                                 end if;
                                 if prec_abitante_other_corsia=null or else ((prec_abitante_other_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken and then (prec_abitante_other_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory=other_corsia and then (prec_abitante_other_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-safe_distance_to_overtake)))
                                                                             or else (prec_abitante_other_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken=False and then (current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-length_car_on_road>=prec_abitante_other_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+safe_distance_to_overtake))) then
                                    can_overtake:= True;
                                 else
                                    can_overtake:= False;
                                 end if;
                                 if can_overtake and then next_abitante_other_corsia/=null then
                                    can_overtake:= there_are_conditions_to_overtake(current_car_in_corsia,next_abitante_other_corsia,current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti,True);
                                    if can_overtake then
                                       if mailbox.there_are_cars_moving_across_next_ingressi(current_car_in_corsia,current_polo_to_consider)=False then  -- può sorpassare
                                          can_overtake:= mailbox.car_can_overtake_on_first_step_trajectory(current_car_in_corsia,current_polo_to_consider,first_corsia,False);
                                          if can_overtake=True then
                                             can_overtake:= mailbox.car_can_overtake_on_second_step_trajectory(current_car_in_corsia,current_polo_to_consider,first_corsia);
                                          end if;
                                          if can_overtake=True and mailbox.complete_trajectory_on_same_corsia_is_free(current_car_in_corsia,current_polo_to_consider,first_corsia) then
                                             mailbox.set_car_overtaken(True,current_car_in_corsia);
                                             mailbox.update_abitante_destination(current_car_in_corsia,create_trajectory_to_follow(first_corsia,other_corsia,destination.get_ingresso_to_go_trajectory,destination.get_from_ingresso,destination.get_traiettoria_incrocio_to_follow));
                                             traiettoria_rimasta_da_percorrere:= get_traiettoria_cambio_corsia.get_lunghezza_traiettoria;
                                             distance_to_stop_line:= distance_to_stop_line+traiettoria_rimasta_da_percorrere-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                                             next_car_in_ingresso_distance:= mailbox.calculate_distance_to_next_ingressi(current_polo_to_consider,other_corsia,current_car_in_corsia);
                                             calculate_distance_to_next_car_on_road(current_car_in_corsia,next_car_in_opposite_corsia,next_car_in_corsia,other_corsia,next_car_on_road,next_car_on_road_distance);
                                             next_entity_distance:= calculate_next_entity_distance(current_car_in_corsia,next_car_in_ingresso_distance,next_car_on_road,next_car_on_road_distance,id_task,next_entity_is_ingresso,tmp_next_entity_distance);
                                             if next_entity_distance/=0.0 then
                                                next_entity_distance:= next_entity_distance+traiettoria_rimasta_da_percorrere-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                                             end if;
                                          end if;
                                       end if;
                                    end if;
                                 elsif can_overtake then
                                    -- davanti non si ha nessuno si può sorpassare
                                    if mailbox.there_are_cars_moving_across_next_ingressi(current_car_in_corsia,current_polo_to_consider)=False then  -- può sorpassare
                                       can_overtake:= mailbox.car_can_overtake_on_first_step_trajectory(current_car_in_corsia,current_polo_to_consider,first_corsia,False);
                                       if can_overtake=True then
                                          can_overtake:= mailbox.car_can_overtake_on_second_step_trajectory(current_car_in_corsia,current_polo_to_consider,first_corsia);
                                       end if;
                                       if can_overtake=True and mailbox.complete_trajectory_on_same_corsia_is_free(current_car_in_corsia,current_polo_to_consider,first_corsia) then
                                          mailbox.set_car_overtaken(True,current_car_in_corsia);
                                          mailbox.update_abitante_destination(current_car_in_corsia,create_trajectory_to_follow(first_corsia,other_corsia,destination.get_ingresso_to_go_trajectory,destination.get_from_ingresso,destination.get_traiettoria_incrocio_to_follow));
                                          traiettoria_rimasta_da_percorrere:= get_traiettoria_cambio_corsia.get_lunghezza_traiettoria;
                                          distance_to_stop_line:= distance_to_stop_line+traiettoria_rimasta_da_percorrere-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                                          next_car_in_ingresso_distance:= mailbox.calculate_distance_to_next_ingressi(current_polo_to_consider,other_corsia,current_car_in_corsia);
                                          calculate_distance_to_next_car_on_road(current_car_in_corsia,next_car_in_opposite_corsia,next_car_in_corsia,other_corsia,next_car_on_road,next_car_on_road_distance);
                                          next_entity_distance:= calculate_next_entity_distance(current_car_in_corsia,next_car_in_ingresso_distance,next_car_on_road,next_car_on_road_distance,id_task,next_entity_is_ingresso,tmp_next_entity_distance);
                                          if next_entity_distance/=0.0 then
                                             next_entity_distance:= next_entity_distance+traiettoria_rimasta_da_percorrere-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                                          end if;
                                       end if;
                                    end if;
                                 end if;
                              end if;
                           elsif destination.get_ingresso_to_go_trajectory=0 and then (next_car_on_road/=null and then (next_car_in_ingresso_distance=-1.0 or else next_entity_is_ingresso=False)) then
                              -- l'abitante si trova nella corsia giusta, valuta se è il caso di sorpassare
                              -- BEGIN VALUTAZIONE DI SORPASSO
                              if distance_to_stop_line>=bound_to_change_corsia*7.0 and then current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-length_car_on_road>get_larghezza_corsia+get_larghezza_marciapiede then
                                 can_overtake:= True;
                                 next_abitante:= current_car_in_corsia.get_next_from_list_posizione_abitanti;
                                 while next_abitante/=null and then (next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken and next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory=other_corsia) loop
                                    -- l'abitante successivo sta andando verso other_corsia
                                    next_abitante:= next_abitante.get_next_from_list_posizione_abitanti;
                                 end loop;
                                 if next_abitante/=null and then next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=distance_at_witch_can_be_thinked_overtake then -- se non è null allora ha senso parlare di sorpasso
                                    next_abitante_other_corsia:= mailbox.get_next_abitante_in_corsia(other_corsia,current_polo_to_consider,current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti);
                                    if first_corsia=2 then
                                       prec_abitante_other_corsia:= corsia_sinistra;
                                    else
                                       prec_abitante_other_corsia:= corsia_destra;
                                    end if;
                                    if prec_abitante_other_corsia=null or else ((prec_abitante_other_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken and then (prec_abitante_other_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory=other_corsia and then (prec_abitante_other_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-safe_distance_to_overtake)))
                                                                             or else (prec_abitante_other_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken=False and then (current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-length_car_on_road>=prec_abitante_other_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+safe_distance_to_overtake))) then
                                       can_overtake:= True;
                                    else
                                       can_overtake:= False;
                                    end if;
                                    if can_overtake and then next_abitante_other_corsia/=null then
                                       can_overtake:= there_are_conditions_to_overtake(next_abitante,next_abitante_other_corsia,current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti,False);
                                    end if;
                                    if can_overtake then
                                       if mailbox.there_are_cars_moving_across_next_ingressi(current_car_in_corsia,current_polo_to_consider)=False then  -- può sorpassare
                                          can_overtake:= not mailbox.car_can_overtake_on_first_step_trajectory(current_car_in_corsia,current_polo_to_consider,first_corsia,False);
                                          if can_overtake=False then
                                             can_overtake:= not mailbox.car_can_overtake_on_second_step_trajectory(current_car_in_corsia,current_polo_to_consider,first_corsia);
                                          end if;
                                          if can_overtake=False and mailbox.complete_trajectory_on_same_corsia_is_free(current_car_in_corsia,current_polo_to_consider,first_corsia) then
                                             -- * SOVRASCIZIONE DEI PARAMETRI PRECEDENTEMENTE CALCOLATI
                                             mailbox.set_car_overtaken(True,current_car_in_corsia);
                                             -- ** MODIFICA DELLA DESTINAZIONE
                                             mailbox.update_abitante_destination(current_car_in_corsia,create_trajectory_to_follow(first_corsia,other_corsia,destination.get_ingresso_to_go_trajectory,destination.get_from_ingresso,destination.get_traiettoria_incrocio_to_follow));
                                             -- **
                                             traiettoria_rimasta_da_percorrere:= get_traiettoria_cambio_corsia.get_lunghezza_traiettoria;
                                             distance_to_stop_line:= calculate_bound_to_overtake(current_car_in_corsia,current_polo_to_consider,id_task);
                                             distance_to_stop_line:= distance_to_stop_line+traiettoria_rimasta_da_percorrere-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                                             -- viene settato per assicurarsi che il bound overtake non venga superato
                                             can_not_overtake_now:= True;
                                             -- SEMAFORO_IS_VERDE:= FALSE per disabilitare i controlli all'incrocio dato che non ci arriverà
                                             -- dalla corsia in cui ora è stato messo
                                             semaforo_is_verde:= False;
                                             next_car_in_ingresso_distance:= mailbox.calculate_distance_to_next_ingressi(current_polo_to_consider,other_corsia,current_car_in_corsia);
                                             calculate_distance_to_next_car_on_road(current_car_in_corsia,next_car_in_opposite_corsia,next_car_in_corsia,other_corsia,next_car_on_road,next_car_on_road_distance);
                                             next_entity_distance:= calculate_next_entity_distance(current_car_in_corsia,next_car_in_ingresso_distance,next_car_on_road,next_car_on_road_distance,id_task,next_entity_is_ingresso,tmp_next_entity_distance);
                                             if next_entity_distance/=0.0 then
                                                next_entity_distance:= next_entity_distance+traiettoria_rimasta_da_percorrere-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                                             end if;
                                             -- *
                                          end if;
                                       end if;
                                    end if;
                                 end if;
                              end if;
                           end if;
                        end if;
                        -- END VALUTAZIONE DI SORPASSO

                        speed_abitante:= current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                        if stop_entity=False then
                           if next_car_on_road/=null and then (next_car_in_ingresso_distance=-1.0 or else next_entity_is_ingresso=False) then
                              -- si controlla se alla macchina conviene sorpassare
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
                                    -- next_entity_distance vale 0
                                    disable_rallentamento:= True;
                                    --tratto_incrocio:= get_quartiere_utilities_obj.get_classe_locate_abitanti(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_next(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                                    index_road:= 0;
                                    pragma warnings(off);
                                    Put_Line("quartiere:" & Positive'Image(tratto_incrocio.get_id_quartiere_tratto) & " tratto " & Positive'Image(tratto_incrocio.get_id_tratto) & " quartiere ab " & Positive'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " id ab " & Positive'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
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
                                       --semaforo_is_verde:= False;
                                       disable_rallentamento:= False;
                                       costante_additiva:= 0.0;
                                    else
                                       if distance_to_next_car=-1.0 then -- and bound_distance=-1.0 then
                                          costante_additiva:= get_traiettoria_incrocio(destination.get_traiettoria_incrocio_to_follow).get_lunghezza_traiettoria_incrocio;
                                       else
                                          if distance_to_next_car>min_veicolo_distance and then distance_to_next_car-min_veicolo_distance>0.0 then
                                             costante_additiva:= distance_to_next_car-min_veicolo_distance;
                                             --semaforo_is_verde:= False;
                                          else
                                             costante_additiva:= 0.0;
                                             disable_rallentamento:= False;
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
                                                                 disable_rallentamento_1 => disable_rallentamento,
                                                                 disable_rallentamento_2 => disable_rallentamento);
                           end if;
                        end if;
                     end if;
                     if stop_entity=False then
                        new_speed:= calculate_new_speed(speed_abitante,acceleration);
                        new_step:= calculate_new_step(new_speed,acceleration);

                        fix_advance_parameters(car,acceleration,new_speed,new_step,speed_abitante,next_entity_distance,distance_to_stop_line);
                        Put_Line("id quart " & Positive'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " id ab " & Positive'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " acceleration: " & new_float'Image(acceleration) & " new step: " & new_float'Image(new_step) & " new speed: " & new_float'Image(new_speed));




                        --if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken=False and then current_car_in_corsia.get_next_from_list_posizione_abitanti/=null then
                        --   if current_car_in_corsia.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step)<min_veicolo_distance then
                        --      Put_Line("Errore in next_entity_distance " & Positive'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " id ab " & Positive'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " next entity distance settata: " & new_float'Image(next_entity_distance) & " next ab: " & Positive'Image(current_car_in_corsia.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(current_car_in_corsia.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                        --      raise other_error;
                        --   end if;
                        --end if;

                        if can_not_overtake_now then
                           -- distance_to_stop_line in questo caso è bound_overtaken
                           if new_step>distance_to_stop_line then
                              new_step:= current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory+distance_to_stop_line;
                              step_is_just_calculated:= True;
                           end if;
                        end if;

                        if abilita_limite_overtaken then
                           Put_Line("Limite overtaken: " & Positive'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                           if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory+new_step>limite_in_overtaken then
                              new_step:= limite_in_overtaken;
                              step_is_just_calculated:= True;
                           end if;
                        end if;

                        --correct_step_to_advance(new_step,current_car_in_corsia);

                        if ((id_task=16 and current_polo_to_consider=True) and current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti=189) and current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>700.0 then
                           stop_entity:= False;
                        end if;

                        if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken then
                           if step_is_just_calculated then
                              costante_additiva:= current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step;
                           else
                              costante_additiva:= current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory+new_step;
                           end if;
                           costante_additiva:= costante_additiva-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                        else
                           costante_additiva:= current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step;
                        end if;

                        if tmp_next_entity_distance/=-1.0 then
                           segnale:= False;

                           declare
                              ord_ingressi: indici_ingressi:= mailbox.get_ingressi_ordered_by_distance(not current_polo_to_consider);
                              new_indice: Natural;
                           begin
                              segnale:= False;
                              for t in ord_ingressi'Range loop
                                 ingresso:= get_ingresso_from_id(ord_ingressi(t));
                                 distance_ingresso:= get_distance_from_polo_percorrenza(ingresso,current_polo_to_consider);
                                 if segnale=False and current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-min_veicolo_distance then
                                    if costante_additiva>=distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-min_veicolo_distance then
                                       segnale:= True;
                                       new_indice:= t;
                                    end if;
                                 end if;
                              end loop;
                              if segnale then
                                 ingresso:= get_ingresso_from_id(ord_ingressi(new_indice));
                                 distance_ingresso:= get_distance_from_polo_percorrenza(ingresso,current_polo_to_consider);
                                 if tmp_next_entity_distance<=distance_ingresso+get_larghezza_corsia+get_larghezza_marciapiede+get_quartiere_utilities_obj.get_auto_quartiere(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva+min_veicolo_distance then
                                    if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken then
                                       step_is_just_calculated:= True;
                                       new_step:= distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-min_veicolo_distance-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria+get_traiettoria_cambio_corsia.get_lunghezza_traiettoria;
                                    else
                                       new_step:= distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-min_veicolo_distance-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                                    end if;
                                    new_speed:= new_speed/2.0;
                                    costante_additiva:= distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-min_veicolo_distance;
                                 else
                                    new_indice:= new_indice+1;
                                    if new_indice>0 and new_indice<=ord_ingressi'Last then
                                       ingresso:= get_ingresso_from_id(ord_ingressi(new_indice));
                                       distance_ingresso:= get_distance_from_polo_percorrenza(ingresso,current_polo_to_consider);
                                       if costante_additiva>distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-min_veicolo_distance then
                                          if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken then
                                             step_is_just_calculated:= True;
                                             new_step:= distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-min_veicolo_distance-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria+get_traiettoria_cambio_corsia.get_lunghezza_traiettoria;
                                          else
                                             new_step:= distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-min_veicolo_distance-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                                          end if;
                                          new_speed:= new_speed/2.0;
                                          -- MODIFICA DEL VALORE costante_additiva AGGIORNANDOLO
                                          -- IN RELAZIONE ALLA POSIZIONE DELLA MACCHINA NEL PROSSIMO INGRESSO
                                          costante_additiva:= distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-min_veicolo_distance;
                                       end if;
                                    end if;
                                 end if;
                              end if;
                           end;

                        end if;

                        declare
                           ord_ingressi: indici_ingressi:= mailbox.get_ingressi_ordered_by_distance(not current_polo_to_consider);
                           new_indice: Natural;
                           there_are_conditions_to_bound: Boolean:= False;
                           interested_corsia: id_corsie;
                           key_ingresso: Positive;
                           tmp_num_stalli_1: Natural:= 0;
                           tmp_num_stalli_2: Natural:= 0;
                           tmp_num_stalli_3: Natural:= 0;
                           list_abitanti_on_ingresso: ptr_list_posizione_abitanti_on_road;
                           car_has_to_stop: Boolean:= False;
                        begin
                           segnale:= False;
                           for t in ord_ingressi'Range loop
                              ingresso:= get_ingresso_from_id(ord_ingressi(t));
                              distance_ingresso:= get_distance_from_polo_percorrenza(ingresso,current_polo_to_consider);
                              if segnale=False and current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-min_veicolo_distance then
                                 segnale:= True;
                                 new_indice:= t;
                              end if;
                           end loop;
                           if segnale then
                              ingresso:= get_ingresso_from_id(ord_ingressi(new_indice));
                              distance_ingresso:= get_distance_from_polo_percorrenza(ingresso,current_polo_to_consider);
                              key_ingresso:= mailbox.get_key_ingresso(ingresso.get_id_road,not_ordered);
                              if tmp_next_entity_distance=-1.0 or tmp_next_entity_distance>distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-min_veicolo_distance then
                                 -- la macchina avrà davanti: NESSUNO oppure UNA MACCHINA A DISTANZA INFERIORE DELLA DISTANZA LIMITE AL PROSSIMO INGRESSO
                                 -- CONTROLLARE SE È IL CASO DI LIMITARE LA DISTANZA
                                 if costante_additiva>=distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-min_veicolo_distance then
                                    if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken then
                                       interested_corsia:= current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory;
                                    else
                                       interested_corsia:= first_corsia;
                                    end if;
                                    if ingresso.get_polo_ingresso=current_polo_to_consider then
                                       there_are_conditions_to_bound:= True;
                                    else
                                       if interested_corsia=1 then
                                          there_are_conditions_to_bound:= True;
                                       end if;
                                    end if;
                                    if there_are_conditions_to_bound then
                                       if ingresso.get_polo_ingresso=current_polo_to_consider then
                                          if interested_corsia=2 then
                                             tmp_num_stalli_1:= mailbox.get_num_stalli_for_car_in_ingresso(traiettoria                   => entrata_ritorno,
                                                                                  		           index_ingresso                => key_ingresso,
                                                                                        	           from_begin                    => False,
                                                                               			           int_bipedi                    => False,
                                                                                        		   int_corsie                    => linea_corsia,
                                                                                                           precedenza_to_entrata_ritorno => False);
                                             tmp_num_stalli_2:= mailbox.get_num_stalli_for_car_in_ingresso(traiettoria                   => uscita_andata,
                                                                                  		           index_ingresso                => key_ingresso,
                                                                                        	           from_begin                    => True,
                                                                               			           int_bipedi                    => False,
                                                                                        		   int_corsie                    => linea_corsia,
                                                                                                           precedenza_to_entrata_ritorno => False);
                                             tmp_num_stalli_3:= mailbox.get_num_stalli_for_car_in_ingresso(traiettoria                   => uscita_ritorno,
                                                                                  		           index_ingresso                => key_ingresso,
                                                                                        	           from_begin                    => True,
                                                                               			           int_bipedi                    => False,
                                                                                        		   int_corsie                    => linea_corsia,
                                                                                                           precedenza_to_entrata_ritorno => False);

                                             if tmp_num_stalli_2>0 and tmp_num_stalli_3>0 then
                                                raise other_error;
                                             end if;

                                             if tmp_num_stalli_1>max_num_stalli_entrata_ritorno_from_linea_corsia then

                                                ---- FERMA
                                                car_has_to_stop:= True;

                                                list_abitanti_on_ingresso:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,entrata_ritorno);
                                                -- deve essere per forza diverso da null
                                                if list_abitanti_on_ingresso=null then
                                                   raise other_error;
                                                end if;
                                                mailbox.set_flag_abitante_can_overtake_to_next_corsia(list_abitanti_on_ingresso,True);
                                                if tmp_num_stalli_2>0 then
                                                   list_abitanti_on_ingresso:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,uscita_andata);
                                                   -- deve essere per forza diverso da null
                                                end if;
                                                if tmp_num_stalli_3>0 then
                                                   list_abitanti_on_ingresso:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,uscita_ritorno);
                                                   -- deve essere per forza diverso da null
                                                end if;
                                                if tmp_num_stalli_2>0 or tmp_num_stalli_3>0 then
                                                   if list_abitanti_on_ingresso=null then
                                                      raise other_error;
                                                   end if;
                                                   mailbox.set_flag_abitante_can_overtake_to_next_corsia(list_abitanti_on_ingresso,True);
                                                end if;
                                             else
                                                if tmp_num_stalli_2>max_num_stalli_uscite_cars or
                                                  tmp_num_stalli_3>max_num_stalli_uscite_cars then

                                                   ------- FERMA
                                                   car_has_to_stop:= True;

                                                   if tmp_num_stalli_2>max_num_stalli_uscite_cars then
                                                      list_abitanti_on_ingresso:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,uscita_andata);
                                                   else
                                                      list_abitanti_on_ingresso:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,uscita_ritorno);
                                                   end if;
                                                   if list_abitanti_on_ingresso=null then
                                                      raise other_error;
                                                   end if;
                                                   mailbox.set_flag_abitante_can_overtake_to_next_corsia(list_abitanti_on_ingresso,True);
                                                   if tmp_num_stalli_1>0 then
                                                      list_abitanti_on_ingresso:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,entrata_ritorno);
                                                      -- deve essere per forza diverso da null
                                                      if list_abitanti_on_ingresso=null then
                                                         raise other_error;
                                                      end if;
                                                      mailbox.set_flag_abitante_can_overtake_to_next_corsia(list_abitanti_on_ingresso,True);
                                                   end if;
                                                end if;
                                             end if;
                                          else
                                             -- interested_corsia vale 1
                                             tmp_num_stalli_1:= mailbox.get_num_stalli_for_car_in_ingresso(traiettoria                   => uscita_ritorno,
                                                                                  		           index_ingresso                => key_ingresso,
                                                                                        	           from_begin                    => False,
                                                                               			           int_bipedi                    => False,
                                                                                        		   int_corsie                    => linea_corsia,
                                                                                                           precedenza_to_entrata_ritorno => False);
                                             tmp_num_stalli_2:= mailbox.get_num_stalli_for_car_in_ingresso(traiettoria                   => entrata_ritorno,
                                                                                  		           index_ingresso                => key_ingresso,
                                                                                        	           from_begin                    => False,
                                                                               			           int_bipedi                    => False,
                                                                                        		   int_corsie                    => linea_mezzaria,
                                                                                                           precedenza_to_entrata_ritorno => False);

                                             if (tmp_num_stalli_1>max_num_stalli_uscita_ritorno_from_linea_corsia or tmp_num_stalli_2>max_num_stalli_entrata_ritorno_from_linea_mezzaria) then
                                                -- o l'uno o l'altro hanno superato il limite del numero di stalli
                                                -- se sono anche entrambi maggiori di 0 allora li flagghi

                                                ---- FERMA
                                                car_has_to_stop:= True;
                                                if tmp_num_stalli_1>0 then
                                                   list_abitanti_on_ingresso:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,uscita_ritorno);
                                                   if list_abitanti_on_ingresso=null then
                                                      raise other_error;
                                                   end if;
                                                   mailbox.set_flag_abitante_can_overtake_to_next_corsia(list_abitanti_on_ingresso,True);
                                                end if;

                                                if tmp_num_stalli_2>0 then
                                                   list_abitanti_on_ingresso:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,entrata_ritorno);
                                                   if list_abitanti_on_ingresso=null then
                                                      raise other_error;
                                                   end if;
                                                   mailbox.set_flag_abitante_can_overtake_to_next_corsia(list_abitanti_on_ingresso,True);
                                                end if;

                                             end if;
                                          end if;
                                       else
                                          -- interested_corsia=1
                                          tmp_num_stalli_1:= mailbox.get_num_stalli_for_car_in_ingresso(traiettoria                   => uscita_ritorno,
                                                                                  		        index_ingresso                => key_ingresso,
                                                                                        	        from_begin                    => False,
                                                                               			        int_bipedi                    => False,
                                                                                        		int_corsie                    => linea_mezzaria,
                                                                                                        precedenza_to_entrata_ritorno => False);
                                          if tmp_num_stalli_1>max_num_stalli_uscita_ritorno_from_linea_mezzaria then
                                             ---- FERMA
                                             car_has_to_stop:= True;
                                             list_abitanti_on_ingresso:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,uscita_ritorno);
                                             if list_abitanti_on_ingresso=null then
                                                raise other_error;
                                             end if;
                                             mailbox.set_flag_abitante_can_overtake_to_next_corsia(list_abitanti_on_ingresso,True);
                                          end if;
                                       end if;

                                       if car_has_to_stop then
                                          if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken then
                                             step_is_just_calculated:= True;
                                             new_step:= distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-min_veicolo_distance-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria+get_traiettoria_cambio_corsia.get_lunghezza_traiettoria;
                                          else
                                             new_step:= distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-min_veicolo_distance-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                                          end if;
                                          new_speed:= new_speed/2.0;
                                          costante_additiva:= distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-min_veicolo_distance;
                                       end if;

                                    end if;
                                 end if;

                                 if ingresso.get_polo_ingresso=current_polo_to_consider then
                                    if costante_additiva>=distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-min_veicolo_distance then
                                       tmp_num_stalli_1:= mailbox.get_num_stalli_for_bipedi_in_ingresso(entrata_dritto_bici,key_ingresso,True);
                                       car_has_to_stop:= False;
                                       if tmp_num_stalli_1>max_num_stalli_entrata_dritto_bipedi_from_mezzaria then
                                          car_has_to_stop:= True;
                                          if mailbox.get_abilitazione_att_bipedi_per_intersezione_cars(current_polo_to_consider,current_polo_to_consider,mailbox.get_key_ingresso_from_ordered_ingressi(ingresso.get_id_road,current_polo_to_consider),False) then
                                             mailbox.abilita_ingresso_allo_spostamento_bipedi(current_polo_to_consider,current_polo_to_consider,mailbox.get_key_ingresso_from_ordered_ingressi(ingresso.get_id_road,current_polo_to_consider),False);
                                          end if;
                                       end if;
                                       if car_has_to_stop then
                                          if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken then
                                             step_is_just_calculated:= True;
                                             new_step:= distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-min_veicolo_distance-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria+get_traiettoria_cambio_corsia.get_lunghezza_traiettoria;
                                          else
                                             new_step:= distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-min_veicolo_distance-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                                          end if;
                                          new_speed:= new_speed/2.0;
                                          costante_additiva:= distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-min_veicolo_distance;
                                       end if;
                                    end if;
                                 else
                                    if costante_additiva>=distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-min_veicolo_distance then
                                       tmp_num_stalli_1:= mailbox.get_num_stalli_for_bipedi_in_ingresso(uscita_dritto_bici,key_ingresso,False);
                                       car_has_to_stop:= False;
                                       if tmp_num_stalli_1>max_num_stalli_uscite_bipedi_from_mezzaria then
                                          car_has_to_stop:= True;
                                          if mailbox.get_abilitazione_att_bipedi_per_intersezione_cars(current_polo_to_consider,not current_polo_to_consider,mailbox.get_key_ingresso_from_ordered_ingressi(ingresso.get_id_road,not current_polo_to_consider),False) then
                                             mailbox.abilita_ingresso_allo_spostamento_bipedi(current_polo_to_consider,not current_polo_to_consider,mailbox.get_key_ingresso_from_ordered_ingressi(ingresso.get_id_road,not current_polo_to_consider),False);
                                          end if;
                                       end if;
                                       if car_has_to_stop then
                                          if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken then
                                             step_is_just_calculated:= True;
                                             new_step:= distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-min_veicolo_distance-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria+get_traiettoria_cambio_corsia.get_lunghezza_traiettoria;
                                          else
                                             new_step:= distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-min_veicolo_distance-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                                          end if;
                                          new_speed:= new_speed/2.0;
                                          costante_additiva:= distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-min_veicolo_distance;
                                       end if;
                                    end if;
                                 end if;
                              end if;

                           end if;
                        end;

                        declare
                           ord_ingressi: indici_ingressi:= mailbox.get_ingressi_ordered_by_distance(not current_polo_to_consider);
                           new_indice: Natural;
                           there_are_conditions_to_bound: Boolean:= False;
                           key_ingresso: Positive;
                           tmp_num_stalli_1: Natural:= 0;
                           tmp_num_stalli_2: Natural:= 0;
                           tmp_num_stalli_3: Natural:= 0;
                           car_has_to_stop: Boolean:= False;
                        begin
                           segnale:= False;
                           for t in ord_ingressi'Range loop
                              ingresso:= get_ingresso_from_id(ord_ingressi(t));
                              distance_ingresso:= get_distance_from_polo_percorrenza(ingresso,current_polo_to_consider);
                              if segnale=False and current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=distance_ingresso+get_larghezza_corsia-min_veicolo_distance then
                                 segnale:= True;
                                 new_indice:= t;
                              end if;
                           end loop;
                           if segnale then
                              ingresso:= get_ingresso_from_id(ord_ingressi(new_indice));
                              distance_ingresso:= get_distance_from_polo_percorrenza(ingresso,current_polo_to_consider);
                              key_ingresso:= mailbox.get_key_ingresso(ingresso.get_id_road,not_ordered);
                              if tmp_next_entity_distance=-1.0 or tmp_next_entity_distance>distance_ingresso+get_larghezza_corsia-min_veicolo_distance then
                                 -- la macchina avrà davanti: NESSUNO oppure UNA MACCHINA A DISTANZA INFERIORE DELLA DISTANZA LIMITE AL PROSSIMO INGRESSO
                                 -- CONTROLLARE SE È IL CASO DI LIMITARE LA DISTANZA
                                 if costante_additiva>=distance_ingresso+get_larghezza_corsia-min_veicolo_distance then
                                    if ingresso.get_polo_ingresso=current_polo_to_consider then
                                       if costante_additiva>=distance_ingresso+get_larghezza_corsia-min_veicolo_distance then
                                          tmp_num_stalli_1:= mailbox.get_num_stalli_for_bipedi_in_ingresso(uscita_dritto_bici,key_ingresso,True);
                                          car_has_to_stop:= False;
                                          if tmp_num_stalli_1>max_num_stalli_uscite_bipedi_from_begin then
                                             car_has_to_stop:= True;
                                             if mailbox.get_abilitazione_att_bipedi_per_intersezione_cars(current_polo_to_consider,current_polo_to_consider,mailbox.get_key_ingresso_from_ordered_ingressi(ingresso.get_id_road,current_polo_to_consider),True) then
                                                mailbox.abilita_ingresso_allo_spostamento_bipedi(current_polo_to_consider,current_polo_to_consider,mailbox.get_key_ingresso_from_ordered_ingressi(ingresso.get_id_road,current_polo_to_consider),True);
                                             end if;
                                          end if;
                                          if car_has_to_stop then
                                             if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken then
                                                step_is_just_calculated:= True;
                                                new_step:= distance_ingresso+get_larghezza_corsia-min_veicolo_distance-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria+get_traiettoria_cambio_corsia.get_lunghezza_traiettoria;
                                             else
                                                new_step:= distance_ingresso+get_larghezza_corsia-min_veicolo_distance-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                                             end if;
                                             new_speed:= new_speed/2.0;
                                             costante_additiva:= distance_ingresso+get_larghezza_corsia-min_veicolo_distance;
                                          end if;
                                       end if;
                                    else
                                       if costante_additiva>=distance_ingresso+get_larghezza_corsia-min_veicolo_distance then
                                          tmp_num_stalli_1:= mailbox.get_num_stalli_for_bipedi_in_ingresso(entrata_ritorno_bici,key_ingresso,False);
                                          car_has_to_stop:= False;
                                          if tmp_num_stalli_1>max_num_stalli_entrata_ritorno_bipedi then
                                             car_has_to_stop:= True;
                                             if mailbox.get_abilitazione_att_bipedi_per_intersezione_cars(current_polo_to_consider,not current_polo_to_consider,mailbox.get_key_ingresso_from_ordered_ingressi(ingresso.get_id_road,not current_polo_to_consider),True) then
                                                mailbox.abilita_ingresso_allo_spostamento_bipedi(current_polo_to_consider,not current_polo_to_consider,mailbox.get_key_ingresso_from_ordered_ingressi(ingresso.get_id_road,not current_polo_to_consider),True);
                                             end if;
                                          end if;
                                          if car_has_to_stop then
                                             if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken then
                                                step_is_just_calculated:= True;
                                                new_step:= distance_ingresso+get_larghezza_corsia-min_veicolo_distance-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria+get_traiettoria_cambio_corsia.get_lunghezza_traiettoria;
                                             else
                                                new_step:= distance_ingresso+get_larghezza_corsia-min_veicolo_distance-current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                                             end if;
                                             new_speed:= new_speed/2.0;
                                             costante_additiva:= distance_ingresso+get_larghezza_corsia-min_veicolo_distance;
                                          end if;
                                       end if;
                                    end if;
                                 end if;
                              end if;
                           end if;
                        end;

                        mailbox.set_move_parameters_entity_on_main_road(current_car_in_corsia,current_polo_to_consider,first_corsia,new_speed,new_step,step_is_just_calculated);
                        if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken=True and first_corsia/=current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory then -- macchina in sorpasso
                           if abilita_limite_overtaken=False and then current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_distance_on_overtaking_trajectory>=limite_in_overtaken then
                              mailbox.set_flag_abitante_can_overtake_to_next_corsia(current_car_in_corsia,True);
                           end if;
                        end if;

                        if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti=current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti then
                           Put_Line("SAME POSITION ABITANTE id quartiere: " & Positive'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                           get_log_stallo_quartiere.write_state_stallo(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,True);
                        else
                           get_log_stallo_quartiere.write_state_stallo(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,False);
                        end if;

                        if current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_urbana_from_id(id_task).get_lunghezza_road and current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>=get_urbana_from_id(id_task).get_lunghezza_road then
                           -- aggiungi entità
                           -- all'incrocio
                           if get_quartiere_utilities_obj.get_classe_locate_abitanti(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_current_position(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti)/=1 then
                              get_quartiere_utilities_obj.get_classe_locate_abitanti(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).set_position_abitante_to_next(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                           end if;
                           tratto_incrocio:= get_quartiere_utilities_obj.get_classe_locate_abitanti(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_next(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                           abitante_to_transfer:= posizione_abitanti_on_road(create_new_posizione_abitante_from_copy(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti));
                           --abitante_to_transfer.set_where_next_abitante(0.0);

                           if semaforo_is_verde then
                              if disable_rallentamento=False then
                                 abitante_to_transfer.set_where_next_abitante(0.0);
                              else
                                 -- costante additiva >0
                                 if abitante_to_transfer.get_where_next_posizione_abitanti-get_urbana_from_id(id_task).get_lunghezza_road>costante_additiva then
                                    abitante_to_transfer.set_where_next_abitante(costante_additiva);
                                 else
                                    abitante_to_transfer.set_where_next_abitante(abitante_to_transfer.get_where_next_posizione_abitanti-get_urbana_from_id(id_task).get_lunghezza_road);
                                 end if;
                              end if;
                           else
                              abitante_to_transfer.set_where_next_abitante(0.0);
                           end if;

                           -- l'abitante non può andare direttamente a fine traiettoria perchè altrimenti verrebbe eliminato
                           -- senza averne reconfigurato l'abitante e quindi averlo mandata alla prossima entità
                           if abitante_to_transfer.get_where_next_posizione_abitanti>=get_traiettoria_incrocio(destination.get_traiettoria_incrocio_to_follow).get_lunghezza_traiettoria_incrocio then
                              abitante_to_transfer.set_where_next_abitante(get_traiettoria_incrocio(destination.get_traiettoria_incrocio_to_follow).get_lunghezza_traiettoria_incrocio/2.0);
                           end if;
                           if destination.get_traiettoria_incrocio_to_follow=sinistra then
                              if abitante_to_transfer.get_where_next_posizione_abitanti>get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_1).get_distanza_intersezione_incrocio-max_larghezza_veicolo then
                                 abitante_to_transfer.set_where_next_abitante(get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_1).get_distanza_intersezione_incrocio-max_larghezza_veicolo);
                              end if;
                           elsif destination.get_traiettoria_incrocio_to_follow=dritto_1 then
                              if abitante_to_transfer.get_where_next_posizione_abitanti>get_traiettoria_incrocio(dritto_1).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio-max_larghezza_veicolo then
                                 abitante_to_transfer.set_where_next_abitante(get_traiettoria_incrocio(dritto_1).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio-max_larghezza_veicolo);
                              end if;
                           elsif destination.get_traiettoria_incrocio_to_follow=dritto_2 then
                              if abitante_to_transfer.get_where_next_posizione_abitanti>get_traiettoria_incrocio(dritto_2).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio-max_larghezza_veicolo then
                                 abitante_to_transfer.set_where_next_abitante(get_traiettoria_incrocio(dritto_2).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio-max_larghezza_veicolo);
                              end if;
                           elsif destination.get_traiettoria_incrocio_to_follow=destra then
                              if abitante_to_transfer.get_where_next_posizione_abitanti>get_traiettoria_incrocio(destra).get_intersezione_bipedi then
                                 abitante_to_transfer.set_where_next_abitante(get_traiettoria_incrocio(destra).get_intersezione_bipedi);
                              end if;
                           end if;

                           abitante_to_transfer.set_where_now_abitante(abitante_to_transfer.get_where_next_posizione_abitanti);
                           --abitante_to_transfer.set_destination(create_trajectory_to_follow(get_id_quartiere,destination.get_corsia_to_go_trajectory,0,id_task,destination.get_traiettoria_incrocio_to_follow));

                           Put_Line("quartiere:" & Positive'Image(tratto_incrocio.get_id_quartiere_tratto) & " tratto " & Positive'Image(tratto_incrocio.get_id_tratto) & " quartiere ab " & Positive'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " id ab " & Positive'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));

                           ptr_rt_incrocio(get_id_incrocio_quartiere(tratto_incrocio.get_id_quartiere_tratto,tratto_incrocio.get_id_tratto)).insert_new_car(get_id_quartiere,id_task,posizione_abitanti_on_road(abitante_to_transfer));

                           if tratto_incrocio.get_id_quartiere_tratto/=get_id_quartiere then
                              mailbox.add_entità_in_out_quartiere(abitante_to_transfer.get_id_quartiere_posizione_abitanti,abitante_to_transfer.get_id_abitante_posizione_abitanti,car,get_id_quartiere,id_task,first_corsia);
                           end if;

                        end if;
                     else
                        null;
                     end if;
                     --Put_Line(Boolean'Image(mailbox.get_abitanti_on_road(false,1).get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken));

                     if (validity_ingresso_same_direction or else validity_ingresso_opposite_direction) then
                        set_condizioni_per_abilitare_spostamento_bipedi(mailbox,distance_last_ingresso,index_ingresso_same_direction,index_ingresso_opposite_direction,current_polo_to_consider,current_car_in_corsia,distance_ingresso_same_direction,distance_ingresso_opposite_direction,first_corsia);
                     end if;

                  else
                     null; -- NOOP
                  end if;
               else
                  if first_corsia=0 then
                     Put_Line("ERRORE; ABITANTE NON TROVATO; LISTA ROTTA");
                     raise lista_abitanti_rotta;
                  else
                     Put_Line("id_abitante " & Positive'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & new_float'Image(current_car_in_corsia.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is urbana " & Positive'Image(id_task) & " corsia" & Positive'Image(first_corsia) & " polo " & Boolean'Image(current_polo_to_consider) & " quartiere" & Positive'Image(get_id_quartiere) & " ha percorso tutta la strada");
                  end if;
               end if;
            end loop;

            current_polo_to_consider:= True;
         end loop;



         -- la seguente update va fatta prima delle eventuali successive disabilitazioni
         mailbox.update_abilitazioni_attraversamento_bipedi_ingresso;


         -- cicla sugli ingressi per vedere se si ha qualche abitante nelle traiettorie
         -- in modo da disabilitare eventualmente l'attraversamento dei bipedi
         -- BEGIN
         for range_1 in False..True loop
            if range_1 then
               current_ingressi_structure_type_to_consider:= ordered_polo_true;
            else
               current_ingressi_structure_type_to_consider:= ordered_polo_false;
            end if;
            for i in 1..mailbox.get_ordered_ingressi_from_polo(range_1).all'Last loop
               list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(i,current_ingressi_structure_type_to_consider),entrata_andata);
               if list_abitanti/=null then
                  --if mailbox.get_abilitazione_attraversamento_cars_ingresso(False,range_1
                  mailbox.disabilita_attraversamento_bipedi_ingresso(range_1,range_1,i,False);
               end if;
               list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(i,current_ingressi_structure_type_to_consider),uscita_andata);
               if list_abitanti/=null and then list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 then
                  mailbox.disabilita_attraversamento_bipedi_ingresso(range_1,range_1,i,True);
               end if;
            end loop;
         end loop;

         for range_1 in False..True loop
            if range_1 then
               current_ingressi_structure_type_to_consider:= ordered_polo_true;
            else
               current_ingressi_structure_type_to_consider:= ordered_polo_false;
            end if;
            for i in 1..mailbox.get_ordered_ingressi_from_polo(range_1).all'Last loop
               list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(i,current_ingressi_structure_type_to_consider),entrata_ritorno);
               --if list_abitanti/=null and then list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
               --                                                                                                                                                                                  list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
               --   mailbox.disabilita_attraversamento_bipedi_ingresso(range_1,not range_1,i,False);
               --end if;
               if list_abitanti/=null and then list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                  mailbox.disabilita_attraversamento_bipedi_ingresso(not range_1,range_1,i,False);
               end if;
               if list_abitanti/=null and then list_abitanti.get_next_from_list_posizione_abitanti/=null then
                  mailbox.disabilita_attraversamento_bipedi_ingresso(not range_1,range_1,i,False);
               end if;
               list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(i,current_ingressi_structure_type_to_consider),uscita_ritorno);
               if list_abitanti/=null and then list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_traiettoria_ingresso(uscita_ritorno).get_intersezione_bipedi then
                  mailbox.disabilita_attraversamento_bipedi_ingresso(not range_1,range_1,i,True);
               end if;
            end loop;
         end loop;
         -- END

         -- set flag per lo spostamento degli abitanti in uscita_dritto e entrata_dritto
         for range_1 in False..True loop
            for range_2 in False..True loop
               num_ingressi:= mailbox.get_num_ingressi_polo(range_2);
               if range_2 then
                  current_ingressi_structure_type_to_consider:= ordered_polo_true;
               else
                  current_ingressi_structure_type_to_consider:= ordered_polo_false;
               end if;
               for k in 1..num_ingressi loop
                  if mailbox.get_abilitazione_attraversamento_ingresso(range_1,range_2,k,True) then
                     if range_1=range_2 then
                        null;
                        -- l'abilitazione non può essere data subito per questi abitanti
                        --for i in 1..2 loop
                        --   if i=1 then
                        --      list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(k,current_ingressi_structure_type_to_consider),uscita_dritto_bici);
                        --   else
                        --      list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(k,current_ingressi_structure_type_to_consider),uscita_dritto_pedoni);
                        --   end if;
                        --   if list_abitanti_on_traiettoria_ingresso/=null and then list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 then
                        --      mailbox.set_flag_abitante_can_overtake_to_next_corsia(list_abitanti_on_traiettoria_ingresso,True);
                        --   end if;
                        --end loop;
                     else
                        if mailbox.get_num_stalli_for_car_in_ingresso(uscita_ritorno,mailbox.get_key_ingresso(mailbox.get_index_ingresso_from_key(k,current_ingressi_structure_type_to_consider),not_ordered),False,True,linea_corsia,False)>max_num_stalli_uscita_ritorno_in_intersezione_bipedi then
                           null;
                        else
                           for i in 1..2 loop
                              if i=1 then
                                 list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(k,current_ingressi_structure_type_to_consider),entrata_ritorno_bici);
                              else
                                 list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(k,current_ingressi_structure_type_to_consider),entrata_ritorno_pedoni);
                              end if;
                              prec_other_list_abitanti:= null;
                              while list_abitanti_on_traiettoria_ingresso/=null loop
                                 if list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 then
                                    prec_other_list_abitanti:= list_abitanti_on_traiettoria_ingresso;
                                    --prec_other_list_abitanti:= list_abitanti_on_traiettoria_ingresso;
                                 end if;
                                 list_abitanti_on_traiettoria_ingresso:= list_abitanti_on_traiettoria_ingresso.get_next_from_list_posizione_abitanti;
                              end loop;
                              if prec_other_list_abitanti/=null then
                                 mailbox.set_flag_abitante_can_overtake_to_next_corsia(prec_other_list_abitanti,True);
                              end if;
                           end loop;
                        end if;
                     end if;
                  end if;
               end loop;
            end loop;
         end loop;

         for range_1 in False..True loop
            for range_2 in False..True loop
               num_ingressi:= mailbox.get_num_ingressi_polo(range_2);
               if range_2 then
                  current_ingressi_structure_type_to_consider:= ordered_polo_true;
               else
                  current_ingressi_structure_type_to_consider:= ordered_polo_false;
               end if;
               for k in 1..num_ingressi loop
                  if mailbox.get_abilitazione_attraversamento_ingresso(range_1,range_2,k,False) then
                     if range_1=range_2 then
                        for i in 1..2 loop
                           if i=1 then
                              list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(k,current_ingressi_structure_type_to_consider),entrata_dritto_bici);
                           else
                              list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(k,current_ingressi_structure_type_to_consider),entrata_dritto_pedoni);
                           end if;
                           while list_abitanti_on_traiettoria_ingresso/=null loop
                              if list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_larghezza_corsia*2.0 then
                                 mailbox.set_flag_abitante_can_overtake_to_next_corsia(list_abitanti_on_traiettoria_ingresso,True);
                              end if;
                              list_abitanti_on_traiettoria_ingresso:= list_abitanti_on_traiettoria_ingresso.get_next_from_list_posizione_abitanti;
                           end loop;
                        end loop;
                     else
                        for i in 1..2 loop
                           if i=1 then
                              list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(k,current_ingressi_structure_type_to_consider),uscita_dritto_bici);
                           else
                              list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(k,current_ingressi_structure_type_to_consider),uscita_dritto_pedoni);
                           end if;
                           while list_abitanti_on_traiettoria_ingresso/=null loop
                              if list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_larghezza_corsia*2.0+get_larghezza_marciapiede then
                                 mailbox.set_flag_abitante_can_overtake_to_next_corsia(list_abitanti_on_traiettoria_ingresso,True);
                              end if;
                              list_abitanti_on_traiettoria_ingresso:= list_abitanti_on_traiettoria_ingresso.get_next_from_list_posizione_abitanti;
                           end loop;
                        end loop;
                     end if;
                  end if;
               end loop;
            end loop;
         end loop;


         -- spostamento traiettorie ingressi per BICI/PEDONI
         for range_1 in False..True loop
            if range_1 then
               current_ingressi_structure_type_to_consider:= ordered_polo_true;
               current_ingressi_structure_type_to_not_consider:= ordered_polo_false;
            else
               current_ingressi_structure_type_to_consider:= ordered_polo_false;
               current_ingressi_structure_type_to_not_consider:= ordered_polo_true;
            end if;

            list_abitanti_sidewalk_bici:= mailbox.get_abitanti_to_move(sidewalk,range_1,1);
            list_abitanti_sidewalk_pedoni:= mailbox.get_abitanti_to_move(sidewalk,range_1,2);
            prec_list_abitanti_sidewalk_bici:= null;
            prec_list_abitanti_sidewalk_pedoni:= null;

            for z in 1..mailbox.get_ordered_ingressi_from_polo(range_1).all'Last loop
               -- traiettorie da spostare:
               -- uscita_destra_pedoni,uscita_dritto_pedoni,uscita_destra_bici,uscita_dritto_bici,uscita_ritorno_pedoni,uscita_ritorno_bici
               -- entrata_destra_pedoni,entrata_destra_bici,entrata_ritorno_pedoni,entrata_ritorno_bici,entrata_dritto_pedoni,entrata_dritto_bici

               -- viene eseguito l'avanzamento degli abitanti in sidewalk sino all'ingresso z
               ingresso:= get_ingresso_from_id(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider));
               distance_ingresso:= get_distance_from_polo_percorrenza(ingresso,range_1);

               signal:= True;
               while list_abitanti_sidewalk_bici/=null and signal loop
                  if list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<distance_ingresso-get_larghezza_marciapiede-get_larghezza_corsia then
                     prec_list_abitanti_sidewalk_bici:= list_abitanti_sidewalk_bici;
                     list_abitanti_sidewalk_bici:= list_abitanti_sidewalk_bici.get_next_from_list_posizione_abitanti;
                  else
                     signal:= False;
                  end if;
               end loop;

               signal:= True;
               while list_abitanti_sidewalk_pedoni/=null and signal loop
                  if list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<distance_ingresso-get_larghezza_marciapiede-get_larghezza_corsia then
                     prec_list_abitanti_sidewalk_pedoni:= list_abitanti_sidewalk_pedoni;
                     list_abitanti_sidewalk_pedoni:= list_abitanti_sidewalk_pedoni.get_next_from_list_posizione_abitanti;
                  else
                     signal:= False;
                  end if;
               end loop;

               -- POSTCONDITION: list_abitanti_sidewalk_(bici/pedoni) sono settati in modo tale che il primo abitante della lista si trovi dopo distance_ingresso-get_larghezza_marciapiede-get_larghezza_corsia

               -- gli abitanti in entrata_ritorno_pedoni e entrata_ritorno_bici avranno
               -- la flag overtake_next_corsia settata a True se possono attraversare
               for h in 1..2 loop
                  if h=1 then
                     list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),entrata_ritorno_bici);
                     other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),entrata_dritto_bici);
                     traiettoria_da_percorrere:= entrata_ritorno_bici;
                     mezzo:= bike;
                  else
                     list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),entrata_ritorno_pedoni);
                     other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),entrata_dritto_pedoni);
                     traiettoria_da_percorrere:= entrata_ritorno_pedoni;
                     mezzo:= walking;
                  end if;

                  -- prendo l'ultimo bipede in traiettoria
                  --while other_list_abitanti/=null and then other_list_abitanti.get_next_from_list_posizione_abitanti/=null loop
                  --   other_list_abitanti:= other_list_abitanti.get_next_from_list_posizione_abitanti;
                  --end loop;
                  --NOTA TI SERVE IL PRIMO BIPEDE IN TRAIETTORIA DRITTO NON L'ULTIMO

                  -- can_not_overtake_now viene usato per valutare se il bipede
                  -- può sorpassare distance_to_stop_line
                  can_not_overtake_now:= False;
                  while list_abitanti/=null loop
                     stop_entity:= False;
                     next_entity_distance:= 0.0;
                     next_id_quartiere_abitante:= 0;
                     next_id_abitante:= 0;
                     next_abitante_velocity:= 0.0;
                     next_abitante:= null;

                     if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia=False then
                        next_abitante:= list_abitanti.get_next_from_list_posizione_abitanti;
                        stop_entity:= True;
                     end if;

                     if (list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia=False and
                              list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0) and
                       list_abitanti.get_next_from_list_posizione_abitanti=null then
                        if other_list_abitanti=null or else other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_larghezza_corsia+get_larghezza_marciapiede then
                           mailbox.increase_num_stalli_for_bipede_in_ingresso(traiettoria_da_percorrere,mailbox.get_key_ingresso(ingresso.get_id_road,not_ordered),False,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                        end if;
                     end if;

                     if stop_entity=False then
                        case mezzo is
                           -- caso bike: nella traiettoria entrata_ritorno_bici passa una sola bici per volta
                        when bike =>
                           if list_abitanti.get_next_from_list_posizione_abitanti/=null then
                              stop_entity:= True;
                              next_abitante:= list_abitanti.get_next_from_list_posizione_abitanti;
                           else
                              next_abitante:= null;
                              if other_list_abitanti/=null then
                                 if other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_bici_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<min_bici_distance then
                                    stop_entity:= True;
                                 else
                                    next_entity_distance:= other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_bici_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva+(get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti);
                                    next_id_quartiere_abitante:= other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                                    next_id_abitante:= other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                                    next_abitante_velocity:= other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                                 end if;
                              end if;
                           end if;
                        -- caso walking: nella traiettoria entrata_ritorno_pedoni possono passare più pedoni per volta
                        when walking =>
                           next_abitante:= list_abitanti.get_next_from_list_posizione_abitanti;
                           if next_abitante=null then
                              if other_list_abitanti/=null then
                                 next_entity_distance:= other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_pedone_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva+(get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti);
                                 --if other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_pedone_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<0.0 then
                                 --   if other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_pedone_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<min_pedone_distance then
                                 --      stop_entity:= True;
                                 --   else
                                 --      next_entity_distance:= other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_pedone_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva+get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                                 --   end if;
                                 --else
                                    -- in questo caso si può già pensare all'attraversamento
                                    -- senza guardare se vi sono macchine che danno precedenza
                                    -- next_entity_distance:= other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_pedone_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva+(get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti);
                                 --end if;
                                 next_id_quartiere_abitante:= other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                                 next_id_abitante:= other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                                 next_abitante_velocity:= other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                              end if;
                           else
                              if next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_pedone_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<min_pedone_distance then
                                 stop_entity:= True;
                              else
                                 next_entity_distance:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_pedone_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                                 next_id_quartiere_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                                 next_id_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                                 next_abitante_velocity:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                              end if;
                           end if;
                        when car =>
                           raise mezzo_settato_non_corretto;
                        end case;
                     end if;

                     if stop_entity=False then
                        distance_to_stop_line:= get_default_larghezza_corsia+get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                        speed_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                        acceleration:= calculate_acceleration(mezzo                      => mezzo,
                                                              id_abitante                => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                              id_quartiere_abitante      => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                              next_entity_distance       => next_entity_distance,
                                                              distance_to_stop_line      => distance_to_stop_line,
                                                              next_id_quartiere_abitante => next_id_quartiere_abitante,
                                                              next_id_abitante           => next_id_abitante,
                                                              abitante_velocity          => speed_abitante,
                                                              next_abitante_velocity     => next_abitante_velocity,
                                                              disable_rallentamento_1    => True,
                                                              disable_rallentamento_2    => True,
                                                              request_by_incrocio => True);

                        new_speed:= calculate_new_speed(speed_abitante,acceleration);
                        new_step:= calculate_new_step(new_speed,acceleration);

                        fix_advance_parameters(mezzo,acceleration,new_speed,new_step,speed_abitante,next_entity_distance,distance_to_stop_line);
                        step_is_just_calculated:= False;

                        if new_step-get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza>=get_larghezza_corsia then
                           new_speed:= new_speed/2.0;
                           new_step:= get_larghezza_corsia+(get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti);
                        end if;

                        --if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza then
                        --   mailbox.set_flag_abitante_can_overtake_to_next_corsia(list_abitanti,False);
                        --   if new_step-get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza>=get_larghezza_corsia then
                        --      new_speed:= new_speed/2.0;
                        --      new_step:= get_larghezza_corsia+(get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti);
                        --   end if;
                        --end if;

                        mailbox.set_move_parameters_entity_on_traiettoria_ingresso(mezzo,list_abitanti,mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),traiettoria_da_percorrere,range_1,new_speed,new_step,step_is_just_calculated);
                        if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti=list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti then
                           Put_Line("SAME POSITION ABITANTE id quartiere: " & Positive'Image(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                           get_log_stallo_quartiere.write_state_stallo(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,True);
                        else
                           get_log_stallo_quartiere.write_state_stallo(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,False);
                        end if;

                     end if;
                     list_abitanti:= next_abitante;
                  end loop;

               end loop;

               -- configurazione precedenze bipedi
               precedenze_bici_bipedi_su_tratto:= False;
               for h in 1..2 loop
                  entity_length:= 0.0;
                  if h=2 then
                     list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),entrata_dritto_pedoni);
                  else
                     list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),entrata_dritto_bici);
                  end if;
                  while list_abitanti/=null loop -- and then list_abitanti.get_next_from_list_posizione_abitanti/=null loop
                     if h=2 then
                        entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                     else
                        entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                     end if;
                     if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_default_larghezza_corsia*2.0 and
                       (list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_larghezza_corsia*3.0 or else
                        list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length<get_larghezza_corsia*3.0) then
                        precedenze_bici_bipedi_su_tratto:= True;
                     end if;
                     list_abitanti:= list_abitanti.get_next_from_list_posizione_abitanti;
                  end loop;
               end loop;

               for h in 1..2 loop
                  if h=2 then
                     list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),entrata_dritto_pedoni);
                     other_list_abitanti:= get_ingressi_segmento_resources(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider)).get_first_abitante_to_exit_from_urbana(walking);
                     mezzo:= walking;
                     traiettoria_da_percorrere:= entrata_dritto_pedoni;
                  else
                     list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),entrata_dritto_bici);
                     other_list_abitanti:= get_ingressi_segmento_resources(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider)).get_first_abitante_to_exit_from_urbana(bike);
                     mezzo:= bike;
                     traiettoria_da_percorrere:= entrata_dritto_bici;
                  end if;
                  while list_abitanti/=null loop
                     stop_entity:= False;
                     next_entity_distance:= 0.0;
                     next_id_quartiere_abitante:= 0;
                     next_id_abitante:= 0;
                     next_abitante_velocity:= 0.0;
                     step_is_just_calculated:= False;
                     --Put_Line(new_float'Image(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti));
                     --if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>21.0 and list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti=118 then
                     --   stop_entity:= False;
                     --end if;
                     next_abitante:= list_abitanti.get_next_from_list_posizione_abitanti;

                     if (list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_larghezza_corsia*2.0 and
                           list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia=False) and
                       (list_abitanti.get_next_from_list_posizione_abitanti=null or else list_abitanti.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_larghezza_corsia*4.0) then
                        if mailbox.get_num_stalli_for_bipedi_in_ingresso(entrata_dritto_bici,mailbox.get_key_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),not_ordered),True)=0 then
                           other_list:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),entrata_ritorno);
                           if other_list/=null and then ((other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie and other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie) and
                                                           other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia) then
                              null;
                           else
                              other_list:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),uscita_ritorno);
                              if other_list/=null and then ((other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie and other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(uscita_ritorno).get_intersezioni.get_distanza_intersezione-max_larghezza_veicolo) and
                                                              other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia) then
                                 null;
                              else
                                 mailbox.increase_num_stalli_for_bipede_in_ingresso(traiettoria_da_percorrere,mailbox.get_key_ingresso(ingresso.get_id_road,not_ordered),True,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                              end if;
                           end if;
                        else
                           mailbox.increase_num_stalli_for_bipede_in_ingresso(traiettoria_da_percorrere,mailbox.get_key_ingresso(ingresso.get_id_road,not_ordered),True,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                        end if;
                     end if;
                     other_list:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),entrata_ritorno);
                     if (((list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_larghezza_corsia*4.0 and
                             (list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia=False and list_abitanti.get_next_from_list_posizione_abitanti=null)) and
                            (other_list=null or else (other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_ingresso(entrata_ritorno).get_intersezione_bipedi and other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken=False))) and
                           (mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),entrata_andata)=null or else mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),entrata_andata).get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken=False)) then
                        mailbox.increase_num_stalli_for_bipede_in_ingresso(traiettoria_da_percorrere,mailbox.get_key_ingresso(ingresso.get_id_road,not_ordered),False,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                     end if;

                     if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_larghezza_corsia*4.0 then
                        if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_larghezza_corsia then
                           distance_to_stop_line:= get_larghezza_corsia*2.0-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                        elsif list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_larghezza_corsia then
                           distance_to_stop_line:= get_larghezza_corsia*2.0-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                        elsif list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_larghezza_corsia*2.0 then
                           if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_larghezza_corsia*2.0 then
                              if next_abitante/=null then
                                 distance_to_next:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                                 if h=1 then
                                    distance_to_next:= distance_to_next-get_quartiere_utilities_obj.get_bici_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                    costante_additiva:= min_bici_distance;
                                 else
                                    distance_to_next:= distance_to_next-get_quartiere_utilities_obj.get_pedone_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                    costante_additiva:= min_pedone_distance;
                                 end if;
                                 distance_to_next:= distance_to_next-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                                 if distance_to_next-costante_additiva<0.0 then
                                    stop_entity:= True;
                                 end if;
                              end if;
                           end if;

                           if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia then
                              distance_to_stop_line:= get_larghezza_corsia*4.0-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;

                              -- OCCORRE DISABILITARE A MANINA
                              -- QUESTO CASO SI PUÒ PRESENTARE SOLO SE È STATO ABILITATO L'AVANZAMENTO
                              -- DEI BIPEDI PER NUMERO DI STALLI SUPERATO
                              --other_list:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),entrata_andata);
                              --if other_list/=null then
                              --   stop_entity:= True;
                              --end if;
                           else
                              if (next_abitante/=null and then next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_larghezza_corsia*2.0) and precedenze_bici_bipedi_su_tratto then
                                 mailbox.set_flag_abitante_can_overtake_to_next_corsia(list_abitanti,True);
                                 distance_to_stop_line:= get_larghezza_corsia*4.0-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                              else
                                 if next_abitante/=null then
                                    if next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_larghezza_corsia*2.0 then
                                       -- next_abitante si trova a distanza = a corsia*2+marciapiede
                                       -- lo si annulla in modo da far prevalere distance_to_stop_line
                                       next_abitante:= null;
                                    end if;
                                 end if;
                                 distance_to_stop_line:= get_larghezza_corsia*2.0-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                              end if;
                           end if;
                        else
                           distance_to_stop_line:= get_larghezza_corsia*4.0-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                        end if;
                        if next_abitante/=null then
                           if next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_larghezza_corsia*4.0 then
                              next_abitante:= null;
                           else
                              if mezzo=bike then
                                 next_entity_distance:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_bici_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                              else
                                 next_entity_distance:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_pedone_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                              end if;
                              next_id_quartiere_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                              next_id_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                              next_abitante_velocity:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                           end if;
                        end if;
                     else
                        -- l'abitante deve controllare se può attraversare per immettersi nell'ingresso
                        if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia then
                           segnale:= False;
                           if next_abitante=null then
                              next_abitante:= other_list_abitanti;
                              next_entity_distance:= get_larghezza_marciapiede+get_larghezza_corsia*4.0;
                              segnale:= True;
                           end if;
                           if next_abitante/=null then
                              if mezzo=bike then
                                 next_entity_distance:= next_entity_distance+next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_bici_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                                 costante_additiva:= min_bici_distance;
                              else
                                 next_entity_distance:= next_entity_distance+next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_pedone_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                                 costante_additiva:= min_pedone_distance;
                              end if;
                              if segnale=False and next_entity_distance-costante_additiva<0.0 then
                                 stop_entity:= True;
                              end if;
                              next_id_quartiere_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                              next_id_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                              next_abitante_velocity:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                           else
                              -- non c'è l'abitante nell'ingresso
                              -- occorre azzerare la distanza precedentemente settata
                              next_entity_distance:= 0.0;
                           end if;
                           distance_to_stop_line:= ingresso.get_lunghezza_road+get_traiettoria_ingresso(entrata_dritto_bici).get_lunghezza-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                        else
                           stop_entity:= True;
                        end if;
                     end if;

                     if stop_entity=False then
                        speed_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                        acceleration:= calculate_acceleration(mezzo                      => mezzo,
                                                             id_abitante                => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                             id_quartiere_abitante      => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                             next_entity_distance       => next_entity_distance,
                                                             distance_to_stop_line      => distance_to_stop_line,
                                                             next_id_quartiere_abitante => next_id_quartiere_abitante,
                                                             next_id_abitante           => next_id_abitante,
                                                             abitante_velocity          => speed_abitante,
                                                             next_abitante_velocity     => next_abitante_velocity,
                                                             disable_rallentamento_1    => True,
                                                             disable_rallentamento_2    => True,
                                                              request_by_incrocio => True);

                        new_speed:= calculate_new_speed(speed_abitante,acceleration);
                        new_step:= calculate_new_step(new_speed,acceleration);
                        step_is_just_calculated:= False;

                        fix_advance_parameters(mezzo,acceleration,new_speed,new_step,speed_abitante,next_entity_distance,distance_to_stop_line);

                        if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+distance_to_stop_line then
                           new_step:= distance_to_stop_line;
                        end if;

                        -- NELLO SPOSTAMENTO PEDONI, NELL'UPDATE CONTROLLA SE SI DEVE METTERE NELL'INGRESSO
                        mailbox.set_move_parameters_entity_on_traiettoria_ingresso(mezzo,list_abitanti,mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),traiettoria_da_percorrere,range_1,new_speed,new_step,step_is_just_calculated);

                        if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti=list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti then
                           Put_Line("SAME POSITION ABITANTE id quartiere: " & Positive'Image(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                           get_log_stallo_quartiere.write_state_stallo(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,True);
                        else
                           get_log_stallo_quartiere.write_state_stallo(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,False);
                        end if;

                        if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>=get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza then
                           if list_abitanti.get_next_from_list_posizione_abitanti/=null then
                              Put_Line("next abitante is id:" & Positive'Image(list_abitanti.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " " & Positive'Image(list_abitanti.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti));
                              raise lista_abitanti_rotta;
                           end if;
                           new_abitante:= posizione_abitanti_on_road(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti);
                           new_abitante.set_where_next_abitante(new_abitante.get_where_next_posizione_abitanti-get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza);
                           new_abitante.set_where_now_abitante(new_abitante.get_where_next_posizione_abitanti);
                           get_ingressi_segmento_resources(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider)).new_bipede_finish_route(new_abitante,h);
                        end if;

                     end if;

                     list_abitanti:= list_abitanti.get_next_from_list_posizione_abitanti;
                  end loop;
               end loop;

               -- spostamento: entrata_destra_pedoni/bici
               -- controlla se ci sono abitanti che intersecano nella traiettoria entrata_destra_pedoni/bici
               stop_entity:= False;
               -- end controllo
               if stop_entity=False then
                  for h in 1..2 loop
                     if h=1 then
                        list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),entrata_destra_bici);
                        other_list_abitanti:= get_ingressi_segmento_resources(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider)).get_first_abitante_to_exit_from_urbana(bike);
                        mezzo:= bike;
                        traiettoria_da_percorrere:= entrata_destra_bici;
                     else
                        list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),entrata_destra_pedoni);
                        other_list_abitanti:= get_ingressi_segmento_resources(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider)).get_first_abitante_to_exit_from_urbana(walking);
                        mezzo:= walking;
                        traiettoria_da_percorrere:= entrata_destra_pedoni;
                     end if;

                     while list_abitanti/=null loop

                        stop_entity:= False;
                        next_entity_distance:= 0.0;
                        next_id_quartiere_abitante:= 0;
                        next_id_abitante:= 0;
                        next_abitante_velocity:= 0.0;

                        --if mezzo=walking then
                        --   if list_abitanti.get_next_from_list_posizione_abitanti/=null then
                        --      stop_entity:= True;
                        --   end if;
                        --end if;

                        if list_abitanti.get_next_from_list_posizione_abitanti/=null then
                           stop_entity:= True;
                        elsif list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 then
                           if h=2 and then (list_abitanti_sidewalk_pedoni/=null and then (list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=distance_ingresso-get_larghezza_marciapiede-get_larghezza_corsia and then
                                                                                            (list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=distance_ingresso-get_larghezza_corsia or else
                                                                                             list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_pedone_quartiere(list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<=distance_ingresso-get_larghezza_corsia))) then
                              stop_entity:= True;
                           end if;
                           if h=1 and then (list_abitanti_sidewalk_bici/=null and then (list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=distance_ingresso-get_larghezza_marciapiede-get_larghezza_corsia and then
                                                                                          (list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=distance_ingresso-get_larghezza_corsia or else
                                                                                           list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_bici_quartiere(list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<=distance_ingresso-get_larghezza_corsia))) then
                              stop_entity:= True;
                           end if;
                           if h=1 then
                              -- caso bici
                              if mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),entrata_destra_pedoni)=null then
                                 if prec_list_abitanti_sidewalk_pedoni/=null and then prec_list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance_ingresso-get_larghezza_corsia*2.0-get_larghezza_marciapiede then
                                    stop_entity:= True;
                                 end if;
                              end if;
                           end if;
                           if stop_entity=False then
                              list_abitanti_pedoni:= mailbox.get_last_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),entrata_dritto_pedoni);
                              list_abitanti_bici:= mailbox.get_last_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),entrata_dritto_bici);
                              if (list_abitanti_pedoni/=null and then (list_abitanti_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_larghezza_corsia*4.0 or list_abitanti_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia)) or else
                                (list_abitanti_bici/=null and then (list_abitanti_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_larghezza_corsia*4.0 or list_abitanti_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia)) then
                                 stop_entity:= True;
                              end if;
                              if stop_entity=False then
                                 other_list:= get_ingressi_segmento_resources(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider)).get_first_abitante_to_exit_from_urbana(walking);
                                 if other_list/=null and then (other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_pedone_quartiere(other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<0.0) then
                                    stop_entity:= True;
                                 end if;
                                 other_list:= get_ingressi_segmento_resources(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider)).get_first_abitante_to_exit_from_urbana(bike);
                                 if other_list/=null and then (other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_bici_quartiere(other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<0.0) then
                                    stop_entity:= True;
                                 end if;
                              end if;
                           end if;
                        end if;

                        if stop_entity=False then
                           next_abitante:= list_abitanti.get_next_from_list_posizione_abitanti;
                           next_entity_distance:= 0.0;
                           if next_abitante=null then
                              next_entity_distance:= get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza;
                              if mezzo=walking then
                                 next_abitante:= get_ingressi_segmento_resources(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider)).get_first_abitante_to_exit_from_urbana(walking);
                              else
                                 next_abitante:= get_ingressi_segmento_resources(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider)).get_first_abitante_to_exit_from_urbana(bike);
                              end if;
                           end if;
                           if next_abitante/=null then
                              if mezzo=walking then
                                 next_entity_distance:= next_entity_distance+next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_pedone_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                              else
                                 next_entity_distance:= next_entity_distance+next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_bici_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                              end if;
                              next_id_quartiere_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                              next_id_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                              next_abitante_velocity:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                           end if;
                           -- controllo se la distanza minima viene rispettata
                           if next_abitante/=null then
                              if mezzo=walking then
                                 if next_entity_distance<min_pedone_distance then
                                    stop_entity:= True;
                                 end if;
                              else
                                 if next_entity_distance<min_bici_distance then
                                    stop_entity:= True;
                                 end if;
                              end if;
                           end if;
                        end if;

                        if stop_entity=False then
                           distance_to_stop_line:= ingresso.get_lunghezza_road+get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                           speed_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                           acceleration:= calculate_acceleration(mezzo                      => mezzo,
                                                           id_abitante                => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                           id_quartiere_abitante      => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                           next_entity_distance       => next_entity_distance,
                                                           distance_to_stop_line      => distance_to_stop_line,
                                                           next_id_quartiere_abitante => next_id_quartiere_abitante,
                                                           next_id_abitante           => next_id_abitante,
                                                           abitante_velocity          => speed_abitante,
                                                           next_abitante_velocity     => next_abitante_velocity,
                                                           disable_rallentamento_1    => True,
                                                           disable_rallentamento_2    => True,
                                                           request_by_incrocio => True);

                           new_speed:= calculate_new_speed(speed_abitante,acceleration);
                           new_step:= calculate_new_step(new_speed,acceleration);

                           step_is_just_calculated:= False;
                           fix_advance_parameters(mezzo,acceleration,new_speed,new_step,speed_abitante,next_entity_distance,distance_to_stop_line);

                           mailbox.set_move_parameters_entity_on_traiettoria_ingresso(mezzo,list_abitanti,mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),traiettoria_da_percorrere,range_1,new_speed,new_step,step_is_just_calculated);

                           if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti=list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti then
                              Put_Line("SAME POSITION ABITANTE id quartiere: " & Positive'Image(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                              get_log_stallo_quartiere.write_state_stallo(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,True);
                           else
                              get_log_stallo_quartiere.write_state_stallo(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,False);
                           end if;

                           if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>=get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza then
                              if list_abitanti.get_next_from_list_posizione_abitanti/=null then
                                 Put_Line("next abitante is id:" & Positive'Image(list_abitanti.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " " & Positive'Image(list_abitanti.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti));
                                 raise lista_abitanti_rotta;
                              end if;
                              new_abitante:= posizione_abitanti_on_road(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti);
                              new_abitante.set_where_next_abitante(new_abitante.get_where_next_posizione_abitanti-get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza);
                              new_abitante.set_where_now_abitante(new_abitante.get_where_next_posizione_abitanti);
                              get_ingressi_segmento_resources(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider)).new_bipede_finish_route(new_abitante,h);
                           end if;
                        end if;

                        list_abitanti:= list_abitanti.get_next_from_list_posizione_abitanti;
                     end loop;

                  end loop;
               end if;

               -- spostamento uscita_destra_(bici/pedoni)
               -- in queste traiettorie si muove un bipede per volta

               -- AGGIORNAMENTO DI list_abitanti_sidewalk_bici/pedoni ALLA POSIZIONE CORRETTA
               signal:= True;
               while list_abitanti_sidewalk_bici/=null and signal loop
                  if list_abitanti_sidewalk_bici.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<distance_ingresso+get_larghezza_marciapiede+get_larghezza_corsia then
                     prec_list_abitanti_sidewalk_bici:= list_abitanti_sidewalk_bici;
                     list_abitanti_sidewalk_bici:= list_abitanti_sidewalk_bici.get_next_from_list_posizione_abitanti;
                  else
                     signal:= False;
                  end if;
               end loop;

               signal:= True;
               while list_abitanti_sidewalk_pedoni/=null and signal loop
                  if list_abitanti_sidewalk_pedoni.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<distance_ingresso+get_larghezza_marciapiede+get_larghezza_corsia then
                     prec_list_abitanti_sidewalk_pedoni:= list_abitanti_sidewalk_pedoni;
                     list_abitanti_sidewalk_pedoni:= list_abitanti_sidewalk_pedoni.get_next_from_list_posizione_abitanti;
                  else
                     signal:= False;
                  end if;
               end loop;

               for h in 1..2 loop

                  costante_additiva:= 0.0;
                  stop_entity:= False;
                  next_entity_distance:= 0.0;
                  next_id_quartiere_abitante:= 0;
                  next_id_abitante:= 0;
                  next_abitante_velocity:= 0.0;

                  if h=1 then
                     list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),uscita_destra_bici);
                     next_abitante:= list_abitanti_sidewalk_bici;
                     mezzo:= bike;
                     traiettoria_da_percorrere:= uscita_destra_bici;
                  else
                     list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),uscita_destra_pedoni);
                     next_abitante:= list_abitanti_sidewalk_pedoni;
                     mezzo:= walking;
                     traiettoria_da_percorrere:= uscita_destra_pedoni;
                  end if;

                  -- controlla se ocorre dare precedenze a bipedi già in transito in direzione
                  -- uguale a quella dei bipedi in uscita_destra_(bici/pedoni)
                  if list_abitanti/=null and then list_abitanti.get_next_from_list_posizione_abitanti/=null then
                     list_abitanti:= list_abitanti.get_next_from_list_posizione_abitanti;
                  end if;

                  if list_abitanti/=null and then (list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 and
                    list_abitanti.get_next_from_list_posizione_abitanti=null) then
                     mailbox.increase_num_stalli_for_bipede_in_ingresso(traiettoria_da_percorrere,mailbox.get_key_ingresso(ingresso.get_id_road,not_ordered),False,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                  end if;

                  if list_abitanti/=null and then list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 then
                     if h=1 then
                        for j in 1..2 loop
                           entity_length:= 0.0;
                           costante_additiva:= 0.0;
                           if j=1 then
                              other_list_abitanti:= list_abitanti_sidewalk_bici;
                              prec_other_list_abitanti:= prec_list_abitanti_sidewalk_bici;
                              if other_list_abitanti/=null then
                                 entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                 costante_additiva:= min_bici_distance;
                              end if;
                           else
                              other_list_abitanti:= list_abitanti_sidewalk_pedoni;
                              prec_other_list_abitanti:= prec_list_abitanti_sidewalk_pedoni;
                              if other_list_abitanti/=null then
                                 entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                 costante_additiva:= min_pedone_distance;
                              end if;
                           end if;

                           if prec_other_list_abitanti/=null and then prec_other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>=distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede then
                              stop_entity:= True;
                           end if;

                           if other_list_abitanti/=null and then other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length<=distance_ingresso+get_larghezza_corsia+get_larghezza_marciapiede+costante_additiva then
                              stop_entity:= True;
                           end if;
                        end loop;
                     else
                        other_list_abitanti:= list_abitanti_sidewalk_pedoni;
                        prec_other_list_abitanti:= prec_list_abitanti_sidewalk_pedoni;
                        if other_list_abitanti/=null then
                           entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                           costante_additiva:= min_pedone_distance;
                        end if;

                        if prec_other_list_abitanti/=null and then prec_other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>=distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede then
                           stop_entity:= True;
                        end if;

                        if other_list_abitanti/=null and then other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length<=distance_ingresso+get_larghezza_corsia+get_larghezza_marciapiede+costante_additiva then
                           stop_entity:= True;
                        end if;
                     end if;

                  --   if stop_entity=False then
                  --      if h=1 then
                  --         for j in 1..2 loop
                  --            entity_length:= 0.0;
                  --            if j=1 then
                  --               other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),uscita_dritto_bici);
                  --               if other_list_abitanti/=null then
                  --                  entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                  --               end if;
                  --            else
                  --               other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),uscita_dritto_pedoni);
                  --               if other_list_abitanti/=null then
                  --                  entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                  --               end if;
                  --            end if;
                  --            if other_list_abitanti/=null and then (other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_larghezza_marciapiede or else
                  --                                                other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length<=get_larghezza_marciapiede) then
                  --               stop_entity:= True;
                  --            end if;
                  --         end loop;
                  --      else
                  --         other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),uscita_dritto_pedoni);
                  --         if other_list_abitanti/=null then
                  --            entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                  --         end if;

                  --         if other_list_abitanti/=null and then (other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_larghezza_marciapiede or else
                  --                                                other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length<=get_larghezza_marciapiede) then
                  --            stop_entity:= True;
                  --         end if;
                  --      end if;
                  --   end if;

                  end if;

                  -- other_list_abitanti si trova già o dopo l'ingresso
                  -- o in una posizione tra l'inizio ingresso e la fine dell'ingresso

                  if list_abitanti/=null and then stop_entity=False then
                     distance_to_stop_line:= get_urbana_from_id(id_task).get_lunghezza_road-distance_ingresso+get_larghezza_corsia+get_larghezza_marciapiede+get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;

                     if list_abitanti/=null then
                        if list_abitanti.get_next_from_list_posizione_abitanti/=null then
                           next_abitante:= list_abitanti.get_next_from_list_posizione_abitanti;
                        end if;
                     end if;
                     -- il next è proprio next_abitante preso precedentemente
                     -- occorre controllare se next_abitante si trovi prima o
                     -- dopo il successivo ingresso se ve ne sono
                     indice:= z+1;
                     costante_additiva:= -1.0;
                     if indice<=mailbox.get_ordered_ingressi_from_polo(range_1).all'Last then
                        costante_additiva:= get_distance_from_polo_percorrenza(get_ingresso_from_id(mailbox.get_index_ingresso_from_key(indice,current_ingressi_structure_type_to_consider)),range_1)-get_larghezza_marciapiede-get_larghezza_corsia;
                     end if;

                     if next_abitante/=null then
                        if costante_additiva>0.0 and then (next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>costante_additiva) then
                           next_entity_distance:= (costante_additiva-distance_ingresso)/2.0;
                        else
                           if mezzo=bike then
                              next_entity_distance:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_bici_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                           else
                              next_entity_distance:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_pedone_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                           end if;
                           next_entity_distance:= next_entity_distance-distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede+get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                           next_id_quartiere_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                           next_id_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                           next_abitante_velocity:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                        end if;
                     else
                        -- se non si ha un'abitante come next si imposta il seguente limite come distanza
                        if costante_additiva>0.0 then
                           next_entity_distance:= (costante_additiva-distance_ingresso)/2.0;
                        else
                           -- si fissa la distanza massima a metà rispetto alla distance_to_stop_line
                           next_entity_distance:= distance_to_stop_line/2.0;
                        end if;
                     end if;


                     speed_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                     acceleration:= calculate_acceleration(mezzo                      => mezzo,
                                                           id_abitante                => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                           id_quartiere_abitante      => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                           next_entity_distance       => next_entity_distance,
                                                           distance_to_stop_line      => distance_to_stop_line,
                                                           next_id_quartiere_abitante => next_id_quartiere_abitante,
                                                           next_id_abitante           => next_id_abitante,
                                                           abitante_velocity          => speed_abitante,
                                                           next_abitante_velocity     => next_abitante_velocity,
                                                           disable_rallentamento_1    => True,
                                                           disable_rallentamento_2    => True,
                                                              request_by_incrocio => True);

                     new_speed:= calculate_new_speed(speed_abitante,acceleration);
                     new_step:= calculate_new_step(new_speed,acceleration);

                     step_is_just_calculated:= False;
                     fix_advance_parameters(mezzo,acceleration,new_speed,new_step,speed_abitante,next_entity_distance,distance_to_stop_line);

                     mailbox.set_move_parameters_entity_on_traiettoria_ingresso(mezzo,list_abitanti,mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),traiettoria_da_percorrere,range_1,new_speed,new_step,step_is_just_calculated);

                     if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti=list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti then
                        Put_Line("SAME POSITION ABITANTE id quartiere: " & Positive'Image(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                        get_log_stallo_quartiere.write_state_stallo(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,True);
                     else
                        get_log_stallo_quartiere.write_state_stallo(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,False);
                     end if;
                  end if;
               end loop;

               -- spostamento uscita_dritto_(bici_pedoni)
               -- configurazione precedenze bipedi
               for i in 1..2 loop
                  precedenze_bici_bipedi_su_tratto_uscita(i):= False;
               end loop;

               for h in 1..2 loop
                  entity_length:= 0.0;
                  if h=1 then
                     list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),uscita_dritto_bici);
                  else
                     list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),uscita_dritto_pedoni);
                  end if;
                  while list_abitanti/=null loop
                     if h=2 then
                        entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                     else
                        entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                     end if;
                     if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_default_larghezza_corsia+get_larghezza_marciapiede or else
                       list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length<get_default_larghezza_corsia+get_larghezza_marciapiede then
                        precedenze_bici_bipedi_su_tratto_uscita(1):= True;
                     elsif list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_default_larghezza_corsia*2.0+get_larghezza_marciapiede and
                       (list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_default_larghezza_corsia*3.0+get_larghezza_marciapiede or else
                        list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length<get_default_larghezza_corsia*3.0+get_larghezza_marciapiede) then
                        precedenze_bici_bipedi_su_tratto_uscita(2):= True;
                     end if;
                     list_abitanti:= list_abitanti.get_next_from_list_posizione_abitanti;
                  end loop;
               end loop;

               for h in 1..2 loop
                  next_abitante_length:= 0.0;
                  if h=1 then
                     list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),uscita_dritto_bici);
                     other_list:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),uscita_ritorno_bici);
                     if other_list/=null then
                        next_abitante_length:= other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_bici_quartiere(other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                     end if;
                     traiettoria_da_percorrere:= uscita_dritto_bici;
                     mezzo:= bike;
                  else
                     list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),uscita_dritto_pedoni);
                     other_list:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),uscita_ritorno_pedoni);
                     if other_list/=null then
                        next_abitante_length:= other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_pedone_quartiere(other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                     end if;
                     traiettoria_da_percorrere:= uscita_dritto_pedoni;
                     mezzo:= walking;
                  end if;

                  while list_abitanti/=null loop
                     stop_entity:= False;
                     next_entity_distance:= 0.0;
                     next_id_quartiere_abitante:= 0;
                     next_id_abitante:= 0;
                     next_abitante_velocity:= 0.0;
                     step_is_just_calculated:= False;
                     next_abitante:= list_abitanti.get_next_from_list_posizione_abitanti;

                     if ((list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 and
                       list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia=False) and (mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),uscita_andata)=null or else (mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),uscita_andata).get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia=False or mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),uscita_andata).get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0))) then
                        if list_abitanti.get_next_from_list_posizione_abitanti=null or else list_abitanti.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_larghezza_corsia+get_larghezza_marciapiede*2.0 then
                           mailbox.increase_num_stalli_for_bipede_in_ingresso(traiettoria_da_percorrere,mailbox.get_key_ingresso(ingresso.get_id_road,not_ordered),True,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                        end if;
                     end if;
                     if (list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_larghezza_corsia*2.0+get_larghezza_marciapiede and
                       list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia=False) and (list_abitanti.get_next_from_list_posizione_abitanti=null or else list_abitanti.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_larghezza_corsia*2.0+get_larghezza_marciapiede) then
                        if list_abitanti.get_next_from_list_posizione_abitanti=null or else list_abitanti.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_larghezza_corsia*4.0 then
                           mailbox.increase_num_stalli_for_bipede_in_ingresso(traiettoria_da_percorrere,mailbox.get_key_ingresso(ingresso.get_id_road,not_ordered),False,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                        end if;
                     end if;

                     if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 and list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia=False then
                        if next_abitante/=null then
                           if h=1 then
                              --costante_additiva:= min_bici_distance;
                              entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                           else
                              --costante_additiva:= min_pedone_distance;
                              entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                           end if;
                           if next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length-get_larghezza_marciapiede<0.0 then
                              stop_entity:= True;
                           end if;
                        end if;

                        if stop_entity=False then
                           for j in 1..2 loop
                              entity_length:= 0.0;
                              if j=1 then
                                 other_list_abitanti:= list_abitanti_sidewalk_bici;
                                 prec_other_list_abitanti:= prec_list_abitanti_sidewalk_bici;
                                 if other_list_abitanti/=null then
                                    entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                 end if;
                              else
                                 other_list_abitanti:= list_abitanti_sidewalk_pedoni;
                                 prec_other_list_abitanti:= prec_list_abitanti_sidewalk_pedoni;
                                 if other_list_abitanti/=null then
                                    entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                 end if;
                              end if;

                              if prec_other_list_abitanti/=null and then prec_other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>=distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede then
                                 stop_entity:= True;
                              end if;

                              if other_list_abitanti/=null and then other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length<=distance_ingresso+get_larghezza_corsia+get_larghezza_marciapiede then
                                 stop_entity:= True;
                              end if;
                           end loop;
                        end if;

                        --if stop_entity=False then
                        --   if h=1 then
                        --      other_list:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),uscita_destra_bici);
                        --      if other_list/=null then
                        --         stop_entity:= True;
                        --      end if;
                        --   else
                        --      for j in 1..2 loop
                        --         if j=1 then
                        --            other_list:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),uscita_destra_bici);
                        --            if other_list/=null and then other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>0.0 then
                        --               stop_entity:= True;
                        --            end if;
                        --         else
                        --            other_list:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),uscita_destra_pedoni);
                        --            if other_list/=null then
                        --               stop_entity:= True;
                        --            end if;
                        --         end if;

                        --      end loop;
                        --   end if;
                        --end if;

                        if stop_entity=False then
                           other_list:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),uscita_andata);
                           if other_list/=null and then other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia then
                              stop_entity:= True;
                           end if;
                        end if;

                        if stop_entity=False then
                           if mailbox.get_abilitazione_attraversamento_ingresso(range_1,range_1,z,True) then
                              mailbox.set_flag_abitante_can_overtake_to_next_corsia(list_abitanti,True);
                           end if;
                           if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia=False then
                              if precedenze_bici_bipedi_su_tratto_uscita(1)=False then
                                 stop_entity:= True;
                              else
                                 distance_to_stop_line:= get_larghezza_corsia*2.0+get_larghezza_marciapiede;
                              end if;
                           else
                              distance_to_stop_line:= get_larghezza_corsia*2.0+get_larghezza_marciapiede;
                           end if;
                        end if;
                     --elsif list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 then
                        -- il flag qui sarà a True, abilitato o per situazione regolare o per numero di stalli max
                     --   other_list_abitanti:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),uscita_andata);
                     --   if other_list_abitanti/=null and then other_list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 then
                     --      stop_entity:= True;
                     --   end if;

                     else
                        if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_larghezza_corsia+get_larghezza_marciapiede then
                           distance_to_stop_line:= get_larghezza_corsia*2.0+get_larghezza_marciapiede-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                        elsif list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_larghezza_corsia+get_larghezza_marciapiede then
                           distance_to_stop_line:= get_larghezza_corsia*2.0+get_larghezza_marciapiede-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                        elsif list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_larghezza_corsia*2.0+get_larghezza_marciapiede then
                           if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_larghezza_corsia*2.0+get_larghezza_marciapiede then
                              if next_abitante/=null then
                                 distance_to_next:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                                 if h=1 then
                                    distance_to_next:= distance_to_next-get_quartiere_utilities_obj.get_bici_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                    costante_additiva:= min_bici_distance;
                                 else
                                    distance_to_next:= distance_to_next-get_quartiere_utilities_obj.get_pedone_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                    costante_additiva:= min_pedone_distance;
                                 end if;
                                 distance_to_next:= distance_to_next-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                                 if distance_to_next-costante_additiva<0.0 then
                                    stop_entity:= True;
                                 end if;
                              end if;
                           end if;

                           if h=1 then
                              costante_additiva:= get_larghezza_corsia*4.0+get_larghezza_marciapiede-min_bici_distance-min_length_bici;
                           else
                              costante_additiva:= get_larghezza_corsia*4.0+get_larghezza_marciapiede-min_pedone_distance-min_length_pedoni;
                           end if;

                           if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia then
                              distance_to_stop_line:= costante_additiva-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                           else
                              if (next_abitante/=null and then next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_larghezza_corsia*2.0+get_larghezza_marciapiede) and precedenze_bici_bipedi_su_tratto_uscita(2) then
                                 mailbox.set_flag_abitante_can_overtake_to_next_corsia(list_abitanti,True);
                                 distance_to_stop_line:= costante_additiva-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                              else
                                 if next_abitante/=null then
                                    if next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_larghezza_corsia*2.0+get_larghezza_marciapiede then
                                       -- next_abitante si trova a distanza = a corsia*2+marciapiede
                                       -- lo si annulla in modo da far prevalere distance_to_stop_line
                                       next_abitante:= null;
                                    end if;
                                 end if;
                                 distance_to_stop_line:= get_larghezza_corsia*2.0+get_larghezza_marciapiede-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                              end if;
                           end if;
                        else
                           if h=1 then
                              costante_additiva:= get_larghezza_corsia*4.0+get_larghezza_marciapiede-min_bici_distance-min_length_bici;
                           else
                              costante_additiva:= get_larghezza_corsia*4.0+get_larghezza_marciapiede-min_pedone_distance-min_length_pedoni;
                           end if;

                           distance_to_stop_line:= costante_additiva-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                           if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=costante_additiva then
                              if next_abitante/=null then
                                 if next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=costante_additiva then
                                    next_abitante:= null;
                                 end if;
                              else
                                 distance_to_stop_line:= get_larghezza_corsia*4.0+get_larghezza_marciapiede-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                              end if;
                           else
                              distance_to_stop_line:= get_larghezza_corsia*4.0+get_larghezza_marciapiede-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                           end if;
                        end if;
                     end if;

                     if stop_entity=False then

                        if next_abitante/=null then
                           if mezzo=walking then
                              entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                           else
                              entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                           end if;
                           next_entity_distance:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                           next_id_quartiere_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                           next_id_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                           next_abitante_velocity:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                        else
                           if next_abitante_length<0.0 then
                              next_entity_distance:= get_traiettoria_ingresso(traiettoria_da_percorrere).get_lunghezza-abs(next_abitante_length)-list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                           else
                              next_entity_distance:= 0.0;
                           end if;
                           if other_list/=null then
                              next_id_quartiere_abitante:= other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                              next_id_abitante:= other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                              next_abitante_velocity:= other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                           end if;
                        end if;

                        speed_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                        acceleration:= calculate_acceleration(mezzo                      => mezzo,
                                                              id_abitante                => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                              id_quartiere_abitante      => list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                              next_entity_distance       => next_entity_distance,
                                                              distance_to_stop_line      => distance_to_stop_line,
                                                              next_id_quartiere_abitante => next_id_quartiere_abitante,
                                                              next_id_abitante           => next_id_abitante,
                                                              abitante_velocity          => speed_abitante,
                                                              next_abitante_velocity     => next_abitante_velocity,
                                                              disable_rallentamento_1    => True,
                                                              disable_rallentamento_2    => True,
                                                              request_by_incrocio => True);

                        new_speed:= calculate_new_speed(speed_abitante,acceleration);
                        new_step:= calculate_new_step(new_speed,acceleration);
                        step_is_just_calculated:= False;

                        fix_advance_parameters(mezzo,acceleration,new_speed,new_step,speed_abitante,next_entity_distance,distance_to_stop_line);

                        if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+distance_to_stop_line then
                           new_step:= distance_to_stop_line;
                        end if;

                        -- NELLO SPOSTAMENTO PEDONI, NELL'UPDATE CONTROLLA SE SI DEVE METTERE NELL'INGRESSO
                        mailbox.set_move_parameters_entity_on_traiettoria_ingresso(mezzo,list_abitanti,mailbox.get_index_ingresso_from_key(z,current_ingressi_structure_type_to_consider),traiettoria_da_percorrere,range_1,new_speed,new_step,step_is_just_calculated);

                        if list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti=list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti then
                           Put_Line("SAME POSITION ABITANTE id quartiere: " & Positive'Image(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                           get_log_stallo_quartiere.write_state_stallo(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,True);
                        else
                           get_log_stallo_quartiere.write_state_stallo(list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,False);
                        end if;
                     end if;

                     list_abitanti:= list_abitanti.get_next_from_list_posizione_abitanti;

                  end loop;

               end loop;

            end loop;
         end loop;



         -- END SPOSTAMENTO BICI/PEDONI

         current_polo_to_consider:= False;
         current_ingressi_structure_type_to_consider:= ordered_polo_false;
         current_ingressi_structure_type_to_not_consider:= ordered_polo_true;

         for h in 1..2 loop
            for i in reverse mailbox.get_ordered_ingressi_from_polo(current_polo_to_consider).all'Range loop

               ingresso:= get_ingresso_from_id(mailbox.get_index_ingresso_from_key(i,current_ingressi_structure_type_to_consider));

               distance_ingresso:= get_distance_from_polo_percorrenza(ingresso,current_polo_to_consider);

               list_abitanti_uscita_andata:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,uscita_andata);
               list_abitanti_uscita_ritorno:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,uscita_ritorno);
               list_abitanti_entrata_andata:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,entrata_andata);
               list_abitanti_entrata_ritorno:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,entrata_ritorno);


               for tipo_traiettoria in entrata_andata..uscita_andata loop
                  segnale:= False;
                  if tipo_traiettoria=uscita_andata and list_abitanti_uscita_andata/=null then
                     segnale:= True;
                     current_list_abitanti_traiettoria:= list_abitanti_uscita_andata;
                  end if;
                  if tipo_traiettoria=uscita_ritorno and list_abitanti_uscita_ritorno/=null then
                     segnale:= True;
                     current_list_abitanti_traiettoria:= list_abitanti_uscita_ritorno;
                  end if;
                  if tipo_traiettoria=entrata_andata and list_abitanti_entrata_andata/=null then
                     segnale:= True;
                     current_list_abitanti_traiettoria:= list_abitanti_entrata_andata;
                  end if;
                  if tipo_traiettoria=entrata_ritorno and list_abitanti_entrata_ritorno/=null then
                     segnale:= True;
                     current_list_abitanti_traiettoria:= list_abitanti_entrata_ritorno;
                  end if;
                  if segnale then
                     declare
                        --current_distance: new_float:= current_list_abitanti_traiettoria.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                        current_from_begin: Boolean;
                        current_int_bipedi: Boolean;
                        current_int_corsie: traiettorie_intersezioni_linee_corsie;
                        cur_prec_uscita_ritorno_on_entrata_ritorno: Boolean:= False;
                     begin
                        segnale:= False;
                        if current_list_abitanti_traiettoria.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 then
                           current_from_begin:= True;
                           current_int_bipedi:= False;
                           current_int_corsie:= linea_corsia;

                           if tipo_traiettoria=uscita_andata then
                              if list_abitanti_uscita_ritorno/=null then
                                 move_entity:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                                 if list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-move_entity.get_length_entità_passiva>=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                                    null;
                                 else
                                    segnale:= True;
                                 end if;
                              else
                                 segnale:= True;
                              end if;
                              if segnale then
                                 if list_abitanti_entrata_ritorno/=null then
                                    if list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia and list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                                       segnale:= False;
                                    end if;
                                 end if;
                              end if;
                           else
                              if tipo_traiettoria=uscita_ritorno then
                                 if list_abitanti_uscita_andata/=null then
                                    null;
                                 else
                                    segnale:= True;
                                 end if;
                                 if segnale then
                                    if list_abitanti_entrata_ritorno/=null then
                                       if list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia and list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                                          segnale:= False;
                                       end if;
                                    end if;
                                 end if;
                              else
                                 if tipo_traiettoria=entrata_andata then
                                    if list_abitanti_entrata_ritorno/=null then
                                       if list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia and list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                                          segnale:= False;
                                       end if;
                                    end if;
                                    if segnale then
                                       for l in 1..2 loop
                                          if l=1 then
                                             other_list:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,entrata_dritto_bici);
                                          else
                                             other_list:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,entrata_dritto_pedoni);
                                          end if;
                                          while segnale and other_list/=null loop
                                             if other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_larghezza_corsia*4.0 and
                                               other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken then
                                                segnale:= False;
                                             end if;
                                             other_list:= other_list.get_next_from_list_posizione_abitanti;
                                          end loop;
                                       end loop;
                                    end if;
                                 else
                                    segnale:= True;
                                 end if;
                              end if;
                           end if;
                        end if;
                        if tipo_traiettoria/=entrata_andata and tipo_traiettoria/=uscita_andata then
                           if current_list_abitanti_traiettoria.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(tipo_traiettoria).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                              current_from_begin:= False;
                              current_int_bipedi:= False;
                              current_int_corsie:= linea_corsia;

                              if tipo_traiettoria=entrata_ritorno then
                                 if list_abitanti_uscita_andata/=null then
                                    -- se l'abitante in uscita andata ha già il flag a True, entrata ritorno non può
                                    -- metterlo a True altrimenti si avrebbe un revert delle precedenze
                                    if list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia then
                                       null;
                                    else
                                       segnale:= True;
                                    end if;
                                 else
                                    segnale:= True;
                                 end if;
                                 if segnale then
                                    if list_abitanti_uscita_ritorno/=null then
                                       if list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia and list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                                          segnale:= False;
                                       end if;
                                    end if;
                                 end if;
                              else
                                 segnale:= True;
                              end if;
                           end if;
                           if current_list_abitanti_traiettoria.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(tipo_traiettoria).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                              current_from_begin:= False;
                              current_int_bipedi:= False;
                              current_int_corsie:= linea_mezzaria;
                              segnale:= True;
                           end if;
                           if current_list_abitanti_traiettoria.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(tipo_traiettoria).get_intersezione_bipedi then
                              current_from_begin:= False;
                              current_int_bipedi:= True;
                              current_int_corsie:= linea_corsia;
                              segnale:= True;

                              if tipo_traiettoria=entrata_ritorno then
                                 for l in 1..2 loop
                                    if l=1 then
                                       other_list:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,entrata_dritto_bici);
                                    else
                                       other_list:= mailbox.get_abitante_from_ingresso(ingresso.get_id_road,entrata_dritto_pedoni);
                                    end if;
                                    while segnale and other_list/=null loop
                                       if other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_larghezza_corsia*4.0 and
                                         other_list.get_posizione_abitanti_from_list_posizione_abitanti.get_in_overtaken then
                                          segnale:= False;
                                       end if;
                                       other_list:= other_list.get_next_from_list_posizione_abitanti;
                                    end loop;
                                 end loop;
                              end if;
                           end if;
                        end if;
                        if tipo_traiettoria=uscita_ritorno then
                           if current_list_abitanti_traiettoria.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(tipo_traiettoria).get_intersezioni.get_distanza_intersezione-max_larghezza_veicolo then
                              current_from_begin:= False;
                              current_int_bipedi:= False;
                              current_int_corsie:= linea_corsia;
                              segnale:= True;
                              cur_prec_uscita_ritorno_on_entrata_ritorno:= True;
                           end if;
                        end if;
                        if segnale then
                           variabile_nat:= mailbox.get_num_stalli_for_car_in_ingresso(traiettoria    => tipo_traiettoria,
                                                                                      index_ingresso => mailbox.get_key_ingresso(mailbox.get_index_ingresso_from_key(i,current_ingressi_structure_type_to_consider),not_ordered),
                                                                                      from_begin     => current_from_begin,
                                                                                      int_bipedi => current_int_bipedi,
                                                                                      int_corsie => current_int_corsie,
                                                                                      precedenza_to_entrata_ritorno => cur_prec_uscita_ritorno_on_entrata_ritorno);
                           mailbox.set_num_stalli_for_car_in_ingresso(num_stalli     => variabile_nat+1,
                                                                      traiettoria    => tipo_traiettoria,
                                                                      index_ingresso => mailbox.get_key_ingresso(mailbox.get_index_ingresso_from_key(i,current_ingressi_structure_type_to_consider),not_ordered),
                                                                      from_begin     => current_from_begin,
                                                                      int_bipedi => current_int_bipedi,
                                                                      int_corsie => current_int_corsie,
                                                                      precedenza_to_entrata_ritorno => cur_prec_uscita_ritorno_on_entrata_ritorno);
                        end if;
                     end;
                  end if;
               end loop;



               -- ATT IL VALORE SETTATO PER there_are_bipedi_in_movement VIENE USATO
               -- SIA DA uscita_ritorno CHE DA entrata_ritorno

               there_are_bipedi_in_movement_in_entrata:= False;
               for k in 1..2 loop
                  if k=1 then
                     list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(i,current_ingressi_structure_type_to_consider),entrata_dritto_bici);
                  else
                     list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(i,current_ingressi_structure_type_to_consider),entrata_dritto_pedoni);
                  end if;
                  while there_are_bipedi_in_movement_in_entrata=False and then list_abitanti_on_traiettoria_ingresso/=null loop
                     if k=1 then
                        entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                     else
                        entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                     end if;
                     if ((list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_larghezza_corsia and then list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_larghezza_corsia*2.0) and
                           list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia) or else (list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_larghezza_corsia*2.0 and list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length<get_larghezza_corsia*3.0) then
                        there_are_bipedi_in_movement_in_entrata:= True;
                     end if;
                     list_abitanti_on_traiettoria_ingresso:= list_abitanti_on_traiettoria_ingresso.get_next_from_list_posizione_abitanti;
                  end loop;
               end loop;

               there_are_bipedi_in_movement_in_uscita:= False;
               for k in 1..2 loop
                  if k=1 then
                     list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(i,current_ingressi_structure_type_to_consider),uscita_dritto_bici);
                  else
                     list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(i,current_ingressi_structure_type_to_consider),uscita_dritto_pedoni);
                  end if;
                  while there_are_bipedi_in_movement_in_uscita=False and then list_abitanti_on_traiettoria_ingresso/=null loop
                     if k=1 then
                        entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                     else
                        entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                     end if;
                     if ((list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_larghezza_corsia+get_larghezza_marciapiede and then list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_larghezza_corsia*2.0+get_larghezza_marciapiede) and
                           list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia) or else (list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_larghezza_corsia*2.0+get_larghezza_marciapiede and list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length<get_larghezza_corsia*3.0+get_larghezza_marciapiede) then
                        there_are_bipedi_in_movement_in_uscita:= True;
                     end if;
                     list_abitanti_on_traiettoria_ingresso:= list_abitanti_on_traiettoria_ingresso.get_next_from_list_posizione_abitanti;
                  end loop;
               end loop;

               -- TRAIETTORIA USCITA_ANDATA
               can_move_from_traiettoria:= True;
               next_pos_abitante:= 0.0;
               stop_entity:= False;
               if list_abitanti_uscita_andata/=null and then list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 then
                  if mailbox.get_abilitazione_attraversamento_cars_ingresso(True,current_polo_to_consider,i)=False then
                     can_move_from_traiettoria:= False;
                  else
                     for t in 1..2 loop
                        if t=1 then
                           list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(i,current_ingressi_structure_type_to_consider),uscita_dritto_bici);
                        else
                           list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(i,current_ingressi_structure_type_to_consider),uscita_dritto_pedoni);
                        end if;
                        if list_abitanti_on_traiettoria_ingresso/=null then
                           if t=1 then
                              entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                           else
                              entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                           end if;
                           if (list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 and then
                               list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia) or else
                             (list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length<get_larghezza_marciapiede+get_larghezza_corsia) then
                              can_move_from_traiettoria:= False;
                           end if;
                        end if;
                     end loop;
                  end if;
                  if can_move_from_traiettoria then
                     if list_abitanti_uscita_ritorno/=null then
                        Put_Line("uscita ritorno NOT null " & Positive'Image(id_task));
                        move_entity:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                        if list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-move_entity.get_length_entità_passiva>=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then -- intersezione con linea corsia
                           can_move_from_traiettoria:= mailbox.can_abitante_move(list_abitanti_uscita_andata,distance_ingresso,i,uscita_andata,current_polo_to_consider,list_abitanti_entrata_andata,there_are_bipedi_in_movement_in_entrata);
                        else
                           can_move_from_traiettoria:= False;
                        end if;
                     else
                        Put_Line("uscita ritorno null " & Positive'Image(id_task));
                        can_move_from_traiettoria:= mailbox.can_abitante_move(list_abitanti_uscita_andata,distance_ingresso,i,uscita_andata,current_polo_to_consider,list_abitanti_entrata_andata,there_are_bipedi_in_movement_in_entrata);
                     end if;
                  end if;
               end if;
               if (list_abitanti_uscita_andata/=null and then list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(uscita_andata).get_lunghezza) and can_move_from_traiettoria then -- se c è qualcuno da muovere e può muoversi
                  -- cerco se ingressi successivi sullo stesso polo hanno macchine da spostare

                  step_is_just_calculated:= False;

                  declare
                     list_ingressi: indici_ingressi:= mailbox.get_ingressi_ordered_by_distance(not current_polo_to_consider);
                     key: Positive:= mailbox.get_key_ingresso_ordered_by_distance(ingresso.get_id_road,not current_polo_to_consider);
                     next_key: Positive:= key+1;
                  begin
                     if next_key<=list_ingressi'Last then
                        next_pos_abitante:= get_distance_from_polo_percorrenza(get_ingresso_from_id(list_ingressi(next_key)),current_polo_to_consider)-get_larghezza_marciapiede-get_larghezza_corsia-bound_to_change_corsia;
                     else
                        next_pos_abitante:= get_urbana_from_id(id_task).get_lunghezza_road-bound_to_change_corsia;
                     end if;
                  end;

                  acceleration_car:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti)).get_max_acceleration;
                  traiettoria_rimasta_da_percorrere:= get_traiettoria_ingresso(uscita_andata).get_lunghezza-list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                  next_abitante:= mailbox.get_next_abitante_on_road(distance_ingresso,current_polo_to_consider,2,True);
                  distance_to_stop_line:= get_urbana_from_id(id_task).get_lunghezza_road-(distance_ingresso+get_larghezza_corsia+get_larghezza_marciapiede)+traiettoria_rimasta_da_percorrere;
                  calculate_parameters_car_in_uscita(list_abitanti_uscita_andata,traiettoria_rimasta_da_percorrere,next_abitante,distance_to_stop_line,uscita_andata,distance_ingresso,next_pos_abitante,acceleration,new_step,new_speed);
                  fix_advance_parameters(car,acceleration,new_speed,new_step,speed_abitante,next_pos_abitante,distance_to_stop_line);

                  if next_pos_abitante<0.0 then
                     Put_Line("id_abitante " & Positive'Image(list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & new_float'Image(list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is traiettoria uscita andata ingresso " & Positive'Image(ingresso.get_id_road) & " quartiere" & Positive'Image(get_id_quartiere) & " IN ERRORE");
                     if next_abitante/=null then
                        Put_Line("in errore uscita andata next abitante is : " & Positive'Image(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " distance: " & new_float'Image(next_pos_abitante));
                     else
                        Put_Line("next_pos_abitante: " & new_float'Image(next_pos_abitante));
                     end if;
                     raise other_error;
                  end if;

                  -- COMMENTATO CODICE SEGUENTE perchè il CONTROLLO VIENE GIÀ FATTO DA can_abitante_move
                  --stop_entity:= False;
                  --if list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 then
                  --   if next_pos_abitante-get_traiettoria_ingresso(uscita_andata).get_lunghezza<get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva then
                  --      stop_entity:= True;
                  --   end if;
                  --end if;

                  mailbox.set_move_parameters_entity_on_traiettoria_ingresso(car,list_abitanti_uscita_andata,ingresso.get_id_road,uscita_andata,current_polo_to_consider,new_speed,new_step,step_is_just_calculated);

                  Put_Line("id_abitante " & Positive'Image(list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & new_float'Image(list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is traiettoria uscita andata ingresso " & Positive'Image(ingresso.get_id_road) & " quartiere" & Positive'Image(get_id_quartiere) & " next_pos_abitante: " & new_float'Image(next_pos_abitante));
               end if;


               -- TRAIETTORIA USCITA_RITORNO
               stop_entity:= False;
               can_move_from_traiettoria:= True;
               next_pos_abitante:= 0.0;
               if list_abitanti_uscita_ritorno/=null and then list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 then
                  if mailbox.get_abilitazione_attraversamento_cars_ingresso(True,current_polo_to_consider,i)=False then
                     can_move_from_traiettoria:= False;
                  else
                     if list_abitanti_uscita_andata/=null then
                        if list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=0.0 then
                           can_move_from_traiettoria:= False;
                        else
                           can_move_from_traiettoria:= mailbox.can_abitante_move(list_abitanti_uscita_ritorno,distance_ingresso,i,uscita_ritorno,current_polo_to_consider,list_abitanti_entrata_andata,there_are_bipedi_in_movement_in_entrata);
                        end if;
                     else
                        can_move_from_traiettoria:= mailbox.can_abitante_move(list_abitanti_uscita_ritorno,distance_ingresso,i,uscita_ritorno,current_polo_to_consider,list_abitanti_entrata_andata,there_are_bipedi_in_movement_in_entrata);
                     end if;
                  end if;
               end if;
               stop_entity:= False;
               if (list_abitanti_uscita_ritorno/=null and then list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(uscita_ritorno).get_lunghezza) and can_move_from_traiettoria then
                  step_is_just_calculated:= False;
                  if list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                     stop_entity:= not mailbox.can_abitante_continue_move(list_abitanti_uscita_ritorno,distance_ingresso,1,uscita_ritorno,current_polo_to_consider,list_abitanti_entrata_ritorno,there_are_bipedi_in_movement_in_entrata);
                  elsif list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni.get_distanza_intersezione-max_larghezza_veicolo then
                     -- ASSUNZIONE CHE LA MACCHINA NON SIA PIÙ LUNGA DI PEZZI DI TRAIETTORIA TRA PT INTERSEZIONE
                     if (list_abitanti_entrata_ritorno/=null and then list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                       max_larghezza_veicolo+get_traiettoria_ingresso(entrata_ritorno).get_intersezioni.get_distanza_intersezione) or else (list_abitanti_entrata_ritorno/=null and then list_abitanti_entrata_ritorno.get_next_from_list_posizione_abitanti/=null) then
                        if list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia=False then
                           stop_entity:= True;
                        else
                           stop_entity:= False;
                        end if;
                     else
                        stop_entity:= False;
                     end if;
                  elsif list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                     Put_Line("request can continue move by " & Positive'Image(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                     stop_entity:= not mailbox.can_abitante_continue_move(list_abitanti_uscita_ritorno,get_urbana_from_id(id_task).get_lunghezza_road-distance_ingresso,2,uscita_ritorno,current_polo_to_consider,list_abitanti_entrata_ritorno,there_are_bipedi_in_movement_in_uscita);
                  elsif list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(uscita_ritorno).get_intersezione_bipedi then
                     stop_entity:= not can_abitante_on_uscita_ritorno_overtake_bipedi(mailbox,ingresso.get_id_road);
                  end if;
                  if stop_entity=False then -- non ci sono macchine nella traiettoria entrata_ritorno quindi non deve essere data la precedenza alle macchine di quella traiettoria
                                            -- cerco se ingressi precedenti hanno delle svolte a sx


                     declare
                        list_ingressi: indici_ingressi:= mailbox.get_ingressi_ordered_by_distance(current_polo_to_consider);
                        key: Positive:= mailbox.get_key_ingresso_ordered_by_distance(ingresso.get_id_road,current_polo_to_consider);
                        next_key: Positive:= key+1;
                     begin
                        if next_key<=list_ingressi'Last then
                           next_pos_abitante:= get_distance_from_polo_percorrenza(get_ingresso_from_id(list_ingressi(next_key)),not current_polo_to_consider)-get_larghezza_marciapiede-get_larghezza_corsia-bound_to_change_corsia;
                        else
                           next_pos_abitante:= get_urbana_from_id(id_task).get_lunghezza_road-bound_to_change_corsia;
                        end if;
                     end;

                     acceleration_car:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti)).get_max_acceleration;
                     traiettoria_rimasta_da_percorrere:= get_traiettoria_ingresso(uscita_ritorno).get_lunghezza-list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                     next_abitante:= mailbox.get_next_abitante_on_road(get_urbana_from_id(id_task).get_lunghezza_road-distance_ingresso,not current_polo_to_consider,1,True);
                     distance_to_stop_line:= distance_ingresso-get_larghezza_marciapiede-get_larghezza_corsia+traiettoria_rimasta_da_percorrere;
                     calculate_parameters_car_in_uscita(list_abitanti_uscita_ritorno,traiettoria_rimasta_da_percorrere,next_abitante,distance_to_stop_line,uscita_ritorno,get_urbana_from_id(id_task).get_lunghezza_road-distance_ingresso,next_pos_abitante,acceleration,new_step,new_speed);
                     fix_advance_parameters(car,acceleration,new_speed,new_step,speed_abitante,next_pos_abitante,distance_to_stop_line);

                     if next_pos_abitante<0.0 then
                        Put_Line("id_abitante " & Positive'Image(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & new_float'Image(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is traiettoria uscita ritorno ingresso " & Positive'Image(ingresso.get_id_road) & " quartiere" & Positive'Image(get_id_quartiere) & " IN ERRORE");
                        raise other_error;
                     end if;

                     -- begin ottimizzazione nella percorrenza della traiettoria uscita ritorno
                     -- scaglioni steps
                     new_distance:= list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step;
                     if list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                        if new_distance>get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then -- se è maggiore dato che se è uguale sai già che li si ferma
                           stop_entity:= not mailbox.can_abitante_continue_move(list_abitanti_uscita_ritorno,distance_ingresso,1,uscita_ritorno,current_polo_to_consider,list_abitanti_entrata_ritorno,there_are_bipedi_in_movement_in_entrata);
                           if stop_entity then -- la macchina si deve fermare li
                              new_step:= get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie;
                              new_distance:= new_step;
                              step_is_just_calculated:= True;
                           end if;
                        end if;
                     end if;
                     if stop_entity=False and then list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(uscita_ritorno).get_intersezioni.get_distanza_intersezione-max_larghezza_veicolo then
                        if new_distance>=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni.get_distanza_intersezione-max_larghezza_veicolo then
                           if (list_abitanti_entrata_ritorno/=null and then list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                             max_larghezza_veicolo+get_traiettoria_ingresso(entrata_ritorno).get_intersezioni.get_distanza_intersezione) or else (list_abitanti_entrata_ritorno/=null and then list_abitanti_entrata_ritorno.get_next_from_list_posizione_abitanti/=null) then
                              stop_entity:= True;
                           else
                              stop_entity:= False;
                           end if;
                           if stop_entity then
                              new_step:= get_traiettoria_ingresso(uscita_ritorno).get_intersezioni.get_distanza_intersezione-max_larghezza_veicolo;
                              new_distance:= new_step;
                              step_is_just_calculated:= True;
                           end if;
                        end if;
                     end if;
                     if stop_entity=False and then list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                        if new_distance>=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                           ---if list_abitanti_entrata_ritorno=null and then list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                           Put_Line("request can continue move by " & Positive'Image(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                           stop_entity:= not mailbox.can_abitante_continue_move(list_abitanti_uscita_ritorno,get_urbana_from_id(id_task).get_lunghezza_road-distance_ingresso,2,uscita_ritorno,current_polo_to_consider,list_abitanti_entrata_ritorno,there_are_bipedi_in_movement_in_uscita);
                           if stop_entity then
                              new_step:= get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie;
                              new_distance:= new_step;
                              step_is_just_calculated:= True;
                           end if;
                           --end if;
                        end if;
                     end if;
                     if stop_entity=False and then list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(uscita_ritorno).get_intersezione_bipedi then
                        if new_distance>=get_traiettoria_ingresso(uscita_ritorno).get_intersezione_bipedi then
                           stop_entity:= not can_abitante_on_uscita_ritorno_overtake_bipedi(mailbox,ingresso.get_id_road);
                           if stop_entity then
                              new_step:= get_traiettoria_ingresso(uscita_ritorno).get_intersezione_bipedi;
                              new_distance:= new_step;
                              step_is_just_calculated:= True;
                           end if;
                        end if;
                     end if;
                     -- end scaglioni steps e ottimizzazione

                     mailbox.set_move_parameters_entity_on_traiettoria_ingresso(car,list_abitanti_uscita_ritorno,ingresso.get_id_road,uscita_ritorno,not current_polo_to_consider,new_speed,new_step,step_is_just_calculated);
                     Put_Line("id_abitante " & Positive'Image(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & new_float'Image(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is traiettoria uscita ritorno ingresso " & Positive'Image(ingresso.get_id_road) & " quartiere" & Positive'Image(get_id_quartiere) & " next pos abitante: " & new_float'Image(next_pos_abitante) & " stop entity " & Boolean'Image(stop_entity));
                  else
                     Put_Line("BLOCCO id_abitante " & Positive'Image(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & new_float'Image(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is traiettoria uscita ritorno ingresso " & Positive'Image(ingresso.get_id_road) & " quartiere" & Positive'Image(get_id_quartiere));
                  end if;
               end if;


               if list_abitanti_entrata_ritorno/=null then
                  if list_abitanti_uscita_ritorno/=null then
                     if list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni.get_distanza_intersezione-max_larghezza_veicolo then
                        -- il flag_overtake dell'usita ritorno è false
                        -- controllare se è il caso di metterlo a True
                        if mailbox.get_num_stalli_for_car_in_ingresso(traiettoria                   => uscita_ritorno,
                                                                      index_ingresso                => mailbox.get_key_ingresso(mailbox.get_index_ingresso_from_key(i,current_ingressi_structure_type_to_consider),not_ordered),
                                                                      from_begin                    => False,
                                                                      int_bipedi                    => False,
                                                                      int_corsie                    => linea_corsia,
                                                                      precedenza_to_entrata_ritorno => True)>max_num_stalli_uscita_ritorno_in_intersezione_entrata_ritorno then
                           if list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 or else
                             list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                              mailbox.set_flag_abitante_can_overtake_to_next_corsia(list_abitanti_uscita_ritorno,True);
                           end if;
                        end if;
                     else
                        can_move_from_traiettoria:= True;
                     end if;
                  end if;
               end if;

               -- TRAIETTORIA ENTRATA_RITORNO
               can_move_from_traiettoria:= True;
               next_pos_abitante:= 0.0;
               stop_entity:= False;
               if list_abitanti_entrata_ritorno/=null and then list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti=174 then
                  stop_entity:= False;
               end if;

               if list_abitanti_entrata_ritorno/=null and then list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 then
                  -- l'abitante in entrata_ritorno una volta entrata nella lista
                  -- per certo non avrà bipedi in entrata_dritto con posizione intersecante la corsia 1 dell'abitante in entrata_ritorno
                  if list_abitanti_uscita_ritorno=null then
                     can_move_from_traiettoria:= True;
                  else
                     if list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni.get_distanza_intersezione-max_larghezza_veicolo then
                        Put_Line("can move " & Positive'Image(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & new_float'Image(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is traiettoria uscita ritorno ingresso " & Positive'Image(ingresso.get_id_road) & " quartiere" & Positive'Image(get_id_quartiere));
                        if list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia and list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni.get_distanza_intersezione-max_larghezza_veicolo then
                           can_move_from_traiettoria:= False;
                        else
                           can_move_from_traiettoria:= True;
                        end if;
                     else
                        if list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva>
                          max_larghezza_veicolo+get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                           Put_Line("can move " & Positive'Image(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & new_float'Image(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is traiettoria uscita ritorno ingresso " & Positive'Image(ingresso.get_id_road) & " quartiere" & Positive'Image(get_id_quartiere));
                           can_move_from_traiettoria:= True;
                        else
                           can_move_from_traiettoria:= False;
                           Put_Line("can NOT move " & Positive'Image(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & new_float'Image(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is traiettoria uscita ritorno ingresso " & Positive'Image(ingresso.get_id_road) & " quartiere" & Positive'Image(get_id_quartiere));
                        end if;
                     end if;
                  end if;
               end if;
               if (list_abitanti_entrata_ritorno/=null and then list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(entrata_ritorno).get_lunghezza) and can_move_from_traiettoria then
                  step_is_just_calculated:= False;
                  if list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni.get_distanza_intersezione-max_larghezza_veicolo*2.0 then
                     if list_abitanti_uscita_ritorno/=null and then (list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_traiettoria_ingresso(uscita_ritorno).get_intersezioni.get_distanza_intersezione-max_larghezza_veicolo and then
                                                                       (list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                                                                          max_larghezza_veicolo+get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie)) then
                        stop_entity:= True;
                     end if;
                  end if;

                  if list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                     -- ATTTTTTT MODIFY IL SECONDO and then DEL SEGUENTE if, PRIMA ERA UN or else
                     if list_abitanti_uscita_ritorno/=null and then (list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie and then
                                                                     list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni.get_distanza_intersezione-max_larghezza_veicolo) then
                        stop_entity:= False;
                     else
                        stop_entity:= not mailbox.can_abitante_continue_move(list_abitanti_entrata_ritorno,distance_ingresso,1,entrata_ritorno,current_polo_to_consider,null,there_are_bipedi_in_movement_in_entrata);
                     end if;
                  end if;
                  if list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                     -- viene controllato se ci sono dei bipedi in posizione maggiore di get_larghezza_corsia*3.0
                     if there_are_bipedi_in_movement_in_entrata=False then
                        if list_abitanti_entrata_andata/=null then -- and then list_abitanti_entrata_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=0.0 then
                           stop_entity:= True;
                           Put_Line("DARE PRECEDENZA A entrata_andata");
                        else --list_abitanti_entrata_andata=null  --if list_abitanti_entrata_andata=null then
                           if list_abitanti_uscita_andata/=null and then list_abitanti_uscita_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 then
                              there_are_bipedi_in_movement_in_entrata:= True;
                           end if;
                           stop_entity:= not mailbox.can_abitante_continue_move(list_abitanti_entrata_ritorno,distance_ingresso,2,entrata_ritorno,current_polo_to_consider,null,there_are_bipedi_in_movement_in_entrata);
                           there_are_bipedi_in_movement_in_entrata:= False;
                        end if;
                     else
                        -- dato che si hanno dei bipedi in entrata dritto a distanza maggiore di get_larghezza_corsia*2.0
                        stop_entity:= not mailbox.can_abitante_continue_move(list_abitanti_entrata_ritorno,distance_ingresso,2,entrata_ritorno,current_polo_to_consider,null,there_are_bipedi_in_movement_in_entrata);
                     end if;
                  end if;

                  if stop_entity=False then
                     acceleration_car:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti)).get_max_acceleration;
                     traiettoria_rimasta_da_percorrere:= get_traiettoria_ingresso(entrata_ritorno).get_lunghezza-list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                     next_abitante:= get_ingressi_segmento_resources(mailbox.get_index_ingresso_from_key(i,current_ingressi_structure_type_to_consider)).get_first_abitante_to_exit_from_urbana(car);
                     distance_to_stop_line:= ingresso.get_lunghezza_road+traiettoria_rimasta_da_percorrere;
                     calculate_parameters_car_in_entrata(ingresso.get_id_road,list_abitanti_entrata_ritorno,traiettoria_rimasta_da_percorrere,next_abitante,distance_to_stop_line,entrata_ritorno,next_pos_abitante,acceleration,new_step,new_speed);
                     fix_advance_parameters(car,acceleration,new_speed,new_step,speed_abitante,next_pos_abitante,distance_to_stop_line);

                     -- begin ottimizzazione nella percorrenza della traiettoria uscita ritorno
                     -- scaglioni steps
                     new_distance:= list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step;
                     if list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(entrata_ritorno).get_intersezioni.get_distanza_intersezione-max_larghezza_veicolo*2.0 then
                        if new_distance>=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni.get_distanza_intersezione-max_larghezza_veicolo*2.0 then
                           if list_abitanti_uscita_ritorno/=null and then (list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_traiettoria_ingresso(uscita_ritorno).get_intersezioni.get_distanza_intersezione-max_larghezza_veicolo and then
                                                                           (list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_uscita_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                                                                             max_larghezza_veicolo+get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie)) then
                              stop_entity:= True;
                           end if;
                           if stop_entity then
                              new_step:= get_traiettoria_ingresso(entrata_ritorno).get_intersezioni.get_distanza_intersezione-max_larghezza_veicolo*2.0;
                              new_distance:= new_step;
                              step_is_just_calculated:= True;
                           end if;
                        end if;
                     end if;
                     if stop_entity=False and then list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                        if new_distance>=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                           stop_entity:= not mailbox.can_abitante_continue_move(list_abitanti_entrata_ritorno,distance_ingresso,1,entrata_ritorno,current_polo_to_consider,null,there_are_bipedi_in_movement_in_entrata);
                           if stop_entity then
                              new_step:= get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie;
                              new_distance:= new_step;
                              step_is_just_calculated:= True;
                           end if;
                        end if;
                     end if;
                     if stop_entity=False and then list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                        if new_distance>=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                           if list_abitanti_entrata_andata/=null then
                              stop_entity:= True;
                           else
                              stop_entity:= not mailbox.can_abitante_continue_move(list_abitanti_entrata_ritorno,distance_ingresso,2,entrata_ritorno,current_polo_to_consider,null,there_are_bipedi_in_movement_in_entrata);
                           end if;
                           if stop_entity then
                              new_step:= get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie;
                              new_distance:= new_step;
                              step_is_just_calculated:= True;
                           end if;
                        end if;
                     end if;
                     -- end scaglioni e ottimizzazioni

                     if mailbox.get_abilitazione_attraversamento_cars_ingresso(False,current_polo_to_consider,i)=False then
                        if new_distance>get_traiettoria_ingresso(entrata_ritorno).get_intersezione_bipedi then
                           new_step:= get_traiettoria_ingresso(entrata_ritorno).get_intersezione_bipedi;
                           step_is_just_calculated:= True;
                           new_distance:= new_step;
                           new_speed:= new_speed/2.0;
                        end if;
                     end if;

                     mailbox.set_move_parameters_entity_on_traiettoria_ingresso(car,list_abitanti_entrata_ritorno,ingresso.get_id_road,entrata_ritorno,current_polo_to_consider,new_speed,new_step,step_is_just_calculated);
                     if list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>=get_traiettoria_ingresso(entrata_ritorno).get_lunghezza then
                        get_ingressi_segmento_resources(ingresso.get_id_road).new_car_finish_route(posizione_abitanti_on_road(list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti));
                     end if;
                     Put_Line("id_abitante " & Positive'Image(list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & new_float'Image(list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is traiettoria entrata ritorno ingresso " & Positive'Image(ingresso.get_id_road) & " quartiere" & Positive'Image(get_id_quartiere));
                  else
                     Put_Line("STOP_ENTITY 1836 id_abitante " & Positive'Image(list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & new_float'Image(list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is traiettoria entrata ritorno ingresso " & Positive'Image(ingresso.get_id_road) & " quartiere" & Positive'Image(get_id_quartiere));
                  end if;
               elsif list_abitanti_entrata_ritorno/=null then
                  Put_Line("id_abitante " & Positive'Image(list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & new_float'Image(list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is traiettoria entrata ritorno ingresso " & Positive'Image(ingresso.get_id_road) & " quartiere" & Positive'Image(get_id_quartiere));
               end if;

               --if list_abitanti_entrata_ritorno/=null and then list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
               --   mailbox.set_num_stalli_for_car_in_ingresso(entrata_ritorno,ingresso.get_id_road,mailbox.get_num_stalli_for_car_in_ingresso(entrata_ritorno,ingresso.get_id_road)+1);
               --else
               --   mailbox.set_num_stalli_for_car_in_ingresso(entrata_ritorno,ingresso.get_id_road,0);
               --end if;

               -- TRAIETTORIA ENTRATA_ANDATA
               can_move_from_traiettoria:= True;
               next_pos_abitante:= 0.0;
               if list_abitanti_entrata_andata/=null and then list_abitanti_entrata_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 then
                  if mailbox.get_abilitazione_attraversamento_cars_ingresso(False,current_polo_to_consider,i)=False then
                     can_move_from_traiettoria:= False;
                  else
                     -- codice commentato sotto non serve dato che l'abitante non si troverebbe in
                     -- entrata andata se ci fossero dei bipedi in attraversamento
                     --for k in 1..2 loop
                     --   if k=1 then
                     --      list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(i,current_ingressi_structure_type_to_consider),entrata_dritto_bici);
                     --   else
                     --      list_abitanti_on_traiettoria_ingresso:= mailbox.get_abitante_from_ingresso(mailbox.get_index_ingresso_from_key(i,current_ingressi_structure_type_to_consider),entrata_dritto_pedoni);
                     --   end if;
                     --   while list_abitanti_on_traiettoria_ingresso/=null loop
                     --      if list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>get_larghezza_corsia*2.0 or else
                     --        (list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_larghezza_corsia and then (list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_larghezza_corsia*2.0 and then
                     --                                                                                                                                                                   list_abitanti_on_traiettoria_ingresso.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia)) then
                     --         can_move_from_traiettoria:= False;
                     --      end if;
                     --      list_abitanti_on_traiettoria_ingresso:= list_abitanti_on_traiettoria_ingresso.get_next_from_list_posizione_abitanti;
                     --   end loop;
                     --end loop;
                     if can_move_from_traiettoria then
                        next_abitante:= mailbox.get_next_abitante_on_road(distance_ingresso,current_polo_to_consider,2,False); -- False cosi non si attiva la costante additiva nel metodo chiamato
                        if next_abitante/=null then
                           move_entity:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                           if next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-move_entity.get_length_entità_passiva<distance_ingresso then
                              can_move_from_traiettoria:= False;
                           elsif list_abitanti_entrata_ritorno/=null and then list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then  -- > e non >= dato che se fosse uguale allora l'abitante in entrata ritorno sarebbe fermo
                              can_move_from_traiettoria:= False;
                           else
                              can_move_from_traiettoria:= True;
                           end if;
                        else
                           can_move_from_traiettoria:= True;
                        end if;
                        --if can_move_from_traiettoria then
                        --   if list_abitanti_entrata_ritorno/=null and then list_abitanti_entrata_ritorno.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                        --      can_move_from_traiettoria:= False;
                        --   end if;
                        --end if;
                     end if;
                  end if;
               end if;
               if (list_abitanti_entrata_andata/=null and then list_abitanti_entrata_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_ingresso(entrata_andata).get_lunghezza) and can_move_from_traiettoria then
                  step_is_just_calculated:= False;
                  acceleration_car:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list_abitanti_entrata_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_abitanti_entrata_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti)).get_max_acceleration;
                  traiettoria_rimasta_da_percorrere:= get_traiettoria_ingresso(entrata_andata).get_lunghezza-list_abitanti_entrata_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                  next_abitante:= get_ingressi_segmento_resources(mailbox.get_index_ingresso_from_key(i,current_ingressi_structure_type_to_consider)).get_first_abitante_to_exit_from_urbana(car);
                  distance_to_stop_line:= ingresso.get_lunghezza_road+traiettoria_rimasta_da_percorrere;
                  calculate_parameters_car_in_entrata(ingresso.get_id_road,list_abitanti_entrata_andata,traiettoria_rimasta_da_percorrere,next_abitante,distance_to_stop_line,entrata_andata,next_pos_abitante,acceleration,new_step,new_speed);
                  fix_advance_parameters(car,acceleration,new_speed,new_step,speed_abitante,next_pos_abitante,distance_to_stop_line);
                  mailbox.set_move_parameters_entity_on_traiettoria_ingresso(car,list_abitanti_entrata_andata,ingresso.get_id_road,entrata_andata,current_polo_to_consider,new_speed,new_step,step_is_just_calculated);
                  if list_abitanti_entrata_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>=get_traiettoria_ingresso(entrata_andata).get_lunghezza then
                     get_ingressi_segmento_resources(ingresso.get_id_road).new_car_finish_route(posizione_abitanti_on_road(list_abitanti_entrata_andata.get_posizione_abitanti_from_list_posizione_abitanti));
                  end if;
                  Put_Line("id_abitante " & Positive'Image(list_abitanti_entrata_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & new_float'Image(list_abitanti_entrata_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is traiettoria entrata andata ingresso " & Positive'Image(ingresso.get_id_road) & " quartiere" & Positive'Image(get_id_quartiere));
               end if;

               --if list_abitanti_entrata_andata/=null and then list_abitanti_entrata_andata.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 then
               --   mailbox.set_num_stalli_for_car_in_ingresso(entrata_andata,ingresso.get_id_road,mailbox.get_num_stalli_for_car_in_ingresso(entrata_andata,ingresso.get_id_road)+1);
               --else
               --   mailbox.set_num_stalli_for_car_in_ingresso(entrata_andata,ingresso.get_id_road,0);
               --end if;

            end loop;
            current_polo_to_consider:= True;
            current_ingressi_structure_type_to_consider:= ordered_polo_true;
            current_ingressi_structure_type_to_not_consider:= ordered_polo_false;
         end loop;

         mailbox.sposta_bipedi_in_transizione_da_incroci;
         -- LO sopostamento dei temp va fatto prima della risinicronizzazione del
         -- sistema altrimenti l'incrocio potrebbe spostare una macchina nell'urbana
         -- senza considerare la macchina in temp; quindi questa va spostata prima che
         -- l'incrocio possa eseguire al prossimo delta
         mailbox.sposta_macchine_in_transizione_da_incroci;

         -- spostamento abitanti da incrocio a strada
         mailbox.azzera_spostamento_abitanti_in_incroci;

         -- crea snapshot se necessario
         --crea_snapshot(num_delta,ptr_backup_interface(mailbox),id_task);

         get_synchronization_tasks_partition_object.task_has_finished;
         mailbox.delta_terminate;
         --log_mio.write_task_arrived("id_task " & Positive'Image(id_task) & " id_quartiere " & Positive'Image(get_id_quartiere));

         --get_log_stallo_quartiere.finish(id_task);

      end loop;

   exception
      when system_error_exc =>
         exit_task;
      when propaga_error =>
         close_mailbox;
      when regular_exit_system =>
         log_system_error.add_finished_task(id_task);
      when System.RPC.Communication_Error =>
         log_system_error.set_error(altro,error_flag);
         exit_task;
         close_mailbox;
         if error_flag then
            Put_Line("partizione remota non raggiungibile.");
         end if;
      when Error: others =>
         log_system_error.set_error(altro,error_flag);
         exit_task;
         close_mailbox;
         if error_flag then
            Put_Line("Unexpected exception urbana: " & Positive'Image(id_task) & " ID QU " & Positive'Image(get_id_quartiere));
            Put_Line(Exception_Information(Error));
         end if;
   end core_avanzamento_urbane;

   task body core_avanzamento_ingressi is
      id_task: Positive;
      mailbox: ptr_resource_segmento_ingresso;
      resource_main_strada: ptr_resource_segmento_urbana;
      list_abitanti: ptr_list_posizione_abitanti_on_road:= null;
      acceleration: new_float:= 0.0;
      acceleration_car: new_float;
      --acceleration_bipede: new_float;
      new_speed: new_float:= 0.0;
      new_step: new_float:= 0.0;
      distance_to_next: new_float:= 0.0;
      new_requests: ptr_list_posizione_abitanti_on_road:= null;
      pragma Warnings(off);
      default_pos_abitanti: posizione_abitanti_on_road;
      pragma Warnings(on);
      current_posizione_abitante: posizione_abitanti_on_road'Class:= default_pos_abitanti;
      next_posizione_abitante: posizione_abitanti_on_road'Class:= default_pos_abitanti;
      traiettoria_type: traiettoria_ingressi_type;
      traiettoria_da_prendere: trajectory_to_follow;
      distanza_stop_line: new_float;
      state_view_abitanti: JSON_Array;
      num_delta: Natural:= 0;
      speed_abitante: new_float;
      mezzo: means_of_carrying;
      entity_length: new_float;
      error_flag: Boolean:= False;

      flag_chiusura_is_set: Boolean:= False;

      --s: Boolean;
      --destination_abitante_on_bus: tratto;
   begin
      select
         accept configure(id: Positive) do
            id_task:= id;
            mailbox:= get_ingressi_segmento_resources(id);
            resource_main_strada:= get_urbane_segmento_resources(get_ingresso_from_id(id_task).get_id_main_strada_ingresso);
         end configure;
      or
         accept kill do
            null;
            --raise system_error_exc;
         end kill;
      end select;

      if log_system_error.is_in_error then
         raise system_error_exc;
      end if;
      --wait_settings_all_quartieri;
      --Put_Line("task " & Positive'Image(id_task) & " of quartiere " & Positive'Image(get_id_quartiere) & " is set");

      -- Ora i task e le risorse di tutti i quartieri sono attivi
      reconfigure_resource(ptr_backup_interface(mailbox),id_task);

      loop
         -- LO SPOSTAMENTO DI AUTO E BIPEDI PUÒ ESSERE FATTO INDIFFERENTEMENTE
         -- PRIMA L'UNO O PRIMA L'ALTRO

      --for p in 1..100 loop
         synchronization_with_delta(id_task);
         if get_synchronization_tasks_partition_object.is_regular_closure then
            raise regular_exit_system;
         end if;
         if log_system_error.is_in_error then
            raise propaga_error;
         end if;

         --resource_main_strada.wait_update_view;

         state_view_abitanti:= Empty_Array;

         mailbox.update_position_entity(state_view_abitanti);

         state_view_quartiere.registra_aggiornamento_stato_risorsa(id_task,state_view_abitanti,JSON_Null,Empty_Array);

         resource_main_strada.ingresso_wait_turno;
         if log_system_error.is_in_error then
            raise propaga_error;
         end if;

         -- BEGIN SPOSTAMENTO PEDONI/BICI

         for i in reverse 1..2 loop
            list_abitanti:= mailbox.get_marciapiede(mailbox.get_index_inizio_moto,i);
            for j in 1..mailbox.get_number_entity_marciapiede(mailbox.get_index_inizio_moto,i) loop
               current_posizione_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
               if i=1 then
                  --acceleration_bipede:= move_parameters(get_quartiere_utilities_obj.get_pedone_quartiere(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti)).get_max_acceleration;
                  mezzo:= bike;
               else
                  --acceleration_bipede:= move_parameters(get_quartiere_utilities_obj.get_bici_quartiere(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti)).get_max_acceleration;
                  mezzo:= walking;
               end if;

               --Put_Line("id_abitante " & Positive'Image(current_posizione_abitante.get_id_abitante_posizione_abitanti) & " is at " & new_float'Image(current_posizione_abitante.get_where_now_posizione_abitanti) & ", gestore is ingresso " & Positive'Image(id_task));

               speed_abitante:= current_posizione_abitante.get_current_speed_abitante;
               distanza_stop_line:= get_ingresso_from_id(id_task).get_lunghezza_road-current_posizione_abitante.get_where_now_posizione_abitanti;

               if list_abitanti.all.get_next_from_list_posizione_abitanti/=null then
                  next_posizione_abitante:= list_abitanti.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
                  if i=1 then
                     distance_to_next:= next_posizione_abitante.get_where_now_posizione_abitanti-move_parameters(get_quartiere_utilities_obj.all.get_bici_quartiere(next_posizione_abitante.get_id_quartiere_posizione_abitanti,next_posizione_abitante.get_id_abitante_posizione_abitanti)).get_length_entità_passiva-current_posizione_abitante.get_where_now_posizione_abitanti;
                  else
                     distance_to_next:= next_posizione_abitante.get_where_now_posizione_abitanti-move_parameters(get_quartiere_utilities_obj.all.get_pedone_quartiere(next_posizione_abitante.get_id_quartiere_posizione_abitanti,next_posizione_abitante.get_id_abitante_posizione_abitanti)).get_length_entità_passiva-current_posizione_abitante.get_where_now_posizione_abitanti;
                  end if;
                  if distance_to_next<=0.0 then acceleration:= 0.0;
                  else
                     acceleration:= calculate_acceleration(mezzo => mezzo,
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
                  if mailbox.get_last_abitante_in_marciapiede(i).get_id_quartiere_posizione_abitanti/=0 then
                     -- car avanzamento=0 indica che la macchina davanti ha percorso sorpassato completamente l'ingresso
                     if mailbox.get_bipede_avanzamento(i)=0.0 then
                        distance_to_next:= 0.0;
                     else
                        distance_to_next:= get_ingresso_from_id(id_task).get_lunghezza_road-current_posizione_abitante.get_where_now_posizione_abitanti-mailbox.get_bipede_avanzamento(i);
                     end if;
                  else
                     distance_to_next:= 0.0;
                  end if;
                  acceleration:= calculate_acceleration(mezzo => mezzo,
                                                        id_abitante => current_posizione_abitante.get_id_abitante_posizione_abitanti,
                                                        id_quartiere_abitante => current_posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                        next_entity_distance => distance_to_next,
                                                        distance_to_stop_line => distanza_stop_line+add_factor,
                                                        next_id_quartiere_abitante => 0,
                                                        next_id_abitante => 0,
                                                        abitante_velocity => speed_abitante,
                                                        next_abitante_velocity =>0.0);
               end if;
               new_speed:= calculate_new_speed(speed_abitante,acceleration);
               new_step:= calculate_new_step(new_speed,acceleration);

               fix_advance_parameters(mezzo,acceleration,new_speed,new_step,speed_abitante,distance_to_next,distanza_stop_line);

               mailbox.set_move_parameters_entity_on_marciapiede(range_1 => mailbox.get_index_inizio_moto,range_2 => i,num_entity => j,speed => new_speed,step_to_advance => new_step);

               current_posizione_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
               if current_posizione_abitante.get_where_next_posizione_abitanti=get_ingresso_from_id(id_task).get_lunghezza_road then
                  traiettoria_type:= calculate_traiettoria_to_follow_from_ingresso(mezzo,current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti,id_task,resource_main_strada.get_ingressi_ordered_by_distance(True));
                  Put_Line(traiettoria_ingressi_type'Image(traiettoria_type));
                  traiettoria_da_prendere:= calculate_trajectory_to_follow_on_main_strada_from_ingresso(mezzo,current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti,id_task,traiettoria_type);
                  resource_main_strada.aggiungi_entità_from_ingresso(mezzo,id_task,traiettoria_type,current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti,traiettoria_da_prendere);
                  mailbox.delete_bipede_in_uscita(i);
                  list_abitanti:= null;
               else
                  list_abitanti:= list_abitanti.all.get_next_from_list_posizione_abitanti;
               end if;
            end loop;
         end loop;

         mailbox.increase_delta_istantanea;
         for i in 1..2 loop
            new_requests:= mailbox.get_temp_marciapiede(i);
            if new_requests/=null then
               --list_abitanti:= mailbox.get_main_strada(mailbox.get_index_inizio_moto);
               current_posizione_abitante:= new_requests.all.get_posizione_abitanti_from_list_posizione_abitanti;
               mailbox.registra_abitante_to_move(sidewalk,i);
            end if;
         end loop;

         for i in reverse 1..2 loop
            list_abitanti:= mailbox.get_marciapiede(not mailbox.get_index_inizio_moto,i);
            for j in 1..mailbox.get_number_entity_marciapiede(not mailbox.get_index_inizio_moto,i) loop
               current_posizione_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
               --acceleration_car:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti)).get_max_acceleration;
               --Put_Line("id_abitante " & Positive'Image(current_posizione_abitante.get_id_abitante_posizione_abitanti) & " is at " & new_float'Image(current_posizione_abitante.get_where_now_posizione_abitanti) & ", gestore is ingresso " & Positive'Image(id_task));
               -- elimino l'elemento se è fuori traiettoria

               speed_abitante:= current_posizione_abitante.get_current_speed_abitante;
               if i=2 then
                  entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                  mezzo:= walking;
               else
                  entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                  mezzo:= bike;
               end if;

               if current_posizione_abitante.get_where_next_posizione_abitanti-entity_length>=get_ingresso_from_id(id_task).get_lunghezza_road then
                  mailbox.delete_bipede_in_entrata(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti,i);
                  get_quartiere_utilities_obj.get_classe_locate_abitanti(current_posizione_abitante.get_id_quartiere_posizione_abitanti).set_finish_route(current_posizione_abitante.get_id_abitante_posizione_abitanti);
                  if get_ingresso_from_id(id_task).get_type_ingresso=fermata and mezzo=walking then
                     --destination_abitante_on_bus:= get_quartiere_utilities_obj.get_classe_locate_abitanti(current_posizione_abitante.get_id_quartiere_posizione_abitanti).get_destination_abitante_in_bus(current_posizione_abitante.get_id_abitante_posizione_abitanti);
                     --if destination_abitante_on_bus.get_id_quartiere_tratto=get_id_quartiere and get_ingresso_from_id(destination_abitante_on_bus.get_id_tratto).get_id_main_strada_ingresso=get_ingresso_from_id(id_task).get_id_main_strada_ingresso then
                        -- l'abitante è arrivato alla fermata del luogo dove deve arrivare
                     --   get_quartiere_entities_life(current_posizione_abitante.get_id_quartiere_posizione_abitanti).abitante_is_arrived(current_posizione_abitante.get_id_abitante_posizione_abitanti);
                     --else
                        -- la destinazione o è su un quartiere diverso o è su una strada diversa da quella della main strada della fermata
                        -- QUINDI l'abitante è alla fermata di partenza
                     mailbox.add_abitante_in_fermata(create_tratto(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti));
                     --end if;
                  else
                     get_quartiere_entities_life(current_posizione_abitante.get_id_quartiere_posizione_abitanti).abitante_is_arrived(current_posizione_abitante.get_id_abitante_posizione_abitanti);
                  end if;
               else
                  --mailbox.update_position_entity(state_view_abitanti,road,not mailbox.get_index_inizio_moto,i);
                  current_posizione_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
                  if list_abitanti.all.get_next_from_list_posizione_abitanti/=null then
                     next_posizione_abitante:= list_abitanti.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
                     if i=2 then
                        distance_to_next:= next_posizione_abitante.get_where_now_posizione_abitanti-move_parameters(get_quartiere_utilities_obj.all.get_pedone_quartiere(next_posizione_abitante.get_id_quartiere_posizione_abitanti,next_posizione_abitante.get_id_abitante_posizione_abitanti)).get_length_entità_passiva-current_posizione_abitante.get_where_now_posizione_abitanti;
                     else
                        distance_to_next:= next_posizione_abitante.get_where_now_posizione_abitanti-move_parameters(get_quartiere_utilities_obj.all.get_bici_quartiere(next_posizione_abitante.get_id_quartiere_posizione_abitanti,next_posizione_abitante.get_id_abitante_posizione_abitanti)).get_length_entità_passiva-current_posizione_abitante.get_where_now_posizione_abitanti;
                     end if;
                     if distance_to_next<=0.0 then acceleration:= 0.0;
                     else
                        acceleration:= calculate_acceleration(mezzo => mezzo,
                                                              id_abitante => current_posizione_abitante.get_id_abitante_posizione_abitanti,
                                                              id_quartiere_abitante => current_posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                              next_entity_distance => distance_to_next,
                                                              distance_to_stop_line => get_ingresso_from_id(id_task).get_lunghezza_road+entity_length,
                                                              next_id_quartiere_abitante => next_posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                              next_id_abitante => next_posizione_abitante.get_id_abitante_posizione_abitanti,
                                                              abitante_velocity => speed_abitante,
                                                              next_abitante_velocity => next_posizione_abitante.get_current_speed_abitante);
                     end if;
                  else
                     distance_to_next:= 0.0;
                     acceleration:= calculate_acceleration(mezzo => mezzo,
                                                           id_abitante => current_posizione_abitante.get_id_abitante_posizione_abitanti,
                                                           id_quartiere_abitante => current_posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                           next_entity_distance => 0.0,
                                                           distance_to_stop_line => get_ingresso_from_id(id_task).get_lunghezza_road+entity_length,
                                                           next_id_quartiere_abitante => 0,
                                                           next_id_abitante => 0,
                                                           abitante_velocity => speed_abitante,
                                                           next_abitante_velocity =>0.0);
                  end if;

                  new_speed:= calculate_new_speed(speed_abitante,acceleration);
                  new_step:= calculate_new_step(new_speed,acceleration);
                  fix_advance_parameters(mezzo,acceleration,new_speed,new_step,speed_abitante,distance_to_next,new_float'Last);

                  mailbox.set_move_parameters_entity_on_marciapiede(range_1 => not mailbox.get_index_inizio_moto,range_2 => i,num_entity => j,speed => new_speed,step_to_advance => new_step);

                  list_abitanti:= list_abitanti.all.get_next_from_list_posizione_abitanti;
               end if;
            end loop;

         end loop;

         -- END SPOSTAMENTO PEDONI/BICI

         -- BEGIN SPOSTAMENTO AUTO
         list_abitanti:= mailbox.get_main_strada(mailbox.get_index_inizio_moto);
         for i in 1..mailbox.get_number_entity_strada(mailbox.get_index_inizio_moto) loop
            current_posizione_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
            acceleration_car:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti)).get_max_acceleration;

            Put_Line("id_abitante " & Positive'Image(current_posizione_abitante.get_id_abitante_posizione_abitanti) & " is at " & new_float'Image(current_posizione_abitante.get_where_now_posizione_abitanti) & ", gestore is ingresso " & Positive'Image(id_task));

            speed_abitante:= current_posizione_abitante.get_current_speed_abitante;
            distanza_stop_line:= get_ingresso_from_id(id_task).get_lunghezza_road-current_posizione_abitante.get_where_now_posizione_abitanti;

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
                     distance_to_next:= 0.0;
                  else
                     distance_to_next:= get_ingresso_from_id(id_task).get_lunghezza_road-current_posizione_abitante.get_where_now_posizione_abitanti-mailbox.get_car_avanzamento;
                  end if;
               else
                  distance_to_next:= 0.0;
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
            end if;
            new_speed:= calculate_new_speed(speed_abitante,acceleration);
            new_step:= calculate_new_step(new_speed,acceleration);
            fix_advance_parameters(car,acceleration,new_speed,new_step,speed_abitante,distance_to_next,distanza_stop_line);

            mailbox.set_move_parameters_entity_on_main_strada(range_1 => mailbox.get_index_inizio_moto,num_entity => i,speed => new_speed,step_to_advance => new_step);
            current_posizione_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
            if current_posizione_abitante.get_where_next_posizione_abitanti=get_ingresso_from_id(id_task).get_lunghezza_road then
               traiettoria_type:= calculate_traiettoria_to_follow_from_ingresso(car,current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti,id_task,resource_main_strada.get_ingressi_ordered_by_distance(True));
               Put_Line(traiettoria_ingressi_type'Image(traiettoria_type));
               traiettoria_da_prendere:= calculate_trajectory_to_follow_on_main_strada_from_ingresso(car,current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti,id_task,traiettoria_type);
               resource_main_strada.aggiungi_entità_from_ingresso(car,id_task,traiettoria_type,current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti,traiettoria_da_prendere);
               mailbox.delete_car_in_uscita;
               list_abitanti:= null;
            else
               list_abitanti:= list_abitanti.all.get_next_from_list_posizione_abitanti;
            end if;
         end loop;

         new_requests:= mailbox.get_temp_main_strada;
         if new_requests/=null then
            --list_abitanti:= mailbox.get_main_strada(mailbox.get_index_inizio_moto);
            current_posizione_abitante:= new_requests.all.get_posizione_abitanti_from_list_posizione_abitanti;
            mailbox.registra_abitante_to_move(road,1);
         end if;

         list_abitanti:= mailbox.get_main_strada(not mailbox.get_index_inizio_moto);
         for i in 1..mailbox.get_number_entity_strada(not mailbox.get_index_inizio_moto) loop
            current_posizione_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
            acceleration_car:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti)).get_max_acceleration;

            Put_Line("id_abitante " & Positive'Image(current_posizione_abitante.get_id_abitante_posizione_abitanti) & " is at " & new_float'Image(current_posizione_abitante.get_where_now_posizione_abitanti) & ", gestore is ingresso " & Positive'Image(id_task));
            -- elimino l'elemento se è fuori traiettoria

            speed_abitante:= current_posizione_abitante.get_current_speed_abitante;

            if current_posizione_abitante.get_where_next_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva>=get_ingresso_from_id(id_task).get_lunghezza_road then
               --if current_posizione_abitante.get_flag_overtake_next_corsia=False then
               --   mailbox.set_flag_spostamento_from_urbana_completato(posizione_abitanti_on_road(current_posizione_abitante));
               --   if current_posizione_abitante.get_destination.get_corsia_to_go_trajectory=1 then
               --      resource_main_strada.remove_first_element_traiettoria(id_task,entrata_ritorno);
               --   else
               --      resource_main_strada.remove_first_element_traiettoria(id_task,entrata_andata);
               --   end if;
               --end if;
               --if ((current_posizione_abitante.get_id_abitante_posizione_abitanti=70 or current_posizione_abitante.get_id_abitante_posizione_abitanti=72) and current_posizione_abitante.get_id_quartiere_posizione_abitanti=3) and then id_task=93 then
               --   speed_abitante:= current_posizione_abitante.get_current_speed_abitante;
               --end if;
               mailbox.delete_car_in_entrata(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti);
               get_quartiere_utilities_obj.get_classe_locate_abitanti(current_posizione_abitante.get_id_quartiere_posizione_abitanti).set_finish_route(current_posizione_abitante.get_id_abitante_posizione_abitanti);
               if get_ingresso_from_id(id_task).get_type_ingresso=fermata then
                  -- carica scarica abitanti
                  get_gestore_bus_quartiere(current_posizione_abitante.get_id_quartiere_posizione_abitanti).autobus_arrived_at_fermata(current_posizione_abitante.get_id_abitante_posizione_abitanti,mailbox.create_array_abitanti_in_fermata,create_tratto(get_id_quartiere,id_task));
               end if;
               get_quartiere_entities_life(current_posizione_abitante.get_id_quartiere_posizione_abitanti).abitante_is_arrived(current_posizione_abitante.get_id_abitante_posizione_abitanti);
            else
               --mailbox.update_position_entity(state_view_abitanti,road,not mailbox.get_index_inizio_moto,i);
               current_posizione_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
               -- FLAG OVERTAKE NEXT CORSIA usato per indicare se l'abitante ha già attraversato l'incrocio completamente
               --if i=1 and then (current_posizione_abitante.get_flag_overtake_next_corsia=False and then current_posizione_abitante.get_where_now_posizione_abitanti-(get_quartiere_utilities_obj.get_auto_quartiere(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva/2.0)>=0.0) then
               --   mailbox.set_flag_spostamento_from_urbana_completato(posizione_abitanti_on_road(current_posizione_abitante));
               --   if current_posizione_abitante.get_destination.get_corsia_to_go_trajectory=1 then
               --      resource_main_strada.remove_first_element_traiettoria(id_task,entrata_ritorno);
               --   else
               --      resource_main_strada.remove_first_element_traiettoria(id_task,entrata_andata);
               --   end if;
               --end if;
               if list_abitanti.all.get_next_from_list_posizione_abitanti/=null then
                  next_posizione_abitante:= list_abitanti.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
                  distance_to_next:= next_posizione_abitante.get_where_now_posizione_abitanti-move_parameters(get_quartiere_utilities_obj.all.get_auto_quartiere(next_posizione_abitante.get_id_quartiere_posizione_abitanti,next_posizione_abitante.get_id_abitante_posizione_abitanti)).get_length_entità_passiva-current_posizione_abitante.get_where_now_posizione_abitanti;
                  if distance_to_next<=0.0 then acceleration:= 0.0;
                  else
                     acceleration:= calculate_acceleration(mezzo => car,
                                                     id_abitante => current_posizione_abitante.get_id_abitante_posizione_abitanti,
                                                     id_quartiere_abitante => current_posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                     next_entity_distance => distance_to_next,
                                                     distance_to_stop_line => get_ingresso_from_id(id_task).get_lunghezza_road+get_quartiere_utilities_obj.get_auto_quartiere(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva,
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
                                                     distance_to_stop_line => get_ingresso_from_id(id_task).get_lunghezza_road+get_quartiere_utilities_obj.get_auto_quartiere(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva,
                                                     next_id_quartiere_abitante => 0,
                                                     next_id_abitante => 0,
                                                     abitante_velocity => speed_abitante,
                                                     next_abitante_velocity =>0.0);
               end if;
               new_speed:= calculate_new_speed(speed_abitante,acceleration);
               new_step:= calculate_new_step(new_speed,acceleration);
               fix_advance_parameters(car,acceleration,new_speed,new_step,speed_abitante,distance_to_next,new_float'Last);

               mailbox.set_move_parameters_entity_on_main_strada(range_1 => not mailbox.get_index_inizio_moto,num_entity => i,speed => new_speed,step_to_advance => new_step);
               current_posizione_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
               list_abitanti:= list_abitanti.all.get_next_from_list_posizione_abitanti;
            end if;
         end loop;

         mailbox.sposta_abitanti_in_entrata_ingresso;

         --resource_main_strada.view_updated(False);

         -- END SPOSTAMENTO AUTO

         -- crea snapshot se necessario
         --crea_snapshot(num_delta,ptr_backup_interface(mailbox),id_task);
         --log_mio.write_task_arrived("id_task " & Positive'Image(id_task) & " id_quartiere " & Positive'Image(get_id_quartiere));

         --get_log_stallo_quartiere.finish(id_task);

         -- l'urbana 1 è il rappresentante per la chiusura del quartiere in questione
         get_synchronization_tasks_partition_object.task_has_finished;
         if id_task=get_from_ingressi then
            get_synchronization_tasks_partition_object.wait_to_be_last_task;
            if log_system_error.is_in_error then
               raise propaga_error;
            end if;

            if flag_chiusura_is_set=False and signal_quit_arrived then
               declare
                  registro: registro_quartieri:= get_quartiere_utilities_obj.get_saved_partitions;
                  able_to_stop: Boolean:= True;
               begin
                  -- viene controllato se  il quartiere in questione
                  -- sta aspettando altri quartieri
                  for i in registro'Range loop
                     if registro(i)/=null and then i/=get_id_quartiere then
                        if get_quartiere_utilities_obj.is_a_quartiere_to_wait(i)=False then
                           able_to_stop:= False;
                        end if;
                     end if;
                  end loop;
                  if able_to_stop then
                     flag_chiusura_is_set:= True;
                     quartiere_non_ha_nuove_partizioni(get_id_quartiere);
                  end if;
               end;
            end if;
         end if;

      end loop;
   exception
      when system_error_exc =>
         exit_task;
      when propaga_error =>
         close_mailbox;
      when regular_exit_system =>
         log_system_error.add_finished_task(id_task);
      when System.RPC.Communication_Error =>
         log_system_error.set_error(altro,error_flag);
         exit_task;
         close_mailbox;
         if error_flag then
            Put_Line("partizione remota non raggiungibile.");
         end if;
      when Error: others =>
         log_system_error.set_error(altro,error_flag);
         exit_task;
         close_mailbox;
         if error_flag then
            Put_Line("Unexpected exception ingressi: " & Positive'Image(id_task) & " ID QU " & Positive'Image(get_id_quartiere));
            Put_Line(Exception_Information(Error));
         end if;

      --Put_Line("Fine task ingresso" & Positive'Image(id_task) & ",id quartiere" & Positive'Image(get_id_quartiere));
   end core_avanzamento_ingressi;

   task body core_avanzamento_incroci is
      id_task: Positive;
      mailbox: ptr_resource_segmento_incrocio;
      id_mancante: Natural:= 0;
      list: ptr_list_posizione_abitanti_on_road;
      list_car: ptr_list_posizione_abitanti_on_road;
      list_near_car: ptr_list_posizione_abitanti_on_road;
      list_bipedi: ptr_list_posizione_abitanti_on_road;
      list_near_bipedi: ptr_list_posizione_abitanti_on_road;
      next_abitante: ptr_list_posizione_abitanti_on_road;
      index_road: Positive;
      index_other_road: Natural;
      other_index: Natural;
      switch: Boolean;
      quantità_percorsa: new_float:= 0.0;
      min_distance: new_float:= 0.0;
      traiettoria_car: traiettoria_incroci_type;
      other_traiettoria: traiettoria_incroci_type;
      road: road_incrocio_features;
      tratto_road: tratto;
      bound_distance: new_float:= -1.0;
      distance_to_next_car: new_float;
      distance_next_entity: new_float;
      distance_to_stop_line: new_float;
      length_traiettoria: new_float;
      new_abitante: posizione_abitanti_on_road;
      destination_trajectory: trajectory_to_follow;
      acceleration: new_float;
      new_step: new_float;
      new_speed: new_float;
      corsia: id_corsie;
      stop_entity: Boolean;
      id_main_road: Positive;
      state_view_abitanti: JSON_Array;
      pragma Warnings(off);
      state_view_semafori: JSON_Value;
      pragma Warnings(on);
      num_delta: Natural:= 0;
      acceleration_car: new_float;
      speed_abitante: new_float;
      num_car: Positive;
      step_is_just_calculated: Boolean;
      mezzo: means_of_carrying;
      next_id_quartiere_abitante: Natural;
      next_id_abitante: Natural;
      next_entity_distance: new_float;
      next_abitante_velocity: new_float;
      --traiettoria: traiettoria_incroci_type;
      i: Integer;
      error_flag: Boolean:= False;
      entity_length: new_float;
   begin
      select
         accept configure(id: Positive) do
            id_task:= id;
            mailbox:= get_incroci_segmento_resources(id);
            id_mancante:= get_mancante_incrocio_a_3(id_task);
         end configure;
      or
         accept kill do
            null;
            --raise system_error_exc;
         end kill;
      end select;

      if log_system_error.is_in_error then
         raise system_error_exc;
      end if;
      --wait_settings_all_quartieri;
      --Put_Line("task " & Positive'Image(id_task) & " of quartiere " & Positive'Image(get_id_quartiere) & " is set");
      -- Ora i task e le risorse di tutti i quartieri sono attivi

      reconfigure_resource(ptr_backup_interface(mailbox),id_task);

      loop
      --for p in 1..100 loop
         synchronization_with_delta(id_task);
         if get_synchronization_tasks_partition_object.is_regular_closure then
            raise regular_exit_system;
         end if;
         if log_system_error.is_in_error then
            raise propaga_error;
         end if;
         --log_mio.write_task_arrived("id_task " & Positive'Image(id_task) & " id_quartiere " & Positive'Image(get_id_quartiere));

         state_view_abitanti:= Empty_Array;
         mailbox.update_avanzamento_cars(state_view_abitanti);
         mailbox.update_avanzamento_bipedi(state_view_abitanti);
         mailbox.update_colore_semafori(state_view_semafori);

         state_view_quartiere.registra_aggiornamento_stato_risorsa(id_task,state_view_abitanti,state_view_semafori,mailbox.get_entità_in_out_quartiere);
         mailbox.reset_entità_in_out_quartiere;

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
                  traiettoria_car:= list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow;

                  length_traiettoria:= get_traiettoria_incrocio(traiettoria_car).get_lunghezza_traiettoria_incrocio;
                  -- !!! QUI IL FLAG overtake_next_corsia VIENE USATO PER VEDERE SE LA MACCHINA HA ATTRAVERSATO COMPLETAMENTO L'URBANA PRECEDENTE
                  if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_flag_overtake_next_corsia=False and then
                    list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                                                                                                                 list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva>=0.0 then
                     mailbox.set_car_have_passed_urbana(list_car);
                     -- la prima volta è un ingresso quindi errore conversion
                     tratto_road:= get_quartiere_utilities_obj.get_classe_locate_abitanti(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_current_tratto(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                     -- l'incrocio sta nel quartiere in cui sta girando questo codice
                     if get_quartiere_utilities_obj.get_classe_locate_abitanti(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_current_position(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti)=1 then
                        id_main_road:= get_ref_quartiere(tratto_road.get_id_quartiere_tratto).get_id_main_road_from_id_ingresso(tratto_road.get_id_tratto);
                     else
                        id_main_road:= tratto_road.get_id_tratto;
                     end if;
                     Put_Line("id abitante id quartiere " & Positive'Image(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " id ab " & Positive'Image(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " causa rimozione");
                     ptr_rt_urbana(get_id_urbana_quartiere(tratto_road.get_id_quartiere_tratto,id_main_road)).remove_abitante_in_incrocio(get_road_from_incrocio(id_task,get_index_road_from_incrocio(tratto_road.get_id_quartiere_tratto,id_main_road,id_task)).get_polo_road_incrocio,list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory,list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
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
                     else
                        index_other_road:= 0;
                     end if;

                     -- aggiornamento posizione macchina
                     if stop_entity=False then  -- la macchina può avanzare
                        switch:= False;
                        if distance_to_next_car/=-1.0 then
                           distance_next_entity:= distance_to_next_car;
                        else
                           switch:= True;  -- non si ha bound per macchine che stanno davanti
                        --end if;
                        end if;
                        if switch then
                           case traiettoria_car is  -- set distance next entity to length traiettoria
                           when others =>
                              distance_next_entity:= get_traiettoria_incrocio(traiettoria_car).get_lunghezza_traiettoria_incrocio;
                           end case;
                           distance_next_entity:= get_larghezza_marciapiede+get_larghezza_corsia+distance_next_entity-list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                        end if;
                        -- distance_next_entity is set
                        -- occorre impostare come massima distanza il limite inferiore nel quale
                        -- si è impostato di sorpassare; in questo modo un abitante che va a destra da index incrocio 3
                        -- e decide di sorpassare al prossimo delta una volta inserito nell'urbana; se viene inserito un abitante
                        -- nella corsia 1 dall'incroci; questo non si troverà mai a distanza superiore di 10
                        -- quindi l'abitante in corsia 1 riesce a vedere che l'abitante in 2 sta sorpassando
                        -- portando l'inserimento dell'abitante in lista 1 dopo l'abitante immesso nell'incrocio nella corsia 1
                        if distance_next_entity>get_larghezza_corsia+get_larghezza_marciapiede then
                           distance_next_entity:= get_larghezza_corsia+get_larghezza_marciapiede;
                        end if;

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
                        fix_advance_parameters(car,acceleration,new_speed,new_step,speed_abitante,distance_next_entity,distance_next_entity);
                        -- update scaglioni
                        step_is_just_calculated:= False;
                        if traiettoria_car=sinistra and index_other_road/=0 then -- index_other_road se 0 significa che non hai la strada opposta
                           switch:= True;
                           if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<
                             get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_1).get_distanza_intersezione_incrocio-max_larghezza_veicolo then
                              if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_1).get_distanza_intersezione_incrocio-max_larghezza_veicolo then
                                 -- index_other_road è rimasto quello della strada opposta
                                 list_near_car:= mailbox.get_list_car_to_move(index_other_road,1);
                                 while switch and list_near_car/=null loop
                                    -- cicla e guarda se ci sono macchine che vogliono andare dritto

                                    if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow=dritto_1 and then ((list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 and then mailbox.semaforo_is_verde_from_road(get_road_from_incrocio(id_task,index_other_road).get_id_quartiere_road_incrocio,get_road_from_incrocio(id_task,index_other_road).get_id_strada_road_incrocio)) or else (list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 and then
                                      list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                                      get_quartiere_utilities_obj.get_auto_quartiere(list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                                     list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                                      get_traiettoria_incrocio(dritto_1).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio+max_larghezza_veicolo)) then
                                       switch:= False;
                                    end if;
                                    list_near_car:= list_near_car.get_next_from_list_posizione_abitanti;
                                 end loop;
                                 if switch=False then
                                    new_step:= get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_1).get_distanza_intersezione_incrocio-max_larghezza_veicolo;
                                    step_is_just_calculated:= True;
                                 end if;
                              end if;
                           end if;
                           if switch and then list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<
                             get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_2).get_distanza_intersezione_incrocio-max_larghezza_veicolo then
                              if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_2).get_distanza_intersezione_incrocio-max_larghezza_veicolo then
                                 list_near_car:= mailbox.get_list_car_to_move(index_other_road,2);
                                 switch:= True;
                                 while switch and list_near_car/=null loop
                                    -- cicla e guarda se ci sono macchine che vogliono andare dritto

                                    if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow=dritto_2 and then ((list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 and then mailbox.semaforo_is_verde_from_road(get_road_from_incrocio(id_task,index_other_road).get_id_quartiere_road_incrocio,get_road_from_incrocio(id_task,index_other_road).get_id_strada_road_incrocio)) or else (list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=0.0 and then
                                      list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                                      get_quartiere_utilities_obj.get_auto_quartiere(list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                                     list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                                      get_traiettoria_incrocio(dritto_2).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio+max_larghezza_veicolo)) then
                                       switch:= False;
                                    end if;
                                    list_near_car:= list_near_car.get_next_from_list_posizione_abitanti;
                                 end loop;
                                 if switch=False then
                                    new_step:= get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_2).get_distanza_intersezione_incrocio-max_larghezza_veicolo;
                                    step_is_just_calculated:= True;
                                 end if;
                              end if;
                           end if;
                           if switch and then list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_incrocio(sinistra).get_intersezione_bipedi then
                              if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>get_traiettoria_incrocio(sinistra).get_intersezione_bipedi then
                                 if index_road=1 then
                                    other_index:= 3;
                                 elsif index_road=2 then
                                    other_index:= 4;
                                 elsif index_road=3 then
                                    other_index:= 1;
                                 elsif index_road=4 then
                                    other_index:= 2;
                                 end if;

                                 for h in 1..2 loop
                                    if h=1 then
                                       list_bipedi:= mailbox.get_list_bipede_to_move(other_index,dritto_bici);
                                    else
                                       list_bipedi:= mailbox.get_list_bipede_to_move(other_index,dritto_pedoni);
                                    end if;
                                    while switch and list_bipedi/=null loop
                                       if h=1 then
                                          entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                       else
                                          entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                       end if;
                                       if list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 and then
                                         (list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length<get_larghezza_marciapiede+get_larghezza_corsia*2.0) then
                                          switch:= False;
                                       end if;
                                       list_bipedi:= list_bipedi.get_next_from_list_posizione_abitanti;
                                    end loop;
                                    if switch=False then
                                       new_step:= get_traiettoria_incrocio(sinistra).get_intersezione_bipedi;
                                       step_is_just_calculated:= True;
                                    end if;
                                 end loop;
                              end if;
                           end if;
                        elsif traiettoria_car=dritto_1 or traiettoria_car= dritto_2 then
                           switch:= True;
                           if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_incrocio(traiettoria_car).get_intersezione_bipedi then
                              if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>get_traiettoria_incrocio(traiettoria_car).get_intersezione_bipedi then
                                 other_index:= index_road-1;
                                 if other_index=0 then
                                    other_index:= 4;
                                 end if;

                                 for h in 1..2 loop
                                    if h=1 then
                                       list_bipedi:= mailbox.get_list_bipede_to_move(other_index,dritto_bici);
                                    else
                                       list_bipedi:= mailbox.get_list_bipede_to_move(other_index,dritto_pedoni);
                                    end if;
                                    while switch and list_bipedi/=null loop
                                       if h=1 then
                                          entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                       else
                                          entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                       end if;
                                       if list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 and then
                                         ((traiettoria_car=dritto_2 and then list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length<get_larghezza_corsia+get_larghezza_marciapiede) or else
                                            (traiettoria_car=dritto_1 and then list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length<get_larghezza_corsia*2.0+get_larghezza_marciapiede)) then
                                          switch:= False;
                                       end if;
                                       list_bipedi:= list_bipedi.get_next_from_list_posizione_abitanti;
                                    end loop;
                                    if switch=False then
                                       new_step:= get_traiettoria_incrocio(traiettoria_car).get_intersezione_bipedi;
                                       step_is_just_calculated:= True;
                                    end if;
                                 end loop;
                              end if;
                           end if;
                        elsif traiettoria_car=destra then
                           switch:= True;
                           if list_car/=null and then list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<get_traiettoria_incrocio(traiettoria_car).get_intersezione_bipedi then
                              if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step>get_traiettoria_incrocio(traiettoria_car).get_intersezione_bipedi then
                                 other_index:= index_road;
                                 for h in 1..2 loop
                                    if h=1 then
                                       list_bipedi:= mailbox.get_list_bipede_to_move(other_index,dritto_bici);
                                    else
                                       list_bipedi:= mailbox.get_list_bipede_to_move(other_index,dritto_pedoni);
                                    end if;
                                    while switch and list_bipedi/=null loop
                                       if h=1 then
                                          entity_length:= get_quartiere_utilities_obj.get_bici_quartiere(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                       else
                                          entity_length:= get_quartiere_utilities_obj.get_pedone_quartiere(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                       end if;
                                       if list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 and then list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-entity_length<get_larghezza_marciapiede+get_larghezza_corsia then
                                          switch:= False;
                                       end if;
                                       list_bipedi:= list_bipedi.get_next_from_list_posizione_abitanti;
                                    end loop;
                                    if switch=False then
                                       new_step:= get_traiettoria_incrocio(traiettoria_car).get_intersezione_bipedi;
                                       step_is_just_calculated:= True;
                                    end if;
                                 end loop;
                              end if;
                           end if;
                        end if;

                        -- end update scaglioni

                        mailbox.update_avanzamento_abitante(list_car,new_step,new_speed,step_is_just_calculated);
                        Put_Line("id_abitante " & Positive'Image(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " is at " & new_float'Image(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti) & ", gestore is incrocio " & Positive'Image(id_task) & ", traiettoria:" & to_string_incroci_type(traiettoria_car) & ", from index road:" & Positive'Image(index_road) & " quartiere " & Positive'Image(get_id_quartiere));
                        if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<length_traiettoria and then list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>=length_traiettoria then
                           -- passaggio della macchina all'urbana

                           road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,i,traiettoria_car));
                           new_abitante:= posizione_abitanti_on_road(create_new_posizione_abitante_from_copy(list_car.get_posizione_abitanti_from_list_posizione_abitanti));
                           new_abitante.set_where_now_abitante(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti-length_traiettoria);
                           new_abitante.set_where_next_abitante(new_abitante.get_where_now_posizione_abitanti);
                           new_abitante.set_in_overtaken(False);
                           new_abitante.set_came_from_ingresso(False);
                           new_abitante.set_flag_overtake_next_corsia(False);
                           -- calcolo della traiettoria da seguire

                           if new_abitante.get_where_now_posizione_abitanti>get_larghezza_corsia+get_larghezza_marciapiede+min_veicolo_distance then
                              raise other_error;
                           end if;

                           -- può succedere che se l'abitante va molto veloce e si trova immediatamente alla fine dell'incrocio
                           -- senza aver rimosso l'abitante dall'urbana precedente
                           tratto_road:= get_quartiere_utilities_obj.get_classe_locate_abitanti(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_current_tratto(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                           if get_quartiere_utilities_obj.get_classe_locate_abitanti(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_current_position(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti)=1 then
                              id_main_road:= get_ref_quartiere(tratto_road.get_id_quartiere_tratto).get_id_main_road_from_id_ingresso(tratto_road.get_id_tratto);
                           else
                              id_main_road:= tratto_road.get_id_tratto;
                           end if;

                           -- posizionamento all'incrocio corrente
                           get_quartiere_utilities_obj.get_classe_locate_abitanti(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).set_position_abitante_to_next(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                           destination_trajectory:= calculate_trajectory_to_follow_from_incrocio(car,posizione_abitanti_on_road(list_car.get_posizione_abitanti_from_list_posizione_abitanti),road.get_polo_road_incrocio,list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                           new_abitante.set_destination(destination_trajectory);
                           new_abitante.set_backup_corsia_to_go(destination_trajectory.get_corsia_to_go_trajectory);

                           Put_Line("abitante " & Positive'Image(new_abitante.get_id_abitante_posizione_abitanti) & " inserito in urbana da incrocio " & new_float'Image(new_abitante.get_where_now_posizione_abitanti));
                           ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).insert_abitante_from_incrocio(car,new_abitante,not road.get_polo_road_incrocio,list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                           -- si usa destination per memorizzare la strada in cui l'abitante era
                           mailbox.update_abitante_destination(list_car,create_trajectory_to_follow(tratto_road.get_id_quartiere_tratto,list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory,0,id_main_road,traiettoria_car));

                           tratto_road:= get_quartiere_utilities_obj.get_classe_locate_abitanti(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_current_tratto(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                           Put_Line("abitante " & Positive'Image(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti) & " tratto " & Positive'Image(tratto_road.get_id_quartiere_tratto) & " " & Positive'Image(tratto_road.get_id_tratto));
                           --ASSOLUTAMENTE NO: mailbox.update_position_abitante(list_car,Float'Last);

                           if get_id_quartiere/=road.get_id_quartiere_road_incrocio then
                              mailbox.add_entità_in_out_quartiere(new_abitante.get_id_quartiere_posizione_abitanti,new_abitante.get_id_abitante_posizione_abitanti,car,tratto_road.get_id_quartiere_tratto,tratto_road.get_id_tratto,traiettoria_car);
                           end if;

                        end if;
                     else
                        Put_Line("STOP_ENTITY: " & Positive'Image(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                     end if;
                  else
                     null; --NOOP
                  end if;
                  list_car:= list_car.get_next_from_list_posizione_abitanti;
                  num_car:= num_car+1;
               end loop;
            end loop;
         end loop;

         -- crea snapshot se necessario
         --crea_snapshot(num_delta,ptr_backup_interface(mailbox),id_task);

         for index_road in 1..4 loop
            if index_road=id_mancante then
               i:= -1;
            else
               i:= index_road;
            end if;
            if id_mancante/=0 and index_road>id_mancante then
               i:= index_road-1;
            end if;

            -- VIENE CONTROLLATO SE SI HA GIÀ UN BIPEDE CHE SI TROVA PRIMA DI get_larghezza_marciapiede+get_larghezza_corsia
            switch:= False;
            for h in 1..2 loop
               if h=1 then
                  list:= mailbox.get_list_bipede_to_move(index_road,dritto_bici);
               else
                  list:= mailbox.get_list_bipede_to_move(index_road,dritto_pedoni);
               end if;
               while list/=null loop
                  if h=1 then
                     quantità_percorsa:= get_quartiere_utilities_obj.get_bici_quartiere(list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                  else
                     quantità_percorsa:= get_quartiere_utilities_obj.get_pedone_quartiere(list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                  end if;
                  if list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 and then
                    (list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=get_larghezza_marciapiede+get_larghezza_corsia or else
                     list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-quantità_percorsa<get_larghezza_marciapiede+get_larghezza_corsia) then
                     switch:= True;
                  end if;
                  list:= list.get_next_from_list_posizione_abitanti;
               end loop;
            end loop;

            -- switch è un segnale che viene utilizzato per controllare se qualche bipede ha già impegnato l'incrocio
            -- utilizzato per bipedi che devono ancora impegnare l'incrocio ma vi è un abitante subito prima di metà strada
            for traiettoria_bipede in traiettoria_incroci_type'Range loop
               if traiettoria_bipede=destra_pedoni or else (traiettoria_bipede=dritto_pedoni or else (traiettoria_bipede=destra_bici or else (traiettoria_bipede=dritto_bici))) then
                  if traiettoria_bipede=destra_pedoni or else traiettoria_bipede=destra_bici then
                     list_bipedi:= mailbox.get_list_bipede_to_move(index_road,traiettoria_bipede);
                     -- list_bipedi è sicuramente null per index_road=id_mancante dato che non ci possono essere traiettorie per destra_bici/destra_pedoni
                     if traiettoria_bipede=destra_pedoni then
                        mezzo:= walking;
                        corsia:= 2;
                        other_traiettoria:= dritto_pedoni;
                     else
                        mezzo:= bike;
                        corsia:= 1;
                        other_traiettoria:= dritto_bici;
                     end if;

                     if list_bipedi=null and then index_road/=id_mancante then
                        road:= get_road_from_incrocio(id_task,i);
                        if ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio))/=null and then (ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_abilitazione_cambio_traiettoria_bipede(road.get_polo_road_incrocio,mezzo)) then
                           mailbox.remove_first_bipede_to_go_destra_from_dritto(index_road,corsia,list_bipedi);
                        end if;
                     end if;
                     while list_bipedi/=null loop
                        -- nella traiettoria destra può passare un solo pedone alla volta
                        stop_entity:= False;
                        next_id_quartiere_abitante:= 0;
                        next_id_abitante:= 0;
                        next_entity_distance:= 0.0;
                        next_abitante_velocity:= 0.0;

                        -- un bipede non andrà mai a destra dall'indice della strada mancante nell'incrocio a 3
                        if list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti=146 then
                           stop_entity:= False;
                        end if;
                        road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,i,destra));

                        if traiettoria_bipede=destra_pedoni and then list_bipedi.get_next_from_list_posizione_abitanti/=null then
                           stop_entity:= True;
                        end if;

                        if stop_entity=False then
                           --next_abitante:= list_near_bipedi.get_next_from_list_posizione_abitanti;
                           next_abitante:= list_bipedi.get_next_from_list_posizione_abitanti;
                           if next_abitante=null then
                              quantità_percorsa:= ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_bipede(not road.get_polo_road_incrocio,mezzo);
                              if (mezzo=walking and then quantità_percorsa-min_pedone_distance<0.0) or else
                                (mezzo=bike and then quantità_percorsa<0.0) then
                                 stop_entity:= True;
                              end if;
                              if stop_entity=False then
                                 next_entity_distance:= quantità_percorsa+get_traiettoria_incrocio(traiettoria_bipede).get_lunghezza_traiettoria_incrocio-list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                              end if;
                           else
                              next_entity_distance:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                              next_id_quartiere_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                              next_id_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                              next_abitante_velocity:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                           end if;
                        end if;

                        if stop_entity=False then
                           distance_to_stop_line:= get_larghezza_marciapiede+get_larghezza_corsia+get_traiettoria_incrocio(traiettoria_bipede).get_lunghezza_traiettoria_incrocio-list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                           speed_abitante:= list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                           acceleration:= calculate_acceleration(mezzo => mezzo,
                                                                 id_abitante => list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                                 id_quartiere_abitante => list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                 next_entity_distance => next_entity_distance,
                                                                 distance_to_stop_line => distance_to_stop_line,
                                                                 next_id_quartiere_abitante => next_id_quartiere_abitante,
                                                                 next_id_abitante => next_id_abitante,
                                                                 abitante_velocity => speed_abitante,
                                                                 next_abitante_velocity => next_abitante_velocity,
                                                                 disable_rallentamento_1 => False,
                                                                 disable_rallentamento_2 => False,
                                                                 request_by_incrocio => True);

                           new_speed:= calculate_new_speed(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante,acceleration);
                           new_step:= calculate_new_step(new_speed,acceleration);
                           fix_advance_parameters(mezzo,acceleration,new_speed,new_step,speed_abitante,next_entity_distance,distance_to_stop_line);
                           mailbox.update_avanzamento_abitante(list_bipedi,new_step,new_speed,step_is_just_calculated);

                           if list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti=list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti then
                              Put_Line("SAME POSITION ABITANTE id quartiere: " & Positive'Image(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                              get_log_stallo_quartiere.write_state_stallo(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,True);
                           else
                              get_log_stallo_quartiere.write_state_stallo(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,False);
                           end if;
                           if list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>=get_traiettoria_incrocio(traiettoria_bipede).get_lunghezza_traiettoria_incrocio then

                              tratto_road:= get_quartiere_utilities_obj.get_classe_locate_abitanti(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_current_tratto(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                              if get_quartiere_utilities_obj.get_classe_locate_abitanti(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).get_current_position(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti)=1 then
                                 id_main_road:= get_ref_quartiere(tratto_road.get_id_quartiere_tratto).get_id_main_road_from_id_ingresso(tratto_road.get_id_tratto);
                              else
                                 id_main_road:= tratto_road.get_id_tratto;
                              end if;

                              get_quartiere_utilities_obj.get_classe_locate_abitanti(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).set_position_abitante_to_next(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                              destination_trajectory:= calculate_trajectory_to_follow_from_incrocio(mezzo,posizione_abitanti_on_road(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti),road.get_polo_road_incrocio,corsia);
                              new_abitante:= posizione_abitanti_on_road(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti);
                              new_abitante.set_destination(destination_trajectory);
                              new_abitante.set_flag_overtake_next_corsia(False);
                              new_abitante.set_where_next_abitante(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti-get_traiettoria_incrocio(traiettoria_bipede).get_lunghezza_traiettoria_incrocio);
                              new_abitante.set_where_now_abitante(new_abitante.get_where_next_posizione_abitanti);
                              ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).insert_abitante_from_incrocio(mezzo,new_abitante,not road.get_polo_road_incrocio,corsia);

                              if get_id_quartiere/=road.get_id_quartiere_road_incrocio then
                                 mailbox.add_entità_in_out_quartiere(new_abitante.get_id_quartiere_posizione_abitanti,new_abitante.get_id_abitante_posizione_abitanti,mezzo,tratto_road.get_id_quartiere_tratto,tratto_road.get_id_tratto,traiettoria_bipede);
                              end if;

                           end if;
                        end if;

                        list_bipedi:= list_bipedi.get_next_from_list_posizione_abitanti;

                     end loop;
                  else
                     -- traiettoria_bipede vale: dritto_pedoni or dritto_bici
                     if traiettoria_bipede=dritto_pedoni then
                        mezzo:= walking;
                        corsia:= 2;
                        list_bipedi:= mailbox.get_list_bipede_to_move(index_road,traiettoria_bipede);
                        list_near_bipedi:= mailbox.get_list_bipede_to_move(index_road,sinistra_pedoni);
                     else
                        mezzo:= bike;
                        corsia:= 1;
                        list_bipedi:= mailbox.get_list_bipede_to_move(index_road,traiettoria_bipede);
                        list_near_bipedi:= mailbox.get_list_bipede_to_move(index_road,sinistra_bici);
                     end if;


                     --turno:= True;
                     -- passano gli abitanti che sono già in direzione dritto se True;
                     -- se False passano quelli in direzione sinistra

                     -- switch lo setti a True sse hai un bipede nella prima corsia ancora altrimenti
                     -- se False e hai bipedi che devono ancora iniziare a spostarsi occorre rifare il check su
                     -- tutte le traiettorie

                     while list_bipedi/=null or else list_near_bipedi/=null loop
                        stop_entity:= False;
                        next_id_quartiere_abitante:= 0;
                        next_id_abitante:= 0;
                        next_entity_distance:= 0.0;
                        next_abitante_velocity:= 0.0;

                        --if list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti=156 then
                        --   stop_entity:= False;
                        --end if;

                        if mailbox.get_semaforo_bipedi then
                           -- semaforo verde per i bipedi
                           -- BLOCCO 1
                           if (list_bipedi/=null and then list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0) or else list_near_bipedi/=null then

                              if switch=False then
                                 -- occorre controllare se le macchine negli incroci hanno attraversato
                                 if id_mancante=0 or else id_mancante/=index_road then
                                    -- esiste la strada i-esima
                                    list_car:= mailbox.get_list_car_to_move(i,2);
                                    -- controlla se si hanno macchine che arrivano da destra
                                    while list_car/=null and stop_entity=False loop
                                       -- if list_car.get_posizione_abitanti_from_list_posizione_abitanti
                                       if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow=destra and then
                                         list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 then
                                          stop_entity:= True;
                                       end if;
                                       list_car:= list_car.get_next_from_list_posizione_abitanti;
                                    end loop;
                                 end if;

                                 -- controllare se vi sono macchine che arrivano dritte dalla strada opposta
                                 -- perpendicolare a quella in cui vanno i pedoni
                                 index_other_road:= index_road+1;
                                 if index_other_road=5 then
                                    index_other_road:= 1;
                                 end if;

                                 if index_other_road/=id_mancante then
                                    index_other_road:= calulate_index_road_to_go_incrocio_completo_from_incrocio_a_3(id_task,index_road,sinistra);
                                    list_car:= mailbox.get_list_car_to_move(index_other_road,1);
                                    while list_car/=null loop
                                       if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow=dritto_1 and then
                                         list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 then
                                          stop_entity:= True;
                                       end if;
                                       list_car:= list_car.get_next_from_list_posizione_abitanti;
                                    end loop;

                                    list_car:= mailbox.get_list_car_to_move(index_other_road,2);
                                    while list_car/=null loop
                                       if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow=dritto_2 and then
                                         list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 then
                                          stop_entity:= True;
                                       end if;
                                       list_car:= list_car.get_next_from_list_posizione_abitanti;
                                    end loop;
                                 end if;

                                 -- controllare le macchine che vanno a sinistra da quelle in direzione opposta
                                 if index_road=1 then
                                    index_other_road:= 3;
                                 elsif index_road=2 then
                                    index_other_road:= 4;
                                 elsif index_road=3 then
                                    index_other_road:= 1;
                                 elsif index_road=4 then
                                    index_other_road:= 2;
                                 end if;
                                 if index_other_road/=id_mancante then
                                    index_other_road:= calulate_index_road_to_go_incrocio_completo_from_incrocio_a_3(id_task,index_road,dritto_1);
                                    list_car:= mailbox.get_list_car_to_move(index_other_road,1);
                                    while list_car/=null loop
                                       if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow=sinistra and then
                                         list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 then
                                          stop_entity:= True;
                                       end if;
                                       list_car:= list_car.get_next_from_list_posizione_abitanti;
                                    end loop;
                                 end if;

                                 -- controllare la posizione dei primi abitanti nela strada perperdicolare
                                 -- a quella in cui i bipedi devono muoversi
                                 index_other_road:= index_road-1;
                                 if index_other_road=0 then
                                    index_other_road:= 4;
                                 end if;

                                 if id_mancante/=index_other_road then
                                    -- esiste la strada a destra
                                    -- controllare se le macchine che hanno preso la strada a destra
                                    -- hanno sorpassato il marciapiede
                                    road:= get_road_from_incrocio(id_task,calulate_index_road_to_go_incrocio_completo_from_incrocio_a_3(id_task,index_road,destra));
                                    if ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio))/=null then
                                       if stop_entity=False then
                                          stop_entity:= not ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).first_car_abitante_has_passed_incrocio(road.get_polo_road_incrocio,1);
                                       end if;
                                      if stop_entity=False then
                                          stop_entity:= not ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).first_car_abitante_has_passed_incrocio(road.get_polo_road_incrocio,2);
                                       end if;
                                    end if;

                                    -- controllare se ci sono macchine in entrata incrocio dalla
                                    -- strada di destra
                                    for k in 1..2 loop
                                       list_car:= mailbox.get_list_car_to_move(calulate_index_road_to_go_incrocio_completo_from_incrocio_a_3(id_task,index_road,destra),k);
                                       if list_car/=null then
                                          --  ATTTTTTTENZIONE SI CONTROLLA IL WHERE_NEXT DATO CHE IL CICLO SULLE MACCHINE È
                                          -- ESEGUITO PRIMA DI QUELLO SULLO SPOSTAMENTO DEI BIPEDI
                                          if list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>0.0 and then
                                            list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<get_larghezza_marciapiede+min_veicolo_distance then
                                             stop_entity:= True;
                                          end if;
                                       end if;
                                    end loop;

                                 end if;
                              end if;

                              if list_bipedi/=null and then list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 then
                                 if mezzo=walking then
                                    quantità_percorsa:= get_quartiere_utilities_obj.get_pedone_quartiere(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                    min_distance:= min_pedone_distance;
                                 else
                                    --mezzo=bike
                                    quantità_percorsa:= get_quartiere_utilities_obj.get_bici_quartiere(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                    min_distance:= min_bici_distance;
                                 end if;
                                 if list_bipedi.get_next_from_list_posizione_abitanti/=null then
                                    if list_bipedi.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-quantità_percorsa-min_distance<0.0 then
                                       stop_entity:= True;
                                    end if;
                                 end if;
                              end if;

                              -- occorre controllare se è possibile inserire in traiettoria dritto un abitante che è nella traiettoria a sinistra
                              if stop_entity=False and then (list_bipedi=null or else list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti/=0.0) then
                                 -- list_near_bipedi/=null
                                 -- occorre agginugere il primo abitante di list_near_bipede all'inizio di list_bipedi
                                 if list_bipedi/=null then
                                    if mezzo=walking then
                                       quantità_percorsa:= get_quartiere_utilities_obj.get_pedone_quartiere(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                       min_distance:= min_pedone_distance;
                                    else
                                       --mezzo=bike
                                       quantità_percorsa:= get_quartiere_utilities_obj.get_bici_quartiere(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                                       min_distance:= min_bici_distance;
                                    end if;
                                 else
                                    quantità_percorsa:= 0.0;
                                    min_distance:= 0.0;
                                 end if;
                                 if list_bipedi=null or else (list_bipedi/=null and then list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-quantità_percorsa>min_distance) then
                                    if index_road/=id_mancante then
                                       road:= get_road_from_incrocio(id_task,i);
                                       if ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio))/=null and then (ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_abilitazione_cambio_traiettoria_bipede(road.get_polo_road_incrocio,mezzo)) then
                                          mailbox.sposta_bipede_da_sinistra_a_dritto(index_road,mezzo,list_near_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_near_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                                          -- list_bipedi è quindi cambiato
                                          list_bipedi:= mailbox.get_list_bipede_to_move(index_road,traiettoria_bipede);
                                         -- impostando list_near_bipedi a null avremo che nel BLOCCO 1 non ci entrerà
                                       end if;
                                    else
                                       -- non serve controllare get_abilitazione_cambio_traiettoria_bipede dato che la strada considerata non esiste
                                       mailbox.sposta_bipede_da_sinistra_a_dritto(index_road,mezzo,list_near_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_near_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                                       list_bipedi:= mailbox.get_list_bipede_to_move(index_road,traiettoria_bipede);
                                    end if;
                                 end if;
                              end if;
                           end if;
                        else
                           if list_bipedi/=null and then list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0 then
                              stop_entity:= True;
                           end if;
                        end if;

                        list_near_bipedi:= null;

                        if stop_entity=False and then list_bipedi/=null then
                           -- sposta il bipede
                           next_abitante:= list_bipedi.get_next_from_list_posizione_abitanti;
                           distance_to_stop_line:= get_traiettoria_incrocio(traiettoria_bipede).get_lunghezza_traiettoria_incrocio-list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;

                           if next_abitante/=null then
                              if mezzo=walking then
                                 quantità_percorsa:= get_quartiere_utilities_obj.get_pedone_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                              else
                                 quantità_percorsa:= get_quartiere_utilities_obj.get_bici_quartiere(next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                              end if;
                              next_entity_distance:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-quantità_percorsa-list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                              next_id_quartiere_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                              next_id_abitante:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                              next_abitante_velocity:= next_abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                           else
                              -- next_abitante vale null
                              index_other_road:= index_road-1;
                              if index_other_road=0 then
                                 index_other_road:= 4;
                              end if;
                              if id_mancante=index_other_road then
                                 -- macchine che entrano in traiettoria destra non ve ne sono
                                 -- occorre calcolare la posizione del prossimo abitante nell'urbana
                                 road:= get_road_from_incrocio(id_task,calulate_index_road_to_go_incrocio_completo_from_incrocio_a_3(id_task,index_road,dritto_1));
                                 quantità_percorsa:= ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_bipede(not road.get_polo_road_incrocio,mezzo);
                                 next_entity_distance:= get_larghezza_marciapiede*2.0+get_larghezza_corsia*4.0+quantità_percorsa-list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                                 -- viene messa come distance_to_stop_line una distanza in cui si arriva a 10mt in più dalla fine dell'incrocio
                                 distance_to_stop_line:= get_traiettoria_incrocio(traiettoria_bipede).get_lunghezza_traiettoria_incrocio+get_larghezza_corsia+get_larghezza_marciapiede-list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                              end if;
                           end if;

                           speed_abitante:= list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante;
                           acceleration:= calculate_acceleration(mezzo => mezzo,
                                                                 id_abitante => list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,
                                                                 id_quartiere_abitante => list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                 next_entity_distance => next_entity_distance,
                                                                 distance_to_stop_line => distance_to_stop_line,
                                                                 next_id_quartiere_abitante => next_id_quartiere_abitante,
                                                                 next_id_abitante => next_id_abitante,
                                                                 abitante_velocity => speed_abitante,
                                                                 next_abitante_velocity => next_abitante_velocity,
                                                                 disable_rallentamento_1 => True,
                                                                 disable_rallentamento_2 => True,
                                                                 request_by_incrocio => True);

                           new_speed:= calculate_new_speed(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_current_speed_abitante,acceleration);
                           new_step:= calculate_new_step(new_speed,acceleration);
                           fix_advance_parameters(mezzo,acceleration,new_speed,new_step,speed_abitante,next_entity_distance,distance_to_stop_line);
                           mailbox.update_avanzamento_abitante(list_bipedi,new_step,new_speed,False);

                           if list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti=list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti then
                              Put_Line("SAME POSITION ABITANTE id quartiere: " & Positive'Image(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                              get_log_stallo_quartiere.write_state_stallo(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,True);
                           else
                              get_log_stallo_quartiere.write_state_stallo(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti,False);
                           end if;

                           index_other_road:= index_road-1;
                           if index_other_road=0 then
                              index_other_road:= 4;
                           end if;
                           if id_mancante=index_other_road and then (list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow/=sinistra_bici and then list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow/=sinistra_pedoni) then
                              if list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti>=get_traiettoria_incrocio(traiettoria_bipede).get_lunghezza_traiettoria_incrocio then

                                 if i/=-1 then
                                    road:= get_road_from_incrocio(id_task,i);
                                    tratto_road:= create_tratto(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio);
                                 else
                                    tratto_road:= create_tratto(0,0);
                                 end if;

                                 road:= get_road_from_incrocio(id_task,calulate_index_road_to_go_incrocio_completo_from_incrocio_a_3(id_task,index_road,dritto_1));
                                 get_quartiere_utilities_obj.get_classe_locate_abitanti(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti).set_position_abitante_to_next(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti);
                                 destination_trajectory:= calculate_trajectory_to_follow_from_incrocio(mezzo,posizione_abitanti_on_road(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti),road.get_polo_road_incrocio,corsia);
                                 new_abitante:= posizione_abitanti_on_road(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti);
                                 new_abitante.set_destination(destination_trajectory);
                                 new_abitante.set_flag_overtake_next_corsia(False);
                                 new_abitante.set_where_next_abitante(list_bipedi.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti-get_traiettoria_incrocio(traiettoria_bipede).get_lunghezza_traiettoria_incrocio);
                                 new_abitante.set_where_now_abitante(new_abitante.get_where_next_posizione_abitanti);
                                 ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).insert_abitante_from_incrocio(mezzo,new_abitante,not road.get_polo_road_incrocio,corsia);

                                 if get_id_quartiere/=road.get_id_quartiere_road_incrocio then
                                    mailbox.add_entità_in_out_quartiere(new_abitante.get_id_quartiere_posizione_abitanti,new_abitante.get_id_abitante_posizione_abitanti,mezzo,tratto_road.get_id_quartiere_tratto,tratto_road.get_id_tratto,traiettoria_bipede);
                                 end if;

                              end if;
                           end if;
                        end if;

                        if list_bipedi/=null then
                           list_bipedi:= list_bipedi.get_next_from_list_posizione_abitanti;
                        end if;

                     end loop;
                  end if;
               end if;
            end loop;
         end loop;

         -- wake urbane

         get_synchronization_tasks_partition_object.task_has_finished;

         for r in 1..get_size_incrocio(id_task) loop
            if get_id_urbana_quartiere(get_road_from_incrocio(id_task,r).get_id_quartiere_road_incrocio,get_road_from_incrocio(id_task,r).get_id_strada_road_incrocio)/=null then
               declare
                  temp_re_qu_corrente: registro_quartieri:= get_quartiere_utilities_obj.get_saved_partitions;
               begin
                  -- si va a contribuire a risvegliare l'urbana solo se il quartiere era stato notato a inizio sincronizzazione
                  if temp_re_qu_corrente(get_road_from_incrocio(id_task,r).get_id_quartiere_road_incrocio)/=null then
                     --Put_Line("id_incrocio " & Positive'Image(id_task) & " want to notify " & Positive'Image(get_road_from_incrocio(id_task,r).get_id_quartiere_road_incrocio) & " " & Positive'Image(get_road_from_incrocio(id_task,r).get_id_strada_road_incrocio));
                     get_id_urbana_quartiere(get_road_from_incrocio(id_task,r).get_id_quartiere_road_incrocio,get_road_from_incrocio(id_task,r).get_id_strada_road_incrocio).delta_incrocio_finished;
                     --Put_Line("id_incrocio " & Positive'Image(id_task) & " notify " & Positive'Image(get_road_from_incrocio(id_task,r).get_id_quartiere_road_incrocio) & " " & Positive'Image(get_road_from_incrocio(id_task,r).get_id_strada_road_incrocio));
                  end if;
               end;
            end if;
         end loop;

         --get_log_stallo_quartiere.finish(id_task);

      end loop;
   exception
      when system_error_exc =>
         exit_task;
      when propaga_error =>
         close_mailbox;
      when regular_exit_system =>
         log_system_error.add_finished_task(id_task);
      when System.RPC.Communication_Error =>
         log_system_error.set_error(altro,error_flag);
         exit_task;
         close_mailbox;
         if error_flag then
            Put_Line("partizione remota non raggiungibile.");
         end if;
      when Error: others =>
         log_system_error.set_error(altro,error_flag);
         exit_task;
         close_mailbox;
         if error_flag then
            Put_Line("Unexpected exception incroci: " & Positive'Image(id_task) & " ID QU " & Positive'Image(get_id_quartiere));
            Put_Line(Exception_Information(Error));
         end if;

      --Put_Line("Fine task incrocio" & Positive'Image(id_task) & ",id quartiere" & Positive'Image(get_id_quartiere));
   end core_avanzamento_incroci;

end risorse_strade_e_incroci;
