with remote_types;
with global_data;

use remote_types;
use global_data;

package configuration_posizione_abitanti is
   pragma Remote_Call_Interface;

   procedure registra_classe_locate_abitanti_quartiere(id_quartiere: Positive; location_abitanti: ptr_rt_location_abitanti);

   function get_classi_locate_abitanti_all_quaritieri return gps_abitanti_quartieri;

private

   protected type posizione_abitanti_quartieri is
        procedure registra_classe_locate_abitanti_quartiere(id_quartiere: Positive; location_abitanti: ptr_rt_location_abitanti);
        function get_classi_locate_abitanti_all_quaritieri return gps_abitanti_quartieri;
   private
      gps_abitanti_quartie: gps_abitanti_quartieri(1..get_num_quartieri);
   end posizione_abitanti_quartieri;

   server_get_gps_abitanti_quartieri: posizione_abitanti_quartieri;

end configuration_posizione_abitanti;
