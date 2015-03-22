with remote_types;
with configuration_synchronized_package;
--with global_data;

use remote_types;
use configuration_synchronized_package;
--use global_data;

package the_name_server is
   pragma Remote_Call_Interface;

   procedure registra_server_gps(my_gps: ptr_gps_interface);

   function get_server_gps return ptr_gps_interface;

   procedure registra_quartiere(id_quartiere: Positive; rt_quartiere: ptr_rt_quartiere_utilitites);

   function get_ref_rt_quartieri return registro_quartieri;

   function get_ref_quartiere(id_quartiere: Positive) return ptr_rt_quartiere_utilitites;

   procedure registra_local_synchronized_obj(id_quartiere: Positive; obj: ptr_rt_synchronization_tasks);

   function get_ref_local_synchronized_obj return registro_local_synchronized_obj;

   procedure registra_synchronization_tasks_object(obj: ptr_rt_task_synchronization);

   function get_synchronization_tasks_object return ptr_rt_task_synchronization;

   procedure registra_risorse_quartiere(id_quartiere: Positive; set_ingressi: set_resources_ingressi; set_urbane: set_resources_urbane; set_incroci: set_resources_incroci);

   function get_id_ingresso_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_ingresso;

   function get_id_urbana_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_urbana;

   function get_id_incrocio_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_incrocio;

   procedure registra_gestore_semafori(id_quartiere: Positive; handler_semafori_quartiere: ptr_rt_handler_semafori_quartiere);

   function get_gestori_quartiere return handler_semafori;

   type registro_quartiere_entities is array(Positive range <>) of ptr_rt_quartiere_entities_life;

   procedure registra_quartiere_entities_life(id_quartiere: Positive; obj: ptr_rt_quartiere_entities_life);
   function get_quartiere_entities_life(id_quartiere: Positive) return ptr_rt_quartiere_entities_life;

   procedure registra_quartiere_gestore_bus(id_quartiere: Positive; obj: ptr_rt_gestore_bus_quartiere);
   function get_quartiere_gestore_bus(id_quartiere: Positive) return ptr_rt_gestore_bus_quartiere;
   function get_registro_gestori_bus_quartieri return registro_gestori_bus_quartieri;
   -- web server
   procedure registra_webserver(my_web: Access_WebServer_Remote_Interface);
   function get_webServer return Access_WebServer_Remote_Interface;
   -- end web server

   procedure registra_quartiere_log(id_quartiere: Positive; file_log: ptr_rt_report_log);
   function get_log_quartiere(id_quartiere: Positive) return ptr_rt_report_log;
   type registro_quartieri_log is array(Positive range <>) of ptr_rt_report_log;

   --type ptr_registro_quartieri is access all registro_quartieri'Class;
   procedure configure_num_quartieri_name_server(numero_quartieri: in Positive);

   function rci_parameters_are_set return Boolean;

   function get_num_quartieri return Positive;
