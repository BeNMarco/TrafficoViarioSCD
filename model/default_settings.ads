
with numerical_types;
use numerical_types;

package default_settings is
   pragma Elaborate_Body;

   function get_default_desired_velocity_pedoni return new_float;
   function get_default_time_headway_pedoni return new_float;
   function get_default_max_acceleration_pedoni return new_float;
   function get_default_comfortable_deceleration_pedoni return new_float;
   function get_default_s0_pedoni return new_float;
   function get_default_length_pedoni return new_float;

   function get_default_desired_velocity_bici return new_float;
   function get_default_time_headway_bici return new_float;
   function get_default_max_acceleration_bici return new_float;
   function get_default_comfortable_deceleration_bici return new_float;
   function get_default_s0_bici return new_float;
   function get_default_length_bici return new_float;

   function get_default_desired_velocity_auto return new_float;
   function get_default_time_headway_auto return new_float;
   function get_default_max_acceleration_auto return new_float;
   function get_default_comfortable_deceleration_auto return new_float;
   function get_default_s0_auto return new_float;
   function get_default_length_auto return new_float;
   function get_default_num_posti_auto return Positive;

   function get_default_larghezza_marciapiede return new_float;
   function get_default_larghezza_corsia return new_float;

end default_settings;
