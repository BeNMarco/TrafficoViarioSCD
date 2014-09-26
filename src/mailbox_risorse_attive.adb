with Text_IO;

with remote_types;
with data_quartiere;
with global_data;
with risorse_passive_data;
with risorse_mappa_utilities;
with the_name_server;

use Text_IO;

use remote_types;
use data_quartiere;
use global_data;
use risorse_passive_data;
use risorse_mappa_utilities;
use the_name_server;

package body mailbox_risorse_attive is

   function calculate_bound_to_overtake(abitante: ptr_list_posizione_abitanti_on_road) return Float is
      distance: Float;
   begin
      if abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow=empty then
         distance:= get_distance_from_polo_percorrenza(get_ingresso_from_id(abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_ingresso_to_go_trajectory))-abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
         return distance-40.0;
      else
         distance:= get_urbana_from_id(get_ingresso_from_id(abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_ingresso_to_go_trajectory).get_id_main_strada_ingresso).get_lunghezza_road-abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
         return distance-40.0;
      end if;
   end calculate_bound_to_overtake;

   function get_min_length_entità(entity: entità) return Float is
   begin
      case entity is
         when pedone_entity => return min_length_pedoni;
         when bici_entity => return min_length_bici;
         when auto_entity => return min_length_auto;
      end case;
   end get_min_length_entità;

   function calculate_max_num_auto(len: Float) return Natural is
      num: Positive:= Positive(Float'Rounding(len/get_min_length_entità(auto_entity)));
   begin
      if num>get_num_abitanti then
         return get_num_abitanti;
      else
         return num;
      end if;
   end calculate_max_num_auto;

   function calculate_max_num_pedoni(len: Float) return Natural is
      num: Positive:= Positive(Float'Rounding(Float(len)/get_min_length_entità(pedone_entity)));
   begin
      if num>get_num_abitanti then
         return get_num_abitanti;
      else
         return num;
      end if;
   end calculate_max_num_pedoni;

   protected body resource_segmento_urbana is

      entry wait_turno when finish_delta_urbana is
      begin
         num_ingressi_ready:=num_ingressi_ready+1;
         if num_ingressi_ready=num_ingressi then
            finish_delta_urbana:= False;
            num_ingressi_ready:= 0;
         end if;
      end wait_turno;

      procedure delta_terminate is
      begin
         finish_delta_urbana:= True;
      end delta_terminate;

      procedure configure(risorsa: strada_urbana_features; list_ingressi: ptr_list_ingressi_per_urbana;
                          list_ingressi_polo_true: ptr_list_ingressi_per_urbana; list_ingressi_polo_false: ptr_list_ingressi_per_urbana) is
         list: ptr_list_ingressi_per_urbana;
      begin
         risorsa_features:= risorsa;
         list:= list_ingressi;
         for i in 1..num_ingressi loop
            index_ingressi(i):= list.id_ingresso;
            list:= list.next;
         end loop;
         list:= list_ingressi_polo_false;
         for i in 1..num_ingressi_polo_false loop
            ordered_ingressi_polo(False)(i):= list.id_ingresso;
            list:= list.next;
         end loop;
         list:= list_ingressi_polo_true;
         for i in reverse 1..num_ingressi_polo_true loop
            ordered_ingressi_polo(True)(num_ingressi_polo_true-i+1):= list.id_ingresso;
            list:= list.next;
         end loop;
      end configure;

      procedure aggiungi_entità_from_ingresso(id_ingresso: Positive; type_traiettoria: traiettoria_ingressi_type;
                                              id_quartiere_abitante: Positive; id_abitante: Positive; traiettoria_on_main_strada: trajectory_to_follow) is
         index: Natural:= get_key_ingresso(id_ingresso,not_ordered);
         list: ptr_list_posizione_abitanti_on_road:= null;
         place_abitante: posizione_abitanti_on_road;
         new_abitante_to_add: ptr_list_posizione_abitanti_on_road:= new list_posizione_abitanti_on_road;
         prec_list: ptr_list_posizione_abitanti_on_road:= null;
      begin
         if index/=0 then
            list:= set_traiettorie_ingressi(index,type_traiettoria);
            place_abitante:= posizione_abitanti_on_road(create_new_posizione_abitante(id_abitante,id_quartiere_abitante,0.0,0.0,0.0,False,0.0,0.0,True,traiettoria_on_main_strada));
            new_abitante_to_add.posizione_abitante:= place_abitante;
            new_abitante_to_add.next:= null;
            while list/=null loop
               prec_list:= list;
               list:= list.next;
            end loop;
            if prec_list=null then
               set_traiettorie_ingressi(index,type_traiettoria):= new_abitante_to_add;
            else
               prec_list.next:= new_abitante_to_add;
            end if;
         end if;
      end aggiungi_entità_from_ingresso;

      procedure set_move_parameters_entity_on_traiettoria_ingresso(index_ingresso: Positive; traiettoria: traiettoria_ingressi_type; speed: Float; step: Float) is
         key: Natural:= get_key_ingresso(index_ingresso,not_ordered);
         list: ptr_list_posizione_abitanti_on_road;
      begin
         list:= set_traiettorie_ingressi(key,traiettoria);
         list.posizione_abitante.set_current_speed_abitante(speed);
         if step>0.0 then
            if list.posizione_abitante.get_where_now_posizione_abitanti+step>risorsa_features.get_lunghezza_road then
               list.posizione_abitante.set_where_next_abitante(risorsa_features.get_lunghezza_road);
            else
               list.posizione_abitante.set_where_next_abitante(list.posizione_abitante.get_where_now_posizione_abitanti+step);
            end if;
         end if;
      end set_move_parameters_entity_on_traiettoria_ingresso;

      procedure set_move_parameters_entity_on_main_road(current_car_in_corsia: in out ptr_list_posizione_abitanti_on_road; polo: Boolean; num_corsia: id_corsie; speed: Float; step: Float) is
         new_step: Float;
      begin
         if speed>0.0 then
            current_car_in_corsia.posizione_abitante.set_current_speed_abitante(speed);
         end if;

         if step>0.0 then
            if current_car_in_corsia.posizione_abitante.get_in_overtaken then
               current_car_in_corsia.posizione_abitante.set_distance_on_overtaking_trajectory(current_car_in_corsia.posizione_abitante.get_distance_on_overtaking_trajectory+step);
               if current_car_in_corsia.posizione_abitante.get_distance_on_overtaking_trajectory>=16.0 then -- 16.0 lunghezza traiettoria
                  new_step:= current_car_in_corsia.posizione_abitante.get_distance_on_overtaking_trajectory-16.0;
                  current_car_in_corsia.posizione_abitante.set_where_next_abitante(current_car_in_corsia.posizione_abitante.get_where_now_posizione_abitanti+16.0+new_step);
               end if;
            else
               if current_car_in_corsia.posizione_abitante.get_where_now_posizione_abitanti+step>risorsa_features.get_lunghezza_road then
                  current_car_in_corsia.posizione_abitante.set_where_next_abitante(risorsa_features.get_lunghezza_road);
               else
                  current_car_in_corsia.posizione_abitante.set_where_next_abitante(current_car_in_corsia.posizione_abitante.get_where_now_posizione_abitanti+step);
               end if;
            end if;
         end if;
      end set_move_parameters_entity_on_main_road;

      procedure set_car_overtaken(value_overtaken: Boolean; car: in out ptr_list_posizione_abitanti_on_road) is
      begin
         car.posizione_abitante.set_in_overtaken(value_overtaken);
      end set_car_overtaken;

      procedure set_flag_car_can_overtake_to_next_corsia(car: in out ptr_list_posizione_abitanti_on_road; flag: Boolean) is
      begin
         car.posizione_abitante.set_flag_overtake_next_corsia(flag);
      end set_flag_car_can_overtake_to_next_corsia;

      procedure update_traiettorie_ingressi is
         list: ptr_list_posizione_abitanti_on_road;
         list_macchine_in_strada: ptr_list_posizione_abitanti_on_road;
         prec_list_macchine_in_strada: ptr_list_posizione_abitanti_on_road;
         new_abitante: ptr_list_posizione_abitanti_on_road;
         abitante: posizione_abitanti_on_road;
         polo: Boolean:= True;
         consider_polo: Boolean;
         in_uscita: Boolean;
         --ingressi_structure_type: ingressi_type;
         key_ingresso: Positive;
         length_traiettoria: Float;
         num_corsia: id_corsie;
      begin
         for i in 1..2 loop
            polo:= not polo;
            for i in ordered_ingressi_polo(polo).all'Range loop
               key_ingresso:= get_key_ingresso(ordered_ingressi_polo(polo)(i),not_ordered);

               for traiettoria in traiettoria_ingressi_type'Range loop
                  if traiettoria/=empty then
                     -- traiettoria uscita_andata
                     list:= set_traiettorie_ingressi(key_ingresso,traiettoria);
                     if traiettoria=uscita_andata then
                        in_uscita:= True;
                        num_corsia:= 1;
                        length_traiettoria:= 5.0;
                        consider_polo:= polo;
                     elsif traiettoria=uscita_ritorno then
                        in_uscita:= True;
                        num_corsia:= 2;
                        consider_polo:= not polo;
                        length_traiettoria:= 18.0;
                     elsif traiettoria=entrata_andata then
                        in_uscita:= False;
                        length_traiettoria:= 5.0;
                     else -- entrata_ritorno
                        in_uscita:= False;
                        length_traiettoria:= 20.0;
                     end if;
                     if in_uscita and list/=null then
                        list.posizione_abitante.set_where_now_abitante(list.posizione_abitante.get_where_next_posizione_abitanti);
                        if list.posizione_abitante.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(list.posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                                                                                                   list.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva<=0.0 then
                           get_ingressi_segmento_resources(ordered_ingressi_polo(polo)(i)).update_avanzamento_car_in_urbana(list.posizione_abitante.get_where_now_posizione_abitanti);
                        end if;
                        if list.posizione_abitante.get_where_now_posizione_abitanti>=length_traiettoria then
                           list_macchine_in_strada:= main_strada(consider_polo,num_corsia);
                           prec_list_macchine_in_strada:= null;
                           while list_macchine_in_strada/=null and then list_macchine_in_strada.posizione_abitante.get_where_now_posizione_abitanti<list.posizione_abitante.get_where_now_posizione_abitanti loop
                              prec_list_macchine_in_strada:= list_macchine_in_strada;
                              list_macchine_in_strada:= list_macchine_in_strada.next;
                           end loop;
                           abitante:= create_new_posizione_abitante_from_copy(list.posizione_abitante);
                           abitante.set_where_next_abitante(list.posizione_abitante.get_where_now_posizione_abitanti-length_traiettoria+get_distance_from_polo_percorrenza(get_ingresso_from_id(ordered_ingressi_polo(polo)(i)))+10.0);  -- 5.0 lunghezza traiettoria
                           abitante.set_where_now_abitante(abitante.get_where_next_posizione_abitanti);
                           abitante.set_came_from_ingresso(True);  --  set flag to True
                           new_abitante:= create_new_list_posizione_abitante(abitante,list_macchine_in_strada);
                           if prec_list_macchine_in_strada=null then
                              main_strada(consider_polo,1):= new_abitante;
                           else
                              prec_list_macchine_in_strada.next:= new_abitante;
                           end if;
                           main_strada_number_entity(consider_polo,1):= main_strada_number_entity(consider_polo,1)+1;
                           list.posizione_abitante.set_where_now_abitante(Float'Last);
                        end if;
                     elsif in_uscita=False and list/=null then
                        list.posizione_abitante.set_where_now_abitante(list.posizione_abitante.get_where_next_posizione_abitanti);
                        if list.posizione_abitante.get_where_now_posizione_abitanti>=length_traiettoria then
                           get_ingressi_segmento_resources(ordered_ingressi_polo(polo)(i)).new_abitante_finish_route(list.posizione_abitante,car);
                           list.posizione_abitante.set_where_now_abitante(Float'Last);
                        end if;
                     end if;
                  end if;
               end loop;
            end loop;
         end loop;
      end update_traiettorie_ingressi;

      procedure update_car_on_road is
         main_list: ptr_list_posizione_abitanti_on_road;
         prec_main_list: ptr_list_posizione_abitanti_on_road;
         other_list: ptr_list_posizione_abitanti_on_road;
         prec_other_list: ptr_list_posizione_abitanti_on_road;
         next_element_list: ptr_list_posizione_abitanti_on_road;
         other_corsia: id_corsie;
         traiettoria: traiettoria_ingressi_type;
         list_abitanti_traiettoria: ptr_list_posizione_abitanti_on_road;
         prec_list_abitanti_traiettoria: ptr_list_posizione_abitanti_on_road;
      begin
         for i in main_strada'Range(1) loop
            for j in main_strada'Range(2) loop
               main_list:= main_strada(i,j);
               prec_main_list:= null;
               next_element_list:= null;
               while main_list/=null loop
                  if main_list.posizione_abitante.get_came_from_ingresso then
                     if main_list.posizione_abitante.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(main_list.posizione_abitante.get_id_quartiere_posizione_abitanti,main_list.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva>=
                       get_distance_from_polo_percorrenza(get_ingresso_from_id(main_list.posizione_abitante.get_destination.get_from_ingresso))+10.0 then
                        main_list.posizione_abitante.set_came_from_ingresso(False);
                       if main_list.posizione_abitante.get_destination.get_departure_corsia=1 then
                           set_traiettorie_ingressi(main_list.posizione_abitante.get_destination.get_from_ingresso,uscita_andata):=set_traiettorie_ingressi(main_list.posizione_abitante.get_destination.get_from_ingresso,uscita_andata).next;
                        else
                           set_traiettorie_ingressi(main_list.posizione_abitante.get_destination.get_from_ingresso,uscita_ritorno):=set_traiettorie_ingressi(main_list.posizione_abitante.get_destination.get_from_ingresso,uscita_ritorno).next;
                        end if;
                     end if;
                  end if;
                  if main_list.posizione_abitante.get_in_overtaken and main_list.posizione_abitante.get_flag_overtake_next_corsia then
                     -- begin togli elemento dalla lista
                     main_list.posizione_abitante.set_flag_overtake_next_corsia(False);  -- reset del cambio corsia
                     if prec_main_list=null then
                        main_strada(i,j):= main_strada(i,j).next;
                        next_element_list:= main_strada(i,j);
                     else
                        prec_main_list.next:= main_list.next;
                        next_element_list:= main_list.next;
                     end if;
                     main_strada_number_entity(i,j):= main_strada_number_entity(i,j)-1;
                     -- end togli elemento dalla lista
                     if j=1 then
                        other_corsia:= 2;
                     else
                        other_corsia:= 1;
                     end if;
                     other_list:= main_strada(i,other_corsia);
                     prec_other_list:= null;
                     while other_list/=null and then other_list.posizione_abitante.get_where_now_posizione_abitanti<=main_list.posizione_abitante.get_where_now_posizione_abitanti loop
                        prec_other_list:= other_list;
                        other_list:= other_list.next;
                     end loop;
                     main_list.next:= other_list;
                     if prec_other_list=null then
                        main_strada(i,other_corsia):= main_list;
                     else
                        prec_other_list.next:= main_list;
                     end if;
                     main_strada_number_entity(i,other_corsia):= main_strada_number_entity(i,other_corsia)+1;
                     -- prec_main_list resta invariato
                     main_list:= next_element_list;
                  elsif main_list.posizione_abitante.get_in_overtaken then
                     if main_list.posizione_abitante.get_distance_on_overtaking_trajectory>=8.0 then -- lunghezza traiettoria sorpasso
                        main_list.posizione_abitante.set_in_overtaken(False);
                        main_list.posizione_abitante.set_where_next_abitante(main_list.posizione_abitante.get_where_now_posizione_abitanti+7.0+main_list.posizione_abitante.get_distance_on_overtaking_trajectory-8.0);  -- 7.0 lunghezza lineare traiettoria; 8.0 lunghezza traiettoria
                        main_list.posizione_abitante.set_where_now_abitante(main_list.posizione_abitante.get_where_next_posizione_abitanti);
                     end if;
                     prec_main_list:= main_list;
                     main_list:= main_list.next;
                  else
                     main_list.posizione_abitante.set_where_now_abitante(main_list.posizione_abitante.get_where_next_posizione_abitanti);
                     prec_main_list:= main_list;
                     next_element_list:= main_list.next;
                     if main_list.posizione_abitante.get_destination.get_traiettoria_incrocio_to_follow=empty then
                        if get_distance_from_polo_percorrenza(get_ingresso_from_id(main_list.posizione_abitante.get_destination.get_ingresso_to_go_trajectory))=main_list.posizione_abitante.get_where_now_posizione_abitanti then
                           main_list.posizione_abitante.set_where_next_abitante(0.0);
                           main_list.posizione_abitante.set_where_now_abitante(0.0);
                           main_list.next:= null;
                           if main_list.posizione_abitante.get_destination.get_corsia_to_go_trajectory=1 then
                              traiettoria:= entrata_andata;
                           else
                              traiettoria:= entrata_ritorno;
                           end if;
                           list_abitanti_traiettoria:= set_traiettorie_ingressi(main_list.posizione_abitante.get_destination.get_ingresso_to_go_trajectory,traiettoria);
                           prec_list_abitanti_traiettoria:= null;
                           while list_abitanti_traiettoria/=null loop
                              prec_list_abitanti_traiettoria:= list_abitanti_traiettoria;
                              list_abitanti_traiettoria:= list_abitanti_traiettoria.next;
                           end loop;
                           if prec_list_abitanti_traiettoria=null then
                              set_traiettorie_ingressi(main_list.posizione_abitante.get_destination.get_ingresso_to_go_trajectory,traiettoria):= main_list;
                           else
                              prec_list_abitanti_traiettoria.next:= main_list;
                           end if;
                        end if;
                     else  -- occorre percorrere tutta la strada
                        null;
                     end if;
                     main_list:= next_element_list;
                  end if;
               end loop;
            end loop;
         end loop;
      end update_car_on_road;

      procedure remove_first_element_traiettoria(index_ingresso: Positive; traiettoria: traiettoria_ingressi_type) is
         key_ingresso: Positive:= get_key_ingresso(index_ingresso,not_ordered);
      begin
         set_traiettorie_ingressi(key_ingresso,traiettoria):= set_traiettorie_ingressi(index_ingresso,traiettoria).next;
      end remove_first_element_traiettoria;

      procedure insert_abitante_from_incrocio(abitante: posizione_abitanti_on_road; polo: Boolean; num_corsia: id_corsie) is
      begin
         temp_abitanti_in_transizione(polo,num_corsia):= abitante;
      end insert_abitante_from_incrocio;

      procedure sposta_abitanti_in_transizione_da_incroci is
         list: ptr_list_posizione_abitanti_on_road;
         new_abitante: ptr_list_posizione_abitanti_on_road:= new list_posizione_abitanti_on_road;
      begin
         -- per capire se effettivamente è stato spostato qualche abitante dall'incrocio
         -- si guarda se departure corsia /=0
         for polo in Boolean'Range loop
            for num_corsia in id_corsie'Range loop
               if temp_abitanti_in_transizione(polo,num_corsia).get_destination.get_departure_corsia/=0 then
                  list:= main_strada(polo,num_corsia);
                  new_abitante.posizione_abitante:= temp_abitanti_in_transizione(polo,num_corsia);
                  new_abitante.next:= list;
                  main_strada_number_entity(polo,num_corsia):= main_strada_number_entity(polo,num_corsia)+1;
                  temp_abitanti_in_transizione(polo,num_corsia).set_destination(create_trajectory_to_follow(0,0,0,0,empty));
               end if;
            end loop;
         end loop;
      end sposta_abitanti_in_transizione_da_incroci;

      procedure remove_abitante_in_incrocio(polo: Boolean; num_corsia: id_corsie) is
         list: ptr_list_posizione_abitanti_on_road:= main_strada(polo,num_corsia);
         prec_list: ptr_list_posizione_abitanti_on_road:= null;
      begin
         while list/=null loop
            prec_list:= list;
            list:= list.next;
         end loop;
         if prec_list/=null then
            prec_list.next:= null;
         end if;
         main_strada_number_entity(polo,num_corsia):= main_strada_number_entity(polo,num_corsia)-1;
      end remove_abitante_in_incrocio;

      function get_key_ingresso(ingresso: Positive; ingressi_structure_type: ingressi_type) return Natural is
      begin
         for i in 1..num_ingressi loop
            if index_ingressi(i)=ingresso then
               return i;
            end if;
         end loop;
         return 0;
      end get_key_ingresso;

      function get_abitante_from_ingresso(ingresso_key: Positive; traiettoria: traiettoria_ingressi_type) return ptr_list_posizione_abitanti_on_road is
      begin
         return set_traiettorie_ingressi(ingresso_key,traiettoria);
      end get_abitante_from_ingresso;

      function get_ordered_ingressi_from_polo(polo: Boolean) return ptr_indici_ingressi is
      begin
         return ordered_ingressi_polo(polo);
      end get_ordered_ingressi_from_polo;

      -- METODO USATO PER CAPIRE SE PER MACCHINE CHE SONO IN DIREZIONE uscita_ritorno
      -- HANNO INGRESSI CON MACCHINE IN SVOLTA CHE INTERSECANO CON LA TRAIETTORIA uscita_ritorno
      function is_index_ingresso_in_svolta(ingresso: Positive; traiettoria: traiettoria_ingressi_type) return Boolean is
         abitante: ptr_list_posizione_abitanti_on_road;
      begin
         -- cambia da traiettoria a traiettoria
         abitante:= get_abitante_from_ingresso(get_key_ingresso(ingresso,not_ordered),traiettoria);
         case traiettoria is
            when uscita_andata =>
               if abitante.posizione_abitante.get_where_now_posizione_abitanti/=0.0 or abitante.posizione_abitante.get_where_next_posizione_abitanti/=0.0 then
                  return True;
               else
                  return False;
               end if;
            when uscita_ritorno =>
               if abitante.posizione_abitante.get_where_now_posizione_abitanti<=15.0 then --15.0 pt intersezione linea di mezzo
                  return True;
               elsif abitante.posizione_abitante.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(abitante.posizione_abitante.get_id_quartiere_posizione_abitanti,abitante.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva<15.0 then
                  return True;
               else
                  return False;
               end if;
            when entrata_andata =>
               if abitante.posizione_abitante.get_where_now_posizione_abitanti>=0.0 then
                  return True;
               else
                  return False;
               end if;
            when entrata_ritorno =>
               if abitante.posizione_abitante.get_where_now_posizione_abitanti>=15.0 then --15.0 pt intersezione linea di mezzo
                  return True;
               else
                  return False;
               end if;
            when empty =>
               return False;
         end case;
      end is_index_ingresso_in_svolta;

      function get_index_ingresso_from_key(key: Positive; ingressi_structure_type: ingressi_type) return Natural is
         index: Natural:= 0;
      begin
         case ingressi_structure_type is
            when not_ordered =>
               if key>index_ingressi'First and key<index_ingressi'Last then
                  return index_ingressi(key);
               end if;
            when ordered_polo_true =>
               if key>ordered_ingressi_polo(True).all'First and key<ordered_ingressi_polo(True).all'Last then
                  return ordered_ingressi_polo(True)(key);
               end if;
            when ordered_polo_false =>
               if key>ordered_ingressi_polo(False).all'First and key<ordered_ingressi_polo(False).all'Last then
                  return ordered_ingressi_polo(False)(key);
               end if;
         end case;
         return index;
      end get_index_ingresso_from_key;

      function get_ingressi_ordered_by_distance return indici_ingressi is
      begin
         return index_ingressi;
      end get_ingressi_ordered_by_distance;

      function get_next_abitante_on_road(from_distance: Float; range_1: Boolean; range_2: id_corsie) return ptr_list_posizione_abitanti_on_road is
         current_list: ptr_list_posizione_abitanti_on_road:= main_strada(range_1,range_2);
         opposite_list: ptr_list_posizione_abitanti_on_road;
         list: ptr_list_posizione_abitanti_on_road;
         switch: Boolean;
      begin
         if range_2=1 then
            opposite_list:= main_strada(range_1,2);
         else
            opposite_list:= main_strada(range_1,1);
         end if;

         switch:= True;
         list:= current_list;
         while switch and list/=null loop
            if list.posizione_abitante.get_where_now_posizione_abitanti>=from_distance then
               switch:= False;
               current_list:= list;
            end if;
            list:= list.next;
         end loop;

         switch:= True;
         list:= opposite_list;
         while switch and list/=null loop
            if list.posizione_abitante.get_where_now_posizione_abitanti>=from_distance then
               switch:= False;
               opposite_list:= list;
            end if;
            list:= list.next;
         end loop;

         if opposite_list/=null and then opposite_list.posizione_abitante.get_in_overtaken then
            if opposite_list.posizione_abitante.get_distance_on_overtaking_trajectory=4.0 then -- 4.0 è la distanza alla quale si ha intersezione
               if opposite_list.posizione_abitante.get_where_now_posizione_abitanti+3.5<current_list.posizione_abitante.get_where_now_posizione_abitanti then  -- 3.5 è la distanza lineare con pt intersezione
                  return opposite_list;
               else
                  return current_list;
               end if;
            end if;
         end if;
         return current_list;
      end get_next_abitante_on_road;

      -- num_corsia_to_check must be 1 or 2
      function can_abitante_continue_move(distance: Float; num_corsia_to_check: Positive; traiettoria: traiettoria_ingressi_type; polo_ingresso: Boolean) return Boolean is
         list: ptr_list_posizione_abitanti_on_road;
         prec_list: ptr_list_posizione_abitanti_on_road;
         move_entity: move_parameters;
         value: Float;
      begin
         if traiettoria=entrata_ritorno then
            list:= main_strada(not polo_ingresso,num_corsia_to_check);
            while list/=null and then list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=distance loop
               prec_list:= list;
               list:= list.next;
            end loop;
            if list/=null then
               move_entity:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
               if list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-move_entity.get_length_entità_passiva<distance then
                  return False;
               end if;
            end if;
            if prec_list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distance-20.0 then
               return True;
            else
               return False;
            end if;
         end if;
         if traiettoria=uscita_ritorno then
            if num_corsia_to_check=1 then
               list:= main_strada(polo_ingresso,2);
               value:= distance;
            else
               list:= main_strada(not polo_ingresso,2);
               value:= risorsa_features.get_lunghezza_road-distance;
            end if;
            if num_corsia_to_check=1 then
               list:= main_strada(polo_ingresso,2);
               value:= distance;
            else
               list:= main_strada(not polo_ingresso,2);
               value:= risorsa_features.get_lunghezza_road-distance;
            end if;
            while list/=null and then list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=value+10.0 loop
               prec_list:= list;
               list:= list.next;
            end loop;
            if list/=null then
               move_entity:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
               if list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-move_entity.get_length_entità_passiva<value+10.0 then
                  return False;
               end if;
            end if;
            if prec_list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>value-20.0 then  -- 20.0 sarebbe la distanza sicura
               return True;
            else
               return False;
            end if;
         end if;
         return False;
      end can_abitante_continue_move;

      function get_abitanti_on_road(range_1: Boolean; range_2: id_corsie) return ptr_list_posizione_abitanti_on_road is
      begin
         return main_strada(range_1,range_2);
      end get_abitanti_on_road;

      function get_number_entity(structure: data_structures_types; polo: Boolean; num_corsia: id_corsie) return Natural is
      begin
         case structure is
            when road =>
               return main_strada_number_entity(polo,num_corsia);
            when sidewalk =>
               return marciapiedi_num_pedoni_bici(polo,num_corsia);
         end case;
      end get_number_entity;

      function can_car_overtake(car: ptr_list_posizione_abitanti_on_road; polo: Boolean; to_corsia: id_corsie) return Boolean is
         list: ptr_list_posizione_abitanti_on_road:= main_strada(polo,to_corsia);
         prec_list: ptr_list_posizione_abitanti_on_road:= null;
      begin
         while list/=null and then list.posizione_abitante.get_where_now_posizione_abitanti<car.posizione_abitante.get_where_now_posizione_abitanti+5.0 loop -- 5.0 distanza lineare con intersezione corsia di mezzo
            prec_list:= list;
            list:= list.next;
         end loop;
         if list/=null then
            if list.posizione_abitante.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(list.posizione_abitante.get_id_quartiere_posizione_abitanti,list.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva<car.posizione_abitante.get_where_now_posizione_abitanti+12.0 then -- 12.0 è la lunghezza lineare della traiettoria
               return False;
            end if;
         end if;
         if prec_list/=null then
            if prec_list.posizione_abitante.get_where_now_posizione_abitanti<=car.posizione_abitante.get_where_now_posizione_abitanti+5.0-20.0 then  --5.0 dist lineare traiettoria -20.0 distanza sicurezza
               return True;
            else
               return False;
            end if;
         else
            return True;
         end if;
      end can_car_overtake;

      function car_can_initiate_overtaken_on_road(car: ptr_list_posizione_abitanti_on_road; polo: Boolean; num_corsia: id_corsie) return Boolean is
         other_corsia: id_corsie;
         list_current_corsia: ptr_list_posizione_abitanti_on_road;
         list_other_corsia: ptr_list_posizione_abitanti_on_road;
         next_car_length: Float;
         switch: Boolean;
      begin
         if num_corsia=1 then
            other_corsia:= 2;
         else
            other_corsia:= 1;
         end if;

         list_current_corsia:= car.next;
         list_other_corsia:= main_strada(polo,other_corsia);

         -- prima zona sorpasso = zona da where_now a intersezione con linea di mezzo
         -- seconda zona = zona da intersezione linea di mezzo a fine traiettoria

         --while list_current_corsia/=null loop
         --   next_car_length:= get_quartiere_utilities_obj.get_auto_quartiere(list_current_corsia.posizione_abitante.id_quartiere,list_current_corsia.posizione_abitante.id_abitante).get_length_entità_passiva;
         --   if (list_current_corsia.posizione_abitante.where_now<=car.posizione_abitante.where_now+16.0 and list_current_corsia.posizione_abitante.where_now>=car.posizione_abitante.where_now) or--16.0 lunghezza lineare traiettoria
         --     (list_current_corsia.posizione_abitante.where_now-next_car_length<car.posizione_abitante.where_now+16.0) then
         --      if list_current_corsia.posizione_abitante.where_now-next_car_length<car.posizione_abitante.where_now+8.0 then
         --         return False;  -- ho una macchina nella prima zona
         --      end if;
         --      if list_current_corsia.posizione_abitante.in_overtaken then
         --         return False;  -- si ha una macchina dopo la prima zona che vuole sorpassare
         --      end if;
         --   elsif list_current_corsia.posizione_abitante.in_overtaken and list_current_corsia.posizione_abitante.destination.departure_corsia/=num_corsia then
         --      if list_current_corsia.posizione_abitante.where_now+8.0>=car.posizione_abitante.where_now and
         --        list_current_corsia.posizione_abitante.where_now+8.0<=car.posizione_abitante.where_now+8.0 then --  8.0 intersezione a metà corsia lineare
         --         return False; -- ho una macchina che sta attraversando nella prima zona di sorpasso di current car
         --      elsif list_current_corsia.posizione_abitante.distance_on_overtaking_trajectory-next_car_length<6.0 then -- 6.0 distanza intersezione linea di mezzo
         --         return False;  -- la macchina non ha ancora attraversato completamente
         --      end if;
         --   end if;
         --   list_current_corsia:= list_current_corsia.next;
         --end loop;

         for i in 1..main_strada_number_entity(polo,other_corsia) loop
            switch:= False;
            next_car_length:= get_quartiere_utilities_obj.get_auto_quartiere(list_other_corsia.posizione_abitante.get_id_quartiere_posizione_abitanti,list_other_corsia.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
            if (list_other_corsia.posizione_abitante.get_where_now_posizione_abitanti<=car.posizione_abitante.get_where_now_posizione_abitanti+16.0 and list_other_corsia.posizione_abitante.get_where_now_posizione_abitanti>=car.posizione_abitante.get_where_now_posizione_abitanti) or--16.0 lunghezza lineare traiettoria
              (list_other_corsia.posizione_abitante.get_where_now_posizione_abitanti-next_car_length<car.posizione_abitante.get_where_now_posizione_abitanti+16.0) then
               if list_other_corsia.posizione_abitante.get_in_overtaken then
                  if list_other_corsia.posizione_abitante.get_destination.get_corsia_to_go_trajectory=num_corsia then
                     switch:= True;
                  else
                     return False;
                  end if;
               elsif calculate_bound_to_overtake(list_other_corsia)=0.0 then
                  return False;
               end if;
            elsif list_other_corsia.posizione_abitante.get_in_overtaken and list_other_corsia.posizione_abitante.get_destination.get_corsia_to_go_trajectory=num_corsia then
               -- controllare se la macchina nella corsia opposta ha la seconda zona che interseca la prima zona della macchina che vuole sorpassare
               if list_other_corsia.posizione_abitante.get_where_now_posizione_abitanti+6.0>=car.posizione_abitante.get_where_now_posizione_abitanti and
                 list_other_corsia.posizione_abitante.get_where_now_posizione_abitanti+6.0<=car.posizione_abitante.get_where_now_posizione_abitanti+16.0 then
                  switch:= True;
               end if;
            end if;
            if switch then
               -- la macchina è in sorpasso ma non ha ancora attraversato la corsia
               if calculate_bound_to_overtake(car)=0.0 then  -- allora la  macchina in list_current_corsia non è in bound to overtake
                                                             -- annullamento del sorpasso della macchina opposta
                  if list_other_corsia.posizione_abitante.get_where_now_posizione_abitanti+3.5>=car.posizione_abitante.get_where_now_posizione_abitanti and
                    list_other_corsia.posizione_abitante.get_where_now_posizione_abitanti+3.5<=car.posizione_abitante.get_where_now_posizione_abitanti+3.5 then
                     if list_other_corsia.posizione_abitante.get_distance_on_overtaking_trajectory<4.0 then -- 4.0 distanza alla quale si ha l'intersezione
                                                                                                        -- annulla sorpasso
                        list_other_corsia.posizione_abitante.set_in_overtaken(False);
                        if list_other_corsia.posizione_abitante.get_where_now_posizione_abitanti>list_other_corsia.posizione_abitante.get_where_now_posizione_abitanti then
                           list_other_corsia.posizione_abitante.set_where_next_abitante(2.0);  -- TO DO CALCOLARE PITAGORA PER AGGIORNARE where_next
                        else
                           list_other_corsia.posizione_abitante.set_where_now_abitante(2.0);   -- TO DO CALCOLARE PITAGORA PER AGGIORNARE where_now
                        end if;
                     else
                        return False;
                     end if;
                  else
                     return False;
                  end if;
               else  -- l'altra macchina può o non essere in bound overtake ma siccome ha già iniziato il sorpasso glielo si fa finire
                  return False;
               end if;
            end if;
            list_other_corsia:= list_other_corsia.next;
         end loop;

         return True;
      end car_can_initiate_overtaken_on_road;

      function there_are_overtaken_on_ingresso(ingresso: strada_ingresso_features; polo: Boolean) return Boolean is
         list: ptr_list_posizione_abitanti_on_road;
         length_urbana: Float:= get_urbana_from_id(ingresso.get_id_main_strada_ingresso).get_lunghezza_road;
      begin
         if ingresso.get_polo_ingresso=polo then
            for j in 1..2 loop
               list:= main_strada(polo,j);
               for i in 1..main_strada_number_entity(polo,j) loop
                  if list.posizione_abitante.get_in_overtaken and list.posizione_abitante.get_where_now_posizione_abitanti>get_distance_from_polo_percorrenza(ingresso)-10.0-12.0 and
                    list.posizione_abitante.get_where_now_posizione_abitanti<get_distance_from_polo_percorrenza(ingresso)+10.0 then
                     return True;
                  end if;
                  list:= list.next;
               end loop;
            end loop;
         else
            for j in 1..2 loop
               list:= main_strada(polo,j);
               for i in 1..main_strada_number_entity(polo,j) loop
                  if list.posizione_abitante.get_in_overtaken and list.posizione_abitante.get_where_now_posizione_abitanti>length_urbana-get_distance_from_polo_percorrenza(ingresso)-10.0-12.0 and
                    list.posizione_abitante.get_where_now_posizione_abitanti<length_urbana-get_distance_from_polo_percorrenza(ingresso)+10.0 then
                     return True;
                  end if;
                  list:= list.next;
               end loop;
            end loop;
         end if;
         return False;
      end there_are_overtaken_on_ingresso;

      function car_on_same_corsia_have_overtaked(car: ptr_list_posizione_abitanti_on_road; polo: Boolean; num_corsia: id_corsie) return Boolean is
         next_cars: ptr_list_posizione_abitanti_on_road:= car.next;
         next_car_length: Float;
      begin
         if next_cars/=null then
            next_car_length:= get_quartiere_utilities_obj.get_auto_quartiere(next_cars.posizione_abitante.get_id_quartiere_posizione_abitanti,next_cars.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
            if (next_cars.posizione_abitante.get_where_now_posizione_abitanti>=car.posizione_abitante.get_where_now_posizione_abitanti
                and next_cars.posizione_abitante.get_where_now_posizione_abitanti<=car.posizione_abitante.get_where_now_posizione_abitanti+8.0) or
              (next_cars.posizione_abitante.get_where_now_posizione_abitanti-next_car_length<car.posizione_abitante.get_where_now_posizione_abitanti+8.0 and
                 next_cars.posizione_abitante.get_where_now_posizione_abitanti-next_car_length>car.posizione_abitante.get_where_now_posizione_abitanti) then
               return False;
            else
               return True;
            end if;
         end if;
         return True;
      end car_on_same_corsia_have_overtaked;

      function there_are_cars_moving_across_next_ingressi(car: ptr_list_posizione_abitanti_on_road; polo: Boolean) return Boolean is
         list_uscita_ritorno: ptr_list_posizione_abitanti_on_road;
         list_entrata_ritorno: ptr_list_posizione_abitanti_on_road;
         type_ingresso: ingressi_type;
      begin
         for i in ordered_ingressi_polo(polo).all'Range loop
            if is_index_ingresso_in_svolta(ordered_ingressi_polo(polo)(i),uscita_andata) or else
              is_index_ingresso_in_svolta(ordered_ingressi_polo(polo)(i),uscita_ritorno) or else
              is_index_ingresso_in_svolta(ordered_ingressi_polo(polo)(i),entrata_andata) or else
              is_index_ingresso_in_svolta(ordered_ingressi_polo(polo)(i),entrata_ritorno) then
               if car.posizione_abitante.get_where_now_posizione_abitanti>=get_distance_from_polo_percorrenza(get_ingresso_from_id(ordered_ingressi_polo(polo)(i)))-10.0 and
                 car.posizione_abitante.get_where_now_posizione_abitanti<=get_distance_from_polo_percorrenza(get_ingresso_from_id(ordered_ingressi_polo(polo)(i)))+10.0 then
                  return True;
               elsif car.posizione_abitante.get_where_now_posizione_abitanti>get_distance_from_polo_percorrenza(get_ingresso_from_id(ordered_ingressi_polo(polo)(i)))-10.0-12.0
                 and car.posizione_abitante.get_where_now_posizione_abitanti<=get_distance_from_polo_percorrenza(get_ingresso_from_id(ordered_ingressi_polo(polo)(i)))+10.0 then -- 12.0 lunghezza traiettoria sorpasso lineare
                  return True;
               else
                  return False;
               end if;
            end if;
         end loop;

         if polo then
            type_ingresso:= ordered_polo_false;
         else
            type_ingresso:= ordered_polo_true;
         end if;

         for i in ordered_ingressi_polo(not polo).all'Range loop
            list_uscita_ritorno:= set_traiettorie_ingressi(get_key_ingresso(ordered_ingressi_polo(not polo)(i),type_ingresso),uscita_ritorno);
            list_entrata_ritorno:= set_traiettorie_ingressi(get_key_ingresso(ordered_ingressi_polo(not polo)(i),type_ingresso),entrata_ritorno);
            if list_uscita_ritorno/=null and then (list_uscita_ritorno.posizione_abitante.get_where_next_posizione_abitanti>15.0 or else
              (list_entrata_ritorno/=null and then list_entrata_ritorno.posizione_abitante.get_where_now_posizione_abitanti-
                 get_quartiere_utilities_obj.get_auto_quartiere(list_entrata_ritorno.posizione_abitante.get_id_quartiere_posizione_abitanti,list_entrata_ritorno.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva<7.0)) then
               if car.posizione_abitante.get_where_now_posizione_abitanti>=get_urbana_from_id(get_ingresso_from_id(ordered_ingressi_polo(not polo)(i)).get_id_main_strada_ingresso).get_lunghezza_road-get_distance_from_polo_percorrenza(get_ingresso_from_id(ordered_ingressi_polo(not polo)(i)))-10.0 and  -- 12.0 lunghezza traiettoria sorpasso lineare
                 car.posizione_abitante.get_where_now_posizione_abitanti<=get_urbana_from_id(get_ingresso_from_id(ordered_ingressi_polo(not polo)(i)).get_id_main_strada_ingresso).get_lunghezza_road-get_distance_from_polo_percorrenza(get_ingresso_from_id(ordered_ingressi_polo(not polo)(i)))+10.0 then
                  return True;
               elsif car.posizione_abitante.get_where_now_posizione_abitanti>get_distance_from_polo_percorrenza(get_ingresso_from_id(ordered_ingressi_polo(not polo)(i)))-10.0-12.0
                 and car.posizione_abitante.get_where_now_posizione_abitanti<=get_urbana_from_id(get_ingresso_from_id(ordered_ingressi_polo(not polo)(i)).get_id_main_strada_ingresso).get_lunghezza_road-get_distance_from_polo_percorrenza(get_ingresso_from_id(ordered_ingressi_polo(not polo)(i)))+10.0 then -- 12.0 lunghezza traiettoria sorpasso lineare
                  return True;
               else
                  return False;
               end if;
            end if;
         end loop;

         return False;
      end there_are_cars_moving_across_next_ingressi;

      function calculate_distance_ingressi_from_given_distance(polo_to_consider: Boolean; in_corsia: id_corsie; car_distance: Float) return Float is
         key_ingresso: Positive;
         index_ingresso: Positive;
         distance_ingresso: Float;
         list_traiettorie_uscita_andata: ptr_list_posizione_abitanti_on_road;
         list_traiettorie_uscita_ritorno: ptr_list_posizione_abitanti_on_road;
         list_traiettorie_entrata_andata: ptr_list_posizione_abitanti_on_road;
         list_traiettorie_entrata_ritorno: ptr_list_posizione_abitanti_on_road;
         type_ingressi_structure: ingressi_type;
         distance_one: Float:= -1.0;
         distance_two: Float:= -1.0;
      begin
         if polo_to_consider then
            type_ingressi_structure:= ordered_polo_true;
         else
            type_ingressi_structure:= ordered_polo_false;
         end if;

         for i in reverse 1..ordered_ingressi_polo(polo_to_consider).all'Last loop
            key_ingresso:= get_key_ingresso(get_index_ingresso_from_key(i,type_ingressi_structure),not_ordered);
            index_ingresso:= ordered_ingressi_polo(polo_to_consider)(i);
            distance_ingresso:= get_distance_from_polo_percorrenza(get_ingresso_from_id(index_ingresso));

            list_traiettorie_uscita_andata:= set_traiettorie_ingressi(key_ingresso,uscita_andata);
            list_traiettorie_uscita_ritorno:= set_traiettorie_ingressi(key_ingresso,uscita_ritorno);
            list_traiettorie_entrata_andata:= set_traiettorie_ingressi(key_ingresso,entrata_andata);
            list_traiettorie_entrata_ritorno:= set_traiettorie_ingressi(key_ingresso,entrata_ritorno);

            if distance_ingresso>car_distance then
               if in_corsia=1 then
                  if list_traiettorie_uscita_andata/=null and then list_traiettorie_uscita_andata.posizione_abitante.get_where_next_posizione_abitanti>0.0 then
                     distance_one:= distance_ingresso;
                  elsif list_traiettorie_uscita_ritorno/=null and then (list_traiettorie_uscita_ritorno.posizione_abitante.get_where_next_posizione_abitanti>0.0 and then (list_traiettorie_uscita_ritorno.posizione_abitante.get_where_next_posizione_abitanti-
                    get_quartiere_utilities_obj.get_auto_quartiere(list_traiettorie_uscita_ritorno.posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                                   list_traiettorie_uscita_ritorno.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva<7.0)) then
                     distance_one:= distance_ingresso;
                  elsif list_traiettorie_entrata_ritorno/=null and then (list_traiettorie_entrata_ritorno.posizione_abitante.get_where_next_posizione_abitanti>0.0 and then (list_traiettorie_entrata_ritorno.posizione_abitante.get_where_next_posizione_abitanti-
                    get_quartiere_utilities_obj.get_auto_quartiere(list_traiettorie_entrata_ritorno.posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                                   list_traiettorie_entrata_ritorno.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva>25.0)) then
                     distance_one:= distance_ingresso-10.0;
                  elsif list_traiettorie_entrata_andata/=null and then list_traiettorie_entrata_andata.posizione_abitante.get_where_now_posizione_abitanti>=0.0 then
                     distance_one:= distance_ingresso-13.0; -- -13.0 dato che la lunghezza di una macchina è 3.0
                  end if;
               else
                  if list_traiettorie_uscita_ritorno/=null and then (list_traiettorie_uscita_ritorno.posizione_abitante.get_where_next_posizione_abitanti>7.0 and then (list_traiettorie_uscita_ritorno.posizione_abitante.get_where_now_posizione_abitanti-
                    get_quartiere_utilities_obj.get_auto_quartiere(list_traiettorie_uscita_ritorno.posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                                   list_traiettorie_uscita_ritorno.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva<15.0)) then
                     distance_one:= distance_ingresso;
                  elsif list_traiettorie_entrata_ritorno/=null and then (list_traiettorie_entrata_ritorno.posizione_abitante.get_where_next_posizione_abitanti>15.0 and then (list_traiettorie_entrata_ritorno.posizione_abitante.get_where_now_posizione_abitanti-
                    get_quartiere_utilities_obj.get_auto_quartiere(list_traiettorie_entrata_ritorno.posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                                   list_traiettorie_entrata_ritorno.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva<25.0)) then
                     distance_one:= distance_ingresso;
                  end if;
               end if;
            else
               null;  -- NOOP
            end if;
         end loop;

         if polo_to_consider then
            type_ingressi_structure:= ordered_polo_false;
         else
            type_ingressi_structure:= ordered_polo_true;
         end if;

         for i in reverse 1..ordered_ingressi_polo(not polo_to_consider).all'Last loop
            key_ingresso:= get_key_ingresso(get_index_ingresso_from_key(i,type_ingressi_structure),not_ordered);
            index_ingresso:= ordered_ingressi_polo(not polo_to_consider)(i);
            distance_ingresso:= get_urbana_from_id(get_ingresso_from_id(index_ingresso).get_id_main_strada_ingresso).get_lunghezza_road-get_distance_from_polo_percorrenza(get_ingresso_from_id(index_ingresso));

            list_traiettorie_uscita_ritorno:= set_traiettorie_ingressi(key_ingresso,uscita_ritorno);
            list_traiettorie_entrata_ritorno:= set_traiettorie_ingressi(key_ingresso,entrata_ritorno);

            if car_distance<distance_ingresso then -- se l'ingresso si trova ad una distanza maggiore della macchina
               if in_corsia=1 then
                  if list_traiettorie_uscita_ritorno/=null and then list_traiettorie_uscita_ritorno.posizione_abitante.get_where_next_posizione_abitanti>25.0 then
                     distance_two:= distance_ingresso-10.0;
                  end if;
                  -- davanti si può trovare solo una macchina in traiettoria uscita_ritorno considerando
                  -- distanza di sicurezza nel sorpasso
                  --if list_traiettorie_entrata_ritorno/=null and car_in_corsia.posizione_abitante.in_overtaken and
                  --  car_in_corsia.posizione_abitante.where_now+3.0>distance_ingresso-13.0 then  -- 3.0 distanza lineare con pt intersezione
                  --   distance:= distance_ingresso-13.0;
                  --end if;
               else
                  if list_traiettorie_uscita_ritorno/=null and then list_traiettorie_uscita_ritorno.posizione_abitante.get_where_next_posizione_abitanti>15.0 then
                     distance_two:= distance_ingresso-10.0;
                  end if;
                  if list_traiettorie_entrata_ritorno/=null then  -- 3.0 distanza lineare con pt intersezione
                     distance_two:= distance_ingresso-13.0;
                  end if;
               end if;
            end if;
         end loop;

         if distance_one<=distance_two then
           return distance_one;
         else
            return distance_two;
         end if;
      end calculate_distance_ingressi_from_given_distance;

      function calculate_distance_to_next_ingressi(polo_to_consider: Boolean; in_corsia: id_corsie; car_in_corsia: ptr_list_posizione_abitanti_on_road) return Float is
         car_distance: Float;
      begin
         if car_in_corsia.posizione_abitante.get_in_overtaken then
            car_distance:= car_in_corsia.posizione_abitante.get_where_now_posizione_abitanti+12.0;  --12.0 lunghezza lineare traiettoria
         else
            car_distance:= car_in_corsia.posizione_abitante.get_where_now_posizione_abitanti;
         end if;
         return calculate_distance_ingressi_from_given_distance(polo_to_consider,in_corsia,car_distance);
      end calculate_distance_to_next_ingressi;

      function can_abitante_move(distance: Float; key_ingresso: Positive; traiettoria: traiettoria_ingressi_type; polo_ingresso: Boolean) return Boolean is
         list: ptr_list_posizione_abitanti_on_road;
         prec_list: ptr_list_posizione_abitanti_on_road;
         list_1: ptr_list_posizione_abitanti_on_road;
         list_2: ptr_list_posizione_abitanti_on_road;
         move_entity: move_parameters;
      begin
         --if range_1=1 then
         --   index_ingresso:= ordered_ingressi_polo_true(key_ingresso);
         --elsif range_1=2 then
         --   index_ingresso:= ordered_ingressi_polo_false(key_ingresso);
         --else
         --   return False;
         --end if;
         if traiettoria=uscita_andata then
            list:= main_strada(polo_ingresso,1);
            while list/=null and then list.posizione_abitante.get_where_now_posizione_abitanti>=distance+10.0 loop
               prec_list:= list;
               list:= list.next;
            end loop;
            if list/=null then
               move_entity:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
               if list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-move_entity.get_length_entità_passiva<distance+10.0 then
                  return False;
               end if;
            end if;
            if prec_list.posizione_abitante.get_where_now_posizione_abitanti<distance-40.0 then  -- la precedente ha distanza sufficiente per permettere l'attraversamento
               return True;
            else
               return False;
            end if;
         elsif traiettoria=uscita_ritorno then
            list:= main_strada(polo_ingresso,1);
            while list/=null and then list.posizione_abitante.get_where_now_posizione_abitanti>=distance+10.0 loop
               prec_list:= list;
               list:= list.next;
            end loop;
            if list/=null then
               move_entity:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
               if list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-move_entity.get_length_entità_passiva<distance+10.0 then
                  return False;
               end if;
            end if;
            if prec_list.posizione_abitante.get_where_now_posizione_abitanti<distance-40.0 then  -- la precedente ha distanza sufficiente per permettere l'attraversamento
               list:= main_strada(polo_ingresso,1);
               while list/=null and then list.posizione_abitante.get_where_now_posizione_abitanti>=distance+10.0 loop
                  prec_list:= list;
                  list:= list.next;
               end loop;
               if prec_list.posizione_abitante.get_where_now_posizione_abitanti<distance-40.0 then  -- la precedente ha distanza sufficiente per permettere l'attraversamento
                  list:= main_strada(not polo_ingresso,1);
                  while list/=null and then list.posizione_abitante.get_where_now_posizione_abitanti>=risorsa_features.get_lunghezza_road-distance+10.0 loop
                     prec_list:= list;
                     list:= list.next;
                  end loop;
                  if prec_list.posizione_abitante.get_where_now_posizione_abitanti<distance-40.0 then  -- la precedente ha distanza sufficiente per permettere l'attraversamento
                     list:= main_strada(not polo_ingresso,1);
                     while list/=null and then list.posizione_abitante.get_where_now_posizione_abitanti>=distance+10.0 loop
                        prec_list:= list;
                        list:= list.next;
                     end loop;
                     if prec_list.posizione_abitante.get_where_now_posizione_abitanti<distance-40.0 then  -- la precedente ha distanza sufficiente per permettere l'attraversamento
                        return True;
                     else
                        return False;
                     end if;
                  else
                     return False;
                  end if;
               else
                  return False;
               end if;
            else
               return False;
            end if;
         elsif traiettoria=entrata_ritorno then
            list_1:= main_strada(polo_ingresso,1);
            list_2:= main_strada(polo_ingresso,2);
            while list_1/=null and then list_1.posizione_abitante.get_where_now_posizione_abitanti>distance loop
               prec_list:= list_1;
               list_1:= list_1.next;
            end loop;
            if list_1/=null then
               move_entity:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list_1.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_1.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
               if list_1.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-move_entity.get_length_entità_passiva<distance then
                  return False;
               end if;
            end if;
            if prec_list.posizione_abitante.get_where_now_posizione_abitanti<distance-40.0 then  -- la precedente ha distanza sufficiente per permettere l'attraversamento
               while list_2/=null and then list_2.posizione_abitante.get_where_now_posizione_abitanti>distance loop
                  prec_list:= list_2;
                  list_2:= list_2.next;
               end loop;
               if list_2/=null then
                  move_entity:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list_2.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_2.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                  if list_2.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-move_entity.get_length_entità_passiva<distance then
                     return False;
                  end if;
               end if;
               if prec_list.posizione_abitante.get_where_now_posizione_abitanti<distance-40.0 then
                  return True;
               else
                  return False;
               end if;
            else
               return False;
            end if;
         else
            return False;
         end if;
      end can_abitante_move;

      function get_distanza_percorsa_first_abitante(polo: Boolean; num_corsia: id_corsie) return Float is
         distance_ingressi: Float;
         distance_abitante: Float;
      begin
         distance_abitante:= get_distance_to_first_abitante(polo,num_corsia);
         distance_ingressi:= calculate_distance_ingressi_from_given_distance(polo,num_corsia,0.0);
         if distance_abitante=-1.0 and distance_ingressi=-1.0 then
            return -1.0;
         elsif distance_abitante=-1.0 then
            return distance_ingressi;
         elsif distance_ingressi=-1.0 then
            return distance_abitante;
         elsif distance_abitante<=distance_ingressi then
            return distance_abitante;
         else
            return distance_ingressi;
         end if;
      end get_distanza_percorsa_first_abitante;

      function get_distance_to_first_abitante(polo: Boolean; num_corsia: id_corsie) return Float is
         abitante: ptr_list_posizione_abitanti_on_road;
      begin
         abitante:= get_next_abitante_on_road(0.0,polo,num_corsia);
         if abitante/=null then
            if abitante.posizione_abitante.get_in_overtaken and abitante.posizione_abitante.get_destination.get_corsia_to_go_trajectory=num_corsia then
               return abitante.posizione_abitante.get_where_now_posizione_abitanti+3.5;
            else
               return abitante.posizione_abitante.get_where_now_posizione_abitanti;
            end if;
         else
            return -1.0;
         end if;
      end get_distance_to_first_abitante;

      function get_num_ingressi_polo(polo: Boolean) return Natural is
      begin
         if polo then
            return num_ingressi_polo_true;
         else
            return num_ingressi_polo_false;
         end if;
      end get_num_ingressi_polo;

      function get_num_ingressi return Natural is
      begin
         return num_ingressi;
      end get_num_ingressi;

   end resource_segmento_urbana;

   protected body resource_segmento_ingresso is
      entry wait_turno when True is
      begin
         null;
      end wait_turno;
      procedure delta_terminate is
      begin
         null;
      end delta_terminate;

      procedure set_move_parameters_entity_on_main_strada(range_1: Boolean; num_entity: Positive;
                                                          speed: Float; step_to_advance: Float) is
         node: ptr_list_posizione_abitanti_on_road:= null;
      begin
         node:= slide_list(road,range_1,num_entity);
         if speed>0.0 then
            node.posizione_abitante.set_current_speed_abitante(speed);
         end if;
         if step_to_advance>0.0 then
            if range_1=not index_inizio_moto then
               node.posizione_abitante.set_where_next_abitante(node.posizione_abitante.get_where_now_posizione_abitanti+step_to_advance);
            elsif node.posizione_abitante.get_where_now_posizione_abitanti+step_to_advance>risorsa_features.get_lunghezza_road then
               node.posizione_abitante.set_where_next_abitante(risorsa_features.get_lunghezza_road);
            else
               node.posizione_abitante.set_where_next_abitante(node.posizione_abitante.get_where_now_posizione_abitanti+step_to_advance);
            end if;
         end if;
      end set_move_parameters_entity_on_main_strada;

      function slide_list(type_structure: data_structures_types; range_1: Boolean; index_to_slide: Positive) return ptr_list_posizione_abitanti_on_road is
         list: ptr_list_posizione_abitanti_on_road:= null;
         current_node: ptr_list_posizione_abitanti_on_road:= null;
      begin
         case type_structure is
            when road =>
               list:= main_strada(range_1,1);
            when sidewalk =>
               list:= marciapiedi(range_1,1);
         end case;
         for i in 1..index_to_slide loop
            if list=null then
               return null;
            else
               current_node:= list;
               list:= list.all.next;
            end if;
         end loop;
         return current_node;
      end slide_list;

      procedure registra_abitante_to_move(type_structure: data_structures_types; begin_speed: Float; posix: Float) is
         list_abitanti: ptr_list_posizione_abitanti_on_road:= new list_posizione_abitanti_on_road;
         abitante: posizione_abitanti_on_road;
         where_next: Float;
      begin
         case type_structure is
            when road =>
               if main_strada_temp/=null then
                  list_abitanti.next:= main_strada(index_inizio_moto,1);
                  main_strada(index_inizio_moto,1):= list_abitanti;
                  if posix>risorsa_features.get_lunghezza_road then
                     where_next:= risorsa_features.get_lunghezza_road;
                  else
                     where_next:= posix;
                  end if;
                  abitante:= posizione_abitanti_on_road(create_new_posizione_abitante(main_strada_temp.posizione_abitante.get_id_abitante_posizione_abitanti,
                                                        main_strada_temp.posizione_abitante.get_id_quartiere_posizione_abitanti,where_next,0.0,begin_speed,False,
                                                        0.0,0.0,False,create_trajectory_to_follow(0,0,0,0,empty)));
                  main_strada_temp:= main_strada_temp.next;
                  main_strada_number_entity(index_inizio_moto,1):= main_strada_number_entity(index_inizio_moto,1)+1;
               end if;
            when sidewalk =>
               null;
         end case;
      end registra_abitante_to_move;

      procedure new_abitante_to_move(id_quartiere: Positive; id_abitante: Positive; mezzo: means_of_carrying) is
         list_abitanti: ptr_list_posizione_abitanti_on_road:= new list_posizione_abitanti_on_road;
         abitante: posizione_abitanti_on_road;
         last_node: ptr_list_posizione_abitanti_on_road:= null;
      begin
         abitante:= posizione_abitanti_on_road(create_new_posizione_abitante(id_abitante,id_quartiere,0.0,0.0,0.0,False,0.0,0.0,False,create_trajectory_to_follow(0,0,0,0,empty)));
         list_abitanti.posizione_abitante:= abitante;
         case mezzo is
            when walking | autobus | bike =>
               if marciapiedi_temp=null then
                  marciapiedi_temp:= list_abitanti;
               else
                  last_node:= marciapiedi_temp;
                  while last_node.next/=null loop
                     last_node:= last_node.next;
                  end loop;
                  last_node.next:= list_abitanti;
               end if;
            when car =>
               if main_strada_temp=null then
                  main_strada_temp:= list_abitanti;
               else
                  last_node:= main_strada_temp;
                  while last_node.next/=null loop
                     last_node:= last_node.next;
                  end loop;
                  last_node.next:= list_abitanti;
               end if;
         end case;
      end new_abitante_to_move;

      procedure new_abitante_finish_route(abitante: posizione_abitanti_on_road; mezzo: means_of_carrying) is
         new_abitante: ptr_list_posizione_abitanti_on_road;
      begin
         -- guardando destination.corsia_to_go si capisce se l'abitante arriva da entrata_andata o entrata_ritorno
         case mezzo is
            when walking | autobus | bike =>
               null;
            when car =>
               new_abitante:= create_new_list_posizione_abitante(create_new_posizione_abitante_from_copy(abitante),main_strada(not index_inizio_moto,1));
               if new_abitante.posizione_abitante.get_destination.get_corsia_to_go_trajectory=2 then -- traiettoria da entrata_ritorno
                  new_abitante.posizione_abitante.set_where_next_abitante(new_abitante.posizione_abitante.get_where_now_posizione_abitanti-25.0);  -- lenght traiettoria entrata_ritorno
               else
                  new_abitante.posizione_abitante.set_where_next_abitante(new_abitante.posizione_abitante.get_where_now_posizione_abitanti-10.0);  -- length traiettoria entrata_andata
               end if;
               new_abitante.posizione_abitante.set_where_now_abitante(new_abitante.posizione_abitante.get_where_next_posizione_abitanti);
               main_strada(not index_inizio_moto,1):= new_abitante;
               main_strada_number_entity(not index_inizio_moto,1):= main_strada_number_entity(not index_inizio_moto,1)+1;
         end case;
      end new_abitante_finish_route;

      procedure update_position_entity(type_structure: data_structures_types; range_1: Boolean; index_entity: Positive) is
         nodo: ptr_list_posizione_abitanti_on_road:= null;
      begin
         case type_structure is
            when road =>
               nodo:= slide_list(road,range_1,index_entity);
            when sidewalk =>
               nodo:= slide_list(sidewalk,range_1,index_entity);
         end case;
         nodo.posizione_abitante.set_where_now_abitante(nodo.posizione_abitante.get_where_next_posizione_abitanti);
      end update_position_entity;

      procedure update_avanzamento_car_in_urbana(distance: Float) is
      begin
         car_avanzamento_in_urbana:= distance;
      end update_avanzamento_car_in_urbana;

      procedure delete_car_in_uscita is
      begin
         slide_list(road,index_inizio_moto,main_strada_number_entity(index_inizio_moto,1)-1).next:= null;
         main_strada_number_entity(index_inizio_moto,1):= main_strada_number_entity(index_inizio_moto,1)-1;
      end delete_car_in_uscita;

      procedure delete_car_in_entrata is
      begin
         slide_list(road,not index_inizio_moto,main_strada_number_entity(not index_inizio_moto,1)-1).next:= null;
         main_strada_number_entity(not index_inizio_moto,1):= main_strada_number_entity(not index_inizio_moto,1)-1;
      end delete_car_in_entrata;

      function get_main_strada(range_1: Boolean) return ptr_list_posizione_abitanti_on_road is
      begin
         return main_strada(range_1,1);
      end get_main_strada;

      function get_marciapiede(range_1: Boolean) return ptr_list_posizione_abitanti_on_road is
      begin
         return marciapiedi(range_1,1);
      end get_marciapiede;

      function get_number_entity_strada(range_1: Boolean) return Natural is
      begin
         return main_strada_number_entity(range_1,1);
      end get_number_entity_strada;

      function get_number_entity_marciapiede(range_1: Boolean) return Natural is
      begin
         return marciapiedi_number_entity(range_1,1);
      end get_number_entity_marciapiede;

      function get_temp_main_strada return ptr_list_posizione_abitanti_on_road is
      begin
         return main_strada_temp;
      end get_temp_main_strada;

      function get_temp_marciapiede return ptr_list_posizione_abitanti_on_road is
      begin
         return marciapiedi_temp;
      end get_temp_marciapiede;

      function get_posix_first_entity(type_structure: data_structures_types; range_1: Boolean) return Float is
      begin
         case type_structure is
            when road =>
               return main_strada(range_1,1).posizione_abitante.get_where_now_posizione_abitanti;
            when sidewalk =>
               return marciapiedi(range_1,1).posizione_abitante.get_where_now_posizione_abitanti;
         end case;
      end get_posix_first_entity;

      function get_index_inizio_moto return Boolean is
      begin
         return index_inizio_moto;
      end get_index_inizio_moto;

      function get_first_abitante_to_exit_from_urbana return ptr_list_posizione_abitanti_on_road is
      begin
         return main_strada(not index_inizio_moto,1);
      end get_first_abitante_to_exit_from_urbana;

      function get_car_avanzamento return Float is
      begin
         return car_avanzamento_in_urbana;
      end get_car_avanzamento;

      procedure configure(risorsa: strada_ingresso_features; inizio_moto: Boolean) is
      begin
         risorsa_features:= risorsa;
         index_inizio_moto:= inizio_moto;
      end configure;
   end resource_segmento_ingresso;

   protected body resource_segmento_incrocio is
      function get_num_urbane_to_wait return Positive is
      begin
         if id_risorsa>=get_from_incroci_a_4 and id_risorsa<=get_to_incroci_a_4 then
            return 4;
         else
            return 3;
         end if;
      end get_num_urbane_to_wait;

      entry wait_turno when finish_delta_incrocio is
      begin
         num_urbane_ready:=num_urbane_ready+1;
         if num_urbane_ready=get_num_urbane_to_wait then
            finish_delta_incrocio:= False;
            num_urbane_ready:= 0;
         end if;
      end wait_turno;

      procedure delta_terminate is
      begin
         finish_delta_incrocio:= True;
      end delta_terminate;

      procedure change_verso_semafori_verdi is
      begin
         verso_semafori_verdi:= not verso_semafori_verdi;
      end change_verso_semafori_verdi;

      procedure insert_new_car(from_id_quartiere: Positive; from_id_road: Positive; car: posizione_abitanti_on_road) is
         key_road: Natural;
         new_abitante: ptr_list_posizione_abitanti_on_road:= new list_posizione_abitanti_on_road;
         copy_car: posizione_abitanti_on_road:= car;
      begin
         key_road:= get_index_road_from_incrocio(id_risorsa,from_id_quartiere,from_id_road);
         copy_car.set_where_now_abitante(0.0);
         copy_car.set_where_next_abitante(0.0);
         if key_road/=0 then
            new_abitante.posizione_abitante:= car;
            new_abitante.next:= car_to_move(key_road,car.get_destination.get_corsia_to_go_trajectory);
            car_to_move(key_road,car.get_destination.get_corsia_to_go_trajectory):= new_abitante;
         else
            Put_Line("macchina non inserita");
         end if;
      end insert_new_car;

      procedure update_avanzamento_car(abitante: in out ptr_list_posizione_abitanti_on_road; new_step: Float; new_speed: Float) is
      begin
         if new_speed>0.0 then
            abitante.posizione_abitante.set_current_speed_abitante(new_speed);
         end if;
         if new_step>0.0 then
            abitante.posizione_abitante.set_where_next_abitante(abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step);
            abitante.posizione_abitante.set_current_speed_abitante(new_speed);
         end if;
      end update_avanzamento_car;

      procedure update_avanzamento_cars is
         list: ptr_list_posizione_abitanti_on_road;
      begin
         for i in 1..size_incrocio loop
            for j in id_corsie'Range loop
               list:= car_to_move(i,j);
               while list/=null loop
                  list.posizione_abitante.set_where_now_abitante(list.posizione_abitante.get_where_next_posizione_abitanti);
                  list:= list.next;
               end loop;
            end loop;
         end loop;
      end update_avanzamento_cars;

      function get_verso_semafori_verdi return Boolean is
      begin
         return verso_semafori_verdi;
      end get_verso_semafori_verdi;

      function get_size_incrocio return Positive is
      begin
         return size_incrocio;
      end get_size_incrocio;

      function get_list_car_to_move(key_incrocio: Positive; corsia: id_corsie) return ptr_list_posizione_abitanti_on_road is
      begin
         return car_to_move(key_incrocio,corsia);
      end get_list_car_to_move;

      function get_posix_first_entity(from_id_quartiere_road: Positive; from_id_road: Positive; num_corsia: id_corsie) return Float is
         index: Natural:= get_index_road_from_incrocio(from_id_quartiere_road,from_id_road,id_risorsa);
      begin
         if index/=0 and car_to_move(index,num_corsia)/=null then
            return car_to_move(index,num_corsia).posizione_abitante.get_where_now_posizione_abitanti;
         end if;
         return 0.0;
      end get_posix_first_entity;

   end resource_segmento_incrocio;

   protected body resource_segmento_rotonda is
      entry wait_turno when True is
      begin
         null;
      end wait_turno;
      procedure delta_terminate is
      begin
         null;
      end delta_terminate;
   end resource_segmento_rotonda;

   function get_urbane_segmento_resources(index: Positive) return ptr_resource_segmento_urbana is
   begin
      return urbane_segmento_resources(index);
   end get_urbane_segmento_resources;

   function get_ingressi_segmento_resources(index: Positive) return ptr_resource_segmento_ingresso is
   begin
      return ingressi_segmento_resources(index);
   end get_ingressi_segmento_resources;

   function get_incroci_segmento_resources(index: Positive) return ptr_resource_segmento_incrocio is
   begin
      if index>=get_from_incroci_a_4 and index<=get_to_incroci_a_4 then
         return get_incroci_a_4_segmento_resources(index);
      elsif index>=get_from_incroci_a_3 and index<=get_to_incroci_a_3 then
         return get_incroci_a_3_segmento_resources(index);
      end if;
      return null;
   end get_incroci_segmento_resources;

   function get_rotonde_segmento_resources(index: Positive) return ptr_resource_segmento_rotonda is
   begin
      if index>=get_from_rotonde_a_4 and index<=get_to_rotonde_a_4 then
         return get_rotonde_a_4_segmento_resources(index);
      elsif index>=get_from_rotonde_a_3 and index<=get_to_rotonde_a_3 then
         return get_rotonde_a_3_segmento_resources(index);
      end if;
      return null;
   end get_rotonde_segmento_resources;

   function get_incroci_a_4_segmento_resources(index: Positive) return ptr_resource_segmento_incrocio is
   begin
      return incroci_a_4_segmento_resources(index);
   end get_incroci_a_4_segmento_resources;

   function get_incroci_a_3_segmento_resources(index: Positive) return ptr_resource_segmento_incrocio is
   begin
      return incroci_a_3_segmento_resources(index);
   end get_incroci_a_3_segmento_resources;

   function get_rotonde_a_4_segmento_resources(index: Positive) return ptr_resource_segmento_rotonda is
   begin
      return rotonde_a_4_segmento_resources(index);
   end get_rotonde_a_4_segmento_resources;

   function get_rotonde_a_3_segmento_resources(index: Positive) return ptr_resource_segmento_rotonda is
   begin
      return rotonde_a_3_segmento_resources(index);
   end get_rotonde_a_3_segmento_resources;

   function get_ingressi_urbana(id_urbana: Positive) return ptr_id_ingressi_urbane is
   begin
      return ingressi_urbane(id_urbana);
   end get_ingressi_urbana;

   function get_posizione_abitanti_from_list_posizione_abitanti(obj: list_posizione_abitanti_on_road) return posizione_abitanti_on_road'Class is
   begin
      return obj.posizione_abitante;
   end get_posizione_abitanti_from_list_posizione_abitanti;
   function get_next_from_list_posizione_abitanti(obj: list_posizione_abitanti_on_road) return ptr_list_posizione_abitanti_on_road is
   begin
      return obj.next;
   end get_next_from_list_posizione_abitanti;

   type num_ingressi_urbana is array(Positive range <>) of Natural;
   type num_ingressi_urbana_per_polo is array(Positive range <>,Boolean range <>) of Natural;

   procedure update_list_ingressi(lista: ptr_list_ingressi_per_urbana; new_node: ptr_list_ingressi_per_urbana; structure: ingressi_type; indice_ingresso: Positive) is
      prec_list_ingressi: ptr_list_ingressi_per_urbana;
      list: ptr_list_ingressi_per_urbana:= lista;
   begin
      if list=null then
         case structure is
            when not_ordered =>
               id_ingressi_per_urbana(get_ingresso_from_id(indice_ingresso).get_id_main_strada_ingresso):= new_node;
            when ordered_polo_true =>
               id_ingressi_per_urbana_per_polo(get_ingresso_from_id(indice_ingresso).get_id_main_strada_ingresso,True):= new_node;
            when ordered_polo_false =>
               id_ingressi_per_urbana_per_polo(get_ingresso_from_id(indice_ingresso).get_id_main_strada_ingresso,False):= new_node;
         end case;
      else
         prec_list_ingressi:= null;
         while list/=null and then get_ingresso_from_id(list.id_ingresso).get_distance_from_road_head_ingresso<get_ingresso_from_id(indice_ingresso).get_distance_from_road_head_ingresso loop
            prec_list_ingressi:= list;
            list:= list.next;
         end loop;
         if prec_list_ingressi=null then
            case structure is
            when not_ordered =>
               new_node.next:= id_ingressi_per_urbana(get_ingresso_from_id(indice_ingresso).get_id_main_strada_ingresso);
               id_ingressi_per_urbana(get_ingresso_from_id(indice_ingresso).get_id_main_strada_ingresso):= new_node;
            when ordered_polo_true =>
               new_node.next:= id_ingressi_per_urbana_per_polo(get_ingresso_from_id(indice_ingresso).get_id_main_strada_ingresso,True);
               id_ingressi_per_urbana_per_polo(get_ingresso_from_id(indice_ingresso).get_id_main_strada_ingresso,True):= new_node;
            when ordered_polo_false =>
               new_node.next:= id_ingressi_per_urbana_per_polo(get_ingresso_from_id(indice_ingresso).get_id_main_strada_ingresso,False);
               id_ingressi_per_urbana_per_polo(get_ingresso_from_id(indice_ingresso).get_id_main_strada_ingresso,False):= new_node;
            end case;
         else
            new_node.next:= list;
            prec_list_ingressi.next:= new_node;
         end if;
      end if;
   end update_list_ingressi;

   procedure create_mailbox_entità(urbane: strade_urbane_features; ingressi: strade_ingresso_features;
                                   incroci_a_4: list_incroci_a_4; incroci_a_3: list_incroci_a_3;
                                    rotonde_a_4: list_incroci_a_4; rotonde_a_3: list_incroci_a_3) is
      val_ptr_resource_urbana: ptr_resource_segmento_urbana;
      val_ptr_resource_ingresso: ptr_resource_segmento_ingresso;
      val_ptr_resource_incrocio: ptr_resource_segmento_incrocio;
      val_ptr_resource_rotonda: ptr_resource_segmento_rotonda;
      ptr_resource_urbane: ptr_resource_segmenti_urbane:= new resource_segmenti_urbane(get_from_urbane..get_to_urbane);
      ptr_resource_ingressi: ptr_resource_segmenti_ingressi:= new resource_segmenti_ingressi(get_from_ingressi..get_to_ingressi);
      ptr_resource_incroci_a_4: ptr_resource_segmenti_incroci:= new resource_segmenti_incroci(get_from_incroci_a_4..get_to_incroci_a_4);
      ptr_resource_incroci_a_3: ptr_resource_segmenti_incroci:= new resource_segmenti_incroci(get_from_incroci_a_3..get_to_incroci_a_3);
      ptr_resource_rotonde_a_4: ptr_resource_segmenti_rotonde:= new resource_segmenti_rotonde(get_from_rotonde_a_4..get_to_rotonde_a_4);
      ptr_resource_rotonde_a_3: ptr_resource_segmenti_rotonde:= new resource_segmenti_rotonde(get_from_rotonde_a_3..get_to_rotonde_a_3);
      ingressi_per_urbana: num_ingressi_urbana(get_from_urbane..get_to_urbane):= (others => 0);
      ingressi_per_urbana_per_polo: num_ingressi_urbana_per_polo(get_from_urbane..get_to_urbane,False..True):= (others => (others => 0));
      index_ingressi: id_ingressi_urbane(get_from_urbane..get_to_urbane):= (others => 1);
      node_ingressi: ptr_list_ingressi_per_urbana;
      node_ordered_ingressi: ptr_list_ingressi_per_urbana;
      index_inizio_moto: Boolean;
      polo_ingressi_structure: ingressi_type;
   begin

      for i in get_from_ingressi..get_to_ingressi loop
         node_ingressi:= new list_ingressi_per_urbana;
         node_ordered_ingressi:= new list_ingressi_per_urbana;
         val_ptr_resource_ingresso:= new resource_segmento_ingresso(id_risorsa => ingressi(i).get_id_road);
         node_ordered_ingressi.id_ingresso:= i;
         index_inizio_moto:= ingressi(i).get_polo_ingresso;
         ingressi_per_urbana_per_polo(ingressi(i).get_id_main_strada_ingresso,index_inizio_moto):= ingressi_per_urbana_per_polo(ingressi(i).get_id_main_strada_ingresso,index_inizio_moto)+1;
         if index_inizio_moto then
            polo_ingressi_structure:= ordered_polo_true;
         else
            polo_ingressi_structure:= ordered_polo_false;
         end if;
         update_list_ingressi(id_ingressi_per_urbana_per_polo(ingressi(i).get_id_main_strada_ingresso,index_inizio_moto),node_ordered_ingressi,polo_ingressi_structure,i);
         val_ptr_resource_ingresso.configure(ingressi(i),index_inizio_moto);
         ingressi_per_urbana(ingressi(i).get_id_main_strada_ingresso):= ingressi_per_urbana(ingressi(i).get_id_main_strada_ingresso)+1;
         node_ingressi.id_ingresso:= i;
         update_list_ingressi(id_ingressi_per_urbana(ingressi(i).get_id_main_strada_ingresso),node_ingressi,not_ordered,i);
         ptr_resource_ingressi(i):= val_ptr_resource_ingresso;
      end loop;
      ingressi_segmento_resources:= ptr_resource_ingressi;

      for i in get_from_urbane..get_to_urbane loop
         --Put_Line("begin configure urbana " & Positive'Image(i) & ", id quartiere " & Positive'Image(get_id_quartiere));
         val_ptr_resource_urbana:= new resource_segmento_urbana(id_risorsa => urbane(i).get_id_road,
                                                                num_ingressi => ingressi_per_urbana(urbane(i).get_id_road),
                                                                num_ingressi_polo_true => ingressi_per_urbana_per_polo(urbane(i).get_id_road,True),
                                                                num_ingressi_polo_false => ingressi_per_urbana_per_polo(urbane(i).get_id_road,False));
         val_ptr_resource_urbana.configure(urbane(i),id_ingressi_per_urbana(i),id_ingressi_per_urbana_per_polo(i,True),id_ingressi_per_urbana_per_polo(i,False));
         --Put_Line("end configure urbana " & Positive'Image(i) & ", id quartiere " & Positive'Image(get_id_quartiere));
         ptr_resource_urbane(i):= val_ptr_resource_urbana;
      end loop;
      urbane_segmento_resources:= ptr_resource_urbane;

      for i in ingressi_per_urbana'Range loop
         if ingressi_per_urbana(i)=0 then
            ingressi_urbane(i):= null;
         else
            ingressi_urbane(i):= new id_ingressi_urbane(1..ingressi_per_urbana(i));
         end if;
      end loop;

      for i in ingressi'Range loop
         if ingressi_urbane(ingressi(i).get_id_main_strada_ingresso)/= null then
            ingressi_urbane(ingressi(i).get_id_main_strada_ingresso)(index_ingressi(ingressi(i).get_id_main_strada_ingresso)):= i;
            index_ingressi(ingressi(i).get_id_main_strada_ingresso):= index_ingressi(ingressi(i).get_id_main_strada_ingresso)+1;
            --Put_Line("ingresso" & Positive'Image(i) & " in urbana" & Positive'Image(ingressi(i).get_id_main_strada_ingresso));
         end if;
      end loop;

      for i in get_from_incroci_a_4..get_to_incroci_a_4 loop
         val_ptr_resource_incrocio:= new resource_segmento_incrocio(i,4); --TO DO
         ptr_resource_incroci_a_4(i):= val_ptr_resource_incrocio;
      end loop;
      incroci_a_4_segmento_resources:= ptr_resource_incroci_a_4;

      for i in get_from_incroci_a_3..get_to_incroci_a_3 loop
         val_ptr_resource_incrocio:= new resource_segmento_incrocio(i,3); --TO DO
         ptr_resource_incroci_a_3(i):= val_ptr_resource_incrocio;
      end loop;
      incroci_a_3_segmento_resources:= ptr_resource_incroci_a_3;

      for i in get_from_rotonde_a_4..get_to_rotonde_a_4 loop
         val_ptr_resource_rotonda:= new resource_segmento_rotonda(i,1,1); --TO DO
         ptr_resource_rotonde_a_4(i):= val_ptr_resource_rotonda;
      end loop;
      rotonde_a_4_segmento_resources:= ptr_resource_rotonde_a_4;

      for i in get_from_rotonde_a_3..get_to_rotonde_a_3 loop
         val_ptr_resource_rotonda:= new resource_segmento_rotonda(i,1,1); --TO DO
         ptr_resource_rotonde_a_3(i):= val_ptr_resource_rotonda;
      end loop;
      rotonde_a_3_segmento_resources:= ptr_resource_rotonde_a_3;
   end create_mailbox_entità;

   function get_list_ingressi_urbana(id_urbana: Positive) return ptr_list_ingressi_per_urbana is
   begin
      return id_ingressi_per_urbana(id_urbana);
   end get_list_ingressi_urbana;

   function create_new_list_posizione_abitante(posizione_abitante: posizione_abitanti_on_road;
                                               next: ptr_list_posizione_abitanti_on_road) return ptr_list_posizione_abitanti_on_road is
      list_abitante: ptr_list_posizione_abitanti_on_road:= new list_posizione_abitanti_on_road;
   begin
      list_abitante.posizione_abitante:= posizione_abitante;
      list_abitante.next:= next;
      return list_abitante;
   end create_new_list_posizione_abitante;

   -- precondizione la traiettoria della quale viene calcolato l'indice è una traiettoria percorribile perchè quella strada in cui la traiettoria porta, esiste
   function calulate_index_road_to_go(id_incrocio: Positive; from_index: Positive; traiettoria: traiettoria_incroci_type) return Natural is
      size_incrocio: Positive:= get_size_incrocio(id_incrocio);
      index_to_go: Natural:= 0;
      id_mancante: Natural:= get_mancante_incrocio_a_3(id_incrocio);
   begin
      case traiettoria is
         when dritto | empty => return 0;
         when destra =>
            index_to_go:= from_index-1;
            if index_to_go=0 then
               index_to_go:= size_incrocio;
            end if;
         when sinistra =>
            index_to_go:= from_index+1;
            if index_to_go=size_incrocio+1 then
               index_to_go:= size_incrocio;
            end if;
         when dritto_1 | dritto_2 =>
            if id_mancante=0 then
               if from_index=1 then
                  index_to_go:= 3;
               elsif from_index=2 then
                  index_to_go:= 4;
               elsif from_index=3 then
                  index_to_go:= 1;
               elsif from_index=4 then
                  index_to_go:= 2;
               end if;
            elsif id_mancante=1 or id_mancante=4 then
               if from_index=1 then
                  index_to_go:= 3;
               elsif from_index=3 then
                  index_to_go:= 1;
               end if;
            elsif id_mancante=2 then
               if from_index=1 then
                  index_to_go:= 2;
               elsif from_index=2 then
                  index_to_go:= 1;
               end if;
            elsif id_mancante=3 then
               if from_index=2 then
                  index_to_go:= 3;
               elsif from_index=3 then
                  index_to_go:= 2;
               end if;
            end if;
      end case;
      return index_to_go;
   end calulate_index_road_to_go;

end mailbox_risorse_attive;
