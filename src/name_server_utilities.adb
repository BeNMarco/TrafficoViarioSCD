with Text_IO;

use Text_IO;
package body name_server_utilities is
   procedure init_registro_strade(num_quartieri:Positive; num_strade:Positive) is
   begin
      null;
   end init_registro_strade;

   procedure registra_strada(strada: access rt_strada_features) is
   begin
      null;
   end registra_strada;

   function get_strada(tipo:type_strade; id_quartiere: Positive; id_strada: Positive) return access rt_strada_features is
   begin
      return null;
   end get_strada;


   function get_numero_quartieri(from_file:String) return Positive is -- ottieni il numero di quartieri
   begin
      return 1;
   end get_numero_quartieri;

   function get_numero_strade_max(from_file: String) return Positive is
   begin
   	return 1;
   end get_numero_strade_max;

   protected body registro_strade_resource is
      procedure registra_strada(strada: access rt_strada_features) is
      begin
         null;
      end registra_strada;

      function get_strada(tipo:type_strade; id_quartiere: Positive; id_strada: Positive) return access rt_strada_features is
      begin
         for el in strade'Range(1) loop
            for el1 in strade'Range(2) loop
               Put_Line(Integer'Image(1));
            end loop;
         end loop;
         return null;
      end get_strada;


   end registro_strade_resource;

--begin

   --el:=registro_strade_resource.get_strada(urbana,1,1);

end name_server_utilities;
