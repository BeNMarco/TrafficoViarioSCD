

package body data_quartiere is

   function get_json_urbane return JSON_Array is
   begin
      return json_urbane;
   end get_json_urbane;
   function get_json_ingressi return JSON_Array is
   begin
      return json_ingressi;
   end get_json_ingressi;
   function get_json_incroci_a_4 return JSON_Array is
   begin
      return json_incroci_a_4;
   end get_json_incroci_a_4;
   function get_json_incroci_a_3 return JSON_Array is
   begin
      return json_incroci_a_3;
   end get_json_incroci_a_3;
   function get_json_rotonde_a_4 return JSON_Array is
   begin
      return json_rotonde_a_4;
   end get_json_rotonde_a_4;
   function get_json_rotonde_a_3 return JSON_Array is
   begin
      return json_rotonde_a_3;
   end get_json_rotonde_a_3;
   function get_from_urbane return Natural is
   begin
      return from_urbane;
   end get_from_urbane;
   function get_to_urbane return Natural is
   begin
      return to_urbane;
   end get_to_urbane;
   function get_from_ingressi return Natural is
   begin
      return from_ingressi;
   end get_from_ingressi;
   function get_to_ingressi return Natural is
   begin
      return to_ingressi;
   end get_to_ingressi;
   function get_from_incroci_a_4 return Natural is
   begin
      return from_incroci_a_4;
   end get_from_incroci_a_4;
   function get_to_incroci_a_4 return Natural is
   begin
      return to_incroci_a_4;
   end get_to_incroci_a_4;
   function get_from_incroci_a_3 return Natural is
   begin
      return from_incroci_a_3;
   end get_from_incroci_a_3;
   function get_to_incroci_a_3 return Natural is
   begin
      return to_incroci_a_3;
   end get_to_incroci_a_3;
   function get_from_rotonde_a_4 return Natural is
   begin
      return from_rotonde_a_4;
   end get_from_rotonde_a_4;
   function get_to_rotonde_a_4 return Natural is
   begin
      return to_rotonde_a_4;
   end get_to_rotonde_a_4;
   function get_from_rotonde_a_3 return Natural is
   begin
      return from_rotonde_a_3;
   end get_from_rotonde_a_3;
   function get_to_rotonde_a_3 return Natural is
   begin
      return to_rotonde_a_3;
   end get_to_rotonde_a_3;

end data_quartiere;
