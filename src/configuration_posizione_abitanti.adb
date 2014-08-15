with remote_types;
with global_data;

use remote_types;
use global_data;

package body configuration_posizione_abitanti is
   procedure registra_classe_locate_abitanti_quartiere(id_quartiere: Positive; location_abitanti: ptr_rt_location_abitanti) is
   begin
      server_get_gps_abitanti_quartieri.registra_classe_locate_abitanti_quartiere(id_quartiere, location_abitanti);
   end registra_classe_locate_abitanti_quartiere;

   function get_classi_locate_abitanti_all_quaritieri return gps_abitanti_quartieri is
   begin
      return server_get_gps_abitanti_quartieri.get_classi_locate_abitanti_all_quaritieri;
   end get_classi_locate_abitanti_all_quaritieri;

   protected body posizione_abitanti_quartieri is

      procedure registra_classe_locate_abitanti_quartiere(id_quartiere: Positive; location_abitanti: ptr_rt_location_abitanti) is
      begin
         gps_abitanti_quartie(id_quartiere):= location_abitanti;
      end registra_classe_locate_abitanti_quartiere;

      function get_classi_locate_abitanti_all_quaritieri return gps_abitanti_quartieri is
      begin
         return gps_abitanti_quartie;
      end get_classi_locate_abitanti_all_quaritieri;

   end posizione_abitanti_quartieri;

end configuration_posizione_abitanti;
