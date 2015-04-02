with remote_types;
with data_quartiere;
with strade_e_incroci_common;
with global_data;
with the_name_server;
with risorse_mappa_utilities;
with mailbox_risorse_attive;
with snapshot_interface;
with numerical_types;

use remote_types;
use data_quartiere;
use strade_e_incroci_common;
use global_data;
use the_name_server;
use risorse_mappa_utilities;
use mailbox_risorse_attive;
use snapshot_interface;
use numerical_types;

package risorse_strade_e_incroci is

   type ptr_route_and_distance is access all route_and_distance'Class;
   type percorso_abitanti is array(Positive range <>) of ptr_route_and_distance;

   type core_avanzamento is limited interface;

   procedure configure(entity: access core_avanzamento; id: Positive) is abstract;
   procedure reconfigure_resource(resource: ptr_backup_interface; id_task: Positive);

   procedure crea_snapshot(num_delta: in out Natural; mailbox: ptr_backup_interface; num_task: Positive);

   function calculate_next_car_in_opposite_corsia(current_corsia: ptr_list_posizione_abitanti_on_road; opposite_corsia: ptr_list_posizione_abitanti_on_road) return ptr_list_posizione_abitanti_on_road;

   type tratto_velocipedi_location is ('1','2','3','4');

   procedure update_avanzamento_bipedi_in_uscita_ritorno(mailbox: ptr_resource_segmento_urbana; list_abitanti_sidewalk_pedoni: ptr_list_posizione_abitanti_on_road; list_abitanti_sidewalk_bici: ptr_list_posizione_abitanti_on_road; prec_list_abitanti_sidewalk_pedoni: ptr_list_posizione_abitanti_on_road; prec_list_abitanti_sidewalk_bici: ptr_list_posizione_abitanti_on_road; mezzo: means_of_carrying; index_ingresso_opposite_direction: Positive; current_ingressi_structure_type_to_not_consider: ingressi_type; polo: Boolean; id_road: Positive);

   procedure exit_task;

   task type core_avanzamento_urbane is new core_avanzamento with
      entry configure(id: Positive);
      entry kill;
   end core_avanzamento_urbane;

   task type core_avanzamento_ingressi is new core_avanzamento with
      entry configure(id: Positive);
      entry kill;
   end core_avanzamento_ingressi;

   task type core_avanzamento_incroci is new core_avanzamento with
      entry configure(id: Positive);
      entry kill;
   end core_avanzamento_incroci;

   type task_container_urbane is array(Positive range <>) of core_avanzamento_urbane;
   type task_container_ingressi is array(Positive range <>) of core_avanzamento_ingressi;
   --type task_container_rotonde is array(Positive range <>) of core_avanzamento_rotonde;
   type task_container_incroci is array(Positive range <>) of core_avanzamento_incroci;

   procedure configure_tasks;

   procedure synchronization_with_delta(id: Positive);

   function calculate_acceleration(mezzo: means_of_carrying; id_abitante: Positive; id_quartiere_abitante: Positive; next_entity_distance: new_float; distance_to_stop_line: new_float; next_id_quartiere_abitante: Natural; next_id_abitante: Natural; abitante_velocity: in out new_float; next_abitante_velocity: new_float; disable_rallentamento_1: Boolean:= False; disable_rallentamento_2: Boolean:= False) return new_float;
   function calculate_new_speed(current_speed: new_float; acceleration: new_float) return new_float;
   function calculate_new_step(new_speed: new_float; acceleration: new_float) return new_float;
   function calculate_traiettoria_to_follow_from_ingresso(mezzo: means_of_carrying; id_quartiere_abitante: Positive; id_abitante: Positive; id_ingresso: Positive; ingressi: indici_ingressi) return traiettoria_ingressi_type;
   function calculate_trajectory_to_follow_on_main_strada_from_ingresso(mezzo: means_of_carrying; id_quartiere_abitante: Positive; id_abitante: Positive; from_ingresso: Positive; traiettoria_type: traiettoria_ingressi_type) return trajectory_to_follow;
   function calculate_trajectory_to_follow_from_incrocio(mezzo: means_of_carrying; abitante: posizione_abitanti_on_road; polo: Boolean; num_corsia: id_corsie) return trajectory_to_follow;
   function calculate_distance_to_stop_line_from_entity_on_road(abitante: ptr_list_posizione_abitanti_on_road; polo: Boolean; id_urbana: Positive) return new_float;
   function calculate_next_entity_distance(current_car: ptr_list_posizione_abitanti_on_road; next_car_in_ingresso_distance: new_float; next_car_on_road: ptr_list_posizione_abitanti_on_road; next_car_on_road_distance: new_float; id_road: Positive; next_entity_is_ingresso: out Boolean) return new_float;
   -- has_to_come_back vale True se l'abitante è in rientro da un sorpasso
   function there_are_conditions_to_overtake(next_abitante: ptr_list_posizione_abitanti_on_road; next_abitante_other_corsia: ptr_list_posizione_abitanti_on_road; position_abitante: new_float; has_to_come_back: Boolean) return Boolean;

   procedure calculate_distance_to_next_car_on_road(car_in_corsia: ptr_list_posizione_abitanti_on_road; next_car: ptr_list_posizione_abitanti_on_road; next_car_in_near_corsia: ptr_list_posizione_abitanti_on_road; from_corsia: id_corsie; next_car_on_road: out ptr_list_posizione_abitanti_on_road; next_car_on_road_distance: out new_float);

   procedure calculate_parameters_car_in_uscita(list_abitanti: ptr_list_posizione_abitanti_on_road; traiettoria_rimasta_da_percorrere: new_float; next_abitante: ptr_list_posizione_abitanti_on_road; distance_to_stop_line: new_float; traiettoria_to_go: traiettoria_ingressi_type; distance_ingresso: new_float; next_pos_abitante: in out new_float; acceleration: out new_float; new_step: out new_float; new_speed: out new_float);
   procedure calculate_parameters_car_in_entrata(id_ingresso: Positive; list_abitanti: ptr_list_posizione_abitanti_on_road; traiettoria_rimasta_da_percorrere: new_float; next_abitante: ptr_list_posizione_abitanti_on_road; distance_to_stop_line: new_float; traiettoria_to_go: traiettoria_ingressi_type; next_pos_abitante: in out new_float; acceleration: out new_float; new_step: out new_float; new_speed: out new_float);

   procedure fix_advance_parameters(mezzo: means_of_carrying; acceleration: in out new_float; new_speed: in out new_float; new_step: in out new_float; speed_abitante: new_float; distance_to_next: new_float; distanza_stop_line: new_float);

   procedure set_condizioni_per_abilitare_spostamento_bipedi(mailbox: ptr_resource_segmento_urbana; distance_last_ingresso: in out Boolean; index_ingresso_same_direction: in out Natural; index_ingresso_opposite_direction: in out Natural; current_polo_to_consider: Boolean; current_car_in_corsia: ptr_list_posizione_abitanti_on_road; distance_ingresso_same_direction: in out new_float; distance_ingresso_opposite_direction: in out new_float; corsia: id_corsie);

   function can_abitante_on_uscita_ritorno_overtake_bipedi(mailbox: ptr_resource_segmento_urbana; index_ingresso: Positive) return Boolean;

private

   task_urbane: task_container_urbane(get_from_urbane..get_to_urbane);
   task_ingressi: task_container_ingressi(get_from_ingressi..get_to_ingressi);
   task_incroci: task_container_incroci(get_from_incroci_a_4..get_to_incroci_a_3);
   --task_rotonde: task_container_rotonde(get_from_rotonde_a_4..get_to_rotonde_a_3);

end risorse_strade_e_incroci;
