
package body data_quartiere is

   function get_id_quartiere return Positive is
   begin
      return id_quartiere;
   end get_id_quartiere;
   function get_json_urbane return JSON_Array is
   begin
      return json_urbane;
   end get_json_urbane;
   function get_json_ingressi return JSON_Array is
   begin
      return json_ingressi;
   end get_json_ingressi;
   function get_json_incroci_a_4 return JSON_Array is
   begin
      return json_incroci_a_4;
   end get_json_incroci_a_4;
   function get_json_incroci_a_3 return JSON_Array is
   begin
      return json_incroci_a_3;
   end get_json_incroci_a_3;
   function get_json_rotonde_a_4 return JSON_Array is
   begin
      return json_rotonde_a_4;
   end get_json_rotonde_a_4;
   function get_json_rotonde_a_3 return JSON_Array is
   begin
      return json_rotonde_a_3;
   end get_json_rotonde_a_3;
   function get_from_urbane return Natural is
   begin
      return from_urbane;
   end get_from_urbane;
   function get_to_urbane return Natural is
   begin
      return to_urbane;
   end get_to_urbane;
   function get_from_ingressi return Natural is
   begin
      return from_ingressi;
   end get_from_ingressi;
   function get_to_ingressi return Natural is
   begin
      return to_ingressi;
   end get_to_ingressi;
   function get_from_incroci_a_4 return Natural is
   begin
      return from_incroci_a_4;
   end get_from_incroci_a_4;
   function get_to_incroci_a_4 return Natural is
   begin
      return to_incroci_a_4;
   end get_to_incroci_a_4;
   function get_from_incroci_a_3 return Natural is
   begin
      return from_incroci_a_3;
   end get_from_incroci_a_3;
   function get_to_incroci_a_3 return Natural is
   begin
      return to_incroci_a_3;
   end get_to_incroci_a_3;
   function get_from_rotonde_a_4 return Natural is
   begin
      return from_rotonde_a_4;
   end get_from_rotonde_a_4;
   function get_to_rotonde_a_4 return Natural is
   begin
      return to_rotonde_a_4;
   end get_to_rotonde_a_4;
   function get_from_rotonde_a_3 return Natural is
   begin
      return from_rotonde_a_3;
   end get_from_rotonde_a_3;
   function get_to_rotonde_a_3 return Natural is
   begin
      return to_rotonde_a_3;
   end get_to_rotonde_a_3;
   function get_json_pedoni return JSON_Array is
   begin
      return json_pedoni;
   end get_json_pedoni;
   function get_json_bici return JSON_Array is
   begin
      return json_bici;
   end get_json_bici;
   function get_json_auto return JSON_Array is
   begin
      return json_auto;
   end get_json_auto;
   function get_json_abitanti return JSON_Array is
   begin
      return json_abitanti;
   end get_json_abitanti;
   function get_from_abitanti return Natural is
   begin
      return from_abitanti;
   end get_from_abitanti;
   function get_to_abitanti return Natural is
   begin
      return to_abitanti;
   end get_to_abitanti;

   function get_default_value_pedoni(value: move_settings) return Float is
   begin
      case value is
         when desired_velocity => return default_desired_velocity_pedoni;
         when time_headway => return default_time_headway_pedoni;
         when max_acceleration => return default_max_acceleration_pedoni;
         when comfortable_deceleration => return default_comfortable_deceleration_pedoni;
         when s0 => return default_s0_pedoni;
         when length => return default_length_pedoni;
         when others => return 0.0;
      end case;
   end get_default_value_pedoni;

   function get_default_value_bici(value: move_settings) return Float is
   begin
      case value is
         when desired_velocity => return default_desired_velocity_bici;
         when time_headway => return default_time_headway_bici;
         when max_acceleration => return default_max_acceleration_bici;
         when comfortable_deceleration => return default_comfortable_deceleration_bici;
         when s0 => return default_s0_bici;
         when length => return default_length_bici;
         when others => return 0.0;
      end case;
   end get_default_value_bici;

   function get_default_value_auto(value: move_settings) return Float is
   begin
      case value is
         when desired_velocity => return default_desired_velocity_auto;
         when time_headway => return default_time_headway_auto;
         when max_acceleration => return default_max_acceleration_auto;
         when comfortable_deceleration => return default_comfortable_deceleration_auto;
         when s0 => return default_s0_auto;
         when length => return default_length_auto;
         when num_posti => return Float(default_num_posti_auto);
      end case;
   end get_default_value_auto;

   function get_num_abitanti return Positive is
   begin
      return size_json_abitanti;
   end get_num_abitanti;

   function get_num_task return Natural is
   begin
      return num_task;
   end get_num_task;

end data_quartiere;