private

   web: Access_WebServer_Remote_Interface:= null;

   num_quartieri: Natural:= 0;

   protected type registro_log_quartieri(numero_quartieri: Positive) is
      procedure registra_quartiere_log(id_quartiere: Positive; file_log: ptr_rt_report_log);
      function get_log_quartiere(id_quartiere: Positive) return ptr_rt_report_log;
   private
      registro: registro_quartieri_log(1..numero_quartieri);
   end registro_log_quartieri;

   type ptr_registro_log_quartieri is access registro_log_quartieri;
   registro_log_quartieri_obj: ptr_registro_log_quartieri;

   protected type registro_ref_quartieri(numero_quartieri: Positive) is
      procedure registra_quartiere(id_quartiere: Positive; rt_quartiere: ptr_rt_quartiere_utilitites);
      function get_ref_rt_quartieri return registro_quartieri;
      function get_ref_quartiere(id_quartiere: Positive) return ptr_rt_quartiere_utilitites;
   private
      registro: registro_quartieri(1..numero_quartieri);
   end registro_ref_quartieri;

   type ptr_registro_ref_quartieri is access registro_ref_quartieri;
   registro_ref_quartieri_obj: ptr_registro_ref_quartieri;

   type risorse_quartieri_ingressi is array(Positive range <>) of access set_resources_ingressi;
   type risorse_quartieri_urbane is array(Positive range <>) of access set_resources_urbane;
   type risorse_quartieri_incroci is array(Positive range <>) of access set_resources_incroci;

   protected type registro_risorse_strade(numero_quartieri: Positive) is
      procedure registra_risorse_quartiere(id_quartiere: Positive; set_ingressi: set_resources_ingressi; set_urbane: set_resources_urbane; set_incroci: set_resources_incroci);

      function get_id_ingresso_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_ingresso;

      function get_id_urbana_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_urbana;

      function get_id_incrocio_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_incrocio;
   private
      registro_ingressi: risorse_quartieri_ingressi(1..numero_quartieri);
      registro_urbane: risorse_quartieri_urbane(1..numero_quartieri);
      registro_incroci: risorse_quartieri_incroci(1..numero_quartieri);
   end registro_risorse_strade;

   type ptr_registro_risorse_strade is access registro_risorse_strade;
   registro_risorse_strade_obj: ptr_registro_risorse_strade;

   protected type registro_gestori_semafori(numero_quartieri: Positive) is
      procedure registra_gestore_semafori(id_quartiere: Positive; handler_semafori_quartiere: ptr_rt_handler_semafori_quartiere);
      function get_gestori_quartiere return handler_semafori;
   private
      registro: handler_semafori(1..numero_quartieri);
   end registro_gestori_semafori;

   type ptr_registro_gestori_semafori is access registro_gestori_semafori;
   registro_gestori_semafori_obj: ptr_registro_gestori_semafori;

   protected get_my_mappa is
      procedure registra_mappa(id: out Positive);
   private
      num_mappa: Natural:=0;
   end get_my_mappa;

   protected type registro_local_synchronized_objects(numero_quartieri: Positive) is
      procedure registra_local_synchronized_obj(id_quartiere: Positive; obj: ptr_rt_synchronization_tasks);
      function get_ref_local_synchronized_obj return registro_local_synchronized_obj;
   private
      registro: registro_local_synchronized_obj(1..numero_quartieri);
   end registro_local_synchronized_objects;

   type ptr_registro_local_synchronized_objects is access registro_local_synchronized_objects;
   registro_local_synchronized_objects_obj: ptr_registro_local_synchronized_objects;

   protected type registro_quartiere_entities_life(numero_quartieri: Positive) is
      procedure registra_quartiere_entities_life(id_quartiere: Positive; obj: ptr_rt_quartiere_entities_life);
      function get_quartiere_entities_life(id_quartiere: Positive) return ptr_rt_quartiere_entities_life;
   private
      registro: registro_quartiere_entities(1..numero_quartieri);
   end registro_quartiere_entities_life;

   type ptr_registro_quartiere_entities_life is access registro_quartiere_entities_life;
   registro_quartiere_entities_life_obj: ptr_registro_quartiere_entities_life;

   protected type registro_quartieri_gestori_bus(numero_quartieri: Positive) is
      procedure registra_quartiere_gestore_bus(id_quartiere: Positive; obj: ptr_rt_gestore_bus_quartiere);
      function get_quartiere_gestore_bus(id_quartiere: Positive) return ptr_rt_gestore_bus_quartiere;
      function get_registro return registro_gestori_bus_quartieri;
   private
      registro: registro_gestori_bus_quartieri(1..numero_quartieri);
   end registro_quartieri_gestori_bus;

   type ptr_registro_quartieri_gestori_bus is access registro_quartieri_gestori_bus;
   registro_quartieri_gestori_bus_obj: ptr_registro_quartieri_gestori_bus;


   gps: ptr_gps_interface:= null;

   task_synchronization_obj: ptr_rt_task_synchronization:= null;

end the_name_server;
