with GNATCOLL.JSON;

use GNATCOLL.JSON;

package snapshot_interface is
   pragma Elaborate_Body;

   type backup_interface is limited interface;
   type ptr_backup_interface is access all backup_interface'Class;
   -- ha senso se tra un'esecuzione e l'altra la mappa non cambia
   procedure create_img(obj: access backup_interface; json_1: out JSON_Value) is abstract;
   procedure recovery_resource(obj: access backup_interface) is abstract;

   protected share_snapshot_file_quartiere is
      procedure get_json_value_resource_snap(id_risorsa: Positive; json_resource: out JSON_Value);
      procedure get_json_value_locate_abitanti(json_locate: out JSON_Value);
      procedure configure;
   private
      json_snap: JSON_Value;
   end share_snapshot_file_quartiere;

end snapshot_interface;
