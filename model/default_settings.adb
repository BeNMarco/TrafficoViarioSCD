with numerical_types;
with data_quartiere;
with JSON_Helper;
with GNATCOLL.JSON;

use numerical_types;
use data_quartiere;
use JSON_Helper;
use GNATCOLL.JSON;

package body default_settings is

   function get_default_desired_velocity_pedoni return new_float is
      default_desired_velocity_pedoni: Float:= Get(Val => get_json_default_movement_entity, Field => "default_pedoni").Get("desired_velocity");
   begin
      return new_float(default_desired_velocity_pedoni);
   end get_default_desired_velocity_pedoni;

   function get_default_time_headway_pedoni return new_float is
      default_time_headway_pedoni: Float:= Get(Val => get_json_default_movement_entity, Field => "default_pedoni").Get("time_headway");
   begin
      return new_float(default_time_headway_pedoni);
   end get_default_time_headway_pedoni;

   function get_default_max_acceleration_pedoni return new_float is
      default_max_acceleration_pedoni: Float:= Get(Val => get_json_default_movement_entity, Field => "default_pedoni").Get("max_acceleration");
   begin
      return new_float(default_max_acceleration_pedoni);
   end get_default_max_acceleration_pedoni;

   function get_default_comfortable_deceleration_pedoni return new_float is
      default_comfortable_deceleration_pedoni: Float:= Get(Val => get_json_default_movement_entity, Field => "default_pedoni").Get("comfortable_deceleration");
   begin
      return new_float(default_comfortable_deceleration_pedoni);
   end get_default_comfortable_deceleration_pedoni;

   function get_default_s0_pedoni return new_float is
      default_s0_pedoni: Float:= Get(Val => get_json_default_movement_entity, Field => "default_pedoni").Get("s0");
   begin
      return new_float(default_s0_pedoni);
   end get_default_s0_pedoni;

   function get_default_length_pedoni return new_float is
      default_length_pedoni: Float:= Get(Val => get_json_default_movement_entity, Field => "default_pedoni").Get("length");
   begin
      return new_float(default_length_pedoni);
   end get_default_length_pedoni;

   function get_default_desired_velocity_bici return new_float is
      default_desired_velocity_bici: Float:= Get(Val => get_json_default_movement_entity, Field => "default_bici").Get("desired_velocity");
   begin
      return new_float(default_desired_velocity_bici);
   end get_default_desired_velocity_bici;

   function get_default_time_headway_bici return new_float is
      default_time_headway_bici: Float:= Get(Val => get_json_default_movement_entity, Field => "default_bici").Get("time_headway");
   begin
      return new_float(default_time_headway_bici);
   end get_default_time_headway_bici;

   function get_default_max_acceleration_bici return new_float is
      default_max_acceleration_bici: Float:= Get(Val => get_json_default_movement_entity, Field => "default_bici").Get("max_acceleration");
   begin
      return new_float(default_max_acceleration_bici);
   end get_default_max_acceleration_bici;

   function get_default_comfortable_deceleration_bici return new_float is
      default_comfortable_deceleration_bici: Float:= Get(Val => get_json_default_movement_entity, Field => "default_bici").Get("comfortable_deceleration");
   begin
      return new_float(default_comfortable_deceleration_bici);
   end get_default_comfortable_deceleration_bici;

   function get_default_s0_bici return new_float is
      default_s0_bici: Float:= Get(Val => get_json_default_movement_entity, Field => "default_bici").Get("s0");
   begin
      return new_float(default_s0_bici);
   end get_default_s0_bici;

   function get_default_length_bici return new_float is
      default_length_bici: Float:= Get(Val => get_json_default_movement_entity, Field => "default_bici").Get("length");
   begin
      return new_float(default_length_bici);
   end get_default_length_bici;

   function get_default_desired_velocity_auto return new_float is
      default_desired_velocity_auto: Float:= Get(Val => get_json_default_movement_entity, Field => "default_auto").Get("desired_velocity");
   begin
      return new_float(default_desired_velocity_auto);
   end get_default_desired_velocity_auto;

   function get_default_time_headway_auto return new_float is
      default_time_headway_auto: Float:= Get(Val => get_json_default_movement_entity, Field => "default_auto").Get("time_headway");
   begin
      return new_float(default_time_headway_auto);
   end get_default_time_headway_auto;

   function get_default_max_acceleration_auto return new_float is
      default_max_acceleration_auto: Float:= Get(Val => get_json_default_movement_entity, Field => "default_auto").Get("max_acceleration");
   begin
      return new_float(default_max_acceleration_auto);
   end get_default_max_acceleration_auto;

   function get_default_comfortable_deceleration_auto return new_float is
      default_comfortable_deceleration_auto: Float:= Get(Val => get_json_default_movement_entity, Field => "default_auto").Get("comfortable_deceleration");
   begin
      return new_float(default_comfortable_deceleration_auto);
   end get_default_comfortable_deceleration_auto;

   function get_default_s0_auto return new_float is
      default_s0_auto: Float:= Get(Val => get_json_default_movement_entity, Field => "default_auto").Get("s0");
   begin
      return new_float(default_s0_auto);
   end get_default_s0_auto;

   function get_default_length_auto return new_float is
      default_length_auto: Float:= Get(Val => get_json_default_movement_entity, Field => "default_auto").Get("length");
   begin
      return new_float(default_length_auto);
   end get_default_length_auto;

   function get_default_num_posti_auto return Positive is
      default_num_posti_auto: Positive:= Get(Val => get_json_default_movement_entity, Field => "default_auto").Get("num_posti");
   begin
      return default_num_posti_auto;
   end get_default_num_posti_auto;

   function get_defaul_larghezza_marciapiede return new_float is
      larghezza_marciapiede: Float:= Get(Val => get_json_road_parameters, Field => "larghezza_marciapiede");
   begin
      return new_float(larghezza_marciapiede);
   end get_defaul_larghezza_marciapiede;

   function get_defaul_larghezza_corsia return new_float is
     larghezza_corsia: Float:= Get(Val => get_json_road_parameters, Field => "larghezza_corsia");
   begin
      return new_float(larghezza_corsia);
   end get_defaul_larghezza_corsia;

end default_settings;
