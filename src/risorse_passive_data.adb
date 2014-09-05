


package body risorse_passive_data is

   function get_urbana_from_id(index: Positive) return strada_urbana_features is
   begin
      return urbane_features(index);
   end get_urbana_from_id;
   function get_ingresso_from_id(index: Positive) return strada_ingresso_features is
   begin
      return ingressi_features(index);
   end get_ingresso_from_id;
   function get_incrocio_a_4_from_id(index: Positive) return list_road_incrocio_a_4 is
   begin
      return incroci_a_4(index);
   end get_incrocio_a_4_from_id;
   function get_incrocio_a_3_from_id(index: Positive) return list_road_incrocio_a_3 is
   begin
      return incroci_a_3(index);
   end get_incrocio_a_3_from_id;
   function get_rotonda_a_4_from_id(index: Positive) return list_road_incrocio_a_4 is
   begin
      return rotonde_a_4(index);
   end get_rotonda_a_4_from_id;
   function get_rotonda_a_3_from_id(index: Positive) return list_road_incrocio_a_3 is
   begin
      return rotonde_a_3(index);
   end get_rotonda_a_3_from_id;

   function get_urbane return strade_urbane_features is
   begin
      return urbane_features;
   end get_urbane;
   function get_ingressi return strade_ingresso_features is
   begin
      return ingressi_features;
   end get_ingressi;
   function get_incroci_a_4 return list_incroci_a_4 is
   begin
      return incroci_a_4;
   end get_incroci_a_4;
   function get_incroci_a_3 return list_incroci_a_3 is
   begin
      return incroci_a_3;
   end get_incroci_a_3;
   function get_rotonde_a_4 return list_incroci_a_4 is
   begin
      return rotonde_a_4;
   end get_rotonde_a_4;
   function get_rotonde_a_3 return list_incroci_a_3 is
   begin
      return rotonde_a_3;
   end get_rotonde_a_3;


end risorse_passive_data;
