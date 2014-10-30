with remote_types;
with data_quartiere;
with strade_e_incroci_common;
with global_data;
with the_name_server;
with risorse_mappa_utilities;
with mailbox_risorse_attive;
with snapshot_interface;

use remote_types;
use data_quartiere;
use strade_e_incroci_common;
use global_data;
use the_name_server;
use risorse_mappa_utilities;
use mailbox_risorse_attive;
use snapshot_interface;

package risorse_strade_e_incroci is

   type ptr_route_and_distance is access all route_and_distance'Class;
   type percorso_abitanti is array(Positive range <>) of ptr_route_and_distance;

   --protected type location_abitanti(num_abitanti: Positive) is new rt_location_abitanti with
   --     procedure set_percorso_abitante(id_abitante: Positive; percorso: route_and_distance);
   --private
   --   percorsi: percorso_abitanti(1..num_abitanti):= (others => null);
   --end location_abitanti;

   --type ptr_location_abitanti is access location_abitanti;

   type core_avanzamento is limited interface;

   procedure configure(entity: access core_avanzamento; id: Positive) is abstract;

   procedure crea_snapshot(num_delta: in out Natural; mailbox: ptr_backup_interface; num_task: Positive);

   task type core_avanzamento_urbane is new core_avanzamento with
      entry configure(id: Positive);
   end core_avanzamento_urbane;

   task type core_avanzamento_ingressi is new core_avanzamento with
      entry configure(id: Positive);
   end core_avanzamento_ingressi;

   task type core_avanzamento_rotonde is new core_avanzamento with
      entry configure(id: Positive);
   end core_avanzamento_rotonde;

   task type core_avanzamento_incroci is new core_avanzamento with
      entry configure(id: Positive);
   end core_avanzamento_incroci;

   type task_container_urbane is array(Positive range <>) of core_avanzamento_urbane;
   type task_container_ingressi is array(Positive range <>) of core_avanzamento_ingressi;
   type task_container_rotonde is array(Positive range <>) of core_avanzamento_rotonde;
   type task_container_incroci is array(Positive range <>) of core_avanzamento_incroci;

   procedure configure_tasks;

   procedure synchronization_with_delta(id: Positive);

   function calculate_acceleration(mezzo: means_of_carrying; id_abitante: Positive; id_quartiere_abitante: Positive; next_entity_distance: Float; distance_to_stop_line: Float; next_id_quartiere_abitante: Natural; next_id_abitante: Natural; abitante_velocity: Float; next_abitante_velocity: Float) return Float;
   function calculate_new_speed(current_speed: Float; acceleration: Float) return Float;
   function calculate_new_step(new_speed: Float; acceleration: Float) return Float;
   function calculate_traiettoria_to_follow_from_ingresso(id_quartiere_abitante: Positive; id_abitante: Positive; id_ingresso: Positive; ingressi: indici_ingressi) return traiettoria_ingressi_type;
   function calculate_trajectory_to_follow_on_main_strada_from_ingresso(id_quartiere_abitante: Positive; id_abitante: Positive; from_ingresso: Positive; traiettoria_type: traiettoria_ingressi_type) return trajectory_to_follow;
   function calculate_trajectory_to_follow_on_main_strada_from_incrocio(abitante: posizione_abitanti_on_road; polo: Boolean; num_corsia: id_corsie) return trajectory_to_follow;
   function calculate_distance_to_stop_line_from_entity_on_road(abitante: ptr_list_posizione_abitanti_on_road; polo: Boolean; id_urbana: Positive) return Float;
   function calculate_next_entity_distance(next_car_in_ingresso_distance: Float; next_car_on_road: ptr_list_posizione_abitanti_on_road; next_car_on_road_distance: Float; id_road: Positive) return Float;
   procedure calculate_distance_to_next_car_on_road(car_in_corsia: ptr_list_posizione_abitanti_on_road; next_car: ptr_list_posizione_abitanti_on_road; next_car_in_near_corsia: ptr_list_posizione_abitanti_on_road; from_corsia: id_corsie; next_car_on_road: out ptr_list_posizione_abitanti_on_road; next_car_on_road_distance: out Float);

   procedure calculate_parameters_car_in_uscita(list_abitanti: ptr_list_posizione_abitanti_on_road; traiettoria_rimasta_da_percorrere: Float; next_abitante: ptr_list_posizione_abitanti_on_road; distance_to_stop_line: Float; traiettoria_to_go: traiettoria_ingressi_type; distance_ingresso: Float; next_pos_abitante: in out Float; acceleration: out Float; new_step: out Float; new_speed: out Float);
   procedure calculate_parameters_car_in_entrata(list_abitanti: ptr_list_posizione_abitanti_on_road; traiettoria_rimasta_da_percorrere: Float; next_abitante: ptr_list_posizione_abitanti_on_road; distance_to_stop_line: Float; traiettoria_to_go: traiettoria_ingressi_type; next_pos_abitante: in out Float; acceleration: out Float; new_step: out Float; new_speed: out Float);

private

   task_urbane: task_container_urbane(get_from_urbane..get_to_urbane);
   task_ingressi: task_container_ingressi(get_from_ingressi..get_to_ingressi);
   task_incroci: task_container_incroci(get_from_incroci_a_4..get_to_incroci_a_3);
   task_rotonde: task_container_rotonde(get_from_rotonde_a_4..get_to_rotonde_a_3);

end risorse_strade_e_incroci;
