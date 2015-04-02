with remote_types;
--with global_data;

use remote_types;
--use global_data;

package the_name_server is
   pragma Remote_Call_Interface;

   function is_server_registered return Boolean;
   function is_web_server_registered return Boolean;
   function is_quartiere_registered(id: Positive) return Boolean;

   procedure registra_server_gps(my_gps: ptr_gps_interface; all_ok: in out Boolean);

   function get_server_gps return ptr_gps_interface;

   procedure registra_quartiere(id_quartiere: Positive;
                                set_ingressi: set_resources_ingressi; set_urbane: set_resources_urbane; set_incroci: set_resources_incroci;
                                entities_life: ptr_rt_quartiere_entities_life;
                                gestore_bus: ptr_rt_gestore_bus_quartiere;
                                report_log: ptr_rt_report_log;
                                quartiere_utilities: ptr_rt_quartiere_utilitites;
                                synch_local_obj: ptr_rt_synchronization_partitions_type;
                                all_ok: in out Boolean);

   procedure quartiere_has_registered_map(id_quartiere: Positive);

   function get_ref_rt_quartieri return registro_quartieri;

   function get_ref_quartiere(id_quartiere: Positive) return ptr_rt_quartiere_utilitites;

   function get_id_ingresso_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_ingresso;

   function get_id_urbana_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_urbana;

   function get_id_incrocio_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_incrocio;

   type registro_quartiere_entities is array(Positive range <>) of ptr_rt_quartiere_entities_life;

   function get_quartiere_entities_life(id_quartiere: Positive) return ptr_rt_quartiere_entities_life;

   function get_registro_quartieri return registro_quartieri;

   function get_quartiere_gestore_bus(id_quartiere: Positive) return ptr_rt_gestore_bus_quartiere;

   function get_synchronizer_quartiere(id_quartiere: Positive) return ptr_rt_synchronization_partitions_type;
   -- web server
   procedure registra_webserver(my_web: Access_WebServer_Remote_Interface; all_ok: in out Boolean);
   function get_webServer return Access_WebServer_Remote_Interface;
   -- end web server

   function get_log_quartiere(id_quartiere: Positive) return ptr_rt_report_log;
   type registro_quartieri_log is array(Positive range <>) of ptr_rt_report_log;

   procedure configure_num_quartieri_name_server(numero_quartieri: Positive);
   function rci_parameters_are_set return Boolean;
   function get_num_quartieri return Positive;

   type registro_synchronizer_quartieri is array(Positive range <>) of ptr_rt_synchronization_partitions_type;

private

   type set_versioni is array(Positive range <>) of Boolean;

   protected servers_ref is
      procedure registra_server_gps(my_gps: ptr_gps_interface);
      procedure registra_webserver(my_web: Access_WebServer_Remote_Interface);

      function get_server_gps return ptr_gps_interface;
      function get_webServer return Access_WebServer_Remote_Interface;

      function is_server_registered return Boolean;
      function is_web_server_registered return Boolean;

   private
      gps: ptr_gps_interface:= null;
      web: Access_WebServer_Remote_Interface:= null;

      registered: set_versioni(1..2):= (others => False);  -- 1 è il gps; 2 il webserver
   end servers_ref;

   num_quartieri: Natural:= 0;

   type risorse_quartieri_ingressi is array(Positive range <>) of access set_resources_ingressi;
   type risorse_quartieri_urbane is array(Positive range <>) of access set_resources_urbane;
   type risorse_quartieri_incroci is array(Positive range <>) of access set_resources_incroci;

   protected type cfg_quartieri(max_num_quartieri: Positive) is
      procedure registra_quartiere(id_quartiere: Positive;
                                   set_ingressi: set_resources_ingressi; set_urbane: set_resources_urbane; set_incroci: set_resources_incroci;
                                   entities_life: ptr_rt_quartiere_entities_life;
                                   gestore_bus: ptr_rt_gestore_bus_quartiere;
                                   report_log: ptr_rt_report_log;
                                   quartiere_utilities: ptr_rt_quartiere_utilitites;
                                   synch_local_obj: ptr_rt_synchronization_partitions_type);

      procedure quartiere_has_registered_map(id_quartiere: Positive);

      function get_log_quartiere(id_quartiere: Positive) return ptr_rt_report_log;

      function get_ref_rt_quartieri return registro_quartieri;
      function get_ref_quartiere(id_quartiere: Positive) return ptr_rt_quartiere_utilitites;

      function get_id_ingresso_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_ingresso;
      function get_id_urbana_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_urbana;
      function get_id_incrocio_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_incrocio;

      function get_quartiere_entities_life(id_quartiere: Positive) return ptr_rt_quartiere_entities_life;

      function get_quartiere_gestore_bus(id_quartiere: Positive) return ptr_rt_gestore_bus_quartiere;
      function get_registro_gestori_bus return registro_gestori_bus_quartieri;

      function get_synchronizer_quartiere(id_quartiere: Positive) return ptr_rt_synchronization_partitions_type;

      function get_registro_quartieri return registro_quartieri;

      function is_quartiere_registered(id: Positive) return Boolean;
   private
      registro_quartieri_util: registro_quartieri(1..max_num_quartieri);

      registro_log: registro_quartieri_log(1..max_num_quartieri);

      registro_ingressi: risorse_quartieri_ingressi(1..max_num_quartieri);
      registro_urbane: risorse_quartieri_urbane(1..max_num_quartieri);
      registro_incroci: risorse_quartieri_incroci(1..max_num_quartieri);

      registro_lifes: registro_quartiere_entities(1..max_num_quartieri);

      registro_bus: registro_gestori_bus_quartieri(1..max_num_quartieri);
      registro_synch_quartieri: registro_synchronizer_quartieri(1..max_num_quartieri);

      registered: set_versioni(1..max_num_quartieri):= (others => False);

      map_registered: set_versioni(1..max_num_quartieri):= (others => False);
   end cfg_quartieri;

   type ptr_cfg_quartieri is access cfg_quartieri;

   cfg_quartieri_obj: ptr_cfg_quartieri;

end the_name_server;
