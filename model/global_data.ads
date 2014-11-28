


package global_data is
   pragma Shared_Passive;

   num_quartieri: constant Positive:= 3;
   min_length_pedoni: constant Float:= 0.5;
   min_length_bici: constant Float:= 1.5;
   min_length_auto: constant Float:= 3.0;
   num_delta_semafori: constant Positive:= 15;
   delta_value: constant Float:= 0.5;
   max_larghezza_veicolo: constant Float:= 1.5;
   bound_to_change_corsia: constant Float:= 45.0;
   num_delta_to_wait_to_have_system_snapshot: constant Positive:= 30;
   min_veicolo_distance: constant Float:= 2.0;
   distance_at_witch_decelarate: constant Float:= 3.5;
   add_factor: constant Float:= 0.0;
   distance_at_witch_can_be_thinked_overtake: constant Float:= 120.0;

   safe_distance_to_overtake: constant Float:= 20.0;

end global_data;
