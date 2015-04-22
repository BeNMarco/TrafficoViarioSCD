
with numerical_types;
use numerical_types;


package global_data is
   --pragma Shared_Passive;

   --num_quartieri: constant Positive:= 3;
   min_length_pedoni: constant new_float:= 0.5;
   min_length_bici: constant new_float:= 1.0;
   min_length_auto: constant new_float:= 3.0;
   max_length_pedoni: constant new_float:= 0.5;
   max_length_bici: constant new_float:= 1.0;
   max_length_veicolo: constant new_float:= 4.3;
   num_delta_semafori: constant Positive:= 40;
   num_delta_semafori_bipedi: constant Positive:= 20;
   delta_value: constant new_float:= 0.5;
   max_larghezza_veicolo: constant new_float:= 1.5;
   bound_to_change_corsia: constant new_float:= 45.0;
   num_delta_to_wait_to_have_system_snapshot: constant Positive:= 1;--30;
   min_veicolo_distance: constant new_float:= 2.0;
   min_bici_distance: constant new_float:= 1.0;
   min_pedone_distance: constant new_float:= 0.5;
   distance_at_witch_decelarate: constant new_float:= 3.5;
   add_factor: constant new_float:= 0.0;
   distance_at_witch_can_be_thinked_overtake: constant new_float:= 120.0;

   safe_distance_to_overtake: constant new_float:= 20.0;
   num_delta_before_insert_bipede: constant Positive:= 45;

   max_num_stalli_car_in_entrata_ingresso: constant Positive:= 12;

end global_data;
