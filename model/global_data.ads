


package global_data is
   pragma Shared_Passive;

   function get_num_quartieri return Positive;
   num_quartieri: constant Positive:= 3;
   min_length_pedoni: constant Float:= 0.5;
   min_length_bici: constant Float:= 1.5;
   min_length_auto: constant Float:= 3.0;
   num_delta_semafori: constant Positive:= 15;
   delta_value: constant Float:= 0.5;
   safe_distance_to_overtake: Float:= 15.0;
   max_larghezza_veicolo: Float:= 1.5;
   bound_to_change_corsia: Float:= 40.0;

end global_data;
