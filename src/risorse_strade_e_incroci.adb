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
         if get_ingresso_from_id(nodo.get_id_tratto).get_distance_from_road_head_ingresso/=ingresso.get_distance_from_road_head_ingresso then
            return diritto;
         else
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
      end if;
   end calculate_traiettoria_to_follow_from_ingresso;

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

   procedure synchronization_with_delta(id: Positive) is
      synch_obj: ptr_synchronization_tasks:= get_synchronization_tasks_partition_object;
   begin
      synch_obj.registra_task(id);
      synch_obj.wait_tasks_partitions;
   end synchronization_with_delta;

   --protected body location_abitanti is
   --   procedure set_percorso_abitante(id_abitante: Positive; percorso: route_and_distance) is
   --   begin
   --      percorsi(id_abitante):= new route_and_distance'(percorso);
   --   end set_percorso_abitante;
   --end location_abitanti;

   task body core_avanzamento_urbane is
      id_task: Positive;
      mailbox: ptr_resource_segmento_urbana;
      array_estremi_strada_urbana: estremi_resource_strada_urbana:= (others => null);
   begin
      accept configure(id: Positive) do
         id_task:= id;
         mailbox:= get_urbane_segmento_resources(id);
      end configure;
      -- Put_Line("configurato" & Positive'Image(id_task) & "id quartiere" & Positive'Image(get_id_quartiere));

      wait_settings_all_quartieri;
      array_estremi_strada_urbana:= get_resource_estremi_urbana(id_task);

      -- BEGIN LOOP
      --synchronization_with_delta(id_task);
      -- aspetta che finiscano gli incroci
      if array_estremi_strada_urbana(1)/=null then
         array_estremi_strada_urbana(1).wait_turno;
      end if;
      if array_estremi_strada_urbana(2)/=null then
         array_estremi_strada_urbana(2).wait_turno;
      end if;
      -- fine wait; gli incroci hanno fatto l'avanzamento
      if mailbox.there_are_pedoni_or_bici_to_move then -- muovi pedoni
         delay 2.0; --simulazione lavoro
      end if;
      if mailbox.there_are_autos_to_move then -- muovi pedoni
         delay 2.0; --simulazione lavoro
      end if;
      mailbox.delta_terminate;
      -- set all entità passive a TRUE
      -- END LOOP;

      Put_Line("Fine task urbana" & Positive'Image(id_task) & ",id quartiere" & Positive'Image(get_id_quartiere));
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
   begin
      accept configure(id: Positive) do
         id_task:= id;
         mailbox:= get_ingressi_segmento_resources(id);
         resource_main_strada:= get_urbane_segmento_resources(get_ingresso_from_id(id_task).get_id_main_strada_ingresso);
      end configure;

      wait_settings_all_quartieri;
      -- Ora i task e le risorse di tutti i quartieri sono attivi

      while id_task=35 and get_id_quartiere=1 loop
      --synchronization_with_delta(id_task);
      --resource_main_strada.wait_turno;
         if mailbox.there_are_autos_to_move then
            list_abitanti:= mailbox.get_main_strada(mailbox.get_index_inizio_moto);
            for i in 1..mailbox.get_number_entity_strada(mailbox.get_index_inizio_moto) loop
               mailbox.update_position_entity(road,mailbox.get_index_inizio_moto,i);
               current_posizione_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
               if list_abitanti.all.get_next_from_list_posizione_abitanti/=null then
                  next_posizione_abitante:= list_abitanti.get_next_from_list_posizione_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
                  distance_to_next:= next_posizione_abitante.get_old_posizione-move_parameters(get_quartiere_utilities_obj.all.get_auto_quartiere(next_posizione_abitante.get_id_quartiere_posizione_abitanti,next_posizione_abitante.get_id_abitante_posizione_abitanti)).get_length_entità_passiva-current_posizione_abitante.get_old_posizione;
                  if distance_to_next<=0.0 then acceleration:= 0.0;
                  else
                     acceleration:= calculate_acceleration(mezzo => car,
                                                           id_abitante => current_posizione_abitante.get_id_abitante_posizione_abitanti,
                                                           id_quartiere_abitante => current_posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                           next_entity_distance => distance_to_next,
                                                           distance_to_stop_line => get_ingresso_from_id(id_task).get_lunghezza_road-current_posizione_abitante.get_old_posizione+1.0,
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
                                                        distance_to_stop_line => get_ingresso_from_id(id_task).get_lunghezza_road-current_posizione_abitante.get_old_posizione+1.0,
                                                        next_id_quartiere_abitante => 0,
                                                        next_id_abitante => 0,
                                                        abitante_velocity => current_posizione_abitante.get_current_speed_abitante,
                                                        next_abitante_velocity =>0.0);
               end if;
               new_speed:= calculate_new_speed(current_posizione_abitante.get_current_speed_abitante,acceleration);
               new_step:= calculate_new_step(new_speed,acceleration);
               mailbox.set_move_parameters_entity_on_main_strada(range_1 => mailbox.get_index_inizio_moto,num_entity => i,speed => new_speed,step_to_advance => new_step);
               current_posizione_abitante:= list_abitanti.get_posizione_abitanti_from_list_posizione_abitanti;
               --Put_Line("new_speed" & Float'Image(new_speed) & " new_step" & Float'Image(new_step));
               Put_Line("advance num car" & Positive'Image(i) & "now " & Float'Image(current_posizione_abitante.get_where_now_posizione_abitanti) & Float'Image(current_posizione_abitante.get_where_next_posizione_abitanti));
               if current_posizione_abitante.get_where_next_posizione_abitanti=get_ingresso_from_id(id_task).get_lunghezza_road then
                  traiettoria_type:= calculate_traiettoria_to_follow_from_ingresso(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti,id_task,resource_main_strada.get_ordered_ingressi_from_polo_true_urbana);
                  resource_main_strada.aggiungi_entità_from_ingresso(id_task,traiettoria_type,current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti);
               end if;
               list_abitanti:= list_abitanti.all.get_next_from_list_posizione_abitanti;
               delay 1.0;
            end loop;
         end if;
         new_requests:= mailbox.get_temp_main_strada;
         if new_requests/=null then
            loop
               list_abitanti:= mailbox.get_main_strada(mailbox.get_index_inizio_moto);
               current_posizione_abitante:= new_requests.all.get_posizione_abitanti_from_list_posizione_abitanti;
               if mailbox.get_number_entity_strada(mailbox.get_index_inizio_moto)/=0 then
                  next_posizione_abitante:= list_abitanti.all.get_posizione_abitanti_from_list_posizione_abitanti;
                  distance_to_next:= next_posizione_abitante.get_old_posizione-move_parameters(get_quartiere_utilities_obj.all.get_auto_quartiere(next_posizione_abitante.get_id_quartiere_posizione_abitanti,next_posizione_abitante.get_id_abitante_posizione_abitanti)).get_length_entità_passiva-current_posizione_abitante.get_old_posizione;
                  if distance_to_next<=0.0 then acceleration:= 0.0;
                  else
                     acceleration:= calculate_acceleration(mezzo => car,
                                                           id_abitante => current_posizione_abitante.get_id_abitante_posizione_abitanti,
                                                           id_quartiere_abitante => current_posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                           next_entity_distance => distance_to_next,
                                                           distance_to_stop_line => get_ingresso_from_id(id_task).get_lunghezza_road-current_posizione_abitante.get_old_posizione+1.0,
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
                                                        distance_to_stop_line => get_ingresso_from_id(id_task).get_lunghezza_road-current_posizione_abitante.get_old_posizione+1.0,
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
                  traiettoria_type:= calculate_traiettoria_to_follow_from_ingresso(current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti,id_task,resource_main_strada.get_ordered_ingressi_from_polo_true_urbana);
                  resource_main_strada.aggiungi_entità_from_ingresso(id_task,traiettoria_type,current_posizione_abitante.get_id_quartiere_posizione_abitanti,current_posizione_abitante.get_id_abitante_posizione_abitanti);
               end if;
               new_requests:= mailbox.get_temp_main_strada;
               exit when residente.get_length_entità_passiva-new_step>=0.0 or new_requests=null;
            end loop;
         end if;
      --if new_step/=0.0 then
      --end if;
      --quando l'abitante è arrivato occorre invocare l'asincrono abitante_is_arrived del tipo del quartiere del luogo arrivo che muoverà nuovamente l'abitante

            -- controlla se l ultime entità è arrivata alla fine
            -- aggiungi entità from ingressi al resorce main strada
            -- array temporaneo spostamenti entità

         exit when new_step=250.0;
      end loop;
   Put_Line("Fine task ingresso" & Positive'Image(id_task) & ",id quartiere" & Positive'Image(get_id_quartiere));
   end core_avanzamento_ingressi;

   task body core_avanzamento_incroci is
      id_task: Positive;
      mailbox: ptr_resource_segmento_incrocio;
   begin
      accept configure(id: Positive) do
         id_task:= id;
         mailbox:= get_incroci_segmento_resources(id);
      end configure;

      wait_settings_all_quartieri;
      -- Ora i task e le risorse di tutti i quartieri sono attivi

      -- loop
      --synchronization_with_delta(id_task);
      delay 5.0;
      mailbox.delta_terminate;
      -- end loop;

      Put_Line("Fine task incrocio" & Positive'Image(id_task) & ",id quartiere" & Positive'Image(get_id_quartiere));
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
