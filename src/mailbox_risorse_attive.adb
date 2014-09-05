with Text_IO;

with remote_types;
with data_quartiere;
with global_data;
with risorse_passive_data;

use Text_IO;

use remote_types;
use data_quartiere;
use global_data;
use risorse_passive_data;

package body mailbox_risorse_attive is

   function get_min_length_entit�(entity: entit�) return Float is
   begin
      case entity is
         when pedone_entity => return min_length_pedoni;
         when bici_entity => return min_length_bici;
         when auto_entity => return min_length_auto;
      end case;
   end get_min_length_entit�;

   function calculate_max_num_auto(len: Float) return Positive is
      num: Positive:= Positive(Float'Rounding(len/get_min_length_entit�(auto_entity)));
   begin
      if num>get_num_abitanti then
         return get_num_abitanti;
      else
         return num;
      end if;
   end calculate_max_num_auto;

   function calculate_max_num_pedoni(len: Float) return Positive is
      num: Positive:= Positive(Float'Rounding(Float(len)/get_min_length_entit�(pedone_entity)));
   begin
      if num>get_num_abitanti then
         return get_num_abitanti;
      else
         return num;
      end if;
   end calculate_max_num_pedoni;

   protected body resource_segmento_urbana is
      function there_are_autos_to_move return Boolean is
      begin
         for i in 1..2 loop
            for j in 1..2 loop
               if main_strada_number_entity(i,j)/=0 then
                  --for z in max_num_auto-main_strada_number_entity(i,j)..max_num_auto loop
                     --if main_strada(i,j,z).to_move_in_delta then
                        return False;
                     --end if;
                  --end loop;
               end if;
            end loop;
         end loop;
         return False;
      end there_are_autos_to_move;

      function there_are_pedoni_or_bici_to_move return Boolean is
      begin
         for i in 1..2 loop
            for j in 1..2 loop
               if marciapiedi_num_pedoni_bici(i,j)/=0 then
                  --for z in max_num_pedoni-marciapiedi_num_pedoni_bici(i,j)..max_num_pedoni loop
                     --if marciapiedi(i,j,z).to_move_in_delta then
                        return False;
                     --end if;
                  --end loop;
               end if;
            end loop;
         end loop;
         return False;
      end there_are_pedoni_or_bici_to_move;

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
            ordered_ingressi_polo_false(i):= list_ingressi_polo_false.id_ingresso;
            list:= list.next;
         end loop;
         list:= list_ingressi_polo_true;
         for i in 1..num_ingressi_polo_true loop
            ordered_ingressi_polo_true(i):= list_ingressi_polo_true.id_ingresso;
            list:= list.next;
         end loop;
      end configure;

      procedure aggiungi_entit�_from_ingresso(id_ingresso: Positive; type_traiettoria: traiettoria_ingressi_type;
                                               id_quartiere_abitante: Positive; id_abitante: Positive) is
         index: Natural:= get_index_ingresso(id_ingresso);
         list: ptr_list_posizione_abitanti_on_road:= null;
         place_abitante: posizione_abitanti_on_road;
         new_abitante_to_add: ptr_list_posizione_abitanti_on_road:= new list_posizione_abitanti_on_road;
         prec_list: ptr_list_posizione_abitanti_on_road:= null;
      begin
         if index/=0 then
            list:= set_traiettorie_ingressi(index,type_traiettoria);
            place_abitante.id_abitante:= id_abitante;
            place_abitante.id_quartiere:= id_quartiere_abitante;
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
      end aggiungi_entit�_from_ingresso;

      function get_index_ingresso(index: Positive) return Natural is
      begin
         for i in 1..num_ingressi loop
            if index_ingressi(i)=index then
               return i;
            end if;
         end loop;
         return 0;
      end get_index_ingresso;

      function get_ordered_ingressi_from_polo_true_urbana return indici_ingressi is
      begin
         return index_ingressi;
      end get_ordered_ingressi_from_polo_true_urbana;

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

      procedure set_move_parameters_entity_on_main_strada(range_1: Positive; num_entity: Positive;
                                                          speed: Float; step_to_advance: Float) is
         node: ptr_list_posizione_abitanti_on_road:= null;
      begin
         node:= slide_list(road,range_1,num_entity);
         if speed>0.0 then
            node.posizione_abitante.current_speed:= speed;
         end if;
         if step_to_advance>0.0 then
            if node.posizione_abitante.where_now+step_to_advance>risorsa_features.get_lunghezza_road then
               node.posizione_abitante.where_next:= risorsa_features.get_lunghezza_road;
            else
               node.posizione_abitante.where_next:= node.posizione_abitante.where_now+step_to_advance;
            end if;
         end if;
      end set_move_parameters_entity_on_main_strada;

      function slide_list(type_structure: data_structures_types; range_1: Positive; index_to_slide: Positive) return ptr_list_posizione_abitanti_on_road is
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
      begin
         case type_structure is
            when road =>
               if main_strada_temp/=null then
                  list_abitanti.next:= main_strada(index_inizio_moto,1);
                  main_strada(index_inizio_moto,1):= list_abitanti;
                  list_abitanti.posizione_abitante.id_abitante:= main_strada_temp.posizione_abitante.id_abitante;
                  list_abitanti.posizione_abitante.id_quartiere:= main_strada_temp.posizione_abitante.id_quartiere;
                  list_abitanti.posizione_abitante.where_now:= 0.0;
                  if posix>risorsa_features.get_lunghezza_road then
                     list_abitanti.posizione_abitante.where_next:= risorsa_features.get_lunghezza_road;
                  else
                     list_abitanti.posizione_abitante.where_next:= posix;
                  end if;
                  list_abitanti.posizione_abitante.current_speed:= begin_speed;
                  list_abitanti.posizione_abitante.to_move_in_delta:= True;
                  main_strada_temp:= main_strada_temp.next;
                  main_strada_number_entity(index_inizio_moto,1):= main_strada_number_entity(index_inizio_moto,1)+1;
               end if;
            when sidewalk =>
               null;
         end case;
      end registra_abitante_to_move;

      procedure new_abitante_to_move(id_quartiere: Positive; id_abitante: Positive; mezzo: means_of_carrying) is
         list_abitanti: ptr_list_posizione_abitanti_on_road:= new list_posizione_abitanti_on_road;
         last_node: ptr_list_posizione_abitanti_on_road:= null;
      begin
         list_abitanti.posizione_abitante.id_abitante:= id_abitante;
         list_abitanti.posizione_abitante.id_quartiere:= id_quartiere;
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

      procedure update_position_entity(type_structure: data_structures_types; range_1: Positive; index_entity: Positive) is
         nodo: ptr_list_posizione_abitanti_on_road:= null;
      begin
         case type_structure is
            when road =>
               nodo:= slide_list(road,range_1,index_entity);
            when sidewalk =>
               nodo:= slide_list(sidewalk,range_1,index_entity);
         end case;
         nodo.posizione_abitante.where_now:= nodo.posizione_abitante.where_next;
      end update_position_entity;

      function get_main_strada(range_1: Positive) return ptr_list_posizione_abitanti_on_road is
      begin
         return main_strada(range_1,1);
      end get_main_strada;

      function get_marciapiede(range_1: Positive) return ptr_list_posizione_abitanti_on_road is
      begin
         return marciapiedi(range_1,1);
      end get_marciapiede;

      function get_number_entity_strada(range_1: Positive) return Natural is
      begin
         return main_strada_number_entity(range_1,1);
      end get_number_entity_strada;

      function get_number_entity_marciapiede(range_1: Positive) return Natural is
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

      function get_posix_first_entity(type_structure: data_structures_types; range_1: Positive) return Float is
      begin
         case type_structure is
            when road =>
               return main_strada(range_1,1).posizione_abitante.where_now;
            when sidewalk =>
               return marciapiedi(range_1,1).posizione_abitante.where_now;
         end case;
      end get_posix_first_entity;

      function get_index_inizio_moto return Positive is
      begin
         return index_inizio_moto;
      end get_index_inizio_moto;

      function there_are_autos_to_move return Boolean is
      begin
         for i in 1..2 loop
            for j in 1..1 loop
               if main_strada_number_entity(i,j)/=0 then
                  loop
                     exit when main_strada(i,j)=null;
                     if main_strada(i,j).posizione_abitante.to_move_in_delta then
                        return True;
                     end if;
                  end loop;
               end if;
            end loop;
         end loop;
         return False;
      end there_are_autos_to_move;
      function there_are_pedoni_or_bici_to_move return Boolean is
      begin
         for i in 1..2 loop
            for j in 1..1 loop
               if marciapiedi_number_entity(i,j)/=0 then
                  loop
                     exit when marciapiedi(i,j)=null;
                     if marciapiedi(i,j).posizione_abitante.to_move_in_delta then
                        return True;
                     end if;
                  end loop;
               end if;
            end loop;
         end loop;
         return False;
      end there_are_pedoni_or_bici_to_move;

      procedure configure(risorsa: strada_ingresso_features; inizio_moto: Positive) is
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

      function there_are_autos_to_move return Boolean is
      begin
         return False;
      end there_are_autos_to_move;
      function there_are_pedoni_or_bici_to_move return Boolean is
      begin
         return False;
      end there_are_pedoni_or_bici_to_move;

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
      function there_are_autos_to_move return Boolean is
      begin
         return False;
      end there_are_autos_to_move;
      function there_are_pedoni_or_bici_to_move return Boolean is
      begin
         return False;
      end there_are_pedoni_or_bici_to_move;

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
   function get_id_abitante_posizione_abitanti(obj: posizione_abitanti_on_road) return Positive is
   begin
      return obj.id_abitante;
   end get_id_abitante_posizione_abitanti;
   function get_id_quartiere_posizione_abitanti(obj: posizione_abitanti_on_road) return Positive is
   begin
      return obj.id_quartiere;
   end get_id_quartiere_posizione_abitanti;
   function get_where_next_posizione_abitanti(obj: posizione_abitanti_on_road) return Float is
   begin
      return obj.where_next;
   end get_where_next_posizione_abitanti;
   function get_where_now_posizione_abitanti(obj: posizione_abitanti_on_road) return Float is
   begin
      return obj.where_now;
   end get_where_now_posizione_abitanti;
   function get_current_speed_abitante(obj: posizione_abitanti_on_road) return Float is
   begin
      return obj.current_speed;
   end get_current_speed_abitante;
   function get_to_move_in_delta_posizione_abitanti(obj: posizione_abitanti_on_road) return Boolean is
   begin
      return obj.to_move_in_delta;
   end get_to_move_in_delta_posizione_abitanti;
   procedure set_current_speed_abitante(obj: in out posizione_abitanti_on_road; speed: Float) is
   begin
      obj.current_speed:= speed;
   end set_current_speed_abitante;
   procedure set_where_next_abitante(obj: in out posizione_abitanti_on_road; where_next: Float) is
   begin
      obj.where_next:= where_next;
   end set_where_next_abitante;
   procedure set_where_now_abitante(obj: in out posizione_abitanti_on_road; where_now: Float) is
   begin
      obj.where_now:= where_now;
   end set_where_now_abitante;
   procedure set_to_move_in_delta(obj: in out posizione_abitanti_on_road; to_move_in_delta: Boolean) is
   begin
      obj.to_move_in_delta:= to_move_in_delta;
   end set_to_move_in_delta;
   function get_posizione_abitanti_from_list_posizione_abitanti(obj: list_posizione_abitanti_on_road) return posizione_abitanti_on_road'Class is
   begin
      return obj.posizione_abitante;
   end get_posizione_abitanti_from_list_posizione_abitanti;
   function get_next_from_list_posizione_abitanti(obj: list_posizione_abitanti_on_road) return ptr_list_posizione_abitanti_on_road is
   begin
      return obj.next;
   end get_next_from_list_posizione_abitanti;

   type num_ingressi_urbana is array(Positive range <>) of Natural;
   type num_ingressi_urbana_per_polo is array(Positive range <>,Positive range <>) of Natural;

   procedure update_list_ingressi(lista: ptr_list_ingressi_per_urbana; new_node: ptr_list_ingressi_per_urbana; structure: ingressi_type_structure; indice_ingresso: Positive) is
      prec_list_ingressi: ptr_list_ingressi_per_urbana;
      list: ptr_list_ingressi_per_urbana:= lista;
   begin
      if list=null then
         case structure is
            when not_ordered =>
               id_ingressi_per_urbana(get_ingresso_from_id(indice_ingresso).get_id_main_strada_ingresso):= new_node;
            when ordered_polo_true =>
               id_ingressi_per_urbana_polo_true(get_ingresso_from_id(indice_ingresso).get_id_main_strada_ingresso):= new_node;
            when ordered_polo_false =>
               id_ingressi_per_urbana_polo_false(get_ingresso_from_id(indice_ingresso).get_id_main_strada_ingresso):= new_node;
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
               new_node.next:= id_ingressi_per_urbana_polo_true(get_ingresso_from_id(indice_ingresso).get_id_main_strada_ingresso);
               id_ingressi_per_urbana_polo_true(get_ingresso_from_id(indice_ingresso).get_id_main_strada_ingresso):= new_node;
            when ordered_polo_false =>
               new_node.next:= id_ingressi_per_urbana_polo_false(get_ingresso_from_id(indice_ingresso).get_id_main_strada_ingresso);
               id_ingressi_per_urbana_polo_false(get_ingresso_from_id(indice_ingresso).get_id_main_strada_ingresso):= new_node;
            end case;
         else
            new_node.next:= list;
            prec_list_ingressi.next:= new_node;
         end if;
      end if;
   end update_list_ingressi;

   procedure create_mailbox_entit�(urbane: strade_urbane_features; ingressi: strade_ingresso_features;
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
      ingressi_per_urbana_per_polo: num_ingressi_urbana_per_polo(get_from_urbane..get_to_urbane,1..2):= (others => (others => 0));
      index_ingressi: id_ingressi_urbane(get_from_urbane..get_to_urbane):= (others => 1);
      node_ingressi: ptr_list_ingressi_per_urbana;
      node_ordered_ingressi: ptr_list_ingressi_per_urbana;
      index_inizio_moto: Positive;
   begin

      for i in get_from_ingressi..get_to_ingressi loop
         node_ingressi:= new list_ingressi_per_urbana;
         node_ordered_ingressi:= new list_ingressi_per_urbana;
         val_ptr_resource_ingresso:= new resource_segmento_ingresso(id_risorsa => ingressi(i).get_id_road,
                                                                    max_num_auto => calculate_max_num_auto(ingressi(i).get_lunghezza_road),
                                                                    max_num_pedoni => calculate_max_num_pedoni(ingressi(i).get_lunghezza_road));
         node_ordered_ingressi.id_ingresso:=i;
         if ingressi(i).get_polo_ingresso then
            index_inizio_moto:= 1;
            ingressi_per_urbana_per_polo(ingressi(i).get_id_main_strada_ingresso,1):= ingressi_per_urbana_per_polo(ingressi(i).get_id_main_strada_ingresso,1)+1;
            update_list_ingressi(id_ingressi_per_urbana_polo_true(ingressi(i).get_id_main_strada_ingresso),node_ordered_ingressi,ordered_polo_true,i);
         else
            index_inizio_moto:= 2;
            ingressi_per_urbana_per_polo(ingressi(i).get_id_main_strada_ingresso,2):= ingressi_per_urbana_per_polo(ingressi(i).get_id_main_strada_ingresso,2)+1;
            update_list_ingressi(id_ingressi_per_urbana_polo_false(ingressi(i).get_id_main_strada_ingresso),node_ordered_ingressi,ordered_polo_false,i);
         end if;
         val_ptr_resource_ingresso.configure(ingressi(i),index_inizio_moto);
         ingressi_per_urbana(ingressi(i).get_id_main_strada_ingresso):= ingressi_per_urbana(ingressi(i).get_id_main_strada_ingresso)+1;
         node_ingressi.id_ingresso:= i;
         update_list_ingressi(id_ingressi_per_urbana(ingressi(i).get_id_main_strada_ingresso),node_ingressi,not_ordered,i);
         ptr_resource_ingressi(i):= val_ptr_resource_ingresso;
      end loop;
      ingressi_segmento_resources:= ptr_resource_ingressi;

      for i in get_from_urbane..get_to_urbane loop
         val_ptr_resource_urbana:= new resource_segmento_urbana(id_risorsa => urbane(i).get_id_road,
                                                                num_ingressi => ingressi_per_urbana(urbane(i).get_id_road),
                                                                num_ingressi_polo_true => ingressi_per_urbana_per_polo(urbane(i).get_id_road,1),
                                                                num_ingressi_polo_false => ingressi_per_urbana_per_polo(urbane(i).get_id_road,2));
         val_ptr_resource_urbana.configure(urbane(i),id_ingressi_per_urbana(i),id_ingressi_per_urbana_polo_true(i),id_ingressi_per_urbana_polo_false(i));
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
         val_ptr_resource_incrocio:= new resource_segmento_incrocio(i,1,1); --TO DO
         ptr_resource_incroci_a_4(i):= val_ptr_resource_incrocio;
      end loop;
      incroci_a_4_segmento_resources:= ptr_resource_incroci_a_4;

      for i in get_from_incroci_a_3..get_to_incroci_a_3 loop
         val_ptr_resource_incrocio:= new resource_segmento_incrocio(i,1,1); --TO DO
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
   end create_mailbox_entit�;

   function get_id_abitante_from_posizione(obj: posizione_abitanti_on_road) return Positive is
   begin
      return obj.id_abitante;
   end get_id_abitante_from_posizione;
   function get_id_quartiere_from_posizione(obj: posizione_abitanti_on_road) return Positive is
   begin
      return obj.id_quartiere;
   end get_id_quartiere_from_posizione;
   function get_new_posizione(obj: posizione_abitanti_on_road) return Float is
   begin
      return obj.where_next;
   end get_new_posizione;
   function get_old_posizione(obj: posizione_abitanti_on_road) return Float is
   begin
      return obj.where_now;
   end get_old_posizione;
   function get_to_move_in_delta(obj: posizione_abitanti_on_road) return Boolean is
   begin
      return obj.to_move_in_delta;
   end get_to_move_in_delta;

   function get_list_ingressi_urbana(id_urbana: Positive) return ptr_list_ingressi_per_urbana is
   begin
      return id_ingressi_per_urbana(id_urbana);
   end get_list_ingressi_urbana;

end mailbox_risorse_attive;
