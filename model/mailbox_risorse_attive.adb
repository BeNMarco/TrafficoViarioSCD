with Text_IO;
with GNATCOLL.JSON;
with Polyorb.Parameters;
with Ada.Strings.Unbounded;

with remote_types;
with data_quartiere;
with global_data;
with risorse_passive_data;
with risorse_mappa_utilities;
with the_name_server;
with model_webserver_communication_protocol_utilities;
with JSON_Helper;
with absolute_path;
with numerical_types;

use Text_IO;
use GNATCOLL.JSON;
use Polyorb.Parameters;
use Ada.Strings.Unbounded;

use remote_types;
use data_quartiere;
use global_data;
use risorse_passive_data;
use risorse_mappa_utilities;
use the_name_server;
use model_webserver_communication_protocol_utilities;
use JSON_Helper;
use absolute_path;
use numerical_types;

package body mailbox_risorse_attive is

   function calculate_bound_to_overtake(abitante: ptr_list_posizione_abitanti_on_road; polo: Boolean; id_urbana: Positive) return new_float is
      distance: new_float;
   begin
      if abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow=empty then
         if polo then
            distance:= get_urbana_from_id(id_urbana).get_lunghezza_road-get_ingresso_from_id(abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_ingresso_to_go_trajectory).get_distance_from_road_head_ingresso-abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
         else
            distance:= get_ingresso_from_id(abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_ingresso_to_go_trajectory).get_distance_from_road_head_ingresso-abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
         end if;
      else
         distance:= get_urbana_from_id(id_urbana).get_lunghezza_road-abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
      end if;
      return distance-bound_to_change_corsia;
   end calculate_bound_to_overtake;

   function get_min_length_entità(entity: entità) return new_float is
   begin
      case entity is
         when pedone_entity => return min_length_pedoni;
         when bici_entity => return min_length_bici;
         when auto_entity => return min_length_auto;
      end case;
   end get_min_length_entità;

   --function create_img_abitante(abitante: posizione_abitanti_on_road; new_position_abitante: Float) return JSON_Value is
      --json_1: JSON_Value:= Create_Object;
      --json_2: JSON_Value:= Create_Object;
   --begin
   --   begin
   --      if new_position_abitante=-1.0 then
   --         json_1.Set_Field("id_abitante",abitante.get_id_abitante_posizione_abitanti);
   --         json_1.Set_Field("id_quartiere",abitante.get_id_quartiere_posizione_abitanti);
   --      else
   --         json_1.Set_Field("id_abitante",new_position_abitante);
   --         json_1.Set_Field("id_quartiere",new_position_abitante);
   --      end if;

   --      json_1.Set_Field("where_next",Create(abitante.get_where_next_posizione_abitanti));
   --      json_1.Set_Field("where_now",Create(abitante.get_where_now_posizione_abitanti));
   --      json_1.Set_Field("current_speed",Create(abitante.get_current_speed_abitante));
   --      json_1.Set_Field("in_overtaken",abitante.get_in_overtaken);
   --      json_1.Set_Field("can_pass_corsia",abitante.get_flag_overtake_next_corsia);
   --      json_1.Set_Field("came_from_ingresso",abitante.get_came_from_ingresso);
   --      json_1.Set_Field("distance_on_overtaking_trajectory",Create(abitante.get_distance_on_overtaking_trajectory));

   --      json_2.Set_Field("departure_corsia",abitante.get_destination.get_departure_corsia);
   --      json_2.Set_Field("corsia_to_go",abitante.get_destination.get_corsia_to_go_trajectory);
   --      json_2.Set_Field("ingresso_to_go",abitante.get_destination.get_ingresso_to_go_trajectory);
   --      json_2.Set_Field("from_ingresso",abitante.get_destination.get_from_ingresso);
   --      json_2.Set_Field("traiettoria_incrocio_to_follow",to_string_incroci_type(abitante.get_destination.get_traiettoria_incrocio_to_follow));
   --      json_1.Set_Field("destination",json_2);
   --      json_1.Set_Field("backup_corsia_to_go",abitante.get_backup_corsia_to_go);
   --   exception
   --      when others =>
   --         Put_Line("creazione abitante error in: " & Positive'Image(get_id_quartiere));
   --         raise set_field_json_error;
   --   end;
   --   return json_1;
   --end create_img_abitante;

   --function create_img_strada(road: road_state; id_risorsa: Positive) return JSON_Value is
   --   json_1: JSON_Value:= Create_Object;
   --   json_2: JSON_Value;
   --   json_abitanti: JSON_Array;
   --   json_abitante: JSON_Value;
   --   list: ptr_list_posizione_abitanti_on_road;
   --   new_position_abitante: Float;
   --begin
      -- "main_strada": {"false": {"1":[{abitante1},{..abitanteN}],"2": *1o*2}, "true": [[],*1o*2]}
   --   for i in road'Range(1) loop
   --      json_2:= Create_Object;
   --      for j in road'Range(2) loop
   --         list:= road(i,j);
   --         json_abitanti:= Empty_Array;
   --         while list/=null loop
   --            if id_risorsa>=get_from_urbane and id_risorsa<=get_to_urbane then
   --               if list.posizione_abitante.get_where_now_posizione_abitanti>=get_urbana_from_id(id_risorsa).get_lunghezza_road then
   --                  new_position_abitante:= -1.0;
   --               else
   --                  new_position_abitante:= Float'Last;
   --               end if;
   --            else
   --               new_position_abitante:= -1.0;
   --            end if;
   --            json_abitante:= create_img_abitante(list.posizione_abitante,new_position_abitante);
   --            Append(json_abitanti,json_abitante);
   --            list:= list.next;
   --         end loop;
   --         json_2.Set_Field(Positive'Image(j),json_abitanti);
   --      end loop;
   --      begin
   --         if i then
   --            json_1.Set_Field("TRUE",json_2);
   --         else
   --            json_1.Set_Field("FALSE",json_2);
   --         end if;
   --      exception
   --         when others =>
   --            Put_Line("errore nella creazione abitanti in strada in: " & Positive'Image(get_id_quartiere));
   --            raise set_field_json_error;
   --      end;
   --   end loop;
   --   return json_1;
   --end create_img_strada;

   --function create_img_num_entity_strada(num_entity_strada: number_entity) return JSON_Value is
   --   json_1: JSON_Value:= Create_Object;
   --   json_2: JSON_Value;
   --begin
      -- "main_strada_number_entity": {"false": {"1": NUM,"2": NUM se c'è}, "true": {"1": NUM,"2": NUM se c'è}}
   --   for i in num_entity_strada'Range(1) loop
   --      json_2:= Create_Object;
   --      for j in num_entity_strada'Range(2) loop
   --         json_2.Set_Field(Positive'Image(j),num_entity_strada(i,j));
   --      end loop;
   --      begin
   --         if i then
   --            json_1.Set_Field("TRUE",json_2);
   --         else
   --            json_1.Set_Field("FALSE",json_2);
   --         end if;
   --      exception
   --         when others =>
   --            Put_Line("errore nella creazione num entity in strada in: " & Positive'Image(get_id_quartiere));
   --            raise set_field_json_error;
   --      end;
   --   end loop;
   --   return json_1;
   --end create_img_num_entity_strada;

   --function create_abitante_from_json(json_abitante: JSON_Value) return posizione_abitanti_on_road is
   --   destination: trajectory_to_follow;
   --begin
   --   destination:= create_trajectory_to_follow(from_corsia                    => json_abitante.Get("destination").Get("departure_corsia"),
   --                                             corsia_to_go                   => json_abitante.Get("destination").Get("corsia_to_go"),
   --                                             ingresso_to_go                 => json_abitante.Get("destination").Get("ingresso_to_go"),
   --                                             from_ingresso                  => json_abitante.Get("destination").Get("from_ingresso"),
   --                                             traiettoria_incrocio_to_follow => convert_to_traiettoria_incroci(json_abitante.Get("destination").Get("traiettoria_incrocio_to_follow")));
   --   return posizione_abitanti_on_road(create_new_posizione_abitante(id_abitante                       => json_abitante.Get("id_abitante"),
   --                                                                   id_quartiere                      => json_abitante.Get("id_quartiere"),
   --                                                                   where_next                        => json_abitante.Get("where_next"),
   --                                                                   where_now                         => json_abitante.Get("where_now"),
   --                                                                   current_speed                     => json_abitante.Get("current_speed"),
   --                                                                   in_overtaken                      => json_abitante.Get("in_overtaken"),
   --                                                                  can_pass_corsia                   => json_abitante.Get("can_pass_corsia"),
   --                                                                   distance_on_overtaking_trajectory => json_abitante.Get("distance_on_overtaking_trajectory"),
   --                                                                   came_from_ingresso                => json_abitante.Get("came_from_ingresso"),
   --                                                                   destination                       => destination,
   --                                                                   backup_corsia_to_go => json_abitante.Get("backup_corsia_to_go")));
   --end create_abitante_from_json;

   --function create_array_abitanti(json_abitanti: JSON_Array) return ptr_list_posizione_abitanti_on_road is
   --   prec_abitante: ptr_list_posizione_abitanti_on_road;
   --  list: ptr_list_posizione_abitanti_on_road;
   --   json_abitante: JSON_Value;
   --   abitante: posizione_abitanti_on_road;
   --   ptr_abitante: ptr_list_posizione_abitanti_on_road;
   --begin
   --   for z in 1..Length(json_abitanti) loop
   --      json_abitante:= Get(json_abitanti,z);
   --      abitante:= create_abitante_from_json(json_abitante);
   --      ptr_abitante:= create_new_list_posizione_abitante(abitante,null);
   --      if prec_abitante=null then
   --         list:= ptr_abitante;
   --      else
   --         prec_abitante.next:= ptr_abitante;
   --      end if;
   --      prec_abitante:= ptr_abitante;
   --   end loop;
   --   return list;
   --end create_array_abitanti;

   protected body resource_segmento_urbana is

      procedure create_img(json_1: out JSON_Value) is
         --json_2: JSON_Array;
         --json_3: JSON_Value;
         --json_4: JSON_Value;
         --json_abitanti: JSON_Array;
         --json_abitante: JSON_Value;
         --list: ptr_list_posizione_abitanti_on_road;
      begin
         null;

         --begin
         --json_1:= Create_Object;
         -- creazione traiettorie ingressi
         -- "set_traiettorie_ingressi" : [{"num_ingresso" : 1, "traiettorie" : {"entrata_andata" : [{abitante1},{abitante2},...,{abitanteN}]}},[ALTRO INGRESSO],[...]]
         --for i in set_traiettorie_ingressi'Range(1) loop
         --   json_3:= Create_Object;
         --   json_4:= Create_Object;
         --   json_3.Set_Field("num_ingresso",i);
         --   for j in set_traiettorie_ingressi'Range(2) loop
         --      list:= set_traiettorie_ingressi(i,j);
         --      json_abitanti:= Empty_Array;
         --      while list/=null loop
         --         json_abitante:= create_img_abitante(list.posizione_abitante,-1.0);
         --         Append(json_abitanti,json_abitante);
         --         list:= list.next;
         --      end loop;
         --      json_4.Set_Field(to_string_ingressi_type(j),json_abitanti);
         --   end loop;
         --   json_3.Set_Field("traiettorie",json_4);
         --   Append(json_2,json_3);
         --end loop;
         --json_1.Set_Field("set_traiettorie_ingressi",json_2);
         -- end creazione traiettorie ingressi

         --json_abitanti:= Empty_Array;
         --json_2:= Empty_Array;
         -- creazione main_strada
         --json_1.Set_Field("main_strada",create_img_strada(main_strada,id_risorsa));

         -- MARCIAPIEDI IMAGE TO DO
         -- MARCIAPIEDI NUMBER ENTITY TO DO
         --json_1.Set_Field("main_strada_number_entity",create_img_num_entity_strada(main_strada_number_entity));

         -- "temp_abitanti_in_transizione": {"false": {"1":{abitante1},"2": *1o*2}, "true": [{},*1o*2]}
         --json_3:= Create_Object;
         --for i in temp_abitanti_in_transizione'Range(1) loop
         --   json_4:= Create_Object;
         --   for j in temp_abitanti_in_transizione'Range(2) loop
         --      if temp_abitanti_in_transizione(i,j).get_id_abitante_posizione_abitanti=0 then
         --         json_abitante:= Create_Object;
         --      else
         --         json_abitante:= create_img_abitante(temp_abitanti_in_transizione(i,j));
         --      end if;
         --   json_4.Set_Field(Positive'Image(j),json_abitante);
         --   end loop;
         --   if i then
         --      json_3.Set_Field("TRUE",json_4);
         --   else
         --      json_3.Set_Field("FALSE",json_4);
         --  end if;
         --end loop;
         --json_1.Set_Field("temp_abitanti_in_transizione",json_3);
         --exception
         --   when others =>
         --      Put_Line("errore nella creazione strada in: " & Positive'Image(get_id_quartiere) & " " & Positive'Image(id_risorsa));
         --      raise set_field_json_error;
         --end;
      end create_img;

      procedure recovery_resource is
         --json_resource: JSON_Value;
         --json_traiettorie_ingressi: JSON_Array;
         --json_main_strada: JSON_Value;
         --json_numer_entity: JSON_Value;
         --json_abitanti_in_transazione: JSON_Value;
         --json_1: JSON_Value;
         --json_2: JSON_Value;
         --json_abitanti: JSON_Array;
         --json_abitante: JSON_Value;
         --list: ptr_list_posizione_abitanti_on_road;
         --prec_list: ptr_list_posizione_abitanti_on_road;
      begin
         null;
         --share_snapshot_file_quartiere.get_json_value_resource_snap(id_risorsa,json_resource);

         --json_traiettorie_ingressi:= json_resource.Get("set_traiettorie_ingressi");
         --for i in 1..Length(json_traiettorie_ingressi) loop
         --   json_1:= Get(json_traiettorie_ingressi,i);
         --   json_2:= json_1.Get("traiettorie");
         --   for j in traiettoria_ingressi_type'First..traiettoria_ingressi_type'Last loop
         --      json_abitanti:= json_2.Get(to_string_ingressi_type(j));
         --      set_traiettorie_ingressi(json_1.Get("num_ingresso"),j):= create_array_abitanti(json_abitanti);
         --   end loop;
         --end loop;

         --json_main_strada:= json_resource.Get("main_strada");
         --for i in False..True loop
         --   json_1:= json_main_strada.Get(Boolean'Image(i));
         --   for j in 1..2 loop
         --      json_abitanti:= json_1.Get(Positive'Image(j));
         --      main_strada(i,j):= create_array_abitanti(json_abitanti);
         --   end loop;
         --end loop;

         --for i in False..True loop
         --   for j in 1..2 loop
         --      list:= main_strada(i,j);
         --      prec_list:= null;
         --      while list/=null loop
         --         list.prev:= prec_list;
         --         prec_list:= list;
         --         list:= list.next;
         --      end loop;
         --   end loop;
         --end loop;

         --json_numer_entity:= json_resource.Get("main_strada_number_entity");
         --for i in False..True loop
         --   json_1:= json_numer_entity.Get(Boolean'Image(i));
         --   for j in 1..2 loop
         --      main_strada_number_entity(i,j):= json_1.Get(Positive'Image(j));
         --   end loop;
         --end loop;

         --json_abitanti_in_transazione:= json_resource.Get("temp_abitanti_in_transizione");
         --for i in False..True loop
         --   json_1:= json_abitanti_in_transazione.Get(Boolean'Image(i));
         --   for j in 1..2 loop
         --      json_abitante:= json_1.Get(Positive'Image(j));
         --      if json_abitante.Has_Field("id_abitante") then
         --         temp_abitanti_in_transizione(i,j):= create_abitante_from_json(json_abitante);
         --      end if;
         --   end loop;
         --end loop;

      end recovery_resource;

      entry ingresso_wait_turno when finish_delta_urbana is
      begin
         num_ingressi_ready:=num_ingressi_ready+1;
         if num_ingressi_ready=num_ingressi then
            finish_delta_urbana:= False;
            num_ingressi_ready:= 0;
         end if;
      end ingresso_wait_turno;

      procedure delta_terminate is
      begin
         --Put_Line("finish wait " & Positive'Image(id_risorsa) & " id quartiere " & Positive'Image(get_id_quartiere));
         finish_delta_urbana:= True;
      end delta_terminate;

      function get_num_estremi_urbana return Positive is
      begin
         if array_estremi_strada_urbana(2)=null then
            return 1;
         else
            return 2;
         end if;
      end get_num_estremi_urbana;

      function slide_list(range_1: Boolean; range_2: id_corsie; index_to_slide: Natural) return ptr_list_posizione_abitanti_on_road is
         list: ptr_list_posizione_abitanti_on_road:= main_strada(range_1,range_2);
      begin
         for i in 1..main_strada_number_entity(range_1,range_2) loop
            if i=index_to_slide then
               return list;
            end if;
            list:= list.next;
         end loop;
         return null;
      end slide_list;

      entry wait_incroci when get_num_estremi_urbana=num_delta_incroci_finished is
      begin
         num_delta_incroci_finished:= 0;
      end wait_incroci;

      procedure delta_incrocio_finished is
      begin
         num_delta_incroci_finished:= num_delta_incroci_finished+1;
      end delta_incrocio_finished;

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
         for i in 1..num_ingressi_polo_true loop
            ordered_ingressi_polo(True)(num_ingressi_polo_true-i+1):= list.id_ingresso;
            list:= list.next;
         end loop;

      end configure;

      procedure set_estremi_urbana(estremi: estremi_resource_strada_urbana) is
      begin
         array_estremi_strada_urbana:= estremi;
      end set_estremi_urbana;

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
            place_abitante:= posizione_abitanti_on_road(create_new_posizione_abitante(id_abitante,id_quartiere_abitante,0.0,0.0,0.0,False,False,0.0,True,traiettoria_on_main_strada,traiettoria_on_main_strada.get_corsia_to_go_trajectory));
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
            -- ora che è stata aggiunta una nuova entità è necessario impostare a 0 l'avanzamento
            get_ingressi_segmento_resources(id_ingresso).update_avanzamento_car_in_urbana(move_parameters(get_quartiere_utilities_obj.all.get_auto_quartiere(new_abitante_to_add.posizione_abitante.get_id_quartiere_posizione_abitanti,new_abitante_to_add.posizione_abitante.get_id_abitante_posizione_abitanti)).get_length_entità_passiva);
         end if;
      end aggiungi_entità_from_ingresso;

      procedure set_move_parameters_entity_on_traiettoria_ingresso(abitante: ptr_list_posizione_abitanti_on_road; index_ingresso: Positive; traiettoria: traiettoria_ingressi_type; polo_to_go: Boolean; speed: new_float; step: new_float; step_is_just_calculated: Boolean:= False) is
         key: Natural:= get_key_ingresso(index_ingresso,not_ordered);
      begin
         if speed>0.0 then
            abitante.posizione_abitante.set_current_speed_abitante(speed);
         end if;
         if step>0.0 then
            if step_is_just_calculated then
               abitante.posizione_abitante.set_where_next_abitante(step);
            else
               if abitante.posizione_abitante.get_where_now_posizione_abitanti+step>get_traiettoria_ingresso(traiettoria).get_lunghezza and then ((traiettoria=uscita_andata or traiettoria=uscita_ritorno) and then
                                                                                                                                                  get_distance_from_polo_percorrenza(get_ingresso_from_id(index_ingresso),polo_to_go)+get_larghezza_marciapiede+get_larghezza_corsia+abitante.posizione_abitante.get_where_now_posizione_abitanti-get_traiettoria_ingresso(traiettoria).get_lunghezza>risorsa_features.get_lunghezza_road) then -- cioè se l'abitante rischia di andare oltre la lunghezza della strada
                  abitante.posizione_abitante.set_where_next_abitante(risorsa_features.get_lunghezza_road);
               else
                  abitante.posizione_abitante.set_where_next_abitante(abitante.posizione_abitante.get_where_now_posizione_abitanti+step);
               end if;
            end if;
         end if;
      end set_move_parameters_entity_on_traiettoria_ingresso;

      procedure set_move_parameters_entity_on_main_road(current_car_in_corsia: in out ptr_list_posizione_abitanti_on_road; polo: Boolean; num_corsia: id_corsie; speed: new_float; step: new_float; step_is_just_calculated: Boolean:= False) is
         distance: new_float;
      begin
         if speed>0.0 then
            current_car_in_corsia.posizione_abitante.set_current_speed_abitante(speed);
         end if;

         if step>0.0 then
            if current_car_in_corsia.posizione_abitante.get_in_overtaken then
               if step_is_just_calculated then
                  current_car_in_corsia.posizione_abitante.set_distance_on_overtaking_trajectory(step);
               else
                  current_car_in_corsia.posizione_abitante.set_distance_on_overtaking_trajectory(current_car_in_corsia.posizione_abitante.get_distance_on_overtaking_trajectory+step);
               end if;
               --if current_car_in_corsia.posizione_abitante.get_distance_on_overtaking_trajectory>=get_traiettoria_cambio_corsia.get_lunghezza_traiettoria then
               --   new_step:= current_car_in_corsia.posizione_abitante.get_distance_on_overtaking_trajectory-get_traiettoria_cambio_corsia.get_lunghezza_traiettoria;
               --   current_car_in_corsia.posizione_abitante.set_where_next_abitante(current_car_in_corsia.posizione_abitante.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_traiettoria+new_step);
               --end if;
            else
               if current_car_in_corsia.posizione_abitante.get_destination.get_traiettoria_incrocio_to_follow/=empty then
                  current_car_in_corsia.posizione_abitante.set_where_next_abitante(current_car_in_corsia.posizione_abitante.get_where_now_posizione_abitanti+step);
               else
                  distance:= get_distance_from_polo_percorrenza(get_ingresso_from_id(current_car_in_corsia.posizione_abitante.get_destination.get_ingresso_to_go_trajectory),polo)-get_larghezza_marciapiede-get_larghezza_corsia;
                  if current_car_in_corsia.posizione_abitante.get_where_now_posizione_abitanti+step>distance then
                     current_car_in_corsia.posizione_abitante.set_where_next_abitante(distance);
                  else
                     current_car_in_corsia.posizione_abitante.set_where_next_abitante(current_car_in_corsia.posizione_abitante.get_where_now_posizione_abitanti+step);
                  end if;
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

      procedure update_traiettorie_ingressi(state_view_abitanti: in out JSON_Array) is
         list: ptr_list_posizione_abitanti_on_road;
         list_macchine_in_strada: ptr_list_posizione_abitanti_on_road;
         prec_list_macchine_in_strada: ptr_list_posizione_abitanti_on_road;
         new_abitante: ptr_list_posizione_abitanti_on_road;
         list_altra_uscita: ptr_list_posizione_abitanti_on_road;
         abitante: posizione_abitanti_on_road;
         polo: Boolean:= True;
         consider_polo: Boolean;
         in_uscita: Boolean;
         --ingressi_structure_type: ingressi_type;
         key_ingresso: Positive;
         length_traiettoria: new_float;
         length_car: new_float;
         num_corsia: id_corsie;
         departure_distance: new_float;
         state_view_abitante: JSON_Value;
         bound_overtaken: new_float;

         ab: posizione_abitanti_on_road;

         main_list: ptr_list_posizione_abitanti_on_road;
         fine_ingresso_distance: new_float;
         car_length: new_float;
      begin
         for i in 1..2 loop
            polo:= not polo;
            for i in ordered_ingressi_polo(polo).all'Range loop
               key_ingresso:= get_key_ingresso(ordered_ingressi_polo(polo)(i),not_ordered);
               for traiettoria in traiettoria_ingressi_type'Range loop
                  if traiettoria/=empty then
                     -- traiettoria uscita_andata
                     list:= set_traiettorie_ingressi(key_ingresso,traiettoria);
                     if list/=null and then list.next/=null then
                        state_view_abitante:= create_car_traiettoria_ingresso_state(list.next.posizione_abitante.get_id_quartiere_posizione_abitanti,list.next.posizione_abitante.get_id_abitante_posizione_abitanti,get_id_quartiere,id_risorsa,Float(list.next.posizione_abitante.get_where_now_posizione_abitanti),polo,Float(get_ingresso_from_id(ordered_ingressi_polo(polo)(i)).get_distance_from_road_head_ingresso),traiettoria);
                        Append(state_view_abitanti,state_view_abitante);
                     end if;
                     if traiettoria=uscita_andata then
                        in_uscita:= True;
                        num_corsia:= 2;
                        consider_polo:= polo;
                     elsif traiettoria=uscita_ritorno then
                        in_uscita:= True;
                        num_corsia:= 1;
                        consider_polo:= not polo;
                     elsif traiettoria=entrata_andata then
                        in_uscita:= False;
                     else -- entrata_ritorno
                        in_uscita:= False;
                     end if;
                     length_traiettoria:= get_traiettoria_ingresso(traiettoria).get_lunghezza;
                     if in_uscita and (list/=null and then list.posizione_abitante.get_where_now_posizione_abitanti<length_traiettoria) then
                        list.posizione_abitante.set_where_now_abitante(list.posizione_abitante.get_where_next_posizione_abitanti);
                        --if list.posizione_abitante.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(list.posizione_abitante.get_id_quartiere_posizione_abitanti,
                        -- AGGIORNAMENTO POSIZIONE MACCHINA SSE NON È ARRIVATA ALTRA MACCHINA IN LISTA
                        length_car:= move_parameters(get_quartiere_utilities_obj.all.get_auto_quartiere(list.posizione_abitante.get_id_quartiere_posizione_abitanti,list.posizione_abitante.get_id_abitante_posizione_abitanti)).get_length_entità_passiva;
                        if list.next=null then
                           --if get_ingressi_segmento_resources(ordered_ingressi_polo(polo)(i)).get_car_avanzamento<=length_car then
                           if length_car-list.posizione_abitante.get_where_now_posizione_abitanti>0.0 then
                              get_ingressi_segmento_resources(ordered_ingressi_polo(polo)(i)).update_avanzamento_car_in_urbana(length_car-list.posizione_abitante.get_where_now_posizione_abitanti);
                           else
                              if traiettoria=uscita_ritorno then
                                 list_altra_uscita:= set_traiettorie_ingressi(key_ingresso,uscita_andata);
                              else
                                 list_altra_uscita:= set_traiettorie_ingressi(key_ingresso,uscita_ritorno);
                              end if;
                              if list_altra_uscita=null then
                                 get_ingressi_segmento_resources(ordered_ingressi_polo(polo)(i)).update_avanzamento_car_in_urbana(0.0);
                              elsif list_altra_uscita.posizione_abitante.get_where_now_posizione_abitanti-move_parameters(get_quartiere_utilities_obj.all.get_auto_quartiere(list_altra_uscita.posizione_abitante.get_id_quartiere_posizione_abitanti,list_altra_uscita.posizione_abitante.get_id_abitante_posizione_abitanti)).get_length_entità_passiva>=0.0 then
                                 get_ingressi_segmento_resources(ordered_ingressi_polo(polo)(i)).update_avanzamento_car_in_urbana(0.0);
                              end if;
                           end if;
                        end if;
                        if list.posizione_abitante.get_where_now_posizione_abitanti>=length_traiettoria then
                           list_macchine_in_strada:= main_strada(consider_polo,num_corsia);
                           prec_list_macchine_in_strada:= null;

                           departure_distance:= get_distance_from_polo_percorrenza(get_ingresso_from_id(ordered_ingressi_polo(polo)(i)),consider_polo);

                           abitante:= create_new_posizione_abitante_from_copy(list.posizione_abitante);
                           abitante.set_where_next_abitante(list.posizione_abitante.get_where_now_posizione_abitanti-length_traiettoria+departure_distance+get_larghezza_marciapiede+get_larghezza_corsia);  -- 5.0 lunghezza traiettoria
                           abitante.set_where_now_abitante(abitante.get_where_next_posizione_abitanti);
                           abitante.set_came_from_ingresso(True);  --  set flag to True
                           if abitante.get_id_abitante_posizione_abitanti=77 then
                              prec_list_macchine_in_strada:= null;
                           end if;
                           while list_macchine_in_strada/=null and then list_macchine_in_strada.posizione_abitante.get_where_now_posizione_abitanti<abitante.get_where_now_posizione_abitanti loop
                              prec_list_macchine_in_strada:= list_macchine_in_strada;
                              ab:= prec_list_macchine_in_strada.posizione_abitante;
                              list_macchine_in_strada:= list_macchine_in_strada.next;
                           end loop;
                           new_abitante:= create_new_list_posizione_abitante(abitante,list_macchine_in_strada);
                           bound_overtaken:= calculate_bound_to_overtake(new_abitante,consider_polo,id_risorsa);
                           if bound_overtaken<0.0 then
                              new_abitante.posizione_abitante.set_where_now_abitante(new_abitante.posizione_abitante.get_where_now_posizione_abitanti+bound_overtaken);
                              new_abitante.posizione_abitante.set_where_next_abitante(new_abitante.posizione_abitante.get_where_now_posizione_abitanti);
                           end if;
                           if list_macchine_in_strada/=null then
                              list_macchine_in_strada.prev:= new_abitante;
                           end if;
                           new_abitante.prev:= prec_list_macchine_in_strada;
                           if prec_list_macchine_in_strada=null then
                              main_strada(consider_polo,num_corsia):= new_abitante;
                           else
                              prec_list_macchine_in_strada.next:= new_abitante;
                           end if;
                           main_strada_number_entity(consider_polo,num_corsia):= main_strada_number_entity(consider_polo,num_corsia)+1;
                           list.posizione_abitante.set_where_now_abitante(new_float'Last);
                        else
                           state_view_abitante:= create_car_traiettoria_ingresso_state(list.posizione_abitante.get_id_quartiere_posizione_abitanti,list.posizione_abitante.get_id_abitante_posizione_abitanti,get_id_quartiere,id_risorsa,Float(list.posizione_abitante.get_where_now_posizione_abitanti),polo,Float(get_ingresso_from_id(ordered_ingressi_polo(polo)(i)).get_distance_from_road_head_ingresso),traiettoria);
                           Append(state_view_abitanti,state_view_abitante);
                        end if;
                     elsif in_uscita=False then
                        if list/=null then
                           if list.posizione_abitante.get_where_now_posizione_abitanti<length_traiettoria then
                              list.posizione_abitante.set_where_now_abitante(list.posizione_abitante.get_where_next_posizione_abitanti);
                              if list.posizione_abitante.get_where_now_posizione_abitanti>=length_traiettoria then
                                 get_ingressi_segmento_resources(ordered_ingressi_polo(polo)(i)).new_abitante_finish_route(list.posizione_abitante);
                                 list.posizione_abitante.set_where_now_abitante(new_float'Last);
                              else
                                 state_view_abitante:= create_car_traiettoria_ingresso_state(list.posizione_abitante.get_id_quartiere_posizione_abitanti,list.posizione_abitante.get_id_abitante_posizione_abitanti,get_id_quartiere,id_risorsa,Float(list.posizione_abitante.get_where_now_posizione_abitanti),polo,Float(get_ingresso_from_id(ordered_ingressi_polo(polo)(i)).get_distance_from_road_head_ingresso),traiettoria);
                                 Append(state_view_abitanti,state_view_abitante);
                              end if;
                           end if;
                        end if;
                     end if;
                  end if;
               end loop;
            end loop;
         end loop;

         for i in main_strada'Range(1) loop
            for j in main_strada'Range(2) loop
               main_list:= main_strada(i,j);
               while main_list/=null loop
                  if main_list.posizione_abitante.get_came_from_ingresso then
                     -- se l'abitante sorpassa subito una volta uscito dall'ingresso
                     car_length:= get_quartiere_utilities_obj.get_auto_quartiere(main_list.posizione_abitante.get_id_quartiere_posizione_abitanti,main_list.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva;

                     fine_ingresso_distance:= get_distance_from_polo_percorrenza(get_ingresso_from_id(main_list.posizione_abitante.get_destination.get_from_ingresso),i)+get_larghezza_marciapiede+get_larghezza_corsia;

                     if (main_list.posizione_abitante.get_in_overtaken and then main_list.posizione_abitante.get_where_now_posizione_abitanti+main_list.posizione_abitante.get_distance_on_overtaking_trajectory-car_length>=fine_ingresso_distance) or else
                       (main_list.posizione_abitante.get_where_now_posizione_abitanti-car_length>=fine_ingresso_distance) then
                        main_list.posizione_abitante.set_came_from_ingresso(False);
                        -- lo state_view_abitante al + viene costruito nell'else ****
                        if main_list.posizione_abitante.get_destination.get_departure_corsia=2 then
                           set_traiettorie_ingressi(get_key_ingresso(main_list.posizione_abitante.get_destination.get_from_ingresso,not_ordered),uscita_andata):= set_traiettorie_ingressi(get_key_ingresso(main_list.posizione_abitante.get_destination.get_from_ingresso,not_ordered),uscita_andata).next;
                        else
                           --Put_Line("Delete " & Positive'Image(get_id_quartiere) & " ingresso " & Natural'Image(main_list.posizione_abitante.get_destination.get_from_ingresso) & " id abitante " & Positive'Image(main_list.posizione_abitante.get_id_abitante_posizione_abitanti));
                           set_traiettorie_ingressi(get_key_ingresso(main_list.posizione_abitante.get_destination.get_from_ingresso,not_ordered),uscita_ritorno):= set_traiettorie_ingressi(get_key_ingresso(main_list.posizione_abitante.get_destination.get_from_ingresso,not_ordered),uscita_ritorno).next;
                        end if;
                     end if;
                  end if;
                  main_list:= main_list.next;
               end loop;
            end loop;
         end loop;
      end update_traiettorie_ingressi;

      procedure update_car_on_road(state_view_abitanti: in out JSON_Array) is
         main_list: ptr_list_posizione_abitanti_on_road;
         prec_main_list: ptr_list_posizione_abitanti_on_road;
         other_list: ptr_list_posizione_abitanti_on_road;
         prec_other_list: ptr_list_posizione_abitanti_on_road;
         next_element_list: ptr_list_posizione_abitanti_on_road;
         other_corsia: id_corsie;
         traiettoria: traiettoria_ingressi_type;
         list_abitanti_traiettoria: ptr_list_posizione_abitanti_on_road;
         prec_list_abitanti_traiettoria: ptr_list_posizione_abitanti_on_road;
         car_length: new_float;
         fine_ingresso_distance: new_float;
         state_view_abitante: JSON_Value;
         distance_ingresso: new_float;
         flag_overtake_next_corsia: Boolean;
         ab: posizione_abitanti_on_road;
         polo_ingresso: Boolean;
         log_str: Unbounded_String;
      begin
         for i in main_strada'Range(1) loop
            for j in main_strada'Range(2) loop
               main_list:= main_strada(i,j);
               prec_main_list:= null;
               next_element_list:= null;
               while main_list/=null loop
                  main_list.posizione_abitante.set_where_now_abitante(main_list.posizione_abitante.get_where_next_posizione_abitanti);
                  if main_list.posizione_abitante.get_came_from_ingresso then
                     -- se l'abitante sorpassa subito una volta uscito dall'ingresso
                     car_length:= get_quartiere_utilities_obj.get_auto_quartiere(main_list.posizione_abitante.get_id_quartiere_posizione_abitanti,main_list.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva;

                     fine_ingresso_distance:= get_distance_from_polo_percorrenza(get_ingresso_from_id(main_list.posizione_abitante.get_destination.get_from_ingresso),i)+get_larghezza_marciapiede+get_larghezza_corsia;

                     if (main_list.posizione_abitante.get_in_overtaken and then main_list.posizione_abitante.get_where_now_posizione_abitanti+main_list.posizione_abitante.get_distance_on_overtaking_trajectory-car_length>=fine_ingresso_distance) or else
                       (main_list.posizione_abitante.get_where_now_posizione_abitanti-car_length>=fine_ingresso_distance) then
                        main_list.posizione_abitante.set_came_from_ingresso(False);
                        -- lo state_view_abitante al + viene costruito nell'else ****
                        if main_list.posizione_abitante.get_destination.get_departure_corsia=2 then
                           set_traiettorie_ingressi(get_key_ingresso(main_list.posizione_abitante.get_destination.get_from_ingresso,not_ordered),uscita_andata):= set_traiettorie_ingressi(get_key_ingresso(main_list.posizione_abitante.get_destination.get_from_ingresso,not_ordered),uscita_andata).next;
                        else
                           --Put_Line("Delete " & Positive'Image(get_id_quartiere) & " ingresso " & Natural'Image(main_list.posizione_abitante.get_destination.get_from_ingresso) & " id abitante " & Positive'Image(main_list.posizione_abitante.get_id_abitante_posizione_abitanti));
                           set_traiettorie_ingressi(get_key_ingresso(main_list.posizione_abitante.get_destination.get_from_ingresso,not_ordered),uscita_ritorno):= set_traiettorie_ingressi(get_key_ingresso(main_list.posizione_abitante.get_destination.get_from_ingresso,not_ordered),uscita_ritorno).next;
                        end if;
                     end if;
                  end if;
                  flag_overtake_next_corsia:= False;
                  if main_list.posizione_abitante.get_in_overtaken then
                       --and main_list.posizione_abitante.get_flag_overtake_next_corsia then
                       -- begin togli elemento dalla lista
                     if main_list.posizione_abitante.get_flag_overtake_next_corsia then
                        -- creo intanto lo state_view anche se poi non viene usato perchè subentrato da quello per fine traiettoria sorpasso
                        state_view_abitante:= create_car_traiettoria_cambio_corsia_state(main_list.posizione_abitante.get_id_quartiere_posizione_abitanti,main_list.posizione_abitante.get_id_abitante_posizione_abitanti,get_id_quartiere,id_risorsa,Float(main_list.posizione_abitante.get_distance_on_overtaking_trajectory),
                                                                                     i,Float(main_list.posizione_abitante.get_where_now_posizione_abitanti),main_list.posizione_abitante.get_destination.get_departure_corsia,main_list.posizione_abitante.get_destination.get_corsia_to_go_trajectory);

                        flag_overtake_next_corsia:= True;
                        main_list.posizione_abitante.set_flag_overtake_next_corsia(False);  -- reset del cambio corsia
                        Put_Line("begin overtake " & Positive'Image(main_list.posizione_abitante.get_id_abitante_posizione_abitanti));

                        if prec_main_list=null then
                           main_strada(i,j):= main_strada(i,j).next;
                           if main_strada(i,j)/=null then
                              main_strada(i,j).prev:= null;
                           end if;
                           next_element_list:= main_strada(i,j);
                        else
                           prec_main_list.next:= main_list.next;
                           if main_list.next/=null then
                              main_list.next.prev:= prec_main_list;
                           end if;
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
                        if other_list/=null then
                           other_list.prev:= main_list;
                        end if;
                        main_list.prev:= prec_other_list;
                        if prec_other_list=null then
                           main_strada(i,other_corsia):= main_list;
                        else
                           prec_other_list.next:= main_list;
                        end if;
                        main_strada_number_entity(i,other_corsia):= main_strada_number_entity(i,other_corsia)+1;
                        -- prec_main_list resta invariato
                        Put_Line("end overtake " & Positive'Image(main_list.posizione_abitante.get_id_abitante_posizione_abitanti));
                     end if;
                     if main_list.posizione_abitante.get_distance_on_overtaking_trajectory>=get_traiettoria_cambio_corsia.get_lunghezza_traiettoria then -- lunghezza traiettoria sorpasso
                        main_list.posizione_abitante.set_in_overtaken(False);
                        main_list.posizione_abitante.set_where_next_abitante(main_list.posizione_abitante.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria+main_list.posizione_abitante.get_distance_on_overtaking_trajectory-get_traiettoria_cambio_corsia.get_lunghezza_traiettoria);
                        main_list.posizione_abitante.set_where_now_abitante(main_list.posizione_abitante.get_where_next_posizione_abitanti);
                        main_list.posizione_abitante.set_distance_on_overtaking_trajectory(0.0);
                        state_view_abitante:= create_car_urbana_state(main_list.posizione_abitante.get_id_quartiere_posizione_abitanti,main_list.posizione_abitante.get_id_abitante_posizione_abitanti,get_id_quartiere,id_risorsa,Float(main_list.posizione_abitante.get_where_now_posizione_abitanti),i,j);
                     else -- ****
                        state_view_abitante:= create_car_traiettoria_cambio_corsia_state(main_list.posizione_abitante.get_id_quartiere_posizione_abitanti,main_list.posizione_abitante.get_id_abitante_posizione_abitanti,get_id_quartiere,id_risorsa,Float(main_list.posizione_abitante.get_distance_on_overtaking_trajectory),
                                                                                     i,Float(main_list.posizione_abitante.get_where_now_posizione_abitanti),main_list.posizione_abitante.get_destination.get_departure_corsia,main_list.posizione_abitante.get_destination.get_corsia_to_go_trajectory);
                     end if;
                     Append(state_view_abitanti,state_view_abitante);
                     if flag_overtake_next_corsia then
                        main_list:= next_element_list;
                     else
                        prec_main_list:= main_list;
                        main_list:= main_list.next;
                     end if;
                  else
                     if main_list.posizione_abitante.get_destination.get_traiettoria_incrocio_to_follow=empty then
                        --Put_Line(Float'Image(get_distance_from_polo_percorrenza(get_ingresso_from_id(main_list.posizione_abitante.get_destination.get_ingresso_to_go_trajectory))));

                        if not i then
                           distance_ingresso:= get_ingresso_from_id(main_list.posizione_abitante.get_destination.get_ingresso_to_go_trajectory).get_distance_from_road_head_ingresso;
                        else
                           distance_ingresso:= get_urbana_from_id(id_risorsa).get_lunghezza_road-get_ingresso_from_id(main_list.posizione_abitante.get_destination.get_ingresso_to_go_trajectory).get_distance_from_road_head_ingresso;
                        end if;

                        if distance_ingresso-get_larghezza_marciapiede-get_larghezza_corsia<=main_list.posizione_abitante.get_where_now_posizione_abitanti then
                           next_element_list:= main_list.next;
                           if next_element_list/=null then
                              next_element_list.prev:= prec_main_list;
                           end if;
                           if prec_main_list/=null then  -- si ha un elemento in prec_list
                              prec_main_list.next:= next_element_list;
                           else  --  non si ha niente come elemento precedente
                              main_strada(i,j):= next_element_list;
                              --if main_strada(i,j).next/=null then
                              --   main_strada(i,j):= main_strada(i,j).next;
                              --else
                              --   main_strada(i,j):= null;
                              --end if;
                           end if;
                           main_list.posizione_abitante.set_where_next_abitante(0.0);
                           main_list.posizione_abitante.set_where_now_abitante(0.0);
                           main_list.next:= null;
                           if main_list.posizione_abitante.get_destination.get_corsia_to_go_trajectory=1 then
                              traiettoria:= entrata_ritorno;
                              polo_ingresso:= not i;
                           else
                              traiettoria:= entrata_andata;
                              polo_ingresso:= i;
                           end if;
                           list_abitanti_traiettoria:= set_traiettorie_ingressi(get_key_ingresso(main_list.posizione_abitante.get_destination.get_ingresso_to_go_trajectory,not_ordered),traiettoria);
                           -- update view state
                           state_view_abitante:= create_car_traiettoria_ingresso_state(main_list.posizione_abitante.get_id_quartiere_posizione_abitanti,main_list.posizione_abitante.get_id_abitante_posizione_abitanti,get_id_quartiere,id_risorsa,Float(main_list.posizione_abitante.get_where_now_posizione_abitanti),polo_ingresso,Float(get_ingresso_from_id(main_list.posizione_abitante.get_destination.get_ingresso_to_go_trajectory).get_distance_from_road_head_ingresso),traiettoria);
                           Append(state_view_abitanti,state_view_abitante);
                           -- end update
                           prec_list_abitanti_traiettoria:= null;
                           while list_abitanti_traiettoria/=null loop
                              prec_list_abitanti_traiettoria:= list_abitanti_traiettoria;
                              ab:= prec_list_abitanti_traiettoria.posizione_abitante;
                              list_abitanti_traiettoria:= list_abitanti_traiettoria.next;
                           end loop;
                           if prec_list_abitanti_traiettoria=null then
                              set_traiettorie_ingressi(get_key_ingresso(main_list.posizione_abitante.get_destination.get_ingresso_to_go_trajectory,not_ordered),traiettoria):= main_list;
                           else
                              prec_list_abitanti_traiettoria.next:= main_list;
                           end if;
                           main_strada_number_entity(i,j):= main_strada_number_entity(i,j)-1;
                        else
                           if main_list.posizione_abitante.get_where_now_posizione_abitanti<get_urbana_from_id(id_risorsa).get_lunghezza_road then
                              state_view_abitante:= create_car_urbana_state(main_list.posizione_abitante.get_id_quartiere_posizione_abitanti,main_list.posizione_abitante.get_id_abitante_posizione_abitanti,get_id_quartiere,id_risorsa,Float(main_list.posizione_abitante.get_where_now_posizione_abitanti),i,j);
                              Append(state_view_abitanti,state_view_abitante);
                           end if;
                           prec_main_list:= main_list;
                           next_element_list:= main_list.next;
                        end if;
                     else  -- occorre percorrere tutta la strada
                        if main_list.posizione_abitante.get_where_now_posizione_abitanti<get_urbana_from_id(id_risorsa).get_lunghezza_road then
                          state_view_abitante:= create_car_urbana_state(main_list.posizione_abitante.get_id_quartiere_posizione_abitanti,main_list.posizione_abitante.get_id_abitante_posizione_abitanti,get_id_quartiere,id_risorsa,Float(main_list.posizione_abitante.get_where_now_posizione_abitanti),i,j);
                           Append(state_view_abitanti,state_view_abitante);
                        end if;
                        prec_main_list:= main_list;
                        next_element_list:= main_list.next;
                     end if;
                     main_list:= next_element_list;
                  end if;
               end loop;
            end loop;
         end loop;

         --for i in main_strada'Range(1) loop
         --   for j in main_strada'Range(2) loop
         --      main_list:= main_strada(i,j);
         --      Append(log_str,"id risorsa: " & Positive'Image(id_risorsa) & " polo: " & Boolean'Image(i) & " corsia: " & Positive'Image(j));
         --      while main_list/=null loop
         --         Append(log_str,"[" & Positive'Image(main_list.posizione_abitante.get_id_quartiere_posizione_abitanti) & "," & Positive'Image(main_list.posizione_abitante.get_id_abitante_posizione_abitanti) & "],");
         --         main_list:= main_list.next;
         --      end loop;
         --   end loop;
         --end loop;

         --log.write(To_String(log_str));

         -- controllo di possibili errori
         for i in main_strada'Range(1) loop
            for j in main_strada'Range(2) loop
               main_list:= main_strada(i,j);
               while main_list/=null loop
                  if main_list.next/=null then
                     if main_list.posizione_abitante.get_where_now_posizione_abitanti>main_list.next.posizione_abitante.get_where_now_posizione_abitanti then
                        Put_Line("Errore distanze: " & Positive'Image(main_list.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(main_list.posizione_abitante.get_id_abitante_posizione_abitanti) & " > " & Positive'Image(main_list.next.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(main_list.next.posizione_abitante.get_id_abitante_posizione_abitanti) & " distanze " & new_float'Image(main_list.posizione_abitante.get_where_now_posizione_abitanti) & " > " & new_float'Image(main_list.next.posizione_abitante.get_where_now_posizione_abitanti));
                        raise distanza_next_abitante_minore;
                     end if;
                  end if;
                  main_list:= main_list.next;
               end loop;
            end loop;
         end loop;
      end update_car_on_road;


      procedure remove_first_element_traiettoria(index_ingresso: Positive; traiettoria: traiettoria_ingressi_type) is
         key_ingresso: Positive:= get_key_ingresso(index_ingresso,not_ordered);
      begin
         set_traiettorie_ingressi(key_ingresso,traiettoria):= set_traiettorie_ingressi(key_ingresso,traiettoria).next;
      end remove_first_element_traiettoria;

      procedure insert_abitante_from_incrocio(abitante: posizione_abitanti_on_road; polo: Boolean; num_corsia: id_corsie) is
      begin
         temp_abitanti_in_transizione(polo,num_corsia):= abitante;
      end insert_abitante_from_incrocio;

      procedure sposta_abitanti_in_transizione_da_incroci is
         list: ptr_list_posizione_abitanti_on_road;
         new_abitante: ptr_list_posizione_abitanti_on_road;
      begin
         -- per capire se effettivamente è stato spostato qualche abitante dall'incrocio
         -- si guarda se departure corsia /=0
         for polo in Boolean'Range loop
            for num_corsia in id_corsie'Range loop
               if temp_abitanti_in_transizione(polo,num_corsia).get_destination.get_departure_corsia/=0 then
                  new_abitante:= new list_posizione_abitanti_on_road;
                  list:= main_strada(polo,num_corsia);
                  new_abitante.posizione_abitante:= temp_abitanti_in_transizione(polo,num_corsia);
                  new_abitante.next:= list;
                  if list/=null then
                     list.prev:= new_abitante;
                  end if;
                  main_strada(polo,num_corsia):= new_abitante;
                  main_strada_number_entity(polo,num_corsia):= main_strada_number_entity(polo,num_corsia)+1;
                  temp_abitanti_in_transizione(polo,num_corsia).set_destination(create_trajectory_to_follow(0,0,0,0,empty));
               end if;
            end loop;
         end loop;
      end sposta_abitanti_in_transizione_da_incroci;

      function get_abitante_in_transizione_da_incrocio(polo: Boolean; corsia: id_corsie) return posizione_abitanti_on_road is
      begin
         return temp_abitanti_in_transizione(polo,corsia);
      end get_abitante_in_transizione_da_incrocio;

      procedure azzera_spostamento_abitanti_in_incroci is
         pragma Warnings(off);
         default_abitante: posizione_abitanti_on_road;
         pragma Warnings(on);
      begin
         for polo in Boolean'Range loop
            for num_corsia in id_corsie'Range loop
               temp_abitanti_in_transizione(polo,num_corsia):= default_abitante;
               temp_abitanti_in_transizione(polo,num_corsia).set_destination(create_trajectory_to_follow(0,0,0,0,empty));
            end loop;
         end loop;
      end azzera_spostamento_abitanti_in_incroci;

      procedure remove_abitante_in_incrocio(polo: Boolean; num_corsia: id_corsie; id_quartiere: Positive; id_abitante: Positive) is
         list: ptr_list_posizione_abitanti_on_road:= main_strada(polo,num_corsia);
         prec_prec_list: ptr_list_posizione_abitanti_on_road:= null;
         prec_list: ptr_list_posizione_abitanti_on_road:= null;
         ab: posizione_abitanti_on_road;
      begin
         while list/=null loop --and then list.next/=null loop
            prec_prec_list:= prec_list;
            prec_list:= list;
            ab:= posizione_abitanti_on_road(list.posizione_abitante);
            list:= list.next;
         end loop;
         if prec_prec_list/=null then
            prec_list.prev:= null;
            ab:= posizione_abitanti_on_road(prec_list.posizione_abitante);
            if ab.get_id_abitante_posizione_abitanti/=id_abitante or ab.get_id_quartiere_posizione_abitanti/=id_quartiere then
               Put_Line("RIMOSSO ABITANTE SBAGLIATO; abitante corretto: " & Positive'Image(id_quartiere) & Positive'Image(id_abitante) & " abitante rimosso: " & Positive'Image(ab.get_id_quartiere_posizione_abitanti) & Positive'Image(ab.get_id_abitante_posizione_abitanti));
               raise deleted_wrong_abitante;
            end if;
            Put_Line("remove ab id quartiere " & Positive'Image(ab.get_id_quartiere_posizione_abitanti) & " id abitante " & Positive'Image(ab.get_id_abitante_posizione_abitanti));
            prec_prec_list.next:= null;
            ab:= posizione_abitanti_on_road(prec_prec_list.posizione_abitante);
         else
            if main_strada(polo,num_corsia).posizione_abitante.get_id_abitante_posizione_abitanti/=id_abitante or main_strada(polo,num_corsia).posizione_abitante.get_id_quartiere_posizione_abitanti/=id_quartiere then
               Put_Line("RIMOSSO ABITANTE SBAGLIATO; abitante corretto: " & Positive'Image(id_quartiere) & Positive'Image(id_abitante) & " abitante rimosso: " & Positive'Image(main_strada(polo,num_corsia).posizione_abitante.get_id_quartiere_posizione_abitanti) & Positive'Image(main_strada(polo,num_corsia).posizione_abitante.get_id_abitante_posizione_abitanti));
               raise deleted_wrong_abitante;
            end if;
            Put_Line("remove ab id quartiere " & Positive'Image(main_strada(polo,num_corsia).posizione_abitante.get_id_quartiere_posizione_abitanti) & " id abitante " & Positive'Image(main_strada(polo,num_corsia).posizione_abitante.get_id_abitante_posizione_abitanti));
            main_strada(polo,num_corsia):= null;
         end if;
         main_strada_number_entity(polo,num_corsia):= main_strada_number_entity(polo,num_corsia)-1;
      end remove_abitante_in_incrocio;

      procedure update_abitante_destination(abitante: in out ptr_list_posizione_abitanti_on_road; destination: trajectory_to_follow) is
      begin
         abitante.posizione_abitante.set_destination(destination);
      end update_abitante_destination;

      function get_key_ingresso(ingresso: Positive; ingressi_structure_type: ingressi_type) return Natural is
      begin
         for i in 1..num_ingressi loop
            if index_ingressi(i)=ingresso then
               return i;
            end if;
         end loop;
         return 0;
      end get_key_ingresso;

      function get_abitante_from_ingresso(index_ingresso: Positive; traiettoria: traiettoria_ingressi_type) return ptr_list_posizione_abitanti_on_road is
      begin
         return set_traiettorie_ingressi(get_key_ingresso(index_ingresso,not_ordered),traiettoria);
      end get_abitante_from_ingresso;

      function get_ordered_ingressi_from_polo(polo: Boolean) return ptr_indici_ingressi is
      begin
         return ordered_ingressi_polo(polo);
      end get_ordered_ingressi_from_polo;

      -- METODO USATO PER CAPIRE SE PER MACCHINE CHE SONO IN DIREZIONE uscita_andata
      -- HANNO INGRESSI CON MACCHINE IN SVOLTA CHE INTERSECANO CON LA TRAIETTORIA uscita_andata
      function is_index_ingresso_in_svolta(ingresso: Positive; traiettoria: traiettoria_ingressi_type) return Boolean is
         abitante: ptr_list_posizione_abitanti_on_road;
      begin
         -- cambia da traiettoria a traiettoria
         abitante:= get_abitante_from_ingresso(ingresso,traiettoria);
         if abitante=null then
            return False;
         end if;
         case traiettoria is
            when uscita_andata =>
               if abitante.posizione_abitante.get_where_next_posizione_abitanti>0.0 then
                  return True;
               else
                  return False;
               end if;
            when uscita_ritorno =>
               if abitante.posizione_abitante.get_where_now_posizione_abitanti<=get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                  return True;
               elsif abitante.posizione_abitante.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(abitante.posizione_abitante.get_id_quartiere_posizione_abitanti,abitante.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                 get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                  return True;
               else
                  return False;
               end if;
            when entrata_andata =>
               return True;
            when entrata_ritorno =>
               if abitante.posizione_abitante.get_where_now_posizione_abitanti>=
                 get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                  return True;
               else
                  return False;
               end if;
            when empty =>
               return False;
            when others =>
               return False;
         end case;
      end is_index_ingresso_in_svolta;

      function get_index_ingresso_from_key(key: Positive; ingressi_structure_type: ingressi_type) return Natural is
         index: Natural:= 0;
      begin
         case ingressi_structure_type is
            when not_ordered =>
               if key>=index_ingressi'First and key<=index_ingressi'Last then
                  return index_ingressi(key);
               end if;
            when ordered_polo_true =>
               if key>=ordered_ingressi_polo(True).all'First and key<=ordered_ingressi_polo(True).all'Last then
                  return ordered_ingressi_polo(True)(key);
               end if;
            when ordered_polo_false =>
               if key>=ordered_ingressi_polo(False).all'First and key<=ordered_ingressi_polo(False).all'Last then
                  return ordered_ingressi_polo(False)(key);
               end if;
         end case;
         return index;
      end get_index_ingresso_from_key;

      function get_ingressi_ordered_by_distance return indici_ingressi is
      begin
         return index_ingressi;
      end get_ingressi_ordered_by_distance;

      function get_next_abitante_on_road(from_distance: new_float; range_1: Boolean; range_2: id_corsie; from_ingresso: Boolean:= True) return ptr_list_posizione_abitanti_on_road is
         current_list: ptr_list_posizione_abitanti_on_road:= main_strada(range_1,range_2);
         opposite_list: ptr_list_posizione_abitanti_on_road;
         opposite_index: id_corsie;
         list: ptr_list_posizione_abitanti_on_road;
         switch: Boolean;
         move_entity: move_parameters;
         costante_additiva: new_float;
      begin
         if from_ingresso then
            costante_additiva:= get_larghezza_marciapiede+get_larghezza_corsia;
         else
            costante_additiva:= 0.0;
         end if;

         if range_2=1 then
            opposite_index:= 2;
         else
            opposite_index:= 1;
         end if;
         opposite_list:= main_strada(range_1,opposite_index);

         switch:= True;
         list:= current_list;
         while switch and list/=null loop
            move_entity:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
            if list.posizione_abitante.get_where_now_posizione_abitanti-move_entity.get_length_entità_passiva>=from_distance+costante_additiva then
               switch:= False;
               current_list:= list;
            end if;
            list:= list.next;
         end loop;
         if switch then
            current_list:= null;
         end if;

         switch:= True;
         list:= opposite_list;
         while switch and list/=null loop
            if list.posizione_abitante.get_where_now_posizione_abitanti>=from_distance+costante_additiva and then list.posizione_abitante.get_in_overtaken then
               if list.posizione_abitante.get_destination.get_corsia_to_go_trajectory=opposite_index then  -- l'abitante è in sorpasso verso la corsia opposta a quella in cui deve correre *list
                  if list.posizione_abitante.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(list.posizione_abitante.get_id_quartiere_posizione_abitanti,list.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva<get_traiettoria_cambio_corsia.get_lunghezza_traiettoria/2.0 then
                     switch:= False;
                     opposite_list:= list;
                  end if;
               else -- sai che l'abitante nella corsia opposta vuole sorpassare
                  -- dopo ottimizzazione:
                  switch:= False;
                  opposite_list:= list;
                  -- end dopo ottimizzazione
                  -- prima dell'ottimizzazione dei sorpassi:
                  	--if list.posizione_abitante.get_distance_on_overtaking_trajectory=get_traiettoria_cambio_corsia.get_lunghezza_traiettoria/2.0 then
                  	--   switch:= False;
                  	--   opposite_list:= list;
                   	--end if;
                   -- end
               end if;
            end if;
            list:= list.next;
         end loop;
         if switch then
            opposite_list:= null;
         end if;

         if opposite_list/=null then
            if current_list/=null then
               if opposite_list.posizione_abitante.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria/2.0<current_list.posizione_abitante.get_where_now_posizione_abitanti then
                  return opposite_list;
               else
                  return current_list;
               end if;
            else
               return opposite_list;
            end if;
         end if;
         return current_list;
      end get_next_abitante_on_road;

      -- num_corsia_to_check must be 1 or 2
      -- 2 corsie incontrate per entrata_ritorno e 2 per uscita ritorno
      function can_abitante_continue_move(distance: new_float; num_corsia_to_check: Positive; traiettoria: traiettoria_ingressi_type; polo_ingresso: Boolean; abitante_altra_traiettoria: ptr_list_posizione_abitanti_on_road:= null) return Boolean is
         list: ptr_list_posizione_abitanti_on_road;
         prec_list: ptr_list_posizione_abitanti_on_road:= null;
         move_entity: move_parameters;
         opposite_corsia: id_corsie;
         ab: posizione_abitanti_on_road;
         costante: new_float;
         altro_ab: ptr_list_posizione_abitanti_on_road:= abitante_altra_traiettoria;
         switch: Boolean;
      begin
         if traiettoria=entrata_ritorno then
            if num_corsia_to_check=1 then
               opposite_corsia:= 2;
            else
               opposite_corsia:= 1;
            end if;

            -- controlla nella lista opposta se si hanno macchine in sorpasso
            if num_corsia_to_check=1 then
               list:= main_strada(polo_ingresso,opposite_corsia);
               while list/=null loop
                  if list.posizione_abitante.get_in_overtaken and list.posizione_abitante.get_destination.get_corsia_to_go_trajectory=num_corsia_to_check then
                     if list.posizione_abitante.get_distance_on_overtaking_trajectory>=get_traiettoria_cambio_corsia.get_lunghezza_traiettoria then
                        costante:= list.posizione_abitante.get_distance_on_overtaking_trajectory-get_traiettoria_cambio_corsia.get_lunghezza_traiettoria+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                     else
                        costante:= get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                     end if;
                     if list.posizione_abitante.get_where_now_posizione_abitanti+costante>=distance-(get_larghezza_marciapiede+get_larghezza_corsia)*3.0 and
                       list.posizione_abitante.get_where_now_posizione_abitanti<distance then
                        return False;
                     else
                        if (list.posizione_abitante.get_where_now_posizione_abitanti>=distance and list.posizione_abitante.get_where_now_posizione_abitanti<=distance+move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list.posizione_abitante.get_id_quartiere_posizione_abitanti,list.posizione_abitante.get_id_abitante_posizione_abitanti)).get_length_entità_passiva) and (list.posizione_abitante.get_distance_on_overtaking_trajectory<move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list.posizione_abitante.get_id_quartiere_posizione_abitanti,list.posizione_abitante.get_id_abitante_posizione_abitanti)).get_length_entità_passiva) then
                           return False;
                        end if;
                     end if;
                  else
                     -- l'abitante se in sorpasso sta andando verso la corsia opposite_corsia
                     if list.posizione_abitante.get_in_overtaken then
                        if list.posizione_abitante.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria/2.0>=distance-get_larghezza_marciapiede-get_larghezza_corsia-max_larghezza_veicolo and
                          list.posizione_abitante.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria/2.0<=distance+move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list.posizione_abitante.get_id_quartiere_posizione_abitanti,list.posizione_abitante.get_id_abitante_posizione_abitanti)).get_length_entità_passiva then
                           return False;
                        end if;
                     end if;
                  end if;
                  list:= list.next;
               end loop;
            else
               list:= main_strada(polo_ingresso,opposite_corsia);
               while list/=null loop
                  if list.posizione_abitante.get_in_overtaken and list.posizione_abitante.get_destination.get_corsia_to_go_trajectory=num_corsia_to_check then
                     if list.posizione_abitante.get_distance_on_overtaking_trajectory>=get_traiettoria_cambio_corsia.get_lunghezza_traiettoria then
                        costante:= list.posizione_abitante.get_distance_on_overtaking_trajectory-get_traiettoria_cambio_corsia.get_lunghezza_traiettoria+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                     else
                        costante:= get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                     end if;
                     if (list.posizione_abitante.get_where_now_posizione_abitanti+costante>=distance-(get_larghezza_marciapiede+get_larghezza_corsia)*3.0 and list.posizione_abitante.get_where_now_posizione_abitanti<=distance) then
                        return False;
                     end if;
                  else
                     -- l'abitante è in sorpasso verso opposite_corsia quindi in un punto controllato
                     null;
                  end if;
                  list:= list.next;
               end loop;
            end if;

            list:= main_strada(polo_ingresso,num_corsia_to_check);
            while list/=null and then list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<distance loop
               prec_list:= list;
               ab:= prec_list.posizione_abitante;
               list:= list.next;
            end loop;
            if list/=null then  -- prec_list/=null è il segnale che indica che si è entrati nel ciclo almeno una volta
               move_entity:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
               if list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-move_entity.get_length_entità_passiva<distance then
                  return False;
               end if;
            end if;
            if prec_list=null then
               return True;
            elsif prec_list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti<
              distance-(get_larghezza_marciapiede+get_larghezza_corsia)*3.0 then
               return True;
            else
               return False;
            end if;
         end if;
         if traiettoria=uscita_ritorno then

            -- controllare macchine in sorpasso
            if num_corsia_to_check=2 then
               list:= main_strada(not polo_ingresso,2);
               while list/=null loop
                  if list.posizione_abitante.get_in_overtaken and list.posizione_abitante.get_destination.get_corsia_to_go_trajectory=1 then
                     if list.posizione_abitante.get_distance_on_overtaking_trajectory>=get_traiettoria_cambio_corsia.get_lunghezza_traiettoria then
                        costante:= list.posizione_abitante.get_distance_on_overtaking_trajectory-get_traiettoria_cambio_corsia.get_lunghezza_traiettoria+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                     else
                        costante:= get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                     end if;
                     if list.posizione_abitante.get_where_now_posizione_abitanti+costante>=distance-(get_larghezza_marciapiede+get_larghezza_corsia)*3.0 and list.posizione_abitante.get_where_now_posizione_abitanti<=distance+get_larghezza_marciapiede+get_larghezza_corsia then
                        return False;
                     --else
                     --   if list.posizione_abitante.get_where_now_posizione_abitanti>distance-(get_larghezza_marciapiede+get_larghezza_corsia)*3.0 and (list.posizione_abitante.get_where_now_posizione_abitanti<distance+get_larghezza_marciapiede+get_larghezza_corsia or else (list.posizione_abitante.get_where_now_posizione_abitanti=distance and list.posizione_abitante.get_distance_on_overtaking_trajectory<move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list.posizione_abitante.get_id_quartiere_posizione_abitanti,list.posizione_abitante.get_id_abitante_posizione_abitanti)).get_length_entità_passiva)) then
                     --      return False;
                     --   end if;
                     end if;
                  else
                     -- l'abitante se in sorpasso sta andando verso la corsia opposite_corsia
                     if list.posizione_abitante.get_in_overtaken then
                        if list.posizione_abitante.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria/2.0>=distance-max_larghezza_veicolo and
                          list.posizione_abitante.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria/2.0<=distance+get_larghezza_marciapiede+get_larghezza_corsia+move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list.posizione_abitante.get_id_quartiere_posizione_abitanti,list.posizione_abitante.get_id_abitante_posizione_abitanti)).get_length_entità_passiva then
                           return False;
                        end if;
                     end if;
                  end if;
                  list:= list.next;
               end loop;
            else

               -- ****
               -- SE altro_ab SI TROVA IN INTERSEZIONE CON linea_corsia; L'ABITANTE IN USCITA RITORNO
               -- DEVE PASSARE PER EVITARE STALLI
               if altro_ab/=null and then altro_ab.posizione_abitante.get_where_now_posizione_abitanti=get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                  return True;
               end if;

               -- controllare le macchine che da 2 vogliono andare a corsia 1
               -- si trovano in una posizione + vicina al dove dare la precedenza
               list:= main_strada(polo_ingresso,2);
               while list/=null loop
                  if list.posizione_abitante.get_in_overtaken and list.posizione_abitante.get_destination.get_corsia_to_go_trajectory=1 then
                     if list.posizione_abitante.get_distance_on_overtaking_trajectory>=get_traiettoria_cambio_corsia.get_lunghezza_traiettoria then
                        costante:= list.posizione_abitante.get_distance_on_overtaking_trajectory-get_traiettoria_cambio_corsia.get_lunghezza_traiettoria+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                     else
                        costante:= get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                     end if;
                     if (list.posizione_abitante.get_where_now_posizione_abitanti+costante>=distance-(get_larghezza_marciapiede+get_larghezza_corsia)*3.0 and list.posizione_abitante.get_where_now_posizione_abitanti<=distance) then
                        return False;
                     end if;
                  end if;
                  list:= list.next;
               end loop;
            end if;

            if num_corsia_to_check=1 then
               list:= main_strada(polo_ingresso,1);
            else
               list:= main_strada(not polo_ingresso,1);
            end if;
            while list/=null and then list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<distance+get_larghezza_marciapiede+get_larghezza_corsia loop
               prec_list:= list;
               list:= list.next;
            end loop;
            if list/=null then
               move_entity:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
               if list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-move_entity.get_length_entità_passiva<distance+get_larghezza_marciapiede+get_larghezza_corsia then
                  return False;
               end if;
            end if;
            if prec_list=null then
               return True;
            else
               if num_corsia_to_check=2 then
                  switch:= False;
                  while altro_ab/=null loop
                     if altro_ab.posizione_abitante.get_where_now_posizione_abitanti<get_traiettoria_ingresso(entrata_ritorno).get_intersezioni.get_distanza_intersezione then
                        switch:= True;
                     end if;
                     altro_ab:= altro_ab.next;
                  end loop;
                  if switch then
                     if prec_list.posizione_abitante.get_where_next_posizione_abitanti>distance-get_larghezza_marciapiede-get_larghezza_corsia then
                        return False;
                     else
                        return True;
                     end if;
                  else
                     if prec_list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti<
                       distance-(get_larghezza_marciapiede+get_larghezza_corsia)*3.0 then
                        return True;
                     else
                        return False;
                     end if;
                  end if;
               else
                  -- SI CONTROLLA SE SI HANNO ABITANTI DATO CHE l'abitante
                  -- IN entrata_ritorno NON È IN UNA POSIZIONE CRITICA(cioè in intersezione con linea_corsia)
                  if prec_list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_next_posizione_abitanti<
                    distance-(get_larghezza_marciapiede+get_larghezza_corsia)*3.0 then
                     return True;
                  else
                     return False;
                  end if;
               end if;
            end if;
         end if;
         return True;
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
         return True;
      end can_car_overtake;

      function car_can_overtake_on_first_step_trajectory(car: ptr_list_posizione_abitanti_on_road; polo: Boolean; num_corsia: id_corsie; is_bound_overtaken: Boolean:= False) return Boolean is
         other_corsia: id_corsie;
         list_other_corsia: ptr_list_posizione_abitanti_on_road;
         next_car_length: new_float;
         costante_additiva: new_float:= 0.0;
         segnale: Boolean;
      begin
         if num_corsia=1 then
            other_corsia:= 2;
         else
            other_corsia:= 1;
         end if;

         list_other_corsia:= main_strada(polo,other_corsia);

         if is_bound_overtaken then
            costante_additiva:= get_larghezza_marciapiede+get_larghezza_corsia;
         end if;

         -- prima zona sorpasso = zona da where_now a intersezione con linea di mezzo
         -- seconda zona = zona da intersezione linea di mezzo a fine traiettoria

         segnale:= True;
         for i in 1..main_strada_number_entity(polo,other_corsia) loop
            next_car_length:= get_quartiere_utilities_obj.get_auto_quartiere(list_other_corsia.posizione_abitante.get_id_quartiere_posizione_abitanti,list_other_corsia.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
            Put_Line("abitante altra corsia di : " & Positive'Image(car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(car.posizione_abitante.get_id_abitante_posizione_abitanti) & " is " & Positive'Image(list_other_corsia.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_other_corsia.posizione_abitante.get_id_abitante_posizione_abitanti) & " where " & new_float'Image(list_other_corsia.posizione_abitante.get_where_now_posizione_abitanti) & " car corrente dist " & new_float'Image(car.posizione_abitante.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria/2.0) & " " & Boolean'Image(is_bound_overtaken) & " " & Positive'Image(car.posizione_abitante.get_backup_corsia_to_go));
            if (is_bound_overtaken=True and then ((list_other_corsia.posizione_abitante.get_where_now_posizione_abitanti<=car.posizione_abitante.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria/2.0 or list_other_corsia.posizione_abitante.get_where_now_posizione_abitanti-next_car_length<car.posizione_abitante.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria/2.0) and list_other_corsia.posizione_abitante.get_where_now_posizione_abitanti>=car.posizione_abitante.get_where_now_posizione_abitanti-costante_additiva)) or else
              (is_bound_overtaken=False and then ((list_other_corsia.posizione_abitante.get_where_now_posizione_abitanti<=car.posizione_abitante.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria/2.0 or list_other_corsia.posizione_abitante.get_where_now_posizione_abitanti-next_car_length<car.posizione_abitante.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria/2.0) and list_other_corsia.posizione_abitante.get_where_now_posizione_abitanti>=car.posizione_abitante.get_where_now_posizione_abitanti)) then
               if is_bound_overtaken then
                  -- si controlla che se la macchina è in bound_overtaken percaso la macchina list_other_corsia si trovi anch essa in buond overtaken
                  if car.posizione_abitante.get_backup_corsia_to_go=1 then
                     -- la macchina si trova a destra quindi ha la precedenza su quelle a sinistra
                     -- se la macchina nell'altra corsia non deve andare nella corsia 2 significa
                     -- che non è in bound to overtake altrimenti lo è
                     -- se deve andare in 2 allora è in bound_to_overtake
                     -- e deve dare la precedenza
                     segnale:= False;
                     if list_other_corsia.posizione_abitante.get_backup_corsia_to_go=2 and calculate_bound_to_overtake(list_other_corsia,polo,id_risorsa)=0.0 then
                        return True;
                     end if;
                     --if list_other_corsia.posizione_abitante.get_backup_corsia_to_go/=2 then
                     --   Put_Line("on first step can not overtake: " & Positive'Image(car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(car.posizione_abitante.get_id_abitante_posizione_abitanti));
                     --   return False;
                     --end if;
                  else
                     -- la macchina si trova a sinistra e deve andare a destra; quindi deve dare
                     -- la precedenza alle macchine che sono a destra
                     Put_Line("on first step can not overtake: " & Positive'Image(car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(car.posizione_abitante.get_id_abitante_posizione_abitanti));
                     return False;
                  end if;
               else
                  Put_Line("on first step can not overtake: " & Positive'Image(car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(car.posizione_abitante.get_id_abitante_posizione_abitanti));
                  return False;
               end if;
            end if;
            list_other_corsia:= list_other_corsia.next;
         end loop;

         if list_other_corsia/=null then
            raise alcuni_elementi_non_visitati;
         end if;


         Put_Line("on first step can overtake: " & Positive'Image(car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(car.posizione_abitante.get_id_abitante_posizione_abitanti));
         return segnale;

      end car_can_overtake_on_first_step_trajectory;

      function car_can_overtake_on_second_step_trajectory(car: ptr_list_posizione_abitanti_on_road; polo: Boolean; num_corsia: id_corsie) return Boolean is
         other_corsia: id_corsie;
         list_current_corsia: ptr_list_posizione_abitanti_on_road;
         list_other_corsia: ptr_list_posizione_abitanti_on_road;
         next_car_length: new_float;
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

         Put_Line("second step request by " & Positive'Image(car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(car.posizione_abitante.get_id_abitante_posizione_abitanti));

         for i in 1..main_strada_number_entity(polo,other_corsia) loop
            switch:= False;
            next_car_length:= get_quartiere_utilities_obj.get_auto_quartiere(list_other_corsia.posizione_abitante.get_id_quartiere_posizione_abitanti,list_other_corsia.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
            if (list_other_corsia.posizione_abitante.get_where_now_posizione_abitanti<=car.posizione_abitante.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria and list_other_corsia.posizione_abitante.get_where_now_posizione_abitanti>=car.posizione_abitante.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria/2.0) or
              (list_other_corsia.posizione_abitante.get_where_now_posizione_abitanti-next_car_length<=car.posizione_abitante.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria and list_other_corsia.posizione_abitante.get_where_now_posizione_abitanti>=car.posizione_abitante.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria/2.0) then
               Put_Line("can NOT overtake from second step request by " & Positive'Image(car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(car.posizione_abitante.get_id_abitante_posizione_abitanti));
               return False;
            end if;
            list_other_corsia:= list_other_corsia.next;
         end loop;

         Put_Line("can overtake from second step request by " & Positive'Image(car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(car.posizione_abitante.get_id_abitante_posizione_abitanti));

         if list_other_corsia/=null then
            raise alcuni_elementi_non_visitati;
         end if;

         return True;
      end car_can_overtake_on_second_step_trajectory;

      function there_are_overtaken_on_ingresso(ingresso: strada_ingresso_features; polo: Boolean) return Boolean is
         list: ptr_list_posizione_abitanti_on_road;
         length_urbana: new_float:= get_urbana_from_id(ingresso.get_id_main_strada_ingresso).get_lunghezza_road;
      begin
         for j in 1..2 loop
            list:= main_strada(polo,j);
            for i in 1..main_strada_number_entity(polo,j) loop
               if list.posizione_abitante.get_in_overtaken and list.posizione_abitante.get_where_now_posizione_abitanti>get_distance_from_polo_percorrenza(ingresso,polo)-get_larghezza_marciapiede-get_larghezza_corsia
                 -get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria and  -- l'ultima sottrazione viene eseguita per avere il buond minimo al quale si può avere un sorpasso che interseca l'ingresso
                 list.posizione_abitante.get_where_now_posizione_abitanti<get_distance_from_polo_percorrenza(ingresso,polo)+get_larghezza_marciapiede+get_larghezza_corsia then
                  return True;
               end if;
               list:= list.next;
            end loop;
         end loop;
         return False;
      end there_are_overtaken_on_ingresso;

      function get_next_abitante_in_corsia(num_corsia: id_corsie; polo: Boolean; from_distance: new_float) return ptr_list_posizione_abitanti_on_road is
         list: ptr_list_posizione_abitanti_on_road;
      begin
         -- se l'abitante è in sorpasso verso la corsia opposta a num_corsia allora
         -- quell'abitante non viene considerato come idoneo per il next per una macchina
         -- in sorpasso verso num_corsia

         -- il next viene considerato considerando il where now e non la lunghezza della macchina
         -- infatti se la macchina interseca la traiettoria di sorpasso il task fa in modo
         -- che la macchina non sorpassi

         list:= main_strada(polo,num_corsia);
         while list/=null loop
            if list.posizione_abitante.get_where_now_posizione_abitanti>from_distance then
               if list.posizione_abitante.get_in_overtaken=False then
                  return list;
               else
                  if list.posizione_abitante.get_destination.get_corsia_to_go_trajectory=num_corsia then
                     return list;
                  end if;
               end if;
            end if;
            list:= list.next;
         end loop;
         return null;

      end get_next_abitante_in_corsia;

      -- metodo usato per individuare se esistono macchine nella medesima traiettoria che intersecano la zona di sorpasso di car
      function complete_trajectory_on_same_corsia_is_free(car: ptr_list_posizione_abitanti_on_road; polo: Boolean; num_corsia: id_corsie) return Boolean is
         next_cars: ptr_list_posizione_abitanti_on_road:= car.next;
         next_car_length: new_float;
      begin
         if next_cars/=null then
            next_car_length:= get_quartiere_utilities_obj.get_auto_quartiere(next_cars.posizione_abitante.get_id_quartiere_posizione_abitanti,next_cars.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
            --if (next_cars.posizione_abitante.get_where_now_posizione_abitanti>=car.posizione_abitante.get_where_now_posizione_abitanti
            --    and next_cars.posizione_abitante.get_where_now_posizione_abitanti<=car.posizione_abitante.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria) or
            --  (next_cars.posizione_abitante.get_where_now_posizione_abitanti-next_car_length<car.posizione_abitante.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria and
            --     next_cars.posizione_abitante.get_where_now_posizione_abitanti>car.posizione_abitante.get_where_now_posizione_abitanti) then
            --   return False;
            --else
            --   return True;
            --end if;
            if next_cars.posizione_abitante.get_where_now_posizione_abitanti<=car.posizione_abitante.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria or
              next_cars.posizione_abitante.get_where_now_posizione_abitanti-next_car_length<=car.posizione_abitante.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria then
               return False;
            else
               return True;
            end if;
         end if;
         return True;
      end complete_trajectory_on_same_corsia_is_free;

      function get_last_abitante_ingresso(key_ingresso: Positive; traiettoria: traiettoria_ingressi_type) return ptr_list_posizione_abitanti_on_road is
      begin
         if set_traiettorie_ingressi(key_ingresso,traiettoria)/=null then
            if set_traiettorie_ingressi(key_ingresso,traiettoria).next/=null then
               return set_traiettorie_ingressi(key_ingresso,traiettoria).next;
            else
               return set_traiettorie_ingressi(key_ingresso,traiettoria);
            end if;
         else
            return null;
         end if;
      end get_last_abitante_ingresso;

      function there_are_cars_moving_across_next_ingressi(car: ptr_list_posizione_abitanti_on_road; polo: Boolean) return Boolean is
         list_uscita_ritorno: ptr_list_posizione_abitanti_on_road;
         list_entrata_ritorno: ptr_list_posizione_abitanti_on_road;
         type_ingresso: ingressi_type;
         car_length: new_float;
         list_traiettorie_entrata_andata: ptr_list_posizione_abitanti_on_road;
         type_ingressi_structure: ingressi_type;
         key_ingresso: Positive;
         costante: new_float:= 0.0;
      begin

         if polo then
            type_ingressi_structure:= ordered_polo_true;
         else
            type_ingressi_structure:= ordered_polo_false;
         end if;

         for i in ordered_ingressi_polo(polo).all'Range loop
            if is_index_ingresso_in_svolta(ordered_ingressi_polo(polo)(i),uscita_andata) or else
              is_index_ingresso_in_svolta(ordered_ingressi_polo(polo)(i),uscita_ritorno) or else
              is_index_ingresso_in_svolta(ordered_ingressi_polo(polo)(i),entrata_andata) or else
              is_index_ingresso_in_svolta(ordered_ingressi_polo(polo)(i),entrata_ritorno) then
               key_ingresso:= get_key_ingresso(get_index_ingresso_from_key(i,type_ingressi_structure),not_ordered);
               list_traiettorie_entrata_andata:= get_last_abitante_ingresso(key_ingresso,entrata_andata);
               if list_traiettorie_entrata_andata/=null then
                  car_length:= get_quartiere_utilities_obj.get_auto_quartiere(list_traiettorie_entrata_andata.posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                                           list_traiettorie_entrata_andata.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                  if list_traiettorie_entrata_andata.posizione_abitante.get_where_now_posizione_abitanti-car_length<0.0 then
                     costante:= car_length-list_traiettorie_entrata_andata.posizione_abitante.get_where_now_posizione_abitanti;
                  end if;
               end if;
               if list_traiettorie_entrata_andata/=null and then list_traiettorie_entrata_andata.next/=null then
                  costante:= get_quartiere_utilities_obj.get_auto_quartiere(list_traiettorie_entrata_andata.next.posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                                              list_traiettorie_entrata_andata.next.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
               end if;
               if car.posizione_abitante.get_where_now_posizione_abitanti>=get_distance_from_polo_percorrenza(get_ingresso_from_id(ordered_ingressi_polo(polo)(i)),polo)-get_larghezza_marciapiede-get_larghezza_corsia and
                 car.posizione_abitante.get_where_now_posizione_abitanti<=get_distance_from_polo_percorrenza(get_ingresso_from_id(ordered_ingressi_polo(polo)(i)),polo)+get_larghezza_marciapiede+get_larghezza_corsia then
                  return True;
               elsif car.posizione_abitante.get_where_now_posizione_abitanti>=get_distance_from_polo_percorrenza(get_ingresso_from_id(ordered_ingressi_polo(polo)(i)),polo)-get_larghezza_marciapiede-get_larghezza_corsia-
                 get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria-costante and car.posizione_abitante.get_where_now_posizione_abitanti<=get_distance_from_polo_percorrenza(get_ingresso_from_id(ordered_ingressi_polo(polo)(i)),polo)+get_larghezza_marciapiede+get_larghezza_corsia then
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
            if (list_uscita_ritorno/=null and then list_uscita_ritorno.posizione_abitante.get_where_now_posizione_abitanti>get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie) or else
              (list_entrata_ritorno/=null and then list_entrata_ritorno.posizione_abitante.get_where_now_posizione_abitanti-
                 get_quartiere_utilities_obj.get_auto_quartiere(list_entrata_ritorno.posizione_abitante.get_id_quartiere_posizione_abitanti,list_entrata_ritorno.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva<get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie) or else
              (list_entrata_ritorno/=null and then list_entrata_ritorno.next/=null) then
               car_length:= 0.0;
               if list_entrata_ritorno/=null and then list_entrata_ritorno.next/=null then
                  car_length:= get_quartiere_utilities_obj.get_auto_quartiere(list_entrata_ritorno.next.posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                                              list_entrata_ritorno.next.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva;

               end if;
               if car.posizione_abitante.get_where_now_posizione_abitanti>=get_distance_from_polo_percorrenza(get_ingresso_from_id(ordered_ingressi_polo(not polo)(i)),polo)-get_larghezza_marciapiede-get_larghezza_corsia and
                 car.posizione_abitante.get_where_now_posizione_abitanti<=get_distance_from_polo_percorrenza(get_ingresso_from_id(ordered_ingressi_polo(not polo)(i)),polo)+get_larghezza_marciapiede+get_larghezza_corsia then
                  return True;
               elsif car.posizione_abitante.get_where_now_posizione_abitanti>get_distance_from_polo_percorrenza(get_ingresso_from_id(ordered_ingressi_polo(not polo)(i)),polo)-get_larghezza_marciapiede-get_larghezza_corsia-
                 get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria-car_length and car.posizione_abitante.get_where_now_posizione_abitanti<=get_distance_from_polo_percorrenza(get_ingresso_from_id(ordered_ingressi_polo(not polo)(i)),polo)+get_larghezza_marciapiede+get_larghezza_corsia then
                  return True;
               else
                  return False;
               end if;
            end if;
         end loop;

         return False;
      end there_are_cars_moving_across_next_ingressi;

      function calculate_distance_ingressi_from_given_distance(polo_to_consider: Boolean; in_corsia: id_corsie; car_distance: new_float) return new_float is
         key_ingresso: Positive;
         index_ingresso: Positive;
         distance_ingresso: new_float;
         list_traiettorie_uscita_andata: ptr_list_posizione_abitanti_on_road;
         list_traiettorie_uscita_ritorno: ptr_list_posizione_abitanti_on_road;
         list_traiettorie_entrata_andata: ptr_list_posizione_abitanti_on_road;
         list_traiettorie_entrata_ritorno: ptr_list_posizione_abitanti_on_road;
         type_ingressi_structure: ingressi_type;
         distance_one: new_float:= -1.0;
         distance_two: new_float:= -1.0;
         car_length: new_float;
      begin
         if polo_to_consider then
            type_ingressi_structure:= ordered_polo_true;
         else
            type_ingressi_structure:= ordered_polo_false;
         end if;

         for i in reverse 1..ordered_ingressi_polo(polo_to_consider).all'Last loop
            key_ingresso:= get_key_ingresso(get_index_ingresso_from_key(i,type_ingressi_structure),not_ordered);
            index_ingresso:= ordered_ingressi_polo(polo_to_consider)(i);
            distance_ingresso:= get_distance_from_polo_percorrenza(get_ingresso_from_id(index_ingresso),polo_to_consider);

            list_traiettorie_uscita_andata:= set_traiettorie_ingressi(key_ingresso,uscita_andata);
            list_traiettorie_uscita_ritorno:= set_traiettorie_ingressi(key_ingresso,uscita_ritorno);
            list_traiettorie_entrata_andata:= get_last_abitante_ingresso(key_ingresso,entrata_andata);
            list_traiettorie_entrata_ritorno:= get_last_abitante_ingresso(key_ingresso,entrata_ritorno);

            if distance_ingresso>car_distance then
               if in_corsia=2 then
                  if list_traiettorie_uscita_andata/=null and then list_traiettorie_uscita_andata.posizione_abitante.get_where_now_posizione_abitanti>0.0 then
                     distance_one:= distance_ingresso;
                  elsif list_traiettorie_uscita_ritorno/=null and then (list_traiettorie_uscita_ritorno.posizione_abitante.get_where_now_posizione_abitanti>0.0 and then (list_traiettorie_uscita_ritorno.posizione_abitante.get_where_now_posizione_abitanti-
                    get_quartiere_utilities_obj.get_auto_quartiere(list_traiettorie_uscita_ritorno.posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                                   list_traiettorie_uscita_ritorno.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva<get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie)) then
                     distance_one:= distance_ingresso;
                  elsif list_traiettorie_entrata_ritorno/=null and then list_traiettorie_entrata_ritorno.posizione_abitante.get_where_now_posizione_abitanti>get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                                                                         --and then (list_traiettorie_entrata_ritorno.posizione_abitante.get_where_now_posizione_abitanti-
                    							 --get_quartiere_utilities_obj.get_auto_quartiere(list_traiettorie_entrata_ritorno.posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                                         --list_traiettorie_entrata_ritorno.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva>get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie)) then
                     distance_one:= distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede;
                  elsif list_traiettorie_entrata_andata/=null and then list_traiettorie_entrata_andata.posizione_abitante.get_where_now_posizione_abitanti>=0.0 then
                     car_length:= get_quartiere_utilities_obj.get_auto_quartiere(list_traiettorie_entrata_andata.posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                                                 list_traiettorie_entrata_andata.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                     if list_traiettorie_entrata_andata.next/=null then
                        car_length:= get_quartiere_utilities_obj.get_auto_quartiere(list_traiettorie_entrata_andata.next.posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                                                    list_traiettorie_entrata_andata.next.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                        distance_one:= distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-car_length;
                     else
                        if list_traiettorie_entrata_andata.posizione_abitante.get_where_now_posizione_abitanti-car_length<0.0 then
                           distance_one:= distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-(car_length-list_traiettorie_entrata_andata.posizione_abitante.get_where_now_posizione_abitanti);
                        else
                           distance_one:= distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede;
                        end if;
                     end if;
                  end if;
               else
                  if list_traiettorie_uscita_ritorno/=null and then (list_traiettorie_uscita_ritorno.posizione_abitante.get_where_now_posizione_abitanti>get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie
                                                                     and then (list_traiettorie_uscita_ritorno.posizione_abitante.get_where_now_posizione_abitanti-
                                                                               get_quartiere_utilities_obj.get_auto_quartiere(list_traiettorie_uscita_ritorno.posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                                               list_traiettorie_uscita_ritorno.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva<get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie)) then
                     distance_one:= distance_ingresso-get_larghezza_marciapiede-get_larghezza_corsia;
                     Put_Line("stop 1656 " & new_float'Image(car_distance) & " uscita ritorno: " & new_float'Image(list_traiettorie_uscita_ritorno.posizione_abitante.get_where_now_posizione_abitanti));
                  elsif list_traiettorie_entrata_ritorno/=null and then (list_traiettorie_entrata_ritorno.posizione_abitante.get_where_now_posizione_abitanti>get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie
                                                                         and then (list_traiettorie_entrata_ritorno.posizione_abitante.get_where_now_posizione_abitanti-
                                                                                     get_quartiere_utilities_obj.get_auto_quartiere(list_traiettorie_entrata_ritorno.posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                                                                                                    list_traiettorie_entrata_ritorno.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva<get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie)) then
                     distance_one:= distance_ingresso-get_larghezza_marciapiede-get_larghezza_corsia;
                     Put_Line("stop 1662 " & new_float'Image(car_distance) & " entrata ritorno: " & new_float'Image(list_traiettorie_entrata_ritorno.posizione_abitante.get_where_now_posizione_abitanti));
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

         for i in 1..ordered_ingressi_polo(not polo_to_consider).all'Last loop
            key_ingresso:= get_key_ingresso(get_index_ingresso_from_key(i,type_ingressi_structure),not_ordered);
            index_ingresso:= ordered_ingressi_polo(not polo_to_consider)(i);
            distance_ingresso:= get_distance_from_polo_percorrenza(get_ingresso_from_id(index_ingresso),polo_to_consider);

            list_traiettorie_uscita_ritorno:= set_traiettorie_ingressi(key_ingresso,uscita_ritorno);
            list_traiettorie_entrata_ritorno:= get_last_abitante_ingresso(key_ingresso,entrata_ritorno);

            if distance_ingresso>car_distance then -- se l'ingresso si trova ad una distanza maggiore della macchina
               --if in_corsia=2 then
                  --if list_traiettorie_uscita_ritorno/=null and then list_traiettorie_uscita_ritorno.posizione_abitante.get_where_next_posizione_abitanti>get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                  --   distance_two:= distance_ingresso-get_larghezza_marciapiede-get_larghezza_corsia;
                  --end if;
               --else
               if in_corsia=1 then
                  if list_traiettorie_uscita_ritorno/=null and then list_traiettorie_uscita_ritorno.posizione_abitante.get_where_now_posizione_abitanti>get_traiettoria_ingresso(uscita_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                     distance_two:= distance_ingresso-get_larghezza_marciapiede-get_larghezza_corsia;
                  end if;
                  if list_traiettorie_entrata_ritorno/=null then
                     car_length:= get_quartiere_utilities_obj.get_auto_quartiere(list_traiettorie_entrata_ritorno.posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                                                 list_traiettorie_entrata_ritorno.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                     if list_traiettorie_entrata_ritorno.next/=null then
                        car_length:= get_quartiere_utilities_obj.get_auto_quartiere(list_traiettorie_entrata_ritorno.next.posizione_abitante.get_id_quartiere_posizione_abitanti,
                                                                                       list_traiettorie_entrata_ritorno.next.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
                        distance_two:= distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-car_length;
                     else
                        if list_traiettorie_entrata_ritorno.posizione_abitante.get_where_now_posizione_abitanti-car_length<get_traiettoria_ingresso(entrata_ritorno).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                           if list_traiettorie_entrata_ritorno.posizione_abitante.get_where_now_posizione_abitanti-car_length<0.0 then
                              distance_two:= distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede-(car_length-list_traiettorie_entrata_ritorno.posizione_abitante.get_where_now_posizione_abitanti);
                           else
                              distance_two:= distance_ingresso-get_larghezza_corsia-get_larghezza_marciapiede;
                           end if;
                        end if;
                     end if;
                  end if;
               end if;
            end if;
         end loop;

         if distance_one=-1.0 and distance_two=-1.0 then
            return -1.0;
         else
            if distance_one/=-1.0 and distance_two/=-1.0 then
               if distance_one<=distance_two then
                  return distance_one;
               else
                  return distance_two;
               end if;
            else
               if distance_one=-1.0 then
                  return distance_two;
               else
                  return distance_one;
               end if;
            end if;
         end if;
      end calculate_distance_ingressi_from_given_distance;

      function calculate_distance_to_next_ingressi(polo_to_consider: Boolean; in_corsia: id_corsie; car_in_corsia: ptr_list_posizione_abitanti_on_road) return new_float is
         car_distance: new_float;
      begin
         if car_in_corsia.posizione_abitante.get_in_overtaken then
            car_distance:= car_in_corsia.posizione_abitante.get_where_now_posizione_abitanti+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
         else
            car_distance:= car_in_corsia.posizione_abitante.get_where_now_posizione_abitanti;
         end if;
         return calculate_distance_ingressi_from_given_distance(polo_to_consider,in_corsia,car_distance);
      end calculate_distance_to_next_ingressi;

      function can_abitante_move(distance: new_float; key_ingresso: Positive; traiettoria: traiettoria_ingressi_type; polo_ingresso: Boolean) return Boolean is
         list: ptr_list_posizione_abitanti_on_road;
         prec_list: ptr_list_posizione_abitanti_on_road:= null;
         --list_1: ptr_list_posizione_abitanti_on_road;
         --list_2: ptr_list_posizione_abitanti_on_road;
         move_entity: move_parameters;
         costante: new_float;
      begin
         -- pol_ingresso indica indica in effetti la direzione di movimento degli abitanti nell'urbana
         if traiettoria=uscita_andata then

            -- cerco se vi sono abitanti in sorpasso
            list:= main_strada(polo_ingresso,1);
            while list/=null loop
               if list.posizione_abitante.get_in_overtaken and list.posizione_abitante.get_destination.get_corsia_to_go_trajectory=2 then
                  if list.posizione_abitante.get_distance_on_overtaking_trajectory>=get_traiettoria_cambio_corsia.get_lunghezza_traiettoria then
                     costante:= list.posizione_abitante.get_distance_on_overtaking_trajectory-get_traiettoria_cambio_corsia.get_lunghezza_traiettoria+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                  else
                     costante:= get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                  end if;
                  if (list.posizione_abitante.get_where_now_posizione_abitanti+costante>=distance-(get_larghezza_marciapiede+get_larghezza_corsia)*3.0 and list.posizione_abitante.get_where_now_posizione_abitanti<=distance+get_larghezza_marciapiede+get_larghezza_corsia) then
                     return False;
                  end if;
               else
                  -- l'abitante è in sorpasso verso la corsia 1 ma non ha ancora
                  -- attraversato, quindi verrà trovato nel blocco che
                  -- guarda la lista main_strada(polo_ingresso,2)
                  null;
               end if;
               list:= list.next;
            end loop;
            -- end

            list:= main_strada(polo_ingresso,2);
            while list/=null and then list.posizione_abitante.get_where_now_posizione_abitanti<distance+get_larghezza_marciapiede+get_larghezza_corsia loop
               prec_list:= list;
               list:= list.next;
            end loop;
            if list/=null then  -- controllare se la macchina si trova ancora in parte nell'ingresso
               move_entity:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
               if list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-move_entity.get_length_entità_passiva<distance+get_larghezza_marciapiede+get_larghezza_corsia then
                  return False;
               end if;
            end if;
            if prec_list=null then
               return True;
            elsif prec_list.posizione_abitante.get_where_next_posizione_abitanti<distance-(get_larghezza_corsia+get_larghezza_marciapiede)*3.0 then  -- la precedente ha distanza sufficiente per permettere l'attraversamento
               return True;
            else
               return False;
            end if;
         elsif traiettoria=uscita_ritorno then

            -- cerco se vi sono abitanti in sorpasso
            list:= main_strada(polo_ingresso,1);
            while list/=null loop
               if list.posizione_abitante.get_in_overtaken and list.posizione_abitante.get_destination.get_corsia_to_go_trajectory=2 then
                  if list.posizione_abitante.get_distance_on_overtaking_trajectory>=get_traiettoria_cambio_corsia.get_lunghezza_traiettoria then
                     costante:= list.posizione_abitante.get_distance_on_overtaking_trajectory-get_traiettoria_cambio_corsia.get_lunghezza_traiettoria+get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                  else
                     costante:= get_traiettoria_cambio_corsia.get_lunghezza_lineare_traiettoria;
                  end if;
                  if (list.posizione_abitante.get_where_now_posizione_abitanti+costante>=distance-(get_larghezza_marciapiede+get_larghezza_corsia)*3.0 and list.posizione_abitante.get_where_now_posizione_abitanti<=distance+get_larghezza_marciapiede+get_larghezza_corsia) then
                     return False;
                  end if;
               else
                  -- l'abitante è in sorpasso verso la corsia 1 ma non ha ancora
                  -- attraversato, quindi verrà trovato nel blocco che
                  -- guarda la lista main_strada(polo_ingresso,2)
                  null;
               end if;
               list:= list.next;
            end loop;
            -- end

            list:= main_strada(polo_ingresso,2);
            while list/=null and then list.posizione_abitante.get_where_now_posizione_abitanti<distance+get_larghezza_marciapiede+get_larghezza_corsia loop
               prec_list:= list;
               list:= list.next;
            end loop;
            if list/=null then
               move_entity:= move_parameters(get_quartiere_utilities_obj.get_auto_quartiere(list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
               if list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-move_entity.get_length_entità_passiva<distance+get_larghezza_marciapiede+get_larghezza_corsia then
                  return False;
               end if;
            end if;
            if prec_list=null then
               return True;
            elsif prec_list.posizione_abitante.get_where_next_posizione_abitanti<distance-(get_larghezza_corsia+get_larghezza_marciapiede)*3.0 then  -- la precedente ha distanza sufficiente per permettere l'attraversamento
               return True;
            else
               return False;
            end if;
         else
            return True;
         end if;
      end can_abitante_move;

      function get_distanza_percorsa_first_abitante(polo: Boolean; num_corsia: id_corsie) return new_float is
         distance_ingressi: new_float;
         distance_abitante: new_float;
         abitante: ptr_list_posizione_abitanti_on_road;
      begin
         abitante:= main_strada(polo,num_corsia);
         if abitante/=null then
            -- viene ritornata la posizione dell'abitante se la macchina non ha attraversato
            -- completamente l'incrocio; altrimenti viene ritornata la posizione della macchina
            -- sottraendovi la lunghezza della macchina
            if abitante.posizione_abitante.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(abitante.posizione_abitante.get_id_quartiere_posizione_abitanti,abitante.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva<0.0 then
               distance_abitante:= abitante.posizione_abitante.get_where_now_posizione_abitanti;
               return distance_abitante;
            else
               abitante:= get_next_abitante_on_road(0.0,polo,num_corsia,False);
               distance_abitante:= abitante.posizione_abitante.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(abitante.posizione_abitante.get_id_quartiere_posizione_abitanti,abitante.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva;
            end if;
         else
            abitante:= get_next_abitante_on_road(0.0,polo,num_corsia,False);
            if abitante/=null then
               distance_abitante:= abitante.posizione_abitante.get_where_now_posizione_abitanti;
            else
               distance_abitante:= -1.0;
            end if;
         end if;

         distance_ingressi:= calculate_distance_ingressi_from_given_distance(polo,num_corsia,0.0);
         if distance_abitante=-1.0 and distance_ingressi=-1.0 then
            return -1.0;
         elsif distance_abitante=-1.0 then
            return distance_ingressi;
         -- da qui sai che abitante è diverso da null dato che distance_abitante/=-1.0
         elsif distance_ingressi=-1.0 then
            return distance_abitante;
         elsif distance_abitante<=distance_ingressi then
            return distance_abitante;
         else
            return distance_ingressi;
         end if;
      end get_distanza_percorsa_first_abitante;

      function first_car_abitante_has_passed_incrocio(polo: Boolean; num_corsia: id_corsie) return Boolean is
         abitante: ptr_list_posizione_abitanti_on_road;
      begin
         abitante:= main_strada(polo,num_corsia);
         if abitante=null then
            return True;
         end if;
         if abitante.posizione_abitante.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(abitante.posizione_abitante.get_id_quartiere_posizione_abitanti,abitante.posizione_abitante.get_id_abitante_posizione_abitanti).get_length_entità_passiva>=0.0 then
            return True;
         else
            return False;
         end if;
      end first_car_abitante_has_passed_incrocio;

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

      procedure create_img(json_1: out JSON_Value) is
         --list: ptr_list_posizione_abitanti_on_road;
         --json_abitanti: JSON_Array;
         --json_abitante: JSON_Value;
      begin
         null;
         --begin
         --json_1:= Create_Object;

         --if last_abitante_in_urbana.get_id_quartiere_posizione_abitanti/=0 then
         --   json_1.Set_Field("last_abitante_in_urbana",create_img_abitante(last_abitante_in_urbana,-1.0));
         --end if;

         --json_1.Set_Field("car_avanzamento_in_urbana",car_avanzamento_in_urbana);

         -- creazione main_strada
         --json_1.Set_Field("main_strada",create_img_strada(main_strada,id_risorsa));

         -- MARCIAPIEDI IMAGE TO DO
         -- MARCIAPIEDI NUMBER ENTITY TO DO
         -- MARCIAPIEDI TEMP TO DO
         --json_1.Set_Field("main_strada_number_entity",create_img_num_entity_strada(main_strada_number_entity));

         --list:= main_strada_temp;
         --while list/=null loop
         --   json_abitante:= create_img_abitante(list.posizione_abitante,-1.0);
         --   Append(json_abitanti,json_abitante);
         --   list:= list.next;
         --end loop;
         --json_1.Set_Field("main_strada_temp",json_abitanti);
         --exception
         --   when others =>
         --      Put_Line("errore nella creazione ingresso in: " & Positive'Image(get_id_quartiere) & " " & Positive'Image(id_risorsa));
         --      raise set_field_json_error;
         --end;
      end create_img;

      procedure recovery_resource is
         --json_resource: JSON_Value;
         --json_main_strada: JSON_Value;
         --json_numer_entity: JSON_Value;
         --json_1: JSON_Value;
         --json_2: JSON_Value;
         --json_abitanti: JSON_Array;
      begin
         null;
         --share_snapshot_file_quartiere.get_json_value_resource_snap(id_risorsa,json_resource);

         --if json_resource.Has_Field("last_abitante_in_urbana") then
         --   last_abitante_in_urbana:= create_abitante_from_json(json_resource.Get("last_abitante_in_urbana"));
         --end if;

         --car_avanzamento_in_urbana:= json_resource.Get("car_avanzamento_in_urbana");

         --json_main_strada:= json_resource.Get("main_strada");
         --for i in False..True loop
         --   json_1:= json_main_strada.Get(Boolean'Image(i));
         --   json_abitanti:= json_1.Get(Positive'Image(1));
         --   main_strada(i,1):= create_array_abitanti(json_abitanti);
         --end loop;

         --json_numer_entity:= json_resource.Get("main_strada_number_entity");
         --for i in False..True loop
         --   json_1:= json_numer_entity.Get(Boolean'Image(i));
         --   main_strada_number_entity(i,1):= json_1.Get(Positive'Image(1));
         --end loop;

         --json_abitanti:= json_resource.Get("main_strada_temp");
         --main_strada_temp:= create_array_abitanti(json_abitanti);

      end recovery_resource;

      procedure set_move_parameters_entity_on_main_strada(range_1: Boolean; num_entity: Positive;
                                                          speed: new_float; step_to_advance: new_float) is
         node: ptr_list_posizione_abitanti_on_road:= null;
      begin
         node:= slide_list(road,range_1,1,num_entity);
         if speed>0.0 then
            node.posizione_abitante.set_current_speed_abitante(speed);
         end if;
         if step_to_advance>0.0 then
            if range_1=not index_inizio_moto then
               node.posizione_abitante.set_where_next_abitante(node.posizione_abitante.get_where_now_posizione_abitanti+step_to_advance);
            else
               if node.posizione_abitante.get_where_now_posizione_abitanti+step_to_advance>risorsa_features.get_lunghezza_road then
                  node.posizione_abitante.set_where_next_abitante(risorsa_features.get_lunghezza_road);
               else
                  node.posizione_abitante.set_where_next_abitante(node.posizione_abitante.get_where_now_posizione_abitanti+step_to_advance);
               end if;
            end if;
         end if;
      end set_move_parameters_entity_on_main_strada;

      procedure set_move_parameters_entity_on_marciapiede(range_1: Boolean; range_2: id_corsie; num_entity: Positive;
                                                          speed: new_float; step_to_advance: new_float) is
         node: ptr_list_posizione_abitanti_on_road:= null;
      begin
         node:= slide_list(sidewalk,range_1,range_2,num_entity);
         if speed>0.0 then
            node.posizione_abitante.set_current_speed_abitante(speed);
         end if;
         if step_to_advance>0.0 then
            if range_1=not index_inizio_moto then
               node.posizione_abitante.set_where_next_abitante(node.posizione_abitante.get_where_now_posizione_abitanti+step_to_advance);
            else
               if node.posizione_abitante.get_where_now_posizione_abitanti+step_to_advance>risorsa_features.get_lunghezza_road then
                  node.posizione_abitante.set_where_next_abitante(risorsa_features.get_lunghezza_road);
               else
                  node.posizione_abitante.set_where_next_abitante(node.posizione_abitante.get_where_now_posizione_abitanti+step_to_advance);
               end if;
            end if;
         end if;
      end set_move_parameters_entity_on_marciapiede;

      function slide_list(type_structure: data_structures_types; range_1: Boolean; range_2: id_corsie; index_to_slide: Positive) return ptr_list_posizione_abitanti_on_road is
         list: ptr_list_posizione_abitanti_on_road:= null;
         current_node: ptr_list_posizione_abitanti_on_road:= null;
      begin
         case type_structure is
            when road =>
               list:= main_strada(range_1,1);
            when sidewalk =>
               list:= marciapiedi(range_1,range_2);
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

      procedure registra_abitante_to_move(type_structure: data_structures_types; range_2: id_corsie) is
         list_abitanti: ptr_list_posizione_abitanti_on_road:= new list_posizione_abitanti_on_road;
         abitante: posizione_abitanti_on_road;
      begin
         case type_structure is
            when road =>
               if main_strada_temp/=null then
                  list_abitanti.next:= main_strada(index_inizio_moto,1);
                  main_strada(index_inizio_moto,1):= list_abitanti;
                  abitante:= posizione_abitanti_on_road(create_new_posizione_abitante(main_strada_temp.posizione_abitante.get_id_abitante_posizione_abitanti,
                                                        main_strada_temp.posizione_abitante.get_id_quartiere_posizione_abitanti,0.0,0.0,0.0,False,
                                                        False,0.0,False,create_trajectory_to_follow(0,0,0,0,empty),0));
                  list_abitanti.posizione_abitante:= abitante;
                  main_strada_number_entity(index_inizio_moto,1):= main_strada_number_entity(index_inizio_moto,1)+1;
                  main_strada_temp:= main_strada_temp.next;
               end if;
            when sidewalk =>
               case range_2 is
                  when 1 =>
                     if bici_temp/=null then
                        list_abitanti.next:= marciapiedi(index_inizio_moto,1);
                        marciapiedi(index_inizio_moto,1):= list_abitanti;
                        abitante:= posizione_abitanti_on_road(create_new_posizione_abitante(bici_temp.posizione_abitante.get_id_abitante_posizione_abitanti,
                                                              bici_temp.posizione_abitante.get_id_quartiere_posizione_abitanti,0.0,0.0,0.0,False,
                                                              False,0.0,False,create_trajectory_to_follow(0,0,0,0,empty),0));
                        list_abitanti.posizione_abitante:= abitante;
                        bici_temp:= bici_temp.next;
                     end if;
                  when 2 =>
                     if pedoni_temp/=null then
                        list_abitanti.next:= marciapiedi(index_inizio_moto,2);
                        marciapiedi(index_inizio_moto,2):= list_abitanti;
                        abitante:= posizione_abitanti_on_road(create_new_posizione_abitante(pedoni_temp.posizione_abitante.get_id_abitante_posizione_abitanti,
                                                              pedoni_temp.posizione_abitante.get_id_quartiere_posizione_abitanti,0.0,0.0,0.0,False,
                                                              False,0.0,False,create_trajectory_to_follow(0,0,0,0,empty),0));
                        list_abitanti.posizione_abitante:= abitante;
                        pedoni_temp:= pedoni_temp.next;
                     end if;
               end case;
               marciapiedi_number_entity(index_inizio_moto,range_2):= marciapiedi_number_entity(index_inizio_moto,range_2)+1;
         end case;
      end registra_abitante_to_move;

      procedure new_abitante_to_move(id_quartiere: Positive; id_abitante: Positive; mezzo: means_of_carrying) is
         list_abitanti: ptr_list_posizione_abitanti_on_road:= new list_posizione_abitanti_on_road;
         abitante: posizione_abitanti_on_road;
         last_node: ptr_list_posizione_abitanti_on_road:= null;
      begin
         abitante:= posizione_abitanti_on_road(create_new_posizione_abitante(id_abitante,id_quartiere,0.0,0.0,0.0,False,False,0.0,False,create_trajectory_to_follow(0,0,0,0,empty),0));
         list_abitanti.posizione_abitante:= abitante;
         case mezzo is
            when walking =>
               if pedoni_temp=null then
                  pedoni_temp:= list_abitanti;
               else
                  last_node:= pedoni_temp;
                  while last_node.next/=null loop
                     last_node:= last_node.next;
                  end loop;
                  last_node.next:= list_abitanti;
               end if;
            when bike =>
               if bici_temp=null then
                  bici_temp:= list_abitanti;
               else
                  last_node:= bici_temp;
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

      procedure new_abitante_finish_route(abitante: posizione_abitanti_on_road) is
      begin
         -- guardando destination.corsia_to_go si capisce se l'abitante arriva da entrata_andata o entrata_ritorno
         temp_abitante_finish_route:= abitante;
      end new_abitante_finish_route;

      procedure update_position_entity(state_view_abitanti: in out JSON_Array) is--; type_structure: data_structures_types; range_1: Boolean; index_entity: Positive) is
         nodo: ptr_list_posizione_abitanti_on_road:= null;
         state_view_abitante: JSON_Value;
         list: ptr_list_posizione_abitanti_on_road;
      begin
         for i in main_strada'Range(1) loop
            list:= main_strada(i,1);
            for j in 1..main_strada_number_entity(i,1) loop
               list.posizione_abitante.set_where_now_abitante(list.posizione_abitante.get_where_next_posizione_abitanti);
               state_view_abitante:= create_car_ingresso_state(list.posizione_abitante.get_id_quartiere_posizione_abitanti,list.posizione_abitante.get_id_abitante_posizione_abitanti,get_id_quartiere,id_risorsa,Float(list.posizione_abitante.get_where_now_posizione_abitanti),risorsa_features.get_polo_ingresso);
               Append(state_view_abitanti,state_view_abitante);
               list:= list.next;
            end loop;
         end loop;

         -- controllo di possibili errori
         for i in main_strada'Range(1) loop
            list:= main_strada(i,1);
            while list/=null loop
               if list.next/=null then
                  if list.posizione_abitante.get_where_now_posizione_abitanti>list.next.posizione_abitante.get_where_now_posizione_abitanti then
                     Put_Line("Errore distanze: " & Positive'Image(list.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list.posizione_abitante.get_id_abitante_posizione_abitanti) & ">" & Positive'Image(list.next.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list.next.posizione_abitante.get_id_abitante_posizione_abitanti));
                     raise distanza_next_abitante_minore;
                  end if;
               end if;
               list:= list.next;
            end loop;
         end loop;
      end update_position_entity;

      procedure update_avanzamento_car_in_urbana(distance: new_float) is
      begin
         car_avanzamento_in_urbana:= distance;
      end update_avanzamento_car_in_urbana;

      procedure delete_car_in_uscita is
         ptr_abitante: ptr_list_posizione_abitanti_on_road;
      begin
         if main_strada_number_entity(index_inizio_moto,1)=1 then
            last_abitante_in_urbana:= main_strada(index_inizio_moto,1).posizione_abitante;
            main_strada(index_inizio_moto,1):= null;
         else
            ptr_abitante:= slide_list(road,index_inizio_moto,1,main_strada_number_entity(index_inizio_moto,1)-1);
            last_abitante_in_urbana:= ptr_abitante.next.posizione_abitante;
            ptr_abitante.next:= null;
         end if;
         main_strada_number_entity(index_inizio_moto,1):= main_strada_number_entity(index_inizio_moto,1)-1;
      end delete_car_in_uscita;

      procedure delete_car_in_entrata(id_abitante: Positive) is
         list: ptr_list_posizione_abitanti_on_road;
      begin
         if main_strada_number_entity(not index_inizio_moto,1)=1 then
            main_strada(not index_inizio_moto,1):= null;
         else
            list:= slide_list(road,not index_inizio_moto,1,main_strada_number_entity(not index_inizio_moto,1)-1);
            if list.next.posizione_abitante.get_id_abitante_posizione_abitanti/=id_abitante then
               Put_Line("current abitante " & Positive'Image(id_abitante) & " e quart " & Positive'Image(get_id_quartiere) & "abitante in errore next " & Positive'Image(list.next.posizione_abitante.get_id_abitante_posizione_abitanti) & " quartiere " & Positive'Image(list.next.posizione_abitante.get_id_quartiere_posizione_abitanti));
               raise list_abitanti_error;
            else
               list.next:= null;
            end if;
         end if;
         main_strada_number_entity(not index_inizio_moto,1):= main_strada_number_entity(not index_inizio_moto,1)-1;
      end delete_car_in_entrata;

      procedure delete_bipede_in_uscita(range_2: id_corsie) is
      begin
         null;
      end delete_bipede_in_uscita;

      procedure delete_bipede_in_entrata(id_abitante: Positive; range_2: id_corsie) is
      begin
         null;
      end delete_bipede_in_entrata;

      procedure set_flag_spostamento_from_urbana_completato(car: posizione_abitanti_on_road) is
      begin
         if main_strada(not index_inizio_moto,1).posizione_abitante.get_id_quartiere_posizione_abitanti/=car.get_id_quartiere_posizione_abitanti or else main_strada(not index_inizio_moto,1).posizione_abitante.get_id_abitante_posizione_abitanti/=car.get_id_abitante_posizione_abitanti then
            raise list_abitanti_error;
         end if;
         main_strada(not index_inizio_moto,1).posizione_abitante.set_flag_overtake_next_corsia(True);
      end set_flag_spostamento_from_urbana_completato;

      procedure sposta_abitanti_in_entrata_ingresso is
         pragma Warnings(off);
         default_abitante: posizione_abitanti_on_road;
         pragma Warnings(on);
         new_abitante: ptr_list_posizione_abitanti_on_road;
      begin
         if temp_abitante_finish_route.get_id_quartiere_posizione_abitanti/=0 then
            new_abitante:= create_new_list_posizione_abitante(create_new_posizione_abitante_from_copy(temp_abitante_finish_route),main_strada(not index_inizio_moto,1));
            if new_abitante.posizione_abitante.get_destination.get_corsia_to_go_trajectory=2 then -- traiettoria da entrata_andata
               new_abitante.posizione_abitante.set_where_next_abitante(new_abitante.posizione_abitante.get_where_now_posizione_abitanti-get_traiettoria_ingresso(entrata_andata).get_lunghezza);
            else
               new_abitante.posizione_abitante.set_where_next_abitante(new_abitante.posizione_abitante.get_where_now_posizione_abitanti-get_traiettoria_ingresso(entrata_ritorno).get_lunghezza);
            end if;
            if new_abitante.posizione_abitante.get_where_next_posizione_abitanti>=get_ingresso_from_id(id_risorsa).get_lunghezza_road/2.0 then
               new_abitante.posizione_abitante.set_where_next_abitante(get_ingresso_from_id(id_risorsa).get_lunghezza_road/2.0);
               new_abitante.posizione_abitante.set_current_speed_abitante(new_abitante.posizione_abitante.get_current_speed_abitante/2.0);
            end if;
            new_abitante.posizione_abitante.set_where_now_abitante(new_abitante.posizione_abitante.get_where_next_posizione_abitanti);
            if main_strada(not index_inizio_moto,1)/=null then
               new_abitante.next:= main_strada(not index_inizio_moto,1);
            end if;
            main_strada(not index_inizio_moto,1):= new_abitante;
            main_strada_number_entity(not index_inizio_moto,1):= main_strada_number_entity(not index_inizio_moto,1)+1;
            temp_abitante_finish_route:= default_abitante;
         end if;
      end sposta_abitanti_in_entrata_ingresso;

      function get_main_strada(range_1: Boolean) return ptr_list_posizione_abitanti_on_road is
      begin
         return main_strada(range_1,1);
      end get_main_strada;

      function get_marciapiede(range_1: Boolean; range_2: id_corsie) return ptr_list_posizione_abitanti_on_road is
      begin
         return marciapiedi(range_1,range_2);
      end get_marciapiede;

      function get_number_entity_strada(range_1: Boolean) return Natural is
      begin
         return main_strada_number_entity(range_1,1);
      end get_number_entity_strada;

      function get_number_entity_marciapiede(range_1: Boolean; range_2: id_corsie) return Natural is
      begin
         return marciapiedi_number_entity(range_1,range_2);
      end get_number_entity_marciapiede;

      function get_temp_main_strada return ptr_list_posizione_abitanti_on_road is
      begin
         return main_strada_temp;
      end get_temp_main_strada;

      function get_temp_marciapiede(range_2: id_corsie) return ptr_list_posizione_abitanti_on_road is
      begin
         case range_2 is
            when 1 =>
               return bici_temp;
            when 2 =>
               return pedoni_temp;
         end case;
      end get_temp_marciapiede;

      function get_index_inizio_moto return Boolean is
      begin
         return index_inizio_moto;
      end get_index_inizio_moto;

      function get_first_abitante_to_exit_from_urbana return ptr_list_posizione_abitanti_on_road is
      begin
         return main_strada(not index_inizio_moto,1);
      end get_first_abitante_to_exit_from_urbana;

      function get_car_avanzamento return new_float is
      begin
         return car_avanzamento_in_urbana;
      end get_car_avanzamento;

      function get_last_abitante_in_urbana return posizione_abitanti_on_road is
      begin
         return last_abitante_in_urbana;
      end get_last_abitante_in_urbana;

      function get_last_abitante_in_marciapiede(range_2: id_corsie) return posizione_abitanti_on_road is
      begin
         case range_2 is
            when 1 =>
               return last_abitante_in_marciapiede_1;
            when 2 =>
               return last_abitante_in_marciapiede_1;
         end case;
      end get_last_abitante_in_marciapiede;

      procedure configure(risorsa: strada_ingresso_features; inizio_moto: Boolean) is
      begin
         risorsa_features:= risorsa;
         index_inizio_moto:= inizio_moto;
      end configure;
   end resource_segmento_ingresso;

   --procedure update_bound_next_car_in_incrocio(previous_bound: in out Float; new_bound: Float) is
   --begin
      -- FIRST TIME previous_bound=-1.0 per indicare che non è settato; settato a -1.0 dato che se esiste è > 0
   --   if previous_bound=-1.0 then
   --      previous_bound:= new_bound;
   --   elsif new_bound<previous_bound then
   --      previous_bound:= new_bound;
   --   end if;
   --end update_bound_next_car_in_incrocio;

   protected body resource_segmento_incrocio is

      procedure update_avanzamento_car(abitante: in out ptr_list_posizione_abitanti_on_road; new_step: new_float; new_speed: new_float; step_is_just_calculated: Boolean:= False) is
      begin
         if new_speed>0.0 then
            abitante.posizione_abitante.set_current_speed_abitante(new_speed);
         end if;
         if new_step>0.0 then
            if step_is_just_calculated then
               abitante.posizione_abitante.set_where_next_abitante(new_step);
            else
               abitante.posizione_abitante.set_where_next_abitante(abitante.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+new_step);
            end if;
         end if;
      end update_avanzamento_car;

      procedure create_img(json_1: out JSON_Value) is
         --json_2: JSON_Value;
         --json_3: JSON_Value;
         --json_abitanti: JSON_Array;
         --json_abitante: JSON_Value;
         --list: ptr_list_posizione_abitanti_on_road;
         --new_position_abitanti: Float;
      begin
         null;
         --begin
         --json_1:= Create_Object;
         --json_1.Set_Field("verso_semafori_verdi",verso_semafori_verdi);

         --"car_to_move": {"1": {"1":[{},{}],"2":[{},{}]},{"size_incrocio"}}
         --json_2:= Create_Object;
         --for i in car_to_move'Range(1) loop
         --   json_3:= Create_Object;
         --   for j in car_to_move'Range(2) loop
         --      list:= car_to_move(i,j);
         --      json_abitanti:= Empty_Array;
         --      while list/=null loop
         --         if list.posizione_abitante.get_where_now_posizione_abitanti>=get_traiettoria_incrocio(list.posizione_abitante.get_destination.get_traiettoria_incrocio_to_follow).get_lunghezza_traiettoria_incrocio then
         --            new_position_abitanti:= Float'Last;
         --         else
         --            new_position_abitanti:= -1.0;
         --         end if;
         --         json_abitante:= create_img_abitante(list.posizione_abitante,new_position_abitanti);
         --         Append(json_abitanti,json_abitante);
         --         list:= list.next;
         --      end loop;
         --      json_3.Set_Field(Positive'Image(j),json_abitanti);
         --   end loop;
         --   json_2.Set_Field(Positive'Image(i),json_3);
         --end loop;
         --json_1.Set_Field("car_to_move",json_2);
         --exception
         --   when others =>
         --      Put_Line("errore nella creazione incrocio in: " & Positive'Image(get_id_quartiere) & " " & Positive'Image(id_risorsa));
         --      raise set_field_json_error;
         --end;
      end create_img;

      procedure recovery_resource is
         --json_resource: JSON_Value;
         --json_main_strada: JSON_Value;
         --json_1: JSON_Value;
         --json_2: JSON_Value;
         --json_abitanti: JSON_Array;
      begin
         null;
         --share_snapshot_file_quartiere.get_json_value_resource_snap(id_risorsa,json_resource);

         --verso_semafori_verdi:= json_resource.Get("verso_semafori_verdi");

         --json_main_strada:= json_resource.Get("car_to_move");
         --for i in 1..size_incrocio loop
         --   json_1:= json_main_strada.Get(Positive'Image(i));
         --   for j in 1..2 loop
         --      json_abitanti:= json_1.Get(Positive'Image(j));
         --      car_to_move(i,j):= create_array_abitanti(json_abitanti);
         --   end loop;
         --end loop;

      end recovery_resource;

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
         --new_abitante: ptr_list_posizione_abitanti_on_road:= new list_posizione_abitanti_on_road;
         copy_car: posizione_abitanti_on_road:= car;
      begin
         --key_road:= get_index_road_from_incrocio(from_id_quartiere,from_id_road,id_risorsa);
         --copy_car.set_where_now_abitante(0.0);
         --copy_car.set_where_next_abitante(0.0);
         --copy_car.set_current_speed_abitante(0.0);
         --copy_car.set_flag_overtake_next_corsia(False);
         --if key_road/=0 then
         --   Put_Line("inserito in incrocio id abitante " & Positive'Image(car.get_id_abitante_posizione_abitanti) & " from road " & Positive'Image(key_road) & " corsia to go " & Positive'Image(copy_car.get_destination.get_corsia_to_go_trajectory) & " where: " & Float'Image(copy_car.get_where_now_posizione_abitanti));
         --   new_abitante.posizione_abitante:= copy_car;
         --   new_abitante.next:= car_to_move(key_road,car.get_destination.get_corsia_to_go_trajectory);
         --   car_to_move(key_road,car.get_destination.get_corsia_to_go_trajectory):= new_abitante;
         --else
         --   Put_Line("macchina non inserita");
         --end if;


         key_road:= get_index_road_from_incrocio(from_id_quartiere,from_id_road,id_risorsa);
         copy_car.set_flag_overtake_next_corsia(False);
         if key_road/=0 then
            Put_Line("inserito in incrocio id abitante " & Positive'Image(car.get_id_abitante_posizione_abitanti) & " from road " & Positive'Image(key_road) & " corsia to go " & Positive'Image(copy_car.get_destination.get_corsia_to_go_trajectory) & " where: " & new_float'Image(copy_car.get_where_now_posizione_abitanti));
            --new_abitante.posizione_abitante:= copy_car;
            --new_abitante.next:= car_to_move(key_road,car.get_destination.get_corsia_to_go_trajectory);
            if temp_car_to_move(key_road,copy_car.get_destination.get_corsia_to_go_trajectory).get_id_quartiere_posizione_abitanti/=0 then
               raise list_abitanti_error;
            end if;
            temp_car_to_move(key_road,copy_car.get_destination.get_corsia_to_go_trajectory):= copy_car;
         else
            Put_Line("macchina non inserita");
         end if;
      end insert_new_car;

      procedure update_avanzamento_cars(state_view_abitanti: in out JSON_Array) is
         list: ptr_list_posizione_abitanti_on_road;
         prec_list: ptr_list_posizione_abitanti_on_road;
         traiettoria_car: traiettoria_incroci_type;
         length_traiettoria: new_float;
         state_view_abitante: JSON_Value;
         from_road: tratto;
         road: road_incrocio_features;
         abitante: posizione_abitanti_on_road;
         new_abitante: ptr_list_posizione_abitanti_on_road;
         pragma Warnings(off);
         default_abitante: posizione_abitanti_on_road;
         pragma Warnings(on);
      begin
         for i in 1..size_incrocio loop
            for j in id_corsie'Range loop
               list:= car_to_move(i,j);
               prec_list:= null;
               while list/=null loop
                  list.posizione_abitante.set_where_now_abitante(list.posizione_abitante.get_where_next_posizione_abitanti);
                  traiettoria_car:= list.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow;
                  length_traiettoria:= get_traiettoria_incrocio(traiettoria_car).get_lunghezza_traiettoria_incrocio;
                  if list.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=length_traiettoria then
                     -- controlla se list è stato cancellato dall'urbana
                     if list.posizione_abitante.get_flag_overtake_next_corsia=False then
                        list.posizione_abitante.set_flag_overtake_next_corsia(True);
                        ptr_rt_urbana(get_id_urbana_quartiere(list.posizione_abitante.get_destination.get_departure_corsia,list.posizione_abitante.get_destination.get_from_ingresso)).remove_abitante_in_incrocio(get_road_from_incrocio(id_risorsa,get_index_road_from_incrocio(list.posizione_abitante.get_destination.get_departure_corsia,list.posizione_abitante.get_destination.get_from_ingresso,id_risorsa)).get_polo_road_incrocio,list.posizione_abitante.get_destination.get_corsia_to_go_trajectory,list.posizione_abitante.get_id_quartiere_posizione_abitanti,list.posizione_abitante.get_id_abitante_posizione_abitanti);
                     end if;
                     road:= get_road_from_incrocio(id_risorsa,calulate_index_road_to_go(id_risorsa,i,list.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow));
                     if ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).first_car_abitante_has_passed_incrocio(not road.get_polo_road_incrocio,list.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory) then
                        Put_Line("remove abitante " & Positive'Image(list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti));
                        if prec_list=null then
                           car_to_move(i,j):= car_to_move(i,j).next;
                           list:= car_to_move(i,j);
                        else
                           prec_list.next:= list.next;
                           --prec_list:= list;
                           list:= prec_list.next;
                        end if;
                     else
                        list:= list.next;
                     end if;
                  else
                     from_road:= get_quartiere_utilities_obj.get_classe_locate_abitanti(list.posizione_abitante.get_id_quartiere_posizione_abitanti).get_current_tratto(list.posizione_abitante.get_id_abitante_posizione_abitanti);
                     if get_quartiere_utilities_obj.get_classe_locate_abitanti(list.posizione_abitante.get_id_quartiere_posizione_abitanti).get_current_position(list.posizione_abitante.get_id_abitante_posizione_abitanti)=1 then
                        from_road:= create_tratto(from_road.get_id_quartiere_tratto,get_ref_quartiere(from_road.get_id_quartiere_tratto).get_id_main_road_from_id_ingresso(from_road.get_id_tratto));
                     end if;
                     state_view_abitante:= create_car_incrocio_state(list.posizione_abitante.get_id_quartiere_posizione_abitanti,list.posizione_abitante.get_id_abitante_posizione_abitanti,get_id_quartiere,id_risorsa,Float(list.posizione_abitante.get_where_now_posizione_abitanti),from_road.get_id_quartiere_tratto,from_road.get_id_tratto,traiettoria_car);
                     Append(state_view_abitanti,state_view_abitante);
                     prec_list:= list;
                     list:= list.next;
                  end if;
               end loop;
            end loop;
         end loop;

         for i in 1..size_incrocio loop
            for j in id_corsie'Range loop
               abitante:= temp_car_to_move(i,j);
               if abitante.get_id_quartiere_posizione_abitanti/=0 then
                  new_abitante:= new list_posizione_abitanti_on_road;
                  new_abitante.posizione_abitante:= abitante;
                  new_abitante.next:= car_to_move(i,j);
                  car_to_move(i,j):= new_abitante;
                  temp_car_to_move(i,j):= default_abitante;
               end if;
            end loop;
         end loop;
      end update_avanzamento_cars;

      procedure set_car_have_passed_urbana(abitante: in out ptr_list_posizione_abitanti_on_road) is
      begin
         abitante.posizione_abitante.set_flag_overtake_next_corsia(True);
      end set_car_have_passed_urbana;

      procedure update_avanzamento_in_urbana(abitante: in out ptr_list_posizione_abitanti_on_road; avanzamento: new_float) is
      begin
         abitante.posizione_abitante.set_distance_on_overtaking_trajectory(avanzamento);
      end update_avanzamento_in_urbana;

      procedure update_abitante_destination(abitante: in out ptr_list_posizione_abitanti_on_road; destination: trajectory_to_follow) is
      begin
         abitante.posizione_abitante.set_destination(destination);
      end update_abitante_destination;

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

      function get_posix_first_entity(from_id_quartiere_road: Positive; from_id_road: Positive; num_corsia: id_corsie) return new_float is
         index: Natural:= get_index_road_from_incrocio(from_id_quartiere_road,from_id_road,id_risorsa);
         list: ptr_list_posizione_abitanti_on_road;
      begin
         if index/=0 then
            list:= car_to_move(index,num_corsia);
            if list/=null then
               return list.posizione_abitante.get_where_now_posizione_abitanti;
            end if;
         end if;
         -- se ritorna -1 significa che l'abitante ha già attraversato l'incrocio
         return -1.0;
      end get_posix_first_entity;

      function semaforo_is_verde_from_road(id_quartiere_road: Positive; id_road: Positive) return Boolean is
         index_road: Natural:= get_index_road_from_incrocio(id_quartiere_road,id_road,id_risorsa);
         id_mancante: Natural:= get_mancante_incrocio_a_3(id_risorsa);
      begin
         if get_size_incrocio(id_risorsa)=3 then
            if index_road>=id_mancante then
               index_road:= index_road+1;
            end if;
         end if;
         if verso_semafori_verdi=True and then (index_road=1 or index_road=3) then
            return True;
         else
            if verso_semafori_verdi=False and then (index_road=2 or index_road=4) then
               return True;
            end if;
         end if;
         return False;
      end semaforo_is_verde_from_road;

      function slide_list(num_urbana: Positive; num_corsia: id_corsie; index_to_slide: Positive) return ptr_list_posizione_abitanti_on_road is
         list: ptr_list_posizione_abitanti_on_road:= car_to_move(num_urbana,num_corsia);
      begin
         for i in 1..index_to_slide loop
            if i=index_to_slide then
               return list;
            end if;
            if list/=null then
               list:= list.next;
            else
               return null;
            end if;
         end loop;
         return null;
      end slide_list;

      -- se index_road vale 0 allora anche i deve valere 0 ed occorre calcolarseli => from_id_quartiere_road e from_id_road saranno diversi da 0
      -- id task è l'id dell'incrocio
      -- indice sarebbe l'indice della strada nell'incrocio, se 0 viene calcolato
      -- se num_car=0 allora la macchina non è ancora stata inserita nell'incrocio
      procedure calcola_bound_avanzamento_in_incrocio(index_road: in out Natural; indice: Natural; traiettoria_car: traiettoria_incroci_type; corsia: id_corsie; num_car: Natural; bound_distance: in out new_float; stop_entity: in out Boolean; distance_to_next_car: in out new_float; from_id_quartiere_road: Natural:= 0; from_id_road: Natural:= 0) is
         index_other_road: Natural;
         id_mancante: Natural:= get_mancante_incrocio_a_3(id_risorsa);
         i: Natural:= indice;
         id_task: Positive:= id_risorsa;
         list: ptr_list_posizione_abitanti_on_road;
         list_car: ptr_list_posizione_abitanti_on_road:= null;
         list_near_car: ptr_list_posizione_abitanti_on_road;
         list_near_other_car: ptr_list_posizione_abitanti_on_road;
         can_continue: Boolean;
         traiettoria_near_car: traiettoria_incroci_type;
         road: road_incrocio_features;
         quantità_percorsa: new_float:= 0.0;
         switch: Boolean:= True;
         limite: new_float;
         distanza_intersezione: new_float;
         where_now_car: new_float;
         id_quartiere_next_car: Positive;
         id_abitante_next_car: Positive;
      begin
         stop_entity:= False;
         bound_distance:= -1.0;
         distance_to_next_car:= -1.0;
         if index_road=0 then
            i:= get_index_road_from_incrocio(from_id_quartiere_road,from_id_road,id_task);
            index_road:= i;
            if id_mancante/=0 and i>=id_mancante then  -- condizione valida per incroci a 3
               index_road:= i+1;
            end if;
         end if;

         if num_car/=0 then
            list_car:= slide_list(i,corsia,num_car);
         end if;

         if list_car=null then
            -- se list_car=NULL sai che il semaforo è VERDE
            where_now_car:= 0.0;
         else
            where_now_car:= list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
            -- begin inizializzazione di stop entity
            if where_now_car=0.0 then
               if verso_semafori_verdi=True and then (index_road=1 or index_road=3) then
                  stop_entity:= False;
               elsif verso_semafori_verdi=False and then (index_road=2 or index_road=4) then
                  stop_entity:= False;
               else
                  stop_entity:= True;
               end if;
            else
               stop_entity:= False;
               -- end inizializzazione
            end if;
         end if;

         if num_car/=0 and then list_car=null then
            raise index_abitante_scelto_sbagliato;
         end if;

         if (list_car=null or else (stop_entity=False and then list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=0.0)) then
            index_other_road:= index_road+1;

            if index_other_road=5 then -- index_other_road è la posizione dell'indice della strada nell'incrocio
               index_other_road:= 1;
            end if;
            if id_mancante/=0 and then id_mancante=index_other_road then -- la strada a sx non esiste
               switch:= False;
            end if;
            if switch then -- se true sai che la strada a sinistra esiste
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
                  list_near_car:= get_list_car_to_move(index_other_road,z);
                  can_continue:= True;
                  if traiettoria_car=destra and z=1 then
                     can_continue:= False; -- per le macchine in svolta a dx tutti i controlli sono già stati fatti
                  end if;
                  -- limite impone il limite per le macchine che dalla strada sinistra procedono dritte
                  case traiettoria_car is
                     when dritto | empty =>  -- caso non presentabile
                        limite:= 0.0;
                     when dritto_2 | destra =>
                        limite:= get_traiettoria_incrocio(dritto_2).get_lunghezza_traiettoria_incrocio; -- lunghezza traiettoria dritto1/2; quando necessiti di una traiettoria dritto usa dritto1o2
                     when dritto_1 | sinistra =>
                        limite:= get_traiettoria_incrocio(dritto_1).get_lunghezza_traiettoria_incrocio-get_larghezza_marciapiede-get_larghezza_corsia;
                  end case;

                  while can_continue and stop_entity=False and list_near_car/=null loop
                     traiettoria_near_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow;
                     if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti/=0.0 then
                        if traiettoria_near_car=dritto_1 or traiettoria_near_car=dritto_2 then
                           if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_incrocio(dritto_1).get_lunghezza_traiettoria_incrocio then
                              road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,index_other_road,traiettoria_near_car));
                              quantità_percorsa:= get_traiettoria_incrocio(traiettoria_near_car).get_lunghezza_traiettoria_incrocio+ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                           else
                              quantità_percorsa:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                           end if;
                           if quantità_percorsa-get_quartiere_utilities_obj.get_auto_quartiere(list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<limite then
                              Put_Line("STOP RIGA 2600 " & Positive'Image(list_near_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_near_car.posizione_abitante.get_id_abitante_posizione_abitanti));
                              stop_entity:= True;
                              --if traiettoria_near_car=dritto_2 then
                              --   stop_entity:= True;
                              --else
                              --   update_bound_next_car_in_incrocio(bound_distance,get_larghezza_marciapiede+get_larghezza_corsia);
                              --end if;
                           end if;
                        elsif traiettoria_near_car=sinistra then -- non entrerà mai per z=2 dato che per z=2 dalla corsia 2 le macchine vanno a destra o dritto_2
                           if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_incrocio(sinistra).get_lunghezza_traiettoria_incrocio then
                              road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,index_other_road,traiettoria_near_car));
                              quantità_percorsa:= get_traiettoria_incrocio(traiettoria_near_car).get_lunghezza_traiettoria_incrocio+ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                           else
                              quantità_percorsa:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                           end if;
                           if traiettoria_car=dritto_1 then
                              stop_entity:= True;
                              Put_Line("STOP RIGA 2617 " & Positive'Image(list_near_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_near_car.posizione_abitante.get_id_abitante_posizione_abitanti));
                              --if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti+quantità_percorsa-
                              --  get_quartiere_utilities_obj.get_auto_quartiere(list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva>=get_traiettoria_incrocio(sinistra).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                              --   update_bound_next_car_in_incrocio(bound_distance,get_larghezza_marciapiede+get_larghezza_corsia*2.0); --  larghezza di una mezza strada
                              --else
                              --   update_bound_next_car_in_incrocio(bound_distance,get_larghezza_marciapiede+get_larghezza_corsia*1.5);  -- si fa avanzare la macchina fino a meta della prossima corsia
                              --end if;
                           elsif traiettoria_car=sinistra then
                              if quantità_percorsa-get_quartiere_utilities_obj.get_auto_quartiere(list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                                max_larghezza_veicolo+get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_1).get_distanza_intersezione_incrocio then
                                 stop_entity:= True;
                                 Put_Line("STOP RIGA 2628 " & Positive'Image(list_near_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_near_car.posizione_abitante.get_id_abitante_posizione_abitanti));
                                 --update_bound_next_car_in_incrocio(bound_distance,get_traiettoria_incrocio(sinistra).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie);
                              end if;
                           end if;
                        end if;
                     end if;
                     list_near_car:= list_near_car.get_next_from_list_posizione_abitanti;
                  end loop;
               end loop;
            end if;

            -- END: CONTROLLO MACCHINE IN AVANZAMENTO DALLA STRADA A SINISTRA

            can_continue:= True;
            if traiettoria_car=destra then
               can_continue:= False;
               -- per le macchine in svolta a dx tutti i controlli sono già stati fatti
               -- dato che l'incrocio con altre macchine si poteva avere al più
               -- solo con macchine in arrivo da sinistra
            end if;
            if can_continue and stop_entity=False then
               -- stop_entity=False(la macchina non deve già fermarsi)
               -- BEGIN: CONTROLLO MACCHINE IN AVANZAMENTO DALLA STRADA A DESTRA
               switch:= True;
               index_other_road:= index_road-1;
               if index_other_road=0 then
                  index_other_road:= 4;
               end if;
               if id_mancante/=0 and then id_mancante=index_other_road then -- la strada a dx non esiste
                  switch:= False;
               end if;
               if switch then
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

                  for z in reverse id_corsie'Range loop
                     list_near_car:= get_list_car_to_move(index_other_road,z);
                     case traiettoria_car is
                        when dritto | destra | empty =>  -- caso non presentabile
                           limite:= 0.0;
                        when dritto_2  =>
                           limite:= get_larghezza_marciapiede+get_larghezza_corsia; -- lunghezza mezza corsia
                        when dritto_1  =>
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
                                    quantità_percorsa:= get_traiettoria_incrocio(traiettoria_near_car).get_lunghezza_traiettoria_incrocio+ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                                 else
                                    quantità_percorsa:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                                 end if;

                                 if quantità_percorsa-get_quartiere_utilities_obj.get_auto_quartiere(list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<limite then
                                    --if traiettoria_near_car=dritto_1 then
                                    --   update_bound_next_car_in_incrocio(bound_distance,get_larghezza_marciapiede+get_larghezza_corsia); -- 1 strada
                                    --else
                                    --   update_bound_next_car_in_incrocio(bound_distance,get_larghezza_marciapiede+get_larghezza_corsia*3.0); -- 1 strada e 1/2
                                    --end if;
                                    stop_entity:= True;
                                    Put_Line("STOP RIGA 2702 " & Positive'Image(list_near_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_near_car.posizione_abitante.get_id_abitante_posizione_abitanti));
                                 end if;
                              elsif traiettoria_car=sinistra then
                                 if traiettoria_near_car=dritto_1 then
                                    stop_entity:= True;
                                    Put_Line("STOP RIGA 2707 " & Positive'Image(list_near_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_near_car.posizione_abitante.get_id_abitante_posizione_abitanti));
                                    --update_bound_next_car_in_incrocio(bound_distance,get_traiettoria_incrocio(sinistra).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie);
                                 end if;
                              end if;
                           elsif traiettoria_near_car=destra and traiettoria_car=dritto_2 then -- per z=1 non entrerà mai
                              --update_bound_next_car_in_incrocio(bound_distance,get_larghezza_marciapiede+get_larghezza_corsia*3.0); -- 1 strada e 1/2
                              stop_entity:= True;
                              Put_Line("STOP RIGA 2714 " & Positive'Image(list_near_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_near_car.posizione_abitante.get_id_abitante_posizione_abitanti));
                           elsif traiettoria_near_car=sinistra then-- per z=2 non entrerà mai
                              if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_incrocio(sinistra).get_lunghezza_traiettoria_incrocio then
                                 road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,index_other_road,traiettoria_near_car));
                                 quantità_percorsa:= get_traiettoria_incrocio(traiettoria_near_car).get_lunghezza_traiettoria_incrocio+ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                              else
                                 quantità_percorsa:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                              end if;
                              if traiettoria_car=dritto_1 then
                                 if quantità_percorsa-get_quartiere_utilities_obj.get_auto_quartiere(list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                                  list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_1).get_distanza_intersezione_incrocio+max_larghezza_veicolo then
                                    stop_entity:= True;
                                    Put_Line("STOP RIGA 2726 " & Positive'Image(list_near_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_near_car.posizione_abitante.get_id_abitante_posizione_abitanti));
                                    --update_bound_next_car_in_incrocio(bound_distance,get_larghezza_marciapiede+get_larghezza_corsia);  -- la si fa avanzare sino ad una corsia
                                 end if;
                              elsif traiettoria_car=dritto_2 then
                                 if quantità_percorsa-get_quartiere_utilities_obj.get_auto_quartiere(list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                                  list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<get_traiettoria_incrocio(sinistra).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie+max_larghezza_veicolo then
                                    --update_bound_next_car_in_incrocio(bound_distance,get_larghezza_marciapiede+get_larghezza_corsia*1.5);  -- la si fa avanzare sino ad una corsia
                                    stop_entity:= True;
                                    Put_Line("STOP RIGA 2734 " & Positive'Image(list_near_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_near_car.posizione_abitante.get_id_abitante_posizione_abitanti));
                                 end if;
                              elsif traiettoria_car=sinistra then
                                 if quantità_percorsa-get_quartiere_utilities_obj.get_auto_quartiere(list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                                  list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<get_traiettoria_incrocio(sinistra).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
                                    stop_entity:= True; -- si ferma la macchina che vuole andare a sinistra
                                    Put_Line("STOP RIGA 2740 " & Positive'Image(list_near_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_near_car.posizione_abitante.get_id_abitante_posizione_abitanti));
                                 end if;
                              end if;
                           end if;
                        end if;
                        list_near_car:= list_near_car.get_next_from_list_posizione_abitanti;
                     end loop;
                  end loop;
               end if;-- END: CONTROLLO MACCHINE IN AVANZAMENTO DALLA STRADA A DESTRA


               -- BEGIN: CONTROLLO MACCHINE IN AVANZAMENTO DALLA STRADA OPPOSTA
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
                     null;
                     --list_near_car:= get_list_car_to_move(index_other_road,1);

                     --while list_near_car/=null loop
                        --traiettoria_near_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow;
                        --if traiettoria_near_car=sinistra and then list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>0.0 then
                           --if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_incrocio(sinistra).get_lunghezza_traiettoria_incrocio then
                           --   road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,index_other_road,traiettoria_near_car));
                           --   quantità_percorsa:= get_traiettoria_incrocio(traiettoria_near_car).get_lunghezza_traiettoria_incrocio+ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                           --else
                           --   quantità_percorsa:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                           --end if;
                           --if quantità_percorsa-get_quartiere_utilities_obj.get_auto_quartiere(list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                           --                                                       list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                           --  get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(traiettoria_car).get_distanza_intersezione_incrocio+max_larghezza_veicolo then
                           --   stop_entity:= True;
                           --   Put_Line("STOP RIGA 2783 " & Positive'Image(list_near_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_near_car.posizione_abitante.get_id_abitante_posizione_abitanti));
                           --end if;

                        --end if;
                       -- list_near_car:= list_near_car.get_next_from_list_posizione_abitanti;
                     --end loop;
                  elsif traiettoria_car=sinistra then
                     null;
                     --for z in id_corsie'Range loop
                     --   list_near_car:= get_list_car_to_move(index_other_road,z);
                     --   while list_near_car/=null loop
                     --      traiettoria_near_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow;
                     --      if traiettoria_near_car=dritto_1 or traiettoria_near_car=dritto_2 then
                     --         if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_incrocio(dritto_1).get_lunghezza_traiettoria_incrocio then
                     --            road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,index_other_road,traiettoria_near_car));
                     --            quantità_percorsa:= get_traiettoria_incrocio(traiettoria_near_car).get_lunghezza_traiettoria_incrocio+ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                     --         else
                     --            quantità_percorsa:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                     --         end if;
                     --         if quantità_percorsa-get_quartiere_utilities_obj.get_auto_quartiere(list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                     --                                                                              list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                     --           get_traiettoria_incrocio(traiettoria_near_car).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio+max_larghezza_veicolo then  -- distanza ultima corsia
                                   --update_bound_next_car_in_incrocio(bound_distance,get_traiettoria_incrocio(sinistra).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie);
                     --            distance_to_next_car:= get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_1).get_distanza_intersezione_incrocio+max_larghezza_veicolo;
                     --         end if;
                     --      end if;
                     --      list_near_car:= list_near_car.get_next_from_list_posizione_abitanti;
                     --   end loop;
                     --end loop;
                  end if;
               end if;
            -- END: CONTROLLO MACCHINE IN AVANZAMENTO DALLA STRADA OPPOSTA
            end if;
         end if;


         -- ORA SI PROCEDE CON IL CALCOLO DELL'AVANZAMENTO UNA VOLTA CALCOLATO, SE NECESSARIO IL bound_distance
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
               switch:= True; -- MANCA LA STRADA OPPOSTA
            end if;
            if traiettoria_car=destra then
               if list_car/=null then
                  list:= list_car.next;
               else
                  list:= car_to_move(i,corsia);
               end if;
               list_near_car:= null;
               list_near_other_car:= null;
               while list/=null loop
                  traiettoria_near_car:= list.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow;
                  if list_near_other_car=null and traiettoria_near_car=dritto_2 then
                     list_near_other_car:= list;
                  end if;
                  if list_near_car=null and traiettoria_near_car=destra then
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
                  Put_Line("STOP RIGA 2864 " & Positive'Image(list_near_other_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_near_other_car.posizione_abitante.get_id_abitante_posizione_abitanti));
               end if;
               if stop_entity=False then
                  if list_near_car/=null then  -- si ha una macchina davanti che è in svolta a dx
                     id_quartiere_next_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                     id_abitante_next_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                     if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_incrocio(destra).get_lunghezza_traiettoria_incrocio then
                        road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,i,traiettoria_car));
                        quantità_percorsa:= get_traiettoria_incrocio(destra).get_lunghezza_traiettoria_incrocio+ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                     else
                        quantità_percorsa:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                     end if;
                     distance_to_next_car:= quantità_percorsa-get_quartiere_utilities_obj.get_auto_quartiere(id_quartiere_next_car,id_abitante_next_car).get_length_entità_passiva-where_now_car;
                  else
                     road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,i,traiettoria_car));
                     distance_to_next_car:= ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,2);
                     if distance_to_next_car/=-1.0 then
                        distance_to_next_car:= distance_to_next_car+get_traiettoria_incrocio(destra).get_lunghezza_traiettoria_incrocio-where_now_car;
                     end if;
                  end if;
               end if;
            elsif traiettoria_car=dritto_1 or traiettoria_car=dritto_2 then

               -- primo step di fermo a intersezione traiettoria sx - 3.0
               -- è presente la strada opposta alla strada corrente
               -- cerca elemento della strada opposita che vuole girara a sinistra

               -- prima viene calcolato se la macchina può avanzare in relazione alle macchine che ha davanti
               if list_car/=null then
                  list:= list_car.next;
               else
                  list:= car_to_move(i,corsia);
               end if;
               list_near_car:= null;
               list_near_other_car:= null;
               while list/=null and (list_near_other_car=null or list_near_car=null) loop
                  traiettoria_near_car:= list.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow;
                  if list_near_other_car=null and (traiettoria_near_car=destra or traiettoria_near_car=sinistra) then
                     list_near_other_car:= list;
                  end if;
                  if list_near_car=null and (traiettoria_near_car=dritto_1 or traiettoria_near_car=dritto_2) then
                     list_near_car:= list;
                  end if;
                  list:= list.get_next_from_list_posizione_abitanti;
               end loop;
               if list_near_other_car/=null then
                  traiettoria_near_car:= list_near_other_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow;
                  if traiettoria_near_car=destra then
                     stop_entity:= True;
                     Put_Line("STOP RIGA 2913 " & Positive'Image(list_near_other_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_near_other_car.posizione_abitante.get_id_abitante_posizione_abitanti));
                  else  --  =sinistra
                     if list_near_other_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                       get_quartiere_utilities_obj.get_auto_quartiere(list_near_other_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                      list_near_other_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                       get_traiettoria_incrocio(sinistra).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
                        stop_entity:= True;
                        Put_Line("STOP RIGA 2920 " & Positive'Image(list_near_other_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_near_other_car.posizione_abitante.get_id_abitante_posizione_abitanti));
                     end if;
                  end if;
               end if;
               if stop_entity=False then
                  if list_near_car/=null then  -- si ha una macchina davanti che procede in direzione dritto_1/dritto_2
                     id_quartiere_next_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                     id_abitante_next_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                     if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_incrocio(dritto_1).get_lunghezza_traiettoria_incrocio then
                        road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,i,traiettoria_car));
                        quantità_percorsa:= get_traiettoria_incrocio(traiettoria_car).get_lunghezza_traiettoria_incrocio+ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                     else
                        quantità_percorsa:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                     end if;
                     distance_to_next_car:= quantità_percorsa-get_quartiere_utilities_obj.get_auto_quartiere(id_quartiere_next_car,id_abitante_next_car).get_length_entità_passiva-where_now_car;
                  else
                     road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,i,traiettoria_car));
                     if traiettoria_car=dritto_2 then
                        distance_to_next_car:= ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,2);  -- ask next strada dovè la prox macchina + somma la traiettoria percorsa
                     else
                        distance_to_next_car:= ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,1);  -- ask next strada dovè la prox macchina + somma la traiettoria percorsa
                     end if;
                     if distance_to_next_car/=-1.0 then
                        distance_to_next_car:= distance_to_next_car+get_traiettoria_incrocio(dritto_1).get_lunghezza_traiettoria_incrocio-where_now_car;
                     end if;
                     -- ask next strada dovè la prox macchina + somma la traiettoria percorsa
                  end if;
                  if switch=False then
                     -- si controlla se la macchina ha delle macchine a sx che avanzano nella strada opposta
                     distanza_intersezione:= get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(traiettoria_car).get_distanza_intersezione_incrocio;
                     limite:= get_traiettoria_incrocio(traiettoria_car).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio;

                     -- controlla se ho macchine che arrivano da sx solo se posso trovarmele davanti
                     if list_car=null or else list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti<=limite-max_larghezza_veicolo then
                        list_near_car:= get_list_car_to_move(index_other_road,1);
                        while list_near_car/=null and stop_entity=False loop
                           traiettoria_near_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow;
                           if traiettoria_near_car=sinistra then
                              if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>distanza_intersezione-max_larghezza_veicolo then
                                 --  distanza_intersezione-max_larghezza_veicolo indica distanza pt intersezione con traiettoria dritto_1
                                 -- si ferma sempre nel punto distanza_intersezione-max_larghezza_veicolo, la volta dopo avanza sse non si hanno macchine che vanno diritte
                                 if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_incrocio(sinistra).get_lunghezza_traiettoria_incrocio then
                                    road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,index_other_road,traiettoria_near_car));
                                    quantità_percorsa:= get_traiettoria_incrocio(traiettoria_near_car).get_lunghezza_traiettoria_incrocio+ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                                 else
                                    quantità_percorsa:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                                 end if;
                                 id_quartiere_next_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                                 id_abitante_next_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                                 if quantità_percorsa-get_quartiere_utilities_obj.get_auto_quartiere(id_quartiere_next_car,id_abitante_next_car).get_length_entità_passiva<limite+max_larghezza_veicolo then
                                    if distance_to_next_car=-1.0 then
                                       if list_car/=null and then list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=limite-max_larghezza_veicolo then
                                          -- distance_next_car=0.0
                                          stop_entity:= True;
                                       else
                                          distance_to_next_car:= limite-max_larghezza_veicolo;
                                       end if;
                                    else
                                       if distance_to_next_car+where_now_car>limite-max_larghezza_veicolo then
                                          if list_car/=null and then list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=limite-max_larghezza_veicolo then
                                             -- distance_next_car=0.0
                                             stop_entity:= True;
                                          else
                                             distance_to_next_car:= limite-max_larghezza_veicolo;
                                          end if;
                                       else
                                          null;
                                       end if;
                                    end if;
                                    stop_entity:= True;
                                    if list_car=null then
                                       Put_Line("STOP RIGA 2971 " & Positive'Image(list_near_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_near_car.posizione_abitante.get_id_abitante_posizione_abitanti));
                                    else
                                       Put_Line("STOP RIGA 2971 " & Positive'Image(list_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_car.posizione_abitante.get_id_abitante_posizione_abitanti) & " a causa di " & Positive'Image(list_near_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_near_car.posizione_abitante.get_id_abitante_posizione_abitanti) & " where: " & new_float'Image(list_car.posizione_abitante.get_where_now_posizione_abitanti));
                                    end if;
                                 end if;
                              end if;
                           end if;
                           list_near_car:= list_near_car.get_next_from_list_posizione_abitanti;
                        end loop;
                     end if;
                  end if;
               end if;

            elsif traiettoria_car=sinistra then
               if list_car/=null then
                  list:= list_car.next;
               else
                  list:= car_to_move(i,corsia);
               end if;
               list_near_car:= null;
               list_near_other_car:= null;
               while list/=null and (list_near_other_car=null or list_near_car=null) loop
                  traiettoria_near_car:= list.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_traiettoria_incrocio_to_follow;
                  if list_near_other_car=null and traiettoria_near_car=dritto_1 then
                     list_near_other_car:= list;
                  end if;
                  if list_near_car=null and traiettoria_near_car=sinistra then
                     list_near_car:= list;
                  end if;
                  list:= list.get_next_from_list_posizione_abitanti;
               end loop;

               if list_near_other_car/=null then
                  if list_near_other_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                    get_quartiere_utilities_obj.get_auto_quartiere(list_near_other_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                            list_near_other_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<get_larghezza_marciapiede+get_larghezza_corsia*1.5 then
                     stop_entity:= True;
                     if list_car=null then
                        Put_Line("STOP RIGA 3005 " & Positive'Image(list_near_other_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_near_other_car.posizione_abitante.get_id_abitante_posizione_abitanti));
                     else
                        Put_Line("STOP RIGA 3005 " & Positive'Image(list_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_car.posizione_abitante.get_id_abitante_posizione_abitanti) & " a causa di " & Positive'Image(list_near_other_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_near_other_car.posizione_abitante.get_id_abitante_posizione_abitanti) & " where: " & new_float'Image(list_car.posizione_abitante.get_where_now_posizione_abitanti));
                     end if;
                  end if;
               end if;
               if stop_entity=False then
                  if list_near_car/=null then  -- si ha una macchina davanti che procede in direzione sinistra
                     id_quartiere_next_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti;
                     id_abitante_next_car:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti;
                     if list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti>=get_traiettoria_incrocio(sinistra).get_lunghezza_traiettoria_incrocio then
                        road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,i,traiettoria_car));
                        quantità_percorsa:= get_traiettoria_incrocio(sinistra).get_lunghezza_traiettoria_incrocio+ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_destination.get_corsia_to_go_trajectory);
                     else
                        quantità_percorsa:= list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti;
                     end if;
                     distance_to_next_car:= quantità_percorsa-get_quartiere_utilities_obj.get_auto_quartiere(id_quartiere_next_car,id_abitante_next_car).get_length_entità_passiva-where_now_car;
                  else
                     road:= get_road_from_incrocio(id_task,calulate_index_road_to_go(id_task,i,traiettoria_car));
                     distance_to_next_car:= ptr_rt_urbana(get_id_urbana_quartiere(road.get_id_quartiere_road_incrocio,road.get_id_strada_road_incrocio)).get_distanza_percorsa_first_abitante(not road.get_polo_road_incrocio,1);  -- ask next strada dovè la prox macchina + somma la traiettoria percorsa
                     if distance_to_next_car/=-1.0 then
                        distance_to_next_car:= distance_to_next_car+get_traiettoria_incrocio(sinistra).get_lunghezza_traiettoria_incrocio-where_now_car;
                     end if;
                  end if;
                  if switch=False then  -- esiste la strada opposta
                     for z in id_corsie'Range loop
                        list_near_car:= get_list_car_to_move(index_other_road,z);
                        while stop_entity=False and list_near_car/=null loop
                           -- cicla e guarda se ci sono macchine che vogliono andare dritto
                           -- !!!!!!!!********* DA AGGIUNGERE CONTROLLO CHE LA MACCHINA IN LIST_NEAR_CAR STIA ANDANDO A SINISTRA
                           if z=1 and then (list_car=null or else list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=
                                              get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_1).get_distanza_intersezione_incrocio-max_larghezza_veicolo) then
                              -- distanza con intersezione dritto1
                              -- si ha una macchina che vuole andare verso dritto_1 dato che list_near_car/=null
                              if list_near_car.posizione_abitante.get_destination.get_traiettoria_incrocio_to_follow=dritto_1 and then list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-get_quartiere_utilities_obj.get_auto_quartiere(list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                                                                                                                                   list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                                get_traiettoria_incrocio(dritto_1).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio+max_larghezza_veicolo then
                                 stop_entity:= True;
                                 if list_car=null then
                                    Put_Line("STOP RIGA 3039 " & Positive'Image(list_near_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_near_car.posizione_abitante.get_id_abitante_posizione_abitanti));
                                 else
                                    Put_Line("STOP RIGA 3039 " & Positive'Image(list_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_car.posizione_abitante.get_id_abitante_posizione_abitanti) & " a causa di " & Positive'Image(list_near_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_near_car.posizione_abitante.get_id_abitante_posizione_abitanti) & " where: " & new_float'Image(list_car.posizione_abitante.get_where_now_posizione_abitanti));
                                 end if;
                              end if;
                           elsif z=2 and then (list_car=null or else list_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti=
                                                 get_traiettoria_incrocio(sinistra).get_intersezioni_incrocio(dritto_2).get_distanza_intersezione_incrocio-max_larghezza_veicolo) then
                              if list_near_car.posizione_abitante.get_destination.get_traiettoria_incrocio_to_follow=dritto_2 and then list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_where_now_posizione_abitanti-
                                get_quartiere_utilities_obj.get_auto_quartiere(list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_quartiere_posizione_abitanti,
                                                                               list_near_car.get_posizione_abitanti_from_list_posizione_abitanti.get_id_abitante_posizione_abitanti).get_length_entità_passiva<
                                get_traiettoria_incrocio(dritto_2).get_intersezioni_incrocio(sinistra).get_distanza_intersezione_incrocio+max_larghezza_veicolo then -- distanza dritto2 intersecata sinistra
                                 stop_entity:= True;
                                 if list_car=null then
                                    Put_Line("STOP RIGA 3048 " & Positive'Image(list_near_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_near_car.posizione_abitante.get_id_abitante_posizione_abitanti));
                                 else
                                    Put_Line("STOP RIGA 3048 " & Positive'Image(list_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_car.posizione_abitante.get_id_abitante_posizione_abitanti) & " a causa di " & Positive'Image(list_near_car.posizione_abitante.get_id_quartiere_posizione_abitanti) & " " & Positive'Image(list_near_car.posizione_abitante.get_id_abitante_posizione_abitanti) & " where: " & new_float'Image(list_car.posizione_abitante.get_where_now_posizione_abitanti));
                                 end if;
                              end if;
                           end if;
                           list_near_car:= list_near_car.get_next_from_list_posizione_abitanti;
                        end loop;
                     end loop;
                  end if;
               end if;
            end if;
         end if;
      end calcola_bound_avanzamento_in_incrocio;

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
   function get_prev_from_list_posizione_abitanti(obj: list_posizione_abitanti_on_road) return ptr_list_posizione_abitanti_on_road is
   begin
      return obj.prev;
   end get_prev_from_list_posizione_abitanti;

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
         val_ptr_resource_ingresso.configure(ingressi(i),not index_inizio_moto);
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
               index_to_go:= 1;
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
