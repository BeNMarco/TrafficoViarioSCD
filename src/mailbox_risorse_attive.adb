with remote_types;
with data_quartiere;
with global_data;

use remote_types;
use data_quartiere;
use global_data;

package body mailbox_risorse_attive is

   function get_min_length_entità(entity: entità) return Float is
   begin
      case entity is
         when pedone_entity => return min_length_pedoni;
         when bici_entity => return min_length_bici;
         when auto_entity => return min_length_auto;
      end case;
   end get_min_length_entità;

   function calculate_max_num_auto(len: Positive) return Positive is
      num: Positive:= Positive(Float'Rounding(Float(len)/get_min_length_entità(auto_entity)));
   begin
      if num>get_num_abitanti then
         return get_num_abitanti;
      else
         return num;
      end if;
   end calculate_max_num_auto;

   function calculate_max_num_pedoni(len: Positive) return Positive is
      num: Positive:= Positive(Float'Rounding(Float(len)/get_min_length_entità(pedone_entity)));
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
                  for z in max_num_auto-main_strada_number_entity(i,j)..max_num_auto loop
                     if main_strada(i,j,z).to_move_in_delta then
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
            for j in 1..2 loop
               if marciapiedi_num_pedoni_bici(i,j)/=0 then
                  for z in max_num_pedoni-marciapiedi_num_pedoni_bici(i,j)..max_num_pedoni loop
                     if marciapiedi(i,j,z).to_move_in_delta then
                        return True;
                     end if;
                  end loop;
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
      function there_are_autos_to_move return Boolean is
      begin
         return False;
      end there_are_autos_to_move;
      function there_are_pedoni_or_bici_to_move return Boolean is
      begin
         return False;
      end there_are_pedoni_or_bici_to_move;

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

   type num_ingressi_urbana is array(Positive range <>) of Natural;
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
   begin

      for i in get_from_ingressi..get_to_ingressi loop
         val_ptr_resource_ingresso:= new resource_segmento_ingresso(id_risorsa => ingressi(i).get_id_road,
                                                                    length => ingressi(i).get_lunghezza_road,
                                                                    max_num_auto => calculate_max_num_auto(ingressi(i).get_lunghezza_road),
                                                                    max_num_pedoni => calculate_max_num_pedoni(ingressi(i).get_lunghezza_road));
         ingressi_per_urbana(ingressi(i).get_id_main_strada_ingresso):= ingressi_per_urbana(ingressi(i).get_id_main_strada_ingresso)+1;
         ptr_resource_ingressi(i):= val_ptr_resource_ingresso;
      end loop;
      ingressi_segmento_resources:= ptr_resource_ingressi;

      for i in get_from_urbane..get_to_urbane loop
         val_ptr_resource_urbana:= new resource_segmento_urbana(id_risorsa => urbane(i).get_id_road,
                                                                length => urbane(i).get_lunghezza_road,
                                                                num_ingressi => ingressi_per_urbana(urbane(i).get_id_road),
                                                                max_num_auto => calculate_max_num_auto(urbane(i).get_lunghezza_road),
                                                                max_num_pedoni => calculate_max_num_pedoni(urbane(i).get_lunghezza_road));
         ptr_resource_urbane(i):= val_ptr_resource_urbana;
      end loop;
      urbane_segmento_resources:= ptr_resource_urbane;

      for i in get_from_incroci_a_4..get_to_incroci_a_4 loop
         val_ptr_resource_incrocio:= new resource_segmento_incrocio(i,1,1,1); --TO DO
         ptr_resource_incroci_a_4(i):= val_ptr_resource_incrocio;
      end loop;
      incroci_a_4_segmento_resources:= ptr_resource_incroci_a_4;

      for i in get_from_incroci_a_3..get_to_incroci_a_3 loop
         val_ptr_resource_incrocio:= new resource_segmento_incrocio(i,1,1,1); --TO DO
         ptr_resource_incroci_a_3(i):= val_ptr_resource_incrocio;
      end loop;
      incroci_a_3_segmento_resources:= ptr_resource_incroci_a_3;

      for i in get_from_rotonde_a_4..get_to_rotonde_a_4 loop
         val_ptr_resource_rotonda:= new resource_segmento_rotonda(i,1,1,1); --TO DO
         ptr_resource_rotonde_a_4(i):= val_ptr_resource_rotonda;
      end loop;
      rotonde_a_4_segmento_resources:= ptr_resource_rotonde_a_4;

      for i in get_from_rotonde_a_3..get_to_rotonde_a_3 loop
         val_ptr_resource_rotonda:= new resource_segmento_rotonda(i,1,1,1); --TO DO
         ptr_resource_rotonde_a_3(i):= val_ptr_resource_rotonda;
      end loop;
      rotonde_a_3_segmento_resources:= ptr_resource_rotonde_a_3;
   end create_mailbox_entità;

   function get_id_abitante_from_posizione(obj: posizione_abitanti_on_road) return Positive is
   begin
      return obj.id_abitante;
   end get_id_abitante_from_posizione;
   function get_id_quartiere_from_posizione(obj: posizione_abitanti_on_road) return Positive is
   begin
      return obj.id_quartiere;
   end get_id_quartiere_from_posizione;
   function get_where_from_posizione(obj: posizione_abitanti_on_road) return Float is
   begin
      return obj.where;
   end get_where_from_posizione;
   function get_to_move_in_delta(obj: posizione_abitanti_on_road) return Boolean is
   begin
      return obj.to_move_in_delta;
   end get_to_move_in_delta;

end mailbox_risorse_attive;
