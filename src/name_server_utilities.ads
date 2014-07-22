with rt_strade;

use rt_strade;

package name_server_utilities is
   pragma Remote_Call_Interface;

   type registro_strade is array(Positive range <>,Positive range <>) of access rt_strada_features;--ptr_rt_strada_features;

   procedure init_registro_strade(num_quartieri:Positive; num_strade:Positive);

   --procedure registra_strada(strada: access rt_strada_features); --ptr_rt_strada_features);

   --function get_strada(tipo:type_strade; id_quartiere: Positive; id_strada: Positive) return ptr_rt_strada_features;

private

   function get_numero_quartieri(from_file: String) return Positive;

   function get_numero_strade_max(from_file: String) return Positive;

   protected registro_strade_resource is
      --procedure registra_strada(strada: ptr_rt_strada_features);
      --function get_strada(tipo:type_strade; id_quartiere: Positive; id_strada: Positive) return ptr_rt_strada_features;
   private
      strade: registro_strade(1..get_numero_quartieri("data/setup_name_server"),1..get_numero_strade_max("data/setup_name_server"));
   end registro_strade_resource;


end name_server_utilities;
