
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



   max_num_stalli_uscite_cars: constant Positive:= 15;

   max_num_stalli_uscita_ritorno_from_linea_corsia: constant Positive:= 15;
   max_num_stalli_uscita_ritorno_from_linea_mezzaria: constant Positive:= 15;

   max_num_stalli_entrata_ritorno_from_linea_corsia: constant Positive:= 8;
   max_num_stalli_entrata_ritorno_from_linea_mezzaria: constant Positive:= 8;

   max_num_stalli_uscita_ritorno_in_intersezione_entrata_ritorno: constant Positive:= 15;

   max_num_stalli_uscita_ritorno_in_intersezione_bipedi: constant Positive:= 20;

   max_num_stalli_entrata_cars_int_bipedi: constant Positive:= 5;

   max_num_stalli_entrata_dritto_bipedi_from_fine: constant Positive:= 15;
   max_num_stalli_entrata_dritto_bipedi_from_mezzaria: constant Positive:= 20;

   max_num_stalli_uscite_bipedi_from_begin: constant Positive:= 30; -- uscita_(destra/dritto)_(bici/pedoni)
   max_num_stalli_uscite_bipedi_from_mezzaria: constant Positive:= 30;

   max_num_stalli_uscite_ritorno_bipedi: constant Positive:= 15; -- uscita_(destra/dritto)_(bici/pedoni)
   max_num_stalli_entrata_ritorno_bipedi: constant Positive:= 30;


   max_num_bipedi_cross_per_sessione: constant Positive:= 8;


end global_data;
