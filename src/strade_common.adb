

package body strade_common is

   function create_new_road_incrocio(val_id_quartiere: Positive;val_id_strada: Positive;
                                     val_tipo_strada: type_strade) return road_incrocio_features is
      road_incrocio: road_incrocio_features;
   begin
      road_incrocio.id_quartiere:= val_id_quartiere;
      road_incrocio.id_strada:= val_id_strada;
      road_incrocio.tipo_strada:= val_tipo_strada;
      return road_incrocio;
   end create_new_road_incrocio;

end strade_common;
