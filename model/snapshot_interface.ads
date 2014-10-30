with GNATCOLL.JSON;

use GNATCOLL.JSON;

package snapshot_interface is

   type backup_interface is limited interface;
   type ptr_backup_interface is access all backup_interface'Class;
   -- ha senso se tra un'esecuzione e l'altra la mappa non cambia
   procedure create_img(obj: access backup_interface; json_1: out JSON_Value) is abstract;

end snapshot_interface;
