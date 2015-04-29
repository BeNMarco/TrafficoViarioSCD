with Ada.Unchecked_Deallocation;
with gps_utilities;
with strade_e_incroci_common;

use gps_utilities;
use strade_e_incroci_common;

package support_type_gps_utilities is

   --procedure Free_hash_quartiere_strade is new Ada.Unchecked_Deallocation
   --  (Object => hash_quartiere_strade, Name => ptr_hash_quartiere_strade);

   --procedure Free_nodi_quartiere is new Ada.Unchecked_Deallocation
   --  (Object => nodi_quartiere, Name => ptr_nodi_quartiere);

   procedure Free_percorso is new Ada.Unchecked_Deallocation
     (Object => list_percorso, Name => ptr_percorso);


   type ptr_strade_urbane_features is access all strade_urbane_features;
   procedure Free_strade_urbane_features is new Ada.Unchecked_Deallocation
     (Object => strade_urbane_features, Name => ptr_strade_urbane_features);

   type ptr_hash_quartiere_strade is access all hash_quartiere_strade;
   procedure Free_hash_quartiere_strade is new Ada.Unchecked_Deallocation
     (Object => hash_quartiere_strade, Name => ptr_hash_quartiere_strade);

   type ptr_strade_ingresso_features is access all strade_ingresso_features;
   procedure Free_strade_ingresso_features is new Ada.Unchecked_Deallocation
     (Object => strade_ingresso_features, Name => ptr_strade_ingresso_features);

end support_type_gps_utilities;
