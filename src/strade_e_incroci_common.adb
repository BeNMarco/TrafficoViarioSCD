

package body strade_e_incroci_common is

   function get_lunghezza_road(road: access rt_strada_features) return Natural is
   begin
      return road.lunghezza;
   end get_lunghezza_road;

   function get_id_main_strada_ingresso(road: access strada_ingresso_features) return Positive is
   begin
      return road.id_main_strada;
   end get_id_main_strada_ingresso;

   function get_distance_from_road_head_ingresso(road: access strada_ingresso_features) return Natural is
   begin
      return road.distance_from_road_head;
   end get_distance_from_road_head_ingresso;

      -- begin get methods road_incrocio_features
   function get_id_quartiere_road_incrocio(road: access road_incrocio_features) return Positive is
   begin
      return road.id_quartiere;
   end get_id_quartiere_road_incrocio;
   function get_id_strada_road_incrocio(road: access road_incrocio_features) return Positive is
   begin
      return road.id_strada;
   end get_id_strada_road_incrocio;
   -- end get methods road_incrocio_features

   function create_new_road_incrocio(val_id_quartiere: Positive;val_id_strada: Positive)
                                     return road_incrocio_features is
      road_incrocio: road_incrocio_features;
   begin
      road_incrocio.id_quartiere:= val_id_quartiere;
      road_incrocio.id_strada:= val_id_strada;
      return road_incrocio;
   end create_new_road_incrocio;

   function create_new_urbana(val_tipo: type_strade;val_id: Positive;val_id_quartiere: Positive;
                              val_lunghezza: Natural;val_num_corsie: Positive) return strada_urbana_features is
      ptr_strada: strada_urbana_features;
   begin
      ptr_strada.id:= val_id;
      ptr_strada.tipo:= val_tipo;
      ptr_strada.id_quartiere:= val_id_quartiere;
      ptr_strada.lunghezza:= val_lunghezza;
      ptr_strada.num_corsie:= val_num_corsie;
      return ptr_strada;
   end create_new_urbana;

   function create_new_ingresso(val_tipo: type_strade;val_id: Positive;val_id_quartiere: Positive;
                                val_lunghezza: Natural;val_num_corsie: Positive;val_id_main_strada: Positive;
                                val_distance_from_road_head: Natural) return strada_ingresso_features is
      ptr_strada: strada_ingresso_features;
   begin
      ptr_strada.id:= val_id;
      ptr_strada.tipo:= val_tipo;
      ptr_strada.id_quartiere:= val_id_quartiere;
      ptr_strada.lunghezza:= val_lunghezza;
      ptr_strada.num_corsie:= val_num_corsie;
      ptr_strada.id_main_strada:= val_id_main_strada;
      ptr_strada.distance_from_road_head:= val_distance_from_road_head;
      return ptr_strada;
   end create_new_ingresso;

end strade_e_incroci_common;
